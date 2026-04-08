extends Node

## Fabrica de particulas. Cria efeitos visuais em posicoes 3D.
## Usa pool para evitar alocacoes constantes (performance com 500+ inimigos).

# --- Particle Pool ---
const PARTICLE_POOL_SIZE := 30
const MAX_ACTIVE_PARTICLES := 24  # Keep headroom inside the pool to avoid burst allocations
var _particle_pool: Array = []  # Available GPUParticles3D nodes
var _active_particles: Dictionary = {}  # node -> cleanup_timer

# --- Damage Number Pool ---
const DAMAGE_NUMBER_POOL_SIZE := 50
var _dmg_pool: Array = []  # Available Label3D nodes
var _dmg_script = preload("res://scripts/effects/damage_number.gd")

# Shared meshes to avoid re-creating every time
var _sphere_mesh: SphereMesh
var _box_mesh: BoxMesh
var _small_sphere_mesh: SphereMesh

# Shared draw passes with materials (avoid creating new meshes per spawn)
var _spark_draw_pass: SphereMesh  # For slash sparks, whip sparks
var _dust_draw_pass: SphereMesh   # For ground dust, hammer dust
var _debris_draw_pass: BoxMesh    # For hammer debris

# Shared draw passes for hit/death/collect/level-up/explosion (avoid per-emission allocation)
var _hit_draw_pass: SphereMesh
var _death_draw_pass: BoxMesh
var _collect_draw_pass: SphereMesh
var _levelup_draw_pass: SphereMesh
var _explosion_draw_pass: SphereMesh

func _ready() -> void:
	_create_shared_meshes()
	_init_particle_pool()
	_init_damage_number_pool()

func _create_shared_meshes() -> void:
	_sphere_mesh = SphereMesh.new()
	_sphere_mesh.radius = 0.08
	_sphere_mesh.height = 0.16

	_box_mesh = BoxMesh.new()
	_box_mesh.size = Vector3(0.1, 0.1, 0.1)

	_small_sphere_mesh = SphereMesh.new()
	_small_sphere_mesh.radius = 0.05
	_small_sphere_mesh.height = 0.1

	# Spark draw pass (slash sparks, whip sparks)
	_spark_draw_pass = SphereMesh.new()
	_spark_draw_pass.radius = 0.03
	_spark_draw_pass.height = 0.06
	var spark_mat = StandardMaterial3D.new()
	spark_mat.emission_enabled = true
	spark_mat.emission_energy_multiplier = 5.0
	_spark_draw_pass.surface_set_material(0, spark_mat)

	# Dust draw pass (ground dust, hammer dust)
	_dust_draw_pass = SphereMesh.new()
	_dust_draw_pass.radius = 0.08
	_dust_draw_pass.height = 0.16
	var dust_mat = StandardMaterial3D.new()
	dust_mat.emission_enabled = true
	dust_mat.emission_energy_multiplier = 0.5
	dust_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_dust_draw_pass.surface_set_material(0, dust_mat)

	# Debris draw pass (hammer debris)
	_debris_draw_pass = BoxMesh.new()
	_debris_draw_pass.size = Vector3(0.04, 0.04, 0.04)
	var debris_mat = StandardMaterial3D.new()
	debris_mat.emission_enabled = true
	debris_mat.emission_energy_multiplier = 1.0
	_debris_draw_pass.surface_set_material(0, debris_mat)

	# Hit draw pass (shared for spawn_hit_particles)
	_hit_draw_pass = SphereMesh.new()
	_hit_draw_pass.radius = 0.08
	_hit_draw_pass.height = 0.16
	var hit_mat = StandardMaterial3D.new()
	hit_mat.emission_enabled = true
	hit_mat.emission_energy_multiplier = 2.0
	_hit_draw_pass.surface_set_material(0, hit_mat)

	# Death draw pass (shared for spawn_death_particles)
	_death_draw_pass = BoxMesh.new()
	_death_draw_pass.size = Vector3(0.1, 0.1, 0.1)
	var death_mat = StandardMaterial3D.new()
	death_mat.emission_enabled = true
	death_mat.emission_energy_multiplier = 1.5
	_death_draw_pass.surface_set_material(0, death_mat)

	# Collect draw pass (shared for spawn_collect_particles)
	_collect_draw_pass = SphereMesh.new()
	_collect_draw_pass.radius = 0.05
	_collect_draw_pass.height = 0.1
	var collect_mat = StandardMaterial3D.new()
	collect_mat.emission_enabled = true
	collect_mat.emission_energy_multiplier = 3.0
	_collect_draw_pass.surface_set_material(0, collect_mat)

	# Level-up draw pass (shared for spawn_level_up_particles)
	_levelup_draw_pass = SphereMesh.new()
	_levelup_draw_pass.radius = 0.06
	_levelup_draw_pass.height = 0.12
	var levelup_mat = StandardMaterial3D.new()
	levelup_mat.emission_enabled = true
	levelup_mat.emission_energy_multiplier = 3.0
	_levelup_draw_pass.surface_set_material(0, levelup_mat)

	# Explosion draw pass (shared for spawn_explosion_particles)
	_explosion_draw_pass = SphereMesh.new()
	_explosion_draw_pass.radius = 0.1
	_explosion_draw_pass.height = 0.2
	var explosion_mat = StandardMaterial3D.new()
	explosion_mat.emission_enabled = true
	explosion_mat.emission_energy_multiplier = 4.0
	_explosion_draw_pass.surface_set_material(0, explosion_mat)

