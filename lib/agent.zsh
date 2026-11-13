#!/usr/bin/env zsh
# ╔══════════════════════════════════════════════════════════════════════╗
# ║  myzsh :: agent                                                    ║
# ║  Detect IDE / AI-agent / non-interactive shells → lean agent mode  ║
# ╚══════════════════════════════════════════════════════════════════════╝
#
# Agent mode loads only what is safe for tools that drive the shell
# programmatically: no theme, plugins, deferred loading, banners,
# spelling-correction prompts or interactive cp/mv/rm aliases.
#
# Overrides:
#   MYZSH_FORCE_INTERACTIVE=1  always load the full framework
#   MYZSH_AGENT_MODE=1         always use agent mode

_myzsh_detect_agent() {
  # 1. Explicit opt-out wins over everything
  if [[ -n "$MYZSH_FORCE_INTERACTIVE" ]]; then
    unset MYZSH_AGENT_MODE
    return 1
  fi

  # 2. Explicit opt-in
  if [[ "$MYZSH_AGENT_MODE" == (1|true) ]]; then
    typeset -g MYZSH_AGENT_MODE=1
    return 0
  fi
  unset MYZSH_AGENT_MODE

  local why=""
  # 3. Not a real interactive terminal (zsh -ic from a tool, piped stdin)
  if [[ ! -o interactive || ! -t 0 || ! -t 1 || "$TERM" == dumb ]]; then
    why=notty
  # 4. IDE terminals with shell integration (Kiro, VS Code, Cursor, Windsurf)
  elif [[ "$TERM_PROGRAM" == (vscode|kiro) ]]; then
    why=ide
  # 5. Known AI-agent environment markers
  elif [[ -n "${KIRO_SESSION_ID}${CLAUDECODE}${CURSOR_AGENT}${GEMINI_CLI}${CODEX_SANDBOX}" ]]; then
    why=env
  else
    # 6. Spawned directly by an agent CLI (e.g. Kiro CLI running zsh -i)
    local parent
    parent=$(ps -o comm= -p "$PPID" 2>/dev/null)
    parent="${${parent##*/}#-}"
    if [[ "$parent" == (kiro-cli*|q|qchat|claude|codex|cursor-agent|gemini|aider) ]]; then
      why=parent
    fi
  fi

  [[ -n "$why" ]] || return 1
  typeset -g MYZSH_AGENT_MODE=1 MYZSH_AGENT_REASON="$why"
  return 0
}
