extends Node

class_name SurvivalManager

## SurvivalManager - Handles survival mechanics (hunger, thirst, stamina, health, infection)

signal stat_changed(stat_name: String, current: float, max: float)
signal health_changed(current: float, max: float)
signal stamina_changed(current: float, max: float)
signal hunger_changed(current: float, max: float)
signal thirst_changed(current: float, max: float)
signal infection_changed(current: float, max: float)
signal player_died()
signal infection_stage_changed(stage: int)
signal low_stamina_warning()
signal critical_health_warning()

@export_group("Survival Rates (per second)")
@export var hunger_rate: float = 0.003 # ~5.5 min from full to empty
@export var thirst_rate: float = 0.006 # ~2.7 min from full to empty
@export var stamina_regen_rate: float = 15.0
@export var stamina_drain_rate: float = 25.0
@export var health_regen_rate: float = 0.5 # Only when well-fed/hydrated
@export var infection_rate: float = 0.001 # Passive infection increase

@export_group("Thresholds")
@export var low_health_threshold: float = 0.25
@export var low_stamina_threshold: float = 0.2
@export var critical_hunger_threshold: float = 0.1
@export var critical_thirst_threshold: float = 0.1

@export_group("Infection Stages")
@export var infection_stages: Array[Dictionary] = [
	{"threshold": 0, "name": "Healthy", "health_penalty": 0.0, "stamina_penalty": 0.0, "description": "No infection"},
	{"threshold": 25, "name": "Exposed", "health_penalty": 0.05, "stamina_penalty": 0.1, "description": "Minor exposure, slightly reduced stats"},
	{"threshold": 50, "name": "Infected", "health_penalty": 0.15, "stamina_penalty": 0.25, "description": "Active infection, significant penalties"},
	{"threshold": 75, "name": "Severe", "health_penalty": 0.3, "stamina_penalty": 0.5, "description": "Severe infection, major penalties, health drain"},
	{"threshold": 100, "name": "Critical", "health_penalty": 0.5, "stamina_penalty": 0.75, "description": "Critical infection, rapid health loss"},
]

var stats: Dictionary = {
	"health": 100.0,
	"max_health": 100.0,
	"stamina": 100.0,
	"max_stamina": 100.0,
	"hunger": 100.0,
	"max_hunger": 100.0,
	"thirst": 100.0,
	"max_thirst": 100.0,
	"infection": 0.0,
	"max_infection": 100.0,
}

var current_infection_stage: int = 0
var is_dead: bool = false
var last_damage_time: float = 0.0
var health_regen_timer: float = 0.0
var difficulty_multiplier: float = 1.0

func _ready() -> void:
	_process_mode = Node.PROCESS_MODE_ALWAYS
	_load_stats_from_game_manager()
	_update_infection_stage()

func _load_stats_from_game_manager() -> void:
	var gm_stats = GameManager.player_stats
	for key in stats:
		if gm_stats.has(key):
			stats[key] = gm_stats[key]

func _process(delta: float) -> void:
	if is_dead:
		return
	
	_update_survival(delta)
	_update_health_regen(delta)
	_update_infection_effects(delta)
	_check_warnings()
	_sync_to_game_manager()

func _update_survival(delta: float) -> void:
	# Hunger drain
	var hunger_drain = hunger_rate * difficulty_multiplier * delta
	_modify_stat("hunger", -hunger_drain)
	
	# Thirst drain (faster than hunger)
	var thirst_drain = thirst_rate * difficulty_multiplier * delta
	_modify_stat("thirst", -thirst_drain)
	
	# Stamina regen (when not exhausted)
	if stats["stamina"] < stats["max_stamina"]:
		var regen = stamina_regen_rate * delta
		# Slower regen if hungry/thirsty
		var hunger_factor = stats["hunger"] / stats["max_hunger"]
		var thirst_factor = stats["thirst"] / stats["max_thirst"]
		regen *= (hunger_factor + thirst_factor) / 2.0
		_modify_stat("stamina", regen)
	
	# Passive infection increase (very slow)
	var infection_increase = infection_rate * difficulty_multiplier * delta
	_modify_stat("infection", infection_increase)

func _update_health_regen(delta: float) -> void:
	# Health only regens when well fed, hydrated, and not recently damaged
	if stats["health"] >= stats["max_health"]:
		return
	
	if Time.get_ticks_msec() / 1000.0 - last_damage_time < 10.0:
		return # No regen for 10 seconds after damage
	
	var hunger_factor = stats["hunger"] / stats["max_hunger"]
	var thirst_factor = stats["thirst"] / stats["max_thirst"]
	
	if hunger_factor > 0.5 and thirst_factor > 0.5:
		health_regen_timer += delta
		if health_regen_timer >= 5.0: # Regen tick every 5 seconds
			health_regen_timer = 0.0
			var regen = health_regen_rate * hunger_factor * thirst_factor
			_modify_stat("health", regen)

func _update_infection_effects(delta: float) -> void:
	var stage_data = infection_stages[current_infection_stage]
	
	# Health drain at severe/critical infection
	if current_infection_stage >= 3:
		var drain = (current_infection_stage - 2) * 0.5 * delta # 0.5/sec at stage 3, 1.0/sec at stage 4
		_modify_stat("health", -drain)

