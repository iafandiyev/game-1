extends Control

## Journal - Mission journal and document viewer

@onready var missions_list: VBoxContainer = %MissionsList
@onready var documents_list: VBoxContainer = %DocumentsList
@onready var survivors_list: VBoxContainer = %SurvivorsList
@onready var lore_list: VBoxContainer = %LoreList
@onready var entry_details: Panel = %EntryDetails
@onready var detail_title: Label = %DetailTitle
@onready var detail_content: Label = %DetailContent
@onready var close_button: Button = %CloseButton

func _ready() -> void:
	_connect_signals()
	_populate_all()

func _connect_signals() -> void:
	close_button.pressed.connect(_on_close_pressed)
	InputManager.inventory_pressed.connect(_on_close_pressed) # J key
	GameManager.game_loaded.connect(_on_game_loaded)
	MissionManager.mission_completed.connect(_on_mission_completed)

func _on_game_loaded(save_data: Dictionary) -> void:
	_populate_all()

func _on_mission_completed(mission_id: String) -> void:
	_populate_missions()

func _populate_all() -> void:
	_populate_missions()
	_populate_documents()
	_populate_survivors()
	_populate_lore()

func _populate_missions() -> void:
	for child in missions_list.get_children():
		child.queue_free()
	
	var active_mission = MissionManager.get_active_mission()
	var completed = GameManager.completed_missions
	
	# Active mission first
	if active_mission:
		_create_mission_entry(active_mission, true)
	
	# Available missions
	var available = MissionManager.get_available_missions()
	for mission in available:
		_create_mission_entry(mission, false)
	
	# Completed missions
	for mission_id in completed:
		var mission_data = MissionManager.missions.get(mission_id)
		if mission_data:
			_create_completed_entry(mission_data)

func _create_mission_entry(mission: Dictionary, is_active: bool) -> void:
	var panel = Panel.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.1, 0.8)
	if is_active:
		style.border_width_bottom = 2
		style.border_color = Color(1.0, 0.8, 0.1, 1)
	style.corner_radius = 8
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	panel.add_theme_stylebox_override("panel", style)
	
	var vbox = VBoxContainer.new()
	panel.add_child(vbox)
	
	var title = Label.new()
	title.text = mission.get("name", "Unknown Mission")
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(1, 0.8, 0.1) if is_active else Color(0.9, 0.9, 0.9))
	vbox.add_child(title)
	
	var desc = Label.new()
	desc.text = mission.get("description", "")
	desc.add_theme_font_size_override("font_size", 14)
	desc.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(desc)
	
	# Objectives
	for obj in mission.get("objectives", []):
		var obj_label = Label.new()
		var status = "⬜" # Would check completion
		obj_label.text = "%s %s" % [status, obj.get("description", "")]
		obj_label.add_theme_font_size_override("font_size", 13)
		obj_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
		vbox.add_child(obj_label)
	
	panel.gui_input.connect(_on_mission_clicked.bind(mission))
	missions_list.add_child(panel)

func _create_completed_entry(mission_data: Dictionary) -> void:
	var panel = Panel.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.1, 0.08, 0.8)
	style.corner_radius = 6
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	panel.add_theme_stylebox_override("panel", style)
	
	var hbox = HBoxContainer.new()
	panel.add_child(hbox)
	
	var check = TextureRect.new()
	check.custom_minimum_size = Vector2(20, 20)
	check.add_theme_color_override("modulate", Color(0.2, 0.8, 0.3))
	hbox.add_child(check)
	
	var label = Label.new()
	label.text = mission_data.get("name", "Unknown")
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color(0.6, 0.8, 0.6))
	hbox.add_child(label)
	
	missions_list.add_child(panel)

func _on_mission_clicked(mission: Dictionary, event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_show_mission_details(mission)

func _show_mission_details(mission: Dictionary) -> void:
	detail_title.text = mission.get("name", "Unknown Mission")
	detail_content.text = mission.get("description", "")
	entry_details.visible = true

func _populate_documents() -> void:
	for child in documents_list.get_children():
		child.queue_free()
	
	for doc_id in GameManager.collected_documents:
		_create_document_entry(doc_id)

func _create_document_entry(doc_id: String) -> void:
	var item = ItemDatabase.get_item(doc_id)
	if not item:
		return
	
	var btn = Button.new()
	btn.text = item.get("name", doc_id)
	btn.add_theme_font_size_override("font_size", 16)
	btn.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.custom_minimum_size = Vector2(0, 40)
	btn.pressed.connect(_show_document.bind(item))
	documents_list.add_child(btn)

func _show_document(item: Dictionary) -> void:
	detail_title.text = item.get("name", "Document")
	detail_content.text = item.get("description", "No description available.")
	entry_details.visible = true

func _populate_survivors() -> void:
	for child in survivors_list.get_children():
		child.queue_free()
	
	for survivor_id in GameManager.found_survivors:
		_create_survivor_entry(survivor_id)

func _create_survivor_entry(survivor_id: String) -> void:
	# Would load survivor data
	var btn = Button.new()
	btn.text = "Survivor: %s" % survivor_id
	btn.add_theme_font_size_override("font_size", 16)
	btn.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.custom_minimum_size = Vector2(0, 40)
	survivors_list.add_child(btn)

func _populate_lore() -> void:
	for child in lore_list.get_children():
		child.queue_free()
	
	# Add lore entries based on collected documents
	var lore_entries = [
		{"id": "virus_origin", "title": "The Origin", "unlocked": "research_notes_1" in GameManager.collected_documents},
		{"id": "virus_structure", "title": "Viral Structure", "unlocked": "research_notes_2" in GameManager.collected_documents},
		{"id": "military_response", "title": "Military Response", "unlocked": "radio_log_1" in GameManager.collected_documents},
		{"id": "survivor_account", "title": "A Survivor's Tale", "unlocked": "survivor_note_1" in GameManager.collected_documents},
	]
	
	for entry in lore_entries:
		var btn = Button.new()
		btn.text = entry["title"]
		btn.disabled = not entry["unlocked"]
		btn.add_theme_font_size_override("font_size", 16)
		btn.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.custom_minimum_size = Vector2(0, 40)
		btn.pressed.connect(_show_lore.bind(entry))
		lore_list.add_child(btn)

func _show_lore(entry: Dictionary) -> void:
	detail_title.text = entry["title"]
	detail_content.text = _get_lore_text(entry["id"])
	entry_details.visible = true

func _get_lore_text(lore_id: String) -> String:
	var texts = {
		"virus_origin": "The virus originated from a research facility studying ancient pathogens. A containment breach released the pathogen into the city's water supply.",
		"virus_structure": "The virus rewrites host DNA, creating aggressive behavior and enhanced physical capabilities. It spreads through bodily fluids.",
		"military_response": "The military established a quarantine zone. All exits are sealed. They claim to be working on a cure, but broadcasts have stopped.",
		"survivor_account": "I've seen things... people changing. It takes hours sometimes, minutes others. There's no pattern. Just run. Just survive."
	}
	return texts.get(lore_id, "Information not yet available.")

func _on_close_pressed() -> void:
	AudioManager.play_ui_sound("menu_select")
	UIManager.hide_journal()
	queue_free()