extends CharacterBody3D
## Cámara libre y desplazamiento compartido por ambas perspectivas.
var active := false
var first_person := false
var yaw := 0.0
var pitch := -0.12
var touch_move := Vector2.ZERO
var move_finger := -1
var look_finger := -1
var pivot: Node3D
var arm: SpringArm3D
var camera: Camera3D
var model: Node3D
const SPEED := 4.0

func _ready() -> void:
	collision_layer = 1
	collision_mask = 1
	var collider := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.28
	capsule.height = 1.72
	collider.shape = capsule
	collider.position.y = 0.86
	add_child(collider)
	pivot = Node3D.new()
	pivot.position.y = 1.55
	add_child(pivot)
	arm = SpringArm3D.new()
	arm.collision_mask = 1
	arm.margin = 0.15
	arm.add_excluded_object(get_rid())
	pivot.add_child(arm)
	camera = Camera3D.new()
	camera.near = 0.08
	camera.fov = 72
	arm.add_child(camera)
	camera.current = true
	set_camera_mode(false)

func set_camera_mode(first: bool) -> void:
	first_person = first
	if is_instance_valid(arm):
		arm.spring_length = 0.0 if first else 3.8
	if is_instance_valid(model):
		model.visible = not first

func stop_input() -> void:
	touch_move = Vector2.ZERO
	move_finger = -1
	look_finger = -1
	velocity = Vector3.ZERO
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func joystick_center() -> Vector2:
	return Vector2(110, get_viewport().get_visible_rect().size.y - 110)

func _input(event: InputEvent) -> void:
	if not active:
		return
	var size := get_viewport().get_visible_rect().size
	if event is InputEventScreenTouch:
		if event.pressed:
			if event.position.distance_to(joystick_center()) < 95 and move_finger == -1:
				move_finger = event.index
				touch_move = ((event.position - joystick_center()) / 60.0).limit_length()
			elif event.position.x > size.x * 0.45 and event.position.y > 90 and event.position.y < size.y - 150:
				look_finger = event.index
		else:
			if event.index == move_finger:
				move_finger = -1
				touch_move = Vector2.ZERO
			if event.index == look_finger:
				look_finger = -1
	elif event is InputEventScreenDrag:
		if event.index == move_finger:
			touch_move = ((event.position - joystick_center()) / 60.0).limit_length()
		elif event.index == look_finger:
			look(event.relative * 0.004)

func _unhandled_input(event: InputEvent) -> void:
	if not active:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		look(event.relative * 0.0025)

func look(delta: Vector2) -> void:
	yaw -= delta.x
	pitch = clampf(pitch - delta.y, -1.12, 0.75)

func _physics_process(delta: float) -> void:
	pivot.rotation = Vector3(pitch, yaw, 0)
	if not active:
		return
	var axis := touch_move
	if Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP):
		axis.y -= 1
	if Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN):
		axis.y += 1
	if Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT):
		axis.x -= 1
	if Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT):
		axis.x += 1
	axis = axis.limit_length()
	var direction := Basis(Vector3.UP, yaw) * Vector3(axis.x, 0, axis.y)
	velocity.x = direction.x * SPEED
	velocity.z = direction.z * SPEED
	if not is_on_floor():
		velocity.y -= 18.0 * delta
	else:
		velocity.y = 0
	move_and_slide()
	if model and direction.length_squared() > 0.01:
		model.rotation.y = lerp_angle(model.rotation.y, atan2(-direction.x, -direction.z), delta * 12)

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		stop_input()
