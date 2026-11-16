extends Node

class_name MissionManager

## MissionManager - Handles mission tracking, objectives, and progression

signal mission_started(mission_id: String)
signal mission_completed(mission_id: String)
signal mission_failed(mission_id: String)
signal objective_updated(mission_id: String, objective_id: String, completed: bool)
signal mission_progress(mission_id: String, progress: float)

@export_group("Mission Data")
@export var missions: Dictionary = {}

var active_mission_id: String = ""
var mission_states: Dictionary = {}
var completed_missions: Array[String] = []
var failed_missions: Array[String] = []

func _ready() -> void:
	_process_mode = Node.PROCESS_MODE_ALWAYS
	_load_mission_data()

func _load_mission_data() -> void:
	# Load mission definitions from data files
	var dir = DirAccess.open("res://data/missions/")
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".json"):
				var file_path = "res://data/missions/%s" % file_name
				var file = FileAccess.open(file_path, FileAccess.READ)
				if file:
					var json_string = file.get_as_text()
					file.close()
					var parse_result = JSON.parse_string(json_string)
					if parse_result.get("error") == OK:
						var mission_data = parse_result.get("result")
						missions[mission_data["id"]] = mission_data
			file_name = dir.get_next()
		dir.list_dir_end()
	
	# Initialize mission states
	for mission_id in missions:
		mission_states[mission_id] = {
			"state": "not_started", # not_started, active, completed, failed
			"objectives": {},
			"progress": 0.0,
			"current_objective_index": 0,
		}
		
		var mission = missions[mission_id]
		for obj in mission.get("objectives", []):
			mission_states[mission_id]["objectives"][obj["id"]] = {
				"completed": false,
				"progress": 0.0,
			}

func start_mission(mission_id: String) -> bool:
	if not missions.has(mission_id):
		push_error("Mission not found: " + mission_id)
		return false
	
	if mission_states[mission_id]["state"] != "not_started":
		return false
	
	mission_states[mission_id]["state"] = "active"
	active_mission_id = mission_id
	GameManager.set_active_mission(mission_id)
	mission_started.emit(mission_id)
	
	# Auto-complete first objective if it's "reach_location" and player is there
	_check_objectives(mission_id)
	
	return true

func complete_mission(mission_id: String) -> void:
	if not missions.has(mission_id):
		return
	
	if mission_states[mission_id]["state"] != "active":
		return
	
	mission_states[mission_id]["state"] = "completed"
	mission_states[mission_id]["progress"] = 1.0
	
	if mission_id not in completed_missions:
		completed_missions.append(mission_id)
	
	GameManager.complete_mission(mission_id)
	
	if active_mission_id == mission_id:
		active_mission_id = ""
	
	mission_completed.emit(mission_id)
	
	# Check for next mission in chain
	var mission = missions[mission_id]
	var next_mission = mission.get("next_mission", "")
	if next_mission != "":
		# Could auto-start or just make available
		pass

func fail_mission(mission_id: String) -> void:
	if not missions.has(mission_id):
		return
	
	if mission_states[mission_id]["state"] != "active":
		return
	
	mission_states[mission_id]["state"] = "failed"
	
	if mission_id not in failed_missions:
		failed_missions.append(mission_id)
	
	if active_mission_id == mission_id:
		active_mission_id = ""
	
	mission_failed.emit(mission_id)

func update_objective(mission_id: String, objective_id: String, completed: bool, progress: float = -1) -> void:
	if not missions.has(mission_id):
		return
	
	if not mission_states[mission_id]["objectives"].has(objective_id):
		return
	
	var obj_state = mission_states[mission_id]["objectives"][objective_id]
	obj_state["completed"] = completed
	if progress >= 0:
		obj_state["progress"] = progress
	
	objective_updated.emit(mission_id, objective_id, completed)
	_check_objectives(mission_id)

func _check_objectives(mission_id: String) -> void:
	var mission = missions[mission_id]
	var objectives = mission.get("objectives", [])
	var all_completed = true
	var completed_count = 0
	
	for obj in objectives:
		var obj_state = mission_states[mission_id]["objectives"][obj["id"]]
		if obj_state["completed"]:
			completed_count += 1
		else:
			all_completed = false
	
	var progress = completed_count / objectives.size() if objectives.size() > 0 else 0.0
	mission_states[mission_id]["progress"] = progress
	mission_progress.emit(mission_id, progress)
	
	if all_completed and objectives.size() > 0:
		complete_mission(mission_id)

func get_mission_state(mission_id: String) -> Dictionary:
	return mission_states.get(mission_id, {})

func get_active_mission() -> Dictionary:
	if active_mission_id == "":
		return {}
	return {
		"id": active_mission_id,
		"data": missions.get(active_mission_id, {}),
		"state": mission_states.get(active_mission_id, {}),
	}

func get_available_missions() -> Array[Dictionary]:
	var available = []
	for mission_id, mission in missions:
		var state = mission_states[mission_id]["state"]
		if state == "not_started":
			# Check prerequisites
			var prereqs = mission.get("prerequisites", [])
			var can_start = true
			for prereq in prereqs:
				if prereq not in completed_missions:
					can_start = false
					break
			if can_start:
				available.append(mission)
	return available

func get_completed_missions() -> Array[String]:
	return completed_missions

func is_mission_completed(mission_id: String) -> bool:
	return mission_id in completed_missions

func is_mission_active(mission_id: String) -> bool:
	return active_mission_id == mission_id

func get_objective_text(mission_id: String, objective_id: String) -> String:
	var mission = missions.get(mission_id, {})
	for obj in mission.get("objectives", []):
		if obj["id"] == objective_id:
			return obj.get("description", "")
	return ""

func get_current_objective(mission_id: String) -> Dictionary:
	var mission = missions.get(mission_id, {})
	var objectives = mission.get("objectives", [])
	var current_index = mission_states[mission_id].get("current_objective_index", 0)
	
	if current_index < objectives.size():
		return objectives[current_index]
	return {}

# Save/Load
func get_save_data() -> Dictionary:
	return {
		"active_mission_id": active_mission_id,
		"mission_states": mission_states,
		"completed_missions": completed_missions,
		"failed_missions": failed_missions,
	}

func load_save_data(data: Dictionary) -> void:
	active_mission_id = data.get("active_mission_id", "")
	mission_states = data.get("mission_states", {})
	completed_missions = data.get("completed_missions", [])
	failed_missions = data.get("failed_missions", [])
	
	# Ensure all missions have states
	for mission_id in missions:
		if not mission_states.has(mission_id):
			mission_states[mission_id] = {
				"state": "not_started",
				"objectives": {},
				"progress": 0.0,
				"current_objective_index": 0,
			}
			for obj in missions[mission_id].get("objectives", []):
				mission_states[mission_id]["objectives"][obj["id"]] = {
					"completed": false,
					"progress": 0.0,
				}
	
	if active_mission_id != "":
		GameManager.set_active_mission(active_mission_id)