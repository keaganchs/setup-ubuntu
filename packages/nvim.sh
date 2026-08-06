#!/usr/bin/env bash
# neovim (>=0.12, for vim.pack). apt's build lags several minor releases behind,
# so install the official tarball into ~/.local/share -- which also means this
# works without root.
set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

NVIM_DIR="$HOME/.local/share/nvim"

if [ -x "$NVIM_DIR/bin/nvim" ]; then
  log "neovim already installed ($("$NVIM_DIR/bin/nvim" --version | head -1))"
  exit 0
fi

case "$(uname -m)" in
  x86_64)  NVIM_ARCH="x86_64" ;;
  aarch64) NVIM_ARCH="arm64" ;;
  *) err "unsupported architecture: $(uname -m)"; exit 1 ;;
esac

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

log "installing neovim (nvim-linux-$NVIM_ARCH)"
curl -fsSL "https://github.com/neovim/neovim/releases/latest/download/nvim-linux-${NVIM_ARCH}.tar.gz" -o "$tmp/nvim.tar.gz"
mkdir -p "$NVIM_DIR"
tar -xzf "$tmp/nvim.tar.gz" -C "$NVIM_DIR" --strip-components=1

log "installed $("$NVIM_DIR/bin/nvim" --version | head -1)"
