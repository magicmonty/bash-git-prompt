#!/bin/bash
# -*- coding: UTF-8 -*-
# gitstatus.sh -- produce the current git repo status on STDOUT
# Functionally equivalent to 'gitstatus.py', but written in bash (not python).
#
# Alan K. Stebbens <aks@stebbens.org> [http://github.com/aks]

if [ -z "${__GIT_PROMPT_DIR}" ]; then
  SOURCE="${BASH_SOURCE[0]}"
  while [ -h "${SOURCE}" ]; do
    DIR="$( cd -P "$( dirname "${SOURCE}" )" && pwd )"
    SOURCE="$(readlink "${SOURCE}")"
    [[ $SOURCE != /* ]] && SOURCE="${DIR}/${SOURCE}"
  done
  __GIT_PROMPT_DIR="$( cd -P "$( dirname "${SOURCE}" )" && pwd )"
fi

gitstatus=$( LC_ALL=C git status --porcelain --branch )

# if the status is fatal, exit now
[[ "$?" -ne 0 ]] && exit 0

num_staged=0
num_changed=0
num_conflicts=0
num_untracked=0
while IFS='' read -r line || [[ -n "$line" ]]; do
  status=${line:0:2}
  case "$status" in
    \#\#) branch_line="$line" ;;
    ?M) ((num_changed++)) ;;
    U?) ((num_conflicts++)) ;;
    \?\?) ((num_untracked++)) ;;
    *) ((num_staged++)) ;;
  esac
done <<< "$gitstatus"

if [[ "$__GIT_PROMPT_IGNORE_STASH" = "1" ]]; then
  num_stashed=0
else
  stash_file="$( git rev-parse --git-dir )/logs/refs/stash"
  if [[ -e "${stash_file}" ]]; then
    num_stashed=$( wc -l "${stash_file}" | cut -d' ' -f1 )
  else
    num_stashed=0
  fi
fi

clean=0
if (( num_changed == 0 && num_staged == 0 && num_untracked == 0 && num_stashed == 0 )) ; then
  clean=1
fi

remote=

branch_line=$( echo "$gitstatus" | grep "^##" )
IFS="." read -ra line <<< "${branch_line/\#\# }"
branch="${line[0]}"

if [[ "${#line[@]}" -eq 1 ]]; then
  remote="_NO_REMOTE_TRACKING_"
fi

if [[ -z "$branch" ]]; then
  tag=$( git describe --exact-match )
  if [[ -n "$tag" ]]; then
    branch="$tag"
  else
    branch="_PREHASH_$( git rev-parse --short HEAD )"
  fi
elif [[ "$branch" == *"Initial commit on"* ]]; then
  IFS=" " read -ra branch_line <<< "$branch"
  branch=${branch_line[-1]}
elif [[ "$branch" == *"no branch"* ]]; then
  branch="_PREHASH_$( git rev-parse --short HEAD )"
else
  IFS="[,]" read -ra remote_line <<< "${line[3]}"
  for rline in "${remote_line[@]}"; do
    if [[ "$rline" == *ahead* ]]; then
      num_ahead=${rline:6}
      remote="${remote}_AHEAD_${num_ahead}"
    fi
    if [[ "$rline" == *behind* ]]; then
      num_behind=${rline:7}
      remote="${remote}_BEHIND_${num_behind# }"
    fi
  done
fi

if [[ -z "$remote" ]] ; then
  remote='.'
fi

printf "%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n" \
  "$branch" \
  "$remote" \
  $num_staged \
  $num_conflicts \
  $num_changed \
  $num_untracked \
  $num_stashed \
  $clean

exit
