#!/usr/bin/env bash
# ripgrep -- telescope's live_grep backend.
set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

has rg && { log "ripgrep already installed"; exit 0; }

case "$(uname -m)" in
  x86_64)  RG_TARGET="x86_64-unknown-linux-musl" ;;
  aarch64) RG_TARGET="aarch64-unknown-linux-gnu" ;;
  *) err "unsupported architecture: $(uname -m)"; exit 1 ;;
esac

# Installed from the upstream tarball rather than apt so it works without root
# and doesn't lag behind.
version="$(github_latest_tag BurntSushi/ripgrep)"
install_release_bin \
  "https://github.com/BurntSushi/ripgrep/releases/download/${version}/ripgrep-${version}-${RG_TARGET}.tar.gz" \
  rg
