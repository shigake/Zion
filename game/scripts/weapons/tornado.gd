extends Node3D

## Tornado — invoca vortex que orbita o jogador e puxa inimigos proximos (dano de gelo).

var summon_timer: float = 0.0
var _active_tornados: Array = []

func _process(delta: float) -> void:
	if not is_inside_tree():
		return
	if GameManager.paused or GameManager.is_game_over:
		return

	var level = GameManager.get_weapon_level("tornado")
	if level <= 0:
		return

	var w = WeaponDB.get_weapon("tornado")
	var max_summons = w.get("max_summons", 1) + int(w.get("summons_per_level", 0)) * (level - 1)
	var cooldown = WeaponDB.get_cooldown("tornado", level) * GameManager.cooldown_mult

	# Clean up dead tornados
	_active_tornados = _active_tornados.filter(func(t): return is_instance_valid(t))

	summon_timer -= delta
	if summon_timer <= 0 and _active_tornados.size() < max_summons:
		summon_timer = cooldown
		_spawn_tornado(level)

func _get_player_node() -> Node3D:
	var candidate = get_parent().get_parent() if get_parent() else null
	if candidate is CharacterBody3D:
		return candidate
	return null

func _spawn_tornado(level: int) -> void:
	if not is_inside_tree():
		return
	var player = _get_player_node()
	if not player:
		return

	AudioManager.play_sfx("tornado")

	var tornado = TornadoInstance.new()
	tornado.player = player
	tornado.level = level
	tornado.weapon_id = "tornado"

	var w = WeaponDB.get_weapon("tornado")
	tornado.damage = int(WeaponDB.get_damage("tornado", level))
	tornado.orbit_radius = 5.0 + (level - 1) * 0.3
	tornado.area_radius = w.get("base_area", 5.0) + w.get("area_per_level", 0.5) * (level - 1)
	tornado.lifetime = 8.0 + level * 2.0
	tornado.orbit_speed = 2.0 + level * 0.2

	get_tree().current_scene.call_deferred("add_child", tornado)
	_active_tornados.append(tornado)

