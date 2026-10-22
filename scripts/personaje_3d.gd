class_name Personaje3D
extends Node3D
## Personaje 3D hecho de bloques (estilo voxel). Piernas y brazos articulados que se
## animan al caminar. El frente del modelo mira hacia -Z, como las cámaras de Godot.

const ASPECTO := {
	"ezra": {"piel": "c68b5e", "pelo": "3a2416", "tunica": "b5643a", "manto": "7a3b28", "cinto": "e0b04a", "peinado": "corto"},
	"caminante": {"piel": "b07a52", "pelo": "2b1d14", "tunica": "8a8a92", "manto": "5e5d6b", "capucha": true,
		"candil": true, "barba": "3a2a1e"},
	"marta": {"piel": "d39b70", "pelo": "5a3420", "tunica": "6a7fb0", "delantal": true, "peinado": "panuelo", "panuelo": "d9b25a"},
	"simeon": {"piel": "c99470", "pelo": "e8e4dc", "tunica": "5d6b4a", "barba": "efeae0", "peinado": "calvo", "baston": true},
	"tomas": {"piel": "a8714a", "pelo": "1e1610", "tunica": "7b4f8f", "peinado": "corto", "barba": "1e1610"},
	"lia": {"piel": "c68b5e", "pelo": "2a1a12", "tunica": "d0796a", "peinado": "largo", "nino": true},
	"noemi": {"piel": "b9845a", "pelo": "1a120c", "tunica": "3f8f86", "peinado": "panuelo", "panuelo": "e8e0cc"},
	"jared": {"piel": "9c6844", "pelo": "241812", "tunica": "5a4a3a", "manto": "3a3028", "peinado": "corto", "barba": "241812"},
	"abuela": {"piel": "c99470", "pelo": "d8d4cc", "tunica": "7a5a8a", "peinado": "panuelo", "panuelo": "5a4a6a", "baston": true},
	"vigia": {"piel": "8f5a3a", "pelo": "140e0a", "tunica": "3a4a6a", "manto": "2a3048", "peinado": "corto"},
}

static var _materiales := {}

var mirando := Vector3(0, 0, 1)
var _fase := 0.0
var _cuerpo: Node3D
var _pierna_i: Node3D
var _pierna_d: Node3D
var _brazo_i: Node3D
var _brazo_d: Node3D


static func material(color: String, brillo := false) -> StandardMaterial3D:
	var clave := color + ("*" if brillo else "")
	if not _materiales.has(clave):
		var m := StandardMaterial3D.new()
		m.albedo_color = Color(color)
		m.roughness = 1.0
		if brillo:
			m.emission_enabled = true
			m.emission = Color(color)
			m.emission_energy_multiplier = 2.0
		_materiales[clave] = m
	return _materiales[clave]


func _caja(padre: Node3D, tam: Vector3, pos: Vector3, color: String, brillo := false) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = tam
	mi.mesh = b
	mi.position = pos
	mi.material_override = material(color, brillo)
	padre.add_child(mi)
	return mi


func _articulacion(pos: Vector3) -> Node3D:
	var n := Node3D.new()
	n.position = pos
	_cuerpo.add_child(n)
	return n


