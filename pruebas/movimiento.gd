extends Node
## Prueba física: cruzar el umbral del arca, agacharse y no levantarse bajo un techo.
var fallos := 0

func comprobar(condicion: bool, mensaje: String) -> void:
	if not condicion:
		fallos += 1
	print("  ", "✔ " if condicion else "✘ ", mensaje)

func _ready() -> void:
	Juego.nueva_partida(false)
	Juego.flags["intro_vista_0"] = true
	var main: Node = load("res://escenas/main.tscn").instantiate()
	add_child(main)
	await get_tree().process_frame
	main.iniciar_capitulo(0)
	var j: Jugador = main.jugador
	j.bloqueado = false
	j.global_position = Vector3(30.5, 0.05, 26.5)
	j.yaw = 0
	await get_tree().create_timer(0.3).timeout
	j.entrada_tactil = Vector2(0, -1)
	await get_tree().create_timer(0.15).timeout
	j.pedir_salto()
	var maximo := 0.0
	for i in 80:
		await get_tree().physics_frame
		maximo = maxf(maximo, j.position.y)
		if j.position.z < 23.4:
			j.entrada_tactil = Vector2.ZERO
	j.entrada_tactil = Vector2.ZERO
	comprobar(maximo > 1.0, "el salto supera el umbral de un bloque")
	comprobar(j.position.z < 24.0 and j.position.y > 0.9, "entra físicamente por la puerta del arca")
	j.agachado_tactil = true
	await get_tree().physics_frame
	await get_tree().physics_frame
	comprobar(j.agachado and j._forma.shape.height == 1.0, "agacharse reduce la colisión")
	var techo := StaticBody3D.new()
	var forma := CollisionShape3D.new()
	var caja := BoxShape3D.new()
	caja.size = Vector3(2, 0.2, 2)
	forma.shape = caja
	techo.add_child(forma)
	main.nivel.add_child(techo)
	techo.global_position = j.global_position + Vector3(0, 1.3, 0)
	await get_tree().physics_frame
	j.agachado_tactil = false
	await get_tree().physics_frame
	await get_tree().physics_frame
	comprobar(j.agachado, "no se levanta atravesando un techo")
	techo.queue_free()
	await get_tree().physics_frame
	await get_tree().physics_frame
	comprobar(not j.agachado, "vuelve a levantarse con espacio libre")
	print("MOVIMIENTO: %d fallos" % fallos)
	get_tree().quit(fallos)
