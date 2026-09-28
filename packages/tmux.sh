#!/usr/bin/env bash
# tmux plus its plugins. The config itself is symlinked by install.sh; this
# script installs the binary and lets tpm fetch the plugins listed in tmux.conf.
set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

if ! has tmux; then
  if [ -n "${NO_SUDO:-}" ]; then
    warn "tmux binary needs root to install (apt); the config is still set up."
    warn "Ask an admin for 'apt install tmux', or build it into ~/.local yourself."
  else
    apt_install tmux || exit 1
  fi
fi

# tpm has to land as a real git checkout rather than a copy of the submodule's
# files: it tells installed plugins apart by running `git remote` in each plugin
# directory, and `prefix + U` updates tpm itself through that remote.
TPM_DIR="$HOME/.config/tmux/plugins/tpm"
if ! git -C "$TPM_DIR" remote >/dev/null 2>&1; then
  log "installing tpm"
  rm -rf "$TPM_DIR"
  mkdir -p "$(dirname "$TPM_DIR")"
  if git clone -q https://github.com/tmux-plugins/tpm "$TPM_DIR"; then
    # Pin to the revision this repo's submodule records, so the installed tpm
    # matches what the dotfiles were tested against.
    rev="$(git -C "$DOTFILES_DIR" rev-parse "HEAD:config/tmux/plugins/tpm" 2>/dev/null)"
    [ -n "$rev" ] && git -C "$TPM_DIR" checkout -q "$rev" 2>/dev/null
  else
    warn "could not clone tpm; tmux plugins won't be installed"
  fi
fi

TPM="$TPM_DIR/bin/install_plugins"
if has tmux && [ -x "$TPM" ]; then
  log "installing tmux plugins via tpm"
  # tpm is a no-op for plugins that are already cloned.
  "$TPM" >/dev/null || warn "tpm couldn't install plugins; run prefix + I inside tmux"
fi
