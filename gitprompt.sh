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

function git_prompt_config()
{
  # Colors
  ResetColor="\[\033[0m\]"            # Text reset

  # Bold
  local BoldGreen="\[\033[1;32m\]"    # Green
  local BoldBlue="\[\033[1;34m\]"     # Blue

  # High Intensty
  local IntenseBlack="\[\033[0;90m\]" # Grey

  # Bold High Intensty
  local Magenta="\[\033[1;95m\]"      # Purple

  # Regular Colors
  local Yellow="\[\033[0;33m\]"
  local White='\[\033[37m\]'
  local Red="\[\033[0;31m\]"
  local Blue="\[\033[0;34m\]"
  local Cyan="\[\033[0;36m\]"
  local Green="\[\033[0;32m\]"

  #Checking if root to change output
  _isroot=false
  [[ $UID -eq 0 ]] && _isroot=true

  # source the user's ~/.git-prompt-colors.sh file, or the one that should be
  # sitting in the same directory as this script

  if [[ -z "$__GIT_PROMPT_COLORS_FILE" ]]; then
    local pfx file dir
    for dir in "$HOME" "$__GIT_PROMPT_DIR" ; do
      for pfx in '.' '' ; do
        file="$dir/${pfx}git-prompt-colors.sh"
        if [[ -f "$file" ]]; then
          __GIT_PROMPT_COLORS_FILE="$file"
          break 2
        fi
      done
    done
  fi

   # Various variables you might want for your PS1 prompt instead
  local Time12a="\$(date +%H:%M)"
  # local Time12a="(\$(date +%H:%M:%S))"
  # local Time12a="(\@))"
  local PathShort="\w"

  # if the envar is defined, source the file for custom colors
  if [[ -n "$__GIT_PROMPT_COLORS_FILE" && -f "$__GIT_PROMPT_COLORS_FILE" ]]; then
    source "$__GIT_PROMPT_COLORS_FILE"
  else
    # Default values for the appearance of the prompt.  Do not change these
    # below.  Instead, copy these to `~/.git-prompt-colors.sh` and change them
    # there.
    GIT_PROMPT_PREFIX="["
    GIT_PROMPT_SUFFIX="]"
    GIT_PROMPT_SEPARATOR="|"
    GIT_PROMPT_BRANCH="${Magenta}"
    GIT_PROMPT_STAGED="${Red}●"
    GIT_PROMPT_CONFLICTS="${Red}✖"
    GIT_PROMPT_CHANGED="${Blue}✚"
    GIT_PROMPT_REMOTE=" "
    GIT_PROMPT_UNTRACKED="${Cyan}…"
    GIT_PROMPT_STASHED="${BoldBlue}⚑"
    GIT_PROMPT_CLEAN="${BoldGreen}✔"
    GIT_PROMPT_COMMAND_OK="${Green}✔ "
    GIT_PROMPT_COMMAND_FAIL="${Red}✘ "

    GIT_PROMPT_START_USER="${Yellow}${PathShort}${ResetColor}"
    GIT_PROMPT_START_ROOT="${Yellow}${PathShort}${ResetColor}"
    GIT_PROMPT_END_USER=" \n${White}${Time12a}${ResetColor} $ "
    GIT_PROMPT_END_ROOT=" \n${White}${Time12a}${ResetColor} # "

    # Please do not add colors to these symbols
    GIT_PROMPT_SYMBOLS_AHEAD="↑·"
    GIT_PROMPT_SYMBOLS_BEHIND="↓·"
    GIT_PROMPT_SYMBOLS_PREHASH=":"    
  fi

  if [ "x${GIT_PROMPT_SHOW_LAST_COMMAND_INDICATOR}" == "x1" ]; then
  	if [ $LAST_COMMAND_STATE = 0 ]; then
  		LAST_COMMAND_INDICATOR="${GIT_PROMPT_COMMAND_OK}";
  	else
  		LAST_COMMAND_INDICATOR="${GIT_PROMPT_COMMAND_FAIL}";
  	fi
  fi

  if [ "x${GIT_PROMPT_START}" == "x" ]; then
    #First statment is for non root behavior second for root
    if $_isroot; then
      PROMPT_START="${GIT_PROMPT_START_ROOT}"
    else
      PROMPT_START="${GIT_PROMPT_START_USER}"
    fi
  else
    PROMPT_START="${GIT_PROMPT_START}"
  fi

  if [ "x${GIT_PROMPT_END}" == "x" ]; then
    #First statment is for non root behavior second for root
    if ! $_isroot; then
      PROMPT_END="${GIT_PROMPT_END_USER}"
    else
      PROMPT_END="${GIT_PROMPT_END_ROOT}"
    fi
  else
    PROMPT_END="${GIT_PROMPT_END}"
  fi

  # set GIT_PROMPT_LEADING_SPACE to 0 if you want to have no leading space in front of the GIT prompt
  if [ "x${GIT_PROMPT_LEADING_SPACE}" == "x0" ]; then
    PROMPT_LEADING_SPACE=""
  else
    PROMPT_LEADING_SPACE=" "
  fi

  if [ "x${GIT_PROMPT_ONLY_IN_REPO}" == "x1" ]; then
    EMPTY_PROMPT=$OLD_GITPROMPT
  else
    if [[ -n "${VIRTUAL_ENV}" ]]; then
      EMPTY_PROMPT="${LAST_COMMAND_INDICATOR}(${Blue}$(basename "${VIRTUAL_ENV}")${ResetColor}) ${PROMPT_START}$($prompt_callback)${PROMPT_END}"
    elif [[ -n "${CONDA_DEFAULT_ENV}" ]]; then
      EMPTY_PROMPT="${LAST_COMMAND_INDICATOR}(${Blue}$(basename "${CONDA_DEFAULT_ENV}")${ResetColor}) ${PROMPT_START}$($prompt_callback)${PROMPT_END}"
    else
      EMPTY_PROMPT="${LAST_COMMAND_INDICATOR}${PROMPT_START}$($prompt_callback)${PROMPT_END}"
    fi
  fi

  # fetch remote revisions every other $GIT_PROMPT_FETCH_TIMEOUT (default 5) minutes
  GIT_PROMPT_FETCH_TIMEOUT=${1-5}
  if [ "x$__GIT_STATUS_CMD" == "x" ]
  then
    git_prompt_dir
    local sfx file
    # look first for a '.sh' version, then use the python version
    for sfx in sh py ; do
      file="${__GIT_PROMPT_DIR}/gitstatus.$sfx"
      if [[ -x "$file" ]]; then
        __GIT_STATUS_CMD="$file"
        break
      fi
    done
  fi
}

