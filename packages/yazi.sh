#!/usr/bin/env bash
# yazi -- terminal file manager, plus `ya`, its CLI. nvim drives it through
# yazi.nvim (config/nvim/lua/user/yazi.lua), which needs both on PATH.
set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

if has yazi && has ya; then
  log "yazi already installed ($(yazi --version 2>/dev/null | head -1))"
  exit 0
fi

case "$(uname -m)" in
  x86_64)  YAZI_ARCH="x86_64" ;;
  aarch64) YAZI_ARCH="aarch64" ;;
  *) err "unsupported architecture: $(uname -m)"; exit 1 ;;
esac

# One archive holds both binaries, so this does its own download rather than
# calling install_release_bin twice and fetching ~10MB twice. Same idea though:
# run what was downloaded before installing it, because upstream's glibc build
# comes from a newer Ubuntu than this one may be (see packages/tree-sitter.sh).
install_yazi() {
  local libc="$1" url tmpdir found rc=1
  url="https://github.com/sxyazi/yazi/releases/latest/download/yazi-${YAZI_ARCH}-unknown-linux-${libc}.zip"
  tmpdir="$(mktemp -d)"

  log "downloading $url"
  if curl -fsSL "$url" -o "$tmpdir/yazi.zip"; then
    mkdir -p "$tmpdir/x"
    if has unzip; then
      unzip -oq "$tmpdir/yazi.zip" -d "$tmpdir/x"
    else
      python3 -m zipfile -e "$tmpdir/yazi.zip" "$tmpdir/x"
    fi

    found="$(find "$tmpdir/x" -type f -name yazi -print -quit)"
    if [ -z "$found" ]; then
      err "yazi not found in $url"
    else
      chmod +x "$found" "$(dirname "$found")/ya"
      local output
      if output="$("$found" --version 2>&1)"; then
        mkdir -p "$LOCAL_BIN"
        install -m 0755 "$found" "$(dirname "$found")/ya" "$LOCAL_BIN/"
        log "installed $output"
        rc=0
      else
        warn "the $libc build does not run on this machine:"
        warn "  $(printf '%s' "$output" | head -1)"
      fi
    fi
  fi

  rm -rf "$tmpdir"
  return "$rc"
}

# gnu first, musl second: the musl build is statically linked, so it runs
# anywhere, which is the whole point of keeping it as the fallback.
if install_yazi gnu || install_yazi musl; then
  hash -r
else
  err "no usable yazi release for this machine."
  err "Build it instead: cargo install --locked yazi-fm yazi-cli --root \"\$HOME/.local\""
  exit 1
fi

# Optional, for yazi's previews: images, video thumbnails, PDFs and archives.
# Best-effort on purpose -- yazi itself is installed by now, and these are the
# only part of this script that needs root, so an unprivileged run keeps what
# it already has rather than failing.
apt_install ffmpegthumbnailer imagemagick p7zip-full poppler-utils \
  || warn "skipped yazi's optional preview tools (ffmpegthumbnailer, imagemagick, p7zip-full, poppler-utils)"
