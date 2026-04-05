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
	sparks.amount = 5
	sparks.lifetime = 0.3
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

	# Smoke trail rising from bomb (smoldering effect)
	var smoke = GPUParticles3D.new()
	smoke.name = "BombSmoke"
	smoke.amount = 6
	smoke.lifetime = 1.5
	smoke.emitting = true
	smoke.one_shot = false
	smoke.position = Vector3(0, 0.5, 0)
	var smoke_mat = ParticleProcessMaterial.new()
	smoke_mat.direction = Vector3(0, 1, 0)
	smoke_mat.spread = 25.0
	smoke_mat.initial_velocity_min = 0.2
	smoke_mat.initial_velocity_max = 0.5
	smoke_mat.gravity = Vector3(0, 0.3, 0)
	smoke_mat.scale_min = 0.3
	smoke_mat.scale_max = 0.7
	smoke_mat.damping_min = 1.0
	smoke_mat.damping_max = 2.0
	var smoke_color = GradientTexture1D.new()
	var smoke_grad = Gradient.new()
	smoke_grad.set_color(0, Color(0.2, 0.15, 0.1, 0.25))
	smoke_grad.set_color(1, Color(0.15, 0.1, 0.08, 0.0))
	smoke_color.gradient = smoke_grad
	smoke_mat.color_ramp = smoke_color
	var smoke_scale_c = CurveTexture.new()
	var ssc = Curve.new()
	ssc.add_point(Vector2(0.0, 0.3))
	ssc.add_point(Vector2(0.5, 1.0))
	ssc.add_point(Vector2(1.0, 0.5))
	smoke_scale_c.curve = ssc
	smoke_mat.scale_curve = smoke_scale_c
	smoke.process_material = smoke_mat
	var smoke_draw = SphereMesh.new()
	smoke_draw.radius = 0.1
	smoke_draw.height = 0.08
	smoke_draw.radial_segments = 5
	smoke_draw.rings = 3
	var smoke_draw_mat = StandardMaterial3D.new()
	smoke_draw_mat.albedo_color = Color(0.2, 0.15, 0.1, 0.25)
	smoke_draw_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	smoke_draw_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	smoke_draw.surface_set_material(0, smoke_draw_mat)
	smoke.draw_pass_1 = smoke_draw
	add_child(smoke)

	# Danger glow on ground (red disc pulsing beneath bomb)
	var danger_glow = MeshInstance3D.new()
	danger_glow.name = "DangerGlow"
	var glow_cyl = CylinderMesh.new()
	glow_cyl.top_radius = 0.6
	glow_cyl.bottom_radius = 0.6
	glow_cyl.height = 0.01
	danger_glow.mesh = glow_cyl
	danger_glow.position.y = 0.005
	var danger_mat = StandardMaterial3D.new()
	danger_mat.albedo_color = Color(0.8, 0.15, 0.05, 0.15)
	danger_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	danger_mat.emission_enabled = true
	danger_mat.emission = Color(0.9, 0.2, 0.05)
	danger_mat.emission_energy_multiplier = 1.5
	danger_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	danger_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	danger_glow.material_override = danger_mat
	add_child(danger_glow)

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
	ScreenEffects.shake(0.5)
	AudioManager.play_sfx("hit")

	# Core flash
	_spawn_explosion_flash(pos, 0.5, Color(1.0, 0.9, 0.6), 6.0, 0.15)
	# Fire burst
	ParticleFactory.spawn_explosion_particles(pos, explosion_radius)
	ParticleFactory.spawn_hit_particles(pos, Color(1.0, 0.4, 0.0))
	# Smoke/debris
	ParticleFactory.spawn_hit_particles(pos + Vector3(0, 0.5, 0), Color(1.0, 0.7, 0.1))
	ParticleFactory.spawn_death_particles(pos, Color(0.3, 0.15, 0.05))

	# Shockwave ring (expanding torus on ground)
	_spawn_shockwave_ring(pos, explosion_radius)
	# Smoke column after explosion
	_spawn_smoke_column(pos)

	# Damage all enemies in radius (spatial grid: O(1) instead of O(n))
	var nearby = GameManager.get_enemies_in_radius(global_position, explosion_radius)
	for enemy in nearby:
		if not is_instance_valid(enemy):
			continue
		var dist = global_position.distance_to(enemy.global_position)
		if enemy.has_method("take_damage"):
			var falloff = 1.0 - (dist / explosion_radius) * 0.5
			var final_damage = int(damage * falloff)
			GameManager._last_attacking_weapon = "time_bomb"
			enemy.call_deferred("take_damage", final_damage, "fire")

	queue_free()

