class_name Nivel
extends Node3D
## Construye un capítulo a partir de su JSON: el mapa es una cuadrícula de caracteres
## (ver datos/LEEME_CAPITULOS.md) y la "leyenda" convierte letras en personajes,
## lámparas, objetos, letreros, mecanismos y salidas.

const C := 2.0  # tamaño de cada celda en metros

const SUELOS := {".": "pasto", "=": "camino", ",": "arena", ":": "adoquin", "_": "madera", "%": "piedra_oscura"}

var datos: Dictionary
var main: Node
var jugador: Jugador
var inicio := Vector3.ZERO
var ancho := 0
var alto := 0
var entidades: Array[Entidad] = []
var progreso_acertijos := {}

var _superficies := {}  # textura -> SurfaceTool
var _solidos := {}  # Vector2i -> altura


func construir(d: Dictionary, main_ref: Node) -> void:
	datos = d
	main = main_ref
	var filas: Array = d["mapa"]
	alto = filas.size()
	for f in filas:
		ancho = max(ancho, String(f).length())
	var leyenda: Dictionary = d.get("leyenda", {})
	var suelo_def: String = d.get("suelo", ".")
	for z in alto:
		var fila: String = filas[z]
		for x in fila.length():
			var ch := fila[x]
			if leyenda.has(ch):
				var def: Dictionary = leyenda[ch]
				_suelo(x, z, String(def.get("suelo", suelo_def)))
				_crear_entidad(def, x, z)
			else:
				_celda(ch, x, z, suelo_def)
	_cerrar_mallas()
	_crear_colisiones()
	_ambiente(d.get("ambiente", {}))


func centro(x: int, z: int) -> Vector3:
	return Vector3((x + 0.5) * C, 0, (z + 0.5) * C)


# ------------------------------------------------------------------ celdas del mapa
func _celda(ch: String, x: int, z: int, suelo_def: String) -> void:
	var p := centro(x, z)
	match ch:
		"#":
			_suelo(x, z, "piedra_oscura")
			_caja(p - Vector3(C / 2, 0, C / 2), p + Vector3(C / 2, 3.2, C / 2), "muro", "muro")
			_solidos[Vector2i(x, z)] = 3.2
		"H":
			_suelo(x, z, "camino")
			_caja(p - Vector3(C / 2, 0, C / 2), p + Vector3(C / 2, 2.6, C / 2), "pared_casa", "tejado")
			_caja(p - Vector3(C / 2 + 0.15, -2.6, C / 2 + 0.15), p + Vector3(C / 2 + 0.15, 2.95, C / 2 + 0.15), "tejado", "tejado")
			_solidos[Vector2i(x, z)] = 3.0
		"~":
			_cara_suelo(p, "agua", -0.3)
			_solidos[Vector2i(x, z)] = 1.5
		"T":
			_suelo(x, z, suelo_def if suelo_def != ":" else ".")
			_sprite_decorado("arbol", p, 0.095)
			_solidos[Vector2i(x, z)] = 2.0
		"B":
			_suelo(x, z, suelo_def)
			_sprite_decorado("arbusto", p, 0.1)
			_solidos[Vector2i(x, z)] = 1.0
		"b":  # arbusto falso: se puede atravesar (pasaje secreto)
			_suelo(x, z, suelo_def)
			_sprite_decorado("arbusto_secreto", p, 0.1)
		"R":
			_suelo(x, z, suelo_def)
			_caja(p - Vector3(0.8, 0, 0.8), p + Vector3(0.8, 1.3, 0.8), "roca", "roca")
			_solidos[Vector2i(x, z)] = 1.3
		"F":
			_suelo(x, z, suelo_def)
			_caja(p - Vector3(C / 2, 0, 0.12), p + Vector3(C / 2, 0.9, 0.12), "madera", "madera")
			_caja(p - Vector3(0.12, 0, C / 2), p + Vector3(0.12, 0.9, C / 2), "madera", "madera")
			_solidos[Vector2i(x, z)] = 0.9
		"P":
			_suelo(x, z, suelo_def)
			inicio = p
		" ":
			pass
		_:
			_suelo(x, z, ch if SUELOS.has(ch) else suelo_def)


func _suelo(x: int, z: int, clave: String) -> void:
	var tex: String = SUELOS.get(clave, clave)
	_cara_suelo(centro(x, z), tex, 0.0)


func _st(tex: String) -> SurfaceTool:
	if not _superficies.has(tex):
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		_superficies[tex] = st
	return _superficies[tex]


