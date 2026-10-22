extends Node
## Capturas de la fase 1: portada, HUD con objetos, mochila, aldeanos y ciclo de día.

var main: Node


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://capturas"))
	Juego.nueva_partida(false)
	main = load("res://escenas/main.tscn").instantiate()
	add_child(main)
	await _esperar(1.5)
	await _foto("f1_portada")
	for i in 5:
		Juego.flags["intro_vista_%d" % i] = true
	Juego.flags["permiso_noemi"] = true
	Juego.flags["permiso_criado"] = true
	main.iniciar_capitulo(1)
	await _esperar(0.5)
	Juego.capitulo = 1
	for k in 4:
		Juego.aplicar({"recoger": {"icono": "espiga", "nombre": "Espigas de cebada", "clave": "espiga"}})
	Juego.aplicar({"recoger": {"icono": "pan", "nombre": "Pan", "clave": "pan"}, "amor": 2, "fe": 1})
	Juego.aplicar({"recoger": {"icono": "espiga", "nombre": "Gavilla olvidada", "clave": "gavilla_olvidada", "reliquia": true}})
	main.jugador.global_position = Vector3(30, 0.2, 18)
	main.jugador.yaw = 0.3
	await _esperar(3.5)
	await _foto("f2_hud_rut")
	main._mostrar_mochila()
	await _esperar(0.4)
	await _foto("f3_mochila")
	main._limpiar_menu()
	main._modo_juego(true)
	main.iniciar_capitulo(0)
	await _esperar(0.5)
	main.jugador.global_position = Vector3(12, 0.2, 26)
	main.jugador.yaw = PI * 0.6
	main.jugador.pitch = -0.15
	await _esperar(3.5)
	await _foto("f4_mercado")
	main.iniciar_capitulo(4)
	await _esperar(0.5)
	main.nivel.ciclo.hora = 19.0
	main.nivel.ciclo.aplicar()
	main.jugador.pitch = 0.1
	await _esperar(3.5)
	await _foto("f5_emaus_anochecer")
	get_tree().quit()


func _esperar(s: float) -> void:
	await get_tree().create_timer(s).timeout


func _foto(nombre: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("user://capturas/%s.png" % nombre)
