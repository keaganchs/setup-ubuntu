#!/usr/bin/env bash
# Anki, from the official tarball.
#
# There's no apt package; upstream ships a .tar.zst whose bundled install.sh
# honours $PREFIX, so this works system-wide as root and under ~/.local without.
# See https://docs.ankiweb.net/platform/linux/installing.html
set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

if [ -n "${NO_SUDO:-}" ]; then
  PREFIX="$HOME/.local"
else
  PREFIX="/usr/local"
fi
MARKER="$PREFIX/share/anki/.installed-version"

case "$(uname -m)" in
  x86_64)  ANKI_ARCH="x86_64" ;;
  aarch64) ANKI_ARCH="aarch64" ;;
  *) err "unsupported architecture: $(uname -m)"; exit 1 ;;
esac

version="$(github_latest_tag ankitects/anki)" || exit 1

if [ "$(cat "$MARKER" 2>/dev/null)" = "$version" ]; then
  log "anki $version already installed"
  exit 0
fi

# GNU tar shells out to the zstd binary for .zst, so it has to be present.
if ! has zstd; then
  if [ -n "${NO_SUDO:-}" ]; then
    err "zstd is required to unpack the Anki tarball, and installing it needs root"
    exit 1
  fi
  apt_install zstd || exit 1
fi

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

log "downloading anki $version (~185MB)"
curl -fL --progress-bar \
  "https://github.com/ankitects/anki/releases/download/${version}/anki-${version}-linux-${ANKI_ARCH}.tar.zst" \
  -o "$tmp/anki.tar.zst" || exit 1

log "unpacking anki"
tar -xf "$tmp/anki.tar.zst" -C "$tmp" || exit 1

src="$(find "$tmp" -maxdepth 1 -type d -name 'anki-*' | head -1)"
[ -d "$src" ] || { err "unexpected tarball layout"; exit 1; }

# The bundle's install.sh insists on being run from its own directory, and
# installs Qt/X11 runtime deps via apt when it has the privileges to.
log "installing anki into $PREFIX"
if [ -n "${NO_SUDO:-}" ]; then
  warn "no root: skipping Anki's Qt/X11 dependency install -- if it won't start,"
  warn "have an admin install libxcb-cursor0 libxcb-icccm4 libxcb-keysyms1 libnss3"
  (cd "$src" && PREFIX="$PREFIX" ./install.sh) || exit 1
else
  (cd "$src" && sudo_cmd env PREFIX="$PREFIX" ./install.sh) || exit 1
fi

# install.sh doesn't record what it installed, so track it ourselves to make
# re-runs cheap (the download is 185MB).
if [ -n "${NO_SUDO:-}" ]; then
  printf '%s\n' "$version" > "$MARKER"
else
  printf '%s\n' "$version" | sudo_cmd tee "$MARKER" >/dev/null
fi

log "installed anki $version (run 'anki')"
