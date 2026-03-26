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
	var line_mesh = MeshInstance3D.new()
	var im = ImmediateMesh.new()
	im.surface_begin(Mesh.PRIMITIVE_LINES)
	im.surface_set_color(Color(0.4, 0.7, 1.0))
	# Main line with zigzag segments
	var segments = 6
	var prev_point = from
	for i in range(1, segments + 1):
		var t = float(i) / float(segments)
		var point = from.lerp(to, t)
		if i < segments:
			# Add random offset for zigzag effect
			point += Vector3(randf_range(-0.3, 0.3), randf_range(-0.2, 0.2), randf_range(-0.3, 0.3))
		im.surface_add_vertex(prev_point)
		im.surface_add_vertex(point)
		prev_point = point
	im.surface_end()
	line_mesh.mesh = im

	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.4, 0.7, 1.0, 0.9)
	mat.emission_enabled = true
	mat.emission = Color(0.3, 0.6, 1.0)
	mat.emission_energy_multiplier = 1.5
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	line_mesh.material_override = mat

	get_tree().current_scene.call_deferred("add_child", line_mesh)
	chain_visuals.append({"node": line_mesh, "timer": 0.15})

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
