extends Node

class_name Inventory

## Inventory - Item storage and management system

signal item_added(item_id: String, count: int)
signal item_removed(item_id: String, count: int)
signal item_used(item_id: String)
signal inventory_full()
signal capacity_changed(capacity: int)

@export var max_slots: int = 20
@export var max_weight: float = 50.0

var items: Dictionary = {} # item_id -> {count, data}
var current_weight: float = 0.0

func _ready() -> void:
	_load_item_database()

func _load_item_database() -> void:
	var file = FileAccess.open("res://data/items/items.json", FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		file.close()
		var parse_result = JSON.parse_string(json_string)
		if parse_result.get("error") == OK:
			ItemDatabase.items = parse_result.get("result").get("items", [])

func add_item(item_id: String, count: int = 1) -> bool:
	var item_data = ItemDatabase.get_item(item_id)
	if not item_data:
		push_error("Item not found in database: " + item_id)
		return false
	
	var stack_size = item_data.get("stack_size", 1)
	var weight = item_data.get("weight", 0.0)
	
	# Check weight capacity
	if current_weight + (weight * count) > max_weight:
		inventory_full.emit()
		return false
	
	# Check if item already exists and can stack
	if items.has(item_id):
		var existing = items[item_id]
		var space_in_stack = stack_size - existing.count
		
		if space_in_stack >= count:
			existing.count += count
			items[item_id] = existing
			current_weight += weight * count
			item_added.emit(item_id, count)
			return true
		elif space_in_stack > 0:
			existing.count = stack_size
			items[item_id] = existing
			current_weight += weight * space_in_stack
			item_added.emit(item_id, space_in_stack)
			# Try to add remaining
			return add_item(item_id, count - space_in_stack)
	
	# Need new slot
	if get_used_slots() >= max_slots:
		inventory_full.emit()
		return false
	
	var stacks_needed = ceil(count / stack_size)
	if get_used_slots() + stacks_needed > max_slots:
		inventory_full.emit()
		return false
	
	# Add new stacks
	var remaining = count
	while remaining > 0:
		var stack_count = min(remaining, stack_size)
		var slot_id = _get_next_slot_id()
		items[slot_id] = {
			"item_id": item_id,
			"count": stack_count,
			"data": item_data.duplicate(true)
		}
		remaining -= stack_count
	
	current_weight += weight * count
	item_added.emit(item_id, count)
	return true

func remove_item(item_id: String, count: int = 1) -> bool:
	var total_count = get_item_count(item_id)
	if total_count < count:
		return false
	
	var remaining = count
	var keys_to_remove = []
	
	for slot_id, stack in items:
		if stack["item_id"] == item_id:
			var item_data = ItemDatabase.get_item(item_id)
			var weight = item_data.get("weight", 0.0)
			
			if stack["count"] <= remaining:
				remaining -= stack["count"]
				current_weight -= weight * stack["count"]
				keys_to_remove.append(slot_id)
			else:
				stack["count"] -= remaining
				current_weight -= weight * remaining
				items[slot_id] = stack
				remaining = 0
				break
	
	for key in keys_to_remove:
		items.erase(key)
	
	item_removed.emit(item_id, count)
	return true

func use_item(item_id: String) -> bool:
	var item_data = ItemDatabase.get_item(item_id)
	if not item_data:
		return false
	
	if not item_data.get("usable", false):
		return false
	
	if get_item_count(item_id) <= 0:
		return false
	
	# Apply use effects
	var use_effect = item_data.get("use_effect")
	if use_effect:
		_apply_effect(use_effect)
	
	var secondary_effect = item_data.get("secondary_effect")
	if secondary_effect:
		_apply_effect(secondary_effect)
	
	# Check for negative effects
	var negative_effect = item_data.get("negative_effect")
	if negative_effect:
		_apply_effect(negative_effect)
	
	remove_item(item_id, 1)
	item_used.emit(item_id)
	return true

func _apply_effect(effect: Dictionary) -> void:
	var effect_type = effect.get("type")
	var amount = effect.get("amount", 0)
	
	match effect_type:
		"heal":
			SurvivalManager.heal(amount)
		"cure_infection":
			SurvivalManager.cure_infection(amount)
		"eat":
			SurvivalManager.eat(amount)
		"drink":
			SurvivalManager.drink(amount)
		"restore_stamina":
			SurvivalManager.restore_stamina(amount)
		"add_infection":
			SurvivalManager.add_infection(amount)
		"unlock":
			# Would trigger unlock logic
			pass
		"repair":
			# Would trigger repair logic
			pass
		"throw_molotov":
			# Would spawn molotov
			pass
		"place_trap":
			# Would place trap
			pass
		"distract":
			# Would create noise distraction
			pass
		"increase_capacity":
			max_slots += amount
			capacity_changed.emit(max_slots)
		_:
			push_warning("Unknown effect type: " + effect_type)

func get_item_count(item_id: String) -> int:
	var count = 0
	for stack in items.values():
		if stack["item_id"] == item_id:
			count += stack["count"]
	return count

func get_item_stack(item_id: String) -> Dictionary:
	for slot_id, stack in items:
		if stack["item_id"] == item_id:
			return {"slot_id": slot_id, "stack": stack}
	return {}

func get_used_slots() -> int:
	return items.size()

func get_free_slots() -> int:
	return max_slots - get_used_slots()

func get_total_weight() -> float:
	return current_weight

func get_capacity() -> int:
	return max_slots

func has_item(item_id: String, count: int = 1) -> bool:
	return get_item_count(item_id) >= count

func get_all_items() -> Array[Dictionary]:
	var result = []
	for slot_id, stack in items:
		result.append({
			"slot_id": slot_id,
			"item_id": stack["item_id"],
			"count": stack["count"],
			"data": stack["data"]
		})
	return result

func _get_next_slot_id() -> String:
	var index = 0
	while items.has("slot_" + str(index)):
		index += 1
	return "slot_" + str(index)

func clear() -> void:
	items.clear()
	current_weight = 0.0

func get_save_data() -> Dictionary:
	var save_items = {}
	for slot_id, stack in items:
		save_items[slot_id] = {
			"item_id": stack["item_id"],
			"count": stack["count"]
		}
	return {
		"items": save_items,
		"max_slots": max_slots,
		"max_weight": max_weight,
		"current_weight": current_weight,
	}

func load_save_data(data: Dictionary) -> void:
	items.clear()
	current_weight = 0.0
	max_slots = data.get("max_slots", max_slots)
	max_weight = data.get("max_weight", max_weight)
	
	for slot_id, stack_data in data.get("items", {}):
		var item_data = ItemDatabase.get_item(stack_data["item_id"])
		if item_data:
			items[slot_id] = {
				"item_id": stack_data["item_id"],
				"count": stack_data["count"],
				"data": item_data.duplicate(true)
			}
			current_weight += item_data.get("weight", 0.0) * stack_data["count"]