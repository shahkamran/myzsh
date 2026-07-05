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

# Create cache/data dirs with restrictive permissions
[[ -d "$MYZSH_CACHE" ]] || mkdir -p -m 700 "$MYZSH_CACHE"
[[ -d "$MYZSH_DATA" ]]  || mkdir -p -m 700 "$MYZSH_DATA"

# ─── Load Security First (bootstrap) ─────────────────────────────────
# Security module must load before anything else
if [[ -f "$MYZSH_DIR/lib/security.zsh" ]]; then
  source "$MYZSH_DIR/lib/security.zsh"
fi

# ─── Load Configuration (with ownership check) ───────────────────────
if [[ -f "$MYZSH_DIR/myzsh.conf" ]]; then
  myzsh-safe-source "$MYZSH_DIR/myzsh.conf" true
fi

# ─── Validate Config Values (prevent path traversal) ─────────────────
# Theme name must be alphanumeric/dash/underscore only
if [[ -n "$MYZSH_THEME" && "$MYZSH_THEME" =~ [^a-zA-Z0-9_-] ]]; then
  echo "⚠️  myzsh: invalid theme name '${MYZSH_THEME}', falling back to powerline" >&2
  MYZSH_THEME="powerline"
fi

# Alias group names must be alphanumeric/dash/underscore only
local -a _validated_aliases=()
for _ag in "${MYZSH_ALIASES[@]}"; do
  if [[ "$_ag" =~ [^a-zA-Z0-9_-] ]]; then
    echo "⚠️  myzsh: invalid alias group '${_ag}', skipping" >&2
  else
    _validated_aliases+=("$_ag")
  fi
done
MYZSH_ALIASES=("${_validated_aliases[@]}")
unset _validated_aliases _ag

# ─── Core Modules (loaded immediately) ───────────────────────────────
# Security already loaded above; load remaining core modules
local -a core_modules=(
  "init"
  "history"
  "keybindings"
)

for module in "${core_modules[@]}"; do
  local module_file="$MYZSH_DIR/lib/${module}.zsh"
  if [[ -f "$module_file" ]]; then
    myzsh-safe-source "$module_file" true
  fi
done

# ─── Theme (loaded before prompt) ────────────────────────────────────
local theme_file="$MYZSH_DIR/themes/${MYZSH_THEME:-powerline}/${MYZSH_THEME:-powerline}.zsh-theme"
if [[ -f "$theme_file" ]]; then
  myzsh-safe-source "$theme_file"
fi

# ─── Completion (after theme, before plugins) ─────────────────────────
if [[ -f "$MYZSH_DIR/lib/completion.zsh" ]]; then
  myzsh-safe-source "$MYZSH_DIR/lib/completion.zsh" true
fi

# ─── Aliases ──────────────────────────────────────────────────────────
if (( ${#MYZSH_ALIASES[@]} )); then
  for alias_group in "${MYZSH_ALIASES[@]}"; do
    local alias_file="$MYZSH_DIR/aliases/${alias_group}.zsh"
    if [[ -f "$alias_file" ]]; then
      myzsh-safe-source "$alias_file" true
    fi
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

  # Defer plugin loading with security verification
  for plugin_name in "${MYZSH_PLUGINS[@]}"; do
    # Validate plugin name
    if [[ "$plugin_name" =~ [^a-zA-Z0-9_-] ]]; then
      echo "⚠️  myzsh: invalid plugin name '${plugin_name}', skipping" >&2
      continue
    fi
    local plugin_file="$MYZSH_DIR/plugins/${plugin_name}/${plugin_name}.plugin.zsh"
    if [[ -f "$plugin_file" ]]; then
      myzsh-defer "myzsh-safe-source '$plugin_file'"
    fi
  done

  # Add completions to fpath (deferred)
  if [[ -d "$MYZSH_DIR/plugins/zsh-completions/src" ]]; then
    myzsh-defer 'fpath=("'"$MYZSH_DIR"'/plugins/zsh-completions/src" $fpath)'
  fi
else
  # Fallback: load plugins immediately with security checks
  for plugin_name in "${MYZSH_PLUGINS[@]}"; do
    if [[ "$plugin_name" =~ [^a-zA-Z0-9_-] ]]; then
      echo "⚠️  myzsh: invalid plugin name '${plugin_name}', skipping" >&2
      continue
    fi
    local plugin_file="$MYZSH_DIR/plugins/${plugin_name}/${plugin_name}.plugin.zsh"
    if [[ -f "$plugin_file" ]]; then
      myzsh-safe-source "$plugin_file"
    fi
  done
fi

# ─── Local Overrides (ownership/permission checked, no checksum) ──────
if [[ -f "$MYZSH_DIR/local.zsh" ]]; then
  myzsh-safe-source "$MYZSH_DIR/local.zsh" true
fi

# ─── History File Permissions ─────────────────────────────────────────
[[ -f "${MYZSH_DATA}/history" ]] && chmod 600 "${MYZSH_DATA}/history" 2>/dev/null

# ─── Benchmark Results ────────────────────────────────────────────────
if [[ "$MYZSH_BENCHMARK" == "true" ]]; then
  zprof
fi
