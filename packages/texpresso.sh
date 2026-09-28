#!/usr/bin/env bash
# requires-sudo
# TeXpresso, the live LaTeX previewer texpresso.vim drives. There's no release
# binary or apt package, so it's built from source: the build dependencies are
# apt packages, hence requires-sudo.
set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

SRC_DIR="$HOME/.local/src/texpresso"

# texpresso runs texpresso-xetex from its own directory, so both are installed
# side by side, and "installed" means both are there.
if [ -x "$LOCAL_BIN/texpresso" ] && [ -x "$LOCAL_BIN/texpresso-xetex" ]; then
  log "texpresso already installed (delete $LOCAL_BIN/texpresso to rebuild from upstream)"
  exit 0
fi

# From upstream's INSTALL.md and CI. texlive-xetex is what TeXpresso compiles
# with at runtime; libtesseract-dev covers Ubuntu builds of mupdf linked
# against it, which mupdf-config.sh otherwise quietly skips and the link fails.
apt_install \
  build-essential \
  pkg-config \
  libsdl2-dev \
  libmupdf-dev \
  libmujs-dev \
  libfreetype-dev \
  libgumbo-dev \
  libjbig2dec0-dev \
  libjpeg-dev \
  libopenjp2-7-dev \
  libssl-dev \
  libfontconfig-dev \
  libleptonica-dev \
  libtesseract-dev \
  libharfbuzz-dev \
  texlive-xetex || { err "could not install texpresso's build dependencies"; exit 1; }

if [ -d "$SRC_DIR/.git" ]; then
  log "updating $SRC_DIR"
  git -C "$SRC_DIR" pull --ff-only || { err "git pull failed in $SRC_DIR"; exit 1; }
else
  log "cloning texpresso into $SRC_DIR"
  mkdir -p "$(dirname "$SRC_DIR")"
  git clone https://github.com/let-def/texpresso.git "$SRC_DIR" || { err "git clone failed"; exit 1; }
fi

log "building texpresso"
# distclean first: Makefile.config records which libraries were found, and a
# stale one from before the dependencies above were installed breaks the link.
make -C "$SRC_DIR" distclean >/dev/null
make -C "$SRC_DIR" config >/dev/null || { err "texpresso make config failed"; exit 1; }
# Ubuntu 22.04's libmupdf-dev is 1.19, whose per-module headers aren't
# self-contained: TeXpresso includes <mupdf/fitz/display-list.h> on its own and
# the build dies on "unknown type name 'fz_colorspace'". Force-including the
# umbrella header first supplies those types; on newer mupdf it's a no-op.
printf '%s\n' 'CFLAGS += -include mupdf/fitz.h' >> "$SRC_DIR/Makefile.config"
make -C "$SRC_DIR" -j"$(nproc)" all || { err "texpresso build failed"; exit 1; }

mkdir -p "$LOCAL_BIN"
install -m 0755 "$SRC_DIR/build/texpresso" "$SRC_DIR/build/texpresso-xetex" "$LOCAL_BIN/" \
  || { err "could not install texpresso into $LOCAL_BIN"; exit 1; }
log "installed texpresso into $LOCAL_BIN"
