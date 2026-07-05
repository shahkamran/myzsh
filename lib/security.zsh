#!/usr/bin/env zsh
# ╔══════════════════════════════════════════════════════════════════════╗
# ║  myzsh :: security                                                 ║
# ║  Safe sourcing, permission checks, checksum verification           ║
# ╚══════════════════════════════════════════════════════════════════════╝

MYZSH_LOCKFILE="$MYZSH_DIR/myzsh.lock"

# ─── Safe Source ──────────────────────────────────────────────────────
# Sources a file only if it passes ownership and permission checks
myzsh-safe-source() {
  local file="$1"
  local skip_checksum="${2:-false}"

  if [[ ! -f "$file" ]]; then
    return 1
  fi

  # Permission check
  if [[ "$MYZSH_STRICT_PERMISSIONS" == "true" ]]; then
    local file_owner file_perms
    file_owner=$(stat -f '%u' "$file" 2>/dev/null || stat -c '%u' "$file" 2>/dev/null)
    file_perms=$(stat -f '%Lp' "$file" 2>/dev/null || stat -c '%a' "$file" 2>/dev/null)

    # Must be owned by current user or root
    if [[ "$file_owner" != "$(id -u)" && "$file_owner" != "0" ]]; then
      echo "⚠️  myzsh: refusing to source '$file' (owner mismatch)" >&2
      return 1
    fi

    # Must not be world-writable
    if [[ "${file_perms: -1}" =~ [2367] ]]; then
      echo "⚠️  myzsh: refusing to source '$file' (world-writable)" >&2
      return 1
    fi
  fi

  # Checksum verification for plugins
  if [[ "$MYZSH_VERIFY_PLUGINS" == "true" && "$skip_checksum" == "false" ]]; then
    if [[ -f "$MYZSH_LOCKFILE" ]]; then
      local expected_hash actual_hash
      expected_hash=$(grep "^${file}:" "$MYZSH_LOCKFILE" 2>/dev/null | cut -d: -f2)
      if [[ -n "$expected_hash" ]]; then
        actual_hash=$(shasum -a 256 "$file" 2>/dev/null | cut -d' ' -f1)
        if [[ "$actual_hash" != "$expected_hash" ]]; then
          echo "🔒 myzsh: checksum mismatch for '$file'" >&2
          echo "   Run 'myzsh-update-lock' to update." >&2
          return 1
        fi
      fi
    fi
  fi

  source "$file"
}

# ─── Update Lockfile ──────────────────────────────────────────────────
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

  local failures=0
  while IFS=: read -r file expected_hash; do
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
    fi
  done < "$MYZSH_LOCKFILE"

  if (( failures == 0 )); then
    echo "✓ All files verified successfully"
  else
    echo "⚠️  ${failures} file(s) failed verification"
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
