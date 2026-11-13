#!/usr/bin/env zsh
# ╔══════════════════════════════════════════════════════════════════════╗
# ║  myzsh :: tests/run                                                ║
# ║  End-to-end tests: real interactive zsh sessions driven via zpty   ║
# ╚══════════════════════════════════════════════════════════════════════╝
#
# Usage: zsh -f tests/run.zsh [--src DIR] [--only T1,T2,...]
#   --src   myzsh tree to test (default: this repo)
#   --only  comma-separated case list (T1 T2 T3 T4 T5 T6 T7 S U)
# Env: MYZSH_TEST_KEEP=1 keeps the sandbox, MYZSH_TEST_VERBOSE=1 dumps output.

emulate -L zsh
setopt NO_CORRECT NO_CORRECT_ALL
unalias -a 2>/dev/null

typeset -g HERE="${0:A:h}"
typeset -g SRC="${HERE:h}" ONLY=""
while (( $# )); do
  case "$1" in
    --src)  SRC="$2"; shift 2 ;;
    --only) ONLY="$2"; shift 2 ;;
    *) print -u2 "unknown arg: $1"; exit 2 ;;
  esac
done

source "$HERE/harness.zsh"
t_prepare "$SRC" || { print -u2 "sandbox setup failed"; exit 2; }
print -r -- "myzsh tests — source: ${SRC:A}  sandbox: $T_ROOT"
print -r -- ""

want() { [[ -z "$ONLY" || ",$ONLY," == *",$1,"* ]]; }
dump() { [[ -n "$MYZSH_TEST_VERBOSE" ]] && { print -r -- "----- $1"; t_clean | cat -v; print -r -- "-----"; }; }

# Answer any pending y/n prompt so a stuck session can't hang later steps
unstick() { [[ "$(t_clean)" == *"[nyae]"* || "$(t_clean)" == *"(y/n"* || "$(t_clean)" == *"remove "*"?"* ]] && { t_send "n"; t_read 0.5; t_send $'\r'; t_read 0.5; }; }

# ─── T1: no spelling-correction prompt in agent shells ───────────────
if want T1; then
  print -r -- "── T1: autocorrect prompt (issue 1)"
  t1_case() {  # t1_case <label> <mode> [env...]
    local label="$1" mode="$2"; shift 2
    t_start "$mode" "$@"; T_OUT=""
    t_cmd 'gti --version' 1.5
    local out="$(t_clean)"; dump "T1 $label"
    unstick; t_stop
    if [[ "$out" == *"correct 'gti' to 'git'"* ]]; then
      t_fail "T1 $label: no correction prompt" "$(print -r -- "$out" | grep -a correct)"
    else
      t_pass "T1 $label: no correction prompt"
    fi
  }
  if [[ -n "$T_KIRO_RC" ]]; then t1_case "kiro IDE terminal" kiro; else t_skip "T1 kiro IDE terminal" "kiro not installed"; fi
  t1_case "KIRO_SESSION_ID set" full KIRO_SESSION_ID=test
  t1_case "CLAUDECODE=1" full CLAUDECODE=1
  T_SHELL="$T_ROOT/bin/kiro-cli -fc '/bin/zsh -i; :'" t1_case "parent process kiro-cli" full
  unset T_SHELL

  # Piped stdin (agent runs `... | zsh -i`): must not stop for an answer
  out=$(print -r -- 'gti --version; echo @@DONE' | t_notty 8 /usr/bin/env -i ${(f)"$(t_env full)"} /bin/zsh -i 2>&1)
  local rc=$?
  if [[ "$out" == *"correct 'gti'"* || $rc == 142 ]]; then
    t_fail "T1 piped stdin, no tty: no correction prompt (rc=$rc)" "$(print -r -- "$out" | grep -a correct)"
  else
    t_pass "T1 piped stdin, no tty: no correction prompt (rc=$rc)"
  fi

  # Human terminal keeps spelling correction
  t_start full; T_OUT=""
  t_cmd 'gti --version' 1.5
  out="$(t_clean)"; dump "T1 full"; unstick; t_stop
  [[ "$out" == *"correct 'gti' to 'git'"* ]]; t_check "T1 external terminal still offers correction" $? "$out"
