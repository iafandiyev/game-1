extends Node

class_name AudioManager

## AudioManager - Centralized audio management
## Handles music, SFX, ambient sounds, and volume controls

signal volume_changed(bus: String, volume: float)

@export_group("Audio Buses")
@export var master_bus: int = 0
@export var music_bus: int = 1
@export var sfx_bus: int = 2
@export var ambient_bus: int = 3
@export var voice_bus: int = 4

@export_group("Audio Resources")
@export var music_tracks: Array[AudioStream] = []
@export var ambient_tracks: Array[AudioStream] = []
@export var ui_sounds: Dictionary = {}

var current_music: AudioStreamPlayer = null
var current_ambient: AudioStreamPlayer = null
var music_fade_tween: Tween = null
var ambient_fade_tween: Tween = null

# Volume settings (0.0 to 1.0)
var master_volume: float = 1.0
var music_volume: float = 0.7
var sfx_volume: float = 1.0
var ambient_volume: float = 0.8
var voice_volume: float = 1.0

func _ready() -> void:
	_process_mode = Node.PROCESS_MODE_ALWAYS
	_load_volume_settings()
	_apply_all_volumes()
	_create_audio_players()

func _create_audio_players() -> void:
	# Music player
	current_music = AudioStreamPlayer.new()
	current_music.bus = "Music"
	current_music.autoplay = false
	add_child(current_music)
	
	# Ambient player
	current_ambient = AudioStreamPlayer.new()
	current_ambient.bus = "Ambient"
	current_ambient.autoplay = false
	add_child(current_ambient)

func _load_volume_settings() -> void:
	var settings = GameManager.get_setting("master_volume")
	if settings != null:
		master_volume = GameManager.get_setting("master_volume")
		music_volume = GameManager.get_setting("music_volume")
		sfx_volume = GameManager.get_setting("sfx_volume")
	else:
		# Use defaults from GameManager settings
		master_volume = GameManager.settings["master_volume"]
		music_volume = GameManager.settings["music_volume"]
		sfx_volume = GameManager.settings["sfx_volume"]
		ambient_volume = GameManager.settings.get("ambient_volume", 0.8)
		voice_volume = GameManager.settings.get("voice_volume", 1.0)

func _apply_all_volumes() -> void:
	_set_bus_volume("Master", master_volume)
	_set_bus_volume("Music", music_volume * master_volume)
	_set_bus_volume("SFX", sfx_volume * master_volume)
	_set_bus_volume("Ambient", ambient_volume * master_volume)
	_set_bus_volume("Voice", voice_volume * master_volume)

func _set_bus_volume(bus_name: String, volume: float) -> void:
	var bus_index = AudioServer.get_bus_index(bus_name)
	if bus_index >= 0:
		AudioServer.set_bus_volume_db(bus_index, linear_to_db(volume))

func linear_to_db(linear: float) -> float:
	if linear <= 0.0:
		return -80.0
	return 20.0 * log10(linear)

func db_to_linear(db: float) -> float:
	return pow(10.0, db / 20.0)

# Music control
func play_music(track_name: String, fade_time: float = 2.0, loop: bool = true) -> void:
	var track = _find_music_track(track_name)
	if not track:
		push_warning("Music track not found: " + track_name)
		return
	
	if current_music.playing:
		fade_out_music(fade_time)
	
	if music_fade_tween:
		music_fade_tween.kill()
	
	current_music.stream = track
	current_music.play()
	current_music.loop = loop
	
	# Fade in
	music_fade_tween = create_tween()
	music_fade_tween.tween_property(current_music, "volume_db", linear_to_db(music_volume * master_volume), fade_time)
	music_fade_tween.set_trans(Tween.TRANS_LINEAR)

func fade_out_music(fade_time: float = 2.0) -> void:
	if not current_music.playing:
		return
	
	if music_fade_tween:
		music_fade_tween.kill()
	
	music_fade_tween = create_tween()
	music_fade_tween.tween_property(current_music, "volume_db", -80.0, fade_time)
	music_fade_tween.set_trans(Tween.TRANS_LINEAR)
	music_fade_tween.finished.connect(_on_music_fade_out_finished)

func _on_music_fade_out_finished() -> void:
	current_music.stop()
	current_music.stream = null

func stop_music(immediate: bool = false) -> void:
	if immediate:
		if music_fade_tween:
			music_fade_tween.kill()
		current_music.stop()
		current_music.stream = null
	else:
		fade_out_music(1.0)

func set_music_volume(volume: float) -> void:
	music_volume = clamp(volume, 0.0, 1.0)
	GameManager.set_setting("music_volume", music_volume)
	_set_bus_volume("Music", music_volume * master_volume)
	volume_changed.emit("music", music_volume)
	
	if current_music.playing:
		current_music.volume_db = linear_to_db(music_volume * master_volume)

# Ambient control
func play_ambient(track_name: String, fade_time: float = 3.0, loop: bool = true) -> void:
	var track = _find_ambient_track(track_name)
	if not track:
		push_warning("Ambient track not found: " + track_name)
		return
	
	if current_ambient.playing:
		fade_out_ambient(fade_time)
	
	if ambient_fade_tween:
		ambient_fade_tween.kill()
	
	current_ambient.stream = track
	current_ambient.play()
	current_ambient.loop = loop
	
	# Fade in
	ambient_fade_tween = create_tween()
	ambient_fade_tween.tween_property(current_ambient, "volume_db", linear_to_db(ambient_volume * master_volume), fade_time)
	ambient_fade_tween.set_trans(Tween.TRANS_LINEAR)

