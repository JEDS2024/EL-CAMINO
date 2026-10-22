class_name Personaje3D
extends Node3D
## Personaje 3D hecho de bloques (estilo voxel). Piernas y brazos articulados que se
## animan al caminar. El frente del modelo mira hacia -Z, como las cámaras de Godot.

## Aspecto de cada personaje. Opciones: piel, pelo, tunica, manto, cinto, barba, peinado
## (corto, largo, calvo, panuelo), panuelo, capucha, turbante, tocado/tocado2 (egipcio), collar,
## armadura, casco, escudo, lanza, honda, baston, candil, nino, escala.
const ASPECTO := {
	# Génesis 43–45
	"jose": {"piel": "b9845a", "pelo": "1a120c", "tunica": "e8e2d0", "cinto": "d9a830", "collar": "d9a830",
		"tocado": "e8e2d0", "tocado2": "3a5a9a"},
	"mayordomo": {"piel": "a8714a", "pelo": "140e0a", "tunica": "f0ead8", "cinto": "8a6a3a", "tocado": "f0ead8", "tocado2": "a08050"},
	"juda": {"piel": "a8714a", "pelo": "2a1a12", "tunica": "8a5a3a", "manto": "6a4a2a", "barba": "2a1a12"},
	"benjamin": {"piel": "c68b5e", "pelo": "3a2416", "tunica": "5a7a9a", "barba": "3a2416"},
	"ruben": {"piel": "b07a52", "pelo": "241812", "tunica": "7a6a4a", "manto": "4a3a2a", "barba": "241812"},
	"simeon": {"piel": "9c6844", "pelo": "1a120c", "tunica": "6a4a6a", "barba": "1a120c"},
	"jacob": {"piel": "c99470", "pelo": "e8e4dc", "tunica": "6a5a4a", "manto": "4a3a2a", "barba": "efeae0",
		"peinado": "calvo", "baston": true},
	"levi": {"piel": "b9845a", "pelo": "2a1a12", "tunica": "4a6a5a", "barba": "2a1a12"},
	"egipcio": {"piel": "a8714a", "pelo": "140e0a", "tunica": "f0ead8", "cinto": "3a5a9a", "tocado": "f0ead8", "tocado2": "3a5a9a"},
	# Rut 1–2
	"rut": {"piel": "c68b5e", "pelo": "2a1a12", "tunica": "9a5a4a", "peinado": "panuelo", "panuelo": "d9b25a"},
	"noemi": {"piel": "c99470", "pelo": "d8d4cc", "tunica": "5a4a6a", "peinado": "panuelo", "panuelo": "3a3048", "baston": true},
	"booz": {"piel": "b9845a", "pelo": "5a5048", "tunica": "6a3a2a", "manto": "8a2a2a", "barba": "8a8078", "turbante": "e8e0cc"},
	"criado": {"piel": "a8714a", "pelo": "1e1610", "tunica": "8a7a5a", "barba": "1e1610"},
	"segador": {"piel": "9c6844", "pelo": "1a120c", "tunica": "c8b88a"},
	"criada": {"piel": "b9845a", "pelo": "2a1a12", "tunica": "8a7a5a", "peinado": "panuelo", "panuelo": "c8b88a"},
	# 1 Samuel 17
	"david": {"piel": "d39b70", "pelo": "9a4a24", "tunica": "a8865a", "cinto": "6b4527", "honda": true, "baston": true},
	"eliab": {"piel": "b07a52", "pelo": "241812", "tunica": "6a5a4a", "barba": "241812", "armadura": "9a7a3a", "casco": "9a7a3a"},
	"saul": {"piel": "b9845a", "pelo": "1e1610", "tunica": "4a3a6a", "manto": "7a1a2a", "barba": "1e1610",
		"armadura": "a07a3a", "casco": "a07a3a", "escala": 1.12},
	"soldado": {"piel": "a8714a", "pelo": "1a120c", "tunica": "5a5a4a", "barba": "1a120c", "casco": "8a6a3a"},
	"goliat": {"piel": "a07050", "pelo": "140e0a", "tunica": "5a3a2a", "barba": "140e0a", "armadura": "b08a40",
		"casco": "b08a40", "lanza": true, "escala": 1.75},
	"escudero": {"piel": "9c6844", "pelo": "140e0a", "tunica": "5a3a2a", "casco": "8a6a3a", "escudo": "8a6a3a"},
	# Nehemías 2–6
	"nehemias": {"piel": "b9845a", "pelo": "2a1a12", "tunica": "3a4a8a", "manto": "2a3058", "cinto": "d9a830",
		"barba": "2a1a12", "turbante": "e8e0cc"},
	"eliasib": {"piel": "c99470", "pelo": "e8e4dc", "tunica": "e8e8f0", "manto": "3a4a9a", "barba": "efeae0", "turbante": "f0f0f0"},
	"sanbalat": {"piel": "9c6844", "pelo": "140e0a", "tunica": "5a1a2a", "manto": "2a1a1a", "barba": "140e0a", "turbante": "8a2a2a"},
	"tobias": {"piel": "b07a52", "pelo": "1e1610", "tunica": "3a5a3a", "manto": "2a3a2a", "barba": "1e1610", "turbante": "6a8a5a"},
	"salum": {"piel": "a8714a", "pelo": "4a4040", "tunica": "6a6a5a", "barba": "6a6058", "peinado": "calvo"},
	"hija_salum": {"piel": "c68b5e", "pelo": "2a1a12", "tunica": "7a8a5a", "peinado": "panuelo", "panuelo": "c8a060"},
	"obrero": {"piel": "9c6844", "pelo": "1a120c", "tunica": "8a7a6a"},
	# Lucas 24
	"cleofas": {"piel": "b07a52", "pelo": "3a2416", "tunica": "7a5a3a", "manto": "5a4030", "barba": "3a2416"},
	"companero": {"piel": "c68b5e", "pelo": "1e1610", "tunica": "5a6a7a", "barba": "1e1610"},
	"forastero": {"piel": "b07a52", "pelo": "2b1d14", "tunica": "d8d0c0", "manto": "7a6a5a", "capucha": true, "barba": "2b1d14"},
}

