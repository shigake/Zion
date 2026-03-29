extends Node3D

## Gerencia eventos especiais durante a run (estilo Vampire Survivors).
## Eventos a cada ~3-5 minutos, alternando hordas e mini-bosses.
## Timeline: Horda Dourada (3), Elite Rush (5), Eclipse (8), Mini-boss (10),
## Meteoros (12), Horda Massiva (15), Roda da Fortuna (18), Mini-boss 2 (20),
## Portal (22), Boss Final (25 via spawner).

signal event_started(event_name: String)
signal event_ended(event_name: String)
signal event_warning(event_name: String, seconds_left: float)

var active_event: String = ""
var event_timer: float = 0.0
var next_random_event_time: float = 0.0
var rng: RandomNumberGenerator = RandomNumberGenerator.new()

## Annulus spawning — mesmas constantes do enemy_spawner
const MIN_SPAWN_RADIUS: float = 15.0
const MAX_SPAWN_RADIUS: float = 20.0

## Gera posição em anel (annulus) ao redor de um centro
func _get_annulus_position(center: Vector3, min_r: float = MIN_SPAWN_RADIUS, max_r: float = MAX_SPAWN_RADIUS) -> Vector3:
	var angle = rng.randf() * TAU
	var distance = rng.randf_range(min_r, max_r)
	return center + Vector3(cos(angle), 0, sin(angle)) * distance

# Eclipse state
var _eclipse_original_energy: float = -1.0
var _eclipse_original_modulate: Color = Color.WHITE
var _eclipse_glowing_enemies: Array = []
var _eclipse_xp_bonus_active: bool = false
var _eclipse_prev_xp_mult: float = 1.0

# Meteor shower state
var _meteor_spawns_remaining: int = 0
var _meteor_spawn_timer: float = 0.0
var _meteor_spawn_interval: float = 0.0

# Fever mode state
var _recent_kills: Array[float] = []  # timestamps of recent kills
var _fever_active: bool = false
var _fever_prev_damage_mult: float = 1.0
var _fever_prev_speed_mult: float = 1.0
var _fever_canvas: CanvasLayer = null
var _fever_overlay: ColorRect = null
var _fever_pulse_tween: Tween = null
var _fever_shake_timer: float = 0.0

# Merchant state
var _merchant_node: Node3D = null
var _merchant_items: Array = []

# Portal Dimensional state
var _portal_enemies_remaining: int = 0
var _portal_original_pos: Vector3 = Vector3.ZERO
var _portal_active: bool = false

# Warning state
var _warned_events: Array = []  # events already warned about
const WARNING_TIME: float = 10.0  # warn 10 seconds before

# Eventos fixos por tempo — estilo Vampire Survivors (a cada ~3-5 min)
var timed_events: Dictionary = {
	180.0: "golden_horde",       # Min 3 — warmup horde
	300.0: "elite_horde",        # Min 5 — elite rush
	480.0: "eclipse",            # Min 8 — darkness
	600.0: "miniboss",           # Min 10 — mini-boss
	720.0: "meteor_shower",      # Min 12 — chaos
	900.0: "massive_horde",      # Min 15 — massive horde + elites
	1080.0: "roulette",          # Min 18 — roda da fortuna
	1200.0: "miniboss_strong",   # Min 20 — mini-boss forte
	1320.0: "portal_dimensional", # Min 22 — portal
	# Min 25 (1500s) — Boss final (handled by enemy_spawner)
}
var triggered_timed: Array = []

