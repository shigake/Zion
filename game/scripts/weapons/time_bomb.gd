extends Node3D

## Bomba Relogio — dropa bomba na posicao do jogador, explode apos fuse.

var attack_timer: float = 0.0
var active_bombs: Array = []
const MAX_BOMBS: int = 3
const FUSE_TIME: float = 3.0
const EXPLOSION_RADIUS: float = 4.0

func _process(delta: float) -> void:
	if GameManager.paused or GameManager.is_game_over:
		return

	var level = GameManager.get_weapon_level("time_bomb")
	if level <= 0:
		return

	var cooldown = WeaponDB.get_cooldown("time_bomb", level) / GameManager.attack_speed_mult

	# Limpa bombas invalidas
	active_bombs = active_bombs.filter(func(b): return is_instance_valid(b))

	attack_timer -= delta
	if attack_timer <= 0:
		attack_timer = cooldown
		if active_bombs.size() < MAX_BOMBS:
			_drop_bomb(level)

func _drop_bomb(level: int) -> void:
	var player_pos = get_parent().get_parent().global_position
	var bomb = _create_bomb_node(level)
	bomb.global_position = player_pos
	get_tree().current_scene.call_deferred("add_child", bomb)
	active_bombs.append(bomb)

func _create_bomb_node(level: int) -> Node3D:
	var bomb = Node3D.new()
	bomb.name = "TimeBomb"
	bomb.set_meta("level", level)
	bomb.set_meta("fuse_time", FUSE_TIME)
	bomb.set_meta("explosion_radius", EXPLOSION_RADIUS)

	# Visual: esfera vermelha
	var mesh_inst = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 0.3
	sphere.height = 0.6
	mesh_inst.mesh = sphere
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.8, 0.1, 0.1, 1.0)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.3, 0.0)
	mat.emission_energy_multiplier = 1.5
	mesh_inst.material_override = mat
	bomb.add_child(mesh_inst)

	# Timer label 3D
	var label = Label3D.new()
	label.text = str(int(FUSE_TIME))
	label.font_size = 32
	label.position = Vector3(0, 1.0, 0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = Color(1.0, 0.8, 0.0)
	bomb.add_child(label)

	# Fuse script via set_script
	var script = GDScript.new()
	script.source_code = _get_bomb_script()
	script.reload()
	bomb.set_script(script)

	return bomb

func _get_bomb_script() -> String:
	return """extends Node3D

var fuse_timer: float = 0.0
var fuse_time: float = 3.0
var explosion_radius: float = 4.0
var bomb_level: int = 1
var has_exploded: bool = false

func _ready() -> void:
	fuse_time = get_meta("fuse_time", 3.0)
	explosion_radius = get_meta("explosion_radius", 4.0)
	bomb_level = get_meta("level", 1)

func _process(delta: float) -> void:
	if has_exploded:
		return
	if GameManager.paused or GameManager.is_game_over:
		return

	fuse_timer += delta

	# Atualiza label
	var label = get_child(1) as Label3D
	if label:
		var remaining = max(0, fuse_time - fuse_timer)
		label.text = str(int(ceil(remaining)))

	# Pulsa a bomba
	var mesh_node = get_child(0) as MeshInstance3D
	if mesh_node:
		var pulse = 1.0 + sin(fuse_timer * 8.0) * 0.1
		mesh_node.scale = Vector3.ONE * pulse

	if fuse_timer >= fuse_time:
		_explode()

func _explode() -> void:
	has_exploded = true
	var dmg = int(WeaponDB.get_damage("time_bomb", bomb_level))
	var pos = global_position
	var radius_sq = explosion_radius * explosion_radius

	var enemies = get_tree().get_nodes_in_group("enemies")
	for e in enemies:
		if not is_instance_valid(e):
			continue
		if pos.distance_squared_to(e.global_position) <= radius_sq:
			if e.has_method("take_damage"):
				e.call_deferred("take_damage", dmg, "fire")

	ScreenEffects.shake(0.5, 12.0)
	AudioManager.play_sfx("hit")
	ParticleFactory.spawn_hit_particles(pos, Color(1.0, 0.4, 0.0))
	ParticleFactory.spawn_hit_particles(pos + Vector3(0, 0.5, 0), Color(1.0, 0.7, 0.1))

	var tween = create_tween()
	var mesh_node = get_child(0) as MeshInstance3D
	if mesh_node:
		tween.tween_property(mesh_node, "scale", Vector3.ONE * 3.0, 0.15)
	tween.tween_callback(queue_free)
"""
