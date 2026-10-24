class_name Construccion
extends Node3D
## Bloques de 1 metro estilo Minecraft: picar, poner y planos (siluetas azules que hay que llenar
## con el material indicado). Los planos con "requiere" no se activan hasta que la historia llega
## a ese punto. Lo construido para la historia queda fijo; lo demás se puede volver a picar.

signal plano_completo(id: String)

## textura: de assets/texturas; da: lo que se recoge al picarlo (si no, el mismo material);
## color: de las chispas al picarlo
const MATERIALES := {
	"piedra": {"textura": "muro", "nombre": "Piedra", "icono": "bloque_piedra", "color": "#8a8590"},
	"escombro": {"textura": "roca", "nombre": "Escombro", "icono": "bloque_piedra", "da": "piedra", "color": "#9a9088"},
	"madera": {"textura": "gofer", "nombre": "Madera de gofer", "icono": "bloque_madera", "color": "#b07a44"},
	"brea": {"textura": "brea", "nombre": "Brea", "icono": "bloque_brea", "color": "#2a2420"},
	"tronco": {"textura": "tronco", "nombre": "Tronco", "icono": "bloque_madera", "da": "madera", "color": "#7a5a3a"},
}
const ALCANCE := 5.5
const MAX_LIBRES := 150  # bloques fuera de los planos, para construir libremente
const ALTURA_MAX := 14

var nivel: Nivel
var bloques := {}  # Vector3i -> {"material": String, "fijo": bool}
## id -> {"celdas": {Vector3i: material}, "efectos", "dialogo", "requiere", "hecho", "activo"}
var planos := {}
var seleccion := ""  # material elegido en la barra
var libres := 0
var _mallas := {}  # material -> MeshInstance3D
var _cuerpo: StaticBody3D
var _formas := {}  # Vector3i -> CollisionShape3D
var _fantasmas: MeshInstance3D
var _fantasmas_materiales: Array[Node3D] = []
var _previa: MeshInstance3D
var _material_previa: StandardMaterial3D
var _latido := 0.0


func _ready() -> void:
	_cuerpo = StaticBody3D.new()
	add_child(_cuerpo)
	_previa = MeshInstance3D.new()
	var caja := BoxMesh.new()
	caja.size = Vector3.ONE * 1.04
	_previa.mesh = caja
	_material_previa = StandardMaterial3D.new()
	_material_previa.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_material_previa.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_material_previa.no_depth_test = false
	_previa.material_override = _material_previa
	_previa.visible = false
	add_child(_previa)


static func nombre_de(material: String) -> String:
	return MATERIALES.get(material, {}).get("nombre", material)


# ------------------------------------------------------------------ bloques
func poner(c: Vector3i, material: String, fijo := false, reconstruir := true) -> void:
	if bloques.has(c):
		return
	bloques[c] = {"material": material, "fijo": fijo}
	var forma := CollisionShape3D.new()
	var b := BoxShape3D.new()
	b.size = Vector3.ONE
	forma.shape = b
	forma.position = Vector3(c) + Vector3.ONE * 0.5
	_cuerpo.add_child(forma)
	_formas[c] = forma
	if reconstruir:
		_reconstruir(material)


func quitar(c: Vector3i) -> String:
	if not bloques.has(c):
		return ""
	var material: String = bloques[c]["material"]
	bloques.erase(c)
	_formas[c].queue_free()
	_formas.erase(c)
	_reconstruir(material)
	return material


func se_puede_picar(c: Vector3i) -> bool:
	return bloques.has(c) and not bloques[c]["fijo"]


## Qué se recoge al picar un bloque de este material.
func recurso_de(material: String) -> String:
	return MATERIALES.get(material, {}).get("da", material)


