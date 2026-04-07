#!/usr/bin/env bash
# benchmark-compare.sh -- show benchmark progress over time
#
# Usage:
#   ./tests/benchmark-compare.sh             # compare last 2 runs
#   ./tests/benchmark-compare.sh --all       # show all stored runs
#   ./tests/benchmark-compare.sh --list      # list all stored run timestamps/SHAs
#   ./tests/benchmark-compare.sh A B         # compare specific runs by index (1-based)

SCRIPT_DIR=$(dirname -- "$(readlink -f -- "$0")")
RESULTS_FILE="${SCRIPT_DIR}/benchmark-results.tsv"

if [[ ! -f "${RESULTS_FILE}" ]]; then
  echo "No results file found at ${RESULTS_FILE}"
  echo "Run ./tests/benchmark.sh first."
  exit 1
fi

# ── helpers ────────────────────────────────────────────────────────────────────

_ms() {
  local ns="${1}"
  printf "%d.%d" "$(( ns / 1000000 ))" "$(( (ns % 1000000) / 100000 ))"
}

_delta_pct() {
  # _delta_pct OLD NEW  →  "+12.3%" or "-5.1%" or "  0.0%"
  local old="${1}" new="${2}"
  if (( old == 0 )); then echo "    n/a"; return; fi
  local diff=$(( new - old ))
  local sign=""
  (( diff > 0 )) && sign="+"
  # integer percent with one decimal: diff*1000/old → tenths of a percent
  local tenths=$(( diff * 1000 / old ))
  local whole=$(( tenths / 10 ))
  local frac=$(( tenths % 10 ))
  (( frac < 0 )) && frac=$(( -frac ))
  printf "%s%d.%d%%" "${sign}" "${whole}" "${frac}"
}

_color_delta() {
  local pct="${1}"
  if [[ "${pct}" == *-* ]]; then
    printf "\033[32m%s\033[0m" "${pct}"   # green = faster
  elif [[ "${pct}" == "+0.0%" ]]; then
    printf "%s" "${pct}"
  else
    printf "\033[31m%s\033[0m" "${pct}"   # red = slower
  fi
}

# ── parse arguments ────────────────────────────────────────────────────────────

MODE="last2"
RUN_A="" RUN_B=""

for arg in "$@"; do
  case "${arg}" in
    --all)  MODE="all" ;;
    --list) MODE="list" ;;
    [0-9]*) [[ -z "${RUN_A}" ]] && RUN_A="${arg}" || RUN_B="${arg}"; MODE="pick" ;;
  esac
done

# ── collect unique run timestamps ─────────────────────────────────────────────

declare -a run_timestamps=()
declare -A run_sha=()

while IFS=$'\t' read -r ts sha _ label _ _ _; do
  [[ "${ts}" == "timestamp" ]] && continue  # skip header
  if [[ -z "${run_sha["${ts}"]+x}" ]]; then
    run_timestamps+=("${ts}")
    run_sha["${ts}"]="${sha}"
  fi
done < "${RESULTS_FILE}"

num_runs="${#run_timestamps[@]}"

if (( num_runs == 0 )); then
  echo "Results file exists but contains no data rows."
  exit 1
fi

# ── list mode ─────────────────────────────────────────────────────────────────

if [[ "${MODE}" == "list" ]]; then
  echo ""
  echo "Stored benchmark runs (${num_runs} total):"
  echo ""
  for (( i=0; i<num_runs; i++ )); do
    ts="${run_timestamps[${i}]}"
    printf "  [%2d]  %s  sha=%s\n" "$(( i + 1 ))" "${ts}" "${run_sha["${ts}"]}"
  done
  echo ""
  exit 0
fi

# ── resolve which runs to compare ─────────────────────────────────────────────

