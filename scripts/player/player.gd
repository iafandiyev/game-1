extends CharacterBody2D

class_name Player

## Player - Main player character controller
## Handles movement, combat, animation, and interaction

signal health_changed(current: float, max: float)
signal stamina_changed(current: float, max: float)
signal weapon_changed(weapon: Dictionary)
signal ammo_changed(current: int, reserve: int)
signal inventory_changed()
signal interaction_available(interactable: Node)
signal interaction_unavailable()
signal died()
signal checkpoint_reached(checkpoint_id: String)

@export_group("Movement")
@export var walk_speed: float = 180.0
@export var run_speed: float = 320.0
@export var crouch_speed: float = 80.0
@export var jump_velocity: float = -450.0
@export var gravity: float = 980.0
@export var acceleration: float = 15.0
@export var deceleration: float = 20.0
@export var air_acceleration: float = 8.0
@export var air_deceleration: float = 5.0
@export var coyote_time: float = 0.1
@export var jump_buffer_time: float = 0.1
@export var wall_slide_speed: float = 150.0
@export var wall_jump_force: float = 350.0

@export_group("Combat")
@export var melee_range: float = 60.0
@export var melee_damage: float = 30.0
@export var melee_knockback: float = 300.0
@export var melee_cooldown: float = 0.6
@export var interaction_range: float = 80.0

@export_group("Components")
@export var animation_player: AnimationPlayer
@export var sprite: AnimatedSprite2D
@export var collision_shape: CollisionShape2D
@export var weapon_pivot: Node2D
@export var aim_target: Marker2D
@export var flashlight: Node2D
@export var muzzle_flash_spawn: Marker2D
@export var shell_eject_spawn: Marker2D

@export_group("References")
@export var camera: Camera2D

# State
var current_weapon: Dictionary = null
var weapon_instance: Node = null
var velocity = Vector2.ZERO
var is_on_floor: bool = false
var is_on_wall: bool = false
var wall_normal: Vector2 = Vector2.ZERO
var facing_right: bool = true
var is_crouching: bool = false
var is_running: bool = false
var is_aiming: bool = false
var is_reloading: bool = false
var is_attacking: bool = false
var can_jump: bool = false
var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0
var melee_cooldown_timer: float = 0.0
var last_damage_time: float = 0.0
var invulnerability_time: float = 1.0
var flashlight_on: bool = false
var flashlight_battery: float = 100.0

# Input state
var move_input: Vector2 = Vector2.ZERO
var aim_input: Vector2 = Vector2.ZERO

# Weapon slots
var weapon_slots: Array[Dictionary] = [null, null, null, null]
var current_weapon_slot: int = 0

# Animation states
enum AnimState {
	IDLE,
	WALK,
	RUN,
	CROUCH,
	CROUCH_WALK,
	JUMP,
	FALL,
	LAND,
	WALL_SLIDE,
	AIM_IDLE,
	AIM_WALK,
	AIM_RUN,
	MELEE,
	RELOAD,
	INTERACT,
	DEATH
}

var current_anim_state: AnimState = AnimState.IDLE

func _ready() -> void:
	_setup_references()
	_connect_signals()
	_load_equipment()
	_setup_collision_layers()

func _setup_references() -> void:
	if not animation_player:
		animation_player = get_node_or_null("AnimationPlayer")
	if not sprite:
		sprite = get_node_or_null("AnimatedSprite2D")
	if not collision_shape:
		collision_shape = get_node_or_null("CollisionShape2D")
	if not weapon_pivot:
		weapon_pivot = get_node_or_null("WeaponPivot")
	if not aim_target:
		aim_target = get_node_or_null("AimTarget")
	if not flashlight:
		flashlight = get_node_or_null("Flashlight")
	if not muzzle_flash_spawn:
		muzzle_flash_spawn = get_node_or_null("MuzzleFlashSpawn")
	if not shell_eject_spawn:
		shell_eject_spawn = get_node_or_null("ShellEjectSpawn")

