extends Resource
class_name PlayerCamera

@export var mouse_sensitivity: float = 0.002
var rotation_x := 0.0

func update(player: CharacterBody3D, input: PlayerInput, delta: float):
	var mouse = input.consume_mouse_delta()

	# Rotar el cuerpo (yaw)
	player.rotate_y(-mouse.x * mouse_sensitivity)

	# Rotar la cámara (pitch)
	rotation_x = clamp(rotation_x - mouse.y * mouse_sensitivity, -1.5, 1.5)

	var cam = player.get_node("Camera3D")
	cam.rotation.x = rotation_x
