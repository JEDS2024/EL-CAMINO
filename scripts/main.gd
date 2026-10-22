extends Node
## Punto de entrada: crea la vista 3D pixelada, la interfaz y maneja el flujo del juego
## (título → elegir cámara → capítulos → final).

const ESCALA_PIXEL := 3  # la escena 3D se dibuja a 1/3 de la resolución y se agranda sin suavizar
const DISTANCIA_INTERACCION := 2.6

var vista: SubViewport
var ui: CanvasLayer
var hud: Hud
var dialogo: CajaDialogo
var tactil: ControlesTactiles
var capa_menu: Control

var nivel: Nivel
var jugador: Jugador
var datos_cap: Dictionary = {}
var en_juego := false
var en_titulo := false
var _objetivo_entidad: Entidad
var _reloj := 0.0


func _ready() -> void:
	_crear_vista()
	_crear_ui()
	Juego.aviso.connect(hud.mostrar_aviso)
	mostrar_titulo()


# ------------------------------------------------------------------ construcción
func _crear_vista() -> void:
	var cont := SubViewportContainer.new()
	cont.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cont.stretch = true
	cont.stretch_shrink = ESCALA_PIXEL
	cont.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	cont.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(cont)
	vista = SubViewport.new()
	vista.own_world_3d = true
	vista.handle_input_locally = false
	cont.add_child(vista)


func _crear_ui() -> void:
	ui = CanvasLayer.new()
	ui.layer = 1
	add_child(ui)
	var raiz := Control.new()
	raiz.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	raiz.mouse_filter = Control.MOUSE_FILTER_IGNORE
	raiz.theme = Tema.crear()
	ui.add_child(raiz)

	tactil = ControlesTactiles.new()
	raiz.add_child(tactil)
	tactil.mover.connect(_mover_tactil)
	tactil.mirar.connect(_mirar_tactil)

	hud = Hud.new()
	raiz.add_child(hud)
	hud.pedir_interactuar.connect(_interactuar)
	hud.pedir_vista.connect(_cambiar_vista)
	hud.pedir_pausa.connect(_mostrar_pausa)
	tactil.excluir = [hud.boton_accion, hud.boton_vista, hud.boton_pausa]

	dialogo = CajaDialogo.new()
	raiz.add_child(dialogo)
	dialogo.resolver = func(id): return datos_cap.get("dialogos", {}).get(id, [])

	capa_menu = Control.new()
	capa_menu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	capa_menu.mouse_filter = Control.MOUSE_FILTER_IGNORE
	raiz.add_child(capa_menu)
	_modo_juego(false)


func _mover_tactil(v: Vector2) -> void:
	if jugador:
		jugador.entrada_tactil = v


func _mirar_tactil(d: Vector2) -> void:
	if jugador and not jugador.bloqueado:
		jugador.mirar(d)


func _modo_juego(activo: bool) -> void:
	en_juego = activo
	hud.visible = activo
	tactil.visible = activo
	tactil.reiniciar()
	if jugador:
		jugador.bloqueado = not activo


# ------------------------------------------------------------------ niveles
func _cargar_nivel(i: int) -> void:
	if nivel:
		vista.remove_child(nivel)
		nivel.queue_free()
		nivel = null
		jugador = null
	datos_cap = Juego.datos_capitulo(i)
	nivel = Nivel.new()
	vista.add_child(nivel)
	nivel.construir(datos_cap, self)
	jugador = Jugador.new()
	nivel.add_child(jugador)
	jugador.position = nivel.inicio + Vector3(0, 0.2, 0)
	jugador.yaw = deg_to_rad(float(datos_cap.get("mirar_inicio", 0)))
	nivel.jugador = jugador
	var retratos := {"Ezra": "ezra"}
	for clave in datos_cap.get("leyenda", {}):
		var def: Dictionary = datos_cap["leyenda"][clave]
		if def.get("tipo", "") == "npc":
			retratos[def.get("nombre", "")] = def.get("sprite", "")
	dialogo.retratos = retratos


func iniciar_capitulo(i: int) -> void:
	_limpiar_menu()
	en_titulo = false
	Juego.capitulo = i
	Juego.guardar_partida()
	_cargar_nivel(i)
	_modo_juego(true)
	hud.actualizar()
	hud.mostrar_titulo(datos_cap.get("titulo", ""), datos_cap.get("subtitulo", ""))
	var marca := "intro_vista_%d" % i
	if not Juego.flags.get(marca, false):
		Juego.flags[marca] = true
		await get_tree().create_timer(2.2).timeout
		_abrir_dialogo(datos_cap.get("intro", []))


