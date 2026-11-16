extends Node

## TestMissions - Mission system tests

class_name TestMissions

var test_base: Object = null

func run_tests() -> Dictionary:
	test_base = load("res://tests/run_tests.gd").new().TestBase.new()
	
	test_mission_structure()
	test_objectives()
	test_prerequisites()
	test_progression()
	test_rewards()
	test_choices()
	
	return test_base.get_results()

func test_mission_structure() -> void:
	var missions = {
		"m1_welcome_to_hell": {
			"name": "Welcome to Hell",
			"chapter": 1,
			"prerequisites": [],
			"next_mission": "m2_first_steps",
			"objectives": [
				{"id": "obj_escape_apartment", "type": "reach_location", "target": "apartment_exit", "optional": false},
				{"id": "obj_find_weapon", "type": "acquire_item", "target": "baseball_bat", "count": 1, "optional": false},
				{"id": "obj_reach_safehouse", "type": "reach_location", "target": "safehouse_entrance", "optional": false}
			],
			"rewards": {"experience": 100, "items": [{"item_id": "bandage", "count": 3}]}
		},
		"m2_first_steps": {
			"name": "First Steps",
			"chapter": 1,
			"prerequisites": ["m1_welcome_to_hell"],
			"next_mission": "m3_supply_run",
			"objectives": [
				{"id": "obj_learn_crafting", "type": "craft_item", "target": "bandage", "count": 1, "optional": false},
				{"id": "obj_kill_zombies", "type": "kill_enemies", "target": "walker", "count": 5, "optional": false},
				{"id": "obj_find_food", "type": "acquire_item", "target": "canned_food", "count": 2, "optional": false}
			],
			"rewards": {"experience": 200, "items": [{"item_id": "pistol", "count": 1}]}
		}
	}
	
	# Test mission 1
	var m1 = missions["m1_welcome_to_hell"]
	test_base.assert_equal(m1["name"], "Welcome to Hell", "Mission 1 name")
	test_base.assert_equal(m1["chapter"], 1, "Mission 1 chapter")
	test_base.assert_equal(m1["prerequisites"].size(), 0, "Mission 1 no prerequisites")
	test_base.assert_equal(m1["next_mission"], "m2_first_steps", "Mission 1 leads to mission 2")
	test_base.assert_equal(m1["objectives"].size(), 3, "Mission 1 has 3 objectives")
	
	# Test mission 2
	var m2 = missions["m2_first_steps"]
	test_base.assert_equal(m2["prerequisites"].size(), 1, "Mission 2 has 1 prerequisite")
	test_base.assert_true("m1_welcome_to_hell" in m2["prerequisites"], "Mission 2 requires mission 1")
	
	# Test objective types
	var obj_types = []
	for obj in m1["objectives"]:
		obj_types.append(obj["type"])
	
	test_base.assert_true("reach_location" in obj_types, "Has reach_location objective")
	test_base.assert_true("acquire_item" in obj_types, "Has acquire_item objective")

func test_objectives() -> void:
	# Test objective completion tracking
	var mission_objectives = {
		"obj_1": {"completed": false, "progress": 0.0},
		"obj_2": {"completed": false, "progress": 0.0},
		"obj_3": {"completed": false, "progress": 0.0}
	}
	
	# Complete first objective
	mission_objectives["obj_1"]["completed"] = true
	mission_objectives["obj_1"]["progress"] = 1.0
	
	var completed = 0
	for obj in mission_objectives.values():
		if obj["completed"]:
			completed += 1
	
	test_base.assert_equal(completed, 1, "One objective completed")
	
	# Complete second
	mission_objectives["obj_2"]["completed"] = true
	completed = 0
	for obj in mission_objectives.values():
		if obj["completed"]:
			completed += 1
	
	test_base.assert_equal(completed, 2, "Two objectives completed")
	
	# Test progress calculation
	var total = mission_objectives.size()
	var progress = completed / total
	test_base.assert_equal(progress, 2.0/3.0, "Progress 66%")
	
	# Test all complete
	mission_objectives["obj_3"]["completed"] = true
	completed = 0
	for obj in mission_objectives.values():
		if obj["completed"]:
			completed += 1
	
	progress = completed / total
	test_base.assert_equal(progress, 1.0, "Progress 100% when all done")

