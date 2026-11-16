extends Control

## MainMenu - Main menu controller

@onready var new_game_button: Button = %NewGameButton
@onready var continue_button: Button = %ContinueButton
@onready var load_game_button: Button = %LoadGameButton
@onready var settings_button: Button = %SettingsButton
@onready var credits_button: Button = %CreditsButton
@onready var quit_button: Button = %QuitButton

func _ready() -> void:
	_connect_signals()
	_check_continue_availability()

func _connect_signals() -> void:
	new_game_button.pressed.connect(_on_new_game_pressed)
	continue_button.pressed.connect(_on_continue_pressed)
	load_game_button.pressed.connect(_on_load_game_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	credits_button.pressed.connect(_on_credits_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	
	GameManager.game_loaded.connect(_on_game_loaded)

func _check_continue_availability() -> var:
	var saves = SaveManager.get_all_saves_info()
	var has_save = false
	for save in saves:
		if save.get("exists") and not save.get("corrupted"):
			has_save = true
			break
	continue_button.disabled = not has_save

func _on_new_game_pressed() -> void:
	AudioManager.play_ui_sound("menu_select")
	_show_difficulty_selection()

func _show_difficulty_selection() -> void:
	var dialog = ConfirmationDialog.new()
	dialog.title = "Select Difficulty"
	dialog.ok_button_text = "Start"
	dialog.cancel_button_text = "Cancel"
	
	var vbox = VBoxContainer.new()
	dialog.add_child(vbox)
	
	var difficulties = [
		{"id": 0, "name": "Easy", "desc": "Reduced damage, more resources"},
		{"id": 1, "name": "Normal", "desc": "Balanced survival experience"},
		{"id": 2, "name": "Hard", "desc": "Increased damage, scarce resources"},
		{"id": 3, "name": "Survival", "desc": "Permadeath, minimal resources"}
	]
	
	var button_group = ButtonGroup.new()
	
	for diff in difficulties:
		var btn = CheckButton.new()
		btn.text = diff["name"] + " - " + diff["desc"]
		btn.button_group = button_group
		btn.name = "diff_" + str(diff["id"])
		vbox.add_child(btn)
		if diff["id"] == 1:
			btn.button_pressed = true
	
	dialog.confirmed.connect(_on_difficulty_confirmed.bind(dialog))
	dialog.popup_centered()

func _on_difficulty_confirmed(dialog: ConfirmationDialog) -> void:
	for child in dialog.get_children():
		if child is CheckButton and child.button_pressed:
			var diff_id = int(child.name.replace("diff_", ""))
			GameManager.new_game(GameManager.Difficulty(diff_id))
			break
	dialog.queue_free()

func _on_continue_pressed() -> void:
	AudioManager.play_ui_sound("menu_select")
	GameManager.continue_game()

func _on_load_game_pressed() -> void:
	AudioManager.play_ui_sound("menu_select")
	_show_load_menu()

func _show_load_menu() -> void:
	var dialog = AcceptDialog.new()
	dialog.title = "Load Game"
	
	var vbox = VBoxContainer.new()
	dialog.add_child(vbox)
	
	var saves = SaveManager.get_all_saves_info()
	var has_saves = false
	
	for i in range(saves.size()):
		var save = saves[i]
		if save.get("exists") and not save.get("corrupted"):
			has_saves = true
			var btn = Button.new()
			btn.text = "Slot %d - Day %d - %s - %s" % [
				i + 1,
				save.get("day_count", 1),
				save.get("level", "Unknown"),
				Time.get_datetime_string_from_unix_time(save.get("timestamp", 0))
			]
			btn.custom_minimum_size = Vector2(500, 40)
			btn.pressed.connect(_on_load_slot_selected.bind(i))
			vbox.add_child(btn)
	
	if not has_saves:
		var label = Label.new()
		label.text = "No save files found."
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(label)
	
	dialog.popup_centered()

func _on_load_slot_selected(slot: int) -> void:
	var save_data = SaveManager.load_game(slot)
	if save_data:
		GameManager._apply_save_data(save_data)
		GameManager._change_level(GameManager.current_level)
		GameManager.current_state = GameManager.GameState.PLAYING
		GameManager.game_state_changed.emit(GameManager.GameState.PLAYING)
		GameManager.game_loaded.emit(save_data)

func _on_settings_pressed() -> void:
	AudioManager.play_ui_sound("menu_select")
	UIManager.show_settings()

func _on_credits_pressed() -> void:
	AudioManager.play_ui_sound("menu_select")
	_show_credits()

func _show_credits() -> void:
	var dialog = AcceptDialog.new()
	dialog.title = "Credits"
	
	var vbox = VBoxContainer.new()
	dialog.add_child(vbox)
	
	var credits = [
		"LAST NIGHT",
		"",
		"Game Design & Programming",
		"AI Assistant",
		"",
		"Engine: Godot 4.x",
		"",
		"Assets: CC0 & Original",
		"Audio: CC0 & Original",
		"",
		"Special Thanks:",
		"Godot Community",
		"Open Source Contributors"
	]
	
	for line in credits:
		var label = Label.new()
		label.text = line
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(label)
	
	dialog.popup_centered()

func _on_quit_pressed() -> void:
	AudioManager.play_ui_sound("menu_select")
	get_tree().quit()

func _on_game_loaded(save_data: Dictionary) -> void:
	_check_continue_availability()