const CARAS := [
	[Vector3i(1, 0, 0), Vector3.RIGHT], [Vector3i(-1, 0, 0), Vector3.LEFT], [Vector3i(0, 1, 0), Vector3.UP],
	[Vector3i(0, -1, 0), Vector3.DOWN], [Vector3i(0, 0, 1), Vector3.BACK], [Vector3i(0, 0, -1), Vector3.FORWARD],
]


## Rehace la malla de un material: solo las caras que dan al aire (como Minecraft).
func _reconstruir(material: String) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var hay_caras := false
	for c in bloques:
		if bloques[c]["material"] != material:
			continue
		for cara in CARAS:
			if bloques.has(c + cara[0]):
				continue
			_cara(st, Vector3(c), cara[1])
			hay_caras = true
	if not _mallas.has(material):
		var mi := MeshInstance3D.new()
		mi.material_override = Nivel.material(MATERIALES.get(material, MATERIALES["piedra"])["textura"])
		add_child(mi)
		_mallas[material] = mi
	_mallas[material].mesh = st.commit() if hay_caras else null


## hundir: mete la cara un poco hacia adentro (siluetas), para que no coincida con el muro de al lado y vibre.
func _cara(st: SurfaceTool, o: Vector3, n: Vector3, hundir := 0.0) -> void:
	# las cuatro esquinas de la cara del cubo unitario en o que mira hacia n
	var centro := o + Vector3.ONE * 0.5 + n * (0.5 - hundir)
	var arriba := Vector3.UP if absf(n.y) < 0.5 else Vector3.FORWARD
	var der := arriba.cross(n) * 0.5
	arriba *= 0.5
	var v := [centro - der + arriba, centro + der + arriba, centro + der - arriba, centro - der - arriba]
	var uv := [Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)]
	for i in [0, 1, 2, 0, 2, 3]:
		st.set_normal(n)
		st.set_uv(uv[i])
		st.add_vertex(v[i])


## Montón de bloques sueltos para picar (escombros, troncos...).
func monton(base: Vector3i, material: String, cantidad: int) -> void:
	var orden := [Vector3i(0, 0, 0), Vector3i(1, 0, 1), Vector3i(1, 0, 0), Vector3i(0, 0, 1), Vector3i(0, 1, 0), Vector3i(1, 1, 1)]
	for i in mini(cantidad, orden.size()):
		poner(base + orden[i], material)


# ------------------------------------------------------------------ planos
func agregar_plano(id: String, celdas: Dictionary, efectos: Dictionary, dialogo: String, requiere: Array, nombre := "") -> void:
	var hecho := Juego.cumple("flag:plano_" + id)
	planos[id] = {"celdas": celdas, "efectos": efectos, "dialogo": dialogo, "requiere": requiere, "hecho": hecho,
		"activo": false, "nombre": nombre}
	if hecho:
		for c in celdas:
			poner(c, celdas[c], true)
	actualizar_planos()
	_dibujar_fantasmas()  # los planos que aún no se activan también se ven, en gris, para saber dónde irán


## Activa los planos cuya condición ya se cumple. Devuelve true si alguno se activó ahora.
func actualizar_planos() -> bool:
	var cambio := false
	for id in planos:
		var p: Dictionary = planos[id]
		var activo: bool = not p["hecho"] and Juego.cumple(p["requiere"])
		if activo != p["activo"]:
			p["activo"] = activo
			cambio = true
	if cambio:
		_dibujar_fantasmas()
	return cambio and planos.values().any(func(p): return p["activo"])


