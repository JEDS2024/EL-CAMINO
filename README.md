# El Camino

Aventura 3D con estilo pixel art para celular (Android), hecha en **Godot 4.7**, basada en **historias reales de la Biblia**.
En cada capítulo juegas como su protagonista. Las decisiones hacen crecer la **fe, la esperanza, el amor y el perdón**,
pero nunca cambian lo que la Biblia cuenta.

## Qué tiene esta versión (0.9)

- **3D pixelado**: la escena se dibuja a 1/3 de la resolución y se agranda sin suavizar. Los personajes son modelos 3D de bloques con brazos y piernas animados.
- **Cámara en primera o tercera persona**: se elige al empezar y se cambia en cualquier momento (botón «Vista» o tecla C).
- **Controles táctiles**: joystick a la izquierda, deslizar a la derecha para mirar y botón de acción. En la PC: WASD para caminar; flechas, IJKL o arrastrar con el mouse (clic izquierdo o derecho) para mirar; E/Espacio para interactuar; Tab o B para la mochila; C para la vista y Esc para pausa.
- **Seis capítulos bíblicos**, en orden histórico:
  1. *Noé y el arca* (Génesis 6–9): construcción por planos, recogida de alimento, parejas y ciclo del diluvio.
  2. *José perdona a sus hermanos* (Génesis 43–45): sentar a los hermanos por edad (43:33), la copa de plata y el perdón.
  3. *Rut en el campo de Booz* (Rut 1–2): espigar tras los segadores y el efa de cebada (2:17).
  4. *David y Goliat* (1 Samuel 17): Eliab, Saúl, la armadura y las cinco piedras lisas (17:40).
  5. *Nehemías reconstruye el muro* (Nehemías 2–6): la inspección nocturna (2:13-15), Sanbalat y la obra con la espada en la mano (4:17).
  6. *El camino a Emaús* (Lucas 24:13-35): el forastero explica las Escrituras y se le reconoce al partir el pan.
- **Decisiones con consecuencias**: cambian diálogos, virtudes, luz y el final.
- **Secretos** detrás de arbustos falsos, **acertijos** de orden y **guardado automático**.

## Fase 2: arca y construcción por bloques

- El capítulo de Noé se juega antes de las cinco historias existentes. Sus partidas guardadas desplazan automáticamente los índices y conservan capítulos, estrellas, registros y marcas de introducción.
- El arca carga sus bloques estructurales fijos; completa los planos de costado, aposentos y brea con madera de gofer y brea que se extraen de montones.
- Guarda cuatro alimentos y recibe cuatro parejas de animales; ovejas, vacas, camellos y aves caminan a la entrada y desaparecen al llegar.
- Lluvia, subida y retirada del agua y arcoíris acompañan la secuencia narrada de Génesis 7–9. Música, lluvia y efectos son recursos originales.

## 0.9: voz natural, lenguaje claro y guía

- **Narración grabada con voz natural** (Kokoro-82M, voz Dora, sin internet) para todos los diálogos, misiones, versículos y preguntas. Se regenera con `herramientas/generar_voces.py`.
- **Diálogos en español actual**, fieles al sentido del versículo citado; solo el «versículo para recordar» queda literal.
- **Tarjeta «Nueva misión»** con instrucciones de cada objetivo, leídas en voz alta, y botón «?» para repetirlas.
- **Construcción guiada**: el rombo dorado señala el montón para picar o el bloque exacto que sigue; las siluetas laten y llevan cartel; las obras que aún no tocan se ven en gris.
- Arreglos: aldeanos que caminaban de espaldas, cuello de los personajes, luz del candil que quemaba al protagonista, silueta que vibraba y cámara pegada a la pared.

## Para toda la familia

- **Música original** para cada historia (arpa, flauta, laúd y tambor de marco) y efectos de sonido. Todo se genera con `herramientas/generar_audio.py`.
- **Guía visual**: un faro dorado marca el siguiente objetivo, y un «!» aparece sobre quien tiene algo nuevo que decir. Se puede apagar en Ajustes.
- **Leer en voz alta**: los diálogos, el versículo y las preguntas se leen con la voz del celular o de la PC, sin leer las referencias bíblicas.
- **Texto grande** opcional.
- **Repaso al final de cada historia**: un versículo para recordar y tres preguntas. Cada respuesta se explica con su cita, y valen hasta 3 estrellas.
- **Capítulos**: se puede volver a jugar cualquier historia ya desbloqueada. Al rejugar, sus virtudes y secretos no se duplican.
- **Celebraciones**: chispas al encender, recoger o resolver, y confeti al terminar un capítulo.

