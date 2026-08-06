#!/usr/bin/env bash
# Entry point for the tracked shell config. ~/.bashrc stays a real, untracked
# file and just sources this one, so anything installers append to ~/.bashrc
# (conda init, brew shellenv, ...) stays local to the machine.

_dotfiles_bash_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

for _f in "$_dotfiles_bash_dir"/exports.sh \
          "$_dotfiles_bash_dir"/aliases.sh \
          "$_dotfiles_bash_dir"/functions.sh \
          "$_dotfiles_bash_dir"/integrations.sh \
          "$_dotfiles_bash_dir"/prompt.sh; do
  [ -r "$_f" ] && . "$_f"
done
unset _f _dotfiles_bash_dir
