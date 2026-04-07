#!/bin/bash
# shellcheck disable=SC1091

SCRIPT_DIR=$(dirname -- "$( readlink -f -- "$0"; )";)
source "$SCRIPT_DIR/base.sh"

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

# Create a minimal git repo with one commit in a temp directory.
# Prints the repo path; caller must rm -rf it when done.
_make_temp_repo() {
    local dir
    dir=$(mktemp -d)
    git -C "$dir" init -q
    git -C "$dir" config user.email "test@test.com"
    git -C "$dir" config user.name "Test"
    echo "init" > "$dir/file.txt"
    git -C "$dir" add .
    git -C "$dir" commit -q -m "initial commit"
    echo "$dir"
}

# Simulate an interactive rebase in progress by writing the state files
# that git itself would create.
_start_fake_rebase() {
    local git_dir="$1"
    mkdir -p "$git_dir/rebase-merge"
    touch   "$git_dir/rebase-merge/interactive"
    echo "1" > "$git_dir/rebase-merge/msgnum"
    echo "3" > "$git_dir/rebase-merge/end"
}

_stop_fake_rebase() {
    rm -rf "${1}/rebase-merge"
}

# ---------------------------------------------------------------------------
# Test 1: createPrivateIndex makes a copy during rebase, not otherwise
# ---------------------------------------------------------------------------

function test_createprivateindex_copy_path() {
    local repo
    repo=$(_make_temp_repo)
    local git_dir="$repo/.git"

    local orig_tmpdir="${TMPDIR:-}"
    export TMPDIR="$repo/.tmp"
    mkdir -p "$TMPDIR"

    cd "$repo" || return 1
    export GIT_PROMPT_FETCH_REMOTE_STATUS=0
    source "$SCRIPT_DIR/../gitprompt.sh" 2>/dev/null

    # ── outside rebase: should return the real index, no copy ──────────────
    local idx_normal
    idx_normal=$(createPrivateIndex)

    if [[ "$idx_normal" == *"git-index-private"* ]]; then
        echo "FAIL: createPrivateIndex returned a copy outside rebase: $idx_normal"
        rm -rf "$repo"
        return 1
    fi

    # ── during rebase: should return a temp copy ────────────────────────────
    _start_fake_rebase "$git_dir"

    local idx_rebase
    idx_rebase=$(createPrivateIndex)

    if [[ "$idx_rebase" != *"git-index-private"* ]]; then
        echo "FAIL: createPrivateIndex did not return a copy during rebase: $idx_rebase"
        _stop_fake_rebase "$git_dir"
        rm -rf "$repo"
        return 1
    fi

    # Temp copy must exist on disk
    if [[ ! -f "$idx_rebase" ]]; then
        echo "FAIL: private index copy does not exist on disk: $idx_rebase"
        _stop_fake_rebase "$git_dir"
        rm -rf "$repo"
        return 1
    fi

    rm -f "$idx_rebase"
    _stop_fake_rebase "$git_dir"
    TMPDIR="$orig_tmpdir"
    rm -rf "$repo"
    return 0
}

# ---------------------------------------------------------------------------
# Test 2: prompt shows REBASE-i state and cleans up temp index file
# ---------------------------------------------------------------------------

function test_prompt_shows_rebase_state() {
    local repo
    repo=$(_make_temp_repo)
    local git_dir="$repo/.git"

    # Use repo dir as TMPDIR so temp index files are isolated and cleaned up with $repo
    local orig_tmpdir="${TMPDIR:-}"
    export TMPDIR="$repo/.tmp"
    mkdir -p "$TMPDIR"

    cd "$repo" || return 1
    export GIT_PROMPT_FETCH_REMOTE_STATUS=0
    source "$SCRIPT_DIR/../gitprompt.sh" 2>/dev/null

    _start_fake_rebase "$git_dir"

    run_prompt_command

    # GIT_BRANCH is exported by updatePrompt and contains the branch+state,
    # e.g. "master|REBASE-i". PS1 contains a literal ${GIT_BRANCH} that is
    # only expanded at display time, so we check GIT_BRANCH directly.
    if [[ "$GIT_BRANCH" != *"REBASE-i"* ]]; then
        echo "FAIL: expected REBASE-i in GIT_BRANCH, got: $GIT_BRANCH"
        _stop_fake_rebase "$git_dir"
        TMPDIR="$orig_tmpdir"
        rm -rf "$repo"
        return 1
    fi

    # updatePrompt must have cleaned up the private index copy
    local leftover
    leftover=$(ls "$repo/.tmp/git-index-private"* 2>/dev/null)
    if [[ -n "$leftover" ]]; then
        echo "FAIL: private index copy not cleaned up: $leftover"
        _stop_fake_rebase "$git_dir"
        TMPDIR="$orig_tmpdir"
        rm -rf "$repo"
        return 1
    fi

    _stop_fake_rebase "$git_dir"
    TMPDIR="$orig_tmpdir"
    rm -rf "$repo"
    return 0
}

# ---------------------------------------------------------------------------
# Test 3: prompt recovers cleanly after rebase ends (back to normal index)
# ---------------------------------------------------------------------------

function test_prompt_recovers_after_rebase() {
    local repo
    repo=$(_make_temp_repo)
    local git_dir="$repo/.git"

    local orig_tmpdir="${TMPDIR:-}"
    export TMPDIR="$repo/.tmp"
    mkdir -p "$TMPDIR"

    cd "$repo" || return 1
    export GIT_PROMPT_FETCH_REMOTE_STATUS=0
    source "$SCRIPT_DIR/../gitprompt.sh" 2>/dev/null

    # Run once during rebase
    _start_fake_rebase "$git_dir"
    run_prompt_command
    local branch_during="$GIT_BRANCH"

    # Run again after rebase ends
    _stop_fake_rebase "$git_dir"
    run_prompt_command
    local branch_after="$GIT_BRANCH"

    if [[ "$branch_after" == *"REBASE"* ]]; then
        echo "FAIL: REBASE still in GIT_BRANCH after rebase ended: $branch_after"
        rm -rf "$repo"
        return 1
    fi

    if [[ "$branch_during" != *"REBASE"* ]]; then
        echo "FAIL: REBASE not shown in GIT_BRANCH during rebase: $branch_during"
        TMPDIR="$orig_tmpdir"
        rm -rf "$repo"
        return 1
    fi

    TMPDIR="$orig_tmpdir"
    rm -rf "$repo"
    return 0
}

run_test "test_createprivateindex_copy_path"
run_test "test_prompt_shows_rebase_state"
run_test "test_prompt_recovers_after_rebase"
