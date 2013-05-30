if set -q $__GIT_PROMPT_DIR
  set __GIT_PROMPT_DIR ~/.bash
end

# Colors
# Reset
set ResetColor (set_color normal)   # Text Reset

# Regular Colors
set Red (set_color red)             # Red
set Yellow (set_color yellow);      # Yellow
set Blue (set_color blue)           # Blue
set WHITE (set_color white)

# Bold
set BGreen (set_color green)        # Green

# High Intensty
set IBlack (set_color black)        # Black

# Bold High Intensty
set Magenta (set_color purple)      # Purple

# Various variables you might want for your PS1 prompt instead
set Time (date +%X)

# Default values for the appearance of the prompt. Configure at will.
set GIT_PROMPT_PREFIX "("
set GIT_PROMPT_SUFFIX ")"
set GIT_PROMPT_SEPARATOR "|"
set GIT_PROMPT_BRANCH "$Magenta"
set GIT_PROMPT_STAGED "$Red}●"
set GIT_PROMPT_CONFLICTS "$Red✖"
set GIT_PROMPT_CHANGED "$Blue✚"
set GIT_PROMPT_REMOTE " "
set GIT_PROMPT_UNTRACKED "…"
set GIT_PROMPT_CLEAN "$BGreen✔"

#Not applied two lines conention from https://github.com/magicmonty/bash-git-prompt/pull/5/files

set PROMPT_END " % "

function fish_prompt
    set -e __CURRENT_GIT_STATUS
    set gitstatus "$__GIT_PROMPT_DIR/gitstatus.py"

    set PROMPT_START "$IBlack$Time $ResetColor$Yellow"

    set _GIT_STATUS (python $gitstatus)
    set __CURRENT_GIT_STATUS $_GIT_STATUS
    set GIT_BRANCH $__CURRENT_GIT_STATUS[1]

    set __CURRENT_GIT_STATUS_PARAM_COUNT (count $__CURRENT_GIT_STATUS)

    if not test "0" -eq $__CURRENT_GIT_STATUS_PARAM_COUNT
        set GIT_REMOTE "$__CURRENT_GIT_STATUS[2]"
        set GIT_STAGED $__CURRENT_GIT_STATUS[3]
        set GIT_CONFLICTS $__CURRENT_GIT_STATUS[4]
        set GIT_CHANGED $__CURRENT_GIT_STATUS[5]
        set GIT_UNTRACKED $__CURRENT_GIT_STATUS[6]
        set GIT_CLEAN $__CURRENT_GIT_STATUS[7]
    end

	if test -n "$__CURRENT_GIT_STATUS"
        set STATUS " $GIT_PROMPT_PREFIX$GIT_PROMPT_BRANCH$GIT_BRANCH$ResetColor"

        if test -n $GIT_REMOTE
            set STATUS "$STATUS$GIT_PROMPT_REMOTE$GIT_REMOTE$ResetColor"
        end

        set STATUS "$STATUS$GIT_PROMPT_SEPARATOR"

        if test $GIT_STAGED -ne "0"
            set STATUS "$STATUS$GIT_PROMPT_STAGED$GIT_STAGED$ResetColor"
        end

        if test $GIT_CONFLICTS -ne "0"
            set STATUS "$STATUS$GIT_PROMPT_CONFLICTS$GIT_CONFLICTS$ResetColor"
        end

        if  test $GIT_CHANGED -ne "0"
            set STATUS "$STATUS$GIT_PROMPT_CHANGED$GIT_CHANGED$ResetColor"
        end

        if test  "$GIT_UNTRACKED" -ne "0"
            set STATUS "$STATUS$GIT_PROMPT_UNTRACKED$GIT_UNTRACKED$ResetColor"
        end

        if test "$GIT_CLEAN" -eq "1"
            set STATUS "$STATUS$GIT_PROMPT_CLEAN"
        end

        set STATUS "$STATUS$ResetColor$GIT_PROMPT_SUFFIX"

        set PS1 "$PROMPT_START"(prompt_pwd)"$STATUS$PROMPT_END"
	else
        set PS1 "$PROMPT_START"(prompt_pwd)"$ResetColor$PROMPT_END"
	end
    echo -e $PS1
end


