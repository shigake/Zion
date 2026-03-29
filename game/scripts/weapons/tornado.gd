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
		var sprite_path = "res://assets/sprites/weapons/tornado.png"
		if ResourceLoader.exists(sprite_path):
			_sprite = Sprite3D.new()
			_sprite.texture = load(sprite_path)
			_sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			_sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
			_sprite.pixel_size = 0.04
			_sprite.shaded = false
			_sprite.transparent = true
			_sprite.name = "WeaponSprite"
			add_child(_sprite)
		else:
			# Fallback procedural mesh - tall cone
			_mesh = MeshInstance3D.new()
			var cone = CylinderMesh.new()
			cone.top_radius = 0.05
			cone.bottom_radius = 0.8
			cone.height = 2.0
			_mesh.mesh = cone
			var mat = StandardMaterial3D.new()
			mat.albedo_color = Color(0.5, 0.8, 1.0, 0.5)
			mat.emission_enabled = true
			mat.emission = Color(0.4, 0.7, 1.0)
			mat.emission_energy_multiplier = 2.0
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			_mesh.material_override = mat
			add_child(_mesh)

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

		# Spin visual + scale pulse (breathing effect)
		var pulse = 1.0 + sin(_lifetime_timer * 3.0) * 0.15
		if _mesh:
			_mesh.rotation.y += 8.0 * delta
			_mesh.scale = Vector3(pulse, 1.0 + sin(_lifetime_timer * 2.0) * 0.08, pulse)
		if _sprite:
			_sprite.rotation.y += 8.0 * delta
			_sprite.scale = Vector3(pulse, 1.0 + sin(_lifetime_timer * 2.0) * 0.08, pulse)

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

			# Pull toward center
			if body is CharacterBody3D or body is RigidBody3D:
				var pull_dir = (global_position - body.global_position).normalized()
				pull_dir.y = 0
				body.global_position += pull_dir * _pull_strength * _damage_interval

	func _spawn_vortex_particles() -> void:
		if not is_inside_tree():
			return
		# Only spawn every few frames for performance
		if Engine.get_process_frames() % 3 != 0:
			return
		var scene = get_tree().current_scene
		if not scene:
			return
		# Small ice/wind particle orbiting the tornado
		var particle = MeshInstance3D.new()
		var sphere = SphereMesh.new()
		sphere.radius = 0.06
		sphere.height = 0.12
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(0.6, 0.85, 1.0, 0.6)
		mat.emission_enabled = true
		mat.emission = Color(0.5, 0.8, 1.0)
		mat.emission_energy_multiplier = 4.0
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		sphere.surface_set_material(0, mat)
		particle.mesh = sphere
		scene.add_child(particle)
		# Start at random position around tornado
		var angle = randf() * TAU
		var offset = Vector3(cos(angle) * 0.5, randf_range(-0.3, 1.5), sin(angle) * 0.5)
		particle.global_position = global_position + offset
		# Spiral outward and fade
		var tween = particle.create_tween()
		tween.set_parallel(true)
		var end_pos = global_position + Vector3(cos(angle) * 2.0, 1.5, sin(angle) * 2.0)
		tween.tween_property(particle, "global_position", end_pos, 0.5)
		tween.tween_property(particle, "scale", Vector3(0.1, 0.1, 0.1), 0.5)
		tween.chain().tween_callback(particle.queue_free)