func _quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, n: Vector3, uv: Array) -> void:
	for i in [0, 1, 2, 0, 2, 3]:
		st.set_normal(n)
		st.set_uv(uv[i])
		st.add_vertex([a, b, c, d][i])


func _cara_suelo(p: Vector3, tex: String, y: float) -> void:
	var h := C / 2
	_quad(_st(tex), Vector3(p.x - h, y, p.z - h), Vector3(p.x + h, y, p.z - h), Vector3(p.x + h, y, p.z + h),
		Vector3(p.x - h, y, p.z + h), Vector3.UP, [Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)])


func _caja(a: Vector3, b: Vector3, tex_lados: String, tex_arriba: String) -> void:
	var s := _st(tex_lados)
	var u := func(v: float) -> float: return v / C
	var vt := func(y: float) -> float: return (b.y - y) / C
	# norte (-z) y sur (+z)
	_quad(s, Vector3(a.x, b.y, a.z), Vector3(b.x, b.y, a.z), Vector3(b.x, a.y, a.z), Vector3(a.x, a.y, a.z), Vector3.FORWARD,
		[Vector2(u.call(a.x), vt.call(b.y)), Vector2(u.call(b.x), vt.call(b.y)), Vector2(u.call(b.x), vt.call(a.y)), Vector2(u.call(a.x), vt.call(a.y))])
	_quad(s, Vector3(b.x, b.y, b.z), Vector3(a.x, b.y, b.z), Vector3(a.x, a.y, b.z), Vector3(b.x, a.y, b.z), Vector3.BACK,
		[Vector2(u.call(b.x), vt.call(b.y)), Vector2(u.call(a.x), vt.call(b.y)), Vector2(u.call(a.x), vt.call(a.y)), Vector2(u.call(b.x), vt.call(a.y))])
	# oeste (-x) y este (+x)
	_quad(s, Vector3(a.x, b.y, b.z), Vector3(a.x, b.y, a.z), Vector3(a.x, a.y, a.z), Vector3(a.x, a.y, b.z), Vector3.LEFT,
		[Vector2(u.call(b.z), vt.call(b.y)), Vector2(u.call(a.z), vt.call(b.y)), Vector2(u.call(a.z), vt.call(a.y)), Vector2(u.call(b.z), vt.call(a.y))])
	_quad(s, Vector3(b.x, b.y, a.z), Vector3(b.x, b.y, b.z), Vector3(b.x, a.y, b.z), Vector3(b.x, a.y, a.z), Vector3.RIGHT,
		[Vector2(u.call(a.z), vt.call(b.y)), Vector2(u.call(b.z), vt.call(b.y)), Vector2(u.call(b.z), vt.call(a.y)), Vector2(u.call(a.z), vt.call(a.y))])
	# techo
	_quad(_st(tex_arriba), Vector3(a.x, b.y, a.z), Vector3(b.x, b.y, a.z), Vector3(b.x, b.y, b.z), Vector3(a.x, b.y, b.z), Vector3.UP,
		[Vector2(u.call(a.x), u.call(a.z)), Vector2(u.call(b.x), u.call(a.z)), Vector2(u.call(b.x), u.call(b.z)), Vector2(u.call(a.x), u.call(b.z))])


static func material(tex: String) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_texture = load("res://assets/texturas/%s.png" % tex)
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.roughness = 1.0
	if tex == "agua":
		m.albedo_color = Color(1, 1, 1)
		m.emission_enabled = true
		m.emission = Color("1d3a5a")
	return m


func _cerrar_mallas() -> void:
	for tex in _superficies:
		var mi := MeshInstance3D.new()
		mi.mesh = _superficies[tex].commit()
		mi.material_override = material(tex)
		add_child(mi)
	_superficies.clear()


func _sprite_decorado(nombre: String, p: Vector3, tam: float) -> Sprite3D:
	var s := Sprite3D.new()
	s.texture = load("res://assets/sprites/%s.png" % nombre)
	s.pixel_size = tam
	s.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	s.shaded = true
	s.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	s.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	s.position = p + Vector3(0, s.texture.get_height() * tam * 0.5, 0)
	add_child(s)
	return s


