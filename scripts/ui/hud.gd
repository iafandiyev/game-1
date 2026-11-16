extends CanvasLayer

class_name HUD

## HUD - In-game heads-up display

@onready var health_bar: ProgressBar = %HealthBar
@onready var stamina_bar: ProgressBar = %StaminaBar
@onready var hunger_bar: ProgressBar = %HungerBar
@onready var thirst_bar: ProgressBar = %ThirstBar
@onready var infection_bar: ProgressBar = %InfectionBar
@onready var weapon_name: Label = %WeaponName
@onready var current_ammo: Label = %CurrentAmmo
@onready var reserve_ammo: Label = %ReserveAmmo
@onready var weapon_slots: Array[TextureRect] = [%WeaponSlot1, %WeaponSlot2, %WeaponSlot3, %WeaponSlot4]
@onready var objective_label: Label = %ObjectiveText
@onready var interaction_prompt: Label = %InteractionPrompt

func _ready() -> void:
	_connect_signals()
	_update_all()

func _connect_signals() -> void:
	SurvivalManager.health_changed.connect(_on_health_changed)
	SurvivalManager.stamina_changed.connect(_on_stamina_changed)
	SurvivalManager.hunger_changed.connect(_on_hunger_changed)
	SurvivalManager.thirst_changed.connect(_on_thirst_changed)
	SurvivalManager.infection_changed.connect(_on_infection_changed)
	GameManager.weapon_changed.connect(_on_weapon_changed)
	GameManager.ammo_changed.connect(_on_ammo_changed)
	MissionManager.objective_updated.connect(_on_objective_updated)

func _update_all() -> void:
	_on_health_changed(SurvivalManager.get_stat("health"), SurvivalManager.get_stat("max_health"))
	_on_stamina_changed(SurvivalManager.get_stat("stamina"), SurvivalManager.get_stat("max_stamina"))
	_on_hunger_changed(SurvivalManager.get_stat("hunger"), SurvivalManager.get_stat("max_hunger"))
	_on_thirst_changed(SurvivalManager.get_stat("thirst"), SurvivalManager.get_stat("max_thirst"))
	_on_infection_changed(SurvivalManager.get_stat("infection"), SurvivalManager.get_stat("max_infection"))

func update_stat(stat_name: String, value: Variant) -> void:
	match stat_name:
		"health":
			_on_health_changed(value, SurvivalManager.get_stat("max_health"))
		"stamina":
			_on_stamina_changed(value, SurvivalManager.get_stat("max_stamina"))
		"hunger":
			_on_hunger_changed(value, SurvivalManager.get_stat("max_hunger"))
		"thirst":
			_on_thirst_changed(value, SurvivalManager.get_stat("max_thirst"))
		"infection":
			_on_infection_changed(value, SurvivalManager.get_stat("max_infection"))
		"objective":
			objective_label.text = str(value)

func _on_health_changed(current: float, max: float) -> void:
	health_bar.max_value = max
	health_bar.value = current
	
	# Color change based on health
	var percent = current / max if max > 0 else 0
	if percent <= 0.25:
		health_bar.add_theme_color_override("fill_color", Color(1, 0.1, 0.1, 1))
	elif percent <= 0.5:
		health_bar.add_theme_color_override("fill_color", Color(1, 0.5, 0.1, 1))
	else:
		health_bar.add_theme_color_override("fill_color", Color(0.8, 0.1, 0.1, 1))

func _on_stamina_changed(current: float, max: float) -> void:
	stamina_bar.max_value = max
	stamina_bar.value = current

func _on_hunger_changed(current: float, max: float) -> void:
	hunger_bar.max_value = max
	hunger_bar.value = current
	
	var percent = current / max if max > 0 else 0
	if percent <= 0.2:
		hunger_bar.add_theme_color_override("fill_color", Color(1, 0.3, 0.1, 1))
	elif percent <= 0.4:
		hunger_bar.add_theme_color_override("fill_color", Color(1, 0.7, 0.1, 1))
	else:
		hunger_bar.add_theme_color_override("fill_color", Color(0.9, 0.6, 0.1, 1))

