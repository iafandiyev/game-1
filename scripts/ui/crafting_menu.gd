extends Control

## CraftingMenu - Crafting interface

@onready var craft_button: Button = %CraftButton

var selected_recipe_id: String = ""
var recipe_entries: Dictionary = {}

func _ready() -> void:
	_connect_signals()
	_populate_recipes()

func _connect_signals() -> void:
	CraftingManager.recipe_crafted.connect(_on_recipe_crafted)
	CraftingManager.recipe_discovered.connect(_on_recipe_discovered)
	craft_button.pressed.connect(_on_craft_pressed)

func _populate_recipes() -> void:
	var recipes = CraftingManager.get_known_recipes()
	var category_lists = {
		"medicine": %MedicineList,
		"weapons": %WeaponsList,
		"tools": %ToolsList,
		"construction": %ConstructionList,
		"ammunition": %AmmunitionList,
		"food": %FoodList
	}
	
	# Add to All list
	var all_list = %AllRecipesList
	
	for recipe in recipes:
		_create_recipe_entry(all_list, recipe)
		
		var category = recipe.get("category", "tools")
		if category_lists.has(category):
			_create_recipe_entry(category_lists[category], recipe)

func _create_recipe_entry(parent: VBoxContainer, recipe: Dictionary) -> void:
	var entry_scene = preload("res://scenes/ui/crafting_recipe_entry.tscn")
	var entry = entry_scene.instantiate()
	entry.set_recipe(recipe)
	entry.selected.connect(_on_recipe_selected.bind(recipe["id"]))
	parent.add_child(entry)
	recipe_entries[recipe["id"]] = entry

func _on_recipe_selected(recipe_id: String) -> void:
	selected_recipe_id = recipe_id
	var recipe = CraftingManager.get_recipe(recipe_id)
	
	if not recipe:
		return
	
	%RecipeName.text = recipe.get("name", recipe_id)
	%RecipeDescription.text = recipe.get("description", "")
	
	# Show ingredients
	var ingredients_list = %IngredientsList
	for child in ingredients_list.get_children():
		child.queue_free()
	
	for ingredient in recipe.get("ingredients", []):
		var item_id = ingredient.get("item_id")
		var count = ingredient.get("count", 1)
		var db_item = ItemDatabase.get_item(item_id)
		var have = Inventory.get_item_count(item_id)
		
		var label = Label.new()
		var color = Color(1, 1, 1, 1) if have >= count else Color(1, 0.3, 0.3, 1)
		label.add_theme_color_override("font_color", color)
		label.text = "%s x%d (%d/%d)" % [db_item.get("name", item_id), count, have, count]
		ingredients_list.add_child(label)
	
	# Show requirements
	var req_list = %RequirementsList
	for child in req_list.get_children():
		child.queue_free()
	
	var requirements = recipe.get("requirements", {})
	var level = requirements.get("level", 0)
	if level > 0:
		var label = Label.new()
		label.text = "Crafting Level: %d" % level
		req_list.add_child(label)
	
	var workstation = requirements.get("workstation", "")
	if workstation != "":
		var label = Label.new()
		label.text = "Requires: %s" % workstation.replace("_", " ").capitalize()
		req_list.add_child(label)
	
	var tools = requirements.get("tools", [])
	for tool in tools:
		var label = Label.new()
		label.text = "Tool: %s" % tool
		req_list.add_child(label)
	
	# Enable/disable craft button
	var can_craft = CraftingManager.can_craft(recipe_id)
	craft_button.disabled = not can_craft
	craft_button.text = "CRAFT" if can_craft else "MISSING REQUIREMENTS"
	
	%RecipeDetails.visible = true

func _on_craft_pressed() -> void:
	if selected_recipe_id != "":
		CraftingManager.craft(selected_recipe_id)

func _on_recipe_crafted(recipe_id: String) -> void:
	_refresh_all_entries()

func _on_recipe_discovered(recipe_id: String) -> void:
	_populate_recipes()

func _refresh_all_entries() -> void:
	for entry in recipe_entries.values():
		if entry.has_method("refresh"):
			entry.refresh()