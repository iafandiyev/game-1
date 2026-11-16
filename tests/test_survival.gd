extends Node

## TestSurvival - Survival mechanics tests

class_name TestSurvival

var test_base: Object = null

func run_tests() -> Dictionary:
	test_base = load("res://tests/run_tests.gd").new().TestBase.new()
	
	test_hunger_thirst()
	test_stamina()
	test_health_regen()
	test_infection()
	test_critical_conditions()
	test_consumables()
	
	return test_base.get_results()

func test_hunger_thirst() -> void:
	var max_hunger = 100.0
	var max_thirst = 100.0
	var hunger = 100.0
	var thirst = 100.0
	
	var hunger_rate = 0.003 # per second
	var thirst_rate = 0.006 # per second
	
	# Test 1 minute drain
	var delta = 60.0
	hunger -= hunger_rate * delta
	thirst -= thirst_rate * delta
	
	test_base.assert_equal(hunger, 82.0, "Hunger after 1 minute")
	test_base.assert_equal(thirst, 64.0, "Thirst after 1 minute")
	
	# Test 10 minutes
	hunger = 100.0
	thirst = 100.0
	delta = 600.0
	hunger -= hunger_rate * delta
	thirst -= thirst_rate * delta
	
	test_base.assert_equal(hunger, 82.0, "Hunger after 10 minutes")
	test_base.assert_equal(thirst, 64.0, "Thirst after 10 minutes")
	
	# Test critical thresholds
	hunger = 5.0
	thirst = 5.0
	var critical_hunger = hunger <= 10.0
	var critical_thirst = thirst <= 10.0
	test_base.assert_true(critical_hunger, "Critical hunger at 5")
	test_base.assert_true(critical_thirst, "Critical thirst at 5")
	
	# Test eating/drinking
	hunger = 20.0
	thirst = 30.0
	hunger = min(max_hunger, hunger + 35.0) # canned food
	thirst = min(max_thirst, thirst + 40.0) # water bottle
	
	test_base.assert_equal(hunger, 55.0, "Hunger after canned food")
	test_base.assert_equal(thirst, 70.0, "Thirst after water bottle")
	
	# Test cap at max
	hunger = 90.0
	hunger = min(max_hunger, hunger + 35.0)
	test_base.assert_equal(hunger, 100.0, "Hunger capped at max")

func test_stamina() -> void:
	var max_stamina = 100.0
	var stamina = 100.0
	var drain_rate = 25.0
	var regen_rate = 15.0
	
	# Test running drain
	var delta = 1.0
	stamina = max(0.0, stamina - drain_rate * delta)
	test_base.assert_equal(stamina, 75.0, "Stamina after 1s running")
	
	# Test regen while resting
	stamina = 50.0
	stamina = min(max_stamina, stamina + regen_rate * delta)
	test_base.assert_equal(stamina, 65.0, "Stamina regen while resting")
	
	# Test hunger/thirst affect regen
	var hunger = 30.0 # 30%
	var thirst = 40.0 # 40%
	var hunger_factor = hunger / 100.0
	var thirst_factor = thirst / 100.0
	var effective_regen = regen_rate * (hunger_factor + thirst_factor) / 2.0
	
	test_base.assert_equal(effective_regen, 5.25, "Reduced regen when hungry/thirsty")
	
	# Test cannot sprint when low
	var can_sprint = stamina > 10.0 and hunger > 10.0 and thirst > 10.0
	stamina = 5.0
	can_sprint = stamina > 10.0 and hunger > 10.0 and thirst > 10.0
	test_base.assert_false(can_sprint, "Cannot sprint with low stamina")
	
	hunger = 5.0
	can_sprint = stamina > 10.0 and hunger > 10.0 and thirst > 10.0
	test_base.assert_false(can_sprint, "Cannot sprint when hungry")
	
	thirst = 5.0
	can_sprint = stamina > 10.0 and hunger > 10.0 and thirst > 10.0
	test_base.assert_false(can_sprint, "Cannot sprint when thirsty")

func test_health_regen() -> void:
	var max_health = 100.0
	var health = 50.0
	var regen_rate = 0.5
	var last_damage_time = 0.0
	var current_time = 15.0 # 15 seconds since damage
	
	# Test no regen within 10 seconds of damage
	last_damage_time = 5.0
	var can_regen = current_time - last_damage_time >= 10.0
	test_base.assert_false(can_regen, "No regen within 10s of damage")
	
	# Test regen after 10 seconds
	last_damage_time = 0.0
	can_regen = current_time - last_damage_time >= 10.0
	test_base.assert_true(can_regen, "Regen after 10s")
	
	# Test regen requires hunger/thirst > 50%
	var hunger = 60.0
	var thirst = 60.0
	var hunger_ok = hunger > 50.0
	var thirst_ok = thirst > 50.0
	test_base.assert_true(hunger_ok and thirst_ok, "Regen when well fed/hydrated")
	
	hunger = 30.0
	hunger_ok = hunger > 50.0
	test_base.assert_false(hunger_ok and thirst_ok, "No regen when hungry")
	
	# Test regen amount
	health = 50.0
	var regen_amount = regen_rate * (hunger/100.0) * (thirst/100.0)
	health = min(max_health, health + regen_amount)
	# With hunger=30, thirst=60: 0.5 * 0.3 * 0.6 = 0.09
	
	hunger = 80.0
	thirst = 90.0
	regen_amount = regen_rate * (hunger/100.0) * (thirst/100.0)
	# 0.5 * 0.8 * 0.9 = 0.36
	test_base.assert_true(regen_amount > 0.3, "Higher regen when well fed")

