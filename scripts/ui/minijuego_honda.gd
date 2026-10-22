class_name MinijuegoHonda
extends Control
## Minijuego de la honda (1 Samuel 17:49): la piedra gira y un marcador recorre la barra;
## hay que lanzar cuando el marcador está en la zona dorada.

signal terminado

const ANCHO_ZONA := 0.2  # fracción de la barra; generosa para que los niños también acierten

var _pos := 0.0
var _dir := 1.0
var _velocidad := 0.75
var _zona := 0.5
var _activo := true
var _t := 0.0
var _barra: Control
var _mensaje: Label
var _boton: Button


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var fondo := ColorRect.new()
	fondo.color = Color(0, 0, 0, 0.45)
	fondo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(fondo)
	var centro := CenterContainer.new()
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(centro)
	var panel := PanelContainer.new()
	centro.add_child(panel)
	var col := VBoxContainer.new()
	col.custom_minimum_size = Vector2(720, 0)
	col.add_theme_constant_override("separation", 16)
	panel.add_child(col)
	var titulo := Label.new()
	titulo.text = "¡La honda de David!"
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.add_theme_font_size_override("font_size", 48)
	titulo.add_theme_color_override("font_color", Color("ffd36b"))
	col.add_child(titulo)
	_mensaje = Label.new()
	_mensaje.text = "Pulsa «¡Lanzar!» cuando la piedra pase por la zona dorada."
	_mensaje.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_mensaje.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_mensaje.add_theme_font_size_override("font_size", 26)
	col.add_child(_mensaje)
	_barra = Control.new()
	_barra.custom_minimum_size = Vector2(680, 150)
	_barra.draw.connect(_dibujar)
	col.add_child(_barra)
	_boton = Button.new()
	_boton.text = "¡Lanzar!"
	_boton.custom_minimum_size = Vector2(0, 90)
	_boton.add_theme_font_size_override("font_size", 40)
	_boton.focus_mode = Control.FOCUS_NONE
	_boton.pressed.connect(lanzar)
	col.add_child(_boton)
	_zona = randf_range(0.3, 0.7)


func _process(delta: float) -> void:
	_t += delta
	if _activo:
		_pos += _dir * _velocidad * delta
		if _pos > 1.0:
			_pos = 1.0
			_dir = -1.0
		elif _pos < 0.0:
			_pos = 0.0
			_dir = 1.0
	_barra.queue_redraw()


func _unhandled_input(ev: InputEvent) -> void:
	if ev.is_action_pressed("interactuar"):
		get_viewport().set_input_as_handled()
		lanzar()


func acierta() -> bool:
	return absf(_pos - _zona) <= ANCHO_ZONA / 2.0


func lanzar() -> void:
	if not _activo:
		return
	resolver(acierta())


## Termina el intento: con acierto avanza la historia; si no, se puede intentar otra vez.
func resolver(bien: bool) -> void:
	_activo = false
	if bien:
		Sonido.efecto("exito")
		_mensaje.text = "¡La piedra dio en la frente del filisteo!"
		_boton.disabled = true
		await get_tree().create_timer(1.0).timeout
		terminado.emit()
	else:
		Sonido.efecto("fallo")
		_mensaje.text = "¡Casi! Espera a que la piedra pase por lo dorado y vuelve a intentarlo."
		await get_tree().create_timer(0.8).timeout
		_zona = randf_range(0.3, 0.7)
		_activo = true


func _dibujar() -> void:
	var w := _barra.size.x
	# la honda girando con la piedra
	var centro := Vector2(w / 2, 48)
	var ang := _t * 9.0
	var piedra := centro + Vector2(cos(ang), sin(ang) * 0.45) * 52
	_barra.draw_line(centro + Vector2(0, -30), piedra, Color("8a6a42"), 4.0)
	_barra.draw_circle(piedra, 11, Color("c8c2b8"))
	_barra.draw_circle(piedra + Vector2(-3, -3), 4, Color("f0ece4"))
	# barra con la zona dorada y el marcador
	var y := 112.0
	var r := Rect2(20, y, w - 40, 26)
	_barra.draw_rect(r, Color(0.1, 0.08, 0.15))
	var zx := r.position.x + (_zona - ANCHO_ZONA / 2.0) * r.size.x
	_barra.draw_rect(Rect2(zx, y, ANCHO_ZONA * r.size.x, r.size.y), Color("ffd36b"))
	_barra.draw_rect(r, Color.BLACK, false, 3.0)
	var mx := r.position.x + _pos * r.size.x
	_barra.draw_rect(Rect2(mx - 5, y - 10, 10, r.size.y + 20), Color.WHITE)
	_barra.draw_rect(Rect2(mx - 5, y - 10, 10, r.size.y + 20), Color.BLACK, false, 2.0)
