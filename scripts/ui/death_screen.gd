extends Control

## DeathScreen - Game over screen

@onready var retry_button: Button = %RetryButton
@onready var load_save_button: Button = %LoadSaveButton
@onready var main_menu_button: Button = %MainMenuButton
@onready var quit_button: Button = %QuitButton
@onready var survival_time_label: Label = %SurvivalTime
@onready var day_count_label: Label = %DayCount

func _ready() -> void:
	_connect_signals()
	_update_stats()
	
	# Play death sound
	AudioManager.play_sfx("death")

func _connect_signals() -> void:
	retry_button.pressed.connect(_on_retry_pressed)
	load_save_button.pressed.connect(_on_load_save_pressed)
	main_menu_button.pressed.connect(_on_main_menu_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

func _update_stats() -> void:
	var play_time = GameManager.play_time
	var hours = int(play_time / 3600)
	var minutes = int(fmod(play_time, 3600) / 60)
	var seconds = int(fmod(play_time, 60))
	survival_time_label.text = "Survival Time: %02d:%02d:%02d" % [hours, minutes, seconds]
	
	day_count_label.text = "Day: %d" % GameManager.world_state.get("day_count", 1)

func _on_retry_pressed() -> void:
	AudioManager.play_ui_sound("menu_select")
	GameManager.respawn_at_checkpoint()
	queue_free()

func _on_load_save_pressed() -> void:
	AudioManager.play_ui_sound("menu_select")
	UIManager.close_all_ui()
	GameManager.return_to_main_menu()
	# Show load menu
	_show_load_menu()

func _show_load_menu() -> void:
	var dialog = AcceptDialog.new()
	dialog.title = "Load Game"
	
	var vbox = VBoxContainer.new()
	dialog.add_child(vbox)
	
	var saves = SaveManager.get_all_saves_info()
	for i in range(saves.size()):
		var save = saves[i]
		if save.get("exists") and not save.get("corrupted"):
			var btn = Button.new()
			btn.text = "Slot %d - Day %d - %s" % [
				i + 1,
				save.get("day_count", 1),
				save.get("level", "Unknown")
			]
			btn.custom_minimum_size = Vector2(500, 40)
			btn.pressed.connect(_on_load_slot_selected.bind(i, dialog))
			vbox.add_child(btn)
	
	dialog.popup_centered()

func _on_load_slot_selected(slot: int, dialog: AcceptDialog) -> void:
	var save_data = SaveManager.load_game(slot)
	if save_data:
		GameManager._apply_save_data(save_data)
		GameManager._change_level(GameManager.current_level)
		GameManager.current_state = GameManager.GameState.PLAYING
		GameManager.game_state_changed.emit(GameManager.GameState.PLAYING)
		GameManager.game_loaded.emit(save_data)
	dialog.queue_free()
	queue_free()

func _on_main_menu_pressed() -> void:
	AudioManager.play_ui_sound("menu_select")
	GameManager.return_to_main_menu()
	queue_free()

func _on_quit_pressed() -> void:
	AudioManager.play_ui_sound("menu_select")
	get_tree().quit()