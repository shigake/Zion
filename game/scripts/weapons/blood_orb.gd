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
	var _mesh: MeshInstance3D = null
	var _sprite: Sprite3D = null

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

		# Billboard sprite
		var sprite_path = "res://assets/sprites/weapons/blood_orb.png"
		if ResourceLoader.exists(sprite_path):
			_sprite = Sprite3D.new()
			_sprite.texture = load(sprite_path)
			_sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			_sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
			_sprite.pixel_size = 0.03
			_sprite.shaded = false
			_sprite.transparent = true
			_sprite.name = "WeaponSprite"
			add_child(_sprite)
		else:
			# Fallback procedural mesh - dark red sphere
			_mesh = MeshInstance3D.new()
			var sphere_mesh = SphereMesh.new()
			sphere_mesh.radius = 0.4
			sphere_mesh.height = 0.8
			_mesh.mesh = sphere_mesh
			var mat = StandardMaterial3D.new()
			mat.albedo_color = Color(0.6, 0.05, 0.1, 0.8)
			mat.emission_enabled = true
			mat.emission = Color(0.8, 0.1, 0.15)
			mat.emission_energy_multiplier = 3.0
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			_mesh.material_override = mat
			add_child(_mesh)

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

		# Gentle orbit around player with floating bob
		_orbit_angle += _orbit_speed * delta
		var bob_offset = sin(_lifetime_timer * 2.5) * 0.25
		var orbit_pos = player.global_position + Vector3(
			cos(_orbit_angle) * orbit_radius,
			1.0 + bob_offset,
			sin(_orbit_angle) * orbit_radius
		)
		global_position = orbit_pos

		# Pulse visual — heartbeat pattern + alpha glow oscillation
		var heartbeat = abs(sin(_lifetime_timer * 5.0)) * 0.15
		var glow_alpha = 0.75 + sin(_lifetime_timer * 3.5) * 0.25
		if _mesh:
			var pulse = 1.0 + heartbeat
			_mesh.scale = Vector3(pulse, pulse, pulse)
		if _sprite:
			var pulse = 1.0 + heartbeat
			_sprite.scale = Vector3(pulse, pulse, pulse)
			_sprite.modulate = Color(1.0, 0.85 + sin(_lifetime_timer * 4.0) * 0.15, 0.9, glow_alpha)

		# Dark trail particles
		_trail_timer += delta
		if _trail_timer >= 0.12 and Engine.get_frames_per_second() > 35:
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
			var heal_amount = int(total_damage_dealt * lifesteal)
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
		if Engine.get_frames_per_second() < 40:
			return
		var scene = Engine.get_main_loop().current_scene if Engine.get_main_loop() else null
		if not scene:
			return

		var wisp = MeshInstance3D.new()
		var sphere = SphereMesh.new()
		sphere.radius = 0.03
		sphere.height = 0.06
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(0.8, 0.1, 0.15, 0.7)
		mat.emission_enabled = true
		mat.emission = Color(0.9, 0.1, 0.2)
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

	func _spawn_drain_line(from_pos: Vector3) -> void:
		if not is_inside_tree():
			return
		if Engine.get_frames_per_second() < 35:
			return
		var scene = Engine.get_main_loop().current_scene if Engine.get_main_loop() else null
		if not scene:
			return

		var line_mesh = MeshInstance3D.new()
		var im = ImmediateMesh.new()
		var start = from_pos + Vector3(0, 0.5, 0)
		var end = global_position

		# Slightly wavy line with 4 segments
		im.surface_begin(Mesh.PRIMITIVE_LINES)
		im.surface_set_color(Color(0.9, 0.1, 0.15, 0.6))
		var seg_count := 4
		for i in range(seg_count):
			var t0 = float(i) / float(seg_count)
			var t1 = float(i + 1) / float(seg_count)
			var p0 = start.lerp(end, t0)
			var p1 = start.lerp(end, t1)
			if i > 0 and i < seg_count:
				p0 += Vector3(randf_range(-0.1, 0.1), randf_range(-0.05, 0.05), randf_range(-0.1, 0.1))
			im.surface_add_vertex(p0)
			im.surface_add_vertex(p1)
		im.surface_end()
		line_mesh.mesh = im

		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(0.9, 0.1, 0.15, 0.6)
		mat.emission_enabled = true
		mat.emission = Color(0.8, 0.05, 0.1)
		mat.emission_energy_multiplier = 5.0
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.no_depth_test = true
		line_mesh.material_override = mat

		scene.add_child(line_mesh)
		var line_tween = line_mesh.create_tween()
		line_tween.tween_property(line_mesh, "transparency", 1.0, 0.25)
		line_tween.tween_callback(line_mesh.queue_free)

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
