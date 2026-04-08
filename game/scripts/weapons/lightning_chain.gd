extends Node3D

## Relampago em Cadeia — atinge o inimigo mais proximo e encadeia para vizinhos.

var attack_timer: float = 0.0
var chain_visuals: Array = []

# Cached materials/meshes — reused across all bolts to avoid per-cast allocations
var _glow_mat: StandardMaterial3D = null
var _core_mat: StandardMaterial3D = null
var _outer_mat: StandardMaterial3D = null
var _spark_mesh: SphereMesh = null
var _spark_mat: StandardMaterial3D = null
var _spark_proc_mat: ParticleProcessMaterial = null
var _flash_sphere: SphereMesh = null

func _ready() -> void:
	# 3D lightning orb model (visual for the weapon)
	var _model_path = "res://assets/models/lightning_orb.glb"
	var _model_scene = EnemyBase3D._safe_load_model(_model_path)
	if _model_scene:
		var model = _model_scene.instantiate()
		model.name = "WeaponModel"
		model.scale = Vector3(0.25, 0.25, 0.25)
		add_child(model)

func _process(delta: float) -> void:
	if not is_inside_tree():
		return
	if GameManager.paused or GameManager.is_game_over:
		return

	var level = GameManager.get_weapon_level("lightning_chain")
	if level <= 0:
		return

	# Clean up expired chain visuals
	_cleanup_visuals(delta)

	var cooldown = WeaponDB.get_cooldown("lightning_chain", level) / GameManager.attack_speed_mult * GameManager.cooldown_mult
	attack_timer -= delta
	if attack_timer <= 0:
		attack_timer = cooldown
		_cast(level)

func _get_player_node() -> Node3D:
	var candidate = get_parent().get_parent() if get_parent() else null
	if candidate is CharacterBody3D:
		return candidate
	return null

func _cast(level: int) -> void:
	if not is_inside_tree():
		return
	var enemies = GameManager.get_enemies()
	if enemies.is_empty():
		return

	var player = _get_player_node()
	if not player:
		return
	var player_pos = player.global_position

	var nearest: Node3D = null
	if GameManager.manual_aim:
		# With manual aim, find enemy closest to the aim direction ray
		var best_dot = -1.0
		for e in enemies:
			if not is_instance_valid(e):
				continue
			var to_enemy = (e.global_position - player_pos).normalized()
			to_enemy.y = 0
			var dot = to_enemy.dot(GameManager.aim_direction)
			if dot > best_dot:
				best_dot = dot
				nearest = e
	else:
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

	var base_damage = int(WeaponDB.get_damage("lightning_chain", level))
	var max_chains = 2 + int(level / 3)  # 2 at lv1, 3 at lv3, 4 at lv6, 5 at lv9
	var chain_range = 5.0 + level * 0.5

	# Hit first target
	var hit_targets: Array = []
	var current_target = nearest
	var current_damage = base_damage

	for i in range(max_chains + 1):  # +1 for initial target
		if current_target == null or not is_instance_valid(current_target):
			break
		if not current_target.has_method("take_damage"):
			break

		GameManager._last_attacking_weapon = "lightning_chain"
		current_target.call_deferred("take_damage", current_damage, "electric")
		hit_targets.append(current_target)
		ParticleFactory.spawn_hit_particles(current_target.global_position + Vector3(0, 0.5, 0), Color(0.6, 0.9, 1.0))

		# Draw lightning line from previous to current
		if hit_targets.size() >= 2:
			var prev = hit_targets[hit_targets.size() - 2]
			_draw_lightning(prev.global_position + Vector3(0, 0.5, 0), current_target.global_position + Vector3(0, 0.5, 0))
		elif hit_targets.size() == 1:
			_draw_lightning(player_pos + Vector3(0, 0.8, 0), current_target.global_position + Vector3(0, 0.5, 0))

		# Reduce damage for next chain (minimum 1)
		current_damage = maxi(1, int(current_damage * 0.7))

		# Find next nearest enemy not already hit
		var next_target: Node3D = null
		var next_min_dist = INF
		for e in enemies:
			if not is_instance_valid(e):
				continue
			if e in hit_targets:
				continue
			var d = current_target.global_position.distance_squared_to(e.global_position)
			if d < chain_range * chain_range and d < next_min_dist:
				next_min_dist = d
				next_target = e

		current_target = next_target

	AudioManager.play_sfx("electric_zap")
	# Screen feedback scales with chain length
	if hit_targets.size() >= 3:
		ScreenEffects.shake(0.12)
		ScreenEffects.flash(0.04, 0.1)
	elif hit_targets.size() >= 1:
		ScreenEffects.shake(0.06)

