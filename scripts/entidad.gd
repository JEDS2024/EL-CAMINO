class_name Entidad
extends Node3D
## Todo lo que se puede tocar en el mundo: personajes (npc), lámparas, letreros,
## objetos, mecanismos (pozo, brecha del muro, montón) y salidas. Su comportamiento viene del JSON.
## Opcionales para cualquier entidad: "aparece_si" (condiciones para existir), "etiqueta" (nombre
## flotante) y "accion" (texto del botón).

const ICONOS_LAMPARA := ["fe", "esperanza", "amor", "perdon", "luz"]

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
var reparado: Node3D
var roto: Node3D
var etiqueta: Label3D
var activo := true
## main la marca cada cuadro cuando es lo que el jugador va a usar
var resaltada := false
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
			personaje.configurar(d.get("modelo", d.get("sprite", "caminante")))
			solido = not d.get("seguir", false) and not d.has("aparece_si")
		"lampara":
			_pedestal(0.5)
			sprite = _sprite("lampara_apagada", 0.09, 0.5)
			var icono: String = d.get("icono", d.get("simbolo", "luz"))
			if icono in ICONOS_LAMPARA:
				simbolo = _sprite_icono(icono, 3.2)
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
			match d.get("modelo", "pozo"):
				"brecha": _crear_brecha()
				"monton": _crear_monton()
				_: _crear_pozo()
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
	if d.has("etiqueta"):
		etiqueta = Label3D.new()
		etiqueta.text = d["etiqueta"]
		etiqueta.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		etiqueta.pixel_size = 0.004
		etiqueta.font_size = 40
		etiqueta.outline_size = 12
		etiqueta.modulate = Color("fff3dc")
		etiqueta.position.y = 2.75 if tipo == "npc" else 2.3
		etiqueta.visible = false
		add_child(etiqueta)
	_revisar_aparicion()


func _revisar_aparicion() -> void:
	if not def.has("aparece_si"):
		return
	var ahora := Juego.cumple(def["aparece_si"])
	if ahora == activo and is_inside_tree():
		return
	activo = ahora
	visible = ahora
	if ahora:
		add_to_group("interactuable")
	else:
		remove_from_group("interactuable")


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


func _crear_brecha() -> void:
	# escombros mientras está roto; un tramo de muro nuevo cuando se repara
	roto = Node3D.new()
	add_child(roto)
	var r := RandomNumberGenerator.new()
	r.seed = int(position.x * 13 + position.z * 7)
	for i in 6:
		var mi := MeshInstance3D.new()
		var caja := BoxMesh.new()
		var t := r.randf_range(0.35, 0.7)
		caja.size = Vector3(t, t * 0.7, t)
		mi.mesh = caja
		mi.material_override = Nivel.material("muro")
		mi.position = Vector3(r.randf_range(-0.7, 0.7), t * 0.35, r.randf_range(-0.7, 0.7))
		mi.rotation.y = r.randf() * TAU
		roto.add_child(mi)
	reparado = MeshInstance3D.new()
	var muro := BoxMesh.new()
	muro.size = Vector3(2.0, 3.2, 2.0)
	reparado.mesh = muro
	reparado.material_override = Nivel.material("muro")
	reparado.position.y = 1.6
	add_child(reparado)
	_mostrar_mecanismo(Juego.cumple("flag:" + String(def.get("flag_activo", ""))))


func _crear_monton() -> void:
	# montón de gavillas: crece cuando el mecanismo se completa
	roto = Node3D.new()
	add_child(roto)
	reparado = Node3D.new()
	add_child(reparado)
	for i in 3:
		var mi := MeshInstance3D.new()
		var caja := BoxMesh.new()
		caja.size = Vector3(0.5, 0.25, 0.5)
		mi.mesh = caja
		mi.material_override = Personaje3D.material("d9b25a")
		mi.position = Vector3(-0.4 + i * 0.4, 0.13, 0)
		roto.add_child(mi)
	for i in 3:
		var mi := MeshInstance3D.new()
		var caja := BoxMesh.new()
		caja.size = Vector3(0.6, 0.7, 0.6)
		mi.mesh = caja
		mi.material_override = Personaje3D.material("cfa95a")
		mi.position = Vector3(-0.5 + i * 0.5, 0.35, 0.1 * i)
		reparado.add_child(mi)
	_mostrar_mecanismo(Juego.cumple("flag:" + String(def.get("flag_activo", ""))))


func _mostrar_mecanismo(listo: bool) -> void:
	if reparado:
		reparado.visible = listo
	if roto:
		roto.visible = not listo
	if agua:
		agua.visible = listo


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
	if def.has("accion"):
		return def["accion"]
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
				_mostrar_mecanismo(true)
				var nuevo: Node3D = agua if agua else reparado
				nuevo.scale = Vector3(0.1, 0.1, 0.1)
				create_tween().tween_property(nuevo, "scale", Vector3.ONE, 1.2)
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
	if int(_t * 4) != int((_t - delta) * 4):
		_revisar_aparicion()
	if not activo:
		return
	if simbolo:
		simbolo.position.y += sin(_t * 2.5) * 0.002
	if tipo == "salida" and int(_t * 4) % 4 == 0:
		_actualizar_salida()
	if personaje:
		_mover_personaje(delta)
	if etiqueta:
		_actualizar_etiqueta()


func _actualizar_etiqueta() -> void:
	# el nombre se ve al estar cerca de un personaje o al apuntar a un objeto; nunca pegado a la cámara
	var j := nivel.jugador
	if j == null:
		return
	var d := Vector2(j.global_position.x - global_position.x, j.global_position.z - global_position.z).length()
	var cerca := tipo == "npc" and d < 7.0
	var d_camara := etiqueta.global_position.distance_to(j.camara.global_position)
	etiqueta.visible = (resaltada or cerca) and d_camara > 3.0


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
