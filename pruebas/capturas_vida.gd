extends Node
## Capturas: fogata y vegetación en el campamento de David, minijuego de la honda, cueva de Emaús.

var main: Node


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://capturas"))
	Juego.nueva_partida(false)
	for i in 5:
		Juego.flags["intro_vista_%d" % i] = true
	main = load("res://escenas/main.tscn").instantiate()
	add_child(main)
	await _esperar(1.0)
	main.iniciar_capitulo(2)
	await _esperar(0.5)
	main.jugador.global_position = Vector3(41, 0.2, 36)
	main.jugador.yaw = PI * 0.15
	main.jugador.pitch = -0.2
	await _esperar(3.5)
	await _foto("v1_campamento")
	main._mostrar_minijuego({"tipo": "honda", "exito": "victoria"})
	await _esperar(0.6)
	await _foto("v2_honda")
	main._limpiar_menu()
	main._modo_juego(true)
	main.iniciar_capitulo(4)
	await _esperar(0.5)
	main.jugador.global_position = Vector3(11, 0.2, 31)
	main.jugador.yaw = PI * 0.5
	main.jugador.pitch = -0.2
	main.nivel.ciclo.hora = 17.6
	main.nivel.ciclo.aplicar()
	await _esperar(3.5)
	await _foto("v3_cueva_emaus")
	get_tree().quit()


func _esperar(s: float) -> void:
	await get_tree().create_timer(s).timeout


func _foto(nombre: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("user://capturas/%s.png" % nombre)
