#!/usr/bin/env zsh
# ╔══════════════════════════════════════════════════════════════════════╗
# ║  myzsh :: init                                                     ║
# ║  Core initialisation: environment, path, options                   ║
# ╚══════════════════════════════════════════════════════════════════════╝

# ─── ZSH Options ──────────────────────────────────────────────────────
setopt AUTO_CD              # cd by typing directory name
setopt AUTO_PUSHD           # push directories onto stack
setopt PUSHD_IGNORE_DUPS    # no duplicates in dir stack
setopt PUSHD_SILENT         # don't print dir stack after pushd/popd
setopt EXTENDED_GLOB        # advanced globbing
setopt NO_BEEP              # silence terminal beeps
setopt INTERACTIVE_COMMENTS # allow comments in interactive shell
setopt MULTIOS              # multiple redirections
setopt PROMPT_SUBST         # enable prompt substitution
setopt LONG_LIST_JOBS       # display PID when suspending processes

# Spelling correction asks "correct X to Y? [nyae]" and waits for an answer,
# which hangs AI agents and IDE tools — only enable it for humans
if [[ -n "$MYZSH_AGENT_MODE" ]]; then
  unsetopt CORRECT CORRECT_ALL
else
  setopt CORRECT            # spelling correction for commands
fi

# ─── Path Configuration ──────────────────────────────────────────────
# -g: this file is sourced from inside myzsh-safe-source(); a plain
# `typeset -U path` would create an empty function-local path
typeset -gU path  # deduplicate

local -a extra_paths=(
  "$HOME/.local/bin"
  "$HOME/bin"
  "/usr/local/bin"
  "/opt/homebrew/bin"
  "/opt/homebrew/sbin"
)

for p in "${extra_paths[@]}"; do
  [[ -d "$p" ]] && path=("$p" $path)
done

export PATH

# ─── Editor ───────────────────────────────────────────────────────────
export EDITOR="${EDITOR:-vim}"
export VISUAL="${VISUAL:-$EDITOR}"

# ─── Pager ────────────────────────────────────────────────────────────
export PAGER="${PAGER:-less}"
# --mouse needs less >= 551; older versions abort with "no mouse option"
export LESS="-R"
if [[ -z "$MYZSH_AGENT_MODE" ]] && command less --help 2>/dev/null | command grep -q -- '--mouse'; then
  LESS+=" --mouse --wheel-lines=3"
fi

# ─── Locale ───────────────────────────────────────────────────────────
# Only default LANG: forcing LC_ALL overrides the user's LC_* choices and
# emits setlocale warnings where en_US.UTF-8 isn't generated (minimal Linux)
export LANG="${LANG:-en_US.UTF-8}"

# ─── Colour Support ──────────────────────────────────────────────────
autoload -Uz colors && colors

if [[ "$TERM" != "dumb" ]]; then
  export TERM="${TERM:-xterm-256color}"
fi

# ─── LS_COLORS for completion (macOS compatibility) ───────────────────
# macOS uses LSCOLORS but zsh completion needs LS_COLORS (GNU format)
if [[ -z "$LS_COLORS" ]]; then
  if (( $+commands[gdircolors] )); then
    eval "$(gdircolors -b)"
  elif (( $+commands[dircolors] )); then
    eval "$(dircolors -b)"
  else
    # Sensible defaults for macOS where dircolors isn't available
    export LS_COLORS="di=1;34:ln=35:so=32:pi=33:ex=31:bd=34;46:cd=34;43:su=30;41:sg=30;46:tw=30;42:ow=30;43"
  fi
fi

# ─── Reload Function ─────────────────────────────────────────────────
unalias reload 2>/dev/null
reload() {
  echo "♻️  Reloading shell..."
  exec zsh
}

# ─── Myzsh Info ───────────────────────────────────────────────────────
myzsh-info() {
  cat <<'EOF'
  ╔══════════════════════════════════════╗
  ║            myzsh v1.0.0             ║
  ╠══════════════════════════════════════╣
  ║  A minimalist, secure, decorative   ║
  ║  zsh framework built for speed.     ║
  ╚══════════════════════════════════════╝
EOF
  echo ""
  echo "  Theme:     ${MYZSH_THEME:-powerline}"
  echo "  Plugins:   ${(j:, :)MYZSH_PLUGINS}"
  echo "  Aliases:   ${(j:, :)MYZSH_ALIASES}"
  echo "  Defer:     ${MYZSH_DEFER:-true}"
  echo "  Security:  ${MYZSH_VERIFY_PLUGINS:-true}"
  echo ""
}

# ─── Myzsh Update ────────────────────────────────────────────────────
myzsh-update() {
  echo "🔄 Updating myzsh..."
  echo ""

  # Pull latest framework
  echo "  ▸ Pulling latest changes..."
  if git -C "$MYZSH_DIR" pull --ff-only 2>&1 | sed 's/^/    /'; then
    echo "  ✓ Framework updated"
  else
    echo "  ✗ Pull failed (you may have local changes)" >&2
    echo "    Run: cd ~/.myzsh && git stash && git pull && git stash pop" >&2
    return 1
  fi

  echo ""

  # Update submodules
  echo "  ▸ Updating plugins..."
  git -C "$MYZSH_DIR" submodule update --init --recursive 2>&1 | sed 's/^/    /'
  echo "  ✓ Plugins updated"

  echo ""

  # Regenerate lockfile
  echo "  ▸ Regenerating lockfile..."
  myzsh-update-lock 2>&1 | sed 's/^/    /'

  echo ""
  echo "✓ Update complete. Run 'reload' to apply."
}
