#!/usr/bin/env bash
# One-time interactive setup: git identity, plus a GPG key and pass store so
# git-credential-manager can encrypt the GitHub token at rest.
#
# install.sh offers to run this only when git has no global user.email; run it
# by hand any time with:  bash scripts/git-credentials.sh
set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

[ -t 0 ] || { err "this script needs an interactive terminal"; exit 1; }

for tool in git gpg pass; do
  has "$tool" || { err "$tool is not installed (run: bash install.sh base)"; exit 1; }
done

#
# Identity
#

current_name="$(git config --global user.name || true)"
current_email="$(git config --global user.email || true)"

read -r -p "Name for git [${current_name}]: " git_name
[ -n "${git_name:-}" ] && git config --global user.name "$git_name"

read -r -p "Email for git [${current_email}]: " git_email
[ -n "${git_email:-}" ] && git config --global user.email "$git_email"

#
# GPG key
#

if gpg --list-secret-keys --with-colons 2>/dev/null | grep -q '^sec'; then
  log "a GPG secret key already exists, skipping key generation"
else
  log "Generating a GPG key to encrypt stored git credentials..."
  gpg --gen-key || { err "gpg key generation failed"; exit 1; }
fi

#
# pass store
#

if [ -f "$HOME/.password-store/.gpg-id" ]; then
  log "pass store already initialised for $(cat "$HOME/.password-store/.gpg-id")"
else
  # pass init takes any unique identifier of the key: name, email, or key id.
  gpg --list-secret-keys --keyid-format=long
  read -r -p "GPG key id (or the email/name it was created with): " pass_id
  pass init "$pass_id" || { err "pass init failed"; exit 1; }
fi

#
# Token
#

if pass ls git >/dev/null 2>&1; then
  log "a token is already stored under 'git' (pass edit git to change it)"
else
  echo "Enter the git token to use on this device:"
  pass insert git
fi

log "git credential storage configured (credential.credentialStore = gpg)"
