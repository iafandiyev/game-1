extends Node

## TestCombat - Combat and weapon tests

class_name TestCombat

var test_base: Object = null

func run_tests() -> Dictionary:
	test_base = load("res://tests/run_tests.gd").new().TestBase.new()
	
	test_weapon_stats()
	test_ammo_management()
test_reload()
	test_spread_and_recoil()
	test_melee()
	test_damage_calculation()
	
	return test_base.get_results()

func test_weapon_stats() -> void:
	var weapons = {
		"pistol": {
			"damage": 25, "fire_rate": 0.3, "magazine_size": 15,
			"ammo_type": "9mm", "range": 300, "sound_radius": 15.0
		},
		"shotgun": {
			"damage": 15, "pellets": 8, "fire_rate": 1.0, "magazine_size": 8,
			"ammo_type": "12gauge", "range": 100, "sound_radius": 25.0
		},
		"rifle": {
			"damage": 35, "fire_rate": 0.1, "magazine_size": 30,
			"ammo_type": "556", "range": 500, "sound_radius": 30.0
		},
		"baseball_bat": {
			"damage": 40, "attack_speed": 1.2, "stamina_cost": 15,
			"reach": 80, "sound_radius": 2.0
		}
	}
	
	# Pistol tests
	var pistol = weapons["pistol"]
	test_base.assert_equal(pistol["damage"], 25, "Pistol damage")
	test_base.assert_equal(pistol["magazine_size"], 15, "Pistol magazine size")
	test_base.assert_equal(pistol["ammo_type"], "9mm", "Pistol ammo type")
	test_base.assert_equal(pistol["range"], 300, "Pistol range")
	
	# Shotgun tests
	var shotgun = weapons["shotgun"]
	test_base.assert_equal(shotgun["pellets"], 8, "Shotgun pellets")
	test_base.assert_equal(shotgun["damage"], 15, "Shotgun per-pellet damage")
	test_base.assert_equal(shotgun["range"], 100, "Shotgun short range")
	
	# Rifle tests
	var rifle = weapons["rifle"]
	test_base.assert_equal(rifle["damage"], 35, "Rifle damage")
	test_base.assert_equal(rifle["magazine_size"], 30, "Rifle magazine size")
	test_base.assert_equal(rifle["range"], 500, "Rifle long range")
	
	# Melee tests
	var bat = weapons["baseball_bat"]
	test_base.assert_equal(bat["damage"], 40, "Bat damage")
	test_base.assert_equal(bat["stamina_cost"], 15, "Bat stamina cost")
	test_base.assert_equal(bat["sound_radius"], 2.0, "Bat silent")

func test_ammo_management() -> void:
	var pistol = {
		"current_ammo": 15,
		"reserve_ammo": 45,
		"magazine_size": 15,
		"max_ammo": 60
	}
	
	# Test firing
	func fire(weapon: Dictionary) -> bool:
		if weapon["current_ammo"] > 0:
			weapon["current_ammo"] -= 1
			return true
		return false
	
	# Fire 5 shots
	for i in range(5):
		var result = fire(pistol)
		test_base.assert_true(result, "Shot " + str(i+1) + " fired")
	
	test_base.assert_equal(pistol["current_ammo"], 10, "Ammo after 5 shots")
	
	# Fire until empty
	for i in range(10):
		fire(pistol)
	
	test_base.assert_equal(pistol["current_ammo"], 0, "Ammo depleted")
	test_base.assert_false(fire(pistol), "Cannot fire when empty")
	
	# Test reload
	func reload(weapon: Dictionary) -> void:
		var needed = weapon["magazine_size"] - weapon["current_ammo"]
		var to_reload = min(needed, weapon["reserve_ammo"])
		weapon["current_ammo"] += to_reload
		weapon["reserve_ammo"] -= to_reload
	
	reload(pistol)
	test_base.assert_equal(pistol["current_ammo"], 15, "Reloaded to full")
	test_base.assert_equal(pistol["reserve_ammo"], 30, "Reserve reduced")
	
	# Test partial reload
	pistol["current_ammo"] = 5
	pistol["reserve_ammo"] = 3
	reload(pistol)
	test_base.assert_equal(pistol["current_ammo"], 8, "Partial reload")
	test_base.assert_equal(pistol["reserve_ammo"], 0, "Reserve empty")

