extends Zombie

class_name Crawler

## Crawler - Low-profile zombie
## Moves through tight spaces, dangerous in vents and low corridors

@export var crawl_speed: float = 100.0
@export var pounce_cooldown: float = 6.0
@export var pounce_range: float = 300.0
@export var pounce_speed: float = 500.0
@export var vent_navigation: bool = true

var pounce_timer: float = 0.0
var is_pouncing: bool = false
var is_in_vent: bool = false

func _ready() -> void:
	zombie_type = "crawler"
	max_health = 50.0
	damage = 20.0
	move_speed = 70.0
	chase_speed = 120.0
	detection_range = 200.0
	attack_range = 40.0
	attack_cooldown = 1.2
	sound_detection_range = 250.0
	fov_angle = 150.0 # Wider FOV
	knockback_resistance = 0.4
	infection_chance = 0.35
	xp_reward = 15
	loot_table = "crawler_loot"
	
	# Collision shape is lower
	if collision_shape and collision_shape.shape is RectangleShape2D:
		var shape = collision_shape.shape as RectangleShape2D
		shape.size = Vector2(shape.size.x, 50)
		collision_shape.position = Vector2(0, 15)
	
	super._ready()

func _physics_process(delta: float) -> void:
	if current_state == State.DEAD:
		return
	
	if pounce_timer > 0:
		pounce_timer -= delta
	
	if is_pouncing:
		_update_pounce(delta)
	
	super._physics_process(delta)

func _state_chase(delta: float) -> void:
	if not player_detected or last_known_player_position == Vector2.ZERO:
		_change_state(State.SEARCH)
		return
	
	var distance = global_position.distance_to(last_known_player_position)
	var player = _get_player()
	
	# Pounce attack from distance
	if distance <= pounce_range and distance > attack_range * 2 and pounce_timer <= 0 and _can_see_player():
		_perform_pounce()
		return
	
	# Check if player is in vent/low area
	if player and _is_player_in_low_area(player):
		# Crawlers are faster in vents
		_move_towards(last_known_player_position, crawl_speed * 1.5)
	else:
		_move_towards(last_known_player_position, chase_speed)
	
	if distance < attack_range and _can_see_player():
		_change_state(State.ATTACK)

func _state_attack(delta: float) -> void:
	if not player_detected:
		_change_state(State.CHASE)
		return
	
	var distance = global_position.distance_to(last_known_player_position)
	
	if distance > attack_range * 1.5:
		_change_state(State.CHASE)
		return
	
	velocity.x = lerp(velocity.x, 0, 20.0 * delta)
	
	if attack_cooldown_timer <= 0 and _can_see_player():
		_perform_attack()

func _perform_pounce() -> void:
	pounce_timer = pounce_cooldown
	is_pouncing = true
	
	var player = _get_player()
	if not player:
		return
	
	var direction = (player.global_position - global_position).normalized()
	velocity = direction * pounce_speed
	
	if animation_player and animation_player.has_animation("pounce"):
		animation_player.play("pounce")
	
	AudioManager.play_zombie_sound("crawler", "pounce")
	
	var timer = Timer.new()
	timer.wait_time = 0.6
	timer.one_shot = true
	timer.timeout.connect(_on_pounce_end)
	add_child(timer)
	timer.start()

func _on_pounce_end() -> void:
	is_pouncing = false

func _update_pounce(delta: float) -> void:
	# Check collision with player during pounce
	var player = _get_player()
	if player and global_position.distance_to(player.global_position) < 50.0:
		if player.has_method("take_damage"):
			player.take_damage(damage * 1.5, "crawler_pounce", global_position)
			_on_pounce_end()

func _is_player_in_low_area(player: Node) -> bool:
	# Check if player is crouching or in a low corridor
	if player.has_method("is_crouching_active"):
		return player.is_crouching_active()
	
	# Raycast down from player to check ceiling height
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(
		player.global_position,
		player.global_position + Vector2(0, -100),
		1 << 2 # World layer
	)
	query.exclude = [player.get_rid(), get_rid()]
	
	var result = space_state.intersect_ray(query)
	if result:
		var distance = player.global_position.distance_to(result.position)
		return distance < 80.0
	
	return false

func _perform_attack() -> void:
	is_attacking = true
	attack_cooldown_timer = attack_cooldown
	
	if animation_player and animation_player.has_animation("attack"):
		animation_player.play("attack")
	
	AudioManager.play_zombie_sound("crawler", "attack")
	attacked.emit()
	
	var player = _get_player()
	if player and player.has_method("take_damage"):
		player.take_damage(damage, "zombie_crawler", global_position)
		
		# High infection chance
		if randf() < infection_chance:
			SurvivalManager.add_infection(12.0)

func _can_see_player() -> bool:
	var player = _get_player()
	if not player:
		return false
	
	var direction_to_player = (player.global_position - global_position).normalized()
	var distance = global_position.distance_to(player.global_position)
	
	if distance > detection_range:
		return false
	
	# Crawlers have wider FOV
	var forward = Vector2(1 if facing_right else -1, 0)
	var angle = abs(forward.angle_to(direction_to_player))
	
	if angle > deg_to_rad(fov_angle / 2.0):
		return false
	
	# Raycast for line of sight (lower origin)
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(
		global_position + Vector2(0, -20),
		player.global_position + Vector2(0, -40),
		1 << 2
	)
	query.exclude = [get_rid(), player.get_rid()]
	
	return space_state.intersect_ray(query) == null

func take_damage(amount: float, damage_type: String = "physical", source_position: Vector2 = Vector2.ZERO) -> void:
	super.take_damage(amount, damage_type, source_position)
	
	# Crawlers are harder to hit when in vents
	if is_in_vent and damage_type != "explosion":
		amount *= 0.5