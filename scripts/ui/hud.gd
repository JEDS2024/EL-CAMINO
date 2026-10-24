class_name Hud
extends Control
## HUD inspirado en Minecraft: barra de 9 casillas abajo con lo recogido, virtudes encima
## (como los corazones), barra de luz (como la de experiencia), mira en primera persona,
## objetivo arriba, avisos y botones táctiles.

signal pedir_interactuar
signal pedir_vista
signal pedir_pausa
signal pedir_mochila
signal pedir_ayuda
signal pedir_picar
signal pedir_poner
signal elegir_casilla(i: int)

const CASILLAS := 9
const TAM_CASILLA := 62

var boton_accion: Button
var boton_vista: Button
var boton_pausa: Button
var boton_mochila: Button
var boton_ayuda: Button
var _mision: PanelContainer
var _mision_titulo: Label
var _mision_texto: Label
var _tween_mision: Tween
var boton_picar: Button
var boton_poner: Button
var barra: HBoxContainer
var construir := false  # el capítulo tiene bloques: se muestran Picar/Poner y la mira
var casilla_elegida := -1
var _marco: Panel
var _valores := {}
var _barra_luz: ProgressBar
var _texto_luz: Label
var _casillas: Array[Panel] = []
var _iconos: Array[TextureRect] = []
var _cantidades: Array[Label] = []
var _mira: Label
var _objetivo: Label
var _titulo: Label
var _subtitulo: Label
var _aviso: Label
var _tween_aviso: Tween


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	# barra de objetos (abajo al centro)
	barra = HBoxContainer.new()
	barra.add_theme_constant_override("separation", 2)
	barra.anchor_left = 0.5
	barra.anchor_right = 0.5
	barra.anchor_top = 1.0
	barra.anchor_bottom = 1.0
	barra.offset_left = -(TAM_CASILLA * CASILLAS + 2 * (CASILLAS - 1)) / 2.0
	barra.offset_right = -barra.offset_left
	barra.offset_top = -TAM_CASILLA - 12
	barra.offset_bottom = -12
	barra.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(barra)
	for i in CASILLAS:
		var c := Panel.new()
		c.custom_minimum_size = Vector2(TAM_CASILLA, TAM_CASILLA)
		c.add_theme_stylebox_override("panel", Tema.textura("ranura", Vector2.ZERO))
		c.mouse_filter = Control.MOUSE_FILTER_STOP
		c.gui_input.connect(func(ev: InputEvent):
			if (ev is InputEventScreenTouch or ev is InputEventMouseButton) and ev.pressed:
				elegir_casilla.emit(i))
		barra.add_child(c)
		var ic := TextureRect.new()
		ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ic.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		ic.offset_left = 10
		ic.offset_top = 10
		ic.offset_right = -10
		ic.offset_bottom = -10
		c.add_child(ic)
		var n := Label.new()
		n.add_theme_font_size_override("font_size", 22)
		n.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		n.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
		n.offset_left = -40
		n.offset_top = -30
		n.offset_right = -6
		n.offset_bottom = -2
		n.mouse_filter = Control.MOUSE_FILTER_IGNORE
		c.add_child(n)
		_casillas.append(c)
		_iconos.append(ic)
		_cantidades.append(n)

	# marco blanco sobre la casilla elegida (como en Minecraft)
	_marco = Panel.new()
	var borde := StyleBoxFlat.new()
	borde.bg_color = Color(0, 0, 0, 0)
	borde.border_color = Color(1, 1, 1, 0.95)
	borde.set_border_width_all(4)
	_marco.add_theme_stylebox_override("panel", borde)
	_marco.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_marco.visible = false

	# barra de luz (como la experiencia) justo encima
	_barra_luz = ProgressBar.new()
	_barra_luz.show_percentage = false
	_barra_luz.anchor_left = 0.5
	_barra_luz.anchor_right = 0.5
	_barra_luz.anchor_top = 1.0
	_barra_luz.anchor_bottom = 1.0
	_barra_luz.offset_left = barra.offset_left
	_barra_luz.offset_right = barra.offset_right
	_barra_luz.offset_top = barra.offset_top - 16
	_barra_luz.offset_bottom = barra.offset_top - 4
	var fondo := StyleBoxFlat.new()
	fondo.bg_color = Color(0.05, 0.05, 0.08, 0.85)
	fondo.border_color = Color.BLACK
	fondo.set_border_width_all(2)
	var relleno := StyleBoxFlat.new()
	relleno.bg_color = Color("ffc84a")
	relleno.border_color = Color("8a5a10")
	relleno.set_border_width_all(2)
	_barra_luz.add_theme_stylebox_override("background", fondo)
	_barra_luz.add_theme_stylebox_override("fill", relleno)
	_barra_luz.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_barra_luz)
	_texto_luz = _etiqueta(22, Color("ffe7a0"))
	_texto_luz.anchor_left = 0.5
	_texto_luz.anchor_right = 0.5
	_texto_luz.anchor_top = 1.0
	_texto_luz.anchor_bottom = 1.0
	_texto_luz.offset_left = -60
	_texto_luz.offset_right = 60
	_texto_luz.offset_top = barra.offset_top - 34
	_texto_luz.offset_bottom = barra.offset_top - 10

	# virtudes encima, a la izquierda de la barra (como los corazones)
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 8)
	fila.anchor_left = 0.5
	fila.anchor_right = 0.5
	fila.anchor_top = 1.0
	fila.anchor_bottom = 1.0
	fila.offset_left = barra.offset_left
	fila.offset_right = barra.offset_left + 300
	fila.offset_top = barra.offset_top - 52
	fila.offset_bottom = barra.offset_top - 20
	fila.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fila)
	for v in Juego.VIRTUDES:
		var ic := TextureRect.new()
		ic.texture = load("res://assets/iconos/%s.png" % v)
		ic.custom_minimum_size = Vector2(30, 30)
		ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		fila.add_child(ic)
		var lb := Label.new()
		lb.add_theme_font_size_override("font_size", 24)
		fila.add_child(lb)
		_valores[v] = lb

	# mira central (solo en primera persona)
	_mira = _etiqueta(34, Color(1, 1, 1, 0.85))
	_mira.text = "+"
	Tema.anclar(_mira, 0.5, 0.5, 0.5, 0.5)
	_mira.offset_left = -20
	_mira.offset_right = 20
	_mira.offset_top = -24
	_mira.offset_bottom = 20

	# objetivo, título y avisos (arriba al centro)
	_objetivo = _etiqueta(26, Color("fff3dc"))
	Tema.anclar(_objetivo, 0.2, 0.0, 0.7, 0.0)
	_objetivo.offset_top = 18
	_objetivo.add_theme_stylebox_override("normal", Tema.textura("panel", Vector2(18, 8)))
	_titulo = _etiqueta(68, Color("ffd36b"))
	Tema.anclar(_titulo, 0.1, 0.24, 0.9, 0.24)
	_subtitulo = _etiqueta(30, Color(1, 1, 1, 0.9))
	Tema.anclar(_subtitulo, 0.1, 0.36, 0.9, 0.36)
	_aviso = _etiqueta(34, Color("ffff80"))
	Tema.anclar(_aviso, 0.25, 0.62, 0.75, 0.62)
	_aviso.modulate.a = 0

	# botones táctiles
	boton_pausa = _boton("II", Vector2(72, 64))
	_esquina(boton_pausa, -92, 18, -20, 82)
	boton_pausa.pressed.connect(func(): pedir_pausa.emit())
	boton_vista = _boton("", Vector2(150, 64))
	_esquina(boton_vista, -258, 18, -104, 82)
	boton_vista.pressed.connect(func(): pedir_vista.emit())
	boton_ayuda = _boton("?", Vector2(72, 64))
	_esquina(boton_ayuda, -338, 18, -266, 82)
	boton_ayuda.add_theme_font_size_override("font_size", 34)
	boton_ayuda.tooltip_text = "¿Qué hago ahora?"
	boton_ayuda.pressed.connect(func(): pedir_ayuda.emit())
	_crear_tarjeta_mision()
	boton_mochila = _boton("Mochila", Vector2(150, 64))
	_esquina(boton_mochila, -258, 94, -104, 158)
	boton_mochila.pressed.connect(func(): pedir_mochila.emit())
	boton_accion = _boton("Hablar", Vector2(190, 110))
	boton_accion.add_theme_font_size_override("font_size", 34)
	boton_accion.anchor_left = 1.0
	boton_accion.anchor_right = 1.0
	boton_accion.anchor_top = 1.0
	boton_accion.anchor_bottom = 1.0
	boton_accion.offset_left = -240
	boton_accion.offset_right = -40
	boton_accion.offset_top = -170
	boton_accion.offset_bottom = -50
	boton_accion.visible = false
	boton_accion.pressed.connect(func(): pedir_interactuar.emit())
	# construir: encima del botón de acción
	boton_poner = _boton("Poner", Vector2(96, 96))
	_esquina_abajo(boton_poner, -240, -286, -144, -190)
	boton_poner.pressed.connect(func(): pedir_poner.emit())
	boton_picar = _boton("Picar", Vector2(96, 96))
	_esquina_abajo(boton_picar, -136, -286, -40, -190)
	boton_picar.pressed.connect(func(): pedir_picar.emit())
	for b in [boton_poner, boton_picar]:
		b.add_theme_font_size_override("font_size", 26)
		b.visible = false

	Juego.estado_cambiado.connect(actualizar)
	actualizar()


