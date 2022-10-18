#!/bin/bash

SCRIPT_DIR=$(dirname -- "$( readlink -f -- "$0"; )";)
source "$SCRIPT_DIR/base.sh"

REPO_ROOT="$SCRIPT_DIR/.."

function test_original_prompt_is_restored() {
  GIT_PROMPT_ONLY_IN_REPO=1

  PS1="$"

  # Navigate outside the git repo
  cd "$REPO_ROOT/.."
  source "$SCRIPT_DIR/../gitprompt.sh"
  run_prompt_command

  if [ "$PS1" != "$" ]; then
    echo "PS1: $PS1 != \$"
    return 1
  fi

  # Navigate back into the repo
  cd "$REPO_ROOT"
  run_prompt_command
  if [ "$PS1" == "$" ]; then
    echo "PS1: $PS1 == \$"
    return 1
  fi

  # And navigate again outside the repo
  cd "$REPO_ROOT/.."
  run_prompt_command
  if [ "$PS1" != "$" ]; then
    echo "PS1: $PS1 != \$"
    return 1
  fi
}

run_test "test_original_prompt_is_restored"
