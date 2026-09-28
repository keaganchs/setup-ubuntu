#!/usr/bin/env bash
# A python venv with pynvim, for nvim's python3 provider (UltiSnips needs it).
# lua/user/latex.lua points g:python3_host_prog here.
set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

VENV="$HOME/.local/share/nvim-python"

if "$VENV/bin/python3" -c 'import pynvim' 2>/dev/null; then
  log "nvim python provider already installed"
  exit 0
fi

# The system python rather than whatever is first on PATH: a Homebrew python
# gets upgraded in place, and a venv built on it breaks when that happens.
PYTHON=/usr/bin/python3
[ -x "$PYTHON" ] || PYTHON="$(command -v python3)"
[ -n "$PYTHON" ] || { err "no python3 found"; exit 1; }

log "creating $VENV"
# A venv left half-built by a failed run would make `-m venv` reuse it.
rm -rf "$VENV"
"$PYTHON" -m venv "$VENV" || { err "python3 -m venv failed (is python3-venv installed?)"; exit 1; }
"$VENV/bin/pip" install --quiet --upgrade pip pynvim || { err "pip install pynvim failed"; exit 1; }
log "installed pynvim into $VENV"
