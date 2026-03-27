extends CharacterBody3D
class_name EnemyBase3D

## Inimigo base 3D. Persegue jogador, dano por contato, damage numbers, particulas, knockback.

@export var speed: float = 4.0
@export var max_hp: int = 20
@export var damage: int = 10
@export var xp_drop: int = 1
@export var enemy_color: Color = Color(0.8, 0.2, 0.2)

## Resistencias por tipo de dano. 0.5 = resistente, 1.0 = normal, 1.5 = fraco.
@export var resistances: Dictionary = {}

var hp: int = 20
var target: Node3D = null
var is_dead: bool = false
var knockback_velocity: Vector3 = Vector3.ZERO
var _animator: Node = null
var _hit_count: int = 0

@onready var mesh: MeshInstance3D = $Mesh
@onready var hitbox: Area3D = $Hitbox

func _ready() -> void:
	# Multiplayer HP scaling
	var hp_mult = GameManager.get_mp_hp_mult()
	max_hp = int(max_hp * hp_mult)
	hp = max_hp
	add_to_group("enemies")
	# Mutation: furious bosses — start at 75% HP (phase 2)
	# Applied after boss subclass _ready() via deferred call
	call_deferred("_apply_furious_boss_mutation")
	# Desativa colisao fisica com player para evitar empurrar o jogador
	# Dano por contato e detectado via Area3D (Hitbox)
	collision_mask = 0
	hitbox.body_entered.connect(_on_body_entered)
	# Substitui mesh simples por modelo procedural
	_apply_procedural_model()

func _get_base_enemy_type() -> String:
	## Derive the base enemy type from the scene file path, not from `name`
	## which may have been overwritten by stage skins (e.g. "Mushroom Slime").
	## "res://scenes/enemies/slime.tscn" -> "Slime"
	## "res://scenes/enemies/zombie_runner.tscn" -> "ZombieRunner"
	if scene_file_path and not scene_file_path.is_empty():
		var file = scene_file_path.get_file().get_basename()  # e.g. "zombie_runner"
		# Convert snake_case to PascalCase
		var parts = file.split("_")
		var result = ""
		for p in parts:
			if p.length() > 0:
				result += p[0].to_upper() + p.substr(1)
		return result
	return name

func _apply_procedural_model() -> void:
	var enemy_type = _get_base_enemy_type()
	var model = ModelFactory.get_model_for_enemy(enemy_type)
	if model.get_child_count() > 0:
		mesh.visible = false
		model.name = "ProceduralModel"
		add_child(model)
		ModelFactory.apply_model_materials(model, enemy_color)
		_animator = preload("res://scripts/effects/procedural_animator.gd").new()
		_animator.setup(model)
		add_child(_animator)
	else:
		VisualSetup.apply_cel_shader_to_mesh(mesh, enemy_color)

## Separacao entre inimigos — raio e forca de repulsao
const SEPARATION_RADIUS := 1.5
const SEPARATION_FORCE := 3.0
const MAX_NEIGHBORS_CHECK := 8

func _physics_process(delta: float) -> void:
	if is_dead or GameManager.paused:
		return

	# Knockback decay
	if knockback_velocity.length() > 0.1:
		knockback_velocity = knockback_velocity.lerp(Vector3.ZERO, 8.0 * delta)
		velocity = knockback_velocity
		move_and_slide()
		return

	_find_target()
	if target and is_instance_valid(target):
		var direction = (target.global_position - global_position).normalized()
		direction.y = 0
		var effective_speed = speed
		# Veteran relic: enemies 15% faster
		if GameManager.veteran_relic_active:
			effective_speed *= 1.15
		# Mutation: speed demons
		effective_speed *= MutationManager.get_enemy_speed_modifier()
		# Separacao: repulsao de inimigos proximos
		var separation = _get_separation_vector()
		var final_dir = (direction * effective_speed + separation).normalized()
		velocity = final_dir * effective_speed
		move_and_slide()
		if _animator:
			_animator.set_walking(true)
	else:
		if _animator:
			_animator.set_walking(false)

func _get_separation_vector() -> Vector3:
	var sep := Vector3.ZERO
	var enemies = get_tree().get_nodes_in_group("enemies")
	var checked := 0
	for enemy in enemies:
		if enemy == self or not is_instance_valid(enemy) or enemy.is_dead:
			continue
		var diff = global_position - enemy.global_position
		diff.y = 0
		var dist = diff.length()
		if dist < SEPARATION_RADIUS and dist > 0.01:
			# Quanto mais perto, mais forte a repulsao
			sep += diff.normalized() * (SEPARATION_RADIUS - dist) / SEPARATION_RADIUS * SEPARATION_FORCE
			checked += 1
			if checked >= MAX_NEIGHBORS_CHECK:
				break
	return sep

