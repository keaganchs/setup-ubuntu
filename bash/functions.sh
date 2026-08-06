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
