extends Node
## Punto de entrada: crea la vista 3D pixelada, la interfaz y maneja el flujo del juego
## (título → elegir cámara → capítulos → final).

const ESCALA_PIXEL := 2  # la escena 3D se dibuja a 1/2 de la resolución y se agranda sin suavizar
const DISTANCIA_INTERACCION := 2.6

var vista: SubViewport
var ui: CanvasLayer
var hud: Hud
var dialogo: CajaDialogo
var tactil: ControlesTactiles
var capa_menu: Control

var nivel: Nivel
var jugador: Jugador
var datos_cap: Dictionary = {}
var en_juego := false
var en_titulo := false
var _objetivo_entidad: Entidad
var _reloj := 0.0
var faro: Faro
var hablando_con := ""  # nombre de quien dice la línea actual del diálogo
var _mision_actual := {}  # objetivo vigente (para la tarjeta de ayuda)
var _apunte := {}  # bloque al que apunta la mira (capítulos con construcción)
var _espera_bloque := 0.0
var _volver_ajustes: Callable


func _ready() -> void:
	get_tree().quit_on_go_back = false
	_crear_vista()
	_crear_ui()
	Actualizador.antes_de_instalar.connect(func():
		if not en_titulo:
			Juego.guardar_partida())
	Juego.aviso.connect(hud.mostrar_aviso)
	Juego.aviso.connect(_sonido_aviso)
	mostrar_titulo()


# ------------------------------------------------------------------ construcción
func _crear_vista() -> void:
	var cont := SubViewportContainer.new()
	cont.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cont.stretch = true
	cont.stretch_shrink = ESCALA_PIXEL
	cont.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	cont.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(cont)
	vista = SubViewport.new()
	vista.own_world_3d = true
	vista.handle_input_locally = false
	cont.add_child(vista)


func _crear_ui() -> void:
	ui = CanvasLayer.new()
	ui.layer = 1
	add_child(ui)
	var raiz := Control.new()
	raiz.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	raiz.mouse_filter = Control.MOUSE_FILTER_IGNORE
	raiz.theme = Tema.crear()
	ui.add_child(raiz)

	tactil = ControlesTactiles.new()
	raiz.add_child(tactil)
	tactil.mover.connect(_mover_tactil)
	tactil.mirar.connect(_mirar_tactil)

	hud = Hud.new()
	raiz.add_child(hud)
	hud.pedir_interactuar.connect(_interactuar)
	hud.pedir_vista.connect(_cambiar_vista)
	hud.pedir_pausa.connect(_mostrar_pausa)
	hud.pedir_mochila.connect(_mostrar_mochila)
	hud.pedir_ayuda.connect(func(): _explicar_mision(_mision_actual, false))
	hud.pedir_salto.connect(func():
		if jugador:
			jugador.pedir_salto())
	hud.cambiar_agachado.connect(func(valor: bool):
		if jugador:
			jugador.agachado_tactil = valor)
	hud.pedir_picar.connect(_picar)
	hud.pedir_poner.connect(_poner)
	hud.elegir_casilla.connect(_elegir_casilla)
	tactil.excluir = [hud.boton_accion, hud.boton_vista, hud.boton_pausa, hud.boton_mochila, hud.boton_ayuda, hud.boton_picar,
		hud.boton_poner, hud.boton_salto, hud.boton_agachar, hud.barra]

	tactil.acciones_tactiles[hud.boton_salto] = func(): hud.pedir_salto.emit()
	tactil.acciones_tactiles[hud.boton_agachar] = func():
		hud.boton_agachar.button_pressed = not hud.boton_agachar.button_pressed
	if DisplayServer.is_touchscreen_available():
		for boton in [hud.boton_salto, hud.boton_agachar]:
			boton.mouse_filter = Control.MOUSE_FILTER_IGNORE

	dialogo = CajaDialogo.new()
	raiz.add_child(dialogo)
	dialogo.resolver = func(id): return datos_cap.get("dialogos", {}).get(id, [])
	dialogo.linea_mostrada.connect(func(quien: String):
		hablando_con = quien
		if jugador:
			jugador.modelo.hablando = quien != "" and quien == String(datos_cap.get("protagonista", {}).get("nombre", "")))

	capa_menu = Control.new()
	capa_menu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	capa_menu.mouse_filter = Control.MOUSE_FILTER_IGNORE
	raiz.add_child(capa_menu)
	_modo_juego(false)


func _mover_tactil(v: Vector2) -> void:
	if jugador:
		jugador.entrada_tactil = v


func _mirar_tactil(d: Vector2) -> void:
	if jugador and not jugador.bloqueado:
		jugador.mirar(d)


func _modo_juego(activo: bool) -> void:
	en_juego = activo
	hud.visible = activo
	tactil.visible = activo
	tactil.reiniciar()
	if not activo:
		hud.boton_agachar.set_pressed_no_signal(false)
	if jugador:
		jugador.agachado_tactil = false
		jugador.bloqueado = not activo
	if nivel and not activo:
		nivel.construccion.mostrar_previa(null, "")


