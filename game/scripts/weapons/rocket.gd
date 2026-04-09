extends Area3D

## Projetil da Bazuca. Vai ate o alvo e explode em area.

@export var speed: float = 12.0
@export var damage: int = 30
@export var explosion_radius: float = 3.0

var target_pos: Vector3 = Vector3.ZERO
var direction: Vector3 = Vector3.FORWARD
var _sprite: Sprite3D = null
var _lifetime: float = 0.0
const MAX_LIFETIME := 5.0  # Despawn after 5 seconds to prevent memory leak

# Cached materials — lazy-initialized once, reused across explosions
var _flash_mat: StandardMaterial3D = null
var _fireball_mat: StandardMaterial3D = null
var _shockwave_mat: StandardMaterial3D = null
var _spark_mat: StandardMaterial3D = null

var _direction_initialized: bool = false

func _ready() -> void:
	# Direction is calculated in first _physics_process frame
	# because global_position may not be set yet during add_child
	_setup_billboard_sprite()
	# Smoke trail behind rocket
	var trail = Node3D.new()
	trail.set_script(preload("res://scripts/effects/weapon_trail.gd"))
	trail.trail_color = Color(0.5, 0.4, 0.3, 0.6)
	trail.trail_color_tip = Color(1.0, 0.5, 0.1, 0.8)
	trail.max_points = 20
	trail.trail_width = 0.15
	add_child(trail)

## Called by bazooka.gd after setting target_pos and global_position.
## Resets state for ObjectPool reuse — ensures direction is recalculated.
func initialize() -> void:
	_direction_initialized = false
	_lifetime = 0.0
	visible = true
	set_physics_process(true)

func _setup_billboard_sprite() -> void:
	# Guard: nao recria sprite se ja existe
	if _sprite and is_instance_valid(_sprite):
		_update_sprite_rotation()
		return
	_sprite = get_node_or_null("ProjectileSprite")
	if _sprite:
		_update_sprite_rotation()
		return
	var sprite_path = "res://assets/sprites/projectiles/rocket.png"
	if ResourceLoader.exists(sprite_path):
		var existing_mesh = get_node_or_null("Mesh")
		if not existing_mesh:
			existing_mesh = get_node_or_null("MeshInstance3D")
		if existing_mesh:
			existing_mesh.visible = false
		var sprite = Sprite3D.new()
		sprite.texture = load(sprite_path)
		sprite.billboard = BaseMaterial3D.BILLBOARD_DISABLED
		sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		sprite.pixel_size = 0.04
		sprite.shaded = false
		sprite.transparent = true
		sprite.name = "ProjectileSprite"
		# Deita no plano XZ (top-down)
		sprite.rotation.x = -PI / 2.0
		add_child(sprite)
		_sprite = sprite
		_update_sprite_rotation()

func _update_sprite_rotation() -> void:
	if not _sprite:
		return
	# Sprite tem ponta fina em -X, soma PI pra apontar na direcao de viagem
	var angle = atan2(-direction.z, direction.x) + PI
	_sprite.rotation.z = angle

func _physics_process(delta: float) -> void:
	# Calcula direcao 1x no primeiro frame (global_position agora eh valida)
	if not _direction_initialized:
		_direction_initialized = true
		# RESET: limpa rotacao residual de reuso anterior
		transform.basis = Basis()
		direction = (target_pos - global_position).normalized()
		direction.y = 0
		_update_sprite_rotation()

	# Lifetime safety — despawn if stuck or target unreachable
	_lifetime += delta
	if _lifetime >= MAX_LIFETIME:
		_explode()
		return

	# Movimento reto — sem manipulacao de rotacao aqui
	global_position += direction * speed * delta

	# Chegou no alvo
	var flat_pos = Vector3(global_position.x, 0, global_position.z)
	var flat_target = Vector3(target_pos.x, 0, target_pos.z)
	if flat_pos.distance_to(flat_target) < 0.5:
		_explode()

func _explode() -> void:
	# Dano em area (spatial grid: O(1) instead of O(n))
	var nearby = GameManager.get_enemies_in_radius(global_position, explosion_radius)
	for e in nearby:
		if not is_instance_valid(e):
			continue
		if e.has_method("take_damage"):
			GameManager._last_attacking_weapon = "bazooka"
			e.call_deferred("take_damage", damage, "fire")

	AudioManager.play_sfx("explosion")
	# Epic explosion screen feedback
	ScreenEffects.shake(0.5)
	ScreenEffects.flash(0.06, 0.2)

	# --- Multi-layer explosion ---
	var explosion_root = Node3D.new()
	get_tree().current_scene.add_child(explosion_root)
	explosion_root.global_position = global_position

	_create_flash(explosion_root)
	_create_fireball(explosion_root)
	_create_shockwave(explosion_root)
	_create_smoke_particles(explosion_root)
	_create_spark_particles(explosion_root)

	# Cleanup root after all animations finish
	var cleanup_tween = explosion_root.create_tween()
	cleanup_tween.tween_interval(2.0)
	cleanup_tween.tween_callback(explosion_root.queue_free)

	queue_free()

# Layer 1: Bright white flash
func _create_flash(parent: Node3D) -> void:
	var mesh_inst = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 0.5
	sphere.height = 1.0
	mesh_inst.mesh = sphere

	if not _flash_mat:
		_flash_mat = StandardMaterial3D.new()
		_flash_mat.albedo_color = Color(1, 1, 1, 1)
		_flash_mat.emission_enabled = true
		_flash_mat.emission = Color(1, 1, 1, 1)
		_flash_mat.emission_energy_multiplier = 16.0
		_flash_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_flash_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mesh_inst.set_surface_override_material(0, _flash_mat)

	mesh_inst.scale = Vector3(0.1, 0.1, 0.1)
	parent.add_child(mesh_inst)

	var tween = mesh_inst.create_tween()
	tween.tween_property(mesh_inst, "scale", Vector3.ONE, 0.05)
	tween.tween_callback(mesh_inst.hide)

