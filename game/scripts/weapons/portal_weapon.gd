extends Node3D

## Portal — abre portal em cluster de inimigos, teleportando-os para longe.

var attack_timer: float = 0.0
const CLUSTER_MIN_ENEMIES: int = 3
const CLUSTER_RADIUS: float = 3.0
const TELEPORT_DISTANCE: float = 20.0
const PORTAL_DAMAGE: int = 5

func _process(delta: float) -> void:
	if GameManager.paused or GameManager.is_game_over:
		return

	var level = GameManager.get_weapon_level("portal_weapon")
	if level <= 0:
		return

	var cooldown = WeaponDB.get_cooldown("portal_weapon", level) / GameManager.attack_speed_mult

	attack_timer -= delta
	if attack_timer <= 0:
		attack_timer = cooldown
		_try_open_portal(level)

func _try_open_portal(level: int) -> void:
	var enemies = get_tree().get_nodes_in_group("enemies")
	if enemies.size() < CLUSTER_MIN_ENEMIES:
		return

	# Encontra o melhor cluster
	var best_center: Vector3 = Vector3.ZERO
	var best_cluster: Array = []
	var cluster_radius_sq = CLUSTER_RADIUS * CLUSTER_RADIUS

	for e in enemies:
		if not is_instance_valid(e):
			continue
		var center = e.global_position
		var cluster: Array = []
		for other in enemies:
			if not is_instance_valid(other):
				continue
			if center.distance_squared_to(other.global_position) <= cluster_radius_sq:
				cluster.append(other)
		if cluster.size() > best_cluster.size():
			best_cluster = cluster
			best_center = center

	if best_cluster.size() < CLUSTER_MIN_ENEMIES:
		return

	# Dano por level
	var dmg = int(WeaponDB.get_damage("portal_weapon", level))

	# Teleporta os inimigos do cluster
	var random_angle = randf() * TAU
	var teleport_dir = Vector3(cos(random_angle), 0, sin(random_angle))

	for enemy in best_cluster:
		if not is_instance_valid(enemy):
			continue
		if enemy.has_method("take_damage"):
			enemy.call_deferred("take_damage", dmg, "dark")
		# Teleporta
		var offset = Vector3(randf_range(-2, 2), 0, randf_range(-2, 2))
		enemy.global_position = enemy.global_position + teleport_dir * TELEPORT_DISTANCE + offset

	# Efeitos visuais no local do portal
	_spawn_portal_effect(best_center)
	AudioManager.play_sfx("hit")

func _spawn_portal_effect(pos: Vector3) -> void:
	ParticleFactory.spawn_hit_particles(pos, Color(0.4, 0.0, 0.8))
	ParticleFactory.spawn_hit_particles(pos + Vector3(0, 1, 0), Color(0.6, 0.1, 1.0))

	# Portal visual temporario
	var portal = MeshInstance3D.new()
	var torus = TorusMesh.new()
	torus.inner_radius = 0.8
	torus.outer_radius = 1.5
	portal.mesh = torus
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.5, 0.0, 1.0, 0.7)
	mat.emission_enabled = true
	mat.emission = Color(0.6, 0.1, 1.0)
	mat.emission_energy_multiplier = 3.0
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	portal.material_override = mat
	portal.global_position = pos + Vector3(0, 0.5, 0)
	portal.rotation.x = PI / 2.0
	get_tree().current_scene.call_deferred("add_child", portal)

	# Fade out e remove
	var tween = portal.create_tween()
	tween.tween_property(mat, "albedo_color:a", 0.0, 1.0)
	tween.tween_callback(portal.queue_free)
