extends Resource
class_name PlayerAnimations

# (opcional) para usar luego con correr / caminar
@export var stats: PlayerStats

# Nombres de las animaciones en tu AnimationPlayer
@export var idle_anim: String = "Idle"
@export var move_anim: String = "Walk"
@export var jumpstart_anim: String = "Jump_Start"
@export var jumpinair_anim: String = "Jump"
@export var jumpfall_anim: String = "Jump_Land"
@export var sprint_anim: String = "Sprint"
@export var crouch_anim: String = "Crouch_Idle"
@export var crouch_walk_anim: String = "Crouch_Fwd"
@export var roll_anim: String = "Roll"   

var current_anim: String = ""

# ---- Estado interno de salto ----
const JUMP_START_TIME := 0.20   # segundos que dura (aprox) la anim de inicio
const JUMP_LAND_TIME  := 0.20   # segundos que dura (aprox) la anim de aterrizar

var jump_state := "ground"      # "ground", "start", "air", "land"
var jump_state_time := 0.0

# ---- Estado de agachado ----
var is_crouching := false

func set_crouching(crouch: bool) -> void:
	is_crouching = crouch

# ---- Estado de roll ----
const ROLL_TIME := 0.6          # ajustá a la duración de tu anim
var is_rolling := false
var roll_time := 0.0

func start_roll() -> void:
	# No reiniciar si ya está rodando (evita spam)
	if not is_rolling:
		is_rolling = true
		roll_time = 0.0


func update(player: CharacterBody3D, anim_player: AnimationPlayer, delta: float) -> String:
	if anim_player == null:
		return ""

	var vel: Vector3 = player.velocity
	var horizontal_speed := Vector2(vel.x, vel.z).length()
	var on_floor := player.is_on_floor()

	# ---- actualizar roll ----
	if is_rolling:
		roll_time += delta
		if roll_time >= ROLL_TIME:
			is_rolling = false

	# ---- actualizar estados de salto ----
	jump_state_time += delta

	match jump_state:
		"ground":
			if not on_floor:
				jump_state = "start"
				jump_state_time = 0.0

		"start":
			if on_floor:
				jump_state = "ground"
				jump_state_time = 0.0
			elif jump_state_time >= JUMP_START_TIME:
				jump_state = "air"
				jump_state_time = 0.0

		"air":
			if on_floor:
				jump_state = "land"
				jump_state_time = 0.0

		"land":
			if jump_state_time >= JUMP_LAND_TIME:
				jump_state = "ground"
				jump_state_time = 0.0

	# --------- ELEGIR ANIMACIÓN ---------
	var target_anim := ""

	# 1️⃣ Prioridad absoluta: si está haciendo roll, usamos roll y listo
	if is_rolling:
		target_anim = roll_anim

	else:
		# 2️⃣ Luego el estado de salto / tierra
		match jump_state:
			"start":
				target_anim = jumpstart_anim
			"air":
				target_anim = jumpinair_anim
			"land":
				target_anim = jumpfall_anim
			"ground":
				# En tierra: miramos crouch + velocidad
				if is_crouching:
					if horizontal_speed < 0.1:
						target_anim = crouch_anim          # agachado quieto
					else:
						target_anim = crouch_walk_anim     # caminando agachado
				else:
					if horizontal_speed < 0.1:
						target_anim = idle_anim
					elif stats != null and horizontal_speed < stats.speed * 1.2:
						target_anim = move_anim            # caminar normal
					else:
						target_anim = sprint_anim          # correr

	_play_if_different(anim_player, target_anim)
	current_anim = target_anim
	return target_anim


func _play_if_different(anim_player: AnimationPlayer, name: String) -> void:
	if anim_player == null:
		return
	if name == "":
		return
	if anim_player.current_animation != name:
		anim_player.play(name)