# ------------------------------------------------------------------ niveles
func _cargar_nivel(i: int) -> void:
	if nivel:
		vista.remove_child(nivel)
		nivel.queue_free()
		nivel = null
		jugador = null
	datos_cap = Juego.datos_capitulo(i)
	nivel = Nivel.new()
	vista.add_child(nivel)
	nivel.construir(datos_cap, self)
	jugador = Jugador.new()
	var prota: Dictionary = datos_cap.get("protagonista", {"nombre": "", "modelo": "david"})
	jugador.clave_modelo = prota.get("modelo", "david")
	nivel.add_child(jugador)
	jugador.position = nivel.inicio + Vector3(0, 0.2, 0)
	jugador.yaw = deg_to_rad(float(datos_cap.get("mirar_inicio", 0)))
	nivel.jugador = jugador
	nivel.particulas_ambiente(jugador, String(datos_cap.get("ambiente", {}).get("particulas", "")))
	faro = Faro.new()
	faro.visible = false
	nivel.add_child(faro)
	_mision_actual = {}
	_reloj = 2.6  # la primera misión se explica después de la introducción
	nivel.construccion.plano_completo.connect(_plano_completo)
	hud.construir = bool(datos_cap.get("construccion", false))
	hud.casilla_elegida = -1
	hud.fijar_construccion(false, false, false)
	var retratos := {String(prota.get("nombre", "")): jugador.clave_modelo}
	retratos.merge(datos_cap.get("retratos", {}))
	for clave in datos_cap.get("leyenda", {}):
		var def: Dictionary = datos_cap["leyenda"][clave]
		if def.get("tipo", "") == "npc":
			retratos[def.get("nombre", "")] = def.get("modelo", def.get("sprite", ""))
	dialogo.retratos = retratos


func iniciar_capitulo(i: int) -> void:
	_limpiar_menu()
	en_titulo = false
	Juego.capitulo = i
	Juego.guardar_partida()
	_cargar_nivel(i)
	_modo_juego(true)
	hud.actualizar()
	Sonido.tocar_musica(datos_cap.get("musica", "titulo"))
	Sonido.tocar_ambiente(datos_cap.get("ambiente_sonido", ""))
	var sub_titulo: String = datos_cap.get("subtitulo", "")
	if datos_cap.has("lugar"):
		sub_titulo += "  ·  " + String(datos_cap["lugar"])
	hud.mostrar_titulo(datos_cap.get("titulo", ""), sub_titulo)
	var marca := "intro_vista_%d" % i
	if not Juego.flags.get(marca, false):
		Juego.marcar(marca)
		await get_tree().create_timer(2.2).timeout
		_abrir_dialogo(datos_cap.get("intro", []), _ayuda_controles if i == 0 else Callable())


func _ayuda_controles() -> void:
	var texto := "Joystick para caminar · desliza en el resto de la pantalla para mirar"
	if not DisplayServer.is_touchscreen_available():
		texto = "WASD: caminar · Flechas o arrastrar el mouse: mirar · E: interactuar · C: vista"
	hud.mostrar_aviso(texto, "", 6.0)


func terminar_capitulo() -> void:
	Sonido.efecto("capitulo")
	var epilogo: Array = datos_cap.get("epilogo", [])
	if epilogo.is_empty():
		_mostrar_versiculo()
	else:
		_abrir_dialogo(epilogo, _mostrar_versiculo)


# ------------------------------------------------------------------ diálogos
func iniciar_dialogo(id: String, _entidad: Entidad = null) -> void:
	if id == "":
		return
	var lineas: Array = datos_cap.get("dialogos", {}).get(id, [])
	if lineas.is_empty():
		push_warning("Diálogo no encontrado: " + id)
		return
	Juego.marcar("visto_" + id)  # quita el «!» del personaje
	_abrir_dialogo(lineas)


func mostrar_lineas(lineas: Array) -> void:
	_abrir_dialogo(lineas)


func decir(texto: String) -> void:
	_abrir_dialogo([{"quien": "", "texto": texto}])


func _abrir_dialogo(lineas: Array, despues: Callable = Callable()) -> void:
	if lineas.is_empty():
		if despues.is_valid():
			despues.call()
		return
	if jugador:
		jugador.bloqueado = true
	tactil.reiniciar()
	tactil.visible = false
	hud.fijar_accion("")
	hud.ocultar_mision()
	dialogo.iniciar(lineas, func():
		hablando_con = ""
		if jugador:
			jugador.modelo.hablando = false
		if en_juego:
			jugador.bloqueado = false
			tactil.visible = true
		Juego.guardar_partida()
		if despues.is_valid():
			despues.call()
		elif not Juego.minijuego_pedido.is_empty() and en_juego:
			var mj: Dictionary = Juego.minijuego_pedido
			Juego.minijuego_pedido = {}
			_mostrar_minijuego(mj)
		elif Juego.fin_pedido and en_juego:
			Juego.fin_pedido = false
			terminar_capitulo())


# ------------------------------------------------------------------ bucle
func _process(delta: float) -> void:
	if en_titulo and jugador:
		jugador.yaw += delta * 0.08
		return
	if not en_juego or dialogo.visible or jugador == null:
		return
	if _objetivo_entidad and is_instance_valid(_objetivo_entidad):
		_objetivo_entidad.resaltada = false
	_objetivo_entidad = null
	var mejor := DISTANCIA_INTERACCION
	for e in get_tree().get_nodes_in_group("interactuable"):
		var d := Vector2(e.global_position.x - jugador.global_position.x, e.global_position.z - jugador.global_position.z).length()
		if d < mejor:
			mejor = d
			_objetivo_entidad = e
	if _objetivo_entidad:
		_objetivo_entidad.resaltada = true
	hud.fijar_accion(_objetivo_entidad.texto_accion() if _objetivo_entidad else "")
	if hud.construir:
		_apuntar_bloque()
	_espera_bloque -= delta
	_reloj -= delta
	if _reloj <= 0:
		_reloj = 0.5
		if nivel.construccion.actualizar_planos():
			hud.mostrar_aviso(_texto_ayuda_bloques(), "", 5.0)
		_actualizar_seleccion()
		var actual: Dictionary = {}
		for o in datos_cap.get("objetivos", []):
			if not Juego.cumple(o.get("hecho", [])):
				actual = o
				break
		hud.fijar_objetivo(_texto_objetivo(actual))
		_actualizar_faro(actual)
		if actual.get("texto", "") != _mision_actual.get("texto", ""):
			_mision_actual = actual
			_explicar_mision(actual, true)


