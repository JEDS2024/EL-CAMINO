extends Node
## Punto de entrada: crea la vista 3D pixelada, la interfaz y maneja el flujo del juego
## (título → elegir cámara → capítulos → final).

const ESCALA_PIXEL := 2  # la escena 3D se dibuja a 1/2 de la resolución y se agranda sin suavizar
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
var faro: Faro
var hablando_con := ""  # nombre de quien dice la línea actual del diálogo


func _ready() -> void:
	_crear_vista()
	_crear_ui()
	Juego.aviso.connect(hud.mostrar_aviso)
	Juego.aviso.connect(_sonido_aviso)
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
	hud.pedir_mochila.connect(_mostrar_mochila)
	tactil.excluir = [hud.boton_accion, hud.boton_vista, hud.boton_pausa, hud.boton_mochila]

	dialogo = CajaDialogo.new()
	raiz.add_child(dialogo)
	dialogo.resolver = func(id): return datos_cap.get("dialogos", {}).get(id, [])
	dialogo.linea_mostrada.connect(func(quien: String):
		hablando_con = quien
		if jugador:
			jugador.modelo.hablando = quien != "" and quien == String(datos_cap.get("protagonista", {}).get("nombre", "")))

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
	var prota: Dictionary = datos_cap.get("protagonista", {"nombre": "", "modelo": "david"})
	jugador.clave_modelo = prota.get("modelo", "david")
	nivel.add_child(jugador)
	jugador.position = nivel.inicio + Vector3(0, 0.2, 0)
	jugador.yaw = deg_to_rad(float(datos_cap.get("mirar_inicio", 0)))
	nivel.jugador = jugador
	nivel.particulas_ambiente(jugador, String(datos_cap.get("ambiente", {}).get("particulas", "")))
	faro = Faro.new()
	faro.visible = false
	nivel.add_child(faro)
	_reloj = 0.0
	var retratos := {String(prota.get("nombre", "")): jugador.clave_modelo}
	retratos.merge(datos_cap.get("retratos", {}))
	for clave in datos_cap.get("leyenda", {}):
		var def: Dictionary = datos_cap["leyenda"][clave]
		if def.get("tipo", "") == "npc":
			retratos[def.get("nombre", "")] = def.get("modelo", def.get("sprite", ""))
	dialogo.retratos = retratos


func iniciar_capitulo(i: int) -> void:
	_limpiar_menu()
	en_titulo = false
	Juego.capitulo = i
	Juego.guardar_partida()
	_cargar_nivel(i)
	_modo_juego(true)
	hud.actualizar()
	Sonido.tocar_musica(datos_cap.get("musica", "titulo"))
	Sonido.tocar_ambiente(datos_cap.get("ambiente_sonido", ""))
	var sub_titulo: String = datos_cap.get("subtitulo", "")
	if datos_cap.has("lugar"):
		sub_titulo += "  ·  " + String(datos_cap["lugar"])
	hud.mostrar_titulo(datos_cap.get("titulo", ""), sub_titulo)
	var marca := "intro_vista_%d" % i
	if not Juego.flags.get(marca, false):
		Juego.marcar(marca)
		await get_tree().create_timer(2.2).timeout
		_abrir_dialogo(datos_cap.get("intro", []), _ayuda_controles if i == 0 else Callable())


func _ayuda_controles() -> void:
	var texto := "Joystick para caminar · desliza en el resto de la pantalla para mirar"
	if not DisplayServer.is_touchscreen_available():
		texto = "WASD: caminar · Flechas o arrastrar el mouse: mirar · E: interactuar · C: vista"
	hud.mostrar_aviso(texto, "", 6.0)


func terminar_capitulo() -> void:
	Sonido.efecto("capitulo")
	var epilogo: Array = datos_cap.get("epilogo", [])
	if epilogo.is_empty():
		_mostrar_versiculo()
	else:
		_abrir_dialogo(epilogo, _mostrar_versiculo)


