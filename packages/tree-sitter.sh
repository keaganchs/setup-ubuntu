#!/usr/bin/env bash
# tree-sitter CLI -- nvim-treesitter shells out to it to build every parser.
set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

# nvim-treesitter's main branch refuses to build parsers with anything older
# (see TREE_SITTER_MIN_VER in its lua/nvim-treesitter/health.lua). apt's
# tree-sitter lags several major releases behind that, hence the release binary.
TS_MIN_VER="0.26.1"
# rust-version in tree-sitter's Cargo.toml, needed only for the source build.
RUST_MIN_VER="1.84.0"

# `has tree-sitter` is not enough to call this done: upstream's linux-x64 build
# is linked against glibc 2.39 (Ubuntu 24.04), so on 22.04 the binary installs
# fine and then dies at the dynamic linker before printing anything. Asking it
# for its version tests both that it runs and that it's new enough.
version_ge() { [ "$(printf '%s\n%s\n' "$1" "$2" | sort -V | head -1)" = "$2" ]; }

ts_version() { tree-sitter --version 2>/dev/null | awk '{print $2}'; }

ts_ok() {
  local version
  version="$(ts_version)"
  [ -n "$version" ] && version_ge "$version" "$TS_MIN_VER"
}

# `has` and the functions above go through bash's command hash, which still
# points at a binary we just replaced.
recheck() { hash -r; ts_ok; }

if ts_ok; then
  log "tree-sitter $(ts_version) already installed"
  exit 0
fi

case "$(uname -m)" in
  x86_64)  TS_ARCH="x64" ;;
  aarch64) TS_ARCH="arm64" ;;
  *) err "unsupported architecture: $(uname -m)"; exit 1 ;;
esac

if install_release_bin \
  "https://github.com/tree-sitter/tree-sitter/releases/latest/download/tree-sitter-cli-linux-${TS_ARCH}.zip" \
  tree-sitter --version && recheck
then
  log "installed tree-sitter $(ts_version)"
  exit 0
fi

#
# Fallback: build it. Reached on any distro whose glibc is older than the one
# upstream builds against -- Ubuntu 22.04 has 2.35 against their 2.39 -- where
# no prebuilt tree-sitter new enough for nvim-treesitter exists. (Homebrew's
# and npm's are no help: the formula is a release behind, and npm just unpacks
# the same prebuilt binary.)
#

warn "no usable prebuilt tree-sitter; building it from source instead"

if ! has cargo; then
  log "installing rust via rustup (needed to build tree-sitter)"
  # PATH already covers ~/.cargo/bin, from bash/exports.sh and lib/common.sh.
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs \
    | sh -s -- -y --no-modify-path --profile minimal || { err "rustup install failed"; exit 1; }
  hash -r
fi

has cargo || { err "cargo is not on PATH after installing rust"; exit 1; }

rust_version="$(rustc --version 2>/dev/null | awk '{print $2}')"
if ! version_ge "${rust_version:-0}" "$RUST_MIN_VER"; then
  if has rustup; then
    log "rust ${rust_version:-?} is older than $RUST_MIN_VER, updating the stable toolchain"
    rustup update stable || { err "rustup update failed"; exit 1; }
  else
    err "rust ${rust_version:-?} is too old to build tree-sitter (needs $RUST_MIN_VER+)"
    err "and rustup isn't installed to update it."
    exit 1
  fi
fi

# --force because cargo refuses to overwrite an existing binary, which is
# exactly what we're here to do when the prebuilt one landed and didn't run.
log "building tree-sitter-cli from source (several minutes)"
cargo install --locked --force tree-sitter-cli --root "$HOME/.local" || {
  err "cargo install tree-sitter-cli failed"
  exit 1
}

recheck || { err "built tree-sitter is missing or older than $TS_MIN_VER"; exit 1; }
log "installed tree-sitter $(ts_version)"
