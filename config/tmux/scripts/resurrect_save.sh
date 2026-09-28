#!/usr/bin/env bash
# prefix + C-s, in place of tmux-resurrect's own binding: refuses to save for
# the first GRACE seconds after the tmux server starts.
#
# Every save repoints resurrect's `last` file, which is what a restore (and
# `tmux resume`) loads. A save in a fresh server -- before `tmux resume` has
# finished, or out of habit right after launching -- records one empty session
# and quietly replaces the layout that was worth restoring.
set -uo pipefail

GRACE=10

started="$(tmux display-message -p '#{start_time}')"
age=$(( $(date +%s) - ${started:-0} ))

if [ "$age" -lt "$GRACE" ]; then
  tmux display-message "Not saved: tmux started ${age}s ago (saving opens after ${GRACE}s)"
  exit 0
fi

# The save format has no field for the terminal's size, so record the size of
# the client doing the saving alongside it; resume.sh sizes the window back.
# #{client_*} here is the client whose key press ran this script.
RESURRECT="$HOME/.config/tmux/plugins/tmux-resurrect/scripts"
# shellcheck source=/dev/null
source "$RESURRECT/variables.sh"
# shellcheck source=/dev/null
source "$RESURRECT/helpers.sh"
size="$(tmux display-message -p '#{client_width} #{client_height}')"
# Only overwrite the recorded size with something that is one -- a save run
# with no client attached reports nothing, and an empty file would lose it.
case "$size" in
  [0-9]*' '[0-9]*) printf '%s\n' "$size" > "$(resurrect_dir)/last_size" ;;
esac

exec "$RESURRECT/save.sh"
