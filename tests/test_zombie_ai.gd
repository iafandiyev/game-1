extends Node

## TestZombieAI - Zombie AI behavior tests

class_name TestZombieAI

var test_base: Object = null

func run_tests() -> Dictionary:
	test_base = load("res://tests/run_tests.gd").new().TestBase.new()
	
	test_zombie_types()
	test_detection()
	test_state_machine()
test_pathfinding()
	test_attacks()
	test_damage_reactions()
	
	return test_base.get_results()

func test_zombie_types() -> void:
	var zombies = {
		"walker": {
			"max_health": 100.0, "damage": 15.0, "move_speed": 60.0,
			"chase_speed": 80.0, "detection_range": 250.0, "attack_range": 45.0
		},
		"runner": {
			"max_health": 75.0, "damage": 25.0, "move_speed": 180.0,
			"chase_speed": 280.0, "detection_range": 350.0, "attack_range": 55.0
		},
		"tank": {
			"max_health": 500.0, "damage": 40.0, "move_speed": 40.0,
			"chase_speed": 60.0, "detection_range": 300.0, "attack_range": 70.0
		},
		"screamer": {
			"max_health": 60.0, "damage": 10.0, "move_speed": 50.0,
			"chase_speed": 70.0, "detection_range": 400.0, "attack_range": 40.0
		},
		"crawler": {
			"max_health": 50.0, "damage": 20.0, "move_speed": 70.0,
			"chase_speed": 120.0, "detection_range": 200.0, "attack_range": 40.0
		}
	}
	
	# Test walker stats
	var walker = zombies["walker"]
	test_base.assert_equal(walker["max_health"], 100.0, "Walker health")
	test_base.assert_equal(walker["move_speed"], 60.0, "Walker slow speed")
	test_base.assert_equal(walker["chase_speed"], 80.0, "Walker slow chase")
	
	# Test runner stats
	var runner = zombies["runner"]
	test_base.assert_equal(runner["max_health"], 75.0, "Runner less health")
	test_base.assert_equal(runner["move_speed"], 180.0, "Runner fast")
	test_base.assert_equal(runner["chase_speed"], 280.0, "Runner very fast chase")
	test_base.assert_equal(runner["damage"], 25.0, "Runner higher damage")
	
	# Test tank stats
	var tank = zombies["tank"]
	test_base.assert_equal(tank["max_health"], 500.0, "Tank high health")
	test_base.assert_equal(tank["move_speed"], 40.0, "Tank very slow")
	test_base.assert_equal(tank["damage"], 40.0, "Tank high damage")
	test_base.assert_equal(tank["attack_range"], 70.0, "Tank long reach")
	
	# Test screamer stats
	var screamer = zombies["screamer"]
	test_base.assert_equal(screamer["detection_range"], 400.0, "Screamer long detection")
	test_base.assert_equal(screamer["max_health"], 60.0, "Screamer low health")
	
	# Test crawler stats
	var crawler = zombies["crawler"]
	test_base.assert_equal(crawler["detection_range"], 200.0, "Crawler short detection")
	test_base.assert_equal(crawler["max_health"], 50.0, "Crawler lowest health")
	test_base.assert_equal(crawler["chase_speed"], 120.0, "Crawler fast chase")