func _dibujar_fantasmas() -> void:
	for fantasma in _fantasmas_materiales:
		fantasma.queue_free()
	_fantasmas_materiales.clear()
	var superficies := {}
	for id in planos:
		if not planos[id]["activo"]:
			continue
		for c in planos[id]["celdas"]:
			if bloques.has(c):
				continue
			var material: String = planos[id]["celdas"][c]
			if not superficies.has(material):
				var st := SurfaceTool.new()
				st.begin(Mesh.PRIMITIVE_TRIANGLES)
				superficies[material] = st
			for cara in CARAS:
				if not planos[id]["celdas"].has(c + cara[0]) and not bloques.has(c + cara[0]):
					_cara(superficies[material], Vector3(c), cara[1], 0.03)
	for material in superficies:
		var mi := MeshInstance3D.new()
		mi.mesh = superficies[material].commit()
		var m := Nivel.material(MATERIALES[material]["textura"]).duplicate() as StandardMaterial3D
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED  # se ve igual de claro de noche
		m.albedo_color = Color(0.55, 1.0, 0.75, 0.6)
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
		mi.material_override = m
		mi.set_meta("latir", true)
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mi)
		_fantasmas_materiales.append(mi)
	# planos que aún no son tiempo de construir: silueta gris tenue para ver dónde irán
	var pendientes := SurfaceTool.new()
	pendientes.begin(Mesh.PRIMITIVE_TRIANGLES)
	var hay_pendientes := false
	for id in planos:
		if planos[id]["activo"] or planos[id]["hecho"]:
			continue
		for c in planos[id]["celdas"]:
			for cara in CARAS:
				if not planos[id]["celdas"].has(c + cara[0]):
					_cara(pendientes, Vector3(c), cara[1], 0.03)
					hay_pendientes = true
	if hay_pendientes:
		var gris := MeshInstance3D.new()
		gris.mesh = pendientes.commit()
		var mg := StandardMaterial3D.new()
		mg.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mg.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mg.albedo_color = Color(0.75, 0.8, 0.95, 0.22)
		mg.cull_mode = BaseMaterial3D.CULL_DISABLED
		gris.material_override = mg
		gris.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(gris)
		_fantasmas_materiales.append(gris)
	# cartel flotante sobre cada plano: qué va y cuántos faltan (o que aún no es tiempo)
	for id in planos:
		if planos[id]["activo"] or planos[id]["hecho"]:
			continue
		var suma_p := Vector3.ZERO
		var tope_p := -INF
		for c in planos[id]["celdas"]:
			suma_p += Vector3(c)
			tope_p = maxf(tope_p, c.y)
		var centro_p: Vector3 = suma_p / float(planos[id]["celdas"].size()) + Vector3(0.5, 0, 0.5)
		var cartel_p := Label3D.new()
		cartel_p.text = "%s\n(%s)" % [String(planos[id].get("nombre", "Aquí irá la obra")), String(planos[id].get("pendiente", "más adelante"))]
		cartel_p.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		cartel_p.visibility_range_end = 16.0  # solo de cerca: de lejos era un letrero diminuto que se veía a través de las paredes
		cartel_p.pixel_size = 0.006
		cartel_p.font_size = 40
		cartel_p.outline_size = 14
		cartel_p.modulate = Color(0.85, 0.88, 1.0, 0.85)
		cartel_p.outline_modulate = Color(0.05, 0.05, 0.12)
		cartel_p.position = Vector3(centro_p.x, tope_p + 2.0, centro_p.z)
		add_child(cartel_p)
		_fantasmas_materiales.append(cartel_p)
	# cartel flotante sobre cada plano activo: qué va y cuántos faltan
	for id in planos:
		if not planos[id]["activo"]:
			continue
		var faltan_aqui := faltan(id)
		if faltan_aqui == 0:
			continue
		var tope := Vector3(-INF, -INF, -INF)
		var suma := Vector3.ZERO
		for c in planos[id]["celdas"]:
			suma += Vector3(c)
			tope = tope.max(Vector3(c))
		var centro: Vector3 = suma / float(planos[id]["celdas"].size()) + Vector3(0.5, 0, 0.5)
		var cartel := Label3D.new()
		cartel.text = "Pon aquí: %s\n(faltan %d)" % [nombre_de(planos[id]["celdas"].values()[0]), faltan_aqui]
		cartel.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		cartel.no_depth_test = true
		cartel.visibility_range_end = 30.0
		cartel.pixel_size = 0.006
		cartel.font_size = 44
		cartel.outline_size = 14
		cartel.modulate = Color("bff6d0")
		cartel.outline_modulate = Color(0.04, 0.1, 0.06)
		cartel.position = Vector3(centro.x, tope.y + 2.0, centro.z)
		add_child(cartel)
		_fantasmas_materiales.append(cartel)


