class_name PanelActualizaciones
extends VBoxContainer
## La descarga vive en el autoload: cerrar Ajustes no interrumpe ni duplica la petición.
var _estado: Label
var _progreso: ProgressBar
var _buscar: Button
var _descargar: Button
var _instalar: Button
var _cancelar: Button

func _ready() -> void:
	add_theme_constant_override("separation", 12)
	var titulo := Label.new()
	titulo.text = "Actualizaciones · El Camino " + String(ProjectSettings.get_setting("application/config/version", ""))
	titulo.add_theme_font_size_override("font_size", 28)
	titulo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(titulo)
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
	_cancelar.visible = e in ["consultando", "descargando", "preparado", "permiso"]
	_cancelar.text = "Descartar descarga" if e in ["preparado", "permiso"] else "Cancelar"
