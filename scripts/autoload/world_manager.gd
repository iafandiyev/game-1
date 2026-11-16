extends Node

class_name WorldManager

## WorldManager - Manages world state, day/night cycle, weather, and level transitions

signal time_changed(hour: float)
signal day_changed(day: int)
signal weather_changed(weather: String)
signal level_transition(from_level: String, to_level: String)
signal safehouse_upgraded(upgrade_id: String)
signal generator_fuel_changed(fuel: float)

@export_group("Time Settings")
@export var day_length_seconds: float = 1200.0 # 20 minutes per day
@export var night_start_hour: float = 20.0
@export var night_end_hour: float = 6.0
@export var time_scale: float = 1.0

@export_group("Weather")
@export var weather_types: Array[String] = ["clear", "rain", "fog", "storm", "windy"]
@export var weather_change_chance: float = 0.001 # Per second
@export var weather_duration_min: float = 300.0 # 5 minutes
@export var weather_duration_max: float = 1200.0 # 20 minutes

var current_time: float = 8.0 # 0-24 hours
var current_day: int = 1
var current_weather: String = "clear"
var weather_timer: float = 0.0
var next_weather_change: float = 0.0
var is_paused: bool = false

# Level connections (for world map)
var level_connections: Dictionary = {
	"abandoned_city": ["hospital", "supermarket"],
	"hospital": ["abandoned_city", "metro"],
	"supermarket": ["abandoned_city", "military_base"],
	"metro": ["hospital", "military_base"],
	"military_base": ["supermarket", "metro"],
	"safehouse": ["abandoned_city"],
}

# Safehouse upgrades
var safehouse_upgrades: Dictionary = {
	"storage_expansion": {"level": 0, "max_level": 3, "cost": [100, 200, 400], "effect": "Increases storage capacity"},
	"generator": {"level": 0, "max_level": 2, "cost": [150, 300], "effect": "Provides power for crafting and lights"},
	"water_purifier": {"level": 0, "max_level": 2, "cost": [200, 400], "effect": "Produces clean water over time"},
	"medical_station": {"level": 0, "max_level": 2, "cost": [250, 500], "effect": "Allows crafting advanced medicine"},
	"workshop": {"level": 0, "max_level": 3, "cost": [150, 300, 600], "effect": "Unlocks advanced crafting recipes"},
	"barricades": {"level": 0, "max_level": 3, "cost": [100, 250, 500], "effect": "Increases safehouse defense"},
	"garden": {"level": 0, "max_level": 2, "cost": [300, 600], "effect": "Produces food over time"},
	"radio": {"level": 0, "max_level": 1, "cost": [400], "effect": "Receives survivor broadcasts"},
}

var generator_fuel: float = 100.0
var max_generator_fuel: float = 100.0
var fuel_consumption_rate: float = 0.5 # Per minute when generator is on
var generator_on: bool = false

func _ready() -> void:
	_process_mode = Node.PROCESS_MODE_ALWAYS
	_load_world_state()
	_calculate_next_weather_change()

func _load_world_state() -> void:
	current_time = GameManager.world_state.get("time_of_day", 8.0)
	current_day = GameManager.world_state.get("day_count", 1)
	current_weather = GameManager.world_state.get("weather", "clear")
	
	# Load safehouse upgrades
	var saved_upgrades = GameManager.world_state.get("safehouse_upgrades", [])
	for upgrade_id in saved_upgrades:
		if safehouse_upgrades.has(upgrade_id):
			safehouse_upgrades[upgrade_id]["level"] = 1
	
	generator_fuel = GameManager.world_state.get("generator_fuel", 100.0)

func _process(delta: float) -> void:
	if is_paused:
		return
	
	_update_time(delta)
	_update_weather(delta)
	_update_generator(delta)

func _update_time(delta: float) -> void:
	var time_increment = (24.0 / day_length_seconds) * time_scale * delta
	current_time += time_increment
	
	if current_time >= 24.0:
		current_time -= 24.0
		current_day += 1
		day_changed.emit(current_day)
		GameManager.world_state["day_count"] = current_day
	
	GameManager.world_state["time_of_day"] = current_time
	time_changed.emit(current_time)

func _update_weather(delta: float) -> void:
	weather_timer += delta
	
	if weather_timer >= next_weather_change:
		_change_weather()
		weather_timer = 0.0
		_calculate_next_weather_change()

func _calculate_next_weather_change() -> void:
	next_weather_change = randf_range(weather_duration_min, weather_duration_max)

func _change_weather() -> void:
	var possible_weather = weather_types.duplicate()
	possible_weather.erase(current_weather)
	
	# Weight weather based on time of day
	var weights = []
	for w in possible_weather:
		var weight = 1.0
		if w == "fog" and (current_time >= 20.0 or current_time < 6.0):
			weight = 2.0 # More fog at night
		if w == "storm" and current_day > 10:
			weight = 1.5 # More storms later in game
		weights.append(weight)
	
	# Weighted random selection
	var total_weight = 0.0
	for w in weights:
		total_weight += w
	
	var rand_val = randf() * total_weight
	var accum = 0.0
	
	for i in range(possible_weather.size()):
		accum += weights[i]
		if rand_val <= accum:
			current_weather = possible_weather[i]
			break
	
	GameManager.world_state["weather"] = current_weather
	weather_changed.emit(current_weather)

