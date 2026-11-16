extends Node

class_name InputManager

## InputManager - Unified input handling for desktop and mobile
## Supports keyboard/mouse, gamepad, and touch controls

signal move_input(direction: Vector2)
signal aim_input(position: Vector2)
signal jump_pressed()
signal jump_released()
signal crouch_pressed()
signal crouch_released()
signal run_pressed()
signal run_released()
signal shoot_pressed()
signal shoot_released()
signal reload_pressed()
signal interact_pressed()
signal flashlight_pressed()
signal inventory_pressed()
signal pause_pressed()
signal weapon_switch(weapon_index: int)

# Input state
var move_vector: Vector2 = Vector2.ZERO
var aim_position: Vector2 = Vector2.ZERO
var is_aiming: bool = false
var is_running: bool = false
var is_crouching: bool = false

# Touch control state
var touch_joystick_active: bool = false
var touch_joystick_id: int = -1
var touch_joystick_center: Vector2 = Vector2.ZERO
var touch_aim_active: bool = false
var touch_aim_id: int = -1
var touch_aim_center: Vector2 = Vector2.ZERO

# Button states
var touch_buttons: Dictionary = {
	"jump": {"pressed": false, "id": -1},
	"crouch": {"pressed": false, "id": -1},
	"shoot": {"pressed": false, "id": -1},
	"reload": {"pressed": false, "id": -1},
	"interact": {"pressed": false, "id": -1},
}

var use_touch_controls: bool = false
var joystick_deadzone: float = 0.15
var joystick_radius: float = 80.0

func _ready() -> void:
	_process_mode = Node.PROCESS_MODE_ALWAYS
	_detect_platform()
	_setup_input_map()

func _detect_platform() -> void:
	use_touch_controls = OS.has_touchscreen_ui_hint()
	if use_touch_controls:
		Input.mouse_mode = Input.MOUSE_MODE_HIDDEN

func _setup_input_map() -> void:
	# Ensure all actions exist in InputMap
	var actions = [
		"move_left", "move_right", "move_up", "move_down",
		"jump", "crouch", "run",
		"shoot", "aim", "reload",
		"interact", "flashlight", "inventory",
		"pause", "weapon_1", "weapon_2", "weapon_3", "weapon_4"
	]
	
	for action in actions:
		if not InputMap.has_action(action):
			InputMap.add_action(action)

func _process(delta: float) -> void:
	_process_keyboard_input()
	_process_gamepad_input()
	
	if use_touch_controls:
		_process_touch_input()

func _process_keyboard_input() -> void:
	var move_x = 0.0
	var move_y = 0.0
	
	if Input.is_action_pressed("move_left"):
		move_x -= 1.0
	if Input.is_action_pressed("move_right"):
		move_x += 1.0
	if Input.is_action_pressed("move_up"):
		move_y -= 1.0
	if Input.is_action_pressed("move_down"):
		move_y += 1.0
	
	move_vector = Vector2(move_x, move_y).normalized()
	
	# Aim position from mouse
	if Input.is_action_pressed("aim"):
		is_aiming = true
		aim_position = get_viewport().get_mouse_position()
	else:
		is_aiming = false
	
	# Run
	var run_pressed_now = Input.is_action_just_pressed("run")
	var run_released_now = Input.is_action_just_released("run")
	if run_pressed_now:
		is_running = true
		run_pressed.emit()
	elif run_released_now:
		is_running = false
		run_released.emit()
	
	# Jump
	if Input.is_action_just_pressed("jump"):
		jump_pressed.emit()
	if Input.is_action_just_released("jump"):
		jump_released.emit()
	
	# Crouch
	if Input.is_action_just_pressed("crouch"):
		is_crouching = true
		crouch_pressed.emit()
	if Input.is_action_just_released("crouch"):
		is_crouching = false
		crouch_released.emit()
	
	# Shoot
	if Input.is_action_just_pressed("shoot"):
		shoot_pressed.emit()
	if Input.is_action_just_released("shoot"):
		shoot_released.emit()
	
	# Reload
	if Input.is_action_just_pressed("reload"):
		reload_pressed.emit()
	
	# Interact
	if Input.is_action_just_pressed("interact"):
		interact_pressed.emit()
	
	# Flashlight
	if Input.is_action_just_pressed("flashlight"):
		flashlight_pressed.emit()
	
	# Inventory
	if Input.is_action_just_pressed("inventory"):
		inventory_pressed.emit()
	
	# Pause
	if Input.is_action_just_pressed("pause"):
		pause_pressed.emit()
	
	# Weapon switching
	for i in range(1, 5):
		if Input.is_action_just_pressed("weapon_%d" % i):
			weapon_switch.emit(i - 1)

