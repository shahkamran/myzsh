#!/usr/bin/env zsh
# ╔══════════════════════════════════════════════════════════════════════╗
# ║  myzsh :: tests/harness                                            ║
# ║  zpty helpers: drive a real interactive zsh with myzsh loaded      ║
# ╚══════════════════════════════════════════════════════════════════════╝
#
# Every test runs against a throwaway copy of the framework with its own
# ZDOTDIR, cache and data dirs, so the user's real shell is never touched.

zmodload zsh/zpty zsh/datetime

typeset -g  T_ROOT="" T_DIR="" T_OUT="" T_SRC=""
typeset -gi T_PASS=0 T_FAIL=0 T_SKIP=0
typeset -g  T_PATH="/usr/bin:/bin:/usr/sbin:/sbin"
[[ -d /opt/homebrew/bin ]] && T_PATH="$T_PATH:/opt/homebrew/bin"
typeset -g  T_KIRO_RC=""
typeset -ga T_FAILED=()
# The zsh under test, and a UTF-8 locale this host really has (many Linux
# images only generate C.UTF-8); empty T_UTF8 means none, width checks skip
typeset -g  T_ZSH=/bin/zsh T_UTF8=""
[[ -x "$T_ZSH" ]] || T_ZSH="${commands[zsh]:-zsh}"
() {
  local l
  for l in en_US.UTF-8 C.UTF-8 C.utf8 ${(M)${(f)"$(locale -a 2>/dev/null)"}:#*[Uu][Tt][Ff]*8}; do
    LC_ALL="$l" "$T_ZSH" -fc '(( ${#${:-━}} == 1 ))' 2>/dev/null && { T_UTF8="$l"; return; }
  done
}

# ─── Results ─────────────────────────────────────────────────────────
t_pass() { (( T_PASS++ )); print -r -- "PASS  $1"; }
t_fail() {
  (( T_FAIL++ )); T_FAILED+=("$1")
  print -r -- "FAIL  $1"
  [[ -n "$2" ]] && print -r -- "$2" | sed 's/^/        | /' | head -n 25
}
t_skip() { (( T_SKIP++ )); print -r -- "SKIP  $1${2:+ ($2)}"; }
# t_check <name> <0|1 result> [detail]
t_check() { if (( $2 == 0 )); then t_pass "$1"; else t_fail "$1" "$3"; fi; }

t_finish() {
  print -r -- ""
  print -r -- "Summary: ${T_PASS} passed, ${T_FAIL} failed, ${T_SKIP} skipped"
  (( T_FAIL )) && print -rl -- "Failed:" "${T_FAILED[@]/#/  - }"
  [[ -n "$T_ROOT" && "$T_ROOT" == /tmp/myzsh-test.* && -z "$MYZSH_TEST_KEEP" ]] && /bin/rm -rf "$T_ROOT"
  (( T_FAIL == 0 ))
}

# ─── Sandbox ─────────────────────────────────────────────────────────
# t_prepare <src>: copy a myzsh tree into a sandbox with its own ZDOTDIRs
t_prepare() {
  T_SRC="${1:A}"
  T_ROOT=$(mktemp -d /tmp/myzsh-test.XXXXXX) || return 1
  T_DIR="$T_ROOT/myzsh"
  /bin/cp -Rp "$T_SRC" "$T_DIR"
  /bin/rm -rf "$T_DIR/.git" "$T_DIR/.agents" "$T_DIR/myzsh.lock" "$T_DIR/local.zsh"

  # Plugin submodules may not be checked out in a dev clone: borrow them
  local p from="${MYZSH_TEST_PLUGINS_FROM:-$HOME/.myzsh/plugins}"
  for p in zsh-autosuggestions zsh-completions zsh-syntax-highlighting; do
    if [[ ! -f "$T_DIR/plugins/$p/$p.plugin.zsh" && -f "$from/$p/$p.plugin.zsh" ]]; then
      /bin/rm -rf "$T_DIR/plugins/$p"
      /bin/cp -Rp "$from/$p" "$T_DIR/plugins/$p"
    fi
  done
  chmod -R go-w "$T_DIR"

  /bin/mkdir -p "$T_ROOT"/{zd,kzd,cache,data,bin} \
    "$T_ROOT/work/capabilities" "$T_ROOT/work/CapabilitiesNotifierForNCL"
  ln -s "$T_ZSH" "$T_ROOT/bin/kiro-cli"
  # Menu fixture: 12 long names → a multi-row, multi-column completion menu
  local i
  for i in {01..12}; do /bin/mkdir -p "$T_ROOT/menu/capabilities-module-$i"; done

  # User ZDOTDIR: size the pty, load myzsh, optionally report executed commands
  cat > "$T_ROOT/zd/.zshrc" <<EOF
[[ -t 0 ]] && stty rows 40 cols 160 2>/dev/null
export MYZSH_DIR="$T_DIR"
source "\$MYZSH_DIR/zshrc"
if [[ -n "\$T_PREEXEC" ]]; then
  _t_preexec() { print -r -- "@@EXEC[\$1]@@"; }
  preexec_functions+=(_t_preexec)
fi
EOF

  # Kiro IDE ZDOTDIR: Kiro's real shell-integration script, which then
  # sources \$USER_ZDOTDIR/.zshrc exactly like the IDE does
  if (( $+commands[kiro] )); then
    T_KIRO_RC=$(kiro --locate-shell-integration-path zsh 2>/dev/null)
  fi
  if [[ -n "$T_KIRO_RC" && -f "$T_KIRO_RC" ]]; then
    print -r -- "[[ -t 0 ]] && stty rows 40 cols 160 2>/dev/null; . ${(q)T_KIRO_RC}" > "$T_ROOT/kzd/.zshrc"
  else
    T_KIRO_RC=""
  fi
}

# t_conf <KEY> <value>: set a myzsh.conf value in the sandbox copy
t_conf() {
  local conf="$T_DIR/myzsh.conf" tmp="$T_ROOT/conf.tmp"
  sed "s|^$1=.*|$1=$2|" "$conf" > "$tmp" && /bin/cat "$tmp" > "$conf" && /bin/rm -f "$tmp"
}

# t_env <mode>: print env assignments for a launch mode
#   full  — external terminal (Terminal.app)
#   kiro  — Kiro IDE terminal with Kiro's real shell integration
#   plain — no TERM_PROGRAM at all
t_env() {
  local -a e=(HOME="$HOME" USER="$USER" LOGNAME="$LOGNAME" SHELL="$T_ZSH"
              PATH="$T_PATH" TERM=xterm-256color LANG="${T_UTF8:-C}"
              XDG_CACHE_HOME="$T_ROOT/cache" XDG_DATA_HOME="$T_ROOT/data")
  case "$1" in
    full)  e+=(TERM_PROGRAM=Apple_Terminal ZDOTDIR="$T_ROOT/zd") ;;
    kiro)  e+=(TERM_PROGRAM=kiro VSCODE_INJECTION=1 Q_TERM_DISABLED=1 COLORTERM=truecolor
               ZDOTDIR="$T_ROOT/kzd" USER_ZDOTDIR="$T_ROOT/zd") ;;
    plain) e+=(ZDOTDIR="$T_ROOT/zd") ;;
  esac
  print -rl -- "${e[@]}"
}

