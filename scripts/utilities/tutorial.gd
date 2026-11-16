extends Node

class_name Tutorial

## Tutorial - In-game tutorial system

static var tutorial_steps: Array[Dictionary] = [
	{
		"id": "movement",
		"title": "Movement",
		"text": "Use the virtual joystick on the left to move. Tap A/D or Left/Right arrows on keyboard.",
		"trigger": "move",
		"completed": false
	},
	{
		"id": "jump",
		"title": "Jump",
		"text": "Tap the Jump button on the right to jump. Press W, Space, or Up Arrow on keyboard.",
		"trigger": "jump",
		"completed": false
	},
	{
		"id": "crouch",
		"title": "Crouch",
		"text": "Hold the Crouch button to crouch. Press S or Down Arrow on keyboard. Crouching reduces noise.",
		"trigger": "crouch",
		"completed": false
	},
	{
		"id": "aim_shoot",
		"title": "Aim & Shoot",
		"text": "Drag on the right side to aim. Tap the Fire button to shoot. Mouse aims, Left Click shoots on desktop.",
		"trigger": "shoot",
		"completed": false
	},
	{
		"id": "reload",
		"title": "Reload",
		"text": "Tap the Reload button when ammo is low. Press R on keyboard. Reloading takes time.",
		"trigger": "reload",
		"completed": false
	},
	{
		"id": "interact",
		"title": "Interact",
		"text": "Approach objects and press Interact (E). Open doors, loot containers, use workstations.",
		"trigger": "interact",
		"completed": false
	},
	{
		"id": "inventory",
		"title": "Inventory",
		"text": "Press the Inventory button (I) to manage items. Combine items, use consumables, equip weapons.",
		"trigger": "inventory",
		"completed": false
	},
	{
		"id": "crafting",
		"title": "Crafting",
		"text": "Open Crafting in the Inventory. Combine materials to create medicine, ammo, tools, and traps.",
		"trigger": "crafting",
		"completed": false
	},
	{
		"id": "survival",
		"title": "Survival",
		"text": "Monitor Hunger, Thirst, Stamina, and Infection. Eat, drink, rest, and use medicine to survive.",
		"trigger": "survival",
		"completed": false
	},
	{
		"id": "flashlight",
		"title": "Flashlight",
		"text": "Press Flashlight (F) at night. Battery drains over time. Find batteries to recharge.",
		"trigger": "flashlight",
		"completed": false
	},
	{
		"id": "stealth",
		"title": "Stealth",
		"text": "Crouch to move quietly. Zombies detect sound. Avoid running near them. Use distractions.",
		"trigger": "stealth",
		"completed": false
	},
	{
		"id": "safehouse",
		"title": "Safehouse",
		"text": "Your base of operations. Store items, sleep to pass time, craft, upgrade defenses, manage generator.",
		"trigger": "safehouse",
		"completed": false
	},
	{
		"id": "checkpoints",
		"title": "Checkpoints",
		"text": "Activate checkpoints to save progress. On death, you respawn at the last checkpoint.",
		"trigger": "checkpoint",
		"completed": false
	}
]

static func get_step(step_id: String) -> Dictionary:
	for step in tutorial_steps:
		if step["id"] == step_id:
			return step
	return {}

static func complete_step(step_id: String) -> void:
	for step in tutorial_steps:
		if step["id"] == step_id:
			step["completed"] = true
			break

static func is_completed(step_id: String) -> bool:
	var step = get_step(step_id)
	return step.get("completed", false)

static func get_next_incomplete() -> Dictionary:
	for step in tutorial_steps:
		if not step["completed"]:
			return step
	return {}

static func show_tutorial(step_id: String) -> void:
	var step = get_step(step_id)
	if step and not step["completed"]:
		UIManager.show_notification(step["title"] + "\n" + step["text"], 5.0, "info")
		complete_step(step_id)

static func check_trigger(trigger: String) -> void:
	for step in tutorial_steps:
		if step["trigger"] == trigger and not step["completed"]:
			show_tutorial(step["id"])
			break

static func get_progress() -> float:
	var completed = 0
	for step in tutorial_steps:
		if step["completed"]:
			completed += 1
	return completed / tutorial_steps.size()

static func reset() -> void:
	for step in tutorial_steps:
		step["completed"] = false