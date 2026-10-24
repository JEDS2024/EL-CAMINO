class_name PanelActualizaciones
extends VBoxContainer
## La descarga vive en el autoload: cerrar Ajustes no interrumpe ni duplica la petición.
var _estado: Label
var _progreso: ProgressBar
var _buscar: Button
var _descargar: Button
var _instalar: Button
var _cancelar: Button
var _externa: Button

func _ready() -> void:
	add_theme_constant_override("separation", 12)
	var titulo := Label.new()
	titulo.text = "Actualizaciones de El Camino"
	titulo.add_theme_font_size_override("font_size", 28)
	titulo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(titulo)
	var version := Label.new()
	version.text = "Versión instalada: " + String(ProjectSettings.get_setting("application/config/version", ""))
	version.add_theme_font_size_override("font_size", 26)
	version.add_theme_color_override("font_color", Color("a9e6a4"))
	version.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(version)
	_estado = Label.new()
	_estado.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_estado.add_theme_font_size_override("font_size", 23)
	add_child(_estado)
	_progreso = ProgressBar.new()
	_progreso.custom_minimum_size.y = 36
	add_child(_progreso)
	_buscar = _boton("Buscar actualizaciones", Actualizador.buscar)
	_descargar = _boton("Descargar actualización", Actualizador.descargar)
	_instalar = _boton("Instalar actualización", Actualizador.instalar)
	_externa = _boton("Abrir APK en el navegador", Actualizador.abrir_descarga_externa)
	_cancelar = _boton("Cancelar", Actualizador.cancelar)
	Actualizador.cambiado.connect(_actualizar)
	_actualizar()

func _boton(texto: String, accion: Callable) -> Button:
	var b := Button.new()
	b.text = texto
	b.custom_minimum_size.y = 68
	b.add_theme_font_size_override("font_size", 26)
	b.pressed.connect(accion)
	add_child(b)
	return b

func _actualizar() -> void:
	var e: String = Actualizador.estado
	_estado.text = Actualizador.mensaje
	if e == "disponible" and OS.get_name() != "Android":
		_estado.text += " Instala el APK en tu dispositivo Android para actualizarlo."
	_progreso.visible = e in ["descargando", "verificando"]
	_progreso.value = Actualizador.progreso * 100
	_buscar.visible = e not in ["consultando", "descargando", "verificando", "instalando", "preparado", "permiso"]
	_descargar.visible = e == "disponible" and OS.get_name() == "Android"
	_instalar.visible = e in ["preparado", "permiso"] and OS.get_name() == "Android"
	_instalar.text = "Permitir instalación y continuar" if e == "permiso" else "Instalar actualización"
	_externa.visible = OS.get_name() == "Android" and not Actualizador.nueva.is_empty() and e in ["disponible", "preparado", "permiso", "error"]
	_cancelar.visible = e in ["consultando", "descargando", "preparado", "permiso"]
	_cancelar.text = "Descartar descarga" if e in ["preparado", "permiso"] else "Cancelar"
