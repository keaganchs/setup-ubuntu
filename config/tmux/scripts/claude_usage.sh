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
MAX_AGE=300 # seconds between refreshes

mkdir -p "$CACHE_DIR"

age=999999
if [ -f "$CACHE_FILE" ]; then
  age=$(( $(date +%s) - $(stat -c %Y "$CACHE_FILE" 2>/dev/null || echo 0) ))
fi

if [ "$age" -ge "$MAX_AGE" ] && [ ! -e "$LOCK_FILE" ]; then
  (
    trap 'rm -f "$LOCK_FILE"' EXIT
    : > "$LOCK_FILE"
    claude -p "/usage" >"$CACHE_FILE.tmp" 2>/dev/null && mv "$CACHE_FILE.tmp" "$CACHE_FILE"
  ) &
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

[ -n "$pct" ] && printf '#[fg=#0c1418,bg=#daab8e] 󱚝 #[fg=#cdd6f4,bg=#1f282e] %s%%%s ' "$pct" "$time_str"