if [[ "${MODE}" == "all" ]]; then
  # Print a summary table of avg times per label across all runs
  echo ""
  echo "=== All benchmark runs (avg ms) ==="
  echo ""

  # Collect all labels in order
  declare -a all_labels=()
  declare -A seen_labels=()
  while IFS=$'\t' read -r ts _ _ label _ _ _; do
    [[ "${ts}" == "timestamp" ]] && continue
    if [[ -z "${seen_labels["${label}"]+x}" ]]; then
      all_labels+=("${label}")
      seen_labels["${label}"]=1
    fi
  done < "${RESULTS_FILE}"

  # Print header row
  printf "  %-40s" "label"
  for ts in "${run_timestamps[@]}"; do
    printf "  %10s" "${run_sha["${ts}"]}"
  done
  printf "\n"

  printf "  %-40s" ""
  for ts in "${run_timestamps[@]}"; do
    printf "  %10s" "${ts:0:10}"
  done
  printf "\n\n"

  for label in "${all_labels[@]}"; do
    printf "  %-40s" "${label}"
    prev_avg=""
    for ts in "${run_timestamps[@]}"; do
      # Look up this label/timestamp combo
      avg_val=""
      while IFS=$'\t' read -r r_ts _ _ r_label _ r_avg _; do
        [[ "${r_ts}" == "timestamp" ]] && continue
        if [[ "${r_ts}" == "${ts}" && "${r_label}" == "${label}" ]]; then
          avg_val="${r_avg}"
          break
        fi
      done < "${RESULTS_FILE}"

      if [[ -z "${avg_val}" ]]; then
        printf "  %10s" "-"
      else
        ms="$(_ms "${avg_val}")"
        if [[ -n "${prev_avg}" ]]; then
          pct="$(_delta_pct "${prev_avg}" "${avg_val}")"
          printf "  %6s ms %s" "${ms}" "$(printf "%7s" "${pct}")"
        else
          printf "  %10s ms" "${ms}"
        fi
        prev_avg="${avg_val}"
      fi
    done
    printf "\n"
  done
  echo ""
  exit 0
fi

# ── pick two runs to compare ───────────────────────────────────────────────────

if [[ "${MODE}" == "pick" ]]; then
  idx_a=$(( RUN_A - 1 ))
  idx_b="${RUN_B:-${num_runs}}"
  idx_b=$(( idx_b - 1 ))
elif [[ "${MODE}" == "last2" ]]; then
  if (( num_runs < 2 )); then
    echo "Only 1 run stored. Need at least 2 to compare. Run the benchmark again."
    echo "(Use --list to see stored runs, --all for a full history table)"
    exit 0
  fi
  idx_a=$(( num_runs - 2 ))
  idx_b=$(( num_runs - 1 ))
fi

ts_a="${run_timestamps[${idx_a}]}"
ts_b="${run_timestamps[${idx_b}]}"
sha_a="${run_sha["${ts_a}"]}"
sha_b="${run_sha["${ts_b}"]}"

# ── load data for both runs ────────────────────────────────────────────────────

declare -A data_a_avg
declare -A data_b_min data_b_avg
declare -a ordered_labels=()
declare -A seen_label=()

while IFS=$'\t' read -r ts _ _ label min avg _; do
  [[ "${ts}" == "timestamp" ]] && continue
  if [[ "${ts}" == "${ts_a}" ]]; then
    data_a_avg["${label}"]="${avg}"
  fi
  if [[ "${ts}" == "${ts_b}" ]]; then
    data_b_min["${label}"]="${min}"
    data_b_avg["${label}"]="${avg}"
    if [[ -z "${seen_label["${label}"]+x}" ]]; then
      ordered_labels+=("${label}")
      seen_label["${label}"]=1
    fi
  fi
done < "${RESULTS_FILE}"

# ── print comparison table ────────────────────────────────────────────────────

echo ""
echo "=== Benchmark comparison ==="
printf "  A: [%d] %s  sha=%s\n" "$(( idx_a + 1 ))" "${ts_a}" "${sha_a}"
printf "  B: [%d] %s  sha=%s\n" "$(( idx_b + 1 ))" "${ts_b}" "${sha_b}"
echo ""
printf "  %-40s  %10s  %10s  %10s  %8s\n" "label" "A avg (ms)" "B avg (ms)" "B min (ms)" "delta avg"
printf "  %-40s  %10s  %10s  %10s  %8s\n" \
  "$(printf '%0.s-' {1..40})" "----------" "----------" "----------" "--------"

for label in "${ordered_labels[@]}"; do
  a_avg="${data_a_avg["${label}"]:-}"
  b_avg="${data_b_avg["${label}"]:-}"
  b_min="${data_b_min["${label}"]:-}"

  a_str="$([[ -n "${a_avg}" ]] && _ms "${a_avg}" || echo "-")"
  b_str="$([[ -n "${b_avg}" ]] && _ms "${b_avg}" || echo "-")"
  bmin_str="$([[ -n "${b_min}" ]] && _ms "${b_min}" || echo "-")"

  if [[ -n "${a_avg}" && -n "${b_avg}" ]]; then
    pct="$(_delta_pct "${a_avg}" "${b_avg}")"
    colored="$(_color_delta "${pct}")"
    printf "  %-40s  %10s  %10s  %10s  %s\n" \
      "${label}" "${a_str}" "${b_str}" "${bmin_str}" "${colored}"
  else
    printf "  %-40s  %10s  %10s  %10s  %8s\n" \
      "${label}" "${a_str}" "${b_str}" "${bmin_str}" "n/a"
  fi
done

echo ""
echo "  Green = faster in B, red = slower in B."
echo "  Use --list to see all run indices, --all for full history table."
echo ""
