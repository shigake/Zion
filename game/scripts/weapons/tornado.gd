extends Node3D

## Tornado — invoca vortex que orbita o jogador e puxa inimigos proximos (dano de gelo).
## Otimizado: GPUParticles3D no lugar de MeshInstance3D per-frame.

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
	var _mesh: Node3D = null
	var _ribbon_mesh: MeshInstance3D = null  # Inner glow cone (always MeshInstance3D)
	var _vortex_particles: GPUParticles3D = null
	var _debris_particles: GPUParticles3D = null

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

		# --- 3D spiral vortex model ---
		# Load imported tornado model (double helix spiral)
		var _tornado_scene_path = "res://assets/models/tornado_vortex.glb"
		if ResourceLoader.exists(_tornado_scene_path):
			var tornado_scene = load(_tornado_scene_path)
			_mesh = tornado_scene.instantiate() as Node3D
			# Scale to match area
			var vortex_scale = area_radius * 0.5
			_mesh.scale = Vector3(vortex_scale, 1.0, vortex_scale)
			# Apply vibrant ice material — semi-transparent glowing spiral
			var mat1 = StandardMaterial3D.new()
			mat1.albedo_color = Color(0.2, 0.9, 1.0, 0.6)
			mat1.emission_enabled = true
			mat1.emission = Color(0.15, 0.85, 1.0)
			mat1.emission_energy_multiplier = 7.0
			mat1.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			mat1.cull_mode = BaseMaterial3D.CULL_DISABLED
			mat1.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			for child in _mesh.get_children():
				if child is MeshInstance3D:
					child.material_override = mat1
				for grandchild in child.get_children():
					if grandchild is MeshInstance3D:
						grandchild.material_override = mat1
			add_child(_mesh)
		else:
			# Fallback: original cone mesh
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

		# Layer 2: Inner glow cone (kept for volumetric fill)
		_ribbon_mesh = MeshInstance3D.new()
		var cone2 = CylinderMesh.new()
		cone2.top_radius = 0.06
		cone2.bottom_radius = area_radius * 0.25
		cone2.height = 1.8
		cone2.radial_segments = 8
		_ribbon_mesh.mesh = cone2
		_ribbon_mesh.position.y = 0.9
		var mat2 = StandardMaterial3D.new()
		mat2.albedo_color = Color(0.6, 0.9, 1.0, 0.12)
		mat2.emission_enabled = true
		mat2.emission = Color(0.55, 0.85, 1.0)
		mat2.emission_energy_multiplier = 1.5
		mat2.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat2.cull_mode = BaseMaterial3D.CULL_DISABLED
		_ribbon_mesh.material_override = mat2
		add_child(_ribbon_mesh)

		# Layer 3: Vortex particles — GPUParticles3D (one-time setup, zero per-frame allocation)
		_vortex_particles = GPUParticles3D.new()
		_vortex_particles.amount = 16
		_vortex_particles.lifetime = 0.6
		_vortex_particles.emitting = true
		_vortex_particles.one_shot = false
		_vortex_particles.explosiveness = 0.0
		_vortex_particles.position.y = 0.5

		var vp_mat = ParticleProcessMaterial.new()
		vp_mat.direction = Vector3(0, 1, 0)
		vp_mat.spread = 180.0
		vp_mat.initial_velocity_min = 1.5
		vp_mat.initial_velocity_max = 3.0
		vp_mat.gravity = Vector3(0, 2.0, 0)
		vp_mat.scale_min = 0.06
		vp_mat.scale_max = 0.14
		vp_mat.color = Color(0.6, 0.85, 1.0, 0.6)
		# Radial velocity for spiral outward effect
		vp_mat.radial_velocity_min = 2.0
		vp_mat.radial_velocity_max = 4.0
		vp_mat.damping_min = 1.0
		vp_mat.damping_max = 2.0
		# Fade out over lifetime via scale curve
		var scale_curve = CurveTexture.new()
		var curve = Curve.new()
		curve.add_point(Vector2(0.0, 1.0))
		curve.add_point(Vector2(0.7, 0.8))
		curve.add_point(Vector2(1.0, 0.0))
		scale_curve.curve = curve
		vp_mat.scale_curve = scale_curve
		_vortex_particles.process_material = vp_mat

		# Draw pass: small unshaded sphere
		var vp_draw = SphereMesh.new()
		vp_draw.radius = 0.10
		vp_draw.height = 0.20
		vp_draw.radial_segments = 4
		vp_draw.rings = 2
		var vp_draw_mat = StandardMaterial3D.new()
		vp_draw_mat.albedo_color = Color(0.6, 0.85, 1.0, 0.6)
		vp_draw_mat.emission_enabled = true
		vp_draw_mat.emission = Color(0.5, 0.8, 1.0)
		vp_draw_mat.emission_energy_multiplier = 6.0
		vp_draw_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		vp_draw_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		vp_draw.surface_set_material(0, vp_draw_mat)
		_vortex_particles.draw_pass_1 = vp_draw
		add_child(_vortex_particles)

		# Layer 4: Debris particles — GPUParticles3D (brownish bits rising)
		_debris_particles = GPUParticles3D.new()
		_debris_particles.amount = 7
		_debris_particles.lifetime = 0.8
		_debris_particles.emitting = true
		_debris_particles.one_shot = false
		_debris_particles.explosiveness = 0.0
		_debris_particles.position.y = 0.2

		var dp_mat = ParticleProcessMaterial.new()
		dp_mat.direction = Vector3(0, 1, 0)
		dp_mat.spread = 120.0
		dp_mat.initial_velocity_min = 1.0
		dp_mat.initial_velocity_max = 2.5
		dp_mat.gravity = Vector3(0, 1.5, 0)
		dp_mat.angular_velocity_min = -220.0
		dp_mat.angular_velocity_max = 220.0
		dp_mat.scale_min = 0.05
		dp_mat.scale_max = 0.12
		dp_mat.color = Color(0.3, 0.25, 0.2, 0.5)
		dp_mat.radial_velocity_min = 0.5
		dp_mat.radial_velocity_max = 2.0
		var dp_scale_curve = CurveTexture.new()
		var dp_curve = Curve.new()
		dp_curve.add_point(Vector2(0.0, 0.8))
		dp_curve.add_point(Vector2(0.5, 1.0))
		dp_curve.add_point(Vector2(1.0, 0.0))
		dp_scale_curve.curve = dp_curve
		dp_mat.scale_curve = dp_scale_curve
		_debris_particles.process_material = dp_mat

		var dp_draw = BoxMesh.new()
		dp_draw.size = Vector3(0.08, 0.08, 0.08)
		var dp_draw_mat = StandardMaterial3D.new()
		dp_draw_mat.albedo_color = Color(0.3, 0.25, 0.2, 0.5)
		dp_draw_mat.emission_enabled = true
		dp_draw_mat.emission = Color(0.2, 0.15, 0.1)
		dp_draw_mat.emission_energy_multiplier = 1.0
		dp_draw_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		dp_draw_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		dp_draw.surface_set_material(0, dp_draw_mat)
		_debris_particles.draw_pass_1 = dp_draw
		add_child(_debris_particles)

		# Layer 5: Ground dust cloud (circular base fog)
		var _dust_cloud = GPUParticles3D.new()
		_dust_cloud.name = "DustCloud"
		_dust_cloud.amount = 10
		_dust_cloud.lifetime = 1.2
		_dust_cloud.emitting = true
		_dust_cloud.one_shot = false
		_dust_cloud.position.y = 0.05
		var dust_mat = ParticleProcessMaterial.new()
		dust_mat.direction = Vector3(0, 0.2, 0)
		dust_mat.spread = 180.0
		dust_mat.initial_velocity_min = 0.5
		dust_mat.initial_velocity_max = 1.5
		dust_mat.gravity = Vector3(0, -0.3, 0)
		dust_mat.scale_min = 0.5
		dust_mat.scale_max = 1.2
		dust_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
		dust_mat.emission_sphere_radius = area_radius * 0.4
		dust_mat.radial_velocity_min = 1.0
		dust_mat.radial_velocity_max = 2.5
		dust_mat.damping_min = 1.0
		dust_mat.damping_max = 3.0
		var dust_color = GradientTexture1D.new()
		var dust_grad = Gradient.new()
		dust_grad.set_color(0, Color(0.5, 0.45, 0.35, 0.3))
		dust_grad.set_color(1, Color(0.4, 0.35, 0.25, 0.0))
		dust_color.gradient = dust_grad
		dust_mat.color_ramp = dust_color
		var dust_scale_c = CurveTexture.new()
		var dsc = Curve.new()
		dsc.add_point(Vector2(0.0, 0.3))
		dsc.add_point(Vector2(0.3, 1.0))
		dsc.add_point(Vector2(1.0, 0.0))
		dust_scale_c.curve = dsc
		dust_mat.scale_curve = dust_scale_c
		_dust_cloud.process_material = dust_mat
		var dust_draw = SphereMesh.new()
		dust_draw.radius = 0.15
		dust_draw.height = 0.12  # Flat spheres — dust puffs
		dust_draw.radial_segments = 5
		dust_draw.rings = 3
		var dust_draw_mat = StandardMaterial3D.new()
		dust_draw_mat.albedo_color = Color(0.45, 0.4, 0.3, 0.3)
		dust_draw_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		dust_draw_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		dust_draw.surface_set_material(0, dust_draw_mat)
		_dust_cloud.draw_pass_1 = dust_draw
		add_child(_dust_cloud)

		# Layer 6: Ice crystal sparkles (diamond-like particles)
		var _ice_sparkles = GPUParticles3D.new()
		_ice_sparkles.name = "IceSparkles"
		_ice_sparkles.amount = 12
		_ice_sparkles.lifetime = 0.6
		_ice_sparkles.emitting = true
		_ice_sparkles.one_shot = false
		_ice_sparkles.position.y = 1.0
		var ice_mat = ParticleProcessMaterial.new()
		ice_mat.direction = Vector3(0, 1, 0)
		ice_mat.spread = 160.0
		ice_mat.initial_velocity_min = 0.8
		ice_mat.initial_velocity_max = 2.0
		ice_mat.gravity = Vector3(0, 0.5, 0)
		ice_mat.scale_min = 0.03
		ice_mat.scale_max = 0.08
		ice_mat.angular_velocity_min = -300.0
		ice_mat.angular_velocity_max = 300.0
		ice_mat.radial_velocity_min = 1.0
		ice_mat.radial_velocity_max = 3.0
		ice_mat.color = Color(0.7, 0.95, 1.0, 0.8)
		_ice_sparkles.process_material = ice_mat
		# Diamond-shaped particle (stretched box)
		var ice_draw = BoxMesh.new()
		ice_draw.size = Vector3(0.04, 0.06, 0.04)
		var ice_draw_mat = StandardMaterial3D.new()
		ice_draw_mat.albedo_color = Color(0.75, 0.95, 1.0, 0.85)
		ice_draw_mat.emission_enabled = true
		ice_draw_mat.emission = Color(0.6, 0.9, 1.0)
		ice_draw_mat.emission_energy_multiplier = 8.0
		ice_draw_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		ice_draw_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		ice_draw.surface_set_material(0, ice_draw_mat)
		_ice_sparkles.draw_pass_1 = ice_draw
		add_child(_ice_sparkles)

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
		if hit_count >= 5:
			ScreenEffects.shake(0.12)
		elif hit_count >= 3:
			ScreenEffects.shake(0.08)
