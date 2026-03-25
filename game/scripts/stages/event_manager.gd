extends Node3D

## Gerencia eventos especiais durante a run.
## Eventos: Horda Dourada (min 5), Eclipse (min 8), Roulette (min 10),
## Meteor Shower (min 12), Angel Challenge (min 15),
## Treasure Goblin (aleatorio), Merchant (aleatorio), Fever Mode (kill streak)

signal event_started(event_name: String)
signal event_ended(event_name: String)

var active_event: String = ""
var event_timer: float = 0.0
var next_random_event_time: float = 0.0
var rng: RandomNumberGenerator = RandomNumberGenerator.new()

# Eclipse state
var _eclipse_original_energy: float = -1.0
var _eclipse_hidden_enemies: Array = []

# Meteor shower state
var _meteor_spawns_remaining: int = 0
var _meteor_spawn_timer: float = 0.0
var _meteor_spawn_interval: float = 0.0

# Fever mode state
var _recent_kills: Array[float] = []  # timestamps of recent kills
var _fever_active: bool = false
var _fever_prev_damage_mult: float = 1.0
var _fever_prev_speed_mult: float = 1.0

# Eventos fixos por tempo
var timed_events: Dictionary = {
	300.0: "golden_horde",     # Min 5
	480.0: "eclipse",          # Min 8
	600.0: "roulette",         # Min 10
	720.0: "meteor_shower",    # Min 12
	900.0: "angel_challenge",  # Min 15
}
var triggered_timed: Array = []

func _ready() -> void:
	rng.randomize()
	next_random_event_time = rng.randf_range(180, 300)  # Primeiro evento aleatorio entre 3-5 min
	GameManager.enemy_killed.connect(_on_enemy_killed)

func _process(delta: float) -> void:
	if GameManager.paused or GameManager.is_game_over:
		return

	# Meteor shower staggered spawning (runs even during active event)
	if _meteor_spawns_remaining > 0:
		_meteor_spawn_timer -= delta
		if _meteor_spawn_timer <= 0:
			_spawn_single_meteor()
			_meteor_spawns_remaining -= 1
			_meteor_spawn_timer = _meteor_spawn_interval

	# Fever mode kill tracking - prune old kills
	var current_time = GameManager.game_time
	while not _recent_kills.is_empty() and current_time - _recent_kills[0] > 5.0:
		_recent_kills.remove_at(0)

	# Check fever mode trigger (20+ kills in 5 seconds)
	if not _fever_active and _recent_kills.size() >= 20:
		_start_fever_mode()

	# Evento ativo
	if active_event != "":
		event_timer -= delta
		if event_timer <= 0:
			_end_event()
		return

	# Check timed events
	for time in timed_events:
		if GameManager.game_time >= time and time not in triggered_timed:
			triggered_timed.append(time)
			_start_event(timed_events[time])
			return

	# Check random events
	if GameManager.game_time >= next_random_event_time:
		var random_events = ["treasure_goblin", "merchant"]
		var event = random_events[rng.randi() % random_events.size()]
		_start_event(event)
		next_random_event_time = GameManager.game_time + rng.randf_range(120, 240)

func _on_enemy_killed(position: Vector3, xp_value: int) -> void:
	_recent_kills.append(GameManager.game_time)

func _start_event(event_name: String) -> void:
	active_event = event_name
	event_started.emit(event_name)

	match event_name:
		"golden_horde":
			event_timer = 20.0
			_spawn_golden_horde()
		"treasure_goblin":
			event_timer = 30.0
			_spawn_treasure_goblin()
		"merchant":
			event_timer = 30.0
			_spawn_merchant()
		"roulette":
			event_timer = 5.0
			_do_roulette()
		"eclipse":
			event_timer = 20.0
			_start_eclipse()
		"meteor_shower":
			event_timer = 12.0  # 10s of spawns + 2s buffer for last meteor
			_start_meteor_shower()
		"angel_challenge":
			event_timer = 1.0  # Instant effect, short timer
			_do_angel_challenge()

func _end_event() -> void:
	var ended = active_event

	# Cleanup for specific events
	match ended:
		"eclipse":
			_end_eclipse()

	active_event = ""
	event_ended.emit(ended)