func _spawn_shockwave_ring(pos: Vector3, radius: float) -> void:
	var ring = MeshInstance3D.new()
	var torus = TorusMesh.new()
	torus.inner_radius = 0.1
	torus.outer_radius = 0.3
	torus.ring_segments = 4
	torus.rings = 16
	ring.mesh = torus
	ring.global_position = pos + Vector3(0, 0.1, 0)
	ring.rotation.x = PI / 2.0
	var ring_mat = StandardMaterial3D.new()
	ring_mat.albedo_color = Color(1.0, 0.6, 0.1, 0.6)
	ring_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ring_mat.emission_enabled = true
	ring_mat.emission = Color(1.0, 0.5, 0.0)
	ring_mat.emission_energy_multiplier = 4.0
	ring_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ring_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	ring.material_override = ring_mat
	get_tree().current_scene.add_child(ring)
	var tw = ring.create_tween()
	var target_scale = radius * 2.0
	tw.set_parallel(true)
	tw.tween_property(ring, "scale", Vector3(target_scale, target_scale, target_scale), 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(ring_mat, "albedo_color:a", 0.0, 0.35)
	tw.set_parallel(false)
	tw.tween_callback(ring.queue_free)

func _spawn_smoke_column(pos: Vector3) -> void:
	var smoke = GPUParticles3D.new()
	smoke.amount = 10
	smoke.lifetime = 1.5
	smoke.emitting = true
	smoke.one_shot = true
	smoke.global_position = pos
	var sm = ParticleProcessMaterial.new()
	sm.direction = Vector3(0, 1, 0)
	sm.spread = 30.0
	sm.initial_velocity_min = 1.0
	sm.initial_velocity_max = 3.0
	sm.gravity = Vector3(0, 0.5, 0)
	sm.scale_min = 0.5
	sm.scale_max = 1.5
	sm.damping_min = 1.0
	sm.damping_max = 3.0
	var sm_color = GradientTexture1D.new()
	var sm_grad = Gradient.new()
	sm_grad.set_color(0, Color(0.25, 0.2, 0.15, 0.4))
	sm_grad.set_color(1, Color(0.1, 0.08, 0.05, 0.0))
	sm_color.gradient = sm_grad
	sm.color_ramp = sm_color
	var sm_sc = CurveTexture.new()
	var smc = Curve.new()
	smc.add_point(Vector2(0.0, 0.3))
	smc.add_point(Vector2(0.3, 1.0))
	smc.add_point(Vector2(1.0, 0.6))
	sm_sc.curve = smc
	sm.scale_curve = sm_sc
	smoke.process_material = sm
	var sm_draw = SphereMesh.new()
	sm_draw.radius = 0.2
	sm_draw.height = 0.15
	sm_draw.radial_segments = 5
	sm_draw.rings = 3
	var sm_draw_mat = StandardMaterial3D.new()
	sm_draw_mat.albedo_color = Color(0.2, 0.15, 0.1, 0.35)
	sm_draw_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	sm_draw_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sm_draw.surface_set_material(0, sm_draw_mat)
	smoke.draw_pass_1 = sm_draw
	get_tree().current_scene.add_child(smoke)
	# Auto-cleanup after particles finish
	get_tree().create_timer(2.0).timeout.connect(smoke.queue_free)

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
