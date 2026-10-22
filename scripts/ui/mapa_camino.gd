class_name MapaCamino
extends Control
## Mapa ilustrado (aproximado, no a escala) con los lugares de las cinco historias.

# "lado": dónde va el nombre respecto al punto (las posiciones son aproximadas y algo separadas para leerse)
const LUGARES := [
	{"nombre": "Egipto", "historia": "José", "pos": Vector2(0.14, 0.82), "lado": Vector2(0, -1)},
	{"nombre": "Belén", "historia": "Rut", "pos": Vector2(0.66, 0.6), "lado": Vector2(1, 0)},
	{"nombre": "Valle de Ela", "historia": "David", "pos": Vector2(0.47, 0.62), "lado": Vector2(-1, 0)},
	{"nombre": "Jerusalén", "historia": "Nehemías", "pos": Vector2(0.66, 0.4), "lado": Vector2(1, 0)},
	{"nombre": "Emaús", "historia": "Cleofás", "pos": Vector2(0.5, 0.33), "lado": Vector2(-1, 0)},
]

var actual := 0
var completados: Array = []
var _t := 0.0


func _ready() -> void:
	custom_minimum_size = Vector2(900, 480)


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _p(rel: Vector2) -> Vector2:
	return rel * size


func _draw() -> void:
	var tierra := Color("c9b07a")
	var mar := Color("3d6a96")
	draw_rect(Rect2(Vector2.ZERO, size), tierra)
	# Mar Mediterráneo al oeste
	var costa := PackedVector2Array([_p(Vector2(0, 0)), _p(Vector2(0.46, 0)), _p(Vector2(0.42, 0.25)),
		_p(Vector2(0.38, 0.5)), _p(Vector2(0.33, 0.66)), _p(Vector2(0.22, 0.7)), _p(Vector2(0.1, 0.69)), _p(Vector2(0, 0.7))])
	draw_colored_polygon(costa, mar)
	# el Nilo y su delta
	for ramal in [Vector2(0.05, 0.71), Vector2(0.12, 0.7), Vector2(0.19, 0.71)]:
		draw_line(_p(ramal), _p(Vector2(0.12, 0.82)), mar.lightened(0.15), 4.0)
	draw_line(_p(Vector2(0.12, 0.82)), _p(Vector2(0.13, 1.0)), mar.lightened(0.15), 5.0)
	# Jordán, Mar de Galilea y Mar Muerto
	draw_line(_p(Vector2(0.77, 0.12)), _p(Vector2(0.78, 0.42)), mar.lightened(0.15), 4.0)
	draw_circle(_p(Vector2(0.77, 0.1)), size.y * 0.035, mar)
	draw_colored_polygon(PackedVector2Array([_p(Vector2(0.765, 0.42)), _p(Vector2(0.8, 0.42)), _p(Vector2(0.8, 0.6)), _p(Vector2(0.77, 0.6))]), mar)
	var fuente := get_theme_default_font()
	draw_string(fuente, _p(Vector2(0.08, 0.3)), "Mar Mediterráneo", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(1, 1, 1, 0.6))
	draw_string(fuente, _p(Vector2(0.81, 0.52)), "Mar Muerto", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(0.15, 0.2, 0.35, 0.8))
	draw_string(fuente, _p(Vector2(0.8, 0.27)), "Jordán", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(0.15, 0.2, 0.35, 0.8))
	draw_string(fuente, _p(Vector2(0.15, 0.92)), "Nilo", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(0.15, 0.2, 0.35, 0.8))
	# el camino entre las historias
	for i in LUGARES.size() - 1:
		var a := _p(LUGARES[i]["pos"])
		var b := _p(LUGARES[i + 1]["pos"])
		var hecho := i < actual
		var pasos := int(a.distance_to(b) / 14.0)
		for k in pasos:
			if k % 2 == 0:
				draw_line(a.lerp(b, float(k) / pasos), a.lerp(b, float(k + 1) / pasos),
					Color("8a4a2a") if hecho else Color(0.45, 0.35, 0.25, 0.5), 4.0)
	# los lugares
	for i in LUGARES.size():
		var l: Dictionary = LUGARES[i]
		var c := _p(l["pos"])
		var es_actual := i == actual
		var radio := 14.0 + (4.0 * sin(_t * 4.0) if es_actual else 0.0)
		var color := Color("ffd36b") if (i in completados or es_actual) else Color(0.5, 0.45, 0.4)
		draw_circle(c, radio + 3, Color(0.1, 0.07, 0.15))
		draw_circle(c, radio, color)
		var lado: Vector2 = l["lado"]
		var ancho := 150.0
		var base := c + Vector2(-ancho / 2, 0)
		var alineado := HORIZONTAL_ALIGNMENT_CENTER
		if lado.x > 0:
			base = c + Vector2(24, 0)
			alineado = HORIZONTAL_ALIGNMENT_LEFT
		elif lado.x < 0:
			base = c + Vector2(-24 - ancho, 0)
			alineado = HORIZONTAL_ALIGNMENT_RIGHT
		else:
			base.y -= 34
		draw_string(fuente, base + Vector2(0, -2), "%d. %s" % [i + 1, l["nombre"]], alineado, ancho, 22, Color(0.12, 0.08, 0.15))
		draw_string(fuente, base + Vector2(0, 20), l["historia"], alineado, ancho, 18, Color(0.3, 0.18, 0.1))
	draw_string(fuente, Vector2(size.x - 250, size.y - 12), "Mapa aproximado, no a escala", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.2, 0.15, 0.1, 0.7))
