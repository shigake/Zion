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
