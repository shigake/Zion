extends Node3D

## Chicote Eletrico — atinge o inimigo mais proximo e encadeia para vizinhos.

var attack_timer: float = 0.0
var chain_visuals: Array = []

func _process(delta: float) -> void:
	if not is_inside_tree():
		return
	if GameManager.paused or GameManager.is_game_over:
		return

	var level = GameManager.get_weapon_level("chain_whip")
	if level <= 0:
		return

	# Clean up expired chain visuals
	_cleanup_visuals(delta)

	var cooldown = WeaponDB.get_cooldown("chain_whip", level) / GameManager.attack_speed_mult * GameManager.cooldown_mult
	attack_timer -= delta
	if attack_timer <= 0:
		attack_timer = cooldown
		_attack(level)

func _get_player_node() -> Node3D:
	var candidate = get_parent().get_parent() if get_parent() else null
	if candidate is CharacterBody3D:
		return candidate
	return null

func _attack(level: int) -> void:
	if not is_inside_tree():
		return
	var enemies = GameManager.get_enemies()
	if enemies.is_empty():
		return

	if not is_inside_tree():
		return
	var player = _get_player_node()
	if not player or not is_instance_valid(player):
		return
	var player_pos = player.global_position

	var base_area = WeaponDB.weapons.get("chain_whip", {}).get("base_area", 3.5)
	var area_per_lvl = WeaponDB.weapons.get("chain_whip", {}).get("area_per_level", 0.3)
	var area = (base_area + area_per_lvl * (level - 1)) * GameManager.area_mult
	var chain_range = 4.0 + level * 0.3

	# Find nearest enemy within melee area range
	var nearest: Node3D = null
	if GameManager.manual_aim:
		var best_dot = -1.0
		for e in enemies:
			if not is_instance_valid(e):
				continue
			var dist = player_pos.distance_to(e.global_position)
			if dist > area:
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
			var d = player_pos.distance_to(e.global_position)
			if d > area:
				continue
			if d < min_dist:
				min_dist = d
				nearest = e

	if nearest == null:
		return

	var base_damage = int(WeaponDB.get_damage("chain_whip", level))
	var max_chains = 2 + int(level / 2)  # 2 base, +1 per 2 levels

	# Chain attack
	var hit_targets: Array = []
	var current_target = nearest
	var current_damage = base_damage

	for i in range(max_chains + 1):  # +1 for initial target
		if current_target == null or not is_instance_valid(current_target):
			break
		if not current_target.has_method("take_damage"):
			break

		GameManager._last_attacking_weapon = "chain_whip"
		current_target.call_deferred("take_damage", current_damage, "electric")
		hit_targets.append(current_target)
		ParticleFactory.spawn_hit_particles(current_target.global_position + Vector3(0, 0.5, 0), Color(0.6, 0.9, 1.0))
		# Impact flash/glow at hit point
		_spawn_impact_flash(current_target.global_position + Vector3(0, 0.5, 0))

		# Draw chain line from previous to current
		if hit_targets.size() >= 2:
			var prev = hit_targets[hit_targets.size() - 2]
			_draw_chain(prev.global_position + Vector3(0, 0.5, 0), current_target.global_position + Vector3(0, 0.5, 0))
		elif hit_targets.size() == 1:
			_draw_chain(player_pos + Vector3(0, 0.8, 0), current_target.global_position + Vector3(0, 0.5, 0))

		# Reduce damage for next chain (80% falloff)
		current_damage = int(current_damage * 0.8)

		# Find next nearest enemy not already hit within chain range
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

	AudioManager.play_sfx("chain_whip")
	AudioManager.play_sfx("hit")
	# Spawn electric sparks at first hit
	if not hit_targets.is_empty():
		_spawn_electric_burst(hit_targets[0].global_position + Vector3(0, 0.5, 0))

