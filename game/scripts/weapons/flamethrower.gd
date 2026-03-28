extends Node3D

## Lancachamas — dano continuo em cone de fogo na direcao do inimigo mais proximo.

var tick_timer: float = 0.0
var tick_interval: float = 0.2
var is_firing: bool = false
var fire_timer: float = 0.0
var fire_duration: float = 1.5
var cooldown_timer: float = 0.0
var fire_direction: Vector3 = Vector3.FORWARD

@onready var flame_area: Area3D = $FlameArea
@onready var flame_mesh: MeshInstance3D = $FlameMesh

var burning_enemies: Dictionary = {}  # enemy_id -> burn_timer
var ember_particles: GPUParticles3D = null
var heat_shimmer: MeshInstance3D = null
var _shimmer_time: float = 0.0

func _ready() -> void:
	flame_mesh.visible = false
	flame_area.monitoring = false
	# Billboard sprite
	var _sprite_path = "res://assets/sprites/weapons/flamethrower.png"
	if ResourceLoader.exists(_sprite_path):
		flame_mesh.visible = false
		var sprite = Sprite3D.new()
		sprite.texture = load(_sprite_path)
		sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		sprite.pixel_size = 0.03
		sprite.shaded = false
		sprite.transparent = true
		sprite.name = "WeaponSprite"
		flame_mesh.get_parent().add_child(sprite)
	# Ember/spark particles
	_create_ember_particles()
	# Heat shimmer overlay
	_create_heat_shimmer()

func _get_player_node() -> Node3D:
	var candidate = get_parent().get_parent() if get_parent() else null
	if candidate is CharacterBody3D:
		return candidate
	return null

func _create_ember_particles() -> void:
	ember_particles = GPUParticles3D.new()
	ember_particles.emitting = false
	ember_particles.amount = 24
	ember_particles.lifetime = 0.8
	ember_particles.explosiveness = 0.1
	ember_particles.randomness = 0.6
	ember_particles.visibility_aabb = AABB(Vector3(-3, -1, -5), Vector3(6, 4, 10))

	var mat = ParticleProcessMaterial.new()
	mat.direction = Vector3(0, 1, 0)
	mat.spread = 35.0
	mat.initial_velocity_min = 1.5
	mat.initial_velocity_max = 3.5
	mat.gravity = Vector3(0, -1.0, 0)
	mat.scale_min = 0.03
	mat.scale_max = 0.08
	mat.color = Color(1.0, 0.6, 0.15, 0.9)

	# Color ramp: orange -> red -> transparent
	var color_ramp = GradientTexture1D.new()
	var grad = Gradient.new()
	grad.set_color(0, Color(1.0, 0.7, 0.2, 1.0))
	grad.add_point(0.5, Color(1.0, 0.3, 0.05, 0.7))
	grad.set_color(1, Color(0.6, 0.1, 0.0, 0.0))
	color_ramp.gradient = grad
	mat.color_ramp = color_ramp

	ember_particles.process_material = mat

	# Simple sphere mesh for each ember
	var sphere = SphereMesh.new()
	sphere.radius = 0.04
	sphere.height = 0.08
	sphere.radial_segments = 4
	sphere.rings = 2
	var ember_mat = StandardMaterial3D.new()
	ember_mat.emission_enabled = true
	ember_mat.emission = Color(1.0, 0.5, 0.1, 1.0)
	ember_mat.emission_energy_multiplier = 3.0
	ember_mat.transparency = 1
	ember_mat.albedo_color = Color(1.0, 0.6, 0.2, 0.9)
	sphere.material = ember_mat
	ember_particles.draw_pass_1 = sphere

	flame_mesh.add_child(ember_particles)

func _create_heat_shimmer() -> void:
	heat_shimmer = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(2.6, 0.5, 4.6)
	var shimmer_mat = StandardMaterial3D.new()
	shimmer_mat.transparency = 1
	shimmer_mat.albedo_color = Color(1.0, 0.9, 0.8, 0.07)
	shimmer_mat.emission_enabled = true
	shimmer_mat.emission = Color(1.0, 0.7, 0.3, 1.0)
	shimmer_mat.emission_energy_multiplier = 0.5
	shimmer_mat.no_depth_test = true
	box.material = shimmer_mat
	heat_shimmer.mesh = box
	heat_shimmer.position = Vector3(0, 0.15, -0.1)
	flame_mesh.add_child(heat_shimmer)

