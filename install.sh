#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
STATE="$HOME/.local/state/niri-noctalia-dotfiles"
CONFIG="$HOME/.config"
PICTURES_DIR="$(xdg-user-dir PICTURES 2>/dev/null || true)"
if [[ -z "$PICTURES_DIR" || "$PICTURES_DIR" == "$HOME" ]]; then
  PICTURES_DIR="$HOME/Pictures"
fi
WALLPAPER="$PICTURES_DIR/Noctalia"
NIRI_WALLPAPER="$ROOT/config/wallpaper/wallhaven-e7xx6r_1920x1080-dark10.png"
PKGS=(niri noctalia kitty dolphin fastfetch lightdm lightdm-webkit2-greeter jq xdg-desktop-portal xdg-desktop-portal-kde xdg-desktop-portal-gtk xdg-desktop-portal-gnome xwayland-satellite qt6-wayland breeze playerctl brightnessctl wl-clipboard)
LIGHTDM_THEME_NAME=niri-noctalia
LIGHTDM_THEME_DIR="/usr/share/lightdm-webkit/themes/$LIGHTDM_THEME_NAME"
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
for f in niri/config.kdl noctalia/config.toml noctalia/bar.toml noctalia/BlueDusk.json kitty/kitty.conf kitty/current-theme.conf fastfetch/config.jsonc fastfetch/arch.txt dolphinrc kdeglobals xdg-desktop-portal/niri-portals.conf environment.d/90-kde-qt.conf wallpaper/wallhaven-e7xx6r_1920x1080-dark10.png; do
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
for binary in niri noctalia jq; do
  if ! command -v "$binary" >/dev/null 2>&1; then
    echo "No encuentro '$binary' en PATH después de instalar los paquetes. No copié la configuración." >&2
    exit 1
  fi
done
for palette_key in primary on_surface surface error tertiary; do
  palette_color="$(jq -er ".dark.$palette_key" "$ROOT/config/noctalia/BlueDusk.json")"
  if [[ ! "$palette_color" =~ ^#[[:xdigit:]]{6}$ ]]; then
    echo "Color inválido en la paleta Noctalia: $palette_key=$palette_color" >&2
    exit 1
  fi
  case "$palette_key" in
    primary) LIGHTDM_PRIMARY="$palette_color" ;;
    on_surface) LIGHTDM_FOREGROUND="$palette_color" ;;
    surface) LIGHTDM_SURFACE="$palette_color" ;;
    error) LIGHTDM_ERROR="$palette_color" ;;
    tertiary) LIGHTDM_SUCCESS="$palette_color" ;;
  esac
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
cp -a "$ROOT/config/environment.d/90-kde-qt.conf" "$CONFIG/environment.d/"
legacy_qt_env="$CONFIG/environment.d/90-gnome-qt.conf"
if [[ -f "$legacy_qt_env" ]] && grep -qx '# Qt6ct palette and Breeze widget style for Qt apps in the Niri session\.' "$legacy_qt_env" &&
   grep -qx 'QT_QPA_PLATFORMTHEME=qt6ct' "$legacy_qt_env" &&
   grep -qx 'QT_STYLE_OVERRIDE=breeze' "$legacy_qt_env"; then
  rm -f -- "$legacy_qt_env"
fi
wallpaper_toml_path="$(printf '%s' "$WALLPAPER" | sed 's/[\\&|"]/\\&/g')"
sed -i "s|~/Pictures/Noctalia|$wallpaper_toml_path|g" "$CONFIG/noctalia/config.toml"

# Configure the WebKit2 greeter without replacing LightDM's main configuration.
sudo install -d -m 755 /etc/lightdm/lightdm.conf.d
printf '[Seat:*]\ngreeter-session=lightdm-webkit2-greeter\n' | sudo tee /etc/lightdm/lightdm.conf.d/50-niri-noctalia.conf >/dev/null
greeter_config=/etc/lightdm/lightdm-webkit2-greeter.conf
greeter_tmp_dir="$(mktemp -d)"
saved_greeter_config="$STATE/system-backup/lightdm-webkit2-greeter.conf"
if [[ -e "$STATE/created/display-manager-saved" && -s "$saved_greeter_config" ]] &&
   sudo test -f "$greeter_config" &&
   ! sudo grep -Eq '^[[:space:]]*(debug_mode|detect_theme_errors)[[:space:]]*=' "$greeter_config"; then
  # Recover settings lost by the previous installer version before merging.
  cp -a "$saved_greeter_config" "$greeter_tmp_dir/original"
elif sudo test -f "$greeter_config"; then
  sudo cat "$greeter_config" > "$greeter_tmp_dir/original"
else
  : > "$greeter_tmp_dir/original"
fi
awk -v theme_name="$LIGHTDM_THEME_NAME" '
  function add_missing_greeter_settings() {
    if (!theme_seen) print "webkit_theme = " theme_name
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
    if (!theme_seen) print "webkit_theme = " theme_name
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
      print "webkit_theme = " theme_name
      print "debug_mode = true"
      print "detect_theme_errors = true"
    }
  }
' "$greeter_tmp_dir/original" > "$greeter_tmp_dir/updated"
sudo install -m 644 "$greeter_tmp_dir/updated" "$greeter_config"
rm -rf -- "$greeter_tmp_dir"

# Build a separately named Glorious theme and tint it with Noctalia's palette.
glorious_theme_source=/usr/share/lightdm-webkit/themes/glorious
if ! sudo test -d "$glorious_theme_source"; then
  echo "No encuentro el tema Glorious instalado en $glorious_theme_source." >&2
  exit 1
