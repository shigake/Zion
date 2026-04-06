extends Node3D

## Plasma Cannon — carrega por 1s e dispara um feixe largo de dano em linha.

var attack_timer: float = 0.0
var is_charging: bool = false
var is_firing: bool = false
var charge_timer: float = 0.0
var charge_duration: float = 1.0
var fire_timer: float = 0.0
var fire_duration: float = 0.4
var beam_direction: Vector3 = Vector3.FORWARD

@onready var beam_area: Area3D = $BeamArea
@onready var beam_mesh: MeshInstance3D = $BeamMesh
@onready var charge_mesh: MeshInstance3D = $ChargeMesh

var hit_enemies: Array = []
var energy_ring: MeshInstance3D = null
var charge_particles: GPUParticles3D = null
var beam_pulse_time: float = 0.0
var beam_smoke: GPUParticles3D = null
var beam_sparks: GPUParticles3D = null
var beam_glow_ring: MeshInstance3D = null

func _ready() -> void:
	beam_mesh.visible = false
	charge_mesh.visible = false
	beam_area.monitoring = false
	beam_area.body_entered.connect(_on_body_entered)
	# Billboard sprite
	var _sprite_path = "res://assets/sprites/weapons/plasma_cannon.png"
	if ResourceLoader.exists(_sprite_path):
		charge_mesh.visible = false
		var sprite = Sprite3D.new()
		sprite.texture = load(_sprite_path)
		sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		sprite.pixel_size = 0.03
		sprite.shaded = false
		sprite.transparent = true
		sprite.name = "WeaponSprite"
		charge_mesh.get_parent().add_child(sprite)
	_setup_billboard_sprite()

func _get_player_node() -> Node3D:
	var candidate = get_parent().get_parent() if get_parent() else null
	if candidate is CharacterBody3D:
		return candidate
	return null

func _setup_billboard_sprite() -> void:
	var sprite_path = "res://assets/sprites/projectiles/plasma_bolt.png"
	if ResourceLoader.exists(sprite_path):
		var existing_mesh = charge_mesh.get_node_or_null("Mesh")
		if not existing_mesh:
			existing_mesh = charge_mesh.get_node_or_null("MeshInstance3D")
		if existing_mesh:
			existing_mesh.visible = false
		var sprite = Sprite3D.new()
		sprite.texture = load(sprite_path)
		sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		sprite.pixel_size = 0.04
		sprite.shaded = false
		sprite.transparent = true
		sprite.name = "ProjectileSprite"
		charge_mesh.add_child(sprite)

	# -- Energy ring orbiting the charge sphere --
	energy_ring = MeshInstance3D.new()
	var torus = TorusMesh.new()
	torus.inner_radius = 0.05
	torus.outer_radius = 0.15
	energy_ring.mesh = torus
	var ring_mat = StandardMaterial3D.new()
	ring_mat.albedo_color = Color(0.3, 0.8, 1.0, 0.7)
	ring_mat.emission_enabled = true
	ring_mat.emission = Color(0.3, 0.8, 1.0)
	ring_mat.emission_energy_multiplier = 4.0
	ring_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ring_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	energy_ring.material_override = ring_mat
	energy_ring.visible = false
	charge_mesh.add_child(energy_ring)

	# -- Convergence particles (move toward center) --
	charge_particles = GPUParticles3D.new()
	charge_particles.amount = 14
	charge_particles.lifetime = 0.5
	charge_particles.emitting = false

	var conv_mat = ParticleProcessMaterial.new()
	conv_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	conv_mat.emission_sphere_radius = 1.2
	conv_mat.direction = Vector3(0, 0, 0)
	conv_mat.spread = 0.0
	conv_mat.initial_velocity_min = 0.0
	conv_mat.initial_velocity_max = 0.0
	conv_mat.radial_velocity_min = -3.5
	conv_mat.radial_velocity_max = -2.0
	conv_mat.gravity = Vector3.ZERO
	conv_mat.scale_min = 0.3
	conv_mat.scale_max = 0.8
	conv_mat.color = Color(0.4, 0.85, 1.0)
	# Fade convergence particles over lifetime
	var conv_color_ramp = GradientTexture1D.new()
	var conv_grad = Gradient.new()
	conv_grad.set_color(0, Color(0.6, 0.9, 1.0, 0.8))
	conv_grad.set_color(1, Color(0.3, 0.7, 1.0, 0.0))
	conv_color_ramp.gradient = conv_grad
	conv_mat.color_ramp = conv_color_ramp
	charge_particles.process_material = conv_mat

	var dot_mesh = SphereMesh.new()
	dot_mesh.radius = 0.02
	dot_mesh.height = 0.04
	var dot_mat = StandardMaterial3D.new()
	dot_mat.albedo_color = Color(0.4, 0.85, 1.0)
	dot_mat.emission_enabled = true
	dot_mat.emission = Color(0.3, 0.8, 1.0)
	dot_mat.emission_energy_multiplier = 3.0
	dot_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	dot_mesh.material = dot_mat
	charge_particles.draw_pass_1 = dot_mesh
	charge_particles.visible = false
	charge_mesh.add_child(charge_particles)

