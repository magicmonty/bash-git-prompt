set +e

export __GIT_PROMPT_USR_CMDS=mv mv_mv rm rm_rm gitWrap;

### GIT {mv|rm} wrapper
gitWrap() {
  local cmd="$1";
  case "$cmd" in
    mv) cmd="mv"; ;;
    rm) cmd="rm"; ;;
  esac;
  shift;
  git "$cmd" "$@";
}

mv() {
  gitWrap "$FUNCNAME" "$@";
}

rm() {
  gitWrap "$FUNCNAME" "$@";
}

mv_mv() {
  /bin/mv "$@";
}

rm_rm() {
  /bin/rm "$@";
}
