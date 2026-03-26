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
	var mesh_inst = MeshInstance3D.new()
	var mesh = CylinderMesh.new()
	mesh.top_radius = portal_radius
	mesh.bottom_radius = portal_radius
	mesh.height = 0.05
	mesh_inst.mesh = mesh
	var mat = StandardMaterial3D.new()
	mat.albedo_color = albedo
	mat.emission_enabled = true
	mat.emission = emission
	mat.emission_energy_multiplier = 2.0
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color.a = 0.7
	mesh_inst.material_override = mat
	return mesh_inst

func _process(delta: float) -> void:
	if GameManager.paused:
		return

	timer += delta
	if timer >= portal_lifetime:
		queue_free()
		return

	# Rotate portal visuals
	if entry_mesh:
		entry_mesh.rotation.y += delta * 2.0
	if exit_mesh:
		exit_mesh.rotation.y -= delta * 2.0

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

	# Check enemies near entry portal
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		var eid = enemy.get_instance_id()
		if eid in teleported_enemies:
			continue
		var dist = entry_mesh.global_position.distance_to(enemy.global_position)
		if dist <= portal_radius:
			# Teleport enemy to exit position with some randomness
			var offset = Vector3(randf_range(-2, 2), 0, randf_range(-2, 2))
			enemy.global_position = exit_position + offset
			teleported_enemies[eid] = teleport_cooldown
			ParticleFactory.spawn_hit_particles(enemy.global_position, Color(0.5, 0.0, 0.8))
