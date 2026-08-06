#!/usr/bin/env bash
# fzf -- fuzzy finder. Its bash key bindings are wired up in bash/integrations.sh.
set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

has fzf && { log "fzf already installed"; exit 0; }

arch="$(deb_arch)" || exit 1

# apt's fzf is drastically behind upstream, so use the official release.
version="$(github_latest_tag junegunn/fzf)"
install_release_bin \
  "https://github.com/junegunn/fzf/releases/download/${version}/fzf-${version#v}-linux_${arch}.tar.gz" \
  fzf
