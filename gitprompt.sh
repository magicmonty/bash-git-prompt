#!/usr/bin/env bash

function async_run() {
  {
    eval "$@" &> /dev/null
  }&
}

function git_prompt_dir() {
  # assume the gitstatus.sh is in the same directory as this script
  # code thanks to http://stackoverflow.com/questions/59895
  if [[ -z "${__GIT_PROMPT_DIR:+x}" ]]; then
    local SOURCE="${BASH_SOURCE[0]}"
    while [[ -h "${SOURCE}" ]]; do
      local DIR="$( command cd -P "$( dirname "${SOURCE}" )" && pwd )"
      SOURCE="$(readlink "${SOURCE}")"
      [[ ${SOURCE} != /* ]] && SOURCE="${DIR}/${SOURCE}"
    done
    __GIT_PROMPT_DIR="$( command cd -P "$( dirname "${SOURCE}" )" && pwd )"
  fi
}

function echoc() {
  echo -e "${1}${2}${ResetColor}" | sed 's/\\\]//g'  | sed 's/\\\[//g'
}

function get_theme() {
  local CUSTOM_THEME_FILE="${HOME}/.git-prompt-colors.sh"
  if [[ ! (-z "${GIT_PROMPT_THEME_FILE:+x}" ) ]]; then
    CUSTOM_THEME_FILE="${GIT_PROMPT_THEME_FILE}"
  fi
  local DEFAULT_THEME_FILE="${__GIT_PROMPT_DIR}/themes/Default.bgptheme"

  if [[ -z "${GIT_PROMPT_THEME+x}" ]]; then
    if [[ -r "${CUSTOM_THEME_FILE}" ]]; then
      GIT_PROMPT_THEME="Custom"
      __GIT_PROMPT_THEME_FILE="${CUSTOM_THEME_FILE}"
    else
      GIT_PROMPT_THEME="Default"
      __GIT_PROMPT_THEME_FILE="${DEFAULT_THEME_FILE}"
    fi
  else
    if [[ "${GIT_PROMPT_THEME}" = "Custom" ]]; then
      GIT_PROMPT_THEME="Custom"
      __GIT_PROMPT_THEME_FILE="${CUSTOM_THEME_FILE}"

      if [[ ! (-r "${__GIT_PROMPT_THEME_FILE}") ]]; then
        GIT_PROMPT_THEME="Default"
        __GIT_PROMPT_THEME_FILE="${DEFAULT_THEME_FILE}"
      fi
    else
      local theme=""

      # use default theme, if theme was not found
      for themefile in "${__GIT_PROMPT_DIR}/themes/"*.bgptheme; do
        local basename=${themefile##*/}
        if [[ "${basename%.bgptheme}" = "${GIT_PROMPT_THEME}" ]]; then
          theme="${GIT_PROMPT_THEME}"
          break
        fi
      done

      if [[ "${theme}" = "" ]]; then
        GIT_PROMPT_THEME="Default"
      fi

      __GIT_PROMPT_THEME_FILE="${__GIT_PROMPT_DIR}/themes/${GIT_PROMPT_THEME}.bgptheme"
    fi
  fi
}

function git_prompt_load_colors() {
  if gp_set_file_var __PROMPT_COLORS_FILE prompt-colors.sh ; then
    # outsource the color defs
    source "${__PROMPT_COLORS_FILE}"
  else
    echo 1>&2 "Cannot find prompt-colors.sh!"
  fi
}

function git_prompt_load_theme() {
  get_theme
  local DEFAULT_THEME_FILE="${__GIT_PROMPT_DIR}/themes/Default.bgptheme"
  source "${DEFAULT_THEME_FILE}"
  source "${__GIT_PROMPT_THEME_FILE}"
}

function git_prompt_list_themes() {
  git_prompt_load_colors
  git_prompt_dir
  get_theme

  for themefile in "${__GIT_PROMPT_DIR}/themes/"*.bgptheme; do
    local basename="${themefile##*/}"
    local theme="${basename%.bgptheme}"
    if [[ "${GIT_PROMPT_THEME}" = "${theme}" ]]; then
      echoc "${Red}" "*${theme}"
    else
      echo "${theme}"
    fi
  done

  if [[ "${GIT_PROMPT_THEME}" = "Custom" ]]; then
    echoc "${Magenta}" "*Custom"
  else
    echoc "${Blue}" "Custom"
  fi
}

function git_prompt_make_custom_theme() {
  if [[ -r "${HOME}/.git-prompt-colors.sh" ]]; then
    echoc "${Red}" "You have already created a custom theme!"
  else
    git_prompt_dir

    local base="Default"
    if [[ -n "${1}" && -r "${__GIT_PROMPT_DIR}/themes/${1}.bgptheme" ]]; then
      base="${1}"
      echoc "${Green}" "Using theme ${Magenta}\"${base}\"${Green} as base theme!"
    else
      echoc "${Green}" "Using theme ${Magenta}\"Default\"${Green} as base theme!"
    fi

    if [[ "${base}" = "Custom" ]]; then
      echoc "${Red}" "You cannot use the custom theme as base"
    else
      echoc "${Green}" "Creating new custom theme in \"${HOME}/.git-prompt-colors.sh\""
      echoc "${DimYellow}" "Please add ${Magenta}\"GIT_PROMPT_THEME=Custom\"${DimYellow} to your .bashrc to use this theme"
      if [[ "${base}" == "Default" ]]; then
        cp "${__GIT_PROMPT_DIR}/themes/Custom.bgptemplate" "${HOME}/.git-prompt-colors.sh"
      else
        cp "${__GIT_PROMPT_DIR}/themes/${base}.bgptheme" "${HOME}/.git-prompt-colors.sh"
      fi
    fi
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
  local envar="${1}"
  local file="${2}"
  if eval "[[ -n \"\${${envar}+x}\" && -r \"\${${envar}+x}\" ]]" ; then # is envar set to a readable file?
    local basefile
    eval "basefile=\"\`basename \\\"\${${envar}}\\\"\`\""   # assign basefile
    if [[ "${basefile}" = "${file}" || "${basefile}" = ".${file}" ]]; then
      return 0
    fi
  else  # envar is not set, or it's set to a different file than requested
    eval "${envar}="      # set empty envar
    gp_maybe_set_envar_to_path "${envar}" "${HOME}/.${file}" "${HOME}/${file}" "${HOME}/lib/${file}" && return 0
    git_prompt_dir
    gp_maybe_set_envar_to_path "${envar}" "${__GIT_PROMPT_DIR}/${file}" "${0##*/}/${file}" && return 0
  fi
  return 1
}

# gp_maybe_set_envar_to_path ENVAR FILEPATH ...
#
# return 0 (true) if any FILEPATH is readable, set ENVAR to it
# return 1 (false) if not

function gp_maybe_set_envar_to_path() {
  local envar="${1}"
  shift
  local file
  for file in "${@}" ; do
    if [[ -r "${file}" ]]; then
      eval "${envar}=\"${file}\""
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
  for var in GIT_PROMPT_DIR __GIT_PROMPT_COLORS_FILE __PROMPT_COLORS_FILE __GIT_STATUS_CMD GIT_PROMPT_THEME_NAME; do
    unset ${var}
  done
}

# gp_format_exit_status RETVAL
#
# echos the symbolic signal name represented by RETVAL if the process was
# signalled, otherwise echos the original value of RETVAL

gp_format_exit_status() {
  local RETVAL="${1}"
  local SIGNAL
  # Suppress STDERR in case RETVAL is not an integer (in such cases, RETVAL
  # is echoed verbatim)
  if [[ "${RETVAL}" -gt 128 ]] 2>/dev/null; then
    SIGNAL=$(( RETVAL - 128 ))
    kill -l "${SIGNAL}" 2>/dev/null || echo "${RETVAL}"
  else
    echo "${RETVAL}"
  fi
}

gp_format_username_repo() {
    git config --get remote.origin.url | sed 's|^.*//||; s/.*@//; s/[^:/]\+[:/]//; s/.git$//'
}

function git_prompt_config() {
  #Checking if root to change output
  _isroot=false
  [[ "${UID}" -eq 0 ]] && _isroot=true

  # There are two files related to colors:
  #
  #  prompt-colors.sh -- sets generic color names suitable for bash 'PS1' prompt
  #  git-prompt-colors.sh -- sets the GIT_PROMPT color scheme, using names from prompt-colors.sh
  git_prompt_load_colors

  # source the user's ~/.git-prompt-colors.sh file, or the one that should be
  # sitting in the same directory as this script
  git_prompt_load_theme

  if is_function prompt_callback; then
    prompt_callback="prompt_callback"
  else
    prompt_callback="prompt_callback_default"
  fi

  if [[ "${GIT_PROMPT_LAST_COMMAND_STATE:-0}" = 0 ]]; then
    LAST_COMMAND_INDICATOR="${GIT_PROMPT_COMMAND_OK}";
  else
    LAST_COMMAND_INDICATOR="${GIT_PROMPT_COMMAND_FAIL}";
  fi

  # replace _LAST_COMMAND_STATE_ token with the actual state
  GIT_PROMPT_LAST_COMMAND_STATE=$(gp_format_exit_status "${GIT_PROMPT_LAST_COMMAND_STATE}")
  LAST_COMMAND_INDICATOR="${LAST_COMMAND_INDICATOR//_LAST_COMMAND_STATE_/${GIT_PROMPT_LAST_COMMAND_STATE}}"

  # Do this only once to define PROMPT_START and PROMPT_END

  if [[ -z "${PROMPT_START:+x}" || -z "${PROMPT_END:+x}" ]]; then

    if [[ -z "${GIT_PROMPT_START:+x}" ]] ; then
      if ${_isroot}; then
        PROMPT_START="${GIT_PROMPT_START_ROOT-}"
      else
        PROMPT_START="${GIT_PROMPT_START_USER-}"
      fi
    else
      PROMPT_START="${GIT_PROMPT_START-}"
    fi

    if [[ -z "${GIT_PROMPT_END:+x}" ]] ; then
      if $_isroot; then
        PROMPT_END="${GIT_PROMPT_END_ROOT-}"
      else
        PROMPT_END="${GIT_PROMPT_END_USER-}"
      fi
    else
      PROMPT_END="${GIT_PROMPT_END-}"
    fi
  fi

  # set GIT_PROMPT_LEADING_SPACE to 0 if you want to have no leading space in front of the GIT prompt
  if [[ "${GIT_PROMPT_LEADING_SPACE:-1}" = "0" ]]; then
    PROMPT_LEADING_SPACE=""
  else
    PROMPT_LEADING_SPACE=" "
  fi

  if [[ "${GIT_PROMPT_ONLY_IN_REPO:-0}" == 1 ]]; then
    EMPTY_PROMPT="${OLD_GITPROMPT}"
  elif [[ "${GIT_PROMPT_WITH_VIRTUAL_ENV:-1}" == 1 ]]; then
    local ps="$(gp_add_virtualenv_to_prompt)${PROMPT_START}$(${prompt_callback})${PROMPT_END}"
    EMPTY_PROMPT="${ps//_LAST_COMMAND_INDICATOR_/${LAST_COMMAND_INDICATOR}}"
  else
    local ps="${PROMPT_START}$(${prompt_callback})${PROMPT_END}"
    EMPTY_PROMPT="${ps//_LAST_COMMAND_INDICATOR_/${LAST_COMMAND_INDICATOR}}"
  fi

  # fetch remote revisions every other $GIT_PROMPT_FETCH_TIMEOUT (default 5) minutes
  if [[ -z "${GIT_PROMPT_FETCH_TIMEOUT:+x}" ]]; then
    GIT_PROMPT_FETCH_TIMEOUT="5"
  fi
  if [[ -z "${__GIT_STATUS_CMD:+x}" ]] ; then          # if GIT_STATUS_CMD not defined..
    git_prompt_dir
    if ! gp_maybe_set_envar_to_path __GIT_STATUS_CMD "${__GIT_PROMPT_DIR}/${GIT_PROMPT_STATUS_COMMAND}" ; then
      echo 1>&2 "Cannot find ${GIT_PROMPT_STATUS_COMMAND}!"
    fi
    # __GIT_STATUS_CMD defined
  fi
  unset GIT_BRANCH
}

function setLastCommandState() {
  GIT_PROMPT_LAST_COMMAND_STATE="${?}"
}

function we_are_on_repo() {
  if [[ -e "$(git rev-parse --git-dir 2> /dev/null)" ]]; then
    echo 1
  else
    echo 0
  fi
}

function update_old_git_prompt() {
  local in_repo=$(we_are_on_repo)
  if [[ "${GIT_PROMPT_OLD_DIR_WAS_GIT}" = 0 ]]; then
    OLD_GITPROMPT="${PS1}"
  fi

  GIT_PROMPT_OLD_DIR_WAS_GIT="${in_repo}"
}

function setGitPrompt() {
  update_old_git_prompt

  local repo=$(git rev-parse --show-toplevel 2> /dev/null)
  if [[ ! -e "${repo}" ]] && [[ "${GIT_PROMPT_ONLY_IN_REPO-}" = 1 ]]; then
    # we do not permit bash-git-prompt outside git repos, so nothing to do
    PS1="${OLD_GITPROMPT}"
    return
  fi

  local EMPTY_PROMPT
  local __GIT_STATUS_CMD

  git_prompt_config

  if [[ ! -e "${repo}" ]] || [[ "${GIT_PROMPT_DISABLE-}" = 1 ]]; then
    PS1="${EMPTY_PROMPT}"
    return
  fi

  local FETCH_REMOTE_STATUS=1
  if [[ "${GIT_PROMPT_FETCH_REMOTE_STATUS}" = 0 ]]; then
    FETCH_REMOTE_STATUS=0
  fi

  unset GIT_PROMPT_IGNORE
  OLD_GIT_PROMPT_SHOW_UNTRACKED_FILES="${GIT_PROMPT_SHOW_UNTRACKED_FILES}"
  unset GIT_PROMPT_SHOW_UNTRACKED_FILES

  OLD_GIT_PROMPT_IGNORE_SUBMODULES="${GIT_PROMPT_IGNORE_SUBMODULES}"
  unset GIT_PROMPT_IGNORE_SUBMODULES

  if [[ -e "${repo}/.bash-git-rc" ]]; then
    # The config file can only contain variable declarations on the form A_B=0 or G_P=all
    local CONFIG_SYNTAX="^(FETCH_REMOTE_STATUS|GIT_PROMPT_SHOW_UNTRACKED_FILES|GIT_PROMPT_IGNORE_SUBMODULES|GIT_PROMPT_IGNORE)=[0-9a-z]+$"
    if grep -q -v -E "${CONFIG_SYNTAX}" "${repo}/.bash-git-rc"; then
      echo ".bash-git-rc can only contain variable values on the form NAME=value. Ignoring file." >&2
    else
      source "${repo}/.bash-git-rc"
    fi
  fi

  if [[ -z "${GIT_PROMPT_SHOW_UNTRACKED_FILES+x}" ]]; then
    GIT_PROMPT_SHOW_UNTRACKED_FILES="${OLD_GIT_PROMPT_SHOW_UNTRACKED_FILES}"
  fi
  unset OLD_GIT_PROMPT_SHOW_UNTRACKED_FILES

  if [[ -z "${GIT_PROMPT_IGNORE_SUBMODULES+x}" ]]; then
    GIT_PROMPT_IGNORE_SUBMODULES="${OLD_GIT_PROMPT_IGNORE_SUBMODULES}"
  fi
  unset OLD_GIT_PROMPT_IGNORE_SUBMODULES

  if [[ "${GIT_PROMPT_IGNORE-}" = 1 ]]; then
    PS1="${EMPTY_PROMPT}"
    return
  fi

  if [[ "${FETCH_REMOTE_STATUS}" = 1 ]]; then
    checkUpstream
  fi

  updatePrompt
}

# some versions of find do not have -mmin
_have_find_mmin=1

function olderThanMinutes() {
  local matches
  local find_exit_code

  if [[ -z "${_find_command+x}" ]]; then
    if command -v gfind > /dev/null; then
      _find_command="gfind"
    else
      _find_command="find"
    fi
  fi

  if [[ "${_have_find_mmin}" = 1 ]]; then
    matches=$("${_find_command}" "${1}" -mmin +"${2}" 2> /dev/null)
    find_exit_code="${?}"
    if [[ -n "${matches}" ]]; then
      return 0
    else
      if [[ "${find_exit_code}" != 0 ]]; then
        _have_find_mmin=0
      else
        return 1
      fi
    fi
  fi

  # try perl, solaris ships with perl
  if command -v perl > /dev/null; then
    perl -e '((time - (stat("'"${1}"'"))[9]) / 60) > '"${2}"' && exit(0) || exit(1)'
    return "${?}"
  else
    echo >&2
    echo "[1;31mWARNING[0m: neither a find that supports -mmin (such as GNU find) or perl is available, disabling remote status checking. Install GNU find as gfind or perl to enable this feature, or set GIT_PROMPT_FETCH_REMOTE_STATUS=0 to disable this warning." >&2
    echo >&2
    GIT_PROMPT_FETCH_REMOTE_STATUS=0
    return 1
  fi
}

function checkUpstream() {
  local GIT_PROMPT_FETCH_TIMEOUT
  git_prompt_config

  local FETCH_HEAD="${repo}/.git/FETCH_HEAD"
  # Fech repo if local is stale for more than $GIT_FETCH_TIMEOUT minutes
  if [[ ! -e "${FETCH_HEAD}" ]] || olderThanMinutes "${FETCH_HEAD}" "${GIT_PROMPT_FETCH_TIMEOUT}"
  then
    if [[ -n $(git remote show) ]]; then
      (
        async_run "GIT_TERMINAL_PROMPT=0 git fetch --quiet"
        disown -h
      )
    fi
  fi
}

function replaceSymbols() {
  # Disable globbing, so a * could be used as symbol here
  set -f

  if [[ -z ${GIT_PROMPT_SYMBOLS_NO_REMOTE_TRACKING+x} ]]; then
    GIT_PROMPT_SYMBOLS_NO_REMOTE_TRACKING=L
  fi

  local VALUE="${1//_AHEAD_/${GIT_PROMPT_SYMBOLS_AHEAD}}"
  local VALUE1="${VALUE//_BEHIND_/${GIT_PROMPT_SYMBOLS_BEHIND}}"
  local VALUE2="${VALUE1//_NO_REMOTE_TRACKING_/${GIT_PROMPT_SYMBOLS_NO_REMOTE_TRACKING}}"

  echo "${VALUE2//_PREHASH_/${GIT_PROMPT_SYMBOLS_PREHASH}}"

  # reenable globbing symbols
  set +f
}

function createPrivateIndex {
  # Create a copy of the index to avoid conflicts with parallel git commands, e.g. git rebase.
  local __GIT_INDEX_FILE
  local __GIT_INDEX_PRIVATE
  if [[ -z "${GIT_INDEX_FILE+x}" ]]; then
    __GIT_INDEX_FILE="$(git rev-parse --git-dir)/index"
  else
    __GIT_INDEX_FILE="${GIT_INDEX_FILE}"
  fi
  __GIT_INDEX_PRIVATE="/tmp/git-index-private$$"
  command cp "${__GIT_INDEX_FILE}" "${__GIT_INDEX_PRIVATE}" 2>/dev/null
  echo "${__GIT_INDEX_PRIVATE}"
}

function updatePrompt() {
  local LAST_COMMAND_INDICATOR
  local PROMPT_LEADING_SPACE
  local PROMPT_START
  local PROMPT_END
  local EMPTY_PROMPT
  local Blue="\[\033[0;34m\]"

  git_prompt_config

  __GIT_PROMPT_IGNORE_STASH="${GIT_PROMPT_IGNORE_STASH:-0}"
  __GIT_PROMPT_SHOW_UPSTREAM="${GIT_PROMPT_SHOW_UPSTREAM:-0}"
  __GIT_PROMPT_IGNORE_SUBMODULES="${GIT_PROMPT_IGNORE_SUBMODULES:-0}"
  __GIT_PROMPT_WITH_USERNAME_AND_REPO="${GIT_PROMPT_WITH_USERNAME_AND_REPO:-0}"
  export __GIT_PROMPT_SHOW_UNTRACKED_FILES="${GIT_PROMPT_SHOW_UNTRACKED_FILES-normal}"
  local __GIT_PROMPT_SHOW_CHANGED_FILES_COUNT="${GIT_PROMPT_SHOW_CHANGED_FILES_COUNT:-1}"

  local GIT_INDEX_PRIVATE="$(createPrivateIndex)"
  #important to define GIT_INDEX_FILE as local: This way it only affects this function (and below) - even with the export afterwards
  local GIT_INDEX_FILE
  export GIT_INDEX_FILE="${GIT_INDEX_PRIVATE}"

  local -a git_status_fields
  while IFS=$'\n' read -r line; do git_status_fields+=("${line}"); done < <("${__GIT_STATUS_CMD}" 2>/dev/null)

  export GIT_BRANCH=$(replaceSymbols "${git_status_fields[0]}")
  local GIT_REMOTE="$(replaceSymbols "${git_status_fields[1]}")"
  if [[ "." == "${GIT_REMOTE}" ]]; then
    unset GIT_REMOTE
  fi
  local GIT_REMOTE_USERNAME_REPO="$(replaceSymbols "${git_status_fields[2]}")"
  if [[ "." == "${GIT_REMOTE_USERNAME_REPO}" ]]; then
    unset GIT_REMOTE_USERNAME_REPO
  fi

  local GIT_FORMATTED_UPSTREAM
  local GIT_UPSTREAM_PRIVATE="${git_status_fields[3]}"
  if [[ "${__GIT_PROMPT_SHOW_UPSTREAM:-0}" != "1" || "^" == "${GIT_UPSTREAM_PRIVATE}" ]]; then
    unset GIT_FORMATTED_UPSTREAM
  else
    GIT_FORMATTED_UPSTREAM="${GIT_PROMPT_UPSTREAM//_UPSTREAM_/${GIT_UPSTREAM_PRIVATE}}"
  fi

  local GIT_STAGED="${git_status_fields[4]}"
  local GIT_CONFLICTS="${git_status_fields[5]}"
  local GIT_CHANGED="${git_status_fields[6]}"
  local GIT_UNTRACKED="${git_status_fields[7]}"
  local GIT_STASHED="${git_status_fields[8]}"
  local GIT_CLEAN="${git_status_fields[9]}"


  local NEW_PROMPT="${EMPTY_PROMPT}"
  if [[ "${#git_status_fields[@]}" -gt 0 ]]; then

    if [[ -z "${GIT_REMOTE_USERNAME_REPO+x}" ]]; then
      local GIT_PROMPT_PREFIX_FINAL="${GIT_PROMPT_PREFIX//_USERNAME_REPO_/${ResetColor}}"
    else
      if [[ -z "${GIT_PROMPT_USERNAME_REPO_SEPARATOR+x}" ]]; then
        local GIT_PROMPT_PREFIX_FINAL="${GIT_PROMPT_PREFIX//_USERNAME_REPO_/${GIT_REMOTE_USERNAME_REPO}${ResetColor}}"
      else
        local GIT_PROMPT_PREFIX_FINAL="${GIT_PROMPT_PREFIX//_USERNAME_REPO_/${GIT_REMOTE_USERNAME_REPO}${ResetColor}${GIT_PROMPT_USERNAME_REPO_SEPARATOR}}"
      fi
    fi

    case "${GIT_BRANCH-}" in
      ${GIT_PROMPT_MASTER_BRANCHES})
        local STATUS_PREFIX="${PROMPT_LEADING_SPACE}${GIT_PROMPT_PREFIX_FINAL}${GIT_PROMPT_MASTER_BRANCH}${URL_SHORT-}\${GIT_BRANCH}${ResetColor}${GIT_FORMATTED_UPSTREAM-}"
        ;;
      *)
        local STATUS_PREFIX="${PROMPT_LEADING_SPACE}${GIT_PROMPT_PREFIX_FINAL}${GIT_PROMPT_BRANCH}${URL_SHORT-}\${GIT_BRANCH}${ResetColor}${GIT_FORMATTED_UPSTREAM-}"
        ;;
    esac
    local STATUS=""

    # __add_status KIND VALEXPR INSERT
    # eg: __add_status  'STAGED' '-ne 0'

    __chk_gitvar_status() {
      local v
      if [[ "${2-}" = "-n" ]] ; then
        v="${2} \"\${GIT_${1}-}\""
      else
        v="\${GIT_${1}-} ${2}"
      fi
      if eval "[[ ${v} ]]" ; then
        if [[ "${3-}" != '-' ]] && [[ "${__GIT_PROMPT_SHOW_CHANGED_FILES_COUNT}" == "1" || "${1-}" == "REMOTE" ]]; then
          __add_status "\${GIT_PROMPT_${1}}\${GIT_${1}}\${ResetColor}"
        else
          __add_status "\${GIT_PROMPT_${1}}\${ResetColor}"
        fi
      fi
    }

    __add_gitvar_status() {
      __add_status "\${GIT_PROMPT_${1}}\${GIT_${1}}\${ResetColor}"
    }

    # __add_status SOMETEXT
    __add_status() {
      eval "STATUS=\"${STATUS}${1}\""
    }

    __chk_gitvar_status 'REMOTE'       '-n'
    if [[ "${GIT_CLEAN}" -eq 0 ]] || [[ "${GIT_PROMPT_CLEAN}" != "" ]]; then
      __add_status        "${GIT_PROMPT_SEPARATOR}"
      __chk_gitvar_status 'STAGED'     '!= "0" && ${GIT_STAGED-} != "^"'
      __chk_gitvar_status 'CONFLICTS'  '!= "0"'
      __chk_gitvar_status 'CHANGED'    '!= "0"'
      __chk_gitvar_status 'UNTRACKED'  '!= "0"'
      __chk_gitvar_status 'STASHED'    '!= "0"'
      __chk_gitvar_status 'CLEAN'      '= "1"'   -
    fi
    __add_status        "${ResetColor}${GIT_PROMPT_SUFFIX}"

    NEW_PROMPT="$(gp_add_virtualenv_to_prompt)${PROMPT_START}$(${prompt_callback})${STATUS_PREFIX}${STATUS}${PROMPT_END}"
  else
    NEW_PROMPT="${EMPTY_PROMPT}"
  fi

  PS1="${NEW_PROMPT//_LAST_COMMAND_INDICATOR_/${LAST_COMMAND_INDICATOR}${ResetColor}}"
  command rm "${GIT_INDEX_PRIVATE}" 2>/dev/null
}

