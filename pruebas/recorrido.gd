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

	# --- 1. José (Génesis 43–45)
	await _usar(_lampara("ruben"))
	_ok(not _lampara("ruben").encendida, "los asientos esperan a que hables con el mayordomo")
	await _usar(_npc("Mayordomo"))
	await _usar(_tipo("letrero"))
	await _usar(_lampara("benjamin"))  # orden equivocado a propósito
	_ok(not Juego.cumple("flag:mesa_ok"), "sentar al menor primero no resuelve")
	for s in ["ruben", "simeon", "levi", "juda", "benjamin"]:
		await _usar(_lampara(s))
	_ok(Juego.cumple("flag:mesa_ok"), "hermanos sentados por edad (Gén 43:33)")
	await _usar(_npc("Benjamín"))
	await _usar(_npc("Mayordomo"))
	_ok(Juego.cumple("flag:copa_hallada"), "la copa aparece en el costal de Benjamín")
	await _usar(_npc("Judá"))
	_ok(Juego.cumple("flag:perdon_revelado"), "José se da a conocer y perdona")
	await _objetos()
	await _usar(_tipo("salida"))
	await _seguir()

	# --- 2. Rut (Rut 1–2)
	_ok(Juego.capitulo == 1, "pasó a Rut")
	await _usar(_npc("Noemí"))
	await _usar(_npc("Criado de los segadores"))
	await _esperar(0.5)
	_ok(_npc("Booz").activo, "Booz llega al campo")
	await _usar(_npc("Booz"))
	await _esperar(0.5)
	await _objetos()
	_ok(Juego.contadores.get("espigas", 0) >= 6, "espigas recogidas")
	await _usar(_tipo("mecanismo"))
	_ok(Juego.cumple("flag:efa"), "un efa de cebada (Rut 2:17)")
	await _usar(_npc("Noemí"))
	await _seguir()

	# --- 3. David (1 Samuel 17)
	_ok(Juego.capitulo == 2, "pasó a David")
	await _usar(_npc("Goliat"))
	_ok(not Juego.fin_pedido and Juego.capitulo == 2, "Goliat solo desafía si no estás listo")
	await _usar(_npc("Soldado de Israel"))
	await _usar(_npc("Eliab"))
	await _usar(_npc("Saúl"))
	_ok(Juego.cumple("flag:saul_bendice"), "Saúl: «Ve, y Jehová sea contigo»")
	await _objetos()
	_ok(Juego.contadores.get("piedras", 0) == 5, "cinco piedras lisas (17:40)")
	await _usar(_npc("Goliat"))
	await _honda()
	await _seguir()

	# --- 4. Nehemías (Nehemías 2–6)
	_ok(Juego.capitulo == 3, "pasó a Nehemías")
	await _usar(_tipo("letrero"))
	await _usar(_lampara("dragon"))  # orden equivocado a propósito
	_ok(not Juego.cumple("flag:inspeccion_ok"), "la ruta empieza en la puerta del Valle")
	for s in ["valle", "dragon", "muladar", "fuente", "estanque"]:
		await _usar(_lampara(s))
	_ok(Juego.cumple("flag:inspeccion_ok"), "inspección nocturna (Neh 2:13-15)")
	await _usar(_npc("Eliasib"))
	await _usar(_mecanismo("tramo_este"))
	_ok(not Juego.cumple("flag:tramo_este"), "sin guardia los obreros tienen miedo")
	await _usar(_mecanismo("tramo_norte"))
	await _usar(_npc("Sanbalat"))
	await _usar(_npc("Obrero"))
	await _usar(_mecanismo("tramo_este"))
	await _usar(_mecanismo("tramo_oeste"))
	_ok(Juego.contadores.get("tramos", 0) == 3, "muro reparado")
	await _usar(_npc("Salum"))
	await _objetos()
	await _usar(_tipo("salida"))
	await _seguir()

	# --- 5. Emaús (Lucas 24)
	_ok(Juego.capitulo == 4, "pasó a Emaús")
	await _usar(_lampara("genesis"))
	_ok(not _lampara("genesis").encendida, "las Escrituras esperan al forastero")
	await _usar(_npc("Forastero"))
	await _usar(_lampara("isaias"))  # orden equivocado a propósito
	_ok(not Juego.cumple("flag:escrituras_ok"), "comenzando desde Moisés")
	for s in ["genesis", "deuteronomio", "isaias", "zacarias"]:
		await _usar(_lampara(s))
	_ok(Juego.cumple("flag:escrituras_ok"), "Escrituras en orden (Lc 24:27)")
	await _objetos()
	await _usar(_tipo("salida"))
	await _dialogos()
	await _frames(3)
	await _repaso()
	var b := _boton_menu("Ver el final")
	_ok(b != null, "aparece el botón del final")
	if b:
		b.pressed.emit()
		await _dialogos()
	_ok(_boton_menu("Volver al inicio") != null, "pantalla de fin")
	_ok(Juego.secretos == 5, "los 5 secretos encontrados")

	# --- rejugar un capítulo desde «Capítulos» no duplica virtudes ni secretos
	var antes := Juego.virtudes.duplicate()
	main.mostrar_titulo()
	await _frames(3)
	main.jugar_capitulo(2)
	await _esperar(2.6)
	await _dialogos()
	_ok(not Juego.cumple("flag:saul_bendice") and Juego.contadores.get("piedras", 0) == 0, "David empieza de nuevo")
	_ok(Juego.secretos == 4, "su secreto vuelve a estar escondido")
	await _usar(_npc("Soldado de Israel"))
	await _usar(_npc("Saúl"))
	await _objetos()
	await _usar(_npc("Goliat"))
	await _honda()
	await _dialogos()
	await _frames(3)
	await _repaso()
	_ok(Juego.virtudes["fe"] <= antes["fe"] + 1 and Juego.secretos == 5, "rejugar no infla las virtudes")
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


