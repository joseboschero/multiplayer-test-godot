extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _on_host_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/enviroment/level/basic_map.tscn")
	NetworkManager.host()

func _on_connect_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/connect_menu.tscn")

func _on_settings_pressed() -> void:
	$SettingsMenu.open($VBoxContainer)

func _on_quit_pressed() -> void:
	get_tree().quit()
