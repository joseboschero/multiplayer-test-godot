extends Node

signal Weapon_Changed
signal Update_Ammo
signal Update_Weapon_Stack

@onready var Animation_Player = get_node("%AnimationPlayer")

var Current_Weapon = null
var Weapon_Stack = []
var Weapon_Indicator = 0
var Next_Weapon: String
var Weapon_List = {}

@export var _weapon_resources: Array[Active_Weapon_Resource]
@export var Start_Weapons: Array[String]


func _ready():
	Initialize(Start_Weapons)

func _input(event):
	if not is_multiplayer_authority():
		return

	if event.is_action_pressed("Weapon_Up"):
		Weapon_Indicator = min(Weapon_Indicator + 1, Weapon_Stack.size() - 1)
		exit(Weapon_Stack[Weapon_Indicator])

	if event.is_action_pressed("Weapon_Down"):
		Weapon_Indicator = max(Weapon_Indicator - 1, 0)
		exit(Weapon_Stack[Weapon_Indicator])
	
	if event.is_action_pressed("Shoot"):
		shoot()
		
	if event.is_action_pressed("Reload"):
		reload()


func Initialize(_start_weapons: Array):
	for weapon in _weapon_resources:
		Weapon_List[weapon.Weapon_Name] = weapon

	for i in _start_weapons:
		if Weapon_List.has(i):
			Weapon_Stack.push_back(i)

	Current_Weapon = Weapon_List[Weapon_Stack[0]]
	emit_signal("Update_Weapon_Stack", Weapon_Stack)
	enter()

func play_anim_local_and_remote(anim_name: String):
	Animation_Player.play(anim_name)

	var my_id = multiplayer.get_unique_id()
	for peer_id in multiplayer.get_peers():
		if peer_id != my_id:
			rpc_id(peer_id, "rpc_play_anim", anim_name)


@rpc("any_peer", "reliable")
func rpc_play_anim(anim_name: String):
	Animation_Player.play(anim_name)


func enter():
	if Current_Weapon == null:
		return

	play_anim_local_and_remote(Current_Weapon.Activate_Anim) 
	emit_signal("Weapon_Changed", Current_Weapon.Weapon_Name)
	emit_signal("Update_Ammo", [Current_Weapon.Current_Ammo, Current_Weapon.Reserve_Ammo])


func Change_Weapon(weapon_name: String):
	if not Weapon_List.has(weapon_name):
		return

	Current_Weapon = Weapon_List[weapon_name]
	Next_Weapon = ""
	enter()


func exit(_next_weapon: String):
	if _next_weapon != Current_Weapon.Weapon_Name:
		var current_anim = Animation_Player.get_current_animation()

		if current_anim != Current_Weapon.Deactivate_Anim:
			play_anim_local_and_remote(Current_Weapon.Deactivate_Anim)
			Next_Weapon = _next_weapon


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if not is_multiplayer_authority():
		return

	if anim_name == Current_Weapon.Deactivate_Anim:
		Change_Weapon(Next_Weapon)
		
	if anim_name == Current_Weapon.Shoot_Anim && Current_Weapon.Auto_Fire == true:
		if Input.is_action_pressed("Shoot"):
			shoot()

func shoot():
	if Current_Weapon.Current_Ammo != 0:
		if !Animation_Player.is_playing():
			play_anim_local_and_remote(Current_Weapon.Shoot_Anim)
			Current_Weapon.Current_Ammo -= 1
			emit_signal("Update_Ammo", [Current_Weapon.Current_Ammo, Current_Weapon.Reserve_Ammo])
	else:
		reload()

func reload():
	if Current_Weapon.Current_Ammo == Current_Weapon.Magazine:
		return
	
	elif !Animation_Player.is_playing():
		if Current_Weapon.Reserve_Ammo != 0:
			play_anim_local_and_remote(Current_Weapon.Reload_Anim)
			var Reload_Amount = min(Current_Weapon.Magazine-Current_Weapon.Current_Ammo,Current_Weapon.Magazine,Current_Weapon.Reserve_Ammo)
			
			Current_Weapon.Current_Ammo = Current_Weapon.Current_Ammo + Reload_Amount
			Current_Weapon.Reserve_Ammo = Current_Weapon.Reserve_Ammo - Reload_Amount
			
			emit_signal("Update_Ammo", [Current_Weapon.Current_Ammo, Current_Weapon.Reserve_Ammo])
		else:
			play_anim_local_and_remote(Current_Weapon.Out_Of_Ammo_Anim)
