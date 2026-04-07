extends Node3D

## Orbe de Sangue — invoca orbe que drena vida dos inimigos e cura o jogador.
## Otimizado: shared static meshes para todos efeitos visuais (zero alocacao per-frame).

var summon_timer: float = 0.0
var _active_orbs: Array = []

func _process(delta: float) -> void:
	if not is_inside_tree():
		return
	if GameManager.paused or GameManager.is_game_over:
		return

	var level = GameManager.get_weapon_level("blood_orb")
	if level <= 0:
		return

	var w = WeaponDB.get_weapon("blood_orb")
	var max_summons = w.get("max_summons", 1) + int(w.get("summons_per_level", 0)) * (level - 1)
	var cooldown = WeaponDB.get_cooldown("blood_orb", level) * GameManager.cooldown_mult

	# Clean up dead orbs
	_active_orbs = _active_orbs.filter(func(o): return is_instance_valid(o))

	summon_timer -= delta
	if summon_timer <= 0 and _active_orbs.size() < max_summons:
		summon_timer = cooldown
		_spawn_orb(level)

func _get_player_node() -> Node3D:
	var candidate = get_parent().get_parent() if get_parent() else null
	if candidate is CharacterBody3D:
		return candidate
	return null

func _spawn_orb(level: int) -> void:
	if not is_inside_tree():
		return
	var player = _get_player_node()
	if not player:
		return

	AudioManager.play_sfx("blood_orb")

	var orb = BloodOrbInstance.new()
	orb.player = player
	orb.level = level
	orb.weapon_id = "blood_orb"

	var w = WeaponDB.get_weapon("blood_orb")
	orb.damage = int(WeaponDB.get_damage("blood_orb", level))
	orb.area_radius = w.get("base_area", 4.0) + w.get("area_per_level", 0.4) * (level - 1)
	orb.lifesteal = w.get("lifesteal", 0.05)
	orb.lifetime = 8.0 + level * 2.0
	orb.orbit_radius = 2.5 + level * 0.2

	get_tree().current_scene.call_deferred("add_child", orb)
	_active_orbs.append(orb)