# Layer 2: Fireball (orange/red expanding sphere)
func _create_fireball(parent: Node3D) -> void:
	var mesh_inst = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 0.5
	sphere.height = 1.0
	mesh_inst.mesh = sphere

	if not _fireball_mat:
		_fireball_mat = StandardMaterial3D.new()
		_fireball_mat.emission_enabled = true
		_fireball_mat.emission = Color(1.0, 0.4, 0.1, 1)
		_fireball_mat.emission_energy_multiplier = 3.0
		_fireball_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_fireball_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	# Reset albedo for this explosion (tween fades it to 0)
	_fireball_mat.albedo_color = Color(1.0, 0.4, 0.1, 0.8)
	mesh_inst.set_surface_override_material(0, _fireball_mat)

	var start_scale = 0.3
	var end_scale = explosion_radius
	mesh_inst.scale = Vector3(start_scale, start_scale, start_scale)
	parent.add_child(mesh_inst)

	var tween = mesh_inst.create_tween()
	tween.set_parallel(true)
	tween.tween_property(mesh_inst, "scale", Vector3(end_scale, end_scale, end_scale), 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
	tween.tween_property(_fireball_mat, "albedo_color", Color(1.0, 0.4, 0.1, 0.0), 0.4)
	tween.set_parallel(false)
	tween.tween_callback(mesh_inst.queue_free)

# Layer 3: Shockwave ring (expanding torus)
func _create_shockwave(parent: Node3D) -> void:
	var mesh_inst = MeshInstance3D.new()
	var torus = TorusMesh.new()
	torus.inner_radius = 0.4
	torus.outer_radius = 0.5
	mesh_inst.mesh = torus

	if not _shockwave_mat:
		_shockwave_mat = StandardMaterial3D.new()
		_shockwave_mat.emission_enabled = true
		_shockwave_mat.emission = Color(1, 1, 1, 1)
		_shockwave_mat.emission_energy_multiplier = 3.0
		_shockwave_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_shockwave_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_shockwave_mat.no_depth_test = true
	# Reset albedo for this explosion (tween fades it to 0)
	_shockwave_mat.albedo_color = Color(1, 1, 1, 0.3)
	mesh_inst.set_surface_override_material(0, _shockwave_mat)

	mesh_inst.scale = Vector3(0.1, 0.1, 0.1)
	parent.add_child(mesh_inst)

	var final_s = explosion_radius
	var tween = mesh_inst.create_tween()
	tween.set_parallel(true)
	tween.tween_property(mesh_inst, "scale", Vector3(final_s, final_s * 0.3, final_s), 0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
	tween.tween_property(_shockwave_mat, "albedo_color", Color(1, 1, 1, 0.0), 0.25)
	tween.set_parallel(false)
	tween.tween_callback(mesh_inst.queue_free)

# Layer 4: Smoke particles rising (reduced count for performance)
func _create_smoke_particles(parent: Node3D) -> void:
	var particles = GPUParticles3D.new()
	particles.amount = 10
	particles.lifetime = 1.0
	particles.one_shot = true
	particles.explosiveness = 0.9
	particles.emitting = true

	var proc_mat = ParticleProcessMaterial.new()
	proc_mat.direction = Vector3(0, 1, 0)
	proc_mat.spread = 40.0
	proc_mat.initial_velocity_min = 1.0
	proc_mat.initial_velocity_max = 2.5
	proc_mat.gravity = Vector3(0, -0.3, 0)
	proc_mat.scale_min = 1.0
	proc_mat.scale_max = 2.5
	proc_mat.damping_min = 1.0
	proc_mat.damping_max = 2.0
	proc_mat.color = Color(0.4, 0.4, 0.4, 0.5)
	particles.process_material = proc_mat

	var draw_mesh = SphereMesh.new()
	draw_mesh.radius = 0.15
	draw_mesh.height = 0.3
	particles.draw_pass_1 = draw_mesh

	parent.add_child(particles)

# Layer 5: Sparks flying outward
func _create_spark_particles(parent: Node3D) -> void:
	var particles = GPUParticles3D.new()
	particles.amount = 18
	particles.lifetime = 0.5
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.emitting = true

	var proc_mat = ParticleProcessMaterial.new()
	proc_mat.direction = Vector3(0, 1, 0)
	proc_mat.spread = 180.0
	proc_mat.initial_velocity_min = 5.0
	proc_mat.initial_velocity_max = 10.0
	proc_mat.gravity = Vector3(0, -5.0, 0)
	proc_mat.scale_min = 0.3
	proc_mat.scale_max = 0.6
	proc_mat.damping_min = 2.0
	proc_mat.damping_max = 4.0
	proc_mat.color = Color(1.0, 0.5, 0.0, 1.0)
	particles.process_material = proc_mat

	var draw_mesh = SphereMesh.new()
	draw_mesh.radius = 0.03
	draw_mesh.height = 0.06
	if not _spark_mat:
		_spark_mat = StandardMaterial3D.new()
		_spark_mat.albedo_color = Color(1.0, 0.6, 0.1, 1.0)
		_spark_mat.emission_enabled = true
		_spark_mat.emission = Color(1.0, 0.5, 0.0, 1)
		_spark_mat.emission_energy_multiplier = 8.0
		_spark_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	draw_mesh.material = _spark_mat
	particles.draw_pass_1 = draw_mesh

	parent.add_child(particles)
