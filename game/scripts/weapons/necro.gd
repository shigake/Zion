extends Node3D

## Necromante — invoca esqueletos que perseguem e atacam inimigos.

var summon_timer: float = 0.0
var skeleton_scene: PackedScene = preload("res://scenes/weapons/skeleton_summon.tscn")

func _process(delta: float) -> void:
	if GameManager.paused or GameManager.is_game_over:
		return

	var level = GameManager.get_weapon_level("necro")
	if level <= 0:
		return

	var cooldown = WeaponDB.get_cooldown("necro", level) * GameManager.cooldown_mult
	var max_summons = 2 + (level - 1)

	# Conta summons ativos
	var current_summons = get_tree().get_nodes_in_group("player_summons").size()

	summon_timer -= delta
	if summon_timer <= 0 and current_summons < max_summons:
		summon_timer = cooldown
		_summon(level)

func _summon(level: int) -> void:
	var player_pos = get_parent().get_parent().global_position
	var offset = Vector3(randf_range(-2, 2), 0, randf_range(-2, 2))

	var skeleton = ObjectPool.get_instance(skeleton_scene)
	skeleton.global_position = player_pos + offset
	skeleton.damage = int(WeaponDB.get_damage("necro", level))
	skeleton.lifetime = 8.0 + level * 2.0
	get_tree().current_scene.call_deferred("add_child", skeleton)
	# Green summon circle
	_spawn_summon_circle(player_pos + offset)

func _spawn_summon_circle(pos: Vector3) -> void:
	var circle = MeshInstance3D.new()
	var disc = CylinderMesh.new()
	disc.top_radius = 1.0
	disc.bottom_radius = 1.0
	disc.height = 0.05
	circle.mesh = disc
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 1.0, 0.3, 0.8)
	mat.emission_enabled = true
	mat.emission = Color(0.2, 1.0, 0.3)
	mat.emission_energy_multiplier = 3.0
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	circle.material_override = mat
	circle.global_position = pos
	get_tree().current_scene.add_child(circle)
	var tween = circle.create_tween()
	tween.tween_property(mat, "albedo_color", Color(0.2, 1.0, 0.3, 0.0), 0.5)
	tween.tween_callback(circle.queue_free)
