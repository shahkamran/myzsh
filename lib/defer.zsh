#!/usr/bin/env zsh
# ╔══════════════════════════════════════════════════════════════════════╗
# ║  myzsh :: defer                                                    ║
# ║  Lightweight deferred execution engine                             ║
# ║  Runs commands after prompt is displayed (shell is idle)           ║
# ╚══════════════════════════════════════════════════════════════════════╝

typeset -ga _myzsh_defer_queue=()
typeset -g _myzsh_defer_loaded=false

# ─── Queue a command for deferred execution ───────────────────────────
# Only supports: source <path> and fpath assignments
myzsh-defer() {
  _myzsh_defer_queue+=("$*")

  # Install the hook if not already installed
  if [[ "$_myzsh_defer_loaded" == "false" ]]; then
    _myzsh_defer_loaded=true
    autoload -Uz add-zsh-hook
    add-zsh-hook precmd _myzsh_defer_precmd
  fi
}

# ─── Precmd hook: schedule deferred execution ─────────────────────────
_myzsh_defer_precmd() {
  # Remove ourselves — only run once
  add-zsh-hook -d precmd _myzsh_defer_precmd

  # Use sched to run after prompt renders
  if (( ${#_myzsh_defer_queue} > 0 )); then
    zmodload zsh/sched 2>/dev/null
    sched +0 _myzsh_defer_execute
  fi
}

# ─── Execute all deferred commands (safe dispatch) ────────────────────
_myzsh_defer_execute() {
  local cmd
  for cmd in "${_myzsh_defer_queue[@]}"; do
    # Safe dispatch: only allow known command patterns
    case "$cmd" in
      myzsh-safe-source\ *)
        # Extract file path and call safe-source
        local file="${cmd#myzsh-safe-source }"
        # Remove surrounding quotes if present
        file="${file//\'/}"
        file="${file//\"/}"
        myzsh-safe-source "$file"
        ;;
      source\ *)
        # Direct source (for trusted internal files only)
        local file="${cmd#source }"
        file="${file//\'/}"
        file="${file//\"/}"
        source "$file" 2>> "${MYZSH_CACHE}/defer-errors.log"
        ;;
      fpath=*)
        # fpath assignment — execute safely
        eval "$cmd" 2>> "${MYZSH_CACHE}/defer-errors.log"
        ;;
      *)
        # Reject unknown commands — log and skip
        echo "[$(date '+%H:%M:%S')] REJECTED deferred command: $cmd" >> "${MYZSH_CACHE}/defer-errors.log"
        ;;
    esac
  done
  _myzsh_defer_queue=()

  # Refresh prompt after plugins load
  if (( ${+functions[_zsh_highlight]} )); then
    zle && zle reset-prompt 2>/dev/null
  fi
}
