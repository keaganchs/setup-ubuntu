#!/usr/bin/env bash
# FiraCode Nerd Font -- the tmux status bar and nvim use nerd-font glyphs, which
# render as tofu without them.
#
# This is ryanoasis' patched build of tonsky/FiraCode rather than upstream
# FiraCode: same typeface, plus the private-use-area icons the status bar needs
# (U+E725 for the git branch, U+F169D for the Claude usage segment). Upstream
# FiraCode has none of those.
set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

FONT_FAMILY="FiraCode"
FONT_DIR="$HOME/.local/share/fonts/$FONT_FAMILY"

# Glyphs the tmux status bar emits; the install is only useful if they're there.
REQUIRED_GLYPHS=(e725 f169d)

#
# The font itself
#

if compgen -G "$FONT_DIR/*.ttf" >/dev/null; then
  log "$FONT_FAMILY Nerd Font already installed"
else
  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' EXIT

  log "downloading $FONT_FAMILY Nerd Font"
  curl -fsSL "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/${FONT_FAMILY}.zip" -o "$tmp/font.zip" || exit 1

  mkdir -p "$FONT_DIR"
  if has unzip; then
    unzip -oq "$tmp/font.zip" -d "$FONT_DIR" '*.ttf'
  else
    python3 -m zipfile -e "$tmp/font.zip" "$FONT_DIR"
  fi

  has fc-cache && fc-cache -f "$FONT_DIR" >/dev/null
  log "installed fonts into $FONT_DIR"

  # Already-running apps read the fontconfig cache at startup, so they won't see
  # what we just installed.
  pgrep -x gnome-terminal- >/dev/null 2>&1 &&
    warn "Restart your terminal (all windows) for the new fonts to be picked up."
fi

#
# Check the glyphs actually made it in
#

if has fc-list; then
  for glyph in "${REQUIRED_GLYPHS[@]}"; do
    if ! fc-list ":charset=$glyph" family 2>/dev/null | grep -q "$FONT_FAMILY Nerd Font"; then
      warn "$FONT_FAMILY Nerd Font has no glyph at U+${glyph^^} -- the tmux status bar will show tofu there."
    fi
  done
fi

# Pointing GNOME Terminal at this font is packages/gnome-terminal.sh's job --
# it owns the profile's font and colours together.