func _ready() -> void:
	rng.randomize()
	next_random_event_time = rng.randf_range(120, 240)  # Primeiro evento aleatorio entre 2-4 min
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

	# Fever mode screen shake pulse every 2 seconds
	if _fever_active:
		_fever_shake_timer += delta
		if _fever_shake_timer >= 2.0:
			_fever_shake_timer = 0.0
			ScreenEffects.shake(0.06)

	# Evento ativo
	if active_event != "":
		event_timer -= delta
		if event_timer <= 0:
			_end_event()
		return

	# Check warnings for upcoming timed events (10s before)
	for time in timed_events:
		if time not in _warned_events and time not in triggered_timed:
			if GameManager.game_time >= time - WARNING_TIME and GameManager.game_time < time:
				_warned_events.append(time)
				event_warning.emit(timed_events[time], time - GameManager.game_time)

	# Check timed events
	for time in timed_events:
		if GameManager.game_time >= time and time not in triggered_timed:
			triggered_timed.append(time)
			_start_event(timed_events[time])
			return

	# Check random events (between timed events)
	if GameManager.game_time >= next_random_event_time:
		var random_events = ["treasure_goblin", "merchant", "chest_mimic"]
		var event = random_events[rng.randi() % random_events.size()]
		_start_event(event)
		next_random_event_time = GameManager.game_time + rng.randf_range(90, 180)

func _on_enemy_killed(position: Vector3, xp_value: int) -> void:
	_recent_kills.append(GameManager.game_time)

func _start_event(event_name: String) -> void:
	active_event = event_name
	GameManager.events_triggered.append(event_name)
	event_started.emit(event_name)

	# Screen shake + flash for major events
	var is_major = event_name in ["elite_horde", "massive_horde", "miniboss", "miniboss_strong"]
	if is_major:
		ScreenEffects.shake(0.2)

	match event_name:
		"golden_horde":
			event_timer = 20.0
			_spawn_golden_horde()
		"elite_horde":
			event_timer = 25.0
			_spawn_elite_horde()
		"massive_horde":
			event_timer = 30.0
			_spawn_massive_horde()
		"miniboss":
			event_timer = 1.0  # Instant spawn, boss stays until killed
			_spawn_event_miniboss(false)
		"miniboss_strong":
			event_timer = 1.0  # Instant spawn, boss stays until killed
			_spawn_event_miniboss(true)
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
			event_timer = 15.0
			_start_eclipse()
		"meteor_shower":
			event_timer = 12.0  # 10s of spawns + 2s buffer for last meteor
			_start_meteor_shower()
		"angel_challenge":
			event_timer = 1.0  # Instant effect, short timer
			_do_angel_challenge()
		"portal_dimensional":
			event_timer = 30.0
			_start_portal_dimensional()
		"chest_mimic":
			event_timer = 30.0
			_spawn_chest_mimic()

func _end_event() -> void:
	var ended = active_event

	# Cleanup for specific events
	match ended:
		"eclipse":
			_end_eclipse()
		"portal_dimensional":
			_end_portal_dimensional()
		"merchant":
			_cleanup_merchant()

	active_event = ""
	event_ended.emit(ended)

func _spawn_golden_horde() -> void:
	var players = GameManager.get_players()
	if players.is_empty():
		return
	var center = players[0].global_position
	var slime_scene = preload("res://scenes/enemies/slime.tscn")

	for i in range(30):
		var pos = _get_annulus_position(center)
		var enemy = slime_scene.instantiate()
		if enemy is EnemyBase3D:
			enemy.enemy_color = Color(1.0, 0.85, 0.2)
			enemy.xp_drop = 5
			enemy.max_hp = 5
			enemy.hp = 5
		get_parent().add_child(enemy)
		enemy.global_position = pos
		GameManager.enemies_alive += 1

# ---- Elite Horde (min 5) ----
# Spawna 20 inimigos elite (dourados, 3x HP, 1.5x dmg) de todos os lados
func _spawn_elite_horde() -> void:
	var players = GameManager.get_players()
	if players.is_empty():
		return
	var center = players[0].global_position

	var enemy_scenes = [
		preload("res://scenes/enemies/skeleton.tscn"),
		preload("res://scenes/enemies/bat.tscn"),
		preload("res://scenes/enemies/zombie_runner.tscn"),
		preload("res://scenes/enemies/ghost.tscn"),
	]

	for i in range(20):
		var pos = _get_annulus_position(center)
		var enemy = enemy_scenes[rng.randi() % enemy_scenes.size()].instantiate()
		if enemy is EnemyBase3D:
			enemy.max_hp = int(enemy.max_hp * 3.0)
			enemy.hp = enemy.max_hp
			enemy.damage = int(enemy.damage * 1.5)
			enemy.speed *= 1.2
			enemy.xp_drop = enemy.xp_drop * 5
			enemy.enemy_color = Color(1.0, 0.85, 0.2)  # Dourado
			enemy.scale = Vector3(1.3, 1.3, 1.3)
		get_parent().add_child(enemy)
		enemy.global_position = pos
		GameManager.enemies_alive += 1

