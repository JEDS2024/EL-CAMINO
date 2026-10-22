extends Node3D
const Quest = preload("res://godot/quest.gd")
const Disciple = preload("res://godot/disciple.gd")
const Joystick = preload("res://godot/joystick.gd")
var quest = Quest.new()
var player
var targets: Dictionary = {}
var materials: Dictionary = {}
var objective: Label
var prompt: Label
var camera_button: Button
var interact_button: Button
var start_panel: PanelContainer
var dialog_panel: PanelContainer
var dialog_text: Label
var speaker: Label
var camera_choice: OptionButton
var end_panel: PanelContainer
var dialog_lines: Array = []
var line_index := 0
var marker: Label3D
var current_target := ""
var playing := false
var root_ui: Control

func _ready() -> void:
	_build_materials()
	_build_environment()
	_build_village()
	player = Disciple.new()
	player.name = "Discipulo"
	add_child(player)
	player.position = Vector3(0, 0.1, 9)
	player.model = _character(player, Color("54847e"))
	player.set_camera_mode(false)
	_build_ui()
	quest.changed.connect(_update_quest)
	_update_quest()

func _material(name_: String, base: Color, tiles: float = 1.0) -> StandardMaterial3D:
	var image := Image.create(16, 16, false, Image.FORMAT_RGB8)
	var rng := RandomNumberGenerator.new()
	rng.seed = absi(name_.hash())
	for y in 16:
		for x in 16:
			var shade := rng.randf_range(-0.07, 0.07)
			image.set_pixel(x, y, Color(clampf(base.r + shade, 0, 1), clampf(base.g + shade, 0, 1), clampf(base.b + shade, 0, 1)))
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = ImageTexture.create_from_image(image)
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	mat.roughness = 1.0
	mat.uv1_scale = Vector3(tiles, tiles, tiles)
	materials[name_] = mat
	return mat

func _build_materials() -> void:
	_material("grass", Color("82965b"), 24)
	_material("sand", Color("ccb17b"), 5)
	_material("wall", Color("d1b68b"), 3)
	_material("roof", Color("ad7756"), 3)
	_material("wood", Color("816344"))
	_material("leaves", Color("657e48"), 2)
	_material("stone", Color("a09b7e"))
	_material("water", Color("54949b"), 14)
	_material("dark", Color("394d46"))
	_material("basket", Color("ad8450"))

func _box(parent: Node3D, pos: Vector3, size: Vector3, mat: Material, solid: bool = false) -> Node3D:
	var node: Node3D = StaticBody3D.new() if solid else Node3D.new()
	node.position = pos
	parent.add_child(node)
	var mesh := MeshInstance3D.new()
	var shape := BoxMesh.new()
	shape.size = size
	mesh.mesh = shape
	mesh.material_override = mat
	node.add_child(mesh)
	if solid:
		var collision := CollisionShape3D.new()
		var box_shape := BoxShape3D.new()
		box_shape.size = size
		collision.shape = box_shape
		node.add_child(collision)
	return node

