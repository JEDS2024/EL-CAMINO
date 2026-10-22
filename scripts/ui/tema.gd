class_name Tema
extends RefCounted
## Estilo visual de la interfaz: fuente, botones y paneles con aire de pergamino nocturno.


static func _caja(fondo: Color, borde: Color, grosor := 3) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = fondo
	s.border_color = borde
	s.set_border_width_all(grosor)
	s.set_corner_radius_all(8)
	s.content_margin_left = 22
	s.content_margin_right = 22
	s.content_margin_top = 12
	s.content_margin_bottom = 12
	return s


## Ancla un control a proporciones de su padre, sin márgenes.
static func anclar(c: Control, izq: float, arriba: float, der: float, abajo: float) -> void:
	c.anchor_left = izq
	c.anchor_top = arriba
	c.anchor_right = der
	c.anchor_bottom = abajo
	c.offset_left = 0
	c.offset_top = 0
	c.offset_right = 0
	c.offset_bottom = 0


static func crear() -> Theme:
	var t := Theme.new()
	t.default_font = load("res://assets/fuentes/FiraSansCompressed-SemiBold.otf")
	t.default_font_size = 28
	var oro := Color("ffd36b")
	t.set_stylebox("normal", "Button", _caja(Color(0.12, 0.08, 0.2, 0.86), Color(oro, 0.75)))
	t.set_stylebox("hover", "Button", _caja(Color(0.2, 0.14, 0.32, 0.92), oro))
	t.set_stylebox("pressed", "Button", _caja(Color(0.36, 0.25, 0.12, 0.95), oro))
	t.set_stylebox("focus", "Button", _caja(Color(0, 0, 0, 0), Color(oro, 0.9), 2))
	t.set_stylebox("disabled", "Button", _caja(Color(0.1, 0.1, 0.1, 0.6), Color(0.4, 0.4, 0.4)))
	t.set_color("font_color", "Button", Color("fff3dc"))
	t.set_color("font_hover_color", "Button", Color.WHITE)
	t.set_color("font_pressed_color", "Button", oro)
	t.set_stylebox("panel", "PanelContainer", _caja(Color(0.07, 0.05, 0.12, 0.88), Color(oro, 0.55)))
	t.set_color("font_color", "Label", Color("fff3dc"))
	return t
