#!/usr/bin/env bash
# GNOME Terminal profile: font and colours.
#
# These live in dconf rather than a config file, so they're applied with
# gsettings instead of symlinked. The dotfiles own these values, so a re-run
# resets a profile that has drifted. No-ops on a machine without GNOME.
set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

FONT="FiraCode Nerd Font Mono"
BACKGROUND='#0c1418'
FOREGROUND='#d0cfcc'

# Ubuntu's stock palette, with one change: the blue at index 4 lightened from
# #12488b to #1e6fd9 (+17.6pp HSL lightness), which takes it from 2.06:1 to
# 3.84:1 against the background. bold-is-bright is off, so bash's \033[1;34m --
# the prompt's cwd, and ls's directories -- renders from index 4. Index 12, the
# bright blue, is left at its stock #2a7bde.
PALETTE=(
  '#171421' '#c01c28' '#26a269' '#a2734c'
  '#1e6fd9' '#a347ba' '#2aa1b3' '#d0cfcc'
  '#5e5c64' '#f66151' '#33da7a' '#e9ad0c'
  '#2a7bde' '#c061cb' '#33c7de' '#ffffff'
)

has gsettings || { log "gsettings not available, skipping GNOME Terminal setup"; exit 0; }
gsettings list-schemas 2>/dev/null | grep -qx 'org.gnome.Terminal.ProfilesList' || {
  log "GNOME Terminal not installed, skipping"
  exit 0
}

profile="$(gsettings get org.gnome.Terminal.ProfilesList default 2>/dev/null | tr -d "'")"
[ -n "$profile" ] || { warn "no default GNOME Terminal profile found"; exit 0; }
SCHEMA="org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$profile/"

get() { gsettings get "$SCHEMA" "$1" 2>/dev/null | tr -d "'"; }

# Set a key only when it differs, so a re-run stays quiet.
set_key() {
  local key="$1" value="$2"
  [ "$(gsettings get "$SCHEMA" "$key" 2>/dev/null)" = "$value" ] && return 0
  log "$key -> $value"
  gsettings set "$SCHEMA" "$key" "$value" || warn "could not set $key"
}

# GNOME Terminal writes colours back as either '#rrggbb' or 'rgb(r,g,b)'
# depending on what set them, so compare on the parsed value rather than text.
norm_colour() {
  local c="${1,,}" r g b
  case "$c" in
    'rgb('*) IFS='(),' read -r _ r g b _ <<<"$c"; printf '#%02x%02x%02x' "$r" "$g" "$b" ;;
    *) printf '%s' "$c" ;;
  esac
}

set_colour() {
  local key="$1" value="$2"
  [ "$(norm_colour "$(get "$key")")" = "$(norm_colour "$value")" ] && return 0
  log "$key -> $value"
  gsettings set "$SCHEMA" "$key" "$value" || warn "could not set $key"
}

#
# Font
#

current_font="$(get font)"
if [ "$(get use-system-font)" = "false" ] && [ "${current_font% *}" = "$FONT" ]; then
  log "font already '$current_font'"
else
  # Keep whatever point size the profile already had.
  size="$(printf '%s' "$current_font" | grep -oE '[0-9]+$')"
  : "${size:=12}"
  set_key use-system-font false
  set_key font "'$FONT $size'"
fi

#
# Colours
#

set_key use-theme-colors false
set_colour background-color "$BACKGROUND"
set_colour foreground-color "$FOREGROUND"

# Bold text keeps the normal palette entry rather than jumping to the bright
# one -- otherwise \033[1;34m would render from index 12, not the index 4 we
# tuned above.
set_key bold-is-bright false

palette_literal="[$(printf "'%s', " "${PALETTE[@]}")"
palette_literal="${palette_literal%, }]"
set_key palette "$palette_literal"
