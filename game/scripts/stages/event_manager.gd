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

	# Cria NPC merchant visual — visual mais elaborado
	_merchant_node = Node3D.new()
	_merchant_node.name = "Merchant"

	# Base body (robe/capa)
	var body = MeshInstance3D.new()
	var capsule = CapsuleMesh.new()
	capsule.radius = 0.35
	capsule.height = 1.3
	body.mesh = capsule
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.12, 0.2, 0.45)
	mat.emission_enabled = true
	mat.emission = Color(0.08, 0.2, 0.5)
	mat.emission_energy_multiplier = 2.0
	body.material_override = mat
	body.position.y = 0.65
	_merchant_node.add_child(body)

	# Crystal floating above head (rotating)
	var crystal_mesh = MeshInstance3D.new()
	var prism = PrismMesh.new()
	prism.size = Vector3(0.25, 0.35, 0.25)
	crystal_mesh.mesh = prism
	var crystal_mat = StandardMaterial3D.new()
	crystal_mat.albedo_color = Color(0.3, 0.7, 1.0, 0.85)
	crystal_mat.emission_enabled = true
	crystal_mat.emission = Color(0.2, 0.5, 1.0)
	crystal_mat.emission_energy_multiplier = 3.0
	crystal_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	crystal_mesh.material_override = crystal_mat
	crystal_mesh.position.y = 1.7
	_merchant_node.add_child(crystal_mesh)

	# Floating glow sphere around crystal
	var glow_mesh = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 0.2
	sphere.height = 0.4
	glow_mesh.mesh = sphere
	var glow_mat = StandardMaterial3D.new()
	glow_mat.albedo_color = Color(0.15, 0.4, 0.9, 0.2)
	glow_mat.emission_enabled = true
	glow_mat.emission = Color(0.1, 0.3, 0.8)
	glow_mat.emission_energy_multiplier = 2.5
	glow_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glow_mat.no_depth_test = true
	glow_mesh.material_override = glow_mat
	glow_mesh.position.y = 1.7
	_merchant_node.add_child(glow_mesh)

	# Label
	var label = Label3D.new()
	label.text = "✦ Mercador ✦"
	label.font_size = 36
	label.outline_size = 6
	label.outline_modulate = Color(0.05, 0.1, 0.3)
	label.modulate = Color(0.4, 0.7, 1.0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position.y = 2.1
	label.no_depth_test = true
	_merchant_node.add_child(label)

	# Subtitle hint
	var hint_label = Label3D.new()
	hint_label.text = "Aproxime-se"
	hint_label.font_size = 20
	hint_label.outline_size = 3
	hint_label.outline_modulate = Color(0.05, 0.05, 0.15)
	hint_label.modulate = Color(0.6, 0.65, 0.8, 0.8)
	hint_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	hint_label.position.y = 1.85
	hint_label.no_depth_test = true
	_merchant_node.add_child(hint_label)

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

	AudioManager.play_sfx("menu_click")

	# --- CanvasLayer ---
	var canvas = CanvasLayer.new()
	canvas.name = "MerchantUI"
	canvas.layer = 15
	canvas.process_mode = Node.PROCESS_MODE_ALWAYS

	# --- Dark overlay backdrop ---
	var overlay = ColorRect.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0, 0, 0, 0)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	canvas.add_child(overlay)

	# Fade in overlay
	var overlay_tween = create_tween()
	overlay_tween.tween_property(overlay, "color", Color(0, 0, 0, 0.65), 0.25)

	# --- Center container for the panel ---
	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(center)

	# --- Main panel with custom style ---
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(480, 0)
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.08, 0.1, 0.18, 0.97)
	panel_style.border_color = Color(0.2, 0.5, 0.9, 0.8)
	panel_style.set_border_width_all(2)
	panel_style.border_width_top = 3
	panel_style.set_corner_radius_all(12)
	panel_style.set_content_margin_all(20)
	panel_style.content_margin_top = 16
	panel_style.content_margin_bottom = 16
	panel_style.shadow_color = Color(0.1, 0.3, 0.6, 0.4)
	panel_style.shadow_size = 12
	panel_style.shadow_offset = Vector2(0, 6)
	panel.add_theme_stylebox_override("panel", panel_style)
	center.add_child(panel)

	var main_vbox = VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 12)
	panel.add_child(main_vbox)

	# --- Header section ---
	var header = VBoxContainer.new()
	header.add_theme_constant_override("separation", 4)
	main_vbox.add_child(header)

	# Merchant icon + title
	var title_row = HBoxContainer.new()
	title_row.alignment = BoxContainer.ALIGNMENT_CENTER
	title_row.add_theme_constant_override("separation", 10)
	header.add_child(title_row)

	# Crystal icon
	var crystal_icon_path = "res://assets/sprites/ui/currency.png"
	if ResourceLoader.exists(crystal_icon_path):
		var crystal_icon = TextureRect.new()
		crystal_icon.texture = load(crystal_icon_path)
		crystal_icon.custom_minimum_size = Vector2(32, 32)
		crystal_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		crystal_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		title_row.add_child(crystal_icon)

	var title = Label.new()
	title.text = "MERCADOR DIMENSIONAL"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(0.3, 0.65, 1.0))
	title_row.add_child(title)

	# Title bounce animation
	title.pivot_offset = Vector2(100, 14)
	title.scale = Vector2(0.5, 0.5)
	var title_tween = create_tween()
	title_tween.set_ease(Tween.EASE_OUT)
	title_tween.set_trans(Tween.TRANS_BACK)
	title_tween.tween_property(title, "scale", Vector2.ONE, 0.4)

	# Subtitle
	var subtitle = Label.new()
	subtitle.text = "Fragmentos dimensionais a venda"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 12)
	subtitle.add_theme_color_override("font_color", Color(0.5, 0.55, 0.7))
	header.add_child(subtitle)

	# --- Crystal balance ---
	var balance_center = CenterContainer.new()
	main_vbox.add_child(balance_center)
	var balance_panel = PanelContainer.new()
	var balance_style = StyleBoxFlat.new()
	balance_style.bg_color = Color(0.1, 0.12, 0.2, 0.8)
	balance_style.border_color = Color(1.0, 0.85, 0.2, 0.5)
	balance_style.set_border_width_all(1)
	balance_style.set_corner_radius_all(6)
	balance_style.content_margin_left = 16
	balance_style.content_margin_right = 16
	balance_style.content_margin_top = 6
	balance_style.content_margin_bottom = 6
	balance_panel.add_theme_stylebox_override("panel", balance_style)
	balance_center.add_child(balance_panel)

	var balance_label = Label.new()
	balance_label.name = "BalanceLabel"
	balance_label.text = "💎 %d cristais" % GameManager.crystals_this_run
	balance_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	balance_label.add_theme_font_size_override("font_size", 16)
	balance_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	balance_panel.add_child(balance_label)

	# --- Separator ---
	var sep = HSeparator.new()
	main_vbox.add_child(sep)

	# --- Item cards ---
	var cards_vbox = VBoxContainer.new()
	cards_vbox.add_theme_constant_override("separation", 8)
	main_vbox.add_child(cards_vbox)

	for i in range(_merchant_items.size()):
		var item = _merchant_items[i]
		var item_data = ItemDB.get_item(item["id"])
		var can_afford = GameManager.crystals_this_run >= item["cost"]
		var already_bought = item.get("bought", false)

		# Card container
		var card = PanelContainer.new()
		var item_color = item_data.get("color", Color(0.4, 0.6, 0.9))
		var card_style = StyleBoxFlat.new()
		if already_bought:
			card_style.bg_color = Color(0.06, 0.08, 0.1, 0.6)
			card_style.border_color = Color(0.3, 0.3, 0.3, 0.3)
		elif can_afford:
			card_style.bg_color = Color(item_color.r * 0.15 + 0.06, item_color.g * 0.15 + 0.06, item_color.b * 0.15 + 0.08, 0.9)
			card_style.border_color = Color(item_color.r, item_color.g, item_color.b, 0.6)
		else:
			card_style.bg_color = Color(0.08, 0.08, 0.1, 0.7)
			card_style.border_color = Color(0.3, 0.2, 0.2, 0.4)
		card_style.set_border_width_all(1)
		card_style.set_corner_radius_all(8)
		card_style.content_margin_left = 12
		card_style.content_margin_right = 12
		card_style.content_margin_top = 10
		card_style.content_margin_bottom = 10
		card.add_theme_stylebox_override("panel", card_style)
		cards_vbox.add_child(card)

		var card_hbox = HBoxContainer.new()
		card_hbox.add_theme_constant_override("separation", 12)
		card.add_child(card_hbox)

		# Item icon
		var icon_bg = ColorRect.new()
		icon_bg.custom_minimum_size = Vector2(48, 48)
		icon_bg.color = Color(item_color.r * 0.3, item_color.g * 0.3, item_color.b * 0.3, 0.5)
		card_hbox.add_child(icon_bg)

		var icon_path = "res://assets/sprites/items/%s.png" % item["id"]
		if ResourceLoader.exists(icon_path):
			var icon = TextureRect.new()
			icon.texture = load(icon_path)
			icon.custom_minimum_size = Vector2(40, 40)
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			icon.position = Vector2(4, 4)
			icon_bg.add_child(icon)
		else:
			var icon_fallback = Label.new()
			icon_fallback.text = "💎"
			icon_fallback.add_theme_font_size_override("font_size", 24)
			icon_fallback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			icon_fallback.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			icon_fallback.set_anchors_preset(Control.PRESET_FULL_RECT)
			icon_bg.add_child(icon_fallback)

		# Item info (name + description)
		var info_vbox = VBoxContainer.new()
		info_vbox.add_theme_constant_override("separation", 2)
		info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card_hbox.add_child(info_vbox)

		var name_label = Label.new()
		name_label.text = item["name"]
		name_label.add_theme_font_size_override("font_size", 15)
		if already_bought:
			name_label.add_theme_color_override("font_color", Color(0.4, 0.4, 0.45))
		else:
			name_label.add_theme_color_override("font_color", Color(item_color.r * 0.5 + 0.5, item_color.g * 0.5 + 0.5, item_color.b * 0.5 + 0.5))
		info_vbox.add_child(name_label)

		var desc = item_data.get("description", "")
		if desc != "":
			var desc_label = Label.new()
			desc_label.text = desc
			desc_label.add_theme_font_size_override("font_size", 11)
			desc_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.55))
			desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			info_vbox.add_child(desc_label)

		# Buy button / status
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(110, 40)
		if already_bought:
			btn.text = "✓ Comprado"
			btn.disabled = true
			btn.add_theme_color_override("font_disabled_color", Color(0.3, 0.6, 0.3))
		elif can_afford:
			btn.text = "💎 %d" % item["cost"]
			var btn_style = StyleBoxFlat.new()
			btn_style.bg_color = Color(0.12, 0.3, 0.15, 0.9)
			btn_style.border_color = Color(0.3, 0.8, 0.4, 0.7)
			btn_style.set_border_width_all(1)
			btn_style.set_corner_radius_all(6)
			btn_style.set_content_margin_all(8)
			btn.add_theme_stylebox_override("normal", btn_style)
			var btn_hover = btn_style.duplicate()
			btn_hover.bg_color = Color(0.15, 0.4, 0.2, 0.95)
			btn_hover.border_color = Color(0.4, 0.9, 0.5, 0.9)
			btn.add_theme_stylebox_override("hover", btn_hover)
			var btn_pressed = btn_style.duplicate()
			btn_pressed.bg_color = Color(0.08, 0.25, 0.1, 0.9)
			btn.add_theme_stylebox_override("pressed", btn_pressed)
			btn.add_theme_color_override("font_color", Color(0.7, 1.0, 0.7))
			btn.add_theme_color_override("font_hover_color", Color(0.9, 1.0, 0.9))
			btn.pressed.connect(_buy_merchant_item.bind(item, canvas))
		else:
			btn.text = "💎 %d" % item["cost"]
			btn.disabled = true
			var btn_dis_style = StyleBoxFlat.new()
			btn_dis_style.bg_color = Color(0.12, 0.08, 0.08, 0.7)
			btn_dis_style.border_color = Color(0.4, 0.2, 0.2, 0.4)
			btn_dis_style.set_border_width_all(1)
			btn_dis_style.set_corner_radius_all(6)
			btn_dis_style.set_content_margin_all(8)
			btn.add_theme_stylebox_override("disabled", btn_dis_style)
			btn.add_theme_color_override("font_disabled_color", Color(0.6, 0.3, 0.3))
		card_hbox.add_child(btn)

		# Staggered card animation
		card.modulate = Color(1, 1, 1, 0)
		card.position.y += 20
		var card_tween = create_tween()
		card_tween.set_ease(Tween.EASE_OUT)
		card_tween.set_trans(Tween.TRANS_CUBIC)
		card_tween.tween_property(card, "modulate:a", 1.0, 0.3).set_delay(0.1 + i * 0.1)
		var pos_tween = create_tween()
		pos_tween.set_ease(Tween.EASE_OUT)
		pos_tween.set_trans(Tween.TRANS_CUBIC)
		pos_tween.tween_property(card, "position:y", 0.0, 0.3).set_delay(0.1 + i * 0.1)

	# --- Separator ---
	var sep2 = HSeparator.new()
	main_vbox.add_child(sep2)

	# --- Close button ---
	var close_center = CenterContainer.new()
	main_vbox.add_child(close_center)
	var close_btn = Button.new()
	close_btn.text = "Fechar"
	close_btn.custom_minimum_size = Vector2(140, 38)
	var close_style = StyleBoxFlat.new()
	close_style.bg_color = Color(0.2, 0.15, 0.15, 0.8)
	close_style.border_color = Color(0.5, 0.3, 0.3, 0.5)
	close_style.set_border_width_all(1)
	close_style.set_corner_radius_all(6)
	close_style.set_content_margin_all(8)
	close_btn.add_theme_stylebox_override("normal", close_style)
	var close_hover = close_style.duplicate()
	close_hover.bg_color = Color(0.3, 0.18, 0.18, 0.9)
	close_hover.border_color = Color(0.7, 0.35, 0.35, 0.7)
	close_btn.add_theme_stylebox_override("hover", close_hover)
	close_btn.add_theme_font_size_override("font_size", 14)
	close_btn.add_theme_color_override("font_color", Color(0.8, 0.7, 0.7))
	close_btn.add_theme_color_override("font_hover_color", Color(1.0, 0.85, 0.85))
	close_btn.pressed.connect(func():
		AudioManager.play_sfx("menu_click")
		canvas.queue_free()
		GameManager.paused = false
		get_tree().paused = false
	)
	close_center.add_child(close_btn)

	# --- Keyboard hint ---
	var hint = Label.new()
	hint.text = "ESC para fechar"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 10)
	hint.add_theme_color_override("font_color", Color(0.35, 0.35, 0.4))
	main_vbox.add_child(hint)

	add_child(canvas)
	GameManager.paused = true
	get_tree().paused = true

	# Focus first buyable button
	await get_tree().process_frame
	var first_btn = _find_first_buyable_btn(cards_vbox)
	if first_btn:
		first_btn.grab_focus()

func _find_first_buyable_btn(container: VBoxContainer) -> Button:
	for card in container.get_children():
		if card is PanelContainer:
			var hbox = card.get_child(0)
			if hbox is HBoxContainer:
				for child in hbox.get_children():
					if child is Button and not child.disabled:
						return child
	return null

func _buy_merchant_item(item: Dictionary, canvas: CanvasLayer) -> void:
	if GameManager.crystals_this_run >= item["cost"]:
		GameManager.crystals_this_run -= item["cost"]
		GameManager.add_item(item["id"])
		item["bought"] = true
		AudioManager.play_sfx("menu_click")
		# Rebuild the merchant UI to reflect changes
		var old_canvas = canvas
		old_canvas.queue_free()
		GameManager.paused = false
		get_tree().paused = false
		# Re-show with updated state
		call_deferred("_show_merchant_ui")
	else:
		AudioManager.play_sfx("error")

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		var ui = get_node_or_null("MerchantUI")
		if ui:
			if get_viewport(): get_viewport().set_input_as_handled()
			AudioManager.play_sfx("menu_click")
			ui.queue_free()
			GameManager.paused = false
			get_tree().paused = false

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
