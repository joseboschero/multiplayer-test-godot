extends Resource
class_name PlayerMovement

var velocity := Vector3.ZERO

# Dash state
var is_dashing: bool = false
var dash_time_left: float = 0.0
var dash_cooldown_left: float = 0.0
var dash_direction: Vector3 = Vector3.ZERO

# External impulses
var external_impulse: Vector3 = Vector3.ZERO

# Ground slam
var is_ground_slamming: bool = false
var slam_force: float = 30.0  # Fuerza de caída
var slam_radius: float = 10.0  # Radio de efecto
var slam_impulse_strength: float = 15.0  # Fuerza del impulso a enemigos
var was_in_air: bool = false

func update(player: CharacterBody3D, input: PlayerInput, stats: PlayerStats, delta: float):
	# Actualizar detección de doble toque
	input.update_dash_detection(delta)

	# Actualizar cooldown del dash
	if dash_cooldown_left > 0:
		dash_cooldown_left -= delta

	# Verificar si se solicita dash
	if input.is_dash_requested() and dash_cooldown_left <= 0 and not is_dashing:
		# Iniciar dash en la dirección hacia adelante
		var forward = player.global_transform.basis.z
		forward.y = 0
		forward = forward.normalized()

		# Guardar la dirección del dash (hacia adelante del jugador)
		dash_direction = -forward  # Negativo porque basis.z apunta hacia atrás
		is_dashing = true
		dash_time_left = stats.dash_duration
		dash_cooldown_left = stats.dash_cooldown

	# Actualizar tiempo de dash
	if is_dashing:
		dash_time_left -= delta
		if dash_time_left <= 0:
			is_dashing = false

	# Calcular dirección de movimiento
	var direction2D = input.get_move_input()

	var forward = player.global_transform.basis.z
	var right = player.global_transform.basis.x

	forward.y = 0
	right.y = 0
	forward = forward.normalized()
	right = right.normalized()

	var direction3D = (forward * direction2D.y) + (right * direction2D.x)
	direction3D = direction3D.normalized()

	# Aplicar movimiento
	if is_dashing:
		# Durante el dash, aplicar velocidad del dash
		velocity.x = dash_direction.x * stats.dash_speed
		velocity.z = dash_direction.z * stats.dash_speed
	else:
		# Movimiento normal
		velocity.x = direction3D.x * stats.speed
		velocity.z = direction3D.z * stats.speed

	# Actualizar carga del salto
	input.update_jump_charge(delta, stats.max_jump_charge_time)

	# Actualizar detección de ground slam
	input.update_ground_slam_input()

	# Ground slam - activar si está en el aire y presiona F
	if input.is_ground_slam_pressed() and not player.is_on_floor():
		is_ground_slamming = true
		print("¡Ground Slam activado!")

	# Rastrear si estaba en el aire
	if not player.is_on_floor():
		was_in_air = true

	# Gravedad y salto
	if not player.is_on_floor():
		if is_ground_slamming:
			# Durante el slam, aplicar fuerza hacia abajo
			velocity.y = -slam_force
		else:
			velocity.y -= stats.gravity * delta
	else:
		# Detectar impacto del ground slam
		if is_ground_slamming and was_in_air:
			# Impacto! Activar explosión
			ground_slam_impact(player)
			is_ground_slamming = false

		was_in_air = false

		# Super salto con carga (solo si no está haciendo slam)
		if not is_ground_slamming and input.is_jump_released():
			var charge_time = input.get_jump_charge_percent()
			var charge_percent = charge_time / stats.max_jump_charge_time

			# Interpolar entre salto normal y salto máximo
			var jump_strength = lerp(stats.jump_force, stats.max_jump_force, charge_percent)
			velocity.y = jump_strength

			# Resetear la carga
			input.reset_jump_charge()

	# Aplicar impulsos externos (solo una vez)
	if external_impulse.length() > 0:
		velocity += external_impulse
		external_impulse = Vector3.ZERO  # Limpiar inmediatamente después de aplicar

	player.velocity = velocity
	player.move_and_slide()

func apply_impulse(impulse: Vector3):
	external_impulse += impulse

func ground_slam_impact(player: CharacterBody3D):
	print("¡IMPACTO DE GROUND SLAM!")

	# Obtener todos los nodos dañables (jugadores y enemigos)
	var all_nodes = player.get_tree().get_nodes_in_group("damageable")

	var targets_hit = 0

	for node in all_nodes:
		# No afectarse a sí mismo
		if node == player:
			continue

		# Verificar que es un CharacterBody3D con posición
		if node is CharacterBody3D or node is RigidBody3D:
			# Calcular distancia
			var distance = player.global_position.distance_to(node.global_position)

			if distance <= slam_radius:
				# Objetivo dentro del radio
				targets_hit += 1

				# Calcular dirección desde el jugador hacia el objetivo (horizontal + arriba)
				var direction = (node.global_position - player.global_position)
				direction.y = 0  # Eliminar diferencia vertical primero
				direction = direction.normalized()

				# Agregar componente vertical para levantar al objetivo
				direction.y = 1.0  # Impulsar hacia arriba

				direction = direction.normalized()

				# Aplicar impulso
				var impulse = direction * slam_impulse_strength

				if node.has_method("apply_pull_impulse"):
					node.apply_pull_impulse(impulse)
					print("Objetivo ", node.name, " impulsado con fuerza ", slam_impulse_strength)

				# Aplicar daño si es jugador
				if node.is_in_group("players") and node.has_method("take_damage"):
					node.take_damage(10)  # Daño del ground slam

	print("Ground Slam: ", targets_hit, " objetivos afectados")
