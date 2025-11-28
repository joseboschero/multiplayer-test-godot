extends PassiveWeapon

@export var damage_per_second: float = 10.0
@export var knockback_force := 2.0  # Fuerza del empuje por golpe
@export var knockback_interval := 0.5  # Segundos entre cada empuje al mismo enemigo

@onready var mp := get_tree().get_multiplayer()

# Dictionary que guarda: {enemy_instance_id: timestamp_ultimo_knockback}
# Esto evita empujar al enemigo en cada frame (60 veces por segundo)
var enemy_last_knockback := {}

func _ready():
	super._ready()
	# Desactivar timer heredado porque usamos daño continuo en _physics_process
	timer.stop()

func _physics_process(delta):
	# Solo el dueño del arma (el jugador que la porta) calcula daño
	# Esto evita que cada cliente procese el mismo enemigo múltiples veces
	if not is_multiplayer_authority():
		return
	
	do_damage_continuous(delta)

func do_damage_continuous(delta: float):
	# Tiempo actual en segundos (convertido de milisegundos)
	var current_time = Time.get_ticks_msec() / 1000.0
	
	# Iterar todos los enemigos dentro del área del arma
	for enemy in enemies_in_range:
		# Verificar que el enemigo aún existe en el árbol de escena
		if enemy and enemy.is_inside_tree():
			# ID único del enemigo para trackear su último knockback
			var enemy_id = enemy.get_instance_id()
			
			# Daño escalado por delta (si delta=0.016s a 60fps, hace ~0.16 de daño por frame)
			# En 1 segundo completo suma 10 de daño
			var damage_amount = damage_per_second * delta
			
			# Lógica para decidir si aplicar knockback en este frame
			var should_knockback = false
			
			# Primera vez que golpeamos a este enemigo
			if not enemy_id in enemy_last_knockback:
				should_knockback = true
			# Ya pasó suficiente tiempo desde el último knockback (0.5s por defecto)
			elif current_time - enemy_last_knockback[enemy_id] >= knockback_interval:
				should_knockback = true
			
			var knockback = Vector3.ZERO
			if should_knockback:
				# Vector desde el arma hacia el enemigo (dirección del empuje)
				var dir = (enemy.global_position - global_position).normalized()
				dir.y = 0  # Anular componente vertical = solo empujar horizontalmente
				knockback = dir * knockback_force
				# Guardar timestamp de este knockback
				enemy_last_knockback[enemy_id] = current_time
			
			# Enviar al servidor (peer 1) para que procese el daño y knockback
			# Esto centraliza la lógica en un solo lugar (el servidor)
			request_damage_enemy.rpc_id(1, enemy.get_path(), damage_amount, knockback)

func _on_enemy_exited(enemy):
	# Cuando un enemigo sale del área, limpiar su tracking
	# Así no acumulamos IDs de enemigos muertos/lejanos en el dictionary
	var enemy_id = enemy.get_instance_id()
	if enemy_id in enemy_last_knockback:
		enemy_last_knockback.erase(enemy_id)

# RPC que cualquier peer puede llamar ("any_peer") pero solo ejecuta en el servidor
# "call_local" significa que también se ejecuta localmente en quien lo llama
@rpc("any_peer", "call_local")
func request_damage_enemy(enemy_path: NodePath, damage: float, knockback: Vector3):
	# Doble verificación: solo el servidor procesa
	if not mp.is_server():
		return
	
	# Buscar el enemigo en el árbol de escena usando su path
	var enemy = get_node_or_null(enemy_path)
	if enemy and enemy.has_method("take_damage"):
		enemy.take_damage(damage)
		
		# Solo aplicar knockback si realmente hay fuerza (> 0.01)
		# Evita llamadas innecesarias cuando knockback = Vector3.ZERO
		if knockback.length() > 0.01 and enemy.has_method("apply_knockback"):
			enemy.apply_knockback(knockback)
