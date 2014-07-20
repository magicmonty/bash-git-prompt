#!/bin/bash
# -*- coding: UTF-8 -*-
# gitstatus.sh -- produce the current git repo status on STDOUT
# Functionally equivalent to 'gitstatus.py', but written in bash (not python).
#
# Alan K. Stebbens <aks@stebbens.org> [http://github.com/aks]

# helper functions
count_lines() { echo "$1" | egrep -c "^$2" ; }
all_lines() { echo "$1" | grep -v "^$" | wc -l ; }

if [ -z "${__GIT_PROMPT_DIR}" ]; then
  SOURCE="${BASH_SOURCE[0]}"
  while [ -h "${SOURCE}" ]; do
    DIR="$( cd -P "$( dirname "${SOURCE}" )" && pwd )"
    SOURCE="$(readlink "${SOURCE}")"
    [[ $SOURCE != /* ]] && SOURCE="${DIR}/${SOURCE}"
  done
  __GIT_PROMPT_DIR="$( cd -P "$( dirname "${SOURCE}" )" && pwd )"
fi

if [[ -z "$__GIT_PROMPT_COLORS_FILE" ]]; then
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

# if the envar is defined, source the file for custom colors
if [[ -n "$__GIT_PROMPT_COLORS_FILE" && -f "$__GIT_PROMPT_COLORS_FILE" ]]; then
  source "$__GIT_PROMPT_COLORS_FILE"
fi

# change those symbols to whatever you prefer
if [[ -n "${GIT_PROMPT_SYMBOLS_AHEAD}" ]]; then
  symbols_ahead="${GIT_PROMPT_SYMBOLS_AHEAD}"
else
  symbols_ahead='↑·'
fi

if [[ -n "${GIT_PROMPT_SYMBOLS_BEHIND}" ]]; then
  symbols_behind="${GIT_PROMPT_SYMBOLS_BEHIND}"
else
  symbols_behind='↓·'
fi

if [[ -n "${GIT_PROMPT_SYMBOLS_PREHASH}" ]]; then
  symbols_prehash=':'
else
  symbols_prehash="${GIT_PROMPT_SYMBOLS_PREHASH}"
fi

gitsym=`git symbolic-ref HEAD`

# if "fatal: Not a git repo .., then exit
case "$gitsym" in fatal*) exit 0 ;; esac

# the current branch is the tail end of the symbolic reference
branch="${gitsym##refs/heads/}"    # get the basename after "refs/heads/"

gitstatus=`git diff --name-status 2>&1`

# if the diff is fatal, exit now
case "$gitstatus" in fatal*) exit 0 ;; esac


staged_files=`git diff --staged --name-status`

num_changed=$(( `all_lines "$gitstatus"` - `count_lines "$gitstatus" U` ))
num_conflicts=`count_lines "$staged_files" U`
num_staged=$(( `all_lines "$staged_files"` - num_conflicts ))
num_untracked=`git status -s -uall | grep -c "^??"`
if [[ -n "$GIT_PROMPT_IGNORE_STASH" ]]; then
  num_stashed=0
else	
  num_stashed=`git stash list | wc -l`
fi

clean=0
if (( num_changed == 0 && num_staged == 0 && num_U == 0 && num_untracked == 0 && num_stashed == 0 )) ; then
  clean=1
fi

remote=

if [[ -z "$branch" ]]; then
  tag=`git describe --exact-match`
  if [[ -n "$tag" ]]; then
    branch="$tag"
  else
    branch="${symbols_prehash}`git rev-parse --short HEAD`"
  fi
else
  remote_name=`git config branch.${branch}.remote`

  if [[ -n "$remote_name" ]]; then
    merge_name=`git config branch.${branch}.merge`
  else
    remote_name='origin'
    merge_name="refs/heads/${branch}"
  fi

  if [[ "$remote_name" == '.' ]]; then
    remote_ref="$merge_name"
  else
    remote_ref="refs/remotes/$remote_name/${merge_name##refs/heads/}"
  fi

  # detect if the local branch have a remote tracking branch
  cmd_output=$(git rev-parse --abbrev-ref ${branch}@{upstream} 2>&1 >/dev/null)

  if [ `count_lines "$cmd_output" "fatal: No upstream"` == 1 ] ; then
    has_remote_tracking=0
  else
    has_remote_tracking=1
  fi

  # get the revision list, and count the leading "<" and ">"
  revgit=`git rev-list --left-right ${remote_ref}...HEAD`
  num_revs=`all_lines "$revgit"`
  num_ahead=`count_lines "$revgit" "^>"`
  num_behind=$(( num_revs - num_ahead ))
  if (( num_behind > 0 )) ; then
    remote="${remote}${symbols_behind}${num_behind}"
  fi
  if (( num_ahead > 0 )) ; then
    remote="${remote}${symbols_ahead}${num_ahead}"
  fi
fi

if [[ -z "$remote" ]] ; then
  remote='.'
fi

if [[ "$has_remote_tracking" == "0" ]] ; then
  remote='L'
fi 

for w in "$branch" "$remote" $num_staged $num_conflicts $num_changed $num_untracked $num_stashed $clean ; do
  echo "$w"
done

exit
