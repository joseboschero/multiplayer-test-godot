extends CharacterBody3D

@export var max_health := 100
var health := 100
@export var speed := 2.0
var knockback_velocity := Vector3.ZERO
var knockback_decay := 3.0
var target_player: Node3D = null
var spawn_time := 0.0

@onready var mp := get_tree().get_multiplayer()

func _ready():
	add_to_group("enemy")
	health = max_health
	spawn_time = Time.get_ticks_msec() / 1000.0
	
	# Solo el servidor controla la IA
	if not mp.is_server():
		set_physics_process(false)
	
	print("[%.2fs] 🧟 Enemigo creado" % [0.0])

func _physics_process(delta):
	# Solo el servidor calcula movimiento
	if not mp.is_server():
		return
	
	if health <= 0:
		die()
		return
	
	# Encontrar jugador más cercano
	update_target()
	
	var move_vec = Vector3.ZERO
	
	if knockback_velocity.length() > 0.1:
		move_vec = knockback_velocity
		knockback_velocity = knockback_velocity.move_toward(Vector3.ZERO, knockback_decay * delta)
	else:
		if target_player and is_instance_valid(target_player):
			var dir = (target_player.global_position - global_position)
			if dir.length() > 0.001:
				dir = dir.normalized()
				move_vec = dir * speed
	
	velocity = move_vec
	move_and_slide()
	
	# Sincronizar posición
	rpc("sync_transform", global_transform)

func update_target():
	var players = get_tree().get_nodes_in_group("player")
	var closest_distance = INF
	target_player = null
	
	for player in players:
		if player and is_instance_valid(player):
			var dist = global_position.distance_to(player.global_position)
			if dist < closest_distance:
				closest_distance = dist
				target_player = player

@rpc("authority", "unreliable")
func sync_transform(t: Transform3D):
	# Solo los clientes actualizan su transform
	if not mp.is_server():
		global_transform = global_transform.interpolate_with(t, 0.3)

func take_damage(amount: float):
	# Solo el servidor procesa daño
	if not mp.is_server():
		return
	
	var current_time = (Time.get_ticks_msec() / 1000.0) - spawn_time
	health -= amount
	
	# Sincronizar HP
	rpc("sync_health", health)
	
	if int(health) % 10 == 0 or health <= 0:
		print("[%.2fs] 🩸 HP: %.0f" % [current_time, health])
	
	if health <= 0:
		die()

@rpc("authority", "call_local")
func sync_health(new_health: float):
	health = new_health

func die():
	var time_alive = (Time.get_ticks_msec() / 1000.0) - spawn_time
	print("[%.2fs] ☠️ Enemigo eliminado | Vivió: %.2fs" % [time_alive, time_alive])
	rpc("destroy_enemy")

@rpc("authority", "call_local")
func destroy_enemy():
	queue_free()

func apply_knockback(force: Vector3):
	# Solo el servidor aplica knockback
	if not mp.is_server():
		return
	knockback_velocity += force
