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
		sprite.pixel_size = 0.02
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
	charge_particles.amount = 10
	charge_particles.lifetime = 0.5
	charge_particles.emitting = false

	var conv_mat = ParticleProcessMaterial.new()
	conv_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	conv_mat.emission_sphere_radius = 1.0
	conv_mat.direction = Vector3(0, 0, 0)
	conv_mat.spread = 0.0
	conv_mat.initial_velocity_min = 0.0
	conv_mat.initial_velocity_max = 0.0
	conv_mat.radial_velocity_min = -3.0
	conv_mat.radial_velocity_max = -2.0
	conv_mat.gravity = Vector3.ZERO
	conv_mat.scale_min = 0.3
	conv_mat.scale_max = 0.8
	conv_mat.color = Color(0.4, 0.85, 1.0)
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
	var area_scale = 1.0 + (level - 1) * 0.12
	beam_area.scale = Vector3(area_scale, 1.0, area_scale)
	beam_mesh.scale = Vector3(area_scale, 1.0, area_scale)

	# Screen shake and SFX
	ScreenEffects.shake(0.4)
	AudioManager.play_sfx("hit")

func _on_body_entered(body: Node3D) -> void:
	if body in hit_enemies:
		return
	if body.has_method("take_damage") and body.is_in_group("enemies"):
		var level = GameManager.get_weapon_level("plasma_cannon")
		var dmg = int(WeaponDB.get_damage("plasma_cannon", level))
		body.call_deferred("take_damage", dmg, "electric")
		hit_enemies.append(body)
		ParticleFactory.spawn_hit_particles(body.global_position + Vector3(0, 0.5, 0), Color(0.3, 0.8, 1.0))
