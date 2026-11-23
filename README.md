# Niri + Noctalia — CachyOS

Dotfiles personales para una sesión Wayland con Niri y Noctalia en CachyOS. El conjunto también configura Kitty y Dolphin, aplica la paleta oscura violeta actual y conserva GNOME como sesión alternativa.

> **Nota de desarrollo:** la mayor parte de este proyecto fue creada con *vibecoding*: desarrollo iterativo asistido por modelos de inteligencia artificial a partir de instrucciones y revisiones humanas. Las decisiones, pruebas en el equipo y ajustes finales siguen siendo responsabilidad de quien mantiene el proyecto.

## Características

- **Niri:** configuración modular para animaciones, pantalla, input, layout, reglas de ventanas, atajos y aplicaciones de inicio.
- **Enfoque del puntero:** no usa `focus-follows-mouse`; mover el puntero entre ventanas no cambia el foco automáticamente.
- **Noctalia v5:** barra, paneles, tema oscuro personalizado, paleta actual, transparencias y wallpaper.
- **Dolphin y KDE:** incluye `dolphinrc` y `kdeglobals` con los colores oscuros actuales para que Dolphin y sus diálogos no aparezcan con fondo blanco.
- **Kitty:** terminal con paleta, fondo translúcido y padding.
- **Cursor:** configura el cursor Windows 10 que usa Niri. El instalador lo obtiene desde AUR mediante `yay`.
- **Tema de inicio de sesión:** instala el tema Glorious para LightDM. No cambia el gestor de inicio de sesión que ya usa el sistema.
- **Dependencias de sesión:** instala Niri, Noctalia, Dolphin, portales, soporte Wayland para Qt y utilidades de multimedia, brillo y clipboard.
- **Instalador actualizable:** al volver a ejecutar `install.sh`, actualiza las configuraciones, conserva los respaldos de la primera instalación y registra los paquetes agregados en cada ejecución.
- **Desinstalador:** guarda una copia de las configuraciones instaladas, restaura las configuraciones anteriores y propone quitar los paquetes que incorporó el instalador.

## Requisitos

- CachyOS.
- Ejecutar los scripts como usuario normal, sin `sudo`.
- `yay` instalado para obtener `windows-10-cursor` desde AUR.
- Conexión a Internet y `sudo` disponible para instalar paquetes con `pacman`.

## Instalar o actualizar

Desde la carpeta del proyecto, ejecuta:

```bash
./install.sh
```

En la primera instalación, el script respalda las configuraciones que ya existan en `~/.config`, instala las dependencias y copia los archivos del proyecto. Si ya existe el marcador `~/.local/state/niri-noctalia-dotfiles/installed`, el mismo comando funciona como actualizador: reemplaza los archivos administrados por el proyecto y conserva los respaldos originales.

Si el wallpaper del proyecto ya existe en `~/Pictures/Noctalia` y fue modificado, el instalador lo conserva durante una actualización. Después de instalar o actualizar, cierra sesión y entra en **Niri** para aplicar toda la configuración. GNOME permanece disponible como sesión alternativa.

## Desinstalar

Desde la carpeta del proyecto, ejecuta:

```bash
./uninstall.sh
```

El desinstalador restaura las configuraciones anteriores. La configuración que estaba activa justo antes de desinstalar se conserva en `~/.local/state/niri-noctalia-dotfiles/uninstall-saved`; los respaldos de la primera instalación permanecen en `~/.local/state/niri-noctalia-dotfiles/backup`. El script solicita confirmación de `pacman` antes de quitar paquetes agregados por el instalador.

## Estructura

```text
config/
├── dolphinrc
├── kdeglobals
├── kitty/kitty.conf
├── niri/
│   ├── config.kdl
│   └── cfg/
├── noctalia/
│   ├── BlueDusk.json
│   ├── bar.toml
│   └── config.toml
└── wallpaper/
```

`install.sh` instala y actualiza la configuración. `uninstall.sh` restaura los respaldos y retira los archivos instalados.

## Notas

- La salida de pantalla de ejemplo permanece comentada en `config/niri/cfg/display.kdl`; ajusta ese archivo si necesitas fijar resolución o escala.
- Si Noctalia no encuentra el wallpaper, revisa que `~/Pictures/Noctalia` exista y que `config/noctalia/config.toml` apunte a ese directorio.
