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

var current_anim: String = ""

# ---- Estado interno de salto ----
const JUMP_START_TIME := 0.20   # segundos que dura (aprox) la anim de inicio
const JUMP_LAND_TIME  := 0.20   # segundos que dura (aprox) la anim de aterrizar

var jump_state := "ground"      # "ground", "start", "air", "land"
var jump_state_time := 0.0


func update(player: CharacterBody3D, anim_player: AnimationPlayer, delta: float):
	if anim_player == null:
		return

	var vel: Vector3 = player.velocity
	var horizontal_speed := Vector2(vel.x, vel.z).length()
	var on_floor := player.is_on_floor()

	# Actualizamos temporizador del estado actual
	jump_state_time += delta

	# --------- LÓGICA DE ESTADOS DE SALTO ---------
	match jump_state:
		"ground":
			# Si dejamos de estar en el piso -> empezamos salto
			if not on_floor:
				jump_state = "start"
				jump_state_time = 0.0

		"start":
			# Si por algún motivo volvemos al piso rápido, cancelamos
			if on_floor:
				jump_state = "ground"
				jump_state_time = 0.0
			# Cuando pasa cierto tiempo, pasamos a estar en el aire
			elif jump_state_time >= JUMP_START_TIME:
				jump_state = "air"
				jump_state_time = 0.0

		"air":
			# Cuando volvemos a tocar el piso -> animación de aterrizar
			if on_floor:
				jump_state = "land"
				jump_state_time = 0.0

		"land":
			# Después de la anim de aterrizar volvemos a estado normal
			if jump_state_time >= JUMP_LAND_TIME:
				jump_state = "ground"
				jump_state_time = 0.0

	# --------- ELEGIR ANIMACIÓN SEGÚN ESTADO ---------
	var target_anim := ""

	match jump_state:
		"start":
			target_anim = jumpstart_anim
		"air":
			target_anim = jumpinair_anim
		"land":
			target_anim = jumpfall_anim
		"ground":
			# En tierra: idle o caminar
			if horizontal_speed < 0.1:
				target_anim = idle_anim
			else:
				# Más adelante podés diferenciar caminar / sprint con stats.speed
				target_anim = move_anim

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
