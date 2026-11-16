extends Node

class_name UIManager

## UIManager - Central UI management
## Handles UI scene transitions, HUD updates, and menu navigation

signal ui_opened(ui_name: String)
signal ui_closed(ui_name: String)
signal hud_updated(stat_name: String, value: Variant)

@export_group("UI Scenes")
@export var main_menu_scene: PackedScene
@export var pause_menu_scene: PackedScene
@export var death_screen_scene: PackedScene
@export var inventory_scene: PackedScene
@export var crafting_scene: PackedScene
@export var map_scene: PackedScene
@export var journal_scene: PackedScene
@export var settings_scene: PackedScene
@export var dialogue_scene: PackedScene
@export var checkpoint_notification_scene: PackedScene
@export var loading_screen_scene: PackedScene
@export var hud_scene: PackedScene

var current_ui: Node = null
var hud_instance: Node = null
var ui_stack: Array[Node] = []
var canvas_layer: CanvasLayer = null

func _ready() -> void:
	_process_mode = Node.PROCESS_MODE_ALWAYS
	_create_canvas_layer()
	_show_main_menu()

func _create_canvas_layer() -> void:
	canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 100
	get_tree().get_root().add_child(canvas_layer)

func _show_main_menu() -> void:
	if main_menu_scene:
		var instance = main_menu_scene.instantiate()
		canvas_layer.add_child(instance)
		current_ui = instance
		ui_opened.emit("main_menu")

func show_pause_menu() -> void:
	if pause_menu_scene and not _is_ui_open("pause_menu"):
		var instance = pause_menu_scene.instantiate()
		canvas_layer.add_child(instance)
		_push_ui(instance, "pause_menu")

func hide_pause_menu() -> void:
	_pop_ui("pause_menu")

func show_death_screen() -> void:
	if death_screen_scene:
		var instance = death_screen_scene.instantiate()
		canvas_layer.add_child(instance)
		_push_ui(instance, "death_screen")

func show_inventory() -> void:
	if inventory_scene and not _is_ui_open("inventory"):
		var instance = inventory_scene.instantiate()
		canvas_layer.add_child(instance)
		_push_ui(instance, "inventory")

func hide_inventory() -> void:
	_pop_ui("inventory")

func show_crafting() -> void:
	if crafting_scene and not _is_ui_open("crafting"):
		var instance = crafting_scene.instantiate()
		canvas_layer.add_child(instance)
		_push_ui(instance, "crafting")

func hide_crafting() -> void:
	_pop_ui("crafting")

func show_map() -> void:
	if map_scene and not _is_ui_open("map"):
		var instance = map_scene.instantiate()
		canvas_layer.add_child(instance)
		_push_ui(instance, "map")

func hide_map() -> void:
	_pop_ui("map")

func show_journal() -> void:
	if journal_scene and not _is_ui_open("journal"):
		var instance = journal_scene.instantiate()
		canvas_layer.add_child(instance)
		_push_ui(instance, "journal")

func hide_journal() -> void:
	_pop_ui("journal")

func show_settings() -> void:
	if settings_scene and not _is_ui_open("settings"):
		var instance = settings_scene.instantiate()
		canvas_layer.add_child(instance)
		_push_ui(instance, "settings")

func hide_settings() -> void:
	_pop_ui("settings")

func show_dialogue(dialogue_data: Dictionary) -> void:
	if dialogue_scene and not _is_ui_open("dialogue"):
		var instance = dialogue_scene.instantiate()
		if instance.has_method("set_dialogue_data"):
			instance.set_dialogue_data(dialogue_data)
		canvas_layer.add_child(instance)
		_push_ui(instance, "dialogue")

func hide_dialogue() -> void:
	_pop_ui("dialogue")

func show_checkpoint_notification(checkpoint_name: String) -> void:
	if checkpoint_notification_scene:
		var instance = checkpoint_notification_scene.instantiate()
		if instance.has_method("set_checkpoint_name"):
			instance.set_checkpoint_name(checkpoint_name)
		canvas_layer.add_child(instance)
		# Auto-hide after animation
		var timer = Timer.new()
		timer.wait_time = 3.0
		timer.one_shot = true
		timer.timeout.connect(instance.queue_free.bind())
		instance.add_child(timer)
		timer.start()

func show_loading_screen() -> void:
	if loading_screen_scene:
		var instance = loading_screen_scene.instantiate()
		canvas_layer.add_child(instance)
		current_ui = instance

func hide_loading_screen() -> void:
	if current_ui and current_ui == get_tree().get_root().get_node_or_null("CanvasLayer/LoadingScreen"):
		current_ui.queue_free()
		current_ui = null

func create_hud() -> void:
	if hud_scene and not hud_instance:
		hud_instance = hud_scene.instantiate()
		canvas_layer.add_child(hud_instance)
		hud_instance.set_as_top_level(true)