fi
if [[ ! -e "$STATE/created/lightdm-theme-installed" ]] && sudo test -e "$LIGHTDM_THEME_DIR"; then
  echo "Ya existe $LIGHTDM_THEME_DIR y no pertenece a esta instalación; no lo sobrescribo." >&2
  exit 1
fi
sudo install -d -m 755 "$LIGHTDM_THEME_DIR"
touch "$STATE/created/lightdm-theme-installed"
sudo cp -a "$glorious_theme_source/." "$LIGHTDM_THEME_DIR/"
sudo sed -i -E 's/^name=.*/name=niri-noctalia/' "$LIGHTDM_THEME_DIR/index.theme"
sudo install -m 644 "$NIRI_WALLPAPER" "$LIGHTDM_THEME_DIR/assets/bg.png"
sudo sed -i "s|this._defaultBackgroundPath = 'assets/bg.jpg';|this._defaultBackgroundPath = 'assets/bg.png';|" "$LIGHTDM_THEME_DIR/js/backgrounds.js"
if ! cmp -s "$NIRI_WALLPAPER" "$LIGHTDM_THEME_DIR/assets/bg.png" ||
   ! sudo grep -Fq "this._defaultBackgroundPath = 'assets/bg.png';" "$LIGHTDM_THEME_DIR/js/backgrounds.js"; then
  echo "No pude aplicar el wallpaper de Niri al tema de LightDM." >&2
  exit 1
fi
theme_css="$LIGHTDM_THEME_DIR/css/global.css"
set_theme_color() {
  local variable="$1" value="$2"
  sudo sed -i -E "s|^([[:space:]]*${variable}:[[:space:]]*).*(;[[:space:]]*)$|\\1${value}\\2|" "$theme_css"
  if ! sudo grep -Fq -- "${variable}: ${value};" "$theme_css"; then
    echo "No pude aplicar $variable=$value a la variante LightDM." >&2
    exit 1
  fi
}
set_theme_color --global-bg "${LIGHTDM_SURFACE}E6"
set_theme_color --global-fg "${LIGHTDM_FOREGROUND}FF"
set_theme_color --button-bg-hover "${LIGHTDM_PRIMARY}30"
set_theme_color --button-bg-focus "${LIGHTDM_PRIMARY}55"
set_theme_color --button-bg-active "${LIGHTDM_PRIMARY}70"
set_theme_color --tooltip-error-bg "${LIGHTDM_ERROR}60"
set_theme_color --tooltip-success-bg "${LIGHTDM_SUCCESS}60"
set_theme_color --login-form-elements-fg "$LIGHTDM_FOREGROUND"
set_theme_color --login-failed-bg "${LIGHTDM_ERROR}60"
set_theme_color --login-success-bg "${LIGHTDM_SUCCESS}60"
set_theme_color --sidebar-group-elements-bg "${LIGHTDM_PRIMARY}22"
set_theme_color --sidebar-group-elements-fg "$LIGHTDM_FOREGROUND"
set_theme_color --sidebar-group-elements-button-bg "${LIGHTDM_PRIMARY}14"
set_theme_color --sidebar-elements-bg "${LIGHTDM_PRIMARY}22"
set_theme_color --main-screen-button-bg "${LIGHTDM_PRIMARY}22"
set_theme_color --arrow-indicator-bg "$LIGHTDM_PRIMARY"
set_theme_color --arrow-indicator-bg-fade "${LIGHTDM_PRIMARY}20"
if ! sudo grep -Fq "name=$LIGHTDM_THEME_NAME" "$LIGHTDM_THEME_DIR/index.theme" ||
   ! sudo grep -Fq "webkit_theme = $LIGHTDM_THEME_NAME" "$greeter_config" ||
   ! sudo grep -Fq 'debug_mode = true' "$greeter_config" ||
   ! sudo grep -Fq 'detect_theme_errors = true' "$greeter_config"; then
  echo "La configuración integrada de LightDM no pasó la validación." >&2
  exit 1
fi

# Replace the selected display manager for the next boot; do not stop the
# current graphical session while this installer is running.
display_manager_unit="$(basename "$(readlink -f /etc/systemd/system/display-manager.service 2>/dev/null || true)")"
if [[ -n "$display_manager_unit" && "$display_manager_unit" != lightdm.service ]]; then
  sudo systemctl disable "$display_manager_unit"
fi
sudo systemctl enable lightdm.service
sudo systemctl reset-failed lightdm.service

# Update the running user manager too; environment.d is otherwise read only
# when the manager starts, leaving portal backends on a stale Qt theme.
systemctl --user set-environment QT_QPA_PLATFORMTHEME=kde QT_STYLE_OVERRIDE=Breeze
systemctl --user restart xdg-desktop-portal.service
if ((!KEEP_EXISTING_WALLPAPER)); then
  cp -a "$ROOT/config/wallpaper/wallhaven-e7xx6r_1920x1080-dark10.png" "$WALLPAPER/"
  rm -f "$STATE/created/kept-wallpaper"
else
  touch "$STATE/created/kept-wallpaper"
fi
niri validate --config "$CONFIG/niri/config.kdl"
noctalia config validate
touch "$STATE/installed"
if ((UPDATING)); then
  echo "Actualización completada. Reinicia el equipo para aplicar LightDM y cierra sesión y vuelve a entrar en Niri para aplicar la configuración."
else
  echo "Instalado. Reinicia el equipo para iniciar con LightDM y elige Niri en el selector de sesiones. GNOME seguirá disponible."
fi
echo "Los respaldos originales se conservan en: $STATE/backup"
