extends Resource
class_name PlayerInput

var mouse_delta := Vector2.ZERO
var sprinting := false
var enabled := true   # 👈 AGREGADO

func _init():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func get_move_input() -> Vector2:
	if not enabled:
		return Vector2.ZERO

	var x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	var y = Input.get_action_strength("move_backward") - Input.get_action_strength("move_forward")
	return Vector2(x, y)

func is_jump_pressed() -> bool:
	return enabled and Input.is_action_just_pressed("jump")

func is_crouching() -> bool:
	return enabled and Input.is_action_pressed("crouch")

func update_mouse_input(event: InputEvent):
	if not enabled:
		return

	if event is InputEventMouseMotion:
		mouse_delta = event.relative

func consume_mouse_delta() -> Vector2:
	var d = mouse_delta
	mouse_delta = Vector2.ZERO
	return d

func is_sprinting() -> bool:
	return enabled and Input.is_action_pressed("sprint")

func is_roll_pressed() -> bool:
	return enabled and Input.is_action_just_pressed("roll")