fi

# ─── T2: Tab cycles in place, never appends extra words ─────────────
if want T2; then
  print -r -- "── T2: Tab appends words (issue 2)"
  t_start full T_PREEXEC=1
  t_cmd "cd $T_ROOT/work" 0.8; T_OUT=""
  t_send "cd cap"; t_read 0.3
  repeat 4 { t_send $'\t'; t_read 0.6; }
  t_send $'\r'; t_read 0.8; t_send $'\r'; t_read 0.5
  dump "T2"
  local last="$(t_exec_lines | grep '^cd ' | tail -1)"
  t_stop
  local -a words=(${(z)last})
  if (( ${#words} == 2 )) && [[ "${words[2]%/}" == (capabilities|CapabilitiesNotifierForNCL) ]]; then
    t_pass "T2 cd cap + Tab×4 + Return runs one directory [$last]"
  else
    t_fail "T2 cd cap + Tab×4 + Return runs one directory" "executed: [$last]"
  fi
fi

# ─── T3: menu selection is keyboard-navigable ────────────────────────
if want T3; then
  print -r -- "── T3: menu keyboard navigation (issue 3)"
  t_start full T_PREEXEC=1
  # t3_pick <key...>: in a 12-entry menu, type `cd cap` + keys, report PWD.
  # Tab 1 inserts the common prefix, Tab 2 lists, Tab 3 enters the menu.
  t3_pick() {
    t_cmd "cd $T_ROOT/menu" 0.8; T_OUT=""
    t_send "cd cap"; t_read 0.3
    local k
    for k in "$@"; do
      case "$k" in
        MENU)  t_send $'\t'; t_read 0.5; t_send $'\t'; t_read 0.5; t_send $'\t' ;;
        TAB)   t_send $'\t' ;;
        STAB)  t_send $'\e[Z' ;;
        DOWN)  t_send $'\e[B' ;;
        UP)    t_send $'\e[A' ;;
        RIGHT) t_send $'\e[C' ;;
        LEFT)  t_send $'\e[D' ;;
        ODOWN) t_send $'\eOB' ;;
        SPLIT) t_send $'\e'; t_read 0.15; t_send '[B' ;;  # ESC, pause, rest of Down
        BURST) t_send $'\t\t\t\e[B' ;;   # whole sequence in one write
        RET)   t_send $'\r' ;;
      esac
      t_read 0.6
    done
    t_send $'\r'; t_read 0.6     # second Return if the first only accepted the match
    T_OUT=""
    t_cmd 'print -r -- "@@PWD[${PWD:t}]@@"' 0.6
    REPLY="$(t_marker PWD)"
  }
  t3_pick MENU RET;            local base="$REPLY"
  t3_pick MENU DOWN RET;       local down="$REPLY"
  t3_pick MENU RIGHT RET;      local right="$REPLY"
  t3_pick MENU TAB RET;        local cyc="$REPLY"
  t3_pick MENU TAB STAB RET;   local back="$REPLY"
  t3_pick MENU ODOWN RET;      local odown="$REPLY"
  t3_pick BURST RET;           local burst="$REPLY"
  t3_pick MENU DOWN UP RET;    local upk="$REPLY"
  t3_pick MENU RIGHT LEFT RET; local lft="$REPLY"
  t3_pick MENU SPLIT RET;      local split="$REPLY"
  dump "T3"
  t_stop
  isdir() { [[ "$1" == capabilities-module-<01-12> ]]; }
  print -r -- "      selections: menu=$base down=$down right=$right tab=$cyc shift-tab=$back app-down=$odown burst=$burst down-up=$upk right-left=$lft split-down=$split"
  isdir "$base";                                t_check "T3 Tab opens the menu, Return runs the selection [$base]" $?
  isdir "$down" && [[ "$down" != "$base" ]];    t_check "T3 Down moves the selection [$down]" $?
  isdir "$right" && [[ "$right" != "$base" && "$right" != "$down" ]]; t_check "T3 Right moves the selection [$right]" $?
  isdir "$cyc" && [[ "$cyc" != "$base" ]];      t_check "T3 Tab cycles the selection [$cyc]" $?
  isdir "$back" && [[ "$back" == "$base" ]];    t_check "T3 Shift-Tab cycles back [$back]" $?
  isdir "$odown" && [[ "$odown" == "$down" ]];  t_check "T3 application-mode Down (^[OB) [$odown]" $?
  isdir "$burst" && [[ "$burst" == "$down" ]];  t_check "T3 keys arriving in one burst [$burst]" $?
  isdir "$upk" && [[ "$upk" == "$base" ]];      t_check "T3 Up moves the selection back [$upk]" $?
  isdir "$lft" && [[ "$lft" == "$base" ]];      t_check "T3 Left moves the selection back, stays in menu [$lft]" $?
  isdir "$split" && [[ "$split" == "$down" ]];  t_check "T3 Down whose ESC arrives separately [$split]" $?
