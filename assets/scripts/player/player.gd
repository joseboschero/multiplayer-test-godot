extends CharacterBody3D
class_name Player

# variables para animaciones
@export var animations: PlayerAnimations

@onready var anim_player: AnimationPlayer = $"animations/AnimationPlayer"

# variables para multijugador
@export var stats: PlayerStats
@export var input_handler: PlayerInput
@export var movement: PlayerMovement
@export var camera_controller: PlayerCamera

@onready var mp := get_tree().get_multiplayer()
@onready var cam: Camera3D = $Camera3D
@onready var mesh: MeshInstance3D = $MeshInstance3D

func _ready():
	if stats == null: stats = PlayerStats.new()
	if input_handler == null: input_handler = PlayerInput.new()
	if movement == null: movement = PlayerMovement.new()
	if camera_controller == null: camera_controller = PlayerCamera.new()
	
	DebugOverlay.watch_value("Speed", func(): 
		print(movement.current_speed)
		return movement.current_speed
	)

	# Multiplayer: asignar autoridad según el nombre
	if name.is_valid_int():
		set_multiplayer_authority(name.to_int())
		
	if is_multiplayer_authority():
		cam.current = true
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	else:
		cam.current = false

	print("Player listo. name=", name,
		" authority=", get_multiplayer_authority(),
		" my_id=", mp.get_unique_id())


func _physics_process(delta):
	# Solo procesa input y movimiento el dueño local
	if is_multiplayer_authority():
		movement.update(self, input_handler, stats, delta)
		
		# 👇 Actualizar animaciones según velocidad / estado
		if animations:
			animations.update(self, anim_player, delta)

		# Envía posición/rotación a otros
		rpc("sync_transform", global_transform)


@rpc("any_peer", "unreliable")
func sync_transform(t: Transform3D):
	# Clientes que NO son dueños actualizan transform
	if not is_multiplayer_authority():
		global_transform = t


func _process(delta):
	if is_multiplayer_authority():
		camera_controller.update(self, input_handler, delta)


func _input(event):
	if is_multiplayer_authority():
		input_handler.update_mouse_input(event)


func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

# func para animar al personaje
