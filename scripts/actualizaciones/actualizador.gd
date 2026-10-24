extends Node
## Consulta a petición del usuario. Descargas privadas, TLS y verificación antes de instalar.
signal cambiado
signal antes_de_instalar

const PAQUETE := "com.jader.elcamino"
const CARPETA := "user://actualizaciones"
const PARCIAL := CARPETA + "/descarga.part"
const APK := CARPETA + "/ElCamino.apk"
const RECIBO := CARPETA + "/descarga.json"
const MAX_APK := 250 * 1024 * 1024

var estado := "listo"
var mensaje := "Busca si hay una versión nueva de El Camino."
var nueva := {}
var progreso := 0.0
var _consulta: HTTPRequest
var _descarga: HTTPRequest
var _url_consulta := ""
var _url_descarga := ""
var _saltos_consulta := 0
var _saltos_descarga := 0
var _ultimo_progreso := -1

func _ready() -> void:
	_consulta = HTTPRequest.new()
	_consulta.timeout = 20
	_consulta.body_size_limit = 65536
	_consulta.max_redirects = 0  # comprobar HTTPS también en cada redirección
	_consulta.use_threads = true
	add_child(_consulta)
	_consulta.request_completed.connect(_consulta_terminada)
	_descarga = HTTPRequest.new()
	_descarga.timeout = 600
	_descarga.body_size_limit = MAX_APK
	_descarga.max_redirects = 0
	_descarga.use_threads = true
	_descarga.accept_gzip = false
	add_child(_descarga)
	_descarga.request_completed.connect(_descarga_terminada)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(CARPETA))
	_borrar(PARCIAL)
	_recuperar()

func codigo_actual() -> int:
	if InstaladorAndroid.disponible():
		return InstaladorAndroid.codigo_instalado()
	return int(ProjectSettings.get_setting("actualizaciones/version_code", 11))

func url_versiones() -> String:
	return String(ProjectSettings.get_setting("actualizaciones/url_versiones", ""))

static func url_segura(url: String) -> bool:
	if not url.begins_with("https://") or url.contains("\n") or url.contains("\r") or url.contains(" "):
		return false
	var host := url.substr(8).get_slice("/", 0)
	return not host.is_empty() and not host.contains("@") and not host.begins_with(":")

static func validar_manifiesto(dato: Variant) -> String:
	if not dato is Dictionary:
		return "El servidor no devolvió una versión válida."
	if dato.get("package", "") != PAQUETE:
		return "El anuncio de actualización no pertenece a El Camino."
	var codigo = dato.get("version_code", null)
	var tam = dato.get("size", null)
	if not (codigo is int or codigo is float) or float(codigo) != floorf(float(codigo)) or codigo <= 0 or codigo > 2100000000:
		return "El código de versión no es válido."
	if not (tam is int or tam is float) or float(tam) != floorf(float(tam)) or tam <= 0 or tam > MAX_APK:
		return "El tamaño anunciado del APK no es válido."
	if not dato.get("apk_url", null) is String or not url_segura(dato.apk_url):
		return "La descarga debe usar una dirección HTTPS válida."
	if not dato.get("version_name", null) is String or dato.version_name.is_empty() or dato.version_name.length() > 40:
		return "El nombre de versión no es válido."
	if not dato.get("sha256", null) is String or RegEx.create_from_string("^[a-fA-F0-9]{64}$").search(dato.sha256) == null:
		return "Falta la huella SHA-256 de la actualización."
	return ""

func _cambiar(nuevo_estado: String, texto: String) -> void:
	estado = nuevo_estado
	mensaje = texto
	cambiado.emit()

func buscar() -> void:
	if estado in ["consultando", "descargando", "verificando"]:
		return
	nueva = {}
	_saltos_consulta = 0
	_url_consulta = url_versiones()
	if not url_segura(_url_consulta):
		_cambiar("error", "La dirección pública de actualizaciones todavía no está configurada.")
		return
	_cambiar("consultando", "Buscando actualizaciones…")
	if _consulta.request(_url_consulta, ["Accept: application/json", "Cache-Control: no-cache"]) != OK:
		_cambiar("error", "No se pudo iniciar la consulta. Inténtalo otra vez.")