func _find_target() -> void:
	var players = get_tree().get_nodes_in_group("players")
	if players.is_empty():
		target = null
		return
	# If player is hidden in cornfield and far away, lose target
	if GameManager.player_hidden:
		if target and is_instance_valid(target):
			if global_position.distance_to(target.global_position) > 5.0:
				target = null
				return
	var min_dist = INF
	for p in players:
		if not is_instance_valid(p):
			continue
		var dist = global_position.distance_squared_to(p.global_position)
		if dist < min_dist:
			min_dist = dist
			target = p

func take_damage(amount: int, damage_type: String = "physical") -> void:
	if is_dead or not is_inside_tree():
		return
	# Apply resistance multiplier (minimum 1 damage)
	var resist_mult: float = resistances.get(damage_type, 1.0)
	var is_crit = GameManager.crit_chance > 0.0 and randf() < GameManager.crit_chance
	var crit_mult = GameManager.crit_multiplier if is_crit else 1.0
	var final_damage = maxi(1, int(amount * GameManager.get_effective_damage_mult() * resist_mult * crit_mult))
	hp -= final_damage
	GameManager.total_damage_dealt += final_damage
	AchievementManager.on_attack()
	# Cross-combo check (multiplayer)
	if MultiplayerManager.is_online and damage_type != "physical":
		var peer = MultiplayerManager.local_player_id
		SynergySystem.try_cross_combo(global_position, damage_type, peer, final_damage)
	_hit_count += 1

	# Damage number - color by type (crits are yellow and larger)
	var dmg_color: Color
	if is_crit:
		dmg_color = Color(1.0, 0.9, 0.2)
	else:
		dmg_color = _get_damage_color(damage_type)
	var pos = global_position
	var dmg_label = ParticleFactory.get_damage_number()
	dmg_label.text = str(final_damage) + ("!" if is_crit else "")
	dmg_label.font_size = 40 if is_crit else 28
	dmg_label.outline_size = 6
	dmg_label.modulate = dmg_color
	dmg_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	dmg_label.global_position = pos + Vector3(randf_range(-0.3, 0.3), 1.2, 0)
	dmg_label.visible = true
	dmg_label.set_process(true)
	if not dmg_label.get_parent():
		get_tree().current_scene.call_deferred("add_child", dmg_label)

	# Hit particles + screen shake
	ParticleFactory.spawn_hit_particles(pos + Vector3(0, 0.5, 0), Color.WHITE)
	ScreenEffects.shake(0.04)

	# Knockback
	if target and is_instance_valid(target):
		var kb_dir = (global_position - target.global_position).normalized()
		knockback_velocity = kb_dir * 3.5

	AudioManager.play_sfx("hit")
	if _animator:
		_animator.play_hit()
	_flash_white()
	if hp <= 0:
		call_deferred("_die")

func _get_damage_color(damage_type: String) -> Color:
	match damage_type:
		"fire":
			return Color(1.0, 0.5, 0.2)
		"ice":
			return Color(0.4, 0.8, 1.0)
		"electric":
			return Color(1.0, 1.0, 0.3)
		"dark":
			return Color(0.7, 0.3, 0.9)
		"poison":
			return Color(0.3, 0.9, 0.3)
		_:
			return Color(1, 1, 0.8)

func _flash_white() -> void:
	var proc_model = get_node_or_null("ProceduralModel")
	if proc_model:
		for child in proc_model.get_children():
			if child is MeshInstance3D and child.material_override is ShaderMaterial:
				child.material_override.set_shader_parameter("albedo_color", Color.WHITE)
		var tween = create_tween()
		tween.tween_callback(func():
			if is_instance_valid(proc_model):
				for child in proc_model.get_children():
					if child is MeshInstance3D and child.material_override is ShaderMaterial:
						child.material_override.set_shader_parameter("albedo_color", enemy_color)
		).set_delay(0.15)
	else:
		var mat = mesh.material_override
		if mat is ShaderMaterial:
			mat.set_shader_parameter("albedo_color", Color.WHITE)
			var tween = create_tween()
			tween.tween_callback(func(): mat.set_shader_parameter("albedo_color", enemy_color)).set_delay(0.15)