# ------------------------------------------------------------------ diálogos
func iniciar_dialogo(id: String, _entidad: Entidad = null) -> void:
	if id == "":
		return
	var lineas: Array = datos_cap.get("dialogos", {}).get(id, [])
	if lineas.is_empty():
		push_warning("Diálogo no encontrado: " + id)
		return
	Juego.marcar("visto_" + id)  # quita el «!» del personaje
	_abrir_dialogo(lineas)


func mostrar_lineas(lineas: Array) -> void:
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
		hablando_con = ""
		if jugador:
			jugador.modelo.hablando = false
		if en_juego:
			jugador.bloqueado = false
			tactil.visible = true
		Juego.guardar_partida()
		if despues.is_valid():
			despues.call()
		elif not Juego.minijuego_pedido.is_empty() and en_juego:
			var mj: Dictionary = Juego.minijuego_pedido
			Juego.minijuego_pedido = {}
			_mostrar_minijuego(mj)
		elif Juego.fin_pedido and en_juego:
			Juego.fin_pedido = false
			terminar_capitulo())


# ------------------------------------------------------------------ bucle
func _process(delta: float) -> void:
	if en_titulo and jugador:
		jugador.yaw += delta * 0.08
		return
	if not en_juego or dialogo.visible or jugador == null:
		return
	if _objetivo_entidad and is_instance_valid(_objetivo_entidad):
		_objetivo_entidad.resaltada = false
	_objetivo_entidad = null
	var mejor := DISTANCIA_INTERACCION
	for e in get_tree().get_nodes_in_group("interactuable"):
		var d := Vector2(e.global_position.x - jugador.global_position.x, e.global_position.z - jugador.global_position.z).length()
		if d < mejor:
			mejor = d
			_objetivo_entidad = e
	if _objetivo_entidad:
		_objetivo_entidad.resaltada = true
	hud.fijar_accion(_objetivo_entidad.texto_accion() if _objetivo_entidad else "")
	_reloj -= delta
	if _reloj <= 0:
		_reloj = 0.5
		var actual: Dictionary = {}
		for o in datos_cap.get("objetivos", []):
			if not Juego.cumple(o.get("hecho", [])):
				actual = o
				break
		hud.fijar_objetivo(actual.get("texto", ""))
		_actualizar_faro(actual)


## Coloca el faro sobre el objetivo: la entidad más cercana con una de las letras de "marca",
## o la siguiente lámpara de "marca_acertijo".
func _actualizar_faro(o: Dictionary) -> void:
	var destino: Entidad = null
	if o.has("marca_acertijo"):
		destino = nivel.siguiente_del_acertijo(o["marca_acertijo"])
	elif o.has("marca"):
		var mejor := INF
		for e in nivel.entidades:
			if is_instance_valid(e) and e.activo and e.is_in_group("interactuable") and e.letra in String(o["marca"]):
				var d := e.global_position.distance_to(jugador.global_position)
				if d < mejor:
					mejor = d
					destino = e
	for e in nivel.entidades:
		if is_instance_valid(e):
			e.marcada = Juego.guia and e == destino
	faro.visible = Juego.guia and destino != null
	if destino:
		faro.global_position = destino.global_position


func _interactuar() -> void:
	if dialogo.visible:
		dialogo.avanzar()
	elif en_juego and _objetivo_entidad and is_instance_valid(_objetivo_entidad):
		var e := _objetivo_entidad
		# el jugador se gira hacia lo que usa y hace un gesto
		var hacia := e.global_position - jugador.global_position
		hacia.y = 0
		jugador.modelo.actualizar(0.2, hacia, false)
		match e.tipo:
			"objeto": jugador.modelo.gesto("recoger")
			"lampara", "mecanismo": jugador.modelo.gesto("encender")
			"npc": jugador.modelo.gesto("saludar")
		e.interactuar(self)


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
	elif ev.is_action_pressed("mochila") and en_juego and not dialogo.visible:
		_mostrar_mochila()


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
	b.pressed.connect(func(): Sonido.efecto("seleccion", 0.7))
	if accion.is_valid():
		b.pressed.connect(accion)
	col.add_child(b)
	return b


