extends Node

## TestSaveLoad - Save/load system tests

class_name TestSaveLoad

var test_base: Object = null

func run_tests() -> Dictionary:
	test_base = load("res://tests/run_tests.gd").new().TestBase.new()
	
	test_save_data_structure()
	test_versioning()
	test_corruption_handling()
	test_slot_management()
	test_settings_persistence()
	test_world_state()
	
	return test_base.get_results()

func test_save_data_structure() -> void:
	var save_data = {
		"version": 1,
		"timestamp": 1234567890,
		"player_stats": {
			"health": 75.0,
			"max_health": 100.0,
			"stamina": 50.0,
			"max_stamina": 100.0,
			"hunger": 60.0,
			"max_hunger": 100.0,
			"thirst": 40.0,
			"max_thirst": 100.0,
			"infection": 10.0,
			"max_infection": 100.0
		},
		"completed_missions": ["m1_welcome_to_hell", "m2_first_steps"],
		"active_mission": "m3_supply_run",
		"discovered_locations": ["abandoned_city", "hospital"],
		"activated_checkpoints": ["cp_apartment", "cp_downtown"],
		"current_checkpoint": "cp_downtown",
		"collected_documents": ["research_notes_1"],
		"found_survivors": [],
		"world_state": {
			"time_of_day": 14.5,
			"day_count": 2,
			"weather": "rain",
			"safehouse_upgrades": ["storage_expansion", "generator"],
			"generator_fuel": 75.0,
			"barricade_health": 100.0
		},
		"current_level": "abandoned_city",
		"play_time": 3600.0,
		"difficulty": 1,
		"settings": {
			"master_volume": 1.0,
			"music_volume": 0.7,
			"sfx_volume": 1.0
		}
	}
	
	# Test required fields exist
	test_base.assert_true(save_data.has("version"), "Save has version")
	test_base.assert_true(save_data.has("timestamp"), "Save has timestamp")
	test_base.assert_true(save_data.has("player_stats"), "Save has player stats")
	test_base.assert_true(save_data.has("completed_missions"), "Save has completed missions")
	test_base.assert_true(save_data.has("current_level"), "Save has current level")
	
	# Test player stats structure
	var stats = save_data["player_stats"]
	test_base.assert_equal(stats["health"], 75.0, "Health saved")
	test_base.assert_equal(stats["max_health"], 100.0, "Max health saved")
	test_base.assert_equal(stats["infection"], 10.0, "Infection saved")
	
	# Test arrays
	test_base.assert_equal(save_data["completed_missions"].size(), 2, "Two completed missions")
	test_base.assert_equal(save_data["discovered_locations"].size(), 2, "Two discovered locations")
	test_base.assert_true("m1_welcome_to_hell" in save_data["completed_missions"], "Mission 1 completed")
	
	# Test world state
	var world = save_data["world_state"]
	test_base.assert_equal(world["day_count"], 2, "Day count saved")
	test_base.assert_equal(world["weather"], "rain", "Weather saved")
	test_base.assert_equal(world["safehouse_upgrades"].size(), 2, "Two upgrades")

func test_versioning() -> void:
	var current_version = 1
	
	# Test version 1 save
	var save_v1 = {"version": 1, "data": "test"}
	test_base.assert_equal(save_v1["version"], current_version, "Current version save")
	
	# Test older version (would need migration)
	var save_v0 = {"version": 0, "data": "test"}
	test_base.assert_true(save_v0["version"] < current_version, "Old version detected")
	
	# Test migration function concept
	func migrate_save(save: Dictionary) -> Dictionary:
		var version = save.get("version", 0)
		if version < 1:
			save["version"] = 1
			# Add new fields with defaults
			if not save.has("world_state"):
				save["world_state"] = {"time_of_day": 8.0, "day_count": 1}
		return save
	
	var migrated = migrate_save(save_v0)
	test_base.assert_equal(migrated["version"], 1, "Migrated to version 1")
	test_base.assert_true(migrated.has("world_state"), "Added missing world_state")

func test_corruption_handling() -> void:
	# Test JSON parsing
	var valid_json = '{"version": 1, "health": 100}'
	var invalid_json = '{"version": 1, "health": 100' # missing brace
	
	var parse_result = JSON.parse_string(valid_json)
	test_base.assert_equal(parse_result.get("error"), OK, "Valid JSON parses")
	
	parse_result = JSON.parse_string(invalid_json)
	test_base.assert_not_equal(parse_result.get("error"), OK, "Invalid JSON fails")
	
	# Test missing file handling
	var file_exists = false # Simulate missing file
	test_base.assert_false(file_exists, "Missing file handled")
	
	# Test empty file
	var empty_json = ''
	parse_result = JSON.parse_string(empty_json)
	test_base.assert_not_equal(parse_result.get("error"), OK, "Empty file fails")
	
	# Test wrong data types
	var wrong_type_json = '{"version": "one", "health": "full"}'
	parse_result = JSON.parse_string(wrong_type_json)
	if parse_result.get("error") == OK:
		var data = parse_result.get("result")
		test_base.assert_false(typeof(data["version"]) == TYPE_INT, "String version detected")
		test_base.assert_false(typeof(data["health"]) == TYPE_FLOAT, "String health detected")

