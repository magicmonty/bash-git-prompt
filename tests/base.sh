
function run_test() {
  test_function="$1"

  if [ -z "$test_function" ]; then
    echo "Test function missing. Specify one."
    exit 2
  fi

  echo ""
  echo "--> Running $test_function"
  if $test_function ; then
    echo "++ Test successful"
  else
    echo "-- Test failed"
    exit 1
  fi
}

function run_prompt_command() {
  # bash 5.1+ may store PROMPT_COMMAND as an array; handle both forms
  if [[ "$(declare -p PROMPT_COMMAND 2>/dev/null)" == "declare -a"* ]]; then
    for cmd in "${PROMPT_COMMAND[@]}"; do
      $cmd
    done
  else
    IFS=';' read -ra COMMANDS <<< "$PROMPT_COMMAND"
    for cmd in "${COMMANDS[@]}"; do
      $cmd
    done
  fi
}
