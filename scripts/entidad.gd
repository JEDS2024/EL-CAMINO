class_name Entidad
extends Node3D
## Todo lo que se puede tocar en el mundo: personajes (npc), lámparas, letreros,
## objetos, mecanismos (como el pozo) y salidas. Su comportamiento viene del JSON.

var tipo := ""
var def: Dictionary = {}
var nivel: Nivel
var solido := false
var encendida := false

var personaje: Personaje3D
var sprite: Sprite3D
var simbolo: Sprite3D
var luz: OmniLight3D
var agua: MeshInstance3D
var _t := 0.0


func preparar(d: Dictionary, n: Nivel) -> void:
	def = d
	nivel = n
	tipo = d.get("tipo", "")
	add_to_group("interactuable")
	match tipo:
		"npc":
			personaje = Personaje3D.new()
			add_child(personaje)
			personaje.configurar(d.get("sprite", "caminante"))
			solido = not d.get("seguir", false)
		"lampara":
			_pedestal(0.5)
			sprite = _sprite("lampara_apagada", 0.09, 0.5)
			simbolo = _sprite_icono(d.get("simbolo", "luz"), 3.2)
			luz = OmniLight3D.new()
			luz.light_color = Color("ffbf60")
			luz.light_energy = 2.2
			luz.omni_range = 9.0
			luz.position.y = 2.0
			luz.visible = false
			add_child(luz)
			solido = true
			if nivel.acertijo_resuelto(d.get("acertijo", "")):
				fijar_encendida(true)
		"letrero":
			_pedestal(1.3, Vector3(1.4, 1.3, 0.35))
			solido = true
		"objeto":
			simbolo = _sprite_icono(d.get("icono", "luz"), 0.9)
			luz = OmniLight3D.new()
			luz.light_color = Color(d.get("color_luz", "#ff8090"))
			luz.light_energy = 1.0
			luz.omni_range = 3.0
			luz.position.y = 0.9
			add_child(luz)
		"mecanismo":
			_crear_pozo()
			solido = true
		"salida":
			sprite = _sprite("arco_cerrado", 0.13, 0.0)
			luz = OmniLight3D.new()
			luz.light_color = Color("ffe3a0")
			luz.light_energy = 2.0
			luz.omni_range = 7.0
			luz.position.y = 2.0
			add_child(luz)
			_actualizar_salida()


# ------------------------------------------------------------------ visuales
func _sprite(nombre: String, tam: float, y: float) -> Sprite3D:
	var s := Sprite3D.new()
	s.texture = load("res://assets/sprites/%s.png" % nombre)
	s.pixel_size = tam
	s.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	s.shaded = true
	s.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	s.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	s.position.y = y + s.texture.get_height() * tam * 0.5
	add_child(s)
	return s


func _sprite_icono(nombre: String, y: float) -> Sprite3D:
	var s := Sprite3D.new()
	s.texture = load("res://assets/iconos/%s.png" % nombre)
	s.pixel_size = 0.045
	s.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	s.shaded = false
	s.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	s.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	s.position.y = y
	add_child(s)
	return s


func _pedestal(alto: float, tam := Vector3(0.9, 0.5, 0.9)) -> void:
	var mi := MeshInstance3D.new()
	var caja := BoxMesh.new()
	caja.size = Vector3(tam.x, alto, tam.z)
	mi.mesh = caja
	mi.material_override = Nivel.material("muro")
	mi.position.y = alto / 2
	add_child(mi)


func _crear_pozo() -> void:
	for i in 8:
		var ang := TAU * i / 8.0
		var mi := MeshInstance3D.new()
		var caja := BoxMesh.new()
		caja.size = Vector3(0.55, 0.8, 0.55)
		mi.mesh = caja
		mi.material_override = Nivel.material("roca")
		mi.position = Vector3(cos(ang) * 0.85, 0.4, sin(ang) * 0.85)
		add_child(mi)
	agua = MeshInstance3D.new()
	var plano := PlaneMesh.new()
	plano.size = Vector2(1.3, 1.3)
	agua.mesh = plano
	agua.material_override = Nivel.material("agua")
	agua.position.y = 0.55
	agua.visible = Juego.cumple("flag:" + String(def.get("flag_activo", "")))
	add_child(agua)


