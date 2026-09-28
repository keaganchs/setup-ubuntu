#!/usr/bin/env bash
# requires-sudo
# TeX Live, latexmk (VimTeX's compiler) and Zathura (VimTeX's viewer). xdotool
# is how VimTeX finds an already-open Zathura window to forward-search in
# rather than opening a second one; it needs X11, not Wayland.
set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

apt_install \
  latexmk \
  texlive-latex-extra \
  texlive-science \
  texlive-xetex \
  xdotool \
  zathura
