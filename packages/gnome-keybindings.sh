#!/usr/bin/env bash
# GNOME desktop keybindings.
#
# These live in dconf rather than a config file, so they're applied with
# gsettings instead of symlinked. No-ops on a machine without GNOME.
set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

# schema|key|value  -- values are GVariant literals, quoted as gsettings wants.
BINDINGS=(
  # Launch a terminal with Super+T instead of GNOME's default Ctrl+Alt+T.
  "org.gnome.settings-daemon.plugins.media-keys|terminal|['<Super>t']"
)

has gsettings || { log "gsettings not available, skipping GNOME keybindings"; exit 0; }

# Schemas that hold the bindings a new one could collide with.
CONFLICT_SCHEMAS=(
  org.gnome.settings-daemon.plugins.media-keys
  org.gnome.desktop.wm.keybindings
  org.gnome.shell.keybindings
  org.gnome.mutter.keybindings
)

warn_on_conflict() {
  local schema="$1" key="$2" value="$3" line
  # The literal accelerator, e.g. <Super>t, as it appears in other bindings.
  local accel="${value#*\'}"; accel="${accel%%\'*}"
  [ -n "$accel" ] || return 0

  for s in "${CONFLICT_SCHEMAS[@]}"; do
    gsettings list-schemas 2>/dev/null | grep -qx "$s" || continue
    while IFS= read -r line; do
      # Skip the binding we're about to set.
      [[ "$line" == "$schema $key "* ]] && continue
      warn "'$accel' is also bound by: $line"
    done < <(gsettings list-recursively "$s" 2>/dev/null | grep -F "'$accel'")
  done
}

for entry in "${BINDINGS[@]}"; do
  IFS='|' read -r schema key value <<<"$entry"

  gsettings list-schemas 2>/dev/null | grep -qx "$schema" || {
    log "schema $schema not installed, skipping $key"
    continue
  }

  current="$(gsettings get "$schema" "$key" 2>/dev/null)"
  if [ "$current" = "$value" ]; then
    log "$key already set to $value"
    continue
  fi

  warn_on_conflict "$schema" "$key" "$value"
  log "setting $schema $key: $current -> $value"
  gsettings set "$schema" "$key" "$value" || warn "could not set $schema $key"
done
