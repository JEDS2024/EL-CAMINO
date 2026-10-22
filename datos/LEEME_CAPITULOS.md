# Cómo crear capítulos de El Camino

Cada capítulo es un archivo JSON en `datos/capitulos/`. Para agregar uno nuevo:

1. Copia un capítulo existente y cámbiale el nombre.
2. Agrégalo a la lista `CAPITULOS` en `scripts/juego.gd`, en el orden en que se juega.
3. Revísalo con `python3 herramientas/validar_capitulos.py`.

## Partes del capítulo

| Clave | Para qué sirve |
|---|---|
| `titulo`, `subtitulo` | Se muestran al entrar al capítulo |
| `suelo` | Suelo por defecto (ver tabla de caracteres) |
| `mirar_inicio` | Hacia dónde mira Ezra al empezar, en grados (0 = norte) |
| `ambiente` | Colores del cielo, luz ambiente, niebla y "sol" (o luna) |
| `mapa` | La cuadrícula del nivel; cada carácter es una celda de 2×2 metros |
| `leyenda` | Convierte letras del mapa en personajes, lámparas, objetos, etc. |
| `acertijos` | Grupos de lámparas que se encienden en un orden |
| `objetivos` | Lo que se muestra arriba; aparece el primero que no esté `hecho` |
| `intro`, `epilogo` | Diálogos al entrar y al terminar el capítulo |
| `dialogos` | Todas las conversaciones, por nombre |
| `final` | Solo en el último capítulo: el desenlace según la virtud más alta |

## Caracteres del mapa

| Carácter | Qué es |
|---|---|
| `.` | Pasto |
| `=` | Camino de tierra |
| `,` | Arena |
| `:` | Adoquines |
| `_` | Madera |
| `%` | Piedra oscura |
| `#` | Muro de piedra (alto) |
| `H` | Casa (pared y tejado) |
| `~` | Agua (no se puede pisar) |
| `T` | Árbol |
| `B` | Arbusto (sólido) |
| `b` | **Arbusto falso**: se puede atravesar; sirve para esconder secretos |
| `R` | Roca |
| `F` | Valla de madera |
| `P` | Donde empieza Ezra |

Cualquier otra letra o número que pongas en la `leyenda` se vuelve una entidad.
Dentro de la leyenda, `"suelo"` define qué suelo hay debajo de esa entidad.

## Entidades de la leyenda

- **npc**: `{"tipo":"npc","nombre":"Marta","sprite":"marta","dialogos":[{"si":[...],"id":"..."}, {"id":"..."}]}`
  Usa el primer diálogo cuya condición `si` se cumpla. Con `"seguir": true` acompaña a Ezra (opcional: `"seguir_si"`).
  Sprites disponibles: ezra, caminante, marta, simeon, tomas, lia, noemi, jared, abuela, vigia.
- **lampara**: `{"tipo":"lampara","acertijo":"plaza","simbolo":"fe","requiere":[...],"dialogo_frio":"..."}`
  Símbolos: fe, esperanza, amor, perdon, luz.
- **letrero**: `{"tipo":"letrero","dialogo":"..."}`
- **objeto**: `{"tipo":"objeto","id":"hilo1","icono":"hilo","efectos":{...},"dialogo":"..."}`
  Íconos: hilo, pieza, pan, fe, esperanza, amor, perdon, luz. Con `"secreto":1` en efectos cuenta como secreto.
- **mecanismo**: el pozo. `{"tipo":"mecanismo","requiere":[...],"flag_activo":"...","efectos":{...},"dialogo_listo":"...","dialogo_falta":"...","dialogo_hecho":"..."}`
- **salida**: `{"tipo":"salida","requiere":[...],"dialogo_cerrado":"..."}`. Al cruzarla termina el capítulo.

## Diálogos

Cada diálogo es una lista de líneas:

```json
{"quien": "Marta", "texto": "Hola", "si": ["flag:algo"], "efectos": {"amor": 1},
 "opciones": [{"texto": "Te ayudo", "efectos": {"amor": 1}, "siguiente": "otro_dialogo"}]}
```

- `quien` vacío = narrador. El retrato se toma del npc con ese nombre.
- `si`: la línea (u opción) solo aparece si se cumplen las condiciones.
- Una opción sin `siguiente` continúa con la línea que sigue.

## Condiciones (`si`, `requiere`, `hecho`)

Listas de textos, y todos se tienen que cumplir. Para negar uno, ponle `!` delante:

- `"flag:nombre"`: la marca existe.
- `"obj:hilo1"`: Ezra tiene ese objeto.
- `"cont:piezas>=3"`: contador.
- `"amor>=2"`: virtud.
- `"luz>=50"`: luz del candil.

## Efectos

`{"fe":1, "esperanza":1, "amor":1, "perdon":1, "luz":10, "flag":"x" o ["x","y"], "quitar_flag":"x",
"sumar":{"piezas":1}, "objeto":"pan", "secreto":1, "aviso":"Texto en pantalla"}`

**Consejo:** los efectos que suben virtudes ponlos en diálogos que solo se vean una vez (controlados con flags), para que el jugador no pueda repetirlos.
