#!/usr/bin/env bash
# requires-sudo
# Baseline apt packages everything else assumes.
set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

apt_install \
  build-essential \
  ca-certificates \
  curl \
  file \
  git \
  gnupg \
  jq \
  pass \
  procps \
  python-is-python3 \
  python3-pip \
  python3-venv \
  unzip \
  wget \
  zstd
