extends Node

class_name Particles

## Particles - Particle effect helpers

static func create_blood_splat(position: Vector2, intensity: float = 1.0) -> GPUParticles2D:
	var particles = GPUParticles2D.new()
	particles.emitting = true
	particles.one_shot = true
	particles.amount = int(10 * intensity)
	particles.lifetime = 1.0
	particles.explosiveness = 1.0
	particles.spread = 180.0
	particles.gravity = Vector2(0, 200)
	particles.initial_velocity = 100.0 * intensity
	particles.velocity_random = 0.5
	particles.scale = 0.5 * intensity
	particles.scale_random = 0.3
	particles.color = Color(0.6, 0.05, 0.05, 1)
	particles.color_ramp = Gradient.new()
	var ramp = Gradient.new()
	var colors = PackedColorArray([Color(0.8, 0.1, 0.1, 1), Color(0.4, 0.02, 0.02, 0.5), Color(0.2, 0.01, 0.01, 0)])
	ramp.colors = colors
	particles.color_ramp = ramp
	particles.global_position = position
	return particles

static func create_blood_mist(position: Vector2) -> GPUParticles2D:
	var particles = GPUParticles2D.new()
	particles.emitting = true
	particles.one_shot = true
	particles.amount = 20
	particles.lifetime = 0.5
	particles.explosiveness = 1.0
	particles.spread = 90.0
	particles.gravity = Vector2(0, 50)
	particles.initial_velocity = 50.0
	particles.scale = 0.3
	particles.color = Color(0.8, 0.1, 0.1, 0.5)
	particles.color_ramp = _create_blood_gradient()
	particles.global_position = position
	return particles

static func create_muzzle_flash(position: Vector2, weapon_type: String) -> GPUParticles2D:
	var particles = GPUParticles2D.new()
	particles.emitting = true
	particles.one_shot = true
	
	match weapon_type:
		"pistol":
			particles.amount = 5
			particles.lifetime = 0.1
			particles.initial_velocity = 0
			particles.scale = 0.5
			particles.color = Color(1, 0.9, 0.5, 1)
		"shotgun":
			particles.amount = 15
			particles.lifetime = 0.15
			particles.initial_velocity = 0
			particles.scale = 1.0
			particles.color = Color(1, 0.8, 0.3, 1)
		"rifle":
			particles.amount = 8
			particles.lifetime = 0.08
			particles.initial_velocity = 0
			particles.scale = 0.7
			particles.color = Color(1, 0.95, 0.6, 1)
	
	particles.explosiveness = 1.0
	particles.spread = 180.0
	particles.global_position = position
	return particles

static func create_shell_casing(position: Vector2, caliber: String) -> GPUParticles2D:
	var particles = GPUParticles2D.new()
	particles.emitting = true
	particles.one_shot = true
	particles.amount = 1
	particles.lifetime = 3.0
	particles.explosiveness = 0.0
	particles.gravity = Vector2(0, 300)
	particles.initial_velocity = 50.0
	particles.velocity_random = 0.5
	particles.spread = 30.0
	particles.scale = 0.3
	particles.color = Color(0.8, 0.7, 0.3, 1)
	particles.global_position = position
	return particles

static func create_explosion(position: Vector2, size: float = 1.0) -> GPUParticles2D:
	var particles = GPUParticles2D.new()
	particles.emitting = true
	particles.one_shot = true
	particles.amount = int(50 * size)
	particles.lifetime = 1.5 * size
	particles.explosiveness = 1.0
	particles.spread = 180.0
	particles.gravity = Vector2(0, 100)
	particles.initial_velocity = 200.0 * size
	particles.velocity_random = 0.5
	particles.scale = 1.0 * size
	particles.scale_random = 0.5
	particles.color = Color(1, 0.6, 0.1, 1)
	particles.color_ramp = _create_fire_gradient()
	particles.global_position = position
	return particles

static func create_molotov_fire(position: Vector2) -> GPUParticles2D:
	var particles = GPUParticles2D.new()
	particles.emitting = true
	particles.one_shot = false
	particles.amount = 30
	particles.lifetime = 2.0
	particles.explosiveness = 0.1
	particles.spread = 90.0
	particles.gravity = Vector2(0, -50) # Fire rises
	particles.initial_velocity = 30.0
	particles.velocity_random = 0.5
	particles.scale = 0.8
	particles.scale_random = 0.3
	particles.color = Color(1, 0.5, 0.1, 1)
	particles.color_ramp = _create_fire_gradient()
	particles.global_position = position
	return particles

static func create_dust(position: Vector2, amount: int = 10) -> GPUParticles2D:
	var particles = GPUParticles2D.new()
	particles.emitting = true
	particles.one_shot = true
	particles.amount = amount
	particles.lifetime = 1.0
	particles.explosiveness = 0.5
	particles.spread = 180.0
	particles.gravity = Vector2(0, 50)
	particles.initial_velocity = 50.0
	particles.velocity_random = 0.5
	particles.scale = 0.3
	particles.scale_random = 0.5
	particles.color = Color(0.4, 0.35, 0.3, 0.5)
	particles.global_position = position
	return particles

static func create_rain(amount: int = 1000) -> GPUParticles2D:
	var particles = GPUParticles2D.new()
	particles.emitting = true
	particles.one_shot = false
	particles.amount = amount
	particles.lifetime = 2.0
	particles.explosiveness = 0.0
	particles.gravity = Vector2(0, 500)
	particles.initial_velocity = 400.0
	particles.velocity_random = 0.2
	particles.spread = 10.0
	particles.scale = 0.1
	particles.scale_random = 0.2
	particles.color = Color(0.7, 0.8, 1.0, 0.5)
	particles.global_position = Vector2(0, 0) # Will be repositioned
	return particles

static func create_fog() -> GPUParticles2D:
	var particles = GPUParticles2D.new()
	particles.emitting = true
	particles.one_shot = false
	particles.amount = 50
	particles.lifetime = 10.0
	particles.explosiveness = 0.0
	particles.gravity = Vector2(0, 0)
	particles.initial_velocity = 5.0
	particles.velocity_random = 0.5
	particles.spread = 180.0
	particles.scale = 5.0
	particles.scale_random = 0.5
	particles.color = Color(0.3, 0.3, 0.35, 0.1)
	particles.global_position = Vector2(0, 0)
	return particles

static func _create_blood_gradient() -> Gradient:
	var gradient = Gradient.new()
	var colors = PackedColorArray([
		Color(0.8, 0.1, 0.1, 1),
		Color(0.6, 0.05, 0.05, 0.5),
		Color(0.3, 0.02, 0.02, 0)
	])
	gradient.colors = colors
	return gradient

static func _create_fire_gradient() -> Gradient:
	var gradient = Gradient.new()
	var colors = PackedColorArray([
		Color(1, 0.8, 0.1, 1),
		Color(1, 0.4, 0.05, 0.8),
		Color(0.8, 0.1, 0.02, 0.3),
		Color(0.3, 0.05, 0.01, 0)
	])
	gradient.colors = colors
	return gradient