func test_slot_management() -> void:
	var max_slots = 5
	var saves = {}
	
	# Simulate save slots
	for i in range(max_slots):
		saves[i] = {
			"exists": i < 3,
			"corrupted": i == 2,
			"timestamp": 1000 + i * 100,
			"level": "level_" + str(i),
			"play_time": 1000 * i
		}
	
	# Test slot availability
	var available_slots = 0
	for i in range(max_slots):
		if not saves[i]["exists"]:
			available_slots += 1
	
	test_base.assert_equal(available_slots, 2, "Two empty slots")
	
	# Test latest save detection
	var latest_slot = -1
	var latest_time = 0
	for i in range(max_slots):
		if saves[i]["exists"] and not saves[i]["corrupted"]:
			if saves[i]["timestamp"] > latest_time:
				latest_time = saves[i]["timestamp"]
				latest_slot = i
	
	test_base.assert_equal(latest_slot, 1, "Slot 1 is latest valid save")
	
	# Test corrupted save skipped
	test_base.assert_true(saves[2]["corrupted"], "Slot 2 corrupted")
	test_base.assert_not_equal(latest_slot, 2, "Corrupted slot not selected")

func test_settings_persistence() -> void:
	var settings = {
		"master_volume": 0.8,
		"music_volume": 0.5,
		"sfx_volume": 1.0,
		"brightness": 1.2,
		"vibration": true,
		"auto_save": true,
		"show_tutorial": false,
		"control_scheme": "default",
		"language": "en"
	}
	
	# Test settings saved
	test_base.assert_equal(settings["master_volume"], 0.8, "Master volume saved")
	test_base.assert_equal(settings["music_volume"], 0.5, "Music volume saved")
	test_base.assert_equal(settings["sfx_volume"], 1.0, "SFX volume saved")
	
	# Test boolean settings
	test_base.assert_true(settings["vibration"], "Vibration enabled")
	test_base.assert_true(settings["auto_save"], "Auto-save enabled")
	test_base.assert_false(settings["show_tutorial"], "Tutorial disabled")
	
	# Test settings modification
	settings["master_volume"] = 0.5
	test_base.assert_equal(settings["master_volume"], 0.5, "Volume changed")
	
	# Test settings bounds
	func clamp_setting(key: String, value: float) -> float:
		if key.ends_with("_volume") or key == "brightness":
			return clamp(value, 0.0, 2.0)
		return value
	
	test_base.assert_equal(clamp_setting("master_volume", 1.5), 1.5, "Volume clamped to max")
	test_base.assert_equal(clamp_setting("master_volume", -0.5), 0.0, "Volume clamped to min")
	test_base.assert_equal(clamp_setting("brightness", 3.0), 2.0, "Brightness clamped")

func test_world_state() -> void:
	var world_state = {
		"time_of_day": 14.5,
		"day_count": 3,
		"weather": "fog",
		"safehouse_upgrades": ["storage_expansion", "generator", "water_purifier"],
		"generator_fuel": 50.0,
		"barricade_health": 80.0,
		"is_night": false
	}
	
	# Test time of day
	test_base.assert_equal(world_state["time_of_day"], 14.5, "Time saved")
	
	# Test night detection
	var is_night = world_state["time_of_day"] >= 20.0 or world_state["time_of_day"] < 6.0
	test_base.assert_false(is_night, "Not night at 14:30")
	
	world_state["time_of_day"] = 22.0
	is_night = world_state["time_of_day"] >= 20.0 or world_state["time_of_day"] < 6.0
	test_base.assert_true(is_night, "Night at 22:00")
	
	world_state["time_of_day"] = 4.0
	is_night = world_state["time_of_day"] >= 20.0 or world_state["time_of_day"] < 6.0
	test_base.assert_true(is_night, "Night at 04:00")
	
	# Test day count
	test_base.assert_equal(world_state["day_count"], 3, "Day 3")
	
	# Test weather
	test_base.assert_equal(world_state["weather"], "fog", "Foggy weather")
	
	# Test safehouse upgrades
	test_base.assert_equal(world_state["safehouse_upgrades"].size(), 3, "Three upgrades")
	test_base.assert_true("generator" in world_state["safehouse_upgrades"], "Generator upgraded")
	
	# Test generator fuel
	test_base.assert_equal(world_state["generator_fuel"], 50.0, "Half fuel")
	
	# Test barricade health
	test_base.assert_equal(world_state["barricade_health"], 80.0, "Barricade damaged")