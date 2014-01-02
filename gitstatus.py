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

from subprocess import Popen, PIPE

import sys
gitsym = Popen(['git', 'symbolic-ref', 'HEAD'], stdout=PIPE, stderr=PIPE)
branch, error = gitsym.communicate()

error_string = error.decode('utf-8')

if 'fatal: Not a git repository' in error_string:
	sys.exit(0)

branch = branch.decode('utf-8').strip()[11:]

res, err = Popen(['git','diff','--name-status'], stdout=PIPE, stderr=PIPE).communicate()
err_string = err.decode('utf-8')

if 'fatal' in err_string:
	sys.exit(0)

changed_files = [namestat[0] for namestat in res.splitlines()]
staged_files = [namestat[0] for namestat in Popen(['git','diff', '--staged','--name-status'], stdout=PIPE).communicate()[0].splitlines()]
nb_changed = len(changed_files) - changed_files.count('U')
nb_U = staged_files.count('U')
nb_staged = len(staged_files) - nb_U
staged = str(nb_staged)
conflicts = str(nb_U)
changed = str(nb_changed)
status_lines = Popen(['git','status','-s','-uall'],stdout=PIPE).communicate()[0].splitlines()
untracked_lines = [a for a in map(lambda s: s.decode('utf-8'), status_lines) if a.startswith("??")]
nb_untracked = len(untracked_lines)
untracked = str(nb_untracked)
stashes = Popen(['git','stash','list'],stdout=PIPE).communicate()[0].splitlines()
nb_stashed = len(stashes)
stashed = str(nb_stashed)

if not nb_changed and not nb_staged and not nb_U and not nb_untracked and not nb_stashed:
	clean = '1'
else:
	clean = '0'

remote = ''

tag, tag_error = Popen(['git', 'describe', '--exact-match'], stdout=PIPE, stderr=PIPE).communicate()

if not branch: # not on any branch
	if tag: # if we are on a tag, print the tag's name
		branch = tag
	else:
		branch = symbols['prehash']+ Popen(['git','rev-parse','--short','HEAD'], stdout=PIPE).communicate()[0].decode('utf-8')[:-1]
else:
	remote_name = Popen(['git','config','branch.%s.remote' % branch], stdout=PIPE).communicate()[0].strip()
	if remote_name:
		merge_name = Popen(['git','config','branch.%s.merge' % branch], stdout=PIPE).communicate()[0].strip()
	else:
		remote_name = "origin"
		merge_name = "refs/heads/%s" % branch

	if remote_name == '.': # local
		remote_ref = merge_name
	else:
		remote_ref = 'refs/remotes/%s/%s' % (remote_name, merge_name[11:])
	revgit = Popen(['git', 'rev-list', '--left-right', '%s...HEAD' % remote_ref],stdout=PIPE, stderr=PIPE)
	revlist = revgit.communicate()[0]
	if revgit.poll(): # fallback to local
		revlist = Popen(['git', 'rev-list', '--left-right', '%s...HEAD' % merge_name],stdout=PIPE, stderr=PIPE).communicate()[0]
	behead = revlist.splitlines()
	ahead = len([x for x in behead if x[0]=='>'])
	behind = len(behead) - ahead
	if behind:
		remote += '%s%s' % (symbols['behind'], behind)
	if ahead:
		remote += '%s%s' % (symbols['ahead of'], ahead)

if remote == "":
	remote = '.'

out = '\n'.join([
	str(branch),
	str(remote),
	staged,
	conflicts,
	changed,
	untracked,
	stashed,
	clean])
Print(out)
