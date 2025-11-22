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

	# ----- CÁLCULO DE VELOCIDAD -----
	var current_speed := stats.speed

	if input.is_crouching():
		# agachado: muy lento
		current_speed = stats.speed * stats.crouch_speed_multiplier
	elif input.is_sprinting():
		# sólo sprint si NO está agachado
		current_speed = stats.sprint_speed

	velocity.x = direction3D.x * current_speed
	velocity.z = direction3D.z * current_speed

	if input.is_roll_pressed():
		# pequeño dash hacia adelante
		velocity += direction3D * stats.roll_boost_speed

	
	if not player.is_on_floor():
		velocity.y -= stats.gravity * delta
	else:
		if input.is_jump_pressed():
			velocity.y = stats.jump_force

	player.velocity = velocity
	player.move_and_slide()
