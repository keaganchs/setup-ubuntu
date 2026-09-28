#!/usr/bin/env bash
# Prints a styled tmux status segment with Claude Code's real current-session
# usage percentage and time until it resets, sourced from `claude -p "/usage"`
# (the same number the /usage slash command shows), not a local estimate.
#
# That call takes ~1s, so results are cached and refreshed in the background
# on a timer -- the tmux status bar always reads the last cached value and
# never blocks on the network.

CACHE_DIR="$HOME/.cache/tmux"
CACHE_FILE="$CACHE_DIR/claude_usage"
LOCK_FILE="$CACHE_DIR/claude_usage.lock"
MAX_AGE=300   # seconds between refreshes
STALE_AGE=1800 # after this, say so rather than showing the old number as current

mkdir -p "$CACHE_DIR"

age=999999
if [ -f "$CACHE_FILE" ]; then
  age=$(( $(date +%s) - $(stat -c %Y "$CACHE_FILE" 2>/dev/null || echo 0) ))
fi

if [ "$age" -ge "$MAX_AGE" ] && command -v claude >/dev/null 2>&1; then
  (
    # flock, not a lock file guarded by a trap: the kernel drops this lock
    # however the process ends, so a refresh killed by a reboot or a killed
    # tmux server can't leave a lock behind. One that did pinned this segment
    # to a ten-day-old 4% -- every later run saw the file and skipped.
    flock -n 9 || exit 0
    tmp="$CACHE_FILE.tmp"
    # timeout so a hung call releases the lock and tries again next tick;
    # -s so a failed call (not logged in, no network) keeps the old cache
    # rather than blanking the segment.
    if timeout 60 claude -p "/usage" >"$tmp" 2>/dev/null && [ -s "$tmp" ]; then
      mv "$tmp" "$CACHE_FILE"
    else
      rm -f "$tmp"
    fi
  ) 9>"$LOCK_FILE" &
  disown
fi

[ -f "$CACHE_FILE" ] || exit 0

line="$(grep -m1 '^Current session:' "$CACHE_FILE")"
[ -n "$line" ] || exit 0

pct="$(echo "$line" | grep -oE '[0-9]+% used' | grep -oE '[0-9]+')"
reset_str="$(echo "$line" | sed -E 's/.*resets ([A-Za-z]+ [0-9]+, [0-9]+:[0-9]+[ap]m).*/\1/' | tr -d ',')"
reset_epoch="$(date -d "$reset_str" +%s 2>/dev/null)"

time_str=""
if [ -n "$reset_epoch" ]; then
  remaining=$(( reset_epoch - $(date +%s) ))
  [ "$remaining" -lt 0 ] && remaining=0
  time_str=" $(( remaining / 3600 ))h$(( (remaining % 3600) / 60 ))m"
fi

# A number no longer being refreshed is worse than no number, so mark it:
# muted text and a "?" instead of the countdown, which is meaningless by then.
fg="#cdd6f4"
if [ "$age" -ge "$STALE_AGE" ]; then
  fg="#6c7086"
  time_str=" ?"
fi

[ -n "$pct" ] && printf '#[fg=#0c1418,bg=#8facda] 󱚝 #[fg=%s,bg=#1f282e] %s%%%s ' "$fg" "$pct" "$time_str"
