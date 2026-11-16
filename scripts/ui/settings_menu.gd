extends Control

## SettingsMenu - Game settings interface

@onready var master_slider: HSlider = %MasterSlider
@onready var music_slider: HSlider = %MusicSlider
@onready var sfx_slider: HSlider = %SfxSlider
@onready var brightness_slider: HSlider = %BrightnessSlider
@onready var vsync_check: CheckButton = %VSyncCheck
@onready var auto_save_check: CheckButton = %AutoSaveCheck
@onready var vibration_check: CheckButton = %VibrationCheck
@onready var tutorial_check: CheckButton = %TutorialCheck
@onready var control_scheme_option: OptionButton = %ControlSchemeOption
@onready var language_option: OptionButton = %LanguageOption
@onready var back_button: Button = %BackButton

func _ready() -> void:
	_load_settings()
	_connect_signals()

func _connect_signals() -> void:
	master_slider.value_changed.connect(_on_master_volume_changed)
	music_slider.value_changed.connect(_on_music_volume_changed)
	sfx_slider.value_changed.connect(_on_sfx_volume_changed)
	brightness_slider.value_changed.connect(_on_brightness_changed)
	vsync_check.toggled.connect(_on_vsync_toggled)
	auto_save_check.toggled.connect(_on_auto_save_toggled)
	vibration_check.toggled.connect(_on_vibration_toggled)
	tutorial_check.toggled.connect(_on_tutorial_toggled)
	control_scheme_option.item_selected.connect(_on_control_scheme_changed)
	language_option.item_selected.connect(_on_language_changed)
	back_button.pressed.connect(_on_back_pressed)

func _load_settings() -> void:
	master_slider.value = GameManager.get_setting("master_volume") or 1.0
	music_slider.value = GameManager.get_setting("music_volume") or 0.7
	sfx_slider.value = GameManager.get_setting("sfx_volume") or 1.0
	brightness_slider.value = GameManager.get_setting("brightness") or 1.0
	vsync_check.button_pressed = true
	auto_save_check.button_pressed = GameManager.get_setting("auto_save") or true
	vibration_check.button_pressed = GameManager.get_setting("vibration") or true
	tutorial_check.button_pressed = GameManager.get_setting("show_tutorial") or true
	control_scheme_option.selected = 0 # Default
	language_option.selected = 0 # English

func _on_master_volume_changed(value: float) -> void:
	GameManager.set_setting("master_volume", value)
	AudioManager.set_master_volume(value)

func _on_music_volume_changed(value: float) -> void:
	GameManager.set_setting("music_volume", value)
	AudioManager.set_music_volume(value)

func _on_sfx_volume_changed(value: float) -> void:
	GameManager.set_setting("sfx_volume", value)
	AudioManager.set_sfx_volume(value)

func _on_brightness_changed(value: float) -> void:
	GameManager.set_setting("brightness", value)
	# Apply brightness to rendering
	RenderingServer.set_default_clear_color(Color(value * 0.05, value * 0.05, value * 0.05, 1))

func _on_vsync_toggled(pressed: bool) -> void:
	# VSync handled by project settings
	OS.vsync_enabled = pressed

func _on_auto_save_toggled(pressed: bool) -> void:
	GameManager.set_setting("auto_save", pressed)

func _on_vibration_toggled(pressed: bool) -> void:
	GameManager.set_setting("vibration", pressed)

func _on_tutorial_toggled(pressed: bool) -> void:
	GameManager.set_setting("show_tutorial", pressed)

func _on_control_scheme_changed(index: int) -> void:
	var schemes = ["default", "left_handed", "custom"]
	GameManager.set_setting("control_scheme", schemes[index])

func _on_language_changed(index: int) -> void:
	var languages = ["en", "es", "fr", "de", "ru", "zh", "ja"]
	GameManager.set_setting("language", languages[index])
	# Would trigger translation reload

func _on_back_pressed() -> void:
	AudioManager.play_ui_sound("menu_select")
	UIManager.hide_settings()
	queue_free()