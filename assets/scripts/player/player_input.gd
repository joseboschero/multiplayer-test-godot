extends Resource
class_name PlayerInput

var mouse_delta := Vector2.ZERO

# Dash detection
var last_forward_press_time: float = -999.0
var double_tap_time: float = 0.3  # Tiempo máximo entre toques para detectar doble toque
var dash_requested: bool = false

# Jump charge detection
var jump_charge_time: float = 0.0
var is_charging_jump: bool = false
var jump_released: bool = false

# Mouse button detection
var left_click_pressed: bool = false
var right_click_pressed: bool = false

# Pull/attraction detection
var pull_pressed: bool = false

# Reload detection
var reload_pressed: bool = false

# Ground slam detection
var ground_slam_pressed: bool = false

func _init():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func get_move_input() -> Vector2:
	var x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	var y = Input.get_action_strength("move_backward") - Input.get_action_strength("move_forward")
	return Vector2(x, y)

func is_jump_pressed() -> bool:
	# Ya no se usa para salto simple, solo para referencia
	return Input.is_action_just_pressed("jump")

func update_jump_charge(delta: float, max_charge_time: float):
	# Detectar si se está presionando el espacio
	if Input.is_action_pressed("jump"):
		if not is_charging_jump:
			# Comenzar a cargar
			is_charging_jump = true
			jump_charge_time = 0.0
			jump_released = false
		else:
			# Continuar cargando (máximo 2 segundos)
			jump_charge_time += delta
			if jump_charge_time > max_charge_time:
				jump_charge_time = max_charge_time
	else:
		# Se soltó el espacio
		if is_charging_jump:
			jump_released = true
			is_charging_jump = false

func get_jump_charge_percent() -> float:
	# Retorna un valor entre 0.0 y 1.0 representando el porcentaje de carga
	return jump_charge_time

func is_jump_released() -> bool:
	if jump_released:
		jump_released = false  # Consumir el evento
		return true
	return false

func reset_jump_charge():
	jump_charge_time = 0.0
	is_charging_jump = false
	jump_released = false

func update_mouse_input(event: InputEvent):
	if event is InputEventMouseMotion:
		mouse_delta = event.relative
	elif event is InputEventMouseButton:
		# Detectar click izquierdo
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			left_click_pressed = true
		# Detectar click derecho
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			right_click_pressed = true

func consume_mouse_delta() -> Vector2:
	var d = mouse_delta
	mouse_delta = Vector2.ZERO
	return d

func update_dash_detection(delta: float):
	# Detectar doble toque de W (move_forward)
	if Input.is_action_just_pressed("move_forward"):
		var current_time = Time.get_ticks_msec() / 1000.0
		var time_since_last_press = current_time - last_forward_press_time

		if time_since_last_press <= double_tap_time:
			# Doble toque detectado!
			dash_requested = true

		last_forward_press_time = current_time

func is_dash_requested() -> bool:
	if dash_requested:
		dash_requested = false  # Consumir la solicitud
		return true
	return false

func is_left_click_pressed() -> bool:
	if left_click_pressed:
		left_click_pressed = false  # Consumir el click
		return true
	return false

func is_right_click_pressed() -> bool:
	if right_click_pressed:
		right_click_pressed = false  # Consumir el click
		return true
	return false

func update_pull_input():
	# Detectar tecla Z
	if Input.is_action_just_pressed("ui_page_down") or Input.is_key_pressed(KEY_Z):
		pull_pressed = true

func is_pull_pressed() -> bool:
	if pull_pressed:
		pull_pressed = false  # Consumir la solicitud
		return true
	return false

func update_reload_input():
	# Detectar tecla R
	if Input.is_key_pressed(KEY_R):
		reload_pressed = true

func is_reload_pressed() -> bool:
	if reload_pressed:
		reload_pressed = false  # Consumir la solicitud
		return true
	return false

func update_ground_slam_input():
	# Detectar tecla F
	if Input.is_key_pressed(KEY_F):
		ground_slam_pressed = true

func is_ground_slam_pressed() -> bool:
	if ground_slam_pressed:
		ground_slam_pressed = false  # Consumir la solicitud
		return true
	return false
