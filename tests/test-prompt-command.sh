#!/bin/bash

SCRIPT_DIR=$(dirname -- "$( readlink -f -- "$0"; )";)
source "$SCRIPT_DIR/base.sh"

function test_prompt_command_is_set() {
  source "$SCRIPT_DIR/../gitprompt.sh"

  echo "$PROMPT_COMMAND"
  [[ "$PROMPT_COMMAND" == "setLastCommandState;setGitPrompt" ]]
}

function test_prompt_command_respecting_custom_function() {
  PROMPT_COMMAND="some"
  source "$SCRIPT_DIR/../gitprompt.sh"

  echo "$PROMPT_COMMAND"
  [[ "$PROMPT_COMMAND" == "setLastCommandState;some;setGitPrompt" ]]
}

run_test "test_prompt_command_is_set"
run_test "test_prompt_command_respecting_custom_function"
