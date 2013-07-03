# Informative git prompt for bash and fish

This prompt is a port of the "Informative git prompt for zsh" which you can find [here](https://github.com/olivierverdier/zsh-git-prompt)

A ``bash`` prompt that displays information about the current git repository.
In particular the branch name, difference with remote branch, number of files staged, changed, etc.

(an original idea from this [blog post][]).

## Examples

The prompt may look like the following: 

* ``(master↑3|✚1)``: on branch ``master``, ahead of remote by 3 commits, 1 file changed but not staged
* ``(status|●2)``: on branch ``status``, 2 files staged
* ``(master|✚7…)``: on branch ``master``, 7 files changed, some files untracked
* ``(master|✖2✚3)``: on branch ``master``, 2 conflicts, 3 files changed
* ``(experimental↓2↑3|✔)``: on branch ``experimental``; your branch has diverged by 3 commits, remote by 2 commits; the repository is otherwise clean
* ``(:70c2952|✔)``: not on any branch; parent commit has hash ``70c2952``; the repository is otherwise clean

##  Prompt Structure

By default, the general appearance of the prompt is::

    (<branch> <branch tracking>|<local status>)

The symbols are as follows:

- Local Status Symbols
  - ``✔``: repository clean
  - ``●n``: there are ``n`` staged files
  - ``✖n``: there are ``n`` unmerged files
  - ``✚n``: there are ``n`` changed but *unstaged* files
  - ``…n``: there are ``n`` untracked files
- Branch Tracking Symbols
  - ``↑n``: ahead of remote by ``n`` commits
  - ``↓n``: behind remote by ``n`` commits
  - ``↓m↑n``: branches diverged, other by ``m`` commits, yours by ``n`` commits
- Branch Symbol:<br />
  	When the branch name starts with a colon ``:``, it means it's actually a hash, not a branch (although it should be pretty clear, unless you name your branches like hashes :-)

## Install

1. Create the directory ``~/.bash`` if it does not exist (this location is customizable).
1. Move the file ``gitstatus.py`` into ``~/.bash/``.
1. Source the file ``gitprompt.sh`` from your ``~/.bashrc`` config file, and, configure your prompt in ``~/.bash/gitprompt.sh``. For this you have to set the variables PROMPT\_START and PROMPT\_END.
1. You may also redefine the function ``setGitPrompt`` to adapt it to your needs (to change the order in which the information is displayed).
1. Go in a git repository and test it!

**Enjoy!**

[blog post]: http://sebastiancelis.com/2009/nov/16/zsh-prompt-git-users/