# --- Inner class for blood orb instance ---
class BloodOrbInstance extends Area3D:
	var player: Node3D = null
	var level: int = 1
	var weapon_id: String = "blood_orb"
	var damage: int = 4
	var area_radius: float = 4.0
	var lifesteal: float = 0.05
	var orbit_radius: float = 2.5
	var lifetime: float = 10.0
	var _orbit_angle: float = 0.0
	var _orbit_speed: float = 1.5
	var _lifetime_timer: float = 0.0
	var _damage_timer: float = 0.0
	var _damage_interval: float = 0.5
	var _core_mesh: MeshInstance3D = null
	var _shell_mesh: MeshInstance3D = null
	var _droplet_meshes: Array = []
	var _trail_particles: GPUParticles3D = null

	# Shared static meshes — created once, reused by all orb instances (zero per-frame allocation)
	static var _shared_droplet_mesh: SphereMesh = null
	static var _shared_wisp_mesh: SphereMesh = null
	static var _shared_drain_mesh: SphereMesh = null
	static var _shared_heal_mesh: SphereMesh = null

	static func _ensure_shared_meshes() -> void:
		if not _shared_droplet_mesh:
			_shared_droplet_mesh = SphereMesh.new()
			_shared_droplet_mesh.radius = 0.05
			_shared_droplet_mesh.height = 0.10
			var dm = StandardMaterial3D.new()
			dm.albedo_color = Color(0.55, 0.04, 0.08)
			dm.emission_enabled = true
			dm.emission = Color(0.9, 0.05, 0.1)
			dm.emission_energy_multiplier = 2.0
			dm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			_shared_droplet_mesh.surface_set_material(0, dm)

		if not _shared_wisp_mesh:
			_shared_wisp_mesh = SphereMesh.new()
			_shared_wisp_mesh.radius = 0.06
			_shared_wisp_mesh.height = 0.12
			_shared_wisp_mesh.radial_segments = 4
			_shared_wisp_mesh.rings = 2
			var wm = StandardMaterial3D.new()
			wm.albedo_color = Color(0.2, 1.0, 0.3, 0.7)
			wm.emission_enabled = true
			wm.emission = Color(0.3, 1.0, 0.4)
			wm.emission_energy_multiplier = 3.0
			wm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			wm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			_shared_wisp_mesh.surface_set_material(0, wm)

		if not _shared_drain_mesh:
			_shared_drain_mesh = SphereMesh.new()
			_shared_drain_mesh.radius = 0.08
			_shared_drain_mesh.height = 0.16
			_shared_drain_mesh.radial_segments = 4
			_shared_drain_mesh.rings = 2
			var drm = StandardMaterial3D.new()
			drm.albedo_color = Color(0.8, 0.05, 0.1, 0.9)
			drm.emission_enabled = true
			drm.emission = Color(1.0, 0.1, 0.15)
			drm.emission_energy_multiplier = 4.0
			drm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			drm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			drm.no_depth_test = true
			_shared_drain_mesh.surface_set_material(0, drm)

		if not _shared_heal_mesh:
			_shared_heal_mesh = SphereMesh.new()
			_shared_heal_mesh.radius = 0.15
			_shared_heal_mesh.height = 0.05
			_shared_heal_mesh.radial_segments = 6
			_shared_heal_mesh.rings = 1
			var hm = StandardMaterial3D.new()
			hm.albedo_color = Color(0.2, 0.9, 0.3, 0.6)
			hm.emission_enabled = true
			hm.emission = Color(0.3, 1.0, 0.4)
			hm.emission_energy_multiplier = 5.0
			hm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			hm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			_shared_heal_mesh.surface_set_material(0, hm)

	## Adds emission glow to imported model without replacing original textures
	static func _add_emission_to_model(model: Node3D, color: Color, strength: float) -> void:
		for child in model.get_children():
			if child is MeshInstance3D:
				var mi := child as MeshInstance3D
				for si in range(mi.get_surface_override_material_count()):
					var base_mat = mi.mesh.surface_get_material(si)
					if base_mat is StandardMaterial3D:
						var mat = base_mat.duplicate() as StandardMaterial3D
						mat.emission_enabled = true
						mat.emission = color
						mat.emission_energy_multiplier = strength
						mi.set_surface_override_material(si, mat)
			_add_emission_to_model(child, color, strength)

	func _ready() -> void:
		add_to_group("player_summons")
		collision_layer = 8  # PlayerAttacks
		collision_mask = 2   # Enemies
		_orbit_angle = randf() * TAU
		_ensure_shared_meshes()

		# Collision shape
		var shape = CollisionShape3D.new()
		var sphere = SphereShape3D.new()
		sphere.radius = area_radius * GameManager.area_mult
		shape.shape = sphere
		add_child(shape)

		# --- 3D Blood Orb model ---
		var _orb_scene_path = "res://assets/models/blood_orb.glb"
		if ResourceLoader.exists(_orb_scene_path):
			var orb_scene = load(_orb_scene_path)
			_core_mesh = orb_scene.instantiate() as Node3D
			_core_mesh.scale = Vector3(0.35, 0.35, 0.35)
			# Keep original textures, just boost emission for glow
			_add_emission_to_model(_core_mesh, Color(1.0, 0.1, 0.15), 2.5)
			add_child(_core_mesh)
			# Shell: translucent outer glow
			_shell_mesh = MeshInstance3D.new()
			var shell_sm = SphereMesh.new()
			shell_sm.radius = 0.44
			shell_sm.height = 0.88
			shell_sm.radial_segments = 8
			shell_sm.rings = 4
			_shell_mesh.mesh = shell_sm
			var shell_mat = StandardMaterial3D.new()
			shell_mat.albedo_color = Color(0.9, 0.1, 0.15, 0.18)
			shell_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			shell_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
			shell_mat.emission_enabled = true
			shell_mat.emission = Color(1.0, 0.1, 0.1)
			shell_mat.emission_energy_multiplier = 1.0
			_shell_mesh.material_override = shell_mat
			add_child(_shell_mesh)
		else:
			# Fallback: original spheres
			_core_mesh = MeshInstance3D.new()
			var core_sm = SphereMesh.new()
			core_sm.radius = 0.32
			core_sm.height = 0.64
			_core_mesh.mesh = core_sm
			var core_mat = StandardMaterial3D.new()
			core_mat.albedo_color = Color(0.7, 0.04, 0.1)
			core_mat.emission_enabled = true
			core_mat.emission = Color(1.0, 0.05, 0.15)
			core_mat.emission_energy_multiplier = 3.0
			_core_mesh.material_override = core_mat
			add_child(_core_mesh)
			_shell_mesh = MeshInstance3D.new()
			var shell_sm = SphereMesh.new()
			shell_sm.radius = 0.44
			shell_sm.height = 0.88
			_shell_mesh.mesh = shell_sm
			var shell_mat = StandardMaterial3D.new()
			shell_mat.albedo_color = Color(0.9, 0.1, 0.15, 0.18)
			shell_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			shell_mat.emission_enabled = true
			shell_mat.emission = Color(1.0, 0.1, 0.1)
			shell_mat.emission_energy_multiplier = 1.0
			_shell_mesh.material_override = shell_mat
			add_child(_shell_mesh)

		# Layer 3: Orbiting droplets (4 small spheres)
		for i in range(4):
			var droplet_mi = MeshInstance3D.new()
			droplet_mi.mesh = _shared_droplet_mesh
			add_child(droplet_mi)
			_droplet_meshes.append(droplet_mi)

		# Layer 4: Dark trail — GPUParticles3D (blood dripping downward)
		_trail_particles = GPUParticles3D.new()
		_trail_particles.amount = 8
		_trail_particles.lifetime = 0.6
		_trail_particles.emitting = true
		_trail_particles.one_shot = false
		_trail_particles.explosiveness = 0.0

		var tp_mat = ParticleProcessMaterial.new()
		tp_mat.direction = Vector3(0, -1, 0)
		tp_mat.spread = 40.0
		tp_mat.initial_velocity_min = 0.5
		tp_mat.initial_velocity_max = 1.2
		tp_mat.gravity = Vector3(0, -2.0, 0)  # Stronger gravity — dripping blood
		tp_mat.scale_min = 0.03
		tp_mat.scale_max = 0.07
		var tp_color = GradientTexture1D.new()
		var tp_grad = Gradient.new()
		tp_grad.set_color(0, Color(0.6, 0.02, 0.08, 0.7))
		tp_grad.set_color(1, Color(0.3, 0.0, 0.03, 0.0))
		tp_color.gradient = tp_grad
		tp_mat.color_ramp = tp_color
		var tp_scale_curve = CurveTexture.new()
		var tp_curve = Curve.new()
		tp_curve.add_point(Vector2(0.0, 1.0))
		tp_curve.add_point(Vector2(0.6, 0.6))
		tp_curve.add_point(Vector2(1.0, 0.0))
		tp_scale_curve.curve = tp_curve
		tp_mat.scale_curve = tp_scale_curve
		_trail_particles.process_material = tp_mat

		var tp_draw = SphereMesh.new()
		tp_draw.radius = 0.04
		tp_draw.height = 0.08
		tp_draw.radial_segments = 4
		tp_draw.rings = 2
		var tp_draw_mat = StandardMaterial3D.new()
		tp_draw_mat.albedo_color = Color(0.5, 0.0, 0.05, 0.5)
		tp_draw_mat.emission_enabled = true
		tp_draw_mat.emission = Color(0.6, 0.05, 0.1)
		tp_draw_mat.emission_energy_multiplier = 3.0
		tp_draw_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		tp_draw_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		tp_draw.surface_set_material(0, tp_draw_mat)
		_trail_particles.draw_pass_1 = tp_draw
		add_child(_trail_particles)

		# Layer 5: Dark mist aura (ominous fog surrounding the orb)
		var _dark_mist = GPUParticles3D.new()
		_dark_mist.name = "DarkMist"
		_dark_mist.amount = 6
		_dark_mist.lifetime = 1.5
		_dark_mist.emitting = true
		_dark_mist.one_shot = false
		var mist_mat = ParticleProcessMaterial.new()
		mist_mat.direction = Vector3(0, 0, 0)
		mist_mat.spread = 180.0
		mist_mat.initial_velocity_min = 0.0
		mist_mat.initial_velocity_max = 0.1
		mist_mat.gravity = Vector3.ZERO
		mist_mat.scale_min = 0.5
		mist_mat.scale_max = 1.2
		mist_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
		mist_mat.emission_sphere_radius = 0.4
		mist_mat.radial_velocity_min = 0.2
		mist_mat.radial_velocity_max = 0.6
		mist_mat.damping_min = 1.0
		mist_mat.damping_max = 2.0
		var mist_color = GradientTexture1D.new()
		var mist_grad = Gradient.new()
		mist_grad.set_color(0, Color(0.15, 0.0, 0.02, 0.2))
		mist_grad.set_color(1, Color(0.05, 0.0, 0.01, 0.0))
		mist_color.gradient = mist_grad
		mist_mat.color_ramp = mist_color
		var mist_scale_c = CurveTexture.new()
		var msc = Curve.new()
		msc.add_point(Vector2(0.0, 0.3))
		msc.add_point(Vector2(0.4, 1.0))
		msc.add_point(Vector2(1.0, 0.0))
		mist_scale_c.curve = msc
		mist_mat.scale_curve = mist_scale_c
		_dark_mist.process_material = mist_mat
		var mist_draw = SphereMesh.new()
		mist_draw.radius = 0.2
		mist_draw.height = 0.15  # Flat — fog-like
		mist_draw.radial_segments = 5
		mist_draw.rings = 3
		var mist_draw_mat = StandardMaterial3D.new()
		mist_draw_mat.albedo_color = Color(0.15, 0.0, 0.03, 0.2)
		mist_draw_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mist_draw_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mist_draw.surface_set_material(0, mist_draw_mat)
		_dark_mist.draw_pass_1 = mist_draw
		add_child(_dark_mist)

		# Layer 6: Blood glow ring (pulsing circle below the orb)
		var _blood_ring = MeshInstance3D.new()
		_blood_ring.name = "BloodRing"
		var blood_torus = TorusMesh.new()
		blood_torus.inner_radius = 0.3
		blood_torus.outer_radius = 0.4
		blood_torus.ring_segments = 4
		blood_torus.rings = 12
		_blood_ring.mesh = blood_torus
		_blood_ring.position.y = -0.2
		_blood_ring.rotation.x = PI / 2.0
		var blood_ring_mat = StandardMaterial3D.new()
		blood_ring_mat.albedo_color = Color(0.7, 0.05, 0.1, 0.3)
		blood_ring_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		blood_ring_mat.emission_enabled = true
		blood_ring_mat.emission = Color(0.8, 0.05, 0.1)
		blood_ring_mat.emission_energy_multiplier = 2.0
		blood_ring_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_blood_ring.material_override = blood_ring_mat
		add_child(_blood_ring)

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

		# Decrement rate-limit timers
		if _drain_line_throttle > 0.0:
			_drain_line_throttle -= delta

		# Gentle orbit around player with floating bob
		_orbit_angle += _orbit_speed * delta
		var bob_offset = sin(_lifetime_timer * 2.5) * 0.25
		var orbit_pos = player.global_position + Vector3(
			cos(_orbit_angle) * orbit_radius,
			1.0 + bob_offset,
			sin(_orbit_angle) * orbit_radius
		)
		global_position = orbit_pos

		# Heartbeat pulse on core
		var heartbeat = abs(sin(_lifetime_timer * 5.0)) * 0.15
		var pulse = 1.0 + heartbeat
		if _core_mesh:
			_core_mesh.scale = Vector3(pulse, pulse, pulse)

		# Slow rotation on shell
		if _shell_mesh:
			_shell_mesh.rotation.y += 0.8 * delta

		# Orbiting droplets around the orb
		for i in range(_droplet_meshes.size()):
			var dm = _droplet_meshes[i]
			if is_instance_valid(dm):
				var d_angle = _lifetime_timer * 3.0 + i * TAU / 4.0
				var d_radius = 0.55 + sin(_lifetime_timer * 2.0 + i) * 0.1
				var d_y = sin(_lifetime_timer * 2.5 + i * 1.5) * 0.15
				dm.position = Vector3(cos(d_angle) * d_radius, d_y, sin(d_angle) * d_radius)

		# Damage tick
		_damage_timer += delta
		if _damage_timer >= _damage_interval:
			_damage_timer = 0.0
			_deal_damage_and_heal()

	func _deal_damage_and_heal() -> void:
		var bodies = get_overlapping_bodies()
		var total_damage_dealt := 0
		for body in bodies:
			if not is_instance_valid(body):
				continue
			if not body.is_in_group("enemies"):
				continue
			if not body.has_method("take_damage"):
				continue

			GameManager._last_attacking_weapon = weapon_id
			body.call_deferred("take_damage", damage, "dark")
			total_damage_dealt += damage

			# Red drain line from enemy to orb (shared mesh, throttled)
			_spawn_drain_line(body.global_position)

			# Dark drain wisp (shared mesh)
			_spawn_drain_wisps(body.global_position)

		# Lifesteal heal with visual feedback
		if total_damage_dealt > 0:
			var heal_amount = maxi(1, ceili(total_damage_dealt * lifesteal)) if lifesteal > 0.0 else 0
			if heal_amount > 0:
				GameManager.heal(heal_amount)
				# Green heal flash on significant heal
				if heal_amount >= 3:
					_spawn_heal_pulse()
				# Screen pulse on big drain (5+ enemies)
				if total_damage_dealt >= damage * 5:
					ScreenEffects.shake(0.06)

	func _spawn_drain_wisps(from_pos: Vector3) -> void:
		if not is_inside_tree():
			return
		if Engine.get_frames_per_second() < 45:
			return
		# Skip wisps if drain line throttle is active (avoid double visual spam)
		if _drain_line_throttle > 0.15:
			return
		var scene = get_tree().current_scene
		if not scene:
			return

		var wisp = MeshInstance3D.new()
		wisp.mesh = _shared_wisp_mesh  # Shared mesh — zero material allocation
		scene.add_child(wisp)
		wisp.global_position = from_pos + Vector3(0, 0.5, 0)

		var tween = wisp.create_tween()
		tween.tween_property(wisp, "global_position", global_position, 0.35).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
		tween.tween_callback(wisp.queue_free)

	var _drain_line_throttle: float = 0.0  # Rate limit drain lines

	func _spawn_drain_line(from_pos: Vector3) -> void:
		if not is_inside_tree():
			return
		if Engine.get_frames_per_second() < 35:
			return
		# Rate limit: max one drain line call per 0.3s to avoid node spam
		if _drain_line_throttle > 0.0:
			return
		_drain_line_throttle = 0.3
		# Spawn 2 blood droplets flying from enemy to orb (shared mesh, no per-spawn material)
		var start = from_pos + Vector3(0, 0.5, 0)
		var target = global_position
		var scene = get_tree().current_scene
		if not scene:
			return
		for i in range(2):
			var droplet = MeshInstance3D.new()
			droplet.mesh = _shared_drain_mesh  # Shared mesh — zero material allocation
			scene.add_child(droplet)
			# Posicao inicial com offset aleatorio
			var offset = Vector3(randf_range(-0.3, 0.3), randf_range(-0.2, 0.2), randf_range(-0.3, 0.3))
			droplet.global_position = start + offset
			# Anima voando pro orbe + fade
			var dur = randf_range(0.15, 0.3)
			var tw = droplet.create_tween()
			tw.set_parallel(true)
			tw.tween_property(droplet, "global_position", target, dur).set_ease(Tween.EASE_IN)
			tw.tween_property(droplet, "scale", Vector3(0.3, 0.3, 0.3), dur)
			tw.set_parallel(false)
			tw.tween_callback(droplet.queue_free)

	func _spawn_heal_pulse() -> void:
		if not is_inside_tree():
			return
		var scene = get_tree().current_scene
		if not scene:
			return
		# Green-red heal ring expanding from orb (shared mesh)
		var ring = MeshInstance3D.new()
		ring.mesh = _shared_heal_mesh  # Shared mesh — zero material allocation
		scene.add_child(ring)
		ring.global_position = global_position
		var htw = ring.create_tween()
		htw.set_parallel(true)
		htw.tween_property(ring, "scale", Vector3(5.0, 1.0, 5.0), 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		htw.tween_property(ring, "scale:y", 0.01, 0.4)
		htw.chain().tween_callback(ring.queue_free)
