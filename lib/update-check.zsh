#!/usr/bin/env zsh
# ╔══════════════════════════════════════════════════════════════════════╗
# ║  myzsh :: update-check                                             ║
# ║  Weekly check for available updates (non-blocking)                 ║
# ╚══════════════════════════════════════════════════════════════════════╝

# Check interval: 7 days (in seconds)
MYZSH_UPDATE_CHECK_INTERVAL=${MYZSH_UPDATE_CHECK_INTERVAL:-604800}
MYZSH_UPDATE_STAMP_FILE="$MYZSH_CACHE/.update-check"

# ─── Should we check? ────────────────────────────────────────────────
_myzsh_should_check_update() {
  # Skip if disabled
  [[ "$MYZSH_AUTO_UPDATE_CHECK" == "false" ]] && return 1

  # Skip if no network command available
  command -v git &>/dev/null || return 1

  # Skip if stamp file is recent enough
  if [[ -f "$MYZSH_UPDATE_STAMP_FILE" ]]; then
    local last_check
    last_check=$(cat "$MYZSH_UPDATE_STAMP_FILE" 2>/dev/null)
    local now=$EPOCHSECONDS
    if (( now - last_check < MYZSH_UPDATE_CHECK_INTERVAL )); then
      return 1
    fi
  fi

  return 0
}

# ─── Perform the check (background, non-blocking) ────────────────────
_myzsh_check_for_updates() {
  if ! _myzsh_should_check_update; then
    return
  fi

  # Record that we checked (even if fetch fails, don't spam)
  echo "$EPOCHSECONDS" > "$MYZSH_UPDATE_STAMP_FILE"

  # Run fetch in background to avoid blocking shell startup
  {
    # Fetch remote without merging
    git -C "$MYZSH_DIR" fetch origin main --quiet 2>/dev/null

    # Compare local HEAD with remote
    local local_head remote_head
    local_head=$(git -C "$MYZSH_DIR" rev-parse HEAD 2>/dev/null)
    remote_head=$(git -C "$MYZSH_DIR" rev-parse origin/main 2>/dev/null)

    if [[ -n "$local_head" && -n "$remote_head" && "$local_head" != "$remote_head" ]]; then
      # Count commits behind
      local behind
      behind=$(git -C "$MYZSH_DIR" rev-list --count HEAD..origin/main 2>/dev/null)

      # Write update-available flag
      echo "$behind" > "$MYZSH_CACHE/.update-available"
    else
      # Up to date — remove flag if present
      rm -f "$MYZSH_CACHE/.update-available"
    fi
  } &!
}

# ─── Show update banner (if updates available) ────────────────────────
_myzsh_show_update_banner() {
  if [[ -f "$MYZSH_CACHE/.update-available" ]]; then
    local behind
    behind=$(cat "$MYZSH_CACHE/.update-available" 2>/dev/null)

    echo ""
    print -P "%F{yellow}╭──────────────────────────────────────────────────╮%f"
    print -P "%F{yellow}│%f  🔄 %F{white}myzsh update available%f — ${behind} new commit(s)     %F{yellow}│%f"
    print -P "%F{yellow}│%f                                                  %F{yellow}│%f"
    print -P "%F{yellow}│%f  Run %F{cyan}myzsh-update%f to update                    %F{yellow}│%f"
    print -P "%F{yellow}│%f  Run %F{240}myzsh-update-dismiss%f to dismiss this       %F{yellow}│%f"
    print -P "%F{yellow}╰──────────────────────────────────────────────────╯%f"
    echo ""
  fi
}

# ─── Dismiss the update notice ────────────────────────────────────────
myzsh-update-dismiss() {
  rm -f "$MYZSH_CACHE/.update-available"
  echo "✓ Update notice dismissed (will check again in 7 days)"
}

# ─── Run the check and show banner ───────────────────────────────────
zmodload zsh/datetime 2>/dev/null
_myzsh_check_for_updates
_myzsh_show_update_banner
