#!/usr/bin/env zsh
# ╔══════════════════════════════════════════════════════════════════════╗
# ║  myzsh :: completion                                               ║
# ║  Rich tab completion with fuzzy matching and decorations           ║
# ╚══════════════════════════════════════════════════════════════════════╝

# ─── Completion Cache ─────────────────────────────────────────────────
local zcompdump="$MYZSH_CACHE/zcompdump"
autoload -Uz compinit

# Only regenerate once a day for speed
if [[ -f "$zcompdump" ]]; then
  local today=$(date +'%j')
  local file_day
  # macOS: date -r <file>, Linux: stat -c '%Y' + date -d
  file_day=$(date -r "$zcompdump" +'%j' 2>/dev/null || \
    date -d @"$(stat -c '%Y' "$zcompdump" 2>/dev/null)" +'%j' 2>/dev/null)
  if [[ "$today" == "$file_day" ]]; then
    compinit -C -i -d "$zcompdump"
  else
    compinit -i -d "$zcompdump"
  fi
else
  compinit -i -d "$zcompdump"
fi

# ─── Completion Options ───────────────────────────────────────────────
setopt COMPLETE_IN_WORD
setopt ALWAYS_TO_END
setopt AUTO_MENU            # Enable menu completion
setopt AUTO_LIST            # Show list on ambiguous completion
setopt AUTO_PARAM_SLASH

# ─── Completion Styling ───────────────────────────────────────────────
zstyle ':completion:*' group-name ''
zstyle ':completion:*:descriptions' format '%F{yellow}── %d ──%f'
zstyle ':completion:*:corrections' format '%F{green}── %d (errors: %e) ──%f'
zstyle ':completion:*:messages' format '%F{purple}── %d ──%f'
zstyle ':completion:*:warnings' format '%F{red}── no matches found ──%f'

# Coloured completion lists
if [[ -n "$LS_COLORS" ]]; then
  zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
else
  zstyle ':completion:*' list-colors ''
fi
zstyle ':completion:*' list-prompt '%SAt %p: Hit TAB for more%s'

# Menu selection — show menu and allow arrow navigation
zstyle ':completion:*' menu select
zstyle ':completion:*' select-prompt '%SScrolling: %p%s'

# ─── Fuzzy Matching ──────────────────────────────────────────────────
if [[ "$MYZSH_FUZZY_COMPLETION" == "true" ]]; then
  zstyle ':completion:*' completer _complete _match _approximate
  zstyle ':completion:*:match:*' original only
  zstyle ':completion:*:approximate:*' max-errors 1 numeric
fi

# ─── Case-Insensitive Matching ────────────────────────────────────────
if [[ "$MYZSH_CASE_INSENSITIVE" == "true" ]]; then
  zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|=*' 'l:|=* r:|=*'
fi

# ─── Completion Categories ────────────────────────────────────────────
# Processes
zstyle ':completion:*:*:kill:*' menu yes select
zstyle ':completion:*:kill:*' force-list always
zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#)*=0=01;31'
zstyle ':completion:*:kill:*' command 'ps -u $USER -o pid,%cpu,tty,time,command'

# Directories
zstyle ':completion:*' squeeze-slashes true
zstyle ':completion:*:cd:*' tag-order local-directories directory-stack path-directories

# Man pages
zstyle ':completion:*:manuals' separate-sections true
zstyle ':completion:*:manuals.(^1*)' insert-sections true

# ─── Tab Completion Key Bindings ──────────────────────────────────────
# Tab keeps zsh's default expand-or-complete: with `menu select` above it
# opens the menu on the second Tab and edits the current word in place.
zmodload zsh/complist

bindkey '^[[Z'  reverse-menu-complete       # Shift-Tab: previous match

# Menu selection navigation (when inside the completion menu)
# Tab must be menu-complete (cycles in place). accept-and-menu-complete
# would insert each match as a new word: "cd a b a b".
bindkey -M menuselect '^I'   menu-complete              # Tab cycles forward in menu
bindkey -M menuselect '^[[Z' reverse-menu-complete      # Shift-Tab cycles backward
bindkey -M menuselect '^[[A' up-line-or-history         # Up arrow in menu
bindkey -M menuselect '^[[B' down-line-or-history       # Down arrow in menu
bindkey -M menuselect '^[[C' forward-char               # Right arrow in menu
bindkey -M menuselect '^[[D' backward-char              # Left arrow in menu
bindkey -M menuselect '^[OA' up-line-or-history         # Up (application mode)
bindkey -M menuselect '^[OB' down-line-or-history       # Down (application mode)
bindkey -M menuselect '^[OC' forward-char               # Right (application mode)
bindkey -M menuselect '^[OD' backward-char              # Left (application mode)
bindkey -M menuselect '^M'  .accept-line                # Return accepts and runs
bindkey -M menuselect '^o'  accept-and-infer-next-history  # Ctrl+O accepts and drills in
# No binding for a bare ESC: it would make ESC a prefix key and break
# arrow keys whose bytes arrive split. Ctrl+G cancels the menu.
