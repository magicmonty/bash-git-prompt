#!/bin/bash
# -*- coding: UTF-8 -*-
# gitstatus.sh -- produce the current git repo status on STDOUT
# Functionally equivalent to 'gitstatus.py', but written in bash (not python).
#
# Alan K. Stebbens <aks@stebbens.org> [http://github.com/aks]

# change those symbols to whatever you prefer
symbols_ahead='↑·'
symbols_behind='↓·'
symbols_prehash=':'

gitsym=`git symbolic-ref HEAD`

# if "fatal: Not a git repo .., then exit
case "$gitsym" in fatal*) exit 0 ;; esac

# the current branch is the tail end of the symbolic reference
branch="${gitsym##refs/heads/}"    # get the basename after "refs/heads/"

tmp="/tmp/$$-gitstatus.out"
trap "rm -f \"$tmp\"" EXIT

status=`git diff --name-status >$tmp`

# if the diff is fatal, exit now
if grep -s "^fatal:" $tmp 2>/dev/null ; then
  exit
fi

# count_lines U
count_lines() { egrep -c "^$1" <$tmp ; }

num_changed=$(( `wc -l <$tmp` - `count_lines U` ))

staged_files=`git diff --staged --name-status >$tmp`
num_conflicts=`count_lines U`
num_staged=$(( `wc -l <$tmp` - num_conflicts ))
num_untracked=`git status -s -uall | grep -c "^??"`
num_stashed=`git stash list | wc -l`

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
    remote_ref="refs/remotes/$remote_name/${merge_name##*/}"
  fi
  # get the revision list, and count the leading "<" and ">"
  revgit=`git rev-list --left-right ${remote_ref}...HEAD >$tmp`
  num_revs=`wc -l <$tmp`
  num_ahead=`count_lines "^>"`
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

for w in "$branch" "$remote" $num_staged $num_conflicts $num_changed $num_untracked $num_stashed $clean ; do
  echo "$w"
done

exit