# --- Inner class for tornado instance ---
class TornadoInstance extends Area3D:
	var player: Node3D = null
	var level: int = 1
	var weapon_id: String = "tornado"
	var damage: int = 6
	var orbit_radius: float = 5.0
	var area_radius: float = 5.0
	var orbit_speed: float = 2.0
	var lifetime: float = 10.0
	var _orbit_angle: float = 0.0
	var _lifetime_timer: float = 0.0
	var _damage_timer: float = 0.0
	var _damage_interval: float = 0.5
	var _pull_strength: float = 3.0
	var _mesh: MeshInstance3D = null
	var _ribbon_mesh: MeshInstance3D = null

	func _ready() -> void:
		add_to_group("player_summons")
		collision_layer = 8  # PlayerAttacks
		collision_mask = 2   # Enemies
		_orbit_angle = randf() * TAU

		# Collision shape
		var shape = CollisionShape3D.new()
		var sphere = SphereShape3D.new()
		sphere.radius = area_radius * GameManager.area_mult
		shape.shape = sphere
		add_child(shape)

		# --- Full 3D procedural vortex (no Sprite3D) ---
		# Layer 1: Main cone — outer vortex
		_mesh = MeshInstance3D.new()
		var cone1 = CylinderMesh.new()
		cone1.top_radius = 0.08
		cone1.bottom_radius = area_radius * 0.6
		cone1.height = 2.2
		cone1.radial_segments = 10
		_mesh.mesh = cone1
		_mesh.position.y = 1.1
		var mat1 = StandardMaterial3D.new()
		mat1.albedo_color = Color(0.5, 0.8, 1.0, 0.28)
		mat1.emission_enabled = true
		mat1.emission = Color(0.4, 0.7, 1.0)
		mat1.emission_energy_multiplier = 2.0
		mat1.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat1.cull_mode = BaseMaterial3D.CULL_DISABLED
		_mesh.material_override = mat1
		add_child(_mesh)

		# Layer 2: Inner ribbon — counter-rotating for spiral illusion
		_ribbon_mesh = MeshInstance3D.new()
		var cone2 = CylinderMesh.new()
		cone2.top_radius = 0.12
		cone2.bottom_radius = area_radius * 0.35
		cone2.height = 1.4
		cone2.radial_segments = 8
		_ribbon_mesh.mesh = cone2
		_ribbon_mesh.position.y = 0.7
		var mat2 = StandardMaterial3D.new()
		mat2.albedo_color = Color(0.6, 0.9, 1.0, 0.18)
		mat2.emission_enabled = true
		mat2.emission = Color(0.55, 0.85, 1.0)
		mat2.emission_energy_multiplier = 1.5
		mat2.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat2.cull_mode = BaseMaterial3D.CULL_DISABLED
		_ribbon_mesh.material_override = mat2
		add_child(_ribbon_mesh)

	func _process(delta: float) -> void:
		if not is_inside_tree():
			return
		if GameManager.paused or GameManager.is_game_over:
			return
		if not is_instance_valid(player):
			queue_free()
			return

		_lifetime_timer += delta
		if _lifetime_timer >= lifetime:
			queue_free()
			return

		# Orbit around player
		_orbit_angle += orbit_speed * delta
		var orbit_pos = player.global_position + Vector3(
			cos(_orbit_angle) * orbit_radius,
			0.5,
			sin(_orbit_angle) * orbit_radius
		)
		global_position = orbit_pos

		# Spin visual: main cone rotates forward, ribbon counter-rotates for vortex illusion
		var pulse = 1.0 + sin(_lifetime_timer * 3.0) * 0.15
		if _mesh:
			_mesh.rotation.y += 12.0 * delta
			_mesh.scale = Vector3(pulse, 1.0 + sin(_lifetime_timer * 2.0) * 0.08, pulse)
		if _ribbon_mesh:
			_ribbon_mesh.rotation.y -= 8.0 * delta
			_ribbon_mesh.scale = Vector3(pulse * 0.9, 1.0 + sin(_lifetime_timer * 2.5) * 0.06, pulse * 0.9)

		# Spawn vortex trail particles
		if Engine.get_frames_per_second() > 35:
			_spawn_vortex_particles()

		# Damage tick
		_damage_timer += delta
		if _damage_timer >= _damage_interval:
			_damage_timer = 0.0
			_deal_damage_and_pull(delta)

	func _deal_damage_and_pull(_delta: float) -> void:
		var bodies = get_overlapping_bodies()
		var hit_count := 0
		for body in bodies:
			if not is_instance_valid(body):
				continue
			if not body.is_in_group("enemies"):
				continue
			if not body.has_method("take_damage"):
				continue

			# Damage
			GameManager._last_attacking_weapon = weapon_id
			body.call_deferred("take_damage", damage, "ice")
			hit_count += 1

			# Pull toward center
			if body is CharacterBody3D or body is RigidBody3D:
				var pull_dir = (global_position - body.global_position).normalized()
				pull_dir.y = 0
				body.global_position += pull_dir * _pull_strength * _damage_interval

			# Ice hit particles on enemy (limit to 3 for performance)
			if hit_count <= 3 and Engine.get_frames_per_second() > 40:
				ParticleFactory.spawn_hit_particles(body.global_position + Vector3(0, 0.5, 0), Color(0.5, 0.85, 1.0), 3)

		# Screen shake if vortex is hitting many enemies
		if hit_count >= 3:
			ScreenEffects.shake(0.08)

	# Shared meshes/materials for vortex particles (avoid creating per frame)
	static var _shared_sphere_mesh: SphereMesh = null
	static var _shared_box_mesh: BoxMesh = null

	func _ensure_shared_meshes() -> void:
		if not _shared_sphere_mesh:
			_shared_sphere_mesh = SphereMesh.new()
			_shared_sphere_mesh.radius = 0.10
			_shared_sphere_mesh.height = 0.20
			var mat = StandardMaterial3D.new()
			mat.albedo_color = Color(0.6, 0.85, 1.0, 0.6)
			mat.emission_enabled = true
			mat.emission = Color(0.5, 0.8, 1.0)
			mat.emission_energy_multiplier = 4.0
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			_shared_sphere_mesh.surface_set_material(0, mat)
		if not _shared_box_mesh:
			_shared_box_mesh = BoxMesh.new()
			_shared_box_mesh.size = Vector3(0.08, 0.08, 0.08)
			var dmat = StandardMaterial3D.new()
			dmat.albedo_color = Color(0.3, 0.25, 0.2, 0.5)
			dmat.emission_enabled = true
			dmat.emission = Color(0.2, 0.15, 0.1)
			dmat.emission_energy_multiplier = 1.0
			dmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			dmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			_shared_box_mesh.surface_set_material(0, dmat)

	func _spawn_vortex_particles() -> void:
		if not is_inside_tree():
			return
		# Reduced spawn rate: every 4 frames instead of 2 (still looks good)
		if Engine.get_process_frames() % 4 != 0:
			return
		var scene = get_tree().current_scene
		if not scene:
			return
		_ensure_shared_meshes()
		# Ice/wind particle spiraling around tornado (shared mesh)
		var particle = MeshInstance3D.new()
		particle.mesh = _shared_sphere_mesh
		scene.add_child(particle)
		var angle = randf() * TAU
		var p_offset = Vector3(cos(angle) * 0.5, randf_range(-0.3, 1.5), sin(angle) * 0.5)
		particle.global_position = global_position + p_offset
		# Spiral outward and upward
		var p_tween = particle.create_tween()
		p_tween.set_parallel(true)
		var end_pos = global_position + Vector3(cos(angle) * 2.0, 2.0, sin(angle) * 2.0)
		p_tween.tween_property(particle, "global_position", end_pos, 0.5)
		p_tween.tween_property(particle, "scale", Vector3(0.1, 0.1, 0.1), 0.5)
		p_tween.chain().tween_callback(particle.queue_free)

		# Secondary debris particle — every 8 frames (shared mesh)
		if Engine.get_process_frames() % 8 == 0:
			var debris = MeshInstance3D.new()
			debris.mesh = _shared_box_mesh
			scene.add_child(debris)
			var d_angle = randf() * TAU
			debris.global_position = global_position + Vector3(cos(d_angle) * 0.3, 0.1, sin(d_angle) * 0.3)
			var dtw = debris.create_tween()
			dtw.set_parallel(true)
			dtw.tween_property(debris, "global_position:y", global_position.y + 2.5, 0.6)
			dtw.tween_property(debris, "rotation", Vector3(randf() * 5.0, randf() * 5.0, randf() * 5.0), 0.6)
			dtw.tween_property(debris, "scale", Vector3(0.01, 0.01, 0.01), 0.6)
			dtw.chain().tween_callback(debris.queue_free)
