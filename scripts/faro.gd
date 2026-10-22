class_name Faro
extends Node3D
## Marca discreta del siguiente objetivo: un rombo dorado que flota y gira, y un anillo
## de luz suave en el suelo. (Antes era una columna de luz que tapaba a los personajes.)

var _rombo: Node3D
var _anillo: MeshInstance3D
var _t := 0.0


func _material(color: Color, alfa: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = Color(color, alfa)
	if alfa < 1.0:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m


func _ready() -> void:
	# rombo: dos pirámides unidas por la base
	_rombo = Node3D.new()
	add_child(_rombo)
	for arriba in [true, false]:
		var mi := MeshInstance3D.new()
		var p := PrismMesh.new()
		p.size = Vector3(0.32, 0.26, 0.32)
		mi.mesh = p
		mi.material_override = _material(Color("ffd36b"), 1.0)
		mi.position.y = 0.13 if arriba else -0.13
		if not arriba:
			mi.rotation_degrees.z = 180
		_rombo.add_child(mi)
	_anillo = MeshInstance3D.new()
	var toro := TorusMesh.new()
	toro.inner_radius = 0.75
	toro.outer_radius = 0.9
	toro.rings = 24
	toro.ring_segments = 6
	_anillo.mesh = toro
	_anillo.scale = Vector3(1, 0.05, 1)
	_anillo.position.y = 0.05
	_anillo.material_override = _material(Color("ffe7a0"), 0.55)
	add_child(_anillo)


func _process(delta: float) -> void:
	_t += delta
	_rombo.position.y = 3.05 + sin(_t * 2.6) * 0.12
	_rombo.rotation.y = _t * 2.0
	var pulso := 1.0 + sin(_t * 3.0) * 0.08
	_anillo.scale = Vector3(pulso, 0.05, pulso)
