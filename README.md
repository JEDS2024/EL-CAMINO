# El Camino

Aventura 3D con estilo pixel art para celular (Android), hecha en **Godot 4.7**, basada en **historias reales de la Biblia**.
En cada capítulo juegas como su protagonista. Las decisiones hacen crecer la **fe, la esperanza, el amor y el perdón**,
pero nunca cambian lo que la Biblia cuenta.

## Qué tiene esta versión (0.3)

- **3D pixelado**: la escena se dibuja a 1/3 de la resolución y se agranda sin suavizar. Los personajes son modelos 3D de bloques con brazos y piernas animados.
- **Cámara en primera o tercera persona**: se elige al empezar y se cambia en cualquier momento (botón «Vista» o tecla C).
- **Controles táctiles**: joystick a la izquierda, deslizar a la derecha para mirar y botón de acción. En la PC: WASD para caminar; flechas, IJKL o arrastrar con el mouse (clic izquierdo o derecho) para mirar; E/Espacio para interactuar; C para la vista y Esc para pausa.
- **Cinco capítulos bíblicos**, en orden histórico:
  1. *José perdona a sus hermanos* (Génesis 43–45): sentar a los hermanos por edad (43:33), la copa de plata y el perdón.
  2. *Rut en el campo de Booz* (Rut 1–2): espigar tras los segadores y el efa de cebada (2:17).
  3. *David y Goliat* (1 Samuel 17): Eliab, Saúl, la armadura y las cinco piedras lisas (17:40).
  4. *Nehemías reconstruye el muro* (Nehemías 2–6): la inspección nocturna (2:13-15), Sanbalat y la obra con la espada en la mano (4:17).
  5. *El camino a Emaús* (Lucas 24:13-35): el forastero explica las Escrituras y se le reconoce al partir el pan.
- **Decisiones con consecuencias**: cambian diálogos, virtudes, luz y el final.
- **Secretos** detrás de arbustos falsos, **acertijos** de orden y **guardado automático**.

## Fidelidad bíblica

- Lo que dicen los personajes bíblicos sigue el texto, y cada línea lleva su referencia entre paréntesis.
- Las citas son adaptaciones de la Reina-Valera 1909, que es de dominio público. Revísalas con tu Biblia.
- Lo que no está en la Biblia se cuenta como **narración** y nunca se pone en boca de un personaje bíblico.
- Las decisiones del jugador cambian sus virtudes y algunas reflexiones, no los hechos.

## Cómo abrirlo

```bash
~/Juegos/herramientas/godot-lanzador.sh
```

Importa la carpeta `LUMBRAL` (el nombre de la carpeta no importa) y presiona F5. El APK de prueba se exporta desde Proyecto → Exportar → Android, o así:

```bash
JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64 ANDROID_HOME=~/Android/Sdk ~/Juegos/herramientas/godot --headless --path . --export-debug "Android" ../builds/ElCamino-v0.3.apk
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
| `scripts/personaje_3d.gd` | Modelos 3D de bloques del elenco bíblico (tocado egipcio, armaduras, Goliat gigante…) y su animación |
| `scripts/ui/` | Diálogos, HUD, controles táctiles y tema visual |
| `assets/` | Arte pixel original (regenerable con `herramientas/generar_arte.py`) |

## Créditos

- Arte pixel: generado por código para este proyecto (`herramientas/generar_arte.py`).
- Fuente: Fira Sans Compressed (SIL Open Font License 1.1).
- Citas bíblicas: adaptadas de la Reina-Valera 1909 (dominio público).
