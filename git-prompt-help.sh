#!/usr/bin/env bash
#  git-prompt-help -- show useful info to help new users with the information
# being displayed.

git_prompt_help() {
  source "${__GIT_PROMPT_DIR}/prompt-colors.sh"
  source "${__GIT_PROMPT_DIR}/themes/Default.bgptheme"

 cat <<EOF | sed 's/\\\[\\033//g' | sed 's/\\\]//g'
git prompt の書式：${GIT_PROMPT_PREFIX}<BRANCH><TRACKING>${GIT_PROMPT_SEPARATOR}<LOCALSTATUS>${GIT_PROMPT_SUFFIX}${ResetColor}

BRANCH は "${GIT_PROMPT_MASTER_BRANCH}master${ResetColor}" や "${GIT_PROMPT_BRANCH}stage${ResetColor}" のようなブランチ名、タグ名、もしくは
'${GIT_PROMPT_SYMBOLS_PREHASH:-':'}${ResetColor}'プリフィックスが付いたコミット${GIT_PROMPT_SYMBOLS_PREHASH}hash${ResetColor}。

TRACKING は、ローカルブランチがリモートブランチからどれだけ乖離していかを表す。
これは空の文字列もしくは以下のいずれか：

    ${GIT_PROMPT_BRANCH}${ResetColor}${GIT_PROMPT_REMOTE}${GIT_PROMPT_SYMBOLS_AHEAD}N${ResetColor} - リモートより N コミット分進んでいる
    ${GIT_PROMPT_BRANCH}${ResetColor}${GIT_PROMPT_REMOTE}${GIT_PROMPT_SYMBOLS_BEHIND}M${ResetColor} - リモートより M ミット分遅れている
    ${GIT_PROMPT_BRANCH}${ResetColor}${GIT_PROMPT_REMOTE}${GIT_PROMPT_SYMBOLS_BEHIND}M${GIT_PROMPT_SYMBOLS_AHEAD}N${ResetColor} - ブランチは分岐済み。他は M コミット分、あなたは N コミット分

LOCALSTATUS は以下のいずれか：

    ${GIT_PROMPT_CLEAN}${ResetColor} - リポジトリはクリーン（同期が取れている）
    ${GIT_PROMPT_STAGED}N${ResetColor} - ステージングされたファイルが N 個
    ${GIT_PROMPT_CONFLICTS}N${ResetColor} - マージコンフリクトが N ファイル
    ${GIT_PROMPT_CHANGED}N${ResetColor} - 変更＆未ステージングが N 個
    ${GIT_PROMPT_UNTRACKED}N${ResetColor} - 未追跡ファイルが N 個
    ${GIT_PROMPT_STASHED}N${ResetColor} - stash エントリが N 個

使用例は "git_prompt_examples" を参照のこと。
EOF
}

help_git_prompt() { git_prompt_help ; }

git_prompt_examples() {

  format_branch() {
    case "$1" in
      ${GIT_PROMPT_MASTER_BRANCHES})
        echo "${GIT_PROMPT_MASTER_BRANCH}$1${ResetColor}"
        ;;
      *)
        echo "${GIT_PROMPT_BRANCH}$1${ResetColor}"
        ;;
    esac
  }
  local p="${GIT_PROMPT_PREFIX}"
  local s="${GIT_PROMPT_SUFFIX}${ResetColor}"

  cat <<EOF | sed 's/\\\[\\033//g' | sed 's/\\\]//g'
これらは git prompt の表示状態のサンプルです：

${p}`format_branch master`${GIT_PROMPT_REMOTE}${GIT_PROMPT_SYMBOLS_AHEAD}3${ResetColor}|${GIT_PROMPT_CHANGED}1${ResetColor}${s}  - 現在 "master" ブランチ、リモートより進んでいるのが
    ３コミット、変更されたが未ステージングが１ファイル

${p}`format_branch status`${GIT_PROMPT_SEPARATOR}${GIT_PROMPT_STAGED}2${ResetColor}${s}     - 現在 "status" ブランチ、２ファイルがステージング済み

${p}`format_branch master`${GIT_PROMPT_SEPARATOR}${GIT_PROMPT_CHANGED}7${GIT_PROMPT_UNTRACKED}${ResetColor}${s}   - 現在 "master" ブランチ, 変更ファイル７、未追跡ファイルあり

${p}`format_branch master`${GIT_PROMPT_SEPARATOR}${GIT_PROMPT_CONFLICTS}2${GIT_PROMPT_CHANGED}3${ResetColor}${s}  - 現在 "master" ブランチ, コンフリクト２、変更３

${p}`format_branch master`${GIT_PROMPT_SEPARATOR}${GIT_PROMPT_STASHED}2${ResetColor}${s}     - 現在 "master" ブランチ, stash（退避）３

${p}`format_branch experimental`${GIT_PROMPT_REMOTE}${GIT_PROMPT_SYMBOLS_BEHIND}2${GIT_PROMPT_SYMBOLS_AHEAD}3${ResetColor}${GIT_PROMPT_SEPARATOR}${GIT_PROMPT_CLEAN}${ResetColor}${s} - 現在 "experimental" ブランチ：あなたのブランチは
    分岐後３コミット、リモートから２コミット、それ以外はクリーン。

${p}${GIT_PROMPT_BRANCH}${GIT_PROMPT_SYMBOLS_PREHASH}70c2952${ResetColor}${GIT_PROMPT_SEPARATOR}${GIT_PROMPT_CLEAN}${ResetColor}${s}    - どのブランチにもいない状態、親コミットは "70c2952"、
    それ以外はクリーン。

${p}`format_branch extra-features`${GIT_PROMPT_SYMBOLS_NO_REMOTE_TRACKING}${ResetColor}${GIT_PROMPT_SEPARATOR}${GIT_PROMPT_CHANGED}2${GIT_PROMPT_UNTRACKED}4${ResetColor}${s} - 現在 "extra-features" ブランチ、リモートセットは
    存在しない ( '${GIT_PROMPT_SYMBOLS_NO_REMOTE_TRACKING}${ResetColor}' によるシグナル),変更２ファイルで、未追跡ファイルが４個
EOF
}

git_prompt_color_samples() {

  showColor() {
    local color=$(eval echo "\${${1}}")
    echo -e "${color}${1}${ResetColor}" | sed 's/\\\]//g'  | sed 's/\\\[//g'
  }

  local x=0
  while (( x < 8 )) ; do
    showColor "${ColorNames[@]:$x:1}"
    showColor "Dim${ColorNames[@]:$x:1}"
    showColor "Bold${ColorNames[@]:$x:1}"
    showColor "Bright${ColorNames[@]:$x:1}"
    (( x++ ))
  done
}
