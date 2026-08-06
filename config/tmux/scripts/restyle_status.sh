#!/usr/bin/env bash
# Post-process the catppuccin theme's status line, after tpm has built it.
#
# Two jobs:
#
#   1. Recolour catppuccin mocha's base and surface to match the terminal
#      background. The theme reads its palette from a .tmuxtheme file inside the
#      plugin directory -- which tpm owns and overwrites on update -- and its
#      @catppuccin_flavour option is interpolated into a path in that same
#      directory, so there's nowhere to point it at our own file. Substituting
#      on the built options is the one approach that survives a plugin update.
#
#   2. Give only the leftmost right-aligned segment the rounded cap. tmux.conf
#      sets @catppuccin_right_separator to the square cap for all of them.
#
# Both passes are no-ops once applied, so re-sourcing tmux.conf is safe.
set -uo pipefail

# Keep BACKGROUND in sync with packages/gnome-terminal.sh. SURFACE is that
# colour plus the same lightness step mocha uses from base to surface0
# (+19,+20,+22), which keeps segment fills readable -- #cdd6f4 on it is 10.4:1.
declare -A RECOLOUR=(
  ['#1e1e2e']='#0c1418'   # base:     bar background, and the glyph fg on accent blocks
  ['#313244']='#1f282e'   # surface0: the fill behind segment text
  ['colour232']='#0c1418' # the window-tab formats use 256-palette equivalents
  ['colour237']='#1f282e'
  ['#585b70']='#46515a'   # black4:   copy-mode selection fill, same step off the new base

  # Accents, muted against the darker base: HSL saturation x0.55, lightness
  # -5pp. Catppuccin's pastels are tuned for #1e1e2e and read as neon on
  # #0c1418. The dark glyph sits on top of these, so they can't go much further
  # down -- the red below is the worst case at 7.39:1 and the rest clear 8:1.
  ['#f5c2e7']='#e2bcd7'   # pink:  window segment
  ['#a6e3a1']='#a3cb9f'   # green: session segment
  ['#f38ba8']='#d590a3'   # red:   prefix-active indicator
  ['#89b4fa']='#8facda'   # blue:  window tab, git branch, active pane border
  ['#fab387']='#daab8e'   # peach: current window tab, Claude usage
  ['#89dceb']='#8dc3cd'   # cyan:  message line
)

GLOBAL_OPTIONS=(
  status-bg status-style status-left status-right
  message-style message-command-style
  pane-border-style pane-active-border-style
  mode-style
)

WINDOW_OPTIONS=(
  window-status-style window-status-current-style window-status-activity-style
  window-status-format window-status-current-format clock-mode-colour
)

recolour() {
  local value="$1" from
  for from in "${!RECOLOUR[@]}"; do
    value="${value//$from/${RECOLOUR[$from]}}"
  done
  printf '%s' "$value"
}

for option in "${GLOBAL_OPTIONS[@]}"; do
  current="$(tmux show-option -gv "$option" 2>/dev/null)" || continue
  [ -n "$current" ] || continue
  updated="$(recolour "$current")"
  [ "$updated" = "$current" ] || tmux set-option -gq "$option" "$updated"
done

for option in "${WINDOW_OPTIONS[@]}"; do
  current="$(tmux show-option -gwv "$option" 2>/dev/null)" || continue
  [ -n "$current" ] || continue
  updated="$(recolour "$current")"
  [ "$updated" = "$current" ] || tmux set-option -gwq "$option" "$updated"
done

ROUND=$''  # powerline left half circle
SQUARE=$'█' # full block

status_right="$(tmux show-option -gv status-right 2>/dev/null)"
case "$status_right" in
  # Already rounded: the theme hasn't rebuilt the line since the last pass, so
  # replacing again would eat the next segment's square cap instead.
  *"$ROUND"*) ;;
  # ${var/pat/rep} replaces the first match only -- exactly the leftmost segment.
  *"$SQUARE"*) tmux set-option -gq status-right "${status_right/$SQUARE/$ROUND}" ;;
esac
