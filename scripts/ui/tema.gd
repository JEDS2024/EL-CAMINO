class_name Tema
extends RefCounted
## Estilo visual de la interfaz, inspirado en Minecraft: fuente pixelada, botones de piedra
## con relieve y paneles oscuros con bisel. Las texturas salen de herramientas/generar_arte.py.

const MARGEN := 9  # 3 píxeles del dibujo x escala 3


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


static func textura(nombre: String, contenido := Vector2(18, 12)) -> StyleBoxTexture:
	var s := StyleBoxTexture.new()
	s.texture = load("res://assets/ui/%s.png" % nombre)
	s.texture_margin_left = MARGEN
	s.texture_margin_top = MARGEN
	s.texture_margin_right = MARGEN
	s.texture_margin_bottom = MARGEN
	s.content_margin_left = contenido.x
	s.content_margin_right = contenido.x
	s.content_margin_top = contenido.y
	s.content_margin_bottom = contenido.y
	return s


static var _pixel: FontVariation


## Fuente pixelada; si le falta un símbolo, usa Fira. Sin ligaduras ("fi" se veía como un solo signo).
static func fuente_pixel() -> Font:
	if _pixel == null:
		var f: FontFile = load("res://assets/fuentes/PixelifySans.ttf")
		if f.fallbacks.is_empty():
			f.fallbacks = [load("res://assets/fuentes/FiraSansCompressed-SemiBold.otf")]
		_pixel = FontVariation.new()
		_pixel.base_font = f
		_pixel.opentype_features = {"liga": 0, "clig": 0, "dlig": 0}
	return _pixel


## Fuente cómoda para leer textos largos (diálogos, citas).
static func fuente_lectura() -> Font:
	return load("res://assets/fuentes/FiraSansCompressed-SemiBold.otf")


static func crear() -> Theme:
	var t := Theme.new()
	t.default_font = fuente_pixel()
	t.default_font_size = 28
	for tipo in ["Button", "CheckButton"]:
		t.set_stylebox("normal", tipo, textura("boton"))
		t.set_stylebox("hover", tipo, textura("boton_encima"))
		t.set_stylebox("pressed", tipo, textura("boton_pulsado"))
		t.set_stylebox("hover_pressed", tipo, textura("boton_encima" if tipo == "CheckButton" else "boton_pulsado"))
		t.set_stylebox("disabled", tipo, textura("boton_apagado"))
		t.set_stylebox("focus", tipo, StyleBoxEmpty.new())
		t.set_color("font_color", tipo, Color("f4f4f4"))
		t.set_color("font_hover_color", tipo, Color("ffffa0"))
		t.set_color("font_pressed_color", tipo, Color("ffd36b"))
		t.set_color("font_hover_pressed_color", tipo, Color("ffffa0"))
		t.set_color("font_disabled_color", tipo, Color(0.8, 0.8, 0.8))
		t.set_color("font_shadow_color", tipo, Color(0.12, 0.12, 0.12))
		t.set_constant("shadow_offset_x", tipo, 2)
		t.set_constant("shadow_offset_y", tipo, 2)
	t.set_stylebox("panel", "PanelContainer", textura("panel", Vector2(22, 16)))
	t.set_color("font_color", "Label", Color("fff3dc"))
	t.set_color("font_shadow_color", "Label", Color(0, 0, 0, 0.55))
	t.set_constant("shadow_offset_x", "Label", 2)
	t.set_constant("shadow_offset_y", "Label", 2)
	return t
