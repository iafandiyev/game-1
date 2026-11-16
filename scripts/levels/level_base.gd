extends Node2D

class_name LevelBase

## LevelBase - Base class for all game levels

signal level_loaded()
signal player_spawned(player: Node)
signal checkpoint_activated(checkpoint_id: String)
signal exit_triggered(exit_id: String, target_level: String)

@export var level_id: String = ""
@export var level_name: String = ""
@export var spawn_point: Vector2 = Vector2(100, 500)
@export var background_music_day: String = ""
@export var background_music_night: String = ""
@export var ambient_sounds: Array[String] = []

var player: Node = null
var spawned_enemies: Array[Node] = []
var active_checkpoints: Array[String] = []
var level_data: Dictionary = {}

func _ready() -> void:
	_load_level_data()
	_setup_level()
	_spawn_player()
	_start_ambience()
	level_loaded.emit()

func _load_level_data() -> void:
	var data_path = "res://data/levels/%s.json" % level_id
	if ResourceLoader.exists(data_path):
		var file = FileAccess.open(data_path, FileAccess.READ)
		if file:
			var json_string = file.get_as_text()
			file.close()
			var parse_result = JSON.parse_string(json_string)
			if parse_result.get("error") == OK:
				level_data = parse_result.get("result")
				level_id = level_data.get("id", level_id)
				level_name = level_data.get("name", level_name)
				spawn_point = Vector2(
					level_data.get("spawn_point", {}).get("x", 100),
					level_data.get("spawn_point", {}).get("y", 500)
				)

func _setup_level() -> void:
	# Setup background parallax
	# Setup lighting
	# Setup navigation
	pass

func _spawn_player() -> void:
	var player_scene = preload("res://scenes/player/player.tscn")
	player = player_scene.instantiate()
	player.global_position = spawn_point
	player.name = "Player"
	add_child(player)
	player.add_to_group("player")
	player_spawned.emit(player)
	
	# Make camera follow player
	var camera = player.get_node_or_null("Camera2D")
	if camera:
		camera.make_current()

func _start_ambience() -> void:
	# Start ambient sounds
	for sound in ambient_sounds:
		AudioManager.play_environment_sound(sound, Vector2.ZERO)
	
	# Start music based on time of day
	if WorldManager.is_night():
		if background_music_night != "":
			AudioManager.play_music(background_music_night)
	else:
		if background_music_day != "":
			AudioManager.play_music(background_music_day)

func activate_checkpoint(checkpoint_id: String) -> void:
	if checkpoint_id not in active_checkpoints:
		active_checkpoints.append(checkpoint_id)
		GameManager.activate_checkpoint(checkpoint_id)
		checkpoint_activated.emit(checkpoint_id)

func trigger_exit(exit_id: String, target_level: String) -> void:
	exit_triggered.emit(exit_id, target_level)
	GameManager._change_level(target_level)

func spawn_enemy(enemy_type: String, position: Vector2) -> Node:
	var enemy_scene_path = "res://scenes/enemies/%s.tscn" % enemy_type.to_lower()
	if ResourceLoader.exists(enemy_scene_path):
		var enemy_scene = load(enemy_scene_path)
		var enemy = enemy_scene.instantiate()
		enemy.global_position = position
		add_child(enemy)
		spawned_enemies.append(enemy)
		return enemy
	return null

func get_save_data() -> Dictionary:
	var enemy_data = []
	for enemy in spawned_enemies:
		if enemy and enemy.has_method("get_save_data"):
			enemy_data.append(enemy.get_save_data())
	
	return {
		"level_id": level_id,
		"active_checkpoints": active_checkpoints,
		"enemies": enemy_data,
		"player_position": player.global_position if player else spawn_point,
	}

func load_save_data(data: Dictionary) -> void:
	active_checkpoints = data.get("active_checkpoints", [])
	
	# Restore player position
	if player and data.has("player_position"):
		player.global_position = data["player_position"]
	
	# Restore enemies
	for enemy_data in data.get("enemies", []):
		var enemy_type = enemy_data.get("zombie_type", "walker")
		var position = Vector2(
			enemy_data.get("position", {}).get("x", 0),
			enemy_data.get("position", {}).get("y", 0)
		)
		var enemy = spawn_enemy(enemy_type, position)
		if enemy and enemy.has_method("load_save_data"):
			enemy.load_save_data(enemy_data)