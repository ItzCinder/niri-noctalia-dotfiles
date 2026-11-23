# Noria

**Noria** es una configuración personal de escritorio para CachyOS, basada en Niri y Noctalia. También configura Kitty y Dolphin, aplica una paleta oscura violeta y conserva GNOME como sesión alternativa.

> **Versión:** `0.1-alpha`. Primera versión alpha: está en pruebas y puede cambiar mientras se sigue ajustando la instalación y la configuración.

> **Nota de desarrollo:** la mayor parte de este proyecto fue creada con *vibecoding*: desarrollo iterativo asistido por modelos de inteligencia artificial a partir de instrucciones y revisiones humanas. Las decisiones, pruebas en el equipo y ajustes finales siguen siendo responsabilidad de quien mantiene el proyecto.

## Características

- **Niri:** configuración modular para animaciones, pantalla, input, layout, reglas de ventanas, atajos y aplicaciones de inicio.
- **Enfoque del puntero:** no usa `focus-follows-mouse`; mover el puntero entre ventanas no cambia el foco automáticamente.
- **Noctalia v5:** barra, paneles, tema oscuro personalizado, paleta actual, transparencias y wallpaper. El plugin Niri Displays permite cambiar resolución y frecuencia por monitor; se abre con `Mod+Shift+M`.
- **Selector de archivos:** configura `xdg-desktop-portal` para preferir el backend KDE de Dolphin y usar GTK como alternativa. Mantiene el tema Breeze y la paleta Noctalia en las aplicaciones Qt y en el portal KDE.
- **Dolphin y KDE:** aplica la paleta oscura `noctalia`, iconos Breeze oscuros y el estilo Breeze. Dolphin conserva visible su barra de menú; el selector KDE usa vista de detalles, panel de lugares más ancho, ruta completa y previsualización.
- **Kitty:** instala la configuración y el tema Dracula que se usan actualmente, con fondo translúcido y padding.
- **Fastfetch:** instala Fastfetch con el logo ASCII de Arch y el resumen de sistema personalizado.
- **Cursor:** configura el cursor Windows 10 que usa Niri. El instalador lo obtiene desde AUR mediante `yay`.
- **Inicio de sesión:** instala LightDM, el greeter WebKit2 y una variante de Glorious con los colores de la paleta Noctalia y el mismo wallpaper que usa Niri. Conserva el resto de la configuración del greeter, activa depuración y detección de errores, y configura el tema para el próximo arranque. Los paquetes del gestor anterior se conservan.
- **Dependencias de sesión:** instala Niri, Noctalia, Dolphin, el portal de escritorio y sus backends KDE/GTK, soporte Wayland para Qt y utilidades de multimedia, brillo y clipboard.
- **Instalador actualizable:** al volver a ejecutar `install.sh`, actualiza las configuraciones, conserva los respaldos de la primera instalación y registra los paquetes agregados en cada ejecución.
- **Desinstalador:** guarda una copia de las configuraciones instaladas, restaura las configuraciones anteriores y propone quitar los paquetes que incorporó el instalador.

## Requisitos

- CachyOS.
- Ejecutar los scripts como usuario normal, sin `sudo`.
- `yay` instalado para obtener `windows-10-cursor` y el tema Glorious desde AUR.
- Conexión a Internet y `sudo` disponible para instalar paquetes con `pacman`.

## Rendimiento y compatibilidad

La referencia de rendimiento es un Intel Core i3-6100, Intel HD Graphics 530, Radeon HD 6670 y 16 GiB de RAM. Niri conserva el desenfoque con un solo pase y las animaciones usan una tolerancia de asentamiento menos estricta. Kitty mantiene sus opciones actuales de transparencia y padding; su frecuencia de redibujado conserva el valor equilibrado del programa. Se mantienen la transparencia, el desenfoque, las animaciones y la composición visual.

No se fija una resolución, frecuencia de refresco, nombre de monitor, GPU ni ruta de inicio de usuario. Niri deja la salida de ejemplo comentada; el instalador guarda el wallpaper en la carpeta Imágenes que informa XDG y actualiza la ruta de Noctalia. Niri Displays abre un panel independiente para cambiar resolución y frecuencia por monitor durante la sesión; Niri no conserva esos cambios temporales al reiniciar. El Monitor integrado de Noctalia 5.6 solo expone controles de brillo, así que el acceso al panel se hace con `Mod+Shift+M`. Para establecer valores permanentes, configura la salida correspondiente en `config/niri/cfg/display.kdl`. El instalador sigue dirigido a CachyOS y requiere una GPU con aceleración gráfica compatible con Niri/Wayland.

