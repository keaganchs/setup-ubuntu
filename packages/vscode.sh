#!/usr/bin/env bash
# requires-sudo
# Visual Studio Code, from Microsoft's apt repo so it stays updated with the
# rest of the system.
set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

has code && { log "vscode already installed"; exit 0; }

KEYRING=/usr/share/keyrings/microsoft.gpg
LIST=/etc/apt/sources.list.d/vscode.list

if [ ! -f "$KEYRING" ]; then
  log "adding microsoft apt key"
  curl -fsSL https://packages.microsoft.com/keys/microsoft.asc \
    | gpg --dearmor \
    | sudo_cmd tee "$KEYRING" >/dev/null || exit 1
fi

if [ ! -f "$LIST" ]; then
  log "adding vscode apt repo"
  echo "deb [arch=$(deb_arch) signed-by=$KEYRING] https://packages.microsoft.com/repos/code stable main" \
    | sudo_cmd tee "$LIST" >/dev/null || exit 1
  apt_update force # the new repo has no index yet
fi

apt_install code