func fade_out_ambient(fade_time: float = 3.0) -> void:
	if not current_ambient.playing:
		return
	
	if ambient_fade_tween:
		ambient_fade_tween.kill()
	
	ambient_fade_tween = create_tween()
	ambient_fade_tween.tween_property(current_ambient, "volume_db", -80.0, fade_time)
	ambient_fade_tween.set_trans(Tween.TRANS_LINEAR)
	ambient_fade_tween.finished.connect(_on_ambient_fade_out_finished)

func _on_ambient_fade_out_finished() -> void:
	current_ambient.stop()
	current_ambient.stream = null

func stop_ambient(immediate: bool = false) -> void:
	if immediate:
		if ambient_fade_tween:
			ambient_fade_tween.kill()
		current_ambient.stop()
		current_ambient.stream = null
	else:
		fade_out_ambient(2.0)

func set_ambient_volume(volume: float) -> void:
	ambient_volume = clamp(volume, 0.0, 1.0)
	GameManager.set_setting("ambient_volume", ambient_volume)
	_set_bus_volume("Ambient", ambient_volume * master_volume)
	volume_changed.emit("ambient", ambient_volume)
	
	if current_ambient.playing:
		current_ambient.volume_db = linear_to_db(ambient_volume * master_volume)

# SFX control
func play_sfx(sound_name: String, position: Vector2 = Vector2.ZERO, pitch_variance: float = 0.1, volume_db: float = 0.0) -> AudioStreamPlayer2D:
	var sound = _get_ui_sound(sound_name)
	if not sound:
		# Try to load from assets
		sound = load("res://assets/audio/sfx/%s.ogg" % sound_name)
		if not sound:
			push_warning("SFX not found: " + sound_name)
			return null
	
	var player = AudioStreamPlayer2D.new()
	player.stream = sound
	player.bus = "SFX"
	player.position = position
	player.pitch_scale = 1.0 + randf_range(-pitch_variance, pitch_variance)
	player.volume_db = volume_db
	player.autoplay = true
	add_child(player)
	
	player.finished.connect(player.queue_free.bind())
	return player

func play_sfx_at_node(sound_name: String, node: Node2D, pitch_variance: float = 0.1, volume_db: float = 0.0) -> AudioStreamPlayer2D:
	return play_sfx(sound_name, node.global_position, pitch_variance, volume_db)

# UI sounds
func play_ui_sound(sound_name: String) -> void:
	var sound = _get_ui_sound(sound_name)
	if sound:
		var player = AudioStreamPlayer.new()
		player.stream = sound
		player.bus = "SFX"
		player.autoplay = true
		add_child(player)
		player.finished.connect(player.queue_free.bind())
	else:
		push_warning("UI sound not found: " + sound_name)

func _get_ui_sound(sound_name: String) -> AudioStream:
	return ui_sounds.get(sound_name)

func _find_music_track(track_name: String) -> AudioStream:
	for track in music_tracks:
		if track.get_path().get_file().get_basename() == track_name:
			return track
	return null

func _find_ambient_track(track_name: String) -> AudioStream:
	for track in ambient_tracks:
		if track.get_path().get_file().get_basename() == track_name:
			return track
	return null

# Master volume
func set_master_volume(volume: float) -> void:
	master_volume = clamp(volume, 0.0, 1.0)
	GameManager.set_setting("master_volume", master_volume)
	_apply_all_volumes()
	volume_changed.emit("master", master_volume)

func set_sfx_volume(volume: float) -> void:
	sfx_volume = clamp(volume, 0.0, 1.0)
	GameManager.set_setting("sfx_volume", sfx_volume)
	_set_bus_volume("SFX", sfx_volume * master_volume)
	volume_changed.emit("sfx", sfx_volume)

func set_voice_volume(volume: float) -> void:
	voice_volume = clamp(volume, 0.0, 1.0)
	GameManager.set_setting("voice_volume", voice_volume)
	_set_bus_volume("Voice", voice_volume * master_volume)
	volume_changed.emit("voice", voice_volume)

# Game event sounds
func play_footstep(surface_type: String = "concrete", is_running: bool = false) -> void:
	var sound_name = "footstep_%s_%s" % [surface_type, "run" if is_running else "walk"]
	play_sfx(sound_name)

func play_weapon_sound(weapon_type: String, action: String) -> void:
	var sound_name = "weapon_%s_%s" % [weapon_type, action]
	play_sfx(sound_name)

func play_zombie_sound(zombie_type: String, action: String) -> void:
	var sound_name = "zombie_%s_%s" % [zombie_type, action]
	play_sfx(sound_name)

func play_environment_sound(sound_name: String, position: Vector2) -> void:
	play_sfx(sound_name, position)

func play_heartbeat(intensity: float = 1.0) -> void:
	var player = AudioStreamPlayer.new()
	player.bus = "SFX"
	player.autoplay = true
	add_child(player)
	player.finished.connect(player.queue_free.bind())
	# Would load heartbeat sound based on intensity

# Dynamic music layers for tension
func set_music_tension(level: float) -> void:
	# 0.0 = calm, 1.0 = high tension
	# Could crossfade between music layers
	pass

# Radio/voice communications
func play_radio_message(message_id: String) -> void:
	var sound = load("res://assets/audio/voice/%s.ogg" % message_id)
	if sound:
		var player = AudioStreamPlayer.new()
		player.stream = sound
		player.bus = "Voice"
		player.autoplay = true
		add_child(player)
		player.finished.connect(player.queue_free.bind())