## Cómo cumplir un objetivo: su "ayuda" del JSON o, si no tiene, una explicación según su tipo.
func ayuda_de(o: Dictionary) -> String:
	if o.has("ayuda"):
		return String(o["ayuda"])
	if o.has("marca_plano"):
		return "Sigue el rombo dorado. Pica bloques del montón con «Picar» y ponlos en la silueta azul con «Poner»."
	if o.has("marca_acertijo"):
		return "Sigue el rombo dorado y pulsa el botón junto a cada lugar, en el orden correcto."
	return "Sigue el rombo dorado y, cuando estés cerca, pulsa el botón grande de la derecha."


## Tarjeta de la misión vigente; la lee en voz alta si está activada la lectura.
func _explicar_mision(o: Dictionary, nueva: bool) -> void:
	if o.is_empty() or not en_juego or dialogo.visible:
		return
	var como := ayuda_de(o)
	hud.mostrar_mision(String(o.get("texto", "")), como, nueva)
	if Juego.leer_voz:
		CajaDialogo.hablar(como)


## Material que pide ahora un objetivo de construir ("marca_plano"), si el jugador no tiene nada de él.
func _material_que_falta(o: Dictionary) -> String:
	var id := _plano_del_objetivo(o)
	var con := nivel.construccion
	if id == "":
		return ""
	var celda = con.celda_que_falta(id, jugador.global_position)
	if celda == null:
		return ""
	var material: String = con.planos[id]["celdas"][celda]
	return material if Juego.cantidad_bloque(material) == 0 else ""


## Plano activo y sin terminar que señala "marca_plano" (un id o una lista de ids), o "".
func _plano_del_objetivo(o: Dictionary) -> String:
	var ids = o.get("marca_plano", [])
	for id in (ids if ids is Array else [ids]):
		var con := nivel.construccion
		if con.planos.has(id) and con.planos[id]["activo"] and not con.planos[id]["hecho"]:
			return String(id)
	return ""


## Texto del objetivo; en los de construir avisa primero de dónde sacar el material.
func _texto_objetivo(o: Dictionary) -> String:
	var texto := String(o.get("texto", ""))
	var falta := _material_que_falta(o)
	if falta != "":
		var fuente := "los troncos" if falta == "madera" else ("los montones de brea" if falta == "brea" else "los escombros")
		texto = "Pica %s para sacar %s («Picar»)" % [fuente, Construccion.nombre_de(falta).to_lower()]
	return texto


## Coloca el faro sobre el objetivo: la entidad más cercana con una de las letras de "marca",
## la siguiente lámpara de "marca_acertijo" o, en "marca_plano", el próximo bloque por poner
## (o el montón donde conseguir el material, si no tienes).
func _actualizar_faro(o: Dictionary) -> void:
	var destino: Entidad = null
	var punto: Variant = null
	if o.has("marca_plano"):
		var con := nivel.construccion
		var falta := _material_que_falta(o)
		var id_plano := _plano_del_objetivo(o)
		var celda: Variant = null
		if falta != "":
			celda = con.fuente_de(falta, jugador.global_position)
		elif id_plano != "":
			celda = con.celda_que_falta(id_plano, jugador.global_position)
		if celda != null:
			punto = Vector3(celda) + Vector3(0.5, 0.0, 0.5)
	elif o.has("marca_acertijo"):
		destino = nivel.siguiente_del_acertijo(o["marca_acertijo"])
	elif o.has("marca"):
		var mejor := INF
		for e in nivel.entidades:
			if is_instance_valid(e) and e.activo and e.is_in_group("interactuable") and e.letra in String(o["marca"]):
				var d := e.global_position.distance_to(jugador.global_position)
				if d < mejor:
					mejor = d
					destino = e
	for e in nivel.entidades:
		if is_instance_valid(e):
			e.marcada = Juego.guia and e == destino
	if destino:
		punto = destino.global_position
	faro.visible = Juego.guia and punto != null
	if punto != null:
		faro.global_position = punto


func _interactuar() -> void:
	if dialogo.visible:
		dialogo.avanzar()
	elif en_juego and _objetivo_entidad and is_instance_valid(_objetivo_entidad):
		var e := _objetivo_entidad
		# el jugador se gira hacia lo que usa y hace un gesto
		var hacia := e.global_position - jugador.global_position
		hacia.y = 0
		jugador.modelo.actualizar(0.2, hacia, false)
		match e.tipo:
			"objeto": jugador.modelo.gesto("recoger")
			"lampara", "mecanismo": jugador.modelo.gesto("encender")
			"npc": jugador.modelo.gesto("saludar")
		e.interactuar(self)


# ------------------------------------------------------------------ bloques (estilo Minecraft)
## Material de construcción en la mano: el elegido en la barra o, si se acabó, el primero que haya
## (prefiere lo que falta en los planos activos).
func _material_elegido() -> String:
	var c := nivel.construccion
	if c.seleccion != "" and Juego.cantidad_bloque(c.seleccion) > 0:
		return c.seleccion
	var falta := c.faltantes()
	var primero := ""
	for o in Juego.inventario_capitulo().values():
		if o.has("bloque") and o["cantidad"] > 0:
			if falta.has(o["bloque"]):
				return o["bloque"]
			if primero == "":
				primero = o["bloque"]
	return primero


func _actualizar_seleccion() -> void:
	var m := _material_elegido()
	var idx := -1
	var lista: Array = Juego.inventario_capitulo().values()
	for i in lista.size():
		if lista[i].get("bloque", "") == m:
			idx = i
	if idx != hud.casilla_elegida:
		hud.casilla_elegida = idx
		hud.actualizar()