func fijar_encendida(si: bool) -> void:
	encendida = si
	sprite.texture = load("res://assets/sprites/%s.png" % ("lampara_encendida" if si else "lampara_apagada"))
	luz.visible = si


func _actualizar_salida() -> void:
	var abierta := Juego.cumple(def.get("requiere", []))
	sprite.texture = load("res://assets/sprites/%s.png" % ("arco_abierto" if abierta else "arco_cerrado"))
	luz.visible = abierta


# ------------------------------------------------------------------ interacción
func texto_accion() -> String:
	match tipo:
		"npc": return "Hablar"
		"lampara": return "Encender"
		"letrero": return "Leer"
		"objeto": return "Tomar"
		"mecanismo": return "Usar"
		"salida": return "Cruzar"
	return "Ver"


func interactuar(main: Node) -> void:
	match tipo:
		"npc":
			for opcion in def.get("dialogos", []):
				if Juego.cumple(opcion.get("si", [])):
					main.iniciar_dialogo(opcion["id"], self)
					return
		"letrero":
			main.iniciar_dialogo(def.get("dialogo", ""))
		"lampara":
			if encendida:
				main.decir("La llama arde tranquila.")
			elif not Juego.cumple(def.get("requiere", [])):
				main.iniciar_dialogo(def.get("dialogo_frio", ""))
			else:
				fijar_encendida(true)
				nivel.lampara_encendida(self)
		"objeto":
			var efectos: Dictionary = def.get("efectos", {}).duplicate()
			if def.has("id"):
				var previas = efectos.get("flag", [])
				efectos["flag"] = (previas if previas is Array else [previas]) + ["tomado_" + String(def["id"])]
			Juego.aplicar(efectos)
			main.iniciar_dialogo(def.get("dialogo", ""))
			remove_from_group("interactuable")
			var t := create_tween()
			t.tween_property(self, "scale", Vector3.ZERO, 0.3)
			t.tween_callback(queue_free)
		"mecanismo":
			var flag_activo := "flag:" + String(def.get("flag_activo", ""))
			if Juego.cumple(flag_activo):
				main.iniciar_dialogo(def.get("dialogo_hecho", ""))
			elif Juego.cumple(def.get("requiere", [])):
				Juego.aplicar(def.get("efectos", {}))
				agua.visible = true
				agua.scale = Vector3(0.1, 1, 0.1)
				create_tween().tween_property(agua, "scale", Vector3.ONE, 1.2)
				main.iniciar_dialogo(def.get("dialogo_listo", ""))
			else:
				main.iniciar_dialogo(def.get("dialogo_falta", ""))
		"salida":
			if Juego.cumple(def.get("requiere", [])):
				main.terminar_capitulo()
			else:
				main.iniciar_dialogo(def.get("dialogo_cerrado", ""))


func _process(delta: float) -> void:
	_t += delta
	if simbolo:
		simbolo.position.y += sin(_t * 2.5) * 0.002
	if tipo == "salida" and int(_t * 4) % 4 == 0:
		_actualizar_salida()
	if personaje:
		_mover_personaje(delta)


func _mover_personaje(delta: float) -> void:
	var j := nivel.jugador
	if j == null:
		return
	var hacia := j.global_position - global_position
	hacia.y = 0
	var dist := hacia.length()
	var moviendose := false
	if def.get("seguir", false) and Juego.cumple(def.get("seguir_si", [])):
		if dist > 14.0:
			global_position = j.global_position - hacia.normalized() * 2.0
		elif dist > 2.6:
			global_position += hacia.normalized() * minf(4.2 * delta, dist - 2.6)
			moviendose = true
	var mirar := hacia if dist < 6.0 else Vector3.ZERO
	personaje.actualizar(delta, mirar, moviendose)
