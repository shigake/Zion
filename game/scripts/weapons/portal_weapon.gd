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
	var enemies = GameManager.get_enemies()
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

	# Container for multi-layer portal
	var container = Node3D.new()
	get_tree().current_scene.call_deferred("add_child", container)
	container.position = pos + Vector3(0, 0.5, 0)

	# --- Outer ring ---
	var outer_ring = MeshInstance3D.new()
	var outer_torus = TorusMesh.new()
	outer_torus.inner_radius = 0.8
	outer_torus.outer_radius = 1.5
	outer_ring.mesh = outer_torus
	var outer_mat = StandardMaterial3D.new()
	outer_mat.albedo_color = Color(0.5, 0.0, 1.0, 0.7)
	outer_mat.emission_enabled = true
	outer_mat.emission = Color(0.6, 0.1, 1.0)
	outer_mat.emission_energy_multiplier = 3.0
	outer_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	outer_ring.material_override = outer_mat
	outer_ring.rotation.x = PI / 2.0
	container.add_child(outer_ring)

	# --- Inner ring (opposite rotation, slightly different purple) ---
	var inner_ring = MeshInstance3D.new()
	var inner_torus = TorusMesh.new()
	inner_torus.inner_radius = 0.4
	inner_torus.outer_radius = 0.8
	inner_ring.mesh = inner_torus
	var inner_mat = StandardMaterial3D.new()
	inner_mat.albedo_color = Color(0.7, 0.0, 0.9, 0.6)
	inner_mat.emission_enabled = true
	inner_mat.emission = Color(0.8, 0.2, 1.0)
	inner_mat.emission_energy_multiplier = 2.5
	inner_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	inner_ring.material_override = inner_mat
	inner_ring.rotation.x = PI / 2.0
	container.add_child(inner_ring)

	# --- Center void (dark sphere "black hole") ---
	var void_center = MeshInstance3D.new()
	var void_sphere = SphereMesh.new()
	void_sphere.radius = 0.3
	void_sphere.height = 0.6
	void_center.mesh = void_sphere
	var void_mat = StandardMaterial3D.new()
	void_mat.albedo_color = Color(0.05, 0.0, 0.1, 0.9)
	void_mat.emission_enabled = true
	void_mat.emission = Color(0.2, 0.0, 0.5)
	void_mat.emission_energy_multiplier = 1.0
	void_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	void_center.material_override = void_mat
	container.add_child(void_center)

	# --- Suction particles (moving toward center) ---
	var suction_particles = GPUParticles3D.new()
	suction_particles.amount = 8
	suction_particles.lifetime = 0.6
	suction_particles.emitting = true
	suction_particles.one_shot = false
	var suction_mat = ParticleProcessMaterial.new()
	suction_mat.direction = Vector3(0, 0, 0)
	suction_mat.spread = 180.0
	suction_mat.initial_velocity_min = -3.0
	suction_mat.initial_velocity_max = -1.5
	suction_mat.gravity = Vector3(0, 0, 0)
	suction_mat.scale_min = 0.2
	suction_mat.scale_max = 0.5
	suction_mat.color = Color(0.7, 0.2, 1.0, 0.8)
	suction_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	suction_mat.emission_sphere_radius = 1.5
	suction_mat.attractor_interaction_enabled = true
	suction_particles.process_material = suction_mat
	# Draw pass: bright purple dots
	var dot_mesh = SphereMesh.new()
	dot_mesh.radius = 0.02
	dot_mesh.height = 0.04
	var dot_mat = StandardMaterial3D.new()
	dot_mat.albedo_color = Color(0.8, 0.3, 1.0, 0.8)
	dot_mat.emission_enabled = true
	dot_mat.emission = Color(0.7, 0.2, 1.0)
	dot_mat.emission_energy_multiplier = 4.0
	dot_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	dot_mesh.surface_set_material(0, dot_mat)
	suction_particles.draw_pass_1 = dot_mesh
	container.add_child(suction_particles)

	# --- Animate rotations + fade out ---
	# Store references for the rotation script
	container.set_meta("outer_ring", outer_ring)
	container.set_meta("inner_ring", inner_ring)
	container.set_meta("outer_mat", outer_mat)
	container.set_meta("inner_mat", inner_mat)
	container.set_meta("void_mat", void_mat)
	container.set_meta("elapsed", 0.0)

	var script = GDScript.new()
	script.source_code = _get_portal_anim_script()
	script.reload()
	container.set_script(script)

func _get_portal_anim_script() -> String:
	return """extends Node3D

const PORTAL_DURATION := 1.5

var elapsed: float = 0.0

func _process(delta: float) -> void:
	elapsed += delta

	# Rotate outer ring (2.0 rad/s)
	var outer = get_meta("outer_ring") as MeshInstance3D
	if outer and is_instance_valid(outer):
		outer.rotation.y += delta * 2.0

	# Rotate inner ring opposite (-3.0 rad/s)
	var inner = get_meta("inner_ring") as MeshInstance3D
	if inner and is_instance_valid(inner):
		inner.rotation.y -= delta * 3.0

	# Fade out near end
	if elapsed > PORTAL_DURATION - 0.5:
		var fade = (PORTAL_DURATION - elapsed) / 0.5
		fade = clamp(fade, 0.0, 1.0)

		var o_mat = get_meta("outer_mat") as StandardMaterial3D
		if o_mat:
			o_mat.albedo_color.a = 0.7 * fade
		var i_mat = get_meta("inner_mat") as StandardMaterial3D
		if i_mat:
			i_mat.albedo_color.a = 0.6 * fade
		var v_mat = get_meta("void_mat") as StandardMaterial3D
		if v_mat:
			v_mat.albedo_color.a = 0.9 * fade

	if elapsed >= PORTAL_DURATION:
		queue_free()
"""