func _sonido_aviso(_texto: String, icono: String) -> void:
	if icono in Juego.VIRTUDES:
		Sonido.efecto("virtud", 0.8)


func mostrar_titulo() -> void:
	_modo_juego(false)
	_cargar_nivel(0)
	en_titulo = true
	Sonido.tocar_musica("titulo")
	Sonido.tocar_ambiente("")
	jugador.brazo.spring_length = 9.0
	jugador.pitch = -0.35
	faro.visible = false
	var col := _pantalla(0.35)
	_logo(col)
	col.add_child(Control.new())
	if Juego.hay_partida():
		_boton(col, "Continuar", func():
			Juego.cargar_partida()
			jugar_capitulo(Juego.capitulo))
		_boton(col, "Capítulos", func():
			Juego.cargar_partida()
			_mostrar_capitulos())
	_boton(col, "Nueva aventura", _elegir_vista)
	_boton(col, "Ajustes", func(): _mostrar_ajustes(mostrar_titulo))


const FRASES_PORTADA := [
	"¡Historias reales de la Biblia!", "¡Cinco piedras lisas!", "¡De Jehová es la batalla!",
	"¡Tu pueblo será mi pueblo!", "¡Yo soy José!", "¡Levantémonos y edifiquemos!",
	"¡Ardía nuestro corazón!", "¡Para niños y adultos!",
]


## Logo grande con sombra y una frase amarilla inclinada que late (como en Minecraft).
func _logo(col: Control) -> void:
	var caja := Control.new()
	caja.custom_minimum_size = Vector2(760, 190)
	col.add_child(caja)
	var titulo := Label.new()
	titulo.text = "EL CAMINO"
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.add_theme_font_size_override("font_size", 150)
	titulo.add_theme_color_override("font_color", Color("f0d48a"))
	titulo.add_theme_color_override("font_outline_color", Color("3a2a18"))
	titulo.add_theme_constant_override("outline_size", 18)
	titulo.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
	titulo.add_theme_constant_override("shadow_offset_x", 8)
	titulo.add_theme_constant_override("shadow_offset_y", 8)
	Tema.anclar(titulo, 0, 0, 1, 0)
	caja.add_child(titulo)
	var sub := Label.new()
	sub.text = "Historias de la Biblia"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 34)
	Tema.anclar(sub, 0, 0, 1, 0)
	sub.offset_top = 150
	caja.add_child(sub)
	var frase := Label.new()
	frase.text = FRASES_PORTADA[randi() % FRASES_PORTADA.size()]
	frase.add_theme_font_size_override("font_size", 30)
	frase.add_theme_color_override("font_color", Color("ffff40"))
	frase.add_theme_color_override("font_shadow_color", Color("3f3f00"))
	frase.position = Vector2(560, 120)
	frase.rotation_degrees = -16
	caja.add_child(frase)
	frase.pivot_offset = Vector2(frase.get_minimum_size().x / 2, 16)
	var t: Tween = frase.create_tween().set_loops()
	t.tween_property(frase, "scale", Vector2(1.08, 1.08), 0.35).set_trans(Tween.TRANS_SINE)
	t.tween_property(frase, "scale", Vector2(0.96, 0.96), 0.35).set_trans(Tween.TRANS_SINE)


func _elegir_vista() -> void:
	var col := _pantalla(0.6)
	_texto(col, "¿Cómo quieres recorrer el camino?", 46, Color("ffd36b"))
	_boton(col, "Primera persona — ver con los ojos del protagonista", func():
		Juego.nueva_partida(true)
		_mostrar_mapa_camino(0))
	_boton(col, "Tercera persona — ver al protagonista en el mundo", func():
		Juego.nueva_partida(false)
		_mostrar_mapa_camino(0))
	_texto(col, "Puedes cambiarlo cuando quieras con el botón «Vista».", 24, Color(1, 1, 1, 0.7))
	_boton(col, "Volver", mostrar_titulo)