function setGitPrompt() {
  LAST_COMMAND_STATE=$?

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
  local GIT_PROMPT_PREFIX
  local GIT_PROMPT_SUFFIX
  local GIT_PROMPT_SEPARATOR
  local GIT_PROMPT_BRANCH
  local GIT_PROMPT_STAGED
  local GIT_PROMPT_CONFLICTS
  local GIT_PROMPT_CHANGED
  local GIT_PROMPT_REMOTE
  local GIT_PROMPT_UNTRACKED
  local GIT_PROMPT_STASHED
  local GIT_PROMPT_CLEAN
  local LAST_COMMAND_INDICATOR
  local PROMPT_LEADING_SPACE
  local PROMPT_START
  local PROMPT_END
  local EMPTY_PROMPT
  local GIT_PROMPT_FETCH_TIMEOUT
  local __GIT_STATUS_CMD
  local Blue="\[\033[0;34m\]"

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
    local STATUS="${PROMPT_LEADING_SPACE}${GIT_PROMPT_PREFIX}${GIT_PROMPT_BRANCH}${GIT_BRANCH}${ResetColor}"

    if [[ -n "${GIT_REMOTE}" ]]; then
      STATUS="${STATUS}${GIT_PROMPT_REMOTE}${GIT_REMOTE}${ResetColor}"
    fi

    STATUS="${STATUS}${GIT_PROMPT_SEPARATOR}"
    if [ "${GIT_STAGED}" -ne "0" ]; then
      STATUS="${STATUS}${GIT_PROMPT_STAGED}${GIT_STAGED}${ResetColor}"
    fi

    if [ "${GIT_CONFLICTS}" -ne "0" ]; then
      STATUS="${STATUS}${GIT_PROMPT_CONFLICTS}${GIT_CONFLICTS}${ResetColor}"
    fi

    if [ "${GIT_CHANGED}" -ne "0" ]; then
      STATUS="${STATUS}${GIT_PROMPT_CHANGED}${GIT_CHANGED}${ResetColor}"
    fi

    if [ "${GIT_UNTRACKED}" -ne "0" ]; then
      STATUS="${STATUS}${GIT_PROMPT_UNTRACKED}${GIT_UNTRACKED}${ResetColor}"
    fi

    if [ "${GIT_STASHED}" -ne "0" ]; then
      STATUS="${STATUS}${GIT_PROMPT_STASHED}${GIT_STASHED}${ResetColor}"
    fi

    if [ "${GIT_CLEAN}" -eq "1" ]; then
      STATUS="${STATUS}${GIT_PROMPT_CLEAN}"
    fi

    STATUS="${STATUS}${ResetColor}${GIT_PROMPT_SUFFIX}"


    PS1="${LAST_COMMAND_INDICATOR}${PROMPT_START}$($prompt_callback)${STATUS}${PROMPT_END}"
    if [[ -n "${VIRTUAL_ENV}" ]]; then
      PS1="(${Blue}$(basename ${VIRTUAL_ENV})${ResetColor}) ${PS1}"
    fi

    if [[ -n "${CONDA_DEFAULT_ENV}" ]]; then
      PS1="(${Blue}$(basename ${CONDA_DEFAULT_ENV})${ResetColor}) ${PS1}"
    fi

  else
    PS1="${EMPTY_PROMPT}"
  fi
}

function prompt_callback_default {
    return
}

function run {
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

  git_prompt_dir
  source "$__GIT_PROMPT_DIR/git-prompt-help.sh"
}

run
