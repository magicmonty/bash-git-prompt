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
  if [ -z "${__GIT_PROMPT_DIR}" ]; then
    local SOURCE="${BASH_SOURCE[0]}"
    while [ -h "${SOURCE}" ]; do
      local DIR="$( cd -P "$( dirname "${SOURCE}" )" && pwd )"
      SOURCE="$(readlink "${SOURCE}")"
      [[ $SOURCE != /* ]] && SOURCE="${DIR}/${SOURCE}"
    done
    __GIT_PROMPT_DIR="$( cd -P "$( dirname "${SOURCE}" )" && pwd )"
  fi
}

# gp_set_file_var ENVAR SOMEFILE
#
# Set ENVAR to the path to SOMEFILE, based on $HOME, $__GIT_PROMPT_DIR, and the
# directory of the current script.  The SOMEFILE can be prefixed with '.', or
# not.
#
# Return 0 (success) if ENVAR not already defined, 1 (failure) otherwise.

function gp_set_file_var() {
  local envar="$1"
  local file="$2"
  if eval "test -z \"\$$envar\"" ; then
    eval "$envar="      # set empty envar
    gp_maybe_set_envar_to_path "$envar" "$HOME/.$file"            && return 0
    gp_maybe_set_envar_to_path "$envar" "$HOME/$file"             && return 0
    gp_maybe_set_envar_to_path "$envar" "$HOME/lib/$file"         && return 0
    git_prompt_dir
    gp_maybe_set_envar_to_path "$envar" "$__GIT_PROMPT_DIR/$file" && return 0
    gp_maybe_set_envar_to_path "$envar" "${0##*/}/$file"          && return 0
  fi
  return 1
}

# gp_maybe_set_envar_to_path ENVAR FILEPATH
#
# return 0 (true) if FILEPATH is readable, set ENVAR to it
# return 1 (false) if not

function gp_maybe_set_envar_to_path(){
  local envar="$1"
  local file="$2"
  if [[ -r "$file" ]]; then
    eval "$envar=\"$file\""
    return 0
  fi
  return 1
}

function git_prompt_config()
{

  # There are two files related to colors:
  #
  #  prompt-colors.sh -- sets generic color names suitable for bash `PS1` prompt
  #  git-prompt-colors.sh -- sets the GIT_PROMPT color scheme, using names from prompt-colors.sh

  if gp_set_file_var __PROMPT_COLORS_SH prompt-colors.sh ; then

    if [[ -n "${__PROMPT_COLORS_SH}" ]]; then
      source "${__PROMPT_COLORS_SH}"        # outsource the color defs
    else
      echo 1>&2 "Cannot find prompt-colors.sh!"
    fi
  fi

  # source the user's ~/.git-prompt-colors.sh file, or the one that should be
  # sitting in the same directory as this script

  if gp_set_file_var __GIT_PROMPT_COLORS_FILE git-prompt-colors.sh ; then

    # if the envar is defined, source the file for custom colors
    if [[ -n "${__GIT_PROMPT_COLORS_FILE}" ]]; then
      source "${__GIT_PROMPT_COLORS_FILE}"
    else
      echo 1>&2 "Cannot find git-prompt-colors.sh!"
    fi
  fi

  # Do this only once to define PROMPT_START and PROMPT_END

  if [[ -z "$PROMPT_START" || -z "$PROMPT_END" ]]; then

    # Various variables you might want for your PS1 prompt instead
    local Time12a="\$(date +%H:%M)"
    # local Time12a="(\$(date +%H:%M:%S))"
    # local Time12a="(\@))"
    local PathShort="\w"

    if [[ -z "${GIT_PROMPT_START}" ]] ; then
      PROMPT_START="${Yellow}${PathShort}${ResetColor}"
    else
      PROMPT_START="${GIT_PROMPT_START}"
    fi

    if [[ -z "${GIT_PROMPT_END}" ]] ; then
      PROMPT_END=" \n${White}${Time12a}${ResetColor} $ "
    else
      PROMPT_END="${GIT_PROMPT_END}"
    fi
  fi

  EMPTY_PROMPT="${PROMPT_START}$($prompt_callback)${PROMPT_END}"

  # fetch remote revisions every other $GIT_PROMPT_FETCH_TIMEOUT (default 5) minutes
  GIT_PROMPT_FETCH_TIMEOUT=${1-5}
  if [[ -z "$__GIT_STATUS_CMD" ]] ; then          # if GIT_STATUS_CMD not defined..
    git_prompt_dir
    local sfx file
    # look first for a '.sh' version, then use the python version
    for sfx in sh py ; do
      file="$__GIT_PROMPT_DIR/gitstatus.$sfx"
      if [[ -x "$file" ]]; then
        __GIT_STATUS_CMD="$file"
        break
      fi
    done
  fi
}

