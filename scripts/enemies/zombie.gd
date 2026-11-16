extends CharacterBody2D

class_name Zombie

## Zombie - Base zombie AI class
## Implements state machine for zombie behavior

signal died(position: Vector2, zombie_type: String)
signal detected_player()
signal lost_player()
signal attacked()
signal noise_heard(position: Vector2, loudness: float)

@export_group("Zombie Stats")
@export var zombie_type: String = "walker"
@export var max_health: float = 100.0
@export var damage: float = 15.0
@export var move_speed: float = 80.0
@export var chase_speed: float = 120.0
@export var detection_range: float = 300.0
@export var attack_range: float = 50.0
@export var attack_cooldown: float = 1.5
@export var sound_detection_range: float = 200.0
@export var fov_angle: float = 120.0
@export var knockback_resistance: float = 0.5
@export var infection_chance: float = 0.2

@export_group("Components")
@export var animation_player: AnimationPlayer
@export var sprite: AnimatedSprite2D
@export var collision_shape: CollisionShape2D
@export var detection_zone: Area2D
@export var attack_zone: Area2D
@export var health_bar: ProgressBar

@export_group("Loot")
@export var loot_table: String = "zombie_common"
@export var xp_reward: int = 10

# State machine
enum State {
	IDLE,
	PATROL,
	SUSPICIOUS,
	INVESTIGATE,
	CHASE,
	ATTACK,
	SEARCH,
	RETURN_PATROL,
	DEAD
}

var current_state: State = State.IDLE
var health: float = 100.0
var velocity = Vector2.ZERO
var gravity: float = 980.0
var target_position: Vector2 = Vector2.ZERO
var last_known_player_position: Vector2 = Vector2.ZERO
var player_in_sight: bool = false
var player_detected: bool = false
var attack_cooldown_timer: float = 0.0
var state_timer: float = 0.0
var patrol_points: Array[Vector2] = []
var current_patrol_index: int = 0
var patrol_wait_timer: float = 0.0
var search_timer: float = 0.0
var search_duration: float = 10.0
var return_patrol_timer: float = 0.0
var is_attacking: bool = false
var facing_right: bool = true
var last_damage_time: float = 0.0
var invulnerability_time: float = 0.2
var stun_timer: float = 0.0

# Navigation
var navigation_agent: NavigationAgent2D = null
var path: Array[Vector2] = []
var path_index: int = 0

func _ready() -> void:
	_setup_references()
	_setup_stats()
	_setup_collision()
	_setup_navigation()
	_start_idle_state()

func _setup_references() -> void:
	if not animation_player:
		animation_player = get_node_or_null("AnimationPlayer")
	if not sprite:
		sprite = get_node_or_null("AnimatedSprite2D")
	if not collision_shape:
		collision_shape = get_node_or_null("CollisionShape2D")
	if not detection_zone:
		detection_zone = get_node_or_null("DetectionZone")
	if not attack_zone:
		attack_zone = get_node_or_null("AttackZone")
	if not health_bar:
		health_bar = get_node_or_null("HealthBar")
	
	# Navigation
	navigation_agent = NavigationAgent2D.new()
	add_child(navigation_agent)

func _setup_stats() -> void:
	health = max_health
	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = health
		health_bar.visible = false

func _setup_collision() -> void:
	collision_layer = 1 << 1  # Enemy layer
	collision_mask = (1 << 2) | (1 << 0) | (1 << 4)  # World, Player, Projectile
	
	if detection_zone:
		detection_zone.monitoring = true
		detection_zone.monitorable = false
		detection_zone.connect("body_entered", _on_detection_body_entered.bind())
		detection_zone.connect("body_exited", _on_detection_body_exited.bind())
	
	if attack_zone:
		attack_zone.monitoring = true
		attack_zone.monitorable = false
		attack_zone.connect("body_entered", _on_attack_zone_body_entered.bind())

