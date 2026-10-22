extends Node
## Prueba la cámara con eventos simulados de toque y de mouse.
## Uso: godot --headless --path . res://pruebas/camara.tscn

var main: Node
var escala := Vector2.ONE  # logico -> ventana (en headless la ventana mide 64x64)


func _ready() -> void:
	main = load("res://escenas/main.tscn").instantiate()
	add_child(main)
	await _frames(5)
	Juego.nueva_partida(false)
	Juego.flags["intro_vista_0"] = true
	main.iniciar_capitulo(0)
	await _frames(10)
	var tam: Vector2 = main.get_viewport().get_visible_rect().size
	escala = main.get_viewport().get_final_transform().get_scale()
	print("pantalla: ", tam, "  tactil.size: ", main.tactil.size, "  visible: ", main.tactil.is_visible_in_tree())
	var p := Vector2(tam.x * 0.75, tam.y * 0.5)

	var yaw0: float = main.jugador.yaw
	_evento_toque(true, p)
	for i in 10:
		_evento_arrastre(p + Vector2(i * 10, 0), Vector2(10, 0))
		await _frames(1)
	_evento_toque(false, p)
	await _frames(2)
	print("toque: yaw ", yaw0, " -> ", main.jugador.yaw)

	yaw0 = main.jugador.yaw
	var b := InputEventMouseButton.new()
	b.button_index = MOUSE_BUTTON_LEFT
	b.pressed = true
	b.position = p * escala
	Input.parse_input_event(b)
	await _frames(1)
	for i in 10:
		var m := InputEventMouseMotion.new()
		m.position = (p + Vector2(i * 10, 0)) * escala
		m.relative = Vector2(10, 0) * escala
		m.button_mask = MOUSE_BUTTON_MASK_LEFT
		Input.parse_input_event(m)
		await _frames(1)
	b = b.duplicate()
	b.pressed = false
	Input.parse_input_event(b)
	await _frames(2)
	print("mouse arrastrando: yaw ", yaw0, " -> ", main.jugador.yaw)

	yaw0 = main.jugador.yaw
	for i in 5:
		var m := InputEventMouseMotion.new()
		m.position = Vector2(tam.x * 0.2, tam.y * 0.8) * escala
		m.relative = Vector2(-10, 0) * escala
		m.button_mask = MOUSE_BUTTON_MASK_RIGHT
		Input.parse_input_event(m)
		await _frames(1)
	print("clic derecho (aunque sea en la zona del joystick): yaw ", yaw0, " -> ", main.jugador.yaw)

	yaw0 = main.jugador.yaw
	Input.action_press("mirar_derecha")
	await get_tree().create_timer(0.3).timeout
	Input.action_release("mirar_derecha")
	print("flecha derecha: yaw ", yaw0, " -> ", main.jugador.yaw)

	yaw0 = main.jugador.yaw
	var arriba_izq := Vector2(tam.x * 0.2, tam.y * 0.2)
	_evento_toque(true, arriba_izq)
	_evento_arrastre(arriba_izq + Vector2(10, 0), Vector2(10, 0))
	await _frames(2)
	_evento_toque(false, arriba_izq)
	print("toque arriba a la izquierda mira: yaw ", yaw0, " -> ", main.jugador.yaw)

	var pos0: Vector3 = main.jugador.global_position
	var abajo_izq := Vector2(tam.x * 0.15, tam.y * 0.8)
	_evento_toque(true, abajo_izq)
	_evento_arrastre(abajo_izq + Vector2(0, -60), Vector2(0, -3))
	await _frames(2)
	await get_tree().create_timer(0.6).timeout
	_evento_toque(false, abajo_izq)
	print("joystick abajo a la izquierda mueve: ", pos0.distance_to(main.jugador.global_position) > 0.5)
	get_tree().quit()


func _evento_toque(pulsado: bool, pos: Vector2) -> void:
	var t := InputEventScreenTouch.new()
	t.index = 0
	t.pressed = pulsado
	t.position = pos * escala
	Input.parse_input_event(t)


func _evento_arrastre(pos: Vector2, rel: Vector2) -> void:
	var d := InputEventScreenDrag.new()
	d.index = 0
	d.position = pos * escala
	d.relative = rel * escala
	Input.parse_input_event(d)


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame
