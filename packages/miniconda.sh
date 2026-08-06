#!/usr/bin/env bash
# Miniconda, with auto-activation of the base env turned off so it doesn't
# shadow project venvs.
set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

CONDA_DIR="$HOME/miniconda3"

if [ ! -x "$CONDA_DIR/bin/conda" ]; then
  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' EXIT

  log "installing miniconda"
  curl -fsSL "https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-$(uname -m).sh" -o "$tmp/miniconda.sh" || exit 1
  # -b batch, -u update in place: makes a re-run non-interactive and harmless.
  bash "$tmp/miniconda.sh" -b -u -p "$CONDA_DIR" || exit 1
else
  log "miniconda already installed"
fi

# conda init appends its own block to ~/.bashrc and is a no-op once present.
"$CONDA_DIR/bin/conda" init --all >/dev/null
# auto_activate is the current name; older conda only knows auto_activate_base.
"$CONDA_DIR/bin/conda" config --set auto_activate false 2>/dev/null \
  || "$CONDA_DIR/bin/conda" config --set auto_activate_base false
log "miniconda ready ($("$CONDA_DIR/bin/conda" --version))"
