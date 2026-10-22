# Guía para agentes (Claude Code y Codex)

Juego Godot 4.7 (GDScript, renderer Compatibility) para Android, orientación horizontal. Todo en español: código, comentarios, textos y commits.

- Godot: `~/Juegos/herramientas/godot` (para exportar a Android: `JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64 ANDROID_HOME=~/Android/Sdk`).
- **Las historias deben ser bíblicas y fieles al texto.** Lo que dice un personaje bíblico sale de la Escritura y lleva referencia (libro capítulo:versículo). Lo demás va como narración (`quien` vacío). No se inventan palabras de Jesús ni de Dios. Las decisiones no cambian los hechos bíblicos.
- La historia y los niveles viven en `datos/capitulos/*.json` (formato en `datos/LEEME_CAPITULOS.md`). El contenido nuevo va ahí, no en código.
- Casi toda la escena se arma por código (`scripts/main.gd`, `scripts/nivel.gd`); no hay escenas `.tscn` complejas.
- Interfaz: usa `set_anchors_and_offsets_preset` o `Tema.anclar(...)`. Cambiar solo `anchor_*` deja los controles aplastados.
- Diálogos y botones deben verse bien en 1280×720 y en celulares 20:9 (aspecto `expand`).

## Antes de dar algo por terminado

```bash
python3 herramientas/validar_capitulos.py
~/Juegos/herramientas/godot --headless --path . res://pruebas/recorrido.tscn   # debe decir RESULTADO: TODO BIEN
```

Si agregas o cambias un capítulo, actualiza `pruebas/recorrido.gd` para que lo recorra.

## Reparto de trabajo sugerido

Uno programa y el otro revisa el diff (`codex review` o una revisión de Claude) antes del commit.
No trabajen los dos sobre los mismos archivos al mismo tiempo; usen ramas o worktrees separados.
