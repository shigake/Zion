extends Node3D

## Comportamento de uma bomba individual — espera o fuse_time e explode em area.

var damage: int = 20
var explosion_radius: float = 3.0
var fuse_time: float = 3.0
var timer: float = 0.0
var has_exploded: bool = false

var bomb_mesh: MeshInstance3D = null
var blink_timer: float = 0.0

func _ready() -> void:
	# Create bomb visual — dark red/black metallic body
	bomb_mesh = MeshInstance3D.new()
	var mesh = SphereMesh.new()
	mesh.radius = 0.3
	mesh.height = 0.6
	bomb_mesh.mesh = mesh
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.3, 0.05, 0.05, 1.0)
	mat.metallic = 0.5
	mat.emission_enabled = true
	mat.emission = Color(0.8, 0.1, 0.1)
	mat.emission_energy_multiplier = 1.0
	bomb_mesh.material_override = mat
	bomb_mesh.position.y = 0.3
	add_child(bomb_mesh)

	# Fuse cylinder on top
	var fuse = MeshInstance3D.new()
	var fuse_cyl = CylinderMesh.new()
	fuse_cyl.top_radius = 0.01
	fuse_cyl.bottom_radius = 0.01
	fuse_cyl.height = 0.15
	fuse.mesh = fuse_cyl
	var fuse_mat = StandardMaterial3D.new()
	fuse_mat.albedo_color = Color(0.15, 0.1, 0.05, 1.0)
	fuse.material_override = fuse_mat
	fuse.position = Vector3(0.02, 0.65, 0)
	fuse.rotation.z = 0.3
	add_child(fuse)

	# Fuse spark particles
	var sparks = GPUParticles3D.new()
	sparks.amount = 3
	sparks.lifetime = 0.2
	sparks.emitting = true
	sparks.one_shot = false
	sparks.position = Vector3(0.02 + sin(0.3) * 0.075, 0.65 + cos(0.3) * 0.075, 0)
	var spark_mat = ParticleProcessMaterial.new()
	spark_mat.direction = Vector3(0, 1, 0)
	spark_mat.spread = 60.0
	spark_mat.initial_velocity_min = 0.3
	spark_mat.initial_velocity_max = 1.0
	spark_mat.gravity = Vector3(0, -3, 0)
	spark_mat.scale_min = 0.2
	spark_mat.scale_max = 0.5
	spark_mat.color = Color(1.0, 0.7, 0.1, 0.9)
	sparks.process_material = spark_mat
	var spark_mesh = SphereMesh.new()
	spark_mesh.radius = 0.01
	spark_mesh.height = 0.02
	var spark_draw_mat = StandardMaterial3D.new()
	spark_draw_mat.albedo_color = Color(1.0, 0.6, 0.1, 0.9)
	spark_draw_mat.emission_enabled = true
	spark_draw_mat.emission = Color(1.0, 0.5, 0.0)
	spark_draw_mat.emission_energy_multiplier = 5.0
	spark_draw_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	spark_mesh.surface_set_material(0, spark_draw_mat)
	sparks.draw_pass_1 = spark_mesh
	add_child(sparks)

func _process(delta: float) -> void:
	if GameManager.paused:
		return

	timer += delta
	blink_timer += delta

	# Countdown pulse: emission oscillates, faster as timer approaches 0
	if bomb_mesh:
		bomb_mesh.visible = true
		var progress = clamp(timer / fuse_time, 0.0, 1.0)
		var pulse_speed = lerp(4.0, 16.0, progress)
		var pulse_val = (sin(blink_timer * pulse_speed) + 1.0) * 0.5
		var emission_energy = lerp(0.5, 2.0, pulse_val)

		var mat = bomb_mesh.material_override as StandardMaterial3D
		if mat:
			mat.emission_energy_multiplier = emission_energy

		var scale_pulse = 1.0 + sin(blink_timer * pulse_speed) * 0.08
		bomb_mesh.scale = Vector3.ONE * scale_pulse

	if timer >= fuse_time and not has_exploded:
		_explode()

func _explode() -> void:
	has_exploded = true

	var pos = global_position

	# Multi-layer explosion
	ScreenEffects.shake(0.4)
	AudioManager.play_sfx("hit")

	# Core flash
	_spawn_explosion_flash(pos, 0.5, Color(1.0, 0.9, 0.6), 6.0, 0.15)
	# Fire burst
	ParticleFactory.spawn_explosion_particles(pos, explosion_radius)
	ParticleFactory.spawn_hit_particles(pos, Color(1.0, 0.4, 0.0))
	# Smoke/debris
	ParticleFactory.spawn_hit_particles(pos + Vector3(0, 0.5, 0), Color(1.0, 0.7, 0.1))
	ParticleFactory.spawn_death_particles(pos, Color(0.3, 0.15, 0.05))

	# Damage all enemies in radius (spatial grid: O(1) instead of O(n))
	var nearby = GameManager.get_enemies_in_radius(global_position, explosion_radius)
	for enemy in nearby:
		if not is_instance_valid(enemy):
			continue
		var dist = global_position.distance_to(enemy.global_position)
		if enemy.has_method("take_damage"):
			var falloff = 1.0 - (dist / explosion_radius) * 0.5
			var final_damage = int(damage * falloff)
			enemy.call_deferred("take_damage", final_damage, "fire")

	queue_free()

func _spawn_explosion_flash(pos: Vector3, radius: float, color: Color, energy: float, duration: float) -> void:
	var flash = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = radius
	sphere.height = radius * 2.0
	flash.mesh = sphere
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(color.r, color.g, color.b, 0.8)
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = energy
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	flash.material_override = mat
	flash.global_position = pos
	get_tree().current_scene.add_child(flash)
	var tw = flash.create_tween()
	tw.set_parallel(true)
	tw.tween_property(flash, "scale", Vector3.ONE * 4.0, duration)
	tw.tween_property(mat, "albedo_color:a", 0.0, duration)
	tw.set_parallel(false)
	tw.tween_callback(flash.queue_free)