func _elegir_casilla(i: int) -> void:
	var lista: Array = Juego.inventario_capitulo().values()
	if nivel and i < lista.size() and lista[i].has("bloque"):
		nivel.construccion.seleccion = lista[i]["bloque"]
		Sonido.efecto("seleccion", 0.5)
		hud.mostrar_aviso(String(lista[i]["nombre"]), "", 0.8)
		_actualizar_seleccion()


func _ciclar_material(paso: int) -> void:
	var mats := []
	for o in Juego.inventario_capitulo().values():
		if o.has("bloque"):
			mats.append(o["bloque"])
	if mats.size() < 2:
		return
	var actual := mats.find(_material_elegido())
	nivel.construccion.seleccion = mats[posmod(actual + paso, mats.size())]
	_actualizar_seleccion()


func _apuntar_bloque() -> void:
	var c := nivel.construccion
	_apunte = c.apuntar(jugador.camara, jugador)
	var mat := _material_elegido()
	var puede_picar := false
	var puede_poner := false
	if not _apunte.is_empty():
		puede_picar = c.se_puede_picar(_apunte["bloque"])
		puede_poner = mat != "" and c.motivo_para_no_poner(_apunte["poner"], mat) == ""
	if puede_poner:
		var destino: Vector3i = _apunte["poner"]
		var es_plano := c.plano_de(destino) != ""
		var material_destino := c.material_de_plano(destino) if es_plano else mat
		c.mostrar_previa(destino, "plano" if es_plano else "poner", material_destino)
	elif puede_picar:
		var material_objetivo: String = c.bloques[_apunte["bloque"]]["material"]
		c.mostrar_previa(_apunte["bloque"], "picar", material_objetivo)
	else:
		c.mostrar_previa(null, "")
	hud.fijar_construccion(true, puede_picar, puede_poner)


func _texto_ayuda_bloques() -> String:
	if DisplayServer.is_touchscreen_available():
		return "Apunta con la mira: «Picar» saca bloques de los montones y «Poner» los coloca en la silueta azul"
	return "Apunta con la mira: Q pica bloques de los montones y F los pone en la silueta azul (1-9 o la rueda: elegir)"


## Lo que dice la obra cuando la tocas: cuántos bloques faltan y cómo se hace.
func ayuda_construir(faltan: int) -> void:
	decir("Faltan %d bloques en la silueta azul. %s." % [faltan, _texto_ayuda_bloques()])


func _picar() -> void:
	if not en_juego or dialogo.visible or not hud.construir or _espera_bloque > 0:
		return
	if _apunte.is_empty() or not nivel.construccion.se_puede_picar(_apunte["bloque"]):
		hud.mostrar_aviso("Apunta la mira a un bloque suelto", "", 1.2)
		return
	picar_en(_apunte["bloque"])


func picar_en(celda: Vector3i) -> void:
	_espera_bloque = 0.15
	var material: String = nivel.construccion.bloques[celda]["material"]
	var recurso := nivel.construccion.picar_jugador(celda)
	Juego.sumar_bloque(recurso, 1)
	Sonido.efecto("picar", 0.8)
	var color := Color(Construccion.MATERIALES.get(material, {}).get("color", "#b8b2a8"))
	nivel.chispas(Vector3(celda) + Vector3.ONE * 0.5, color, 14)
	if jugador.modelo.visible:
		jugador.modelo.gesto("recoger")
	_actualizar_seleccion()


func _poner() -> void:
	if not en_juego or dialogo.visible or not hud.construir or _espera_bloque > 0:
		return
	var mat := _material_elegido()
	if mat == "":
		hud.mostrar_aviso("No tienes bloques: pica un montón para conseguirlos", "", 2.0)
		return
	if _apunte.is_empty():
		hud.mostrar_aviso("Apunta la mira al suelo o a otro bloque", "", 1.2)
		return
	var motivo := nivel.construccion.motivo_para_no_poner(_apunte["poner"], mat)
	if motivo != "":
		hud.mostrar_aviso(motivo, "", 1.6)
		return
	poner_en(_apunte["poner"], mat)


func poner_en(celda: Vector3i, material: String) -> void:
	_espera_bloque = 0.15
	Juego.sumar_bloque(material, -1)
	nivel.construccion.poner_jugador(celda, material)
	Sonido.efecto("poner", 0.8)
	if jugador.modelo.visible:
		jugador.modelo.gesto("encender")
	_actualizar_seleccion()


func _plano_completo(id: String) -> void:
	var p: Dictionary = nivel.construccion.planos[id]
	var centro_plano := Vector3.ZERO
	for c in p["celdas"]:
		centro_plano += Vector3(c)
	centro_plano /= maxf(p["celdas"].size(), 1)
	Sonido.efecto("exito")
	nivel.chispas(centro_plano + Vector3(0.5, 1.5, 0.5), Color("ffe08a"), 80)
	iniciar_dialogo(String(p["dialogo"]))


func _cambiar_vista() -> void:
	if jugador:
		jugador.aplicar_vista(not Juego.primera_persona)
		Juego.guardar_ajustes()
		hud.actualizar()


