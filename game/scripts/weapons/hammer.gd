extends Node3D

## Martelo — slam no chao com shockwave em area ao redor do jogador.

var attack_timer: float = 0.0
var is_attacking: bool = false
var attack_anim_timer: float = 0.0
var attack_duration: float = 0.35

@onready var slam_area: Area3D = $SlamArea
@onready var slam_mesh: MeshInstance3D = $SlamMesh

var hit_enemies: Array = []

func _ready() -> void:
	slam_mesh.visible = false
	slam_area.body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	if GameManager.paused or GameManager.is_game_over:
		return

	var level = GameManager.get_weapon_level("hammer")
	if level <= 0:
		return

	var cooldown = WeaponDB.get_cooldown("hammer", level) / GameManager.attack_speed_mult

	if is_attacking:
		attack_anim_timer -= delta
		# Shockwave expand animation
		var progress = 1.0 - (attack_anim_timer / attack_duration)
		var expand = lerp(0.3, 1.0, progress)
		slam_mesh.scale = Vector3(expand, 0.1, expand) * (1.0 + (level - 1) * 0.15)

		if attack_anim_timer <= 0:
			is_attacking = false
			slam_mesh.visible = false
			slam_area.monitoring = false
			hit_enemies.clear()
	else:
		attack_timer -= delta
		if attack_timer <= 0:
			_attack(level)
			attack_timer = cooldown

func _attack(level: int) -> void:
	is_attacking = true
	attack_anim_timer = attack_duration
	slam_mesh.visible = true
	slam_area.monitoring = true
	hit_enemies.clear()

	# Scale area with level — radius 3.0 base
	var area_scale = 1.0 + (level - 1) * 0.15
	slam_area.scale = Vector3.ONE * area_scale
	slam_mesh.scale = Vector3(0.3, 0.1, 0.3) * area_scale

	# Screen shake on impact
	ScreenEffects.shake(0.3)
	AudioManager.play_sfx("hit")

func _on_body_entered(body: Node3D) -> void:
	if body in hit_enemies:
		return
	if body.has_method("take_damage") and body.is_in_group("enemies"):
		var level = GameManager.get_weapon_level("hammer")
		var dmg = int(WeaponDB.get_damage("hammer", level))
		body.call_deferred("take_damage", dmg, "physical")
		hit_enemies.append(body)