func _connect_signals() -> void:
	InputManager.move_input.connect(_on_move_input)
	InputManager.aim_input.connect(_on_aim_input)
	InputManager.jump_pressed.connect(_on_jump_pressed)
	InputManager.jump_released.connect(_on_jump_released)
	InputManager.crouch_pressed.connect(_on_crouch_pressed)
	InputManager.crouch_released.connect(_on_crouch_released)
	InputManager.run_pressed.connect(_on_run_pressed)
	InputManager.run_released.connect(_on_run_released)
	InputManager.shoot_pressed.connect(_on_shoot_pressed)
	InputManager.shoot_released.connect(_on_shoot_released)
	InputManager.reload_pressed.connect(_on_reload_pressed)
	InputManager.interact_pressed.connect(_on_interact_pressed)
	InputManager.flashlight_pressed.connect(_on_flashlight_pressed)
	InputManager.inventory_pressed.connect(_on_inventory_pressed)
	InputManager.weapon_switch.connect(_on_weapon_switch)

func _load_equipment() -> void:
	# Load starting equipment
	equip_weapon(load_weapon_data("baseball_bat"), 0)
	equip_weapon(load_weapon_data("pistol"), 1)
	current_weapon_slot = 1
	switch_weapon(1)

func setup_collision_layers() -> void:
	collision_layer = 1 << 0  # Player layer
	collision_mask = (1 << 2) | (1 << 1) | (1 << 5)  # World, Enemy, Trigger

func _physics_process(delta: float) -> void:
	if GameManager.current_state != GameManager.GameState.PLAYING:
		velocity = Vector2.ZERO
		return
	
	_process_movement(delta)
	_process_combat(delta)
	_process_flashlight(delta)
	_update_animation()
	_check_interactions()
	
	move_and_slide()

func _process_movement(delta: float) -> void:
	is_on_floor = is_on_floor()
	is_on_wall = is_on_wall_only()
	
	# Get input
	var input_dir = InputManager.get_move_vector()
	move_input = input_dir
	
	# Determine movement state
	var was_crouching = is_crouching
	is_crouching = InputManager.is_crouching_active()
	is_running = InputManager.is_running_active() and not is_crouching and move_input.x != 0
	
	# Calculate target speed
	var target_speed = walk_speed
	if is_running:
		target_speed = run_speed
	elif is_crouching:
		target_speed = crouch_speed
	
	# Apply movement
	if is_on_floor:
		var accel = acceleration
		var decel = deceleration
		
		if move_input.x != 0:
			velocity.x = lerp(velocity.x, move_input.x * target_speed, accel * delta)
		else:
			velocity.x = lerp(velocity.x, 0, decel * delta)
		
		# Jump handling
		if jump_buffer_timer > 0:
			if can_jump or coyote_timer > 0:
				velocity.y = jump_velocity
				jump_buffer_timer = 0
				coyote_timer = 0
				can_jump = false
				AudioManager.play_sfx("jump")
	else:
		# Air movement
		var accel = air_acceleration
		var decel = air_deceleration
		
		if move_input.x != 0:
			velocity.x = lerp(velocity.x, move_input.x * target_speed, accel * delta)
		else:
			velocity.x = lerp(velocity.x, 0, decel * delta)
		
		# Wall slide
		if is_on_wall and velocity.y > 0:
			velocity.y = min(velocity.y, wall_slide_speed)
			wall_normal = get_wall_normal()
		
		# Coyote time
		if coyote_timer > 0:
			coyote_timer -= delta
	
	# Apply gravity
	velocity.y += gravity * delta
	
	# Update facing direction
	if move_input.x > 0:
		facing_right = true
	elif move_input.x < 0:
		facing_right = false
	
	# Update sprite flip
	if sprite:
		sprite.flip_h = not facing_right
	
	# Update weapon pivot
	if weapon_pivot:
		weapon_pivot.scale = Vector2(1, 1) if facing_right else Vector2(-1, 1)

func _process_combat(delta: float) -> void:
	is_aiming = InputManager.is_aiming_active()
	aim_input = InputManager.get_aim_position()
	
	# Update aim target
	if aim_target:
		aim_target.global_position = aim_input
	
	# Rotate weapon pivot towards aim
	if weapon_pivot and current_weapon and current_weapon.get("category") == "ranged":
		var direction = (aim_input - weapon_pivot.global_position).normalized()
		weapon_pivot.rotation = direction.angle()
		
		# Flip weapon vertically if aiming down
		if direction.y > 0 and facing_right or direction.y < 0 and not facing_right:
			weapon_pivot.scale = Vector2(1, -1) * abs(weapon_pivot.scale.x)
		else:
			weapon_pivot.scale = Vector2(1, 1) * abs(weapon_pivot.scale.x)
	
	# Melee cooldown
	if melee_cooldown_timer > 0:
		melee_cooldown_timer -= delta
	
	# Reload handling
	if is_reloading and current_weapon:
		# Reload is handled by weapon script via animation events
		pass

