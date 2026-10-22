class_name CicloDia
extends Node
## Hace avanzar la hora del día: mueve el sol (o la luna), cambia los colores del cielo,
## la luz, la niebla y el brillo de las montañas lejanas, interpolando entre momentos del día.

## hora, cielo arriba, horizonte, color astro, energía astro, luz ambiente, energía ambiente,
## niebla, nube clara, nube sombra, estrellas, brillo de lo lejano
const MOMENTOS := [
	[0.0, "0a0e24", "1c2240", "8fa0ff", 0.25, "3a4068", 0.5, "121628", "3a4060", "1a2036", 1.0, 0.3],
	[6.0, "3a5a9a", "f0a070", "ffb070", 0.7, "9a8090", 0.6, "c89080", "ffc8a8", "8a6a8a", 0.2, 0.75],
	[9.0, "3a72c8", "c8dcef", "fff0d0", 1.1, "b0aab0", 0.72, "c8d4e0", "ffffff", "b8c0d0", 0.0, 1.0],
	[15.0, "3a72c8", "d0e0ee", "fff2d8", 1.15, "b4aeb0", 0.74, "ccd6e2", "ffffff", "b8c0d0", 0.0, 1.0],
	[17.5, "3a4a9a", "f09060", "ffa060", 0.8, "a08080", 0.65, "b07870", "ffb890", "8a5a6a", 0.1, 0.8],
	[19.5, "141838", "4a3050", "a0a8ff", 0.3, "4a4060", 0.5, "2a2034", "5a4060", "2a2040", 0.7, 0.4],
	[24.0, "0a0e24", "1c2240", "8fa0ff", 0.25, "3a4068", 0.5, "121628", "3a4060", "1a2036", 1.0, 0.3],
]

var hora := 9.0
var hora_fin := 9.0
var horas_por_segundo := 0.0
var sol: DirectionalLight3D
var env: Environment
var cielo: ShaderMaterial
var lejanos: Array[StandardMaterial3D] = []
var _espera := 0.0


func configurar(c: Dictionary) -> void:
	hora = float(c.get("inicio", 9.0))
	hora_fin = float(c.get("fin", hora))
	var minutos := float(c.get("minutos", 10.0))
	horas_por_segundo = (hora_fin - hora) / (minutos * 60.0) if minutos > 0 else 0.0
	aplicar()


func _process(delta: float) -> void:
	if horas_por_segundo == 0.0:
		return
	hora = minf(hora + horas_por_segundo * delta, hora_fin)
	_espera -= delta
	if _espera <= 0:
		_espera = 0.25
		aplicar()


func _momento(h: float) -> Array:
	h = fposmod(h, 24.0)
	for i in MOMENTOS.size() - 1:
		var a: Array = MOMENTOS[i]
		var b: Array = MOMENTOS[i + 1]
		if h >= a[0] and h <= b[0]:
			var t: float = (h - float(a[0])) / maxf(float(b[0]) - float(a[0]), 0.001)
			var r := [h]
			for k in range(1, a.size()):
				if a[k] is String:
					r.append(Color(a[k]).lerp(Color(b[k]), t))
				else:
					r.append(lerpf(a[k], b[k], t))
			return r
	return MOMENTOS[0]


func aplicar() -> void:
	var m := _momento(hora)
	var de_dia := hora >= 5.5 and hora <= 18.8
	# el sol sale por el este (6 h), cruza alto al mediodía y se pone por el oeste (18 h); de noche, la luna
	var fase := (hora - 6.0) / 12.0 if de_dia else fposmod(hora - 18.0, 24.0) / 12.0
	var elevacion := maxf(sin(clampf(fase, 0.0, 1.0) * PI) * (68.0 if de_dia else 55.0), 6.0)
	sol.rotation_degrees = Vector3(-elevacion, 90.0 - fase * 180.0, 0)
	sol.light_color = m[3]
	sol.light_energy = m[4]
	env.ambient_light_color = m[5]
	env.ambient_light_energy = m[6]
	env.fog_light_color = m[7]
	cielo.set_shader_parameter("arriba", m[1])
	cielo.set_shader_parameter("horizonte", m[2])
	cielo.set_shader_parameter("suelo", (m[2] as Color).darkened(0.6))
	cielo.set_shader_parameter("dir_astro", sol.global_basis.z)
	cielo.set_shader_parameter("color_astro", Color("fff4d6") if de_dia else Color("e8eeff"))
	cielo.set_shader_parameter("es_luna", 0.0 if de_dia else 1.0)
	cielo.set_shader_parameter("tam_astro", 0.05 if de_dia else 0.035)
	cielo.set_shader_parameter("color_nube", m[8])
	cielo.set_shader_parameter("sombra_nube", m[9])
	cielo.set_shader_parameter("estrellas", m[10])
	for mat in lejanos:
		mat.albedo_color = Color(m[11], m[11], m[11])