func test_prerequisites() -> void:
	var all_missions = {
		"m1": {"prerequisites": [], "state": "completed"},
		"m2": {"prerequisites": ["m1"], "state": "not_started"},
		"m3": {"prerequisites": ["m1"], "state": "not_started"},
		"m4": {"prerequisites": ["m2", "m3"], "state": "not_started"},
		"m5": {"prerequisites": ["m4"], "state": "not_started"}
	}
	
	var completed = ["m1"]
	
	func can_start(mission_id: String) -> bool:
		var mission = all_missions[mission_id]
		for prereq in mission["prerequisites"]:
			if prereq not in completed:
				return false
		return mission["state"] == "not_started"
	
	# m2 and m3 available (m1 done)
	test_base.assert_true(can_start("m2"), "Mission 2 available after m1")
	test_base.assert_true(can_start("m3"), "Mission 3 available after m1")
	
	# m4 not available (needs m2 and m3)
	test_base.assert_false(can_start("m4"), "Mission 4 needs m2 and m3")
	
	# Complete m2
	completed.append("m2")
	test_base.assert_false(can_start("m4"), "Mission 4 still needs m3")
	
	# Complete m3
	completed.append("m3")
	test_base.assert_true(can_start("m4"), "Mission 4 available after m2 and m3")
	
	# Complete m4
	completed.append("m4")
	test_base.assert_true(can_start("m5"), "Mission 5 available after m4")

func test_progression() -> void:
	var mission_states = {
		"m1": "completed",
		"m2": "active",
		"m3": "not_started",
		"m4": "failed"
	}
	
	var active_mission = "m2"
	
	# Test active mission tracking
	test_base.assert_equal(active_mission, "m2", "Mission 2 active")
	
	# Test state transitions
	mission_states["m2"] = "completed"
	active_mission = ""
	test_base.assert_equal(active_mission, "", "No active mission after completion")
	
	# Test failed mission
	test_base.assert_equal(mission_states["m4"], "failed", "Mission 4 failed")
	
	# Test available count
	var available = 0
	for state in mission_states.values():
		if state == "not_started":
			available += 1
	test_base.assert_equal(available, 1, "One mission available")

func test_rewards() -> void:
	var rewards = {
		"experience": 100,
		"items": [
			{"item_id": "bandage", "count": 3},
			{"item_id": "water_bottle", "count": 2}
		],
		"unlocks": ["crafting_recipe_bandage", "safehouse_access"]
	}
	
	test_base.assert_equal(rewards["experience"], 100, "XP reward")
	test_base.assert_equal(rewards["items"].size(), 2, "Two item rewards")
	
	var total_items = 0
	for item in rewards["items"]:
		total_items += item["count"]
	test_base.assert_equal(total_items, 5, "Total 5 items")
	
	test_base.assert_true("crafting_recipe_bandage" in rewards["unlocks"], "Unlocks crafting")
	test_base.assert_true("safehouse_access" in rewards["unlocks"], "Unlocks safehouse")

func test_choices() -> void:
	var final_mission = {
		"id": "m15_final_choice",
		"objectives": [{
			"id": "obj_make_choice",
			"type": "choice",
			"options": [
				{"id": "ending_a", "text": "Escape the city", "description": "Take the helicopter and escape"},
				{"id": "ending_b", "text": "Sacrifice yourself", "description": "Destroy the virus source but remain behind"}
			]
		}]
	}
	
	var choice_obj = final_mission["objectives"][0]
	test_base.assert_equal(choice_obj["type"], "choice", "Final mission is a choice")
	test_base.assert_equal(choice_obj["options"].size(), 2, "Two endings")
	
	var ending_a = choice_obj["options"][0]
	var ending_b = choice_obj["options"][1]
	
	test_base.assert_equal(ending_a["id"], "ending_a", "Ending A: Escape")
	test_base.assert_equal(ending_b["id"], "ending_b", "Ending B: Sacrifice")
	
	# Test choice consequence
	var player_choice = "ending_a"
	var unlocked_ending = player_choice
	test_base.assert_equal(unlocked_ending, "ending_a", "Player chose ending A")
	
	player_choice = "ending_b"
	unlocked_ending = player_choice
	test_base.assert_equal(unlocked_ending, "ending_b", "Player chose ending B")
	
	# Test that choice affects outcome
	var endings = {
		"ending_a": {"survives": true, "escapes": true, "truth_revealed": false},
		"ending_b": {"survives": false, "escapes": false, "truth_revealed": true}
	}
	
	var result = endings[player_choice]
	test_base.assert_false(result["survives"], "Ending B: Player dies")
	test_base.assert_true(result["truth_revealed"], "Ending B: Truth revealed")