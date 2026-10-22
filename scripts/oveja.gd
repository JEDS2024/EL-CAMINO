class_name Oveja
extends Node3D
## Oveja de bloques que pasta y camina despacio cerca de donde nació.

var _origen := Vector3.ZERO
var _destino := Vector3.ZERO
var _espera := 0.0
var _t := 0.0
var _cabeza: Node3D
var _azar := RandomNumberGenerator.new()


func _ready() -> void:
	_origen = position
	_destino = position
	_azar.seed = int(position.x * 31 + position.z * 17)
	var lana := Personaje3D.material("f0ece0")
	var negro := Personaje3D.material("2a2420")
	_caja(Vector3(0.7, 0.45, 0.95), Vector3(0, 0.62, 0), lana)
	for x in [-0.2, 0.2]:
		for z in [-0.3, 0.3]:
			_caja(Vector3(0.12, 0.42, 0.12), Vector3(x, 0.21, z), negro)
	_cabeza = Node3D.new()
	_cabeza.position = Vector3(0, 0.78, -0.5)
	add_child(_cabeza)
	var c := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = Vector3(0.3, 0.32, 0.36)
	c.mesh = b
	c.material_override = negro
	_cabeza.add_child(c)
	var copete := MeshInstance3D.new()
	var b2 := BoxMesh.new()
	b2.size = Vector3(0.32, 0.12, 0.2)
	copete.mesh = b2
	copete.material_override = lana
	copete.position = Vector3(0, 0.18, 0.06)
	_cabeza.add_child(copete)


func _caja(tam: Vector3, pos: Vector3, mat: Material) -> void:
	var mi := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = tam
	mi.mesh = b
	mi.material_override = mat
	mi.position = pos
	add_child(mi)


func _process(delta: float) -> void:
	_t += delta
	var hacia := _destino - position
	hacia.y = 0
	if hacia.length() > 0.1:
		position += hacia.normalized() * minf(0.6 * delta, hacia.length())
		rotation.y = lerp_angle(rotation.y, atan2(-hacia.x, -hacia.z), delta * 4.0)
		_cabeza.position.y = 0.78 + sin(_t * 8.0) * 0.02
	else:
		_espera -= delta
		_cabeza.position.y = 0.6 + sin(_t * 2.0) * 0.03  # pastando
		if _espera <= 0:
			_espera = _azar.randf_range(2.0, 6.0)
			_destino = _origen + Vector3(_azar.randf_range(-2.5, 2.5), 0, _azar.randf_range(-2.5, 2.5))