func remove_hud() -> void:
	if hud_instance:
		hud_instance.queue_free()
		hud_instance = null

func update_hud(stat_name: String, value: Variant) -> void:
	if hud_instance and hud_instance.has_method("update_stat"):
		hud_instance.update_stat(stat_name, value)
	hud_updated.emit(stat_name, value)

func update_hud_multiple(stats: Dictionary) -> void:
	for key, value in stats:
		update_hud(key, value)

func _push_ui(ui_node: Node, ui_name: String) -> void:
	ui_stack.append(ui_node)
	current_ui = ui_node
	ui_opened.emit(ui_name)
	
	# Pause game if opening overlay UI
	if ui_name in ["pause_menu", "inventory", "crafting", "map", "journal", "settings", "dialogue"]:
		get_tree().paused = true

func _pop_ui(ui_name: String) -> void:
	for i in range(ui_stack.size() - 1, -1, -1):
		if ui_stack[i].get_name() == ui_name or ui_stack[i].get_class() == ui_name:
			var ui = ui_stack.pop_at(i)
			ui.queue_free()
			ui_closed.emit(ui_name)
			
			# Update current_ui
			if ui_stack.is_empty():
				current_ui = null
			else:
				current_ui = ui_stack[-1]
			
			# Resume game if closing overlay UI
			if ui_name in ["pause_menu", "inventory", "crafting", "map", "journal", "settings", "dialogue"]:
				if not _has_overlay_ui():
					get_tree().paused = false
			break

func _is_ui_open(ui_name: String) -> bool:
	for ui in ui_stack:
		if ui.get_name() == ui_name or ui.get_class() == ui_name:
			return true
	return false

func _has_overlay_ui() -> bool:
	var overlay_uis = ["pause_menu", "inventory", "crafting", "map", "journal", "settings", "dialogue", "death_screen"]
	for ui in ui_stack:
		if ui.get_name() in overlay_uis or ui.get_class() in overlay_uis:
			return true
	return false

func close_all_ui() -> void:
	for ui in ui_stack:
		ui.queue_free()
	ui_stack.clear()
	current_ui = null
	get_tree().paused = false

func get_current_ui() -> Node:
	return current_ui

func is_ui_open(ui_name: String) -> bool:
	return _is_ui_open(ui_name)

func set_hud_visible(visible: bool) -> void:
	if hud_instance:
		hud_instance.visible = visible

# Notification system
func show_notification(message: String, duration: float = 3.0, notification_type: String = "info") -> void:
	var notification = _create_notification(message, notification_type)
	canvas_layer.add_child(notification)
	
	var timer = Timer.new()
	timer.wait_time = duration
	timer.one_shot = true
	timer.timeout.connect(notification.queue_free.bind())
	notification.add_child(timer)
	timer.start()

func _create_notification(message: String, notification_type: String) -> Control:
	var panel = Panel.new()
	panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	panel.set_offset_bottom(-100)
	panel.add_theme_stylebox_override("panel", _create_notification_stylebox(notification_type))
	
	var label = Label.new()
	label.text = message
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", Color.WHITE)
	panel.add_child(label)
	
	# Animate in
	var tween = panel.create_tween()
	tween.tween_property(panel, "offset_bottom", -50, 0.3)
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	
	# Animate out (will be called by timer)
	panel._notification_timer = timer
	return panel

func _create_notification_stylebox(type: String) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.1, 0.9)
	style.border_width_bottom = 3
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	
	match type:
		"warning":
			style.border_color = Color(1.0, 0.8, 0.0, 1.0)
		"error":
			style.border_color = Color(1.0, 0.2, 0.2, 1.0)
		"success":
			style.border_color = Color(0.2, 0.8, 0.3, 1.0)
		_:
			style.border_color = Color(0.3, 0.7, 1.0, 1.0)
	
	return style

# Screen effects
func screen_shake(intensity: float = 5.0, duration: float = 0.3) -> void:
	if canvas_layer:
		var original_pos = canvas_layer.position
		var tween = canvas_layer.create_tween()
		tween.set_loops(int(duration / 0.05))
		tween.tween_property(canvas_layer, "position", original_pos + Vector2(randf_range(-intensity, intensity), randf_range(-intensity, intensity)), 0.05)
		tween.tween_property(canvas_layer, "position", original_pos, 0.05)
		tween.set_trans(Tween.TRANS_SINE)

func flash_screen(color: Color = Color(1, 1, 1, 0.5), duration: float = 0.1) -> void:
	var flash = ColorRect.new()
	flash.color = color
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas_layer.add_child(flash)
	
	var tween = flash.create_tween()
	tween.tween_property(flash, "color:a", 0.0, duration)
	tween.finished.connect(flash.queue_free.bind())