#!/bin/bash
# Module: git-aliases
# Version: 0.1.0
# Description: Git convenience aliases
# BashMod Dependencies: none

alias gitaddcommit='git add -A . && git commit -m '

function git-del-branch() {
    branch="$1"
    git checkout main
    git branch -D "$branch" && git push origin --delete "$branch" && git fetch --prune
}