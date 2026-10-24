extends Node
## Mide si algún personaje o animal camina mirando hacia atrás (frente = -Z del modelo).

var main: Node
var malos := 0


func _ready() -> void:
	Juego.nueva_partida(false)
	main = load("res://escenas/main.tscn").instantiate()
	add_child(main)
	await get_tree().create_timer(0.5).timeout
	for i in Juego.CAPITULOS.size():
		Juego.flags["intro_vista_%d" % i] = true
	for i in Juego.CAPITULOS.size():
		main.iniciar_capitulo(i)
		await get_tree().create_timer(0.5).timeout
		main.jugador.global_position = main.nivel.inicio + Vector3(0, 0.2, 0)
		var antes := {}
		for k in 40:
			for n in _caminantes():
				var modelo: Node3D = n[1]
				var pos: Vector3 = modelo.global_position
				if antes.has(modelo):
					var mov: Vector3 = pos - antes[modelo]
					mov.y = 0
					if mov.length() > 0.02:
						var frente := -modelo.global_basis.z
						frente.y = 0
						var d := frente.normalized().dot(mov.normalized())
						if d < -0.3:
							malos += 1
							if malos < 15:
								print("  ATRÁS cap %d: %s (frente·movimiento = %.2f)" % [i, n[0], d])
				antes[modelo] = pos
			await get_tree().create_timer(0.1).timeout
	print("CAMINAR: %d muestras hacia atrás" % malos)
	get_tree().quit()


func _caminantes() -> Array:
	var r := []
	for e in main.nivel.entidades:
		if is_instance_valid(e) and e.personaje:
			r.append([String(e.def.get("nombre", "?")), e.personaje])
	for o in main.nivel.find_children("*", "Oveja", true, false):
		r.append(["animal " + o.especie, o])
	return r
