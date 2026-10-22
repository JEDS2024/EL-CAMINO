extends Node
## Captura fija del campo de Rut (para comparar el aspecto visual antes y después).

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://capturas"))
	Juego.nueva_partida(false)
	Juego.flags["intro_vista_1"] = true
	Juego.flags["permiso_noemi"] = true
	var main = load("res://escenas/main.tscn").instantiate()
	add_child(main)
	await get_tree().create_timer(0.5).timeout
	main.iniciar_capitulo(1)
	await get_tree().create_timer(0.3).timeout
	main.jugador.global_position = Vector3(25, 0.2, 23)
	main.jugador.yaw = 0.0
	main.jugador.pitch = -0.25
	await get_tree().create_timer(3.5).timeout
	await RenderingServer.frame_post_draw
	var nombre := OS.get_environment("NOMBRE_CAPTURA")
	get_viewport().get_texture().get_image().save_png("user://capturas/%s.png" % (nombre if nombre != "" else "vista_rut"))
	get_tree().quit()
