extends Resource

class_name Active_Weapon_Resource

@export var Weapon_Name: String
@export var Activate_Anim: String
@export var Shoot_Anim: String
@export var Reload_Anim: String
@export var Deactivate_Anim: String
@export var Out_Of_Ammo_Anim: String

@export var Current_Ammo: int
@export var Reserve_Ammo: int
@export var Magazine: int
@export var Max_Ammo: int

@export var Auto_Fire: bool

# Nueva propiedad para guardar la referencia al nodo de arma
var Weapon_Node: Node3D = null
var Animation_Player: AnimationPlayer = null
