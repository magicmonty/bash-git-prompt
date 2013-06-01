
function git_prompt_config() {
  # Colors
  local ResetColor="\[\033[0m\]"
  local BoldGreen="\[\033[1;32m\]"
  local BoldBlue="\[\033[1;34m\]"
  local Magenta="\[\033[1;95m\]"
  local Yellow="\[\033[1;33m\]"
  local White="\[\033[37m\]"
  local Blue="\[\033[0;34m\]"
  local Red="\[\033[0;31m\]"

  # Default values for the appearance of the prompt. Configure at will.
  GIT_PROMPT_PREFIX="["
  GIT_PROMPT_SUFFIX="]"
  GIT_PROMPT_SEPARATOR="|"
  GIT_PROMPT_BRANCH="${Magenta}"
  GIT_PROMPT_STAGED="${Red}● "
  GIT_PROMPT_CONFLICTS="${Red}✖ "
  GIT_PROMPT_CHANGED="${Blue}✚ "
  GIT_PROMPT_REMOTE=" "
  GIT_PROMPT_UNTRACKED="…"
  GIT_PROMPT_CLEAN="${BoldGreen}✔"

  PROMPT_START="${Yellow}\w${ResetColor}"
  PROMPT_END=" \n${White}\@${ResetColor} $ "
}

function setGitPrompt() {
  local ResetColor="\[\033[0m\]"

  local -a GitStatus
  GitStatus=($("${__GIT_PROMPT_DIR:-${HOME}/.bash}/gitstatus.py" 2>/dev/null))

  local GIT_PROMPT_PREFIX
  local GIT_PROMPT_SUFFIX
  local GIT_PROMPT_SEPARATOR
  local GIT_PROMPT_BRANCH
  local GIT_PROMPT_STAGED
  local GIT_PROMPT_CONFLICTS
  local GIT_PROMPT_CHANGED
  local GIT_PROMPT_REMOTE
  local GIT_PROMPT_UNTRACKED
  local GIT_PROMPT_CLEAN
  local PROMPT_START
  local PROMPT_END
  git_prompt_config

  if [[ -n "${GitStatus}" ]]; then
    local Status="${Status} ${GIT_PROMPT_PREFIX}"

    Status="${Status}${GIT_PROMPT_BRANCH}${GitStatus[0]}${ResetColor}"
    if [[ "${GitStatus[1]}" != "." ]]; then
      Status="${Status}${GIT_PROMPT_REMOTE}${GitStatus[1]}${ResetColor}"
    fi

    Status="${Status}${GIT_PROMPT_SEPARATOR}"
    if [[ "${GitStatus[2]}" -ne "0" ]]; then
      Status="${Status}${GIT_PROMPT_STAGED}${GitStatus[2]}${ResetColor}"
    fi

    if [[ "${GitStatus[3]}" -ne "0" ]]; then
      Status="${Status}${GIT_PROMPT_CONFLICTS}${GitStatus[3]}${ResetColor}"
    fi
    if [[ "${GitStatus[4]}" -ne "0" ]]; then
      Status="${Status}${GIT_PROMPT_CHANGED}${GitStatus[4]}${ResetColor}"
    fi
    if [[ "${GitStatus[5]}" -ne "0" ]]; then
      Status="${Status}${GIT_PROMPT_UNTRACKED}${GitStatus[5]}${ResetColor}"
    fi
    if [[ "${GitStatus[6]}" -eq "1" ]]; then
      Status="${Status}${GIT_PROMPT_CLEAN}${ResetColor}"
    fi
    Status="${Status}${GIT_PROMPT_SUFFIX}"

    PS1="${PROMPT_START}${Status}${PROMPT_END}"
    if [[ -n "${VIRTUAL_ENV}" ]]; then
      local Blue="\[\033[1;34m\]"
      PS1="${Blue}($(basename "${VIRTUAL_ENV}"))${ResetColor} ${PS1}"
    fi
  else
    PS1="${PROMPT_START}${PROMPT_END}"
  fi
}

PROMPT_COMMAND=setGitPrompt
