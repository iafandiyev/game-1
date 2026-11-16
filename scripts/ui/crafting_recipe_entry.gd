extends HBoxContainer

## CraftingRecipeEntry - Single recipe entry in crafting list

signal selected(recipe_id: String)

@onready var name_label: Label = %Name
@onready var category_label: Label = %Category
@onready var icon: TextureRect = %Icon
@onready var can_craft_indicator: TextureRect = %CanCraftIndicator

var recipe_data: Dictionary = {}

func set_recipe(recipe: Dictionary) -> void:
	recipe_data = recipe
	name_label.text = recipe.get("name", "Unknown")
	category_label.text = recipe.get("category", "Unknown").capitalize()
	
	var result = recipe.get("result", {})
	var item_id = result.get("item_id", "")
	var db_item = ItemDatabase.get_item(item_id)
	
	var icon_path = db_item.get("icon", "")
	if icon_path != "" and ResourceLoader.exists(icon_path):
		icon.texture = load(icon_path)
	
	_update_craftable_status()

func _update_craftable_status() -> void:
	var can_craft = CraftingManager.can_craft(recipe_data.get("id", ""))
	can_craft_indicator.visible = can_craft
	if can_craft:
		can_craft_indicator.add_theme_color_override("modulate", Color(0.2, 0.8, 0.3, 1))
	else:
		can_craft_indicator.add_theme_color_override("modulate", Color(0.5, 0.5, 0.5, 1))

func refresh() -> void:
	_update_craftable_status()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		selected.emit(recipe_data.get("id", ""))