extends Node
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
	if event.is_action_pressed("Weapon_Up"):
		Weapon_Indicator = min(Weapon_Indicator+1, Weapon_Stack.size()-1)
		exit(Weapon_Stack[Weapon_Indicator])
		
	if event.is_action_pressed("Weapon_Down"):
		Weapon_Indicator = max(Weapon_Indicator-1,0)
		exit(Weapon_Stack[Weapon_Indicator])

func Initialize(_start_weapons: Array):
	# Llenar el diccionario de armas
	for weapon in _weapon_resources:
		print("weapon", weapon.Weapon_Name)
		Weapon_List[weapon.Weapon_Name] = weapon
	
	# DEBUGGING: Ver qué armas se cargaron
	print("Armas disponibles: ", Weapon_List.keys())
	
	# Validar que Start_Weapons tenga elementos
	if _start_weapons.is_empty():
		push_error("Start_Weapons está vacío!")
		return
		
	# Llenar el stack
	for i in _start_weapons:
		if not Weapon_List.has(i):
			push_error("Arma '" + i + "' no existe en Weapon_List!")
			continue
		Weapon_Stack.push_back(i)
	
	# Validar que tengamos al menos un arma
	if Weapon_Stack.is_empty():
		push_error("Weapon_Stack está vacío después de Initialize!")
		return
		
	Current_Weapon = Weapon_List[Weapon_Stack[0]]
	enter()
	
func enter():
	if Current_Weapon == null:
		push_error("Current_Weapon es null!")
		return
	Animation_Player.queue(Current_Weapon.Activate_Anim)
	
func Change_Weapon(weapon_name: String):
	# VALIDACIÓN CRÍTICA
	if not Weapon_List.has(weapon_name):
		push_error("Arma '" + weapon_name + "' no existe en Weapon_List!")
		print("Armas disponibles: ", Weapon_List.keys())
		return
		
	Current_Weapon = Weapon_List[weapon_name]
	Next_Weapon = ""
	enter()
	
func exit(_next_weapon: String):
	if _next_weapon != Current_Weapon.Weapon_Name:
		if Animation_Player.get_current_animation() != Current_Weapon.Deactivate_Anim:
			Animation_Player.play(Current_Weapon.Deactivate_Anim)
			Next_Weapon = _next_weapon

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == Current_Weapon.Deactivate_Anim:
		Change_Weapon(Next_Weapon)
