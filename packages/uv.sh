#!/usr/bin/env bash
# uv -- python package/venv manager.
set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

has uv && { log "uv already installed"; exit 0; }
[ -x "$HOME/.local/bin/uv" ] && { log "uv already installed"; exit 0; }

log "installing uv"
curl -LsSf https://astral.sh/uv/install.sh | sh