func _process_flashlight(delta: float) -> void:
	if flashlight_on:
		flashlight_battery -= delta * 5.0 # 5% per second
		flashlight_battery = max(0.0, flashlight_battery)
		
		if flashlight_battery <= 0:
			toggle_flashlight(false)
		
		if flashlight:
			flashlight.visible = true
			# Flicker when low
			if flashlight_battery < 20 and randf() < 0.05:
				flashlight.modulate = Color(1, 1, 1, 0.5)
			else:
				flashlight.modulate = Color(1, 1, 1, 1)
	else:
		if flashlight:
			flashlight.visible = false

func _update_animation() -> void:
	var new_state = _determine_animation_state()
	
	if new_state != current_anim_state:
		current_anim_state = new_state
		_play_animation(new_state)
	
	# Update animation parameters
	if animation_player:
		animation_player.set_parameter("move_speed", abs(velocity.x))
		animation_player.set_parameter("vertical_velocity", velocity.y)

func _determine_animation_state() -> AnimState:
	if is_dead():
		return AnimState.DEATH
	
	if is_attacking:
		return AnimState.MELEE
	
	if is_reloading:
		return AnimState.RELOAD
	
	if not is_on_floor:
		if velocity.y < 0:
			return AnimState.JUMP
		else:
			return AnimState.FALL
	
	if is_on_wall and velocity.y > 0:
		return AnimState.WALL_SLIDE
	
	if is_crouching:
		if abs(velocity.x) > 10:
			return AnimState.CROUCH_WALK
		return AnimState.CROUCH
	
	if is_aiming:
		if is_running:
			return AnimState.AIM_RUN
		elif abs(velocity.x) > 10:
			return AnimState.AIM_WALK
		return AnimState.AIM_IDLE
	
	if is_running:
		return AnimState.RUN
	
	if abs(velocity.x) > 10:
		return AnimState.WALK
	
	return AnimState.IDLE

func _play_animation(state: AnimState) -> void:
	if not animation_player:
		return
	
	var anim_name = ""
	match state:
		AnimState.IDLE: anim_name = "idle"
		AnimState.WALK: anim_name = "walk"
		AnimState.RUN: anim_name = "run"
		AnimState.CROUCH: anim_name = "crouch_idle"
		AnimState.CROUCH_WALK: anim_name = "crouch_walk"
		AnimState.JUMP: anim_name = "jump"
		AnimState.FALL: anim_name = "fall"
		AnimState.LAND: anim_name = "land"
		AnimState.WALL_SLIDE: anim_name = "wall_slide"
		AnimState.AIM_IDLE: anim_name = "aim_idle"
		AnimState.AIM_WALK: anim_name = "aim_walk"
		AnimState.AIM_RUN: anim_name = "aim_run"
		AnimState.MELEE: anim_name = "melee"
		AnimState.RELOAD: anim_name = "reload"
		AnimState.INTERACT: anim_name = "interact"
		AnimState.DEATH: anim_name = "death"
	
	if animation_player.has_animation(anim_name):
		animation_player.play(anim_name)

func _check_interactions() -> void:
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(
		global_position,
		global_position + Vector2(interaction_range * (1 if facing_right else -1), 0),
		1 << 5 # Interactable layer
	)
	query.exclude = [get_rid()]
	
	var result = space_state.intersect_ray(query)
	if result:
		var interactable = result.collider
		if interactable and interactable.has_method("can_interact"):
			interaction_available.emit(interactable)
			return
	
	interaction_unavailable.emit()

# Input callbacks
func _on_move_input(direction: Vector2) -> void:
	move_input = direction

func _on_aim_input(position: Vector2) -> void:
	aim_input = position

func _on_jump_pressed() -> void:
	if is_on_floor or coyote_timer > 0:
		can_jump = true
		jump_buffer_timer = jump_buffer_time
	elif is_on_wall:
		# Wall jump
		velocity.y = jump_velocity * 0.8
		velocity.x = -wall_normal.x * wall_jump_force
		coyote_timer = 0
		AudioManager.play_sfx("jump")

func _on_jump_released() -> void:
	if velocity.y < 0:
		velocity.y *= 0.5 # Variable jump height

