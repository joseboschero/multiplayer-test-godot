extends CharacterBody3D
class_name Enemy

@export var max_health: float = 10.0
@export var health: float = 10.0
@export var spawn_area_size: float = 40.0  # Tamaño del área de spawn
@export var gravity: float = 12.0

var pull_velocity: Vector3 = Vector3.ZERO

@onready var mesh: MeshInstance3D = $MeshInstance3D

func _ready():
	health = max_health
	# Agregar a grupos para detección de habilidades
	add_to_group("enemies")
	add_to_group("damageable")
	print("Enemigo creado con ", health, " de vida")

func take_damage(damage: float):
	health -= damage
	print("¡Enemigo recibió ", damage, " de daño! Vida restante: ", health)

	# Efecto visual simple (cambiar color temporalmente)
	if mesh:
		flash_damage()

	# Verificar si murió
	if health <= 0:
		die()

func flash_damage():
	# Crear un material temporal para el efecto de daño
	if mesh:
		var material = StandardMaterial3D.new()
		material.albedo_color = Color(1, 0, 0, 1)  # Rojo
		mesh.set_surface_override_material(0, material)

		# Volver al color normal después de 0.1 segundos
		await get_tree().create_timer(0.1).timeout
		mesh.set_surface_override_material(0, null)

func die():
	print("¡Enemigo eliminado! Reapareciendo...")
	respawn()

func respawn():
	# Generar posición aleatoria en el mapa
	var random_x = randf_range(-spawn_area_size / 2, spawn_area_size / 2)
	var random_z = randf_range(-spawn_area_size / 2, spawn_area_size / 2)

	# Reposicionar el enemigo
	global_position = Vector3(random_x, 0, random_z)

	# Resetear vida
	health = max_health

	print("Enemigo reapareció en posición: ", global_position, " con ", health, " de vida")

func _physics_process(delta):
	# Aplicar velocidad del pull
	if pull_velocity.length() > 0:
		# Aplicar el impulso completo (incluye componente Y para levantarlo)
		velocity = pull_velocity

		# Disipar el impulso con el tiempo
		pull_velocity = pull_velocity.lerp(Vector3.ZERO, delta * 3.0)

		# Si el impulso es muy pequeño, eliminarlo
		if pull_velocity.length() < 0.5:
			pull_velocity = Vector3.ZERO
	else:
		# Sin impulso, aplicar gravedad normal
		velocity.x = 0
		velocity.z = 0

	# Siempre aplicar gravedad (incluso durante el pull, para que caiga después)
	if not is_on_floor():
		velocity.y -= gravity * delta

	move_and_slide()

func apply_pull_impulse(impulse: Vector3):
	pull_velocity = impulse
	print("Enemigo recibió impulso de atracción: ", impulse)
