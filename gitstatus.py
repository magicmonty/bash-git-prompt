#!/usr/bin/env python
# -*- coding: UTF-8 -*-

"""This module defines a Print function to use with python 2.x or 3.x., so we can use the prompt with older versions of Python too

It's interface is that of python 3.0's print. See
http://docs.python.org/3.0/library/functions.html?highlight=print#print

Shamelessly ripped from http://www.daniweb.com/software-development/python/code/217214/a-print-function-for-different-versions-of-python
"""

__all__ = ["Print"]
import sys
try:
  Print = eval("print") # python 3.0 case
except SyntaxError:
  try:
    D = dict()
    exec("from __future__ import print_function\np=print", D)
    Print = D["p"] # 2.6 case
    del D
  except SyntaxError:
    del D
    def Print(*args, **kwd): # 2.4, 2.5, define our own Print function
      fout = kwd.get("file", sys.stdout)
      w = fout.write
      if args:
        w(str(args[0]))
        sep = kwd.get("sep", " ")
        for a in args[1:]:
          w(sep)
          w(str(a))
      w(kwd.get("end", "\n"))

# change those symbols to whatever you prefer
symbols = {'ahead of': '↑·', 'behind': '↓·', 'prehash':':'}

import sys
import re
import shlex
from subprocess import Popen, PIPE, check_output


def get_tagname_or_hash():
    """return tagname if exists else hash"""
    cmd = 'git log -1 --format="%h%d"'
    output = check_output(shlex.split(cmd)).decode('utf-8').strip()
    hash_, tagname = None, None
    # get hash
    m = re.search('\(.*\)$', output)
    if m:
        hash_ = output[:m.start()-1]
    # get tagname
    m = re.search('tag: .*[,\)]', output)
    if m:
        tagname = 'tags/' + output[m.start()+len('tag: '): m.end()-1]

    if tagname:
        return tagname
    elif hash_:
        return hash_
    return None

def get_stash():
    cmd = Popen(['git', 'rev-parse', '--git-dir'], stdout=PIPE, stderr=PIPE)
    so, se = cmd.communicate()
    stashFile = '%s%s' % (so.decode('utf-8').rstrip(),'/logs/refs/stash')

    try:
        with open(stashFile) as f:
            return sum(1 for _ in f)
    except IOError:
        return 0

# `git status --porcelain --branch` can collect all information
# branch, remote_branch, untracked, staged, changed, conflicts, ahead, behind
po = Popen(['git', 'status', '--porcelain', '--branch'], env={'LC_ALL': 'C'},
           stdout=PIPE, stderr=PIPE)
stdout, sterr = po.communicate()
if po.returncode != 0:
    sys.exit(0)  # Not a git repository

# collect git status information
untracked, staged, changed, conflicts = [], [], [], []
ahead, behind = 0, 0
remote = ''
status = [(line[0], line[1], line[2:]) for line in stdout.decode('utf-8').splitlines()]
for st in status:
    if st[0] == '#' and st[1] == '#':
        if re.search('Initial commit on', st[2]):
            branch = st[2].split(' ')[-1]
        elif re.search('no branch', st[2]):  # detached status
            branch = get_tagname_or_hash()
        elif len(st[2].strip().split('...')) == 1:
            branch = st[2].strip()
        else:
            # current and remote branch info
            branch, rest = st[2].strip().split('...')
            if len(rest.split(' ')) == 1:
                # remote_branch = rest.split(' ')[0]
                pass
            else:
                # ahead or behind
                divergence = ' '.join(rest.split(' ')[1:])
                divergence = divergence.lstrip('[').rstrip(']')
                for div in divergence.split(', '):
                    if 'ahead' in div:
                        ahead = int(div[len('ahead '):].strip())
                        remote += '%s%s' % (symbols['ahead of'], ahead)
                    elif 'behind' in div:
                        behind = int(div[len('behind '):].strip())
                        remote += '%s%s' % (symbols['behind'], behind)
    elif st[0] == '?' and st[1] == '?':
        untracked.append(st)
    else:
        if st[1] == 'M':
            changed.append(st)
        if st[0] == 'U':
            conflicts.append(st)
        elif st[0] != ' ':
            staged.append(st)

stashed=get_stash()
if not changed and not staged and not conflicts and not untracked and not stashed:
    clean = 1
else:
    clean = 0

if remote == "":
    remote = '.'

out = '\n'.join([
    branch,
    remote.decode('utf-8'),
    str(len(staged)),
    str(len(conflicts)),
    str(len(changed)),
    str(len(untracked)),
    str(stashed),
    str(clean)
])
Print(out)