func _process_gamepad_input() -> void:
	if Input.get_connected_joypads().is_empty():
		return
	
	var joypad = Input.get_connected_joypads()[0]
	
	# Left stick for movement
	var stick_x = Input.get_joy_axis(joypad, JoyAxis.LEFT_X)
	var stick_y = Input.get_joy_axis(joypad, JoyAxis.LEFT_Y)
	
	if abs(stick_x) > joystick_deadzone or abs(stick_y) > joystick_deadzone:
		move_vector = Vector2(stick_x, stick_y).normalized()
	else:
		move_vector = Vector2.ZERO
	
	# Right stick for aiming
	var aim_x = Input.get_joy_axis(joypad, JoyAxis.RIGHT_X)
	var aim_y = Input.get_joy_axis(joypad, JoyAxis.RIGHT_Y)
	
	if abs(aim_x) > joystick_deadzone or abs(aim_y) > joystick_deadzone:
		is_aiming = true
		# Convert stick to screen position
		var viewport_size = get_viewport().get_visible_rect().size
		aim_position = Vector2(viewport_size.x / 2 + aim_x * viewport_size.x / 2,
							  viewport_size.y / 2 + aim_y * viewport_size.y / 2)
	else:
		is_aiming = false
	
	# Triggers
	if Input.is_action_just_pressed("shoot"):
		shoot_pressed.emit()
	if Input.is_action_just_released("shoot"):
		shoot_released.emit()
	
	# Buttons
	if Input.is_action_just_pressed("jump"):
		jump_pressed.emit()
	if Input.is_action_just_released("jump"):
		jump_released.emit()
	
	if Input.is_action_just_pressed("crouch"):
		is_crouching = true
		crouch_pressed.emit()
	if Input.is_action_just_released("crouch"):
		is_crouching = false
		crouch_released.emit()
	
	if Input.is_action_just_pressed("run"):
		is_running = true
		run_pressed.emit()
	if Input.is_action_just_released("run"):
		is_running = false
		run_released.emit()
	
	if Input.is_action_just_pressed("reload"):
		reload_pressed.emit()
	
	if Input.is_action_just_pressed("interact"):
		interact_pressed.emit()
	
	if Input.is_action_just_pressed("flashlight"):
		flashlight_pressed.emit()
	
	if Input.is_action_just_pressed("inventory"):
		inventory_pressed.emit()
	
	if Input.is_action_just_pressed("pause"):
		pause_pressed.emit()

func _process_touch_input() -> void:
	# Touch input is handled via _unhandled_input for multi-touch
	pass

func _unhandled_input(event: InputEvent) -> void:
	if not use_touch_controls:
		return
	
	if event is InputEventScreenTouch:
		_handle_touch(event)
	elif event is InputEventScreenDrag:
		_handle_drag(event)

