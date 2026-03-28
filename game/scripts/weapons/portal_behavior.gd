extends Node3D

## Comportamento do portal — teleporta inimigos que tocam o portal de entrada.

var entry_position: Vector3 = Vector3.ZERO
var player_position: Vector3 = Vector3.ZERO
var portal_lifetime: float = 5.0
var teleport_distance: float = 20.0
var portal_radius: float = 2.0
var timer: float = 0.0

var entry_mesh: MeshInstance3D = null
var exit_mesh: MeshInstance3D = null
var exit_position: Vector3 = Vector3.ZERO
var teleported_enemies: Dictionary = {}  # enemy_id -> cooldown
var teleport_cooldown: float = 1.0  # Prevent re-teleporting immediately

func _ready() -> void:
	# Calculate exit position — far from player
	var away_dir = (entry_position - player_position).normalized()
	if away_dir.length() < 0.1:
		away_dir = Vector3(1, 0, 0)
	away_dir.y = 0
	exit_position = player_position + away_dir * teleport_distance

	# Create entry portal visual (purple)
	entry_mesh = _create_portal_mesh(Color(0.5, 0.0, 0.8, 1), Color(0.7, 0.1, 1.0, 1))
	entry_mesh.global_position = entry_position + Vector3(0, 0.1, 0)
	add_child(entry_mesh)

	# Create exit portal visual (dark blue)
	exit_mesh = _create_portal_mesh(Color(0.0, 0.1, 0.5, 1), Color(0.1, 0.2, 0.8, 1))
	exit_mesh.global_position = exit_position + Vector3(0, 0.1, 0)
	add_child(exit_mesh)

func _create_portal_mesh(albedo: Color, emission: Color) -> MeshInstance3D:
	# Container for multi-layer portal
	var container = MeshInstance3D.new()

	# Outer ring (torus)
	var outer_torus = TorusMesh.new()
	outer_torus.inner_radius = portal_radius * 0.5
	outer_torus.outer_radius = portal_radius
	container.mesh = outer_torus
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(albedo.r, albedo.g, albedo.b, 0.7)
	mat.emission_enabled = true
	mat.emission = emission
	mat.emission_energy_multiplier = 3.0
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	container.material_override = mat
	container.rotation.x = PI / 2.0

	# Inner ring (smaller torus, child of container)
	var inner_ring = MeshInstance3D.new()
	var inner_torus = TorusMesh.new()
	inner_torus.inner_radius = portal_radius * 0.2
	inner_torus.outer_radius = portal_radius * 0.5
	inner_ring.mesh = inner_torus
	var inner_mat = StandardMaterial3D.new()
	inner_mat.albedo_color = Color(albedo.r * 1.3, albedo.g * 0.5, albedo.b * 1.2, 0.6)
	inner_mat.emission_enabled = true
	inner_mat.emission = Color(emission.r * 1.2, emission.g * 0.8, emission.b * 1.1)
	inner_mat.emission_energy_multiplier = 2.5
	inner_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	inner_ring.material_override = inner_mat
	inner_ring.set_meta("inner_ring", true)
	container.add_child(inner_ring)

	# Center void sphere
	var void_sphere_inst = MeshInstance3D.new()
	var void_sphere = SphereMesh.new()
	void_sphere.radius = portal_radius * 0.15
	void_sphere.height = portal_radius * 0.3
	void_sphere_inst.mesh = void_sphere
	var void_mat = StandardMaterial3D.new()
	void_mat.albedo_color = Color(0.05, 0.0, 0.1, 0.9)
	void_mat.emission_enabled = true
	void_mat.emission = Color(0.2, 0.0, 0.5)
	void_mat.emission_energy_multiplier = 1.0
	void_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	void_sphere_inst.material_override = void_mat
	container.add_child(void_sphere_inst)

	# Suction particles
	var suction = GPUParticles3D.new()
	suction.amount = 8
	suction.lifetime = 0.6
	suction.emitting = true
	suction.one_shot = false
	var s_mat = ParticleProcessMaterial.new()
	s_mat.direction = Vector3(0, 0, 0)
	s_mat.spread = 180.0
	s_mat.initial_velocity_min = -2.0
	s_mat.initial_velocity_max = -1.0
	s_mat.gravity = Vector3(0, 0, 0)
	s_mat.scale_min = 0.2
	s_mat.scale_max = 0.5
	s_mat.color = Color(emission.r, emission.g, emission.b, 0.7)
	s_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	s_mat.emission_sphere_radius = portal_radius
	suction.process_material = s_mat
	var dot_mesh = SphereMesh.new()
	dot_mesh.radius = 0.02
	dot_mesh.height = 0.04
	var dot_mat = StandardMaterial3D.new()
	dot_mat.albedo_color = Color(emission.r, emission.g, emission.b, 0.8)
	dot_mat.emission_enabled = true
	dot_mat.emission = emission
	dot_mat.emission_energy_multiplier = 4.0
	dot_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	dot_mesh.surface_set_material(0, dot_mat)
	suction.draw_pass_1 = dot_mesh
	container.add_child(suction)

	return container

func _process(delta: float) -> void:
	if GameManager.paused:
		return

	timer += delta
	if timer >= portal_lifetime:
		queue_free()
		return

	# Rotate portal visuals (outer ring rotates with parent)
	if entry_mesh:
		entry_mesh.rotation.y += delta * 2.0
		# Inner ring rotates opposite direction
		for child in entry_mesh.get_children():
			if child is MeshInstance3D and child.has_meta("inner_ring"):
				child.rotation.y -= delta * 5.0  # Net -3.0 relative since parent adds 2.0
	if exit_mesh:
		exit_mesh.rotation.y -= delta * 2.0
		for child in exit_mesh.get_children():
			if child is MeshInstance3D and child.has_meta("inner_ring"):
				child.rotation.y += delta * 5.0

	# Fade out near end of lifetime
	var remaining = portal_lifetime - timer
	if remaining < 1.0:
		var alpha = remaining
		if entry_mesh and entry_mesh.material_override:
			entry_mesh.material_override.albedo_color.a = alpha * 0.7
		if exit_mesh and exit_mesh.material_override:
			exit_mesh.material_override.albedo_color.a = alpha * 0.7

	# Update teleport cooldowns
	var to_remove: Array = []
	for key in teleported_enemies:
		teleported_enemies[key] -= delta
		if teleported_enemies[key] <= 0:
			to_remove.append(key)
	for key in to_remove:
		teleported_enemies.erase(key)

	# Check enemies near entry portal (spatial grid: O(1))
	var nearby = GameManager.get_enemies_in_radius(entry_mesh.global_position, portal_radius)
	for enemy in nearby:
		if not is_instance_valid(enemy):
			continue
		var eid = enemy.get_instance_id()
		if eid in teleported_enemies:
			continue
		if true:
			# Teleport enemy to exit position with some randomness
			var offset = Vector3(randf_range(-2, 2), 0, randf_range(-2, 2))
			enemy.global_position = exit_position + offset
			teleported_enemies[eid] = teleport_cooldown
			ParticleFactory.spawn_hit_particles(enemy.global_position, Color(0.5, 0.0, 0.8))