func _redireccion(url: String, cabeceras: PackedStringArray) -> String:
	for h in cabeceras:
		if h.to_lower().begins_with("location:"):
			var destino := h.substr(h.find(":") + 1).strip_edges()
			# GitHub utiliza redirecciones absolutas. También admite rutas desde la raíz.
			if destino.begins_with("/") and not destino.begins_with("//"):
				destino = "https://" + url.substr(8).get_slice("/", 0) + destino
			return destino if url_segura(destino) else ""
	return ""

func _consulta_terminada(resultado: int, codigo: int, cabeceras: PackedStringArray, cuerpo: PackedByteArray) -> void:
	if estado != "consultando":
		return
	if resultado in [HTTPRequest.RESULT_SUCCESS, HTTPRequest.RESULT_REDIRECT_LIMIT_REACHED] and codigo in [301, 302, 303, 307, 308]:
		_url_consulta = _redireccion(_url_consulta, cabeceras)
		_saltos_consulta += 1
		if _url_consulta.is_empty() or _saltos_consulta > 8 or _consulta.request(_url_consulta) != OK:
			_cambiar("error", "La redirección de versiones no es válida o no se pudo abrir.")
		return
	if resultado != HTTPRequest.RESULT_SUCCESS:
		_cambiar("error", "No se pudo consultar la versión. Revisa tu conexión e inténtalo otra vez.")
		return
	if codigo == 404:
		_cambiar("error", "Todavía no hay una actualización pública disponible en GitHub.")
		return
	if codigo != 200:
		_cambiar("error", "El servidor de versiones no está disponible (HTTP %d)." % codigo)
		return
	var dato: Variant = JSON.parse_string(cuerpo.get_string_from_utf8())
	var error := validar_manifiesto(dato)
	if not error.is_empty():
		_cambiar("error", error)
		return
	if int(dato.version_code) <= codigo_actual():
		_cambiar("actualizado", "Ya tienes la versión más reciente publicada.")
		return
	nueva = dato
	_cambiar("disponible", "Versión %s disponible (%.1f MB)." % [nueva.version_name, float(nueva.size) / 1048576.0])

func descargar() -> void:
	if estado != "disponible" or not validar_manifiesto(nueva).is_empty():
		return
	if OS.get_name() != "Android":
		_cambiar("error", "La instalación de esta actualización APK está disponible en Android.")
		return
	_iniciar_descarga()

func _iniciar_descarga() -> void:
	_borrar(APK)
	_borrar(RECIBO)
	_borrar(PARCIAL)
	progreso = 0
	_saltos_descarga = 0
	_url_descarga = nueva.apk_url
	_descarga.download_file = PARCIAL
	_cambiar("descargando", "Descargando actualización… Puedes cancelar.")
	if _descarga.request(_url_descarga) != OK:
		_cambiar("error", "No se pudo iniciar la descarga.")

func _descarga_terminada(resultado: int, codigo: int, cabeceras: PackedStringArray, _cuerpo: PackedByteArray) -> void:
	if estado != "descargando":
		return
	if resultado in [HTTPRequest.RESULT_SUCCESS, HTTPRequest.RESULT_REDIRECT_LIMIT_REACHED] and codigo in [301, 302, 303, 307, 308]:
		_url_descarga = _redireccion(_url_descarga, cabeceras)
		_saltos_descarga += 1
		_borrar(PARCIAL)
		if _url_descarga.is_empty() or _saltos_descarga > 8 or _descarga.request(_url_descarga) != OK:
			_fallo_descarga("La redirección de descarga no es válida o no se pudo abrir.")
		return
	if resultado != HTTPRequest.RESULT_SUCCESS or codigo != 200:
		_fallo_descarga("La descarga se interrumpió. Revisa tu conexión y vuelve a buscar la actualización.")
		return
	_cambiar("verificando", "Verificando el archivo descargado…")
	if not _archivo_valido(PARCIAL, nueva):
		_fallo_descarga("El archivo está incompleto o su huella no coincide. Se descartó; vuelve a descargarlo.")
		return
	if DirAccess.rename_absolute(ProjectSettings.globalize_path(PARCIAL), ProjectSettings.globalize_path(APK)) != OK:
		_fallo_descarga("No se pudo guardar la actualización. Revisa el espacio disponible.")
		return
	var recibo := FileAccess.open(RECIBO, FileAccess.WRITE)
	if recibo:
		recibo.store_string(JSON.stringify(nueva))
	progreso = 1.0
	_cambiar("preparado", "Descarga verificada. Pulsa Instalar y confirma la actualización en Android.")