func _esquina(b: Control, izq: float, arriba: float, der: float, abajo: float) -> void:
	b.anchor_left = 1.0
	b.anchor_right = 1.0
	b.offset_left = izq
	b.offset_right = der
	b.offset_top = arriba
	b.offset_bottom = abajo


func _esquina_abajo(b: Control, izq: float, arriba: float, der: float, abajo: float) -> void:
	b.anchor_left = 1.0
	b.anchor_right = 1.0
	b.anchor_top = 1.0
	b.anchor_bottom = 1.0
	b.offset_left = izq
	b.offset_right = der
	b.offset_top = arriba
	b.offset_bottom = abajo


func _etiqueta(tam: int, color: Color) -> Label:
	var l := Label.new()
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size", tam)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(0.05, 0.03, 0.1))
	l.add_theme_constant_override("outline_size", 8)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(l)
	return l


func _boton(texto: String, tam: Vector2) -> Button:
	var b := Button.new()
	b.text = texto
	b.custom_minimum_size = tam
	b.focus_mode = Control.FOCUS_NONE
	add_child(b)
	return b


func actualizar() -> void:
	for v in _valores:
		_valores[v].text = str(Juego.virtudes[v])
	create_tween().tween_property(_barra_luz, "value", Juego.luz, 0.6)
	_texto_luz.text = "Luz %d" % int(Juego.luz)
	boton_vista.text = "Vista: 1ª" if Juego.primera_persona else "Vista: 3ª"
	_mira.visible = Juego.primera_persona or construir
	var objetos: Array = Juego.inventario_capitulo().values()
	for i in CASILLAS:
		var o: Dictionary = objetos[i] if i < objetos.size() else {}
		_iconos[i].texture = load("res://assets/iconos/%s.png" % o["icono"]) if o.has("icono") else null
		_cantidades[i].text = str(o["cantidad"]) if o.get("cantidad", 0) > 1 else ""
		_casillas[i].add_theme_stylebox_override("panel", Tema.textura("ranura_sel" if o.get("reliquia", false) else "ranura", Vector2.ZERO))
	_marco.visible = casilla_elegida >= 0 and casilla_elegida < CASILLAS
	if _marco.visible:
		if _marco.get_parent():
			_marco.get_parent().remove_child(_marco)
		_casillas[casilla_elegida].add_child(_marco)
		_marco.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_marco.offset_left = -3
		_marco.offset_top = -3
		_marco.offset_right = 3
		_marco.offset_bottom = 3


