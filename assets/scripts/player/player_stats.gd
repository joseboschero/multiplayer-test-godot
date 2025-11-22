extends Resource
class_name PlayerStats

@export var speed: float = 6.0
@export var jump_force: float = 4.2
@export var gravity: float = 12.0

# Dash settings
@export var dash_speed: float = 20.0
@export var dash_duration: float = 0.2
@export var dash_cooldown: float = 0.5

# Super jump settings
@export var max_jump_charge_time: float = 2.0
@export var max_jump_force: float = 15.0
