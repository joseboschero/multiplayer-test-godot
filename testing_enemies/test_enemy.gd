extends CharacterBody3D

@export var max_health := 100
var health := 100
@export var speed := 2.0

var knockback_velocity := Vector3.ZERO
var knockback_decay := 3.0
var player: Node3D = null

var spawn_time := 0.0

func _ready():
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]
	health = max_health
	spawn_time = Time.get_ticks_msec() / 1000.0
	print("[%.2fs] 🧟 Enemigo creado con HP: %s" % [0.0, health])

func _physics_process(delta):
	if health <= 0:
		var time_alive = (Time.get_ticks_msec() / 1000.0) - spawn_time
		print("[%.2fs] 💀 Enemigo murió | Vivió: %.2fs" % [time_alive, time_alive])
		queue_free()
		return
	
	var move_vec = Vector3.ZERO
	
	if knockback_velocity.length() > 0.1:
		move_vec = knockback_velocity
		knockback_velocity = knockback_velocity.move_toward(Vector3.ZERO, knockback_decay * delta)
	else:
		if player and is_instance_valid(player):
			var dir = (player.global_transform.origin - global_transform.origin)
			if dir.length() > 0.001:
				dir = dir.normalized()
				move_vec = dir * speed
	
	velocity = move_vec
	move_and_slide()

func take_damage(amount: float):
	var current_time = (Time.get_ticks_msec() / 1000.0) - spawn_time
	health -= amount
	
	# Solo imprime cada 10 HP para no saturar
	if int(health) % 10 == 0 or health <= 0:
		print("[%.2fs] 🩸 HP: %.0f (recibió %.3f de daño)" % [current_time, health, amount])
	
	if health <= 0:
		die()

func die():
	var time_alive = (Time.get_ticks_msec() / 1000.0) - spawn_time
	print("[%.2fs] ☠️ Enemigo eliminado | Vivió: %.2fs" % [time_alive, time_alive])
	queue_free()

func apply_knockback(force: Vector3):
	knockback_velocity += force
