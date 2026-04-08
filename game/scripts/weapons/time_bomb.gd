extends Node3D

## Bomba Relogio — dropa bomba na posicao do jogador, explode apos fuse.

var attack_timer: float = 0.0
var active_bombs: Array = []
const MAX_BOMBS: int = 3
const FUSE_TIME: float = 3.0
const EXPLOSION_RADIUS: float = 4.0

# --- Cached materials (lazy-init, reused across bomb spawns) ---
var _bomb_body_mat_cache: StandardMaterial3D = null
var _fuse_mat_cache: StandardMaterial3D = null
var _spark_draw_mat_cache: StandardMaterial3D = null

func _get_bomb_body_mat() -> StandardMaterial3D:
	if _bomb_body_mat_cache == null:
		_bomb_body_mat_cache = StandardMaterial3D.new()
		_bomb_body_mat_cache.albedo_color = Color(0.3, 0.05, 0.05, 1.0)
		_bomb_body_mat_cache.metallic = 0.5
		_bomb_body_mat_cache.emission_enabled = true
		_bomb_body_mat_cache.emission = Color(0.8, 0.1, 0.1)
		_bomb_body_mat_cache.emission_energy_multiplier = 1.0
	return _bomb_body_mat_cache

func _get_fuse_mat() -> StandardMaterial3D:
	if _fuse_mat_cache == null:
		_fuse_mat_cache = StandardMaterial3D.new()
		_fuse_mat_cache.albedo_color = Color(0.15, 0.1, 0.05, 1.0)
	return _fuse_mat_cache

func _get_spark_draw_mat() -> StandardMaterial3D:
	if _spark_draw_mat_cache == null:
		_spark_draw_mat_cache = StandardMaterial3D.new()
		_spark_draw_mat_cache.albedo_color = Color(1.0, 0.6, 0.1, 0.9)
		_spark_draw_mat_cache.emission_enabled = true
		_spark_draw_mat_cache.emission = Color(1.0, 0.5, 0.0)
		_spark_draw_mat_cache.emission_energy_multiplier = 5.0
		_spark_draw_mat_cache.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return _spark_draw_mat_cache

func _process(delta: float) -> void:
	if not is_inside_tree():
		return
	if GameManager.paused or GameManager.is_game_over:
		return

	var level = GameManager.get_weapon_level("time_bomb")
	if level <= 0:
		return

	var cooldown = WeaponDB.get_cooldown("time_bomb", level) / GameManager.attack_speed_mult * GameManager.cooldown_mult

	# Limpa bombas invalidas
	active_bombs = active_bombs.filter(func(b): return is_instance_valid(b))

	attack_timer -= delta
	if attack_timer <= 0:
		attack_timer = cooldown
		if active_bombs.size() < MAX_BOMBS:
			_drop_bomb(level)

func _get_player_node() -> Node3D:
	var candidate = get_parent().get_parent() if get_parent() else null
	if candidate is CharacterBody3D:
		return candidate
	return null

func _drop_bomb(level: int) -> void:
	if not is_inside_tree():
		return
	var player = _get_player_node()
	if not player:
		return
	var player_pos = player.global_position
	var bomb = _create_bomb_node(level)
	bomb.global_position = player_pos
	get_tree().current_scene.call_deferred("add_child", bomb)
	active_bombs.append(bomb)

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