# Helper function that returns virtual env information to be set in prompt
# Honors virtualenvs own setting VIRTUAL_ENV_DISABLE_PROMPT
function gp_add_virtualenv_to_prompt {
  local ACCUMULATED_VENV_PROMPT=""
  local VENV=""
  if [[ -n "${VIRTUAL_ENV-}" && -z "${VIRTUAL_ENV_DISABLE_PROMPT+x}" ]]; then
    VENV=$(basename "${VIRTUAL_ENV}")
    ACCUMULATED_VENV_PROMPT="${ACCUMULATED_VENV_PROMPT}${GIT_PROMPT_VIRTUALENV//_VIRTUALENV_/${VENV}}"
  fi
  if [[ -n "${NODE_VIRTUAL_ENV-}" && -z "${NODE_VIRTUAL_ENV_DISABLE_PROMPT+x}" ]]; then
    VENV=$(basename "${NODE_VIRTUAL_ENV}")
    ACCUMULATED_VENV_PROMPT="${ACCUMULATED_VENV_PROMPT}${GIT_PROMPT_VIRTUALENV//_VIRTUALENV_/${VENV}}"
  fi
  if [[ -n "${CONDA_DEFAULT_ENV-}" ]]; then
    VENV=$(basename "${CONDA_DEFAULT_ENV}")
    ACCUMULATED_VENV_PROMPT="${ACCUMULATED_VENV_PROMPT}${GIT_PROMPT_VIRTUALENV//_VIRTUALENV_/${VENV}}"
  fi
  echo "${ACCUMULATED_VENV_PROMPT}"
}

