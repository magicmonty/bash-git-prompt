  # These are the color definitions used by gitprompt.sh

  declare -g GIT_PROMPT_PREFIX
  declare -g GIT_PROMPT_SUFFIX
  declare -g GIT_PROMPT_SEPARATOR
  declare -g GIT_PROMPT_BRANCH
  declare -g GIT_PROMPT_STAGED
  declare -g GIT_PROMPT_CONFLICTS
  declare -g GIT_PROMPT_CHANGED
  declare -g GIT_PROMPT_REMOTE
  declare -g GIT_PROMPT_UNTRACKED
  declare -g GIT_PROMPT_STASHED
  declare -g GIT_PROMPT_CLEAN

  GIT_PROMPT_PREFIX="["                 # start of the git info string
  GIT_PROMPT_SUFFIX="]"                 # the end of the git info string
  GIT_PROMPT_SEPARATOR="|"              # separates each item

  GIT_PROMPT_BRANCH="${Magenta}"        # the git branch that is active in the current directory
  GIT_PROMPT_STAGED="${Red}●"           # the number of staged files/directories
  GIT_PROMPT_CONFLICTS="${Red}✖"        # the number of files in conflict
  GIT_PROMPT_CHANGED="${Blue}✚"         # the number of changed files
  GIT_PROMPT_REMOTE=" "                 # the remote branch name (if any)
  GIT_PROMPT_UNTRACKED="${Cyan}…"       # the number of untracked files/dirs
  GIT_PROMPT_STASHED="${BoldBlue}⚑"     # the number of stashed files/dir
  GIT_PROMPT_CLEAN="${BoldGreen}✔"      # a colored flag indicating a "clean" repo