func _spawn_golden_horde() -> void:
	var players = get_tree().get_nodes_in_group("players")
	if players.is_empty():
		return
	var center = players[0].global_position
	var slime_scene = preload("res://scenes/enemies/slime.tscn")

	for i in range(30):
		var angle = rng.randf() * TAU
		var pos = center + Vector3(cos(angle), 0, sin(angle)) * rng.randf_range(15, 25)
		var enemy = slime_scene.instantiate()
		enemy.global_position = pos
		if enemy is EnemyBase3D:
			enemy.enemy_color = Color(1.0, 0.85, 0.2)
			enemy.xp_drop = 5
			enemy.max_hp = 5
			enemy.hp = 5
		get_parent().add_child(enemy)
		GameManager.enemies_alive += 1

func _spawn_treasure_goblin() -> void:
	var players = get_tree().get_nodes_in_group("players")
	if players.is_empty():
		return
	var center = players[0].global_position
	var bat_scene = preload("res://scenes/enemies/bat.tscn")

	var goblin = bat_scene.instantiate()
	goblin.global_position = center + Vector3(10, 0, 10)
	if goblin is EnemyBase3D:
		goblin.enemy_color = Color(0.2, 1.0, 0.3)
		goblin.speed = 8.0  # Rapido, foge
		goblin.max_hp = 100
		goblin.hp = 100
		goblin.xp_drop = 30
		goblin.scale = Vector3(1.5, 1.5, 1.5)
	get_parent().add_child(goblin)
	GameManager.enemies_alive += 1

func _spawn_merchant() -> void:
	# Merchant e um NPC parado que oferece 3 itens por cristais
	# TODO: Implementar UI de merchant (por enquanto dropa 3 items gratis)
	var players = get_tree().get_nodes_in_group("players")
	if players.is_empty():
		return
	var center = players[0].global_position
	var offset = Vector3(rng.randf_range(-5, 5), 0, rng.randf_range(-5, 5))

	# Dropa 3 XP gems grandes como placeholder
	var gem_scene = preload("res://scenes/xp_gem.tscn")
	for i in range(3):
		var gem = gem_scene.instantiate()
		gem.global_position = center + offset + Vector3(i * 1.0, 0, 0)
		gem.xp_value = 10
		get_parent().call_deferred("add_child", gem)

func _do_roulette() -> void:
	# Roda da fortuna: efeito aleatorio
	var effects = ["speed_boost", "damage_boost", "heal", "slow"]
	var effect = effects[rng.randi() % effects.size()]
	match effect:
		"speed_boost":
			GameManager.speed_mult += 0.5
		"damage_boost":
			GameManager.perm_damage_mult += 0.3
		"heal":
			GameManager.heal(50)
		"slow":
			GameManager.speed_mult = maxf(0.5, GameManager.speed_mult - 0.3)

# ---- Eclipse (min 8) ----
# Darken screen, enemies become invisible for 20 seconds
func _start_eclipse() -> void:
	# Reduce DirectionalLight energy
	var dir_light = _find_directional_light()
	if dir_light:
		_eclipse_original_energy = dir_light.light_energy
		dir_light.light_energy = 0.1

	# Add dark overlay via CanvasLayer
	var overlay = ColorRect.new()
	overlay.name = "EclipseOverlay"
	overlay.color = Color(0, 0, 0, 0.6)
	overlay.anchors_preset = Control.PRESET_FULL_RECT
	var canvas = CanvasLayer.new()
	canvas.name = "EclipseCanvas"
	canvas.layer = 10
	canvas.add_child(overlay)
	add_child(canvas)

	# Hide enemy meshes
	_eclipse_hidden_enemies.clear()
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		var mesh = enemy.find_child("MeshInstance3D", true, false)
		if mesh and mesh is MeshInstance3D:
			mesh.visible = false
			_eclipse_hidden_enemies.append(enemy)

func _end_eclipse() -> void:
	# Restore DirectionalLight
	var dir_light = _find_directional_light()
	if dir_light and _eclipse_original_energy >= 0:
		dir_light.light_energy = _eclipse_original_energy
		_eclipse_original_energy = -1.0

	# Remove dark overlay
	var canvas = get_node_or_null("EclipseCanvas")
	if canvas:
		canvas.queue_free()

	# Restore enemy mesh visibility
	for enemy in _eclipse_hidden_enemies:
		if is_instance_valid(enemy):
			var mesh = enemy.find_child("MeshInstance3D", true, false)
			if mesh and mesh is MeshInstance3D:
				mesh.visible = true
	_eclipse_hidden_enemies.clear()

