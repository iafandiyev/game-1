extends Zombie

class_name Screamer

## Screamer - Detection zombie
## Screams to attract other zombies when player is detected

@export var scream_cooldown: float = 15.0
@export var scream_radius: float = 500.0
@export var scream_duration: float = 3.0
@export var scream_damage: float = 5.0
@export var scream_stun_duration: float = 1.0

var scream_timer: float = 0.0
var is_screaming: bool = false
var scream_effect_timer: float = 0.0

func _ready() -> void:
	zombie_type = "screamer"
	max_health = 60.0
	damage = 10.0
	move_speed = 50.0
	chase_speed = 70.0
	detection_range = 400.0
	attack_range = 40.0
	attack_cooldown = 2.0
	sound_detection_range = 500.0
	fov_angle = 140.0
	knockback_resistance = 0.1
	infection_chance = 0.1
	xp_reward = 30
	loot_table = "screamer_loot"
	
	super._ready()

func _physics_process(delta: float) -> void:
	if current_state == State.DEAD:
		return
	
	if scream_timer > 0:
		scream_timer -= delta
	
	if is_screaming:
		scream_effect_timer -= delta
		if scream_effect_timer <= 0:
			_end_scream()
	
	super._physics_process(delta)

func _state_idle(delta: float) -> void:
	super._state_idle(delta)
	
	# Screamers are more alert
	if player_in_sight and scream_timer <= 0:
		_start_scream()

func _state_patrol(delta: float) -> void:
	super._state_patrol(delta)
	
	if player_in_sight and scream_timer <= 0:
		_start_scream()

func _state_suspicious(delta: float) -> void:
	super._state_suspicious(delta)
	
	if player_in_sight and scream_timer <= 0:
		_start_scream()

func _state_chase(delta: float) -> void:
	if not player_detected or last_known_player_position == Vector2.ZERO:
		_change_state(State.SEARCH)
		return
	
	var distance = global_position.distance_to(last_known_player_position)
	
	# Scream when close to player
	if distance < 200.0 and scream_timer <= 0:
		_start_scream()
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
	
	velocity.x = lerp(velocity.x, 0, 15.0 * delta)
	
	if attack_cooldown_timer <= 0 and _can_see_player():
		_perform_attack()

func _start_scream() -> void:
	is_screaming = true
	scream_timer = scream_cooldown
	scream_effect_timer = scream_duration
	
	if animation_player and animation_player.has_animation("scream"):
		animation_player.play("scream")
	
	AudioManager.play_zombie_sound("screamer", "scream")
	
	# Attract all nearby zombies
	_attract_zombies()
	
	# Damage and stun player if close
	var player = _get_player()
	if player:
		var distance = global_position.distance_to(player.global_position)
		if distance < scream_radius:
			player.take_damage(scream_damage, "scream", global_position)
			if player.has_method("stun"):
				player.stun(scream_stun_duration)

func _attract_zombies() -> void:
	# Find all zombies in radius and alert them
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsCircleQueryParameters2D.create(global_position, scream_radius, 1 << 1) # Enemy layer
	query.exclude = [get_rid()]
	
	var results = space_state.intersect_shape(query)
	for result in results:
		var zombie = result.collider
		if zombie and zombie.has_method("hear_noise"):
			zombie.hear_noise(global_position, 20.0) # Very loud
			if zombie.has_method("_change_state"):
				zombie._change_state(Zombie.State.CHASE)
				zombie.last_known_player_position = _get_player().global_position

func _end_scream() -> void:
	is_screaming = false

func _perform_attack() -> void:
	is_attacking = true
	attack_cooldown_timer = attack_cooldown
	
	if animation_player and animation_player.has_animation("attack"):
		animation_player.play("attack")
	
	AudioManager.play_zombie_sound("screamer", "attack")
	attacked.emit()
	
	var player = _get_player()
	if player and player.has_method("take_damage"):
		player.take_damage(damage, "zombie_screamer", global_position)

func take_damage(amount: float, damage_type: String = "physical", source_position: Vector2 = Vector2.ZERO) -> void:
	super.take_damage(amount, damage_type, source_position)
	
	# Screamer screams when damaged
	if scream_timer <= 0 and health > 0:
		_start_scream()

func die() -> void:
	# Final scream on death
	if not is_screaming:
		_start_scream()
	
	super.die()