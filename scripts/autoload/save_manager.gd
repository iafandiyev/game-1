extends Node

class_name SaveManager

## SaveManager - Handles game save/load operations
## Uses versioned JSON save files with corruption protection

signal save_completed(slot: int, success: bool)
signal load_completed(slot: int, success: bool, data: Dictionary)
signal save_deleted(slot: int)
signal auto_save_triggered()

const SAVE_VERSION = 1
const MAX_SAVE_SLOTS = 5
const AUTO_SAVE_INTERVAL = 300.0 # 5 minutes
const SAVE_DIR = "user://saves/"

var auto_save_timer: float = 0.0
var last_save_slot: int = 0

func _ready() -> void:
	_process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_save_directory()

func _process(delta: float) -> void:
	auto_save_timer += delta
	if auto_save_timer >= AUTO_SAVE_INTERVAL:
		auto_save_timer = 0.0
		if GameManager.get_setting("auto_save"):
			auto_save()
			auto_save_triggered.emit()

func _ensure_save_directory() -> void:
	var dir = DirAccess.open(SAVE_DIR)
	if not dir:
		DirAccess.make_dir_recursive_absolute(SAVE_DIR)

func save_game(data: Dictionary, slot: int = -1) -> bool:
	if slot == -1:
		slot = last_save_slot
	
	data["save_version"] = SAVE_VERSION
	data["slot"] = slot
	data["timestamp"] = Time.get_unix_time_from_datetime(Time.get_datetime_now())
	
	var file_path = SAVE_DIR + "save_slot_%d.json" % slot
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	
	if not file:
		push_error("Failed to open save file for writing: " + file_path)
		save_completed.emit(slot, false)
		return false
	
	var json_string = JSON.stringify(data, "\t")
	file.store_string(json_string)
	file.close()
	
	# Update metadata
	_update_save_metadata(slot, data)
	
	last_save_slot = slot
	save_completed.emit(slot, true)
	return true

func load_game(slot: int = -1) -> Dictionary:
	if slot == -1:
		slot = _get_latest_save_slot()
		if slot == -1:
			return {}
	
	var file_path = SAVE_DIR + "save_slot_%d.json" % slot
	var file = FileAccess.open(file_path, FileAccess.READ)
	
	if not file:
		push_error("Failed to open save file for reading: " + file_path)
		load_completed.emit(slot, false, {})
		return {}
	
	var json_string = file.get_as_text()
	file.close()
	
	var parse_result = JSON.parse_string(json_string)
	if parse_result.get("error") != OK:
		push_error("Failed to parse save file: " + file_path + " - " + parse_result.get("error_string"))
		load_completed.emit(slot, false, {})
		return {}
	
	var data = parse_result.get("result")
	
	# Version migration
	data = _migrate_save_data(data)
	
	load_completed.emit(slot, true, data)
	return data

func delete_save(slot: int) -> bool:
	var file_path = SAVE_DIR + "save_slot_%d.json" % slot
	if FileAccess.file_exists(file_path):
		var error = DirAccess.remove_absolute(file_path)
		if error == OK:
			_remove_save_metadata(slot)
			save_deleted.emit(slot)
			return true
	return false

func get_save_info(slot: int) -> Dictionary:
	var file_path = SAVE_DIR + "save_slot_%d.json" % slot
	if not FileAccess.file_exists(file_path):
		return {"exists": false}
	
	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		return {"exists": false, "corrupted": true}
	
	var json_string = file.get_as_text()
	file.close()
	
	var parse_result = JSON.parse_string(json_string)
	if parse_result.get("error") != OK:
		return {"exists": true, "corrupted": true}
	
	var data = parse_result.get("result")
	return {
		"exists": true,
		"corrupted": false,
		"version": data.get("save_version", 0),
		"timestamp": data.get("timestamp", 0),
		"level": data.get("current_level", "unknown"),
		"play_time": data.get("play_time", 0),
		"day_count": data.get("world_state", {}).get("day_count", 1),
		"difficulty": data.get("difficulty", 1),
	}

func get_all_saves_info() -> Array[Dictionary]:
	var saves = []
	for i in range(MAX_SAVE_SLOTS):
		saves.append(get_save_info(i))
	return saves

func _get_latest_save_slot() -> int:
	var latest_slot = -1
	var latest_time = 0
	
	for i in range(MAX_SAVE_SLOTS):
		var info = get_save_info(i)
		if info.get("exists") and not info.get("corrupted"):
			var timestamp = info.get("timestamp", 0)
			if timestamp > latest_time:
				latest_time = timestamp
				latest_slot = i
	
	return latest_slot

func _update_save_metadata(slot: int, data: Dictionary) -> void:
	var meta_path = SAVE_DIR + "metadata.json"
	var metadata = {}
	
	var file = FileAccess.open(meta_path, FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		file.close()
		var parse_result = JSON.parse_string(json_string)
		if parse_result.get("error") == OK:
			metadata = parse_result.get("result")
	
	metadata["slot_%d" % slot] = {
		"timestamp": data.get("timestamp", 0),
		"level": data.get("current_level", "unknown"),
		"play_time": data.get("play_time", 0),
		"day_count": data.get("world_state", {}).get("day_count", 1),
	}
	
	file = FileAccess.open(meta_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(metadata))
		file.close()

func _remove_save_metadata(slot: int) -> void:
	var meta_path = SAVE_DIR + "metadata.json"
	var file = FileAccess.open(meta_path, FileAccess.READ)
	if not file:
		return
	
	var json_string = file.get_as_text()
	file.close()
	
	var parse_result = JSON.parse_string(json_string)
	if parse_result.get("error") != OK:
		return
	
	var metadata = parse_result.get("result")
	metadata.erase("slot_%d" % slot)
	
	file = FileAccess.open(meta_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(metadata))
		file.close()

func _migrate_save_data(data: Dictionary) -> Dictionary:
	var version = data.get("save_version", 0)
	
	# Future migrations would go here
	# if version < 2:
	#     data = _migrate_v1_to_v2(data)
	
	data["save_version"] = SAVE_VERSION
	return data

func auto_save() -> void:
	if GameManager.current_state == GameManager.GameState.PLAYING:
		var save_data = GameManager._create_save_data()
		save_game(save_data, last_save_slot)

func export_save(slot: int, destination_path: String) -> bool:
	var source_path = SAVE_DIR + "save_slot_%d.json" % slot
	if not FileAccess.file_exists(source_path):
		return false
	
	var file = FileAccess.open(source_path, FileAccess.READ)
	if not file:
		return false
	
	var content = file.get_as_text()
	file.close()
	
	file = FileAccess.open(destination_path, FileAccess.WRITE)
	if not file:
		return false
	
	file.store_string(content)
	file.close()
	return true

func import_save(source_path: String, slot: int) -> bool:
	if not FileAccess.file_exists(source_path):
		return false
	
	var file = FileAccess.open(source_path, FileAccess.READ)
	if not file:
		return false
	
	var content = file.get_as_text()
	file.close()
	
	var parse_result = JSON.parse_string(content)
	if parse_result.get("error") != OK:
		return false
	
	var data = parse_result.get("result")
	data = _migrate_save_data(data)
	
	return save_game(data, slot)

func clear_all_saves() -> void:
	for i in range(MAX_SAVE_SLOTS):
		delete_save(i)
	
	var meta_path = SAVE_DIR + "metadata.json"
	if FileAccess.file_exists(meta_path):
		DirAccess.remove_absolute(meta_path)