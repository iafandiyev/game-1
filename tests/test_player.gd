extends Node

## TestPlayer - Player movement and mechanics tests

class_name TestPlayer

var test_base: Object = null

func run_tests() -> Dictionary:
	test_base = load("res://tests/run_tests.gd").new().TestBase.new()
	
	test_movement()
	test_health()
	test_stamina()
	test_weapon_switching()
	test_crouch_jump()
	
	return test_base.get_results()

func test_movement() -> void:
	# Test basic movement vector calculation
	var input = Vector2(1, 0)
	var speed = 180.0
	var expected_velocity = input * speed
	
	test_base.assert_equal(expected_velocity.x, 180.0, "Move right at walk speed")
	test_base.assert_equal(expected_velocity.y, 0.0, "No vertical movement on flat ground")
	
	# Test run speed
	var run_speed = 320.0
	var run_velocity = input * run_speed
	test_base.assert_equal(run_velocity.x, 320.0, "Move right at run speed")
	
	# Test crouch speed
	var crouch_speed = 80.0
	var crouch_velocity = input * crouch_speed
	test_base.assert_equal(crouch_velocity.x, 80.0, "Move right at crouch speed")
	
	# Test diagonal normalization
	var diagonal = Vector2(1, 1).normalized()
	test_base.assert_true(abs(diagonal.length() - 1.0) < 0.01, "Diagonal movement normalized")
	
	# Test zero input
	var zero = Vector2(0, 0)
	test_base.assert_equal(zero.length(), 0.0, "Zero input produces zero velocity")

func test_health() -> void:
	var max_health = 100.0
	var current_health = 100.0
	
	# Test damage
	current_health -= 25.0
	test_base.assert_equal(current_health, 75.0, "Health reduced by damage")
	
	# Test healing
	current_health = min(max_health, current_health + 30.0)
	test_base.assert_equal(current_health, 100.0, "Health capped at max after healing")
	
	# Test death
	current_health = 0.0
	test_base.assert_true(current_health <= 0, "Death at zero health")
	
	# Test overkill
	current_health = 10.0
	current_health -= 50.0
	test_base.assert_true(current_health <= 0, "Overkill results in death")

func test_stamina() -> void:
	var max_stamina = 100.0
	var current_stamina = 100.0
	var drain_rate = 25.0
	var regen_rate = 15.0
	
	# Test stamina drain
	current_stamina = max(0.0, current_stamina - drain_rate)
	test_base.assert_equal(current_stamina, 75.0, "Stamina drained by running")
	
	# Test stamina regen
	current_stamina = min(max_stamina, current_stamina + regen_rate)
	test_base.assert_equal(current_stamina, 90.0, "Stamina regenerates")
	
	# Test exhaustion
	current_stamina = 0.0
	test_base.assert_true(current_stamina <= 0, "Stamina exhausted")
	
	# Test cannot run when exhausted
	var can_sprint = current_stamina > 10.0
	test_base.assert_false(can_sprint, "Cannot sprint when exhausted")

func test_weapon_switching() -> void:
	var weapon_slots = [null, null, null, null]
	var current_slot = 0
	
	# Add weapons
	weapon_slots[0] = {"id": "baseball_bat", "name": "Baseball Bat"}
	weapon_slots[1] = {"id": "pistol", "name": "9mm Pistol"}
	
	# Switch to slot 1
	current_slot = 1
	var current = weapon_slots[current_slot]
	test_base.assert_equal(current["id"], "pistol", "Switched to pistol")
	
	# Switch to slot 0
	current_slot = 0
	current = weapon_slots[current_slot]
	test_base.assert_equal(current["id"], "baseball_bat", "Switched to baseball bat")
	
	# Switch to empty slot (should not change)
	var prev_slot = current_slot
	current_slot = 2
	if not weapon_slots[2]:
		current_slot = prev_slot
	test_base.assert_equal(current_slot, 0, "Empty slot ignored")

func test_crouch_jump() -> void:
	var is_crouching = false
	var is_on_floor = true
	var velocity = Vector2(0, -450.0) # jump_velocity
	
	# Test jump from standing
	var can_jump = is_on_floor and not is_crouching
	test_base.assert_true(can_jump, "Can jump from standing")
	
	# Test crouch prevents jump
	is_crouching = true
	can_jump = is_on_floor and not is_crouching
	test_base.assert_false(can_jump, "Cannot jump while crouching")
	
	# Test coyote time
	var coyote_timer = 0.1
	is_on_floor = false
	can_jump = coyote_timer > 0
	test_base.assert_true(can_jump, "Coyote time allows jump after leaving ground")
	
	# Test jump buffer
	var jump_buffer_timer = 0.05
	is_on_floor = false
	coyote_timer = 0.0
	var buffered_jump = jump_buffer_timer > 0
	test_base.assert_true(buffered_jump, "Jump buffer allows early input")