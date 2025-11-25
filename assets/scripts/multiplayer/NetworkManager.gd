extends Node

@onready var player_scene: PackedScene = load("res://scenes/player/Player.tscn")
@onready var mp := get_tree().get_multiplayer()

const PORT := 9000

func _ready():
	mp.peer_connected.connect(_on_peer_connected)
	mp.peer_disconnected.connect(_on_peer_disconnected)
	mp.connected_to_server.connect(_on_connected_to_server)
	mp.connection_failed.connect(_on_connection_failed)

	print("NetworkManager listo. Mi id: ", mp.get_unique_id())


func host():
	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_server(PORT, 32)
	if error != OK:
		push_error("Error creando servidor: %s" % error)
		return

	mp.multiplayer_peer = peer
	print("Servidor creado en puerto ", PORT)

	_spawn_player(mp.get_unique_id())


func join(ip: String):
	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_client(ip, PORT)
	if error != OK:
		push_error("Error al conectar: %s" % error)
		return

	mp.multiplayer_peer = peer
	print("Intentando conectar a: ", ip)


func _on_connected_to_server():
	print("CLIENTE: Conectado al servidor. Mi id: ", mp.get_unique_id())


func _on_connection_failed():
	print("CLIENTE: Falló la conexión")


func _on_peer_connected(id: int):
	if not mp.is_server():
		return

	print("SERVIDOR: Jugador conectado: ", id)
	_spawn_player(id)

	for child in get_children():
		if child is Player:
			var existing_id := int(child.name)
			if existing_id != id:
				rpc_id(id, "spawn_player", existing_id)


func _on_peer_disconnected(id: int) -> void:
	if not mp.is_server():
		return

	print("SERVIDOR: Jugador desconectado: ", id)
	rpc("despawn_player", id)


@rpc("authority", "call_local")
func spawn_player(id: int):
	var p: Player = player_scene.instantiate()
	p.name = str(id)
	add_child(p)
	print("Jugador creado con id: ", id)


@rpc("authority", "call_local")
func despawn_player(id: int) -> void:
	var player := get_node_or_null(str(id))
	if player:
		player.queue_free()


func _spawn_player(id: int):
	rpc("spawn_player", id)


func reset_state():
	for child in get_children():
		if child is Player:
			child.queue_free()

	if mp.multiplayer_peer:
		mp.multiplayer_peer.close()

	mp.multiplayer_peer = null


func is_network_ready() -> bool:
	return mp.multiplayer_peer != null
