#!/usr/bin/env zsh
# ╔══════════════════════════════════════════════════════════════════════╗
# ║  myzsh :: history                                                  ║
# ║  Powerful shell history with search, dedup, and security           ║
# ╚══════════════════════════════════════════════════════════════════════╝

# ─── History File ─────────────────────────────────────────────────────
export HISTFILE="${MYZSH_DATA}/history"
export HISTSIZE="${MYZSH_HISTSIZE:-50000}"
export SAVEHIST="${MYZSH_SAVEHIST:-50000}"

# ─── History Options ──────────────────────────────────────────────────
setopt EXTENDED_HISTORY       # Write timestamps to history
setopt HIST_EXPIRE_DUPS_FIRST # Expire duplicate entries first
setopt HIST_FIND_NO_DUPS      # Don't display dups when searching
setopt HIST_REDUCE_BLANKS     # Remove extra blanks from commands
setopt INC_APPEND_HISTORY     # Add commands immediately

if [[ "$MYZSH_HIST_IGNORE_DUPS" == "true" ]]; then
  setopt HIST_IGNORE_ALL_DUPS
  setopt HIST_IGNORE_DUPS
fi

if [[ "$MYZSH_HIST_IGNORE_SPACE" == "true" ]]; then
  setopt HIST_IGNORE_SPACE
fi

if [[ "$MYZSH_HIST_SHARE" == "true" ]]; then
  setopt SHARE_HISTORY
fi

# ─── History Security ─────────────────────────────────────────────────
# Never save sensitive commands
MYZSH_HIST_IGNORE_PATTERNS=(
  'export *=*TOKEN*'
  'export *=*SECRET*'
  'export *=*PASSWORD*'
  'export *=*KEY=*'
  '*mysql*-p*'
  '*psql*password*'
  'curl*-H*[Aa]uth*'
  'wget*--password*'
)

zshaddhistory() {
  local cmd="${1%%$'\n'}"
  for pattern in "${MYZSH_HIST_IGNORE_PATTERNS[@]}"; do
    if [[ "$cmd" == ${~pattern} ]]; then
      return 1
    fi
  done
  return 0
}

# ─── History Search ───────────────────────────────────────────────────
autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search

bindkey "^[[A" up-line-or-beginning-search    # Up arrow
bindkey "^[[B" down-line-or-beginning-search  # Down arrow

# ─── History Aliases ──────────────────────────────────────────────────
alias h='history -i -20'
alias hg='history -i 0 | grep'
alias hc='echo -n "" > "$HISTFILE" && echo "✓ History cleared"'

hist() {
  if [[ -n "$1" ]]; then
    history -i 0 | grep --color=auto "$1"
  else
    history -i -50
  fi
}
