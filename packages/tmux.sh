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

TPM="$HOME/.config/tmux/plugins/tpm/bin/install_plugins"
if has tmux && [ -x "$TPM" ]; then
  log "installing tmux plugins via tpm"
  # tpm is a no-op for plugins that are already cloned.
  "$TPM" >/dev/null || warn "tpm couldn't install plugins; run prefix + I inside tmux"
fi
