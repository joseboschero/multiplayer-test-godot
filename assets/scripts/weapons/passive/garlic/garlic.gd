extends PassiveWeapon

@export var damage_per_second: float = 10.0
@export var knockback_force := 0.2

var start_time := 0.0

func _ready():
	super._ready()
	timer.stop()
	#start_time = Time.get_ticks_msec() / 1000.0
	#print("[%.2fs] Garlic iniciado - Daño: %s/s | Knockback: %s" % [0.0, damage_per_second, knockback_force])

func _physics_process(delta):
	do_damage_continuous(delta)

func do_damage_continuous(delta: float):
	var current_time = (Time.get_ticks_msec() / 1000.0) - start_time
	
	for enemy in enemies_in_range:
		if enemy and enemy.is_inside_tree():
			if enemy.has_method("take_damage"):
				enemy.take_damage(damage_per_second * delta)
			
			if enemy.has_method("apply_knockback"):
				var dir = (enemy.global_position - global_position).normalized()
				enemy.apply_knockback(dir * knockback_force)
