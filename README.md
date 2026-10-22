# El Camino

Aventura cristiana en 3D con estilo pixel art para celular (Android), hecha en **Godot 4.7**.
Ezra recorre un valle donde las luces se apagaron, acompañado por un misterioso Caminante.
Las decisiones hacen crecer la **fe, la esperanza, el amor y el perdón**, y con ellas la luz de su candil.

## Qué tiene esta versión (0.2)

- **3D pixelado**: la escena se dibuja a 1/3 de la resolución y se agranda sin suavizar. Los personajes son modelos 3D de bloques con brazos y piernas animados.
- **Cámara en primera o tercera persona**: se elige al empezar y se cambia en cualquier momento (botón «Vista» o tecla C).
- **Controles táctiles**: joystick a la izquierda, deslizar a la derecha para mirar y botón de acción. En la PC: WASD para caminar; flechas, IJKL o arrastrar con el mouse (clic izquierdo o derecho) para mirar; E/Espacio para interactuar; C para la vista y Esc para pausa.
- **Tres capítulos jugables**:
  1. *Aldea de Brasa*: tres lámparas, un pan robado y un incrédulo.
  2. *Pozo Hondo*: un pozo seco y una reconciliación pendiente.
  3. *Ruinas de Peniel*: un acertijo de cuatro lámparas y el camino a Emaús.
- **Decisiones con consecuencias**: cambian diálogos, virtudes, luz y el final.
- **Secretos** detrás de arbustos falsos, **acertijos** de orden y **guardado automático**.

## Cómo abrirlo

```bash
~/Juegos/herramientas/godot-lanzador.sh
```

Importa la carpeta `LUMBRAL` (el nombre de la carpeta no importa) y presiona F5. El APK de prueba se exporta desde Proyecto → Exportar → Android, o así:

```bash
JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64 ANDROID_HOME=~/Android/Sdk ~/Juegos/herramientas/godot --headless --path . --export-debug "Android" ../builds/ElCamino-v0.2.apk
```

## Pruebas

```bash
python3 herramientas/validar_capitulos.py
~/Juegos/herramientas/godot --headless --path . res://pruebas/recorrido.tscn
~/Juegos/herramientas/godot --headless --path . res://pruebas/camara.tscn
~/Juegos/herramientas/godot --path . res://pruebas/capturas.tscn
```

- `validar_capitulos.py` revisa los JSON.
- `recorrido.tscn` juega los 3 capítulos solo y debe terminar en `RESULTADO: TODO BIEN`.
- `camara.tscn` simula toque, mouse, flechas y joystick y muestra cuánto gira la cámara.
- `capturas.tscn` guarda imágenes en `~/.local/share/godot/app_userdata/El Camino/capturas/`.

## Estructura

| Carpeta | Contenido |
|---|---|
| `datos/capitulos/` | La historia y los niveles en JSON (**aquí se crean capítulos nuevos**, ver `datos/LEEME_CAPITULOS.md`) |
| `scripts/juego.gd` | Estado global: virtudes, luz, flags, guardado, condiciones y efectos |
| `scripts/main.gd` | Flujo del juego, menús, vista pixelada |
| `scripts/nivel.gd` | Construye el mundo 3D a partir del mapa de texto |
| `scripts/entidad.gd` | Personajes, lámparas, objetos, letreros, pozo y salidas |
| `scripts/jugador.gd` | Movimiento y cámara 1ª/3ª persona |
| `scripts/personaje_3d.gd` | Modelos 3D de bloques de los personajes y su animación |
| `scripts/ui/` | Diálogos, HUD, controles táctiles y tema visual |
| `assets/` | Arte pixel original (regenerable con `herramientas/generar_arte.py`) |

## Créditos

- Arte pixel: generado por código para este proyecto (`herramientas/generar_arte.py`).
- Fuente: Fira Sans Compressed (SIL Open Font License 1.1).
- Citas bíblicas parafraseadas de 1 Corintios 13:13, Juan 4:13-14 y Lucas 24:32.