func _process(delta: float) -> void:
	if not is_inside_tree():
		return
	if GameManager.paused or GameManager.is_game_over:
		return

	var level = GameManager.get_weapon_level("plasma_cannon")
	if level <= 0:
		return

	var cooldown = WeaponDB.get_cooldown("plasma_cannon", level) / GameManager.attack_speed_mult * GameManager.cooldown_mult

	if is_charging:
		charge_timer -= delta
		# Pulsing charge effect with scale oscillation (0.8x to 1.2x)
		var progress = 1.0 - (charge_timer / charge_duration)
		var base_scale = 0.3 + progress * 0.7
		var pulse_offset = sin(charge_timer * 12.0) * 0.2 * base_scale
		var pulse = base_scale + pulse_offset
		charge_mesh.scale = Vector3(pulse, pulse, pulse)

		# Rotate energy ring continuously
		if energy_ring:
			energy_ring.visible = true
			energy_ring.rotation.y += delta * 5.0
			energy_ring.rotation.x += delta * 2.5
		if charge_particles:
			charge_particles.visible = true
			charge_particles.emitting = true

		if charge_timer <= 0:
			is_charging = false
			charge_mesh.visible = false
			if energy_ring:
				energy_ring.visible = false
			if charge_particles:
				charge_particles.emitting = false
				charge_particles.visible = false
			_fire_beam(level)
	elif is_firing:
		fire_timer -= delta
		# Beam width pulsing
		beam_pulse_time += delta
		var area_scale = beam_area.scale.x  # base scale set in _fire_beam
		var pulse_w = 1.0 + sin(beam_pulse_time * 20.0) * 0.15
		beam_mesh.scale.x = area_scale * pulse_w

		if fire_timer <= 0:
			is_firing = false
			beam_mesh.visible = false
			beam_area.monitoring = false
			beam_pulse_time = 0.0
			hit_enemies.clear()
			# Clean up beam effects
			if beam_smoke:
				beam_smoke.emitting = false
				var _s = beam_smoke
				get_tree().create_timer(1.0).timeout.connect(_s.queue_free)
				beam_smoke = null
			if beam_sparks:
				beam_sparks.queue_free()
				beam_sparks = null
			if beam_glow_ring:
				beam_glow_ring.queue_free()
				beam_glow_ring = null
	else:
		attack_timer -= delta
		if attack_timer <= 0:
			attack_timer = cooldown
			_start_charge(level)

