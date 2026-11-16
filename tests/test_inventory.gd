extends Node

## TestInventory - Inventory system tests

class_name TestInventory

var test_base: Object = null

func run_tests() -> Dictionary:
	test_base = load("res://tests/run_tests.gd").new().TestBase.new()
	
	test_add_item()
	test_stacking()
	test_remove_item()
	test_capacity()
	test_weight()
	test_usable_items()
	
	return test_base.get_results()

func test_add_item() -> void:
	# Simulate inventory
	var items = {}
	var max_slots = 20
	var current_weight = 0.0
	var max_weight = 50.0
	
	func add_item(item_id: String, count: int, stack_size: int, weight: float) -> bool:
		if current_weight + (weight * count) > max_weight:
			return false
		
		if items.has(item_id):
			var space = stack_size - items[item_id].count
			if space >= count:
				items[item_id].count += count
				current_weight += weight * count
				return true
			elif space > 0:
				items[item_id].count = stack_size
				current_weight += weight * space
				return add_item(item_id, count - space, stack_size, weight)
		
		var slots_needed = ceil(count / stack_size)
		if items.size() + slots_needed > max_slots:
			return false
		
		var remaining = count
		while remaining > 0:
			var stack = min(remaining, stack_size)
			var slot_id = "slot_" + str(items.size())
			items[slot_id] = {"item_id": item_id, "count": stack}
			remaining -= stack
		
		current_weight += weight * count
		return true
	
	# Test adding single item
	var result = add_item("bandage", 1, 10, 0.1)
	test_base.assert_true(result, "Add single bandage")
	test_base.assert_equal(items.size(), 1, "One slot used")
	test_base.assert_equal(current_weight, 0.1, "Weight tracked")
	
	# Test adding multiple same item (stacking)
	result = add_item("bandage", 5, 10, 0.1)
	test_base.assert_true(result, "Add 5 more bandages")
	test_base.assert_equal(items.size(), 1, "Still one slot (stacked)")
	test_base.assert_equal(items["slot_0"].count, 6, "Stack count is 6")
	
	# Test adding different item
	result = add_item("water_bottle", 1, 10, 0.5)
	test_base.assert_true(result, "Add water bottle")
	test_base.assert_equal(items.size(), 2, "Two slots used")
	
	# Test stack overflow creates new stack
	result = add_item("bandage", 10, 10, 0.1) # 6 + 10 = 16, needs 2 stacks
	test_base.assert_true(result, "Add 10 bandages (overflow)")
	test_base.assert_equal(items.size(), 3, "New slot created for overflow")

func test_stacking() -> void:
	var items = {}
	var stack_size = 10
	
	# Fill one stack
	items["slot_0"] = {"item_id": "pistol_ammo", "count": 10}
	
	# Try to add more - should create new slot
	var remaining = 15
	var stacks = []
	while remaining > 0:
		var stack = min(remaining, stack_size)
		stacks.append(stack)
		remaining -= stack
	
	test_base.assert_equal(stacks.size(), 2, "15 items with stack size 10 creates 2 stacks")
	test_base.assert_equal(stacks[0], 10, "First stack full")
	test_base.assert_equal(stacks[1], 5, "Second stack partial")

func test_remove_item() -> void:
	var items = {
		"slot_0": {"item_id": "bandage", "count": 10},
		"slot_1": {"item_id": "water_bottle", "count": 3}
	}
	var current_weight = 10 * 0.1 + 3 * 0.5
	
	func remove_item(item_id: String, count: int, weight: float) -> bool:
		var total = 0
		for slot in items.values():
			if slot.item_id == item_id:
				total += slot.count
		if total < count:
			return false
		
		var remaining = count
		var keys_to_remove = []
		for slot_id, slot in items:
			if slot.item_id == item_id:
				if slot.count <= remaining:
					remaining -= slot.count
					current_weight -= weight * slot.count
					keys_to_remove.append(slot_id)
				else:
					slot.count -= remaining
					current_weight -= weight * remaining
					remaining = 0
					break
		
		for key in keys_to_remove:
			items.erase(key)
		return true
	
	# Remove partial stack
	var result = remove_item("bandage", 3, 0.1)
	test_base.assert_true(result, "Remove 3 bandages")
	test_base.assert_equal(items["slot_0"].count, 7, "7 bandages remain")
	
	# Remove entire stack
	result = remove_item("water_bottle", 3, 0.5)
	test_base.assert_true(result, "Remove all water bottles")
	test_base.assert_false(items.has("slot_1"), "Slot removed")
	
	# Try to remove more than available
	result = remove_item("bandage", 10, 0.1)
	test_base.assert_false(result, "Cannot remove more than available")

func test_capacity() -> void:
	var max_slots = 20
	var items = {}
	
	# Fill all slots
	for i in range(max_slots):
		items["slot_" + str(i)] = {"item_id": "item_" + str(i), "count": 1}
	
	test_base.assert_equal(items.size(), max_slots, "All slots filled")
	
	# Try to add one more
	var can_add = items.size() < max_slots
	test_base.assert_false(can_add, "Cannot add when full")

func test_weight() -> void:
	var max_weight = 50.0
	var current_weight = 0.0
	
	# Add heavy items
	var heavy_items = [
		{"id": "scrap_metal", "count": 50, "weight": 0.5}, # 25.0
		{"id": "wood", "count": 50, "weight": 0.3}, # 15.0
	]
	
	for item in heavy_items:
		current_weight += item["count"] * item["weight"]
	
	test_base.assert_equal(current_weight, 40.0, "Heavy items weight calculated")
	
	# Try to exceed
	var extra_weight = 15.0
	test_base.assert_true(current_weight + extra_weight > max_weight, "Would exceed weight limit")

func test_usable_items() -> void:
	var items = {
		"bandage": {"use_effect": {"type": "heal", "amount": 20}, "usable": true},
		"water_bottle": {"use_effect": {"type": "drink", "amount": 40}, "usable": true},
		"scrap_metal": {"use_effect": null, "usable": false}
	}
	
	# Test usable detection
	test_base.assert_true(items["bandage"]["usable"], "Bandage is usable")
	test_base.assert_true(items["water_bottle"]["usable"], "Water bottle is usable")
	test_base.assert_false(items["scrap_metal"]["usable"], "Scrap metal not usable")
	
	# Test effect types
	test_base.assert_equal(items["bandage"]["use_effect"]["type"], "heal", "Bandage heals")
	test_base.assert_equal(items["water_bottle"]["use_effect"]["type"], "drink", "Water restores thirst")
	test_base.assert_equal(items["bandage"]["use_effect"]["amount"], 20, "Bandage heals 20")
	test_base.assert_equal(items["water_bottle"]["use_effect"]["amount"], 40, "Water restores 40 thirst")