func _unhandled_input(ev: InputEvent) -> void:
	if ev.is_action_pressed("pausa") and _volver_ajustes.is_valid():
		_salir_ajustes()
		get_viewport().set_input_as_handled()
		return
	if ev.is_action_pressed("interactuar"):
		_interactuar()
	elif ev.is_action_pressed("cambiar_vista") and en_juego:
		_cambiar_vista()
	elif ev.is_action_pressed("pausa") and en_juego and not dialogo.visible:
		_mostrar_pausa()
	elif ev.is_action_pressed("mochila") and en_juego and not dialogo.visible:
		_mostrar_mochila()
	elif ev.is_action_pressed("picar"):
		_picar()
	elif ev.is_action_pressed("poner"):
		_poner()
	elif ev is InputEventMouseButton and ev.pressed and en_juego and hud.construir and \
			ev.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
		_ciclar_material(1 if ev.button_index == MOUSE_BUTTON_WHEEL_DOWN else -1)
	elif en_juego:
		for i in 9:
			if ev.is_action_pressed("casilla_%d" % (i + 1)):
				_elegir_casilla(i)


func _notification(what: int) -> void:
	# botón "atrás" de Android
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		if _volver_ajustes.is_valid():
			_salir_ajustes()
		elif en_juego:
			_mostrar_pausa()


# ------------------------------------------------------------------ menús
func _limpiar_menu() -> void:
	_volver_ajustes = Callable()
	for c in capa_menu.get_children():
		c.queue_free()


func _pantalla(oscurecer: float) -> VBoxContainer:
	_limpiar_menu()
	var fondo := ColorRect.new()
	fondo.color = Color(0.04, 0.03, 0.08, oscurecer)
	fondo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	capa_menu.add_child(fondo)
	var centro := CenterContainer.new()
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	capa_menu.add_child(centro)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 18)
	col.custom_minimum_size = Vector2(560, 0)
	centro.add_child(col)
	return col


func _texto(col: Control, t: String, tam: int, color := Color(1, 1, 1)) -> Label:
	var l := Label.new()
	l.text = t
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size", tam)
	l.add_theme_color_override("font_color", color)
	col.add_child(l)
	return l


func _boton(col: Control, t: String, accion: Callable) -> Button:
	var b := Button.new()
	b.text = t
	b.custom_minimum_size = Vector2(0, 76)
	b.add_theme_font_size_override("font_size", 32)
	b.pressed.connect(func(): Sonido.efecto("seleccion", 0.7))
	if accion.is_valid():
		b.pressed.connect(accion)
	col.add_child(b)
	return b


func _sonido_aviso(_texto: String, icono: String) -> void:
	if icono in Juego.VIRTUDES:
		Sonido.efecto("virtud", 0.8)


func mostrar_titulo() -> void:
	_modo_juego(false)
	_cargar_nivel(0)
	en_titulo = true
	Sonido.tocar_musica("titulo")
	Sonido.tocar_ambiente("")
	jugador.brazo.spring_length = 9.0
	jugador.pitch = -0.35
	faro.visible = false
	var col := _pantalla(0.35)
	_logo(col)
	col.add_child(Control.new())
	if Juego.hay_partida():
		_boton(col, "Continuar", func():
			Juego.cargar_partida()
			jugar_capitulo(Juego.capitulo))
		_boton(col, "Capítulos", func():
			Juego.cargar_partida()
			_mostrar_capitulos())
	_boton(col, "Nueva aventura", _elegir_vista)
	_boton(col, "Ajustes", func(): _mostrar_ajustes(mostrar_titulo))


const FRASES_PORTADA := [
	"¡Historias reales de la Biblia!", "¡El arca de Noé!", "¡Cinco piedras lisas!", "¡De Jehová es la batalla!",
	"¡Tu pueblo será mi pueblo!", "¡Yo soy José!", "¡Levantémonos y edifiquemos!",
	"¡Ardía nuestro corazón!", "¡Para niños y adultos!",
]


## Logo grande con sombra y una frase amarilla inclinada que late (como en Minecraft).
func _logo(col: Control) -> void:
	var caja := Control.new()
	caja.custom_minimum_size = Vector2(760, 190)
	col.add_child(caja)
	var titulo := Label.new()
	titulo.text = "EL CAMINO"
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.add_theme_font_size_override("font_size", 150)
	titulo.add_theme_color_override("font_color", Color("f0d48a"))
	titulo.add_theme_color_override("font_outline_color", Color("3a2a18"))
	titulo.add_theme_constant_override("outline_size", 18)
	titulo.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
	titulo.add_theme_constant_override("shadow_offset_x", 8)
	titulo.add_theme_constant_override("shadow_offset_y", 8)
	Tema.anclar(titulo, 0, 0, 1, 0)
	caja.add_child(titulo)
	var sub := Label.new()
	sub.text = "Historias de la Biblia"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 34)
	Tema.anclar(sub, 0, 0, 1, 0)
	sub.offset_top = 150
	caja.add_child(sub)
	var frase := Label.new()
	frase.text = FRASES_PORTADA[randi() % FRASES_PORTADA.size()]
	frase.add_theme_font_size_override("font_size", 30)
	frase.add_theme_color_override("font_color", Color("ffff40"))
	frase.add_theme_color_override("font_shadow_color", Color("3f3f00"))
	frase.position = Vector2(560, 120)
	frase.rotation_degrees = -16
	caja.add_child(frase)
	frase.pivot_offset = Vector2(frase.get_minimum_size().x / 2, 16)
	var t: Tween = frase.create_tween().set_loops()
	t.tween_property(frase, "scale", Vector2(1.08, 1.08), 0.35).set_trans(Tween.TRANS_SINE)
	t.tween_property(frase, "scale", Vector2(0.96, 0.96), 0.35).set_trans(Tween.TRANS_SINE)


func _elegir_vista() -> void:
	var col := _pantalla(0.6)
	_texto(col, "¿Cómo quieres recorrer el camino?", 46, Color("ffd36b"))
	_boton(col, "Primera persona — ver con los ojos del protagonista", func():
		Juego.nueva_partida(true)
		_mostrar_mapa_camino(0))
	_boton(col, "Tercera persona — ver al protagonista en el mundo", func():
		Juego.nueva_partida(false)
		_mostrar_mapa_camino(0))
	_texto(col, "Puedes cambiarlo cuando quieras con el botón «Vista».", 24, Color(1, 1, 1, 0.7))
	_boton(col, "Volver", mostrar_titulo)


