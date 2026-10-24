extends Node
## Acerca la cámara al cuello de varios personajes, de frente, de espaldas y de lado.

const CLAVES := ["nehemias", "sanbalat", "eliasib", "obrero", "noe", "jose", "rut", "david"]


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://capturas"))
	var vista := SubViewport.new()
	vista.size = Vector2i(1280, 480)
	vista.own_world_3d = true
	vista.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(vista)
	var sol := DirectionalLight3D.new()
	sol.rotation_degrees = Vector3(-50, 30, 0)
	vista.add_child(sol)
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("5a6a8a")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("a0a0b0")
	env.ambient_light_energy = 0.7
	var we := WorldEnvironment.new()
	we.environment = env
	vista.add_child(we)
	for i in CLAVES.size():
		var p := Personaje3D.new()
		vista.add_child(p)
		p.position = Vector3(i * 1.4, 0, 0)
		p.configurar(CLAVES[i])
	var cam := Camera3D.new()
	cam.fov = 40
	vista.add_child(cam)
	cam.current = true
	if OS.get_cmdline_user_args().has("noche"):  # como en Nehemías: luna tenue y la luz del candil
		env.ambient_light_color = Color("4a5080")
		env.ambient_light_energy = 0.55
		env.background_color = Color("141830")
		sol.light_energy = 0.3
		sol.light_color = Color("8fa0ff")
		for i in CLAVES.size():
			var candil := OmniLight3D.new()
			candil.light_color = Color("ffc978")
			candil.light_energy = 0.7
			candil.omni_range = 12.0
			candil.position = Vector3(i * 1.4, 2.3, 0.7)
			vista.add_child(candil)
	for vuelta in [["frente", 0.0], ["espalda", PI], ["lado", PI / 2], ["tres_cuartos", 2.4]]:
		for hijo in vista.get_children():
			if hijo is Personaje3D:
				hijo.rotation.y = vuelta[1]
		cam.position = Vector3(CLAVES.size() * 0.7 - 0.7, 1.45, -4.2 if vuelta[1] == 0.0 else 4.2)
		cam.look_at(Vector3(CLAVES.size() * 0.7 - 0.7, 1.35, 0))
		if vuelta[0] == "lado":
			cam.position = Vector3(CLAVES.size() * 0.7 - 0.7, 1.45, -4.2)
		await get_tree().create_timer(0.5).timeout
		await RenderingServer.frame_post_draw
		vista.get_texture().get_image().save_png("user://capturas/cuello_%s.png" % vuelta[0])
	get_tree().quit()
