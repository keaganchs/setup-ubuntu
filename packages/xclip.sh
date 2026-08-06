#!/usr/bin/env bash
# requires-sudo
# xclip -- needed for tmux-yank and nvim's clipboard=unnamedplus under X11.
set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

has xclip && { log "xclip already installed"; exit 0; }

apt_install xclip
# Wayland sessions need wl-clipboard instead; harmless to have both.
[ -n "${WAYLAND_DISPLAY:-}" ] && apt_install wl-clipboard

exit 0
