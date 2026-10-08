#!/usr/bin/env bash
# Set up an Ubuntu machine from this dotfiles repo.
#
#   bash ~/.dotfiles/install.sh            # everything
#   bash ~/.dotfiles/install.sh nvim tmux  # only these packages/*.sh scripts
#
# Re-running is safe: every step checks whether its work is already done.
set -uo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "$DOTFILES_DIR/lib/common.sh"

#
# Privileges
#

if [ -n "${NO_SUDO:-}" ]; then
  # Explicit opt-in, e.g. NO_SUDO=1 bash install.sh on a machine where you'll
  # never have root.
  warn "NO_SUDO is set: running only the steps that work without root."
  SUDO=""
elif [ "$(id -u)" -eq 0 ]; then
  SUDO=""
  NO_SUDO=""
elif has sudo && sudo -n true 2>/dev/null; then
  SUDO="sudo"
  NO_SUDO=""
elif has sudo && [ -t 0 ] && id -nG | grep -qwE 'sudo|admin|wheel'; then
  # In the sudo group but the timestamp has expired: ask for the password once
  # here rather than partway through an install. The group check keeps users
  # who have no sudo rights at all from burning three failed password attempts.
  log "Some steps need root."
  if sudo -v; then
    SUDO="sudo"
    NO_SUDO=""
  else
    err "Could not authenticate with sudo."
    exit 1
  fi
else
  warn "No root privileges: apt packages and system tweaks can't be installed."
  warn "Shell config, nvim, tmux config, fzf/fd/rg/gh, node, uv and conda still work."
  if confirm "Continue without root and install only those?"; then
    SUDO=""
    NO_SUDO=1
  else
    err "Aborted. Re-run with sudo access to install everything."
    err "(Non-interactive? Use 'NO_SUDO=1 bash install.sh' to skip this prompt.)"
    exit 1
  fi
fi
export SUDO NO_SUDO

# Keep the sudo timestamp warm so long builds don't stall on a password prompt.
if [ -n "$SUDO" ]; then
  while true; do sudo -n true 2>/dev/null; sleep 50; done &
  SUDO_KEEPALIVE_PID=$!
  trap 'kill "$SUDO_KEEPALIVE_PID" 2>/dev/null' EXIT
fi

#
# Shell config
#

# Each of these three points ~/.<file> at this checkout, and drops the same
# directive left behind by a checkout that has since moved or been deleted --
# those are dead `source`/`$include` lines that make every new shell start with
# a "No such file or directory".

log "Wiring up bash"
touch "$HOME/.bashrc"
append_once_owned "$HOME/.bashrc" "source \"$DOTFILES_DIR/bash/bashrc.sh\"" \
  '^source ".*/bash/bashrc\.sh"$'

log "Wiring up readline"
# ~/.inputrc replaces /etc/inputrc rather than extending it, so pull the system
# defaults back in before adding ours.
append_once "$HOME/.inputrc" '$include /etc/inputrc'
append_once_owned "$HOME/.inputrc" "\$include $DOTFILES_DIR/bash/inputrc" \
  '^\$include .*/bash/inputrc$'

log "Wiring up git"
# git keeps include.path as a multi-valued key rather than a file of lines, so
# the stale-entry cleanup is the same idea spelled in git's own commands.
while IFS= read -r path; do
  [ -n "$path" ] || continue
  [ "$path" = "$DOTFILES_DIR/git/gitconfig" ] && continue
  case "$path" in
    */git/gitconfig)
      warn "git included another checkout: $path"
      warn "  replaced with $DOTFILES_DIR/git/gitconfig"
      # --unset-all matches on a regex, so the old path has to be escaped.
      git config --global --unset-all include.path "^$(printf '%s' "$path" | sed 's/[][\.*^$]/\\&/g')$"
      ;;
  esac
done < <(git config --global --get-all include.path)

git config --global --get-all include.path | grep -qxF "$DOTFILES_DIR/git/gitconfig" \
  || git config --global --add include.path "$DOTFILES_DIR/git/gitconfig"

#
# Tool configs (these tools require their config to live in ~/.config)
#

log "Installing tool configs"
copy_config "$DOTFILES_DIR/config/nvim" "$HOME/.config/nvim"
copy_config "$DOTFILES_DIR/config/tmux" "$HOME/.config/tmux"

# tpm ships as a submodule; a plain `git clone` of this repo leaves it empty.
if [ ! -f "$DOTFILES_DIR/config/tmux/plugins/tpm/tpm" ]; then
  log "Fetching submodules (tpm)"
  git -C "$DOTFILES_DIR" submodule update --init --recursive
fi

#
# Packages
#

log "Installing packages"
FAILED=()
SKIPPED=()

if [ "$#" -gt 0 ]; then
  scripts=()
  for name in "$@"; do
    scripts+=("$DOTFILES_DIR/packages/${name%.sh}.sh")
  done
else
  # base.sh first: the rest assume curl, git and a compiler are present.
  # git.sh last: it's the only one that asks questions, so it waits until the
  # unattended part of the run is over (see the block after this loop).
  scripts=("$DOTFILES_DIR/packages/base.sh")
  for script in "$DOTFILES_DIR"/packages/*.sh; do
    case "$script" in
      "$DOTFILES_DIR"/packages/base.sh|"$DOTFILES_DIR"/packages/git.sh) ;;
      *) scripts+=("$script") ;;
    esac
  done
fi

for script in "${scripts[@]}"; do
  name="$(basename "$script" .sh)"

  if [ ! -f "$script" ]; then
    err "No such package script: $name"
    FAILED+=("$name")
    continue
  fi

  # Scripts that can't do anything useful unprivileged say so in their header.
  if [ -n "$NO_SUDO" ] && grep -qx '# requires-sudo' "$script"; then
    warn "Skipping $name (needs root)"
    SKIPPED+=("$name")
    continue
  fi

  log "Running $name"
  if ! bash "$script"; then
    err "$name failed"
    FAILED+=("$name")
  fi
done

#
# Interactive one-time setup
#

# A no-op once git has an identity and a way to authenticate, so this only
# asks on a first run. On its own:  bash install.sh git
if [ "$#" -eq 0 ]; then
  log "Running git"
  bash "$DOTFILES_DIR/packages/git.sh" || FAILED+=("git")
fi

#
# Summary
#

echo
[ ${#SKIPPED[@]} -gt 0 ] && warn "Skipped (needed root): ${SKIPPED[*]}"
if [ ${#FAILED[@]} -gt 0 ]; then
  err "Failed: ${FAILED[*]}"
  err "Everything else finished. Re-run 'bash install.sh ${FAILED[*]}' to retry just those."
  exit 1
fi

log "Done. Start a new shell (or 'source ~/.bashrc') to pick up the config."