function setGitPrompt() {

  local EMPTY_PROMPT
  local __GIT_STATUS_CMD

  git_prompt_config

  local repo=`git rev-parse --show-toplevel 2> /dev/null`
  if [[ ! -e "${repo}" ]]; then
    PS1="${EMPTY_PROMPT}"
    return
  fi

  checkUpstream
  updatePrompt
}

function checkUpstream() {
  local GIT_PROMPT_FETCH_TIMEOUT
  git_prompt_config

  local FETCH_HEAD="${repo}/.git/FETCH_HEAD"
  # Fech repo if local is stale for more than $GIT_FETCH_TIMEOUT minutes
  if [[ ! -e "${FETCH_HEAD}"  ||  -e `find "${FETCH_HEAD}" -mmin +${GIT_PROMPT_FETCH_TIMEOUT}` ]]
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
  local PROMPT_START
  local PROMPT_END
  local EMPTY_PROMPT
  local __GIT_STATUS_CMD

  git_prompt_config

  local -a GitStatus
  GitStatus=($("${__GIT_STATUS_CMD}" 2>/dev/null))

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

  if [[ -n "${GitStatus}" ]]; then
    local STATUS=" ${GIT_PROMPT_PREFIX}${GIT_PROMPT_BRANCH}${GIT_BRANCH}${ResetColor}"

    # __add_status KIND VALEXPR INSERT
    # eg: __add_status  'STAGED' '-ne 0'

    __chk_gitvar_status() {
      local v
      if [[ "x$2" == "x-n" ]] ; then
        v="$2 \"\${GIT_$1}\""
      else
        v="\${GIT_$1} $2"
      fi
      if eval "test $v" ; then
        if [[ $# -lt 2 || "$3" != '-' ]]; then
          __add_status "\${GIT_PROMPT_$1}\${GIT_$1}\${ResetColor}"
        else
          __add_status "\${GIT_PROMPT_$1}\${ResetColor}"
        fi
      fi
    }

    __add_gitvar_status() {
      __add_status "\${GIT_PROMPT_$1}\${GIT_$1}\${ResetColor}"
    }

    # __add_status SOMETEXT
    __add_status() {
      eval "STATUS=\"${STATUS}$1\""
    }

    __chk_gitvar_status 'REMOTE'     '-n'
    __add_status        "$GIT_PROMPT_SEPARATOR"
    __chk_gitvar_status 'STAGED'     '-ne 0'
    __chk_gitvar_status 'CONFLICTS'  '-ne 0'
    __chk_gitvar_status 'CHANGED'    '-ne 0'
    __chk_gitvar_status 'UNTRACKED'  '-ne 0'
    __chk_gitvar_status 'STASHED'    '-ne 0'
    __chk_gitvar_status 'CLEAN'      '-eq 1'   -
    __add_status        "${ResetColor}$GIT_PROMPT_SUFFIX"

    PS1="${PROMPT_START}$($prompt_callback)${STATUS}${PROMPT_END}"
    if [[ -n "${VIRTUAL_ENV}" ]]; then
      PS1="${Blue}($(basename "${VIRTUAL_ENV}"))${ResetColor} ${PS1}"
    fi

  else
    PS1="${EMPTY_PROMPT}"
  fi
}

function prompt_callback_default {
    return
}

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
  PROMPT_COMMAND="$PROMPT_COMMAND;setGitPrompt"
fi

git_prompt_dir
source $__GIT_PROMPT_DIR/git-prompt-help.sh
