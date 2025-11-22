extends CharacterBody3D
class_name Player

@export var stats: PlayerStats
@export var input_handler: PlayerInput
@export var movement: PlayerMovement
@export var camera_controller: PlayerCamera
@export var gun: Gun

# Sistema de vida
var max_health: float = 100.0
var current_health: float = 100.0

@onready var mp := get_tree().get_multiplayer()
@onready var cam: Camera3D = $Camera3D
@onready var mesh: MeshInstance3D = $MeshInstance3D

func _ready():
	# Crear módulos si faltan
	if stats == null: stats = PlayerStats.new()
	if input_handler == null: input_handler = PlayerInput.new()
	if movement == null: movement = PlayerMovement.new()
	if camera_controller == null: camera_controller = PlayerCamera.new()

	# Crear pistola si no existe
	if gun == null:
		gun = Gun.new()
		add_child(gun)

	# Multiplayer: asignar autoridad según el nombre
	if name.is_valid_int():
		set_multiplayer_authority(name.to_int())


	# 👇 SOLO el dueño local usa esta cámara
	if is_multiplayer_authority():
		cam.current = true          # o cam.make_current()
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

		# Crear crosshair
		create_crosshair()

		# Agregar modelo del arma
		create_weapon_model()
	else:
		cam.current = false

	print("Player listo. name=", name,
		" authority=", get_multiplayer_authority(),
		" my_id=", mp.get_unique_id())


func _physics_process(delta):
	# Solo procesa input y movimiento el dueño local
	if is_multiplayer_authority():
		# Actualizar detección de pull y recarga
		input_handler.update_pull_input()
		input_handler.update_reload_input()

		# Manejar disparos de la pistola
		if input_handler.is_left_click_pressed():
			gun.shoot()

		if input_handler.is_right_click_pressed():
			gun.impulse_player_backwards(self)

		# Manejar atracción de enemigos
		if input_handler.is_pull_pressed():
			gun.pull_enemy(self)

		# Manejar recarga
		if input_handler.is_reload_pressed():
			gun.reload()

		movement.update(self, input_handler, stats, delta)

		# Envía posición/rotación a otros
		rpc("sync_transform", global_transform)


@rpc("any_peer", "unreliable")
func sync_transform(t: Transform3D):
	# Clientes que NO son dueños actualizan transform
	if not is_multiplayer_authority():
		global_transform = t


func _input(event):
	if is_multiplayer_authority():
		input_handler.update_mouse_input(event)


func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func create_crosshair():
	# Crear CanvasLayer para el UI
	var canvas_layer = CanvasLayer.new()
	add_child(canvas_layer)

	# Crear CenterContainer para centrar el crosshair
	var center_container = CenterContainer.new()
	center_container.anchor_right = 1.0
	center_container.anchor_bottom = 1.0
	center_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas_layer.add_child(center_container)

	# Crear Label para el crosshair
	var crosshair_label = Label.new()
	crosshair_label.text = "+"
	crosshair_label.add_theme_font_size_override("font_size", 32)
	crosshair_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.8))
	crosshair_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	crosshair_label.add_theme_constant_override("outline_size", 2)
	crosshair_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	crosshair_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	center_container.add_child(crosshair_label)

	print("Crosshair creado")

	# Crear HUD para munición y vida
	create_hud(canvas_layer)

