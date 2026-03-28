extends Node

## Fabrica de particulas. Cria efeitos visuais em posicoes 3D.
## Usa pool para evitar alocacoes constantes (performance com 500+ inimigos).

# --- Particle Pool ---
const PARTICLE_POOL_SIZE := 30
const MAX_ACTIVE_PARTICLES := 50  # Global budget: max simultaneous particle systems
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
	# Draw pass with a default sphere mesh + material
	var draw_pass = SphereMesh.new()
	draw_pass.radius = 0.08
	draw_pass.height = 0.16
	var draw_mat = StandardMaterial3D.new()
	draw_mat.emission_enabled = true
	draw_mat.emission_energy_multiplier = 2.0
	draw_pass.surface_set_material(0, draw_mat)
	particles.draw_pass_1 = draw_pass
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

	particles.global_position = pos
	particles.emitting = true

	# Schedule return to pool
	_active_particles[particles] = cleanup_time
	var tween = create_tween()
	tween.tween_callback(_return_particle.bind(particles)).set_delay(cleanup_time)

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

# --- Particle spawn methods ---

func spawn_hit_particles(pos: Vector3, color: Color = Color.WHITE, count: int = 6) -> void:
	# Skip entirely at very low FPS — hit particles are the most frequent spawn
	var fps = Engine.get_frames_per_second()
	if fps < 30 and randf() > 0.2:
		return
	if fps < 20:
		return
	var particles = _get_particle()
	var mat: ParticleProcessMaterial = particles.process_material
	mat.direction = Vector3(0, 1, 0)
	mat.spread = 180.0
	mat.initial_velocity_min = 2.0
	mat.initial_velocity_max = 5.0
	mat.gravity = Vector3(0, -8, 0)
	mat.scale_min = 0.05
	mat.scale_max = 0.12
	mat.color = color

	particles.amount = count
	particles.lifetime = 0.4
	particles.explosiveness = 1.0

	# Update draw pass
	var draw_pass = particles.draw_pass_1
	if draw_pass:
		if not draw_pass is SphereMesh:
			draw_pass = SphereMesh.new()
			draw_pass.radius = 0.08
			draw_pass.height = 0.16
			var draw_mat = StandardMaterial3D.new()
			draw_mat.emission_enabled = true
			draw_pass.surface_set_material(0, draw_mat)
			particles.draw_pass_1 = draw_pass
		var draw_mat: StandardMaterial3D = draw_pass.surface_get_material(0)
		if draw_mat:
			draw_mat.albedo_color = color
			draw_mat.emission = color
			draw_mat.emission_energy_multiplier = 2.0

	_setup_and_emit(particles, pos, 1.0)

func spawn_death_particles(pos: Vector3, color: Color, count: int = 12) -> void:
	# Reduce particle count at low FPS
	var fps = Engine.get_frames_per_second()
	if fps < 25:
		count = 3
	elif fps < 40:
		count = mini(count, 6)
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

	# Use box mesh for death particles
	var draw_pass = particles.draw_pass_1
	if not draw_pass is BoxMesh:
		draw_pass = BoxMesh.new()
		draw_pass.size = Vector3(0.1, 0.1, 0.1)
		var draw_mat = StandardMaterial3D.new()
		draw_mat.emission_enabled = true
		draw_pass.surface_set_material(0, draw_mat)
		particles.draw_pass_1 = draw_pass
	var draw_mat: StandardMaterial3D = draw_pass.surface_get_material(0)
	if draw_mat:
		draw_mat.albedo_color = color
		draw_mat.emission = color
		draw_mat.emission_energy_multiplier = 1.5

	_setup_and_emit(particles, pos, 1.5)

func spawn_collect_particles(pos: Vector3, color: Color = Color(0.2, 0.6, 1.0)) -> void:
	var particles = _get_particle()
	var mat: ParticleProcessMaterial = particles.process_material
	mat.direction = Vector3(0, 1, 0)
	mat.spread = 60.0
	mat.initial_velocity_min = 1.0
	mat.initial_velocity_max = 3.0
	mat.gravity = Vector3(0, 2, 0)  # Sobe
	mat.scale_min = 0.03
	mat.scale_max = 0.08
	mat.color = color

	particles.amount = 4
	particles.lifetime = 0.5
	particles.explosiveness = 1.0

	var draw_pass = particles.draw_pass_1
	if draw_pass:
		if not draw_pass is SphereMesh:
			draw_pass = SphereMesh.new()
			draw_pass.radius = 0.05
			draw_pass.height = 0.1
			var draw_mat = StandardMaterial3D.new()
			draw_mat.emission_enabled = true
			draw_pass.surface_set_material(0, draw_mat)
			particles.draw_pass_1 = draw_pass
		var draw_mat: StandardMaterial3D = draw_pass.surface_get_material(0)
		if draw_mat:
			draw_mat.albedo_color = color
			draw_mat.emission = color
			draw_mat.emission_energy_multiplier = 3.0

	_setup_and_emit(particles, pos, 1.0)

func spawn_level_up_particles(pos: Vector3) -> void:
	var color = Color(1.0, 0.9, 0.3)
	var particles = _get_particle()
	var mat: ParticleProcessMaterial = particles.process_material
	mat.direction = Vector3(0, 1, 0)
	mat.spread = 30.0
	mat.initial_velocity_min = 2.0
	mat.initial_velocity_max = 6.0
	mat.gravity = Vector3(0, 0, 0)
	mat.scale_min = 0.05
	mat.scale_max = 0.15
	mat.color = color

	particles.amount = 20
	particles.lifetime = 1.0
	particles.explosiveness = 0.8

	var draw_pass = particles.draw_pass_1
	if draw_pass:
		if not draw_pass is SphereMesh:
			draw_pass = SphereMesh.new()
			draw_pass.radius = 0.06
			draw_pass.height = 0.12
			var draw_mat = StandardMaterial3D.new()
			draw_mat.emission_enabled = true
			draw_pass.surface_set_material(0, draw_mat)
			particles.draw_pass_1 = draw_pass
		var draw_mat: StandardMaterial3D = draw_pass.surface_get_material(0)
		if draw_mat:
			draw_mat.albedo_color = color
			draw_mat.emission = Color(1, 0.85, 0.2)
			draw_mat.emission_energy_multiplier = 3.0

	_setup_and_emit(particles, pos, 2.0)

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

func spawn_explosion_particles(pos: Vector3, radius: float = 3.0) -> void:
	var color = Color(1.0, 0.5, 0.1)
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

	particles.amount = 15
	particles.lifetime = 0.6
	particles.explosiveness = 1.0

	var draw_pass = particles.draw_pass_1
	if draw_pass:
		if not draw_pass is SphereMesh:
			draw_pass = SphereMesh.new()
			draw_pass.radius = 0.1
			draw_pass.height = 0.2
			var draw_mat = StandardMaterial3D.new()
			draw_mat.emission_enabled = true
			draw_pass.surface_set_material(0, draw_mat)
			particles.draw_pass_1 = draw_pass
		var draw_mat: StandardMaterial3D = draw_pass.surface_get_material(0)
		if draw_mat:
			draw_mat.albedo_color = color
			draw_mat.emission = Color(1, 0.4, 0.05)
			draw_mat.emission_energy_multiplier = 4.0

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
