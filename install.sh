#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
STATE="$HOME/.local/state/niri-noctalia-dotfiles"
CONFIG="$HOME/.config"
WALLPAPER="$HOME/Pictures/Noctalia"
PKGS=(niri noctalia kitty dolphin lightdm-webkit2-theme-glorious xdg-desktop-portal-gtk xdg-desktop-portal-gnome xwayland-satellite qt6-wayland qt6ct qt5ct breeze playerctl brightnessctl wl-clipboard)
UPDATING=0
KEEP_EXISTING_WALLPAPER=0

if [[ "$EUID" -eq 0 ]]; then
  echo "Ejecuta este instalador como tu usuario normal, sin sudo. Él pedirá sudo solo para pacman." >&2
  exit 1
fi
if [[ ! -r /etc/os-release ]]; then echo "No puedo identificar la distribución." >&2; exit 1; fi
. /etc/os-release
if [[ "${ID:-}" != cachyos ]]; then
  echo "Este instalador está preparado para CachyOS; detecté ${PRETTY_NAME:-desconocida}." >&2
  exit 1
fi
if ! command -v yay >/dev/null 2>&1; then
  echo "Necesito yay para instalar el cursor Windows-10 desde AUR en CachyOS." >&2
  exit 1
fi
if [[ -e "$STATE/installed" ]]; then
  UPDATING=1
fi
for f in niri/config.kdl noctalia/config.toml noctalia/bar.toml noctalia/BlueDusk.json kitty/kitty.conf dolphinrc kdeglobals wallpaper/wallhaven-e7xx6r_1920x1080-dark10.png; do
  [[ -e "$ROOT/config/$f" ]] || { echo "Falta el archivo del paquete: config/$f" >&2; exit 1; }
done
if [[ -e "$WALLPAPER/wallhaven-e7xx6r_1920x1080-dark10.png" ]] &&
   ! cmp -s "$ROOT/config/wallpaper/wallhaven-e7xx6r_1920x1080-dark10.png" "$WALLPAPER/wallhaven-e7xx6r_1920x1080-dark10.png"; then
  if ((UPDATING)); then
    KEEP_EXISTING_WALLPAPER=1
    echo "Conservo el wallpaper existente, que fue modificado después de la instalación."
  else
    echo "El wallpaper destino ya existe y es distinto; no lo sobrescribo." >&2
    exit 1
  fi
fi

mkdir -p "$STATE" "$CONFIG"
before="$STATE/packages-before.txt"
if [[ ! -s "$before" ]]; then
  pacman -Qq | sort -u > "$before"
fi
pacman -Qq | sort -u > "$STATE/packages-before-run.txt"
previously_added="$STATE/packages-added.txt"
sudo pacman -Syu --needed "${PKGS[@]}"
yay -S --needed windows-10-cursor
for binary in niri noctalia; do
  if ! command -v "$binary" >/dev/null 2>&1; then
    echo "No encuentro '$binary' en PATH después de instalar los paquetes. No copié la configuración." >&2
    exit 1
  fi
done
pacman -Qq | sort -u > "$STATE/packages-after.txt"
newly_added="$STATE/packages-added.new"
comm -13 "$STATE/packages-before-run.txt" "$STATE/packages-after.txt" | sort -u > "$newly_added"
if [[ -s "$previously_added" ]]; then
  cat "$previously_added" "$newly_added" | sort -u > "$STATE/packages-added.merged"
  mv "$STATE/packages-added.merged" "$previously_added"
else
  mv "$newly_added" "$previously_added"
fi
rm -f "$newly_added"
rm -f "$STATE/packages-before-run.txt"

mkdir -p "$STATE/backup" "$STATE/created" "$WALLPAPER"
for item in niri noctalia kitty dolphinrc kdeglobals; do
  if [[ -e "$CONFIG/$item" && ! -e "$STATE/created/had-$item" ]]; then
    cp -a "$CONFIG/$item" "$STATE/backup/$item"
    touch "$STATE/created/had-$item"
  fi
done
mkdir -p "$CONFIG/niri/cfg" "$CONFIG/noctalia/palettes" "$CONFIG/kitty"
cp -a "$ROOT/config/niri/." "$CONFIG/niri/"
cp -a "$ROOT/config/noctalia/config.toml" "$ROOT/config/noctalia/bar.toml" "$CONFIG/noctalia/"
cp -a "$ROOT/config/noctalia/BlueDusk.json" "$CONFIG/noctalia/palettes/"
cp -a "$ROOT/config/kitty/kitty.conf" "$CONFIG/kitty/"
cp -a "$ROOT/config/dolphinrc" "$CONFIG/dolphinrc"
cp -a "$ROOT/config/kdeglobals" "$CONFIG/kdeglobals"
if ((!KEEP_EXISTING_WALLPAPER)); then
  cp -a "$ROOT/config/wallpaper/wallhaven-e7xx6r_1920x1080-dark10.png" "$WALLPAPER/"
  rm -f "$STATE/created/kept-wallpaper"
else
  touch "$STATE/created/kept-wallpaper"
fi
sed -i "s|/home/itzcinder/Imágenes/Noctalia|$WALLPAPER|g" "$CONFIG/noctalia/config.toml"
niri validate --config "$CONFIG/niri/config.kdl"
noctalia config validate
touch "$STATE/installed"
if ((UPDATING)); then
  echo "Actualización completada. Cierra sesión y vuelve a entrar en Niri para aplicar todos los cambios."
else
  echo "Instalado. Cierra sesión y elige Niri en el selector de sesiones. GNOME seguirá disponible."
fi
echo "Los respaldos originales se conservan en: $STATE/backup"
