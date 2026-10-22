class_name Nivel
extends Node3D
## Construye un capítulo a partir de su JSON: el mapa es una cuadrícula de caracteres
## (ver datos/LEEME_CAPITULOS.md) y la "leyenda" convierte letras en personajes,
## lámparas, objetos, letreros, mecanismos y salidas.

const C := 2.0  # tamaño de cada celda en metros

const SUELOS := {".": "pasto", "=": "camino", ",": "arena", ":": "adoquin", "_": "madera", "%": "piedra_oscura",
	";": "cebada"}

var datos: Dictionary
var main: Node
var jugador: Jugador
var inicio := Vector3.ZERO
var ancho := 0
var alto := 0
var entidades: Array[Entidad] = []
var progreso_acertijos := {}
var ciclo: CicloDia
var _materiales_lejanos: Array[StandardMaterial3D] = []

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
				_crear_entidad(def, x, z, ch)
			else:
				_celda(ch, x, z, suelo_def)
	_cordillera(d.get("ambiente", {}))
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
		"A":  # tienda de campaña
			_suelo(x, z, suelo_def)
			_caja(p - Vector3(0.9, 0, 0.9), p + Vector3(0.9, 1.6, 0.9), "tela", "tela")
			_caja(p - Vector3(0.6, -1.6, 0.6), p + Vector3(0.6, 2.2, 0.6), "tela", "tela")
			_solidos[Vector2i(x, z)] = 2.2
		"^":  # cerro natural en terrazas: más alto cuanto más cerca del borde del mapa
			var al_borde := mini(mini(x, ancho - 1 - x), mini(z, alto - 1 - z))
			var altura := (2.4 if al_borde == 0 else 1.4) + float((x * 7 + z * 13) % 3) * 0.3
			var lado := "ladera_arena" if suelo_def == "," else ("roca" if suelo_def == "%" else "ladera")
			var tope := "arena" if suelo_def == "," else ("piedra_oscura" if suelo_def == "%" else "pasto")
			_caja(p - Vector3(C / 2, 0, C / 2), p + Vector3(C / 2, altura, C / 2), lado, tope)
			_solidos[Vector2i(x, z)] = altura
		"Y":
			_suelo(x, z, suelo_def)
			_sprite_decorado("palmera", p, 0.1)
			_solidos[Vector2i(x, z)] = 2.0
		"&":
			_suelo(x, z, suelo_def)
			_sprite_decorado("vasijas", p, 0.06)
			_solidos[Vector2i(x, z)] = 0.8
		"*":
			_suelo(x, z, suelo_def)
			for k in 3:
				var desfase := Vector3(float((x * 3 + k * 5) % 7) / 7.0 - 0.5, 0, float((z * 5 + k * 3) % 7) / 7.0 - 0.5) * 1.4
				_sprite_decorado("flores", p + desfase, 0.05)
		"$":  # puesto de mercado: mesa de madera con toldo de tela
			_suelo(x, z, suelo_def)
			_caja(p - Vector3(0.85, 0, 0.5), p + Vector3(0.85, 0.85, 0.5), "madera", "madera")
			for dx in [-0.8, 0.8]:
				_caja(p + Vector3(dx - 0.06, 0, -0.06), p + Vector3(dx + 0.06, 2.1, 0.06), "madera", "madera")
			_caja(p - Vector3(1.0, -2.1, 0.7), p + Vector3(1.0, 2.25, 0.7), "tela", "tela")
			_solidos[Vector2i(x, z)] = 1.0
		"+":  # aldeano que camina por la zona
			_suelo(x, z, suelo_def)
			_crear_entidad({"tipo": "npc", "nombre": "Aldeano", "aldeano": true, "dialogos": [],
				"estilo": datos.get("estilo_aldeanos", "hebreo")}, x, z, "+")
		"|":  # fogata
			_suelo(x, z, suelo_def)
			_fogata(p)
			_solidos[Vector2i(x, z)] = 0.6
		"?":  # pared falsa: parece muro de piedra pero se puede atravesar (escondite)
			_suelo(x, z, suelo_def)
			_caja(p - Vector3(C / 2, 0, C / 2), p + Vector3(C / 2, 3.2, C / 2), "muro", "muro")
		"!":  # entrada de cueva: parece cerro pero se puede atravesar (escondite)
			_suelo(x, z, suelo_def)
			var lado_c := "ladera_arena" if suelo_def == "," else ("roca" if suelo_def == "%" else "ladera")
			_caja(p - Vector3(C / 2, 0, C / 2), p + Vector3(C / 2, 2.4, C / 2), lado_c, "pasto" if lado_c == "ladera" else "arena")
		"@":  # oveja que pasta
			_suelo(x, z, suelo_def)
			var o := Oveja.new()
			o.position = p
			add_child(o)
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


