extends Control

## LoadingScreen - Loading screen with tips

@onready var progress_bar: ProgressBar = %ProgressBar
@onready var tip_label: Label = %TipLabel

var tips = [
	"Tip: Conserve ammo. Melee weapons are silent.",
	"Tip: Zombies are attracted to sound. Move quietly.",
	"Tip: Night brings more dangerous zombies. Find shelter.",
	"Tip: Craft bandages from cloth. Always carry some.",
	"Tip: Water is more critical than food. Find clean sources.",
	"Tip: Infection can be cured with antibiotics.",
	"Tip: Upgrade your safehouse for better defenses.",
	"Tip: The flashlight battery drains. Turn it off when not needed.",
	"Tip: Runners are fast but fragile. Shotguns work well.",
	"Tip: Tanks are slow but deadly. Keep your distance.",
	"Tip: Screamers call others. Kill them first or run.",
	"Tip: Crawlers hide in vents. Watch your surroundings.",
	"Tip: Sleep in your safehouse to pass time safely.",
	"Tip: Locked doors may hide valuable loot.",
	"Tip: Generators need fuel. Scavenge for gas cans."
]

func _ready() -> void:
	# Show random tip
	tip_label.text = tips[randi() % tips.size()]
	
	# Animate progress bar
	_animate_progress()

func _animate_progress() -> void:
	var tween = create_tween()
	tween.tween_property(progress_bar, "value", 100, 2.0)
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)

func set_progress(percent: float) -> void:
	progress_bar.value = percent

func set_tip(tip: String) -> void:
	tip_label.text = tip