func _init_particle_pool() -> void:
	for i in PARTICLE_POOL_SIZE:
		var p = _create_particle_node()
		_particle_pool.append(p)

func _create_particle_node() -> GPUParticles3D:
	var particles = GPUParticles3D.new()
	particles.one_shot = true
	particles.emitting = false
	particles.explosiveness = 1.0
	particles.process_material = ParticleProcessMaterial.new()
	# Reuse the shared hit draw pass instead of creating one mesh/material per pooled node.
	particles.draw_pass_1 = _hit_draw_pass
	return particles

func _get_particle() -> GPUParticles3D:
	# Try to reuse from pool
	while not _particle_pool.is_empty():
		var p = _particle_pool.pop_back()
		if is_instance_valid(p):
			return p
	# Pool exhausted, create new
	return _create_particle_node()

func _return_particle(p: GPUParticles3D) -> void:
	if not is_instance_valid(p):
		return
	p.emitting = false
	if p.get_parent():
		p.get_parent().remove_child(p)
	# Remove from active tracking
	_active_particles.erase(p)
	_particle_pool.append(p)

func _setup_and_emit(particles: GPUParticles3D, pos: Vector3, cleanup_time: float) -> void:
	# Global particle budget: reject if too many active
	if _active_particles.size() >= MAX_ACTIVE_PARTICLES:
		_particle_pool.append(particles)
		return

	var scene = Engine.get_main_loop().current_scene if Engine.get_main_loop() else null
	if not scene:
		_particle_pool.append(particles)
		return

	if not particles.get_parent():
		scene.add_child(particles)

	if not particles.is_inside_tree():
		_particle_pool.append(particles)
		return

	if not particles.is_in_group("particles"):
		particles.add_to_group("particles")

	particles.global_position = pos
	particles.emitting = true

	# Schedule return to pool via expiry time (no Tween allocation)
	_active_particles[particles] = Time.get_ticks_msec() / 1000.0 + cleanup_time

func _process(_delta: float) -> void:
	# Clean up expired particles (replaces per-emission Tween allocation)
	if _active_particles.is_empty():
		return
	var now := Time.get_ticks_msec() / 1000.0
	var to_return: Array = []
	for p in _active_particles:
		if not is_instance_valid(p):
			to_return.append(p)
			continue
		if now >= _active_particles[p]:
			to_return.append(p)
	for p in to_return:
		if is_instance_valid(p):
			_return_particle(p)
		else:
			_active_particles.erase(p)

# --- Damage Number Pool ---

func _init_damage_number_pool() -> void:
	for i in DAMAGE_NUMBER_POOL_SIZE:
		var label = _create_damage_label()
		_dmg_pool.append(label)

func _create_damage_label() -> Label3D:
	var label = Label3D.new()
	label.set_script(_dmg_script)
	label.visible = false
	return label

func get_damage_number() -> Label3D:
	while not _dmg_pool.is_empty():
		var label = _dmg_pool.pop_back()
		if is_instance_valid(label):
			label._reset_for_reuse()
			return label
	# Pool exhausted, create new
	var label = _create_damage_label()
	label._reset_for_reuse()
	return label

func return_damage_number(label: Label3D) -> void:
	if not is_instance_valid(label):
		return
	label.visible = false
	if label.get_parent():
		label.get_parent().remove_child(label)
	_dmg_pool.append(label)

## Spawn a floating text label at a 3D position (for rewards, quest completion, etc.)
func spawn_damage_number(pos: Vector3, text: String, color: Color = Color.WHITE) -> void:
	var label = get_damage_number()
	if not label:
		return
	label.setup_text(text, color)
	var scene = Engine.get_main_loop().current_scene if Engine.get_main_loop() else null
	if not scene:
		return_damage_number(label)
		return
	if not label.is_inside_tree():
		scene.add_child(label)
	label.global_position = pos
	label.set_process(true)

# --- Particle spawn methods ---

## Cached FPS value — updated every 15 frames to avoid per-call overhead
var _cached_fps: float = 60.0
var _fps_cache_counter: int = 0

