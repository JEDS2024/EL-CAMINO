extends Node
## Nehemías visto desde atrás, de noche: la luz del candil no debe quemar su cuello.

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://capturas"))
	Juego.nueva_partida(false)
	Juego.luz = 100.0
	var main: Node = load("res://escenas/main.tscn").instantiate()
	add_child(main)
	await get_tree().create_timer(1.0).timeout
	for i in 6:
		Juego.flags["intro_vista_%d" % i] = true
	main.iniciar_capitulo(4)
	await get_tree().create_timer(0.6).timeout
	main.jugador.global_position = Vector3(30.0, 0.2, 14.0)
	main.jugador.yaw = 0.0
	main.jugador.pitch = -0.2
	await get_tree().create_timer(3.5).timeout
	main.hud.visible = false
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("user://capturas/candil_%s.png" % OS.get_cmdline_user_args()[0])
	get_tree().quit()
