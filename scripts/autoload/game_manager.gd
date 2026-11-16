extends Node

class_name GameManager

## GameManager - Central game state and flow controller
## Manages game states, scene transitions, and global game data

signal game_state_changed(new_state: GameState)
signal level_changed(level_name: String)
signal new_game_started()
signal game_loaded(save_data: Dictionary)
signal game_saved()
signal player_died()
signal checkpoint_activated(checkpoint_id: String)

enum GameState {
	MAIN_MENU,
	PLAYING,
	PAUSED,
	INVENTORY,
	CRAFTING,
	MAP,
	JOURNAL,
	DIALOGUE,
	DEATH_SCREEN,
	LOADING,
	SETTINGS
}

enum Difficulty {
	EASY,
	NORMAL,
	HARD,
	SURVIVAL
}

var current_state: GameState = GameState.MAIN_MENU
var current_level: String = ""
var previous_level: String = ""
var difficulty: Difficulty = Difficulty.NORMAL
var is_new_game: bool = false
var play_time: float = 0.0
var game_version: String = "1.0.0"

# Player stats (synced with SurvivalManager)
var player_stats: Dictionary = {
	"health": 100,
	"max_health": 100,
	"stamina": 100,
	"max_stamina": 100,
	"hunger": 100,
	"max_hunger": 100,
	"thirst": 100,
	"max_thirst": 100,
	"infection": 0,
	"max_infection": 100,
}

# Game progress
var completed_missions: Array[String] = []
var active_mission: String = ""
var discovered_locations: Array[String] = []
var activated_checkpoints: Array[String] = []
var current_checkpoint: String = ""
var collected_documents: Array[String] = []
var found_survivors: Array[String] = []

# World state
var world_state: Dictionary = {
	"time_of_day": 12.0, # 0-24 hours
	"day_count": 1,
	"weather": "clear",
	"safehouse_upgrades": [],
	"generator_fuel": 100,
	"barricade_health": 100,
}

# Settings
var settings: Dictionary = {
	"master_volume": 1.0,
	"music_volume": 0.7,
	"sfx_volume": 1.0,
	"brightness": 1.0,
	"vibration": true,
	"auto_save": true,
	"show_tutorial": true,
	"control_scheme": "default",
	"language": "en",
}

func _ready() -> void:
	_process_mode = Node.PROCESS_MODE_ALWAYS
	_load_settings()
	_init_game_data()

func _process(delta: float) -> void:
	if current_state == GameState.PLAYING:
		play_time += delta

func _init_game_data() -> void:
	discovered_locations = ["abandoned_city"]
	activated_checkpoints = []

