#!/bin/bash
# shellcheck disable=SC1091

SCRIPT_DIR=$(dirname -- "$( readlink -f -- "$0"; )";)
source "$SCRIPT_DIR/base.sh"

function test_stash_count_in_linked_worktree() {
  local repo worktree status stash_count
  repo=$(mktemp -d)
  worktree="$repo/linked"

  git -C "$repo" init -q || { rm -rf "$repo"; return 1; }
  git -C "$repo" config user.email "test@test.com"
  git -C "$repo" config user.name "Test"
  echo "initial" > "$repo/file.txt"
  git -C "$repo" add file.txt
  git -C "$repo" commit -q -m "initial commit" || { rm -rf "$repo"; return 1; }

  echo "stashed" > "$repo/file.txt"
  git -C "$repo" stash push -q -m "linked worktree test" || { rm -rf "$repo"; return 1; }
  git -C "$repo" worktree add --quiet -b linked-test "$worktree" HEAD || {
    rm -rf "$repo"
    return 1
  }

  status=$(cd "$worktree" && "$SCRIPT_DIR/../gitstatus.sh")
  stash_count=$(printf '%s\n' "$status" | sed -n '9p')

  git -C "$repo" worktree remove --force "$worktree" >/dev/null 2>&1
  rm -rf "$repo"

  if [[ "$stash_count" != "1" ]]; then
    echo "FAIL: expected 1 stash in linked worktree, got: $stash_count"
    return 1
  fi

  return 0
}

run_test "test_stash_count_in_linked_worktree"