func _process(delta: float) -> void:
	# las siluetas laten para que se vean de lejos
	_latido += delta
	var alfa := 0.62 + 0.26 * sin(_latido * 3.5)
	for f in _fantasmas_materiales:
		if f is MeshInstance3D and f.has_meta("latir"):  # solo laten las siluetas activas
			(f.material_override as StandardMaterial3D).albedo_color.a = alfa


## El plano (sin terminar) al que pertenece la celda, o "".
func plano_de(c: Vector3i) -> String:
	for id in planos:
		if not planos[id]["hecho"] and planos[id]["celdas"].has(c):
			return id
	return ""


func material_de_plano(c: Vector3i) -> String:
	var id := plano_de(c)
	return String(planos[id]["celdas"].get(c, "")) if id != "" else ""


## Revisa si algún plano quedó completo; lo fija y aplica sus efectos.
func revisar_planos() -> void:
	for id in planos:
		var p: Dictionary = planos[id]
		if p["hecho"] or not p["activo"]:
			continue
		var completo := true
		for c in p["celdas"]:
			if not bloques.has(c) or bloques[c]["material"] != p["celdas"][c]:
				completo = false
				break
		if completo:
			p["hecho"] = true
			p["activo"] = false
			for c in p["celdas"]:
				bloques[c]["fijo"] = true  # lo construido para la historia ya no se pica
			Juego.marcar("plano_" + id)
			Juego.aplicar(p["efectos"])
			plano_completo.emit(id)
	_dibujar_fantasmas()


func faltan(id: String) -> int:
	var n := 0
	for c in planos[id]["celdas"]:
		var b: Dictionary = bloques.get(c, {})
		if b.get("material", "") != planos[id]["celdas"][c]:
			n += 1
	return n


## Celda que falta en un plano, la más cercana a p (para el faro), o null.
func celda_que_falta(id: String, p: Vector3) -> Variant:
	var mejor: Variant = null
	var d_mejor := INF
	for c in planos[id]["celdas"]:
		if bloques.get(c, {}).get("material", "") == planos[id]["celdas"][c]:
			continue
		var d: float = (Vector3(c) + Vector3.ONE * 0.5).distance_to(p) + c.y * 3.0  # primero lo de abajo
		if d < d_mejor:
			d_mejor = d
			mejor = c
	return mejor


## Bloque suelto más cercano que, al picarlo, da este material (para el faro), o null.
func fuente_de(material: String, p: Vector3) -> Variant:
	var mejor: Variant = null
	var d_mejor := INF
	for c in bloques:
		if se_puede_picar(c) and recurso_de(bloques[c]["material"]) == material and plano_de(c) == "":
			var d: float = Vector3(c).distance_to(p)
			if d < d_mejor:
				d_mejor = d
				mejor = c
	return mejor


## Cuántos bloques de cada material faltan en los planos activos.
func faltantes() -> Dictionary:
	var r := {}
	for id in planos:
		if planos[id]["activo"]:
			for c in planos[id]["celdas"]:
				var m: String = planos[id]["celdas"][c]
				if bloques.get(c, {}).get("material", "") != m:
					r[m] = r.get(m, 0) + 1
	return r


