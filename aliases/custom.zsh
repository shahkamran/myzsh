#!/usr/bin/env zsh
# ╔══════════════════════════════════════════════════════════════════════╗
# ║  myzsh :: aliases/custom                                           ║
# ║  Your personal aliases — add anything you use frequently!          ║
# ╚══════════════════════════════════════════════════════════════════════╝

# ─── Examples (uncomment or add your own) ─────────────────────────────

# Quick server
alias serve='python3 -m http.server 8000'

# Node/NPM
alias ni='npm install'
alias nr='npm run'
alias nrd='npm run dev'
alias nrb='npm run build'
alias nrt='npm run test'

# Python
alias py='python3'
alias pip='pip3'
alias venv='python3 -m venv .venv && source .venv/bin/activate'
alias activate='source .venv/bin/activate'

# Homebrew (macOS)
if [[ "$(uname)" == "Darwin" ]]; then
  alias brewup='brew update && brew upgrade && brew cleanup'
fi

# Quick shortcuts
alias cls='clear'

# Timestamp
alias ts='date +%s'

# JSON pretty print
alias json='python3 -m json.tool'

# ─── Add your own below ──────────────────────────────────────────────