## Estilo Minecraft (fase 1)

- **Interfaz**: fuente pixelada (Pixelify Sans, licencia OFL), botones de piedra con relieve, paneles con bisel y portada con frase destacada.
- **HUD**: barra de 9 casillas con lo que recoges (las reliquias resaltadas), virtudes como "corazones", barra de luz como la de experiencia, mira en primera persona y botón de **Mochila** (Tab o B).
- **Mochila**: lo recogido en el capítulo, las reliquias de todo el viaje y los versículos aprendidos.
- **Ciclo de día y noche**: la hora avanza según cada relato. Rut espiga hasta la tarde, en Emaús anochece y Nehemías trabaja de noche.
- **Mundo vivo**: aldeanos con apariencia al azar que caminan (egipcios en Egipto), ovejas y palomas volando.

## Vida y animación (inspirado en «Actions & Stuff»)

- **Personajes animados**: respiran, cambian el peso de pierna, miran alrededor y **giran la cabeza hacia ti**. Gesticulan al hablar, se agachan al recoger, levantan el brazo al encender y saludan.
- **Movimiento fluido**: el jugador acelera y frena con suavidad, y los acompañantes caminan mirando hacia donde van.
- **Mundo que se mueve**: árboles, palmeras, arbustos y flores que se mecen con el viento (`shaders/vegetacion.gdshader`), agua que corre, lámparas que titilan y fogatas con chispas.
- **Escondites distintos**: un granero con pared falsa (`?`), un rincón cercado del campo, una cueva en los cerros (`!`), un rincón de la muralla y una cueva entre las rocas.
- **Minijuego de la honda** de David (1 Samuel 17:49): lanzar cuando la piedra pasa por la zona dorada.

## Mundo e inmersión

- **Cielo animado** (`shaders/cielo.gdshader`): sol o luna, estrellas que titilan de noche y nubes que avanzan.
- **Mapas naturales**: el Nilo y el mercado en Egipto, el campo de cebada y los pastos con ovejas en Belén, los dos montes y el arroyo del valle de Ela, Jerusalén amurallada de noche y el camino entre colinas hasta Emaús. Al fondo, montañas en el horizonte.
- **Sonido ambiente** por lugar (campo, ciudad, noche, atardecer) y partículas: polvo, polen y luciérnagas.
- **Mapa del camino** antes de cada historia: un mapa aproximado con Egipto, Belén, el valle de Ela, Jerusalén y Emaús.
- **Lectura cómoda**: letras grandes, la cita bíblica en su propia línea, la narración en otro color y el objetivo sobre un fondo.

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
JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64 ANDROID_HOME=~/Android/Sdk ~/Juegos/herramientas/godot --headless --path . --export-debug "Android" ../builds/ElCamino-v0.9.apk
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
- `capturas_menus.tscn` guarda capturas de menús, guía y repaso.
- `capturas.tscn` guarda imágenes en `~/.local/share/godot/app_userdata/El Camino/capturas/`.

## Estructura

| Carpeta | Contenido |
|---|---|
| `datos/capitulos/` | La historia y los niveles en JSON (**aquí se crean capítulos nuevos**, ver `datos/LEEME_CAPITULOS.md`) |
| `scripts/juego.gd` | Estado global: virtudes, luz, flags, guardado, condiciones y efectos |
| `scripts/main.gd` | Flujo del juego, menús, repaso con preguntas, mapa de capítulos, ajustes, vista pixelada |
| `scripts/sonido.gd` | Música con fundido y efectos (autoload `Sonido`) |
| `scripts/faro.gd` | Haz de luz que marca el objetivo |
| `scripts/nivel.gd` | Construye el mundo 3D a partir del mapa de texto |
| `scripts/entidad.gd` | Personajes, lámparas, objetos, letreros, pozo y salidas |
| `scripts/jugador.gd` | Movimiento y cámara 1ª/3ª persona |
| `scripts/personaje_3d.gd` | Modelos 3D de bloques del elenco bíblico (tocado egipcio, armaduras, Goliat gigante…) y su animación |
| `scripts/ui/` | Diálogos, HUD, controles táctiles y tema visual |
| `assets/` | Arte pixel original (regenerable con `herramientas/generar_arte.py`) |

## Créditos

- Arte pixel: generado por código para este proyecto (`herramientas/generar_arte.py`).
- Fuentes: Fira Sans Compressed y Pixelify Sans (SIL Open Font License 1.1).
- Citas bíblicas: adaptadas de la Reina-Valera 1909 (dominio público).