func _build_environment() -> void:
	var world := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("a8cbd0")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("eff4ed")
	env.ambient_light_energy = 0.35
	world.environment = env
	add_child(world)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48, -32, 0)
	sun.light_color = Color("fff4e5")
	sun.light_energy = 0.7
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 50
	add_child(sun)
	_box(self, Vector3(0, -0.6, 0), Vector3(40, 1.2, 40), materials.grass, true)
	_box(self, Vector3(15, 0.04, 0), Vector3(8, 0.08, 40), materials.water)
	_box(self, Vector3(10.6, 0.01, 0), Vector3(1.4, 0.05, 38), materials.sand)
	for specs in [[Vector3(0, 0.025, 0), Vector3(3, 0.05, 34)], [Vector3(-2, 0.03, 2), Vector3(21, 0.06, 2.4)], [Vector3(-5, 0.035, 7), Vector3(12, 0.07, 2.3)], [Vector3(4, 0.04, -4), Vector3(9, 0.08, 2.4)]]:
		_box(self, specs[0], specs[1], materials.sand)
	# Límites físicos: el agua y el borde del mapa no son transitables.
	for specs in [[Vector3(11.3, 2, 0), Vector3(0.4, 5, 40)], [Vector3(-19, 2, 0), Vector3(1, 5, 40)], [Vector3(0, 2, -19), Vector3(40, 5, 1)], [Vector3(0, 2, 19), Vector3(40, 5, 1)]]:
		var boundary := StaticBody3D.new()
		boundary.position = specs[0]
		var shape := CollisionShape3D.new()
		var box_shape := BoxShape3D.new()
		box_shape.size = specs[1]
		shape.shape = box_shape
		boundary.add_child(shape)
		add_child(boundary)
	for i in 14:
		var h := float(2 + i % 4)
		_box(self, Vector3(-21 - i % 2 * 2, h / 2 - 0.1, -22 + i * 3.4), Vector3(5, h, 4), materials.leaves)
		_box(self, Vector3(-18 + i * 2.6, h / 2 - 0.1, -23), Vector3(4, h, 5), materials.sand)

func _house(pos: Vector3, width: float, depth: float) -> void:
	_box(self, pos + Vector3(0, 1.65, 0), Vector3(width, 3.3, depth), materials.wall, true)
	_box(self, pos + Vector3(0, 3.35, 0), Vector3(width + 0.3, 0.35, depth + 0.3), materials.roof)
	_box(self, pos + Vector3(0, 1, depth / 2 + 0.03), Vector3(0.9, 2, 0.08), materials.wood)
	for side in [-1, 1]:
		_box(self, pos + Vector3(side * width * 0.31, 1.9, depth / 2 + 0.05), Vector3(0.65, 0.75, 0.1), materials.dark)
		_box(self, pos + Vector3(side * width * 0.31, 1.9, depth / 2 + 0.12), Vector3(0.07, 0.75, 0.08), materials.wood)

func _tree(pos: Vector3) -> void:
	_box(self, pos + Vector3(0, 1.1, 0), Vector3(0.5, 2.2, 0.5), materials.wood, true)
	_box(self, pos + Vector3(0, 2.7, 0), Vector3(2.8, 1.3, 2.8), materials.leaves)
	_box(self, pos + Vector3(0.25, 3.5, 0.1), Vector3(1.9, 0.6, 1.8), materials.leaves)

func _character(parent: Node3D, robe: Color) -> Node3D:
	var model := Node3D.new()
	parent.add_child(model)
	var cloth := _material("cloth_%s" % robe.to_html(), robe)
	var skin: Material = materials.get("skin")
	if skin == null:
		skin = _material("skin", Color("cfa177"))
	var hair: Material = materials.get("hair")
	if hair == null:
		hair = _material("hair", Color("524333"))
	_box(model, Vector3(0, 0.83, 0), Vector3(0.54, 0.78, 0.33), cloth)
	_box(model, Vector3(0, 1.45, 0), Vector3(0.43, 0.43, 0.43), skin)
	_box(model, Vector3(0, 1.68, 0), Vector3(0.46, 0.12, 0.45), hair)
	_box(model, Vector3(0, 1.47, 0.19), Vector3(0.45, 0.38, 0.1), hair)
	for side in [-1, 1]:
		_box(model, Vector3(side * 0.1, 1.47, -0.218), Vector3(0.05, 0.05, 0.02), materials.dark)
		_box(model, Vector3(side * 0.35, 0.85, 0), Vector3(0.16, 0.65, 0.22), skin)
		_box(model, Vector3(side * 0.15, 0.22, 0), Vector3(0.2, 0.44, 0.24), cloth)
		_box(model, Vector3(side * 0.15, 0.06, -0.04), Vector3(0.23, 0.12, 0.33), materials.wood)
	return model