## Binds

`Mod` es la tecla Super (Windows). Estos son los atajos principales definidos en `config/niri/cfg/keybinds.kdl`:

| Atajo | Acción |
| --- | --- |
| `Mod + Enter` | Abrir Kitty |
| `Mod + B` | Abrir Firefox |
| `Mod + E` | Abrir Dolphin |
| `Mod + S` | Abrir el Centro de control de Noctalia |
| `Mod + Shift + S` | Abrir los ajustes de Noctalia |
| `Mod + Shift + Enter` | Abrir el selector de wallpaper |
| `Mod + Shift + M` | Abrir Niri Displays para cambiar resolución y frecuencia por monitor |
| `Mod + Q` | Cerrar la ventana enfocada |
| `Mod + H/J/K/L` | Mover el foco entre ventanas y columnas |
| `Mod + 1` … `Mod + 9` | Cambiar al espacio de trabajo indicado |
| `Mod + F` | Maximizar la columna enfocada |
| `Mod + Shift + F` | Alternar pantalla completa |
| `Mod + Tab` | Volver al espacio de trabajo anterior |
| `Print` | Captura de región con anotación |
| `Shift + Print` | Captura de pantalla completa con anotación |
| Teclas multimedia | Controlar volumen, brillo y reproducción/pausa |

La lista completa, incluidos los atajos para mover ventanas entre monitores y espacios de trabajo, está en `config/niri/cfg/keybinds.kdl`. Niri también muestra el resumen de atajos con `Mod + Shift + Esc`.

## Instalar o actualizar

Desde la carpeta del proyecto, ejecuta:

```bash
./install.sh
```

En la primera instalación, el script respalda las configuraciones que ya existan en `~/.config`, instala las dependencias y copia los archivos del proyecto. Si ya existe el marcador `~/.local/state/niri-noctalia-dotfiles/installed`, el mismo comando funciona como actualizador: reemplaza los archivos administrados por el proyecto y conserva los respaldos originales.

Si el wallpaper del proyecto ya existe en la carpeta `Noctalia` dentro de Imágenes y fue modificado, el instalador lo conserva durante una actualización. Después de instalar o actualizar, reinicia el equipo para que LightDM tome el lugar del gestor anterior. En la pantalla de inicio, elige **Niri** como sesión. GNOME permanece disponible como sesión alternativa.

## Demostración

La carpeta `assets/demo/` está preparada para el video de demostración. Cuando esté listo, guárdalo como [`video.mp4`](assets/demo/video.mp4).

## Desinstalar

Desde la carpeta del proyecto, ejecuta:

```bash
./uninstall.sh
```

El desinstalador restaura las configuraciones anteriores y la selección del gestor de inicio guardada antes de instalar LightDM. Reinicia para aplicar esa selección. La configuración que estaba activa justo antes de desinstalar se conserva en `~/.local/state/niri-noctalia-dotfiles/uninstall-saved`; los respaldos de la primera instalación permanecen en `~/.local/state/niri-noctalia-dotfiles/backup`. El script solicita confirmación de `pacman` antes de quitar paquetes agregados por el instalador.

## Estructura

```text
.
├── assets/
│   └── demo/
│       └── (video.mp4 se añadirá aquí)
└── config/
    ├── dolphinrc
    ├── environment.d/90-kde-qt.conf
    ├── fastfetch/
    │   ├── arch.txt
    │   └── config.jsonc
    ├── kdeglobals
    ├── kitty/
    │   ├── current-theme.conf
    │   └── kitty.conf
    ├── niri/
    │   ├── config.kdl
    │   └── cfg/
    ├── noctalia/
    │   ├── BlueDusk.json
    │   ├── bar.toml
    │   └── config.toml
    ├── wallpaper/
    └── xdg-desktop-portal/niri-portals.conf
```

`install.sh` instala y actualiza la configuración. `uninstall.sh` restaura los respaldos y retira los archivos instalados.

## Notas

- La salida de pantalla de ejemplo permanece comentada en `config/niri/cfg/display.kdl`; ajusta ese archivo si necesitas fijar resolución o escala.
- Si Noctalia no encuentra el wallpaper, revisa que la carpeta `Noctalia` dentro de Imágenes exista y que `config/noctalia/config.toml` apunte a ese directorio.
