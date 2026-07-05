#!/usr/bin/env zsh
# ╔══════════════════════════════════════════════════════════════════════╗
# ║  myzsh :: pure theme                                               ║
# ║  Inspired by sindresorhus/pure — async git, minimal noise          ║
# ╚══════════════════════════════════════════════════════════════════════╝

_myzsh_pure_git() {
  local branch
  branch=$(git symbolic-ref --short HEAD 2>/dev/null || git describe --tags --exact-match 2>/dev/null) || return
  local dirty=""
  [[ -n $(git status --porcelain 2>/dev/null) ]] && dirty=" %F{red}✗%f"
  echo "%F{242}${branch}%f${dirty}"
}

typeset -g _myzsh_pure_exec_time=""
typeset -g _myzsh_pure_start=0

_myzsh_pure_preexec() { _myzsh_pure_start=$EPOCHSECONDS; }
_myzsh_pure_precmd() {
  if (( _myzsh_pure_start > 0 )); then
    local e=$(( EPOCHSECONDS - _myzsh_pure_start ))
    _myzsh_pure_start=0
    (( e >= 3 )) && _myzsh_pure_exec_time=" %F{yellow}${e}s%f" || _myzsh_pure_exec_time=""
  fi
}

zmodload zsh/datetime
autoload -Uz add-zsh-hook
add-zsh-hook preexec _myzsh_pure_preexec
add-zsh-hook precmd _myzsh_pure_precmd

setopt PROMPT_SUBST

# Two-line prompt: path + git on line 1, arrow on line 2
PROMPT=$'\n''%F{blue}%~%f $(_myzsh_pure_git)${_myzsh_pure_exec_time}'$'\n''%(?.%F{magenta}.%F{red})❯%f '
RPROMPT=''
PROMPT2='%F{242}  ⋮ %f'