## Luciérnagas, polen o polvo flotando alrededor del jugador.
func particulas_ambiente(jugador: Node3D, tipo: String) -> void:
	if tipo == "":
		return
	var p := CPUParticles3D.new()
	p.local_coords = false
	p.amount = 60 if tipo == "luciernagas" else 90
	p.lifetime = 7.0
	p.preprocess = 7.0
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = Vector3(12, 2.5, 12)
	p.position.y = 1.8
	p.direction = Vector3(1, 0.2, 0.3)
	p.spread = 180.0
	p.gravity = Vector3(0, 0.03 if tipo == "luciernagas" else -0.02, 0)
	p.initial_velocity_min = 0.1
	p.initial_velocity_max = 0.45
	var malla := BoxMesh.new()
	malla.size = Vector3.ONE * (0.07 if tipo == "luciernagas" else 0.045)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = {"luciernagas": Color("e8ff7a"), "polen": Color("fff8d8"), "polvo": Color("f0d8a0")}.get(tipo, Color.WHITE)
	malla.material = m
	p.mesh = malla
	var curva := Curve.new()
	curva.add_point(Vector2(0, 0))
	curva.add_point(Vector2(0.2, 1))
	curva.add_point(Vector2(0.8, 1))
	curva.add_point(Vector2(1, 0))
	p.scale_amount_curve = curva
	jugador.add_child(p)


## Montañas lejanas en dos capas (perspectiva aérea): la lejana casi del color del horizonte,
## la cercana más oscura. Crestas irregulares que se oscurecen hacia la base.
func _cordillera(a: Dictionary) -> void:
	var centro_mapa := Vector3(ancho * C / 2, 0, alto * C / 2)
	var horizonte := Color(a.get("cielo_horizonte", "#4a3a5a"))
	var base_color := Color(a.get("montanas", "#6a6a80"))
	var capas := [
		{"radio": maxf(ancho, alto) * C * 0.95 + 70.0, "alto": 34.0, "color": base_color.lerp(horizonte, 0.6), "semilla": 7},
		{"radio": maxf(ancho, alto) * C * 0.75 + 32.0, "alto": 16.0, "color": base_color.lerp(horizonte, 0.15), "semilla": 3},
	]
	for capa in capas:
		var azar := RandomNumberGenerator.new()
		azar.seed = ancho * 100 + alto + int(capa["semilla"])
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		var n := 96
		var alturas := []
		var h := 0.5
		for i in n:  # cresta suave: paseo aleatorio que vuelve a su inicio
			h = clampf(h + azar.randf_range(-0.22, 0.22), 0.15, 1.0)
			alturas.append(h)
		var radio: float = capa["radio"]
		var color: Color = capa["color"]
		for i in n:
			var a0 := TAU * i / n
			var a1 := TAU * (i + 1) / n
			var h0: float = alturas[i] * capa["alto"]
			var h1: float = alturas[(i + 1) % n] * capa["alto"]
			var b0 := centro_mapa + Vector3(cos(a0), 0, sin(a0)) * radio
			var b1 := centro_mapa + Vector3(cos(a1), 0, sin(a1)) * radio
			var c0 := b0 + Vector3(0, h0, 0)
			var c1 := b1 + Vector3(0, h1, 0)
			var abajo := color.darkened(0.25)
			for v in [[b0, abajo], [c0, color], [c1, color], [b0, abajo], [c1, color], [b1, abajo]]:
				st.set_color(v[1])
				st.add_vertex(v[0] + Vector3(0, -2, 0))
		var mi := MeshInstance3D.new()
		mi.mesh = st.commit()
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.vertex_color_use_as_albedo = true
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
		mi.material_override = m
		_materiales_lejanos.append(m)
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mi)
	# suelo lejano bajo las montañas
	var lejos := MeshInstance3D.new()
	var plano := PlaneMesh.new()
	var r_max: float = capas[0]["radio"]
	plano.size = Vector2(r_max * 2.4, r_max * 2.4)
	lejos.mesh = plano
	lejos.position = centro_mapa + Vector3(0, -0.05, 0)
	var ml := StandardMaterial3D.new()
	ml.albedo_color = Color(a.get("suelo_lejano", "#5a6a40"))
	ml.roughness = 1.0
	lejos.material_override = ml
	add_child(lejos)


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
		Vector3(p.x - h, y, p.z + h), Vector3.UP, [Vector2(0, 0), Vector2(C, 0), Vector2(C, C), Vector2(0, C)] if tex != "agua" else [Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)])


