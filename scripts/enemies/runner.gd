extends Zombie

class_name Runner

## Runner - Fast aggressive zombie
## Quickly closes distance and deals high damage

@export var lunge_cooldown: float = 5.0
@export var lunge_speed: float = 600.0
@export var lunge_range: float = 400.0

var lunge_timer: float = 0.0
var is_lunging: bool = false

func _ready() -> void:
	zombie_type = "runner"
	max_health = 75.0
	damage = 25.0
	move_speed = 180.0
	chase_speed = 280.0
	detection_range = 350.0
	attack_range = 55.0
	attack_cooldown = 1.0
	sound_detection_range = 300.0
	fov_angle = 130.0
	knockback_resistance = 0.2
	infection_chance = 0.25
	xp_reward = 20
	loot_table = "runner_loot"
	
	super._ready()

func _physics_process(delta: float) -> void:
	if current_state == State.DEAD:
		return
	
	if lunge_timer > 0:
		lunge_timer -= delta
	
	super._physics_process(delta)

func _state_chase(delta: float) -> void:
	if not player_detected or last_known_player_position == Vector2.ZERO:
		_change_state(State.SEARCH)
		return
	
	var distance = global_position.distance_to(last_known_player_position)
	
	# Lunge attack at medium range
	if distance <= lunge_range and distance > attack_range * 2 and lunge_timer <= 0 and _can_see_player():
		_perform_lunge()
		return
	
	if distance < attack_range and _can_see_player():
		_change_state(State.ATTACK)
		return
	
	# Runners don't use navigation, they charge directly
	_move_towards(last_known_player_position, chase_speed)

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

func _perform_lunge() -> void:
	lunge_timer = lunge_cooldown
	is_lunging = true
	
	var player = _get_player()
	if not player:
		return
	
	var direction = (player.global_position - global_position).normalized()
	velocity = direction * lunge_speed
	
	# Play lunge animation
	if animation_player and animation_player.has_animation("lunge"):
		animation_player.play("lunge")
	
	AudioManager.play_zombie_sound("runner", "lunge")
	
	# Timer to end lunge
	var timer = Timer.new()
	timer.wait_time = 0.5
	timer.one_shot = true
	timer.timeout.connect(_on_lunge_end)
	add_child(timer)
	timer.start()

func _on_lunge_end() -> void:
	is_lunging = false

func _perform_attack() -> void:
	is_attacking = true
	attack_cooldown_timer = attack_cooldown
	
	if animation_player and animation_player.has_animation("attack"):
		animation_player.play("attack")
	
	AudioManager.play_zombie_sound("runner", "attack")
	attacked.emit()
	
	var player = _get_player()
	if player and player.has_method("take_damage"):
		player.take_damage(damage, "zombie_runner", global_position)
		
		# Higher infection chance for runners
		if randf() < infection_chance:
			SurvivalManager.add_infection(8.0)

func take_damage(amount: float, damage_type: String = "physical", source_position: Vector2 = Vector2.ZERO) -> void:
	# Runners are more vulnerable to headshots
	if damage_type == "headshot":
		amount *= 2.0
	
	super.take_damage(amount, damage_type, source_position)
	
	# Runners get enraged when damaged
	if current_state != State.CHASE and current_state != State.ATTACK:
		_change_state(State.CHASE)