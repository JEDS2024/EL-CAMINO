class_name CajaDialogo
extends Control
## Diálogos con efecto máquina de escribir, retrato del personaje y decisiones.
## Cada línea: {"quien", "texto", "si"?, "efectos"?, "opciones"?: [{"texto", "efectos"?, "siguiente"?, "si"?}]}

const VELOCIDAD := 45.0  # letras por segundo

var resolver: Callable  # id -> Array de líneas
var retratos := {}  # nombre visible -> clave de sprite

var _lineas: Array = []
var _indice := -1
var _al_terminar: Callable
var _escribiendo := false
var _esperando_opcion := false
var _letras := 0.0

var _panel: PanelContainer
var _nombre: Label
var _texto: Label
var _retrato: TextureRect
var _indicador: Label
var _opciones: VBoxContainer


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false

	var velo := ColorRect.new()
	velo.color = Color(0, 0, 0, 0.25)
	velo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	velo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(velo)

	_panel = PanelContainer.new()
	Tema.anclar(_panel, 0.04, 0.64, 0.96, 0.96)
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_panel)
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 18)
	_panel.add_child(fila)
	_retrato = TextureRect.new()
	_retrato.custom_minimum_size = Vector2(110, 165)
	_retrato.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_retrato.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_retrato.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	fila.add_child(_retrato)
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fila.add_child(col)
	_nombre = Label.new()
	_nombre.add_theme_font_size_override("font_size", 30)
	_nombre.add_theme_color_override("font_color", Color("ffd36b"))
	col.add_child(_nombre)
	_texto = Label.new()
	_texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_texto.add_theme_font_size_override("font_size", 32)
	_texto.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(_texto)
	_indicador = Label.new()
	_indicador.text = "toca para seguir ▸"
	_indicador.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_indicador.add_theme_font_size_override("font_size", 20)
	_indicador.add_theme_color_override("font_color", Color(1, 1, 1, 0.55))
	col.add_child(_indicador)

	_opciones = VBoxContainer.new()
	Tema.anclar(_opciones, 0.42, 0.08, 0.96, 0.62)
	_opciones.alignment = BoxContainer.ALIGNMENT_END
	_opciones.add_theme_constant_override("separation", 12)
	add_child(_opciones)


func iniciar(lineas: Array, al_terminar: Callable) -> void:
	_lineas = lineas
	_indice = -1
	_al_terminar = al_terminar
	visible = true
	_siguiente()


func _siguiente() -> void:
	_indice += 1
	while _indice < _lineas.size() and not Juego.cumple(_lineas[_indice].get("si", [])):
		_indice += 1
	if _indice >= _lineas.size():
		visible = false
		if _al_terminar.is_valid():
			_al_terminar.call()
		return
	_mostrar(_lineas[_indice])


func _mostrar(l: Dictionary) -> void:
	Juego.aplicar(l.get("efectos", {}))
	var quien: String = l.get("quien", "")
	_nombre.text = quien
	_nombre.visible = quien != ""
	_texto.text = l.get("texto", "")
	_texto.visible_characters = 0
	_letras = 0.0
	_escribiendo = true
	var clave: String = l.get("retrato", retratos.get(quien, ""))
	_retrato.visible = clave != ""
	if clave != "":
		var at := AtlasTexture.new()
		at.atlas = load("res://assets/sprites/pj_%s.png" % clave)
		at.region = Rect2(0, 0, 16, 24)
		_retrato.texture = at
	for b in _opciones.get_children():
		b.queue_free()
	_esperando_opcion = false
	_indicador.visible = false


func _terminar_escritura() -> void:
	_escribiendo = false
	_texto.visible_characters = -1
	var l: Dictionary = _lineas[_indice]
	var ops: Array = []
	for op in l.get("opciones", []):
		if Juego.cumple(op.get("si", [])):
			ops.append(op)
	if ops.is_empty():
		_indicador.visible = true
		return
	_esperando_opcion = true
	for op in ops:
		var b := Button.new()
		b.text = op.get("texto", "...")
		b.custom_minimum_size = Vector2(0, 64)
		b.focus_mode = Control.FOCUS_NONE
		b.pressed.connect(_elegir.bind(op))
		_opciones.add_child(b)


func _elegir(op: Dictionary) -> void:
	for b in _opciones.get_children():
		b.queue_free()
	_esperando_opcion = false
	Juego.aplicar(op.get("efectos", {}))
	if op.has("siguiente") and resolver.is_valid():
		_lineas = resolver.call(op["siguiente"])
		_indice = -1
	_siguiente()


func avanzar() -> void:
	if not visible:
		return
	if _escribiendo:
		_terminar_escritura()
	elif not _esperando_opcion:
		_siguiente()


func _gui_input(ev: InputEvent) -> void:
	# en Android el toque llega también como clic emulado; así no se avanza dos veces
	if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
		accept_event()
		avanzar()


func _process(delta: float) -> void:
	if not _escribiendo:
		return
	_letras += delta * VELOCIDAD
	_texto.visible_characters = int(_letras)
	if _texto.visible_characters >= _texto.text.length():
		_terminar_escritura()
