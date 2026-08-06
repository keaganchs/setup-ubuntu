#!/usr/bin/env bash

alias ls='ls --color=auto'
alias ll='ls -lh'
alias la='ls -lAh'
alias grep='grep --color=auto'

if command -v nvim >/dev/null 2>&1; then
  alias vim='nvim'
  alias vi='nvim'
fi

alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gd='git diff'
alias gco='git checkout'
alias gb='git branch'
alias gp='git pull'

command -v thefuck >/dev/null 2>&1 && eval "$(thefuck --alias)"
