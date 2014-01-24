#!/bin/bash
#  git-prompt-help -- show useful info to help new users with the information
# being displayed.

git_prompt_help() {
  cat <<EOF 1>&2 
The git prompt format is [<BRANCH><TRACKING>|<LOCALSTATUS>]

BRANCH is a branch name, such as "master" or "stage", a tag name, or commit
hash prefixed with ':'.

TRACKING indicates how the local branch differs from the
remote branch.  It can be empty, or one of:

    ↑N   - ahead of remote by N commits
    ↓N   - behind remote by N commits
    ↓M↑N - branches diverged, other by M commits, yours by N commits

LOCALSTATUS is one of the following:

    ✔   - repository clean
    ●N  - N staged files
    ✖N  - N unmerged files
    ✚N  - N changed but *unstaged* files
    …N  - N untracked files
    ⚑N  - N stash entries

See "git_prompt_examples" for examples.
EOF
}
help_git_prompt() { git_prompt_help ; }

git_prompt_examples() {
  cat <<EOF 1>&2
These are examples of the git prompt:

  (master↑3|✚1)   - on branch "master", ahead of remote by 3 commits, 1
                    file changed but not staged

  (status|●2)     - on branch "status", 2 files staged

  (master|✚7…)    - on branch "master", 7 files changed, some files untracked

  (master|✖2✚3)   - on branch "master", 2 conflicts, 3 files changed

  (master|⚑2)     - on branch "master", 2 stash entries

  (experimental↓2↑3|✔)  -  on branch "experimental"; your branch has diverged
                           by 3 commits, remote by 2 commits; the repository is
                           otherwise clean

  (:70c2952|✔)    - not on any branch; parent commit has hash "70c2952"; the
                    repository is otherwise clean
EOF
}

