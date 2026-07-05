#!/usr/bin/env zsh
# ╔══════════════════════════════════════════════════════════════════════╗
# ║  myzsh :: completion                                               ║
# ║  Rich tab completion with fuzzy matching and decorations           ║
# ╚══════════════════════════════════════════════════════════════════════╝

# ─── Completion Cache ─────────────────────────────────────────────────
local zcompdump="$MYZSH_CACHE/zcompdump"
autoload -Uz compinit

# Only regenerate once a day for speed
if [[ -f "$zcompdump" ]] && [[ $(date +'%j') == $(date -r "$zcompdump" +'%j' 2>/dev/null) ]]; then
  compinit -C -d "$zcompdump"
else
  compinit -d "$zcompdump"
fi

# ─── Completion Options ───────────────────────────────────────────────
setopt COMPLETE_IN_WORD
setopt ALWAYS_TO_END
setopt AUTO_MENU
setopt AUTO_LIST
setopt AUTO_PARAM_SLASH
setopt NO_MENU_COMPLETE

# ─── Completion Styling ───────────────────────────────────────────────
zstyle ':completion:*' group-name ''
zstyle ':completion:*:descriptions' format '%F{yellow}── %d ──%f'
zstyle ':completion:*:corrections' format '%F{green}── %d (errors: %e) ──%f'
zstyle ':completion:*:messages' format '%F{purple}── %d ──%f'
zstyle ':completion:*:warnings' format '%F{red}── no matches found ──%f'

# Coloured completion lists
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' list-prompt '%SAt %p: Hit TAB for more%s'

# Menu selection with highlighting
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
zstyle ':completion:*:kill:*' command 'ps -u $USER -o pid,%cpu,tty,cputime,cmd'

# Directories
zstyle ':completion:*' squeeze-slashes true
zstyle ':completion:*:cd:*' tag-order local-directories directory-stack path-directories

# Man pages
zstyle ':completion:*:manuals' separate-sections true
zstyle ':completion:*:manuals.(^1*)' insert-sections true

# ─── Tab Completion Key Bindings ──────────────────────────────────────
bindkey '^[[Z' reverse-menu-complete  # Shift-Tab goes backwards

zmodload zsh/complist
bindkey -M menuselect '^o' accept-and-infer-next-history