func _check_warnings() -> void:
	# Low health warning
	if stats["health"] / stats["max_health"] <= low_health_threshold:
		critical_health_warning.emit()
	
	# Low stamina warning
	if stats["stamina"] / stats["max_stamina"] <= low_stamina_threshold:
		low_stamina_warning.emit()

func _sync_to_game_manager() -> void:
	for key in stats:
		GameManager.player_stats[key] = stats[key]

func _modify_stat(stat_name: String, amount: float) -> void:
	if not stats.has(stat_name):
		return
	
	var max_key = "max_" + stat_name
	var max_value = stats.get(max_key, 100.0)
	
	var old_value = stats[stat_name]
	var new_value = clamp(old_value + amount, 0.0, max_value)
	stats[stat_name] = new_value
	
	if abs(new_value - old_value) > 0.01:
		stat_changed.emit(stat_name, new_value, max_value)
		
		# Specific signals
		match stat_name:
			"health":
				health_changed.emit(new_value, max_value)
				if new_value <= 0 and not is_dead:
					_die()
			"stamina":
				stamina_changed.emit(new_value, max_value)
			"hunger":
				hunger_changed.emit(new_value, max_value)
			"thirst":
				thirst_changed.emit(new_value, max_value)
			"infection":
				infection_changed.emit(new_value, max_value)
				_update_infection_stage()

func _update_infection_stage() -> void:
	var infection = stats["infection"]
	var new_stage = 0
	
	for i in range(infection_stages.size() - 1, -1, -1):
		if infection >= infection_stages[i]["threshold"]:
			new_stage = i
			break
	
	if new_stage != current_infection_stage:
		current_infection_stage = new_stage
		infection_stage_changed.emit(new_stage)

func _die() -> void:
	is_dead = true
	player_died.emit()
	GameManager.show_death_screen()

# Public API
func take_damage(amount: float, damage_type: String = "physical") -> void:
	if is_dead:
		return
	
	var actual_damage = amount * difficulty_multiplier
	last_damage_time = Time.get_ticks_msec() / 1000.0
	
	# Infection chance from zombie attacks
	if damage_type == "zombie_bite" or damage_type == "zombie_scratch":
		var infection_chance = 0.3 if damage_type == "zombie_bite" else 0.1
		if randf() < infection_chance:
			add_infection(10.0)
	
	_modify_stat("health", -actual_damage)

func heal(amount: float) -> void:
	_modify_stat("health", amount)

func restore_stamina(amount: float) -> void:
	_modify_stat("stamina", amount)

func consume_stamina(amount: float) -> bool:
	if stats["stamina"] >= amount:
		_modify_stat("stamina", -amount)
		return true
	return false

func eat(food_value: float) -> void:
	_modify_stat("hunger", food_value)

func drink(water_value: float) -> void:
	_modify_stat("thirst", water_value)

func add_infection(amount: float) -> void:
	_modify_stat("infection", amount)

func cure_infection(amount: float) -> void:
	_modify_stat("infection", -amount)

func set_difficulty_multiplier(multiplier: float) -> void:
	difficulty_multiplier = multiplier

func get_stat(stat_name: String) -> float:
	return stats.get(stat_name, 0.0)

func get_stat_normalized(stat_name: String) -> float:
	var max_key = "max_" + stat_name
	var max_value = stats.get(max_key, 100.0)
	if max_value <= 0:
		return 0.0
	return stats.get(stat_name, 0.0) / max_value

func get_infection_stage() -> int:
	return current_infection_stage

func get_infection_stage_name() -> String:
	return infection_stages[current_infection_stage]["name"]

func get_infection_stage_description() -> String:
	return infection_stages[current_infection_stage]["description"]

func get_health_penalty() -> float:
	return infection_stages[current_infection_stage]["health_penalty"]

func get_stamina_penalty() -> float:
	return infection_stages[current_infection_stage]["stamina_penalty"]

func get_effective_max_health() -> float:
	return stats["max_health"] * (1.0 - get_health_penalty())

func get_effective_max_stamina() -> float:
	return stats["max_stamina"] * (1.0 - get_stamina_penalty())

func is_critical_condition() -> bool:
	return (stats["health"] / stats["max_health"] <= low_health_threshold) or \
		   (stats["hunger"] / stats["max_hunger"] <= critical_hunger_threshold) or \
		   (stats["thirst"] / stats["max_thirst"] <= critical_thirst_threshold) or \
		   (current_infection_stage >= 3)

func can_sprint() -> bool:
	return stats["stamina"] > 10.0 and stats["hunger"] > 10.0 and stats["thirst"] > 10.0

# Save/Load
func get_save_data() -> Dictionary:
	return {
		"stats": stats,
		"current_infection_stage": current_infection_stage,
		"is_dead": is_dead,
		"difficulty_multiplier": difficulty_multiplier,
	}

func load_save_data(data: Dictionary) -> void:
	stats = data.get("stats", stats)
	current_infection_stage = data.get("current_infection_stage", 0)
	is_dead = data.get("is_dead", false)
	difficulty_multiplier = data.get("difficulty_multiplier", 1.0)
	
	_sync_to_game_manager()