func _on_crouch_pressed() -> void:
	is_crouching = true
	_update_collision_shape()

func _on_crouch_released() -> void:
	# Check if we can stand up
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(
		global_position,
		global_position + Vector2(0, -60),
		1 << 2 # World layer
	)
	query.exclude = [get_rid()]
	
	if not space_state.intersect_ray(query):
		is_crouching = false
		_update_collision_shape()

func _on_run_pressed() -> void:
	if SurvivalManager.can_sprint():
		is_running = true

func _on_run_released() -> void:
	is_running = false

func _on_shoot_pressed() -> void:
	if current_weapon and current_weapon.get("category") == "ranged" and not is_reloading:
		_try_shoot()

func _on_shoot_released() -> void:
	pass

func _on_reload_pressed() -> void:
	if current_weapon and current_weapon.get("category") == "ranged":
		_try_reload()

func _on_interact_pressed() -> void:
	_interact()

func _on_flashlight_pressed() -> void:
	toggle_flashlight()

func _on_inventory_pressed() -> void:
	UIManager.show_inventory()

func _on_weapon_switch(index: int) -> void:
	if index >= 0 and index < weapon_slots.size() and weapon_slots[index]:
		switch_weapon(index)

# Combat functions
func _try_shoot() -> void:
	if not current_weapon:
		return
	
	var current_ammo = current_weapon.get("current_ammo", 0)
	var fire_rate = current_weapon.get("fire_rate", 0.1)
	
	if current_ammo <= 0:
		_try_reload()
		return
	
	# Check fire rate (would need a timer per weapon)
	_fire_weapon()

func _fire_weapon() -> void:
	if not current_weapon:
		return
	
	var weapon_data = current_weapon
	var damage = weapon_data.get("damage", 10)
	var spread = weapon_data.get("spread", 0.0)
	var range = weapon_data.get("range", 300)
	var pellets = weapon_data.get("pellets", 1)
	var sound_radius = weapon_data.get("sound_radius", 10.0)
	
	# Consume ammo
	weapon_data["current_ammo"] -= 1
	ammo_changed.emit(weapon_data["current_ammo"], weapon_data.get("reserve_ammo", 0))
	
	# Apply recoil
	var recoil = weapon_data.get("recoil", 2.0)
	velocity.x += -recoil * 50.0 * (1 if facing_right else -1)
	
	# Muzzle flash
	_spawn_muzzle_flash()
	
	# Shell casing
	_spawn_shell_casing()
	
	# Sound
	AudioManager.play_weapon_sound(weapon_data.get("weapon_type", "pistol"), "fire")
	
	# Attract zombies
	WorldManager.attract_zombies(global_position, sound_radius)
	
	# Fire projectiles
	for i in range(pellets):
		var angle = (aim_input - muzzle_flash_spawn.global_position).angle()
		angle += randf_range(-spread, spread)
		_fire_projectile(angle, damage, range)
	
	# Update weapon data in slot
	weapon_slots[current_weapon_slot] = weapon_data
	current_weapon = weapon_data
	weapon_changed.emit(weapon_data)

func _fire_projectile(angle: float, damage: float, range: float) -> void:
	var projectile_scene = preload("res://scenes/weapons/projectile.tscn")
	var projectile = projectile_scene.instantiate()
	projectile.global_position = muzzle_flash_spawn.global_position
	projectile.rotation = angle
	projectile.damage = damage
	projectile.range = range
	projectile.owner_id = get_instance_id()
	get_tree().get_root().add_child(projectile)

func _spawn_muzzle_flash() -> void:
	if muzzle_flash_spawn and current_weapon:
		var flash_scene = current_weapon.get("muzzle_flash")
		if flash_scene:
			var flash = load(flash_scene).instantiate()
			muzzle_flash_spawn.add_child(flash)

func _spawn_shell_casing() -> void:
	if shell_eject_spawn and current_weapon:
		var casing_scene = current_weapon.get("shell_casing")
		if casing_scene:
			var casing = load(casing_scene).instantiate()
			shell_eject_spawn.add_child(casing)