# ---- Massive Horde (min 15) ----
# Horda massiva: 50 inimigos normais + 10 elites de todos os tipos
func _spawn_massive_horde() -> void:
	var players = GameManager.get_players()
	if players.is_empty():
		return
	var center = players[0].global_position

	var basic_scenes = [
		preload("res://scenes/enemies/slime.tscn"),
		preload("res://scenes/enemies/bat.tscn"),
		preload("res://scenes/enemies/skeleton.tscn"),
		preload("res://scenes/enemies/zombie_runner.tscn"),
		preload("res://scenes/enemies/ghost.tscn"),
		preload("res://scenes/enemies/slime_big.tscn"),
	]
	var elite_scenes = [
		preload("res://scenes/enemies/skeleton.tscn"),
		preload("res://scenes/enemies/zombie_runner.tscn"),
		preload("res://scenes/enemies/bomber.tscn"),
		preload("res://scenes/enemies/tank.tscn"),
		preload("res://scenes/enemies/skeleton_archer.tscn"),
	]

	# Spawn 50 normais em ondas circulares (annulus)
	for i in range(50):
		if GameManager.enemies_alive >= GameManager.max_enemies:
			break
		var pos = _get_annulus_position(center)
		var enemy = basic_scenes[rng.randi() % basic_scenes.size()].instantiate()
		get_parent().add_child(enemy)
		enemy.global_position = pos
		GameManager.enemies_alive += 1

	# Spawn 10 elites (mais fortes, dourados)
	for i in range(10):
		if GameManager.enemies_alive >= GameManager.max_enemies:
			break
		var pos = _get_annulus_position(center)
		var enemy = elite_scenes[rng.randi() % elite_scenes.size()].instantiate()
		if enemy is EnemyBase3D:
			enemy.max_hp = int(enemy.max_hp * 3.0)
			enemy.hp = enemy.max_hp
			enemy.damage = int(enemy.damage * 1.5)
			enemy.speed *= 1.2
			enemy.xp_drop = enemy.xp_drop * 5
			enemy.enemy_color = Color(1.0, 0.85, 0.2)
			enemy.scale = Vector3(1.3, 1.3, 1.3)
		get_parent().add_child(enemy)
		enemy.global_position = pos
		GameManager.enemies_alive += 1

