extends Node
## Casos de red, manifiesto, integridad y recuperación; no abre el instalador en un teléfono.
var fallos := 0
var main: Node

func comprobar(si: bool, texto: String) -> void:
	if not si:
		fallos += 1
	print("  ", "✔ " if si else "✘ ", texto)

func _ready() -> void:
	await get_tree().process_frame
	# En Android, JavaClassWrapper solo expone métodos de objetos Java: leer un campo de instancia
	# (info.packageName) corta el script sin aviso y el instalador nunca se abre. En PC no hay Java,
	# así que se revisa el código: después de "info." siempre debe venir una llamada.
	var puente := FileAccess.get_file_as_string("res://scripts/actualizaciones/android.gd")
	var campos := RegEx.create_from_string("(?m)^[^#]*\\binfo\\.\\w+\\b(?!\\s*\\()").search_all(puente)
	comprobar(campos.is_empty(), "el puente Android no lee campos de objetos Java (solo métodos)")
	var contenido := "APK de prueba para verificar integridad de la descarga".to_utf8_buffer()
	var m := {"package": "com.jader.elcamino", "version_code": Actualizador.codigo_actual() + 1,
		"version_name": "siguiente", "apk_url": "https://example.com/juego.apk", "size": contenido.size(),
		"sha256": contenido.hex_encode().sha256_text()}
	var hash := HashingContext.new()
	hash.start(HashingContext.HASH_SHA256)
	hash.update(contenido)
	m.sha256 = hash.finish().hex_encode()
	comprobar(Actualizador.validar_manifiesto(m).is_empty(), "acepta manifiesto completo de El Camino")
	for caso in [{"package": "otra.app"}, {"version_code": 1.5}, {"version_code": "12"},
		{"size": 0}, {"size": Actualizador.MAX_APK + 1}, {"sha256": "incorrecto"},
		{"apk_url": "http://example.com/apk"}, {"apk_url": "https://usuario:clave@example.com/apk"},
		{"apk_url": "https://"}]:
		var invalido := m.duplicate()
		invalido.merge(caso, true)
		comprobar(not Actualizador.validar_manifiesto(invalido).is_empty(), "rechaza manifiesto inválido: %s" % caso.keys()[0])
	Actualizador.estado = "consultando"
	Actualizador._consulta_terminada(0, 404, [], PackedByteArray())
	comprobar(Actualizador.estado == "error", "repositorio privado o release ausente produce aviso")
	Actualizador.estado = "consultando"
	Actualizador._consulta_terminada(HTTPRequest.RESULT_CANT_CONNECT, 0, [], PackedByteArray())
	comprobar(Actualizador.estado == "error", "sin conexión se puede reintentar")
	var vieja := m.duplicate()
	vieja.version_code = Actualizador.codigo_actual()
	Actualizador.estado = "consultando"
	Actualizador._consulta_terminada(0, 200, [], JSON.stringify(vieja).to_utf8_buffer())
	comprobar(Actualizador.estado == "actualizado", "no ofrece reinstalar versión igual")
	Actualizador.estado = "consultando"
	Actualizador._consulta_terminada(0, 200, [], JSON.stringify(m).to_utf8_buffer())
	comprobar(Actualizador.estado == "disponible", "ofrece versión posterior")
	comprobar(Actualizador._redireccion("https://github.com/prueba", ["Location: http://example.com/apk"]).is_empty(), "no baja de HTTPS a HTTP en redirecciones")
	comprobar(Actualizador._redireccion("https://github.com/prueba", ["Location: https://release-assets.githubusercontent.com/apk"]).begins_with("https://"), "acepta redirección HTTPS de GitHub")
	_guardar(Actualizador.PARCIAL, contenido.slice(0, 5))
	Actualizador.estado = "descargando"
	Actualizador._descarga_terminada(0, 200, [], PackedByteArray())
	comprobar(Actualizador.estado == "error" and not FileAccess.file_exists(Actualizador.PARCIAL), "descarga incompleta se elimina")
	var alterado := contenido.duplicate()
	alterado[0] = 0
	_guardar(Actualizador.PARCIAL, alterado)
	Actualizador.estado = "descargando"
	Actualizador._descarga_terminada(0, 200, [], PackedByteArray())
	comprobar(Actualizador.estado == "error" and not FileAccess.file_exists(Actualizador.PARCIAL), "huella incorrecta se elimina")
	_guardar(Actualizador.PARCIAL, contenido)
	Actualizador.estado = "descargando"
	Actualizador._descarga_terminada(0, 200, [], PackedByteArray())
	comprobar(Actualizador.estado == "preparado" and FileAccess.file_exists(Actualizador.APK), "archivo íntegro queda listo para instalar")
	Actualizador.nueva = {}
	Actualizador.estado = "listo"
	Actualizador._recuperar()
	comprobar(Actualizador.estado == "preparado" and not Actualizador.nueva.is_empty(), "descarga verificada se recupera después de reiniciar")
	Actualizador.cancelar()
	comprobar(not FileAccess.file_exists(Actualizador.APK) and not FileAccess.file_exists(Actualizador.RECIBO), "permite descartar una descarga pendiente")
	Actualizador.nueva = m
	_guardar(Actualizador.PARCIAL, contenido)
	Actualizador.estado = "descargando"
	Actualizador.cancelar()
	comprobar(Actualizador.estado == "disponible" and not FileAccess.file_exists(Actualizador.PARCIAL), "cancelar limpia archivo parcial y permite reintentar")
	_probar_apertura_instalador(contenido)
	await _probar_guardado()
	if OS.get_cmdline_user_args().has("--red"):
		await _probar_red()
	print("ACTUALIZADOR: %d fallos" % fallos)
	get_tree().quit(fallos)