func _die() -> void:
	if is_dead:
		return
	is_dead = true
	AudioManager.play_sfx("kill")
	# Track in bestiary
	SaveManager.track_bestiary(name)
	# One Punch achievement: boss killed in 1 hit
	if is_in_group("boss") and _hit_count <= 1:
		AchievementManager.on_boss_killed_one_hit()
	# Telemetry: boss killed event
	if is_in_group("boss"):
		Telemetry.send_event("boss_killed", {
			"boss_name": name,
			"stage": GameManager.selected_stage,
			"time": GameManager.game_time,
		})
	GameManager.enemies_alive -= 1
	GameManager.total_kills += 1
	var pos = global_position if is_inside_tree() else Vector3.ZERO
	GameManager.enemy_killed.emit(pos, xp_drop)
	if is_inside_tree():
		ParticleFactory.spawn_death_particles(pos + Vector3(0, 0.3, 0), enemy_color)
		# Gold particles for elite enemies
		if enemy_color == Color(1.0, 0.85, 0.2) or scale.x > 1.2:
			ParticleFactory.spawn_death_particles(pos + Vector3(0, 0.5, 0), Color(1.0, 0.85, 0.2), 15)
		ScreenEffects.shake(0.06)
		SynergySystem.apply_on_kill_synergies(pos)
		# Mutation: explosive enemies
		if MutationManager.is_active("explosive_enemies") and not is_in_group("boss"):
			_mutation_explode(pos)
		_spawn_xp_gem()
		_spawn_crystal()
		# Gasoline item: fire ground on enemy death
		if GameManager.fire_ground_active:
			_spawn_fire_ground(pos)
	if _animator:
		_animator.play_death()
		# Delay queue_free for death animation
		var tween = create_tween()
		tween.tween_callback(queue_free).set_delay(0.5)
	else:
		queue_free()

func _spawn_xp_gem() -> void:
	var gem_scene = preload("res://scenes/xp_gem.tscn")
	var gem = gem_scene.instantiate()
	gem.global_position = global_position + Vector3(0, 0.3, 0)
	gem.xp_value = xp_drop
	get_tree().current_scene.call_deferred("add_child", gem)

func _spawn_crystal() -> void:
	# 30% chance de dropar cristal
	if randf() > 0.3:
		return
	var crystal_scene = preload("res://scenes/crystal_pickup.tscn")
	var crystal = crystal_scene.instantiate()
	crystal.global_position = global_position + Vector3(0.3, 0.3, 0.3)
	crystal.crystal_value = maxi(1, xp_drop)
	get_tree().current_scene.call_deferred("add_child", crystal)

