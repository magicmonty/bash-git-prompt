#!/bin/sh

function async_run()
{
  {
    $1 &> /dev/null
  }&
}

function git_prompt_dir()
{
  # assume the gitstatus.py is in the same directory as this script
  # code thanks to http://stackoverflow.com/questions/59895
  if [ -z "$__GIT_PROMPT_DIR" ]; then
    local SOURCE="${BASH_SOURCE[0]}"
    while [ -h "$SOURCE" ]; do
      local DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
      SOURCE="$(readlink "$SOURCE")"
      [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
    done
    __GIT_PROMPT_DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
  fi
}

# gp_set_file_var ENVAR SOMEFILE
#
# If ENVAR is set, check that it's value exists as a readable file.  Otherwise,
# Set ENVAR to the path to SOMEFILE, based on $HOME, $__GIT_PROMPT_DIR, and the
# directory of the current script.  The SOMEFILE can be prefixed with '.', or
# not.
#
# Return 0 (success) if ENVAR not already defined, 1 (failure) otherwise.

function gp_set_file_var() {
  local envar="$1"
  local file="$2"
  if eval "[[ -n \"\$$envar\" && -r \"\$$envar\" ]]" ; then # is envar set to a readable file?
    local basefile
    eval "basefile=\"\`basename \\\"\$$envar\\\"\`\""   # assign basefile
    if [[ "$basefile" = "$file" || "$basefile" = ".$file" ]]; then
      return 0
    fi
  else  # envar is not set, or it's set to a different file than requested
    eval "$envar="      # set empty envar
    gp_maybe_set_envar_to_path "$envar" "$HOME/.$file" "$HOME/$file" "$HOME/lib/$file" && return 0
    git_prompt_dir
    gp_maybe_set_envar_to_path "$envar" "$__GIT_PROMPT_DIR/$file" "${0##*/}/$file"     && return 0
  fi
  return 1
}

# gp_maybe_set_envar_to_path ENVAR FILEPATH ...
#
# return 0 (true) if any FILEPATH is readable, set ENVAR to it
# return 1 (false) if not

function gp_maybe_set_envar_to_path(){
  local envar="$1"
  shift
  local file
  for file in "$@" ; do
    if [[ -r "$file" ]]; then
      eval "$envar=\"$file\""
      return 0
    fi
  done
  return 1
}

# git_prompt_reset
#
# unsets selected GIT_PROMPT variables, causing the next prompt callback to
# recalculate them from scratch.

git_prompt_reset() {
  local var
  for var in GIT_PROMPT_DIR __GIT_PROMPT_COLORS_FILE __PROMPT_COLORS_FILE __GIT_STATUS_CMD ; do
    unset $var
  done
}

function git_prompt_config()
{
  #Checking if root to change output
  _isroot=false
  [[ $UID -eq 0 ]] && _isroot=true

  # There are two files related to colors:
  #
  #  prompt-colors.sh -- sets generic color names suitable for bash `PS1` prompt
  #  git-prompt-colors.sh -- sets the GIT_PROMPT color scheme, using names from prompt-colors.sh

  if gp_set_file_var __PROMPT_COLORS_FILE prompt-colors.sh ; then
    source "$__PROMPT_COLORS_FILE"        # outsource the color defs
  else
    echo 1>&2 "Cannot find prompt-colors.sh!"
  fi

  # source the user's ~/.git-prompt-colors.sh file, or the one that should be
  # sitting in the same directory as this script

  if gp_set_file_var __GIT_PROMPT_COLORS_FILE git-prompt-colors.sh ; then
    source "$__GIT_PROMPT_COLORS_FILE"
  else
    echo 1>&2 "Cannot find git-prompt-colors.sh!"
  fi

  if [ $GIT_PROMPT_LAST_COMMAND_STATE = 0 ]; then
    LAST_COMMAND_INDICATOR="$GIT_PROMPT_COMMAND_OK";
  else
    LAST_COMMAND_INDICATOR="$GIT_PROMPT_COMMAND_FAIL";
  fi

  # replace _LAST_COMMAND_STATE_ token with the actual state
  LAST_COMMAND_INDICATOR="${LAST_COMMAND_INDICATOR/_LAST_COMMAND_STATE_/${GIT_PROMPT_LAST_COMMAND_STATE}}"

  # Do this only once to define PROMPT_START and PROMPT_END

  if [[ -z "$PROMPT_START" || -z "$PROMPT_END" ]]; then

    # Various variables you might want for your PS1 prompt instead
    local Time12a="\$(date +%H:%M)"
    # local Time12a="(\$(date +%H:%M:%S))"
    # local Time12a="(\@))"
    local PathShort="\w"

    if [[ -z "$GIT_PROMPT_START" ]] ; then
      if $_isroot; then
        PROMPT_START="$GIT_PROMPT_START_ROOT"
      else
        PROMPT_START="$GIT_PROMPT_START_USER"
      fi
    else
      PROMPT_START="$GIT_PROMPT_START"
    fi

    if [[ -z "$GIT_PROMPT_END" ]] ; then
      if $_isroot; then
        PROMPT_END="$GIT_PROMPT_END_ROOT"
      else
        PROMPT_END="$GIT_PROMPT_END_USER"
      fi
    else
      PROMPT_END="$GIT_PROMPT_END"
    fi
  fi

  # set GIT_PROMPT_LEADING_SPACE to 0 if you want to have no leading space in front of the GIT prompt
  if [[ "$GIT_PROMPT_LEADING_SPACE" = 0 ]]; then
    PROMPT_LEADING_SPACE=""
  else
    PROMPT_LEADING_SPACE=" "
  fi

  if [[ "$GIT_PROMPT_ONLY_IN_REPO" = 1 ]]; then
    EMPTY_PROMPT="$OLD_GITPROMPT"
  else
    local ps=""
    if [[ -n "$VIRTUAL_ENV" ]]; then
      VENV=$(basename "${VIRTUAL_ENV}")
      ps="${ps}${GIT_PROMPT_VIRTUALENV/_VIRTUALENV_/${VENV}}"
    fi
    if [[ -n "$CONDA_DEFAULT_ENV" ]]; then
      VENV=$(basename "${CONDA_DEFAULT_ENV}")
      ps="${ps}${GIT_PROMPT_VIRTUALENV/_VIRTUALENV_/${VENV}}"
    fi
    ps="$ps$PROMPT_START$($prompt_callback)$PROMPT_END"
    EMPTY_PROMPT="${ps/_LAST_COMMAND_INDICATOR_/${LAST_COMMAND_INDICATOR}}"
  fi

  # fetch remote revisions every other $GIT_PROMPT_FETCH_TIMEOUT (default 5) minutes
  GIT_PROMPT_FETCH_TIMEOUT=${1-5}
  if [[ -z "$__GIT_STATUS_CMD" ]] ; then          # if GIT_STATUS_CMD not defined..
    git_prompt_dir
    if ! gp_maybe_set_envar_to_path __GIT_STATUS_CMD "$__GIT_PROMPT_DIR/gitstatus.sh" "$__GIT_PROMPT_DIR/gitstatus.py" ; then
      echo 1>&2 "Cannot find gitstatus.sh or gitstatus.py!"
    fi
    # __GIT_STATUS_CMD defined
  fi
}

function setLastCommandState() {
  GIT_PROMPT_LAST_COMMAND_STATE=$?
}

function setGitPrompt() {
  local EMPTY_PROMPT
  local __GIT_STATUS_CMD

  git_prompt_config

  local repo=`git rev-parse --show-toplevel 2> /dev/null`
  if [[ ! -e "$repo" ]]; then
    PS1="$EMPTY_PROMPT"
    return
  fi

  local FETCH_REMOTE_STATUS=1
  if [[ "$GIT_PROMPT_FETCH_REMOTE_STATUS" = 0 ]]; then
    FETCH_REMOTE_STATUS=0
  fi

  if [[ -e "$repo/.bash-git-rc" ]]; then
    source "$repo/.bash-git-rc"
  fi

  if [ "$FETCH_REMOTE_STATUS" = 1 ]; then
    checkUpstream
  fi

  updatePrompt
}

function checkUpstream() {
  local GIT_PROMPT_FETCH_TIMEOUT
  git_prompt_config

  local FETCH_HEAD="$repo/.git/FETCH_HEAD"
  # Fech repo if local is stale for more than $GIT_FETCH_TIMEOUT minutes
  if [[ ! -e "$FETCH_HEAD"  ||  -e `find "$FETCH_HEAD" -mmin +$GIT_PROMPT_FETCH_TIMEOUT` ]]
  then
    if [[ -n $(git remote show) ]]; then
      (
        async_run "git fetch --quiet"
        disown -h
      )
    fi
  fi
}

function updatePrompt() {
  local LAST_COMMAND_INDICATOR
  local PROMPT_LEADING_SPACE
  local PROMPT_START
  local PROMPT_END
  local EMPTY_PROMPT
  local Blue="\[\033[0;34m\]"

  git_prompt_config

  local -a GitStatus
  GitStatus=($("$__GIT_STATUS_CMD" 2>/dev/null))

  local GIT_BRANCH=${GitStatus[0]}
  local GIT_REMOTE=${GitStatus[1]}
  if [[ "." == "$GIT_REMOTE" ]]; then
    unset GIT_REMOTE
  fi
  local GIT_STAGED=${GitStatus[2]}
  local GIT_CONFLICTS=${GitStatus[3]}
  local GIT_CHANGED=${GitStatus[4]}
  local GIT_UNTRACKED=${GitStatus[5]}
  local GIT_STASHED=${GitStatus[6]}
  local GIT_CLEAN=${GitStatus[7]}

  local NEW_PROMPT="$EMPTY_PROMPT"
  if [[ -n "$GitStatus" ]]; then
    local STATUS="${PROMPT_LEADING_SPACE}${GIT_PROMPT_PREFIX}${GIT_PROMPT_BRANCH}${GIT_BRANCH}${ResetColor}"

    # __add_status KIND VALEXPR INSERT
    # eg: __add_status  'STAGED' '-ne 0'

    __chk_gitvar_status() {
      local v
      if [[ "x$2" == "x-n" ]] ; then
        v="$2 \"\$GIT_$1\""
      else
        v="\$GIT_$1 $2"
      fi
      if eval "test $v" ; then
        if [[ $# -lt 2 || "$3" != '-' ]]; then
          __add_status "\$GIT_PROMPT_$1\$GIT_$1\$ResetColor"
        else
          __add_status "\$GIT_PROMPT_$1\$ResetColor"
        fi
      fi
    }

    __add_gitvar_status() {
      __add_status "\$GIT_PROMPT_$1\$GIT_$1\$ResetColor"
    }

    # __add_status SOMETEXT
    __add_status() {
      eval "STATUS=\"$STATUS$1\""
    }

    __chk_gitvar_status 'REMOTE'     '-n'
    __add_status        "$GIT_PROMPT_SEPARATOR"
    __chk_gitvar_status 'STAGED'     '-ne 0'
    __chk_gitvar_status 'CONFLICTS'  '-ne 0'
    __chk_gitvar_status 'CHANGED'    '-ne 0'
    __chk_gitvar_status 'UNTRACKED'  '-ne 0'
    __chk_gitvar_status 'STASHED'    '-ne 0'
    __chk_gitvar_status 'CLEAN'      '-eq 1'   -
    __add_status        "$ResetColor$GIT_PROMPT_SUFFIX"

    NEW_PROMPT=""
    if [[ -n "$VIRTUAL_ENV" ]]; then
      VENV=$(basename "${VIRTUAL_ENV}")
      NEW_PROMPT="$NEW_PROMPT${GIT_PROMPT_VIRTUALENV/_VIRTUALENV_/${VENV}}"
    fi

    if [[ -n "$CONDA_DEFAULT_ENV" ]]; then
      VENV=$(basename "${CONDA_DEFAULT_ENV}")
      NEW_PROMPT="$NEW_PROMPT${GIT_PROMPT_VIRTUALENV/_VIRTUALENV_/${VENV}}"
    fi

    NEW_PROMPT="$NEW_PROMPT$PROMPT_START$($prompt_callback)$STATUS$PROMPT_END"
  else
    NEW_PROMPT="$EMPTY_PROMPT"
  fi

  PS1="${NEW_PROMPT/_LAST_COMMAND_INDICATOR_/${LAST_COMMAND_INDICATOR}}"
}

function prompt_callback_default {
    return
}

function gp_install_prompt {
  if [ "`type -t prompt_callback`" = 'function' ]; then
      prompt_callback="prompt_callback"
  else
      prompt_callback="prompt_callback_default"
  fi

  if [ -z "$OLD_GITPROMPT" ]; then
    OLD_GITPROMPT=$PS1
  fi

  if [ -z "$PROMPT_COMMAND" ]; then
    PROMPT_COMMAND=setGitPrompt
  else
    PROMPT_COMMAND=${PROMPT_COMMAND%% }; # remove trailing spaces
    PROMPT_COMMAND=${PROMPT_COMMAND%\;}; # remove trailing semi-colon

    local new_entry="setGitPrompt"
    case ";$PROMPT_COMMAND;" in
      *";$new_entry;"*)
        # echo "PROMPT_COMMAND already contains: $new_entry"
        :;;
      *)
        PROMPT_COMMAND="$PROMPT_COMMAND;$new_entry"
        # echo "PROMPT_COMMAND does not contain: $new_entry"
        ;;
    esac
  fi

  local setLastCommandStateEntry="setLastCommandState"
  case ";$PROMPT_COMMAND;" in
    *";$setLastCommandStateEntry;"*)
      # echo "PROMPT_COMMAND already contains: $setLastCommandStateEntry"
      :;;
    *)
      PROMPT_COMMAND="$setLastCommandStateEntry;$PROMPT_COMMAND"
      # echo "PROMPT_COMMAND does not contain: $setLastCommandStateEntry"
      ;;
  esac

  git_prompt_dir
  source "$__GIT_PROMPT_DIR/git-prompt-help.sh"
}

gp_install_prompt
