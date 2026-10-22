extends Node
## Prueba automática: juega los tres capítulos de principio a fin.
## Uso: godot --headless --path . res://pruebas/recorrido.tscn

var main: Node
var fallos := 0


func _ready() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Juego.RUTA_PARTIDA))
	main = load("res://escenas/main.tscn").instantiate()
	add_child(main)
	await _frames(5)
	Juego.nueva_partida(false)
	main.iniciar_capitulo(0)
	await _esperar(2.5)
	await _dialogos()

	# --- capítulo 1
	await _usar(_npc("Simeón"))
	_ok(Juego.cumple("flag:hablo_simeon"), "habló con Simeón")
	await _usar(_tipo("letrero"))
	await _usar(_lampara("esperanza"))  # orden equivocado a propósito
	_ok(not Juego.cumple("flag:lamparas_ok"), "el orden equivocado no resuelve")
	for s in ["fe", "esperanza", "amor"]:
		await _usar(_lampara(s))
	_ok(Juego.cumple("flag:lamparas_ok"), "lámparas de la plaza encendidas")
	await _usar(_npc("Marta"))
	await _usar(_npc("Lía"))
	await _usar(_npc("Marta"))
	_ok(Juego.cumple("flag:pan_resuelto"), "historia del pan resuelta")
	await _usar(_npc("Tomás"))
	await _usar(_tipo("objeto"))
	_ok(Juego.objetos.has("hilo1"), "secreto del hilo encontrado")
	await _salir()

	# --- capítulo 2
	_ok(Juego.capitulo == 1, "pasó al capítulo 2")
	await _usar(_npc("Noemí"))
	await _usar(_npc("Abuela Ana"))
	await _usar(_tipo("objeto"))
	await _usar(_npc("Jared"))
	_ok(Juego.contadores.get("piezas", 0) == 3, "tres piedras del brocal")
	await _usar(_tipo("mecanismo"))
	_ok(Juego.cumple("flag:pozo_reparado"), "pozo reparado")
	await _salir()

	# --- capítulo 3
	_ok(Juego.capitulo == 2, "pasó al capítulo 3")
	await _usar(_lampara("fe"))
	_ok(not Juego.cumple("flag:lamparas_peniel"), "las lámparas no prenden sin hablar con Asaf")
	await _usar(_npc("Asaf"))
	await _usar(_tipo("letrero"))
	for s in ["perdon", "amor", "esperanza", "fe"]:
		await _usar(_lampara(s))
	_ok(Juego.cumple("flag:lamparas_peniel"), "lámparas de Peniel encendidas")
	await _usar(_tipo("objeto"))
	await _usar(_tipo("salida"))
	await _dialogos()
	await _frames(3)
	var b := _boton_menu("Ver el final")
	_ok(b != null, "aparece el botón del final")
	if b:
		b.pressed.emit()
		await _dialogos()
	_ok(_boton_menu("Volver al inicio") != null, "pantalla de fin")
	print("VIRTUDES: ", Juego.virtudes, "  LUZ: ", Juego.luz, "  SECRETOS: ", Juego.secretos)
	print("RESULTADO: ", "TODO BIEN" if fallos == 0 else "%d FALLOS" % fallos)
	get_tree().quit(fallos)


func _ok(cond: bool, que: String) -> void:
	print(("  ✔ " if cond else "  ✘ ") + que)
	if not cond:
		fallos += 1


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _esperar(s: float) -> void:
	await get_tree().create_timer(s).timeout


func _dialogos() -> void:
	var d: CajaDialogo = main.dialogo
	var vueltas := 0
	while d.visible and vueltas < 400:
		vueltas += 1
		var botones := d._opciones.get_children().filter(func(b): return not b.is_queued_for_deletion())
		if botones.size() > 0:
			botones[0].pressed.emit()
		else:
			d.avanzar()
		await _frames(2)


func _entidades() -> Array:
	return main.nivel.entidades.filter(func(e): return is_instance_valid(e))


func _npc(nombre: String) -> Entidad:
	for e in _entidades():
		if e.tipo == "npc" and e.def.get("nombre", "") == nombre:
			return e
	_ok(false, "existe " + nombre)
	return null


func _tipo(t: String) -> Entidad:
	for e in _entidades():
		if e.tipo == t and e.is_in_group("interactuable"):
			return e
	_ok(false, "existe entidad " + t)
	return null


func _lampara(simbolo: String) -> Entidad:
	for e in _entidades():
		if e.tipo == "lampara" and e.def.get("simbolo", "") == simbolo:
			return e
	return null


func _usar(e: Entidad) -> void:
	if e == null:
		return
	main.jugador.global_position = e.global_position + Vector3(1.2, 0.2, 0)
	await _frames(3)
	e.interactuar(main)
	await _frames(2)
	await _dialogos()


func _salir() -> void:
	await _usar(_tipo("salida"))
	await _dialogos()
	await _frames(3)
	var b := _boton_menu("Seguir el camino")
	_ok(b != null, "resumen del capítulo")
	if b:
		b.pressed.emit()
		await _esperar(2.6)
		await _dialogos()


func _boton_menu(texto: String) -> Button:
	for b in main.capa_menu.find_children("*", "Button", true, false):
		if b.text == texto and not b.is_queued_for_deletion():
			return b
	return null
