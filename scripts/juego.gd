extends Node
## Estado global de la partida (autoload "Juego"): virtudes, luz del candil, decisiones,
## objetos, ajustes y guardado. También evalúa condiciones y aplica efectos de la historia.

signal estado_cambiado
signal aviso(texto: String, icono: String)
signal clima_cambiado(tipo: String)

const VIRTUDES := ["fe", "esperanza", "amor", "perdon"]
const NOMBRE_VIRTUD := {"fe": "Fe", "esperanza": "Esperanza", "amor": "Amor", "perdon": "Perdón"}
const CAPITULOS := [
	"res://datos/capitulos/cap0_noe.json",
	"res://datos/capitulos/cap1_jose.json",
	"res://datos/capitulos/cap2_rut.json",
	"res://datos/capitulos/cap3_david.json",
	"res://datos/capitulos/cap4_nehemias.json",
	"res://datos/capitulos/cap5_emaus.json",
]
const RUTA_PARTIDA := "user://partida.cfg"
const RUTA_AJUSTES := "user://ajustes.cfg"

var primera_persona := false
var sensibilidad := 1.0
var vol_musica := 0.8
var vol_efectos := 0.9
var leer_voz := false  # leer los diálogos en voz alta (ideal para niños)
var voz_lectura := ""  # identificador de voz instalado; vacío usa la preferencia española
var ritmo_voz := 1.0
var texto_grande := false
var guia := true  # faro sobre el siguiente objetivo y «!» en personajes
var capitulo := 0
var virtudes := {}
var luz := 30.0
var flags := {}
var contadores := {}
var objetos: Array = []
var secretos := 0
var capitulo_max := 0  # el capítulo más avanzado desbloqueado
var completados: Array = []
var estrellas := {}  # índice de capítulo (texto) -> mejor resultado del repaso (0-3)
## Lo que cada capítulo cambió (flags, virtudes, contadores...) para poder rejugarlo desde cero.
var registro := {}
## Un diálogo pidió terminar el capítulo (efecto fin_capitulo); main lo atiende al cerrarlo.
var fin_pedido := false
## Un diálogo pidió un minijuego (efecto minijuego): {"tipo": "honda", "exito": id de diálogo}.
var minijuego_pedido := {}


func _ready() -> void:
	_registrar_acciones()
	_reiniciar_estado()
	cargar_ajustes()


func _registrar_acciones() -> void:
	var mapa := {
		"mover_arriba": [KEY_W], "mover_abajo": [KEY_S],
		"mover_izquierda": [KEY_A], "mover_derecha": [KEY_D],
		"mirar_izquierda": [KEY_LEFT, KEY_J], "mirar_derecha": [KEY_RIGHT, KEY_L],
		"mirar_arriba": [KEY_UP, KEY_I], "mirar_abajo": [KEY_DOWN, KEY_K],
		"interactuar": [KEY_E, KEY_SPACE, KEY_ENTER], "cambiar_vista": [KEY_C, KEY_V],
		"pausa": [KEY_ESCAPE, KEY_P], "mochila": [KEY_TAB, KEY_B],
		"picar": [KEY_Q, KEY_X], "poner": [KEY_F, KEY_R],
	}
	for i in 9:
		mapa["casilla_%d" % (i + 1)] = [KEY_1 + i]
	for accion in mapa:
		if InputMap.has_action(accion):
			continue
		InputMap.add_action(accion)
		for tecla in mapa[accion]:
			var ev := InputEventKey.new()
			ev.physical_keycode = tecla
			InputMap.action_add_event(accion, ev)


func _reiniciar_estado() -> void:
	capitulo = 0
	virtudes = {"fe": 0, "esperanza": 0, "amor": 0, "perdon": 0}
	luz = 30.0
	flags = {}
	contadores = {}
	objetos = []
	secretos = 0
	capitulo_max = 0
	completados = []
	estrellas = {}
	registro = {}


func nueva_partida(usar_primera_persona: bool) -> void:
	_reiniciar_estado()
	primera_persona = usar_primera_persona
	guardar_ajustes()
	guardar_partida()


# ------------------------------------------------------------------ condiciones y efectos
## Todas las condiciones de la lista deben cumplirse. Formatos:
## "flag:x", "!flag:x", "obj:x", "!obj:x", "cont:x>=3", "fe>=2", "luz>=50"
func cumple(condiciones) -> bool:
	if condiciones == null:
		return true
	if condiciones is String:
		condiciones = [condiciones]
	for c in condiciones:
		if not _cumple_una(String(c)):
			return false
	return true


func _cumple_una(c: String) -> bool:
	var negar := c.begins_with("!")
	if negar:
		c = c.substr(1)
	var r := false
	if c.begins_with("flag:"):
		r = flags.get(c.substr(5), false)
	elif c.begins_with("obj:"):
		r = objetos.has(c.substr(4))
	else:
		var partes := c.replace("cont:", "").split(">=")
		if partes.size() == 2:
			var nombre := partes[0].strip_edges()
			var valor := 0.0
			if nombre == "luz":
				valor = luz
			elif virtudes.has(nombre):
				valor = virtudes[nombre]
			else:
				valor = contadores.get(nombre, 0)
			r = valor >= float(partes[1])
		else:
			push_warning("Condición desconocida: " + c)
	return r != negar