func _get_cached_fps() -> float:
	_fps_cache_counter += 1
	if _fps_cache_counter >= 15:
		_fps_cache_counter = 0
		_cached_fps = Engine.get_frames_per_second()
	return _cached_fps


func spawn_hit_particles(pos: Vector3, color: Color = Color.WHITE, count: int = 9) -> void:
	# Accessibility: reduce particles if reduced motion
	if AccessibilityManager.reduced_motion:
		count = maxi(1, int(count * 0.3))
	# Skip entirely at very low FPS — hit particles are the most frequent spawn
	var fps = _get_cached_fps()
	if fps < 35 and randf() > 0.15:
		return
	if fps < 25:
		return
	# Reduce count at medium-low FPS
	if fps < 45:
		count = mini(count, 4)
	var particles = _get_particle()
	var mat: ParticleProcessMaterial = particles.process_material
	mat.direction = Vector3(0, 1, 0)
	mat.spread = 180.0
	mat.initial_velocity_min = 2.0
	mat.initial_velocity_max = 5.0
	mat.gravity = Vector3(0, -8, 0)
	mat.scale_min = 0.05
	mat.scale_max = 0.156  # +30% bigger particles for more visual impact
	mat.color = color

	particles.amount = count
	particles.lifetime = 0.4
	particles.explosiveness = 1.0

	# Use shared draw pass (no per-emission allocation)
	particles.draw_pass_1 = _hit_draw_pass
	var draw_mat: StandardMaterial3D = _hit_draw_pass.surface_get_material(0)
	if draw_mat:
		draw_mat.albedo_color = color
		draw_mat.emission = color

	_setup_and_emit(particles, pos, 1.0)

	# Brief white flash particle for extra impact (skip at low FPS)
	if fps >= 45 and not AccessibilityManager.reduced_motion:
		_spawn_hit_flash(pos)

## Brief bright white flash particle that fades fast — adds impact punch to hits
func _spawn_hit_flash(pos: Vector3) -> void:
	var particles = _get_particle()
	var mat: ParticleProcessMaterial = particles.process_material
	mat.direction = Vector3(0, 1, 0)
	mat.spread = 180.0
	mat.initial_velocity_min = 0.5
	mat.initial_velocity_max = 1.5
	mat.gravity = Vector3(0, 0, 0)
	mat.scale_min = 0.15
	mat.scale_max = 0.25
	mat.color = Color(1.0, 1.0, 1.0, 0.9)

	particles.amount = 2
	particles.lifetime = 0.12  # Very brief bright flash
	particles.explosiveness = 1.0

	particles.draw_pass_1 = _hit_draw_pass
	var draw_mat: StandardMaterial3D = _hit_draw_pass.surface_get_material(0)
	if draw_mat:
		draw_mat.albedo_color = Color.WHITE
		draw_mat.emission = Color(1.0, 1.0, 1.0)
		draw_mat.emission_energy_multiplier = 5.0

	_setup_and_emit(particles, pos, 0.5)

	# Restore hit draw pass material after flash emits (next frame)
	await get_tree().process_frame
	if draw_mat:
		draw_mat.emission_energy_multiplier = 2.0

func spawn_death_particles(pos: Vector3, color: Color, count: int = 12) -> void:
	# Accessibility: reduce particles if reduced motion
	if AccessibilityManager.reduced_motion:
		count = maxi(2, int(count * 0.3))
	# Reduce particle count at low FPS
	var fps = _get_cached_fps()
	if fps < 25:
		count = 2
	elif fps < 35:
		count = 3
	elif fps < 45:
		count = mini(count, 5)
	var particles = _get_particle()
	var mat: ParticleProcessMaterial = particles.process_material
	mat.direction = Vector3(0, 1, 0)
	mat.spread = 180.0
	mat.initial_velocity_min = 3.0
	mat.initial_velocity_max = 8.0
	mat.gravity = Vector3(0, -6, 0)
	mat.scale_min = 0.08
	mat.scale_max = 0.2
	mat.color = color

	particles.amount = count
	particles.lifetime = 0.6
	particles.explosiveness = 1.0

	# Use shared draw pass (no per-emission allocation)
	particles.draw_pass_1 = _death_draw_pass
	var draw_mat: StandardMaterial3D = _death_draw_pass.surface_get_material(0)
	if draw_mat:
		draw_mat.albedo_color = color
		draw_mat.emission = color

	_setup_and_emit(particles, pos, 1.5)

