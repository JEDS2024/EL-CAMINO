class_name ControlesTactiles
extends Control
## Joystick virtual (abajo a la izquierda) y arrastrar en cualquier otra parte para mirar.
## En la PC: clic izquierdo funciona como un dedo y el clic derecho arrastrado también mira.

signal mover(v: Vector2)
signal mirar(delta: Vector2)

const RADIO := 95.0

var excluir: Array[Control] = []
var acciones_tactiles := {}  # Control -> Callable: permite saltar con otro dedo en el joystick
var _idx_joy := -1
var _idx_mirar := -1
var _origen := Vector2.ZERO
var _pos := Vector2.ZERO


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func reiniciar() -> void:
	_idx_joy = -1
	_idx_mirar = -1
	mover.emit(Vector2.ZERO)
	queue_redraw()


func _sobre_boton(p: Vector2) -> bool:
	for c in excluir:
		if c.is_visible_in_tree() and c.get_global_rect().has_point(p):
			return true
	return false


func _input(ev: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	if ev is InputEventScreenTouch:
		if ev.pressed:
			for boton in (acciones_tactiles if DisplayServer.is_touchscreen_available() else {}):
				if boton.is_visible_in_tree() and boton.get_global_rect().has_point(ev.position):
					acciones_tactiles[boton].call()
					get_viewport().set_input_as_handled()
					return
			if _sobre_boton(ev.position):
				return
			if _en_zona_joystick(ev.position) and _idx_joy == -1:
				_idx_joy = ev.index
				_origen = ev.position
				_pos = ev.position
				queue_redraw()
			elif _idx_mirar == -1:
				_idx_mirar = ev.index
		else:
			if ev.index == _idx_joy:
				_idx_joy = -1
				mover.emit(Vector2.ZERO)
				queue_redraw()
			if ev.index == _idx_mirar:
				_idx_mirar = -1
	elif ev is InputEventMouseMotion and ev.button_mask & MOUSE_BUTTON_MASK_RIGHT:
		mirar.emit(ev.relative)
	elif ev is InputEventScreenDrag:
		if ev.index == _idx_joy:
			_pos = ev.position
			mover.emit(((_pos - _origen) / RADIO).limit_length(1.0))
			queue_redraw()
		elif ev.index == _idx_mirar:
			mirar.emit(ev.relative)


func _en_zona_joystick(p: Vector2) -> bool:
	return p.x < size.x * 0.4 and p.y > size.y * 0.35


func _draw() -> void:
	if _idx_joy == -1:
		var guia := Vector2(150, size.y - 150)
		draw_circle(guia, RADIO, Color(1, 1, 1, 0.07))
		draw_arc(guia, RADIO, 0, TAU, 48, Color(1, 0.83, 0.42, 0.35), 3.0)
		draw_circle(guia, 38, Color(1, 0.83, 0.42, 0.25))
		return
	var tope := _origen + (_pos - _origen).limit_length(RADIO)
	draw_circle(_origen, RADIO, Color(1, 1, 1, 0.1))
	draw_arc(_origen, RADIO, 0, TAU, 48, Color(1, 0.83, 0.42, 0.6), 3.0)
	draw_circle(tope, 40, Color(1, 0.83, 0.42, 0.55))
