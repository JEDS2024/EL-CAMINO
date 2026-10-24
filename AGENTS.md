# Guía para agentes (Claude Code y Codex)

Juego Godot 4.7 (GDScript, renderer Compatibility) para Android, orientación horizontal. Todo en español: código, comentarios, textos y commits.

- Godot: `~/Juegos/herramientas/godot` (para exportar a Android: `JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64 ANDROID_HOME=~/Android/Sdk`).
- **Las historias deben ser bíblicas y fieles al texto, pero en español actual y claro** (que lo entienda un niño). Lo que dice un personaje bíblico sale de la Escritura y lleva referencia (libro capítulo:versículo), contado con palabras de hoy (tú/ustedes, nada de «vosotros», «hízolo», «embetunarás»), sin agregar ni quitar ideas. Lo demás va como narración (`quien` vacío). No se inventan palabras de Jesús ni de Dios. Las decisiones no cambian los hechos bíblicos. Solo el «versículo para recordar» del repaso queda literal (Reina-Valera 1909).
- En capítulos con bloques, cada etapa es un objetivo propio con `marca_plano`: el faro señala el próximo bloque o, si no tienes material, el montón para picarlo.
- La historia y los niveles viven en `datos/capitulos/*.json` (formato en `datos/LEEME_CAPITULOS.md`). El contenido nuevo va ahí, no en código.
- Casi toda la escena se arma por código (`scripts/main.gd`, `scripts/nivel.gd`); no hay escenas `.tscn` complejas.
- Interfaz: usa `set_anchors_and_offsets_preset` o `Tema.anclar(...)`. Cambiar solo `anchor_*` deja los controles aplastados.
- Diálogos y botones deben verse bien en 1280×720 y en celulares 20:9 (aspecto `expand`).

- Pensado para niños y adultos: textos claros, guía visual activable, lectura en voz alta y repaso con preguntas. Cada pregunta nueva necesita una explicación con cita bíblica.
- La lectura en voz alta usa narración grabada con voz neuronal (Kokoro-82M, voz `ef_dora`, licencia Apache 2.0) en `assets/voz/<sha1 del texto>.ogg`. Si cambias o agregas textos, corre `~/Juegos/herramientas/voces/kokoro/.venv/bin/python herramientas/generar_voces.py` (graba lo nuevo y borra lo que sobra) y luego `godot --headless --path . -s res://pruebas/voces.gd` (debe decir 0 sin grabación). Lo que no tenga grabación cae en la voz del sistema, que suena robótica.
- La música y los efectos se regeneran con `herramientas/generar_audio.py`, y el arte con `herramientas/generar_arte.py`. No agregues recursos con derechos de terceros.

## Capítulo de Noé y construcción por planos (0.8)

- `cap0_noe.json` precede a los cinco capítulos anteriores; `Juego._migrar_indices_a_noe` cambia índices de guardado de versión 1 a 2. Conserva esa migración idempotente.
- Personajes nuevos: noe, mujer_noe, sem, cam, jafet. Las parejas de animales usan especie en `Oveja`; no inventar diálogo de personajes bíblicos.
- `estructuras` son bloques fijos; `planos` se completan con inventario y `monton` es una fuente de materiales. `pareja` se entrega una vez, suma el contador y camina a `destino`.
- Los efectos `clima` manejan lluvia, diluvio, retirada de agua y arcoíris. Los versículos del epílogo deben permanecer en orden y como narración con referencia.

## Antes de dar algo por terminado

```bash
python3 herramientas/validar_capitulos.py
~/Juegos/herramientas/godot --headless --path . res://pruebas/recorrido.tscn   # debe decir RESULTADO: TODO BIEN
~/Juegos/herramientas/godot --headless --path . res://pruebas/caminar.tscn     # debe decir CAMINAR: 0 muestras hacia atrás
~/Juegos/herramientas/godot --headless --path . -s res://pruebas/voces.gd      # debe decir 0 sin grabación
```

Si agregas o cambias un capítulo, actualiza `pruebas/recorrido.gd` para que lo recorra.

## Reparto de trabajo sugerido

Uno programa y el otro revisa el diff (`codex review` o una revisión de Claude) antes del commit.
No trabajen los dos sobre los mismos archivos al mismo tiempo; usen ramas o worktrees separados.
