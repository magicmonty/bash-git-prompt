#!/bin/bash
# -*- coding: UTF-8 -*-
# gitstatus.sh -- produce the current git repo status on STDOUT
# Functionally equivalent to 'gitstatus.py', but written in bash (not python).
#
# Alan K. Stebbens <aks@stebbens.org> [http://github.com/aks]

# helper functions
count_lines() { echo "$1" | egrep -c $3 "^$2" ; }

if [ -z "${__GIT_PROMPT_DIR}" ]; then
  SOURCE="${BASH_SOURCE[0]}"
  while [ -h "${SOURCE}" ]; do
    DIR="$( cd -P "$( dirname "${SOURCE}" )" && pwd )"
    SOURCE="$(readlink "${SOURCE}")"
    [[ $SOURCE != /* ]] && SOURCE="${DIR}/${SOURCE}"
  done
  __GIT_PROMPT_DIR="$( cd -P "$( dirname "${SOURCE}" )" && pwd )"
fi

gitstatus=`git status --porcelain --branch`

# if the status is fatal, exit now
[[ "$?" -ne 0 ]] && exit 0

num_staged=`count_lines "$gitstatus" "(\?\?|##| )" "-v"`
num_changed=`count_lines "$gitstatus" ".M"`
num_conflicts=`count_lines "$gitstatus" "U"`
num_untracked=`count_lines "$gitstatus" "\?\?"`

if [[ "$__GIT_PROMPT_IGNORE_STASH" = "1" ]]; then
  num_stashed=0
else
  stash_file="`git rev-parse --git-dir`/logs/refs/stash"
  if [[ -e "${stash_file}" ]]; then
    num_stashed=`wc -l "${stash_file}" | cut -d' ' -f 1`
  else
    num_stashed=0
  fi
fi

clean=0
if (( num_changed == 0 && num_staged == 0 && num_untracked == 0 && num_stashed == 0 )) ; then
  clean=1
fi

remote=

branch_line=`echo "$gitstatus" | grep "^##"`
IFS="." read -ra line <<< "${branch_line/\#\# }"
branch="${line[0]}"

if [[ -z "$branch" ]]; then
  tag=`git describe --exact-match`
  if [[ -n "$tag" ]]; then
    branch="$tag"
  else
    branch="_PREHASH_`git rev-parse --short HEAD`"
  fi
elif [[ "$branch" == *"Initial commit on"* ]]; then
  IFS=" " read -ra branch_line <<< "$branch"
  branch=${branch_line[-1]}
elif [[ "$branch" == *"no branch"* ]]; then
  branch="_PREHASH_`git rev-parse --short HEAD`"
else
  IFS="[]" read -ra remote_line <<< "${line[3]}"
  if [[ "${remote_line[1]}" == *ahead* ]]; then
    num_ahead=${remote_line[1]:6}
    remote="${remote}_AHEAD_${num_ahead}"
  fi
  if [[ "${remote_line[1]}" == *behind* ]]; then
    num_behind=${remote_line[1]:9}
    remote="${remote}_BEHIND_${num_behind}"
  fi
fi

if [[ -z "$remote" ]] ; then
  remote='.'
fi

for w in "$branch" "$remote" $num_staged $num_conflicts $num_changed $num_untracked $num_stashed $clean ; do
  echo "$w"
done

exit
