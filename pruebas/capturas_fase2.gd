extends Node
## Capturas de la fase 2: construir con bloques en el muro de Nehemías (y el arca, cuando exista).

var main: Node


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://capturas"))
	Juego.nueva_partida(false)
	main = load("res://escenas/main.tscn").instantiate()
	add_child(main)
	await _esperar(1.0)
	await _foto("f0_menu_v08")
	for i in Juego.CAPITULOS.size():
		Juego.flags["intro_vista_%d" % i] = true
	var neh := Juego.CAPITULOS.find("res://datos/capitulos/cap4_nehemias.json")
	Juego.flags["edificar"] = true
	main.iniciar_capitulo(neh)
	await _esperar(0.5)
	var con: Construccion = main.nivel.construccion
	Juego.sumar_bloque("piedra", 4)
	var celdas: Array = con.planos["tramo_norte"]["celdas"].keys()
	main.jugador.global_position = Vector3(17.5, 0.2, 12.5)
	main.jugador.yaw = 0.15
	main.jugador.pitch = -0.32
	await _esperar(1.0)
	for k in 3:
		main.poner_en(celdas[k], "piedra")
	await _esperar(2.5)
	await _foto("f6_muro_3p")
	main.jugador.aplicar_vista(true, false)
	main.jugador.global_position = Vector3(17.0, 0.2, 10.2)
	main.jugador.yaw = 0.0
	main.jugador.pitch = -0.45
	await _esperar(1.0)
	await _foto("f7_muro_1p")
	main.jugador.aplicar_vista(false, false)
	var cap := Juego.CAPITULOS.find("res://datos/capitulos/cap0_noe.json")
	if cap >= 0:
		main.iniciar_capitulo(cap)
		await _esperar(0.5)
		main.jugador.global_position = Vector3(31, 0.2, 30)
		main.jugador.yaw = 0.2
		main.jugador.pitch = -0.25
		main.jugador.brazo.spring_length = 9.0
		await _esperar(5.5)
		await _foto("f8_arca")
	get_tree().quit()


func _esperar(s: float) -> void:
	await get_tree().create_timer(s).timeout


func _foto(nombre: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("user://capturas/%s.png" % nombre)
