#!/usr/bin/env bash
# Git identity and credentials.
#
#   bash install.sh git
#
# Interactive, and a no-op once configured, so a full install.sh run doesn't
# stop to ask. Two ways to authenticate, neither needing a browser and neither
# leaving a token in plaintext:
#
#   ssh    an ed25519 key, encrypted with a passphrase, plus an insteadOf
#          rewrite so existing https remotes go over SSH too. The default: no
#          helper, no keyring, no expiry, and it works the same on a headless
#          server where there's no browser and no secret service to talk to.
#   token  a personal access token kept in `pass` (gpg-encrypted on disk) and
#          handed to git by a credential helper. For hosts where SSH is
#          blocked, or a server that can't hold a passphrase-protected key.
set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

has git || { err "git is not installed (run: bash install.sh base)"; exit 1; }

#
# Identity
#

if [ -z "$(git config --global user.name || true)" ] || [ -z "$(git config --global user.email || true)" ]; then
  [ -t 0 ] || { warn "git identity isn't set; re-run 'bash install.sh git' from a terminal"; exit 0; }
  read -r -p "Name for git [$(git config --global user.name || true)]: " git_name
  [ -n "${git_name:-}" ] && git config --global user.name "$git_name"
  read -r -p "Email for git [$(git config --global user.email || true)]: " git_email
  [ -n "${git_email:-}" ] && git config --global user.email "$git_email"
fi

#
# Credentials
#

# Either an insteadOf rewrite or a per-host helper counts as configured. Both
# are only ever written by this script.
if [ -n "$(git config --global --get-regexp '^(url\..*\.insteadof|credential\..*\.helper)$' 2>/dev/null)" ]; then
  log "git credentials already configured (git config --global --list | grep -E 'insteadof|helper')"
  exit 0
fi

[ -t 0 ] || { warn "git credentials aren't set up; re-run 'bash install.sh git' from a terminal"; exit 0; }

read -r -p "Git host [github.com]: " host
host="${host:-github.com}"

if confirm "Authenticate to $host over SSH? (no = personal access token)"; then
  method=ssh
else
  method=token
fi

# An earlier version of this repo pointed git at git-credential-manager, which
# is what makes a push open a browser. Whichever method is chosen below
# replaces it, so drop it rather than leaving it first in the chain.
if git config --global --get-all credential.helper 2>/dev/null | grep -q .; then
  warn "removing the existing global credential.helper (git-credential-manager and friends)"
  git config --global --unset-all credential.helper
  git config --global --unset-all credential.credentialStore
fi

if [ "$method" = ssh ]; then
  has ssh-keygen || { err "openssh-client is not installed"; exit 1; }

  # github.com -> ~/.ssh/github
  default_key="$HOME/.ssh/$(printf '%s' "$host" | cut -d. -f1)"
  read -r -p "SSH key [$default_key]: " key
  key="${key:-$default_key}"

  if [ -f "$key" ]; then
    log "reusing the existing key $key"
  else
    log "Generating an SSH key. Give it a passphrase: that's what keeps it"
    log "encrypted on disk, and ssh-agent will only ask for it once per login."
    mkdir -p "$(dirname "$key")" && chmod 700 "$(dirname "$key")"
    ssh-keygen -t ed25519 -C "$(git config --global user.email)" -f "$key" \
      || { err "ssh-keygen failed"; exit 1; }
  fi

  # AddKeysToAgent means the passphrase is asked for on first use, not every push.
  if grep -qiE "^Host +$host *\$" "$HOME/.ssh/config" 2>/dev/null; then
    log "~/.ssh/config already has a Host entry for $host"
  else
    log "adding a Host entry for $host to ~/.ssh/config"
    printf '\nHost %s\n  HostName %s\n  User git\n  IdentityFile %s\n  AddKeysToAgent yes\n' \
      "$host" "$host" "$key" >> "$HOME/.ssh/config"
    chmod 600 "$HOME/.ssh/config"
  fi

  # Makes the https remotes in repos cloned before today go over SSH without
  # having to rewrite each one.
  #
  # ponytail: this rewrites *every* https URL for this host, so tools that
  # fetch public dependencies from it (cargo, go, pip) also switch to SSH and
  # need the key loaded in an agent. If that bites a non-interactive build,
  # change insteadOf to pushInsteadOf -- fetches stay on https, pushes don't.
  git config --global "url.git@$host:.insteadOf" "https://$host/"
  log "https://$host/ URLs now go over SSH"

  echo
  log "Add this public key at https://$host/settings/keys :"
  echo
  cat "$key.pub"
  echo
  read -r -p "Press enter once it's added to test the connection... " _
  # Both GitHub and GitLab refuse the shell and exit 1 even when the key is
  # accepted, so the greeting is the signal and the status means nothing. It
  # has to be swallowed rather than just ignored: this is the last command in
  # the branch, so under `set -o pipefail` its 1 would become the script's exit
  # status and install.sh would report a working setup as failed.
  auth="$(ssh -o StrictHostKeyChecking=accept-new -T "git@$host" 2>&1 | head -3)"
  printf '%s\n' "$auth"
  case "$auth" in
    *"successfully authenticated"*|*"Welcome to GitLab"*)
      log "$host accepted the key" ;;
    *)
      warn "could not confirm $host accepted the key"
      warn "  add $key.pub at https://$host/settings/keys, then: ssh -T git@$host" ;;
  esac
else
  for tool in gpg pass; do
    has "$tool" || { err "$tool is not installed (run: bash install.sh base)"; exit 1; }
  done

  if gpg --list-secret-keys --with-colons 2>/dev/null | grep -q '^sec'; then
    log "a GPG secret key already exists, skipping key generation"
  else
    log "Generating a GPG key to encrypt the stored token..."
    gpg --gen-key || { err "gpg key generation failed"; exit 1; }
  fi

  if [ -f "$HOME/.password-store/.gpg-id" ]; then
    log "pass store already initialised for $(cat "$HOME/.password-store/.gpg-id")"
  else
    # pass init takes any unique identifier of the key: name, email, or key id.
    gpg --list-secret-keys --keyid-format=long
    read -r -p "GPG key id (or the email/name it was created with): " pass_id
    pass init "$pass_id" || { err "pass init failed"; exit 1; }
  fi

  read -r -p "Username on $host: " git_user
  [ -n "$git_user" ] || { err "a username is required"; exit 1; }

  if pass show "git/$host" >/dev/null 2>&1; then
    log "a token is already stored at git/$host (pass edit git/$host to change it)"
  else
    log "Paste the personal access token (it needs the 'repo' / 'Contents' scope):"
    pass insert "git/$host" || { err "pass insert failed"; exit 1; }
  fi

  # git invokes a `!`-prefixed helper through sh with the operation as $1.
  # Only `get` is answered: there's nothing to store, and an erase should not
  # silently delete the token.
  git config --global "credential.https://$host.helper" \
    '!f() { test "$1" = get || exit 0; echo "username='"$git_user"'"; echo "password=$(pass show '"git/$host"' | head -1)"; }; f'
  log "pushes to https://$host now read the token from pass"
fi

exit 0
