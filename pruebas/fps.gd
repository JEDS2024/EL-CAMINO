extends Node
## Mide los cuadros por segundo en cada capítulo (necesita ventana).

func _ready() -> void:
	Juego.nueva_partida(false)
	for i in 5:
		Juego.flags["intro_vista_%d" % i] = true
	var main = load("res://escenas/main.tscn").instantiate()
	add_child(main)
	await get_tree().create_timer(1.0).timeout
	for cap in Juego.CAPITULOS.size():
		main.iniciar_capitulo(cap)
		await get_tree().create_timer(1.5).timeout
		var cuadros := 0
		var t0 := Time.get_ticks_msec()
		while Time.get_ticks_msec() - t0 < 3000:
			main.jugador.yaw += 0.01
			await get_tree().process_frame
			cuadros += 1
		print("capitulo %d: %.1f fps" % [cap + 1, cuadros / 3.0])
	get_tree().quit()