func _setup_navigation() -> void:
	if navigation_agent:
		navigation_agent.avoidance_enabled = true
		navigation_agent.path_desired_distance = 4.0

func _physics_process(delta: float) -> void:
	if current_state == State.DEAD:
		return
	
	_update_timers(delta)
	_state_machine(delta)
	_apply_physics(delta)
	_update_visuals()
	
	move_and_slide()

func _update_timers(delta: float) -> void:
	if attack_cooldown_timer > 0:
		attack_cooldown_timer -= delta
	if state_timer > 0:
		state_timer -= delta
	if patrol_wait_timer > 0:
		patrol_wait_timer -= delta
	if search_timer > 0:
		search_timer -= delta
	if return_patrol_timer > 0:
		return_patrol_timer -= delta
	if stun_timer > 0:
		stun_timer -= delta

func _state_machine(delta: float) -> void:
	match current_state:
		State.IDLE:
			_state_idle(delta)
		State.PATROL:
			_state_patrol(delta)
		State.SUSPICIOUS:
			_state_suspicious(delta)
		State.INVESTIGATE:
			_state_investigate(delta)
		State.CHASE:
			_state_chase(delta)
		State.ATTACK:
			_state_attack(delta)
		State.SEARCH:
			_state_search(delta)
		State.RETURN_PATROL:
			_state_return_patrol(delta)

func _state_idle(delta: float) -> void:
	velocity.x = lerp(velocity.x, 0, 10.0 * delta)
	
	if state_timer <= 0:
		if patrol_points.size() > 0:
			_change_state(State.PATROL)
		else:
			# Random idle time
			state_timer = randf_range(3.0, 8.0)

func _state_patrol(delta: float) -> void:
	if patrol_points.is_empty():
		_change_state(State.IDLE)
		return
	
	var target = patrol_points[current_patrol_index]
	var distance = global_position.distance_to(target)
	
	if distance < 20.0:
		# Reached patrol point
		patrol_wait_timer = randf_range(2.0, 5.0)
		current_patrol_index = (current_patrol_index + 1) % patrol_points.size()
		_change_state(State.IDLE)
		return
	
	_move_towards(target, move_speed)

func _state_suspicious(delta: float) -> void:
	velocity.x = lerp(velocity.x, 0, 5.0 * delta)
	
	# Look around
	if sprite and animation_player and animation_player.has_animation("look_around"):
		if not animation_player.is_playing():
			animation_player.play("look_around")
	
	if state_timer <= 0:
		_change_state(State.INVESTIGATE)

func _state_investigate(delta: float) -> void:
	if target_position == Vector2.ZERO:
		_change_state(State.SEARCH)
		return
	
	var distance = global_position.distance_to(target_position)
	
	if distance < 30.0:
		# Reached investigation point
		_change_state(State.SEARCH)
		return
	
	_move_towards(target_position, move_speed)

func _state_chase(delta: float) -> void:
	if not player_detected or last_known_player_position == Vector2.ZERO:
		_change_state(State.SEARCH)
		return
	
	var distance = global_position.distance_to(last_known_player_position)
	
	if distance < attack_range and _can_see_player():
		_change_state(State.ATTACK)
		return
	
	if distance < 50.0:
		# Close enough, try direct movement
		_move_towards(last_known_player_position, chase_speed)
	else:
		# Use navigation
		_navigate_to(last_known_player_position, chase_speed)

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

func _state_search(delta: float) -> void:
	velocity.x = lerp(velocity.x, 0, 5.0 * delta)
	
	if search_timer <= 0:
		if patrol_points.size() > 0:
			_change_state(State.RETURN_PATROL)
		else:
			_change_state(State.IDLE)
		return
	
	# Random search movement
	if randf() < 0.02:
		var random_offset = Vector2(randf_range(-100, 100), randf_range(-50, 50))
		_move_towards(last_known_player_position + random_offset, move_speed * 0.5)

