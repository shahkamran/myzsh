#!/usr/bin/env zsh
# ╔══════════════════════════════════════════════════════════════════════╗
# ║  myzsh :: powerline theme                                          ║
# ║  Rich, decorative prompt with git info, icons, and transparency    ║
# ╚══════════════════════════════════════════════════════════════════════╝

# ─── Nerd Font Icons ──────────────────────────────────────────────────
if [[ "$MYZSH_NERD_FONTS" == "true" ]]; then
  local ICON_BRANCH=""       # git branch
  local ICON_DIRTY="✗"
  local ICON_CLEAN="✓"
  local ICON_AHEAD="⇡"
  local ICON_BEHIND="⇣"
  local ICON_STASH=""
  local ICON_FOLDER=""
  local ICON_HOME=""
  local ICON_CLOCK=""
  local ICON_CMD="❯"
  local ICON_ROOT="#"
  local ICON_SSH=""
  local ICON_ARROW=""       # powerline separator
  local ICON_ARROW_THIN="" # thin separator
else
  local ICON_BRANCH="⎇"
  local ICON_DIRTY="×"
  local ICON_CLEAN="✓"
  local ICON_AHEAD="↑"
  local ICON_BEHIND="↓"
  local ICON_STASH="≡"
  local ICON_FOLDER="📁"
  local ICON_HOME="~"
  local ICON_CLOCK="⏱"
  local ICON_CMD="❯"
  local ICON_ROOT="#"
  local ICON_SSH="SSH"
  local ICON_ARROW="▶"
  local ICON_ARROW_THIN="│"
fi

# ─── Colour Palette ──────────────────────────────────────────────────
# Transparency-aware: uses foreground colours heavily
# so background blur/transparency in terminal shines through

if [[ "$MYZSH_TRANSPARENT" == "true" ]]; then
  # Transparent mode: minimal backgrounds, vibrant foregrounds
  local C_USER="%F{cyan}"
  local C_HOST="%F{blue}"
  local C_DIR="%F{magenta}"
  local C_GIT_CLEAN="%F{green}"
  local C_GIT_DIRTY="%F{yellow}"
  local C_TIME="%F{240}"
  local C_CMD_OK="%F{green}"
  local C_CMD_FAIL="%F{red}"
  local C_EXEC_TIME="%F{yellow}"
  local C_VENV="%F{cyan}"
  local C_RESET="%f"
  local C_BG=""
  local SEP_STYLE="thin"  # use thin separators for transparency
else
  # Opaque mode: full powerline segments with backgrounds
  local C_USER="%F{white}%K{24}"   # dark blue bg
  local C_HOST="%F{white}%K{24}"
  local C_DIR="%F{white}%K{54}"    # purple bg
  local C_GIT_CLEAN="%F{black}%K{green}"
  local C_GIT_DIRTY="%F{black}%K{yellow}"
  local C_TIME="%F{white}%K{236}"  # dark grey bg
  local C_CMD_OK="%F{green}"
  local C_CMD_FAIL="%F{red}"
  local C_EXEC_TIME="%F{yellow}%K{236}"
  local C_VENV="%F{white}%K{cyan}"
  local C_RESET="%f%k"
  local C_BG="%k"
  local SEP_STYLE="full"
fi

# ─── Git Status Function ─────────────────────────────────────────────
_myzsh_git_info() {
  # Fast check: are we in a git repo?
  local git_dir
  git_dir=$(git rev-parse --git-dir 2>/dev/null) || return

  local branch
  branch=$(git symbolic-ref --short HEAD 2>/dev/null || git describe --tags --exact-match 2>/dev/null || git rev-parse --short HEAD 2>/dev/null)

  local status_flags=""
  local git_status
  git_status=$(git status --porcelain=v1 2>/dev/null)

  if [[ -n "$git_status" ]]; then
    status_flags=" ${ICON_DIRTY}"
    local colour="${C_GIT_DIRTY}"
  else
    status_flags=" ${ICON_CLEAN}"
    local colour="${C_GIT_CLEAN}"
  fi

  # Ahead/behind
  local ahead behind
  ahead=$(git rev-list --count @{upstream}..HEAD 2>/dev/null)
  behind=$(git rev-list --count HEAD..@{upstream} 2>/dev/null)
  [[ "$ahead" -gt 0 ]] && status_flags+=" ${ICON_AHEAD}${ahead}"
  [[ "$behind" -gt 0 ]] && status_flags+=" ${ICON_BEHIND}${behind}"

  # Stash
  if git stash list 2>/dev/null | head -1 &>/dev/null; then
    local stash_count
    stash_count=$(git stash list 2>/dev/null | wc -l | tr -d ' ')
    [[ "$stash_count" -gt 0 ]] && status_flags+=" ${ICON_STASH}${stash_count}"
  fi

  echo "${colour} ${ICON_BRANCH} ${branch}${status_flags} ${C_RESET}"
}

# ─── Execution Time Tracking ─────────────────────────────────────────
typeset -g _myzsh_cmd_start=0

_myzsh_preexec() {
  _myzsh_cmd_start=$EPOCHSECONDS
}