## Empieza un capítulo; si ya se había terminado, se juega otra vez desde cero.
func jugar_capitulo(i: int) -> void:
	if i in Juego.completados:
		Juego.reiniciar_capitulo(i)
	iniciar_capitulo(i)


## Mapa ilustrado antes de cada historia: dónde ocurre y cuánto camino llevas.
func _mostrar_mapa_camino(i: int) -> void:
	_modo_juego(false)
	var col := _pantalla(0.85)
	col.custom_minimum_size = Vector2(940, 0)
	var d := Juego.datos_capitulo(i)
	_texto(col, "El camino · historia %d de %d" % [i + 1, Juego.CAPITULOS.size()], 34, Color("ffd36b"))
	var mapa := MapaCamino.new()
	mapa.actual = i
	mapa.completados = Juego.completados
	col.add_child(mapa)
	_texto(col, "%s  ·  %s  ·  %s" % [d.get("titulo", ""), d.get("subtitulo", ""), d.get("lugar", "")], 28)
	_boton(col, "Comenzar", jugar_capitulo.bind(i))


func _estrellas(padre: Control, n: int, tam := 34) -> void:
	var fila := HBoxContainer.new()
	fila.alignment = BoxContainer.ALIGNMENT_CENTER
	for k in 3:
		var t := TextureRect.new()
		t.texture = load("res://assets/iconos/estrella.png")
		t.custom_minimum_size = Vector2(tam, tam)
		t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		t.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		t.modulate = Color.WHITE if k < n else Color(0.25, 0.22, 0.32)
		fila.add_child(t)
	padre.add_child(fila)


func _mostrar_capitulos() -> void:
	var col := _pantalla(0.7)
	col.custom_minimum_size = Vector2(760, 0)
	_texto(col, "Capítulos", 56, Color("ffd36b"))
	for i in Juego.CAPITULOS.size():
		var d := Juego.datos_capitulo(i)
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 16)
		col.add_child(fila)
		var abierto := i <= Juego.capitulo_max
		var b := _boton(fila, "%d. %s  ·  %s" % [i + 1, d.get("titulo", ""), d.get("subtitulo", "")] if abierto else "%d. ???  ·  (termina el anterior)" % (i + 1),
			jugar_capitulo.bind(i))
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.disabled = not abierto
		b.add_theme_font_size_override("font_size", 26)
		_estrellas(fila, int(Juego.estrellas.get(str(i), 0)), 28)
	_boton(col, "Volver", mostrar_titulo)


func _mostrar_ajustes(volver: Callable) -> void:
	var col := _pantalla(0.75)
	col.custom_minimum_size = Vector2(620, 0)
	_texto(col, "Ajustes", 56, Color("ffd36b"))
	var deslizador := func(titulo: String, clave: String, minimo: float, maximo: float):
		_texto(col, titulo, 24, Color(1, 1, 1, 0.85))
		var sl := HSlider.new()
		sl.min_value = minimo
		sl.max_value = maximo
		sl.step = 0.05
		sl.value = Juego.get(clave)
		sl.custom_minimum_size = Vector2(0, 44)
		sl.value_changed.connect(func(v):
			Juego.set(clave, v)
			Juego.guardar_ajustes()
			Sonido.aplicar_volumenes())
		col.add_child(sl)
	deslizador.call("Volumen de la música", "vol_musica", 0.0, 1.0)
	deslizador.call("Volumen de los efectos", "vol_efectos", 0.0, 1.0)
	deslizador.call("Sensibilidad de la cámara", "sensibilidad", 0.3, 2.5)
	var interruptor := func(titulo: String, clave: String):
		var c := CheckButton.new()
		c.text = titulo
		c.button_pressed = Juego.get(clave)
		c.add_theme_font_size_override("font_size", 28)
		c.toggled.connect(func(v):
			Juego.set(clave, v)
			Juego.guardar_ajustes()
			Sonido.efecto("seleccion", 0.6))
		col.add_child(c)
	interruptor.call("Leer los diálogos en voz alta", "leer_voz")
	interruptor.call("Texto grande", "texto_grande")
	interruptor.call("Guía: faro sobre el objetivo y «!» en personajes", "guia")
	interruptor.call("Primera persona", "primera_persona")
	if Juego.leer_voz and DisplayServer.tts_get_voices_for_language("es").is_empty():
		_texto(col, "No se encontró una voz en español en este dispositivo.", 22, Color(1, 0.7, 0.6))
	_boton(col, "Volver", func():
		if jugador:
			jugador.aplicar_vista(Juego.primera_persona, false)
		volver.call())


