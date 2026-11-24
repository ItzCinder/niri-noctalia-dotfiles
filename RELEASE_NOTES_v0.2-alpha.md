# Noria v0.2-alpha

Esta versión reúne los cambios posteriores a `v0.1-alpha` y las mejoras de la alpha 0.2.

## Cambios desde v0.1-alpha

- Documentación de los controles de pantalla por monitor mediante Niri Displays.
- Documentación de los atajos de Niri.
- Se indica que el video de demostración aún está pendiente.

## Mejoras de la alpha 0.2

- Se trasladaron las listas de paquetes de repositorio y AUR a `scripts/packages.sh`.
- Se quitó GNOME como sesión alternativa. Se conserva el backend `xdg-desktop-portal-gnome` únicamente para ScreenCast.
- Se añadieron VLC y asociaciones de escritorio para formatos de video comunes.
- Kitty quedó como terminal por defecto de la sesión y para la acción de abrir terminal de Dolphin.
- Se habilitó el plugin Screen Recorder de Noctalia, se añadió `gpu-screen-recorder` y se asignó `Alt + Shift + S` para alternar grabación.
- Se usa el paquete `niri-git` de CachyOS para que soltar Super abra Overview de Niri; `Alt + Tab` cambia a la ventana enfocada anteriormente.
- Se conservó el diseño visual, los efectos y el espaciado existentes; no se cambió la presentación para priorizar rendimiento.
- El instalador y el desinstalador ahora respaldan y restauran `mimeapps.list` y la configuración del terminal.

## Actualización

Ejecuta `./install.sh` desde una sesión de usuario en CachyOS. Cierra sesión y vuelve a entrar en Niri para aplicar las configuraciones de sesión; reinicia para aplicar LightDM.