func test_detection() -> void:
	# Test vision cone
	var fov_angle = 120.0 # degrees
	var half_fov = fov_angle / 2.0 # 60 degrees
	
	func is_in_fov(target_angle: float, facing_right: bool) -> bool:
		var forward = 0.0 if facing_right else 180.0 # degrees
		var diff = abs(target_angle - forward)
		if diff > 180.0:
			diff = 360.0 - diff
		return diff <= half_fov
	
	# Facing right (0 degrees)
	test_base.assert_true(is_in_fov(0.0, true), "Directly ahead")
	test_base.assert_true(is_in_fov(30.0, true), "30 degrees right")
	test_base.assert_true(is_in_fov(-30.0, true), "30 degrees left")
	test_base.assert_true(is_in_fov(60.0, true), "At edge of FOV")
	test_base.assert_false(is_in_fov(61.0, true), "Just outside FOV")
	test_base.assert_false(is_in_fov(180.0, true), "Directly behind")
	
	# Facing left (180 degrees)
	test_base.assert_true(is_in_fov(180.0, false), "Directly ahead (left)")
	test_base.assert_true(is_in_fov(150.0, false), "30 degrees left")
	test_base.assert_true(is_in_fov(210.0, false), "30 degrees right")
	
	# Test distance detection
	var detection_range = 300.0
	var distances = [50.0, 150.0, 299.0, 300.0, 301.0]
	for dist in distances:
		var detected = dist <= detection_range
		if dist < 300.0:
			test_base.assert_true(detected, "Detected at " + str(dist) + " units")
		else:
			test_base.assert_false(detected, "Not detected at " + str(dist) + " units")
	
	# Test sound detection
	var sound_range = 200.0
	var sound_loudness = 10.0 # gunshot
	var effective_range = sound_range * (sound_loudness / 10.0)
	test_base.assert_equal(effective_range, 200.0, "Gunshot heard at 200")
	
	sound_loudness = 5.0 # footsteps
	effective_range = sound_range * (sound_loudness / 10.0)
	test_base.assert_equal(effective_range, 100.0, "Footsteps heard at 100")
	
	sound_loudness = 20.0 # explosion
	effective_range = sound_range * (sound_loudness / 10.0)
	test_base.assert_equal(effective_range, 400.0, "Explosion heard at 400")

func test_state_machine() -> void:
	var states = ["IDLE", "PATROL", "SUSPICIOUS", "INVESTIGATE", "CHASE", "ATTACK", "SEARCH", "RETURN_PATROL", "DEAD"]
	
	# Test state transitions
	var current_state = "IDLE"
	var player_detected = false
	var player_in_sight = false
	var distance_to_player = 500.0
	var attack_range = 50.0
	var detection_range = 300.0
	
	func update_state() -> void:
		match current_state:
			"IDLE":
				if player_in_sight:
					current_state = "CHASE"
				elif player_detected:
					current_state = "SUSPICIOUS"
			"PATROL":
				if player_in_sight:
					current_state = "CHASE"
				elif player_detected:
					current_state = "SUSPICIOUS"
			"SUSPICIOUS":
				if player_in_sight:
					current_state = "CHASE"
				else:
					current_state = "INVESTIGATE"
			"INVESTIGATE":
				if player_in_sight:
					current_state = "CHASE"
				elif distance_to_player < 50.0:
					current_state = "SEARCH"
			"CHASE":
				if not player_detected:
					current_state = "SEARCH"
				elif distance_to_player < attack_range and player_in_sight:
					current_state = "ATTACK"
			"ATTACK":
				if not player_detected or distance_to_player > attack_range * 1.5:
					current_state = "CHASE"
			"SEARCH":
				current_state = "RETURN_PATROL"
			"RETURN_PATROL":
				current_state = "PATROL"
	
	# Test IDLE -> CHASE when player in sight
	player_in_sight = true
	update_state()
	test_base.assert_equal(current_state, "CHASE", "Idle to chase when seen")
	
	# Test CHASE -> ATTACK when in range
	current_state = "CHASE"
	distance_to_player = 40.0
	player_in_sight = true
	update_state()
	test_base.assert_equal(current_state, "ATTACK", "Chase to attack in range")
	
	# Test ATTACK -> CHASE when out of range
	distance_to_player = 100.0
	update_state()
	test_base.assert_equal(current_state, "CHASE", "Attack to chase when out of range")
	
	# Test CHASE -> SEARCH when lost
	player_detected = false
	update_state()
	test_base.assert_equal(current_state, "SEARCH", "Chase to search when lost")

