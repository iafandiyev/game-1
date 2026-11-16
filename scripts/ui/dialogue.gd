extends Control

## Dialogue - Dialogue system for story sequences

signal dialogue_finished()

@onready var speaker_name: Label = %SpeakerName
@onready var dialogue_text: Label = %DialogueText
@onready var choices_container: VBoxContainer = %ChoicesContainer
@onready var continue_prompt: Label = %ContinuePrompt

var dialogue_data: Dictionary = {}
var current_line: int = 0
var lines: Array[Dictionary] = []
var waiting_for_input: bool = false
var typewriter_tween: Tween = null
var full_text: String = ""

func _ready() -> void:
	set_process_mode(PROCESS_MODE_ALWAYS)
	_input.suspend()

func set_dialogue_data(data: Dictionary) -> void:
	dialogue_data = data
	lines = data.get("lines", [])
	current_line = 0
	waiting_for_input = false
	
	if lines.size() > 0:
		_show_line(lines[0])
	else:
		_finish_dialogue()

func _show_line(line: Dictionary) -> void:
	speaker_name.text = line.get("speaker", "")
	dialogue_text.text = ""
	full_text = line.get("text", "")
	
	var choices = line.get("choices", [])
	if choices.size() > 0:
		_show_choices(choices)
	else:
		_show_text_with_typewriter()
		waiting_for_input = true

func _show_text_with_typewriter() -> void:
	if typewriter_tween:
		typewriter_tween.kill()
	
	typewriter_tween = create_tween()
	var char_delay = 0.02
	
	for i in range(full_text.length() + 1):
		typewriter_tween.tween_callback(_update_text.bind(i))
		typewriter_tween.tween_callback(_wait_frame)
	
	typewriter_tween.finished.connect(_on_typewriter_finished)

func _update_text(char_count: int) -> void:
	dialogue_text.text = full_text.substr(0, char_count)

func _wait_frame() -> void:
	# Wait one frame (handled by tween)

func _on_typewriter_finished() -> void:
	dialogue_text.text = full_text
	continue_prompt.visible = true
	
	# Blink animation
	var tween = continue_prompt.create_tween()
	tween.set_loops()
	tween.tween_property(continue_prompt, "modulate:a", 0.3, 0.5)
	tween.tween_property(continue_prompt, "modulate:a", 1.0, 0.5)

func _show_choices(choices: Array[Dictionary]) -> void:
	for child in choices_container.get_children():
		child.queue_free()
	
	for choice in choices:
		var btn = Button.new()
		btn.text = choice.get("text", "")
		btn.custom_minimum_size = Vector2(600, 50)
		btn.add_theme_font_size_override("font_size", 18)
		btn.pressed.connect(_on_choice_selected.bind(choice))
		choices_container.add_child(btn)

func _on_choice_selected(choice: Dictionary) -> void:
	AudioManager.play_ui_sound("menu_select")
	
	# Handle choice consequence
	var consequence = choice.get("consequence", "")
	if consequence != "":
		_handle_consequence(consequence)
	
	_next_line()

func _handle_consequence(consequence: String) -> void:
	# Would trigger game events based on choice
	match consequence:
		"ending_a":
			GameManager.complete_mission("m15_final_choice")
			# Trigger ending A
		"ending_b":
			GameManager.complete_mission("m15_final_choice")
			# Trigger ending B

func _unhandled_input(event: InputEvent) -> void:
	if waiting_for_input and event is InputEventMouseButton and event.pressed:
		_next_line()
	elif waiting_for_input and event is InputEventKey and event.pressed and event.keycode == KEY_SPACE:
		_next_line()

func _next_line() -> void:
	waiting_for_input = false
	continue_prompt.visible = false
	
	if typewriter_tween:
		typewriter_tween.kill()
		typewriter_tween = null
	
	current_line += 1
	if current_line < lines.size():
		_show_line(lines[current_line])
	else:
		_finish_dialogue()

func _finish_dialogue() -> void:
	dialogue_finished.emit()
	queue_free()