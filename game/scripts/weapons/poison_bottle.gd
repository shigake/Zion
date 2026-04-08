extends Node3D

## Garrafa de Veneno — arremessa garrafas que criam pocas de veneno no chao.

var attack_timer: float = 0.0
var active_pools: Array = []

# --- Cached materials (lazy-init, reused across spawns) ---
var _puddle_mat_cache: StandardMaterial3D = null
var _ripple_mat_cache: StandardMaterial3D = null
var _cloud_mesh_mat_cache: StandardMaterial3D = null
var _bubble_mesh_mat_cache: StandardMaterial3D = null

func _get_puddle_mat() -> StandardMaterial3D:
	if _puddle_mat_cache == null:
		_puddle_mat_cache = StandardMaterial3D.new()
		_puddle_mat_cache.albedo_color = Color(0.1, 0.9, 0.15, 0.9)
		_puddle_mat_cache.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_puddle_mat_cache.emission_enabled = true
		_puddle_mat_cache.emission = Color(0.15, 1.0, 0.2)
		_puddle_mat_cache.emission_energy_multiplier = 3.0
		_puddle_mat_cache.roughness = 0.1
		_puddle_mat_cache.cull_mode = BaseMaterial3D.CULL_DISABLED
	return _puddle_mat_cache

func _get_ripple_mat() -> StandardMaterial3D:
	if _ripple_mat_cache == null:
		_ripple_mat_cache = StandardMaterial3D.new()
		_ripple_mat_cache.albedo_color = Color(0.2, 1.0, 0.3, 0.35)
		_ripple_mat_cache.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_ripple_mat_cache.emission_enabled = true
		_ripple_mat_cache.emission = Color(0.15, 0.9, 0.15)
		_ripple_mat_cache.emission_energy_multiplier = 2.0
		_ripple_mat_cache.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_ripple_mat_cache.cull_mode = BaseMaterial3D.CULL_DISABLED
	return _ripple_mat_cache

func _get_cloud_mesh_mat() -> StandardMaterial3D:
	if _cloud_mesh_mat_cache == null:
		_cloud_mesh_mat_cache = StandardMaterial3D.new()
		_cloud_mesh_mat_cache.albedo_color = Color(0.15, 0.95, 0.1, 0.6)
		_cloud_mesh_mat_cache.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_cloud_mesh_mat_cache.emission_enabled = true
		_cloud_mesh_mat_cache.emission = Color(0.15, 0.9, 0.1)
		_cloud_mesh_mat_cache.emission_energy_multiplier = 1.2
		_cloud_mesh_mat_cache.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return _cloud_mesh_mat_cache

func _get_bubble_mesh_mat() -> StandardMaterial3D:
	if _bubble_mesh_mat_cache == null:
		_bubble_mesh_mat_cache = StandardMaterial3D.new()
		_bubble_mesh_mat_cache.albedo_color = Color(0.1, 0.85, 0.05, 0.55)
		_bubble_mesh_mat_cache.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_bubble_mesh_mat_cache.roughness = 0.1
		_bubble_mesh_mat_cache.emission_enabled = true
		_bubble_mesh_mat_cache.emission = Color(0.15, 0.9, 0.05)
		_bubble_mesh_mat_cache.emission_energy_multiplier = 0.6
	return _bubble_mesh_mat_cache

static func _add_emission_recursive(model: Node3D, color: Color, strength: float) -> void:
	for child in model.get_children():
		if child is MeshInstance3D:
			var mi := child as MeshInstance3D
			for si in range(mi.get_surface_override_material_count()):
				var base_mat = mi.mesh.surface_get_material(si)
				if base_mat is StandardMaterial3D:
					var mat = base_mat.duplicate() as StandardMaterial3D
					mat.emission_enabled = true
					mat.emission = color
					mat.emission_energy_multiplier = strength
					mi.set_surface_override_material(si, mat)
		_add_emission_recursive(child, color, strength)

func _process(delta: float) -> void:
	if not is_inside_tree():
		return
	if GameManager.paused or GameManager.is_game_over:
		return

	var level = GameManager.get_weapon_level("poison_bottle")
	if level <= 0:
		return

	# Clean up expired pools
	active_pools = active_pools.filter(func(p): return is_instance_valid(p))

	var max_pools = 3 + int((level - 1) / 2)
	var cooldown = WeaponDB.get_cooldown("poison_bottle", level) / GameManager.attack_speed_mult * GameManager.cooldown_mult

	attack_timer -= delta
	if attack_timer <= 0 and active_pools.size() < max_pools:
		attack_timer = cooldown
		_throw_bottle(level)

func _get_player_node() -> Node3D:
	var candidate = get_parent().get_parent() if get_parent() else null
	if candidate is CharacterBody3D:
		return candidate
	return null