## Muestra u oculta Picar/Poner; se atenúan cuando no hay nada que picar o dónde poner.
func fijar_construccion(visible_si: bool, puede_picar: bool, puede_poner: bool) -> void:
	for b in [boton_picar, boton_poner]:
		b.visible = visible_si
	boton_picar.modulate.a = 1.0 if puede_picar else 0.45
	boton_poner.modulate.a = 1.0 if puede_poner else 0.45


func fijar_accion(texto: String) -> void:
	boton_accion.visible = texto != ""
	boton_accion.text = texto


## Tarjeta «Nueva misión»: qué hay que hacer y cómo, debajo del objetivo. No detiene el juego.
func _crear_tarjeta_mision() -> void:
	_mision = PanelContainer.new()
	Tema.anclar(_mision, 0.2, 0.0, 0.7, 0.0)
	_mision.offset_top = 78
	_mision.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mision.modulate.a = 0.0
	add_child(_mision)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 6)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mision.add_child(col)
	_mision_titulo = Label.new()
	_mision_titulo.add_theme_color_override("font_color", Color("ffd36b"))
	_mision_titulo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(_mision_titulo)
	_mision_texto = Label.new()
	_mision_texto.add_theme_font_override("font", Tema.fuente_lectura())
	_mision_texto.add_theme_color_override("font_color", Color("fff3dc"))
	_mision_texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(_mision_texto)


