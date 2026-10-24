extends Node
## Prueba automática: recorre los seis capítulos en orden.
## Uso: godot --headless --path . res://pruebas/recorrido.tscn

var main: Node
var fallos := 0


func _ready() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Juego.RUTA_PARTIDA))
	main = load("res://escenas/main.tscn").instantiate()
	add_child(main)
	await _frames(5)
	var legado := ConfigFile.new()
	legado.set_value("partida", "version", 1)
	legado.set_value("partida", "capitulo", 2)
	legado.set_value("partida", "capitulo_max", 4)
	legado.set_value("partida", "completados", [0, 4])
	legado.set_value("partida", "estrellas", {"0": 2, "4": 3})
	legado.set_value("partida", "registro", {"0": {"flags": []}, "4": {"flags": []}})
	legado.set_value("partida", "flags", {"intro_vista_0": true, "intro_vista_4": true, "otro": true})
	legado.save(Juego.RUTA_PARTIDA)
	_ok(Juego.cargar_partida(), "se carga partida versión 1")
	_ok(Juego.capitulo == 3 and Juego.capitulo_max == 5, "la migración desplaza capítulo actual y máximo")
	_ok(Juego.completados == [1, 5] and Juego.estrellas.has("1") and Juego.registro.has("5"), "la migración conserva progreso, estrellas y registros")
	_ok(Juego.flags.has("intro_vista_1") and Juego.flags.has("intro_vista_5") and Juego.flags.has("otro"), "la migración desplaza las introducciones y conserva otras marcas")
	Juego.nueva_partida(false)
	Juego.leer_voz = true  # recorre todo leyendo en voz alta con la narración grabada
	main.iniciar_capitulo(0)
	await _esperar(2.5)
	_ok(main.dialogo.visible and Sonido._voz.playing, "la introducción se lee con la voz grabada")
	await _dialogos()

	# --- 0. Noé (Génesis 6–9)
	var con_noe: Construccion = main.nivel.construccion
	_ok(con_noe.bloques.size() > 150, "el arca carga sus bloques estructurales fijos")
	_ok(con_noe.planos.has("costado") and con_noe.planos.has("aposentos") and con_noe.planos.has("brea"), "el arca presenta los tres planos")
	await _esperar(0.6)
	_ok(main.hud._mision.modulate.a > 0.5 and main.hud._mision_texto.text.contains("Picar"), "la tarjeta de misión explica cómo construir")
	_ok(main.hud._objetivo.text.contains("Pica los troncos"), "sin madera, el objetivo dice de dónde sacarla")
	_ok(main.faro.visible and con_noe.bloques.get(Vector3i(main.faro.global_position.floor()), {}).get("material", "") == "tronco",
		"el faro señala un tronco para picar")
	await _construir("costado", 3)
	await _esperar(0.6)
	var hacia: Variant = con_noe.celda_que_falta("costado", main.jugador.global_position)
	_ok(main.faro.visible and hacia != null and main.faro.global_position.distance_to(Vector3(hacia) + Vector3(0.5, 0, 0.5)) < 0.1,
		"con madera, el faro señala el próximo bloque de la silueta")
	await _construir("costado")
	await _construir("aposentos")
	await _construir("brea")
	_ok(Juego.cumple("flag:arca_lista"), "la brea termina el arca")
	await _objetos()
	_ok(Juego.contadores.get("alimento", 0) == 4, "se reúnen cuatro raciones")
	var parejas_noe: Array[Entidad] = []
	for _i in 4:
		var pareja := _tipo("pareja")
		parejas_noe.append(pareja)
		await _usar(pareja)
	_ok(Juego.contadores.get("parejas", 0) == 4, "las cuatro parejas se reciben")
	await _esperar(8.0)
	var desaparecieron := true
	for pareja_noe in parejas_noe:
		if is_instance_valid(pareja_noe):
			desaparecieron = false
			for animal_noe in pareja_noe.animales:
				if is_instance_valid(animal_noe):
					print("DEBUG pareja: ", pareja_noe.def.get("id"), " pos ", animal_noe.global_position, " destino ", pareja_noe.def.get("destino"))
	_ok(desaparecieron, "las parejas llegan a la puerta y desaparecen")
	await _usar(_tipo("salida"))
	_ok(main.nivel._arcoiris.visible and not main.nivel._agua_diluvio.visible and not main.nivel._lluvia.emitting,
		"el epílogo despeja el cielo, baja el agua y muestra el arcoíris")
	await _seguir()

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
	_ok(Juego.capitulo == 2, "pasó a Rut")
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
	_ok(Juego.capitulo == 3, "pasó a David")
	await _usar(_npc("Goliat"))
	_ok(not Juego.fin_pedido and Juego.capitulo == 3, "Goliat solo desafía si no estás listo")
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
	_ok(Juego.capitulo == 4, "pasó a Nehemías")
	await _usar(_tipo("letrero"))
	await _usar(_lampara("dragon"))  # orden equivocado a propósito
	_ok(not Juego.cumple("flag:inspeccion_ok"), "la ruta empieza en la puerta del Valle")
	for s in ["valle", "dragon", "muladar", "fuente", "estanque"]:
		await _usar(_lampara(s))
	_ok(Juego.cumple("flag:inspeccion_ok"), "inspección nocturna (Neh 2:13-15)")
	var con: Construccion = main.nivel.construccion
	var primera: Vector3i = con.planos["tramo_norte"]["celdas"].keys()[0]
	_ok(con.motivo_para_no_poner(primera, "piedra") != "", "no se construye antes de reunir al pueblo")
	await _usar(_npc("Eliasib"))
	await _usar(_obra("tramo_este"))
	_ok(not Juego.cumple("flag:tramo_este"), "sin guardia los obreros tienen miedo")
	await _construir("tramo_norte")
	_ok(Juego.cumple("flag:tramo_norte"), "tramo norte levantado con bloques")
	var fijo: Vector3i = con.planos["tramo_norte"]["celdas"].keys()[0]
	_ok(not con.se_puede_picar(fijo), "lo construido para la historia no se pica")
	await _usar(_npc("Sanbalat"))
	await _usar(_npc("Obrero"))
	await _construir("tramo_este")
	await _construir("tramo_oeste")
	_ok(Juego.contadores.get("tramos", 0) == 3, "muro reparado")
	await _usar(_npc("Salum"))
	await _objetos()
	await _usar(_tipo("salida"))
	await _seguir()

	# --- 5. Emaús (Lucas 24)
	_ok(Juego.capitulo == 5, "pasó a Emaús")
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
	_ok(Juego.secretos == 6, "los seis secretos encontrados")

	# --- rejugar un capítulo desde «Capítulos» no duplica virtudes ni secretos
	var antes := Juego.virtudes.duplicate()
	main.mostrar_titulo()
	await _frames(3)
	main.jugar_capitulo(3)
	await _esperar(2.6)
	await _dialogos()
	_ok(not Juego.cumple("flag:saul_bendice") and Juego.contadores.get("piedras", 0) == 0, "David empieza de nuevo tras insertar a Noé")
	_ok(Juego.secretos == 5, "el secreto de David vuelve a estar escondido")
	await _usar(_npc("Soldado de Israel"))
	await _usar(_npc("Saúl"))
	await _objetos()
	await _usar(_npc("Goliat"))
	await _honda()
	await _dialogos()
	await _frames(3)
	await _repaso()
	_ok(Juego.virtudes["fe"] <= antes["fe"] + 1 and Juego.secretos == 6, "rejugar no infla las virtudes")
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


