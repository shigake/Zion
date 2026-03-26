extends Node3D

## Livro Magico — orbita o jogador, causa dano de contato e dispara paginas.

@export var orbit_radius: float = 1.5
@export var rotation_speed: float = 3.0
@export var hit_cooldown: float = 0.3

var angle: float = 0.0
var hit_timers: Dictionary = {}
var attack_timer: float = 0.0
var projectile_scene: PackedScene = preload("res://scenes/weapons/bullet.tscn")

@onready var book_area: Area3D = $BookArea
@onready var book_mesh: MeshInstance3D = $BookMesh

func _ready() -> void:
	book_area.body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	if GameManager.paused or GameManager.is_game_over:
		return

	var level = GameManager.get_weapon_level("magic_book")
	if level <= 0:
		return

	# Orbit rotation
	var speed = rotation_speed + (level - 1) * 0.2
	angle += speed * delta

	var radius = orbit_radius + (level - 1) * 0.1
	var pos = Vector3(cos(angle) * radius, 0.5, sin(angle) * radius)
	book_area.position = pos
	book_mesh.position = pos
	book_area.rotation.y = angle + PI / 2
	book_mesh.rotation.y = angle + PI / 2

	# Scale with area_mult
	var s = GameManager.area_mult
	book_mesh.scale = Vector3(s, s, s)

	# Decrement hit timers
	var to_remove: Array = []
	for key in hit_timers:
		hit_timers[key] -= delta
		if hit_timers[key] <= 0:
			to_remove.append(key)
	for key in to_remove:
		hit_timers.erase(key)

	# Fire page projectile at nearest enemy
	var fire_cooldown = 2.0 - (level - 1) * 0.15
	fire_cooldown = maxf(0.5, fire_cooldown) / GameManager.attack_speed_mult * GameManager.cooldown_mult
	attack_timer -= delta
	if attack_timer <= 0:
		attack_timer = fire_cooldown
		_fire_page(level)

func _on_body_entered(body: Node3D) -> void:
	if not body.is_in_group("enemies"):
		return
	if not body.has_method("take_damage"):
		return

	var eid = body.get_instance_id()
	if eid in hit_timers:
		return

	var level = GameManager.get_weapon_level("magic_book")
	var dmg = int(WeaponDB.get_damage("magic_book", level))
	body.call_deferred("take_damage", dmg, "physical")
	hit_timers[eid] = hit_cooldown

func _fire_page(level: int) -> void:
	var enemies = get_tree().get_nodes_in_group("enemies")
	if enemies.is_empty():
		return

	var book_global_pos = book_mesh.global_position
	var nearest: Node3D = null
	var min_dist = INF
	for e in enemies:
		if not is_instance_valid(e):
			continue
		var d = book_global_pos.distance_squared_to(e.global_position)
		if d < min_dist:
			min_dist = d
			nearest = e

	if nearest == null:
		return

	var direction = (nearest.global_position - book_global_pos).normalized()
	direction.y = 0

	var num_pages = 1
	if level >= 6:
		num_pages = 2

	for i in range(num_pages):
		var page = ObjectPool.get_instance(projectile_scene)
		page.global_position = book_global_pos
		var spread = (randf() - 0.5) * 0.2
		var spread_dir = direction.rotated(Vector3.UP, spread)
		page.direction = spread_dir.normalized()
		page.damage = int(WeaponDB.get_damage("magic_book", level) * 0.8)
		page.speed = 16.0
		page.lifetime = 2.0
		page.damage_type = "physical"
		get_tree().current_scene.call_deferred("add_child", page)

	AudioManager.play_sfx("hit")
