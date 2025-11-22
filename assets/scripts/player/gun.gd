extends Node3D
class_name Gun

@export var damage: float = 10.0
@export var shoot_range: float = 100.0
@export var impulse_force: float = 15.0
@export var fire_rate: float = 0.2  # Tiempo entre disparos en segundos
@export var impulse_cooldown_time: float = 1.5  # Tiempo de cooldown del impulso
@export var pull_force: float = 20.0  # Fuerza de atracción hacia el jugador
@export var pull_cooldown_time: float = 0.5  # Cooldown del pull
@export var max_ammo_in_mag: int = 30  # Balas en el cargador
@export var max_reserve_ammo: int = 90  # Balas en reserva

var can_shoot: bool = true
var shoot_cooldown: float = 0.0
var can_impulse: bool = true
var impulse_cooldown: float = 0.0
var can_pull: bool = true
var pull_cooldown: float = 0.0

# Sistema de munición
var current_ammo: int = 30  # Balas actuales en el cargador
var reserve_ammo: int = 90  # Balas en reserva

@onready var camera: Camera3D = get_viewport().get_camera_3d()

func _ready():
	pass

func _process(delta):
	# Actualizar cooldown del disparo
	if shoot_cooldown > 0:
		shoot_cooldown -= delta
		if shoot_cooldown <= 0:
			can_shoot = true

	# Actualizar cooldown del impulso
	if impulse_cooldown > 0:
		impulse_cooldown -= delta
		if impulse_cooldown <= 0:
			can_impulse = true

	# Actualizar cooldown del pull
	if pull_cooldown > 0:
		pull_cooldown -= delta
		if pull_cooldown <= 0:
			can_pull = true

func shoot():
	if not can_shoot:
		return

	# Verificar munición
	if current_ammo <= 0:
		print("¡Sin munición! Recarga con R")
		return

	can_shoot = false
	shoot_cooldown = fire_rate
	current_ammo -= 1  # Consumir una bala

	# Obtener la cámara
	if camera == null:
		camera = get_viewport().get_camera_3d()

	if camera == null:
		return

	# Crear raycast desde el centro de la cámara
	var space_state = get_world_3d().direct_space_state
	var from = camera.global_position
	var to = from + (-camera.global_transform.basis.z * shoot_range)

	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [get_parent()]  # Excluir al jugador

	var result = space_state.intersect_ray(query)

	if result:
		print("¡Impacto! Objetivo: ", result.collider.name, " en posición: ", result.position)

		# Aquí puedes agregar efectos visuales, partículas, etc.
		# También puedes hacer daño si el objeto tiene vida
		if result.collider.has_method("take_damage"):
			result.collider.take_damage(damage)
	else:
		print("Disparo al aire")

func impulse_player_backwards(player: CharacterBody3D):
	# Verificar cooldown
	if not can_impulse:
		print("Impulso en cooldown...")
		return

	if camera == null:
		camera = get_viewport().get_camera_3d()

	if camera == null:
		return

	# Activar cooldown
	can_impulse = false
	impulse_cooldown = impulse_cooldown_time

	# Obtener la dirección hacia atrás de la cámara (opuesta a donde apunta)
	var impulse_direction = camera.global_transform.basis.z.normalized()

	# Calcular el impulso completo (incluye componente vertical)
	var impulse = impulse_direction * impulse_force

	# Aplicar impulso al jugador usando el sistema de movimiento
	if player and player.get("movement"):
		var movement = player.get("movement")
		if movement and movement.has_method("apply_impulse"):
			movement.apply_impulse(impulse)
			print("¡Impulso hacia atrás!")

func pull_enemy(player: CharacterBody3D):
	# Verificar cooldown
	if not can_pull:
		print("Pull en cooldown...")
		return

	if camera == null:
		camera = get_viewport().get_camera_3d()

	if camera == null:
		return

	# Activar cooldown
	can_pull = false
	pull_cooldown = pull_cooldown_time

	# Crear raycast desde el centro de la cámara
	var space_state = get_world_3d().direct_space_state
	var from = camera.global_position
	var to = from + (-camera.global_transform.basis.z * shoot_range)

	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [player]  # Excluir al jugador que hace el pull

	var result = space_state.intersect_ray(query)

	if result and result.collider:
		var target = result.collider

		# Verificar que el objetivo sea damageable
		if target.is_in_group("damageable"):
			print("¡Atrayendo objetivo: ", target.name, "!")

			# Calcular dirección desde el objetivo hacia el jugador
			var direction = (player.global_position - target.global_position).normalized()

			# Aplicar impulso hacia el jugador
			if target.has_method("apply_pull_impulse"):
				target.apply_pull_impulse(direction * pull_force)
			else:
				print("El objetivo no tiene método apply_pull_impulse")
		else:
			print("El objetivo no es atacable")
	else:
		print("No hay objetivo para atraer")

func reload():
	# Verificar si ya está lleno
	if current_ammo >= max_ammo_in_mag:
		print("El cargador ya está lleno")
		return

	# Verificar si hay munición en reserva
	if reserve_ammo <= 0:
		print("¡Sin munición en reserva!")
		return

	# Calcular cuántas balas necesita el cargador
	var ammo_needed = max_ammo_in_mag - current_ammo

	# Tomar de la reserva
	var ammo_to_reload = min(ammo_needed, reserve_ammo)

	current_ammo += ammo_to_reload
	reserve_ammo -= ammo_to_reload

	print("Recargado! Munición: ", current_ammo, "/", max_ammo_in_mag, " (Reserva: ", reserve_ammo, ")")
