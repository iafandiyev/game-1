extends Control

## CheckpointNotification - Checkpoint reached notification

@onready var name_label: Label = %Name

func _ready() -> void:
	set_process_mode(PROCESS_MODE_ALWAYS)
	_animate_in()

func set_checkpoint_name(name: String) -> void:
	name_label.text = name

func _animate_in() -> void:
	modulate = Color(1, 1, 1, 0)
	position = Vector2(0, 50)
	
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.3)
	tween.tween_property(self, "position:y", 0, 0.3)
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	
	# Auto-hide after 3 seconds
	var timer = Timer.new()
	timer.wait_time = 3.0
	timer.one_shot = true
	timer.timeout.connect(_animate_out.bind())
	add_child(timer)
	timer.start()

func _animate_out() -> void:
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	tween.tween_property(self, "position:y", -50, 0.5)
	tween.set_trans(Tween.TRANS_SINE)
	tween.finished.connect(queue_free.bind())