func _draw_chain(from: Vector3, to: Vector3) -> void:
	var container = Node3D.new()

	var forward = (to - from).normalized()
	var up = Vector3.UP
	if abs(forward.dot(up)) > 0.9:
		up = Vector3.RIGHT
	var right = forward.cross(up).normalized()
	var perp_up = right.cross(forward).normalized()

	# Zigzag whip segments
	var segments = 8
	var whip_points: Array = [from]
	for i in range(1, segments + 1):
		var t = float(i) / float(segments)
		var point = from.lerp(to, t)
		if i < segments:
			var offset_r = randf_range(-0.15, 0.15)
			var offset_u = randf_range(-0.15, 0.15)
			point += right * offset_r + perp_up * offset_u
		whip_points.append(point)

	# Electric glow pass
	var glow_mesh = MeshInstance3D.new()
	var im_glow = ImmediateMesh.new()
	im_glow.surface_begin(Mesh.PRIMITIVE_LINES)
	im_glow.surface_set_color(Color(0.4, 0.7, 1.0, 0.3))
	for i in range(whip_points.size() - 1):
		im_glow.surface_add_vertex(whip_points[i])
		im_glow.surface_add_vertex(whip_points[i + 1])
	im_glow.surface_end()
	glow_mesh.mesh = im_glow

	var glow_mat = StandardMaterial3D.new()
	glow_mat.albedo_color = Color(0.4, 0.7, 1.0, 0.4)
	glow_mat.emission_enabled = true
	glow_mat.emission = Color(0.5, 0.8, 1.0)
	glow_mat.emission_energy_multiplier = 10.0
	glow_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	glow_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glow_mat.no_depth_test = true
	glow_mesh.material_override = glow_mat
	container.add_child(glow_mesh)

	# Core whip line (bright white-yellow electric)
	var line_mesh = MeshInstance3D.new()
	var im = ImmediateMesh.new()
	im.surface_begin(Mesh.PRIMITIVE_LINES)
	im.surface_set_color(Color(1.0, 0.95, 0.7))
	for i in range(whip_points.size() - 1):
		im.surface_add_vertex(whip_points[i])
		im.surface_add_vertex(whip_points[i + 1])
	im.surface_end()
	line_mesh.mesh = im

	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.95, 0.8, 1.0)
	mat.emission_enabled = true
	mat.emission = Color(0.9, 0.85, 0.5)
	mat.emission_energy_multiplier = 14.0
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.no_depth_test = true
	line_mesh.material_override = mat
	container.add_child(line_mesh)

	# Spark at hit point
	var flash = MeshInstance3D.new()
	var flash_sphere = SphereMesh.new()
	flash_sphere.radius = 0.2
	flash_sphere.height = 0.4
	var flash_mat = StandardMaterial3D.new()
	flash_mat.albedo_color = Color(0.8, 0.9, 1.0, 0.5)
	flash_mat.emission_enabled = true
	flash_mat.emission = Color(0.7, 0.9, 1.0)
	flash_mat.emission_energy_multiplier = 16.0
	flash_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	flash_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	flash_mat.no_depth_test = true
	flash_sphere.material = flash_mat
	flash.mesh = flash_sphere
	flash.position = to
	container.add_child(flash)

	get_tree().current_scene.call_deferred("add_child", container)
	chain_visuals.append({"node": container, "timer": 0.2})

func _spawn_electric_burst(pos: Vector3) -> void:
	if Engine.get_frames_per_second() < 30:
		return
	var scene = get_tree().current_scene
	if not scene:
		return
	# Spawn 4-6 small electric sparks radiating outward
	var spark_count = randi_range(4, 6)
	for i in range(spark_count):
		var spark = MeshInstance3D.new()
		var sphere = SphereMesh.new()
		sphere.radius = 0.04
		sphere.height = 0.08
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(0.7, 0.9, 1.0, 0.8)
		mat.emission_enabled = true
		mat.emission = Color(0.6, 0.85, 1.0)
		mat.emission_energy_multiplier = 12.0
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		sphere.surface_set_material(0, mat)
		spark.mesh = sphere
		scene.add_child(spark)
		spark.global_position = pos
		# Random direction
		var dir = Vector3(randf_range(-1, 1), randf_range(0, 1), randf_range(-1, 1)).normalized()
		var end_pos = pos + dir * randf_range(0.3, 0.8)
		var tween = spark.create_tween()
		tween.set_parallel(true)
		tween.tween_property(spark, "global_position", end_pos, 0.15)
		tween.tween_property(spark, "scale", Vector3(0.01, 0.01, 0.01), 0.2)
		tween.chain().tween_callback(spark.queue_free)

func _spawn_impact_flash(pos: Vector3) -> void:
	var scene = get_tree().current_scene
	if not scene:
		return
	# Bright white-blue flash sphere that scales up and fades fast
	var flash = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 0.1
	sphere.height = 0.2
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.9, 0.95, 1.0, 0.9)
	mat.emission_enabled = true
	mat.emission = Color(0.7, 0.9, 1.0)
	mat.emission_energy_multiplier = 20.0
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.no_depth_test = true
	sphere.surface_set_material(0, mat)
	flash.mesh = sphere
	scene.add_child(flash)
	flash.global_position = pos
	# Quick scale-up then fade out
	var tween = flash.create_tween()
	tween.set_parallel(true)
	tween.tween_property(flash, "scale", Vector3(3.0, 3.0, 3.0), 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(flash, "scale", Vector3(0.01, 0.01, 0.01), 0.12).set_delay(0.08)
	tween.chain().tween_callback(flash.queue_free)

func _cleanup_visuals(delta: float) -> void:
	var to_remove: Array = []
	for i in range(chain_visuals.size()):
		chain_visuals[i]["timer"] -= delta
		if chain_visuals[i]["timer"] <= 0:
			if is_instance_valid(chain_visuals[i]["node"]):
				chain_visuals[i]["node"].queue_free()
			to_remove.append(i)
	to_remove.reverse()
	for idx in to_remove:
		chain_visuals.remove_at(idx)
