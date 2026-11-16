extends LevelBase

class_name Safehouse

## Safehouse - Player base with upgrades and storage

@export var safehouse_upgrades: Dictionary = {}

func _ready() -> void:
	level_id = "safehouse"
	level_name = "Safehouse"
	super._ready()
	_setup_safehouse_interactables()

func _setup_safehouse_interactables() -> void:
	var interactables = get_node_or_null("Entities/Interactables")
	if not interactables:
		return
	
	for child in interactables.get_children():
		if child is Area2D:
			child.body_entered.connect(_on_interactable_entered.bind(child.name))
			child.body_exited.connect(_on_interactable_exited.bind(child.name))

func _on_interactable_entered(body: Node2D, interactable_name: String) -> void:
	if body.is_in_group("player"):
		var prompt_text = _get_interact_prompt(interactable_name)
		if prompt_text != "":
			HUD.show_interaction_prompt(prompt_text)

func _on_interactable_exited(body: Node2D, interactable_name: String) -> void:
	if body.is_in_group("player"):
		HUD.hide_interaction_prompt()

func _get_interact_prompt(name: String) -> String:
	match name:
		"storage": return "[E] Open Storage"
		"bed": return "[E] Sleep (Pass Time)"
		"crafting_station": return "[E] Craft"
		"weapon_rack": return "[E] Weapon Storage"
		"generator": return "[E] Generator"
		"upgrade_terminal": return "[E] Upgrades"
		"exit_city": return "[E] Leave Safehouse"
		_: return ""

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_E:
		var player = get_node_or_null("Player")
		if player:
			_try_interact(player)

func _try_interact(player: Node) -> void:
	var interactables = get_node_or_null("Entities/Interactables")
	if not interactables:
		return
	
	for child in interactables.get_children():
		if child is Area2D:
			var overlap = child.get_overlapping_bodies()
			for body in overlap:
				if body == player:
					_interact_with(child.name)
					return

func _interact_with(name: String) -> void:
	match name:
		"storage":
			UIManager.show_inventory()
		"bed":
			_sleep()
		"crafting_station":
			UIManager.show_crafting()
		"weapon_rack":
			UIManager.show_inventory() # Would show weapon-specific UI
		"generator":
			_toggle_generator()
		"upgrade_terminal":
			_show_upgrades()
		"exit_city":
			_leave_safehouse()

func _sleep() -> void:
	# Pass time to next morning (6 AM)
	var current_time = WorldManager.get_time_of_day()
	var hours_to_morning = 0.0
	
	if current_time >= 20.0:
		hours_to_morning = (24.0 - current_time) + 6.0
	elif current_time < 6.0:
		hours_to_morning = 6.0 - current_time
	else:
		hours_to_morning = 24.0 # Sleep until next morning
	
	WorldManager.advance_time(hours_to_morning)
	
	# Restore health and stamina
	SurvivalManager.heal(20.0)
	SurvivalManager.restore_stamina(50.0)
	
	# Consume hunger/thirst
	SurvivalManager.eat(-10.0)
	SurvivalManager.drink(-15.0)
	
	UIManager.show_notification("Slept until morning. Health and stamina restored.", 3.0, "success")

func _toggle_generator() -> void:
	var on = WorldManager.toggle_generator()
	if on:
		UIManager.show_notification("Generator ON. Fuel: %.0f%%" % WorldManager.get_generator_fuel(), 2.0, "info")
	else:
		UIManager.show_notification("Generator OFF", 2.0, "info")

func _show_upgrades() -> void:
	# Would open upgrade UI
	UIManager.show_notification("Safehouse Upgrades: Coming Soon", 2.0, "info")

func _leave_safehouse() -> void:
	WorldManager.travel_to_level("abandoned_city")