# Use exit status from declare command to determine whether input argument is a
# bash function
function is_function {
  declare -Ff "${1}" >/dev/null;
}

# Helper function that truncates $PWD depending on window width
# Optionally specify maximum length as parameter (defaults to 1/3 of terminal)
function gp_truncate_pwd {
  local tilde="~"
  local newPWD="${PWD/#${HOME}/${tilde}}"
  local pwdmaxlen="${1:-$((${COLUMNS:-80}/3))}"
  [[ "${#newPWD}" -gt "${pwdmaxlen}" ]] && newPWD="...${newPWD:3-$pwdmaxlen}"
  echo -n "${newPWD}"
}

# Sets the window title to the given argument string
function gp_set_window_title {
  echo -ne "\[\033]0;"${@}"\007\]"
}

function prompt_callback_default {
  return
}

# toggle gitprompt
function git_prompt_toggle() {
  if [[ "${GIT_PROMPT_DISABLE:-0}" = 1 ]]; then
    GIT_PROMPT_DISABLE=0
  else
    GIT_PROMPT_DISABLE=1
  fi
  return
}

function gp_install_prompt {
  if [[ -z "${OLD_GITPROMPT+x}" ]]; then
    OLD_GITPROMPT=${PS1}
  fi

  if [[ -z "${GIT_PROMPT_OLD_DIR_WAS_GIT+x}" ]]; then
    GIT_PROMPT_OLD_DIR_WAS_GIT=$(we_are_on_repo)
  fi

  if [[ -z "${PROMPT_COMMAND:+x}" ]]; then
    PROMPT_COMMAND=setGitPrompt
  else
    PROMPT_COMMAND="${PROMPT_COMMAND//$'\n'/;}" # convert all new lines to semi-colons
    PROMPT_COMMAND="${PROMPT_COMMAND#\;}" # remove leading semi-colon
    PROMPT_COMMAND="${PROMPT_COMMAND%% }" # remove trailing spaces
    PROMPT_COMMAND="${PROMPT_COMMAND%\;}" # remove trailing semi-colon

    local new_entry="setGitPrompt"
    case ";${PROMPT_COMMAND};" in
      *";${new_entry};"*)
        # echo "PROMPT_COMMAND already contains: $new_entry"
        :;;
      *)
        PROMPT_COMMAND="${PROMPT_COMMAND};${new_entry}"
        # echo "PROMPT_COMMAND does not contain: $new_entry"
        ;;
    esac
  fi

  local setLastCommandStateEntry="setLastCommandState"
  case ";${PROMPT_COMMAND};" in
    *";${setLastCommandStateEntry};"*)
      # echo "PROMPT_COMMAND already contains: $setLastCommandStateEntry"
      :;;
    *)
      PROMPT_COMMAND="${setLastCommandStateEntry};${PROMPT_COMMAND}"
      # echo "PROMPT_COMMAND does not contain: $setLastCommandStateEntry"
      ;;
  esac

  git_prompt_dir
  source "${__GIT_PROMPT_DIR}/git-prompt-help.sh"
}

gp_install_prompt
