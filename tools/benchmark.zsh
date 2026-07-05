#!/usr/bin/env zsh
# ╔══════════════════════════════════════════════════════════════════════╗
# ║  myzsh :: benchmark                                                ║
# ║  Profiling utility for startup time and function analysis          ║
# ║  Usage: source this file, or run 'myzsh-benchmark [quick|full]'    ║
# ╚══════════════════════════════════════════════════════════════════════╝

# ─── Configuration ────────────────────────────────────────────────────
typeset -g _MYZSH_BENCH_ITERATIONS="${MYZSH_BENCH_ITERATIONS:-5}"

# ─── Colour Definitions ──────────────────────────────────────────────
typeset -g _B_RESET=$'\e[0m'
typeset -g _B_BOLD=$'\e[1m'
typeset -g _B_DIM=$'\e[2m'
typeset -g _B_GREEN=$'\e[32m'
typeset -g _B_YELLOW=$'\e[33m'
typeset -g _B_CYAN=$'\e[36m'
typeset -g _B_MAGENTA=$'\e[35m'
typeset -g _B_RED=$'\e[31m'
typeset -g _B_WHITE=$'\e[37m'

# ─── Box Drawing Helpers ──────────────────────────────────────────────
_bench_header() {
  local title="$1"
  local width=70
  local padding=$(( width - ${#title} - 4 ))
  echo ""
  echo "${_B_CYAN}╔══════════════════════════════════════════════════════════════════════╗${_B_RESET}"
  printf "${_B_CYAN}║${_B_RESET}  ${_B_BOLD}${_B_WHITE}%s${_B_RESET}%*s${_B_CYAN}║${_B_RESET}\n" "$title" "$padding" ""
  echo "${_B_CYAN}╚══════════════════════════════════════════════════════════════════════╝${_B_RESET}"
}

_bench_section() {
  local title="$1"
  echo ""
  echo "${_B_YELLOW}─── ${title} ───────────────────────────────────────────────────────${_B_RESET}" | cut -c1-78
}

_bench_line() {
  local label="$1"
  local value="$2"
  local colour="${3:-$_B_GREEN}"
  printf "  ${_B_DIM}│${_B_RESET} %-42s ${colour}%s${_B_RESET}\n" "$label" "$value"
}

_bench_bar() {
  local percent="$1"
  local max_width=20
  local filled=$(( percent * max_width / 100 ))
  local empty=$(( max_width - filled ))
  local bar=""
  local i
  for (( i = 0; i < filled; i++ )); do bar+="█"; done
  for (( i = 0; i < empty; i++ )); do bar+="░"; done
  echo "$bar"
}

# ─── Quick Benchmark (total startup time only) ────────────────────────
_myzsh_bench_quick() {
  _bench_header "myzsh :: Quick Benchmark"

  _bench_section "Startup Time (averaged over ${_MYZSH_BENCH_ITERATIONS} runs)"

  local total=0
  local times=()
  local i

  for (( i = 1; i <= _MYZSH_BENCH_ITERATIONS; i++ )); do
    local start=$( perl -MTime::HiRes=time -e 'printf "%.6f", time' )
    zsh -i -c exit 2>/dev/null
    local end=$( perl -MTime::HiRes=time -e 'printf "%.6f", time' )
    local elapsed=$( echo "$end - $start" | bc -l )
    times+=($elapsed)
    total=$( echo "$total + $elapsed" | bc -l )
  done

  local avg=$( echo "scale=4; $total / $_MYZSH_BENCH_ITERATIONS" | bc -l )
  local avg_ms=$( echo "scale=1; $avg * 1000" | bc -l )

  # Find min/max
  local min=${times[1]} max=${times[1]}
  for t in "${times[@]}"; do
    (( $(echo "$t < $min" | bc -l) )) && min=$t
    (( $(echo "$t > $max" | bc -l) )) && max=$t
  done
  local min_ms=$( echo "scale=1; $min * 1000" | bc -l )
  local max_ms=$( echo "scale=1; $max * 1000" | bc -l )

  _bench_line "Average startup time" "${avg_ms} ms" "$_B_GREEN"
  _bench_line "Fastest run" "${min_ms} ms" "$_B_CYAN"
  _bench_line "Slowest run" "${max_ms} ms" "$_B_YELLOW"
  _bench_line "Iterations" "$_MYZSH_BENCH_ITERATIONS"

  echo ""

  # Rating
  if (( $(echo "$avg < 0.100" | bc -l) )); then
    echo "  ${_B_GREEN}${_B_BOLD}⚡ Excellent!${_B_RESET} ${_B_DIM}Under 100ms — blazing fast.${_B_RESET}"
  elif (( $(echo "$avg < 0.200" | bc -l) )); then
    echo "  ${_B_YELLOW}${_B_BOLD}✓ Good.${_B_RESET} ${_B_DIM}Under 200ms — snappy.${_B_RESET}"
  elif (( $(echo "$avg < 0.500" | bc -l) )); then
    echo "  ${_B_YELLOW}${_B_BOLD}⚠ Moderate.${_B_RESET} ${_B_DIM}Under 500ms — room for improvement.${_B_RESET}"
  else
    echo "  ${_B_RED}${_B_BOLD}✗ Slow.${_B_RESET} ${_B_DIM}Over 500ms — consider profiling with 'full' mode.${_B_RESET}"
  fi
  echo ""
}

# ─── Full Benchmark (detailed zprof breakdown) ───────────────────────
_myzsh_bench_full() {
  _bench_header "myzsh :: Full Profiling Report"

  # ── Run quick timing first ──
  _bench_section "Startup Time"

  local start=$( perl -MTime::HiRes=time -e 'printf "%.6f", time' )
  zsh -i -c exit 2>/dev/null
  local end=$( perl -MTime::HiRes=time -e 'printf "%.6f", time' )
  local elapsed_ms=$( echo "scale=1; ($end - $start) * 1000" | bc -l )

  _bench_line "Total startup time" "${elapsed_ms} ms" "$_B_GREEN"

  # ── Run profiled session ──
  _bench_section "Top 10 Slowest Function Calls"
  echo ""

  # Run zsh with zprof enabled and capture output
  local profile_output
  profile_output=$( MYZSH_BENCHMARK=true zsh -i -c 'zprof' 2>/dev/null )

  if [[ -z "$profile_output" ]]; then
    echo "  ${_B_DIM}No profiling data available.${_B_RESET}"
    echo "  ${_B_DIM}Ensure MYZSH_BENCHMARK=true triggers zmodload zsh/zprof in your zshrc.${_B_RESET}"
  else
    # Parse the zprof output — extract the top 10 functions
    # zprof output format: num  calls  time  self  name
    local -a top_funcs
    top_funcs=( "${(@f)$(echo "$profile_output" | head -n 30 | tail -n +2 | head -n 10)}" )

    # Print header
    printf "  ${_B_DIM}│${_B_RESET} ${_B_BOLD}%-4s %-30s %8s %8s${_B_RESET}\n" "#" "Function" "Time(ms)" "Calls"
    printf "  ${_B_DIM}│ ────────────────────────────────────────────────────────${_B_RESET}\n"

    local rank=0
    local line
    for line in "${top_funcs[@]}"; do
      [[ -z "$line" ]] && continue
      [[ "$line" == *"-----"* ]] && continue
      [[ "$line" == *"num"* ]] && continue

      rank=$(( rank + 1 ))
      # Parse: num  calls  time  self  name (zprof format varies)
      local func_name time_val calls_val self_val
      # Typical zprof line: " 1)  1    12.34   52.11%   11.22   48.34%  funcname"
      func_name=$( echo "$line" | awk '{print $NF}' )
      time_val=$( echo "$line" | awk '{print $3}' )
      calls_val=$( echo "$line" | awk '{print $2}' )

      # Determine colour based on ranking
      local row_colour="$_B_WHITE"
      (( rank <= 3 )) && row_colour="$_B_RED"
      (( rank > 3 && rank <= 6 )) && row_colour="$_B_YELLOW"
      (( rank > 6 )) && row_colour="$_B_GREEN"

      printf "  ${_B_DIM}│${_B_RESET} ${row_colour}%-4s %-30s %8s %8s${_B_RESET}\n" \
        "${rank})" "${func_name:0:30}" "${time_val}" "${calls_val}"
    done
  fi

  # ── Module load times ──
  _bench_section "Module Load Times"
  echo ""

  local module_output
  module_output=$( MYZSH_BENCHMARK=true zsh -i -c '
    # Report time for each sourced module
    zmodload zsh/zprof
    local -a modules
    modules=( ${(@f)$(zprof | grep -E "(source|compinit|compdef|zmodload)" | head -n 10)} )
    for m in "${modules[@]}"; do
      echo "$m"
    done
  ' 2>/dev/null )

  if [[ -n "$module_output" ]]; then
    printf "  ${_B_DIM}│${_B_RESET} ${_B_BOLD}%-40s %10s${_B_RESET}\n" "Module/Operation" "Time(ms)"
    printf "  ${_B_DIM}│ ────────────────────────────────────────────────────────${_B_RESET}\n"

    echo "$module_output" | while IFS= read -r line; do
      [[ -z "$line" ]] && continue
      local mod_name mod_time
      mod_name=$( echo "$line" | awk '{print $NF}' )
      mod_time=$( echo "$line" | awk '{print $3}' )
      printf "  ${_B_DIM}│${_B_RESET} %-40s ${_B_MAGENTA}%10s${_B_RESET}\n" \
        "${mod_name:0:40}" "${mod_time}"
    done
  else
    echo "  ${_B_DIM}No module-specific data captured.${_B_RESET}"
    echo "  ${_B_DIM}Module times are included in the function calls above.${_B_RESET}"
  fi

  # ── Summary ──
  _bench_section "Summary"
  echo ""

  local total_funcs
  total_funcs=$( echo "$profile_output" | grep -c "^[[:space:]]*[0-9]" 2>/dev/null || echo "0" )
  _bench_line "Total profiled functions" "$total_funcs"
  _bench_line "Startup time" "${elapsed_ms} ms"

  if (( $(echo "$elapsed_ms < 100" | bc -l) )); then
    _bench_line "Rating" "⚡ Excellent" "$_B_GREEN"
  elif (( $(echo "$elapsed_ms < 200" | bc -l) )); then
    _bench_line "Rating" "✓ Good" "$_B_GREEN"
  elif (( $(echo "$elapsed_ms < 500" | bc -l) )); then
    _bench_line "Rating" "⚠ Moderate" "$_B_YELLOW"
  else
    _bench_line "Rating" "✗ Slow — optimise!" "$_B_RED"
  fi

  echo ""
  echo "${_B_DIM}  Tip: Set MYZSH_BENCH_ITERATIONS=N for more accurate quick benchmarks.${_B_RESET}"
  echo "${_B_DIM}  Tip: Use 'myzsh-benchmark quick' for just the startup time.${_B_RESET}"
  echo ""
}

# ─── Main Entry Point ─────────────────────────────────────────────────
myzsh-benchmark() {
  local mode="${1:-full}"

  case "$mode" in
    quick|q)
      _myzsh_bench_quick
      ;;
    full|f)
      _myzsh_bench_full
      ;;
    help|--help|-h)
      _bench_header "myzsh :: Benchmark Help"
      echo ""
      echo "  ${_B_BOLD}Usage:${_B_RESET} myzsh-benchmark [mode]"
      echo ""
      echo "  ${_B_BOLD}Modes:${_B_RESET}"
      _bench_line "quick, q" "Total startup time only (averaged)"
      _bench_line "full, f" "Detailed profiling with zprof (default)"
      _bench_line "help, -h" "Show this help message"
      echo ""
      echo "  ${_B_BOLD}Environment:${_B_RESET}"
      _bench_line "MYZSH_BENCH_ITERATIONS" "Number of timing runs (default: 5)"
      _bench_line "MYZSH_BENCHMARK=true" "Enables zprof in zshrc"
      echo ""
      ;;
    *)
      echo "${_B_RED}Unknown mode: ${mode}${_B_RESET}"
      echo "Run 'myzsh-benchmark help' for usage."
      return 1
      ;;
  esac
}

# ─── Auto-run if sourced directly ─────────────────────────────────────
# If this file is being sourced interactively (not via autoload),
# register the command but don't auto-execute.
if [[ "${zsh_eval_context[-1]}" == "file" ]]; then
  # File is being sourced — just define the function, print a note
  echo "${_B_DIM}myzsh-benchmark loaded. Run 'myzsh-benchmark' or 'myzsh-benchmark quick'.${_B_RESET}"
fi