func spawn_collect_particles(pos: Vector3, color: Color = Color(0.2, 0.6, 1.0)) -> void:
	# Accessibility: skip decorative collect particles if reduced motion
	if AccessibilityManager.reduced_motion:
		return
	# Skip collect particles at very low FPS
	if _get_cached_fps() < 30:
		return
	var particles = _get_particle()
	var mat: ParticleProcessMaterial = particles.process_material
	mat.direction = Vector3(0, 1, 0)
	mat.spread = 90.0  # Wider spread for more satisfying collection feel
	mat.initial_velocity_min = 1.5
	mat.initial_velocity_max = 4.0
	mat.gravity = Vector3(0, 2, 0)  # Sobe
	mat.scale_min = 0.03
	mat.scale_max = 0.08
	mat.color = color

	particles.amount = 5
	particles.lifetime = 0.5
	particles.explosiveness = 1.0

	# Use shared draw pass (no per-emission allocation)
	particles.draw_pass_1 = _collect_draw_pass
	var draw_mat: StandardMaterial3D = _collect_draw_pass.surface_get_material(0)
	if draw_mat:
		draw_mat.albedo_color = color
		draw_mat.emission = color

	_setup_and_emit(particles, pos, 1.0)

	# Subtle screen flash on XP collection for extra satisfaction
	if ScreenEffects and ScreenEffects.has_method("flash"):
		ScreenEffects.flash(0.1, 0.05)

func spawn_level_up_particles(pos: Vector3) -> void:
	# Accessibility: skip decorative level-up particles if reduced motion
	if AccessibilityManager.reduced_motion:
		return
	var color = Color(1.0, 0.9, 0.3)
	var particles = _get_particle()
	var mat: ParticleProcessMaterial = particles.process_material
	mat.direction = Vector3(0, 1, 0)
	mat.spread = 40.0
	mat.initial_velocity_min = 3.0
	mat.initial_velocity_max = 9.0  # Particles go higher
	mat.gravity = Vector3(0, -1, 0)  # Slight gravity so they arc
	mat.scale_min = 0.06
	mat.scale_max = 0.18
	mat.color = color

	particles.amount = 40  # Doubled for dramatic effect
	particles.lifetime = 1.2
	particles.explosiveness = 0.8

	# Use shared draw pass (no per-emission allocation)
	particles.draw_pass_1 = _levelup_draw_pass
	var draw_mat: StandardMaterial3D = _levelup_draw_pass.surface_get_material(0)
	if draw_mat:
		draw_mat.albedo_color = color
		draw_mat.emission = Color(1, 0.85, 0.2)

	_setup_and_emit(particles, pos, 2.5)

	# Gold ring shockwave expanding outward
	_spawn_level_up_ring(pos)