static var _materiales := {}

var mirando := Vector3(0, 0, 1)
var _fase := 0.0
var _cuerpo: Node3D
var _pierna_i: Node3D
var _pierna_d: Node3D
var _brazo_i: Node3D
var _brazo_d: Node3D
var _cabeza: Node3D
var _amplitud := 0.0
var _t := 0.0
var _mirar_a = null  # punto global al que gira la cabeza (o null)
var _vista_azar := 0.0  # giro de cabeza al mirar alrededor
var _proximo_vistazo := 2.0
var hablando := false
var _gesto := ""
var _gesto_t := 0.0


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
	_construir(ASPECTO.get(clave, ASPECTO["companero"]))


## Aldeano con apariencia al azar (pero siempre igual para la misma semilla).
func configurar_aleatorio(semilla: int, estilo := "hebreo") -> void:
	var r := RandomNumberGenerator.new()
	r.seed = semilla
	var pieles := ["c68b5e", "b07a52", "a8714a", "9c6844", "d39b70", "8f5a3a", "b9845a"]
	var pelos := ["1a120c", "2a1a12", "3a2416", "140e0a", "5a3420", "d8d4cc"]
	var telas := ["8a7a5a", "6a5a4a", "a88a6a", "5a6a7a", "7a5a3a", "9a6a4a", "6a7a5a", "b8a888", "7a4a4a", "4a5a6a"]
	var a := {"piel": pieles[r.randi() % pieles.size()], "pelo": pelos[r.randi() % pelos.size()],
		"tunica": telas[r.randi() % telas.size()]}
	if r.randf() < 0.4:
		a["manto"] = telas[r.randi() % telas.size()]
	var mujer := r.randf() < 0.45
	if r.randf() < 0.16:
		a["nino"] = true
	elif not mujer and r.randf() < 0.65:
		a["barba"] = a["pelo"]
	if estilo == "egipcio":
		a["tunica"] = ["f0ead8", "e8e0c8", "d8ccb0"][r.randi() % 3]
		if r.randf() < 0.5:
			a["tocado"] = "f0ead8"
			a["tocado2"] = ["3a5a9a", "a08050", "6a8a5a"][r.randi() % 3]
		a.erase("barba")
	elif mujer:
		a["peinado"] = "panuelo" if r.randf() < 0.7 else "largo"
		a["panuelo"] = ["d9b25a", "e8e0cc", "8a5a6a", "5a6a8a", "c8a060"][r.randi() % 5]
	elif r.randf() < 0.3:
		a["turbante"] = ["e8e0cc", "c8b88a", "8a6a4a"][r.randi() % 3]
	if r.randf() < 0.12 and not a.has("nino"):
		a["baston"] = true
	_construir(a)