## Minijuego de la honda: un intento fallido y luego uno bueno.
func _honda() -> void:
	await _frames(3)
	var juegos: Array = main.capa_menu.find_children("*", "MinijuegoHonda", true, false)
	_ok(juegos.size() == 1, "aparece el minijuego de la honda")
	if juegos.is_empty():
		return
	var mj: MinijuegoHonda = juegos[0]
	mj.resolver(false)
	await _esperar(1.0)
	_ok(not Juego.fin_pedido and mj.is_inside_tree(), "fallar permite intentar otra vez")
	mj.resolver(true)
	await _esperar(1.3)
	await _dialogos()


func _objetos() -> void:
	for e in _entidades():
		if e.tipo == "objeto" and e.activo and e.is_in_group("interactuable"):
			await _usar(e)


func _mecanismo(flag: String) -> Entidad:
	for e in _entidades():
		if e.tipo == "mecanismo" and e.def.get("flag_activo", "") == flag:
			return e
	return null


## Pantalla del versículo y las tres preguntas: responde bien todas.
func _repaso() -> void:
	var b := _boton_menu("Responder preguntas")
	_ok(b != null, "versículo para recordar")
	if b == null:
		return
	var cap := Juego.capitulo
	b.pressed.emit()
	await _frames(3)
	for p in main.datos_cap.get("repaso", {}).get("preguntas", []):
		var correcta: Button = _boton_menu(p["opciones"][int(p["correcta"])])
		correcta.pressed.emit()
		await _frames(2)
		_boton_menu("Siguiente").pressed.emit()
		await _frames(3)
	_ok(int(Juego.estrellas.get(str(cap), 0)) == 3, "tres estrellas en el repaso")


func _seguir() -> void:
	await _dialogos()
	await _frames(3)
	await _repaso()
	var b := _boton_menu("Seguir el camino")
	_ok(b != null, "resumen del capítulo")
	if b:
		b.pressed.emit()
		await _frames(3)
		b = _boton_menu("Comenzar")
		_ok(b != null, "mapa del camino")
		b.pressed.emit()
		await _esperar(2.6)
		await _dialogos()


func _boton_menu(texto: String) -> Button:
	for b in main.capa_menu.find_children("*", "Button", true, false):
		if b.text == texto and not b.is_queued_for_deletion():
			return b
	return null