func _start_charge(level: int) -> void:
	var enemies = GameManager.get_enemies()
	if enemies.is_empty() and not GameManager.manual_aim:
		return

	var player = _get_player_node()
	if not player:
		return
	var player_pos = player.global_position

	if GameManager.manual_aim:
		beam_direction = GameManager.aim_direction
	else:
		# Find nearest enemy
		var nearest: Node3D = null
		var min_dist = INF
		for e in enemies:
			if not is_instance_valid(e):
				continue
			var d = player_pos.distance_squared_to(e.global_position)
			if d < min_dist:
				min_dist = d
				nearest = e

		if nearest == null:
			return

		beam_direction = (nearest.global_position - player_pos).normalized()
		beam_direction.y = 0

	is_charging = true
	charge_duration = maxf(0.5, 1.0 - (level - 1) * 0.05)
	charge_timer = charge_duration
	charge_mesh.visible = true
	charge_mesh.scale = Vector3(0.3, 0.3, 0.3)

	# Charge particles
	ParticleFactory.spawn_hit_particles(player_pos + Vector3(0, 0.5, 0), Color(0.3, 0.8, 1.0))

func _fire_beam(level: int) -> void:
	is_firing = true
	fire_timer = fire_duration
	hit_enemies.clear()

	beam_mesh.visible = true
	beam_area.monitoring = true

	# Aim beam
	if beam_direction.length() > 0.01:
		var aim_angle = atan2(-beam_direction.x, -beam_direction.z)
		rotation.y = aim_angle

	# Scale beam with level
	var area_scale = (1.0 + (level - 1) * 0.12) * GameManager.attack_size_mult
	beam_area.scale = Vector3(area_scale, 1.0, area_scale)
	beam_mesh.scale = Vector3(area_scale, 1.0, area_scale)

	# --- Smoke/vapor trail along beam ---
	if beam_smoke:
		beam_smoke.queue_free()
	beam_smoke = GPUParticles3D.new()
	beam_smoke.amount = 12
	beam_smoke.lifetime = 0.8
	beam_smoke.emitting = true
	beam_smoke.one_shot = false
	beam_smoke.position = Vector3(0, 0.2, -3.0)  # Along beam axis
	var smoke_mat = ParticleProcessMaterial.new()
	smoke_mat.direction = Vector3(0, 1, 0)
	smoke_mat.spread = 40.0
	smoke_mat.initial_velocity_min = 0.3
	smoke_mat.initial_velocity_max = 0.8
	smoke_mat.gravity = Vector3(0, 0.5, 0)
	smoke_mat.scale_min = 0.4
	smoke_mat.scale_max = 1.0
	smoke_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	smoke_mat.emission_box_extents = Vector3(area_scale * 0.5, 0.1, 3.0)
	smoke_mat.damping_min = 2.0
	smoke_mat.damping_max = 4.0
	var smoke_color = GradientTexture1D.new()
	var smoke_grad = Gradient.new()
	smoke_grad.set_color(0, Color(0.3, 0.7, 1.0, 0.3))
	smoke_grad.set_color(1, Color(0.15, 0.4, 0.6, 0.0))
	smoke_color.gradient = smoke_grad
	smoke_mat.color_ramp = smoke_color
	var smoke_scale_curve = CurveTexture.new()
	var sc = Curve.new()
	sc.add_point(Vector2(0.0, 0.3))
	sc.add_point(Vector2(0.3, 1.0))
	sc.add_point(Vector2(1.0, 0.0))
	smoke_scale_curve.curve = sc
	smoke_mat.scale_curve = smoke_scale_curve
	beam_smoke.process_material = smoke_mat
	var smoke_draw = SphereMesh.new()
	smoke_draw.radius = 0.15
	smoke_draw.height = 0.3
	smoke_draw.radial_segments = 5
	smoke_draw.rings = 3
	var smoke_draw_mat = StandardMaterial3D.new()
	smoke_draw_mat.albedo_color = Color(0.3, 0.65, 0.9, 0.35)
	smoke_draw_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	smoke_draw_mat.emission_enabled = true
	smoke_draw_mat.emission = Color(0.2, 0.6, 1.0)
	smoke_draw_mat.emission_energy_multiplier = 1.5
	smoke_draw_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	smoke_draw.surface_set_material(0, smoke_draw_mat)
	beam_smoke.draw_pass_1 = smoke_draw
	add_child(beam_smoke)

	# --- Electric sparks along beam edges ---
	if beam_sparks:
		beam_sparks.queue_free()
	beam_sparks = GPUParticles3D.new()
	beam_sparks.amount = 8
	beam_sparks.lifetime = 0.3
	beam_sparks.emitting = true
	beam_sparks.one_shot = false
	beam_sparks.position = Vector3(0, 0.3, -2.5)
	var sparks_mat = ParticleProcessMaterial.new()
	sparks_mat.direction = Vector3(1, 1, 0)
	sparks_mat.spread = 180.0
	sparks_mat.initial_velocity_min = 2.0
	sparks_mat.initial_velocity_max = 5.0
	sparks_mat.gravity = Vector3(0, -4.0, 0)
	sparks_mat.scale_min = 0.1
	sparks_mat.scale_max = 0.3
	sparks_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	sparks_mat.emission_box_extents = Vector3(area_scale * 0.6, 0.05, 2.5)
	sparks_mat.color = Color(0.5, 0.9, 1.0, 0.9)
	beam_sparks.process_material = sparks_mat
	var spark_draw = SphereMesh.new()
	spark_draw.radius = 0.015
	spark_draw.height = 0.03
	var spark_mat_draw = StandardMaterial3D.new()
	spark_mat_draw.albedo_color = Color(0.6, 0.95, 1.0, 0.9)
	spark_mat_draw.emission_enabled = true
	spark_mat_draw.emission = Color(0.5, 0.9, 1.0)
	spark_mat_draw.emission_energy_multiplier = 6.0
	spark_mat_draw.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	spark_mat_draw.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	spark_draw.surface_set_material(0, spark_mat_draw)
	beam_sparks.draw_pass_1 = spark_draw
	add_child(beam_sparks)

	# --- Glow ring at beam origin ---
	if beam_glow_ring:
		beam_glow_ring.queue_free()
	beam_glow_ring = MeshInstance3D.new()
	var glow_torus = TorusMesh.new()
	glow_torus.inner_radius = 0.2 * area_scale
	glow_torus.outer_radius = 0.4 * area_scale
	beam_glow_ring.mesh = glow_torus
	var glow_mat = StandardMaterial3D.new()
	glow_mat.albedo_color = Color(0.3, 0.8, 1.0, 0.5)
	glow_mat.emission_enabled = true
	glow_mat.emission = Color(0.4, 0.85, 1.0)
	glow_mat.emission_energy_multiplier = 5.0
	glow_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glow_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	beam_glow_ring.material_override = glow_mat
	beam_glow_ring.position = Vector3(0, 0.3, 0)
	beam_glow_ring.rotation.x = PI / 2.0
	add_child(beam_glow_ring)
	# Animate glow ring expanding then fading
	var ring_tw = beam_glow_ring.create_tween()
	ring_tw.set_parallel(true)
	ring_tw.tween_property(beam_glow_ring, "scale", Vector3(2.0, 2.0, 2.0), fire_duration).set_trans(Tween.TRANS_QUAD)
	ring_tw.tween_property(glow_mat, "albedo_color:a", 0.0, fire_duration)

	# Screen shake and SFX
	ScreenEffects.shake(0.4)
	AudioManager.play_sfx("hit")

func _on_body_entered(body: Node3D) -> void:
	if body in hit_enemies:
		return
	if body.has_method("take_damage") and body.is_in_group("enemies"):
		var level = GameManager.get_weapon_level("plasma_cannon")
		var dmg = int(WeaponDB.get_damage("plasma_cannon", level))
		GameManager._last_attacking_weapon = "plasma_cannon"
		body.call_deferred("take_damage", dmg, "electric")
		hit_enemies.append(body)
		ParticleFactory.spawn_hit_particles(body.global_position + Vector3(0, 0.5, 0), Color(0.3, 0.8, 1.0))
