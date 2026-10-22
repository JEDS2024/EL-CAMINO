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
var marcada := false  # el faro la señala (entonces no hace falta el «!»)
var letra := ""  # carácter del mapa que la creó (lo usa la guía de objetivos)
var aviso: Label3D  # «!» cuando un personaje tiene algo nuevo que decir
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
			if d.get("aldeano", false):
				personaje.configurar_aleatorio(int(position.x * 131 + position.z * 17), d.get("estilo", "hebreo"))
			else:
				personaje.configurar(d.get("modelo", d.get("sprite", "caminante")))
			solido = not d.get("seguir", false) and not d.has("aparece_si") and not d.get("aldeano", false)
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
		etiqueta.pixel_size = 0.0045
		etiqueta.font_size = 48
		etiqueta.outline_size = 18
		etiqueta.outline_modulate = Color(0.06, 0.04, 0.12)
		etiqueta.modulate = Color("fff3dc")
		etiqueta.position.y = 2.35 if tipo == "npc" else 2.0
		etiqueta.visible = false
		add_child(etiqueta)
	if tipo == "npc" and not def.get("dialogos", []).is_empty():
		aviso = Label3D.new()
		aviso.text = "!"
		aviso.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		aviso.font_size = 96
		aviso.outline_size = 18
		aviso.pixel_size = 0.006
		aviso.modulate = Color("ffd36b")
		aviso.position.y = 2.95
		aviso.visible = false
		add_child(aviso)
	_revisar_aparicion()


## El diálogo que diría este personaje ahora mismo.
func dialogo_actual() -> String:
	for opcion in def.get("dialogos", []):
		if Juego.cumple(opcion.get("si", [])):
			return opcion["id"]
	return ""


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
			if def.get("aldeano", false):
				var frases: Array = nivel.datos.get("aldeanos_frases", ["Alguien del lugar sigue con sus tareas."])
				main.decir(frases[randi() % frases.size()])
				return
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
				Sonido.efecto("lampara")
				nivel.chispas(global_position + Vector3(0, 1.9, 0), Color("ffbf60"), 24)
				nivel.lampara_encendida(self)
		"objeto":
			var efectos: Dictionary = def.get("efectos", {}).duplicate()
			efectos["recoger"] = {"icono": def.get("icono", "luz"), "nombre": def.get("nombre", def.get("etiqueta", "Objeto")),
				"reliquia": efectos.has("secreto"),
				"clave": String(def.get("id", "")) if efectos.has("secreto") else String(def.get("icono", "luz"))}
			if def.has("id"):
				var previas = efectos.get("flag", [])
				efectos["flag"] = (previas if previas is Array else [previas]) + ["tomado_" + String(def["id"])]
			Juego.aplicar(efectos)
			Sonido.efecto("hallazgo")
			nivel.chispas(global_position + Vector3(0, 0.9, 0), Color(def.get("color_luz", "#ffe08a")), 36)
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
				Sonido.efecto("mecanismo")
				nivel.chispas(global_position + Vector3(0, 1.0, 0), Color("e8dcc0"), 50)
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
		if aviso:
			aviso.visible = Juego.guia and activo and not marcada and not Juego.flags.get("visto_" + dialogo_actual(), false)
	if aviso and aviso.visible:
		aviso.position.y = 2.95 + sin(_t * 4.0) * 0.1
	if not activo:
		return
	if simbolo:
		simbolo.position.y += sin(_t * 2.5) * 0.002
	if tipo == "salida" and int(_t * 4) % 4 == 0:
		_actualizar_salida()
	if tipo == "lampara" and encendida:
		luz.light_energy = 2.1 + sin(_t * 13.0) * 0.12 + sin(_t * 7.3) * 0.1
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


var _vel_seguir := 0.0


func _mover_personaje(delta: float) -> void:
	var j := nivel.jugador
	if j == null:
		return
	var hacia := j.global_position - global_position
	hacia.y = 0
	var dist := hacia.length()
	var cabeza_jugador := j.global_position + Vector3(0, 1.5, 0)
	personaje.mirar_hacia(cabeza_jugador if dist < 7.0 else null)
	personaje.hablando = nivel.main.hablando_con == def.get("nombre", "@")
	# los acompañantes siguen al jugador acelerando y frenando suave, mirando hacia donde caminan
	if def.get("seguir", false) and Juego.cumple(def.get("seguir_si", [])):
		if dist > 16.0:
			global_position = j.global_position - hacia.normalized() * 2.5
			_vel_seguir = 0.0
		else:
			var deseada := clampf((dist - 2.6) * 1.6, 0.0, 5.0)
			_vel_seguir = move_toward(_vel_seguir, deseada, delta * 8.0)
			if _vel_seguir > 0.05:
				global_position += hacia.normalized() * _vel_seguir * delta
				personaje.actualizar(delta, hacia, true)
				return
	if def.get("aldeano", false) and dist > 3.0 and not personaje.hablando:
		var paso := _vagar(delta)
		if paso != Vector3.ZERO:
			personaje.actualizar(delta, paso, true)
			return
	# quieto: solo gira el cuerpo si estás muy cerca y a un costado (la cabeza ya te mira)
	var girar := hacia if dist < 3.2 else Vector3.ZERO
	personaje.actualizar(delta, girar, false)


var _origen_vagar = null
var _destino_vagar := Vector3.ZERO
var _pausa_vagar := 0.0


## Los aldeanos caminan despacio entre lugares libres cercanos a donde empezaron.
func _vagar(delta: float) -> Vector3:
	if _origen_vagar == null:
		_origen_vagar = global_position
		_destino_vagar = global_position
	var hacia := _destino_vagar - global_position
	hacia.y = 0
	if hacia.length() > 0.15:
		var paso := hacia.normalized() * minf(1.3 * delta, hacia.length())
		global_position += paso
		return paso
	_pausa_vagar -= delta
	if _pausa_vagar <= 0:
		_pausa_vagar = randf_range(2.0, 6.0)
		for intento in 6:
			var candidato: Vector3 = _origen_vagar + Vector3(randf_range(-6, 6), 0, randf_range(-6, 6))
			if nivel.libre(candidato) and nivel.libre(global_position.lerp(candidato, 0.5)):
				_destino_vagar = candidato
				break
	return Vector3.ZERO
