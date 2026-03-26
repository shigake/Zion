extends Node3D

## Espada Cloud — ataque lento e massivo em arco frontal de 180 graus.

var attack_timer: float = 0.0
var is_attacking: bool = false
var attack_anim_timer: float = 0.0
var attack_duration: float = 0.5

@onready var slash_area: Area3D = $SlashArea
@onready var slash_mesh: MeshInstance3D = $SlashMesh

var hit_enemies: Array = []
var _trail: Node3D = null

func _ready() -> void:
	slash_mesh.visible = false
	slash_area.body_entered.connect(_on_body_entered)
	# Weapon trail
	_trail = preload("res://scripts/effects/weapon_trail.gd").new()
	_trail.trail_color = Color(0.3, 0.5, 1.0, 0.6)
	_trail.max_points = 20
	slash_mesh.add_child(_trail)

func _process(delta: float) -> void:
	if GameManager.paused or GameManager.is_game_over:
		return

	var level = GameManager.get_weapon_level("cloud_sword")
	if level <= 0:
		return

	var cooldown = WeaponDB.get_cooldown("cloud_sword", level) / GameManager.attack_speed_mult

	if is_attacking:
		attack_anim_timer -= delta
		# Sweep 180 degrees arc — slow massive slash
		var progress = 1.0 - (attack_anim_timer / attack_duration)
		var arc_angle = lerp(-PI / 2.0, PI / 2.0, progress)
		slash_area.rotation.y = arc_angle
		slash_mesh.rotation.y = arc_angle

		if attack_anim_timer <= 0:
			is_attacking = false
			slash_mesh.visible = false
			slash_area.monitoring = false
			hit_enemies.clear()
	else:
		attack_timer -= delta
		if attack_timer <= 0:
			_attack(level)
			attack_timer = cooldown

func _attack(level: int) -> void:
	is_attacking = true
	attack_anim_timer = attack_duration
	slash_mesh.visible = true
	slash_area.monitoring = true
	hit_enemies.clear()

	# Scale with level — very wide slash
	var area_scale = 1.0 + (level - 1) * 0.18
	slash_area.scale = Vector3.ONE * area_scale
	slash_mesh.scale = Vector3.ONE * area_scale

	# Screen shake on massive swing
	ScreenEffects.shake(0.2, 6.0)
	AudioManager.play_sfx("hit")

func _on_body_entered(body: Node3D) -> void:
	if body in hit_enemies:
		return
	if body.has_method("take_damage") and body.is_in_group("enemies"):
		var level = GameManager.get_weapon_level("cloud_sword")
		var dmg = int(WeaponDB.get_damage("cloud_sword", level))
		body.call_deferred("take_damage", dmg, "physical")
		hit_enemies.append(body)
