#!/usr/bin/env bash
# GitHub CLI.
set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

has gh && { log "gh already installed"; exit 0; }

arch="$(deb_arch)" || exit 1

# apt's gh is well behind upstream; the release tarball also installs without root.
version="$(github_latest_tag cli/cli)"
install_release_bin \
  "https://github.com/cli/cli/releases/download/${version}/gh_${version#v}_linux_${arch}.tar.gz" \
  gh
