#!/bin/bash
#  git-prompt-help -- show useful info to help new users with the information
# being displayed.

git_prompt_help() {
 cat <<EOF | sed 's/\\\[\\033//g' | sed 's/\\\]//g'
The git prompt format is [<BRANCH><TRACKING>|<LOCALSTATUS>]

BRANCH is a branch name, such as "master" or "stage", a tag name, or commit
hash prefixed with ':'.

TRACKING indicates how the local branch differs from the
remote branch.  It can be empty, or one of:

    ${GIT_PROMPT_BRANCH}${ResetColor}${GIT_PROMPT_REMOTE}↑·N${ResetColor}   - ahead of remote by N commits
    ${GIT_PROMPT_BRANCH}${ResetColor}${GIT_PROMPT_REMOTE}↓·N${ResetColor}   - behind remote by N commits
    ${GIT_PROMPT_BRANCH}${ResetColor}${GIT_PROMPT_REMOTE}↓·M↑·N${ResetColor} - branches diverged, other by M commits, yours by N commits

LOCALSTATUS is one of the following:

    ${GIT_PROMPT_CLEAN}${ResetColor}   - repository clean
    ${GIT_PROMPT_STAGED}N${ResetColor}  - N staged files
    ${GIT_PROMPT_CONFLICTS}N${ResetColor}  - N conflicted files
    ${GIT_PROMPT_CHANGED}N${ResetColor}  - N changed but *unstaged* files
    ${GIT_PROMPT_UNTRACKED}N${ResetColor}  - N untracked files
    ${GIT_PROMPT_STASHED}N${ResetColor}  - N stash entries

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

