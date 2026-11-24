#!/usr/bin/env bash

# Runtime dependencies from the CachyOS/Arch repositories.
# Keep this list separate from install.sh so package choices are easy to review.
PKGS=(
  # CachyOS main-branch build includes the Mod release bind used for Overview.
  niri-git
  noctalia
  kitty
  dolphin
  vlc
  fastfetch
  lightdm
  lightdm-webkit2-greeter
  jq
  xdg-desktop-portal
  xdg-desktop-portal-kde
  xdg-desktop-portal-gtk
  # No GNOME session is installed; this backend provides ScreenCast for Noctalia.
  xdg-desktop-portal-gnome
  xwayland-satellite
  qt6-wayland
  breeze
  playerctl
  brightnessctl
  wl-clipboard
  gpu-screen-recorder
)

# Theme and cursor packages that are only available in the AUR.
AUR_PKGS=(windows-10-cursor lightdm-webkit2-theme-glorious)
