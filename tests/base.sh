
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