func _draw_lightning(from: Vector3, to: Vector3) -> void:
	var container = Node3D.new()

	# -- Compute perpendicular axes for zigzag offsets --
	var forward = (to - from).normalized()
	var up = Vector3.UP
	if abs(forward.dot(up)) > 0.9:
		up = Vector3.RIGHT
	var right = forward.cross(up).normalized()
	var perp_up = right.cross(forward).normalized()

	# -- Generate zigzag points once, reuse for core + glow passes --
	var segments = 10
	var bolt_points: Array = [from]
	for i in range(1, segments + 1):
		var t = float(i) / float(segments)
		var point = from.lerp(to, t)
		if i < segments:
			var offset_r = randf_range(-0.25, 0.25)
			var offset_u = randf_range(-0.25, 0.25)
			point += right * offset_r + perp_up * offset_u
		bolt_points.append(point)

	# -- Outer glow pass (wide, semi-transparent electric blue) — more passes for thicker arcs --
	var glow_mesh = MeshInstance3D.new()
	var im_glow = ImmediateMesh.new()
	# Draw each segment as a camera-facing quad strip for width — 5 passes for intense glow
	for pass_idx in range(5):
		im_glow.surface_begin(Mesh.PRIMITIVE_LINES)
		im_glow.surface_set_color(Color(0.3, 0.65, 1.0, 0.3))
		var jitter_scale = 0.05 * (pass_idx + 1)
		for i in range(bolt_points.size() - 1):
			var p0 = bolt_points[i] + right * randf_range(-jitter_scale, jitter_scale) + perp_up * randf_range(-jitter_scale, jitter_scale)
			var p1 = bolt_points[i + 1] + right * randf_range(-jitter_scale, jitter_scale) + perp_up * randf_range(-jitter_scale, jitter_scale)
			im_glow.surface_add_vertex(p0)
			im_glow.surface_add_vertex(p1)
		im_glow.surface_end()
	glow_mesh.mesh = im_glow

	if _glow_mat == null:
		_glow_mat = StandardMaterial3D.new()
		_glow_mat.albedo_color = Color(0.3, 0.6, 1.0, 0.3)
		_glow_mat.emission_enabled = true
		_glow_mat.emission = Color(0.4, 0.7, 1.0)
		_glow_mat.emission_energy_multiplier = 18.0
		_glow_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_glow_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_glow_mat.no_depth_test = true
	glow_mesh.material_override = _glow_mat
	container.add_child(glow_mesh)

	# -- Main bolt core (bright white-blue, high emission) --
	var line_mesh = MeshInstance3D.new()
	var im = ImmediateMesh.new()
	im.surface_begin(Mesh.PRIMITIVE_LINES)
	im.surface_set_color(Color(0.85, 0.92, 1.0))
	for i in range(bolt_points.size() - 1):
		im.surface_add_vertex(bolt_points[i])
		im.surface_add_vertex(bolt_points[i + 1])
	im.surface_end()
	line_mesh.mesh = im

	if _core_mat == null:
		_core_mat = StandardMaterial3D.new()
		_core_mat.albedo_color = Color(0.9, 0.95, 1.0, 1.0)
		_core_mat.emission_enabled = true
		_core_mat.emission = Color(0.85, 0.93, 1.0)
		_core_mat.emission_energy_multiplier = 24.0
		_core_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_core_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_core_mat.no_depth_test = true
	line_mesh.material_override = _core_mat
	container.add_child(line_mesh)

	# -- Secondary branch bolt (offset fork, vivid blue) --
	var branch_mesh = MeshInstance3D.new()
	var im2 = ImmediateMesh.new()
	im2.surface_begin(Mesh.PRIMITIVE_LINES)
	im2.surface_set_color(Color(0.5, 0.8, 1.0))
	var branch_offset = right * randf_range(0.08, 0.18) + perp_up * randf_range(-0.08, 0.08)
	var branch_segments = 7
	var prev_branch = from + branch_offset
	for i in range(1, branch_segments + 1):
		var t = float(i) / float(branch_segments)
		var point = (from + branch_offset).lerp(to + branch_offset * 0.4, t)
		if i < branch_segments:
			var offset_r = randf_range(-0.18, 0.18)
			var offset_u = randf_range(-0.18, 0.18)
			point += right * offset_r + perp_up * offset_u
		im2.surface_add_vertex(prev_branch)
		im2.surface_add_vertex(point)
		prev_branch = point
	im2.surface_end()
	branch_mesh.mesh = im2

	if _outer_mat == null:
		_outer_mat = StandardMaterial3D.new()
		_outer_mat.albedo_color = Color(0.5, 0.8, 1.0, 0.7)
		_outer_mat.emission_enabled = true
		_outer_mat.emission = Color(0.5, 0.8, 1.0)
		_outer_mat.emission_energy_multiplier = 16.0
		_outer_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_outer_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_outer_mat.no_depth_test = true
	branch_mesh.material_override = _outer_mat
	container.add_child(branch_mesh)

	# -- Impact flash sphere (bright emissive bloom at hit point) --
	var flash = MeshInstance3D.new()
	if _flash_sphere == null:
		_flash_sphere = SphereMesh.new()
		_flash_sphere.radius = 0.25
		_flash_sphere.height = 0.5
		_flash_sphere.radial_segments = 8
		_flash_sphere.rings = 4
		var flash_mat = StandardMaterial3D.new()
		flash_mat.albedo_color = Color(0.7, 0.9, 1.0, 0.6)
		flash_mat.emission_enabled = true
		flash_mat.emission = Color(0.8, 0.95, 1.0)
		flash_mat.emission_energy_multiplier = 28.0
		flash_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		flash_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		flash_mat.no_depth_test = true
		_flash_sphere.material = flash_mat
	flash.mesh = _flash_sphere
	flash.position = to
	container.add_child(flash)

	# -- Spark particles at impact point (end of bolt) — more sparks --
	var sparks = GPUParticles3D.new()
	sparks.amount = 18
	sparks.lifetime = 0.35
	sparks.one_shot = true
	sparks.emitting = true
	sparks.position = to

	if _spark_proc_mat == null:
		_spark_proc_mat = ParticleProcessMaterial.new()
		_spark_proc_mat.direction = Vector3(0, 1, 0)
		_spark_proc_mat.spread = 180.0
		_spark_proc_mat.initial_velocity_min = 2.5
		_spark_proc_mat.initial_velocity_max = 5.0
		_spark_proc_mat.gravity = Vector3(0, -6, 0)
		_spark_proc_mat.scale_min = 0.6
		_spark_proc_mat.scale_max = 1.4
		_spark_proc_mat.color = Color(0.8, 0.95, 1.0)
	sparks.process_material = _spark_proc_mat

	if _spark_mesh == null:
		_spark_mesh = SphereMesh.new()
		_spark_mesh.radius = 0.03
		_spark_mesh.height = 0.06
		if _spark_mat == null:
			_spark_mat = StandardMaterial3D.new()
			_spark_mat.albedo_color = Color(0.9, 0.97, 1.0)
			_spark_mat.emission_enabled = true
			_spark_mat.emission = Color(0.8, 0.95, 1.0)
			_spark_mat.emission_energy_multiplier = 22.0
			_spark_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_spark_mesh.material = _spark_mat
	sparks.draw_pass_1 = _spark_mesh
	container.add_child(sparks)

	get_tree().current_scene.call_deferred("add_child", container)
	chain_visuals.append({"node": container, "timer": 0.35})

func _cleanup_visuals(delta: float) -> void:
	var to_remove: Array = []
	for i in range(chain_visuals.size()):
		chain_visuals[i]["timer"] -= delta
		if chain_visuals[i]["timer"] <= 0:
			if is_instance_valid(chain_visuals[i]["node"]):
				chain_visuals[i]["node"].queue_free()
			to_remove.append(i)
	# Remove in reverse order
	to_remove.reverse()
	for idx in to_remove:
		chain_visuals.remove_at(idx)
