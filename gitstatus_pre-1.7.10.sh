#!/usr/bin/env bash
# -*- coding: UTF-8 -*-
# gitstatus.sh -- produce the current git repo status on STDOUT
# Functionally equivalent to 'gitstatus.py', but written in bash (not python).
#
# Alan K. Stebbens <aks@stebbens.org> [http://github.com/aks]

# helper functions
count_lines() { echo "${1}" | egrep -c "^${2}" ; }
all_lines() { echo "${1}" | grep -v "^$" | wc -l ; }

if [[ -z "${__GIT_PROMPT_DIR-}" ]]; then
  SOURCE="${BASH_SOURCE[0]}"
  while [[ -h "${SOURCE}" ]]; do
    DIR="$( cd -P "$( dirname "${SOURCE}" )" && pwd )"
    SOURCE="$(readlink "${SOURCE}")"
    [[ "${SOURCE}" != /* ]] && SOURCE="${DIR}/${SOURCE}"
  done
  __GIT_PROMPT_DIR="$( cd -P "$( dirname "${SOURCE}" )" && pwd )"
fi

if [[ "${__GIT_PROMPT_WITH_USERNAME_AND_REPO}" == "1" ]]; then
  # returns "user/repo" from remote.origin.url git variable
  #
  # supports urls:
  # https://user@bitbucket.org/user/repo.git
  # https://github.com/user/repo.git
  # git@github.com:user/repo.git
  #
  remote_url=$(git config --get remote.origin.url | sed 's|^.*//||; s/.*@//; s/[^:/]\+[:/]//; s/.git$//')
else
  remote_url='.'
fi

gitsym=$( git symbolic-ref HEAD 2>/dev/null )

#If exit status OK, we have a branch
if [[ "${?}" == 0 ]]; then
  # the current branch is the tail end of the symbolic reference
  branch="${gitsym##refs/heads/}"    # get the basename after "refs/heads/"
fi

gitstatus=$( git diff --name-status 2>&1 )

# if the diff is fatal, exit now
if [[ "${?}" != 0 ]]; then exit 0; fi

staged_files=$( git diff --staged --name-status )

num_changed=$(( $( all_lines "${gitstatus}" ) - $( count_lines "${gitstatus}" U ) ))
num_conflicts=$( count_lines "${staged_files}" U )
num_staged=$(( $( all_lines "${staged_files}" ) - num_conflicts ))
num_untracked=$( git ls-files --others --exclude-standard $(git rev-parse --show-cdup) | wc -l )

num_stashed=0
if [[ "${__GIT_PROMPT_IGNORE_STASH}" != "1" ]]; then
  stash_file="$( git rev-parse --git-dir )/logs/refs/stash"
  if [[ -e "${stash_file}" ]]; then
    while IFS='' read -r wcline || [[ -n "${wcline}" ]]; do
      ((num_stashed++))
    done < "${stash_file}"
  fi
fi

clean=0
if (( num_changed == 0 && num_staged == 0 && num_untracked == 0 && num_stashed == 0 && num_conflicts == 0 )) ; then
  clean=1
fi

remote=""
upstream=""

if [[ -z "${branch-}" ]]; then
  tag=$( git describe --tags --exact-match 2>/dev/null )
  if [[ -n "${tag}" ]]; then
    branch="${tag}"
  else
    branch="_PREHASH_$( git rev-parse --short HEAD )"
  fi
else
  remote_name=$( git config "branch.${branch}.remote" )

  if [[ -n "$remote_name" ]]; then
    merge_name=$( git config "branch.${branch}.merge" )
  else
    remote_name='origin'
    merge_name="refs/heads/${branch}"
  fi

  if [[ "${remote_name}" == '.' ]]; then
    remote_ref="${merge_name}"
  else
    remote_ref="refs/remotes/${remote_name}/${merge_name##refs/heads/}"
  fi

  # detect if the local branch have a remote tracking branch
  upstream=$( git rev-parse --abbrev-ref "${branch}"@{upstream} 2>&1 )

  if [[ "${?}" == 0 ]]; then
     # get the revision list, and count the leading "<" and ">"
    revgit=$( git rev-list --left-right "${remote_ref}...HEAD" 2>/dev/null )
    if [[ "${?}" == 0 ]]; then
      num_revs=$( all_lines "${revgit}" )
      num_ahead=$( count_lines "${revgit}" "^>" )
      num_behind=$(( num_revs - num_ahead ))
      if (( num_behind > 0 )) ; then
        remote="${remote}_BEHIND_${num_behind}"
      fi
      if (( num_ahead > 0 )) ; then
        remote="${remote}_AHEAD_${num_ahead}"
      fi
    fi
  else
    remote='_NO_REMOTE_TRACKING_'
    remote_url='.'
    unset upstream
  fi
fi

if [[ -z "${remote:+x}" ]] ; then
  remote='.'
fi

if [[ -z "${upstream:+x}" ]] ; then
  upstream='^'
fi

printf "%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n" \
  "${branch}" \
  "${remote}" \
  "${remote_url}" \
  "${upstream}" \
  "${num_staged}" \
  "${num_conflicts}" \
  "${num_changed}" \
  "${num_untracked// /}" \
  "${num_stashed}" \
  "${clean}"

exit
