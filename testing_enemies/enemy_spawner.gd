extends Node3D

@export var enemy_scene: PackedScene
@export var spawn_interval := 2.0
@export var spawn_radius := 20.0
@export var max_enemies := 10
@export var spawn_height := 1.0

var spawn_timer := 0.0
var spawning_enabled := false  # ✅ Control manual de spawn
@onready var mp := get_tree().get_multiplayer()

func _ready():
	# Solo el servidor controla el spawn
	if not mp.is_server():
		set_physics_process(false)
		return
	
	mp.peer_connected.connect(_on_peer_connected)
	print("🎮 EnemySpawner listo. Presiona [SPACE] para iniciar spawn de enemigos")

func _on_peer_connected(peer_id: int):
	print("📡 EnemySpawner: Nuevo cliente ", peer_id, " conectado")
	await get_tree().process_frame
	send_existing_enemies_to(peer_id)

func _input(event):
	# Solo el servidor puede activar el spawn
	if not mp.is_server():
		return
	
	if event.is_action_pressed("ui_accept"):  # SPACE o ENTER
		if not spawning_enabled:
			start_spawning()

func start_spawning():
	spawning_enabled = true
	rpc("enable_spawning")
	print("✅ Spawn de enemigos ACTIVADO")

@rpc("authority", "call_local")
func enable_spawning():
	spawning_enabled = true

func _physics_process(delta):
	if not mp.is_server() or not spawning_enabled:  # ✅ Solo spawea si está habilitado
		return
	
	spawn_timer += delta
	if spawn_timer >= spawn_interval:
		spawn_timer = 0.0
		
		var current_enemies = get_tree().get_nodes_in_group("enemy")
		if current_enemies.size() < max_enemies:
			spawn_enemy()

func spawn_enemy():
	var timestamp = Time.get_ticks_msec()
	
	var rng = RandomNumberGenerator.new()
	rng.seed = timestamp
	
	var angle = rng.randf() * TAU
	var distance = rng.randf_range(5.0, spawn_radius)
	
	var spawn_pos = global_position + Vector3(
		cos(angle) * distance,
		spawn_height,
		sin(angle) * distance
	)
	
	rpc("create_enemy", spawn_pos, timestamp)

@rpc("authority", "call_local")
func create_enemy(pos: Vector3, timestamp: int):
	if not enemy_scene:
		print("⚠️ Enemy scene no configurada")
		return
	
	var enemy = enemy_scene.instantiate()
	var enemy_id = "enemy_" + str(timestamp)
	enemy.name = enemy_id
	
	# ✅ IMPORTANTE: Primero agregar al árbol, LUEGO asignar posición
	add_child(enemy)
	enemy.global_position = pos
	
	print("✅ Enemigo creado: ", enemy_id, " en ", pos)

func send_existing_enemies_to(peer_id: int):
	if not mp.is_server():
		return
	
	var enemy_count = 0
	for child in get_children():
		if child.is_in_group("enemy"):
			enemy_count += 1
	
	if enemy_count == 0:
		print("📭 No hay enemigos para enviar al cliente ", peer_id)
		return
	
	print("📤 Enviando ", enemy_count, " enemigos existentes al cliente: ", peer_id)
	
	for child in get_children():
		if child.is_in_group("enemy"):
			var enemy_name = child.name
			var timestamp_str = enemy_name.replace("enemy_", "")
			if timestamp_str.is_valid_int():
				var timestamp = int(timestamp_str)
				print("  → Enviando enemigo: ", enemy_name, " en ", child.global_position)
				rpc_id(peer_id, "create_enemy", child.global_position, timestamp)
