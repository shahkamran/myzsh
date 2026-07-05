#!/usr/bin/env zsh
# ╔══════════════════════════════════════════════════════════════════════╗
# ║  myzsh :: security                                                 ║
# ║  Safe sourcing, permission checks, checksum verification           ║
# ╚══════════════════════════════════════════════════════════════════════╝

MYZSH_LOCKFILE="$MYZSH_DIR/myzsh.lock"

# ─── Safe Source ──────────────────────────────────────────────────────
# Sources a file only if it passes ownership, permission, and checksum checks
# Usage: myzsh-safe-source <file> [skip_checksum:true|false]
myzsh-safe-source() {
  local file="$1"
  local skip_checksum="${2:-false}"

  if [[ ! -f "$file" ]]; then
    return 1
  fi

  # Permission and ownership checks
  if [[ "$MYZSH_STRICT_PERMISSIONS" == "true" ]]; then
    local file_owner file_perms
    file_owner=$(stat -f '%u' "$file" 2>/dev/null || stat -c '%u' "$file" 2>/dev/null)
    file_perms=$(stat -f '%Lp' "$file" 2>/dev/null || stat -c '%a' "$file" 2>/dev/null)

    # Must be owned by current user or root
    if [[ "$file_owner" != "$(id -u)" && "$file_owner" != "0" ]]; then
      echo "⚠️  myzsh: refusing to source '$file' (owner: $file_owner, expected: $(id -u))" >&2
      return 1
    fi

    # Must not be group-writable or world-writable
    local group_perms="${file_perms: -2:1}"
    local other_perms="${file_perms: -1}"
    if [[ "$other_perms" =~ [2367] ]] || [[ "$group_perms" =~ [2367] ]]; then
      echo "⚠️  myzsh: refusing to source '$file' (group/world-writable: $file_perms)" >&2
      return 1
    fi
  fi

  # Checksum verification (only for plugin/theme files in the lockfile)
  if [[ "$MYZSH_VERIFY_PLUGINS" == "true" && "$skip_checksum" == "false" ]]; then
    if [[ -f "$MYZSH_LOCKFILE" ]]; then
      # Verify lockfile ownership before trusting it
      local lock_owner
      lock_owner=$(stat -f '%u' "$MYZSH_LOCKFILE" 2>/dev/null || stat -c '%u' "$MYZSH_LOCKFILE" 2>/dev/null)
      if [[ "$lock_owner" != "$(id -u)" && "$lock_owner" != "0" ]]; then
        echo "🔒 myzsh: lockfile has wrong owner, refusing all plugin loads" >&2
        return 1
      fi

      # Use grep -F for fixed-string matching (no regex metachar issues)
      local expected_hash
      expected_hash=$(grep -F "${file}:" "$MYZSH_LOCKFILE" 2>/dev/null | head -1 | cut -d: -f2-)

      if [[ -n "$expected_hash" ]]; then
        local actual_hash
        actual_hash=$(shasum -a 256 "$file" 2>/dev/null | cut -d' ' -f1)
        if [[ "$actual_hash" != "$expected_hash" ]]; then
          echo "🔒 myzsh: CHECKSUM MISMATCH for '$file'" >&2
          echo "   Expected: ${expected_hash:0:16}..." >&2
          echo "   Got:      ${actual_hash:0:16}..." >&2
          echo "   Run 'myzsh-update-lock' to update, or investigate." >&2
          return 1
        fi
      fi
    fi
  fi

  source "$file"
}

# ─── Update Lockfile ──────────────────────────────────────────────────
# Regenerates checksums for all plugin and theme files
myzsh-update-lock() {
  echo "🔒 Updating myzsh lockfile..."
  : > "$MYZSH_LOCKFILE"

  local count=0
  for plugin_file in "$MYZSH_DIR"/plugins/**/*.plugin.zsh(N); do
    local hash
    hash=$(shasum -a 256 "$plugin_file" | cut -d' ' -f1)
    echo "${plugin_file}:${hash}" >> "$MYZSH_LOCKFILE"
    ((count++))
  done

  # Also hash theme files
  for theme_file in "$MYZSH_DIR"/themes/**/*.zsh-theme(N); do
    local hash
    hash=$(shasum -a 256 "$theme_file" | cut -d' ' -f1)
    echo "${theme_file}:${hash}" >> "$MYZSH_LOCKFILE"
    ((count++))
  done

  echo "   ✓ Locked ${count} files"
  chmod 600 "$MYZSH_LOCKFILE"
}

# ─── Verify All ───────────────────────────────────────────────────────
myzsh-verify() {
  if [[ ! -f "$MYZSH_LOCKFILE" ]]; then
    echo "⚠️  No lockfile found. Run 'myzsh-update-lock' first."
    return 1
  fi

  local failures=0 checked=0
  while IFS='' read -r line; do
    # Split on last colon (handles paths with colons)
    local file="${line%:*}"
    local expected_hash="${line##*:}"

    if [[ ! -f "$file" ]]; then
      echo "  ✗ Missing: $file"
      ((failures++))
      continue
    fi
    local actual_hash
    actual_hash=$(shasum -a 256 "$file" | cut -d' ' -f1)
    if [[ "$actual_hash" != "$expected_hash" ]]; then
      echo "  ✗ Modified: $file"
      ((failures++))
    else
      ((checked++))
    fi
  done < "$MYZSH_LOCKFILE"

  if (( failures == 0 )); then
    echo "✓ All ${checked} files verified successfully"
  else
    echo "⚠️  ${failures} file(s) failed verification (${checked} passed)"
    return 1
  fi
}

# ─── Directory Permissions ────────────────────────────────────────────
if [[ "$MYZSH_STRICT_PERMISSIONS" == "true" ]]; then
  if [[ -d "$MYZSH_DIR" ]]; then
    local dir_perms
    dir_perms=$(stat -f '%Lp' "$MYZSH_DIR" 2>/dev/null || stat -c '%a' "$MYZSH_DIR" 2>/dev/null)
    if [[ "$dir_perms" != "700" ]]; then
      chmod 700 "$MYZSH_DIR" 2>/dev/null
    fi
  fi
fi
