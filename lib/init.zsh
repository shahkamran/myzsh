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
setopt CORRECT              # spelling correction for commands
setopt EXTENDED_GLOB        # advanced globbing
setopt NO_BEEP              # silence terminal beeps
setopt INTERACTIVE_COMMENTS # allow comments in interactive shell
setopt MULTIOS              # multiple redirections
setopt PROMPT_SUBST         # enable prompt substitution
setopt LONG_LIST_JOBS       # display PID when suspending processes

# ─── Path Configuration ──────────────────────────────────────────────
typeset -U path  # deduplicate

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
export LESS="-R --mouse --wheel-lines=3"

# ─── Locale ───────────────────────────────────────────────────────────
export LANG="${LANG:-en_US.UTF-8}"
export LC_ALL="${LC_ALL:-en_US.UTF-8}"

# ─── Colour Support ──────────────────────────────────────────────────
autoload -Uz colors && colors

if [[ "$TERM" != "dumb" ]]; then
  export TERM="${TERM:-xterm-256color}"
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
