#!/usr/bin/env zsh
# ╔══════════════════════════════════════════════════════════════════════╗
# ║  myzsh :: aliases/navigation                                       ║
# ║  Quick directory navigation and bookmarks                           ║
# ╚══════════════════════════════════════════════════════════════════════╝

# ─── Quick Navigation ─────────────────────────────────────────────────
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
alias -- -='cd -'

# ─── Directory Stack ──────────────────────────────────────────────────
alias d='dirs -v | head -20'
alias 1='cd -1'
alias 2='cd -2'
alias 3='cd -3'
alias 4='cd -4'
alias 5='cd -5'

# ─── Common Directories ──────────────────────────────────────────────
alias dl='cd ~/Downloads'
alias dt='cd ~/Desktop'
alias dev='cd ~/Documents/dev'
alias proj='cd ~/Projects 2>/dev/null || cd ~/Documents/dev'

# ─── Make and Enter Directory ─────────────────────────────────────────
mkcd() {
  mkdir -p "$1" && cd "$1"
}

# ─── Jump to Git Root ─────────────────────────────────────────────────
alias groot='cd "$(git rev-parse --show-toplevel 2>/dev/null || echo .)"'

# ─── Quick Find Directories ──────────────────────────────────────────
# fzf-powered directory jump (if fzf is available)
if command -v fzf &>/dev/null; then
  fcd() {
    local dir
    dir=$(find "${1:-.}" -type d -not -path '*/\.*' 2>/dev/null | fzf +m) && cd "$dir"
  }
fi
