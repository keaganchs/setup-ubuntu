#!/usr/bin/env bash
# requires-sudo
# Discord. The snap is community-maintained and sandboxed away from screen
# sharing, so use the official .deb.
set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

has discord && { log "discord already installed"; exit 0; }

apt_install_deb "https://discord.com/api/download?platform=linux&format=deb"