func test_infection() -> void:
	var infection = 0.0
	var max_infection = 100.0
	
	# Test infection stages
	var stages = [
		{"threshold": 0, "name": "Healthy"},
		{"threshold": 25, "name": "Exposed"},
		{"threshold": 50, "name": "Infected"},
		{"threshold": 75, "name": "Severe"},
		{"threshold": 100, "name": "Critical"}
	]
	
	func get_stage(inf: float) -> int:
		for i in range(stages.size() - 1, -1, -1):
			if inf >= stages[i]["threshold"]:
				return i
		return 0
	
	test_base.assert_equal(get_stage(0), 0, "Stage 0: Healthy")
	test_base.assert_equal(get_stage(10), 0, "Stage 0: Low exposure")
	test_base.assert_equal(get_stage(25), 1, "Stage 1: Exposed")
	test_base.assert_equal(get_stage(50), 2, "Stage 2: Infected")
	test_base.assert_equal(get_stage(75), 3, "Stage 3: Severe")
	test_base.assert_equal(get_stage(90), 3, "Stage 3: High severe")
	test_base.assert_equal(get_stage(100), 4, "Stage 4: Critical")
	
	# Test infection from zombie attacks
	var bite_chance = 0.3
	var scratch_chance = 0.1
	var bite_infection = 10.0
	var scratch_infection = 5.0
	
	# Simulate multiple attacks
	infection = 0.0
	for i in range(10):
		if randf() < bite_chance:
			infection += bite_infection
	
	# Test infection cure
	infection = 60.0
	infection = max(0.0, infection - 40.0) # antibiotics
	test_base.assert_equal(infection, 20.0, "Antibiotics cure 40 infection")
	
	# Test passive infection increase
	infection = 0.0
	var passive_rate = 0.001 # per second
	infection += passive_rate * 3600 # 1 hour
	test_base.assert_equal(infection, 3.6, "Passive infection over 1 hour")

func test_critical_conditions() -> void:
	var health = 100.0
	var max_health = 100.0
	var hunger = 100.0
	var max_hunger = 100.0
	var thirst = 100.0
	var max_thirst = 100.0
	var infection_stage = 0
	
	func is_critical() -> bool:
		return (health / max_health <= 0.25) or \
			   (hunger / max_hunger <= 0.1) or \
			   (thirst / max_thirst <= 0.1) or \
			   (infection_stage >= 3)
	
	# Test healthy
	test_base.assert_false(is_critical(), "Not critical when healthy")
	
	# Test low health
	health = 20.0
	test_base.assert_true(is_critical(), "Critical at 20% health")
	
	health = 100.0
	hunger = 5.0
	test_base.assert_true(is_critical(), "Critical at 5% hunger")
	
	hunger = 100.0
	thirst = 5.0
	test_base.assert_true(is_critical(), "Critical at 5% thirst")
	
	hunger = 100.0
	thirst = 100.0
	infection_stage = 3
	test_base.assert_true(is_critical(), "Critical at severe infection")
	
	infection_stage = 4
	test_base.assert_true(is_critical(), "Critical at critical infection")

func test_consumables() -> void:
	var items = {
		"bandage": {"heal": 20},
		"medkit": {"heal": 60, "cure_infection": 30},
		"antibiotics": {"cure_infection": 40},
		"painkillers": {"heal": 15, "stamina": 30},
		"water_bottle": {"drink": 40},
		"canned_food": {"eat": 35},
		"energy_bar": {"eat": 25, "stamina": 15},
		"cooked_meat": {"eat": 50}
	}
	
	# Test healing items
	var health = 40.0
	health = min(100.0, health + items["bandage"]["heal"])
	test_base.assert_equal(health, 60.0, "Bandage heals 20")
	
	health = 30.0
	health = min(100.0, health + items["medkit"]["heal"])
	test_base.assert_equal(health, 90.0, "Medkit heals 60")
	
	# Test medkit also cures infection
	var infection = 60.0
	infection = max(0.0, infection - items["medkit"]["cure_infection"])
	test_base.assert_equal(infection, 30.0, "Medkit cures 30 infection")
	
	# Test food/water
	var hunger = 30.0
	hunger = min(100.0, hunger + items["canned_food"]["eat"])
	test_base.assert_equal(hunger, 65.0, "Canned food restores 35 hunger")
	
	var thirst = 20.0
	thirst = min(100.0, thirst + items["water_bottle"]["drink"])
	test_base.assert_equal(thirst, 60.0, "Water restores 40 thirst")
	
	# Test energy bar dual effect
	hunger = 50.0
	var stamina = 50.0
	hunger = min(100.0, hunger + items["energy_bar"]["eat"])
	stamina = min(100.0, stamina + items["energy_bar"]["stamina"])
	test_base.assert_equal(hunger, 75.0, "Energy bar restores hunger")
	test_base.assert_equal(stamina, 65.0, "Energy bar restores stamina")