# ---- Mini-boss Event (min 10, min 20) ----
# Spawna mini-boss via evento (ao inves de via spawner)
# strong=false: mini-boss normal (min 10), strong=true: mini-boss forte (min 20)
func _spawn_event_miniboss(strong: bool) -> void:
	var players = GameManager.get_players()
	if players.is_empty():
		return
	var pos = players[0].global_position
	var spawn_pos = _get_annulus_position(pos)

	var stage = GameManager.selected_stage
	var mb_config: Dictionary

	# Configuracao por stage
	match stage:
		"forest":
			mb_config = {"hp": 600, "dmg": 30, "spd": 6.0, "color": Color(0.1, 0.0, 0.2), "name": "Shadow Treant"}
		"farm":
			mb_config = {"hp": 800, "dmg": 35, "spd": 8.0, "color": Color(0.5, 0.5, 0.5), "name": "Mad Bull"}
		"tokyo":
			mb_config = {"hp": 700, "dmg": 30, "spd": 7.0, "color": Color(0.2, 0.2, 0.3), "name": "Mecha Ninja"}
		"volcano":
			mb_config = {"hp": 1000, "dmg": 40, "spd": 3.0, "color": Color(0.6, 0.1, 0.0), "name": "Cerberus"}
		"ocean":
			mb_config = {"hp": 800, "dmg": 35, "spd": 4.0, "color": Color(0.1, 0.3, 0.5), "name": "Baby Kraken"}
		"arena":
			mb_config = {"hp": 900, "dmg": 45, "spd": 5.0, "color": Color(0.7, 0.5, 0.1), "name": "Champion Gladiator"}
		"space":
			mb_config = {"hp": 850, "dmg": 30, "spd": 3.5, "color": Color(0.3, 0.6, 0.2), "name": "Alien Queen"}
		"castle":
			mb_config = {"hp": 700, "dmg": 35, "spd": 6.0, "color": Color(0.5, 0.0, 0.2), "name": "Vampiress"}
		"candy":
			mb_config = {"hp": 1200, "dmg": 25, "spd": 2.0, "color": Color(0.9, 0.6, 0.7), "name": "Triple Layer Cake"}
		_:
			mb_config = {"hp": 500, "dmg": 25, "spd": 2.5, "color": Color(0.4, 0.15, 0.15), "name": "Giant Zombie"}

	# Mini-boss forte (min 20): 2x HP, 1.5x damage, mais rapido, maior
	var hp_mult := 2.0 if strong else 1.0
	var dmg_mult := 1.5 if strong else 1.0
	var spd_mult := 1.3 if strong else 1.0
	var scale_val := 3.0 if strong else 2.5
	var boss_name: String = mb_config["name"]
	if strong:
		boss_name = "Mega " + boss_name

	var zombie_scene = preload("res://scenes/enemies/zombie_runner.tscn")
	var boss = zombie_scene.instantiate()
	if boss is EnemyBase3D:
		boss.max_hp = int(mb_config["hp"] * hp_mult)
		boss.hp = boss.max_hp
		boss.damage = int(mb_config["dmg"] * dmg_mult)
		boss.speed = mb_config["spd"] * spd_mult
		boss.xp_drop = 50 if not strong else 100
		boss.enemy_color = mb_config["color"]
		boss.scale = Vector3(scale_val, scale_val, scale_val)
	get_parent().add_child(boss)
	boss.global_position = spawn_pos
	GameManager.enemies_alive += 1
	GameManager.miniboss_spawned.emit(boss_name)

	AudioManager.play_sfx("boss_appear")

	# Tambem spawna escoltas com o mini-boss forte
	if strong:
		for i in range(5):
			var escort_angle = (float(i) / 5.0) * TAU
			var escort_pos = spawn_pos + Vector3(cos(escort_angle), 0, sin(escort_angle)) * 5.0
			var escort_scenes = [
				preload("res://scenes/enemies/skeleton.tscn"),
				preload("res://scenes/enemies/bomber.tscn"),
			]
			var escort = escort_scenes[rng.randi() % escort_scenes.size()].instantiate()
			if escort is EnemyBase3D:
				escort.max_hp = int(escort.max_hp * 2.0)
				escort.hp = escort.max_hp
				escort.damage = int(escort.damage * 1.3)
				escort.enemy_color = mb_config["color"].lightened(0.3)
				escort.scale = Vector3(1.5, 1.5, 1.5)
			get_parent().add_child(escort)
			escort.global_position = escort_pos
			GameManager.enemies_alive += 1

func _spawn_treasure_goblin() -> void:
	var players = GameManager.get_players()
	if players.is_empty():
		return
	var center = players[0].global_position
	var bat_scene = preload("res://scenes/enemies/bat.tscn")

	var goblin = bat_scene.instantiate()
	if goblin is EnemyBase3D:
		goblin.enemy_color = Color(0.2, 1.0, 0.3)
		goblin.speed = 8.0  # Rapido, foge
		goblin.max_hp = 100
		goblin.hp = 100
		goblin.xp_drop = 30
		goblin.scale = Vector3(1.5, 1.5, 1.5)
	get_parent().add_child(goblin)
	goblin.global_position = _get_annulus_position(center)
	GameManager.enemies_alive += 1

