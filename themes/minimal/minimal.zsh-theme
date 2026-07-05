#!/usr/bin/env zsh
# ╔══════════════════════════════════════════════════════════════════════╗
# ║  myzsh :: minimal theme                                            ║
# ║  Clean, fast, distraction-free prompt                              ║
# ╚══════════════════════════════════════════════════════════════════════╝

# Git branch (minimal)
_myzsh_minimal_git() {
  local branch
  branch=$(git symbolic-ref --short HEAD 2>/dev/null) || return
  local dirty=""
  [[ -n $(git status --porcelain 2>/dev/null) ]] && dirty="*"
  echo " %F{240}on%f %F{magenta}${branch}${dirty}%f"
}

setopt PROMPT_SUBST

PROMPT='%F{blue}%2~%f$(_myzsh_minimal_git) %F{%(?.green.red)}❯%f '
RPROMPT='%F{240}%T%f'
PROMPT2='%F{240}  … %f'
