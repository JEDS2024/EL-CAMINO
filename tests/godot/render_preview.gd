extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	root.size = Vector2i(1152, 720)
	var world = load("res://godot/main.tscn").instantiate()
	root.add_child(world)
	world.start_panel.hide()
	world.player.position = Vector3(0, 0.1, 7)
	world.player.pitch = -0.16
	world.player.yaw = 0.08
	world.player.set_camera_mode(false)
	world._sync_camera_ui()
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var result := root.get_texture().get_image().save_png("res://docs/godot-tercera-persona.png")
	assert(result == OK)
	world.player.set_camera_mode(true)
	world._sync_camera_ui()
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	result = root.get_texture().get_image().save_png("res://docs/godot-primera-persona.png")
	assert(result == OK)
	world.start_panel.show()
	await process_frame
	await RenderingServer.frame_post_draw
	result = root.get_texture().get_image().save_png("res://docs/godot-selector-camara.png")
	assert(result == OK)
	print("Capturas de ambas perspectivas y selector guardadas.")
	quit()
