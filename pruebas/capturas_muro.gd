extends Node
## Captura de las brechas del muro de Nehemías antes y después de reunir al pueblo.

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://capturas"))
	Juego.nueva_partida(true)
	var main: Node = load("res://escenas/main.tscn").instantiate()
	add_child(main)
	await get_tree().create_timer(1.0).timeout
	for i in 6:
		Juego.flags["intro_vista_%d" % i] = true
	main.iniciar_capitulo(4)
	await get_tree().create_timer(0.6).timeout
	main.jugador.global_position = Vector3(17.5, 0.2, 13.0)
	main.jugador.yaw = 0.0
	main.jugador.pitch = 0.1
	await get_tree().create_timer(3.0).timeout
	await _foto("m1_antes")
	Juego.flags["edificar"] = true
	main.nivel.construccion.actualizar_planos()
	await get_tree().create_timer(2.0).timeout
	await _foto("m2_despues")
	get_tree().quit()

func _foto(n: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("user://capturas/%s.png" % n)
