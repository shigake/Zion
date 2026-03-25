extends CharacterBody3D
class_name EnemyBase3D

## Inimigo base 3D. Persegue jogador, dano por contato, damage numbers, particulas, knockback.

@export var speed: float = 4.0
@export var max_hp: int = 20
@export var damage: int = 10
@export var xp_drop: int = 1
@export var enemy_color: Color = Color(0.8, 0.2, 0.2)

var hp: int = 20
var target: Node3D = null
var is_dead: bool = false
var knockback_velocity: Vector3 = Vector3.ZERO

@onready var mesh: MeshInstance3D = $Mesh
@onready var hitbox: Area3D = $Hitbox

func _ready() -> void:
	hp = max_hp
	add_to_group("enemies")
	hitbox.body_entered.connect(_on_body_entered)
	# Aplica cor
	var mat = StandardMaterial3D.new()
	mat.albedo_color = enemy_color
	mesh.set_surface_override_material(0, mat)

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
		velocity = direction * speed
		move_and_slide()

func _find_target() -> void:
	var players = get_tree().get_nodes_in_group("players")
	if players.is_empty():
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

func take_damage(amount: int) -> void:
	if is_dead:
		return
	var final_damage = int(amount * GameManager.perm_damage_mult)
	hp -= final_damage
	GameManager.total_damage_dealt += final_damage

	# Damage number
	var dmg_label = Label3D.new()
	dmg_label.text = str(final_damage)
	dmg_label.font_size = 28
	dmg_label.outline_size = 6
	dmg_label.modulate = Color(1, 1, 0.8)
	dmg_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	dmg_label.global_position = global_position + Vector3(randf_range(-0.3, 0.3), 1.2, 0)
	dmg_label.set_script(preload("res://scripts/effects/damage_number.gd"))
	get_tree().current_scene.call_deferred("add_child", dmg_label)

	# Hit particles + screen shake
	ParticleFactory.spawn_hit_particles(global_position + Vector3(0, 0.5, 0), Color.WHITE)
	ScreenEffects.shake(0.04)

	# Knockback
	if target and is_instance_valid(target):
		var kb_dir = (global_position - target.global_position).normalized()
		knockback_velocity = kb_dir * 3.5

	_flash_white()
	if hp <= 0:
		call_deferred("_die")

func _flash_white() -> void:
	var mat = mesh.get_surface_override_material(0)
	if mat is StandardMaterial3D:
		mat.albedo_color = Color.WHITE
		var tween = create_tween()
		tween.tween_property(mat, "albedo_color", enemy_color, 0.15)

func _die() -> void:
	if is_dead:
		return
	is_dead = true
	GameManager.enemies_alive -= 1
	GameManager.total_kills += 1
	GameManager.enemy_killed.emit(global_position, xp_drop)
	ParticleFactory.spawn_death_particles(global_position + Vector3(0, 0.3, 0), enemy_color)
	ScreenEffects.shake(0.06)
	_spawn_xp_gem()
	_spawn_crystal()
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

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("players") and body.has_method("take_damage"):
		body.take_damage(damage)
