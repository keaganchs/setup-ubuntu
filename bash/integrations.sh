#!/usr/bin/env bash
# Optional third-party shell hooks. Each one is skipped when the tool isn't
# installed, so this file is safe on a machine where install.sh only got
# partway (e.g. an unprivileged run).

# fzf: Ctrl-R history search, Ctrl-T file search, ** completion.
command -v fzf >/dev/null 2>&1 && eval "$(fzf --bash)"

# Homebrew on Linux, whichever prefix it landed in.
for _brew in /home/linuxbrew/.linuxbrew/bin/brew "$HOME/.linuxbrew/bin/brew"; do
  if [ -x "$_brew" ]; then
    eval "$("$_brew" shellenv)"
    break
  fi
done
unset _brew