func _mostrar_pausa() -> void:
	if not en_juego:
		return
	_modo_juego(false)
	var col := _pantalla(0.6)
	_texto(col, "Pausa", 60, Color("ffd36b"))
	_texto(col, "%s · %s" % [datos_cap.get("titulo", ""), datos_cap.get("subtitulo", "")], 28)
	_boton(col, "Continuar", func():
		_limpiar_menu()
		_modo_juego(true))
	_boton(col, "Ajustes", func(): _mostrar_ajustes(_volver_a_pausa))
	_boton(col, "Reiniciar este capítulo", func():
		Juego.reiniciar_capitulo(Juego.capitulo)
		iniciar_capitulo(Juego.capitulo))
	_boton(col, "Guardar y volver al inicio", func():
		Juego.guardar_partida()
		mostrar_titulo())


## Minijuegos dentro de una historia; al ganar sigue el diálogo indicado en "exito".
func _mostrar_minijuego(mj: Dictionary) -> void:
	_modo_juego(false)
	_limpiar_menu()
	var juego := MinijuegoHonda.new()
	capa_menu.add_child(juego)
	juego.terminado.connect(func():
		_limpiar_menu()
		_modo_juego(true)
		iniciar_dialogo(String(mj.get("exito", ""))))


## Mochila: lo recogido en este capítulo, las reliquias del viaje y los versículos aprendidos.
func _mostrar_mochila() -> void:
	if not en_juego:
		return
	_modo_juego(false)
	var col := _pantalla(0.6)
	col.custom_minimum_size = Vector2(760, 0)
	_texto(col, "Mochila", 52, Color("ffd36b"))
	var panel := PanelContainer.new()
	col.add_child(panel)
	var dentro := VBoxContainer.new()
	dentro.add_theme_constant_override("separation", 10)
	panel.add_child(dentro)
	_texto(dentro, "En este capítulo", 26, Color("e8c26a"))
	var rejilla := GridContainer.new()
	rejilla.columns = 9
	rejilla.add_theme_constant_override("h_separation", 4)
	rejilla.add_theme_constant_override("v_separation", 4)
	dentro.add_child(rejilla)
	var objetos: Array = Juego.inventario_capitulo().values()
	var reliquias: Array = Juego.reliquias()
	for i in 18:
		var c := Panel.new()
		c.custom_minimum_size = Vector2(70, 70)
		var o: Dictionary = objetos[i] if i < objetos.size() else {}
		c.add_theme_stylebox_override("panel", Tema.textura("ranura_sel" if o.get("reliquia", false) else "ranura", Vector2.ZERO))
		if o.has("icono"):
			c.tooltip_text = o["nombre"]
			var ic := TextureRect.new()
			ic.texture = load("res://assets/iconos/%s.png" % o["icono"])
			ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			ic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			ic.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			ic.offset_left = 12
			ic.offset_top = 12
			ic.offset_right = -12
			ic.offset_bottom = -12
			ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
			c.add_child(ic)
		rejilla.add_child(c)
	var nombres := []
	for o in objetos:
		nombres.append("%s ×%d" % [o["nombre"], o["cantidad"]] if o["cantidad"] > 1 else String(o["nombre"]))
	_texto(dentro, ", ".join(nombres) if not nombres.is_empty() else "Todavía no has recogido nada.", 22, Color(1, 1, 1, 0.85))
	var nombres_rel := reliquias.map(func(r): return r["nombre"])
	_texto(dentro, "Reliquias del viaje (%d): %s" % [reliquias.size(), ", ".join(nombres_rel) if not nombres_rel.is_empty() else "busca secretos escondidos"], 22, Color("ffe7a0"))
	var versos := []
	for i in Juego.CAPITULOS.size():
		if i in Juego.completados:
			var rep: Dictionary = Juego.datos_capitulo(i).get("repaso", {})
			versos.append("«%s» (%s)" % [rep.get("versiculo", ""), rep.get("cita", "")])
	if not versos.is_empty():
		_texto(dentro, "Versículos aprendidos", 24, Color("e8c26a"))
		var l := _texto(dentro, "\n".join(versos), 22, Color(1, 1, 1, 0.9))
		l.add_theme_font_override("font", Tema.fuente_lectura())
	_boton(col, "Volver", func():
		_limpiar_menu()
		_modo_juego(true))


