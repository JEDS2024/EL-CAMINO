class_name InstaladorAndroid
extends RefCounted
## Puente a las API nativas mediante AndroidRuntime, incluido en Godot 4.4+.

static func disponible() -> bool:
	return OS.get_name() == "Android" and Engine.has_singleton("AndroidRuntime") and Engine.has_singleton("JavaClassWrapper")

static func actividad() -> Object:
	return Engine.get_singleton("AndroidRuntime").getActivity()

static func clase(nombre: String) -> Object:
	return Engine.get_singleton("JavaClassWrapper").wrap(nombre)

static func codigo_instalado() -> int:
	var a := actividad()
	var info: Object = a.getPackageManager().getPackageInfo(a.getPackageName(), 0)
	var version: Object = clase("android.os.Build$VERSION")
	return int(info.getLongVersionCode()) if version.SDK_INT >= 28 else int(info.versionCode)

static func permite_instalar() -> bool:
	var version: Object = clase("android.os.Build$VERSION")
	return version.SDK_INT < 26 or actividad().getPackageManager().canRequestPackageInstalls()

static func abrir_permiso() -> void:
	var a := actividad()
	var Intent: Object = clase("android.content.Intent")
	var Uri: Object = clase("android.net.Uri")
	var intent: Object = Intent.Intent("android.settings.MANAGE_UNKNOWN_APP_SOURCES")
	intent.setData(Uri.parse("package:" + String(a.getPackageName())))
	var runtime := Engine.get_singleton("AndroidRuntime")
	a.runOnUiThread(runtime.createRunnableFromGodotCallable(func(): a.startActivity(intent)))

## Rechaza archivos de otro paquete o una versión que no sea posterior.
## Android valida además la firma al instalar; no se desinstala ni borra la partida.
static func abrir_apk(ruta: String, codigo_esperado: int) -> String:
	var a := actividad()
	var info: Object = a.getPackageManager().getPackageArchiveInfo(ruta, 0)
	if info == null:
		return "El archivo no es un APK válido. Vuelve a descargarlo."
	if String(info.packageName) != String(a.getPackageName()):
		return "Este APK no pertenece a El Camino."
	var version: Object = clase("android.os.Build$VERSION")
	var codigo := int(info.getLongVersionCode()) if version.SDK_INT >= 28 else int(info.versionCode)
	if codigo != codigo_esperado or codigo <= codigo_instalado():
		return "La versión del APK no coincide con la actualización anunciada."
	var File: Object = clase("java.io.File")
	var Provider: Object = clase("androidx.core.content.FileProvider")
	var uri: Object = Provider.getUriForFile(a, String(a.getPackageName()) + ".fileprovider", File.File(ruta))
	if uri == null:
		return "No se pudo compartir el APK con el instalador de Android."
	var Intent: Object = clase("android.content.Intent")
	var intent: Object = Intent.Intent("android.intent.action.VIEW")
	intent.setDataAndType(uri, "application/vnd.android.package-archive")
	intent.addFlags(1)  # FLAG_GRANT_READ_URI_PERMISSION: solo el APK compartido
	# Android 11+ filtra resolveActivity por visibilidad de paquetes. startActivity
	# puede abrir el instalador del sistema sin consultar aplicaciones ajenas.
	var runtime := Engine.get_singleton("AndroidRuntime")
	a.runOnUiThread(runtime.createRunnableFromGodotCallable(func(): a.startActivity(intent)))
	return ""
