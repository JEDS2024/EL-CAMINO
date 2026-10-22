class_name Hud
extends Control
## Virtudes, luz del candil, objetivo actual, avisos y botones táctiles.

signal pedir_interactuar
signal pedir_vista
signal pedir_pausa

var boton_accion: Button
var boton_vista: Button
var boton_pausa: Button
var _valores := {}
var _barra_luz: ProgressBar
var _objetivo: Label
var _titulo: Label
var _subtitulo: Label
var _aviso: Label
var _tween_aviso: Tween


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	# virtudes y luz (arriba a la izquierda)
	var caja := PanelContainer.new()
	caja.position = Vector2(20, 18)
	caja.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(caja)
	var col := VBoxContainer.new()
	caja.add_child(col)
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 14)
	col.add_child(fila)
	for v in Juego.VIRTUDES:
		var ic := TextureRect.new()
		ic.texture = load("res://assets/iconos/%s.png" % v)
		ic.custom_minimum_size = Vector2(32, 32)
		ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		ic.tooltip_text = Juego.NOMBRE_VIRTUD[v]
		fila.add_child(ic)
		var lb := Label.new()
		lb.add_theme_font_size_override("font_size", 26)
		fila.add_child(lb)
		_valores[v] = lb
	var fila_luz := HBoxContainer.new()
	col.add_child(fila_luz)
	var icl := TextureRect.new()
	icl.texture = load("res://assets/iconos/luz.png")
	icl.custom_minimum_size = Vector2(28, 28)
	icl.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icl.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	fila_luz.add_child(icl)
	_barra_luz = ProgressBar.new()
	_barra_luz.custom_minimum_size = Vector2(210, 18)
	_barra_luz.show_percentage = false
	_barra_luz.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var fondo := StyleBoxFlat.new()
	fondo.bg_color = Color(0, 0, 0, 0.5)
	fondo.set_corner_radius_all(4)
	var relleno := StyleBoxFlat.new()
	relleno.bg_color = Color("ffc24a")
	relleno.set_corner_radius_all(4)
	_barra_luz.add_theme_stylebox_override("background", fondo)
	_barra_luz.add_theme_stylebox_override("fill", relleno)
	fila_luz.add_child(_barra_luz)

	# objetivo, título y avisos (arriba al centro)
	_objetivo = _etiqueta(24, Color(1, 1, 1, 0.85))
	Tema.anclar(_objetivo, 0.3, 0.0, 0.7, 0.0)
	_objetivo.offset_top = 22
	_titulo = _etiqueta(64, Color("ffd36b"))
	Tema.anclar(_titulo, 0.1, 0.26, 0.9, 0.26)
	_subtitulo = _etiqueta(30, Color(1, 1, 1, 0.9))
	Tema.anclar(_subtitulo, 0.1, 0.37, 0.9, 0.37)
	_aviso = _etiqueta(30, Color("fff3c4"))
	Tema.anclar(_aviso, 0.25, 0.15, 0.75, 0.15)
	_aviso.modulate.a = 0

	# botones (arriba a la derecha y acción abajo a la derecha)
	boton_pausa = _boton("II", Vector2(72, 64))
	boton_pausa.anchor_left = 1.0
	boton_pausa.anchor_right = 1.0
	boton_pausa.offset_left = -92
	boton_pausa.offset_right = -20
	boton_pausa.offset_top = 18
	boton_pausa.offset_bottom = 82
	boton_pausa.pressed.connect(func(): pedir_pausa.emit())
	boton_vista = _boton("", Vector2(150, 64))
	boton_vista.anchor_left = 1.0
	boton_vista.anchor_right = 1.0
	boton_vista.offset_left = -258
	boton_vista.offset_right = -104
	boton_vista.offset_top = 18
	boton_vista.offset_bottom = 82
	boton_vista.pressed.connect(func(): pedir_vista.emit())
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

	Juego.estado_cambiado.connect(actualizar)
	actualizar()


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
	boton_vista.text = "Vista: 1ª" if Juego.primera_persona else "Vista: 3ª"


func fijar_accion(texto: String) -> void:
	boton_accion.visible = texto != ""
	boton_accion.text = texto


func fijar_objetivo(texto: String) -> void:
	_objetivo.text = ("▸ " + texto) if texto != "" else ""


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
