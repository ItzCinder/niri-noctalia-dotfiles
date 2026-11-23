#!/usr/bin/env bash
set -euo pipefail

STATE="$HOME/.local/state/niri-noctalia-dotfiles"
BACKUP="$STATE/system-backup/lightdm-webkit2-greeter.conf"
TARGET_FILE="$STATE/system-backup/display-manager-target"
ENABLED_FILE="$STATE/system-backup/display-manager-enabled"

if [[ ! -s "$BACKUP" ]]; then
  echo "No encuentro el respaldo anterior del greeter: $BACKUP" >&2
  echo "Inicia una TTY con Ctrl+Alt+F3 y revisa el gestor previo con systemctl." >&2
  exit 1
fi

sudo systemctl stop lightdm.service >/dev/null 2>&1 || true
sudo install -D -m 644 "$BACKUP" /etc/lightdm/lightdm-webkit2-greeter.conf
sudo systemctl reset-failed lightdm.service

previous_target="$(cat "$TARGET_FILE" 2>/dev/null || true)"
previous_unit="${previous_target##*/}"
if [[ -n "$previous_unit" && "$previous_unit" != lightdm.service ]]; then
  sudo systemctl disable lightdm.service >/dev/null 2>&1 || true
  if [[ "$(cat "$ENABLED_FILE" 2>/dev/null || echo 0)" == 1 ]]; then
    sudo systemctl enable "$previous_unit"
  else
    sudo systemctl disable "$previous_unit" >/dev/null 2>&1 || true
  fi
else
  sudo systemctl enable lightdm.service
fi

echo "Configuración de inicio restaurada. Reinicia con: sudo reboot"
