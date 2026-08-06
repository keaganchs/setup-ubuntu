#!/usr/bin/env bash
# nvm + an LTS node, which copilot.vim and several LSP servers need.
set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

export NVM_DIR="$HOME/.nvm"

if [ ! -s "$NVM_DIR/nvm.sh" ]; then
  log "installing nvm"
  git clone -q https://github.com/nvm-sh/nvm.git "$NVM_DIR" || exit 1
  git -C "$NVM_DIR" checkout -q "$(git -C "$NVM_DIR" describe --abbrev=0 --tags)"
fi

# shellcheck disable=SC1091
. "$NVM_DIR/nvm.sh"

if [ -z "$(ls -A "$NVM_DIR/versions/node" 2>/dev/null)" ]; then
  log "installing node LTS"
  nvm install --lts
  nvm alias default 'lts/*'
else
  log "node already installed ($(nvm version default))"
fi