func _on_thirst_changed(current: float, max: float) -> void:
	thirst_bar.max_value = max
	thirst_bar.value = current
	
	var percent = current / max if max > 0 else 0
	if percent <= 0.2:
		thirst_bar.add_theme_color_override("fill_color", Color(0.1, 0.5, 1, 1))
	elif percent <= 0.4:
		thirst_bar.add_theme_color_override("fill_color", Color(0.1, 0.7, 1, 1))
	else:
		thirst_bar.add_theme_color_override("fill_color", Color(0.1, 0.5, 0.9, 1))

func _on_infection_changed(current: float, max: float) -> void:
	infection_bar.max_value = max
	infection_bar.value = current
	
	var percent = current / max if max > 0 else 0
	if percent >= 0.75:
		infection_bar.add_theme_color_override("fill_color", Color(1, 0.1, 0.5, 1))
	elif percent >= 0.5:
		infection_bar.add_theme_color_override("fill_color", Color(0.8, 0.1, 0.8, 1))
	elif percent >= 0.25:
		infection_bar.add_theme_color_override("fill_color", Color(0.6, 0.1, 0.8, 1))
	else:
		infection_bar.add_theme_color_override("fill_color", Color(0.4, 0.1, 0.6, 1))

func _on_weapon_changed(weapon: Dictionary) -> void:
	if weapon:
		weapon_name.text = weapon.get("name", "UNARMED").to_upper()
		weapon_slots[GameManager.current_weapon_slot].modulate = Color(1, 1, 1, 1)
	else:
		weapon_name.text = "UNARMED"

func _on_ammo_changed(current: int, reserve: int) -> void:
	var weapon = GameManager.current_weapon
	if weapon and weapon.get("category") == "ranged":
		current_ammo.text = str(current)
		reserve_ammo.text = str(reserve)
		AmmoContainer.visible = true
	else:
		current_ammo.text = "--"
		reserve_ammo.text = "--"
		AmmoContainer.visible = false

func _on_objective_updated(mission_id: String, objective_id: String, completed: bool) -> void:
	var mission = MissionManager.get_mission_state(mission_id)
	if mission:
		var objective_text = MissionManager.get_objective_text(mission_id, objective_id)
		if objective_text:
			objective_label.text = objective_text

func show_interaction_prompt(text: String) -> void:
	interaction_prompt.text = text
	interaction_prompt.visible = true
	
	var tween = interaction_prompt.create_tween()
	tween.tween_property(interaction_prompt, "modulate:a", 1.0, 0.2)

func hide_interaction_prompt() -> void:
	var tween = interaction_prompt.create_tween()
	tween.tween_property(interaction_prompt, "modulate:a", 0.0, 0.2)
	tween.finished.connect(_on_prompt_fade_out_finished)

func _on_prompt_fade_out_finished() -> void:
	interaction_prompt.visible = false

func show_notification(message: String, notification_type: String = "info") -> void:
	var notification = _create_notification(message, notification_type)
	add_child(notification)
	
	var timer = Timer.new()
	timer.wait_time = 4.0
	timer.one_shot = true
	timer.timeout.connect(notification.queue_free.bind())
	notification.add_child(timer)
	timer.start()

func _create_notification(message: String, type: String) -> Control:
	var panel = Panel.new()
	panel.size = Vector2(300, 60)
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.1, 0.9)
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
			style.border_width_bottom = 3
		"error":
			style.border_color = Color(1.0, 0.2, 0.2, 1.0)
			style.border_width_bottom = 3
		"success":
			style.border_color = Color(0.2, 0.8, 0.3, 1.0)
			style.border_width_bottom = 3
		_:
			style.border_color = Color(0.3, 0.7, 1.0, 1.0)
			style.border_width_bottom = 3
	
	panel.add_theme_stylebox_override("panel", style)
	
	var label = Label.new()
	label.text = message
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color.WHITE)
	panel.add_child(label)
	
	# Animate in
	var tween = panel.create_tween()
	tween.tween_property(panel, "position:x", -320, 0.3).from(20)
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	
	return panel