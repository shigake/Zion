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

@onready var mesh: MeshInstance3D = $Mesh
@onready var hitbox: Area3D = $Hitbox

func _ready() -> void:
	# Multiplayer HP scaling
	var hp_mult = GameManager.get_mp_hp_mult()
	max_hp = int(max_hp * hp_mult)
	hp = max_hp
	add_to_group("enemies")
	# Desativa colisao fisica com player para evitar empurrar o jogador
	# Dano por contato e detectado via Area3D (Hitbox)
	collision_mask = 0
	hitbox.body_entered.connect(_on_body_entered)
	# Substitui mesh simples por modelo procedural
	_apply_procedural_model()

func _apply_procedural_model() -> void:
	var model = ModelFactory.get_model_for_enemy(name)
	if model.get_child_count() > 0:
		# Esconde mesh original
		mesh.visible = false
		# Adiciona modelo procedural
		model.name = "ProceduralModel"
		add_child(model)
		ModelFactory.apply_model_materials(model, enemy_color)
		# Procedural animation
		_animator = preload("res://scripts/effects/procedural_animator.gd").new()
		_animator.setup(model)
		add_child(_animator)
	else:
		# Fallback: cel-shader na mesh original
		VisualSetup.apply_cel_shader_to_mesh(mesh, enemy_color)

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
		velocity = direction * effective_speed
		move_and_slide()
		if _animator:
			_animator.set_walking(true)
	else:
		if _animator:
			_animator.set_walking(false)

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
	var final_damage = maxi(1, int(amount * GameManager.get_effective_damage_mult() * resist_mult))
	hp -= final_damage
	GameManager.total_damage_dealt += final_damage

	# Damage number - color by type
	var dmg_color: Color = _get_damage_color(damage_type)
	var dmg_label = Label3D.new()
	dmg_label.text = str(final_damage)
	dmg_label.font_size = 28
	dmg_label.outline_size = 6
	dmg_label.modulate = dmg_color
	dmg_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	var pos = global_position
	dmg_label.global_position = pos + Vector3(randf_range(-0.3, 0.3), 1.2, 0)
	dmg_label.set_script(preload("res://scripts/effects/damage_number.gd"))
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
	GameManager.enemies_alive -= 1
	GameManager.total_kills += 1
	var pos = global_position if is_inside_tree() else Vector3.ZERO
	GameManager.enemy_killed.emit(pos, xp_drop)
	if is_inside_tree():
		ParticleFactory.spawn_death_particles(pos + Vector3(0, 0.3, 0), enemy_color)
		ScreenEffects.shake(0.06)
		SynergySystem.apply_on_kill_synergies(pos)
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
	var fire = Area3D.new()
	fire.collision_layer = 0
	fire.collision_mask = 2  # Enemies
	var col = CollisionShape3D.new()
	var shape = SphereShape3D.new()
	shape.radius = 1.5
	col.shape = shape
	fire.add_child(col)
	# Visual
	var mesh_inst = MeshInstance3D.new()
	var disc = CylinderMesh.new()
	disc.top_radius = 1.5
	disc.bottom_radius = 1.5
	disc.height = 0.05
	mesh_inst.mesh = disc
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.3, 0.0, 0.5)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.4, 0.0)
	mat.emission_energy_multiplier = 2.0
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mesh_inst.material_override = mat
	fire.add_child(mesh_inst)
	fire.global_position = pos
	fire.monitoring = true
	get_tree().current_scene.call_deferred("add_child", fire)
	# Damage tick + cleanup
	var timer := 0.0
	var lifetime := 3.0
	fire.set_meta("timer", timer)
	fire.set_meta("lifetime", lifetime)
	fire.set_meta("tick", 0.0)
	fire.set_script(preload("res://scripts/effects/fire_ground_effect.gd"))

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("players") and body.has_method("take_damage"):
		body.take_damage(damage)