func _caja(a: Vector3, b: Vector3, tex_lados: String, tex_arriba: String) -> void:
	var s := _st(tex_lados)
	# 16 píxeles de textura por metro (como Minecraft); la casa conserva una ventana por celda
	var escala := C if tex_lados in ["pared_casa"] else 1.0
	var u := func(v: float) -> float: return v / escala
	var vt := func(y: float) -> float: return (b.y - y) / escala
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


var _material_agua: StandardMaterial3D


func _cerrar_mallas() -> void:
	for tex in _superficies:
		var mi := MeshInstance3D.new()
		mi.mesh = _superficies[tex].commit()
		mi.material_override = material(tex)
		if tex == "agua":
			_material_agua = mi.material_override
		add_child(mi)
	_superficies.clear()


const FLEXIBLE := {"arbol": 0.22, "palmera": 0.35, "arbusto": 0.07, "arbusto_secreto": 0.07, "flores": 0.05, "vasijas": 0.0}
var _materiales_vegetacion := {}


## Planta o decorado como un cuadro que mira a la cámara y se mece con el viento (shader).
func _sprite_decorado(nombre: String, p: Vector3, tam: float) -> MeshInstance3D:
	var tex: Texture2D = load("res://assets/sprites/%s.png" % nombre)
	if not _materiales_vegetacion.has(nombre):
		var m := ShaderMaterial.new()
		m.shader = load("res://shaders/vegetacion.gdshader")
		m.set_shader_parameter("textura", tex)
		m.set_shader_parameter("flexible", FLEXIBLE.get(nombre, 0.1))
		_materiales_vegetacion[nombre] = m
	var mi := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(tex.get_width(), tex.get_height()) * tam
	mi.mesh = q
	mi.material_override = _materiales_vegetacion[nombre]
	mi.position = p + Vector3(0, tex.get_height() * tam * 0.5, 0)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	return mi


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
	var sol := DirectionalLight3D.new()
	sol.light_color = Color(a.get("sol_color", "#9fb0ff"))
	sol.light_energy = float(a.get("sol_energia", 0.35))
	var rot: Array = a.get("sol_rotacion", [-50, 35])
	sol.rotation_degrees = Vector3(rot[0], rot[1], 0)
	add_child(sol)

	var cielo_mat := ShaderMaterial.new()
	cielo_mat.shader = load("res://shaders/cielo.gdshader")
	var horizonte := Color(a.get("cielo_horizonte", "#4a3a5a"))
	cielo_mat.set_shader_parameter("arriba", Color(a.get("cielo_arriba", "#141a33")))
	cielo_mat.set_shader_parameter("horizonte", horizonte)
	cielo_mat.set_shader_parameter("suelo", horizonte.darkened(0.6))
	# el astro está en dirección contraria a donde apunta la luz
	cielo_mat.set_shader_parameter("dir_astro", sol.global_basis.z if sol.is_inside_tree() else Basis.from_euler(sol.rotation).z)
	var luna := bool(a.get("luna", false))
	cielo_mat.set_shader_parameter("es_luna", 1.0 if luna else 0.0)
	cielo_mat.set_shader_parameter("color_astro", Color(a.get("color_astro", "#e8eeff" if luna else "#fff4d6")))
	cielo_mat.set_shader_parameter("tam_astro", 0.035 if luna else 0.05)
	cielo_mat.set_shader_parameter("estrellas", float(a.get("estrellas", 1.0 if luna else 0.0)))
	cielo_mat.set_shader_parameter("nubes", float(a.get("nubes", 0.45)))
	cielo_mat.set_shader_parameter("color_nube", Color(a.get("color_nube", "#fff6ec")))
	cielo_mat.set_shader_parameter("sombra_nube", Color(a.get("sombra_nube", "#b8aec8")))
	var cielo := Sky.new()
	cielo.sky_material = cielo_mat
	cielo.radiance_size = Sky.RADIANCE_SIZE_32

	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = cielo
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(a.get("luz_ambiente", "#5a5a80"))
	env.ambient_light_energy = float(a.get("energia_ambiente", 0.55))
	env.fog_enabled = true
	env.fog_light_color = Color(a.get("niebla", "#2a2440"))
	env.fog_density = float(a.get("densidad_niebla", 0.025))
	env.fog_sky_affect = 0.15
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	if a.get("aves", false):
		var aves := Aves.new()
		aves.position = Vector3(ancho * C / 2, 0, alto * C / 2)
		aves.radio = minf(ancho, alto) * C * 0.4
		add_child(aves)
	# ciclo de día y noche (opcional): {"inicio": hora, "fin": hora, "minutos": duración real}
	if a.has("ciclo"):
		ciclo = CicloDia.new()
		ciclo.sol = sol
		ciclo.env = env
		ciclo.cielo = cielo_mat
		ciclo.lejanos = _materiales_lejanos
		add_child(ciclo)
		ciclo.configurar(a["ciclo"])


