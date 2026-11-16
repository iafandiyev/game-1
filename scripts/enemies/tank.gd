extends Zombie

class_name Tank

## Tank - Heavy armored zombie
## High health, slow but devastating attacks

@export var charge_cooldown: float = 8.0
@export var charge_speed: float = 400.0
@export var slam_damage: float = 50.0
@export var slam_radius: float = 100.0
@export var armor: float = 0.5 # Damage reduction

var charge_timer: float = 0.0
var is_charging: bool = false
var slam_timer: float = 0.0

func _ready() -> void:
	zombie_type = "tank"
	max_health = 500.0
	damage = 40.0
	move_speed = 40.0
	chase_speed = 60.0
	detection_range = 300.0
	attack_range = 70.0
	attack_cooldown = 2.5
	sound_detection_range = 200.0
	fov_angle = 100.0
	knockback_resistance = 0.8
	infection_chance = 0.3
	xp_reward = 100
	loot_table = "tank_loot"
	
	super._ready()

func _physics_process(delta: float) -> void:
	if current_state == State.DEAD:
		return
	
	if charge_timer > 0:
		charge_timer -= delta
	
	if slam_timer > 0:
		slam_timer -= delta
		if slam_timer <= 0 and is_charging:
			_perform_slam()
	
	super._physics_process(delta)

func _state_chase(delta: float) -> void:
	if not player_detected or last_known_player_position == Vector2.ZERO:
		_change_state(State.SEARCH)
		return
	
	var distance = global_position.distance_to(last_known_player_position)
	
	# Charge attack at medium-long range
	if distance <= 300.0 and distance > attack_range * 2 and charge_timer <= 0 and _can_see_player():
		_start_charge()
		return
	
	if distance < attack_range and _can_see_player():
		_change_state(State.ATTACK)
		return
	
	_move_towards(last_known_player_position, chase_speed)

func _state_attack(delta: float) -> void:
	if not player_detected:
		_change_state(State.CHASE)
		return
	
	var distance = global_position.distance_to(last_known_player_position)
	
	if distance > attack_range * 1.5:
		_change_state(State.CHASE)
		return
	
	velocity.x = lerp(velocity.x, 0, 10.0 * delta)
	
	if attack_cooldown_timer <= 0 and _can_see_player():
		_perform_attack()

func _start_charge() -> void:
	charge_timer = charge_cooldown
	is_charging = true
	slam_timer = 1.5 # Time before slam
	
	if animation_player and animation_player.has_animation("charge_start"):
		animation_player.play("charge_start")
	
	AudioManager.play_zombie_sound("tank", "charge")

func _perform_slam() -> void:
	is_charging = false
	slam_timer = 0.0
	
	if animation_player and animation_player.has_animation("slam"):
		animation_player.play("slam")
	
	AudioManager.play_zombie_sound("tank", "slam")
	
	# Area damage
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsCircleQueryParameters2D.create(global_position, slam_radius, 1 << 0) # Player layer
	query.exclude = [get_rid()]
	
	var results = space_state.intersect_shape(query)
	for result in results:
		var target = result.collider
		if target and target.has_method("take_damage"):
			target.take_damage(slam_damage, "tank_slam", global_position)
			# Knockback
			if target is CharacterBody2D:
				var direction = (target.global_position - global_position).normalized()
				target.apply_impulse(direction * 500.0)
	
	# Screen shake for nearby players
	UIManager.screen_shake(15.0, 0.5)

func _perform_attack() -> void:
	is_attacking = true
	attack_cooldown_timer = attack_cooldown
	
	if animation_player and animation_player.has_animation("attack"):
		animation_player.play("attack")
	
	AudioManager.play_zombie_sound("tank", "attack")
	attacked.emit()
	
	var player = _get_player()
	if player and player.has_method("take_damage"):
		player.take_damage(damage, "zombie_tank", global_position)
		
		if randf() < infection_chance:
			SurvivalManager.add_infection(10.0)

func take_damage(amount: float, damage_type: String = "physical", source_position: Vector2 = Vector2.ZERO) -> void:
	# Apply armor
	amount *= (1.0 - armor)
	
	# Tanks are resistant to knockback
	super.take_damage(amount, damage_type, source_position)
	
	# Tanks get enraged at low health
	if health / max_health < 0.3 and current_state != State.CHASE and current_state != State.ATTACK:
		_change_state(State.CHASE)
		move_speed *= 1.3
		chase_speed *= 1.3
		attack_cooldown *= 0.7