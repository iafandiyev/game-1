extends Node2D

class_name Shotgun

## Shotgun - 12 gauge pump-action shotgun

@export var weapon_data: Dictionary = {}

func _ready() -> void:
	weapon_data = {
		"id": "shotgun",
		"name": "12 Gauge Shotgun",
		"category": "ranged",
		"weapon_type": "shotgun",
		"damage": 15,
		"pellets": 8,
		"fire_rate": 1.0,
		"reload_time": 3.0,
		"magazine_size": 8,
		"max_ammo": 32,
		"ammo_type": "12gauge",
		"current_ammo": 8,
		"reserve_ammo": 24,
		"accuracy": 0.6,
		"recoil": 8.0,
		"recoil_recovery": 4.0,
		"spread": 0.1,
		"spread_increase": 0.05,
		"max_spread": 0.3,
		"range": 100,
		"sound_radius": 25.0,
		"muzzle_flash": "res://assets/effects/muzzle_flash_shotgun.tscn",
		"shell_casing": "res://assets/effects/shell_casing_12g.tscn"
	}

func get_data() -> Dictionary:
	return weapon_data