extends Node
## Cámara en tercera persona pegada a una pared: el personaje no debe taparla.

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://capturas"))
	Juego.nueva_partida(false)
	var main: Node = load("res://escenas/main.tscn").instantiate()
	add_child(main)
	await get_tree().create_timer(1.0).timeout
	for i in 6:
		Juego.flags["intro_vista_%d" % i] = true
	main.iniciar_capitulo(4)
	await get_tree().create_timer(0.6).timeout
	# de espaldas al muro norte, con la cámara contra él
	main.jugador.global_position = Vector3(30.0, 0.2, 7.6)
	main.jugador.yaw = PI
	main.jugador.pitch = -0.1
	for largo in [1.6, 2.0, 2.6]:
		main.jugador.global_position.z = 8.0 + largo
		await get_tree().create_timer(1.2).timeout
		print("distancia de la cámara=", snappedf(main.jugador.brazo.get_hit_length(), 0.01), " modelo visible=", main.jugador.modelo.visible)
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("user://capturas/pared_%s.png" % str(largo))
	get_tree().quit()