## Gold ring shockwave for level-up — expands outward and fades
func _spawn_level_up_ring(pos: Vector3) -> void:
	var scene = Engine.get_main_loop().current_scene if Engine.get_main_loop() else null
	if not scene:
		return
	var ring = MeshInstance3D.new()
	var torus = TorusMesh.new()
	torus.inner_radius = 0.3
	torus.outer_radius = 0.5
	torus.rings = 16
	torus.ring_segments = 24
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.85, 0.2, 0.8)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.85, 0.2)
	mat.emission_energy_multiplier = 4.0
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.no_depth_test = true
	torus.surface_set_material(0, mat)
	ring.mesh = torus
	scene.add_child(ring)
	ring.global_position = pos + Vector3(0, 0.1, 0)
	ring.rotation_degrees.x = 90.0  # Lay flat on the ground

	# Expand outward and fade
	var tween = ring.create_tween()
	tween.set_parallel(true)
	tween.tween_property(ring, "scale", Vector3(6.0, 6.0, 6.0), 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(mat, "albedo_color:a", 0.0, 0.6).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(ring.queue_free)

## Katana impact sparks — small bright white particles outward from slash point
func spawn_slash_sparks(pos: Vector3, count: int = 5) -> void:
	var color = Color(1.0, 1.0, 1.0)
	var particles = _get_particle()
	var mat: ParticleProcessMaterial = particles.process_material
	mat.direction = Vector3(0, 1, 0)
	mat.spread = 120.0
	mat.initial_velocity_min = 3.0
	mat.initial_velocity_max = 6.0
	mat.gravity = Vector3(0, -6, 0)
	mat.scale_min = 0.02
	mat.scale_max = 0.05
	mat.color = color

	particles.amount = count
	particles.lifetime = 0.15
	particles.explosiveness = 1.0

	particles.draw_pass_1 = _spark_draw_pass
	var draw_mat: StandardMaterial3D = _spark_draw_pass.surface_get_material(0)
	if draw_mat:
		draw_mat.albedo_color = color
		draw_mat.emission = color

	_setup_and_emit(particles, pos, 0.5)

## Cloud sword ground dust — brown/gray particles rising then falling
func spawn_ground_dust(pos: Vector3, count: int = 8) -> void:
	# Accessibility: skip decorative ground dust if reduced motion
	if AccessibilityManager.reduced_motion:
		return
	var color = Color(0.55, 0.45, 0.35, 0.6)
	var particles = _get_particle()
	var mat: ParticleProcessMaterial = particles.process_material
	mat.direction = Vector3(0, 1, 0)
	mat.spread = 45.0
	mat.initial_velocity_min = 1.0
	mat.initial_velocity_max = 2.5
	mat.gravity = Vector3(0, -3, 0)
	mat.scale_min = 0.06
	mat.scale_max = 0.15
	mat.color = color

	particles.amount = count
	particles.lifetime = 0.5
	particles.explosiveness = 0.9

	particles.draw_pass_1 = _dust_draw_pass
	var draw_mat: StandardMaterial3D = _dust_draw_pass.surface_get_material(0)
	if draw_mat:
		draw_mat.albedo_color = color
		draw_mat.emission = Color(0.45, 0.35, 0.25)

	_setup_and_emit(particles, pos, 1.0)

## Hammer debris — rocky bits flying outward
func spawn_hammer_debris(pos: Vector3, count: int = 12) -> void:
	# Accessibility: reduce particles if reduced motion
	if AccessibilityManager.reduced_motion:
		count = maxi(2, int(count * 0.3))
	var color = Color(0.5, 0.35, 0.2)
	var particles = _get_particle()
	var mat: ParticleProcessMaterial = particles.process_material
	mat.direction = Vector3(0, 1, 0)
	mat.spread = 60.0
	mat.initial_velocity_min = 2.0
	mat.initial_velocity_max = 5.0
	mat.gravity = Vector3(0, -8, 0)
	mat.scale_min = 0.03
	mat.scale_max = 0.08
	mat.color = color

	particles.amount = count
	particles.lifetime = 0.6
	particles.explosiveness = 1.0

	particles.draw_pass_1 = _debris_draw_pass
	var draw_mat: StandardMaterial3D = _debris_draw_pass.surface_get_material(0)
	if draw_mat:
		draw_mat.albedo_color = color
		draw_mat.emission = Color(0.4, 0.3, 0.15)

	_setup_and_emit(particles, pos, 1.5)

## Hammer dust cloud — rising brown-gray mist
func spawn_hammer_dust(pos: Vector3, count: int = 8) -> void:
	# Accessibility: skip decorative dust if reduced motion
	if AccessibilityManager.reduced_motion:
		return
	var color = Color(0.5, 0.45, 0.4, 0.4)
	var particles = _get_particle()
	var mat: ParticleProcessMaterial = particles.process_material
	mat.direction = Vector3(0, 1, 0)
	mat.spread = 40.0
	mat.initial_velocity_min = 0.5
	mat.initial_velocity_max = 1.5
	mat.gravity = Vector3(0, 0.5, 0)
	mat.scale_min = 0.1
	mat.scale_max = 0.3
	mat.color = color

	particles.amount = count
	particles.lifetime = 0.8
	particles.explosiveness = 0.8

	particles.draw_pass_1 = _dust_draw_pass
	var draw_mat: StandardMaterial3D = _dust_draw_pass.surface_get_material(0)
	if draw_mat:
		draw_mat.albedo_color = color
		draw_mat.emission = Color(0.4, 0.35, 0.3)

	_setup_and_emit(particles, pos, 1.5)

## Whip crack spark — small white spark on enemy hit
func spawn_whip_spark(pos: Vector3) -> void:
	var color = Color(1.0, 0.9, 0.7)
	var particles = _get_particle()
	var mat: ParticleProcessMaterial = particles.process_material
	mat.direction = Vector3(0, 1, 0)
	mat.spread = 90.0
	mat.initial_velocity_min = 1.5
	mat.initial_velocity_max = 3.0
	mat.gravity = Vector3(0, -5, 0)
	mat.scale_min = 0.02
	mat.scale_max = 0.04
	mat.color = color

	particles.amount = 3
	particles.lifetime = 0.12
	particles.explosiveness = 1.0

	particles.draw_pass_1 = _spark_draw_pass
	var draw_mat: StandardMaterial3D = _spark_draw_pass.surface_get_material(0)
	if draw_mat:
		draw_mat.albedo_color = color
		draw_mat.emission = color

	_setup_and_emit(particles, pos, 0.5)

## Spawn a reward text for chest collection with type-specific color.
## Colors: Gold for crystals, Light blue for XP, Green for HP, Purple for reroll.
func spawn_chest_reward_text(position: Vector3, text: String, color: Color) -> void:
	var label = get_damage_number()
	if not label:
		return
	var elevated_pos = Vector3(position.x, position.y + 1.5, position.z)
	label.setup_text(text, color)
	var scene = Engine.get_main_loop().current_scene if Engine.get_main_loop() else null
	if not scene:
		return_damage_number(label)
		return
	if not label.is_inside_tree():
		scene.add_child(label)
	label.global_position = elevated_pos
	label.set_process(true)
	# Extra upward float + fade for chest rewards (0.8s)
	var tw = create_tween()
	tw.tween_property(label, "global_position:y", elevated_pos.y + 1.0, 0.8).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tw.parallel().tween_property(label, "modulate:a", 0.0, 0.8).set_ease(Tween.EASE_IN)
	tw.tween_callback(func(): return_damage_number(label))

func spawn_explosion_particles(pos: Vector3, radius: float = 3.0) -> void:
	var color = Color(1.0, 0.5, 0.1)
	var explosion_count := 15
	var explosion_lifetime := 0.6
	# Accessibility: reduce explosion particles if reduced motion
	if AccessibilityManager.reduced_motion:
		explosion_count = 4
		explosion_lifetime = 0.3
	var particles = _get_particle()
	var mat: ParticleProcessMaterial = particles.process_material
	mat.direction = Vector3(0, 1, 0)
	mat.spread = 180.0
	mat.initial_velocity_min = radius * 2
	mat.initial_velocity_max = radius * 4
	mat.gravity = Vector3(0, -4, 0)
	mat.scale_min = 0.1
	mat.scale_max = 0.3
	mat.color = color

	particles.amount = explosion_count
	particles.lifetime = explosion_lifetime
	particles.explosiveness = 1.0

	# Use shared draw pass (no per-emission allocation)
	particles.draw_pass_1 = _explosion_draw_pass
	var draw_mat: StandardMaterial3D = _explosion_draw_pass.surface_get_material(0)
	if draw_mat:
		draw_mat.albedo_color = color
		draw_mat.emission = Color(1, 0.4, 0.05)

	_setup_and_emit(particles, pos, 1.5)

## Weapon impact sparks — colored sparks at hit position
func spawn_weapon_sparks(pos: Vector3, color: Color, count: int = 4) -> void:
	var particles = _get_particle()
	var mat: ParticleProcessMaterial = particles.process_material
	mat.direction = Vector3(0, 1, 0)
	mat.spread = 100.0
	mat.initial_velocity_min = 2.5
	mat.initial_velocity_max = 5.0
	mat.gravity = Vector3(0, -7, 0)
	mat.scale_min = 0.02
	mat.scale_max = 0.04
	mat.color = color

	particles.amount = count
	particles.lifetime = 0.15
	particles.explosiveness = 1.0

	particles.draw_pass_1 = _spark_draw_pass
	var draw_mat: StandardMaterial3D = _spark_draw_pass.surface_get_material(0)
	if draw_mat:
		draw_mat.albedo_color = color
		draw_mat.emission = color

	_setup_and_emit(particles, pos, 0.5)

# ==================================================================
# PRD 60: Elemental Death Effects
# ==================================================================

## Spawn element-specific death particles based on damage type.
## Each element has unique direction, velocity, color, and behavior.
func spawn_elemental_death(pos: Vector3, element: String, count: int = 12) -> void:
	# Accessibility: reduce particles if reduced motion
	if AccessibilityManager.reduced_motion:
		count = maxi(2, int(count * 0.3))
	# Reduce at low FPS
	var fps = _get_cached_fps()
	if fps < 25:
		count = 2
	elif fps < 35:
		count = 3
	elif fps < 45:
		count = mini(count, 6)

	match element:
		"fire":
			_spawn_fire_death(pos, count)
		"ice":
			_spawn_ice_death(pos, count)
		"electric":
			_spawn_electric_death(pos, count)
		"dark":
			_spawn_dark_death(pos, count)
		"poison":
			_spawn_poison_death(pos, count)
		_:
			# Physical / unknown — use default death particles (white/gray poof)
			spawn_death_particles(pos, Color(0.85, 0.85, 0.8), count)

## Fire death: orange/red particles burst upward like flames
func _spawn_fire_death(pos: Vector3, count: int) -> void:
	var color = Color(1.0, 0.45, 0.1)
	var particles = _get_particle()
	var mat: ParticleProcessMaterial = particles.process_material
	mat.direction = Vector3(0, 1, 0)
	mat.spread = 40.0
	mat.initial_velocity_min = 4.0
	mat.initial_velocity_max = 9.0
	mat.gravity = Vector3(0, 2, 0)  # Fire rises
	mat.scale_min = 0.06
	mat.scale_max = 0.18
	mat.color = color

	particles.amount = count
	particles.lifetime = 0.7
	particles.explosiveness = 0.9

	particles.draw_pass_1 = _death_draw_pass
	var draw_mat: StandardMaterial3D = _death_draw_pass.surface_get_material(0)
	if draw_mat:
		draw_mat.albedo_color = color
		draw_mat.emission = Color(1.0, 0.3, 0.05)

	_setup_and_emit(particles, pos, 1.2)

	# Secondary ember particles (smaller, slower, more spread)
	if count >= 4:
		var embers = _get_particle()
		var emat: ParticleProcessMaterial = embers.process_material
		emat.direction = Vector3(0, 1, 0)
		emat.spread = 80.0
		emat.initial_velocity_min = 1.5
		emat.initial_velocity_max = 4.0
		emat.gravity = Vector3(0, 1.5, 0)
		emat.scale_min = 0.02
		emat.scale_max = 0.06
		emat.color = Color(1.0, 0.7, 0.2)

		embers.amount = mini(count, 6)
		embers.lifetime = 0.9
		embers.explosiveness = 0.7

		embers.draw_pass_1 = _spark_draw_pass
		var smat: StandardMaterial3D = _spark_draw_pass.surface_get_material(0)
		if smat:
			smat.albedo_color = Color(1.0, 0.7, 0.2)
			smat.emission = Color(1.0, 0.6, 0.1)

		_setup_and_emit(embers, pos + Vector3(0, 0.1, 0), 1.5)

## Ice death: blue/white shards scatter outward like shattering
func _spawn_ice_death(pos: Vector3, count: int) -> void:
	var color = Color(0.5, 0.85, 1.0)
	var particles = _get_particle()
	var mat: ParticleProcessMaterial = particles.process_material
	mat.direction = Vector3(0, 0.3, 0)
	mat.spread = 180.0
	mat.initial_velocity_min = 5.0
	mat.initial_velocity_max = 10.0
	mat.gravity = Vector3(0, -12, 0)  # Heavy shards fall fast
	mat.scale_min = 0.04
	mat.scale_max = 0.14
	mat.color = color

	particles.amount = count
	particles.lifetime = 0.5
	particles.explosiveness = 1.0

	particles.draw_pass_1 = _death_draw_pass
	var draw_mat: StandardMaterial3D = _death_draw_pass.surface_get_material(0)
	if draw_mat:
		draw_mat.albedo_color = color
		draw_mat.emission = Color(0.6, 0.9, 1.0)

	_setup_and_emit(particles, pos, 1.0)

	# Secondary frost mist (slow, rising, fading)
	if count >= 4:
		var mist = _get_particle()
		var mmat: ParticleProcessMaterial = mist.process_material
		mmat.direction = Vector3(0, 1, 0)
		mmat.spread = 60.0
		mmat.initial_velocity_min = 0.5
		mmat.initial_velocity_max = 1.5
		mmat.gravity = Vector3(0, 0.5, 0)
		mmat.scale_min = 0.1
		mmat.scale_max = 0.25
		mmat.color = Color(0.7, 0.9, 1.0, 0.5)

		mist.amount = mini(count, 4)
		mist.lifetime = 0.6
		mist.explosiveness = 0.6

		mist.draw_pass_1 = _dust_draw_pass
		var dmat: StandardMaterial3D = _dust_draw_pass.surface_get_material(0)
		if dmat:
			dmat.albedo_color = Color(0.7, 0.9, 1.0, 0.4)
			dmat.emission = Color(0.5, 0.7, 0.9)

		_setup_and_emit(mist, pos + Vector3(0, 0.2, 0), 1.2)

## Electric death: yellow/cyan sparks jittering outward
func _spawn_electric_death(pos: Vector3, count: int) -> void:
	var color = Color(1.0, 1.0, 0.3)
	var particles = _get_particle()
	var mat: ParticleProcessMaterial = particles.process_material
	mat.direction = Vector3(0, 0.5, 0)
	mat.spread = 180.0
	mat.initial_velocity_min = 6.0
	mat.initial_velocity_max = 12.0
	mat.gravity = Vector3(0, -3, 0)
	mat.scale_min = 0.02
	mat.scale_max = 0.06
	mat.color = color

	particles.amount = count
	particles.lifetime = 0.35
	particles.explosiveness = 1.0

	particles.draw_pass_1 = _spark_draw_pass
	var spark_mat: StandardMaterial3D = _spark_draw_pass.surface_get_material(0)
	if spark_mat:
		spark_mat.albedo_color = color
		spark_mat.emission = Color(0.8, 1.0, 1.0)

	_setup_and_emit(particles, pos, 0.8)

	# Secondary cyan arc particles
	if count >= 4:
		var arcs = _get_particle()
		var amat: ParticleProcessMaterial = arcs.process_material
		amat.direction = Vector3(0, 1, 0)
		amat.spread = 150.0
		amat.initial_velocity_min = 3.0
		amat.initial_velocity_max = 7.0
		amat.gravity = Vector3(0, -5, 0)
		amat.scale_min = 0.01
		amat.scale_max = 0.04
		amat.color = Color(0.3, 1.0, 1.0)

		arcs.amount = mini(count, 8)
		arcs.lifetime = 0.25
		arcs.explosiveness = 0.8

		arcs.draw_pass_1 = _spark_draw_pass

		_setup_and_emit(arcs, pos, 0.6)

## Dark death: purple/black wisps rising upward (dissolve)
func _spawn_dark_death(pos: Vector3, count: int) -> void:
	var color = Color(0.6, 0.2, 0.8)
	var particles = _get_particle()
	var mat: ParticleProcessMaterial = particles.process_material
	mat.direction = Vector3(0, 1, 0)
	mat.spread = 30.0
	mat.initial_velocity_min = 2.0
	mat.initial_velocity_max = 5.0
	mat.gravity = Vector3(0, 3, 0)  # Wisps float upward
	mat.scale_min = 0.08
	mat.scale_max = 0.22
	mat.color = color

	particles.amount = count
	particles.lifetime = 0.8
	particles.explosiveness = 0.6  # Staggered emission for wispy look

	particles.draw_pass_1 = _death_draw_pass
	var death_mat: StandardMaterial3D = _death_draw_pass.surface_get_material(0)
	if death_mat:
		death_mat.albedo_color = color
		death_mat.emission = Color(0.5, 0.1, 0.7)

	_setup_and_emit(particles, pos, 1.5)

	# Secondary dark core particles (smaller, faster rise)
	if count >= 4:
		var core = _get_particle()
		var cmat: ParticleProcessMaterial = core.process_material
		cmat.direction = Vector3(0, 1, 0)
		cmat.spread = 15.0
		cmat.initial_velocity_min = 3.0
		cmat.initial_velocity_max = 6.0
		cmat.gravity = Vector3(0, 4, 0)
		cmat.scale_min = 0.03
		cmat.scale_max = 0.08
		cmat.color = Color(0.3, 0.05, 0.4)

		core.amount = mini(count, 5)
		core.lifetime = 0.6
		core.explosiveness = 0.5

		core.draw_pass_1 = _spark_draw_pass
		var core_mat: StandardMaterial3D = _spark_draw_pass.surface_get_material(0)
		if core_mat:
			core_mat.albedo_color = Color(0.3, 0.05, 0.4)
			core_mat.emission = Color(0.4, 0.1, 0.6)

		_setup_and_emit(core, pos + Vector3(0, 0.3, 0), 1.2)

## Poison death: green bubbles and dripping particles downward
func _spawn_poison_death(pos: Vector3, count: int) -> void:
	var color = Color(0.3, 0.9, 0.2)
	var particles = _get_particle()
	var mat: ParticleProcessMaterial = particles.process_material
	mat.direction = Vector3(0, -0.5, 0)
	mat.spread = 120.0
	mat.initial_velocity_min = 1.5
	mat.initial_velocity_max = 4.0
	mat.gravity = Vector3(0, -6, 0)  # Drips downward
	mat.scale_min = 0.05
	mat.scale_max = 0.15
	mat.color = color

	particles.amount = count
	particles.lifetime = 0.7
	particles.explosiveness = 0.7

	particles.draw_pass_1 = _death_draw_pass
	var poison_mat: StandardMaterial3D = _death_draw_pass.surface_get_material(0)
	if poison_mat:
		poison_mat.albedo_color = color
		poison_mat.emission = Color(0.2, 0.8, 0.1)

	_setup_and_emit(particles, pos, 1.2)

	# Secondary bubble particles (round, rising briefly then falling)
	if count >= 4:
		var bubbles = _get_particle()
		var bmat: ParticleProcessMaterial = bubbles.process_material
		bmat.direction = Vector3(0, 0.5, 0)
		bmat.spread = 90.0
		bmat.initial_velocity_min = 1.0
		bmat.initial_velocity_max = 3.0
		bmat.gravity = Vector3(0, -4, 0)
		bmat.scale_min = 0.04
		bmat.scale_max = 0.1
		bmat.color = Color(0.4, 1.0, 0.3, 0.7)

		bubbles.amount = mini(count, 6)
		bubbles.lifetime = 0.5
		bubbles.explosiveness = 0.5

		bubbles.draw_pass_1 = _collect_draw_pass
		var bubble_mat: StandardMaterial3D = _collect_draw_pass.surface_get_material(0)
		if bubble_mat:
			bubble_mat.albedo_color = Color(0.4, 1.0, 0.3, 0.7)
			bubble_mat.emission = Color(0.3, 0.8, 0.2)

		_setup_and_emit(bubbles, pos + Vector3(0, 0.4, 0), 1.0)