func _volver_a_pausa() -> void:
	en_juego = true
	_mostrar_pausa()


# ------------------------------------------------------------------ repaso al final del capítulo
var _aciertos := 0


func _mostrar_versiculo() -> void:
	_modo_juego(false)
	var rep: Dictionary = datos_cap.get("repaso", {})
	if rep.is_empty():
		_mostrar_resumen()
		return
	var col := _pantalla(0.82)
	col.custom_minimum_size = Vector2(820, 0)
	_texto(col, "Versículo para recordar", 40, Color("ffd36b"))
	var panel := PanelContainer.new()
	col.add_child(panel)
	var dentro := VBoxContainer.new()
	panel.add_child(dentro)
	_texto(dentro, "«%s»" % rep.get("versiculo", ""), 44 if Juego.texto_grande else 38)
	_texto(dentro, rep.get("cita", ""), 30, Color("ffd36b"))
	if Juego.leer_voz:
		var voces := DisplayServer.tts_get_voices_for_language("es")
		if not voces.is_empty():
			DisplayServer.tts_stop()
			DisplayServer.tts_speak("%s. %s" % [rep.get("versiculo", ""), rep.get("cita", "")], voces[0])
	_aciertos = 0
	_boton(col, "Responder preguntas", _mostrar_pregunta.bind(0))


func _mostrar_pregunta(n: int) -> void:
	var preguntas: Array = datos_cap.get("repaso", {}).get("preguntas", [])
	if n >= preguntas.size():
		var k := str(Juego.capitulo)
		Juego.estrellas[k] = maxi(int(Juego.estrellas.get(k, 0)), _aciertos)
		_mostrar_resumen()
		return
	var p: Dictionary = preguntas[n]
	var col := _pantalla(0.82)
	col.custom_minimum_size = Vector2(820, 0)
	_texto(col, "Pregunta %d de %d" % [n + 1, preguntas.size()], 28, Color("ffd36b"))
	_texto(col, p.get("pregunta", ""), 44 if Juego.texto_grande else 38)
	if Juego.leer_voz:
		var voces := DisplayServer.tts_get_voices_for_language("es")
		if not voces.is_empty():
			DisplayServer.tts_stop()
			DisplayServer.tts_speak(p.get("pregunta", ""), voces[0])
	var botones: Array[Button] = []
	for j in p.get("opciones", []).size():
		var b := _boton(col, p["opciones"][j], Callable())
		botones.append(b)
	for j in botones.size():
		botones[j].pressed.connect(func():
			var bien: bool = j == int(p.get("correcta", 0))
			if bien:
				_aciertos += 1
			Sonido.efecto("correcto" if bien else "fallo")
			for b2 in botones:
				b2.disabled = true
			botones[int(p.get("correcta", 0))].modulate = Color(0.6, 1.0, 0.6)
			if not bien:
				botones[j].modulate = Color(1.0, 0.55, 0.55)
			_texto(col, ("¡Correcto! " if bien else "Casi. ") + p.get("explica", ""), 28, Color(0.75, 1, 0.75) if bien else Color(1, 0.85, 0.7))
			_boton(col, "Siguiente", _mostrar_pregunta.bind(n + 1)))


