extends CharacterBody2D

class_name Projectile

## Projectile - Base projectile class for bullets, arrows, etc.

signal hit(position: Vector2, normal: Vector2, target: Node)

@export var speed: float = 1000.0
@export var damage: float = 10.0
@export var range: float = 500.0
@export var penetration: int = 0
@export var hit_effect: PackedScene
@export var trail_effect: PackedScene

var distance_traveled: float = 0.0
var owner_id: int = 0
var direction: Vector2 = Vector2.RIGHT
var hit_count: int = 0
var trail_instance: Node = null

func _ready() -> void:
	collision_layer = 1 << 3 # Projectile layer
	collision_mask = (1 << 2) | (1 << 1) | (1 << 0) # World, Enemy, Player
	
	if trail_effect:
		trail_instance = trail_effect.instantiate()
		add_child(trail_instance)
	
	rotation = direction.angle()

func _physics_process(delta: float) -> void:
	var movement = direction * speed * delta
	distance_traveled += movement.length()
	
	if distance_traveled >= range:
		queue_free()
		return
	
	velocity = movement
	move_and_slide()

func _on_body_entered(body: Node2D) -> void:
	if body.get_instance_id() == owner_id:
		return
	
	hit_count += 1
	
	if body.has_method("take_damage"):
		body.take_damage(damage, "bullet", global_position)
	
	_hit_effect(global_position, -direction)
	
	# Penetration
	if hit_count > penetration:
		queue_free()

func _hit_effect(position: Vector2, normal: Vector2) -> void:
	if hit_effect:
		var effect = hit_effect.instantiate()
		effect.global_position = position
		effect.rotation = normal.angle()
		get_tree().get_root().add_child(effect)
	
	hit.emit(position, normal, null)

func set_direction(dir: Vector2) -> void:
	direction = dir.normalized()
	rotation = direction.angle()