func _state_return_patrol(delta: float) -> void:
	if patrol_points.is_empty():
		_change_state(State.IDLE)
		return
	
	var target = patrol_points[current_patrol_index]
	var distance = global_position.distance_to(target)
	
	if distance < 50.0:
		_change_state(State.PATROL)
		return
	
	_navigate_to(target, move_speed)

func _move_towards(target: Vector2, speed: float) -> void:
	var direction = (target - global_position).normalized()
	velocity.x = direction.x * speed
	
	# Update facing
	if direction.x > 0:
		facing_right = true
	elif direction.x < 0:
		facing_right = false
	
	# Jump over small obstacles
	if is_on_floor() and _check_obstacle_ahead():
		velocity.y = -300.0

func _navigate_to(target: Vector2, speed: float) -> void:
	if not navigation_agent:
		_move_towards(target, speed)
		return
	
	navigation_agent.target_position = target
	
	if navigation_agent.get_next_path_position() != Vector2.ZERO:
		var next_pos = navigation_agent.get_next_path_position()
		var direction = (next_pos - global_position).normalized()
		velocity.x = direction.x * speed
		
		if direction.x > 0:
			facing_right = true
		elif direction.x < 0:
			facing_right = false
		
		# Jump if needed
		if is_on_floor() and _check_obstacle_ahead():
			velocity.y = -300.0

func _check_obstacle_ahead() -> bool:
	var check_distance = 40.0
	var check_height = 20.0
	var direction = 1 if facing_right else -1
	
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(
		global_position + Vector2(0, -check_height),
		global_position + Vector2(direction * check_distance, -check_height),
		1 << 2 # World layer
	)
	query.exclude = [get_rid()]
	
	return space_state.intersect_ray(query) != null

func _can_see_player() -> bool:
	var player = _get_player()
	if not player:
		return false
	
	var direction_to_player = (player.global_position - global_position).normalized()
	var distance = global_position.distance_to(player.global_position)
	
	if distance > detection_range:
		return false
	
	# Check FOV
	var forward = Vector2(1 if facing_right else -1, 0)
	var angle = abs(forward.angle_to(direction_to_player))
	
	if angle > deg_to_rad(fov_angle / 2.0):
		return false
	
	# Raycast for line of sight
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(
		global_position + Vector2(0, -40),
		player.global_position + Vector2(0, -40),
		1 << 2 # World layer
	)
	query.exclude = [get_rid(), player.get_rid()]
	
	return space_state.intersect_ray(query) == null

func _get_player() -> Node:
	return get_tree().get_first_node_in_group("player")

func _perform_attack() -> void:
	is_attacking = true
	attack_cooldown_timer = attack_cooldown
	
	if animation_player and animation_player.has_animation("attack"):
		animation_player.play("attack")
	
	AudioManager.play_zombie_sound(zombie_type, "attack")
	attacked.emit()
	
	var player = _get_player()
	if player and player.has_method("take_damage"):
		player.take_damage(damage, "zombie_" + zombie_type, global_position)
		
		# Infection chance
		if randf() < infection_chance:
			SurvivalManager.add_infection(5.0)