## Empieza un capítulo; si ya se había terminado, se juega otra vez desde cero.
func jugar_capitulo(i: int) -> void:
	if i in Juego.completados:
		Juego.reiniciar_capitulo(i)
	iniciar_capitulo(i)


## Mapa ilustrado antes de cada historia: dónde ocurre y cuánto camino llevas.
func _mostrar_mapa_camino(i: int) -> void:
	_modo_juego(false)
	var col := _pantalla(0.85)
	col.custom_minimum_size = Vector2(940, 0)
	var d := Juego.datos_capitulo(i)
	_texto(col, "El camino · historia %d de %d" % [i + 1, Juego.CAPITULOS.size()], 34, Color("ffd36b"))
	var mapa := MapaCamino.new()
	mapa.actual = i
	mapa.completados = Juego.completados
	col.add_child(mapa)
	_texto(col, "%s  ·  %s  ·  %s" % [d.get("titulo", ""), d.get("subtitulo", ""), d.get("lugar", "")], 28)
	_boton(col, "Comenzar", jugar_capitulo.bind(i))


func _estrellas(padre: Control, n: int, tam := 34) -> void:
	var fila := HBoxContainer.new()
	fila.alignment = BoxContainer.ALIGNMENT_CENTER
	for k in 3:
		var t := TextureRect.new()
		t.texture = load("res://assets/iconos/estrella.png")
		t.custom_minimum_size = Vector2(tam, tam)
		t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		t.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		t.modulate = Color.WHITE if k < n else Color(0.25, 0.22, 0.32)
		fila.add_child(t)
	padre.add_child(fila)


func _mostrar_capitulos() -> void:
	var col := _pantalla(0.7)
	col.custom_minimum_size = Vector2(760, 0)
	_texto(col, "Capítulos", 56, Color("ffd36b"))
	for i in Juego.CAPITULOS.size():
		var d := Juego.datos_capitulo(i)
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 16)
		col.add_child(fila)
		var abierto := i <= Juego.capitulo_max
		var b := _boton(fila, "%d. %s  ·  %s" % [i + 1, d.get("titulo", ""), d.get("subtitulo", "")] if abierto else "%d. ???  ·  (termina el anterior)" % (i + 1),
			jugar_capitulo.bind(i))
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.disabled = not abierto
		b.add_theme_font_size_override("font_size", 26)
		_estrellas(fila, int(Juego.estrellas.get(str(i), 0)), 28)
	_boton(col, "Volver", mostrar_titulo)


## Encabezado y salida fijos; solo las opciones se desplazan con el dedo.
func _mostrar_ajustes(volver: Callable) -> void:
	_limpiar_menu()
	_volver_ajustes = volver
	var fondo := ColorRect.new()
	fondo.color = Color(0.04, 0.03, 0.08, 0.92)
	fondo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	capa_menu.add_child(fondo)
	var margen := MarginContainer.new()
	margen.name = "PanelAjustes"
	margen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for lado in ["left", "right", "top", "bottom"]:
		margen.add_theme_constant_override("margin_" + lado, 24)
	capa_menu.add_child(margen)
	var marco := VBoxContainer.new()
	marco.add_theme_constant_override("separation", 12)
	margen.add_child(marco)
	_texto(marco, "Ajustes", 44, Color("ffd36b"))
	var scroll := ScrollContainer.new()
	scroll.name = "OpcionesDesplazables"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.follow_focus = true
	scroll.scroll_deadzone = 16
	marco.add_child(scroll)
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 18)
	scroll.add_child(col)
	var deslizador := func(titulo: String, clave: String, minimo: float, maximo: float):
		_texto(col, titulo, 24, Color(1, 1, 1, 0.85))
		var sl := HSlider.new()
		sl.min_value = minimo
		sl.max_value = maximo
		sl.step = 0.05
		sl.value = Juego.get(clave)
		sl.custom_minimum_size = Vector2(0, 56)
		sl.value_changed.connect(func(v):
			Juego.set(clave, v)
			Juego.guardar_ajustes()
			Sonido.aplicar_volumenes())
		col.add_child(sl)
	deslizador.call("Volumen de la música", "vol_musica", 0.0, 1.0)
	deslizador.call("Volumen de los efectos", "vol_efectos", 0.0, 1.0)
	deslizador.call("Sensibilidad de la cámara", "sensibilidad", 0.3, 2.5)
	_texto(col, "Voz de lectura: natural, incluida en el juego (no necesita internet)", 22, Color(1, 1, 1, 0.85))
	_boton(col, "Probar voz", func():
		CajaDialogo.hablar("Hola. Esta es la voz que lee las historias de El Camino."))
	var interruptor := func(titulo: String, clave: String):
		var fila := HBoxContainer.new()
		fila.custom_minimum_size.y = 64
		col.add_child(fila)
		var etiqueta := _texto(fila, titulo, 28)
		etiqueta.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		etiqueta.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		etiqueta.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var c := CheckButton.new()
		c.name = "Ajuste_" + clave
		c.custom_minimum_size = Vector2(100, 64)
		c.button_pressed = Juego.get(clave)
		c.toggled.connect(func(v):
			Juego.set(clave, v)
			Juego.guardar_ajustes()
			Sonido.efecto("seleccion", 0.6))
		fila.add_child(c)
	interruptor.call("Leer los diálogos en voz alta", "leer_voz")
	interruptor.call("Texto grande", "texto_grande")
	interruptor.call("Guía: faro sobre el objetivo y «!» en personajes", "guia")
	interruptor.call("Primera persona", "primera_persona")
	col.add_child(PanelActualizaciones.new())
	var salir := _boton(marco, "Volver", _salir_ajustes)
	salir.name = "VolverDeAjustes"


