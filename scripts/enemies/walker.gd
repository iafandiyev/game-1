extends Zombie

class_name Walker

## Walker - Basic slow zombie
## Standard shambling undead

func _ready() -> void:
	zombie_type = "walker"
	max_health = 100.0
	damage = 15.0
	move_speed = 60.0
	chase_speed = 80.0
	detection_range = 250.0
	attack_range = 45.0
	attack_cooldown = 1.8
	sound_detection_range = 150.0
	fov_angle = 110.0
	knockback_resistance = 0.3
	infection_chance = 0.15
	xp_reward = 10
	loot_table = "walker_loot"
	
	super._ready()

func _physics_process(delta: float) -> void:
	super._physics_process(delta)