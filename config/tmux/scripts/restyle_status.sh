#!/usr/bin/env bash
# Post-process the catppuccin theme's status line, after tpm has built it.
#
# Three jobs:
#
#   1. Recolour catppuccin mocha's base and surface to match the terminal
#      background, and collapse its per-segment pastels onto the bar's two
#      accents. The theme reads its palette from a .tmuxtheme file inside the
#      plugin directory -- which tpm owns and overwrites on update -- and its
#      @catppuccin_flavour option is interpolated into a path in that same
#      directory, so there's nowhere to point it at our own file. Substituting
#      on the built options is the one approach that survives a plugin update.
#
#   2. Highlight a window with unread output in the "updated" accent, which
#      needs a conditional the theme's flat format string doesn't have.
#
#   3. Give only the leftmost right-aligned segment the rounded cap. tmux.conf
#      sets @catppuccin_right_separator to the square cap for all of them.
#
# All three passes are no-ops once applied, so re-sourcing tmux.conf is safe.
set -uo pipefail

# The bar speaks in two colours, not one per segment: BLUE is every segment at
# rest, ORANGE means active or updated -- the current window, a window with
# unread output, and the session block while the prefix is held. Keep these in
# sync with git_branch.sh and claude_usage.sh, whose output is generated at
# render time and so never passes through the substitution below.
BLUE='#8facda'
ORANGE='#daab8e'

# Keep BACKGROUND in sync with packages/gnome-terminal.sh. SURFACE is that
# colour plus the same lightness step mocha uses from base to surface0
# (+19,+20,+22), which keeps segment fills readable -- #cdd6f4 on it is 10.4:1.
declare -A RECOLOUR=(
  ['#1e1e2e']='#0c1418'   # base:     bar background, and the glyph fg on accent blocks
  ['#313244']='#1f282e'   # surface0: the fill behind segment text
  ['colour232']='#0c1418' # the window-tab formats use 256-palette equivalents
  ['colour237']='#1f282e'
  ['#585b70']='#46515a'   # black4:   copy-mode selection fill, same step off the new base

  # Accents. Catppuccin gives every segment its own pastel; the bar wants only
  # the two above, so five of the six collapse onto BLUE or ORANGE by the state
  # they mark rather than the segment they belong to. Both are catppuccin's own
  # pastel muted for the darker base (HSL saturation x0.55, lightness -5pp) --
  # at full strength they read as neon on #0c1418, and the dark glyph sits on
  # top of them, so they can't go much further down either: blue is 8.04:1
  # against that glyph and orange 9.03:1.
  ['#89b4fa']="$BLUE"     # blue:  window tab, git branch, active pane border
  ['#f5c2e7']="$BLUE"     # pink:  window-name segment, copy-mode indicator
  ['#a6e3a1']="$BLUE"     # green: session segment
  ['#89dceb']="$BLUE"     # cyan:  message line
  ['#fab387']="$ORANGE"   # peach: current window tab
  ['#f38ba8']="$ORANGE"   # red:   session segment while the prefix is held
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

# Windows with unread output. tmux has window-status-activity-style for this,
# but the theme's window-status-format sets the segment's colours inline and an
# inline #[bg=...] beats the style -- so the conditional has to go in the format
# itself. monitor-activity, set in tmux.conf, is what raises the flag.
window_format="$(tmux show-option -gwv window-status-format 2>/dev/null)"
# The replacement is held in a variable because it contains a closing brace,
# which would otherwise end the ${var/pat/rep} expansion early.
activity_bg="bg=#{?window_activity_flag,$ORANGE,$BLUE}"
case "$window_format" in
  # Already conditional: the theme hasn't rebuilt the format since the last run.
  *window_activity_flag*) ;;
  *"bg=$BLUE"*) tmux set-option -gwq window-status-format "${window_format/bg=$BLUE/$activity_bg}" ;;
esac

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