func _reg() -> Dictionary:
	var k := str(capitulo)
	if not registro.has(k):
		registro[k] = {"flags": [], "virtudes": {}, "contadores": {}, "objetos": [], "secretos": 0, "luz": 0.0, "inventario": {}}
	if not registro[k].has("inventario"):
		registro[k]["inventario"] = {}
	return registro[k]


## Objetos recogidos en el capítulo actual: clave -> {icono, nombre, cantidad, reliquia}.
func inventario_capitulo() -> Dictionary:
	return _reg()["inventario"]


## Bloques de construcción que lleva el jugador en este capítulo (van en la barra como objetos).
func cantidad_bloque(material: String) -> int:
	return int(inventario_capitulo().get("bloque_" + material, {}).get("cantidad", 0))


func sumar_bloque(material: String, n: int) -> void:
	var inv := inventario_capitulo()
	var clave := "bloque_" + material
	if not inv.has(clave):
		var info: Dictionary = Construccion.MATERIALES.get(material, {})
		inv[clave] = {"icono": info.get("icono", "bloque_piedra"), "nombre": info.get("nombre", material), "cantidad": 0,
			"reliquia": false, "bloque": material}
	inv[clave]["cantidad"] += n
	if inv[clave]["cantidad"] <= 0:
		inv.erase(clave)
	estado_cambiado.emit()


## Reliquias (secretos) encontradas en todos los capítulos.
func reliquias() -> Array:
	var lista := []
	for k in registro:
		for clave_inv in registro[k].get("inventario", {}):
			var o: Dictionary = registro[k]["inventario"][clave_inv]
			if o.get("reliquia", false):
				lista.append({"icono": o.get("icono", "luz"), "nombre": o["nombre"]})
	return lista


## Pone una marca y la anota en el registro del capítulo actual.
func marcar(flag: String) -> void:
	if not flags.get(flag, false):
		flags[flag] = true
		_reg()["flags"].append(flag)


## Deshace todo lo que el capítulo i había cambiado, para jugarlo otra vez.
func reiniciar_capitulo(i: int) -> void:
	var r: Dictionary = registro.get(str(i), {})
	for f in r.get("flags", []):
		flags.erase(f)
	for v in r.get("virtudes", {}):
		virtudes[v] -= r["virtudes"][v]
	for c in r.get("contadores", {}):
		contadores[c] = contadores.get(c, 0) - r["contadores"][c]
	for o in r.get("objetos", []):
		objetos.erase(o)
	secretos -= int(r.get("secretos", 0))
	luz = clampf(luz - float(r.get("luz", 0.0)), 0.0, 100.0)
	registro.erase(str(i))
	completados.erase(i)


func aplicar(efectos) -> void:
	if efectos == null or not (efectos is Dictionary):
		return
	var reg := _reg()
	for clave in efectos:
		var v = efectos[clave]
		if clave in VIRTUDES:
			virtudes[clave] += int(v)
			reg["virtudes"][clave] = reg["virtudes"].get(clave, 0) + int(v)
			if int(v) > 0:
				aviso.emit("+%d %s" % [int(v), NOMBRE_VIRTUD[clave]], clave)
		elif clave == "luz":
			var antes := luz
			luz = clampf(luz + float(v), 0.0, 100.0)
			reg["luz"] += luz - antes
			if float(v) > 0:
				aviso.emit("La luz de tu candil crece", "luz")
		elif clave == "flag":
			for f in (v if v is Array else [v]):
				marcar(String(f))
		elif clave == "quitar_flag":
			for f in (v if v is Array else [v]):
				flags.erase(String(f))
		elif clave == "sumar":
			for nombre in v:
				contadores[nombre] = contadores.get(nombre, 0) + int(v[nombre])
				reg["contadores"][nombre] = reg["contadores"].get(nombre, 0) + int(v[nombre])
		elif clave == "objeto":
			if not objetos.has(v):
				objetos.append(v)
				reg["objetos"].append(v)
		elif clave == "secreto":
			secretos += 1
			reg["secretos"] += 1
			aviso.emit("¡Secreto encontrado!", "luz")
		elif clave == "recoger":
			var inv: Dictionary = reg["inventario"]
			# las reliquias van aparte (por su id); lo demás se agrupa por ícono
			var clave_inv := String(v.get("clave", v.get("icono", "luz")))
			if not inv.has(clave_inv):
				inv[clave_inv] = {"icono": v.get("icono", "luz"), "nombre": v.get("nombre", clave_inv), "cantidad": 0,
					"reliquia": v.get("reliquia", false)}
			inv[clave_inv]["cantidad"] += 1
		elif clave == "minijuego":
			minijuego_pedido = v
		elif clave == "fin_capitulo":
			fin_pedido = true
		elif clave == "aviso":
			aviso.emit(String(v), "")
		elif clave == "clima":
			clima_cambiado.emit(String(v))
	estado_cambiado.emit()


