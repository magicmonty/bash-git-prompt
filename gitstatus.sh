#!/usr/bin/env bash
# -*- coding: utf-8 -*-
# gitstatus.sh -- produce the current git repo status
#
# Alan K. Stebbens <aks@stebbens.org> [http://github.com/aks]

# These variables are created as evaluable script definitions
# * VCS_STATUS_BRANCH_NAME
# * VCS_STATUS_STATE
# * VCS_STATUS_REMOTE
# * VCS_STATUS_REMOTE_URL
# * VCS_STATUS_UPSTREAM
# * VCS_STATUS_NUM_STAGED
# * VCS_STATUS_NUM_CONFLICTS
# * VCS_STATUS_NUM_CHANGED
# * VCS_STATUS_NUM_UNTRACKED
# * VCS_STATUS_NUM_STASHED

if [[ "${__GIT_PROMPT_IGNORE_SUBMODULES:-0}" == "1" ]]; then
  _ignore_submodules="--ignore-submodules"
else
  _ignore_submodules=""
fi

if [[ "${__GIT_PROMPT_WITH_USERNAME_AND_REPO:-0}" == "1" ]]; then
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

gitstatus=$( LC_ALL=C git --no-optional-locks status ${_ignore_submodules} --untracked-files="${__GIT_PROMPT_SHOW_UNTRACKED_FILES:-normal}" --porcelain --branch )

[[ ! "${?}" ]] && return 0

git_dir="$(git rev-parse --git-dir 2>/dev/null)"
[[ -z "${git_dir:+x}" ]] && return 0

__git_prompt_read ()
{
  f="${1}"
  shift
  [[ -r "${f}" ]] && read -r "${@}" <"${f}"
}

if [[ -d "${git_dir}/rebase-merge" ]]; then
  __git_prompt_read "${git_dir}/rebase-merge/msgnum" step
  __git_prompt_read "${git_dir}/rebase-merge/end" total
  if [[ -f "${git_dir}/rebase-merge/interactive" ]]; then
    state="|REBASE-i"
  else
    state="|REBASE-m"
  fi
else
  if [[ -d "${git_dir}/rebase-apply" ]]; then
    __git_prompt_read "${git_dir}/rebase-apply/next" step
    __git_prompt_read "${git_dir}/rebase-apply/last" total
    if [[ -f "${git_dir}/rebase-apply/rebasing" ]]; then
      state="|REBASE"
    elif [[ -f "${git_dir}/rebase-apply/applying" ]]; then
      state="|AM"
    else
      state="|AM/REBASE"
    fi
  elif [[ -f "${git_dir}/MERGE_HEAD" ]]; then
    state="|MERGING"
  elif [[ -f "${git_dir}/CHERRY_PICK_HEAD" ]]; then
    state="|CHERRY-PICKING"
  elif [[ -f "${git_dir}/REVERT_HEAD" ]]; then
    state="|REVERTING"
  elif [[ -f "${git_dir}/BISECT_LOG" ]]; then
    state="|BISECTING"
  fi
fi

if [[ -n "${step}" ]] && [[ -n "${total}" ]]; then
  state="${state} ${step}/${total}"
fi

num_staged=0
num_changed=0
num_conflicts=0
num_untracked=0

while IFS='' read -r line || [[ -n "${line}" ]]; do
  status="${line:0:2}"
  while [[ -n ${status} ]]; do
    case "${status}" in
      #two fixed character matches, loop finished
      \#\#) branch_line="${line/\.\.\./^}"; break ;;
      \?\?) ((num_untracked++)); break ;;
      U?) ((num_conflicts++)); break;;
      ?U) ((num_conflicts++)); break;;
      DD) ((num_conflicts++)); break;;
      AA) ((num_conflicts++)); break;;
      #two character matches, first loop
      ?M) ((num_changed++)) ;;
      ?\ ) ;;
      #single character matches, second loop
      U) ((num_conflicts++)) ;;
      \ ) ;;
      *) ((num_staged++)) ;;
    esac
    status="${status:0:(${#status}-1)}"
  done
done <<< "${gitstatus}"

num_stashed=0
if [[ "${__GIT_PROMPT_IGNORE_STASH:-0}" != "1" ]]; then
  stash_file="${git_dir}/logs/refs/stash"
  if [[ -e "${stash_file}" ]]; then
    while IFS='' read -r wcline || [[ -n "${wcline}" ]]; do
      ((num_stashed++))
    done < "${stash_file}"
  fi
fi

IFS="^" read -ra branch_fields <<< "${branch_line/\#\# }"

branch="${branch_fields[0]}"

if [[ "${branch}" == *"Initial commit on"* ]]; then
  IFS=" " read -ra fields <<< "${branch}"
  branch="${fields[3]}"
  remote="_NO_REMOTE_TRACKING_"
  remote_url='.'
elif [[ "${branch}" == *"No commits yet on"* ]]; then
  IFS=" " read -ra fields <<< "${branch}"
  branch="${fields[4]}"
  remote="_NO_REMOTE_TRACKING_"
  remote_url='.'
elif [[ "${branch}" == *"no branch"* ]]; then
  tag=$( git describe --tags --exact-match )
  if [[ -n "${tag}" ]]; then
    branch="${tag}"
  else
    branch="_PREHASH_$( git rev-parse --short HEAD )"
  fi
else
  if [[ "${#branch_fields[@]}" -eq 1 ]]; then
    remote="_NO_REMOTE_TRACKING_"
    remote_url='.'
  else
    IFS="[,]" read -ra remote_fields <<< "${branch_fields[1]}"
    upstream="${remote_fields[0]}"
    for remote_field in "${remote_fields[@]}"; do
      if [[ "${remote_field}" == "ahead "* ]]; then
        num_ahead="${remote_field:6}"
        ahead="_AHEAD_${num_ahead}"
      fi
      if [[ "${remote_field}" == "behind "* ]] || [[ "${remote_field}" == " behind "* ]]; then
        num_behind="${remote_field:7}"
        behind="_BEHIND_${num_behind# }"
      fi
    done
    remote="${behind-}${ahead-}"
  fi
fi

if [[ -z "${remote:+x}" ]] ; then
  remote='.'
fi

if [[ -z "${upstream:+x}" ]] ; then
  upstream='^'
fi

upstream=$(echo $upstream | xargs)

printf "%s;\n%s;\n%s;\n%s;\n%s;\n%s;\n%s;\n%s;\n%s;\n%s;\n" \
  "VCS_STATUS_BRANCH_NAME=\"$branch\"" \
  "VCS_STATUS_STATE=\"$state\"" \
  "VCS_STATUS_REMOTE=\"$remote\"" \
  "VCS_STATUS_REMOTE_URL=\"$remote_url\"" \
  "VCS_STATUS_UPSTREAM=\"$upstream\"" \
  "VCS_STATUS_NUM_STAGED=\"$num_staged\"" \
  "VCS_STATUS_NUM_CONFLICTS=\"$num_conflicts\"" \
  "VCS_STATUS_NUM_CHANGED=\"$num_changed\"" \
  "VCS_STATUS_NUM_UNTRACKED=\"$num_untracked\"" \
  "VCS_STATUS_NUM_STASHED=\"$num_stashed\""