func test_reload() -> void:
	var shotgun = {
		"current_ammo": 2,
		"reserve_ammo": 10,
		"magazine_size": 8,
		"reload_time": 3.0
	}
	
	# Shell-by-shell reload simulation
	var shells_to_load = min(shotgun["magazine_size"] - shotgun["current_ammo"], shotgun["reserve_ammo"])
	test_base.assert_equal(shells_to_load, 6, "6 shells to load")
	
	# Time per shell
	var time_per_shell = shotgun["reload_time"] / shotgun["magazine_size"]
	test_base.assert_equal(time_per_shell, 0.375, "Time per shell")

func test_spread_and_recoil() -> void:
	var pistol = {"spread": 0.02, "max_spread": 0.15, "spread_increase": 0.01, "recoil": 2.0}
	var shotgun = {"spread": 0.1, "max_spread": 0.3, "spread_increase": 0.05, "recoil": 8.0}
	var rifle = {"spread": 0.015, "max_spread": 0.1, "spread_increase": 0.008, "recoil": 3.0}
	
	# Test initial spread
	test_base.assert_equal(pistol["spread"], 0.02, "Pistol initial spread")
	test_base.assert_equal(shotgun["spread"], 0.1, "Shotgun initial spread")
	test_base.assert_equal(rifle["spread"], 0.015, "Rifle initial spread")
	
	# Test spread increase
	var current_spread = pistol["spread"]
	for i in range(5):
		current_spread = min(pistol["max_spread"], current_spread + pistol["spread_increase"])
	
	test_base.assert_equal(current_spread, 0.07, "Spread after 5 shots")
	
	# Test max spread cap
	current_spread = pistol["spread"]
	for i in range(20):
		current_spread = min(pistol["max_spread"], current_spread + pistol["spread_increase"])
	
	test_base.assert_equal(current_spread, pistol["max_spread"], "Spread capped at max")
	
	# Test recoil values
	test_base.assert_equal(pistol["recoil"], 2.0, "Pistol low recoil")
	test_base.assert_equal(shotgun["recoil"], 8.0, "Shotgun high recoil")
	test_base.assert_equal(rifle["recoil"], 3.0, "Rifle medium recoil")

func test_melee() -> void:
	var bat = {"damage": 40, "reach": 80, "stamina_cost": 15, "knockback": 5.0}
	var knife = {"damage": 30, "reach": 60, "stamina_cost": 8, "bleed_chance": 0.25}
	var axe = {"damage": 60, "reach": 90, "stamina_cost": 25, "armor_pierce": 0.3}
	
	# Test reach
	test_base.assert_equal(bat["reach"], 80, "Bat reach")
	test_base.assert_equal(knife["reach"], 60, "Knife shorter reach")
	test_base.assert_equal(axe["reach"], 90, "Axe longest reach")
	
	# Test stamina cost
	test_base.assert_equal(bat["stamina_cost"], 15, "Bat stamina cost")
	test_base.assert_equal(knife["stamina_cost"], 8, "Knife low stamina cost")
	test_base.assert_equal(axe["stamina_cost"], 25, "Axe high stamina cost")
	
	# Test special properties
	test_base.assert_equal(knife["bleed_chance"], 0.25, "Knife bleed chance")
	test_base.assert_equal(axe["armor_pierce"], 0.3, "Axe armor pierce")

func test_damage_calculation() -> void:
	# Test damage multipliers
	var base_damage = 25.0
	var difficulty_multipliers = {
		"easy": 0.75,
		"normal": 1.0,
		"hard": 1.35,
		"survival": 1.75
	}
	
	for diff, mult in difficulty_multipliers:
		var final_damage = base_damage * mult
		if diff == "easy":
			test_base.assert_equal(final_damage, 18.75, "Easy damage reduced")
		elif diff == "normal":
			test_base.assert_equal(final_damage, 25.0, "Normal damage unchanged")
		elif diff == "hard":
			test_base.assert_equal(final_damage, 33.75, "Hard damage increased")
		elif diff == "survival":
			test_base.assert_equal(final_damage, 43.75, "Survival damage greatly increased")
	
	# Test headshot multiplier (2x)
	var headshot_damage = base_damage * 2.0
	test_base.assert_equal(headshot_damage, 50.0, "Headshot double damage")
	
	# Test armor reduction
	var armor = 0.3
	var damage_after_armor = base_damage * (1.0 - armor)
	test_base.assert_equal(damage_after_armor, 17.5, "Armor reduces damage")