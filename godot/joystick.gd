extends Control
var player: CharacterBody3D
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
func _process(_delta: float) -> void:
	queue_redraw()
func _draw() -> void:
	if not is_instance_valid(player):
		return
	var center: Vector2 = player.joystick_center()
	draw_circle(center, 72, Color(0.08, 0.18, 0.17, 0.65))
	draw_arc(center, 72, 0, TAU, 64, Color(0.89, 0.76, 0.5, 0.8), 2)
	draw_circle(center + player.touch_move * 45, 26, Color(0.89, 0.76, 0.5, 0.85))