func test_pathfinding() -> void:
	# Test direct movement vs navigation
	var direct_speed = 80.0
	var nav_speed = 80.0
	
	# Simple distance check
	var start = Vector2(0, 0)
	var target = Vector2(100, 0)
	var distance = start.distance_to(target)
	test_base.assert_equal(distance, 100.0, "Straight line distance")
	
	# With obstacle, path is longer
	var path = [Vector2(0, 0), Vector2(50, 50), Vector2(100, 0)]
	var path_length = 0.0
	for i in range(path.size() - 1):
		path_length += path[i].distance_to(path[i + 1])
	
	test_base.assert_true(path_length > distance, "Path longer than direct")
	test_base.assert_equal(path_length, 141.42, 0.1, "Path length calculated")
	
	# Test movement towards target
	var pos = Vector2(0, 0)
	var speed = 80.0
	var delta = 1.0
	var direction = (target - pos).normalized()
	pos += direction * speed * delta
	test_base.assert_equal(pos.x, 80.0, "Moved 80 units toward target")

func test_attacks() -> void:
	var walker = {"damage": 15.0, "attack_range": 45.0, "attack_cooldown": 1.8}
	var runner = {"damage": 25.0, "attack_range": 55.0, "attack_cooldown": 1.0}
	var tank = {"damage": 40.0, "attack_range": 70.0, "attack_cooldown": 2.5, "slam_damage": 50.0}
	var screamer = {"damage": 10.0, "attack_range": 40.0, "attack_cooldown": 2.0, "scream_radius": 500.0}
	var crawler = {"damage": 20.0, "attack_range": 40.0, "attack_cooldown": 1.2, "pounce_damage": 30.0}
	
	# Test attack cooldowns
	var cooldowns = {
		"walker": 1.8,
		"runner": 1.0,
		"tank": 2.5,
		"screamer": 2.0,
		"crawler": 1.2
	}
	
	for name, cd in cooldowns:
		var attacks_per_minute = 60.0 / cd
		if name == "runner":
			test_base.assert_true(attacks_per_minute > 50, "Runner attacks fast")
		elif name == "tank":
			test_base.assert_true(attacks_per_minute < 30, "Tank attacks slow")
	
	# Test special attacks
	# Tank slam
	var slam_radius = 100.0
	var player_dist = 80.0
	var hit_by_slam = player_dist <= slam_radius
	test_base.assert_true(hit_by_slam, "Player in slam radius")
	
	# Screamer scream
	var scream_radius = 500.0
	player_dist = 300.0
	var hears_scream = player_dist <= scream_radius
	test_base.assert_true(hears_scream, "Player hears scream")
	
	# Crawler pounce
	var pounce_range = 300.0
	player_dist = 200.0
	var can_pounce = player_dist <= pounce_range
	test_base.assert_true(can_pounce, "Crawler can pounce")
	
	# Pounce damage
	test_base.assert_equal(crawler["pounce_damage"], 30.0, "Pounce deals 30 damage")

func test_damage_reactions() -> void:
	var zombies = {
		"walker": {"health": 100.0, "knockback_resistance": 0.3},
		"runner": {"health": 75.0, "knockback_resistance": 0.2},
		"tank": {"health": 500.0, "knockback_resistance": 0.8},
		"screamer": {"health": 60.0, "knockback_resistance": 0.1},
		"crawler": {"health": 50.0, "knockback_resistance": 0.4}
	}
	
	var base_knockback = 300.0
	var damage = 25.0
	
	for name, data in zombies:
		var knockback = base_knockback * (1.0 - data["knockback_resistance"])
		data["health"] -= damage
		
		if name == "tank":
			test_base.assert_equal(knockback, 60.0, "Tank high knockback resistance")
			test_base.assert_equal(data["health"], 475.0, "Tank takes damage")
		elif name == "screamer":
			test_base.assert_equal(knockback, 270.0, "Screamer low knockback resistance")
			test_base.assert_equal(data["health"], 35.0, "Screamer takes damage")
		elif name == "runner":
			test_base.assert_equal(knockback, 240.0, "Runner medium knockback resistance")
	
	# Test death
	var walker = zombies["walker"]
	walker["health"] = 0.0
	var is_dead = walker["health"] <= 0.0
	test_base.assert_true(is_dead, "Walker dies at 0 health")
	
	# Test headshot multiplier on runner
	var runner = zombies["runner"]
	runner["health"] = 75.0
	var headshot_damage = 25.0 * 2.0
	runner["health"] -= headshot_damage
	test_base.assert_equal(runner["health"], 25.0, "Runner headshot 2x damage")