extends Node
## Saca capturas de cada capítulo en primera y tercera persona (necesita ventana, no headless).
## Uso: godot --path . res://pruebas/capturas.tscn   → guarda en user://capturas/

var main: Node


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://capturas"))
	main = load("res://escenas/main.tscn").instantiate()
	add_child(main)
	await _esperar(1.5)
	await _foto("00_titulo")
	Juego.nueva_partida(false)
	Juego.flags["permiso_criado"] = true  # para que Booz ya esté en el campo
	var retratados := ["Judá", "Booz", "Goliat", "Eliasib", "Forastero"]
	for cap in Juego.CAPITULOS.size():
		Juego.flags["intro_vista_%d" % cap] = true
		main.iniciar_capitulo(cap)
		await _esperar(1.0)
		await _foto("%d1_tercera" % (cap + 1))
		main.jugador.yaw += PI * 0.75
		await _esperar(0.4)
		await _foto("%d2_tercera_giro" % (cap + 1))
		main.jugador.aplicar_vista(true, false)
		main.jugador.pitch = 0.0
		await _esperar(0.4)
		await _foto("%d3_primera" % (cap + 1))
		main.jugador.aplicar_vista(false, false)
		var npc: Entidad = null
		for e in main.nivel.entidades:
			if e.tipo == "npc" and e.def.get("nombre", "") == retratados[cap]:
				npc = e
				break
		var lejos := 6.0 if retratados[cap] == "Goliat" else 3.0
		main.jugador.global_position = npc.global_position + Vector3(0, 0.2, lejos)
		main.jugador.yaw = 0.0
		await _esperar(0.5)
		npc.interactuar(main)
		await _esperar(2.0)
		await _foto("%d4_dialogo" % (cap + 1))
		main.dialogo.visible = false
		main._modo_juego(true)
	get_tree().quit()


func _esperar(s: float) -> void:
	await get_tree().create_timer(s).timeout


func _foto(nombre: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("user://capturas/%s.png" % nombre)
