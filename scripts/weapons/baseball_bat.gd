extends Node2D

class_name BaseballBat

## Baseball Bat - Melee weapon

@export var weapon_data: Dictionary = {}

func _ready() -> void:
	weapon_data = {
		"id": "baseball_bat",
		"name": "Baseball Bat",
		"category": "melee",
		"weapon_type": "blunt",
		"damage": 40,
		"attack_speed": 1.2,
		"stamina_cost": 15,
		"knockback": 5.0,
		"reach": 80,
		"accuracy": 1.0,
		"recoil": 0.0,
		"range": 80,
		"sound_radius": 2.0
	}

func get_data() -> Dictionary:
	return weapon_data