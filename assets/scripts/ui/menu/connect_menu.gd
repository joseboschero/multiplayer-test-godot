extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/menu.tscn")

func _on_connect_pressed() -> void:
	var ip = $VBoxContainer/IpInput.text.strip_edges()
	
	if ip == "":
		print("Escribe una IP válida.")
		return
		
	get_tree().change_scene_to_file("res://scenes/enviroment/level/basic_map.tscn")
	NetworkManager.join(ip)
