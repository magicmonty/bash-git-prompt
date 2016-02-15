#!/usr/bin/env bash
# -*- coding: utf-8 -*-
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

gitstatus=$( LC_ALL=C git status --untracked-files=${__GIT_PROMPT_SHOW_UNTRACKED_FILES} --porcelain --branch )

# if the status is fatal, exit now
[[ "$?" -ne 0 ]] && exit 0

num_staged=0
num_changed=0
num_conflicts=0
num_untracked=0
while IFS='' read -r line || [[ -n "$line" ]]; do
  status=${line:0:2}
  case "$status" in
    \#\#) branch_line="${line/\.\.\./^}" ;;
    ?M) ((num_changed++)) ;;
    U?) ((num_conflicts++)) ;;
    \?\?) ((num_untracked++)) ;;
    *) ((num_staged++)) ;;
  esac
done <<< "$gitstatus"

num_stashed=0
if [[ "$__GIT_PROMPT_IGNORE_STASH" != "1" ]]; then
  stash_file="$( git rev-parse --git-dir )/logs/refs/stash"
  if [[ -e "${stash_file}" ]]; then
    while IFS='' read -r wcline || [[ -n "$wcline" ]]; do
      ((num_stashed++))
    done < ${stash_file}
  fi
fi

clean=0
if (( num_changed == 0 && num_staged == 0 && num_untracked == 0 && num_stashed == 0 && num_conflicts == 0)) ; then
  clean=1
fi

IFS="^" read -ra branch_fields <<< "${branch_line/\#\# }"
branch="${branch_fields[0]}"
remote=
upstream=

if [[ "$branch" == *"Initial commit on"* ]]; then
  IFS=" " read -ra fields <<< "$branch"
  branch="${fields[3]}"
  remote="_NO_REMOTE_TRACKING_"
elif [[ "$branch" == *"no branch"* ]]; then
  tag=$( git describe --exact-match )
  if [[ -n "$tag" ]]; then
    branch="$tag"
  else
    branch="_PREHASH_$( git rev-parse --short HEAD )"
  fi
else
  if [[ "${#branch_fields[@]}" -eq 1 ]]; then
    remote="_NO_REMOTE_TRACKING_"
  else
    IFS="[,]" read -ra remote_fields <<< "${branch_fields[1]}"
    upstream="${remote_fields[0]}"
    for remote_field in "${remote_fields[@]}"; do
      if [[ "$remote_field" == *ahead* ]]; then
        num_ahead=${remote_field:6}
        ahead="_AHEAD_${num_ahead}"
      fi
      if [[ "$remote_field" == *behind* ]]; then
        num_behind=${remote_field:7}
        behind="_BEHIND_${num_behind# }"
      fi
    done
    remote="${behind}${ahead}"
  fi
fi

if [[ -z "$remote" ]] ; then
  remote='.'
fi

if [[ -z "$upstream" ]] ; then
  upstream='^'
fi

printf "%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n" \
  "$branch" \
  "$remote" \
  "$upstream" \
  $num_staged \
  $num_conflicts \
  $num_changed \
  $num_untracked \
  $num_stashed \
  $clean

exit