## Muestra la misión con su explicación durante unos segundos.
func mostrar_mision(titulo: String, como: String, nueva: bool) -> void:
	if titulo == "":
		return
	_mision_titulo.text = ("Nueva misión: " if nueva else "Misión: ") + titulo
	_mision_texto.text = como
	_mision_texto.visible = como != ""
	var grande := Juego.texto_grande
	_mision_titulo.add_theme_font_size_override("font_size", 30 if grande else 26)
	_mision_texto.add_theme_font_size_override("font_size", 34 if grande else 28)
	_colocar_mision.call_deferred()
	if _tween_mision:
		_tween_mision.kill()
	_tween_mision = create_tween()
	_tween_mision.tween_property(_mision, "modulate:a", 1.0, 0.3)
	_tween_mision.tween_interval(clampf(4.0 + como.length() * 0.06, 6.0, 14.0))
	_tween_mision.tween_property(_mision, "modulate:a", 0.0, 0.8)


## Siempre debajo del objetivo, aunque este ocupe dos líneas (su alto se conoce un cuadro después).
func _colocar_mision() -> void:
	_objetivo.offset_bottom = _objetivo.offset_top + _objetivo.get_combined_minimum_size().y
	_mision.offset_top = _objetivo.position.y + _objetivo.size.y + 10 if _objetivo.visible else 18.0


func ocultar_mision() -> void:
	if _tween_mision:
		_tween_mision.kill()
	_mision.modulate.a = 0.0


func fijar_objetivo(texto: String) -> void:
	_objetivo.text = ("» " + texto) if texto != "" else ""
	_objetivo.visible = texto != ""
	_colocar_mision.call_deferred()


func mostrar_titulo(titulo: String, subtitulo: String) -> void:
	_titulo.text = titulo
	_subtitulo.text = subtitulo
	var t := create_tween()
	_titulo.modulate.a = 0
	_subtitulo.modulate.a = 0
	t.tween_property(_titulo, "modulate:a", 1.0, 0.8)
	t.parallel().tween_property(_subtitulo, "modulate:a", 1.0, 1.2)
	t.tween_interval(2.4)
	t.tween_property(_titulo, "modulate:a", 0.0, 1.0)
	t.parallel().tween_property(_subtitulo, "modulate:a", 0.0, 1.0)


func mostrar_aviso(texto: String, _icono: String, segundos := 1.6) -> void:
	if _tween_aviso:
		_tween_aviso.kill()
	_aviso.text = texto
	_aviso.modulate.a = 1.0
	_tween_aviso = create_tween()
	_tween_aviso.tween_interval(segundos)
	_tween_aviso.tween_property(_aviso, "modulate:a", 0.0, 0.8)
