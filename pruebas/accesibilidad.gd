extends Node
## Audita acceso físico a entidades/planos y límites en los seis capítulos.
## Complementa recorrido.gd, que prueba las condiciones y minijuegos completos.
var fallos := 0
var main: Node
var espacio: PhysicsDirectSpaceState3D
var capsula := CapsuleShape3D.new()
var exclusion: Array[RID] = []

func comprobar(si: bool, texto: String) -> void:
	if not si:
		fallos += 1
	print("  ", "✔ " if si else "✘ ", texto)

func _ready() -> void:
	capsula.radius = 0.35
	capsula.height = 1.6
	Juego.nueva_partida(false)
	for i in Juego.CAPITULOS.size():
		Juego.flags["intro_vista_%d" % i] = true
	main = load("res://escenas/main.tscn").instantiate()
	add_child(main)
	await get_tree().process_frame
	for i in Juego.CAPITULOS.size():
		main.iniciar_capitulo(i)
		main.jugador.bloqueado = true
		await get_tree().physics_frame
		await get_tree().physics_frame
		espacio = main.jugador.get_world_3d().direct_space_state
		exclusion = [main.jugador.get_rid()]
		_limites(i)
		var accesibles := _rutas()
		_objetivos(accesibles, i, "inicial")
		var con: Construccion = main.nivel.construccion
		if not con.planos.is_empty():
			for plano in con.planos.values():
				for celda in plano["celdas"]:
					con.poner(celda, plano["celdas"][celda], false, false)
			for material in Construccion.MATERIALES:
				con._reconstruir(material)
			await get_tree().physics_frame
			await get_tree().physics_frame
			_objetivos(_rutas(), i, "construido")
	print("ACCESIBILIDAD: %d fallos" % fallos)
	get_tree().quit(fallos)

func _consulta(p: Vector3) -> PhysicsShapeQueryParameters3D:
	var q := PhysicsShapeQueryParameters3D.new()
	q.shape = capsula
	q.transform.origin = p + Vector3(0, 0.83, 0)
	q.exclude = exclusion
	return q

func _paso(a: Vector3, b: Vector3) -> bool:
	if b.y - a.y > 1.2 or a.y - b.y > 2.0:
		return false
	var arriba := maxf(a.y, b.y)
	var elevado := Vector3(a.x, arriba, a.z)
	var q := _consulta(a)
	q.motion = elevado - a
	if q.motion.length() > 0.01 and espacio.cast_motion(q)[0] < 0.99:
		return false
	q = _consulta(elevado)
	q.motion = Vector3(b.x, arriba, b.z) - elevado
	return espacio.cast_motion(q)[0] >= 0.99

func _rutas() -> Array[Vector3]:
	var superficies := {}
	var nivel: Nivel = main.nivel
	for z in nivel.alto * 2:
		for x in nivel.ancho * 2:
			var lista: Array[Vector3] = []
			var vistos := {}
			for altura in range(10, 0, -1):
				var origen := Vector3(x + 0.5, altura - 0.1, z + 0.5)
				var r := PhysicsRayQueryParameters3D.create(origen, Vector3(origen.x, -0.2, origen.z))
				r.exclude = exclusion
				var hit := espacio.intersect_ray(r)
				if hit.is_empty() or hit.normal.y < 0.7:
					continue
				var p: Vector3 = hit.position
				var clave := roundi(p.y * 100)
				if vistos.has(clave):
					continue
				vistos[clave] = true
				if espacio.intersect_shape(_consulta(p), 1).is_empty():
					lista.append(p)
			superficies[Vector2i(x, z)] = lista
	var cola: Array[Vector3] = []
	var visitados := {}
	var mejor := INF
	var inicio := Vector3.ZERO
	for lista in superficies.values():
		for p in lista:
			var distancia: float = p.distance_to(nivel.inicio)
			if distancia < mejor:
				mejor = distancia
				inicio = p
	cola.append(inicio)
	visitados[inicio] = true
	var indice := 0
	while indice < cola.size():
		var a := cola[indice]
		indice += 1
		for dir in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var celda: Vector2i = Vector2i(floori(a.x), floori(a.z)) + dir
			for b in superficies.get(celda, []):
				if not visitados.has(b) and _paso(a, b):
					visitados[b] = true
					cola.append(b)
	return cola

func _cerca(rutas: Array[Vector3], destino: Vector3, alcance: float) -> bool:
	for p in rutas:
		if p.distance_to(destino) <= alcance:
			return true
	return false

func _objetivos(rutas: Array[Vector3], cap: int, fase: String) -> void:
	comprobar(rutas.size() > 20, "cap %d %s: zona inicial conectada" % [cap, fase])
	for e in main.nivel.entidades:
		if is_instance_valid(e):
			comprobar(_cerca(rutas, e.global_position, 2.5), "cap %d %s: acceso a %s" % [cap, fase, e.def.get("id", e.letra)])
	for id in main.nivel.construccion.planos:
		var plano: Dictionary = main.nivel.construccion.planos[id]
		var todos := true
		for celda in plano["celdas"]:
			if not _cerca(rutas, Vector3(celda) + Vector3(0.5, 0, 0.5), 4.0):
				todos = false
		comprobar(todos, "cap %d %s: alcance del plano %s" % [cap, fase, id])

func _limites(cap: int) -> void:
	var n: Nivel = main.nivel
	for altura in [0.5, 4.5, 16.0]:
		var puntos := [Vector3(0.5, altura, n.alto), Vector3(n.ancho * 2 - 0.5, altura, n.alto), Vector3(n.ancho, altura, 0.5), Vector3(n.ancho, altura, n.alto * 2 - 0.5)]
		var direcciones := [Vector3.LEFT, Vector3.RIGHT, Vector3.FORWARD, Vector3.BACK]
		for k in 4:
			var q := _consulta(puntos[k])
			q.motion = direcciones[k] * 2.0
			comprobar(espacio.cast_motion(q)[0] < 0.5, "cap %d: límite %d a altura %.1f" % [cap, k, altura])