# t_notty <seconds> <cmd...>: run a command the way agent tools do — in a
# new session with no controlling terminal — and kill it if it hangs
# (macOS has no timeout(1)). The alarm survives exec; 142 means it hung.
t_notty() {
  local secs="$1"; shift
  perl -MPOSIX -e 'POSIX::setsid(); alarm shift @ARGV; exec @ARGV or exit 127' "$secs" "$@"
}

# ─── pty session ─────────────────────────────────────────────────────
# t_start <mode> [VAR=value ...]  (T_SHELL overrides the shell command)
t_start() {
  local mode="$1"; shift
  local -a envv=("${(@f)$(t_env "$mode")}" "$@")
  local -a cmd=(${(z)${T_SHELL:-$T_ZSH -i}})
  zpty -d T_S 2>/dev/null
  zpty T_S "/usr/bin/env -i ${(j: :)${(q)envv[@]}} ${(j: :)cmd}"
  T_OUT=""
  t_read "${T_STARTUP_WAIT:-3}"
}

t_send() { zpty -w -n T_S "$1"; }
t_stop() { zpty -d T_S 2>/dev/null; }

# t_read <seconds>: collect pty output until the deadline
t_read() {
  local line
  local -F end=$(( EPOCHREALTIME + ${1:-1} ))
  while (( EPOCHREALTIME < end )); do
    if zpty -r -t T_S line 2>/dev/null; then T_OUT+="$line"; else sleep 0.05; fi
  done
}

# t_cmd <text> [seconds]: type a line + Return, collect output
t_cmd() { t_send "$1"$'\r'; t_read "${2:-1}"; }

# t_clean [text] [drop]: strip escapes and zsh's PROMPT_SP filler ("%" +
# spaces, overwritten on a real screen). OSC 633 (VS Code/Kiro markers)
# become <X;…> tokens, or are dropped when a second argument is given.
t_clean() {
  print -rn -- "${1-$T_OUT}" | T_DROP="${2:+1}" LC_ALL=C perl -pe '
    if ($ENV{T_DROP}) { s/\e\]633;[^\a\e]*(\a|\e\\)//g; }
    s/\e\]633;([A-Z])(;[^\a\e]*)?(\a|\e\\)/<$1$2>/g;
    s/\e\][^\a]*(\a|\e\\)//g;
    s/\e\[[0-9;?<>=]*[ -\/]*[@-~]//g;
    s/\e[()][0-9A-Za-z]//g; s/\e[=>]//g;
    s/\r//g; s/%[ ]{20,}//g;'
}

# t_exec_lines: commands reported by the preexec hook
t_exec_lines() { t_clean | LC_ALL=C grep -ao '@@EXEC\[[^]]*\]@@' | sed 's/^@@EXEC\[//; s/\]@@$//'; }
# t_marker <name>: value printed as @@name[value]@@ (last occurrence)
t_marker() { t_clean | LC_ALL=C grep -ao "@@$1\\[[^]]*\\]@@" | grep -v '\$' | tail -1 | sed "s/^@@$1\\[//; s/\\]@@\$//"; }