# ------------------------------------------------------------------ colisiones
func _crear_colisiones() -> void:
	var cuerpo := StaticBody3D.new()
	add_child(cuerpo)
	# piso
	_caja_colision(cuerpo, Vector3(ancho * C / 2, -0.5, alto * C / 2), Vector3(ancho * C, 1, alto * C))
	# bordes del mapa
	_caja_colision(cuerpo, Vector3(-0.5, 2, alto * C / 2), Vector3(1, 6, alto * C))
	_caja_colision(cuerpo, Vector3(ancho * C + 0.5, 2, alto * C / 2), Vector3(1, 6, alto * C))
	_caja_colision(cuerpo, Vector3(ancho * C / 2, 2, -0.5), Vector3(ancho * C, 6, 1))
	_caja_colision(cuerpo, Vector3(ancho * C / 2, 2, alto * C + 0.5), Vector3(ancho * C, 6, 1))
	# celdas sólidas: se unen tramos horizontales de igual altura
	for z in alto:
		var x := 0
		while x < ancho:
			var k := Vector2i(x, z)
			if not _solidos.has(k):
				x += 1
				continue
			var h: float = _solidos[k]
			var fin := x
			while _solidos.get(Vector2i(fin + 1, z), -1.0) == h:
				fin += 1
			var largo := (fin - x + 1) * C
			_caja_colision(cuerpo, Vector3(x * C + largo / 2, h / 2, (z + 0.5) * C), Vector3(largo, h, C))
			x = fin + 1


func _caja_colision(cuerpo: StaticBody3D, pos: Vector3, tam: Vector3) -> void:
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = tam
	cs.shape = box
	cs.position = pos
	cuerpo.add_child(cs)


# ------------------------------------------------------------------ ambiente
func _ambiente(a: Dictionary) -> void:
	var env := Environment.new()
	var cielo := Sky.new()
	var mat := ProceduralSkyMaterial.new()
	mat.sky_top_color = Color(a.get("cielo_arriba", "#141a33"))
	mat.sky_horizon_color = Color(a.get("cielo_horizonte", "#4a3a5a"))
	mat.ground_horizon_color = mat.sky_horizon_color
	mat.ground_bottom_color = Color("#0d0b14")
	cielo.sky_material = mat
	env.background_mode = Environment.BG_SKY
	env.sky = cielo
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(a.get("luz_ambiente", "#5a5a80"))
	env.ambient_light_energy = float(a.get("energia_ambiente", 0.55))
	env.fog_enabled = true
	env.fog_light_color = Color(a.get("niebla", "#2a2440"))
	env.fog_density = float(a.get("densidad_niebla", 0.025))
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var sol := DirectionalLight3D.new()
	sol.light_color = Color(a.get("sol_color", "#9fb0ff"))
	sol.light_energy = float(a.get("sol_energia", 0.35))
	var rot: Array = a.get("sol_rotacion", [-50, 35])
	sol.rotation_degrees = Vector3(rot[0], rot[1], 0)
	add_child(sol)


# ------------------------------------------------------------------ entidades
func _crear_entidad(def: Dictionary, x: int, z: int) -> void:
	if def.has("id") and Juego.flags.get("tomado_" + String(def["id"]), false):
		return
	var e := Entidad.new()
	e.position = centro(x, z)
	add_child(e)
	e.preparar(def, self)
	entidades.append(e)
	if e.solido:
		_solidos[Vector2i(x, z)] = 1.2


func lampara_encendida(e: Entidad) -> void:
	var id: String = e.def.get("acertijo", "")
	var ac: Dictionary = datos.get("acertijos", {}).get(id, {})
	if ac.is_empty():
		return
	var lista: Array = progreso_acertijos.get(id, [])
	lista.append(e.def.get("simbolo", ""))
	progreso_acertijos[id] = lista
	var orden: Array = ac.get("orden", [])
	if ac.get("en_orden", true) and orden[lista.size() - 1] != lista[-1]:
		progreso_acertijos[id] = []
		for otra in entidades:
			if otra.tipo == "lampara" and otra.def.get("acertijo", "") == id:
				otra.fijar_encendida(false)
		main.iniciar_dialogo(ac.get("dialogo_fallo", ""))
		return
	if lista.size() == orden.size():
		Juego.aplicar(ac.get("al_resolver", {}))
		main.iniciar_dialogo(ac.get("dialogo_exito", ""))


func acertijo_resuelto(id: String) -> bool:
	var ac: Dictionary = datos.get("acertijos", {}).get(id, {})
	var flag = ac.get("al_resolver", {}).get("flag", "")
	return flag != "" and Juego.cumple("flag:" + String(flag))