func _spawn_fire_ground(pos: Vector3) -> void:
	var fire_scene = preload("res://scripts/effects/fire_ground_effect.gd")
	var fire = Area3D.new()
	fire.set_script(fire_scene)
	fire.collision_layer = 0
	fire.collision_mask = 2  # Enemies
	var col = CollisionShape3D.new()
	var shape = SphereShape3D.new()
	shape.radius = 1.5
	col.shape = shape
	fire.add_child(col)
	# Visual — base fire disc
	var mesh_inst = MeshInstance3D.new()
	var disc = CylinderMesh.new()
	disc.top_radius = 1.5
	disc.bottom_radius = 1.5
	disc.height = 0.05
	mesh_inst.mesh = disc
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.8, 0.2, 0.05, 0.5)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.4, 0.0)
	mat.emission_energy_multiplier = 1.5
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mesh_inst.material_override = mat
	fire.add_child(mesh_inst)

	# Flames — rising fire particles
	var flames = GPUParticles3D.new()
	flames.name = "Flames"
	flames.amount = 25
	flames.lifetime = 0.6
	flames.position = Vector3(0, 0.05, 0)
	var flame_mat = ParticleProcessMaterial.new()
	flame_mat.direction = Vector3(0, 1, 0)
	flame_mat.initial_velocity_min = 0.5
	flame_mat.initial_velocity_max = 1.5
	flame_mat.spread = 20.0
	flame_mat.gravity = Vector3(0, 0.5, 0)
	flame_mat.scale_min = 0.5
	flame_mat.scale_max = 1.0
	flame_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	flame_mat.emission_sphere_radius = 1.2
	# Scale curve: start big, shrink as they rise
	var flame_scale_curve = CurveTexture.new()
	var fcurve = Curve.new()
	fcurve.add_point(Vector2(0.0, 1.0))
	fcurve.add_point(Vector2(0.5, 0.5))
	fcurve.add_point(Vector2(1.0, 0.0))
	flame_scale_curve.curve = fcurve
	flame_mat.scale_curve = flame_scale_curve
	# Color gradient: yellow -> orange -> red
	var flame_color_ramp = GradientTexture1D.new()
	var flame_gradient = Gradient.new()
	flame_gradient.set_offset(0, 0.0)
	flame_gradient.set_color(0, Color(1.0, 0.9, 0.2, 0.9))
	flame_gradient.add_point(0.5, Color(1.0, 0.5, 0.1, 0.7))
	flame_gradient.set_offset(2, 1.0)
	flame_gradient.set_color(2, Color(0.8, 0.1, 0.0, 0.0))
	flame_color_ramp.gradient = flame_gradient
	flame_mat.color_ramp = flame_color_ramp
	flames.process_material = flame_mat
	var flame_mesh = SphereMesh.new()
	flame_mesh.radius = 0.08
	flame_mesh.height = 0.16
	var flame_mesh_mat = StandardMaterial3D.new()
	flame_mesh_mat.albedo_color = Color(1.0, 0.6, 0.1, 0.8)
	flame_mesh_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	flame_mesh_mat.emission_enabled = true
	flame_mesh_mat.emission = Color(1.0, 0.5, 0.1)
	flame_mesh_mat.emission_energy_multiplier = 2.0
	flame_mesh.material = flame_mesh_mat
	flames.draw_pass_1 = flame_mesh
	fire.add_child(flames)

	# Embers — small bright dots floating up
	var embers = GPUParticles3D.new()
	embers.name = "Embers"
	embers.amount = 8
	embers.lifetime = 1.2
	embers.position = Vector3(0, 0.1, 0)
	var ember_mat = ParticleProcessMaterial.new()
	ember_mat.direction = Vector3(0, 1, 0)
	ember_mat.initial_velocity_min = 0.3
	ember_mat.initial_velocity_max = 0.8
	ember_mat.spread = 40.0
	ember_mat.gravity = Vector3(0, 0.3, 0)
	ember_mat.scale_min = 0.02
	ember_mat.scale_max = 0.05
	ember_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	ember_mat.emission_sphere_radius = 1.0
	embers.process_material = ember_mat
	var ember_mesh = SphereMesh.new()
	ember_mesh.radius = 0.02
	ember_mesh.height = 0.04
	var ember_mesh_mat = StandardMaterial3D.new()
	ember_mesh_mat.albedo_color = Color(1.0, 0.7, 0.2, 0.9)
	ember_mesh_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ember_mesh_mat.emission_enabled = true
	ember_mesh_mat.emission = Color(1.0, 0.6, 0.1)
	ember_mesh_mat.emission_energy_multiplier = 3.0
	ember_mesh.material = ember_mesh_mat
	embers.draw_pass_1 = ember_mesh
	fire.add_child(embers)
	fire.global_position = pos
	fire.monitoring = true
	get_tree().current_scene.call_deferred("add_child", fire)
	# Register as elemental zone for cross-combo
	var owner_peer = MultiplayerManager.local_player_id if MultiplayerManager.is_online else 1
	SynergySystem.register_elemental_zone(pos, "fire", owner_peer, 5.0)

func _apply_furious_boss_mutation() -> void:
	if is_in_group("boss") and MutationManager.is_active("furious_bosses"):
		hp = int(max_hp * 0.75)

func _mutation_explode(pos: Vector3) -> void:
	## Mutation "explosive_enemies": AoE damage on death (like Bomber)
	var explosion_damage = maxi(1, max_hp / 2)
	var explosion_radius = 1.5
	ParticleFactory.spawn_explosion_particles(pos + Vector3(0, 0.3, 0))
	var enemies = get_tree().get_nodes_in_group("enemies")
	for e in enemies:
		if e == self or not is_instance_valid(e) or e.is_dead:
			continue
		if pos.distance_to(e.global_position) <= explosion_radius and e.has_method("take_damage"):
			e.call_deferred("take_damage", explosion_damage, "fire")

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("players") and body.has_method("take_damage"):
		body.take_damage(damage)
		# Track cow damage for achievement
		if GameManager.selected_stage == "farm":
			var cow_names = ["Zombie Cow", "Cow Slime", "Bull", "Mud Blob"]
			if name in cow_names:
				AchievementManager.on_cow_damage()