func _update_generator(delta: float) -> void:
	if generator_on and generator_fuel > 0:
		generator_fuel -= (fuel_consumption_rate / 60.0) * delta
		generator_fuel = max(0.0, generator_fuel)
		GameManager.world_state["generator_fuel"] = generator_fuel
		generator_fuel_changed.emit(generator_fuel)
		
		if generator_fuel <= 0:
			generator_on = false

def get_time_of_day() -> float:
	return current_time

def get_day_count() -> int:
	return current_day

def get_weather() -> String:
	return current_weather

def is_night() -> bool:
	return current_time >= night_start_hour or current_time < night_end_hour

def get_time_until_night() -> float:
	if is_night():
		return 0.0
	return night_start_hour - current_time

def get_time_until_day() -> float:
	if not is_night():
		return 0.0
	if current_time >= night_start_hour:
		return (24.0 - current_time) + night_end_hour
	return night_end_hour - current_time

def set_time(hour: float) -> void:
	current_time = fmod(hour, 24.0)
	GameManager.world_state["time_of_day"] = current_time
	time_changed.emit(current_time)

def advance_time(hours: float) -> void:
	current_time += hours
	while current_time >= 24.0:
		current_time -= 24.0
		current_day += 1
		day_changed.emit(current_day)
	GameManager.world_state["time_of_day"] = current_time
	GameManager.world_state["day_count"] = current_day
	time_changed.emit(current_time)

def set_weather(weather: String) -> void:
	if weather in weather_types:
		current_weather = weather
		GameManager.world_state["weather"] = current_weather
		weather_changed.emit(current_weather)
		_calculate_next_weather_change()

def can_travel_to(from_level: String, to_level: String) -> bool:
	if not level_connections.has(from_level):
		return false
	return to_level in level_connections[from_level]

def get_connected_levels(level: String) -> Array[String]:
	return level_connections.get(level, [])

def travel_to_level(target_level: String) -> bool:
	var current_level = GameManager.current_level
	if can_travel_to(current_level, target_level):
		level_transition.emit(current_level, target_level)
		GameManager._change_level(target_level)
		return true
	return false

# Safehouse upgrades
func get_upgrade_info(upgrade_id: String) -> Dictionary:
	return safehouse_upgrades.get(upgrade_id, {})

func can_upgrade(upgrade_id: String) -> bool:
	if not safehouse_upgrades.has(upgrade_id):
		return false
	var upgrade = safehouse_upgrades[upgrade_id]
	return upgrade["level"] < upgrade["max_level"]

func get_upgrade_cost(upgrade_id: String) -> int:
	if not safehouse_upgrades.has(upgrade_id):
		return -1
	var upgrade = safehouse_upgrades[upgrade_id]
	if upgrade["level"] >= upgrade["max_level"]:
		return -1
	return upgrade["cost"][upgrade["level"]]

func purchase_upgrade(upgrade_id: String) -> bool:
	if not can_upgrade(upgrade_id):
		return false
	
	var cost = get_upgrade_cost(upgrade_id)
	# Check if player has resources (would integrate with inventory)
	# For now, just apply upgrade
	safehouse_upgrades[upgrade_id]["level"] += 1
	
	if safehouse_upgrades[upgrade_id]["level"] == 1:
		if upgrade_id not in GameManager.world_state["safehouse_upgrades"]:
			GameManager.world_state["safehouse_upgrades"].append(upgrade_id)
	
	safehouse_upgraded.emit(upgrade_id)
	return true

func get_all_upgrades() -> Dictionary:
	return safehouse_upgrades

# Generator
func toggle_generator() -> bool:
	if generator_fuel <= 0:
		return false
	generator_on = not generator_on
	return generator_on

def is_generator_on() -> bool:
	return generator_on

def add_generator_fuel(amount: float) -> void:
	generator_fuel = min(max_generator_fuel, generator_fuel + amount)
	GameManager.world_state["generator_fuel"] = generator_fuel
	generator_fuel_changed.emit(generator_fuel)

def get_generator_fuel() -> float:
	return generator_fuel

def get_max_generator_fuel() -> float:
	return max_generator_fuel

# Save/Load
func get_save_data() -> Dictionary:
	var active_upgrades = []
	for upgrade_id, data in safehouse_upgrades:
		if data["level"] > 0:
			active_upgrades.append(upgrade_id)
	
	return {
		"time_of_day": current_time,
		"day_count": current_day,
		"weather": current_weather,
		"safehouse_upgrades": active_upgrades,
		"generator_fuel": generator_fuel,
		"barricade_health": GameManager.world_state.get("barricade_health", 100),
	}

func load_save_data(data: Dictionary) -> void:
	current_time = data.get("time_of_day", 8.0)
	current_day = data.get("day_count", 1)
	current_weather = data.get("weather", "clear")
	
	var saved_upgrades = data.get("safehouse_upgrades", [])
	for upgrade_id in saved_upgrades:
		if safehouse_upgrades.has(upgrade_id):
			safehouse_upgrades[upgrade_id]["level"] = 1
	
	generator_fuel = data.get("generator_fuel", 100.0)
	GameManager.world_state["barricade_health"] = data.get("barricade_health", 100)
	
	GameManager.world_state["time_of_day"] = current_time
	GameManager.world_state["day_count"] = current_day
	GameManager.world_state["weather"] = current_weather
	GameManager.world_state["generator_fuel"] = generator_fuel
	
	time_changed.emit(current_time)
	day_changed.emit(current_day)
	weather_changed.emit(current_weather)
	generator_fuel_changed.emit(generator_fuel)