extends CharacterBody3D
class_name Player

@export var stats: PlayerStats
@export var input_handler: PlayerInput
@export var movement: PlayerMovement
@export var camera_controller: PlayerCamera
@export var animations: PlayerAnimations

@onready var mp := get_tree().get_multiplayer()
@onready var cam: Camera3D = $Camera3D
@onready var mesh: MeshInstance3D = $MeshInstance3D
@onready var anim_player: AnimationPlayer = $"animations/AnimationPlayer"

var garlic_scene = preload("res://scenes/weapons/passive/garlic/garlic.tscn")

func _ready():
	if stats == null: stats = PlayerStats.new()
	if input_handler == null: input_handler = PlayerInput.new()
	if movement == null: movement = PlayerMovement.new()
	if camera_controller == null: camera_controller = PlayerCamera.new()
	
	$PassiveWeaponManager.add_passive_weapon(garlic_scene, self)
	
	if animations == null: animations = PlayerAnimations.new()
	animations.stats = stats
	
	# Multiplayer: autoridad según nombre del nodo (0,1,2, etc.)
	if name.is_valid_int():
		set_multiplayer_authority(name.to_int())
		
	if is_multiplayer_authority():
		cam.current = true
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		
		# ✅ Configurar primera persona - pasar el nodo Player completo
		camera_controller.setup_first_person(cam, self)
	else:
		cam.current = false
		
	print("Player listo. name=", name,
		" authority=", get_multiplayer_authority(),
		" my_id=", mp.get_unique_id())

func _physics_process(delta: float) -> void:
	if is_multiplayer_authority():
		movement.update(self, input_handler, stats, delta)
		var anim_name := ""
		if animations and anim_player:
			if input_handler.is_roll_pressed():
				animations.start_roll()
			animations.set_crouching(input_handler.is_crouching())
			anim_name = animations.update(self, anim_player, delta)
		if anim_name != "":
			rpc("remote_set_animation", anim_name)
		rpc("sync_transform", global_transform)

@rpc("any_peer", "unreliable")
func remote_set_animation(anim_name: String) -> void:
	if is_multiplayer_authority():
		return
	if anim_player == null:
		return
	if anim_name == "":
		return
	if anim_player.current_animation != anim_name:
		anim_player.play(anim_name)

@rpc("any_peer", "unreliable")
func sync_transform(t: Transform3D) -> void:
	if not is_multiplayer_authority():
		global_transform = t

func _process(delta: float) -> void:
	if is_multiplayer_authority():
		camera_controller.update(self, input_handler, delta)

func _input(event: InputEvent) -> void:
	if is_multiplayer_authority():
		input_handler.update_mouse_input(event)
