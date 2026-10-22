class_name Aves
extends Node3D
## Bandada de palomas que vuela en círculos sobre el lugar, batiendo las alas.

var _aves: Array[Node3D] = []
var _alas: Array = []
var _t := 0.0
var radio := 18.0


func _ready() -> void:
	var blanco := Personaje3D.material("f4f2ec")
	var gris := Personaje3D.material("b8b4c0")
	for i in 7:
		var ave := Node3D.new()
		add_child(ave)
		var cuerpo := MeshInstance3D.new()
		var b := BoxMesh.new()
		b.size = Vector3(0.18, 0.16, 0.45)
		cuerpo.mesh = b
		cuerpo.material_override = blanco
		ave.add_child(cuerpo)
		var par := []
		for lado in [-1, 1]:
			var pivote := Node3D.new()
			pivote.position = Vector3(lado * 0.09, 0.04, 0)
			ave.add_child(pivote)
			var ala := MeshInstance3D.new()
			var bm := BoxMesh.new()
			bm.size = Vector3(0.42, 0.03, 0.22)
			ala.mesh = bm
			ala.material_override = gris
			ala.position.x = lado * 0.21
			pivote.add_child(ala)
			par.append(pivote)
		_aves.append(ave)
		_alas.append(par)


func _process(delta: float) -> void:
	_t += delta
	for i in _aves.size():
		var fase := _t * 0.35 + i * 0.5
		var r := radio + sin(i * 1.7) * 4.0
		var p := Vector3(cos(fase) * r, 14.0 + sin(_t * 0.8 + i) * 1.5 + i * 0.4, sin(fase) * r)
		_aves[i].position = p
		_aves[i].rotation.y = -fase  # mira hacia donde vuela (tangente del círculo)
		var aleteo := sin(_t * 14.0 + i) * 0.7
		_alas[i][0].rotation.z = aleteo
		_alas[i][1].rotation.z = -aleteo
