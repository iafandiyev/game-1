extends Control

## SafehouseUI - Safehouse status display

@onready var generator_label: Label = %GeneratorLabel
@onready var fuel_bar: ProgressBar = %FuelBar
@onready var upgrade_list: VBoxContainer = %UpgradeList

func _ready() -> void:
	_update_display()
	WorldManager.generator_fuel_changed.connect(_on_fuel_changed)
	WorldManager.safehouse_upgraded.connect(_on_upgrade_changed)

func _update_display() -> void:
	var on = WorldManager.is_generator_on()
	generator_label.text = "GEN: %s" % ["OFF", "ON"][int(on)]
	fuel_bar.value = WorldManager.get_generator_fuel()
	
	_update_upgrades()

func _on_fuel_changed(fuel: float) -> void:
	fuel_bar.value = fuel

func _on_upgrade_changed(upgrade_id: String) -> void:
	_update_upgrades()

func _update_upgrades() -> void:
	for child in upgrade_list.get_children():
		child.queue_free()
	
	var upgrades = WorldManager.get_all_upgrades()
	for upgrade_id, data in upgrades:
		if data["level"] > 0:
			var label = Label.new()
			label.text = "%s (Lv.%d)" % [upgrade_id.replace("_", " ").capitalize(), data["level"]]
			label.add_theme_font_size_override("font_size", 12)
			label.add_theme_color_override("font_color", Color(0.2, 0.8, 0.3, 1))
			upgrade_list.add_child(label)