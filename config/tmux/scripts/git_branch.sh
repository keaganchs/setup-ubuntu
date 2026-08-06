#!/usr/bin/env bash
# Prints a styled tmux status segment with the current git branch for the
# given directory, or nothing if not inside a repo.
dir="${1:-$PWD}"
branch="$(git -C "$dir" branch --show-current 2>/dev/null)"
[ -n "$branch" ] && printf '#[fg=#0c1418,bg=#8facda] \xee\x9c\xa5 #[fg=#cdd6f4,bg=#1f282e] %s ' "$branch"
