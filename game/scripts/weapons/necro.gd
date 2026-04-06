extends Node3D

## Necromante — invoca esqueletos que perseguem e atacam inimigos.

var summon_timer: float = 0.0
var skeleton_scene: PackedScene = preload("res://scenes/weapons/skeleton_summon.tscn")

func _process(delta: float) -> void:
	if not is_inside_tree():
		return
	if GameManager.paused or GameManager.is_game_over:
		return

	var level = GameManager.get_weapon_level("necro")
	if level <= 0:
		return

	var cooldown = WeaponDB.get_cooldown("necro", level) * GameManager.cooldown_mult
	var max_summons = 2 + (level - 1)

	summon_timer -= delta
	if summon_timer <= 0:
		# Only count summons when we might actually spawn (avoids O(n) scan every frame)
		var current_summons = get_tree().get_nodes_in_group("player_summons").size()
		if current_summons < max_summons:
			summon_timer = cooldown
			_summon(level)
		else:
			summon_timer = 0.5  # Retry in 0.5s instead of next frame

func _get_player_node() -> Node3D:
	var candidate = get_parent().get_parent() if get_parent() else null
	if candidate is CharacterBody3D:
		return candidate
	return null

func _summon(level: int) -> void:
	if not is_inside_tree():
		return
	var player = _get_player_node()
	if not player:
		return
	var player_pos = player.global_position
	var offset = Vector3(randf_range(-2, 2), 0, randf_range(-2, 2))

	var scene_root = get_tree().current_scene
	if not is_instance_valid(scene_root):
		return
	var skeleton = ObjectPool.get_instance(skeleton_scene)
	skeleton.damage = int(WeaponDB.get_damage("necro", level))
	skeleton.lifetime = 8.0 + level * 2.0
	scene_root.add_child(skeleton)
	skeleton.global_position = player_pos + offset
	AudioManager.play_sfx("summon_pop")
	# Green summon circle
	_spawn_summon_circle(player_pos + offset)

func _spawn_summon_circle(pos: Vector3) -> void:
	if not is_inside_tree():
		return
	var scene_root = get_tree().current_scene
	if not is_instance_valid(scene_root):
		return
	# Container node for circle + particles
	var container = Node3D.new()
	scene_root.add_child(container)
	container.global_position = pos

	# Dark summoning circle disc
	var circle = MeshInstance3D.new()
	var disc = CylinderMesh.new()
	disc.top_radius = 1.0
	disc.bottom_radius = 1.0
	disc.height = 0.05
	circle.mesh = disc
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.15, 0.4, 0.2, 0.7)
	mat.emission_enabled = true
	mat.emission = Color(0.1, 0.8, 0.3)
	mat.emission_energy_multiplier = 2.0
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	circle.material_override = mat
	container.add_child(circle)

	# Rising soul particles (green/purple wisps)
	var soul_particles = GPUParticles3D.new()
	soul_particles.amount = 6
	soul_particles.lifetime = 1.0
	soul_particles.emitting = true
	soul_particles.one_shot = false
	var soul_mat = ParticleProcessMaterial.new()
	soul_mat.direction = Vector3(0, 1, 0)
	soul_mat.spread = 40.0
	soul_mat.initial_velocity_min = 0.5
	soul_mat.initial_velocity_max = 1.5
	soul_mat.gravity = Vector3(0, 0.5, 0)
	soul_mat.scale_min = 0.3
	soul_mat.scale_max = 0.8
	soul_mat.color = Color(0.2, 0.9, 0.4, 0.6)
	soul_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
	soul_mat.emission_ring_radius = 0.8
	soul_mat.emission_ring_inner_radius = 0.2
	soul_mat.emission_ring_height = 0.05
	soul_mat.emission_ring_axis = Vector3(0, 1, 0)
	soul_particles.process_material = soul_mat
	# Draw pass: small green/purple wisp sphere
	var wisp_mesh = SphereMesh.new()
	wisp_mesh.radius = 0.04
	wisp_mesh.height = 0.08
	var wisp_mat = StandardMaterial3D.new()
	wisp_mat.albedo_color = Color(0.15, 0.6, 0.3, 0.5)
	wisp_mat.emission_enabled = true
	wisp_mat.emission = Color(0.1, 0.8, 0.3)
	wisp_mat.emission_energy_multiplier = 3.0
	wisp_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	wisp_mesh.surface_set_material(0, wisp_mat)
	soul_particles.draw_pass_1 = wisp_mesh
	container.add_child(soul_particles)

	# Rotation + fade out animation
	var tween = container.create_tween()
	tween.set_parallel(true)
	# Rotate circle (PI/4 rad/s over ~1.5s total lifetime)
	tween.tween_property(circle, "rotation:y", PI / 4.0 * 1.5, 1.5)
	# Fade out the disc
	tween.tween_property(mat, "albedo_color:a", 0.0, 1.5)
	# Fade emission too
	tween.tween_property(mat, "emission_energy_multiplier", 0.0, 1.5)
	tween.set_parallel(false)
	tween.tween_callback(container.queue_free)
