extends Node2D

class_name Rifle

## Rifle - 5.56mm assault rifle

@export var weapon_data: Dictionary = {}

func _ready() -> void:
	weapon_data = {
		"id": "rifle",
		"name": "Assault Rifle",
		"category": "ranged",
		"weapon_type": "rifle",
		"damage": 35,
		"fire_rate": 0.1,
		"reload_time": 2.5,
		"magazine_size": 30,
		"max_ammo": 90,
		"ammo_type": "556",
		"current_ammo": 30,
		"reserve_ammo": 60,
		"accuracy": 0.9,
		"recoil": 3.0,
		"recoil_recovery": 6.0,
		"spread": 0.015,
		"spread_increase": 0.008,
		"max_spread": 0.1,
		"range": 500,
		"sound_radius": 30.0,
		"muzzle_flash": "res://assets/effects/muzzle_flash_rifle.tscn",
		"shell_casing": "res://assets/effects/shell_casing_556.tscn"
	}

func get_data() -> Dictionary:
	return weapon_data