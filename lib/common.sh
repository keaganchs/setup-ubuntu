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

# append_once, but first drop any line matching $pattern that isn't the line we
# want -- the same directive pointing at a different checkout of this repo.
#
# Appending alone isn't enough: moving the clone (or making a second one and
# deleting the first) leaves the old path behind, and since the wiring is a
# `source`/`$include` of a file that no longer exists, every new shell opens with
# "No such file or directory". Only lines this repo writes are matched, so
# anything else in the file is left alone.
append_once_owned() {
  local file="$1" line="$2" pattern="$3" stale tmp
  touch "$file"

  stale="$(grep -E -- "$pattern" "$file" | grep -xvF -- "$line")"
  if [ -n "$stale" ]; then
    while IFS= read -r s; do
      warn "$file pointed at another checkout: $s"
    done <<< "$stale"
    warn "  replaced with $line"
    tmp="$(mktemp)"
    # This drops the wanted line too if it was already present; the append below
    # puts it back, at the end. (awk would be the obvious tool here, but it
    # unescapes -v assignments, so the backslashes in $pattern wouldn't survive
    # the trip and the filter would quietly match nothing.)
    grep -vE -- "$pattern" "$file" > "$tmp"
    # 1 just means nothing was left, which is a legitimate result; only a real
    # grep failure should stop us from writing.
    if [ "$?" -gt 1 ]; then
      err "could not rewrite $file; left as is"
      rm -f "$tmp"
      return 1
    fi
    # Written back through the original file so its mode and owner survive.
    cat "$tmp" > "$file"
    rm -f "$tmp"
  fi

  grep -qxF -- "$line" "$file" || printf '%s\n' "$line" >> "$file"
}

# Copy a config tree into ~/.config/<tool>, where the tool insists on finding it.
#
# The repo owns these files, so a re-run restores them -- but everything else in
# the destination is left where it is, which is what tpm's plugin checkouts and
# anything else a tool writes next to its config depend on. A file the repo also
# ships is backed up before being replaced, so a local edit is recoverable
# rather than silently lost.
#
# "What the repo owns" comes from git: tracked files, plus untracked ones git
# isn't ignoring. So config/tmux/.gitignore, which already marks plugins/* as
# runtime state, decides what gets copied without having to say so twice.
# Submodules are listed by git as a single directory entry and so fall out of
# the file loop below -- right, because a submodule is a dependency to install,
# not config to copy. tpm in particular has to reach its destination as a real
# git checkout (packages/tmux.sh does that): it decides which plugins are
# already installed by running `git remote` in their directories, so a copy of
# its files without the .git would look uninstalled to it.
copy_config() {
  local src="$1" dst="$2"
  local rel prefix file target stamp copied=0
  local -a paths=() drifted=()

  prefix="${src#"$DOTFILES_DIR"/}"
  mapfile -t paths < <(
    {
      git -C "$DOTFILES_DIR" ls-files -- "$prefix"
      git -C "$DOTFILES_DIR" ls-files --others --exclude-standard -- "$prefix"
    } 2>/dev/null | sort -u
  )
  if [ ${#paths[@]} -eq 0 ]; then
    err "no files to copy from $src (is it a git checkout?)"
    return 1
  fi

  # Older installs symlinked this at a checkout. The files live in the repo, so
  # dropping the link loses nothing -- and leaving it would make the copies
  # below write straight back into whichever checkout it points at.
  if [ -L "$dst" ]; then
    log "replacing the $dst symlink with real files"
    rm -f "$dst"
  fi

  stamp="$(date +%Y%m%d%H%M%S)"
  for rel in "${paths[@]}"; do
    file="$DOTFILES_DIR/$rel"
    [ -f "$file" ] || continue
    target="$dst/${rel#"$prefix"/}"
    [ -f "$target" ] && cmp -s "$file" "$target" && continue
    if [ -e "$target" ]; then
      cp -p "$target" "$target.backup.$stamp"
      drifted+=("${rel#"$prefix"/}")
    fi
    mkdir -p "$(dirname "$target")"
    cp -p "$file" "$target"
    copied=$((copied + 1))
  done

  if [ ${#drifted[@]} -gt 0 ]; then
    warn "$dst had local edits to: ${drifted[*]}"
    warn "  replaced from the repo; the old copies are alongside them as *.backup.$stamp"
    warn "  to keep one for good, copy it into $src and commit it"
  fi

  if [ "$copied" -eq 0 ]; then
    log "$dst already up to date"
  else
    log "copied $copied file(s) into $dst"
  fi
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
#
# Any arguments after the binary name are a smoke test: the extracted binary is
# run with them first, and nothing is installed unless it exits 0. Worth passing
# (`--version`) for anything whose upstream build may be linked against a newer
# glibc than the machine has -- see packages/tree-sitter.sh.
install_release_bin() {
  local url="$1" binary="$2" tmpdir archive found
  shift 2
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

  if [ "$#" -gt 0 ]; then
    chmod +x "$found"
    local output
    if ! output="$("$found" "$@" 2>&1)"; then
      warn "$binary from $url does not run on this machine:"
      warn "  $(printf '%s' "$output" | head -1)"
      rm -rf "$tmpdir"
      return 1
    fi
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
