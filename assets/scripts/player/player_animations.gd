extends Resource
class_name PlayerAnimations

# Nombres de las animaciones en tu AnimationPlayer
@export var idle_anim: String = "Idle"
@export var move_anim: String = "Walk"      # o "Walk", "Jog_Forward", etc.
@export var jump_anim: String = "Jump"
@export var fall_anim: String = "Fall"

func update(player: CharacterBody3D, anim_player: AnimationPlayer, delta: float) -> void:
	var vel: Vector3 = player.velocity
	var horizontal_speed := Vector2(vel.x, vel.z).length()
	var on_floor := player.is_on_floor()

	var target_anim := ""

	if not on_floor:
		if vel.y > 0.0:
			target_anim = jump_anim
		else:
			target_anim = fall_anim
	else:
		if horizontal_speed < 0.1:
			target_anim = idle_anim
		else:
			target_anim = move_anim

	_play_if_different(anim_player, target_anim)


func _play_if_different(anim_player: AnimationPlayer, name: String) -> void:
	if name == "":
		return
	if anim_player.current_animation != name:
		anim_player.play(name)