# ------------------------------------------------------------------ entidades
func _crear_entidad(def: Dictionary, x: int, z: int, letra: String) -> void:
	if def.has("id") and Juego.flags.get("tomado_" + String(def["id"]), false):
		return
	var e := Entidad.new()
	e.letra = letra
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
		Sonido.efecto("fallo")
		main.iniciar_dialogo(ac.get("dialogo_fallo", ""))
		return
	# cada lámpara puede tener su propio texto al encenderse bien (p. ej. un pasaje bíblico)
	var dialogos: Dictionary = datos.get("dialogos", {})
	var lineas: Array = dialogos.get(e.def.get("dialogo", ""), []).duplicate()
	if lista.size() == orden.size():
		Juego.aplicar(ac.get("al_resolver", {}))
		Sonido.efecto("exito")
		for otra in entidades:
			if is_instance_valid(otra) and otra.tipo == "lampara" and otra.def.get("acertijo", "") == id:
				chispas(otra.global_position + Vector3(0, 2.0, 0), Color("ffe08a"), 60)
		lineas += dialogos.get(ac.get("dialogo_exito", ""), [])
	main.mostrar_lineas(lineas)


## Estallido de chispas de luz (al encender, recoger o resolver algo).
func chispas(pos: Vector3, color := Color("ffd36b"), cantidad := 40) -> void:
	var p := CPUParticles3D.new()
	p.position = pos
	p.one_shot = true
	p.amount = cantidad
	p.lifetime = 1.1
	p.explosiveness = 0.9
	p.direction = Vector3.UP
	p.spread = 70.0
	p.initial_velocity_min = 2.0
	p.initial_velocity_max = 5.0
	p.gravity = Vector3(0, -4.0, 0)
	p.scale_amount_min = 0.6
	p.scale_amount_max = 1.2
	var malla := BoxMesh.new()
	malla.size = Vector3.ONE * 0.09
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = color
	malla.material = m
	p.mesh = malla
	add_child(p)
	p.emitting = true
	get_tree().create_timer(2.0).timeout.connect(p.queue_free)


