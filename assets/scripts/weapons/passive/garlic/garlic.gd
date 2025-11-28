extends PassiveWeapon

@export var damage_per_second: float = 10.0
@export var knockback_force := 0.2

@onready var mp := get_tree().get_multiplayer()

func _ready():
	super._ready()
	timer.stop()

func _physics_process(delta):
	# Solo el dueño del arma detecta enemigos
	if not is_multiplayer_authority():
		return
	
	do_damage_continuous(delta)

func do_damage_continuous(delta: float):
	for enemy in enemies_in_range:
		if enemy and enemy.is_inside_tree():
			# ✅ Llamar al servidor para aplicar daño
			var damage_amount = damage_per_second * delta
			var dir = (enemy.global_position - global_position).normalized()
			var knockback = dir * knockback_force
			
			# Enviar al servidor para que procese el daño
			request_damage_enemy.rpc_id(1, enemy.get_path(), damage_amount, knockback)

@rpc("any_peer", "call_local")
func request_damage_enemy(enemy_path: NodePath, damage: float, knockback: Vector3):
	# Solo el servidor procesa
	if not mp.is_server():
		return
	
	var enemy = get_node_or_null(enemy_path)
	if enemy and enemy.has_method("take_damage"):
		enemy.take_damage(damage)
		if enemy.has_method("apply_knockback"):
			enemy.apply_knockback(knockback)
