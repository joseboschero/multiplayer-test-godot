extends Resource
class_name PlayerCamera

@export var mouse_sensitivity: float = 0.002
@export var rotation_x := 0.0

# --- Camera Bobbing ---
@export var bob_amount := 0.05
@export var bob_speed_walk := 7.0
@export var bob_speed_sprint := 11.0
@export var bob_timer := 0.0
var base_position := Vector3.ZERO
# -----------------------

func update(player: CharacterBody3D, input: PlayerInput, delta: float):
	var mouse = input.consume_mouse_delta()

	player.rotate_y(-mouse.x * mouse_sensitivity)
	rotation_x = clamp(rotation_x - mouse.y * mouse_sensitivity, -1.5, 1.5)

	var cam = player.get_node("Camera3D")
	cam.rotation.x = rotation_x

	# -------------------------
	#      CAMERA BOBBING
	# -------------------------
	
	if base_position == Vector3.ZERO:
		base_position = cam.position

	var move_input := input.get_move_input()
	var is_moving := move_input.length() > 0.1 and player.is_on_floor()

	var speed = bob_speed_walk
	if input.is_sprinting():
		speed = bob_speed_sprint

	if is_moving:
		bob_timer += delta * speed
		var offset = sin(bob_timer) * bob_amount
		cam.position.x = base_position.x + offset
	else:
		cam.position.y = lerp(cam.position.y, base_position.y, delta * 10.0)