func _text_3d(parent: Node3D, text: String, height: float, color_: Color = Color("f8e6b7")) -> Label3D:
	var label := Label3D.new()
	label.text = text
	label.position.y = height
	label.font_size = 42
	label.pixel_size = 0.006
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = color_
	label.outline_size = 9
	label.no_depth_test = false
	parent.add_child(label)
	return label

func _target(id: String, pos: Vector3, title: String, robe: Color) -> void:
	var body := StaticBody3D.new()
	body.position = pos
	body.name = id
	var collision := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.32
	capsule.height = 1.7
	collision.shape = capsule
	collision.position.y = 0.85
	body.add_child(collision)
	add_child(body)
	var model := _character(body, robe)
	model.rotation.y = PI
	_text_3d(body, title, 2.1)
	targets[id] = body

func _build_village() -> void:
	_house(Vector3(-7, 0, -5), 5, 4)
	_house(Vector3(3.6, 0, -9), 4, 3.5)
	_house(Vector3(-12, 0, 1), 4, 3)
	for pos in [Vector3(-10, 0, 7), Vector3(-15, 0, -10), Vector3(-5, 0, 13), Vector3(6, 0, 13), Vector3(-14, 0, 13), Vector3(8, 0, -13)]:
		_tree(pos)
	# Pozo con hueco visible, borde de bloques y travesaño.
	for specs in [[Vector3(-4, 0.45, 1), Vector3(1.8, 0.9, 0.3)], [Vector3(-4, 0.45, 2.5), Vector3(1.8, 0.9, 0.3)], [Vector3(-4.75, 0.45, 1.75), Vector3(0.3, 0.9, 1.5)], [Vector3(-3.25, 0.45, 1.75), Vector3(0.3, 0.9, 1.5)]]:
		_box(self, specs[0], specs[1], materials.stone, true)
	_box(self, Vector3(-4, 0.15, 1.75), Vector3(1.3, 0.1, 1.3), materials.water)
	for x in [-4.9, -3.1]:
		_box(self, Vector3(x, 1.3, 1.75), Vector3(0.12, 2.6, 0.12), materials.wood)
	_box(self, Vector3(-4, 2.6, 1.75), Vector3(2.2, 0.2, 0.3), materials.wood)
	_target("miriam", Vector3(-2.4, 0, 0.4), "MIRIAM", Color("9e6d85"))
	_target("neighbor", Vector3(3, 0, 4), "HABITANTE", Color("718994"))
	_target("jesus", Vector3(8, 0, -4), "JESÚS", Color("ede4ca"))
	var basket := _box(self, Vector3(-9, 0.26, 7), Vector3(0.65, 0.52, 0.5), materials.basket, true)
	targets.basket = basket
	_text_3d(basket, "CESTA", 0.9)
	var path := Node3D.new()
	path.position = Vector3(0, 0, -15)
	add_child(path)
	targets.path = path
	_text_3d(path, "SENDERO DEL NORTE", 2.5)
	for x in [-1.5, 1.5]:
		_box(self, Vector3(x, 1.2, -15), Vector3(0.25, 2.4, 0.25), materials.wood, true)
	_box(self, Vector3(0, 2.5, -15), Vector3(3.3, 0.2, 0.3), materials.wood)
	marker = _text_3d(self, "◆", 3.0, Color("ffdb84"))

func _label(text: String, size: int = 20) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", Color("f1e8ce"))
	return label

func _button(text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0, 48)
	button.add_theme_font_size_override("font_size", 19)
	button.pressed.connect(callback)
	return button

func _panel(parent: Control, rect: Rect2) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.position = rect.position
	panel.size = rect.size
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.15, 0.14, 0.96)
	style.border_color = Color("c6ac78")
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.content_margin_left = 24
	style.content_margin_right = 24
	style.content_margin_top = 20
	style.content_margin_bottom = 20
	panel.add_theme_stylebox_override("panel", style)
	parent.add_child(panel)
	return panel