func _obra(flag: String) -> Entidad:
	for e in _entidades():
		if e.tipo == "obra" and e.def.get("flag_activo", "") == flag:
			return e
	return null


## Llena un plano como lo haría el jugador: pica montones para sacar material y lo pone en la silueta.
func _construir(id: String, maximo := 999) -> void:
	var con: Construccion = main.nivel.construccion
	con.actualizar_planos()
	_ok(con.planos[id]["activo"], "el plano %s está activo" % id)
	var celdas: Dictionary = con.planos[id]["celdas"]
	var cualquiera: Vector3i = celdas.keys()[0]
	# el jugador se aparta para no estorbar donde van los bloques
	main.jugador.global_position = Vector3(cualquiera) + Vector3(4, 0.2, 4)
	await _frames(2)
	var puestos := 0
	for c in celdas:
		if con.bloques.has(c):
			continue
		if puestos >= maximo:  # deja material en la mano para probar el faro
			while Juego.cantidad_bloque(celdas[c]) == 0:
				main.picar_en(con.fuente_de(celdas[c], main.jugador.global_position))
			return
		puestos += 1
		var material: String = celdas[c]
		while Juego.cantidad_bloque(material) == 0:
			var fuente = null
			for b in con.bloques:
				if con.se_puede_picar(b) and con.recurso_de(con.bloques[b]["material"]) == material and con.plano_de(b) == "":
					fuente = b
					break
			if fuente == null:
				_ok(false, "hay %s para picar" % material)
				return
			main.picar_en(fuente)
		var motivo := con.motivo_para_no_poner(c, material)
		if motivo != "":
			_ok(false, "se puede poner en %s: %s" % [c, motivo])
			return
		main.poner_en(c, material)
	await _frames(3)
	await _dialogos()


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
