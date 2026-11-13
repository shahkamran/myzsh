#!/usr/bin/env zsh
# ╔══════════════════════════════════════════════════════════════════════╗
# ║  myzsh :: security                                                 ║
# ║  Safe sourcing, permission checks, checksum verification           ║
# ╚══════════════════════════════════════════════════════════════════════╝

MYZSH_LOCKFILE="$MYZSH_DIR/myzsh.lock"

# ─── Portable helpers (macOS/BSD + GNU/BusyBox) ───────────────────────
# _myzsh_stat owner|perms <path>: numeric owner uid or octal permissions
_myzsh_stat() {
  local fmt_gnu fmt_bsd
  case "$1" in
    owner) fmt_gnu='%u' fmt_bsd='%u' ;;
    perms) fmt_gnu='%a' fmt_bsd='%Lp' ;;
  esac
  # GNU `stat -f` means --file-system and prints to stdout, so the flavour
  # is detected once (below) instead of trying one and falling back
  if [[ "$_myzsh_stat_flavour" == gnu ]]; then
    command stat -c "$fmt_gnu" "$2" 2>/dev/null
  else
    command stat -f "$fmt_bsd" "$2" 2>/dev/null
  fi
}
if command stat -c '%u' / >/dev/null 2>&1; then
  typeset -g _myzsh_stat_flavour=gnu
else
  typeset -g _myzsh_stat_flavour=bsd
fi

_myzsh_have_sha256() {
  (( $+commands[sha256sum] || $+commands[shasum] || $+commands[openssl] ))
}

# _myzsh_sha256 <file>: print the hex sha256 of a file (nothing on failure)
_myzsh_sha256() {
  local out
  if (( $+commands[sha256sum] )); then
    out=$(command sha256sum "$1" 2>/dev/null)
  elif (( $+commands[shasum] )); then
    out=$(command shasum -a 256 "$1" 2>/dev/null)
  elif (( $+commands[openssl] )); then
    out=$(command openssl dgst -sha256 -r "$1" 2>/dev/null)
  fi
  print -r -- "${out%% *}"
}

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
    file_owner=$(_myzsh_stat owner "$file")
    file_perms=$(_myzsh_stat perms "$file")

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
      lock_owner=$(_myzsh_stat owner "$MYZSH_LOCKFILE")
      if [[ "$lock_owner" != "$(id -u)" && "$lock_owner" != "0" ]]; then
        echo "🔒 myzsh: lockfile has wrong owner, refusing all plugin loads" >&2
        return 1
      fi

      # Use grep -F for fixed-string matching (no regex metachar issues)
      local expected_hash
      expected_hash=$(grep -F "${file}:" "$MYZSH_LOCKFILE" 2>/dev/null | head -1 | cut -d: -f2-)

      if [[ -n "$expected_hash" ]] && ! _myzsh_have_sha256; then
        # No hashing tool on this system: warn once, don't break startup
        if [[ -z "$_myzsh_nohash_warned" ]]; then
          typeset -g _myzsh_nohash_warned=1
          echo "⚠️  myzsh: no sha256 tool (sha256sum/shasum/openssl), skipping checksum checks" >&2
        fi
      elif [[ -n "$expected_hash" ]]; then
        local actual_hash
        actual_hash=$(_myzsh_sha256 "$file")
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
  if ! _myzsh_have_sha256; then
    echo "   ✗ no sha256 tool found (install coreutils, perl-Digest-SHA or openssl)" >&2
    return 1
  fi
  : > "$MYZSH_LOCKFILE"

  local count=0
  for plugin_file in "$MYZSH_DIR"/plugins/**/*.plugin.zsh(N); do
    local hash
    hash=$(_myzsh_sha256 "$plugin_file")
    echo "${plugin_file}:${hash}" >> "$MYZSH_LOCKFILE"
    ((count++))
  done

  # Also hash theme files
  for theme_file in "$MYZSH_DIR"/themes/**/*.zsh-theme(N); do
    local hash
    hash=$(_myzsh_sha256 "$theme_file")
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

  if ! _myzsh_have_sha256; then
    echo "⚠️  No sha256 tool found (sha256sum/shasum/openssl)."
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
    actual_hash=$(_myzsh_sha256 "$file")
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
    dir_perms=$(_myzsh_stat perms "$MYZSH_DIR")
    if [[ "$dir_perms" != "700" ]]; then
      chmod 700 "$MYZSH_DIR" 2>/dev/null
    fi
  fi
fi