func terminar_capitulo() -> void:
	var epilogo: Array = datos_cap.get("epilogo", [])
	if epilogo.is_empty():
		_mostrar_resumen()
	else:
		_abrir_dialogo(epilogo, _mostrar_resumen)


# ------------------------------------------------------------------ diálogos
func iniciar_dialogo(id: String, _entidad: Entidad = null) -> void:
	if id == "":
		return
	var lineas: Array = datos_cap.get("dialogos", {}).get(id, [])
	if lineas.is_empty():
		push_warning("Diálogo no encontrado: " + id)
		return
	_abrir_dialogo(lineas)


func decir(texto: String) -> void:
	_abrir_dialogo([{"quien": "", "texto": texto}])


func _abrir_dialogo(lineas: Array, despues: Callable = Callable()) -> void:
	if lineas.is_empty():
		if despues.is_valid():
			despues.call()
		return
	if jugador:
		jugador.bloqueado = true
	tactil.reiniciar()
	tactil.visible = false
	hud.fijar_accion("")
	dialogo.iniciar(lineas, func():
		if en_juego:
			jugador.bloqueado = false
			tactil.visible = true
		Juego.guardar_partida()
		if despues.is_valid():
			despues.call())


# ------------------------------------------------------------------ bucle
func _process(delta: float) -> void:
	if en_titulo and jugador:
		jugador.yaw += delta * 0.08
		return
	if not en_juego or dialogo.visible or jugador == null:
		return
	_objetivo_entidad = null
	var mejor := DISTANCIA_INTERACCION
	for e in get_tree().get_nodes_in_group("interactuable"):
		var d := Vector2(e.global_position.x - jugador.global_position.x, e.global_position.z - jugador.global_position.z).length()
		if d < mejor:
			mejor = d
			_objetivo_entidad = e
	hud.fijar_accion(_objetivo_entidad.texto_accion() if _objetivo_entidad else "")
	_reloj -= delta
	if _reloj <= 0:
		_reloj = 0.5
		var texto := ""
		for o in datos_cap.get("objetivos", []):
			if not Juego.cumple(o.get("hecho", [])):
				texto = o.get("texto", "")
				break
		hud.fijar_objetivo(texto)


func _interactuar() -> void:
	if dialogo.visible:
		dialogo.avanzar()
	elif en_juego and _objetivo_entidad and is_instance_valid(_objetivo_entidad):
		_objetivo_entidad.interactuar(self)


func _cambiar_vista() -> void:
	if jugador:
		jugador.aplicar_vista(not Juego.primera_persona)
		Juego.guardar_ajustes()
		hud.actualizar()


func _unhandled_input(ev: InputEvent) -> void:
	if ev.is_action_pressed("interactuar"):
		_interactuar()
	elif ev.is_action_pressed("cambiar_vista") and en_juego:
		_cambiar_vista()
	elif ev.is_action_pressed("pausa") and en_juego and not dialogo.visible:
		_mostrar_pausa()


func _notification(what: int) -> void:
	# botón "atrás" de Android
	if what == NOTIFICATION_WM_GO_BACK_REQUEST and en_juego:
		_mostrar_pausa()


# ------------------------------------------------------------------ menús
func _limpiar_menu() -> void:
	for c in capa_menu.get_children():
		c.queue_free()


func _pantalla(oscurecer: float) -> VBoxContainer:
	_limpiar_menu()
	var fondo := ColorRect.new()
	fondo.color = Color(0.04, 0.03, 0.08, oscurecer)
	fondo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	capa_menu.add_child(fondo)
	var centro := CenterContainer.new()
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	capa_menu.add_child(centro)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 18)
	col.custom_minimum_size = Vector2(560, 0)
	centro.add_child(col)
	return col


func _texto(col: Control, t: String, tam: int, color := Color(1, 1, 1)) -> Label:
	var l := Label.new()
	l.text = t
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size", tam)
	l.add_theme_color_override("font_color", color)
	col.add_child(l)
	return l


func _boton(col: Control, t: String, accion: Callable) -> Button:
	var b := Button.new()
	b.text = t
	b.custom_minimum_size = Vector2(0, 76)
	b.add_theme_font_size_override("font_size", 32)
	b.pressed.connect(accion)
	col.add_child(b)
	return b


