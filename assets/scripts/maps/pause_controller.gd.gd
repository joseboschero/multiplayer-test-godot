extends Node

@onready var pause_menu = $"../PauseMenu"

func _input(event):
	if event.is_action_pressed("ui_cancel"): # ESC
		if pause_menu.visible:
			pause_menu.close()
		else:
			pause_menu.open()
