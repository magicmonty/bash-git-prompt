#!/usr/bin/env bash
# shellcheck disable=SC1090,SC1091
# benchmark.sh -- measure bash-git-prompt prompt latency
#
# Usage:
#   ./tests/benchmark.sh [iterations]       (default: 20, auto-saves results)
#   ./tests/benchmark.sh [iterations] --no-save   (skip saving)
#
# Results are appended to tests/benchmark-results.tsv.
# Use tests/benchmark-compare.sh to view progress over time.

SCRIPT_DIR=$(dirname -- "$(readlink -f -- "$0")")
REPO_DIR=$(dirname -- "${SCRIPT_DIR}")
RESULTS_FILE="${SCRIPT_DIR}/benchmark-results.tsv"

ITERATIONS=20
SAVE=1
for arg in "$@"; do
  case "${arg}" in
    --no-save) SAVE=0 ;;
    [0-9]*)    ITERATIONS="${arg}" ;;
  esac
done

# ── helpers ────────────────────────────────────────────────────────────────────

_ms() {
  local ns="${1}"
  printf "%d.%d" "$(( ns / 1000000 ))" "$(( (ns % 1000000) / 100000 ))"
}

_ns() {
  date +%s%N
}

# Collected results: "label\tmin_ns\tavg_ns\tmax_ns"
declare -a _results=()

_record() {
  local label="${1}" min="${2}" avg="${3}" max="${4}"
  printf "  %-40s  min=%s  avg=%s  max=%s ms\n" \
    "${label}" "$(_ms "${min}")" "$(_ms "${avg}")" "$(_ms "${max}")"
  _results+=("${label}"$'\t'"${min}"$'\t'"${avg}"$'\t'"${max}")
}

_bench() {
  local label="${1}"; shift
  local iters="${1}"; shift
  local total=0 min=99999999999 max=0 elapsed t0 t1

  for (( i=0; i<iters; i++ )); do
    t0=$(_ns)
    "$@" >/dev/null 2>&1
    t1=$(_ns)
    elapsed=$(( t1 - t0 ))
    (( elapsed < min )) && min=${elapsed}
    (( elapsed > max )) && max=${elapsed}
    (( total += elapsed ))
  done

  _record "${label}" "${min}" "$(( total / iters ))" "${max}"
}

_bench_fn() {
  local label="${1}"; shift
  local iters="${1}"; shift
  local fn="${1}"; shift
  local total=0 min=99999999999 max=0 elapsed t0 t1

  for (( i=0; i<iters; i++ )); do
    t0=$(_ns)
    "${fn}" "$@" >/dev/null 2>&1
    t1=$(_ns)
    elapsed=$(( t1 - t0 ))
    (( elapsed < min )) && min=${elapsed}
    (( elapsed > max )) && max=${elapsed}
    (( total += elapsed ))
  done

  _record "${label}" "${min}" "$(( total / iters ))" "${max}"
}

# ── environment ────────────────────────────────────────────────────────────────

GIT_SHA=$(git -C "${REPO_DIR}" rev-parse --short HEAD 2>/dev/null || echo "unknown")
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
IN_REPO=$(git rev-parse --is-inside-work-tree 2>/dev/null || echo "no")

echo ""
echo "=== bash-git-prompt benchmark ==="
echo "  timestamp  : ${TIMESTAMP}"
echo "  git sha    : ${GIT_SHA}"
echo "  iterations : ${ITERATIONS}"
echo "  git version: $(git --version)"
echo "  bash version: ${BASH_VERSION}"
echo "  in git repo: ${IN_REPO}"
[[ "${SAVE}" == 1 ]] && echo "  saving to  : ${RESULTS_FILE}"
echo ""

# ── section 1: subprocess baseline ────────────────────────────────────────────

echo "── 1. Subprocess baseline ──────────────────────────────────────────────"
_bench "git rev-parse --git-dir"         "${ITERATIONS}"  git rev-parse --git-dir
_bench "git rev-parse --show-toplevel"   "${ITERATIONS}"  git rev-parse --show-toplevel
_bench "git status --porcelain --branch" "${ITERATIONS}"  \
  git --no-optional-locks status --untracked-files=normal --porcelain --branch
