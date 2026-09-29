#!/usr/bin/env bash

# tm: attach to (or create) a tmux session named after the current git repo.
tm() {
  local dir name
  if dir=$(git rev-parse --show-toplevel 2>/dev/null); then
    name=$(basename "$dir")
  else
    dir=$PWD
    name=$dir
  fi
  name=${name//./_}
  name=${name//:/_}

  tmux has-session -t "$name" 2>/dev/null || tmux new-session -ds "$name" -c "$dir"

  if [ -n "$TMUX" ]; then
    tmux switch-client -t "$name"
  else
    tmux attach-session -t "$name"
  fi
}

# tmux resume / tmux r: start tmux and restore the last tmux-resurrect save
# (config/tmux/scripts/resume.sh). Everything else goes straight to tmux. Bare
# `r` is free to take: tmux accepts a command prefix only when it's unambiguous,
# and r would match several.
tmux() {
  case "${1:-}" in
    resume|r) shift; "$HOME/.config/tmux/scripts/resume.sh" "$@" ;;
    *) command tmux "$@" ;;
  esac
}

# clear: drop tmux's scrollback along with the screen. Without this the lines
# are still there in the pane's history -- and, since tmux.conf has resurrect
# capture the pane contents, they'd come back from a save as well.
clear() {
  command clear "$@"
  local rc=$?
  [ -n "${TMUX:-}" ] && tmux clear-history 2>/dev/null
  return "$rc"
}

# Auto-activate ./.venv on cd, and deactivate when leaving the project.
_venv_auto() {
  if [ -n "$VIRTUAL_ENV" ] && [[ "$PWD/" != "$(dirname "$VIRTUAL_ENV")/"* ]]; then
    if declare -F deactivate >/dev/null; then
      deactivate
    else
      unset VIRTUAL_ENV
    fi
  fi
  if [ -z "$VIRTUAL_ENV" ] && [ -f ./.venv/bin/activate ]; then
    # shellcheck disable=SC1091
    . ./.venv/bin/activate
  fi
}

case "${PROMPT_COMMAND:-}" in
  *_venv_auto*) ;;
  "") PROMPT_COMMAND="_venv_auto" ;;
  *)  PROMPT_COMMAND="_venv_auto; $PROMPT_COMMAND" ;;
esac
