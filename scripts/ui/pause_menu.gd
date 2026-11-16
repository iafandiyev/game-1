extends Control

## PauseMenu - In-game pause menu

@onready var resume_button: Button = %ResumeButton
@onready var save_button: Button = %SaveButton
@onready var settings_button: Button = %SettingsButton
@onready var main_menu_button: Button = %MainMenuButton
@onready var quit_button: Button = %QuitButton

func _ready() -> void:
	_connect_signals()

func _connect_signals() -> void:
	resume_button.pressed.connect(_on_resume_pressed)
	save_button.pressed.connect(_on_save_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	main_menu_button.pressed.connect(_on_main_menu_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	
	# Handle ESC to resume
	InputManager.pause_pressed.connect(_on_resume_pressed)

func _on_resume_pressed() -> void:
	AudioManager.play_ui_sound("menu_select")
	UIManager.hide_pause_menu()
	queue_free()

func _on_save_pressed() -> void:
	AudioManager.play_ui_sound("menu_select")
	GameManager.request_save()
	UIManager.show_notification("Game saved!", 2.0, "success")

func _on_settings_pressed() -> void:
	AudioManager.play_ui_sound("menu_select")
	UIManager.show_settings()

func _on_main_menu_pressed() -> void:
	AudioManager.play_ui_sound("menu_select")
	var confirm = ConfirmationDialog.new()
	confirm.title = "Return to Main Menu?"
	confirm.text = "Any unsaved progress will be lost. Are you sure?"
	confirm.ok_button_text = "Yes"
	confirm.cancel_button_text = "No"
	confirm.confirmed.connect(_on_confirm_main_menu)
	confirm.popup_centered()
	add_child(confirm)

func _on_confirm_main_menu() -> void:
	GameManager.return_to_main_menu()
	queue_free()

func _on_quit_pressed() -> void:
	AudioManager.play_ui_sound("menu_select")
	var confirm = ConfirmationDialog.new()
	confirm.title = "Quit Game?"
	confirm.text = "Are you sure you want to quit to desktop?"
	confirm.ok_button_text = "Yes"
	confirm.cancel_button_text = "No"
	confirm.confirmed.connect(_on_confirm_quit)
	confirm.popup_centered()
	add_child(confirm)

func _on_confirm_quit() -> void:
	get_tree().quit()