func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	root_ui = Control.new()
	root_ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(root_ui)
	var hud := PanelContainer.new()
	hud.position = Vector2(20, 18)
	hud.size = Vector2(760, 78)
	root_ui.add_child(hud)
	var top := VBoxContainer.new()
	hud.add_child(top)
	top.add_child(_label("  LUMBRAL · EL LLAMADO  /  GALILEA", 17))
	objective = _label("", 21)
	top.add_child(objective)
	camera_button = _button("Cámara: 3.ª persona [V]", _toggle_camera)
	camera_button.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	camera_button.position = Vector2(-315, 20)
	camera_button.size = Vector2(295, 50)
	root_ui.add_child(camera_button)
	var controls := Joystick.new()
	controls.player = player
	controls.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root_ui.add_child(controls)
	var crosshair := _label("+", 26)
	crosshair.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	crosshair.position = Vector2(-8, -18)
	crosshair.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_ui.add_child(crosshair)
	prompt = _label("", 20)
	prompt.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	prompt.position = Vector2(-300, -125)
	prompt.size = Vector2(600, 40)
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root_ui.add_child(prompt)
	interact_button = _button("Hablar [E]", _interact)
	interact_button.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	interact_button.position = Vector2(-235, -105)
	interact_button.size = Vector2(210, 65)
	root_ui.add_child(interact_button)
	var help := _label("WASD / flechas: caminar · Ratón / arrastre derecho: mirar · E: interactuar · V: cámara · Esc: menú", 16)
	help.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	help.position = Vector2(-420, -28)
	help.add_theme_color_override("font_shadow_color", Color("172d29"))
	help.add_theme_constant_override("shadow_offset_x", 1)
	help.add_theme_constant_override("shadow_offset_y", 1)
	help.add_theme_constant_override("outline_size", 4)
	help.add_theme_color_override("font_outline_color", Color("172d29"))
	root_ui.add_child(help)
	start_panel = _panel(root_ui, Rect2(Vector2(-290, -210), Vector2(580, 420)))
	var start := VBoxContainer.new()
	start.add_theme_constant_override("separation", 15)
	start_panel.add_child(start)
	start.add_child(_label("LUMBRAL", 36))
	start.add_child(_label("EL LLAMADO · PROTOTIPO 3D", 20))
	var intro := _label("Acompaña a Jesús como un discípulo.\nExplora la aldea, escucha y ayuda a sus habitantes.\n\nElige cómo quieres vivir la aventura:", 20)
	start.add_child(intro)
	camera_choice = OptionButton.new()
	camera_choice.add_item("Primera persona · a través de tus ojos")
	camera_choice.add_item("Tercera persona · ves a tu discípulo")
	camera_choice.selected = 1
	camera_choice.custom_minimum_size.y = 48
	camera_choice.add_theme_font_size_override("font_size", 19)
	start.add_child(camera_choice)
	start.add_child(_button("Comenzar / continuar el camino", _start))
	var note := _label("Escena y diálogos originales inspirados en los Evangelios.\nReferencia visual: bloques y texturas pixeladas originales.", 14)
	start.add_child(note)
	dialog_panel = _panel(root_ui, Rect2(Vector2(-370, 65), Vector2(740, 240)))
	var conversation := VBoxContainer.new()
	conversation.add_theme_constant_override("separation", 12)
	dialog_panel.add_child(conversation)
	speaker = _label("", 21)
	conversation.add_child(speaker)
	dialog_text = _label("", 22)
	dialog_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialog_text.custom_minimum_size = Vector2(680, 90)
	conversation.add_child(dialog_text)
	conversation.add_child(_button("Continuar [Enter]", _advance))
	dialog_panel.hide()
	end_panel = _panel(root_ui, Rect2(Vector2(-290, -160), Vector2(580, 320)))
	var ending := VBoxContainer.new()
	ending.add_theme_constant_override("separation", 20)
	end_panel.add_child(ending)
	ending.add_child(_label("El camino continúa.", 34))
	ending.add_child(_label("Escuchaste, ayudaste y diste el primer paso.\nFin de este primer recorrido 3D.", 21))
	ending.add_child(_button("Volver a jugar", _restart))
	end_panel.hide()