func _find_directional_light() -> DirectionalLight3D:
	var lights = get_tree().get_nodes_in_group("directional_light")
	if not lights.is_empty():
		return lights[0] as DirectionalLight3D
	# Fallback: search in scene tree
	var root = get_tree().current_scene
	if root:
		var light = root.find_child("DirectionalLight3D", true, false)
		if light and light is DirectionalLight3D:
			return light
	return null

# ---- Meteor Shower (min 12) ----
# Spawn 15 meteors staggered over 10 seconds, each falls from y=20 to y=0
# dealing 50 damage in radius 2.0 to enemies AND player
func _start_meteor_shower() -> void:
	_meteor_spawns_remaining = 15
	_meteor_spawn_interval = 10.0 / 15.0  # ~0.67s between spawns
	_meteor_spawn_timer = 0.0  # Spawn first immediately

func _spawn_single_meteor() -> void:
	var players = get_tree().get_nodes_in_group("players")
	if players.is_empty():
		return
	var center = players[0].global_position

	# Random position near player
	var offset = Vector3(rng.randf_range(-12, 12), 0, rng.randf_range(-12, 12))
	var target_pos = center + offset
	target_pos.y = 0.0

	# Create meteor Area3D
	var meteor = Area3D.new()
	meteor.name = "Meteor"

	# Collision shape (sphere radius 2.0 for damage area)
	var col_shape = CollisionShape3D.new()
	var sphere_shape = SphereShape3D.new()
	sphere_shape.radius = 2.0
	col_shape.shape = sphere_shape
	meteor.add_child(col_shape)

	# Visual mesh
	var mesh_instance = MeshInstance3D.new()
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = 0.5
	sphere_mesh.height = 1.0
	mesh_instance.mesh = sphere_mesh
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.3, 0.0)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.5, 0.0)
	mat.emission_energy_multiplier = 3.0
	mesh_instance.material_override = mat
	meteor.add_child(mesh_instance)

	# Start position (above target)
	meteor.global_position = target_pos + Vector3(0, 20, 0)
	get_parent().add_child(meteor)

	# Animate falling with a tween
	var tween = create_tween()
	tween.tween_property(meteor, "global_position", target_pos, 1.0).set_ease(Tween.EASE_IN)
	tween.tween_callback(_meteor_impact.bind(meteor, target_pos))

func _meteor_impact(meteor: Node3D, impact_pos: Vector3) -> void:
	if not is_instance_valid(meteor):
		return

	var damage := 50
	var radius := 2.0

	# Damage enemies in radius
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if is_instance_valid(enemy) and enemy.global_position.distance_to(impact_pos) <= radius:
			if enemy.has_method("take_damage"):
				enemy.take_damage(damage)

	# Damage player in radius
	var players = get_tree().get_nodes_in_group("players")
	for player in players:
		if is_instance_valid(player) and player.global_position.distance_to(impact_pos) <= radius:
			GameManager.take_damage(damage)

	# Screen shake on impact
	ScreenEffects.shake(0.15)

	# Remove meteor
	meteor.queue_free()

# ---- Angel Challenge (min 15) ----
# Double permanent damage but halve current HP
func _do_angel_challenge() -> void:
	GameManager.perm_damage_mult *= 2.0
	GameManager.player_hp = GameManager.player_hp / 2

# ---- Fever Mode (kill streak trigger) ----
# Triggered when 20+ enemies killed in 5 seconds
# Doubles damage and 1.5x speed for 10 seconds
func _start_fever_mode() -> void:
	_fever_active = true
	_fever_prev_damage_mult = GameManager.perm_damage_mult
	_fever_prev_speed_mult = GameManager.speed_mult
	GameManager.perm_damage_mult *= 2.0
	GameManager.speed_mult *= 1.5
	event_started.emit("fever_mode")

	# Clear recent kills to prevent re-triggering immediately
	_recent_kills.clear()

	# Timer to end fever mode after 10 seconds
	var timer = get_tree().create_timer(10.0)
	timer.timeout.connect(_end_fever_mode)

func _end_fever_mode() -> void:
	if not _fever_active:
		return
	_fever_active = false
	GameManager.perm_damage_mult = _fever_prev_damage_mult
	GameManager.speed_mult = _fever_prev_speed_mult
	event_ended.emit("fever_mode")
