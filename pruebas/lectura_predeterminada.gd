extends SceneTree
## Ejecutar con XDG_DATA_HOME temporal: simula instalación nueva y actualización real.
var fallos := 0

func comprobar(condicion: bool, texto: String) -> void:
	if not condicion:
		fallos += 1
	print("  ", "✔ " if condicion else "✘ ", texto)

func _initialize() -> void:
	call_deferred("probar")

func probar() -> void:
	var juego = root.get_node("Juego")
	comprobar(juego.leer_voz, "instalación nueva: lectura activada")
	var anterior := ConfigFile.new()
	anterior.set_value("ajustes", "leer_voz", false)
	anterior.set_value("ajustes", "vol_musica", 0.35)
	anterior.set_value("ajustes", "guia", false)
	anterior.save(juego.RUTA_AJUSTES)
	juego.cargar_ajustes()
	comprobar(juego.leer_voz, "actualización desde 0.11: lectura activada")
	comprobar(is_equal_approx(juego.vol_musica, 0.35) and not juego.guia, "conserva los demás ajustes")
	juego.leer_voz = false
	juego.guardar_ajustes()
	juego.leer_voz = true
	juego.cargar_ajustes()
	comprobar(not juego.leer_voz, "apagar lectura después de actualizar se respeta")
	juego.cargar_ajustes()
	comprobar(not juego.leer_voz, "la migración no se repite al reiniciar")
	print("LECTURA PREDETERMINADA: %d fallos" % fallos)
	quit(fallos)
