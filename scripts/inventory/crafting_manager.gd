extends Node

class_name CraftingManager

## CraftingManager - Handles crafting recipes and validation

signal recipe_crafted(recipe_id: String)
signal crafting_failed(recipe_id: String, reason: String)
signal recipe_discovered(recipe_id: String)

@export var known_recipes: Array[String] = []

var recipe_database: Dictionary = {}

func _ready() -> void:
	_load_recipes()

func _load_recipes() -> void:
	var file = FileAccess.open("res://data/items/crafting_recipes.json", FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		file.close()
		var parse_result = JSON.parse_string(json_string)
		if parse_result.get("error") == OK:
			var recipes = parse_result.get("result").get("recipes", [])
			for recipe in recipes:
				recipe_database[recipe["id"]] = recipe
				# Auto-discover basic recipes
				if recipe.get("requirements", {}).get("level", 0) == 0:
					if recipe["id"] not in known_recipes:
						known_recipes.append(recipe["id"])

func get_recipe(recipe_id: String) -> Dictionary:
	return recipe_database.get(recipe_id, {})

func get_all_recipes() -> Array[Dictionary]:
	var result = []
	for recipe in recipe_database.values():
		result.append(recipe)
	return result

func get_known_recipes() -> Array[Dictionary]:
	var result = []
	for recipe_id in known_recipes:
		if recipe_database.has(recipe_id):
			result.append(recipe_database[recipe_id])
	return result

func get_recipes_by_category(category: String) -> Array[Dictionary]:
	var result = []
	for recipe in recipe_database.values():
		if recipe.get("category") == category:
			result.append(recipe)
	return result

func can_craft(recipe_id: String) -> bool:
	var recipe = get_recipe(recipe_id)
	if not recipe:
		return false
	
	# Check if recipe is known
	if recipe_id not in known_recipes:
		return false
	
	# Check requirements
	var requirements = recipe.get("requirements", {})
	var level_req = requirements.get("level", 0)
	# Would check player crafting level
	
	# Check workstation
	var workstation = requirements.get("workstation", "")
	if workstation != "":
		# Would check if player is near workstation
		pass
	
	# Check tools
	var tools = requirements.get("tools", [])
	for tool in tools:
		# Would check if player has tool
		pass
	
	# Check ingredients
	var ingredients = recipe.get("ingredients", [])
	for ingredient in ingredients:
		var item_id = ingredient.get("item_id")
		var count = ingredient.get("count", 1)
		if not Inventory.has_item(item_id, count):
			return false
	
	return true

func craft(recipe_id: String) -> bool:
	if not can_craft(recipe_id):
		crafting_failed.emit(recipe_id, "Requirements not met")
		return false
	
	var recipe = get_recipe(recipe_id)
	
	# Consume ingredients
	var ingredients = recipe.get("ingredients", [])
	for ingredient in ingredients:
		var item_id = ingredient.get("item_id")
		var count = ingredient.get("count", 1)
		Inventory.remove_item(item_id, count)
	
	# Produce result
	var result = recipe.get("result", {})
	var result_id = result.get("item_id")
	var result_count = result.get("count", 1)
	
	if not Inventory.add_item(result_id, result_count):
		# Rollback ingredients (simplified)
		crafting_failed.emit(recipe_id, "Inventory full")
		return false
	
	recipe_crafted.emit(recipe_id)
	return true

func discover_recipe(recipe_id: String) -> void:
	if recipe_database.has(recipe_id) and recipe_id not in known_recipes:
		known_recipes.append(recipe_id)
		recipe_discovered.emit(recipe_id)

func get_missing_ingredients(recipe_id: String) -> Array[Dictionary]:
	var recipe = get_recipe(recipe_id)
	if not recipe:
		return []
	
	var missing = []
	var ingredients = recipe.get("ingredients", [])
	for ingredient in ingredients:
		var item_id = ingredient.get("item_id")
		var required = ingredient.get("count", 1)
		var have = Inventory.get_item_count(item_id)
		if have < required:
			missing.append({
				"item_id": item_id,
				"required": required,
				"have": have,
				"missing": required - have
			})
	return missing

func get_craft_time(recipe_id: String) -> float:
	var recipe = get_recipe(recipe_id)
	return recipe.get("craft_time", 5.0)

func get_experience_reward(recipe_id: String) -> int:
	var recipe = get_recipe(recipe_id)
	return recipe.get("experience", 0)

func get_save_data() -> Dictionary:
	return {
		"known_recipes": known_recipes,
	}

func load_save_data(data: Dictionary) -> void:
	known_recipes = data.get("known_recipes", [])