fi

# ─── T4: clean command boundaries for the Kiro agent terminal ───────
if want T4; then
  print -r -- "── T4: agent terminal output/exit status (issue 4)"
  if [[ -n "$T_KIRO_RC" ]]; then
    t_start kiro
    local startup_raw="$T_OUT"
    t_cmd 'echo hello-marker; false' 2
    local all="$(t_clean)"; dump "T4 kiro"
    t_stop
    local pre="${all%%<C>*}"
    local na=${#${(@M)${(s:<:)pre}:#A>*}} nb=${#${(@M)${(s:<:)pre}:#B>*}}
    (( na == 1 && nb == 1 )); t_check "T4 one prompt start/end marker pair before the command (A=$na B=$nb)" $? "$(print -r -- "$pre" | cat -v | tail -5)"
    local body="${${all#*<C>}%%<D;*}"
    body="${body//[[:space:]]/}"
    [[ "$body" == "hello-marker" ]]; t_check "T4 command output captured exactly [${body:0:60}]" $?
    [[ "$all" == *"<D;1>"* ]]; t_check "T4 exit status 1 reported" $?
    [[ "$all" != *"<H>"* ]]; t_check "T4 no right prompt (clock) redraws" $?
    local before_a="$(t_clean "${startup_raw%%$'\e]633;A'*}" drop | tr -d '[:space:]')"
    [[ -z "$before_a" ]]; t_check "T4 no startup output before the first prompt" $? "$before_a"
  else
    t_skip "T4 kiro IDE terminal" "kiro not installed"
  fi

  # Agent tools that run `zsh -ic` without a terminal (Kiro CLI, others)
  local out
  out="$(t_notty 8 /usr/bin/env -i ${(f)"$(t_env full)"} /bin/zsh -ic 'echo hello-marker; false' </dev/null 2>/dev/null)"
  local rc=$?
  [[ "$out" == "hello-marker" ]]; t_check "T4 zsh -ic without a tty: stdout is exactly the command output" $? "$(print -r -- "$out" | cat -v | head -8)"
  (( rc == 1 )); t_check "T4 zsh -ic without a tty: exit status preserved (rc=$rc)" $?
fi

# ─── T5: no interactive cp/mv/rm prompts in agent shells ────────────
if want T5; then
  print -r -- "── T5: interactive cp/rm aliases (issue 5)"
  t5_run() {  # t5_run <mode> [env...]
    t_start "$@"
    t_cmd "cd $T_ROOT/work && /bin/rm -f a b x y && echo data > a" 0.6; T_OUT=""
    t_cmd 'cp a b; cp a b; echo "@@CP[$?]@@"' 1.2
    unstick
    local cpout="$(t_clean)"; T_OUT=""
    t_cmd 'touch x y; rm -f x; rm y; echo "@@RM[$?]@@"' 1.2
    unstick
    local rmout="$(t_clean)"; T_OUT=""
    t_cmd 'print -r -- "@@W[$(whence -w cp rm mv | tr "\n" " ")]@@"' 0.8
    local w="$(t_marker W)"
    t_stop
    reply=("$cpout" "$rmout" "$w")
  }
  t5_check() {  # t5_check <label> <mode> [env...]
    local label="$1"; shift
    t5_run "$@"
    local cpout="${reply[1]}" rmout="${reply[2]}" w="${reply[3]}"
    [[ "$cpout" != *overwrite* && "$cpout" == *"@@CP[0]@@"* ]]; t_check "T5 $label: second cp does not prompt" $? "$(print -r -- "$cpout" | grep -a -E 'overwrite|@@CP')"
    local rmbody="${${rmout#*\$?\]@@}}"
    [[ "$rmout" != *"remove "* && "$rmout" == *"@@RM[0]@@"* && "$rmbody" != *$'\nx\n'* ]]; t_check "T5 $label: rm -f / rm print and ask nothing" $? "$(print -r -- "$rmout" | tail -4)"
    [[ "$w" == "cp: command rm: command mv: command "* ]]; t_check "T5 $label: cp/rm/mv are plain commands [$w]" $?
  }
  if [[ -n "$T_KIRO_RC" ]]; then t5_check "kiro IDE terminal" kiro; else t_skip "T5 kiro" "kiro not installed"; fi
  t5_check "KIRO_SESSION_ID set" full KIRO_SESSION_ID=test

  # Human terminal keeps the safety aliases
  t_start full; T_OUT=""
  t_cmd 'print -r -- "@@A[$(alias cp)]@@"' 0.8
  local a="$(t_marker A)"; t_stop
  [[ "$a" == "cp='cp -iv'" ]]; t_check "T5 external terminal keeps cp -iv [$a]" $?

  # local.zsh is loaded last in both modes, so personal aliases win
  print -r -- "alias dc='echo local-dc'" > "$T_DIR/local.zsh"; chmod 600 "$T_DIR/local.zsh"
  local m
  for m in full kiro; do
    [[ "$m" == kiro && -z "$T_KIRO_RC" ]] && continue
    t_start "$m"; T_OUT=""
    t_cmd 'print -r -- "@@DC[$(dc)]@@"' 0.8
    local dcv="$(t_marker DC)"; t_stop
    [[ "$dcv" == "local-dc" ]]; t_check "T5 $m: local.zsh loads and overrides dc [$dcv]" $?
  done
  /bin/rm -f "$T_DIR/local.zsh"
fi

# ─── T6: reload function and powerline compact prompt ───────────────
if want T6; then
  print -r -- "── T6: reload + powerline prompt (issue 6)"
  t_start full; T_OUT=""
  t_cmd 'source $ZDOTDIR/.zshrc; source $ZDOTDIR/.zshrc; print -r -- "@@R[$(whence -w reload)]@@"' 3
  local out="$(t_clean)"; dump "T6 reload"
  [[ "$out" != *"defining function based on alias"* ]]; t_check "T6 re-sourcing zshrc has no reload alias/function clash" $? "$(print -r -- "$out" | grep -a 'defining')"
  local rw="$(t_marker R)"
  [[ "$rw" == "reload: function" ]]; t_check "T6 reload is a function [$rw]" $?
  t_stop

  t_start full
  local first="$T_OUT"
  t_cmd "cd $T_ROOT/work" 1; T_OUT=""
  t_cmd 'true' 1;  local same="$(t_clean)"; T_OUT=""
  t_cmd 'true' 1;  local same2="$(t_clean)"; T_OUT=""
  t_cmd 'cd ..' 1; local moved="$(t_clean)"; T_OUT=""
  t_cmd "/bin/mkdir -p $T_ROOT/g && cd $T_ROOT/g && git init -q && git checkout -q -b xbranch" 2; local gitdir="$(t_clean)"; T_OUT=""
  t_cmd 'git checkout -q -b ybranch' 2; local branch="$(t_clean)"; T_OUT=""
  t_cmd 'false' 1; local failed="$T_OUT"; T_OUT=""
  t_cmd 'true' 1; local ok="$T_OUT"
  dump "T6 prompt"
  t_stop
  [[ "$same" != *"╭─"* && "$same2" != *"╭─"* ]]; t_check "T6 header hidden when dir/branch unchanged" $? "$(print -r -- "$same" | cat -v | tail -3)"
  [[ "$moved" == *"╭─"* ]];  t_check "T6 header shown after cd" $?
  [[ "$gitdir" == *"╭─"* && "$gitdir" == *xbranch* ]]; t_check "T6 header shown in new git repo with branch" $? "$(print -r -- "$gitdir" | cat -v | tail -3)"
  [[ "$branch" == *"╭─"* && "$branch" == *ybranch* ]]; t_check "T6 header shown after branch change" $?
  [[ "$(t_clean "$first")" == *"❯"* ]]; t_check "T6 prompt shows ❯" $?
  [[ "$ok" == *$'\e['(32|38\;5\;2|38\;5\;10)m❯* ]]; t_check "T6 ❯ is green after success" $? "$(print -r -- "$ok" | cat -v | tail -2)"
  [[ "$failed" == *$'\e['(31|38\;5\;1|38\;5\;9)m❯* ]]; t_check "T6 ❯ is red after failure" $? "$(print -r -- "$failed" | cat -v | tail -2)"
fi

# ─── T7: myzsh-help and the ? shortcut ───────────────────────────────
if want T7; then
  print -r -- "── T7: myzsh-help / ?"
  local m
  for m in full kiro; do
    [[ "$m" == kiro && -z "$T_KIRO_RC" ]] && continue
    t_start "$m"; T_OUT=""
    t_cmd '?; echo "@@H1[$?]@@"' 1.5; local o1="$(t_clean)"; T_OUT=""
    t_cmd 'myzsh-help git; echo "@@H2[$?]@@"' 1.5; local o2="$(t_clean)"
    t_stop
    [[ "$o1" == *"myzsh cheatsheet"* && "$o1" == *"@@H1[0]@@"* ]]; t_check "T7 $m: ? shows the cheatsheet" $? "$(print -r -- "$o1" | tail -4)"
    [[ "$o2" == *"git aliases"* && "$o2" == *"@@H2[0]@@"* ]]; t_check "T7 $m: myzsh-help git" $? "$(print -r -- "$o2" | tail -4)"
  done
fi

# ─── S: startup smoke tests ──────────────────────────────────────────
if want S; then
  print -r -- "── S: startup smoke tests"
  bad_startup() { print -r -- "$1" | LC_ALL=C grep -a -n -E '⚠|🔒|[Ee]rror|command not found|no such|not found|parse error|bad option'; }
  s_case() {  # s_case <label> <mode> [env...]
    local label="$1"; shift
    t_start "$@"; t_cmd 'print -r -- "@@UP[ok]@@"' 1
    local out="$(t_clean)"; t_stop
    local bad="$(bad_startup "$out")"
    [[ -z "$bad" && "$(t_marker UP)" == ok ]]; t_check "S $label: clean startup, shell responsive" $? "$bad"
  }
  s_case "external terminal (full)" full
  s_case "no TERM_PROGRAM (full)" plain
  if [[ -n "$T_KIRO_RC" ]]; then s_case "kiro IDE terminal" kiro; else t_skip "S kiro" "kiro not installed"; fi
  T_SHELL="$T_ROOT/bin/kiro-cli -fc '/bin/zsh -i; :'" s_case "under kiro-cli parent" full; unset T_SHELL

  local out="$(t_notty 8 /usr/bin/env -i ${(f)"$(t_env full)"} /bin/zsh -ic 'echo "@@UP[ok]@@"' </dev/null 2>&1)"
  [[ -z "$(bad_startup "$out")" && "$out" == "@@UP[ok]@@" ]]; t_check "S zsh -ic without a tty: clean" $? "$(print -r -- "$out" | head -5)"

  t_conf MYZSH_NERD_FONTS false; s_case "MYZSH_NERD_FONTS=false" full; t_conf MYZSH_NERD_FONTS true
  t_conf MYZSH_THEME '"minimal"'; s_case "theme minimal" full
  t_conf MYZSH_THEME '"pure"'; s_case "theme pure" full
  t_conf MYZSH_THEME '"powerline"'

  # Lockfile present but no sha256 tool on PATH: must still start and load the theme
  /bin/mkdir -p "$T_ROOT/nohash"
  local f
  for f in /usr/bin/* /bin/*; do
    [[ "${f:t}" == (shasum*|sha*sum|openssl) ]] && continue
    [[ -e "$T_ROOT/nohash/${f:t}" ]] || ln -s "$f" "$T_ROOT/nohash/${f:t}"
  done
  for f in "$T_DIR"/themes/**/*.zsh-theme(N) "$T_DIR"/plugins/**/*.plugin.zsh(N); do
    print -r -- "$f:$(shasum -a 256 "$f" | cut -d' ' -f1)"
  done > "$T_DIR/myzsh.lock"; chmod 600 "$T_DIR/myzsh.lock"
  local save_path="$T_PATH"; T_PATH="$T_ROOT/nohash"
  t_start full; t_cmd 'print -r -- "@@UP[ok]@@"' 1
  out="$(t_clean)"; t_stop; T_PATH="$save_path"
  local warn=$(print -r -- "$out" | LC_ALL=C grep -a -c -E '⚠|🔒')
  [[ "$(t_marker UP)" == ok && "$out" == *"╰─"* && "$out" != *"CHECKSUM MISMATCH"* ]] && (( warn <= 1 ))
  # (init.zsh may re-add /opt/homebrew/bin, so this is the startup-level check;
  #  the strict no-tool path is covered by the U case)
  t_check "S PATH without sha256 tools: theme still loads, at most one warning (warnings=$warn)" $? "$(print -r -- "$out" | grep -a -E '⚠|🔒' | head -5)"
  /bin/rm -f "$T_DIR/myzsh.lock"
fi

# ─── U: unit checks (security module) ────────────────────────────────
if want U; then
  print -r -- "── U: security module"
  local u="$T_ROOT/unit"; /bin/mkdir -p "$u"
  print 'typeset -g U_OK=1' > "$u/good.zsh"; chmod 600 "$u/good.zsh"
  print 'typeset -g U_BAD=1' > "$u/bad.zsh";  chmod 666 "$u/bad.zsh"
  local r="$(MYZSH_DIR="$u" MYZSH_STRICT_PERMISSIONS=true /bin/zsh -fc '
    source '"${(q)T_DIR}"'/lib/security.zsh
    myzsh-safe-source '"${(q)u}"'/good.zsh true; a=$?
    myzsh-safe-source '"${(q)u}"'/bad.zsh true 2>/dev/null; b=$?
    print -r -- "$a:$b:${U_OK:-}:${U_BAD:-}"')"
  [[ "$r" == "0:1:1:" ]]; t_check "U safe-source accepts 600, refuses 666 [$r]" $?

  # No sha256 tool at all: locked files still load (one warning), and
  # myzsh-update-lock refuses without wiping the existing lockfile
  local nh="$T_ROOT/nohash-unit"; /bin/mkdir -p "$nh"
  for f in /usr/bin/* /bin/*; do
    [[ "${f:t}" == (shasum*|sha*sum|openssl) ]] && continue
    [[ -e "$nh/${f:t}" ]] || ln -s "$f" "$nh/${f:t}"
  done
  print 'typeset -g U_T1=1' > "$u/t1.zsh"; print 'typeset -g U_T2=1' > "$u/t2.zsh"; chmod 600 "$u"/t*.zsh
  print -r -- "$u/t1.zsh:deadbeef"$'\n'"$u/t2.zsh:deadbeef" > "$u/myzsh.lock"; chmod 600 "$u/myzsh.lock"
  r="$(/usr/bin/env -i HOME="$HOME" PATH="$nh" MYZSH_DIR="$u" MYZSH_VERIFY_PLUGINS=true /bin/zsh -fc '
    source '"${(q)T_DIR}"'/lib/security.zsh
    myzsh-safe-source '"${(q)u}"'/t1.zsh 2>>'"${(q)u}"'/err
    myzsh-safe-source '"${(q)u}"'/t2.zsh 2>>'"${(q)u}"'/err
    myzsh-update-lock >/dev/null 2>&1; l=$?
    print -r -- "${U_T1:-}${U_T2:-}:$(grep -c . '"${(q)u}"'/err):$l:$(grep -c deadbeef '"${(q)u}"'/myzsh.lock)"' 2>&1)"
  [[ "$r" == "11:1:1:2" ]]; t_check "U no sha256 tool: files load, 1 warning, lockfile kept [$r]" $?
  # myzsh-update-lock prints only its own status lines (no stray hash=...)
  /bin/mkdir -p "$u/themes" && print '#' > "$u/themes/a.zsh-theme" && print '#' > "$u/themes/b.zsh-theme"
  r="$(MYZSH_DIR="$u" MYZSH_LOCKFILE="$u/myzsh.lock" /bin/zsh -fc '
    source '"${(q)T_DIR}"'/lib/security.zsh; myzsh-update-lock' 2>&1)"
  [[ "$r" != *"hash="* && "$r" == *"Locked 2 files"* ]]; t_check "U update-lock: no stray output" $? "$r"
  # Update banner: stale flag clears when up to date; box is aligned when behind
  local g="$T_ROOT/upd"; /bin/mkdir -p "$g/cache"
  git -C "$g" init -q && git -C "$g" -c user.name=t -c user.email=t@t commit -q --allow-empty -m a &&
    git -C "$g" update-ref refs/remotes/origin/main HEAD
  ub() { MYZSH_DIR="$g" MYZSH_CACHE="$g/cache" MYZSH_AUTO_UPDATE_CHECK=false LANG=en_US.UTF-8 /bin/zsh -fc '
    source '"${(q)T_DIR}"'/lib/update-check.zsh' 2>&1 | sed $'s/\e\\[[0-9;]*m//g'; }
  print 5 > "$g/cache/.update-available"; r="$(ub)"
  [[ -z "$r" && ! -e "$g/cache/.update-available" ]]; t_check "U stale update notice cleared when up to date" $? "$r"
  git -C "$g" -c user.name=t -c user.email=t@t commit -q --allow-empty -m b &&
    git -C "$g" update-ref refs/remotes/origin/main HEAD && git -C "$g" reset -q --hard HEAD~1
  print 5 > "$g/cache/.update-available"; r="$(ub)"
  local -a w=(); local l
  for l in "${(@f)r}"; do [[ -n "$l" ]] && w+=$(LANG=en_US.UTF-8 /bin/zsh -fc 'print ${(m)#1}' _ "$l"); done
  [[ "$r" == *"1 new commit(s)"* && ${#w} == 6 && ${#${(u)w}} == 1 ]]; t_check "U update banner: live count, aligned box [widths: $w]" $? "$r"
fi

t_finish
