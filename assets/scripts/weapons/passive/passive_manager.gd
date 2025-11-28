extends Node

var passive_weapons = []

func add_passive_weapon(scene: PackedScene, owner: Node3D):
	var weapon = scene.instantiate()

	owner.add_child(weapon)  # se lo agregamos al jugador
	weapon.global_position = owner.global_position

	passive_weapons.append(weapon)
	return weapon
