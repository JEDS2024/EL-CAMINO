extends Node
## Capturas de menús, guía y repaso (necesita ventana). Guarda en user://capturas/menus_*.png

var main: Node


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://capturas"))
	Juego.nueva_partida(false)
	Juego.capitulo_max = 2
	Juego.completados = [0, 1]
	Juego.estrellas = {"0": 3, "1": 2}
	Juego.guardar_partida()
	main = load("res://escenas/main.tscn").instantiate()
	add_child(main)
	await _esperar(1.2)
	await _foto("menus_1_titulo")
	main._mostrar_mapa_camino(2)
	await _esperar(0.4)
	await _foto("menus_0_mapa")
	main._mostrar_capitulos()
	await _esperar(0.4)
	await _foto("menus_2_capitulos")
	main._mostrar_ajustes(main.mostrar_titulo)
	await _esperar(0.4)
	await _foto("menus_3_ajustes")
	Juego.flags["intro_vista_0"] = true
	main.iniciar_capitulo(0)
	await _esperar(3.5)
	await _foto("menus_4_guia")
	main.terminar_capitulo()
	for i in 20:
		main.dialogo.avanzar()
		await _esperar(0.05)
	await _esperar(0.5)
	await _foto("menus_5_versiculo")
	main._mostrar_pregunta(1)
	await _esperar(0.3)
	for b in main.capa_menu.find_children("*", "Button", true, false):
		if b.text == "Del mayor al menor" or b.text == "En el de Rubén":
			b.pressed.emit()
			break
	await _esperar(0.4)
	await _foto("menus_6_pregunta")
	main._aciertos = 2
	main._mostrar_pregunta(99)
	await _esperar(0.8)
	await _foto("menus_7_resumen")
	get_tree().quit()


func _esperar(s: float) -> void:
	await get_tree().create_timer(s).timeout


func _foto(nombre: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("user://capturas/%s.png" % nombre)