func _spawn_merchant() -> void:
	var players = GameManager.get_players()
	if players.is_empty():
		return
	var center = players[0].global_position
	var offset = Vector3(rng.randf_range(-3, 3), 0, rng.randf_range(-3, 3))

	# Cria NPC merchant visual
	_merchant_node = Node3D.new()
	_merchant_node.name = "Merchant"

	var body = MeshInstance3D.new()
	var capsule = CapsuleMesh.new()
	capsule.radius = 0.3
	capsule.height = 1.2
	body.mesh = capsule
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.5, 0.9)
	mat.emission_enabled = true
	mat.emission = Color(0.1, 0.3, 0.6)
	mat.emission_energy_multiplier = 1.5
	body.material_override = mat
	body.position.y = 0.6
	_merchant_node.add_child(body)

	# Label
	var label = Label3D.new()
	label.text = "Mercador"
	label.font_size = 32
	label.outline_size = 4
	label.modulate = Color(0.2, 0.5, 0.9)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position.y = 1.6
	_merchant_node.add_child(label)

	# Interaction Area
	var area = Area3D.new()
	area.name = "InteractArea"
	var col = CollisionShape3D.new()
	var shape = SphereShape3D.new()
	shape.radius = 2.5
	col.shape = shape
	area.add_child(col)
	area.collision_layer = 0
	area.collision_mask = 1  # Detect players
	_merchant_node.add_child(area)

	get_parent().add_child(_merchant_node)
	_merchant_node.global_position = center + offset

	# Generate 3 random items to sell
	_merchant_items.clear()
	var all_items = ItemDB.get_all_item_ids()
	all_items.shuffle()
	for i in range(mini(3, all_items.size())):
		var item_data = ItemDB.get_item(all_items[i])
		_merchant_items.append({
			"id": all_items[i],
			"name": item_data.get("name", all_items[i]),
			"cost": rng.randi_range(5, 15),
		})

	# Show merchant UI when player enters area
	area.body_entered.connect(_on_merchant_body_entered)

func _on_merchant_body_entered(body: Node3D) -> void:
	if not body.is_in_group("players"):
		return
	_show_merchant_ui()

func _show_merchant_ui() -> void:
	# Se ja tem UI aberta, nao abre outra
	if get_node_or_null("MerchantUI"):
		return
	# Cria UI de merchant como CanvasLayer
	var canvas = CanvasLayer.new()
	canvas.name = "MerchantUI"
	canvas.layer = 15
	canvas.process_mode = Node.PROCESS_MODE_ALWAYS  # Funciona mesmo com tree pausada

	var panel = PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.position = Vector2(-200, -150)
	panel.custom_minimum_size = Vector2(400, 300)
	canvas.add_child(panel)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	panel.add_child(vbox)

	var title = Label.new()
	title.text = LocaleManager.tr_key("merchant_title")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	for item in _merchant_items:
		var btn = Button.new()
		btn.text = "%s - %d cristais" % [item["name"], item["cost"]]
		btn.pressed.connect(_buy_merchant_item.bind(item, btn))
		vbox.add_child(btn)

	var close_btn = Button.new()
	close_btn.text = LocaleManager.tr_key("merchant_close")
	close_btn.pressed.connect(func():
		canvas.queue_free()
		GameManager.paused = false
		get_tree().paused = false
	)
	vbox.add_child(close_btn)

	add_child(canvas)
	GameManager.paused = true
	get_tree().paused = true

func _buy_merchant_item(item: Dictionary, btn: Button) -> void:
	if GameManager.crystals_this_run >= item["cost"]:
		GameManager.crystals_this_run -= item["cost"]
		GameManager.add_item(item["id"])
		btn.text = item["name"] + " - " + LocaleManager.tr_key("merchant_bought")
		btn.disabled = true

func _cleanup_merchant() -> void:
	if is_instance_valid(_merchant_node):
		_merchant_node.queue_free()
		_merchant_node = null
	var ui = get_node_or_null("MerchantUI")
	if ui:
		ui.queue_free()

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

