extends Control

## Map - World map interface

@onready var current_location_label: Label = %CurrentLocation
@onready var map_image: TextureRect = %MapImage
@onready var locations_container: Node2D = %LocationsContainer
@onready var close_button: Button = %CloseButton

var location_markers: Dictionary = {}

func _ready() -> void:
	_connect_signals()
	_update_map()

func _connect_signals() -> void:
	close_button.pressed.connect(_on_close_pressed)
	InputManager.inventory_pressed.connect(_on_close_pressed) # M key
	WorldManager.level_changed.connect(_on_level_changed)

func _on_level_changed(level_name: String) -> void:
	_update_map()

func _update_map() -> void:
	var level = GameManager.current_level
	current_location_label.text = _get_level_display_name(level)
	
	# Load map image for current level
	var map_path = "res://assets/ui/maps/%s_map.png" % level
	if ResourceLoader.exists(map_path):
		map_image.texture = load(map_path)
	
	_clear_markers()
	_create_markers(level)

func _get_level_display_name(level_id: String) -> String:
	var names = {
		"abandoned_city": "Abandoned City",
		"hospital": "Hospital",
		"supermarket": "Supermarket",
		"metro": "Underground Metro",
		"military_base": "Military Base",
		"safehouse": "Safehouse"
	}
	return names.get(level_id, level_id)

func _clear_markers() -> void:
	for marker in locations_container.get_children():
		marker.queue_free()
	location_markers.clear()

func _create_markers(level_id: String) -> void:
	# Safehouse marker
	if level_id == "abandoned_city" or level_id == "safehouse":
		_create_marker("safehouse", Vector2(400, 200), "Safehouse")
	
	# Mission marker
	var active_mission = MissionManager.get_active_mission()
	if active_mission:
		var obj = MissionManager.get_current_objective(active_mission["id"])
		if obj and obj.get("target"):
			_create_marker("mission", Vector2(600, 300), obj.get("description", "Mission"))
	
	# Exit markers
	var level_data = GameManager.get_current_level_data()
	for exit in level_data.get("exits", []):
		if not exit.get("required_mission", "") or MissionManager.is_mission_completed(exit["required_mission"]):
			_create_marker("exit", Vector2(800, 250), "Exit to %s" % exit["target_level"])

func _create_marker(type: String, position: Vector2, tooltip: String) -> void:
	var marker = TextureRect.new()
	marker.custom_minimum_size = Vector2(24, 24)
	marker.position = position
	
	var icon_path = "res://assets/ui/icons/map_%s.png" % type
	if ResourceLoader.exists(icon_path):
		marker.texture = load(icon_path)
	else:
		marker.add_theme_stylebox_override("texture", _create_marker_stylebox(type))
	
	var tooltip_control = _create_tooltip(tooltip)
	marker.add_child(tooltip_control)
	
	locations_container.add_child(marker)
	location_markers[type] = marker

func _create_marker_stylebox(type: String) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.corner_radius = 12
	
	match type:
		"safehouse":
			style.bg_color = Color(0.2, 0.8, 0.3, 1)
		"mission":
			style.bg_color = Color(1.0, 0.8, 0.1, 1)
		"exit":
			style.bg_color = Color(0.3, 0.7, 1.0, 1)
		_:
			style.bg_color = Color(0.7, 0.7, 0.7, 1)
	
	return style

func _create_tooltip(text: String) -> Control:
	var panel = Panel.new()
	panel.position = Vector2(30, -40)
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.1, 0.9)
	style.corner_radius = 4
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	panel.add_theme_stylebox_override("panel", style)
	
	var label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", Color.WHITE)
	panel.add_child(label)
	
	panel.visible = false
	
	panel.mouse_entered.connect(panel.show.bind())
	panel.mouse_exited.connect(panel.hide.bind())
	
	return panel

func _on_close_pressed() -> void:
	AudioManager.play_ui_sound("menu_select")
	UIManager.hide_map()
	queue_free()