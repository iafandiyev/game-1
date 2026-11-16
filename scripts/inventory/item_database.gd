extends Node

class_name ItemDatabase

## ItemDatabase - Static database of all game items

static var items: Array[Dictionary] = []
static var items_by_id: Dictionary = {}

static func initialize() -> void:
	var file = FileAccess.open("res://data/items/items.json", FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		file.close()
		var parse_result = JSON.parse_string(json_string)
		if parse_result.get("error") == OK:
			items = parse_result.get("result").get("items", [])
			_build_lookup()

static func _build_lookup() -> void:
	items_by_id.clear()
	for item in items:
		items_by_id[item["id"]] = item

static func get_item(item_id: String) -> Dictionary:
	if items_by_id.is_empty():
		initialize()
	return items_by_id.get(item_id, {})

static func get_items_by_category(category: String) -> Array[Dictionary]:
	if items_by_id.is_empty():
		initialize()
	
	var result = []
	for item in items:
		if item.get("category") == category:
			result.append(item)
	return result

static func get_all_items() -> Array[Dictionary]:
	if items_by_id.is_empty():
		initialize()
	return items.duplicate()

static func item_exists(item_id: String) -> bool:
	if items_by_id.is_empty():
		initialize()
	return items_by_id.has(item_id)

static func get_item_name(item_id: String) -> String:
	var item = get_item(item_id)
	return item.get("name", item_id)

static func get_item_description(item_id: String) -> String:
	var item = get_item(item_id)
	return item.get("description", "")

static func get_item_icon(item_id: String) -> String:
	var item = get_item(item_id)
	return item.get("icon", "")

static func get_item_rarity(item_id: String) -> String:
	var item = get_item(item_id)
	return item.get("rarity", "common")

static func get_item_stack_size(item_id: String) -> int:
	var item = get_item(item_id)
	return item.get("stack_size", 1)

static func get_item_weight(item_id: String) -> float:
	var item = get_item(item_id)
	return item.get("weight", 0.0)

static func get_item_value(item_id: String) -> int:
	var item = get_item(item_id)
	return item.get("value", 0)

static func is_item_usable(item_id: String) -> bool:
	var item = get_item(item_id)
	return item.get("usable", false)

static func is_item_craftable(item_id: String) -> bool:
	var item = get_item(item_id)
	return item.get("craftable", false)

static func get_item_crafting_recipe(item_id: String) -> String:
	var item = get_item(item_id)
	return item.get("crafting_recipe", "")

static func get_item_use_effect(item_id: String) -> Dictionary:
	var item = get_item(item_id)
	return item.get("use_effect", {})

static func get_item_category(item_id: String) -> String:
	var item = get_item(item_id)
	return item.get("category", "")