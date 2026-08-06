#!/usr/bin/env bash

# Prepend a directory to PATH, but only once and only if it exists.
_path_prepend() {
  [ -d "$1" ] || return 0
  case ":$PATH:" in
    *":$1:"*) ;;
    *) PATH="$1:$PATH" ;;
  esac
}

_path_prepend "$HOME/.local/bin"
_path_prepend "$HOME/.cargo/bin"

# Tools installed as self-contained trees under ~/.local/share (nvim, ...).
for _bin in "$HOME"/.local/share/*/bin; do
  _path_prepend "$_bin"
done
unset _bin

export PATH
export EDITOR="${EDITOR:-nvim}"
export VISUAL="$EDITOR"

export NVM_DIR="$HOME/.nvm"
for _node_bin in "$NVM_DIR"/versions/node/*/bin; do
  _path_prepend "$_node_bin"
done
unset _node_bin
export PATH

# Load nvm lazily -- sourcing it eagerly adds ~250ms to every shell start.
nvm() {
  unset -f nvm
  # shellcheck disable=SC1091
  [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh" --no-use
  nvm "$@"
}