func _handle_touch(event: InputEventScreenTouch) -> void:
	var viewport_size = get_viewport().get_visible_rect().size
	var left_threshold = viewport_size.x * 0.4
	var right_threshold = viewport_size.x * 0.6
	
	if event.pressed:
		# Touch began
		if event.position.x < left_threshold:
			# Left side - movement joystick
			touch_joystick_active = true
			touch_joystick_id = event.index
			touch_joystick_center = event.position
		elif event.position.x > right_threshold:
			# Right side - aim/fire
			touch_aim_active = true
			touch_aim_id = event.index
			touch_aim_center = event.position
			is_aiming = true
			aim_position = event.position
			# Also treat as shoot press
			shoot_pressed.emit()
		else:
			# Center area - check for button presses
			_check_touch_buttons(event.position, true)
	else:
		# Touch ended
		if event.index == touch_joystick_id:
			touch_joystick_active = false
			touch_joystick_id = -1
			move_vector = Vector2.ZERO
		elif event.index == touch_aim_id:
			touch_aim_active = false
			touch_aim_id = -1
			is_aiming = false
			shoot_released.emit()
		else:
			_check_touch_buttons(event.position, false)

func _handle_drag(event: InputEventScreenDrag) -> void:
	if event.index == touch_joystick_id and touch_joystick_active:
		var delta = event.position - touch_joystick_center
		var distance = delta.length()
		
		if distance > joystick_radius:
			delta = delta.normalized() * joystick_radius
		
		move_vector = (delta / joystick_radius).clamp(Vector2(-1, -1), Vector2(1, 1))
	
	elif event.index == touch_aim_id and touch_aim_active:
		is_aiming = true
		aim_position = event.position

func _check_touch_buttons(position: Vector2, pressed: bool) -> void:
	var viewport_size = get_viewport().get_visible_rect().size
	var button_size = 80.0
	var button_margin = 20.0
	var bottom_y = viewport_size.y - button_size - button_margin
	
	# Button layout (right to left): Jump, Crouch, Reload, Interact
	var buttons = [
		{"name": "jump", "x": viewport_size.x - button_size - button_margin},
		{"name": "crouch", "x": viewport_size.x - (button_size + button_margin) * 2},
		{"name": "reload", "x": viewport_size.x - (button_size + button_margin) * 3},
		{"name": "interact", "x": viewport_size.x - (button_size + button_margin) * 4},
	]
	
	for btn in buttons:
		var rect = Rect2(btn["x"], bottom_y, button_size, button_size)
		if rect.has_point(position):
			var btn_data = touch_buttons[btn["name"]]
			if pressed and not btn_data["pressed"]:
				btn_data["pressed"] = true
				btn_data["id"] = -1 # Will be set by touch event
				_emit_button_signal(btn["name"], true)
			elif not pressed and btn_data["pressed"]:
				btn_data["pressed"] = false
				btn_data["id"] = -1
				_emit_button_signal(btn["name"], false)

func _emit_button_signal(button_name: String, pressed: bool) -> void:
	match button_name:
		"jump":
			if pressed: jump_pressed.emit()
			else: jump_released.emit()
		"crouch":
			if pressed:
				is_crouching = true
				crouch_pressed.emit()
			else:
				is_crouching = false
				crouch_released.emit()
		"reload":
			if pressed: reload_pressed.emit()
		"interact":
			if pressed: interact_pressed.emit()

func get_move_vector() -> Vector2:
	return move_vector

func get_aim_position() -> Vector2:
	return aim_position

func is_aiming_active() -> bool:
	return is_aiming

func is_running_active() -> bool:
	return is_running

func is_crouching_active() -> bool:
	return is_crouching

func set_touch_controls_enabled(enabled: bool) -> void:
	use_touch_controls = enabled
	if enabled:
		Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	else:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func get_touch_joystick_state() -> Dictionary:
	return {
		"active": touch_joystick_active,
		"center": touch_joystick_center,
		"vector": move_vector,
		"radius": joystick_radius,
	}

func get_touch_aim_state() -> Dictionary:
	return {
		"active": touch_aim_active,
		"center": touch_aim_center,
		"position": aim_position,
	}

func get_touch_button_states() -> Dictionary:
	var states = {}
	for name, data in touch_buttons:
		states[name] = data["pressed"]
	return states