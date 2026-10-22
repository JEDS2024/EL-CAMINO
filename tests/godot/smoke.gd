extends SceneTree
var failures: Array[String] = []
func check(value: bool, description: String) -> void:
	if not value:
		failures.append(description)
		push_error(description)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	root.size = Vector2i(1152, 720)
	var world = load("res://godot/main.tscn").instantiate()
	root.add_child(world)
	await physics_frame
	await physics_frame
	check(world.targets.size() == 5, "Se cargan los cinco puntos de interacción")
	check(world.start_panel.visible and not world.player.active, "Inicio detenido con selector de perspectiva")
	world.camera_choice.selected = 0
	world._start()
	check(world.player.first_person and not world.player.model.visible, "Primera persona oculta el cuerpo")
	check(is_zero_approx(world.player.arm.spring_length), "Primera persona usa cámara a la altura de los ojos")
	world._toggle_camera()
	check(not world.player.first_person and world.player.model.visible, "Tercera persona muestra al discípulo")
	check(world.player.arm.spring_length > 3, "Tercera persona aleja cámara con SpringArm")
	check(world.player.arm.collision_mask == 1, "Cámara de tercera persona comprueba obstáculos")
	# El controlador camina de verdad y no atraviesa las casas.
	world.player.position = Vector3(-7, 0.1, -1)
	world.player.yaw = 0
	var key := InputEventKey.new()
	key.physical_keycode = KEY_W
	key.pressed = true
	Input.parse_input_event(key)
	for frame in 90:
		await physics_frame
	key.pressed = false
	Input.parse_input_event(key)
	check(world.player.position.z < -1.5 and world.player.position.z > -2.85, "Movimiento real se detiene en la pared")
	check(world.player.position.y > -0.1, "El suelo sostiene al jugador")
	world.player.position = Vector3(-7, 0.1, -1.7)
	world.player.yaw = PI
	for frame in 4:
		await physics_frame
	check(world.player.arm.get_hit_length() < 3.0, "La cámara se acerca al personaje delante de una pared")
	var touch := InputEventScreenTouch.new()
	touch.index = 3
	touch.position = world.player.joystick_center() + Vector2(30, -30)
	touch.pressed = true
	Input.parse_input_event(touch)
	Input.flush_buffered_events()
	await physics_frame
	check(world.player.touch_move.length() > 0.5, "El joystick acepta un toque real")
	touch = touch.duplicate()
	touch.pressed = false
	Input.parse_input_event(touch)
	Input.flush_buffered_events()
	await physics_frame
	check(world.player.touch_move == Vector2.ZERO, "Soltar el toque detiene el joystick")
	world.player.yaw = 0
	# Intentar salir o encontrarse con Jesús antes de ayudar no avanza la misión.
	world.quest.interact("path")
	world.quest.interact("jesus")
	check(world.quest.stage == 0, "Los encuentros fuera de orden no avanzan")
	world.player.position = Vector3(0, 0.1, 17)
	check(world.nearby_target().is_empty(), "No se interactúa a distancia")
	for id in ["miriam", "basket", "miriam", "jesus", "path"]:
		world.player.position = world.targets[id].position + Vector3(0, 0.1, 1.5)
		await physics_frame
		check(world.nearby_target() == id, "Se alcanza el objetivo: " + id)
		world._interact()
		check(world.dialog_panel.visible, "Se abre diálogo: " + id)
		check(not world.player.active, "El diálogo detiene movimiento")
		while world.dialog_panel.visible:
			world._advance()
	check(world.quest.stage == 5 and world.end_panel.visible, "Recorrido 3D completo termina correctamente")
	check(not world.targets.basket.visible, "Cesta recogida desaparece")
	check(not world.targets.basket.get_collision_layer_value(1), "Cesta recogida no deja colisión invisible")
	world._toggle_camera()
	check(world.quest.stage == 5, "Cambiar cámara conserva progreso")
	world.player.touch_move = Vector2.ONE
	world.player.stop_input()
	check(world.player.touch_move == Vector2.ZERO, "Pausar limpia el joystick")
	print("LUMBRAL Godot: ", "TODAS LAS COMPROBACIONES PASARON" if failures.is_empty() else str(failures))
	world.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