func _try_reload() -> void:
	if not current_weapon or is_reloading:
		return
	
	var current_ammo = current_weapon.get("current_ammo", 0)
	var magazine_size = current_weapon.get("magazine_size", 0)
	var reserve_ammo = current_weapon.get("reserve_ammo", 0)
	var reload_time = current_weapon.get("reload_time", 2.0)
	
	if current_ammo >= magazine_size or reserve_ammo <= 0:
		return
	
	is_reloading = true
	AudioManager.play_weapon_sound(current_weapon.get("weapon_type", "pistol"), "reload")
	
	# Play reload animation
	if animation_player and animation_player.has_animation("reload"):
		animation_player.play("reload")
	
	# Timer for reload completion
	var timer = Timer.new()
	timer.wait_time = reload_time
	timer.one_shot = true
	timer.timeout.connect(_on_reload_complete.bind(current_weapon))
	add_child(timer)
	timer.start()

func _on_reload_complete(weapon_data: Dictionary) -> void:
	is_reloading = false
	
	var magazine_size = weapon_data.get("magazine_size", 0)
	var reserve_ammo = weapon_data.get("reserve_ammo", 0)
	var needed = magazine_size - weapon_data.get("current_ammo", 0)
	var to_reload = min(needed, reserve_ammo)
	
	weapon_data["current_ammo"] += to_reload
	weapon_data["reserve_ammo"] -= to_reload
	
	ammo_changed.emit(weapon_data["current_ammo"], weapon_data["reserve_ammo"])
	
	weapon_slots[current_weapon_slot] = weapon_data
	current_weapon = weapon_data
	weapon_changed.emit(weapon_data)

func _interact() -> void:
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(
		global_position,
		global_position + Vector2(interaction_range * (1 if facing_right else -1), 0),
		1 << 5
	)
	query.exclude = [get_rid()]
	
	var result = space_state.intersect_ray(query)
	if result:
		var interactable = result.collider
		if interactable and interactable.has_method("interact"):
			interactable.interact(self)