func _throw_bottle(level: int) -> void:
	if not is_inside_tree():
		return
	var enemies = GameManager.get_enemies()
	if enemies.is_empty() and not GameManager.manual_aim:
		return

	var player = _get_player_node()
	if not player:
		return
	var player_pos = player.global_position

	var target_pos: Vector3
	if GameManager.manual_aim:
		# Throw in aim direction, 8 units away
		target_pos = player_pos + GameManager.aim_direction * 8.0
		target_pos.y = 0.05
	else:
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

		target_pos = nearest.global_position
		target_pos.y = 0.05

	# Create poison pool
	var pool = Node3D.new()
	pool.name = "PoisonPool"
	pool.position = target_pos

	# Visual — 3D model + particles
	var pool_radius = 2.0 + (level - 1) * 0.3

	# --- Main puddle: imported organic 3D model ---
	var puddle_mi: Node3D = null
	var _pool_scene_path = "res://assets/models/poison_pool.glb"
	if ResourceLoader.exists(_pool_scene_path):
		var pool_scene = load(_pool_scene_path)
		puddle_mi = pool_scene.instantiate()
		puddle_mi.name = "PuddleModel"
		# Scale model to match pool radius (model is ~2 units wide)
		var model_scale = pool_radius * randf_range(0.9, 1.1)
		puddle_mi.scale = Vector3(model_scale, 1.0, model_scale)
		puddle_mi.rotation.y = randf() * TAU  # Random rotation for variety
		puddle_mi.position = Vector3(0, 0.02, 0)
		# Keep original textures, add neon green emission
		_add_emission_recursive(puddle_mi, Color(0.15, 1.0, 0.2), 3.0)
		pool.add_child(puddle_mi)
	else:
		# Fallback: simple disc
		puddle_mi = MeshInstance3D.new()
		puddle_mi.name = "PuddleDisc"
		var disc = CylinderMesh.new()
		disc.top_radius = pool_radius
		disc.bottom_radius = pool_radius * 0.95
		disc.height = 0.04
		puddle_mi.mesh = disc
		puddle_mi.position = Vector3(0, 0.02, 0)
		puddle_mi.material_override = _get_puddle_mat()
		pool.add_child(puddle_mi)

	# --- Surface ripple effect (animated ring expanding outward) ---
	var ripple_mi = MeshInstance3D.new()
	ripple_mi.name = "Ripple"
	var ripple_torus = TorusMesh.new()
	ripple_torus.inner_radius = pool_radius * 0.3
	ripple_torus.outer_radius = pool_radius * 0.35
	ripple_torus.ring_segments = 4
	ripple_torus.rings = 16
	ripple_mi.mesh = ripple_torus
	ripple_mi.position = Vector3(0, 0.04, 0)
	ripple_mi.rotation.x = PI / 2.0
	# Duplicate from cache since tween animates albedo_color:a per-pool
	var ripple_mat = _get_ripple_mat().duplicate() as StandardMaterial3D
	ripple_mi.material_override = ripple_mat
	ripple_mi.scale = Vector3(0.5, 0.5, 0.5)
	pool.add_child(ripple_mi)
	# Looping ripple animation — expand then reset
	# Store tweens as meta so behavior can kill them on cleanup
	var ripple_tw = pool.create_tween().set_loops()
	ripple_tw.tween_property(ripple_mi, "scale", Vector3(1.3, 1.3, 1.3), 1.2).set_trans(Tween.TRANS_SINE)
	ripple_tw.parallel().tween_property(ripple_mat, "albedo_color:a", 0.0, 1.2)
	ripple_tw.tween_property(ripple_mi, "scale", Vector3(0.5, 0.5, 0.5), 0.0)
	ripple_tw.tween_property(ripple_mat, "albedo_color:a", 0.35, 0.0)
	pool.set_meta("_ripple_tween", ripple_tw)

	# Pulsing animation on puddle (gentle breathing)
	var _base_scale = puddle_mi.scale
	var pulse_tw = pool.create_tween().set_loops()
	pulse_tw.tween_property(puddle_mi, "scale", _base_scale * 1.06, 0.8).set_trans(Tween.TRANS_SINE)
	pulse_tw.tween_property(puddle_mi, "scale", _base_scale * 0.96, 0.8).set_trans(Tween.TRANS_SINE)
	pool.set_meta("_pulse_tween", pulse_tw)

	# --- Toxic cloud (GPUParticles3D stationary, replaces billboard sprite) ---
	var toxic_cloud = GPUParticles3D.new()
	toxic_cloud.name = "ToxicCloud"
	toxic_cloud.amount = 22
	toxic_cloud.lifetime = 2.5
	toxic_cloud.position = Vector3(0, 0.15, 0)  # Lower — hugs the puddle surface
	var cloud_proc = ParticleProcessMaterial.new()
	cloud_proc.direction = Vector3(0, 1, 0)
	cloud_proc.initial_velocity_min = 0.05
	cloud_proc.initial_velocity_max = 0.18
	cloud_proc.spread = 75.0  # Wider spread — fog-like
	cloud_proc.gravity = Vector3(0, 0.08, 0)  # Slower rise — lingers more
	cloud_proc.scale_min = 0.8
	cloud_proc.scale_max = 1.8  # Bigger clouds
	cloud_proc.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	cloud_proc.emission_sphere_radius = pool_radius * 0.5
	cloud_proc.damping_min = 0.8
	cloud_proc.damping_max = 2.0
	var cloud_scale_curve = CurveTexture.new()
	var csc = Curve.new()
	csc.add_point(Vector2(0.0, 0.0))
	csc.add_point(Vector2(0.15, 0.8))
	csc.add_point(Vector2(0.5, 1.0))
	csc.add_point(Vector2(0.85, 0.7))
	csc.add_point(Vector2(1.0, 0.0))
	cloud_scale_curve.curve = csc
	cloud_proc.scale_curve = cloud_scale_curve
	# Green gradient color ramp
	var cloud_color = GradientTexture1D.new()
	var cloud_grad = Gradient.new()
	cloud_grad.set_color(0, Color(0.2, 1.0, 0.15, 0.55))
	cloud_grad.set_color(1, Color(0.1, 0.6, 0.05, 0.0))
	cloud_color.gradient = cloud_grad
	cloud_proc.color_ramp = cloud_color
	toxic_cloud.process_material = cloud_proc
	var cloud_mesh = SphereMesh.new()
	cloud_mesh.radius = 0.12
	cloud_mesh.height = 0.24
	cloud_mesh.radial_segments = 6
	cloud_mesh.rings = 3
	cloud_mesh.surface_set_material(0, _get_cloud_mesh_mat())
	toxic_cloud.draw_pass_1 = cloud_mesh
	pool.add_child(toxic_cloud)

	# --- Bubbles (reduced from 20 to 12, larger radius) ---
	var bubbles = GPUParticles3D.new()
	bubbles.name = "Bubbles"
	bubbles.amount = 12
	bubbles.lifetime = 1.2
	bubbles.position = Vector3(0, 0.08, 0)
	var bubble_mat = ParticleProcessMaterial.new()
	bubble_mat.direction = Vector3(0, 1, 0)
	bubble_mat.initial_velocity_min = 0.4
	bubble_mat.initial_velocity_max = 1.0
	bubble_mat.spread = 50.0
	bubble_mat.gravity = Vector3(0, -0.3, 0)
	bubble_mat.scale_min = 0.05
	bubble_mat.scale_max = 0.12
	bubble_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	bubble_mat.emission_sphere_radius = pool_radius * 0.85
	bubble_mat.damping_min = 0.5
	bubble_mat.damping_max = 1.5
	var bubble_scale_curve = CurveTexture.new()
	var bcurve = Curve.new()
	bcurve.add_point(Vector2(0.0, 0.3))
	bcurve.add_point(Vector2(0.5, 1.0))
	bcurve.add_point(Vector2(0.85, 1.0))
	bcurve.add_point(Vector2(1.0, 0.0))
	bubble_scale_curve.curve = bcurve
	bubble_mat.scale_curve = bubble_scale_curve
	bubbles.process_material = bubble_mat
	var bubble_mesh = SphereMesh.new()
	bubble_mesh.radius = 0.08
	bubble_mesh.height = 0.16
	bubble_mesh.surface_set_material(0, _get_bubble_mesh_mat())
	bubbles.draw_pass_1 = bubble_mesh
	pool.add_child(bubbles)

	# Damage area
	var area = Area3D.new()
	area.collision_layer = 8
	area.collision_mask = 2
	area.monitoring = true
	var shape = CollisionShape3D.new()
	var sphere = SphereShape3D.new()
	sphere.radius = (2.0 + (level - 1) * 0.3) * GameManager.area_mult
	shape.shape = sphere
	area.add_child(shape)
	pool.add_child(area)

	# Pool behavior
	var behavior = Node.new()
	behavior.set_script(preload("res://scripts/weapons/poison_pool_behavior.gd"))
	behavior.set_meta("damage", int(WeaponDB.get_damage("poison_bottle", level)))
	behavior.set_meta("lifetime", 5.0 + level * 0.5)
	behavior.set_meta("area", area)
	pool.add_child(behavior)

	active_pools.append(pool)
	get_tree().current_scene.call_deferred("add_child", pool)

	AudioManager.play_sfx("poison_splash")
	ParticleFactory.spawn_hit_particles(target_pos + Vector3(0, 0.5, 0), Color(0.15, 0.95, 0.1), 8)
	ParticleFactory.spawn_weapon_sparks(target_pos + Vector3(0, 0.5, 0), Color(0.3, 1.0, 0.2), 4)
	ScreenEffects.shake(0.04)