func _guardar(ruta: String, bytes: PackedByteArray) -> void:
	var archivo := FileAccess.open(ruta, FileAccess.WRITE)
	archivo.store_buffer(bytes)
	archivo.close()

func _probar_apertura_instalador(contenido: PackedByteArray) -> void:
	_guardar(Actualizador.APK, contenido)
	Actualizador._intento_instalar = 7
	Actualizador.estado = "instalando"
	Actualizador._salio_al_instalador = false
	Actualizador._comprobar_apertura(6)
	comprobar(Actualizador.estado == "instalando", "un temporizador antiguo no modifica el intento nuevo")
	Actualizador._comprobar_apertura(7)
	comprobar(Actualizador.estado == "preparado" and FileAccess.file_exists(Actualizador.APK), "si no abre Android, permite reintentar sin borrar el APK")
	Actualizador.estado = "instalando"
	Actualizador._notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
	Actualizador._comprobar_apertura(7)
	comprobar(Actualizador.estado == "instalando", "salir al instalador impide un aviso falso")
	Actualizador._notification(NOTIFICATION_APPLICATION_FOCUS_IN)
	comprobar(Actualizador.estado == "preparado", "volver del instalador permite reintentar")
	Actualizador.cancelar()

func _probar_red() -> void:
	var cert := X509Certificate.new()
	cert.load(OS.get_environment("LUMBRAL_CERT_PRUEBA"))
	Actualizador._consulta.set_tls_options(TLSOptions.client(cert))
	Actualizador._descarga.set_tls_options(TLSOptions.client(cert))
	Actualizador._descarga.request_completed.connect(func(r, c, _h, _b): print("  Respuesta de prueba: ", r, "/", c))
	ProjectSettings.set_setting("actualizaciones/url_versiones", OS.get_environment("LUMBRAL_URL_PRUEBA"))
	Actualizador.buscar()
	var limite := Time.get_ticks_msec() + 10000
	while Actualizador.estado == "consultando" and Time.get_ticks_msec() < limite:
		await get_tree().process_frame
	comprobar(Actualizador.estado == "disponible", "HTTPS real: consulta manifiesto con TLS válido")
	if Actualizador.estado == "disponible":
		Actualizador._iniciar_descarga()
		limite = Time.get_ticks_msec() + 10000
		while Actualizador.estado in ["descargando", "verificando"] and Time.get_ticks_msec() < limite:
			await get_tree().process_frame
		print("  Estado HTTPS: ", Actualizador.estado, " · ", Actualizador.mensaje)
		comprobar(Actualizador.estado == "preparado", "HTTPS real: redirección, descarga y verificación completas")
	Actualizador.cancelar()

## Instalar desde el título nunca debe sobrescribir la partida con el mapa de demostración.
func _probar_guardado() -> void:
	Juego.nueva_partida(false)
	Juego.capitulo = 3
	Juego.guardar_partida()
	var antes := FileAccess.get_sha256(Juego.RUTA_PARTIDA)
	main = load("res://escenas/main.tscn").instantiate()
	add_child(main)
	await get_tree().process_frame
	Actualizador.antes_de_instalar.emit()
	comprobar(FileAccess.get_sha256(Juego.RUTA_PARTIDA) == antes, "actualizar desde el título no sobrescribe el progreso guardado")
	Juego.flags["intro_vista_0"] = true
	main.iniciar_capitulo(0)
	main._mostrar_pausa()
	Juego.luz = 67.0
	Actualizador.antes_de_instalar.emit()
	var cfg := ConfigFile.new()
	cfg.load(Juego.RUTA_PARTIDA)
	comprobar(float(cfg.get_value("partida", "luz", 0.0)) == 67.0, "antes de instalar desde la partida, guarda el progreso actual")
