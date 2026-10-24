extends Node
## Captura de la tarjeta «Nueva misión» al empezar el capítulo de Noé.

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://capturas"))
	Juego.nueva_partida(false)
	Juego.leer_voz = false
	var main: Node = load("res://escenas/main.tscn").instantiate()
	add_child(main)
	await get_tree().create_timer(1.0).timeout
	Juego.flags["intro_vista_0"] = true
	main.iniciar_capitulo(0)
	await get_tree().create_timer(3.6).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("user://capturas/mision_noe.png")
	get_tree().quit()
