#!/usr/bin/env bash
set -euo pipefail

STATE="$HOME/.local/state/niri-noctalia-dotfiles"
CONFIG="$HOME/.config"
WALLPAPER="$HOME/Pictures/Noctalia/wallhaven-e7xx6r_1920x1080-dark10.png"
if [[ ! -e "$STATE/installed" ]]; then
  echo "No encuentro una instalación registrada en $STATE." >&2
  exit 1
fi

mkdir -p "$STATE/uninstall-saved"
for item in niri noctalia kitty fastfetch dolphinrc kdeglobals xdg-desktop-portal environment.d; do
  if [[ -e "$CONFIG/$item" ]]; then
    cp -a "$CONFIG/$item" "$STATE/uninstall-saved/$item"
  fi
  rm -rf -- "$CONFIG/$item"
  if [[ -e "$STATE/created/had-$item" ]]; then
    cp -a "$STATE/backup/$item" "$CONFIG/$item"
  fi
done
if [[ ! -e "$STATE/created/kept-wallpaper" ]]; then
  rm -f -- "$WALLPAPER"
fi
rm -f "$STATE/created/kept-wallpaper"
rmdir "$HOME/Pictures/Noctalia" 2>/dev/null || true

added=()
if [[ -f "$STATE/packages-added.txt" ]]; then
  mapfile -t added < "$STATE/packages-added.txt"
fi
if ((${#added[@]})); then
  echo "Paquetes que este instalador añadió y que se propondrán quitar: ${added[*]}"
  sudo pacman -Rns "${added[@]}"
fi
rm -f -- "$STATE/installed" "$STATE/packages-before.txt" "$STATE/packages-after.txt" "$STATE/packages-added.txt"
echo "Desinstalación completada. Se restauraron las configuraciones previas."
echo "Las configuraciones retiradas se conservaron en $STATE/uninstall-saved y los respaldos originales en $STATE/backup."
