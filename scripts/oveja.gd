class_name Oveja
extends Node3D
## Animal voxel sencillo que vaga alrededor de su origen o camina a un destino.

var especie := "oveja"
var radio_paseo := 2.5
var _origen := Vector3.ZERO
var _destino := Vector3.ZERO
var _espera := 0.0
var _t := 0.0
var _cabeza: Node3D
var _patas: Array[Node3D] = []
var _azar := RandomNumberGenerator.new()
var _velocidad := 0.6
var _sigue_destino := false


func configurar(tipo: String) -> void:
	especie = tipo if tipo in ["oveja", "vaca", "camello", "ave"] else "oveja"


func _ready() -> void:
	_origen = global_position
	_destino = global_position
	_azar.seed = int(position.x * 31 + position.z * 17) + especie.hash()
	_velocidad = 0.5 if especie == "camello" else (0.9 if especie == "ave" else 0.65)
	var cuerpo := Color("f0ece0") if especie in ["oveja", "ave"] else (Color("8d4934") if especie == "camello" else Color("d8cec0"))
	var patas := Color("40352d") if especie != "ave" else Color("bb9b42")
	_caja(Vector3(0.72, 0.48, 0.96) if especie != "ave" else Vector3(0.48, 0.3, 0.6), Vector3(0, 0.62, 0), Personaje3D.material(cuerpo.to_html(false)))
	for x in [-0.22, 0.22]:
		for z in [-0.32, 0.32]:
			var pata := Node3D.new()
			pata.position = Vector3(x, 0.35, z)
			add_child(pata)
			_patas.append(pata)
			_caja_en(pata, Vector3(0.12, 0.4, 0.12), Vector3(0, -0.14, 0), Personaje3D.material(patas.to_html(false)))
	_cabeza = Node3D.new()
	_cabeza.position = Vector3(0, 0.78, -0.5)
	add_child(_cabeza)
	_caja_en(_cabeza, Vector3(0.32, 0.34, 0.38), Vector3.ZERO, Personaje3D.material(patas.to_html(false)))
	if especie == "camello":
		_caja(Vector3(0.34, 0.38, 0.4), Vector3(0, 1.02, 0.12), Personaje3D.material("a86742"))
		_caja(Vector3(0.28, 0.5, 0.35), Vector3(0, 0.87, -0.58), Personaje3D.material("8d4934"))
	elif especie == "ave":
		_caja(Vector3(0.4, 0.08, 0.26), Vector3(0, 0.72, 0.06), Personaje3D.material("b89b52"))
	else:
		_caja(Vector3(0.34, 0.12, 0.2), Vector3(0, 0.18, 0.08), Personaje3D.material(cuerpo.to_html(false)))


func _caja(tam: Vector3, pos: Vector3, mat: Material) -> void:
	_caja_en(self, tam, pos, mat)


func _caja_en(padre: Node3D, tam: Vector3, pos: Vector3, mat: Material) -> void:
	var mi := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = tam
	mi.mesh = b
	mi.material_override = mat
	mi.position = pos
	padre.add_child(mi)


func ir_a(destino_global: Vector3) -> void:
	_destino = destino_global
	_velocidad = 1.6
	_sigue_destino = true
	_espera = 0.0


func _process(delta: float) -> void:
	_t += delta
	var hacia := _destino - global_position
	hacia.y = 0
	if hacia.length() > 0.1:
		var avance := hacia.normalized() * minf(_velocidad * delta, hacia.length())
		rotation.y = lerp_angle(rotation.y, atan2(-hacia.x, -hacia.z), minf(1.0, delta * 4.0))
		# Girar antes de avanzar evita marchar de espaldas al cambiar de rumbo.
		var alineacion := maxf(0.0, (-global_basis.z).dot(hacia.normalized()))
		global_position += avance * alineacion
		_cabeza.position.y = 0.78 + sin(_t * 8.0) * 0.02
		for i in _patas.size():
			_patas[i].rotation.x = sin(_t * 9.0 + float(i % 2) * PI) * 0.22
	else:
		_cabeza.position.y = 0.6 + sin(_t * 2.0) * 0.03
		if _sigue_destino:
			return
		_espera -= delta
		if _espera <= 0:
			_espera = _azar.randf_range(2.0, 6.0)
			_destino = _origen + Vector3(_azar.randf_range(-radio_paseo, radio_paseo), 0, _azar.randf_range(-radio_paseo, radio_paseo))
