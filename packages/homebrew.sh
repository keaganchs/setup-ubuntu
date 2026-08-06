#!/usr/bin/env bash
# requires-sudo
# Homebrew on Linux, for tools that only ship a formula. Its installer needs
# root to create /home/linuxbrew.
set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

BREW=""
for candidate in /home/linuxbrew/.linuxbrew/bin/brew "$HOME/.linuxbrew/bin/brew"; do
  [ -x "$candidate" ] && BREW="$candidate" && break
done

if [ -z "$BREW" ]; then
  log "installing homebrew"
  NONINTERACTIVE=1 /bin/bash -c \
    "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || exit 1
  for candidate in /home/linuxbrew/.linuxbrew/bin/brew "$HOME/.linuxbrew/bin/brew"; do
    [ -x "$candidate" ] && BREW="$candidate" && break
  done
fi

[ -n "$BREW" ] || { err "homebrew install did not produce a brew binary"; exit 1; }

eval "$("$BREW" shellenv)"

# brew install is already a no-op for installed formulae, but skipping the call
# avoids a slow tap refresh on every run.
for formula in thefuck; do
  if "$BREW" list --formula "$formula" >/dev/null 2>&1; then
    log "$formula already installed"
  else
    log "brew install $formula"
    "$BREW" install "$formula" || warn "brew install $formula failed"
  fi
done
