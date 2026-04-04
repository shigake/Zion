extends Node3D

## Orbe de Sangue — invoca orbe que drena vida dos inimigos e cura o jogador.

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
	static var _shared_droplet_mesh: SphereMesh = null

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

		# --- Full 3D blood orb (no Sprite3D) ---
		# Layer 1: Core sphere — deep blood-red with emission
		_core_mesh = MeshInstance3D.new()
		var core_sm = SphereMesh.new()
		core_sm.radius = 0.32
		core_sm.height = 0.64
		core_sm.radial_segments = 10
		core_sm.rings = 5
		_core_mesh.mesh = core_sm
		var core_mat = StandardMaterial3D.new()
		core_mat.albedo_color = Color(0.55, 0.04, 0.08)
		core_mat.metallic = 0.3
		core_mat.roughness = 0.2
		core_mat.emission_enabled = true
		core_mat.emission = Color(0.9, 0.05, 0.1)
		core_mat.emission_energy_multiplier = 1.5
		_core_mesh.material_override = core_mat
		add_child(_core_mesh)

		# Layer 2: Translucent shell — slow rotating outer layer
		_shell_mesh = MeshInstance3D.new()
		var shell_sm = SphereMesh.new()
		shell_sm.radius = 0.44
		shell_sm.height = 0.88
		shell_sm.radial_segments = 8
		shell_sm.rings = 4
		_shell_mesh.mesh = shell_sm
		var shell_mat = StandardMaterial3D.new()
		shell_mat.albedo_color = Color(0.7, 0.1, 0.15, 0.22)
		shell_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		shell_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		shell_mat.emission_enabled = true
		shell_mat.emission = Color(0.8, 0.1, 0.1)
		shell_mat.emission_energy_multiplier = 0.5
		_shell_mesh.material_override = shell_mat
		add_child(_shell_mesh)

		# Layer 3: Orbiting droplets (4 small spheres)
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
		for i in range(4):
			var droplet_mi = MeshInstance3D.new()
			droplet_mi.mesh = _shared_droplet_mesh
			add_child(droplet_mi)
			_droplet_meshes.append(droplet_mi)

	var _trail_timer: float = 0.0

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

		# Dark trail particles (reduced frequency to avoid node buildup)
		_trail_timer += delta
		if _trail_timer >= 0.25 and Engine.get_frames_per_second() > 35:
			_trail_timer = 0.0
			_spawn_dark_trail()

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

			# Red drain line from enemy to orb
			_spawn_drain_line(body.global_position)

			# Dark drain visual
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
		var scene = Engine.get_main_loop().current_scene if Engine.get_main_loop() else null
		if not scene:
			return

		var wisp = MeshInstance3D.new()
		var sphere = SphereMesh.new()
		sphere.radius = 0.06
		sphere.height = 0.12
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(0.2, 1.0, 0.3, 0.7)
		mat.emission_enabled = true
		mat.emission = Color(0.3, 1.0, 0.4)
		mat.emission_energy_multiplier = 3.0
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		sphere.surface_set_material(0, mat)
		wisp.mesh = sphere
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
		# Spawn 2-3 blood droplets flying from enemy to orb (reduced from 3-5)
		var start = from_pos + Vector3(0, 0.5, 0)
		var target = global_position
		var scene = Engine.get_main_loop().current_scene if Engine.get_main_loop() else null
		if not scene:
			return
		var count = randi_range(2, 3)
		for i in range(count):
			var droplet = MeshInstance3D.new()
			var sphere = SphereMesh.new()
			sphere.radius = 0.08
			sphere.height = 0.16
			droplet.mesh = sphere
			var mat = StandardMaterial3D.new()
			mat.albedo_color = Color(0.8, 0.05, 0.1, 0.9)
			mat.emission_enabled = true
			mat.emission = Color(1.0, 0.1, 0.15)
			mat.emission_energy_multiplier = 4.0
			mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			mat.no_depth_test = true
			droplet.material_override = mat
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
		# Green-red heal ring expanding from orb
		var ring = MeshInstance3D.new()
		var torus = SphereMesh.new()
		torus.radius = 0.15
		torus.height = 0.05
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(0.2, 0.9, 0.3, 0.6)
		mat.emission_enabled = true
		mat.emission = Color(0.3, 1.0, 0.4)
		mat.emission_energy_multiplier = 5.0
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		torus.surface_set_material(0, mat)
		ring.mesh = torus
		scene.add_child(ring)
		ring.global_position = global_position
		var htw = ring.create_tween()
		htw.set_parallel(true)
		htw.tween_property(ring, "scale", Vector3(5.0, 1.0, 5.0), 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		htw.tween_property(ring, "scale:y", 0.01, 0.4)
		htw.chain().tween_callback(ring.queue_free)

	func _spawn_dark_trail() -> void:
		if not is_inside_tree():
			return
		var scene = get_tree().current_scene
		if not scene:
			return
		var trail = MeshInstance3D.new()
		var sphere = SphereMesh.new()
		sphere.radius = 0.04
		sphere.height = 0.08
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(0.5, 0.0, 0.05, 0.5)
		mat.emission_enabled = true
		mat.emission = Color(0.6, 0.05, 0.1)
		mat.emission_energy_multiplier = 3.0
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		sphere.surface_set_material(0, mat)
		trail.mesh = sphere
		scene.add_child(trail)
		trail.global_position = global_position + Vector3(randf_range(-0.15, 0.15), randf_range(-0.1, 0.1), randf_range(-0.15, 0.15))
		# Float down and fade
		var tween = trail.create_tween()
		tween.set_parallel(true)
		tween.tween_property(trail, "global_position:y", trail.global_position.y - 0.4, 0.4)
		tween.tween_property(trail, "scale", Vector3(0.01, 0.01, 0.01), 0.4)
		tween.chain().tween_callback(trail.queue_free)
