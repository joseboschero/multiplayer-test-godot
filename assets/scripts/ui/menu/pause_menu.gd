extends Control

func _ready():
	visible = false
	$ColorRect.color.a = 0.7

func open():
	visible = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.input_handler.enabled = false

func close():
	visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.input_handler.enabled = true

func _on_resume_pressed():
	print("Resume..")
	close()

func _on_settings_pressed():
	print("Settings...")
	var settings = get_tree().root.get_node("Node3D/SettingsMenu")
	settings.open(self)


func _on_quit_pressed():
	print("Quit...")
	get_tree().quit()
