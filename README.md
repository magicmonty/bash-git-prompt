# Informative git prompt for bash and fish

This prompt is a port of the "Informative git prompt for zsh" which you can
find [here](https://github.com/olivierverdier/zsh-git-prompt)

A ``bash`` prompt that displays information about the current git repository.
In particular the branch name, difference with remote branch, number of files
staged, changed, etc.

(an original idea from this [blog post][]).

`gitstatus.sh` and `git-prompt-help.sh` added by [AKS](http://github.com/aks).

# ATTENTION! Breaking changes!

**If you use this prompt already, please update your ``.git-prompt-colors.sh``, 
if you have one. It now contains a function named ``define_git_prompt_colors()``!**

**Please see the updated ``git-prompt-colors.sh`` in the installation directory!**

## Examples

The prompt may look like the following:

![Example prompt](gitprompt.png)

* ``(master↑3|✚1)``: on branch ``master``, ahead of remote by 3 commits, 1 file changed but not staged
* ``(status|●2)``: on branch ``status``, 2 files staged
* ``(master|✚7…)``: on branch ``master``, 7 files changed, some files untracked
* ``(master|✖2✚3)``: on branch ``master``, 2 conflicts, 3 files changed
* ``(master|⚑2)``: on branch ``master``, 2 stash entries
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
  - ``⚑n``: there are ``n`` stash entries
- Branch Tracking Symbols
  - ``↑n``: ahead of remote by ``n`` commits
  - ``↓n``: behind remote by ``n`` commits
  - ``↓m↑n``: branches diverged, other by ``m`` commits, yours by ``n`` commits
- Branch Symbol:<br />
  	When the branch name starts with a colon ``:``, it means it's actually a hash, not a branch (although it should be pretty clear, unless you name your branches like hashes :-)

## Install

1. Clone this repository to your home directory.

    git clone https://github.com/magicmonty/bash-git-prompt.git .bash-git-prompt

2. Source the file `gitprompt.sh` from `~/.bashrc`

3. `cd` to a git repository and test it!

```sh
   # some other config in .bashrc

   # gitprompt configuration

   # Set config variables first
   GIT_PROMPT_ONLY_IN_REPO=1

   # GIT_PROMPT_FETCH_REMOTE_STATUS=0   # uncomment to avoid fetching remote status

   # GIT_PROMPT_START=...    # uncomment for custom prompt start sequence
   # GIT_PROMPT_END=...      # uncomment for custom prompt end sequence

   # as last entry source the gitprompt script
   source ~/.bash-git-prompt/gitprompt.sh
```

- Go in a git repository and test it!

- You can define `GIT_PROMPT_START` and `GIT_PROMPT_END` to tweak your prompt.

- The default colors are defined within `prompt-colors.sh`, which is sourced by
  `gitprompt.sh`.  The colors used for various git status are defined in
  `git-prompt-colors.sh`.  Both of these files may be overridden by copying
  them to $HOME with a `.` prefix.  They can also be placed in `$HOME/lib`
  without the leading `.`.  The defaults are the original files in the
  `~/.bash-git-prompt` directory.

- You can use `GIT_PROMPT_START_USER`, `GIT_PROMPT_START_ROOT`,
  `GIT_PROMPT_END_USER` and `GIT_PROMPT_END_ROOT` in your
  `.git-prompt-colors.sh` to tweak your prompt. You can also override the start
  and end of the prompt by setting `GIT_PROMPT_START` and `GIT_PROMPT_END`
  before you source the `gitprompt.sh`.

- The current git repo information is obtained by the script `gitstatus.sh` or
  `gitstatus.py`.  Both scripts do the same thing, but the bash script is a tad
  more quick, and is used by default.  If you prefer the python script
  (possibly because you have enhanced it), simply delete or change the name of
  `gitstatus.sh`.

- You can define `prompt_callback` function to tweak your prompt dynamically.

```sh
function prompt_callback {
    if [ `jobs | wc -l` -ne 0 ]; then
        echo -n " jobs:\j"
    fi
}
```

- If you want to show the git prompt only if you are in a git repository you
  can set ``GIT_PROMPT_ONLY_IN_REPO=1`` before sourcing the gitprompt script

- You can show an additional indicator at the start of the prompt, which shows
  the result of the last executed command by setting
  ``GIT_PROMPT_SHOW_LAST_COMMAND_INDICATOR=1`` before sourcing the gitprompt
  script. 
  If you want to display the exit code too, you can use the placeholder
  ``_LAST_COMMAND_STATE_`` in ``GIT_PROMPT_COMMAND_OK`` or ``GIT_PROMPT_COMMAND_FAIL``
  in your ``.git-prompt-colors.sh``:

```sh
GIT_PROMPT_COMMAND_OK="${Green}✔-_LAST_COMMAND_STATE_ " # displays as ✔-0
GIT_PROMPT_COMMAND_FAIL="${Red}✘-_LAST_COMMAND_STATE_ " # displays as ✘-1 for exit code 1
``` 

- It is now possible to disable the fetching of the remote repository either
  globally by setting ``GIT_PROMPT_FETCH_REMOTE_STATUS=0`` in your .bashrc or
  on a per repository basis by creating a file named ``.bash-git-rc`` with the
  content ``FETCH_REMOTE_STATUS=0`` in the root of your git repository.

- You can get help on the git prompt with the function ``git_prompt_help``.
  Examples are available with ``git_prompt_examples``.

- If you make any changes to any file that is sourced by `gitprompt.sh`, you
  should run this command, so that the next prompt update will find all the
  files and source them anew.

```sh
git_prompt_reset
```

**Enjoy!**

## Alternative RPM Install

This project ships an RPM spec to simplify installation on RHEL and
clones. If you wish to install from RPM, you may first build the RPM
from scratch by following this procedure:
* Clone this repository and tag the release with a version number

````sh
    git tag -a -m "Tag release 1.1" 1.1
````

* Run the following command to create a tarball:

````sh
    VER1=$(git describe)
    # replace dash with underscore to work around
    # rpmbuild does not allow dash in version string
    VER=${VER1//\-/_}
    git archive                                \
        --format tar                           \
        --prefix=bash-git-prompt-${VER}/       \
        HEAD                                   \
        --  *.sh                               \
            *.py                               \
            *.fish                             \
            README.md                          \
      > bash-git-prompt-${VER}.tar
    mkdir -p /tmp/bash-git-prompt-${VER}
    sed "s/Version:.*/Version:        ${VER}/"          \
        bash-git-prompt.spec                            \
      > /tmp/bash-git-prompt-${VER}/bash-git-prompt.spec
    OLDDIR=$(pwd)
    cd /tmp
    tar -uf ${OLDDIR}/bash-git-prompt-${VER}.tar      \
            bash-git-prompt-${VER}/bash-git-prompt.spec
    cd ${OLDDIR}
    gzip bash-git-prompt-${VER}.tar
    mv bash-git-prompt-${VER}.tar.gz bash-git-prompt-${VER}.tgz
````

* Log into an RHEL or clones host and run:

````sh
rpmbuild -ta bash-git-prompt-xxx.tar.gz
````
Then you may publish or install the rpm from "~/rpmbuild/RPMS/noarch".

[blog post]: http://sebastiancelis.com/2009/nov/16/zsh-prompt-git-users/
