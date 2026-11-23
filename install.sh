#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
STATE="$HOME/.local/state/niri-noctalia-dotfiles"
CONFIG="$HOME/.config"
WALLPAPER="$HOME/Pictures/Noctalia"
PKGS=(niri noctalia kitty dolphin fastfetch lightdm lightdm-webkit2-greeter xdg-desktop-portal xdg-desktop-portal-kde xdg-desktop-portal-gtk xdg-desktop-portal-gnome xwayland-satellite qt6-wayland qt6ct qt5ct breeze playerctl brightnessctl wl-clipboard)
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
for f in niri/config.kdl noctalia/config.toml noctalia/bar.toml noctalia/BlueDusk.json kitty/kitty.conf kitty/current-theme.conf fastfetch/config.jsonc fastfetch/arch.txt dolphinrc kdeglobals xdg-desktop-portal/niri-portals.conf environment.d/90-gnome-qt.conf wallpaper/wallhaven-e7xx6r_1920x1080-dark10.png; do
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
yay -S --needed windows-10-cursor lightdm-webkit2-theme-glorious
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

mkdir -p "$STATE/backup" "$STATE/created" "$STATE/system-backup" "$WALLPAPER"
for item in niri noctalia kitty fastfetch dolphinrc kdeglobals xdg-desktop-portal environment.d; do
  if [[ -e "$CONFIG/$item" && ! -e "$STATE/created/had-$item" ]]; then
    cp -a "$CONFIG/$item" "$STATE/backup/$item"
    touch "$STATE/created/had-$item"
  fi
done

# Keep the current display-manager choice and LightDM configuration for uninstall.
if [[ ! -e "$STATE/created/display-manager-saved" ]]; then
  display_manager_target="$(readlink /etc/systemd/system/display-manager.service 2>/dev/null || true)"
  printf '%s\n' "$display_manager_target" > "$STATE/system-backup/display-manager-target"
  if [[ -n "$display_manager_target" ]]; then
    display_manager_unit="${display_manager_target##*/}"
    if systemctl is-enabled "$display_manager_unit" >/dev/null 2>&1; then
      display_manager_enabled=1
    else
      display_manager_enabled=0
    fi
  else
    display_manager_enabled=0
  fi
  printf '%s\n' "$display_manager_enabled" > "$STATE/system-backup/display-manager-enabled"
  for system_file in /etc/lightdm/lightdm-webkit2-greeter.conf /etc/lightdm/lightdm.conf.d/50-niri-noctalia.conf; do
    file_key="${system_file##*/}"
    if sudo test -e "$system_file"; then
      sudo cat "$system_file" > "$STATE/system-backup/$file_key"
      touch "$STATE/system-backup/had-$file_key"
    else
      touch "$STATE/system-backup/absent-$file_key"
    fi
  done
  touch "$STATE/created/display-manager-saved"
fi

mkdir -p "$CONFIG/niri/cfg" "$CONFIG/noctalia/palettes" "$CONFIG/kitty" "$CONFIG/fastfetch" "$CONFIG/xdg-desktop-portal" "$CONFIG/environment.d"
cp -a "$ROOT/config/niri/." "$CONFIG/niri/"
cp -a "$ROOT/config/noctalia/config.toml" "$ROOT/config/noctalia/bar.toml" "$CONFIG/noctalia/"
cp -a "$ROOT/config/noctalia/BlueDusk.json" "$CONFIG/noctalia/palettes/"
cp -a "$ROOT/config/kitty/kitty.conf" "$CONFIG/kitty/"
cp -a "$ROOT/config/kitty/current-theme.conf" "$CONFIG/kitty/"
cp -a "$ROOT/config/fastfetch/." "$CONFIG/fastfetch/"
cp -a "$ROOT/config/dolphinrc" "$CONFIG/dolphinrc"
cp -a "$ROOT/config/kdeglobals" "$CONFIG/kdeglobals"
cp -a "$ROOT/config/xdg-desktop-portal/niri-portals.conf" "$CONFIG/xdg-desktop-portal/"
cp -a "$ROOT/config/environment.d/90-gnome-qt.conf" "$CONFIG/environment.d/"

# Configure the WebKit2 greeter without replacing LightDM's main configuration.
sudo install -d -m 755 /etc/lightdm/lightdm.conf.d
printf '[Seat:*]\ngreeter-session=lightdm-webkit2-greeter\n' | sudo tee /etc/lightdm/lightdm.conf.d/50-niri-noctalia.conf >/dev/null
greeter_config=/etc/lightdm/lightdm-webkit2-greeter.conf
greeter_tmp_dir="$(mktemp -d)"
if sudo test -f "$greeter_config"; then
  sudo cat "$greeter_config" > "$greeter_tmp_dir/original"
else
  : > "$greeter_tmp_dir/original"
fi
awk '
  function add_missing_greeter_settings() {
    if (!theme_seen) print "webkit_theme = glorious"
    if (!debug_seen) print "debug_mode = true"
    if (!fallback_seen) print "detect_theme_errors = true"
  }
  /^[[:space:]]*\[[^]]+\][[:space:]]*$/ {
    if (in_greeter) add_missing_greeter_settings()
    in_greeter = ($0 ~ /^\[greeter\][[:space:]]*$/)
    if (in_greeter) greeter_found = 1
    print
    next
  }
  in_greeter && /^[[:space:]]*webkit_theme[[:space:]]*=/ {
    if (!theme_seen) print "webkit_theme = glorious"
    theme_seen = 1
    next
  }
  in_greeter && /^[[:space:]]*debug_mode[[:space:]]*=/ {
    if (!debug_seen) print "debug_mode = true"
    debug_seen = 1
    next
  }
  in_greeter && /^[[:space:]]*detect_theme_errors[[:space:]]*=/ {
    if (!fallback_seen) print "detect_theme_errors = true"
    fallback_seen = 1
    next
  }
  { print }
  END {
    if (in_greeter) add_missing_greeter_settings()
    if (!greeter_found) {
      print ""
      print "[greeter]"
      print "webkit_theme = glorious"
      print "debug_mode = true"
      print "detect_theme_errors = true"
    }
  }
' "$greeter_tmp_dir/original" > "$greeter_tmp_dir/updated"
sudo install -m 644 "$greeter_tmp_dir/updated" "$greeter_config"
rm -rf -- "$greeter_tmp_dir"

# Replace the selected display manager for the next boot; do not stop the
# current graphical session while this installer is running.
display_manager_unit="$(basename "$(readlink -f /etc/systemd/system/display-manager.service 2>/dev/null || true)")"
if [[ -n "$display_manager_unit" && "$display_manager_unit" != lightdm.service ]]; then
  sudo systemctl disable "$display_manager_unit"
fi
sudo systemctl enable lightdm.service

systemctl --user restart xdg-desktop-portal.service
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
  echo "Actualización completada. Reinicia el equipo para aplicar LightDM y cierra sesión y vuelve a entrar en Niri para aplicar la configuración."
else
  echo "Instalado. Reinicia el equipo para iniciar con LightDM y elige Niri en el selector de sesiones. GNOME seguirá disponible."
fi
echo "Los respaldos originales se conservan en: $STATE/backup"
