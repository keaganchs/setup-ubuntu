#!/usr/bin/env bash
# requires-sudo
# PulseAudio at 192kHz/24-bit instead of the 44.1kHz/16-bit default.
set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

apt_install pulseaudio || exit 1

CONF=/etc/pulse/daemon.conf
[ -f "$CONF" ] || { warn "$CONF not found, skipping audio tweaks"; exit 0; }

changed=0
# Match the setting whether it's still commented out or already set to
# something else, so re-runs converge instead of appending duplicates.
set_pulse_option() {
  local key="$1" value="$2"
  if grep -qE "^${key} = ${value}\$" "$CONF"; then
    return 0
  fi
  if grep -qE "^;? *${key} = " "$CONF"; then
    sudo_cmd sed -i -E "s|^;? *${key} = .*|${key} = ${value}|" "$CONF"
  else
    sudo_cmd tee -a "$CONF" >/dev/null <<<"${key} = ${value}"
  fi
  changed=1
}

set_pulse_option default-sample-rate 192000
set_pulse_option default-sample-format s24le

if [ "$changed" -eq 1 ]; then
  log "restarting pulseaudio"
  # PulseAudio runs per-user, so restart it as the desktop user, not as root.
  pulseaudio -k 2>/dev/null
  pulseaudio --start 2>/dev/null || warn "restart pulseaudio (or log out and back in) to apply"
else
  log "pulseaudio already configured"
fi
