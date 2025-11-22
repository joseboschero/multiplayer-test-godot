extends Resource
class_name PlayerMovement

var velocity := Vector3.ZERO

func update(player: CharacterBody3D, input: PlayerInput, stats: PlayerStats, delta: float):
	var direction2D = input.get_move_input()

	var forward = player.global_transform.basis.z
	var right = player.global_transform.basis.x

	forward.y = 0
	right.y = 0
	forward = forward.normalized()
	right = right.normalized()

	var direction3D = (forward * direction2D.y) + (right * direction2D.x)
	direction3D = direction3D.normalized()

	velocity.x = direction3D.x * stats.speed
	velocity.z = direction3D.z * stats.speed

	if not player.is_on_floor():
		velocity.y -= stats.gravity * delta
	else:
		if input.is_jump_pressed():
			velocity.y = stats.jump_force

	player.velocity = velocity
	player.move_and_slide()
