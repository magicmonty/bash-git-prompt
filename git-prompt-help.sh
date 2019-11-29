#!/usr/bin/env bash
#  git-prompt-help -- show useful info to help new users with the information
# being displayed.

git_prompt_help() {
  source "${__GIT_PROMPT_DIR}/prompt-colors.sh"
  source "${__GIT_PROMPT_DIR}/themes/Default.bgptheme"

 cat <<EOF | sed 's/\\\[\\033//g' | sed 's/\\\]//g'
The git prompt format is ${GIT_PROMPT_PREFIX}<BRANCH><TRACKING>${GIT_PROMPT_SEPARATOR}<LOCALSTATUS>${GIT_PROMPT_SUFFIX}${ResetColor}

BRANCH is a branch name, such as "${GIT_PROMPT_MASTER_BRANCH}master${ResetColor}" or "${GIT_PROMPT_BRANCH}stage${ResetColor}", a tag name, or commit
${GIT_PROMPT_SYMBOLS_PREHASH}hash${ResetColor} prefixed with '${GIT_PROMPT_SYMBOLS_PREHASH:-':'}${ResetColor}'.

TRACKING indicates how the local branch differs from the
remote branch.  It can be empty, or one of:

    ${GIT_PROMPT_BRANCH}${ResetColor}${GIT_PROMPT_REMOTE}${GIT_PROMPT_SYMBOLS_AHEAD}N${ResetColor} - ahead of remote by N commits
    ${GIT_PROMPT_BRANCH}${ResetColor}${GIT_PROMPT_REMOTE}${GIT_PROMPT_SYMBOLS_BEHIND}M${ResetColor} - behind remote by M commits
    ${GIT_PROMPT_BRANCH}${ResetColor}${GIT_PROMPT_REMOTE}${GIT_PROMPT_SYMBOLS_AHEAD}N${GIT_PROMPT_SYMBOLS_BEHIND}M${ResetColor} - branches diverged, other by M commits, yours by N commits

LOCALSTATUS is one of the following:

    ${GIT_PROMPT_CLEAN}${ResetColor} - repository clean
    ${GIT_PROMPT_STAGED}N${ResetColor} - N staged files
    ${GIT_PROMPT_CONFLICTS}N${ResetColor} - N files with merge conflicts
    ${GIT_PROMPT_CHANGED}N${ResetColor} - N changed but *unstaged* files
    ${GIT_PROMPT_UNTRACKED}N${ResetColor} - N untracked files
    ${GIT_PROMPT_STASHED}N${ResetColor} - N stash entries

See "git_prompt_examples" for examples.
EOF
}

help_git_prompt() { git_prompt_help ; }

git_prompt_examples() {

  format_branch() {
    case "$1" in
      ${GIT_PROMPT_MASTER_BRANCHES})
        echo "${GIT_PROMPT_MASTER_BRANCH}$1${ResetColor}"
        ;;
      *)
        echo "${GIT_PROMPT_BRANCH}$1${ResetColor}"
        ;;
    esac
  }
  local p="${GIT_PROMPT_PREFIX}"
  local s="${GIT_PROMPT_SUFFIX}${ResetColor}"

  cat <<EOF | sed 's/\\\[\\033//g' | sed 's/\\\]//g'
These are examples of the git prompt:

  ${p}`format_branch master`${GIT_PROMPT_REMOTE}${GIT_PROMPT_SYMBOLS_AHEAD}3${ResetColor}|${GIT_PROMPT_CHANGED}1${ResetColor}${s}  - on branch "master", ahead of remote by 3 commits, 1
                     file changed but not staged

  ${p}`format_branch status`${GIT_PROMPT_SEPARATOR}${GIT_PROMPT_STAGED}2${ResetColor}${s}     - on branch "status", 2 files staged

  ${p}`format_branch master`${GIT_PROMPT_SEPARATOR}${GIT_PROMPT_CHANGED}7${GIT_PROMPT_UNTRACKED}${ResetColor}${s}   - on branch "master", 7 files changed, some files untracked

  ${p}`format_branch master`${GIT_PROMPT_SEPARATOR}${GIT_PROMPT_CONFLICTS}2${GIT_PROMPT_CHANGED}3${ResetColor}${s}  - on branch "master", 2 conflicts, 3 files changed

  ${p}`format_branch master`${GIT_PROMPT_SEPARATOR}${GIT_PROMPT_STASHED}2${ResetColor}${s}     - on branch "master", 2 stash entries

  ${p}`format_branch experimental`${GIT_PROMPT_REMOTE}${GIT_PROMPT_SEPARATOR}${GIT_PROMPT_SYMBOLS_AHEAD}2${GIT_PROMPT_SYMBOLS_BEHIND}3${ResetColor}${s}
                   - on branch "experimental"; your branch has diverged
                     by 3 commits, remote by 2 commits; the repository is
                     otherwise clean

  ${p}${GIT_PROMPT_BRANCH}${GIT_PROMPT_SYMBOLS_PREHASH}70c2952${ResetColor}${GIT_PROMPT_SEPARATOR}${GIT_PROMPT_CLEAN}${ResetColor}${s}    - not on any branch; parent commit has hash "70c2952"; the
                     repository is otherwise clean

  ${p}`format_branch extra-features`${GIT_PROMPT_SYMBOLS_NO_REMOTE_TRACKING}${ResetColor}${GIT_PROMPT_SEPARATOR}${GIT_PROMPT_CHANGED}2${GIT_PROMPT_UNTRACKED}4${ResetColor}${s}
                   - on branch "extra-features"; no remote set (signalled by '${GIT_PROMPT_SYMBOLS_NO_REMOTE_TRACKING}${ResetColor}'),
                     2 files changed and 4 untracked files exist
EOF
}

git_prompt_color_samples() {

  showColor() {
    local color=$(eval echo "\${${1}}")
    echo -e "${color}${1}${ResetColor}" | sed 's/\\\]//g'  | sed 's/\\\[//g'
  }

  local x=0
  while (( x < 8 )) ; do
    showColor "${ColorNames[x]}"
    showColor "Dim${ColorNames[x]}"
    showColor "Bold${ColorNames[x]}"
    showColor "Bright${ColorNames[x]}"
    (( x++ ))
  done
}
