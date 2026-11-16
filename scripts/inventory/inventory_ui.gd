extends Control

## InventoryUI - Inventory management interface

@onready var capacity_label: Label = %CapacityLabel
@onready var weight_label: Label = %WeightLabel
@onready var all_grid: GridContainer = %AllGrid
@onready var weapons_grid: GridContainer = %WeaponsGrid
@onready var ammo_grid: GridContainer = %AmmoGrid
@onready var food_grid: GridContainer = %FoodGrid
@onready var medicine_grid: GridContainer = %MedicineGrid
@onready var materials_grid: GridContainer = %MaterialsGrid
@onready var tools_grid: GridContainer = %ToolsGrid
@onready var quest_grid: GridContainer = %QuestGrid
@onready var item_details: Panel = %ItemDetails
@onready var detail_name: Label = %DetailName
@onready var detail_description: Label = %DetailDescription
@onready var detail_weight: Label = %DetailWeight
@onready var detail_value: Label = %DetailValue
@onready var detail_rarity: Label = %DetailRarity
@onready var use_button: Button = %UseButton
@onready var drop_button: Button = %DropButton
@onready var close_button: Button = %CloseButton

var selected_item_id: String = ""
var selected_slot_id: String = ""
var slot_scenes: Dictionary = {}

func _ready() -> void:
	_connect_signals()
	_refresh_inventory()

func _connect_signals() -> void:
	Inventory.item_added.connect(_on_inventory_changed)
	Inventory.item_removed.connect(_on_inventory_changed)
	Inventory.capacity_changed.connect(_on_capacity_changed)
	use_button.pressed.connect(_on_use_pressed)
	drop_button.pressed.connect(_on_drop_pressed)
	close_button.pressed.connect(_on_close_pressed)
	InputManager.inventory_pressed.connect(_on_inventory_toggled)

func _on_inventory_toggled() -> void:
	if visible:
		UIManager.hide_inventory()
	else:
		UIManager.show_inventory()

func _refresh_inventory() -> void:
	_clear_grids()
	_populate_grids()
	_update_stats()

func _clear_grids() -> void:
	for grid in [all_grid, weapons_grid, ammo_grid, food_grid, medicine_grid, materials_grid, tools_grid, quest_grid]:
		for child in grid.get_children():
			child.queue_free()
	slot_scenes.clear()

func _populate_grids() -> void:
	var items = Inventory.get_all_items()
	var category_grids = {
		"all": all_grid,
		"weapons": weapons_grid,
		"ammunition": ammo_grid,
		"food": food_grid,
		"water": food_grid,
		"medicine": medicine_grid,
		"materials": materials_grid,
		"tools": tools_grid,
		"equipment": tools_grid,
		"weapons": tools_grid,
		"quest": quest_grid
	}
	
	for item_data in items:
		var item_id = item_data["item_id"]
		var db_item = ItemDatabase.get_item(item_id)
		var category = db_item.get("category", "all")
		
		# Add to All grid
		_create_slot(all_grid, item_data)
		
		# Add to category grid
		if category_grids.has(category):
			_create_slot(category_grids[category], item_data)

func _create_slot(grid: GridContainer, item_data: Dictionary) -> void:
	var slot_scene = preload("res://scenes/inventory/inventory_slot.tscn")
	var slot = slot_scene.instantiate()
	slot.set_item(item_data)
	slot.gui_input.connect(_on_slot_input.bind(item_data))
	grid.add_child(slot)
	slot_scenes[item_data["slot_id"]] = slot

func _on_slot_input(item_data: Dictionary, event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_select_item(item_data)

func _select_item(item_data: Dictionary) -> void:
	selected_item_id = item_data["item_id"]
	selected_slot_id = item_data["slot_id"]
	
	var db_item = ItemDatabase.get_item(selected_item_id)
	detail_name.text = db_item.get("name", selected_item_id)
	detail_description.text = db_item.get("description", "")
	detail_weight.text = "Weight: %.1f kg" % db_item.get("weight", 0.0)
	detail_value.text = "Value: %d" % db_item.get("value", 0)
	detail_rarity.text = "Rarity: %s" % db_item.get("rarity", "common").capitalize()
	
	var usable = db_item.get("usable", false)
	use_button.disabled = not usable
	use_button.text = "USE" if usable else "CANNOT USE"
	drop_button.disabled = false
	
	item_details.visible = true

func _on_use_pressed() -> void:
	if selected_item_id != "":
		Inventory.use_item(selected_item_id)
		_refresh_inventory()
		item_details.visible = false

func _on_drop_pressed() -> void:
	if selected_slot_id != "":
		Inventory.remove_item(selected_item_id, 1)
		_refresh_inventory()
		item_details.visible = false

func _on_close_pressed() -> void:
	UIManager.hide_inventory()

func _on_inventory_changed(item_id: String, count: int) -> void:
	_refresh_inventory()

func _on_capacity_changed(capacity: int) -> void:
	_update_stats()

func _update_stats() -> void:
	var used = Inventory.get_used_slots()
	var max_slots = Inventory.get_capacity()
	var weight = Inventory.get_total_weight()
	var max_weight = 50.0
	
	capacity_label.text = "%d / %d" % [used, max_slots]
	weight_label.text = "%.1f / %.1f kg" % [weight, max_weight]
	
	# Color coding
	if used >= max_slots:
		capacity_label.add_theme_color_override("font_color", Color(1, 0.3, 0.3, 1))
	else:
		capacity_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1))
	
	if weight >= max_weight * 0.9:
		weight_label.add_theme_color_override("font_color", Color(1, 0.3, 0.3, 1))
	elif weight >= max_weight * 0.7:
		weight_label.add_theme_color_override("font_color", Color(1, 0.8, 0.2, 1))
	else:
		weight_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1))