_myzsh_precmd_time() {
  if (( _myzsh_cmd_start > 0 )); then
    local elapsed=$(( EPOCHSECONDS - _myzsh_cmd_start ))
    _myzsh_cmd_start=0

    if (( elapsed >= ${MYZSH_EXEC_TIME_THRESHOLD:-3} )); then
      local hours mins secs
      hours=$(( elapsed / 3600 ))
      mins=$(( (elapsed % 3600) / 60 ))
      secs=$(( elapsed % 60 ))

      if (( hours > 0 )); then
        _myzsh_exec_time="${hours}h${mins}m${secs}s"
      elif (( mins > 0 )); then
        _myzsh_exec_time="${mins}m${secs}s"
      else
        _myzsh_exec_time="${secs}s"
      fi
    else
      _myzsh_exec_time=""
    fi
  else
    _myzsh_exec_time=""
  fi
}

zmodload zsh/datetime
autoload -Uz add-zsh-hook
add-zsh-hook preexec _myzsh_preexec
add-zsh-hook precmd _myzsh_precmd_time

# ─── Virtual Environment Indicator ────────────────────────────────────
_myzsh_venv_info() {
  if [[ -n "$VIRTUAL_ENV" ]]; then
    echo "${C_VENV} $(basename $VIRTUAL_ENV) ${C_RESET}"
  fi
}

# ─── SSH Indicator ────────────────────────────────────────────────────
_myzsh_ssh_info() {
  if [[ -n "$SSH_CONNECTION" ]]; then
    echo "${C_USER}${ICON_SSH} ${C_RESET}"
  fi
}

# ─── Build the Prompt ─────────────────────────────────────────────────
_myzsh_build_prompt() {
  local exit_code="$?"
  local prompt_parts=""

  # Top line decoration
  prompt_parts+="${C_TIME}╭─${C_RESET}"

  # SSH indicator
  prompt_parts+="$(_myzsh_ssh_info)"

  # User@host (only show host if SSH or if configured)
  if [[ -n "$SSH_CONNECTION" ]]; then
    prompt_parts+="${C_USER} %n${C_RESET}${C_HOST}@%m ${C_RESET}"
  else
    prompt_parts+="${C_USER} %n ${C_RESET}"
  fi

  # Separator
  if [[ "$SEP_STYLE" == "thin" ]]; then
    prompt_parts+="${C_TIME}${ICON_ARROW_THIN}${C_RESET} "
  fi

  # Directory (shortened)
  prompt_parts+="${C_DIR} ${ICON_FOLDER} %3~ ${C_RESET}"

  # Git info
  if [[ "$MYZSH_SHOW_GIT" == "true" ]]; then
    local git_info="$(_myzsh_git_info)"
    if [[ -n "$git_info" ]]; then
      if [[ "$SEP_STYLE" == "thin" ]]; then
        prompt_parts+="${C_TIME}${ICON_ARROW_THIN}${C_RESET}"
      fi
      prompt_parts+="${git_info}"
    fi
  fi

  # Virtual env
  prompt_parts+="$(_myzsh_venv_info)"

  # Newline + command prompt
  prompt_parts+=$'\n'
  prompt_parts+="${C_TIME}╰─${C_RESET}"

  # Command indicator (green/red based on last exit code)
  if [[ "$exit_code" -eq 0 ]]; then
    prompt_parts+="${C_CMD_OK}${ICON_CMD}${C_RESET} "
  else
    prompt_parts+="${C_CMD_FAIL}${ICON_CMD}${C_RESET} "
  fi

  echo -n "$prompt_parts"
}

# ─── Right Prompt ─────────────────────────────────────────────────────
_myzsh_build_rprompt() {
  local parts=""

  # Execution time
  if [[ -n "$_myzsh_exec_time" && "$MYZSH_SHOW_EXEC_TIME" == "true" ]]; then
    parts+="${C_EXEC_TIME}${ICON_CLOCK} ${_myzsh_exec_time}${C_RESET}"
  fi

  # Timestamp
  parts+=" ${C_TIME}%T${C_RESET}"

  echo -n "$parts"
}

# ─── Set Prompts ──────────────────────────────────────────────────────
setopt PROMPT_SUBST
PROMPT='$(_myzsh_build_prompt)'
RPROMPT='$(_myzsh_build_rprompt)'

# ─── Continuation Prompt ──────────────────────────────────────────────
PROMPT2="${C_TIME}  ╰─ ${C_CMD_OK}…${C_RESET} "

# ─── Terminal Title ───────────────────────────────────────────────────
_myzsh_set_title() {
  print -Pn "\e]0;%~ - %n\a"
}
add-zsh-hook precmd _myzsh_set_title

# ─── Welcome Message ─────────────────────────────────────────────────
if [[ "$MYZSH_TRANSPARENT" == "true" ]]; then
  # Subtle welcome for transparent terminals
  print -P "%F{240}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━%f"
  print -P "%F{cyan}  ⚡ myzsh%f %F{240}:: fast • secure • beautiful%f"
  print -P "%F{240}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━%f"
else
  print -P "%F{cyan}╔══════════════════════════════════════════════╗%f"
  print -P "%F{cyan}║%f  ⚡ %F{white}myzsh%f %F{240}:: fast • secure • beautiful%f  %F{cyan}║%f"
  print -P "%F{cyan}╚══════════════════════════════════════════════╝%f"
fi
