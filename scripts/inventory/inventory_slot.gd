extends Panel

## InventorySlot - Individual inventory slot display

@onready var icon: TextureRect = %Icon
@onready var count_label: Label = %CountLabel
@onready var rarity_border: StyleBoxFlat = %RarityBorder

var item_data: Dictionary = {}

func set_item(data: Dictionary) -> void:
	item_data = data
	
	var db_item = ItemDatabase.get_item(data["item_id"])
	var icon_path = db_item.get("icon", "")
	
	if icon_path != "" and ResourceLoader.exists(icon_path):
		icon.texture = load(icon_path)
	else:
		# Placeholder
		icon.texture = null
		icon.add_theme_stylebox_override("texture", _create_placeholder_stylebox())
	
	var count = data["count"]
	if count > 1:
		count_label.text = "x%d" % count
		count_label.visible = true
	else:
		count_label.visible = false
	
	# Set rarity border color
	var rarity = db_item.get("rarity", "common")
	var colors = {
		"common": Color(0.5, 0.5, 0.5, 1),
		"uncommon": Color(0.2, 0.8, 0.3, 1),
		"rare": Color(0.3, 0.6, 1.0, 1),
		"epic": Color(0.8, 0.3, 1.0, 1),
		"legendary": Color(1.0, 0.8, 0.1, 1),
		"unique": Color(1.0, 0.4, 0.1, 1)
	}
	
	var border_color = colors.get(rarity, colors["common"])
	rarity_border.border_color = border_color
	add_theme_stylebox_override("panel", rarity_border.duplicate())

func _create_placeholder_stylebox() -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.2, 0.2, 0.2, 1)
	style.border_width = 1
	style.border_color = Color(0.4, 0.4, 0.4, 1)
	style.corner_radius = 4
	return style

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		gui_input.emit(item_data, event)