func _archivo_valido(ruta: String, manifiesto: Dictionary) -> bool:
	if not validar_manifiesto(manifiesto).is_empty() or not FileAccess.file_exists(ruta):
		return false
	var archivo := FileAccess.open(ruta, FileAccess.READ)
	if archivo == null or archivo.get_length() != int(manifiesto.size):
		return false
	archivo.close()
	return FileAccess.get_sha256(ruta).to_lower() == String(manifiesto.sha256).to_lower()

func cancelar() -> void:
	if estado in ["preparado", "permiso"]:
		_borrar(APK)
		_borrar(RECIBO)
		nueva = {}
	_consulta.cancel_request()
	_descarga.cancel_request()
	_borrar(PARCIAL)
	_cambiar("disponible" if not nueva.is_empty() else "listo", "Operación cancelada. Puedes volver a intentarlo.")

func _fallo_descarga(texto: String) -> void:
	_borrar(PARCIAL)
	_cambiar("error", texto)

func instalar() -> void:
	if estado not in ["preparado", "permiso"] or not InstaladorAndroid.disponible():
		return
	if not _archivo_valido(APK, nueva):
		_borrar(APK)
		_borrar(RECIBO)
		_cambiar("error", "La descarga guardada no es válida. Busca y descarga la versión otra vez.")
		return
	if not InstaladorAndroid.permite_instalar():
		_cambiar("permiso", "Permite que El Camino instale actualizaciones y vuelve aquí para pulsar Instalar.")
		InstaladorAndroid.abrir_permiso()
		return
	antes_de_instalar.emit()
	Juego.guardar_ajustes()
	var error := InstaladorAndroid.abrir_apk(ProjectSettings.globalize_path(APK), int(nueva.version_code))
	if not error.is_empty():
		_cambiar("error", error)
	else:
		_cambiar("instalando", "Confirma Actualizar en el instalador de Android. Tu partida se conserva.")

func _recuperar() -> void:
	if not FileAccess.file_exists(RECIBO):
		return
	var dato: Variant = JSON.parse_string(FileAccess.get_file_as_string(RECIBO))
	if not validar_manifiesto(dato).is_empty() or int(dato.version_code) <= codigo_actual() or not _archivo_valido(APK, dato):
		_borrar(RECIBO)
		_borrar(APK)
		return
	nueva = dato
	_cambiar("preparado", "Hay una descarga verificada pendiente. Puedes instalarla ahora.")

func _borrar(ruta: String) -> void:
	if FileAccess.file_exists(ruta):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(ruta))

func _process(_delta: float) -> void:
	if estado != "descargando":
		return
	progreso = clampf(float(_descarga.get_downloaded_bytes()) / maxf(1, float(nueva.get("size", 1))), 0, 1)
	var porcentaje := int(progreso * 100)
	if porcentaje != _ultimo_progreso:
		_ultimo_progreso = porcentaje
		cambiado.emit()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_IN:
		if estado == "permiso" and InstaladorAndroid.disponible() and InstaladorAndroid.permite_instalar():
			_cambiar("preparado", "Permiso concedido. Pulsa Instalar para continuar.")
		elif estado == "instalando":
			_cambiar("preparado", "Si cancelaste la instalación, puedes volver a intentarlo.")
