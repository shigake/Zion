extends Node3D

## Foice — gira ao redor do jogador continuamente, causa dano e drena vida.

@export var orbit_radius: float = 2.5
@export var rotation_speed: float = 3.5
@export var hit_cooldown: float = 0.3

var angle: float = 0.0
var hit_timers: Dictionary = {}  # enemy_id -> timer

@onready var scythe_area: Area3D = $ScytheArea
@onready var scythe_mesh: MeshInstance3D = $ScytheMesh

var _trail: Node3D = null

func _ready() -> void:
	scythe_area.body_entered.connect(_on_body_entered)
	# Weapon trail
	_trail = preload("res://scripts/effects/weapon_trail.gd").new()
	_trail.trail_color = Color(0.6, 0.2, 0.8, 0.6)
	_trail.max_points = 20
	scythe_mesh.add_child(_trail)

func _process(delta: float) -> void:
	if GameManager.paused or GameManager.is_game_over:
		return

	var level = GameManager.get_weapon_level("scythe")
	if level <= 0:
		return

	# Rotacao
	var speed = rotation_speed + (level - 1) * 0.3
	angle += speed * delta

	var radius = orbit_radius + (level - 1) * 0.2
	var pos = Vector3(cos(angle) * radius, 0.5, sin(angle) * radius)
	scythe_area.position = pos
	scythe_mesh.position = pos
	scythe_area.rotation.y = angle + PI / 2
	scythe_mesh.rotation.y = angle + PI / 2

	# Escala com area_mult
	var s = GameManager.area_mult
	scythe_mesh.scale = Vector3(s, s, s)

	# Decrementa hit timers
	var to_remove: Array = []
	for key in hit_timers:
		hit_timers[key] -= delta
		if hit_timers[key] <= 0:
			to_remove.append(key)
	for key in to_remove:
		hit_timers.erase(key)

func _on_body_entered(body: Node3D) -> void:
	if not body.is_in_group("enemies"):
		return
	if not body.has_method("take_damage"):
		return

	var eid = body.get_instance_id()
	if eid in hit_timers:
		return

	var level = GameManager.get_weapon_level("scythe")
	var dmg = int(WeaponDB.get_damage("scythe", level))
	body.call_deferred("take_damage", dmg, "dark")
	hit_timers[eid] = hit_cooldown

	# Lifesteal
	var lifesteal = 0.02 * level
	var heal_amount = int(dmg * lifesteal)
	if heal_amount > 0:
		GameManager.heal(heal_amount)