func _start() -> void:
	playing = true
	start_panel.hide()
	player.set_camera_mode(camera_choice.selected == 0)
	player.active = true
	_sync_camera_ui()
	if not OS.has_feature("mobile"):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _toggle_camera() -> void:
	player.set_camera_mode(not player.first_person)
	camera_choice.selected = 0 if player.first_person else 1
	_sync_camera_ui()

func _sync_camera_ui() -> void:
	camera_button.text = "Cámara: %s persona [V]" % ("1.ª" if player.first_person else "3.ª")

func _update_quest() -> void:
	objective.text = "  " + quest.OBJECTIVES[quest.stage]
	if quest.stage >= 2:
		targets.basket.hide()
		targets.basket.set_collision_layer_value(1, false)

func nearby_target() -> String:
	var closest := ""
	var distance := 3.1
	for id in targets:
		if id == "basket" and quest.stage >= 2:
			continue
		var body: Node3D = targets[id]
		var d: float = player.global_position.distance_to(body.global_position)
		if d >= distance:
			continue
		var exclusions: Array[RID] = [player.get_rid()]
		if body is CollisionObject3D:
			exclusions.append(body.get_rid())
		var ray := PhysicsRayQueryParameters3D.create(player.global_position + Vector3.UP, body.global_position + Vector3.UP, 1, exclusions)
		if not get_world_3d().direct_space_state.intersect_ray(ray).is_empty():
			continue
		closest = id
		distance = d
	return closest

func _process(_delta: float) -> void:
	if not is_instance_valid(player):
		return
	current_target = nearby_target() if player.active else ""
	interact_button.disabled = current_target.is_empty()
	var names := {"miriam": "Miriam", "basket": "la cesta", "jesus": "Jesús", "neighbor": "un habitante", "path": "el sendero"}
	prompt.text = ("Cerca del sendero" if current_target == "path" else "Cerca de " + str(names.get(current_target, ""))) if not current_target.is_empty() else ""
	interact_button.text = ("Recoger" if current_target == "basket" else "Partir" if current_target == "path" else "Hablar") + " [E]"
	var guide: String = quest.GUIDES[quest.stage]
	marker.visible = not guide.is_empty()
	if not guide.is_empty():
		marker.global_position = targets[guide].global_position + Vector3(0, 3.3 + sin(Time.get_ticks_msec() * 0.003) * 0.12, 0)

func _interact() -> void:
	if not player.active:
		return
	var id := nearby_target()
	if id.is_empty():
		return
	var result: Dictionary = quest.interact(id)
	if result.is_empty():
		return
	speaker.text = result.speaker
	dialog_lines = result.lines
	line_index = 0
	dialog_text.text = dialog_lines[0]
	dialog_panel.show()
	player.active = false
	player.stop_input()

func _advance() -> void:
	if not dialog_panel.visible:
		return
	line_index += 1
	if line_index < dialog_lines.size():
		dialog_text.text = dialog_lines[line_index]
		return
	dialog_panel.hide()
	if quest.stage == 5:
		end_panel.show()
	else:
		player.active = true
		if not OS.has_feature("mobile"):
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _restart() -> void:
	get_tree().reload_current_scene()

func _unhandled_key_input(event: InputEvent) -> void:
	if not event.is_pressed() or event.is_echo():
		return
	if event.keycode == KEY_V:
		_toggle_camera()
	elif event.keycode == KEY_E:
		_interact()
	elif event.keycode == KEY_ENTER:
		_advance()
	elif event.keycode == KEY_ESCAPE and not dialog_panel.visible and not end_panel.visible:
		player.active = false
		player.stop_input()
		start_panel.show()
		camera_choice.selected = 0 if player.first_person else 1
