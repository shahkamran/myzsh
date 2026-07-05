#!/usr/bin/env zsh
# ╔══════════════════════════════════════════════════════════════════════╗
# ║                            myzsh                                   ║
# ║         A minimalist, secure, decorative zsh framework             ║
# ╚══════════════════════════════════════════════════════════════════════╝

# ─── Benchmark (if enabled) ───────────────────────────────────────────
[[ "$MYZSH_BENCHMARK" == "true" ]] && zmodload zsh/zprof

# ─── Core Paths ───────────────────────────────────────────────────────
export MYZSH_DIR="${MYZSH_DIR:-${HOME}/.myzsh}"
export MYZSH_CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/myzsh"
export MYZSH_DATA="${XDG_DATA_HOME:-$HOME/.local/share}/myzsh"

# Create cache/data dirs if missing
[[ -d "$MYZSH_CACHE" ]] || mkdir -p "$MYZSH_CACHE"
[[ -d "$MYZSH_DATA" ]]  || mkdir -p "$MYZSH_DATA"

# ─── Load Configuration ──────────────────────────────────────────────
[[ -f "$MYZSH_DIR/myzsh.conf" ]] && source "$MYZSH_DIR/myzsh.conf"

# ─── Core Modules (loaded immediately) ───────────────────────────────
# Order matters: security first, then init, then the rest
local -a core_modules=(
  "security"
  "init"
  "history"
  "keybindings"
)

for module in "${core_modules[@]}"; do
  local module_file="$MYZSH_DIR/lib/${module}.zsh"
  if [[ -f "$module_file" ]]; then
    source "$module_file"
  fi
done

# ─── Theme (loaded before prompt) ────────────────────────────────────
local theme_file="$MYZSH_DIR/themes/${MYZSH_THEME:-powerline}/${MYZSH_THEME:-powerline}.zsh-theme"
if [[ -f "$theme_file" ]]; then
  source "$theme_file"
fi

# ─── Completion (after theme, before plugins) ─────────────────────────
if [[ -f "$MYZSH_DIR/lib/completion.zsh" ]]; then
  source "$MYZSH_DIR/lib/completion.zsh"
fi

# ─── Aliases ──────────────────────────────────────────────────────────
if (( ${#MYZSH_ALIASES[@]} )); then
  for alias_group in "${MYZSH_ALIASES[@]}"; do
    local alias_file="$MYZSH_DIR/aliases/${alias_group}.zsh"
    [[ -f "$alias_file" ]] && source "$alias_file"
  done
fi

# ─── Functions (autoloaded) ───────────────────────────────────────────
if [[ -d "$MYZSH_DIR/functions" ]]; then
  fpath=("$MYZSH_DIR/functions" $fpath)
  for func in "$MYZSH_DIR"/functions/*(.N); do
    autoload -Uz "${func:t}"
  done
fi

# ─── Deferred Loading (plugins loaded after prompt) ───────────────────
if [[ "$MYZSH_DEFER" == "true" ]] && [[ -f "$MYZSH_DIR/lib/defer.zsh" ]]; then
  source "$MYZSH_DIR/lib/defer.zsh"

  # Defer plugin loading for fast startup
  for plugin_name in "${MYZSH_PLUGINS[@]}"; do
    local plugin_file="$MYZSH_DIR/plugins/${plugin_name}/${plugin_name}.plugin.zsh"
    if [[ -f "$plugin_file" ]]; then
      myzsh-defer source "$plugin_file"
    fi
  done

  # Add completions to fpath (deferred)
  if [[ -d "$MYZSH_DIR/plugins/zsh-completions/src" ]]; then
    myzsh-defer fpath=("$MYZSH_DIR/plugins/zsh-completions/src" $fpath)
  fi
else
  # Fallback: load plugins immediately
  for plugin_name in "${MYZSH_PLUGINS[@]}"; do
    local plugin_file="$MYZSH_DIR/plugins/${plugin_name}/${plugin_name}.plugin.zsh"
    if [[ -f "$plugin_file" ]]; then
      source "$plugin_file"
    fi
  done
fi

# ─── Local Overrides (not tracked by git) ─────────────────────────────
[[ -f "$MYZSH_DIR/local.zsh" ]] && source "$MYZSH_DIR/local.zsh"

# ─── Benchmark Results ────────────────────────────────────────────────
if [[ "$MYZSH_BENCHMARK" == "true" ]]; then
  zprof
fi
