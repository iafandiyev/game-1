extends Control

## Credits - Credits screen

@onready var scroll_container: ScrollContainer = %ScrollContainer
@onready var credits_label: Label = %CreditsLabel
@onready var back_button: Button = %BackButton

func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	_show_credits()

func _show_credits() -> void:
	var credits = """
LAST NIGHT

Game Design & Development
AI Assistant

Engine
Godot 4.x

Programming
GDScript

Art & Assets
Original Assets
CC0 Licensed Assets
Kenney.nl
OpenGameArt.org

Audio
Original Sounds
CC0 Licensed Audio
Freesound.org

Special Thanks
Godot Engine Community
Open Source Contributors
Playtesters

Version 1.0.0
Built with passion for survival horror games.
"""
	
	credits_label.text = credits
	credits_label.autowrap_mode = TextServer.AUTOWRAP_WORD

func _on_back_pressed() -> void:
	AudioManager.play_ui_sound("menu_select")
	queue_free()