#!/usr/bin/env bash

# user@host:cwd (git branch)$
_git_branch_ps1() {
  local branch
  branch="$(git branch --show-current 2>/dev/null)" || return 0
  [ -n "$branch" ] && printf ' (%s)' "$branch"
}

PS1='\[\033[1;32m\]\u@\h\[\033[0m\]:\[\033[1;34m\]\w\[\033[0;33m\]$(_git_branch_ps1)\[\033[0m\]\$ '