func _salir_ajustes() -> void:
	if not _volver_ajustes.is_valid():
		return
	var volver := _volver_ajustes
	_volver_ajustes = Callable()
	if jugador:
		jugador.aplicar_vista(Juego.primera_persona, false)
	volver.call()


func _mostrar_pausa() -> void:
	if not en_juego:
		return
	_modo_juego(false)
	var col := _pantalla(0.6)
	_texto(col, "Pausa", 60, Color("ffd36b"))
	_texto(col, "%s · %s" % [datos_cap.get("titulo", ""), datos_cap.get("subtitulo", "")], 28)
	_boton(col, "Continuar", func():
		_limpiar_menu()
		_modo_juego(true))
	_boton(col, "Ajustes", func(): _mostrar_ajustes(_volver_a_pausa))
	_boton(col, "Reiniciar este capítulo", func():
		Juego.reiniciar_capitulo(Juego.capitulo)
		iniciar_capitulo(Juego.capitulo))
	_boton(col, "Guardar y volver al inicio", func():
		Juego.guardar_partida()
		mostrar_titulo())


## Minijuegos dentro de una historia; al ganar sigue el diálogo indicado en "exito".
func _mostrar_minijuego(mj: Dictionary) -> void:
	_modo_juego(false)
	_limpiar_menu()
	var juego := MinijuegoHonda.new()
	capa_menu.add_child(juego)
	juego.terminado.connect(func():
		_limpiar_menu()
		_modo_juego(true)
		iniciar_dialogo(String(mj.get("exito", ""))))


## Mochila: lo recogido en este capítulo, las reliquias del viaje y los versículos aprendidos.
func _mostrar_mochila() -> void:
	if not en_juego:
		return
	_modo_juego(false)
	var col := _pantalla(0.6)
	col.custom_minimum_size = Vector2(760, 0)
	_texto(col, "Mochila", 52, Color("ffd36b"))
	var panel := PanelContainer.new()
	col.add_child(panel)
	var dentro := VBoxContainer.new()
	dentro.add_theme_constant_override("separation", 10)
	panel.add_child(dentro)
	_texto(dentro, "En este capítulo", 26, Color("e8c26a"))
	var rejilla := GridContainer.new()
	rejilla.columns = 9
	rejilla.add_theme_constant_override("h_separation", 4)
	rejilla.add_theme_constant_override("v_separation", 4)
	dentro.add_child(rejilla)
	var objetos: Array = Juego.inventario_capitulo().values()
	var reliquias: Array = Juego.reliquias()
	for i in 18:
		var c := Panel.new()
		c.custom_minimum_size = Vector2(70, 70)
		var o: Dictionary = objetos[i] if i < objetos.size() else {}
		c.add_theme_stylebox_override("panel", Tema.textura("ranura_sel" if o.get("reliquia", false) else "ranura", Vector2.ZERO))
		if o.has("icono"):
			c.tooltip_text = o["nombre"]
			var ic := TextureRect.new()
			ic.texture = load("res://assets/iconos/%s.png" % o["icono"])
			ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			ic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			ic.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			ic.offset_left = 12
			ic.offset_top = 12
			ic.offset_right = -12
			ic.offset_bottom = -12
			ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
			c.add_child(ic)
		rejilla.add_child(c)
	var nombres := []
	for o in objetos:
		nombres.append("%s ×%d" % [o["nombre"], o["cantidad"]] if o["cantidad"] > 1 else String(o["nombre"]))
	_texto(dentro, ", ".join(nombres) if not nombres.is_empty() else "Todavía no has recogido nada.", 22, Color(1, 1, 1, 0.85))
	var nombres_rel := reliquias.map(func(r): return r["nombre"])
	_texto(dentro, "Reliquias del viaje (%d): %s" % [reliquias.size(), ", ".join(nombres_rel) if not nombres_rel.is_empty() else "busca secretos escondidos"], 22, Color("ffe7a0"))
	var versos := []
	for i in Juego.CAPITULOS.size():
		if i in Juego.completados:
			var rep: Dictionary = Juego.datos_capitulo(i).get("repaso", {})
			versos.append("«%s» (%s)" % [rep.get("versiculo", ""), rep.get("cita", "")])
	if not versos.is_empty():
		_texto(dentro, "Versículos aprendidos", 24, Color("e8c26a"))
		var l := _texto(dentro, "\n".join(versos), 22, Color(1, 1, 1, 0.9))
		l.add_theme_font_override("font", Tema.fuente_lectura())
	_boton(col, "Volver", func():
		_limpiar_menu()
		_modo_juego(true))


func _volver_a_pausa() -> void:
	en_juego = true
	_mostrar_pausa()


# ------------------------------------------------------------------ repaso al final del capítulo
var _aciertos := 0


func _mostrar_versiculo() -> void:
	_modo_juego(false)
	var rep: Dictionary = datos_cap.get("repaso", {})
	if rep.is_empty():
		_mostrar_resumen()
		return
	var col := _pantalla(0.82)
	col.custom_minimum_size = Vector2(820, 0)
	_texto(col, "Versículo para recordar", 40, Color("ffd36b"))
	var panel := PanelContainer.new()
	col.add_child(panel)
	var dentro := VBoxContainer.new()
	panel.add_child(dentro)
	_texto(dentro, "«%s»" % rep.get("versiculo", ""), 44 if Juego.texto_grande else 38)
	_texto(dentro, rep.get("cita", ""), 30, Color("ffd36b"))
	if Juego.leer_voz:
		CajaDialogo.hablar("%s. %s" % [rep.get("versiculo", ""), rep.get("cita", "")])
	_aciertos = 0
	_boton(col, "Responder preguntas", _mostrar_pregunta.bind(0))