# ---- Eclipse Total (min 8) ----
# Darken the stage, enemies get a glow effect, bonus XP for 15 seconds
func _start_eclipse() -> void:
	# Reduce DirectionalLight energy
	var dir_light = _find_directional_light()
	if dir_light:
		_eclipse_original_energy = dir_light.light_energy
		dir_light.light_energy = 0.15

	# Darken the stage by modulating the current scene
	var root = get_tree().current_scene
	if root:
		_eclipse_original_modulate = root.modulate if "modulate" in root else Color.WHITE
		var tween = create_tween()
		tween.tween_property(root, "modulate", Color(0.2, 0.2, 0.3), 1.0)

	# Add subtle dark overlay via CanvasLayer for extra atmosphere
	var overlay = ColorRect.new()
	overlay.name = "EclipseOverlay"
	overlay.color = Color(0.05, 0.0, 0.1, 0.4)
	overlay.anchors_preset = Control.PRESET_FULL_RECT
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var canvas = CanvasLayer.new()
	canvas.name = "EclipseCanvas"
	canvas.layer = 10
	canvas.add_child(overlay)
	add_child(canvas)

	# Make enemies glow (brighter modulate + emission-like color)
	_eclipse_glowing_enemies.clear()
	var enemies = GameManager.get_enemies()
	for enemy in enemies:
		if is_instance_valid(enemy) and enemy is Node3D:
			enemy.modulate = Color(2.0, 2.0, 2.5)  # Bright glow
			_eclipse_glowing_enemies.append(enemy)

	# Bonus XP during eclipse (1.5x multiplier)
	_eclipse_xp_bonus_active = true
	_eclipse_prev_xp_mult = GameManager.xp_mult
	GameManager.xp_mult = _eclipse_prev_xp_mult * 1.5

func _end_eclipse() -> void:
	# Restore DirectionalLight
	var dir_light = _find_directional_light()
	if dir_light and _eclipse_original_energy >= 0:
		dir_light.light_energy = _eclipse_original_energy
		_eclipse_original_energy = -1.0

	# Restore stage modulate
	var root = get_tree().current_scene
	if root:
		var tween = create_tween()
		tween.tween_property(root, "modulate", _eclipse_original_modulate, 1.0)

	# Remove dark overlay
	var canvas = get_node_or_null("EclipseCanvas")
	if canvas:
		canvas.queue_free()

	# Remove enemy glow
	for enemy in _eclipse_glowing_enemies:
		if is_instance_valid(enemy) and enemy is Node3D:
			enemy.modulate = Color.WHITE
	_eclipse_glowing_enemies.clear()

	# Restore XP multiplier
	if _eclipse_xp_bonus_active:
		GameManager.xp_mult = _eclipse_prev_xp_mult
		_eclipse_xp_bonus_active = false

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
	var players = GameManager.get_players()
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
	get_parent().add_child(meteor)
	meteor.global_position = target_pos + Vector3(0, 20, 0)

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
	var enemies = GameManager.get_enemies()
	for enemy in enemies:
		if is_instance_valid(enemy) and enemy.global_position.distance_to(impact_pos) <= radius:
			if enemy.has_method("take_damage"):
				enemy.take_damage(damage)

	# Damage player in radius
	var players = GameManager.get_players()
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
	_fever_shake_timer = 0.0

	# Create warm-colored overlay
	_fever_canvas = CanvasLayer.new()
	_fever_canvas.name = "FeverCanvas"
	_fever_canvas.layer = 10
	_fever_overlay = ColorRect.new()
	_fever_overlay.name = "FeverOverlay"
	_fever_overlay.color = Color(1.0, 0.7, 0.1, 0.1)
	_fever_overlay.anchors_preset = Control.PRESET_FULL_RECT
	_fever_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fever_canvas.add_child(_fever_overlay)
	add_child(_fever_canvas)

	# Pulse overlay alpha using a looping tween (sine wave between 0.05 and 0.15)
	_fever_pulse_tween = create_tween()
	_fever_pulse_tween.set_loops()
	_fever_pulse_tween.tween_property(_fever_overlay, "color:a", 0.15, 0.8).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	_fever_pulse_tween.tween_property(_fever_overlay, "color:a", 0.05, 0.8).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

	# Timer to end fever mode after 10 seconds
	var timer = get_tree().create_timer(10.0)
	timer.timeout.connect(_end_fever_mode)