# ------------------------------------------------------------------ poner con reglas
## "" si se puede poner un bloque de este material en c; si no, el motivo para el jugador.
func motivo_para_no_poner(c: Vector3i, material: String) -> String:
	if bloques.has(c):
		return "Ahí ya hay un bloque."
	if c.y < 0 or c.y >= ALTURA_MAX or c.x < 2 or c.z < 2 or c.x >= nivel.ancho * 2 - 2 or c.z >= nivel.alto * 2 - 2:
		return "No se puede construir ahí."
	if _choca_con_personas(c):
		return "Apártate un poco para poner el bloque."
	var id := plano_de(c)
	if id != "":
		if not planos[id]["activo"]:
			return "Todavía no es tiempo de construir aquí."
		if planos[id]["celdas"][c] != material:
			return "Aquí va %s." % nombre_de(planos[id]["celdas"][c]).to_lower()
	elif libres >= MAX_LIBRES:
		return "Ya pusiste muchos bloques sueltos. Pica algunos para reusarlos."
	return ""


func _choca_con_personas(c: Vector3i) -> bool:
	var caja := AABB(Vector3(c), Vector3.ONE).grow(-0.02)
	var cuerpos: Array = [nivel.jugador]
	for e in nivel.entidades:
		if is_instance_valid(e) and e.tipo == "npc":
			cuerpos.append(e)
	for cuerpo in cuerpos:
		var p: Vector3 = cuerpo.global_position
		if caja.intersects(AABB(p - Vector3(0.36, 0, 0.36), Vector3(0.72, 1.75, 0.72))):
			return true
	return false


## Pone un bloque del jugador (ya validado). Lleva la cuenta de los bloques sueltos.
func poner_jugador(c: Vector3i, material: String) -> void:
	if plano_de(c) == "":
		libres += 1
	poner(c, material)
	revisar_planos()


func picar_jugador(c: Vector3i) -> String:
	var era_suelto: bool = plano_de(c) == "" and bloques.get(c, {}).get("material", "") in ["piedra", "madera", "brea"]
	var m := quitar(c)
	if era_suelto:
		libres = maxi(libres - 1, 0)
	_dibujar_fantasmas()
	return recurso_de(m)


# ------------------------------------------------------------------ apuntar
## Lo que el jugador apunta desde el centro de la cámara:
## {"bloque": Vector3i (lo tocado), "poner": Vector3i (la celda de al lado)} o {}.
func apuntar(camara: Camera3D, cuerpo_jugador: CollisionObject3D) -> Dictionary:
	var desde := camara.global_position
	var largo := ALCANCE + desde.distance_to(cuerpo_jugador.global_position)
	var q := PhysicsRayQueryParameters3D.create(desde, desde - camara.global_basis.z * largo)
	q.exclude = [cuerpo_jugador.get_rid()]
	var r := get_world_3d().direct_space_state.intersect_ray(q)
	if r.is_empty():
		return {}
	var p: Vector3 = r["position"]
	if p.distance_to(cuerpo_jugador.global_position + Vector3(0, 1.0, 0)) > ALCANCE:
		return {}
	var n: Vector3 = r["normal"]
	return {"bloque": Vector3i((p - n * 0.02).floor()), "poner": Vector3i((p + n * 0.02).floor())}


## Cubo translúcido donde va a caer el bloque (verde si encaja en un plano) o, para picar, rojizo.
func mostrar_previa(c: Variant, modo: String, material: String = "") -> void:
	_previa.visible = c != null and modo != ""
	if not _previa.visible:
		return
	_previa.position = Vector3(c) + Vector3.ONE * 0.5
	if material == "":
		material = seleccion if modo == "poner" else "piedra"
	var textura: String = MATERIALES.get(material, MATERIALES["piedra"])["textura"]
	_material_previa.albedo_texture = load("res://assets/texturas/%s.png" % textura)
	match modo:
		"plano": _material_previa.albedo_color = Color(0.72, 1.0, 0.78, 0.62)
		"poner": _material_previa.albedo_color = Color(1, 1, 1, 0.58)
		"picar": _material_previa.albedo_color = Color(1.0, 0.72, 0.52, 0.48)