func _mostrar_pregunta(n: int) -> void:
	var preguntas: Array = datos_cap.get("repaso", {}).get("preguntas", [])
	if n >= preguntas.size():
		var k := str(Juego.capitulo)
		Juego.estrellas[k] = maxi(int(Juego.estrellas.get(k, 0)), _aciertos)
		_mostrar_resumen()
		return
	var p: Dictionary = preguntas[n]
	var col := _pantalla(0.82)
	col.custom_minimum_size = Vector2(820, 0)
	_texto(col, "Pregunta %d de %d" % [n + 1, preguntas.size()], 28, Color("ffd36b"))
	_texto(col, p.get("pregunta", ""), 44 if Juego.texto_grande else 38)
	if Juego.leer_voz:
		CajaDialogo.hablar(p.get("pregunta", ""))
	var botones: Array[Button] = []
	for j in p.get("opciones", []).size():
		var b := _boton(col, p["opciones"][j], Callable())
		botones.append(b)
	for j in botones.size():
		botones[j].pressed.connect(func():
			var bien: bool = j == int(p.get("correcta", 0))
			if bien:
				_aciertos += 1
			Sonido.efecto("correcto" if bien else "fallo")
			for b2 in botones:
				b2.disabled = true
			botones[int(p.get("correcta", 0))].modulate = Color(0.6, 1.0, 0.6)
			if not bien:
				botones[j].modulate = Color(1.0, 0.55, 0.55)
			_texto(col, ("¡Correcto! " if bien else "Casi. ") + p.get("explica", ""), 28, Color(0.75, 1, 0.75) if bien else Color(1, 0.85, 0.7))
			_boton(col, "Siguiente", _mostrar_pregunta.bind(n + 1)))


func _confeti() -> void:
	var c := CPUParticles2D.new()
	c.position = Vector2(get_viewport().get_visible_rect().size.x / 2, -20)
	c.emitting = true
	c.one_shot = true
	c.amount = 160
	c.lifetime = 3.0
	c.explosiveness = 0.85
	c.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	c.emission_rect_extents = Vector2(get_viewport().get_visible_rect().size.x / 2, 10)
	c.direction = Vector2(0, 1)
	c.spread = 30.0
	c.initial_velocity_min = 120.0
	c.initial_velocity_max = 320.0
	c.gravity = Vector2(0, 260)
	c.angular_velocity_min = -360.0
	c.angular_velocity_max = 360.0
	c.scale_amount_min = 6.0
	c.scale_amount_max = 11.0
	var g := Gradient.new()
	g.colors = PackedColorArray([Color("ffd36b"), Color("ff6f7d"), Color("8fd3ff"), Color("8be07a")])
	g.offsets = PackedFloat32Array([0.0, 0.33, 0.66, 1.0])
	c.color_initial_ramp = g
	capa_menu.add_child(c)


func _mostrar_resumen() -> void:
	_modo_juego(false)
	if not Juego.capitulo in Juego.completados:
		Juego.completados.append(Juego.capitulo)
	Juego.capitulo_max = maxi(Juego.capitulo_max, mini(Juego.capitulo + 1, Juego.CAPITULOS.size() - 1))
	var col := _pantalla(0.7)
	_texto(col, "¡Capítulo completado!", 54, Color("ffd36b"))
	_texto(col, "%s · %s" % [datos_cap.get("titulo", ""), datos_cap.get("subtitulo", "")], 30)
	_estrellas(col, int(Juego.estrellas.get(str(Juego.capitulo), 0)), 56)
	var total := 0
	for k in datos_cap.get("leyenda", {}):
		if datos_cap["leyenda"][k].get("efectos", {}).has("secreto"):
			total += 1
	var lineas := []
	for v in Juego.VIRTUDES:
		lineas.append("%s: %d" % [Juego.NOMBRE_VIRTUD[v], Juego.virtudes[v]])
	_texto(col, "   ".join(lineas), 30)
	var hallados := int(Juego.registro.get(str(Juego.capitulo), {}).get("secretos", 0))
	_texto(col, "Secretos de este capítulo: %d de %d     Luz del candil: %d%%" % [hallados, total, int(Juego.luz)], 24, Color(1, 1, 1, 0.8))
	_confeti()
	var siguiente := Juego.capitulo + 1
	if siguiente < Juego.CAPITULOS.size():
		Juego.capitulo = siguiente
		Juego.guardar_partida()
		_boton(col, "Seguir el camino", _mostrar_mapa_camino.bind(siguiente))
		_boton(col, "Volver al inicio", mostrar_titulo)
	else:
		Juego.guardar_partida()
		_boton(col, "Ver el final", _mostrar_final)


func _mostrar_final() -> void:
	_limpiar_menu()
	var final: Dictionary = datos_cap.get("final", {})
	var lineas: Array = final.get("antes", []) + final.get(Juego.virtud_mayor(), []) + final.get("despues", [])
	_abrir_dialogo(lineas, func():
		_modo_juego(false)
		var col := _pantalla(0.85)
		_texto(col, "Fin del primer viaje", 60, Color("ffd36b"))
		_texto(col, "«¿No ardía nuestro corazón mientras nos hablaba en el camino?» — Lucas 24:32", 30)
		_texto(col, "Puedes volver a jugar cualquier historia desde «Capítulos» para buscar todas las estrellas y secretos.", 26, Color(1, 1, 1, 0.8))
		_confeti()
		_boton(col, "Volver al inicio", mostrar_titulo))
