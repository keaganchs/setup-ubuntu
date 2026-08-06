#!/usr/bin/env bash
# tree-sitter CLI -- nvim-treesitter needs it to compile parsers.
set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

has tree-sitter && { log "tree-sitter already installed"; exit 0; }

case "$(uname -m)" in
  x86_64)  TS_ARCH="x64" ;;
  aarch64) TS_ARCH="arm64" ;;
  *) err "unsupported architecture: $(uname -m)"; exit 1 ;;
esac

# apt's tree-sitter lags several major releases behind nvim-treesitter's needs.
install_release_bin \
  "https://github.com/tree-sitter/tree-sitter/releases/latest/download/tree-sitter-cli-linux-${TS_ARCH}.zip" \
  tree-sitter