func configurar(clave: String) -> void:
	var a: Dictionary = ASPECTO.get(clave, ASPECTO["caminante"])
	var piel: String = a["piel"]
	var pelo: String = a["pelo"]
	var tunica: String = a["tunica"]
	var manga := (Color(tunica).darkened(0.25)).to_html(false)
	var oscuro := "1e1628"

	_cuerpo = Node3D.new()
	add_child(_cuerpo)
	if a.get("nino", false):
		scale = Vector3.ONE * 0.72

	# piernas (giran desde la cadera)
	_pierna_i = _articulacion(Vector3(-0.11, 0.72, 0))
	_pierna_d = _articulacion(Vector3(0.11, 0.72, 0))
	for p in [_pierna_i, _pierna_d]:
		_caja(p, Vector3(0.17, 0.66, 0.19), Vector3(0, -0.36, 0), "4a3a2e")
		_caja(p, Vector3(0.19, 0.08, 0.26), Vector3(0, -0.69, -0.03), "3a2618")

	# túnica, cinto y detalles
	_caja(_cuerpo, Vector3(0.5, 0.78, 0.32), Vector3(0, 0.93, 0), tunica)
	_caja(_cuerpo, Vector3(0.52, 0.07, 0.34), Vector3(0, 0.98, 0), a.get("cinto", "6b4527"))
	if a.get("delantal", false):
		_caja(_cuerpo, Vector3(0.36, 0.42, 0.02), Vector3(0, 0.8, -0.17), "e8e0cc")
	if a.has("manto"):
		_caja(_cuerpo, Vector3(0.56, 0.86, 0.06), Vector3(0, 0.92, 0.18), a["manto"])

	# brazos (giran desde el hombro)
	_brazo_i = _articulacion(Vector3(-0.33, 1.27, 0))
	_brazo_d = _articulacion(Vector3(0.33, 1.27, 0))
	for b in [_brazo_i, _brazo_d]:
		_caja(b, Vector3(0.15, 0.56, 0.17), Vector3(0, -0.27, 0), manga)
		_caja(b, Vector3(0.13, 0.11, 0.13), Vector3(0, -0.6, 0), piel)
	if a.get("candil", false):
		_caja(_brazo_d, Vector3(0.05, 0.12, 0.05), Vector3(0, -0.7, -0.05), "2d2a30")
		_caja(_brazo_d, Vector3(0.14, 0.16, 0.14), Vector3(0, -0.82, -0.05), "ffd36b", true)
		var luz := OmniLight3D.new()
		luz.light_color = Color("ffc978")
		luz.light_energy = 0.9
		luz.omni_range = 3.0
		luz.position = Vector3(0, -0.8, -0.1)
		_brazo_d.add_child(luz)
	if a.get("baston", false):
		_caja(_brazo_i, Vector3(0.06, 1.55, 0.06), Vector3(-0.02, -0.55, -0.12), "7a5230")

	# cabeza
	var cabeza := _articulacion(Vector3(0, 1.32, 0))
	_caja(cabeza, Vector3(0.38, 0.38, 0.38), Vector3(0, 0.19, 0), piel)
	_caja(cabeza, Vector3(0.07, 0.07, 0.02), Vector3(-0.09, 0.22, -0.19), oscuro)
	_caja(cabeza, Vector3(0.07, 0.07, 0.02), Vector3(0.09, 0.22, -0.19), oscuro)
	_caja(cabeza, Vector3(0.06, 0.07, 0.05), Vector3(0, 0.15, -0.21), Color(piel).darkened(0.15).to_html(false))
	if a.has("barba"):
		_caja(cabeza, Vector3(0.36, 0.17, 0.08), Vector3(0, 0.05, -0.17), a["barba"])
		_caja(cabeza, Vector3(0.38, 0.09, 0.3), Vector3(0, 0.03, 0.0), a["barba"])
	else:
		_caja(cabeza, Vector3(0.12, 0.03, 0.02), Vector3(0, 0.08, -0.19), "7a3a30")

	var peinado: String = a.get("peinado", "corto")
	if a.get("capucha", false):
		var m: String = a["manto"]
		_caja(cabeza, Vector3(0.46, 0.08, 0.46), Vector3(0, 0.42, 0.01), m)
		_caja(cabeza, Vector3(0.46, 0.44, 0.06), Vector3(0, 0.2, 0.22), m)
		_caja(cabeza, Vector3(0.05, 0.44, 0.44), Vector3(-0.215, 0.2, 0.01), m)
		_caja(cabeza, Vector3(0.05, 0.44, 0.44), Vector3(0.215, 0.2, 0.01), m)
	elif peinado == "panuelo":
		var t: String = a.get("panuelo", "c2263a")
		_caja(cabeza, Vector3(0.42, 0.1, 0.42), Vector3(0, 0.42, 0.01), t)
		_caja(cabeza, Vector3(0.42, 0.42, 0.06), Vector3(0, 0.2, 0.2), t)
		_caja(cabeza, Vector3(0.04, 0.3, 0.4), Vector3(-0.2, 0.26, 0.02), t)
		_caja(cabeza, Vector3(0.04, 0.3, 0.4), Vector3(0.2, 0.26, 0.02), t)
	elif peinado == "calvo":
		_caja(cabeza, Vector3(0.04, 0.16, 0.3), Vector3(-0.2, 0.2, 0.04), pelo)
		_caja(cabeza, Vector3(0.04, 0.16, 0.3), Vector3(0.2, 0.2, 0.04), pelo)
		_caja(cabeza, Vector3(0.4, 0.16, 0.05), Vector3(0, 0.2, 0.2), pelo)
	else:
		_caja(cabeza, Vector3(0.41, 0.1, 0.41), Vector3(0, 0.41, 0.01), pelo)
		_caja(cabeza, Vector3(0.41, 0.1, 0.06), Vector3(0, 0.35, -0.185), pelo)
		var largo := 0.62 if peinado == "largo" else 0.36
		_caja(cabeza, Vector3(0.41, largo, 0.07), Vector3(0, 0.4 - largo / 2, 0.2), pelo)
		_caja(cabeza, Vector3(0.04, 0.2, 0.36), Vector3(-0.205, 0.3, 0.03), pelo)
		_caja(cabeza, Vector3(0.04, 0.2, 0.36), Vector3(0.205, 0.3, 0.03), pelo)


## Gira hacia `direccion` y anima piernas y brazos si se está moviendo.
func actualizar(delta: float, direccion: Vector3, moviendose: bool, _camara: Camera3D = null) -> void:
	if direccion.length_squared() > 0.001:
		mirando = direccion.normalized()
		var objetivo := atan2(-mirando.x, -mirando.z)
		rotation.y = lerp_angle(rotation.y, objetivo, minf(1.0, delta * 12.0))
	var amplitud := 0.0
	if moviendose:
		_fase += delta * 9.5
		amplitud = 0.62
	else:
		_fase = lerpf(_fase, roundf(_fase / PI) * PI, minf(1.0, delta * 8.0))
	var s := sin(_fase) * amplitud
	_pierna_i.rotation.x = s
	_pierna_d.rotation.x = -s
	_brazo_i.rotation.x = -s * 0.8
	_brazo_d.rotation.x = s * 0.8
	_cuerpo.position.y = absf(sin(_fase)) * 0.05 if moviendose else sin(Time.get_ticks_msec() * 0.002) * 0.008
