#!/usr/bin/env zsh
# ╔══════════════════════════════════════════════════════════════════════╗
# ║  myzsh :: aliases/system                                           ║
# ║  System, file management, and process aliases                       ║
# ╚══════════════════════════════════════════════════════════════════════╝

# ─── File Listing (colourful) ─────────────────────────────────────────
if command -v eza &>/dev/null; then
  alias ls='eza --icons --group-directories-first'
  alias ll='eza -lahF --icons --group-directories-first --git'
  alias la='eza -a --icons --group-directories-first'
  alias lt='eza --tree --icons --level=2'
  alias lta='eza --tree --icons --level=3 -a'
elif command -v exa &>/dev/null; then
  alias ls='exa --icons --group-directories-first'
  alias ll='exa -lahF --icons --group-directories-first --git'
  alias la='exa -a --icons --group-directories-first'
  alias lt='exa --tree --icons --level=2'
else
  alias ls='ls --color=auto'
  alias ll='ls -lahF --color=auto'
  alias la='ls -A --color=auto'
fi

# ─── File Operations (safe) ───────────────────────────────────────────
# Interactive -i prompts ("overwrite …? (y/n)") hang AI agents and IDE
# tools, so these are for human terminals only (see lib/agent.zsh)
if [[ -z "$MYZSH_AGENT_MODE" ]]; then
  alias cp='cp -iv'
  alias mv='mv -iv'
  alias rm='rm -iv'
  alias mkdir='mkdir -pv'
fi

# ─── Disk & Memory ───────────────────────────────────────────────────
alias df='df -h'
alias du='du -h'
alias free='free -h 2>/dev/null || vm_stat'
alias disk='df -h | head -8'

# ─── Process Management ──────────────────────────────────────────────
alias psg='ps aux | grep -v grep | grep'
alias top10='ps aux | head -1; ps aux | sed 1d | sort -nr -k 4 | head -10'
alias ports='lsof -i -n -P | grep LISTEN'
alias myip='curl -s https://ifconfig.me && echo'
alias localip='ipconfig getifaddr en0 2>/dev/null || hostname -I 2>/dev/null'

# ─── Search ──────────────────────────────────────────────────────────
# grep→rg changes option semantics; agents expect real grep
if [[ -z "$MYZSH_AGENT_MODE" ]]; then
  if command -v rg &>/dev/null; then
    alias grep='rg'
  else
    alias grep='grep --color=auto'
  fi
fi
alias findi='find . -iname'

# ─── System Info ──────────────────────────────────────────────────────
alias path='echo $PATH | tr ":" "\n" | sort | uniq'
alias now='date +"%Y-%m-%d %H:%M:%S"'
alias week='date +%V'
alias weather='curl -s "wttr.in/?format=3"'

# ─── Clipboard ───────────────────────────────────────────────────────
if [[ "$(uname)" == "Darwin" ]]; then
  alias clip='pbcopy'
  alias paste='pbpaste'
else
  alias clip='xclip -selection clipboard'
  alias paste='xclip -selection clipboard -o'
fi

# ─── Quick Edit ───────────────────────────────────────────────────────
alias zshrc='${EDITOR} ${MYZSH_DIR}/zshrc'
alias myzshconf='${EDITOR} ${MYZSH_DIR}/myzsh.conf'