func _load_settings() -> void:
	var file = FileAccess.open("user://settings.json", FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		file.close()
		var parse_result = JSON.parse_string(json_string)
		if parse_result.get("error") == OK:
			settings = parse_result.get("result")
	else:
		_save_settings()

func _save_settings() -> void:
	var file = FileAccess.open("user://settings.json", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(settings))
		file.close()

func save_settings() -> void:
	_save_settings()

func get_setting(key: String) -> Variant:
	return settings.get(key, null)

func set_setting(key: String, value: Variant) -> void:
	if settings.has(key):
		settings[key] = value
		_save_settings()

func new_game(difficulty_level: Difficulty = Difficulty.NORMAL) -> void:
	is_new_game = true
	difficulty = difficulty_level
	current_state = GameState.LOADING
	game_state_changed.emit(current_state)
	
	_reset_game_data()
	
	# Load first level
	current_level = "abandoned_city"
	_change_level(current_level)
	
	current_state = GameState.PLAYING
	game_state_changed.emit(current_state)
	new_game_started.emit()

func _reset_game_data() -> void:
	player_stats = {
		"health": 100,
		"max_health": 100,
		"stamina": 100,
		"max_stamina": 100,
		"hunger": 100,
		"max_hunger": 100,
		"thirst": 100,
		"max_thirst": 100,
		"infection": 0,
		"max_infection": 100,
	}
	completed_missions = []
	active_mission = ""
	discovered_locations = ["abandoned_city"]
	activated_checkpoints = []
	current_checkpoint = ""
	collected_documents = []
	found_survivors = []
	world_state = {
		"time_of_day": 8.0,
		"day_count": 1,
		"weather": "clear",
		"safehouse_upgrades": [],
		"generator_fuel": 100,
		"barricade_health": 100,
	}
	play_time = 0.0

func continue_game() -> void:
	current_state = GameState.LOADING
	game_state_changed.emit(current_state)
	
	var save_data = SaveManager.load_game()
	if save_data:
		_apply_save_data(save_data)
		_change_level(current_level)
		current_state = GameState.PLAYING
		game_state_changed.emit(current_state)
		game_loaded.emit(save_data)
	else:
		# No save found, start new game
		new_game()

func _apply_save_data(data: Dictionary) -> void:
	player_stats = data.get("player_stats", player_stats)
	completed_missions = data.get("completed_missions", [])
	active_mission = data.get("active_mission", "")
	discovered_locations = data.get("discovered_locations", ["abandoned_city"])
	activated_checkpoints = data.get("activated_checkpoints", [])
	current_checkpoint = data.get("current_checkpoint", "")
	collected_documents = data.get("collected_documents", [])
	found_survivors = data.get("found_survivors", [])
	world_state = data.get("world_state", world_state)
	current_level = data.get("current_level", "abandoned_city")
	play_time = data.get("play_time", 0.0)
	difficulty = Difficulty(data.get("difficulty", 1))
	settings = data.get("settings", settings)

func request_save() -> void:
	var save_data = _create_save_data()
	SaveManager.save_game(save_data)
	game_saved.emit()

func _create_save_data() -> Dictionary:
	return {
		"version": game_version,
		"timestamp": Time.get_unix_time_from_datetime(Time.get_datetime_now()),
		"player_stats": player_stats,
		"completed_missions": completed_missions,
		"active_mission": active_mission,
		"discovered_locations": discovered_locations,
		"activated_checkpoints": activated_checkpoints,
		"current_checkpoint": current_checkpoint,
		"collected_documents": collected_documents,
		"found_survivors": found_survivors,
		"world_state": world_state,
		"current_level": current_level,
		"play_time": play_time,
		"difficulty": int(difficulty),
		"settings": settings,
	}

func _change_level(level_name: String) -> void:
	previous_level = current_level
	current_level = level_name
	level_changed.emit(level_name)
	
	# Load the level scene
	var level_path = "res://scenes/levels/%s.tscn" % level_name
	if ResourceLoader.exists(level_path):
		var current_scene = get_tree().get_current_scene()
		if current_scene and current_scene != get_tree().get_root():
			current_scene.queue_free()
		get_tree().change_scene_to_file(level_path)
	else:
		push_error("Level not found: " + level_path)

func activate_checkpoint(checkpoint_id: String) -> void:
	if checkpoint_id not in activated_checkpoints:
		activated_checkpoints.append(checkpoint_id)
	current_checkpoint = checkpoint_id
	checkpoint_activated.emit(checkpoint_id)
	
	if settings.get("auto_save", true):
		request_save()

func complete_mission(mission_id: String) -> void:
	if mission_id not in completed_missions:
		completed_missions.append(mission_id)
	active_mission = ""
	request_save()

func set_active_mission(mission_id: String) -> void:
	active_mission = mission_id
	request_save()

func discover_location(location_id: String) -> void:
	if location_id not in discovered_locations:
		discovered_locations.append(location_id)
		request_save()

func collect_document(doc_id: String) -> void:
	if doc_id not in collected_documents:
		collected_documents.append(doc_id)
		request_save()

func find_survivor(survivor_id: String) -> void:
	if survivor_id not in found_survivors:
		found_survivors.append(survivor_id)
		request_save()

func upgrade_safehouse(upgrade_id: String) -> void:
	if upgrade_id not in world_state["safehouse_upgrades"]:
		world_state["safehouse_upgrades"].append(upgrade_id)
		request_save()

func set_time_of_day(hours: float) -> void:
	world_state["time_of_day"] = fmod(hours, 24.0)
	_update_day_night()

func _update_day_night() -> void:
	var hour = world_state["time_of_day"]
	if hour >= 20.0 or hour < 6.0:
		world_state["is_night"] = true
	else:
		world_state["is_night"] = false

func advance_time(hours: float) -> void:
	world_state["time_of_day"] += hours
	if world_state["time_of_day"] >= 24.0:
		world_state["time_of_day"] -= 24.0
		world_state["day_count"] += 1
	_update_day_night()

func is_night() -> bool:
	return world_state.get("is_night", false)

func get_play_time_formatted() -> String:
	var hours = int(play_time / 3600)
	var minutes = int(fmod(play_time, 3600) / 60)
	var seconds = int(fmod(play_time, 60))
	return "%02d:%02d:%02d" % [hours, minutes, seconds]

func pause_game() -> void:
	if current_state == GameState.PLAYING:
		current_state = GameState.PAUSED
		game_state_changed.emit(current_state)
		get_tree().paused = true

func resume_game() -> void:
	if current_state == GameState.PAUSED:
		current_state = GameState.PLAYING
		game_state_changed.emit(current_state)
		get_tree().paused = false

func open_inventory() -> void:
	if current_state == GameState.PLAYING:
		current_state = GameState.INVENTORY
		game_state_changed.emit(current_state)
		get_tree().paused = true

func close_inventory() -> void:
	if current_state == GameState.INVENTORY:
		current_state = GameState.PLAYING
		game_state_changed.emit(current_state)
		get_tree().paused = false

func show_death_screen() -> void:
	current_state = GameState.DEATH_SCREEN
	game_state_changed.emit(current_state)
	get_tree().paused = true
	player_died.emit()

func respawn_at_checkpoint() -> void:
	if current_checkpoint != "":
		# Restore player to checkpoint state
		player_stats["health"] = player_stats["max_health"]
		player_stats["stamina"] = player_stats["max_stamina"]
		player_stats["infection"] = min(player_stats["infection"], 25) # Reduce infection on respawn
		_change_level(current_level)
		current_state = GameState.PLAYING
		game_state_changed.emit(current_state)
		get_tree().paused = false
	else:
		# No checkpoint, restart from beginning
		new_game()

func return_to_main_menu() -> void:
	current_state = GameState.MAIN_MENU
	game_state_changed.emit(current_state)
	get_tree().paused = false
	_change_level("main_menu")

func quit_game() -> void:
	request_save()
	get_tree().quit()

func get_difficulty_multiplier() -> float:
	match difficulty:
		Difficulty.EASY: return 0.75
		Difficulty.NORMAL: return 1.0
		Difficulty.HARD: return 1.35
		Difficulty.SURVIVAL: return 1.75
	return 1.0

func get_current_level_data() -> Dictionary:
	var level_data_path = "res://data/levels/%s.json" % current_level
	if ResourceLoader.exists(level_data_path):
		var file = FileAccess.open(level_data_path, FileAccess.READ)
		if file:
			var json_string = file.get_as_text()
			file.close()
			return JSON.parse_string(json_string).get("result", {})
	return {}