func _construir(a: Dictionary) -> void:
	var piel: String = a["piel"]
	var pelo: String = a["pelo"]
	var tunica: String = a["tunica"]
	var manga := (Color(tunica).darkened(0.25)).to_html(false)
	var oscuro := "1e1628"

	_cuerpo = Node3D.new()
	add_child(_cuerpo)
	if a.get("nino", false):
		scale = Vector3.ONE * 0.72
	if a.has("escala"):
		scale = Vector3.ONE * float(a["escala"])

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
	if a.has("armadura"):  # cota y grebas de bronce (1 Samuel 17:5-6)
		_caja(_cuerpo, Vector3(0.56, 0.46, 0.38), Vector3(0, 1.08, 0), a["armadura"])
		_caja(_pierna_i, Vector3(0.2, 0.3, 0.22), Vector3(0, -0.5, 0), a["armadura"])
		_caja(_pierna_d, Vector3(0.2, 0.3, 0.22), Vector3(0, -0.5, 0), a["armadura"])
	if a.has("collar"):  # collar de oro sobre ropa de lino (Génesis 41:42)
		_caja(_cuerpo, Vector3(0.44, 0.1, 0.36), Vector3(0, 1.28, 0), a["collar"])
		_caja(_cuerpo, Vector3(0.3, 0.12, 0.03), Vector3(0, 1.2, -0.17), a["collar"])

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
	if a.get("honda", false):
		_caja(_brazo_d, Vector3(0.03, 0.34, 0.03), Vector3(0.02, -0.8, -0.04), "5a3a22")
		_caja(_brazo_d, Vector3(0.09, 0.07, 0.06), Vector3(0.02, -0.98, -0.04), "7a5230")
	if a.get("lanza", false):  # el asta como un rodillo de telar, punta de hierro (1 Samuel 17:7)
		_caja(_brazo_d, Vector3(0.09, 2.6, 0.09), Vector3(0, -0.2, -0.12), "6b4527")
		_caja(_brazo_d, Vector3(0.13, 0.32, 0.05), Vector3(0, 1.22, -0.12), "8a8f9a")
	if a.has("escudo"):
		_caja(_brazo_i, Vector3(0.08, 0.8, 0.6), Vector3(-0.08, -0.45, -0.1), a["escudo"])

	# cabeza
	var cabeza := _articulacion(Vector3(0, 1.32, 0))
	_cabeza = cabeza
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
	if a.has("casco"):
		_caja(cabeza, Vector3(0.44, 0.2, 0.44), Vector3(0, 0.36, 0.01), a["casco"])
		_caja(cabeza, Vector3(0.44, 0.26, 0.06), Vector3(0, 0.2, 0.21), a["casco"])
		_caja(cabeza, Vector3(0.08, 0.12, 0.3), Vector3(0, 0.5, 0.02), Color(a["casco"]).darkened(0.3).to_html(false))
	elif a.has("tocado"):  # tocado egipcio a rayas que cae sobre los hombros
		var t1: String = a["tocado"]
		var t2: String = a.get("tocado2", t1)
		_caja(cabeza, Vector3(0.44, 0.12, 0.44), Vector3(0, 0.41, 0.01), t1)
		_caja(cabeza, Vector3(0.44, 0.5, 0.06), Vector3(0, 0.18, 0.21), t1)
		for lado in [-1, 1]:
			_caja(cabeza, Vector3(0.06, 0.55, 0.16), Vector3(lado * 0.22, 0.1, -0.08), t1)
			_caja(cabeza, Vector3(0.065, 0.05, 0.165), Vector3(lado * 0.22, 0.2, -0.08), t2)
			_caja(cabeza, Vector3(0.065, 0.05, 0.165), Vector3(lado * 0.22, 0.02, -0.08), t2)
		_caja(cabeza, Vector3(0.45, 0.04, 0.45), Vector3(0, 0.36, 0.01), t2)
	elif a.has("turbante"):
		_caja(cabeza, Vector3(0.46, 0.18, 0.46), Vector3(0, 0.44, 0.01), a["turbante"])
		_caja(cabeza, Vector3(0.48, 0.05, 0.48), Vector3(0, 0.37, 0.01), Color(a["turbante"]).darkened(0.2).to_html(false))
		_caja(cabeza, Vector3(0.41, 0.2, 0.07), Vector3(0, 0.25, 0.2), pelo)
	elif a.get("capucha", false):
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


## La cabeza gira hacia ese punto (por ejemplo, el jugador). null = mirar al frente o alrededor.
func mirar_hacia(punto) -> void:
	_mirar_a = punto


