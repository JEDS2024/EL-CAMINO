class_name SpritePersonaje
extends Sprite3D
## Personaje pixel art "billboard": elige la fila (frente/espalda/izq/der) según hacia dónde
## mira el personaje respecto a la cámara, y anima el paso al moverse.

const FILA_FRENTE := 0
const FILA_ESPALDA := 1
const FILA_IZQ := 2
const FILA_DER := 3
const ALTO_PX := 24.0

var mirando := Vector3(0, 0, 1)
var _tiempo := 0.0


func configurar(nombre_sprite: String) -> void:
	texture = load("res://assets/sprites/pj_%s.png" % nombre_sprite)
	hframes = 3
	vframes = 4
	pixel_size = 0.072
	billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	shaded = true
	alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	position.y = ALTO_PX * pixel_size * 0.5


func actualizar(delta: float, direccion: Vector3, moviendose: bool, camara: Camera3D) -> void:
	if direccion.length_squared() > 0.001:
		mirando = direccion.normalized()
	var fila := FILA_FRENTE
	if camara:
		var adelante := -camara.global_basis.z
		adelante.y = 0
		adelante = adelante.normalized()
		var derecha := camara.global_basis.x
		derecha.y = 0
		derecha = derecha.normalized()
		var d := mirando.dot(adelante)
		if d > 0.6:
			fila = FILA_ESPALDA
		elif d < -0.6:
			fila = FILA_FRENTE
		else:
			fila = FILA_DER if mirando.dot(derecha) > 0 else FILA_IZQ
	var columna := 0
	if moviendose:
		_tiempo += delta * 8.0
		columna = 1 + (int(_tiempo) % 2)
	else:
		_tiempo = 0.0
	frame = fila * 3 + columna
