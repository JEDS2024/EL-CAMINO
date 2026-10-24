class_name InstaladorAndroid
extends RefCounted
## Puente a las API nativas mediante AndroidRuntime, incluido en Godot 4.4+.

static func disponible() -> bool:
	return OS.get_name() == "Android" and Engine.has_singleton("AndroidRuntime") and Engine.has_singleton("JavaClassWrapper")

static func actividad() -> Object:
	return Engine.get_singleton("AndroidRuntime").getActivity()

static func clase(nombre: String) -> Object:
	return Engine.get_singleton("JavaClassWrapper").wrap(nombre)

## OJO: JavaClassWrapper solo expone MÉTODOS de los objetos Java y los campos ESTÁTICOS de las clases.
## Leer un campo de instancia (info.packageName, info.versionCode) es un error de script en Android
## que corta la función sin aviso: así la 0.13/0.14 nunca llegaba a abrir el instalador.

static func codigo_instalado() -> int:
	var a := actividad()
	var version: Object = clase("android.os.Build$VERSION")
	if version.SDK_INT < 28:  # getLongVersionCode() no existe; versionCode es un campo, inaccesible
		return int(ProjectSettings.get_setting("actualizaciones/version_code", 0))
	var info: Object = a.getPackageManager().getPackageInfo(a.getPackageName(), 0)
	return int(info.getLongVersionCode())

static func permite_instalar() -> bool:
	var version: Object = clase("android.os.Build$VERSION")
	return version.SDK_INT < 26 or actividad().getPackageManager().canRequestPackageInstalls()

static func abrir_permiso() -> String:
	var a := actividad()
	var Intent: Object = clase("android.content.Intent")
	var Uri: Object = clase("android.net.Uri")
	var intent: Object = Intent.Intent("android.settings.MANAGE_UNKNOWN_APP_SOURCES")
	intent.setData(Uri.parse("package:" + String(a.getPackageName())))
	intent.addFlags(268435456)  # FLAG_ACTIVITY_NEW_TASK
	# startActivity permite esta llamada desde el hilo del juego. Un Runnable
	# devolvía éxito antes de intentar abrir la pantalla y ocultaba sus errores.
	a.startActivity(intent)
	var excepcion: Object = Engine.get_singleton("JavaClassWrapper").get_exception()
	if excepcion != null:
		return "Android no pudo abrir el permiso de instalación: " + String(excepcion.toString())
	return ""

## Rechaza un archivo que no sea APK o una versión que no sea posterior (solo con métodos Java).
## El paquete ya lo garantiza el manifiesto verificado con SHA-256, y Android exige al instalar
## mismo paquete y misma firma; no se desinstala ni se borra la partida.
static func abrir_apk(ruta: String, codigo_esperado: int) -> String:
	var a := actividad()
	var info: Object = a.getPackageManager().getPackageArchiveInfo(ruta, 0)
	if info == null:
		return "El archivo no es un APK válido. Vuelve a descargarlo."
	var version: Object = clase("android.os.Build$VERSION")
	if version.SDK_INT >= 28:
		var codigo := int(info.getLongVersionCode())
		if codigo != codigo_esperado or codigo <= codigo_instalado():
			return "La versión del APK no coincide con la actualización anunciada."
	# GodotIO.openURI ya comparte el archivo mediante FileProvider y asigna su
	# MIME, FLAG_ACTIVITY_NEW_TASK y FLAG_GRANT_READ_URI_PERMISSION. Además
	# captura las excepciones Java y devuelve FAILED si no puede abrirlo.
	# Pasar una ruta absoluta (no content://) permite que conceda el permiso.
	var resultado := OS.shell_open(ruta)
	if resultado != OK:
		return "Android no pudo abrir el instalador (código %d). Puedes abrir el APK desde el navegador." % resultado
	return ""
