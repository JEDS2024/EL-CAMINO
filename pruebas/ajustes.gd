extends Node
## Menú móvil: contenido desplazable y salida fija en 16:9, 20:9 y ventanas pequeñas.
var main: Node
var fallos := 0
var salidas := 0

func comprobar(si: bool, texto: String) -> void:
	if not si:
		fallos += 1
	print("  ", "✔ " if si else "✘ ", texto)

func esperar() -> void:
	for i in 5:
		await get_tree().process_frame

func volver() -> void:
	salidas += 1
	main.mostrar_titulo()

func _ready() -> void:
	main = load("res://escenas/main.tscn").instantiate()
	add_child(main)
	await esperar()
	for tam in [Vector2i(1280, 720), Vector2i(1600, 720), Vector2i(960, 540)]:
		get_tree().root.content_scale_size = tam
		get_tree().root.size = tam
		main._mostrar_ajustes(volver)
		await esperar()
		var scroll: ScrollContainer = main.capa_menu.find_child("OpcionesDesplazables", true, false)
		var boton: Button = main.capa_menu.find_child("VolverDeAjustes", true, false)
		var pantalla := get_viewport().get_visible_rect()
		comprobar(pantalla.encloses(boton.get_global_rect()), "%s: Volver completo en pantalla" % tam)
		comprobar(pantalla.encloses(scroll.get_global_rect()), "%s: opciones dentro de la pantalla" % tam)
		comprobar(scroll.get_v_scroll_bar().max_value > scroll.get_v_scroll_bar().page, "%s: se puede desplazar la lista" % tam)
		if OS.get_cmdline_user_args().has("--capturas") and DisplayServer.get_name() != "headless":
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png("/tmp/lumbral-ajustes-%d-inicio.png" % tam.x)
		var guia: CheckButton = main.capa_menu.find_child("Ajuste_guia", true, false)
		var valor_anterior := bool(Juego.guia)
		guia.button_pressed = not valor_anterior
		comprobar(Juego.guia == not valor_anterior, "%s: los interruptores cambian el ajuste" % tam)
		var cfg := ConfigFile.new()
		cfg.load(Juego.RUTA_AJUSTES)
		comprobar(cfg.get_value("ajustes", "guia") == Juego.guia, "%s: el ajuste se guarda" % tam)
		guia.button_pressed = valor_anterior
		var antes := boton.get_global_rect()
		scroll.scroll_vertical = 100000
		await esperar()
		if OS.get_cmdline_user_args().has("--capturas") and DisplayServer.get_name() != "headless":
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png("/tmp/lumbral-ajustes-%d-final.png" % tam.x)
		var ultimo: CheckButton = main.capa_menu.find_child("Ajuste_primera_persona", true, false)
		comprobar(scroll.get_global_rect().encloses(ultimo.get_global_rect()), "%s: última opción accesible" % tam)
		comprobar(boton.get_global_rect() == antes, "%s: Volver permanece fijo" % tam)
		boton.pressed.emit()
		await esperar()
	comprobar(salidas == 3, "Volver sale desde las tres resoluciones")
	main._mostrar_ajustes(volver)
	await esperar()
	main._notification(NOTIFICATION_WM_GO_BACK_REQUEST)
	await esperar()
	comprobar(salidas == 4, "Atrás de Android cierra Ajustes")
	main._mostrar_ajustes(volver)
	await esperar()
	var ev := InputEventAction.new()
	ev.action = "pausa"
	ev.pressed = true
	main._unhandled_input(ev)
	await esperar()
	comprobar(salidas == 5, "Escape cierra Ajustes")
	Juego.flags["intro_vista_0"] = true
	main.iniciar_capitulo(0)
	main._mostrar_pausa()
	main._mostrar_ajustes(Callable(main, "_volver_a_pausa"))
	await esperar()
	main._salir_ajustes()
	await esperar()
	comprobar(main.jugador.bloqueado and not main.en_juego and not main._volver_ajustes.is_valid(), "desde la partida, Volver regresa a la pausa")
	print("AJUSTES: %d fallos" % fallos)
	get_tree().quit(fallos)
