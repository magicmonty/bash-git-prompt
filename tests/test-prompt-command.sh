#!/bin/bash

SCRIPT_DIR=$(dirname -- "$( readlink -f -- "$0"; )";)
source "$SCRIPT_DIR/base.sh"

function test_prompt_command_is_set() {
  unset PROMPT_COMMAND
  source "$SCRIPT_DIR/../gitprompt.sh"

  if [[ "$(declare -p PROMPT_COMMAND 2>/dev/null)" == "declare -a"* ]]; then
    echo "${PROMPT_COMMAND[*]}"
    [[ "${PROMPT_COMMAND[0]}" == "setLastCommandState" && "${PROMPT_COMMAND[-1]}" == "setGitPrompt" ]]
  else
    echo "$PROMPT_COMMAND"
    [[ "$PROMPT_COMMAND" == "setLastCommandState;setGitPrompt" ]]
  fi
}

function test_prompt_command_respecting_custom_function() {
  # unset first to ensure PROMPT_COMMAND is a plain string, not an array
  # (it may be an array after a previous test ran in the same shell)
  unset PROMPT_COMMAND
  PROMPT_COMMAND="some"
  source "$SCRIPT_DIR/../gitprompt.sh"

  # PROMPT_COMMAND starts as a string so gp_install_prompt takes the string branch
  echo "$PROMPT_COMMAND"
  [[ "$PROMPT_COMMAND" == "setLastCommandState;some;setGitPrompt" ]]
}

run_test "test_prompt_command_is_set"
run_test "test_prompt_command_respecting_custom_function"
