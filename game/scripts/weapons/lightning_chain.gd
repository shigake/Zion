extends Node3D

## Relampago em Cadeia — atinge o inimigo mais proximo e encadeia para vizinhos.

var attack_timer: float = 0.0
var chain_visuals: Array = []

func _process(delta: float) -> void:
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

func _cast(level: int) -> void:
	var enemies = get_tree().get_nodes_in_group("enemies")
	if enemies.is_empty():
		return

	var player_pos = get_parent().get_parent().global_position

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

		current_target.call_deferred("take_damage", current_damage, "electric")
		hit_targets.append(current_target)
		ParticleFactory.spawn_hit_particles(current_target.global_position + Vector3(0, 0.5, 0), Color(0.3, 0.7, 1.0))

		# Draw lightning line from previous to current
		if hit_targets.size() >= 2:
			var prev = hit_targets[hit_targets.size() - 2]
			_draw_lightning(prev.global_position + Vector3(0, 0.5, 0), current_target.global_position + Vector3(0, 0.5, 0))
		elif hit_targets.size() == 1:
			_draw_lightning(player_pos + Vector3(0, 0.8, 0), current_target.global_position + Vector3(0, 0.5, 0))

		# Reduce damage for next chain
		current_damage = int(current_damage * 0.7)

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

	AudioManager.play_sfx("hit")

func _draw_lightning(from: Vector3, to: Vector3) -> void:
	var container = Node3D.new()

	# -- Compute perpendicular axes for zigzag offsets --
	var forward = (to - from).normalized()
	var up = Vector3.UP
	if abs(forward.dot(up)) > 0.9:
		up = Vector3.RIGHT
	var right = forward.cross(up).normalized()
	var perp_up = right.cross(forward).normalized()

	# -- Main bolt (thick, white-blue) --
	var line_mesh = MeshInstance3D.new()
	var im = ImmediateMesh.new()
	im.surface_begin(Mesh.PRIMITIVE_LINES)
	im.surface_set_color(Color(0.8, 0.9, 1.0))
	var segments = 8
	var prev_point = from
	for i in range(1, segments + 1):
		var t = float(i) / float(segments)
		var point = from.lerp(to, t)
		if i < segments:
			var offset_r = randf_range(-0.15, 0.15)
			var offset_u = randf_range(-0.15, 0.15)
			point += right * offset_r + perp_up * offset_u
		im.surface_add_vertex(prev_point)
		im.surface_add_vertex(point)
		prev_point = point
	im.surface_end()
	line_mesh.mesh = im

	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.8, 0.9, 1.0, 1.0)
	mat.emission_enabled = true
	mat.emission = Color(0.8, 0.9, 1.0)
	mat.emission_energy_multiplier = 5.0
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	line_mesh.material_override = mat
	container.add_child(line_mesh)

	# -- Secondary branch bolt (thinner, offset, dimmer) --
	var branch_mesh = MeshInstance3D.new()
	var im2 = ImmediateMesh.new()
	im2.surface_begin(Mesh.PRIMITIVE_LINES)
	im2.surface_set_color(Color(0.6, 0.8, 1.0))
	var branch_offset = right * randf_range(0.05, 0.1) + perp_up * randf_range(-0.05, 0.05)
	var branch_segments = 6
	var prev_branch = from + branch_offset
	for i in range(1, branch_segments + 1):
		var t = float(i) / float(branch_segments)
		var point = (from + branch_offset).lerp(to + branch_offset * 0.5, t)
		if i < branch_segments:
			var offset_r = randf_range(-0.1, 0.1)
			var offset_u = randf_range(-0.1, 0.1)
			point += right * offset_r + perp_up * offset_u
		im2.surface_add_vertex(prev_branch)
		im2.surface_add_vertex(point)
		prev_branch = point
	im2.surface_end()
	branch_mesh.mesh = im2

	var mat2 = StandardMaterial3D.new()
	mat2.albedo_color = Color(0.6, 0.8, 1.0, 0.6)
	mat2.emission_enabled = true
	mat2.emission = Color(0.6, 0.8, 1.0)
	mat2.emission_energy_multiplier = 3.0
	mat2.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat2.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	branch_mesh.material_override = mat2
	container.add_child(branch_mesh)

	# -- Spark particles at impact point (end of bolt) --
	var sparks = GPUParticles3D.new()
	sparks.amount = 6
	sparks.lifetime = 0.2
	sparks.one_shot = true
	sparks.emitting = true
	sparks.position = to

	var spark_mat = ParticleProcessMaterial.new()
	spark_mat.direction = Vector3(0, 1, 0)
	spark_mat.spread = 180.0
	spark_mat.initial_velocity_min = 1.5
	spark_mat.initial_velocity_max = 3.0
	spark_mat.gravity = Vector3(0, -5, 0)
	spark_mat.scale_min = 0.5
	spark_mat.scale_max = 1.0
	spark_mat.color = Color(1.0, 0.95, 0.5)
	sparks.process_material = spark_mat

	var spark_sphere = SphereMesh.new()
	spark_sphere.radius = 0.02
	spark_sphere.height = 0.04
	var spark_mesh_mat = StandardMaterial3D.new()
	spark_mesh_mat.albedo_color = Color(1.0, 1.0, 0.7)
	spark_mesh_mat.emission_enabled = true
	spark_mesh_mat.emission = Color(1.0, 0.95, 0.5)
	spark_mesh_mat.emission_energy_multiplier = 4.0
	spark_mesh_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	spark_sphere.material = spark_mesh_mat
	sparks.draw_pass_1 = spark_sphere
	container.add_child(sparks)

	get_tree().current_scene.call_deferred("add_child", container)
	chain_visuals.append({"node": container, "timer": 0.2})

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