func _confeti() -> void:
	var c := CPUParticles2D.new()
	c.position = Vector2(get_viewport().get_visible_rect().size.x / 2, -20)
	c.emitting = true
	c.one_shot = true
	c.amount = 160
	c.lifetime = 3.0
	c.explosiveness = 0.85
	c.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	c.emission_rect_extents = Vector2(get_viewport().get_visible_rect().size.x / 2, 10)
	c.direction = Vector2(0, 1)
	c.spread = 30.0
	c.initial_velocity_min = 120.0
	c.initial_velocity_max = 320.0
	c.gravity = Vector2(0, 260)
	c.angular_velocity_min = -360.0
	c.angular_velocity_max = 360.0
	c.scale_amount_min = 6.0
	c.scale_amount_max = 11.0
	var g := Gradient.new()
	g.colors = PackedColorArray([Color("ffd36b"), Color("ff6f7d"), Color("8fd3ff"), Color("8be07a")])
	g.offsets = PackedFloat32Array([0.0, 0.33, 0.66, 1.0])
	c.color_initial_ramp = g
	capa_menu.add_child(c)


func _mostrar_resumen() -> void:
	_modo_juego(false)
	if not Juego.capitulo in Juego.completados:
		Juego.completados.append(Juego.capitulo)
	Juego.capitulo_max = maxi(Juego.capitulo_max, mini(Juego.capitulo + 1, Juego.CAPITULOS.size() - 1))
	var col := _pantalla(0.7)
	_texto(col, "¡Capítulo completado!", 54, Color("ffd36b"))
	_texto(col, "%s · %s" % [datos_cap.get("titulo", ""), datos_cap.get("subtitulo", "")], 30)
	_estrellas(col, int(Juego.estrellas.get(str(Juego.capitulo), 0)), 56)
	var total := 0
	for k in datos_cap.get("leyenda", {}):
		if datos_cap["leyenda"][k].get("efectos", {}).has("secreto"):
			total += 1
	var lineas := []
	for v in Juego.VIRTUDES:
		lineas.append("%s: %d" % [Juego.NOMBRE_VIRTUD[v], Juego.virtudes[v]])
	_texto(col, "   ".join(lineas), 30)
	var hallados := int(Juego.registro.get(str(Juego.capitulo), {}).get("secretos", 0))
	_texto(col, "Secretos de este capítulo: %d de %d     Luz del candil: %d%%" % [hallados, total, int(Juego.luz)], 24, Color(1, 1, 1, 0.8))
	_confeti()
	var siguiente := Juego.capitulo + 1
	if siguiente < Juego.CAPITULOS.size():
		Juego.capitulo = siguiente
		Juego.guardar_partida()
		_boton(col, "Seguir el camino", _mostrar_mapa_camino.bind(siguiente))
		_boton(col, "Volver al inicio", mostrar_titulo)
	else:
		Juego.guardar_partida()
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
		_texto(col, "Puedes volver a jugar cualquier historia desde «Capítulos» para buscar todas las estrellas y secretos.", 26, Color(1, 1, 1, 0.8))
		_confeti()
		_boton(col, "Volver al inicio", mostrar_titulo))
