#!/usr/bin/env bash
set -euo pipefail

STATE="$HOME/.local/state/niri-noctalia-dotfiles"
CONFIG="$HOME/.config"
PICTURES_DIR="$(xdg-user-dir PICTURES 2>/dev/null || true)"
if [[ -z "$PICTURES_DIR" || "$PICTURES_DIR" == "$HOME" ]]; then
  PICTURES_DIR="$HOME/Pictures"
fi
WALLPAPER="$PICTURES_DIR/Noctalia/wallhaven-e7xx6r_1920x1080-dark10.png"
if [[ ! -e "$STATE/installed" ]]; then
  echo "No encuentro una instalación registrada en $STATE." >&2
  exit 1
fi

mkdir -p "$STATE/uninstall-saved"
for item in niri noctalia kitty fastfetch dolphinrc kdeglobals mimeapps.list xdg-desktop-portal environment.d; do
  if [[ -e "$CONFIG/$item" ]]; then
    cp -a "$CONFIG/$item" "$STATE/uninstall-saved/$item"
  fi
  rm -rf -- "$CONFIG/$item"
  if [[ -e "$STATE/created/had-$item" ]]; then
    cp -a "$STATE/backup/$item" "$CONFIG/$item"
  fi
done

if [[ -e "$STATE/created/display-manager-saved" && ! -e "$STATE/created/display-manager-restored" ]]; then
  # Remove our LightDM selection and put the previous display manager back.
  sudo systemctl disable lightdm.service >/dev/null 2>&1 || true

  for config_name in lightdm-webkit2-greeter.conf 50-niri-noctalia.conf; do
    if [[ -e "$STATE/system-backup/had-$config_name" ]]; then
      if [[ "$config_name" == 50-niri-noctalia.conf ]]; then
        sudo install -d -m 755 /etc/lightdm/lightdm.conf.d
        sudo install -m 644 "$STATE/system-backup/$config_name" "/etc/lightdm/lightdm.conf.d/$config_name"
      else
        sudo install -d -m 755 /etc/lightdm
        sudo install -m 644 "$STATE/system-backup/$config_name" "/etc/lightdm/$config_name"
      fi
    elif [[ -e "$STATE/system-backup/absent-$config_name" ]]; then
      if [[ "$config_name" == 50-niri-noctalia.conf ]]; then
        sudo rm -f "/etc/lightdm/lightdm.conf.d/$config_name"
      else
        sudo rm -f "/etc/lightdm/$config_name"
      fi
    fi
  done

  previous_target="$(cat "$STATE/system-backup/display-manager-target" 2>/dev/null || true)"
  previous_unit="${previous_target##*/}"
  if [[ -n "$previous_unit" ]]; then
    if [[ "$(cat "$STATE/system-backup/display-manager-enabled" 2>/dev/null || echo 0)" == 1 ]]; then
      sudo systemctl enable "$previous_unit"
    else
      sudo systemctl disable "$previous_unit" >/dev/null 2>&1 || true
    fi
  fi
  touch "$STATE/created/display-manager-restored"
  echo "Se restauró la selección anterior del gestor de inicio. Reinicia para aplicarla."
fi
if [[ -e "$STATE/created/lightdm-theme-installed" ]]; then
  sudo rm -rf -- /usr/share/lightdm-webkit/themes/niri-noctalia
  rm -f -- "$STATE/created/lightdm-theme-installed"
fi

if [[ ! -e "$STATE/created/kept-wallpaper" ]]; then
  rm -f -- "$WALLPAPER"
fi
rm -f "$STATE/created/kept-wallpaper"
rmdir "$PICTURES_DIR/Noctalia" 2>/dev/null || true

added=()
if [[ -f "$STATE/packages-added.txt" ]]; then
  mapfile -t added < "$STATE/packages-added.txt"
fi
if ((${#added[@]})); then
  echo "Paquetes que este instalador añadió y que se propondrán quitar: ${added[*]}"
  sudo pacman -Rns "${added[@]}"
fi
rm -f -- "$STATE/installed" "$STATE/packages-before.txt" "$STATE/packages-after.txt" "$STATE/packages-added.txt"
rm -f -- "$STATE/created/display-manager-saved" "$STATE/created/display-manager-restored"
rm -rf -- "$STATE/system-backup"
echo "Desinstalación completada. Se restauraron las configuraciones previas."
echo "Las configuraciones retiradas se conservaron en $STATE/uninstall-saved y los respaldos originales en $STATE/backup."
