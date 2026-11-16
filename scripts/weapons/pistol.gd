extends Node2D

class_name Pistol

## Pistol - 9mm semi-automatic pistol weapon script

@export var weapon_data: Dictionary = {}

func _ready() -> void:
	weapon_data = {
		"id": "pistol",
		"name": "9mm Pistol",
		"category": "ranged",
		"weapon_type": "pistol",
		"damage": 25,
		"fire_rate": 0.3,
		"reload_time": 2.0,
		"magazine_size": 15,
		"max_ammo": 60,
		"ammo_type": "9mm",
		"current_ammo": 15,
		"reserve_ammo": 45,
		"accuracy": 0.85,
		"recoil": 2.0,
		"recoil_recovery": 8.0,
		"spread": 0.02,
		"spread_increase": 0.01,
		"max_spread": 0.15,
		"range": 300,
		"sound_radius": 15.0,
		"muzzle_flash": "res://assets/effects/muzzle_flash_pistol.tscn",
		"shell_casing": "res://assets/effects/shell_casing_9mm.tscn"
	}

func get_data() -> Dictionary:
	return weapon_data