func virtud_mayor() -> String:
	var mejor := "amor"
	for v in VIRTUDES:
		if virtudes[v] > virtudes[mejor]:
			mejor = v
	return mejor


# ------------------------------------------------------------------ datos
func datos_capitulo(i: int) -> Dictionary:
	var texto := FileAccess.get_file_as_string(CAPITULOS[i])
	var d = JSON.parse_string(texto)
	if d == null:
		push_error("No se pudo leer " + CAPITULOS[i])
		return {}
	return d


# ------------------------------------------------------------------ guardado
func hay_partida() -> bool:
	return FileAccess.file_exists(RUTA_PARTIDA)


func guardar_partida() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("partida", "capitulo", capitulo)
	cfg.set_value("partida", "virtudes", virtudes)
	cfg.set_value("partida", "luz", luz)
	cfg.set_value("partida", "flags", flags)
	cfg.set_value("partida", "contadores", contadores)
	cfg.set_value("partida", "objetos", objetos)
	cfg.set_value("partida", "secretos", secretos)
	for clave in ["capitulo_max", "completados", "estrellas", "registro"]:
		cfg.set_value("partida", clave, get(clave))
	cfg.set_value("partida", "version", 2)
	cfg.save(RUTA_PARTIDA)


func cargar_partida() -> bool:
	var cfg := ConfigFile.new()
	if cfg.load(RUTA_PARTIDA) != OK:
		return false
	if int(cfg.get_value("partida", "version", 1)) < 2:
		_migrar_indices_a_noe(cfg)
	capitulo = cfg.get_value("partida", "capitulo", 0)
	virtudes = cfg.get_value("partida", "virtudes", virtudes)
	luz = cfg.get_value("partida", "luz", 30.0)
	flags = cfg.get_value("partida", "flags", {})
	contadores = cfg.get_value("partida", "contadores", {})
	objetos = cfg.get_value("partida", "objetos", [])
	secretos = cfg.get_value("partida", "secretos", 0)
	for clave in ["capitulo_max", "completados", "estrellas", "registro"]:
		set(clave, cfg.get_value("partida", clave, get(clave)))
	return true


## Noé se inserta al principio; conserva el progreso anterior desplazando sus índices.
func _migrar_indices_a_noe(cfg: ConfigFile) -> void:
	var p := "partida"
	cfg.set_value(p, "capitulo", int(cfg.get_value(p, "capitulo", 0)) + 1)
	cfg.set_value(p, "capitulo_max", int(cfg.get_value(p, "capitulo_max", 0)) + 1)
	var completados_viejos: Array = cfg.get_value(p, "completados", [])
	var completados_nuevos: Array = []
	for i in completados_viejos:
		completados_nuevos.append(int(i) + 1)
	cfg.set_value(p, "completados", completados_nuevos)
	var estrellas_viejas: Dictionary = cfg.get_value(p, "estrellas", {})
	var estrellas_nuevas := {}
	for i in estrellas_viejas:
		estrellas_nuevas[str(int(i) + 1)] = estrellas_viejas[i]
	cfg.set_value(p, "estrellas", estrellas_nuevas)
	var registro_viejo: Dictionary = cfg.get_value(p, "registro", {})
	var registro_nuevo := {}
	for i in registro_viejo:
		registro_nuevo[str(int(i) + 1)] = registro_viejo[i]
	cfg.set_value(p, "registro", registro_nuevo)
	var flags_viejas: Dictionary = cfg.get_value(p, "flags", {})
	var flags_nuevas := {}
	for f in flags_viejas:
		var nombre := String(f)
		if nombre.begins_with("intro_vista_"):
			var indice := nombre.substr("intro_vista_".length())
			nombre = "intro_vista_%d" % (int(indice) + 1)
		flags_nuevas[nombre] = flags_viejas[f]
	cfg.set_value(p, "flags", flags_nuevas)
	cfg.set_value(p, "version", 2)
	cfg.save(RUTA_PARTIDA)


func guardar_ajustes() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("ajustes", "primera_persona", primera_persona)
	cfg.set_value("ajustes", "sensibilidad", sensibilidad)
	for clave in ["vol_musica", "vol_efectos", "leer_voz", "voz_lectura", "ritmo_voz", "texto_grande", "guia"]:
		cfg.set_value("ajustes", clave, get(clave))
	cfg.save(RUTA_AJUSTES)


func cargar_ajustes() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(RUTA_AJUSTES) == OK:
		primera_persona = cfg.get_value("ajustes", "primera_persona", false)
		sensibilidad = cfg.get_value("ajustes", "sensibilidad", 1.0)
		for clave in ["vol_musica", "vol_efectos", "leer_voz", "voz_lectura", "ritmo_voz", "texto_grande", "guia"]:
			set(clave, cfg.get_value("ajustes", clave, get(clave)))