func mostrar_titulo() -> void:
	_modo_juego(false)
	_cargar_nivel(0)
	en_titulo = true
	jugador.sprite.visible = false
	jugador.brazo.spring_length = 9.0
	jugador.pitch = -0.35
	var col := _pantalla(0.45)
	_texto(col, "LUMBRAL", 120, Color("ffd36b"))
	_texto(col, "Una aventura de fe, esperanza, amor y perdón", 30, Color(1, 1, 1, 0.85))
	col.add_child(Control.new())
	if Juego.hay_partida():
		_boton(col, "Continuar", func():
			Juego.cargar_partida()
			iniciar_capitulo(Juego.capitulo))
	_boton(col, "Nueva aventura", _elegir_vista)


func _elegir_vista() -> void:
	var col := _pantalla(0.6)
	_texto(col, "¿Cómo quieres recorrer Lumbral?", 46, Color("ffd36b"))
	_boton(col, "Primera persona — ver con los ojos de Ezra", func():
		Juego.nueva_partida(true)
		iniciar_capitulo(0))
	_boton(col, "Tercera persona — ver a Ezra en el mundo", func():
		Juego.nueva_partida(false)
		iniciar_capitulo(0))
	_texto(col, "Puedes cambiarlo cuando quieras con el botón «Vista».", 24, Color(1, 1, 1, 0.7))


func _mostrar_pausa() -> void:
	if not en_juego:
		return
	_modo_juego(false)
	var col := _pantalla(0.6)
	_texto(col, "Pausa", 60, Color("ffd36b"))
	_texto(col, datos_cap.get("titulo", ""), 28)
	_boton(col, "Continuar", func():
		_limpiar_menu()
		_modo_juego(true))
	var vista_btn := _boton(col, "", Callable())
	var refrescar := func(): vista_btn.text = "Vista: primera persona" if Juego.primera_persona else "Vista: tercera persona"
	refrescar.call()
	vista_btn.pressed.connect(func():
		_cambiar_vista()
		refrescar.call())
	_texto(col, "Sensibilidad de la cámara", 24, Color(1, 1, 1, 0.8))
	var s := HSlider.new()
	s.min_value = 0.3
	s.max_value = 2.5
	s.step = 0.1
	s.value = Juego.sensibilidad
	s.custom_minimum_size = Vector2(0, 48)
	s.value_changed.connect(func(v):
		Juego.sensibilidad = v
		Juego.guardar_ajustes())
	col.add_child(s)
	_boton(col, "Guardar y volver al inicio", func():
		Juego.guardar_partida()
		mostrar_titulo())


func _mostrar_resumen() -> void:
	_modo_juego(false)
	var col := _pantalla(0.7)
	_texto(col, "Capítulo completado", 54, Color("ffd36b"))
	_texto(col, datos_cap.get("titulo", ""), 32)
	var total := 0
	for k in datos_cap.get("leyenda", {}):
		if datos_cap["leyenda"][k].get("efectos", {}).has("secreto"):
			total += 1
	var lineas := []
	for v in Juego.VIRTUDES:
		lineas.append("%s: %d" % [Juego.NOMBRE_VIRTUD[v], Juego.virtudes[v]])
	_texto(col, "   ".join(lineas), 30)
	_texto(col, "Luz del candil: %d%%     Secretos en total: %d (este capítulo tenía %d)" % [int(Juego.luz), Juego.secretos, total], 24, Color(1, 1, 1, 0.8))
	var siguiente := Juego.capitulo + 1
	if siguiente < Juego.CAPITULOS.size():
		Juego.capitulo = siguiente
		Juego.guardar_partida()
		_boton(col, "Seguir el camino", func(): iniciar_capitulo(siguiente))
	else:
		_boton(col, "Ver el final", _mostrar_final)


func _mostrar_final() -> void:
	_limpiar_menu()
	var final: Dictionary = datos_cap.get("final", {})
	var lineas: Array = final.get("antes", []) + final.get(Juego.virtud_mayor(), []) + final.get("despues", [])
	_abrir_dialogo(lineas, func():
		_modo_juego(false)
		var col := _pantalla(0.85)
		_texto(col, "Fin del primer viaje", 60, Color("ffd36b"))
		_texto(col, "«¿No ardía nuestro corazón mientras nos hablaba en el camino?» — Lucas 24:32", 30)
		_texto(col, "Gracias por jugar este prototipo de Lumbral.", 26, Color(1, 1, 1, 0.8))
		_boton(col, "Volver al inicio", func():
			if FileAccess.file_exists(Juego.RUTA_PARTIDA):
				DirAccess.remove_absolute(ProjectSettings.globalize_path(Juego.RUTA_PARTIDA))
			mostrar_titulo()))
