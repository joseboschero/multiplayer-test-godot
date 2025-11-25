extends Control

var opener: Control = null

# Resoluciones disponibles
var resolutions = [
	Vector2i(1280, 720),
	Vector2i(1600, 900),
	Vector2i(1920, 1080),
	Vector2i(2560, 1440)
]

func _ready():
	visible = false
	process_mode = PROCESS_MODE_ALWAYS
	_fill_resolution_options()
	_load_settings()

func open(from_menu: Control):
	opener = from_menu
	opener.visible = false
	visible = true
	move_to_front()

func close():
	visible = false
	if opener:
		opener.visible = true
		opener = null

func _fill_resolution_options():
	var option_button = $VBoxContainer/ResolutionOption
	option_button.clear()

	for r in resolutions:
		option_button.add_item("%sx%s" % [r.x, r.y])

func _load_settings():
	var option_button = $VBoxContainer/ResolutionOption
	var fullscreen_check = $VBoxContainer/FullscreenCheck
	var vsync_check = $VBoxContainer/VSyncCheck
	var volume_slider = $VBoxContainer/VolumeSlider

	# Cargar valores actuales del sistema
	var current_res = DisplayServer.window_get_size()
	var fullscreen = DisplayServer.window_get_mode() == DisplayServer.WindowMode.WINDOW_MODE_FULLSCREEN
	var vsync = DisplayServer.window_get_vsync_mode() == DisplayServer.VSyncMode.VSYNC_ENABLED

	fullscreen_check.button_pressed = fullscreen
	vsync_check.button_pressed = vsync

	# Seleccionar resolución actual si está en la lista
	for i in range(resolutions.size()):
		if resolutions[i] == current_res:
			option_button.select(i)

	# Volumen
	volume_slider.value = AudioServer.get_bus_volume_db(0)

func _on_apply_button_pressed():
	var option_button = $VBoxContainer/ResolutionOption
	var fullscreen_check = $VBoxContainer/FullscreenCheck
	var vsync_check = $VBoxContainer/VSyncCheck
	var volume_slider = $VBoxContainer/VolumeSlider

	# Aplicar resolución
	var index = option_button.get_selected_id()
	var res = resolutions[index]

	DisplayServer.window_set_size(res)

	# Pantalla completa
	if fullscreen_check.button_pressed:
		DisplayServer.window_set_mode(DisplayServer.WindowMode.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WindowMode.WINDOW_MODE_WINDOWED)

	# VSync
	if vsync_check.button_pressed:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSyncMode.VSYNC_ENABLED)
	else:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSyncMode.VSYNC_DISABLED)

	# Volumen
	AudioServer.set_bus_volume_db(0, volume_slider.value)

	print("Configuración aplicada.")

func _on_back_button_pressed():
	close()