func _end_fever_mode() -> void:
	if not _fever_active:
		return
	_fever_active = false
	GameManager.perm_damage_mult = _fever_prev_damage_mult
	GameManager.speed_mult = _fever_prev_speed_mult

	# Remove fever overlay
	if _fever_pulse_tween and _fever_pulse_tween.is_valid():
		_fever_pulse_tween.kill()
		_fever_pulse_tween = null
	if is_instance_valid(_fever_canvas):
		_fever_canvas.queue_free()
		_fever_canvas = null
	_fever_overlay = null

	event_ended.emit("fever_mode")

# ---- Portal Dimensional (min 20) ----
# Teletransporta o jogador para uma mini-arena com inimigos de elite.
# Sobreviver garante recompensa rara (itens ou XP massivo).

func _start_portal_dimensional() -> void:
	var players = GameManager.get_players()
	if players.is_empty():
		return

	var player = players[0]
	_portal_original_pos = player.global_position
	_portal_active = true

	# Teletransporta o jogador para longe (mini-dungeon area)
	var dungeon_pos = Vector3(500, 0, 500)  # Longe da arena principal
	player.global_position = dungeon_pos

	# Visual: flash branco
	var overlay = ColorRect.new()
	overlay.name = "PortalFlash"
	overlay.color = Color(0.6, 0.3, 1.0, 0.5)
	overlay.anchors_preset = Control.PRESET_FULL_RECT
	var canvas = CanvasLayer.new()
	canvas.name = "PortalCanvas"
	canvas.layer = 10
	canvas.add_child(overlay)
	add_child(canvas)

	# Fade out the overlay
	var tween = create_tween()
	tween.tween_property(overlay, "color:a", 0.15, 1.5)

	ScreenEffects.shake(0.2)

	# Spawna inimigos de elite na mini-dungeon
	_portal_enemies_remaining = 10
	var enemy_scenes = [
		preload("res://scenes/enemies/skeleton.tscn"),
		preload("res://scenes/enemies/zombie_runner.tscn"),
		preload("res://scenes/enemies/bomber.tscn"),
		preload("res://scenes/enemies/ghost.tscn"),
	]

	for i in range(10):
		var spawn_pos = _get_annulus_position(dungeon_pos, 8.0, 15.0)
		var enemy = enemy_scenes[rng.randi() % enemy_scenes.size()].instantiate()
		# Faz todos elite
		if enemy is EnemyBase3D:
			enemy.max_hp = int(enemy.max_hp * 3.0)
			enemy.hp = enemy.max_hp
			enemy.damage = int(enemy.damage * 1.5)
			enemy.xp_drop = enemy.xp_drop * 5
			enemy.enemy_color = Color(0.6, 0.2, 0.9)  # Roxo
			enemy.scale = Vector3(1.3, 1.3, 1.3)
		get_parent().add_child(enemy)
		enemy.global_position = spawn_pos
		GameManager.enemies_alive += 1

func _end_portal_dimensional() -> void:
	if not _portal_active:
		return
	_portal_active = false

	var players = GameManager.get_players()
	if not players.is_empty():
		players[0].global_position = _portal_original_pos

	# Remove overlay
	var canvas = get_node_or_null("PortalCanvas")
	if canvas:
		canvas.queue_free()

	# Recompensa: cura + XP bonus
	GameManager.heal(GameManager.get_effective_max_hp() / 2)
	GameManager.add_xp(50)

	ScreenEffects.shake(0.15)

# ---- Chest Mimic (aleatorio) ----
# Spawna um bau falso que, ao se aproximar, vira um mini-boss Mimic.

func _spawn_chest_mimic() -> void:
	var players = GameManager.get_players()
	if players.is_empty():
		return
	var center = players[0].global_position

	var mimic_scene = preload("res://scenes/enemies/mimic.tscn")
	var mimic = mimic_scene.instantiate()
	# Faz o mimic mais forte como mini-boss
	if mimic is EnemyBase3D:
		mimic.max_hp = 300
		mimic.hp = 300
		mimic.damage = 30
		mimic.xp_drop = 30
		mimic.scale = Vector3(1.5, 1.5, 1.5)
	get_parent().add_child(mimic)
	mimic.global_position = _get_annulus_position(center)
	GameManager.enemies_alive += 1