func _process(delta: float) -> void:
	if _material_agua:  # el agua corre despacio
		_material_agua.uv1_offset += Vector3(delta * 0.12, delta * 0.05, 0)


## Fogata: leños, llamas que titilan, chispas que suben y luz cálida.
func _fogata(p: Vector3) -> void:
	var raiz := Node3D.new()
	raiz.position = p
	add_child(raiz)
	for ang in [0.0, 1.2, 2.4]:
		var lenio := MeshInstance3D.new()
		var b := BoxMesh.new()
		b.size = Vector3(0.9, 0.14, 0.16)
		lenio.mesh = b
		lenio.material_override = Personaje3D.material("5a3a22")
		lenio.position.y = 0.08
		lenio.rotation.y = ang
		raiz.add_child(lenio)
	var fuego := CPUParticles3D.new()
	fuego.amount = 26
	fuego.lifetime = 0.8
	fuego.position.y = 0.2
	fuego.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	fuego.emission_sphere_radius = 0.22
	fuego.direction = Vector3.UP
	fuego.spread = 15.0
	fuego.gravity = Vector3(0, 1.8, 0)
	fuego.initial_velocity_min = 0.4
	fuego.initial_velocity_max = 1.0
	var malla := BoxMesh.new()
	malla.size = Vector3.ONE * 0.16
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.vertex_color_use_as_albedo = true
	malla.material = m
	fuego.mesh = malla
	var g := Gradient.new()
	g.colors = PackedColorArray([Color("fff2a0"), Color("ff9a30"), Color("c03a10"), Color(0.2, 0.1, 0.05, 0.0)])
	g.offsets = PackedFloat32Array([0.0, 0.35, 0.75, 1.0])
	fuego.color_ramp = g
	var curva := Curve.new()
	curva.add_point(Vector2(0, 1))
	curva.add_point(Vector2(1, 0.2))
	fuego.scale_amount_curve = curva
	raiz.add_child(fuego)
	var luz := OmniLight3D.new()
	luz.light_color = Color("ffa040")
	luz.light_energy = 1.8
	luz.omni_range = 7.0
	luz.position.y = 0.8
	raiz.add_child(luz)
	var t := luz.create_tween().set_loops()
	t.tween_property(luz, "light_energy", 1.3, 0.13)
	t.tween_property(luz, "light_energy", 2.0, 0.17)
	t.tween_property(luz, "light_energy", 1.6, 0.11)


## ¿Se puede pisar este punto del mundo? (para que los aldeanos no atraviesen paredes)
func libre(p: Vector3) -> bool:
	var celda := Vector2i(floori(p.x / C), floori(p.z / C))
	if celda.x < 1 or celda.y < 1 or celda.x >= ancho - 1 or celda.y >= alto - 1:
		return false
	var fila: String = datos["mapa"][celda.y]
	return not _solidos.has(celda) and fila[celda.x] != "~"


## La siguiente lámpara correcta de un acertijo (para la guía visual), o null.
func siguiente_del_acertijo(id: String) -> Entidad:
	var ac: Dictionary = datos.get("acertijos", {}).get(id, {})
	var orden: Array = ac.get("orden", [])
	var hechos: int = progreso_acertijos.get(id, []).size()
	if acertijo_resuelto(id) or hechos >= orden.size():
		return null
	for e in entidades:
		if is_instance_valid(e) and e.tipo == "lampara" and e.def.get("acertijo", "") == id and e.def.get("simbolo", "") == orden[hechos]:
			return e
	return null


func acertijo_resuelto(id: String) -> bool:
	var ac: Dictionary = datos.get("acertijos", {}).get(id, {})
	var flag = ac.get("al_resolver", {}).get("flag", "")
	return flag != "" and Juego.cumple("flag:" + String(flag))
