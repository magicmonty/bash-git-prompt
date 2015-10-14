#!/usr/bin/env bash
#  git-prompt-help -- show useful info to help new users with the information
# being displayed.

git_prompt_help() {
  source ${__GIT_PROMPT_DIR}/prompt-colors.sh
  source ${__GIT_PROMPT_DIR}/themes/Default.bgptheme
 cat <<EOF | sed 's/\\\[\\033//g' | sed 's/\\\]//g'
The git prompt format is ${GIT_PROMPT_PREFIX}<BRANCH><TRACKING>${GIT_PROMPT_SEPARATOR}<LOCALSTATUS>${GIT_PROMPT_SUFFIX}

BRANCH is a branch name, such as "master" or "stage", a tag name, or commit
hash prefixed with ':'.

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
  cat <<EOF | sed 's/\\\[\\033//g' | sed 's/\\\]//g'
These are examples of the git prompt:

  [${GIT_PROMPT_BRANCH}master${ResetColor}${GIT_PROMPT_REMOTE}↑·3${ResetColor}|${GIT_PROMPT_CHANGED}1${ResetColor}]  - on branch "master", ahead of remote by 3 commits, 1
                    file changed but not staged

  [${GIT_PROMPT_BRANCH}status${ResetColor}|${GIT_PROMPT_STAGED}2${ResetColor}]     - on branch "status", 2 files staged

  [${GIT_PROMPT_BRANCH}master${ResetColor}|${GIT_PROMPT_CHANGED}7${GIT_PROMPT_UNTRACKED}${ResetColor}]    - on branch "master", 7 files changed, some files untracked

  [${GIT_PROMPT_BRANCH}master${ResetColor}|${GIT_PROMPT_CONFLICTS}2${GIT_PROMPT_CHANGED}3${ResetColor}]   - on branch "master", 2 conflicts, 3 files changed

  [${GIT_PROMPT_BRANCH}master${ResetColor}|${GIT_PROMPT_STASHED}2${ResetColor}]     - on branch "master", 2 stash entries

  [${GIT_PROMPT_BRANCH}experimental${ResetColor}${GIT_PROMPT_REMOTE}↓·2↑·3${ResetColor}|${GIT_PROMPT_CLEAN}${ResetColor}]
                  -  on branch "experimental"; your branch has diverged
                     by 3 commits, remote by 2 commits; the repository is
                     otherwise clean

  [${GIT_PROMPT_BRANCH}:70c2952${ResetColor}|${GIT_PROMPT_CLEAN}${ResetColor}]    - not on any branch; parent commit has hash "70c2952"; the
                    repository is otherwise clean
EOF
}

git_prompt_color_samples() {
  
  showColor() {
    local color=$(eval echo "\${$1}")
    echo -e "${color}$1${ResetColor}" | sed 's/\\\]//g'  | sed 's/\\\[//g'
  }

  while (( x < 8 )) ; do
    showColor ${ColorNames[x]}
    showColor "Dim${ColorNames[x]}"
    showColor "Bold${ColorNames[x]}"
    showColor "Bright${ColorNames[x]}"
    (( x++ ))
  done
}