# Weapon management
func load_weapon_data(weapon_id: String) -> Dictionary:
	var file = FileAccess.open("res://data/weapons/weapons.json", FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		file.close()
		var parse_result = JSON.parse_string(json_string)
		if parse_result.get("error") == OK:
			var weapons = parse_result.get("result").get("weapons", [])
			for w in weapons:
				if w["id"] == weapon_id:
					return w.duplicate(true)
	return {}

func equip_weapon(weapon_data: Dictionary, slot: int) -> void:
	if slot >= 0 and slot < weapon_slots.size():
		weapon_slots[slot] = weapon_data
		if slot == current_weapon_slot:
			switch_weapon(slot)

func switch_weapon(slot: int) -> void:
	if slot >= 0 and slot < weapon_slots.size() and weapon_slots[slot]:
		# Clean up old weapon
		if weapon_instance:
			weapon_instance.queue_free()
			weapon_instance = null
		
		current_weapon_slot = slot
		current_weapon = weapon_slots[slot]
		
		# Instantiate weapon model
		var model_path = current_weapon.get("model", "")
		if model_path != "":
			var model_scene = load(model_path)
			if model_scene:
				weapon_instance = model_scene.instantiate()
				weapon_pivot.add_child(weapon_instance)
		
		weapon_changed.emit(current_weapon)
		ammo_changed.emit(
			current_weapon.get("current_ammo", 0),
			current_weapon.get("reserve_ammo", 0)
		)
		
		AudioManager.play_weapon_sound(current_weapon.get("weapon_type", "pistol"), "equip")

func add_ammo(ammo_type: String, amount: int) -> void:
	for i in range(weapon_slots.size()):
		var weapon = weapon_slots[i]
		if weapon and weapon.get("ammo_type") == ammo_type:
			weapon["reserve_ammo"] = min(
				weapon.get("max_ammo", 999),
				weapon.get("reserve_ammo", 0) + amount
			)
			if i == current_weapon_slot:
				current_weapon = weapon
				ammo_changed.emit(
					current_weapon.get("current_ammo", 0),
					current_weapon.get("reserve_ammo", 0)
				)

func melee_attack() -> void:
	if melee_cooldown_timer > 0 or is_attacking:
		return
	
	is_attacking = true
	melee_cooldown_timer = melee_cooldown
	
	# Play animation
	if animation_player and animation_player.has_animation("melee"):
		animation_player.play("melee")
	
	AudioManager.play_sfx("melee_swing")
	
	# Check for hits
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(
		weapon_pivot.global_position,
		weapon_pivot.global_position + Vector2(melee_range * (1 if facing_right else -1), 0),
		1 << 1 # Enemy layer
	)
	query.exclude = [get_rid()]
	
	var results = space_state.intersect_ray(query)
	if results:
		var target = results.collider
		if target and target.has_method("take_damage"):
			target.take_damage(melee_damage, "melee", global_position)
			# Apply knockback
			if target is CharacterBody2D:
				target.apply_impulse(Vector2(melee_knockback * (1 if facing_right else -1), 0))
	
	# Timer to reset attacking state
	var timer = Timer.new()
	timer.wait_time = 0.3
	timer.one_shot = true
	timer.timeout.connect(_on_melee_end)
	add_child(timer)
	timer.start()

func _on_melee_end() -> void:
	is_attacking = false

func toggle_flashlight(force_state: bool = null) -> void:
	if force_state != null:
		flashlight_on = force_state
	else:
		flashlight_on = not flashlight_on
	
	if flashlight_on and flashlight_battery <= 0:
		flashlight_on = false

# Health & Damage
func take_damage(amount: float, damage_type: String = "physical", source_position: Vector2 = Vector2.ZERO) -> void:
	var current_time = Time.get_ticks_msec() / 1000.0
	if current_time - last_damage_time < invulnerability_time:
		return
	
	last_damage_time = current_time
	
	SurvivalManager.take_damage(amount, damage_type)
	health_changed.emit(SurvivalManager.get_stat("health"), SurvivalManager.get_stat("max_health"))
	
	# Screen shake
	UIManager.screen_shake(5.0, 0.2)
	
	# Flash red
	if sprite:
		var tween = sprite.create_tween()
		tween.tween_property(sprite, "modulate", Color(1, 0.2, 0.2, 1), 0.1)
		tween.tween_property(sprite, "modulate", Color(1, 1, 1, 1), 0.1)
	
	# Knockback
	if source_position != Vector2.ZERO:
		var direction = (global_position - source_position).normalized()
		velocity = direction * 300.0
	
	# Check death
	if SurvivalManager.get_stat("health") <= 0:
		die()

func heal(amount: float) -> void:
	SurvivalManager.heal(amount)
	health_changed.emit(SurvivalManager.get_stat("health"), SurvivalManager.get_stat("max_health"))

func die() -> void:
	GameManager.show_death_screen()
	died.emit()

func is_dead() -> bool:
	return SurvivalManager.get_stat("health") <= 0

# Stamina
func consume_stamina(amount: float) -> bool:
	return SurvivalManager.consume_stamina(amount)

# Inventory
func add_item(item_id: String, count: int = 1) -> bool:
	# Would integrate with InventoryManager
	return true

def remove_item(item_id: String, count: int = 1) -> bool:
	return true

# Checkpoint
func reach_checkpoint(checkpoint_id: String) -> void:
	GameManager.activate_checkpoint(checkpoint_id)
	checkpoint_reached.emit(checkpoint_id)
	UIManager.show_checkpoint_notification(checkpoint_id)

# Utility
func _update_collision_shape() -> void:
	if collision_shape and collision_shape.shape is RectangleShape2D:
		var shape = collision_shape.shape as RectangleShape2D
		if is_crouching:
			shape.size = Vector2(shape.size.x, 80)
			collision_shape.position = Vector2(0, 20)
		else:
			shape.size = Vector2(shape.size.x, 160)
			collision_shape.position = Vector2(0, 0)

func get_aim_direction() -> Vector2:
	if is_aiming:
		return (aim_input - global_position).normalized()
	return Vector2(1 if facing_right else -1, 0)

func get_save_data() -> Dictionary:
	return {
		"position": global_position,
		"health": SurvivalManager.get_stat("health"),
		"stamina": SurvivalManager.get_stat("stamina"),
		"hunger": SurvivalManager.get_stat("hunger"),
		"thirst": SurvivalManager.get_stat("thirst"),
		"infection": SurvivalManager.get_stat("infection"),
		"current_weapon_slot": current_weapon_slot,
		"weapon_slots": weapon_slots,
		"flashlight_battery": flashlight_battery,
		"facing_right": facing_right,
	}

func load_save_data(data: Dictionary) -> void:
	global_position = data.get("position", global_position)
	current_weapon_slot = data.get("current_weapon_slot", 0)
	weapon_slots = data.get("weapon_slots", weapon_slots)
	flashlight_battery = data.get("flashlight_battery", 100.0)
	facing_right = data.get("facing_right", true)
	
	if weapon_slots.size() > current_weapon_slot:
		switch_weapon(current_weapon_slot)