_bench "git remote"                      "${ITERATIONS}"  git remote
echo ""

# ── section 2: status backends ────────────────────────────────────────────────

echo "── 2. Status backends ──────────────────────────────────────────────────"
[[ -f "${REPO_DIR}/gitstatus.sh" ]] && \
  _bench "gitstatus.sh (bash)"   "${ITERATIONS}"  bash "${REPO_DIR}/gitstatus.sh"
[[ -f "${REPO_DIR}/gitstatus.py" ]] && \
  _bench "gitstatus.py (python)" "${ITERATIONS}"  python3 "${REPO_DIR}/gitstatus.py"
echo ""

# ── section 3: full prompt pipeline ───────────────────────────────────────────

echo "── 3. Full prompt pipeline (setGitPrompt) ──────────────────────────────"
_time_setgitprompt() {
  bash --norc --noprofile -c "
    source '${REPO_DIR}/gitprompt.sh' 2>/dev/null
    GIT_PROMPT_FETCH_REMOTE_STATUS=0
    setGitPrompt
  "
}
_bench "setGitPrompt (fetch disabled)" "${ITERATIONS}"  _time_setgitprompt
echo ""

# ── section 4: internal functions ─────────────────────────────────────────────

echo "── 4. Internal functions (sourced) ─────────────────────────────────────"
export GIT_PROMPT_FETCH_REMOTE_STATUS=0
# shellcheck disable=SC1090
source "${REPO_DIR}/gitprompt.sh" 2>/dev/null

_bench_fn "git_prompt_config"            "${ITERATIONS}"  git_prompt_config
_bench_fn "git_prompt_load_colors"       "${ITERATIONS}"  git_prompt_load_colors
_bench_fn "git_prompt_load_theme"        "${ITERATIONS}"  git_prompt_load_theme
_bench_fn "createPrivateIndex"           "${ITERATIONS}"  createPrivateIndex
_bench_fn "gp_add_virtualenv_to_prompt"  "${ITERATIONS}"  gp_add_virtualenv_to_prompt
echo ""

# ── section 5: stash counting ─────────────────────────────────────────────────

echo "── 5. Stash count: loop vs wc -l ───────────────────────────────────────"
git_dir="$(git rev-parse --git-dir 2>/dev/null)"
stash_file="${git_dir}/logs/refs/stash"
if [[ -f "${stash_file}" ]]; then
  _count_loop() {
    local n=0
    while IFS='' read -r line || [[ -n "${line}" ]]; do (( n++ )); done < "${stash_file}"
    echo "${n}"
  }
  _count_wc() { wc -l < "${stash_file}"; }
  _bench_fn "stash count (read loop)"  "${ITERATIONS}"  _count_loop
  _bench_fn "stash count (wc -l)"      "${ITERATIONS}"  _count_wc
else
  echo "  (no stash file — create a stash entry to compare methods)"
fi
echo ""

# ── save results ───────────────────────────────────────────────────────────────

if [[ "${SAVE}" == 1 ]]; then
  # Write header if file is new
  if [[ ! -f "${RESULTS_FILE}" ]]; then
    printf "timestamp\tgit_sha\titerations\tlabel\tmin_ns\tavg_ns\tmax_ns\n" \
      > "${RESULTS_FILE}"
  fi

  for entry in "${_results[@]}"; do
    IFS=$'\t' read -r label min avg max <<< "${entry}"
    printf "%s\t%s\t%d\t%s\t%d\t%d\t%d\n" \
      "${TIMESTAMP}" "${GIT_SHA}" "${ITERATIONS}" "${label}" "${min}" "${avg}" "${max}" \
      >> "${RESULTS_FILE}"
  done

  echo "  Saved ${#_results[@]} results to ${RESULTS_FILE}"
  echo "  Run ./tests/benchmark-compare.sh to see progress."
fi

echo ""
echo "=== done ==="
echo ""