func create_weapon_model():
	# Cargar el modelo del arma
	var weapon_mesh = load("res://assets/scripts/guns/AssaultRifle_01.obj")

	if weapon_mesh:
		# Crear MeshInstance3D
		var weapon_model = MeshInstance3D.new()
		weapon_model.mesh = weapon_mesh

		# Debug: verificar cuántas superficies tiene el mesh
		var surface_count = weapon_mesh.get_surface_count()
		print("El arma tiene ", surface_count, " superficies")

		# Crear materiales basados en el archivo .mtl
		# Material 1: Negro metálico
		var mat_black = StandardMaterial3D.new()
		mat_black.albedo_color = Color(0.08, 0.08, 0.08)  # Negro del metal
		mat_black.metallic = 0.95
		mat_black.roughness = 0.15
		mat_black.emission_enabled = true
		mat_black.emission = Color(0.05, 0.05, 0.05)  # Emisión suave

		# Material 2: Marrón de madera
		var mat_brown = StandardMaterial3D.new()
		mat_brown.albedo_color = Color(0.35, 0.15, 0.08)  # Marrón rojizo de madera
		mat_brown.roughness = 0.7
		mat_brown.emission_enabled = true
		mat_brown.emission = Color(0.15, 0.06, 0.03)  # Emisión cálida

		# Material 3: Gris metálico
		var mat_gray = StandardMaterial3D.new()
		mat_gray.albedo_color = Color(0.4, 0.4, 0.4)  # Gris metálico
		mat_gray.metallic = 0.85
		mat_gray.roughness = 0.25
		mat_gray.emission_enabled = true
		mat_gray.emission = Color(0.08, 0.08, 0.08)  # Emisión suave

		# Aplicar materiales a las superficies del mesh
		for i in range(surface_count):
			if i == 0:
				weapon_model.set_surface_override_material(i, mat_black)
				print("Aplicado material negro a superficie ", i)
			elif i == 1:
				weapon_model.set_surface_override_material(i, mat_brown)
				print("Aplicado material marrón a superficie ", i)
			elif i == 2:
				weapon_model.set_surface_override_material(i, mat_gray)
				print("Aplicado material gris a superficie ", i)
			else:
				weapon_model.set_surface_override_material(i, mat_black)
				print("Aplicado material negro (por defecto) a superficie ", i)

		# Posicionar el arma en la cámara (primera persona)
		weapon_model.position = Vector3(0.25, -0.25, -0.7)  # Más lejos para ver el cargador
		weapon_model.rotation_degrees = Vector3(0, 0, 0)  # Sin rotación
		weapon_model.scale = Vector3(0.35, 0.35, 0.35)  # Más pequeño

		# Agregar como hijo de la cámara
		cam.add_child(weapon_model)

		print("Modelo del arma cargado con materiales")
	else:
		print("Error: No se pudo cargar el modelo del arma")

func create_hud(canvas_layer: CanvasLayer):
	# Contenedor para el HUD (esquina inferior derecha)
	var hud_container = VBoxContainer.new()
	hud_container.position = Vector2(20, 20)  # Margen desde la esquina superior izquierda
	canvas_layer.add_child(hud_container)

	# Label para la vida
	var health_label = Label.new()
	health_label.name = "HealthLabel"
	health_label.text = "VIDA: 100 / 100"
	health_label.add_theme_font_size_override("font_size", 24)
	health_label.add_theme_color_override("font_color", Color(0, 1, 0))  # Verde
	health_label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	health_label.add_theme_constant_override("outline_size", 2)
	hud_container.add_child(health_label)

	# Label para la munición
	var ammo_label = Label.new()
	ammo_label.name = "AmmoLabel"
	ammo_label.text = "MUNICIÓN: 30 / 90"
	ammo_label.add_theme_font_size_override("font_size", 24)
	ammo_label.add_theme_color_override("font_color", Color(1, 1, 0))  # Amarillo
	ammo_label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	ammo_label.add_theme_constant_override("outline_size", 2)
	hud_container.add_child(ammo_label)

	print("HUD creado")

func _process(delta):
	if is_multiplayer_authority():
		camera_controller.update(self, input_handler, delta)

		# Actualizar HUD
		update_hud()

func update_hud():
	# Buscar los labels del HUD
	var health_label = find_child("HealthLabel", true, false)
	var ammo_label = find_child("AmmoLabel", true, false)

	if health_label:
		health_label.text = "VIDA: " + str(int(current_health)) + " / " + str(int(max_health))

		# Cambiar color según la vida
		if current_health > 60:
			health_label.add_theme_color_override("font_color", Color(0, 1, 0))  # Verde
		elif current_health > 30:
			health_label.add_theme_color_override("font_color", Color(1, 1, 0))  # Amarillo
		else:
			health_label.add_theme_color_override("font_color", Color(1, 0, 0))  # Rojo

	if ammo_label and gun:
		ammo_label.text = "MUNICIÓN: " + str(gun.current_ammo) + " / " + str(gun.reserve_ammo)

		# Cambiar color según munición
		if gun.current_ammo > 10:
			ammo_label.add_theme_color_override("font_color", Color(1, 1, 0))  # Amarillo
		elif gun.current_ammo > 0:
			ammo_label.add_theme_color_override("font_color", Color(1, 0.5, 0))  # Naranja
		else:
			ammo_label.add_theme_color_override("font_color", Color(1, 0, 0))  # Rojo
