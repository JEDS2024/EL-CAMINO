class_name Jugador
extends CharacterBody3D
## El protagonista del capítulo. Se mueve relativo a la cámara y puede verse en primera o
## tercera persona. Lleva un candil cuya luz crece con las buenas decisiones.

const VELOCIDAD := 4.6
const GRAVEDAD := 20.0
const ALTURA_OJOS := 1.55
const DISTANCIA_3P := 3.6

var yaw := 0.0
var pitch := -0.3
var bloqueado := false
var clave_modelo := "david"
var entrada_tactil := Vector2.ZERO

var pivote: Node3D
var brazo: SpringArm3D
var camara: Camera3D
var modelo: Personaje3D
var candil: OmniLight3D


func _ready() -> void:
	var forma := CollisionShape3D.new()
	var capsula := CapsuleShape3D.new()
	capsula.radius = 0.35
	capsula.height = 1.6
	forma.shape = capsula
	forma.position.y = 0.8
	add_child(forma)

	modelo = Personaje3D.new()
	add_child(modelo)
	modelo.configurar(clave_modelo)

	pivote = Node3D.new()
	add_child(pivote)
	brazo = SpringArm3D.new()
	var esfera := SphereShape3D.new()
	esfera.radius = 0.25
	brazo.shape = esfera
	brazo.add_excluded_object(get_rid())
	pivote.add_child(brazo)
	camara = Camera3D.new()
	camara.fov = 72.0
	camara.near = 0.08
	camara.far = 90.0
	brazo.add_child(camara)
	camara.current = true

	candil = OmniLight3D.new()
	candil.light_color = Color("ffc978")
	candil.light_energy = 1.4
	candil.position = Vector3(0.0, 2.3, -0.7)  # alta y adelantada: a un lado del cuello quemaba la piel y la ropa
	add_child(candil)

	aplicar_vista(Juego.primera_persona, false)
	Juego.estado_cambiado.connect(_actualizar_candil)
	_actualizar_candil()


func aplicar_vista(primera: bool, animar := true) -> void:
	Juego.primera_persona = primera
	modelo.visible = not primera
	var altura := ALTURA_OJOS if primera else 1.7
	var largo := 0.0 if primera else DISTANCIA_3P
	if not primera and pitch > -0.1:
		pitch = -0.3
	if animar:
		var t := create_tween().set_parallel().set_trans(Tween.TRANS_SINE)
		t.tween_property(brazo, "spring_length", largo, 0.35)
		t.tween_property(pivote, "position:y", altura, 0.35)
	else:
		brazo.spring_length = largo
		pivote.position.y = altura


func mirar(delta_px: Vector2) -> void:
	var s := 0.0045 * Juego.sensibilidad
	yaw -= delta_px.x * s
	var limite_inf := -1.2 if Juego.primera_persona else -1.05
	var limite_sup := 1.1 if Juego.primera_persona else 0.35
	pitch = clampf(pitch - delta_px.y * s, limite_inf, limite_sup)


func _actualizar_candil() -> void:
	var t := create_tween()
	t.tween_property(candil, "omni_range", 5.0 + Juego.luz * 0.09, 0.8)


func _physics_process(delta: float) -> void:
	var entrada := Vector2.ZERO
	if not bloqueado:
		entrada = Input.get_vector("mover_izquierda", "mover_derecha", "mover_arriba", "mover_abajo") + entrada_tactil
		entrada = entrada.limit_length(1.0)
	var dir := Basis(Vector3.UP, yaw) * Vector3(entrada.x, 0, entrada.y)
	# acelera y frena con suavidad (más rápido al frenar, para que responda bien)
	var objetivo := Vector2(dir.x, dir.z) * VELOCIDAD
	var actual := Vector2(velocity.x, velocity.z)
	actual = actual.move_toward(objetivo, (26.0 if objetivo.length() > 0.1 else 34.0) * delta)
	velocity.x = actual.x
	velocity.z = actual.y
	if is_on_floor():
		velocity.y = -0.5
	else:
		velocity.y -= GRAVEDAD * delta
	move_and_slide()
	if not bloqueado:
		var giro := Input.get_vector("mirar_izquierda", "mirar_derecha", "mirar_arriba", "mirar_abajo")
		if giro != Vector2.ZERO:
			mirar(giro * 520.0 * delta)
	var plano := Vector3(velocity.x, 0, velocity.z)
	modelo.actualizar(delta, plano if plano.length() > 0.3 else Vector3.ZERO, plano.length() > 0.6)
	# un leve parpadeo de la llama
	candil.light_energy = 1.35 + sin(Time.get_ticks_msec() * 0.011) * 0.06


func _process(_delta: float) -> void:
	pivote.rotation.y = yaw
	brazo.rotation.x = pitch
	if not Juego.primera_persona:
		# con la cámara pegada a una pared el personaje taparía la pantalla: se oculta (con margen para que no parpadee)
		var cerca := brazo.get_hit_length() < (2.5 if not modelo.visible else 2.2)
		modelo.visible = not cerca