func _process(delta: float) -> void:
	if not is_inside_tree():
		return
	if GameManager.paused or GameManager.is_game_over:
		return

	var level = GameManager.get_weapon_level("flamethrower")
	if level <= 0:
		return

	var cooldown = WeaponDB.get_cooldown("flamethrower", level) / GameManager.attack_speed_mult * GameManager.cooldown_mult

	# Update burn timers
	var to_remove: Array = []
	for key in burning_enemies:
		burning_enemies[key] -= delta
		if burning_enemies[key] <= 0:
			to_remove.append(key)
	for key in to_remove:
		burning_enemies.erase(key)

	# Animate heat shimmer while visible
	if is_firing and heat_shimmer:
		_shimmer_time += delta * 4.0
		var shimmer_scale_x = 1.0 + sin(_shimmer_time * 3.7) * 0.08
		var shimmer_scale_z = 1.0 + cos(_shimmer_time * 2.9) * 0.06
		var shimmer_y = 0.15 + sin(_shimmer_time * 5.3) * 0.04
		heat_shimmer.scale = Vector3(shimmer_scale_x, 1.0, shimmer_scale_z)
		heat_shimmer.position.y = shimmer_y

	if is_firing:
		fire_timer -= delta
		tick_timer -= delta

		# Aim toward nearest enemy
		_update_aim()

		# Tick damage
		if tick_timer <= 0:
			tick_timer = tick_interval
			_deal_damage(level)

		if fire_timer <= 0:
			is_firing = false
			_set_flame_visible(false)
			flame_area.monitoring = false
			cooldown_timer = cooldown
	else:
		cooldown_timer -= delta
		if cooldown_timer <= 0:
			_start_fire(level)

func _start_fire(level: int) -> void:
	if not is_inside_tree():
		return
	var enemies = GameManager.get_enemies()
	if enemies.is_empty() and not GameManager.manual_aim:
		return

	is_firing = true
	fire_duration = 1.5 + (level - 1) * 0.15
	fire_timer = fire_duration
	tick_timer = 0.0
	_set_flame_visible(true)
	flame_area.monitoring = true

	# Scale cone with level
	var area_scale = 1.0 + (level - 1) * 0.12
	flame_area.scale = Vector3(area_scale, 1.0, area_scale)
	flame_mesh.scale = Vector3(area_scale, 1.0, area_scale)

	_update_aim()

func _update_aim() -> void:
	if GameManager.manual_aim:
		fire_direction = GameManager.aim_direction
		if fire_direction.length() > 0.01:
			var aim_angle = atan2(-fire_direction.x, -fire_direction.z)
			rotation.y = aim_angle
		return

	var player = _get_player_node()
	if not player:
		return
	var player_pos = player.global_position

	# Use spatial grid for nearby search instead of iterating all enemies
	var nearby = GameManager.get_nearby_enemies(player_pos, 15.0)
	if nearby.is_empty():
		return

	var nearest: Node3D = null
	var min_dist = INF
	for e in nearby:
		if not is_instance_valid(e):
			continue
		var d = player_pos.distance_squared_to(e.global_position)
		if d < min_dist:
			min_dist = d
			nearest = e

	if nearest:
		fire_direction = (nearest.global_position - player_pos).normalized()
		fire_direction.y = 0
		if fire_direction.length() > 0.01:
			var aim_angle = atan2(-fire_direction.x, -fire_direction.z)
			rotation.y = aim_angle

func _deal_damage(level: int) -> void:
	var bodies = flame_area.get_overlapping_bodies()
	var dmg = int(WeaponDB.get_damage("flamethrower", level))

	for body in bodies:
		if not is_instance_valid(body):
			continue
		if body.has_method("take_damage") and body.is_in_group("enemies"):
			GameManager._last_attacking_weapon = "flamethrower"
			body.call_deferred("take_damage", dmg, "fire")
			# Apply burn effect (track by id to prevent stacking)
			burning_enemies[body.get_instance_id()] = 2.0

	# Fire particles
	if not bodies.is_empty():
		var player = _get_player_node()
		if not player:
			return
		var player_pos = player.global_position
		var fx_pos = player_pos + fire_direction * 2.0 + Vector3(0, 0.5, 0)
		ParticleFactory.spawn_hit_particles(fx_pos, Color(1.0, 0.4, 0.1))

func _set_flame_visible(visible_flag: bool) -> void:
	flame_mesh.visible = visible_flag
	if ember_particles:
		ember_particles.emitting = visible_flag
	if heat_shimmer:
		heat_shimmer.visible = visible_flag
	if not visible_flag:
		_shimmer_time = 0.0
