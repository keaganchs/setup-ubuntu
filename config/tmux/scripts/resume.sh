#!/usr/bin/env bash
# `tmux resume` / `tmux r` (the tmux() wrapper in bash/functions.sh): start a
# tmux server, bring back the last tmux-resurrect save, size the terminal back
# to what it was, and attach to the session that was active when it was saved.
set -uo pipefail

RESURRECT="$HOME/.config/tmux/plugins/tmux-resurrect/scripts"

# A running server already has its sessions. Restoring into it would only add
# duplicates of whatever the save shares with it, so just go to them.
if tmux has-session 2>/dev/null; then
  if [ -n "${TMUX:-}" ]; then
    echo "tmux is already running (you're in it); nothing to restore." >&2
    exit 0
  fi
  echo "tmux is already running; attaching instead of restoring." >&2
  exec tmux attach-session
fi

if [ ! -x "$RESURRECT/restore.sh" ]; then
  echo "tmux-resurrect isn't installed (run install.sh tmux); starting a plain session." >&2
  exec tmux new-session
fi

# Start the server before anything else so resurrect's helpers can read its
# options -- that's how @resurrect-dir is honoured -- and so the sessions below
# are created with the config already loaded.
tmux start-server
# shellcheck source=/dev/null
source "$RESURRECT/variables.sh"
# shellcheck source=/dev/null
source "$RESURRECT/helpers.sh"
save_dir="$(resurrect_dir)"

# The terminal's size at the time of the save, from resurrect_save.sh. It has
# to be applied before the sessions are restored: tmux builds detached sessions
# at `default-size` and then rescales their layouts to fit the client that
# attaches, and rescaling twice moves pane borders by a cell or two.
cols="" rows=""
if [ -r "$save_dir/last_size" ]; then
  read -r cols rows < "$save_dir/last_size"
  # Only sizes that look like sizes: this ends up in an escape sequence.
  case "${cols}x${rows}" in
    *[!0-9x]* | x*| *x) cols="" rows="" ;;
  esac
fi

if [ -n "$cols" ]; then
  if [ -t 1 ]; then
    # CSI 8 ; rows ; cols t -- the xterm "resize the window" sequence, which
    # gnome-terminal honours. A terminal that doesn't support it ignores it,
    # and tmux then just fits the layouts to the window's real size.
    printf '\033[8;%d;%dt' "$rows" "$cols"
    sleep 0.3 # let the resize land before tmux reads the terminal size
  fi
  # Sessions that restore.sh creates have no client attached either, so they
  # take their size from this rather than from tmux's 80x24 default.
  tmux set-option -g default-size "${cols}x${rows}"
fi

# The session is named 0 on purpose: a server whose only pane is session 0 is
# what resurrect treats as "restoring from scratch", and once it has restored
# the saved sessions it kills that placeholder.
tmux new-session -d -s 0
tmux run-shell "$RESURRECT/restore.sh"

# The save's `state` line records the session the client was on. Resurrect
# would switch to it itself, but there's no client attached yet to switch.
save_file="$(last_resurrect_file)"
target=""
if [ -r "$save_file" ]; then
  target="$(awk -F'\t' '$1 == "state" { print $2; exit }' "$save_file")"
else
  echo "No tmux-resurrect save found; starting a fresh session." >&2
fi

if [ -n "$target" ] && tmux has-session -t "=$target" 2>/dev/null; then
  exec tmux attach-session -t "=$target"
fi
exec tmux attach-session
