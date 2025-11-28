extends Node3D
class_name PassiveWeapon

@export var tick_rate: float = 1.0
@export var radius: float = 3.0
@export var auto_start: bool = true

var enemies_in_range: Array[Node3D] = []

@onready var area := $Area3D
@onready var timer := $Area3D/Timer
@onready var collision_shape := $Area3D/CollisionShape3D

func _ready():
	setup_area()
	setup_connections()
	if auto_start:
		timer.start()

func setup_area():
	var shape = collision_shape.shape
	if shape is SphereShape3D:
		shape.radius = radius
	timer.wait_time = tick_rate

func setup_connections():
	area.connect("body_entered", Callable(self, "_on_body_entered"))
	area.connect("body_exited", Callable(self, "_on_body_exited"))

func _on_body_entered(body):
	#print("🔍 Body detectado: ", body.name, " | Grupos: ", body.get_groups())
	if body.is_in_group("enemy"):
		#print("✓ Enemigo añadido al rango: ", body.name)
		enemies_in_range.append(body)

func _on_body_exited(body):
	enemies_in_range.erase(body)

func _on_timer_timeout():
	do_damage()

# Método virtual - las armas hijas deben implementarlo
func do_damage():
	pass