## Animación corta: "recoger" (se agacha), "encender" (levanta el brazo), "saludar".
func gesto(nombre: String) -> void:
	_gesto = nombre
	_gesto_t = 0.0


## Gira hacia `direccion` y anima el cuerpo: caminar, respirar, mirar, hablar y gestos.
func actualizar(delta: float, direccion: Vector3, moviendose: bool, _camara: Camera3D = null) -> void:
	_t += delta
	if direccion.length_squared() > 0.001:
		mirando = direccion.normalized()
		var objetivo := atan2(-mirando.x, -mirando.z)
		rotation.y = lerp_angle(rotation.y, objetivo, minf(1.0, delta * 10.0))
	# caminar: la amplitud sube y baja suave (sin cortes al arrancar o frenar)
	_amplitud = move_toward(_amplitud, 0.62 if moviendose else 0.0, delta * 3.5)
	if _amplitud > 0.01:
		_fase += delta * 9.5
	else:
		_fase = lerpf(_fase, roundf(_fase / PI) * PI, minf(1.0, delta * 8.0))
	var s := sin(_fase) * _amplitud
	var brazo_i := -s * 0.8
	var brazo_d := s * 0.8
	var cuerpo_y := absf(sin(_fase)) * 0.06 * (_amplitud / 0.62)
	var inclinacion := 0.0
	# respirar y cambiar el peso de pierna cuando está quieto
	if _amplitud < 0.05:
		cuerpo_y += sin(_t * 2.1) * 0.012
		_cuerpo.rotation.z = sin(_t * 0.7) * 0.025
		brazo_i += sin(_t * 2.1) * 0.04
		brazo_d -= sin(_t * 2.1) * 0.04
	else:
		_cuerpo.rotation.z = lerpf(_cuerpo.rotation.z, 0.0, delta * 6.0)
		inclinacion = 0.08 * (_amplitud / 0.62)  # se inclina un poco hacia adelante al caminar
	# hablar: manos que acompañan las palabras y la cabeza asiente
	var cabeza_x := 0.0
	if hablando:
		brazo_d = -0.5 + sin(_t * 5.0) * 0.35
		brazo_i = -0.2 + sin(_t * 3.7 + 1.0) * 0.2
		cabeza_x = sin(_t * 6.0) * 0.07
	# gestos cortos
	if _gesto != "":
		_gesto_t += delta
		var g := sin(clampf(_gesto_t / 0.7, 0.0, 1.0) * PI)
		match _gesto:
			"recoger":
				cuerpo_y -= 0.32 * g
				inclinacion += 0.55 * g
				brazo_d = lerpf(brazo_d, -1.3, g)
				brazo_i = lerpf(brazo_i, -1.1, g)
			"encender":
				brazo_d = lerpf(brazo_d, -2.5, g)
			"saludar":
				brazo_d = -2.7 + sin(_gesto_t * 14.0) * 0.3 * g
				brazo_d = lerpf(0.0, brazo_d, g)
		if _gesto_t > 0.7:
			_gesto = ""
	_pierna_i.rotation.x = s
	_pierna_d.rotation.x = -s
	_brazo_i.rotation.x = lerpf(_brazo_i.rotation.x, brazo_i, minf(1.0, delta * 14.0))
	_brazo_d.rotation.x = lerpf(_brazo_d.rotation.x, brazo_d, minf(1.0, delta * 14.0))
	_cuerpo.position.y = cuerpo_y
	_cuerpo.rotation.x = lerpf(_cuerpo.rotation.x, inclinacion, minf(1.0, delta * 8.0))
	# cabeza: mira a quien tiene cerca, o de vez en cuando echa un vistazo alrededor
	var giro := 0.0
	if _mirar_a != null:
		var local := to_local(_mirar_a)
		giro = clampf(atan2(-local.x, -local.z), -1.1, 1.1)
	else:
		_proximo_vistazo -= delta
		if _proximo_vistazo <= 0:
			_proximo_vistazo = randf_range(2.5, 6.0)
			_vista_azar = randf_range(-0.6, 0.6) if randf() < 0.6 else 0.0
		giro = _vista_azar if _amplitud < 0.05 else 0.0
	_cabeza.rotation.y = lerp_angle(_cabeza.rotation.y, giro, minf(1.0, delta * 5.0))
	_cabeza.rotation.x = lerpf(_cabeza.rotation.x, cabeza_x, minf(1.0, delta * 10.0))
