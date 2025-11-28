extends CharacterBody3D

@export var max_health := 100
var health := 100
@export var speed := 3.0
@export var gravity := 9.8  # Aceleración hacia abajo (m/s²) cuando está en el aire
@export var knockback_decay := 8.0  # Velocidad de frenado del knockback (unidades/segundo)
@export var max_knockback := 5.0  # Velocidad máxima de knockback para evitar vuelos infinitos
@export var grounded_drag := 0.95  # Multiplicador de fricción (0.95 = pierde 5% de velocidad por frame)

var knockback_velocity := Vector3.ZERO  # Velocidad actual del knockback
var target_player: Node3D = null
var spawn_time := 0.0  # Timestamp de creación para logs
var last_knockback_time := 0.0  # Último timestamp que recibió knockback
var knockback_cooldown := 0.1  # Segundos mínimos entre knockbacks

@onready var mp := get_tree().get_multiplayer()

func _ready():
	add_to_group("enemy")
	health = max_health
	spawn_time = Time.get_ticks_msec() / 1000.0
	
	# Solo el servidor calcula física de enemigos
	# Los clientes solo reciben updates de posición vía RPC
	if not mp.is_server():
		set_physics_process(false)
	
	print("[%.2fs] 🧟 Enemigo creado" % [0.0])

func _physics_process(delta):
	# Seguridad: verificar que este código solo corre en el servidor
	if not mp.is_server():
		return
	
	# Si está muerto, eliminar y detener proceso
	if health <= 0:
		die()
		return
	
	# Actualizar target cada frame (busca jugador más cercano)
	update_target()
	
	var move_vec = Vector3.ZERO
	
	# === GRAVEDAD ===
	# Si no está tocando el piso, aplicar gravedad
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		# Si está en el piso, resetear velocidad vertical
		velocity.y = 0
		# Aplicar fricción solo a los ejes horizontales del knockback
		knockback_velocity.x *= grounded_drag  # x *= 0.95 = pierde 5% por frame
		knockback_velocity.z *= grounded_drag
	
	# === MOVIMIENTO ===
	# Si aún tiene knockback significativo (> 0.1 unidades/segundo)
	if knockback_velocity.length() > 0.1:
		# Usar la velocidad del knockback para mover
		move_vec.x = knockback_velocity.x
		move_vec.z = knockback_velocity.z
		
		# Reducir knockback gradualmente hacia 0
		# move_toward(valor_actual, valor_destino, paso_maximo)
		# Ejemplo: si knockback.x=5, decay=8, delta=0.016 → reduce 0.128 por frame
		knockback_velocity.x = move_toward(knockback_velocity.x, 0, knockback_decay * delta)
		knockback_velocity.z = move_toward(knockback_velocity.z, 0, knockback_decay * delta)
	else:
		# No hay knockback, usar movimiento normal de IA
		if target_player and is_instance_valid(target_player):
			# Vector desde enemigo hacia jugador
			var dir = (target_player.global_position - global_position)
			dir.y = 0  # Ignorar diferencia de altura (solo perseguir en plano horizontal)
			
			# Si la distancia es significativa
			if dir.length() > 0.001:
				dir = dir.normalized()  # Convertir a vector unitario (longitud = 1)
				move_vec.x = dir.x * speed
				move_vec.z = dir.z * speed
	
	# Asignar velocidad calculada a velocity (usado por move_and_slide)
	velocity.x = move_vec.x
	velocity.z = move_vec.z
	
	# Mover el CharacterBody3D (maneja colisiones automáticamente)
	move_and_slide()
	
	# Enviar posición actualizada a todos los clientes
	# "unreliable" = puede perder paquetes pero es más rápido (ideal para posición)
	rpc("sync_transform", global_transform)

func update_target():
	# Buscar todos los nodos en el grupo "player"
	var players = get_tree().get_nodes_in_group("player")
	var closest_distance = INF  # Infinito inicial
	target_player = null
	
	# Encontrar el jugador más cercano
	for player in players:
		if player and is_instance_valid(player):
			var dist = global_position.distance_to(player.global_position)
			if dist < closest_distance:
				closest_distance = dist
				target_player = player

# RPC que solo el servidor puede llamar ("authority")
# "unreliable" = UDP, puede perder paquetes pero es rápido
@rpc("authority", "unreliable")
func sync_transform(t: Transform3D):
	# Solo los clientes actualizan su posición (el servidor ya la tiene correcta)
	if not mp.is_server():
		# Interpolación suave (30% hacia la nueva posición, 70% de la vieja)
		# Esto hace que el movimiento se vea fluido aunque lleguen pocos updates
		global_transform = global_transform.interpolate_with(t, 0.3)

func take_damage(amount: float):
	# Solo el servidor calcula daño (fuente única de verdad)
	if not mp.is_server():
		return
	
	var current_time = (Time.get_ticks_msec() / 1000.0) - spawn_time
	health -= amount
	
	# Sincronizar HP a todos los clientes
	rpc("sync_health", health)
	
	# Log cada 10 HP o cuando muere (evita spam en consola)
	if int(health) % 10 == 0 or health <= 0:
		print("[%.2fs] 🩸 HP: %.0f" % [current_time, health])
	
	if health <= 0:
		die()

# RPC que el servidor puede llamar y que también se ejecuta localmente
@rpc("authority", "call_local")
func sync_health(new_health: float):
	health = new_health

func die():
	var time_alive = (Time.get_ticks_msec() / 1000.0) - spawn_time
	print("[%.2fs] ☠️ Enemigo eliminado | Vivió: %.2fs" % [time_alive, time_alive])
	# Decirle a todos los clientes que eliminen este enemigo
	rpc("destroy_enemy")

@rpc("authority", "call_local")
func destroy_enemy():
	# queue_free() elimina el nodo del árbol en el próximo frame
	queue_free()

func apply_knockback(force: Vector3):
	# Solo el servidor aplica knockback (evita desincronización)
	if not mp.is_server():
		return
	
	var current_time = Time.get_ticks_msec() / 1000.0
	
	# Cooldown: si recibió knockback hace menos de 0.1s, ignorar
	# Esto evita que 60 golpes por segundo lo lancen al espacio
	if current_time - last_knockback_time < knockback_cooldown:
		return
	
	last_knockback_time = current_time
	
	# Extraer solo componentes horizontales (X y Z)
	# force.y se ignora completamente
	var horizontal_force = Vector3(force.x, 0, force.z)
	
	# Sumar a la velocidad actual (acumula múltiples knockbacks)
	knockback_velocity += horizontal_force
	
	# Limitar velocidad total para que no vuele infinitamente
	# Si knockback_velocity.length() > 5.0, normalizar y multiplicar por 5.0
	if knockback_velocity.length() > max_knockback:
		knockback_velocity = knockback_velocity.normalized() * max_knockback
