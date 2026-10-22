extends Node
## Música y efectos (autoload "Sonido"). La música cambia con un fundido suave.
## Los archivos están en assets/audio y se generan con herramientas/generar_audio.py.

const VOLUMEN_MUSICA_DB := -8.0

var _musica: AudioStreamPlayer
var _ambiente: AudioStreamPlayer
var _ambiente_actual := ""
var _actual := ""
var _efectos: Array[AudioStreamPlayer] = []
var _cache := {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_musica = AudioStreamPlayer.new()
	add_child(_musica)
	_ambiente = AudioStreamPlayer.new()
	add_child(_ambiente)
	for i in 6:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_efectos.append(p)
	Juego.estado_cambiado.connect(aplicar_volumenes)
	aplicar_volumenes()


func _cargar(ruta: String) -> AudioStream:
	if not _cache.has(ruta):
		_cache[ruta] = load(ruta) if ResourceLoader.exists(ruta) else null
	return _cache[ruta]


func aplicar_volumenes() -> void:
	if _actual != "":
		_musica.volume_db = VOLUMEN_MUSICA_DB + linear_to_db(maxf(Juego.vol_musica, 0.001))
	_ambiente.volume_db = -10.0 + linear_to_db(maxf(Juego.vol_efectos, 0.001))


## Sonido de fondo del lugar (viento, pájaros, grillos, ciudad). "" lo apaga.
func tocar_ambiente(nombre: String) -> void:
	if nombre == _ambiente_actual:
		return
	_ambiente_actual = nombre
	var stream := _cargar("res://assets/audio/amb_%s.ogg" % nombre) as AudioStreamOggVorbis
	if stream == null:
		_ambiente.stop()
		return
	stream.loop = true
	_ambiente.stream = stream
	_ambiente.volume_db = -40.0
	_ambiente.play()
	create_tween().tween_property(_ambiente, "volume_db", -10.0 + linear_to_db(maxf(Juego.vol_efectos, 0.001)), 2.0)


func tocar_musica(nombre: String) -> void:
	if nombre == _actual:
		return
	_actual = nombre
	var stream := _cargar("res://assets/audio/musica_%s.ogg" % nombre) as AudioStreamOggVorbis
	if stream == null:
		return
	stream.loop = true
	var destino := VOLUMEN_MUSICA_DB + linear_to_db(maxf(Juego.vol_musica, 0.001))
	var t := create_tween()
	if _musica.playing:
		t.tween_property(_musica, "volume_db", -40.0, 0.8)
	t.tween_callback(func():
		_musica.stream = stream
		_musica.volume_db = -40.0
		_musica.play())
	t.tween_property(_musica, "volume_db", destino, 1.2)


func efecto(nombre: String, volumen := 1.0) -> void:
	if Juego.vol_efectos <= 0.01:
		return
	var stream := _cargar("res://assets/audio/sfx_%s.ogg" % nombre)
	if stream == null:
		return
	for p in _efectos:
		if not p.playing:
			p.stream = stream
			p.volume_db = linear_to_db(maxf(Juego.vol_efectos * volumen, 0.001))
			p.play()
			return
