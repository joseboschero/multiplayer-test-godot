extends Control

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/menu.tscn")

func _on_connect_pressed() -> void:
	var ip = $VBoxContainer/IpInput.text.strip_edges()
	
	if ip == "":
		print("Escribe una IP válida.")
		return
	
	# Primero conecta
	NetworkManager.join(ip)
	
	# Espera a que la conexión esté lista antes de cambiar escena
	await get_tree().create_timer(0.5).timeout
	get_tree().change_scene_to_file("res://scenes/enviroment/level/basic_map.tscn")
