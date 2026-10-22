# Cómo crear capítulos de El Camino

Cada capítulo es un archivo JSON en `datos/capitulos/`. **Regla de oro:** son historias reales de la Biblia.
Lo que dice un personaje bíblico debe salir del texto, con su referencia al final, por ejemplo «(Rut 2:12)».
Todo lo demás va como narración, con `quien` vacío. Las decisiones del jugador nunca cambian lo que ocurrió.

Para agregar uno nuevo:

1. Copia un capítulo existente y cámbiale el nombre.
2. Agrégalo a la lista `CAPITULOS` en `scripts/juego.gd`, en el orden en que se juega.
3. Revísalo con `python3 herramientas/validar_capitulos.py`.

## Partes del capítulo

| Clave | Para qué sirve |
|---|---|
| `titulo`, `subtitulo` | Se muestran al entrar al capítulo (pon la referencia en el subtítulo) |
| `protagonista` | `{"nombre": "Rut", "modelo": "rut"}`: con quién se juega |
| `retratos` | Nombre → modelo para quien habla sin estar en el mapa (p. ej. `"Jacob": "jacob"`) |
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
| `;` | Campo de cebada |
| `#` | Muro de piedra (alto) |
| `H` | Casa (pared y tejado) |
| `~` | Agua (no se puede pisar) |
| `T` | Árbol |
| `B` | Arbusto (sólido) |
| `b` | **Arbusto falso**: se puede atravesar; sirve para esconder secretos |
| `R` | Roca |
| `F` | Valla de madera |
| `A` | Tienda de campaña |
| `P` | Donde empieza Ezra |

Cualquier otra letra o número que pongas en la `leyenda` se vuelve una entidad.
Dentro de la leyenda, `"suelo"` define qué suelo hay debajo de esa entidad.

## Entidades de la leyenda

Opciones que sirven para cualquier entidad:
- `"aparece_si"`: solo existe cuando se cumplen esas condiciones (p. ej. Booz llega después).
- `"etiqueta"`: nombre flotante.
- `"accion"`: texto del botón, por ejemplo «Sentar» o «Reparar».


- **npc**: `{"tipo":"npc","nombre":"Booz","modelo":"booz","dialogos":[{"si":[...],"id":"..."}, {"id":"..."}]}`
  Usa el primer diálogo cuya condición `si` se cumpla. Con `"seguir": true` acompaña al protagonista (opcional: `"seguir_si"`).
  Modelos (en `scripts/personaje_3d.gd`): jose, mayordomo, juda, benjamin, ruben, simeon, levi, jacob, rut, noemi, booz, criado,
  segador, david, eliab, saul, soldado, goliat, escudero, nehemias, eliasib, sanbalat, salum, hija_salum, obrero, cleofas,
  companero, forastero.
- **lampara**: `{"tipo":"lampara","acertijo":"mesa","simbolo":"ruben","etiqueta":"Asiento de Rubén","requiere":[...],"dialogo_frio":"...","dialogo":"..."}`
  Sirve para cualquier acertijo de orden. `simbolo` es su identificador dentro del orden. Si es fe, esperanza, amor, perdon o luz, se muestra su ícono.
  `dialogo` (opcional) se muestra al encenderla en el orden correcto, por ejemplo para mostrar un pasaje.
- **letrero**: `{"tipo":"letrero","dialogo":"..."}`
- **objeto**: `{"tipo":"objeto","id":"hilo1","icono":"hilo","efectos":{...},"dialogo":"..."}`
  Íconos: espiga, piedra, copa, pergamino, arpa, hilo, pieza, pan, fe, esperanza, amor, perdon, luz. Con `"secreto":1` en efectos cuenta como secreto.
- **mecanismo**: `"modelo"` puede ser `pozo`, `brecha` (escombros que se vuelven muro) o `monton` (gavillas). `{"tipo":"mecanismo","requiere":[...],"flag_activo":"...","efectos":{...},"dialogo_listo":"...","dialogo_falta":"...","dialogo_hecho":"..."}`
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
"sumar":{"piezas":1}, "objeto":"pan", "secreto":1, "aviso":"Texto en pantalla", "fin_capitulo":true}`

`fin_capitulo` termina el capítulo cuando se cierra ese diálogo (como la victoria de David).

**Consejo:** los efectos que suben virtudes ponlos en diálogos que solo se vean una vez (controlados con flags), para que el jugador no pueda repetirlos.