func _apply_physics(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0

func _update_visuals() -> void:
	if sprite:
		sprite.flip_h = not facing_right
	
	if health_bar:
		health_bar.value = health
		health_bar.visible = health < max_health

# Detection signals
func _on_detection_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_detected = true
		last_known_player_position = body.global_position
		player_in_sight = _can_see_player()
		
		if player_in_sight:
			detected_player.emit()
			_change_state(State.CHASE)
		else:
			_change_state(State.SUSPICIOUS)

func _on_detection_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_sight = false

func _on_attack_zone_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and current_state == State.ATTACK:
		if attack_cooldown_timer <= 0:
			_perform_attack()

# Public API
func take_damage(amount: float, damage_type: String = "physical", source_position: Vector2 = Vector2.ZERO) -> void:
	var current_time = Time.get_ticks_msec() / 1000.0
	if current_time - last_damage_time < invulnerability_time:
		return
	
	last_damage_time = current_time
	
	health -= amount
	
	# Knockback
	if source_position != Vector2.ZERO:
		var direction = (global_position - source_position).normalized()
		var knockback = 300.0 * (1.0 - knockback_resistance)
		velocity = direction * knockback
		stun_timer = 0.3
	
	# Visual feedback
	if sprite:
		var tween = sprite.create_tween()
		tween.tween_property(sprite, "modulate", Color(1, 0.3, 0.3, 1), 0.1)
		tween.tween_property(sprite, "modulate", Color(1, 1, 1, 1), 0.1)
	
	if health_bar:
		health_bar.visible = true
	
	# React to damage
	if current_state != State.CHASE and current_state != State.ATTACK:
		if damage_type == "gunshot" or amount > 20:
			# Loud damage attracts attention
			last_known_player_position = source_position if source_position != Vector2.ZERO else _get_player().global_position
			_change_state(State.CHASE)
		else:
			_change_state(State.SUSPICIOUS)
	
	if health <= 0:
		die()

func die() -> void:
	current_state = State.DEAD
	
	# Disable collision
	collision_layer = 0
	collision_mask = 0
	if collision_shape:
		collision_shape.disabled = true
	if detection_zone:
		detection_zone.monitoring = false
	if attack_zone:
		attack_zone.monitoring = false
	
	# Play death animation
	if animation_player and animation_player.has_animation("death"):
		animation_player.play("death")
	
	AudioManager.play_zombie_sound(zombie_type, "death")
	
	# Drop loot
	_drop_loot()
	
	# Award XP
	GameManager.player_stats["experience"] = GameManager.player_stats.get("experience", 0) + xp_reward
	
	# Emit signal
	died.emit(global_position, zombie_type)
	
	# Queue free after animation
	var timer = Timer.new()
	timer.wait_time = 3.0
	timer.one_shot = true
	timer.timeout.connect(queue_free.bind())
	add_child(timer)
	timer.start()

func _drop_loot() -> void:
	# Would implement loot table system
	pass

func hear_noise(position: Vector2, loudness: float) -> void:
	if current_state == State.DEAD:
		return
	
	var distance = global_position.distance_to(position)
	var max_range = sound_detection_range * (loudness / 10.0)
	
	if distance <= max_range:
		target_position = position
		noise_heard.emit(position, loudness)
		
		if current_state == State.IDLE or current_state == State.PATROL:
			_change_state(State.SUSPICIOUS)
		elif current_state == State.CHASE or current_state == State.ATTACK:
			last_known_player_position = position

func set_patrol_points(points: Array[Vector2]) -> void:
	patrol_points = points

func _change_state(new_state: State) -> void:
	if current_state == new_state:
		return
	
	current_state = new_state
	state_timer = 0.0
	
	match new_state:
		State.IDLE:
			state_timer = randf_range(2.0, 6.0)
		State.SUSPICIOUS:
			state_timer = randf_range(1.0, 3.0)
		State.INVESTIGATE:
			pass
		State.SEARCH:
			search_timer = search_duration
		State.RETURN_PATROL:
			return_patrol_timer = 20.0
		State.DEAD:
			pass

func get_state_name() -> String:
	return current_state.name()

# Save/Load
func get_save_data() -> Dictionary:
	return {
		"position": global_position,
		"health": health,
		"state": int(current_state),
		"patrol_index": current_patrol_index,
		"facing_right": facing_right,
		"zombie_type": zombie_type,
	}

func load_save_data(data: Dictionary) -> void:
	global_position = data.get("position", global_position)
	health = data.get("health", max_health)
	current_state = State(data.get("state", 0))
	current_patrol_index = data.get("patrol_index", 0)
	facing_right = data.get("facing_right", true)
	
	if health_bar:
		health_bar.value = health