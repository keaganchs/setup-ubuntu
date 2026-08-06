#!/usr/bin/env bash
# Helpers shared by install.sh and every packages/*.sh script.
# Everything here is written to be safe to run repeatedly.

DOTFILES_DIR="${DOTFILES_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
export DOTFILES_DIR

# install.sh exports these; default sensibly when a package script is run alone.
if [ -z "${SUDO+x}" ] && [ -z "${NO_SUDO:-}" ]; then
  if [ "$(id -u)" -eq 0 ]; then SUDO=""; else SUDO="sudo"; fi
fi

LOCAL_BIN="$HOME/.local/bin"

# Make tools installed earlier in this same run visible to `has`, so re-running
# install.sh doesn't reinstall them just because ~/.bashrc hasn't been sourced.
for _dir in "$LOCAL_BIN" "$HOME/.local/share/nvim/bin" "$HOME/.cargo/bin"; do
  case ":$PATH:" in
    *":$_dir:"*) ;;
    *) PATH="$_dir:$PATH" ;;
  esac
done
unset _dir
export PATH

log()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m==> %s\033[0m\n' "$*" >&2; }
err()  { printf '\033[1;31m==> %s\033[0m\n' "$*" >&2; }

has() { command -v "$1" >/dev/null 2>&1; }

# SUDO is set by install.sh: "" when already root, "sudo" when we can escalate,
# and unset together with NO_SUDO=1 when we can't.
sudo_cmd() {
  if [ -n "${NO_SUDO:-}" ]; then
    warn "skipping (needs root): $*"
    return 1
  fi
  ${SUDO:-} "$@"
}

# Append a line to a file only if it isn't already there.
append_once() {
  local file="$1" line="$2"
  touch "$file"
  grep -qxF -- "$line" "$file" || printf '%s\n' "$line" >> "$file"
}

# Symlink src -> dst, moving anything already at dst out of the way.
link() {
  local src="$1" dst="$2"
  if [ -L "$dst" ] && [ "$(readlink -f "$dst")" = "$(readlink -f "$src")" ]; then
    return 0
  fi
  if [ -e "$dst" ] || [ -L "$dst" ]; then
    local backup="$dst.backup.$(date +%Y%m%d%H%M%S)"
    warn "$dst already exists, moving it to $backup"
    mv "$dst" "$backup"
  fi
  mkdir -p "$(dirname "$dst")"
  ln -sfn "$src" "$dst"
  log "linked $dst -> $src"
}

# apt-get, but a no-op for anything already installed and quiet about it.
apt_install() {
  local missing=()
  local pkg
  for pkg in "$@"; do
    dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null | grep -q 'ok installed' || missing+=("$pkg")
  done
  if [ ${#missing[@]} -eq 0 ]; then
    log "already installed: $*"
    return 0
  fi
  apt_update
  log "apt install: ${missing[*]}"
  sudo_cmd env DEBIAN_FRONTEND=noninteractive apt-get install -y "${missing[@]}"
}

# Refresh the package lists at most once per run, and only if they're stale.
# Pass "force" after adding a new repo, whose index won't exist yet.
apt_update() {
  local stamp=/var/lib/apt/periodic/update-success-stamp
  if [ "${1:-}" != "force" ]; then
    [ -n "${APT_UPDATED:-}" ] && return 0
    if [ -f "$stamp" ] && [ -z "$(find "$stamp" -mmin +1440 2>/dev/null)" ]; then
      APT_UPDATED=1
      export APT_UPDATED
      return 0
    fi
  fi
  log "apt-get update"
  sudo_cmd apt-get update -qq || true
  APT_UPDATED=1
  export APT_UPDATED
}

# Install a .deb from a URL, skipping the download when the binary already exists.
apt_install_deb() {
  local url="$1" tmp
  tmp="$(mktemp --suffix=.deb)"
  log "downloading $url"
  curl -fsSL "$url" -o "$tmp"
  sudo_cmd env DEBIAN_FRONTEND=noninteractive apt-get install -y "$tmp"
  rm -f "$tmp"
}

# The architecture slug used by most GitHub release assets.
deb_arch() {
  case "$(uname -m)" in
    x86_64)  echo amd64 ;;
    aarch64) echo arm64 ;;
    *)       echo "unsupported architecture: $(uname -m)" >&2; return 1 ;;
  esac
}

# Latest release tag of a GitHub repo, without needing jq.
github_latest_tag() {
  local body tag
  # Buffered rather than piped straight into grep -m1, which would close the
  # pipe early and make curl noisily fail with SIGPIPE.
  body="$(curl -fsSL "https://api.github.com/repos/$1/releases/latest")" || return 1
  tag="$(printf '%s' "$body" | grep -m1 '"tag_name"' | sed -E 's/.*"tag_name": *"([^"]+)".*/\1/')"
  [ -n "$tag" ] || { err "could not determine latest release of $1"; return 1; }
  printf '%s' "$tag"
}

# Download a release archive (.tar.gz / .zip) and drop the named binary into
# ~/.local/bin. Keeps upstream-current tools working without root.
install_release_bin() {
  local url="$1" binary="$2" tmpdir archive found
  tmpdir="$(mktemp -d)"
  archive="$tmpdir/archive"

  log "downloading $url"
  curl -fsSL "$url" -o "$archive" || { rm -rf "$tmpdir"; return 1; }

  case "$url" in
    *.zip)
      if has unzip; then
        unzip -oq "$archive" -d "$tmpdir/x"
      else
        # python3 is always present on Ubuntu, and unzip may not be installable
        # without root.
        mkdir -p "$tmpdir/x" && python3 -m zipfile -e "$archive" "$tmpdir/x"
      fi
      ;;
    *) mkdir -p "$tmpdir/x" && tar -xzf "$archive" -C "$tmpdir/x" ;;
  esac

  found="$(find "$tmpdir/x" -type f -name "$binary" -print -quit)"
  if [ -z "$found" ]; then
    err "$binary not found in $url"
    rm -rf "$tmpdir"
    return 1
  fi

  mkdir -p "$LOCAL_BIN"
  install -m 0755 "$found" "$LOCAL_BIN/$binary"
  rm -rf "$tmpdir"
  log "installed $LOCAL_BIN/$binary"
}

confirm() {
  local prompt="$1" reply
  # Non-interactive runs (CI, piped stdin) take the default: no.
  if [ ! -t 0 ]; then
    return 1
  fi
  read -r -p "$prompt [y/N] " reply
  [[ "$reply" =~ ^[Yy]$ ]]
}
