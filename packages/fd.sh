#!/usr/bin/env bash
# fd -- faster file finding for telescope.
set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

has fd && { log "fd already installed"; exit 0; }

case "$(uname -m)" in
  x86_64)  FD_TARGET="x86_64-unknown-linux-musl" ;;
  aarch64) FD_TARGET="aarch64-unknown-linux-gnu" ;;
  *) err "unsupported architecture: $(uname -m)"; exit 1 ;;
esac

# apt ships this as `fdfind` (name clash with an unrelated package) and keeps it
# stale, so take the upstream tarball instead.
version="$(github_latest_tag sharkdp/fd)"
install_release_bin \
  "https://github.com/sharkdp/fd/releases/download/${version}/fd-${version}-${FD_TARGET}.tar.gz" \
  fd