func _create_bomb_node(level: int) -> Node3D:
	var bomb = Node3D.new()
	bomb.name = "TimeBomb"
	bomb.set_meta("level", level)
	bomb.set_meta("fuse_time", FUSE_TIME)
	bomb.set_meta("explosion_radius", EXPLOSION_RADIUS)

	# Child 0: Bomb body — 3D model or fallback sphere
	var _bomb_scene_path = "res://assets/models/time_bomb.glb"
	if ResourceLoader.exists(_bomb_scene_path):
		var bomb_scene = load(_bomb_scene_path)
		var bomb_model = bomb_scene.instantiate()
		bomb_model.name = "BombModel"
		bomb_model.scale = Vector3(0.35, 0.35, 0.35)
		# Keep original textures, add red danger glow
		_add_emission_to_model(bomb_model, Color(1.0, 0.2, 0.1), 1.5)
		bomb.add_child(bomb_model)
	else:
		var mesh_inst = MeshInstance3D.new()
		var sphere = SphereMesh.new()
		sphere.radius = 0.3
		sphere.height = 0.6
		mesh_inst.mesh = sphere
		# Duplicate from cache since explosion tween modifies emission per-bomb
		var mat = _get_bomb_body_mat().duplicate() as StandardMaterial3D
		mesh_inst.material_override = mat
		bomb.add_child(mesh_inst)
		# Fuse cylinder (only for fallback — model has its own fuse)
		var fuse_mesh = MeshInstance3D.new()
		var fuse_cyl = CylinderMesh.new()
		fuse_cyl.top_radius = 0.01
		fuse_cyl.bottom_radius = 0.01
		fuse_cyl.height = 0.15
		fuse_mesh.mesh = fuse_cyl
		fuse_mesh.material_override = _get_fuse_mat()
		fuse_mesh.position = Vector3(0.02, 0.35, 0)
		fuse_mesh.rotation.z = 0.3
		bomb.add_child(fuse_mesh)

	# Timer label 3D
	var label = Label3D.new()
	label.text = str(int(FUSE_TIME))
	label.font_size = 32
	label.position = Vector3(0, 1.0, 0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = Color(1.0, 0.8, 0.0)
	bomb.add_child(label)

	# Child 3: Fuse spark particles at fuse tip
	var spark_particles = GPUParticles3D.new()
	spark_particles.amount = 3
	spark_particles.lifetime = 0.2
	spark_particles.emitting = true
	spark_particles.one_shot = false
	spark_particles.position = Vector3(0.02 + sin(0.3) * 0.075, 0.35 + cos(0.3) * 0.075, 0)
	var spark_mat = ParticleProcessMaterial.new()
	spark_mat.direction = Vector3(0, 1, 0)
	spark_mat.spread = 60.0
	spark_mat.initial_velocity_min = 0.3
	spark_mat.initial_velocity_max = 1.0
	spark_mat.gravity = Vector3(0, -3, 0)
	spark_mat.scale_min = 0.2
	spark_mat.scale_max = 0.5
	spark_mat.color = Color(1.0, 0.7, 0.1, 0.9)
	spark_particles.process_material = spark_mat
	# Draw pass: tiny orange/yellow spark
	var spark_mesh = SphereMesh.new()
	spark_mesh.radius = 0.01
	spark_mesh.height = 0.02
	spark_mesh.surface_set_material(0, _get_spark_draw_mat())
	spark_particles.draw_pass_1 = spark_mesh
	bomb.add_child(spark_particles)

	# Fuse script via set_script
	var script = GDScript.new()
	script.source_code = _get_bomb_script()
	script.reload()
	bomb.set_script(script)

	return bomb

func _get_bomb_script() -> String:
	return """extends Node3D

var fuse_timer: float = 0.0
var fuse_time: float = 3.0
var explosion_radius: float = 4.0
var bomb_level: int = 1
var has_exploded: bool = false

func _ready() -> void:
	fuse_time = get_meta("fuse_time", 3.0)
	explosion_radius = get_meta("explosion_radius", 4.0)
	bomb_level = get_meta("level", 1)

func _process(delta: float) -> void:
	if has_exploded:
		return
	if GameManager.paused or GameManager.is_game_over:
		return

	fuse_timer += delta

	# Update countdown label
	var label = get_child(1) as Label3D
	if label:
		var remaining = max(0, fuse_time - fuse_timer)
		label.text = str(int(ceil(remaining)))

	# Countdown pulse: emission oscillates, faster as timer approaches 0
	var mesh_node = get_child(0) as MeshInstance3D
	if mesh_node:
		var progress = clamp(fuse_timer / fuse_time, 0.0, 1.0)
		# Pulse speed increases as countdown approaches 0 (4 -> 16 Hz)
		var pulse_speed = lerp(4.0, 16.0, progress)
		var pulse_val = (sin(fuse_timer * pulse_speed) + 1.0) * 0.5  # 0..1
		var emission_energy = lerp(0.5, 2.0, pulse_val)

		var mat = mesh_node.material_override as StandardMaterial3D
		if mat:
			mat.emission_energy_multiplier = emission_energy

		# Also pulse scale slightly
		var scale_pulse = 1.0 + sin(fuse_timer * pulse_speed) * 0.08
		mesh_node.scale = Vector3.ONE * scale_pulse

	if fuse_timer >= fuse_time:
		_explode()

func _explode() -> void:
	has_exploded = true
	var dmg = int(WeaponDB.get_damage("time_bomb", bomb_level))
	var pos = global_position
	var radius_sq = explosion_radius * explosion_radius

	# Use spatial grid for O(1) radius query
	var nearby = GameManager.get_enemies_in_radius(pos, explosion_radius)
	for e in nearby:
		if not is_instance_valid(e):
			continue
		if e.has_method("take_damage"):
			GameManager._last_attacking_weapon = "time_bomb"
			e.call_deferred("take_damage", dmg, "fire")

	ScreenEffects.shake(0.5)
	AudioManager.play_sfx("hit")

	# Multi-layer explosion effect
	# Layer 1: Core flash (white/yellow)
	_spawn_explosion_layer(pos, 0.5, Color(1.0, 0.9, 0.6), 6.0, 0.15)
	# Layer 2: Fire burst (orange)
	ParticleFactory.spawn_explosion_particles(pos, explosion_radius)
	ParticleFactory.spawn_hit_particles(pos, Color(1.0, 0.4, 0.0))
	# Layer 3: Smoke/debris (dark)
	ParticleFactory.spawn_hit_particles(pos + Vector3(0, 0.5, 0), Color(1.0, 0.7, 0.1))
	ParticleFactory.spawn_death_particles(pos, Color(0.3, 0.15, 0.05))
	# Layer 4: Shockwave ring on ground
	_spawn_shockwave(pos, explosion_radius)

	# Expand bomb mesh as shockwave then free
	var tween = create_tween()
	var mesh_node = get_child(0) as MeshInstance3D
	if mesh_node:
		var mat = mesh_node.material_override as StandardMaterial3D
		if mat:
			mat.emission = Color(1.0, 0.7, 0.2)
			mat.emission_energy_multiplier = 5.0
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		tween.set_parallel(true)
		tween.tween_property(mesh_node, "scale", Vector3.ONE * 3.0, 0.2)
		if mat:
			tween.tween_property(mat, "albedo_color:a", 0.0, 0.2)
		tween.set_parallel(false)
	tween.tween_callback(queue_free)

func _spawn_shockwave(pos: Vector3, radius: float) -> void:
	var ring = MeshInstance3D.new()
	var torus = TorusMesh.new()
	torus.inner_radius = 0.1
	torus.outer_radius = 0.3
	torus.ring_segments = 4
	torus.rings = 16
	ring.mesh = torus
	ring.global_position = pos + Vector3(0, 0.1, 0)
	ring.rotation.x = PI / 2.0
	var ring_mat = StandardMaterial3D.new()
	ring_mat.albedo_color = Color(1.0, 0.6, 0.1, 0.6)
	ring_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ring_mat.emission_enabled = true
	ring_mat.emission = Color(1.0, 0.5, 0.0)
	ring_mat.emission_energy_multiplier = 4.0
	ring_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ring_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	ring.material_override = ring_mat
	get_tree().current_scene.add_child(ring)
	var stw = ring.create_tween()
	var target = radius * 2.0
	stw.set_parallel(true)
	stw.tween_property(ring, "scale", Vector3(target, target, target), 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	stw.tween_property(ring_mat, "albedo_color:a", 0.0, 0.35)
	stw.set_parallel(false)
	stw.tween_callback(ring.queue_free)

func _spawn_explosion_layer(pos: Vector3, radius: float, color: Color, energy: float, duration: float) -> void:
	var flash = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = radius
	sphere.height = radius * 2.0
	flash.mesh = sphere
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(color.r, color.g, color.b, 0.8)
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = energy
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	flash.material_override = mat
	flash.global_position = pos
	get_tree().current_scene.add_child(flash)
	var tw = flash.create_tween()
	tw.set_parallel(true)
	tw.tween_property(flash, "scale", Vector3.ONE * 4.0, duration)
	tw.tween_property(mat, "albedo_color:a", 0.0, duration)
	tw.set_parallel(false)
	tw.tween_callback(flash.queue_free)
"""
