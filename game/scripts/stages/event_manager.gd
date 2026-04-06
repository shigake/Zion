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

## Annulus spawning centralizado no GameManager

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
var _merchant_ui_cooldown: float = 0.0

# Portal Dimensional state
var _portal_enemies_remaining: int = 0
var _portal_original_pos: Vector3 = Vector3.ZERO
var _portal_active: bool = false

# Warning state
var _warned_events: Array = []  # events already warned about
var WARNING_TIME: float = 10.0  # Aviso N segundos antes do evento

# Eventos fixos por tempo — compactados para runs de 10 min
var timed_events: Dictionary = {
	90.0: "golden_horde",        # Min 1:30 — warmup horde
	150.0: "elite_horde",        # Min 2:30 — elite rush
	210.0: "roulette",           # Min 3:30 — roda da fortuna
	# Min 5:00 (300s) — Boss 1 (handled by enemy_spawner)
	330.0: "miniboss",           # Min 5:30 — mini-boss apos boss
	390.0: "eclipse",            # Min 6:30 — darkness
	450.0: "meteor_shower",      # Min 7:30 — chaos
	510.0: "massive_horde",      # Min 8:30 — massive horde
	540.0: "miniboss_strong",    # Min 9:00 — mini-boss forte
	570.0: "portal_dimensional", # Min 9:30 — portal
	# Min 10:00 (600s) — Boss 2 final (handled by enemy_spawner)
}
var triggered_timed: Array = []

func _ready() -> void:
	# Use seeded RNG for deterministic runs when a seed is set
	if GameManager.current_seed != "":
		rng.seed = hash(GameManager.current_seed) ^ 0xE0E17
	else:
		rng.randomize()
	next_random_event_time = rng.randf_range(GameConstants.EVENT_FIRST_RANDOM_MIN, GameConstants.EVENT_FIRST_RANDOM_MAX)
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
	while not _recent_kills.is_empty() and current_time - _recent_kills[0] > GameConstants.FEVER_KILL_WINDOW:
		_recent_kills.remove_at(0)

	# Check fever mode trigger (20+ kills in 5 seconds)
	if not _fever_active and _recent_kills.size() >= GameConstants.FEVER_KILL_THRESHOLD:
		_start_fever_mode()

	# Fever mode screen shake pulse every 2 seconds
	if _fever_active:
		_fever_shake_timer += delta
		if _fever_shake_timer >= GameConstants.FEVER_SHAKE_INTERVAL:
			_fever_shake_timer = 0.0
			ScreenEffects.shake(GameConstants.FEVER_SHAKE_INTENSITY)

	# Merchant UI cooldown
	if _merchant_ui_cooldown > 0.0:
		_merchant_ui_cooldown -= delta

	# Evento ativo
	if active_event != "":
		event_timer -= delta
		if event_timer <= 0:
			_end_event()
			return
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
		next_random_event_time = GameManager.game_time + rng.randf_range(GameConstants.EVENT_RANDOM_INTERVAL_MIN, GameConstants.EVENT_RANDOM_INTERVAL_MAX)

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
			event_timer = GameConstants.EVENT_GOLDEN_HORDE_DURATION
			_spawn_golden_horde()
		"elite_horde":
			event_timer = GameConstants.EVENT_ELITE_HORDE_DURATION
			_spawn_elite_horde()
		"massive_horde":
			event_timer = GameConstants.EVENT_MASSIVE_HORDE_DURATION
			_spawn_massive_horde()
		"miniboss":
			event_timer = 1.0  # Instant spawn, boss stays until killed
			_spawn_event_miniboss(false)
		"miniboss_strong":
			event_timer = 1.0  # Instant spawn, boss stays until killed
			_spawn_event_miniboss(true)
		"treasure_goblin":
			event_timer = GameConstants.EVENT_GOBLIN_DURATION
			_spawn_treasure_goblin()
		"merchant":
			event_timer = GameConstants.EVENT_MERCHANT_DURATION
			_spawn_merchant()
		"roulette":
			event_timer = GameConstants.EVENT_ROULETTE_DURATION
			_do_roulette()
		"eclipse":
			event_timer = GameConstants.EVENT_ECLIPSE_DURATION
			_start_eclipse()
		"meteor_shower":
			event_timer = GameConstants.EVENT_METEOR_DURATION
			_start_meteor_shower()
		"angel_challenge":
			event_timer = 1.0  # Instant effect, short timer
			_do_angel_challenge()
		"portal_dimensional":
			event_timer = GameConstants.EVENT_PORTAL_DURATION
			_start_portal_dimensional()
		"chest_mimic":
			event_timer = GameConstants.EVENT_CHEST_MIMIC_DURATION
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

	for i in range(GameConstants.EVENT_GOLDEN_HORDE_COUNT):
		var pos = GameManager.get_annulus_position(center)
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

	for i in range(GameConstants.EVENT_ELITE_HORDE_COUNT):
		var pos = GameManager.get_annulus_position(center)
		var enemy = enemy_scenes[rng.randi() % enemy_scenes.size()].instantiate()
		if enemy is EnemyBase3D:
			enemy.max_hp = int(enemy.max_hp * GameConstants.ELITE_HP_MULT)
			enemy.hp = enemy.max_hp
			enemy.damage = int(enemy.damage * GameConstants.ELITE_DAMAGE_MULT)
			enemy.speed *= GameConstants.ELITE_SPEED_MULT
			enemy.xp_drop = enemy.xp_drop * GameConstants.ELITE_XP_MULT
			enemy.enemy_color = GameConstants.ELITE_COLOR
			enemy.scale = GameConstants.ELITE_SCALE
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

	# Spawn normais em ondas circulares (annulus)
	for i in range(GameConstants.EVENT_MASSIVE_NORMAL_COUNT):
		if GameManager.enemies_alive >= GameManager.max_enemies:
			break
		var pos = GameManager.get_annulus_position(center)
		var enemy = basic_scenes[rng.randi() % basic_scenes.size()].instantiate()
		get_parent().add_child(enemy)
		enemy.global_position = pos
		GameManager.enemies_alive += 1

	# Spawn elites (mais fortes, dourados)
	for i in range(GameConstants.EVENT_MASSIVE_ELITE_COUNT):
		if GameManager.enemies_alive >= GameManager.max_enemies:
			break
		var pos = GameManager.get_annulus_position(center)
		var enemy = elite_scenes[rng.randi() % elite_scenes.size()].instantiate()
		if enemy is EnemyBase3D:
			enemy.max_hp = int(enemy.max_hp * GameConstants.ELITE_HP_MULT)
			enemy.hp = enemy.max_hp
			enemy.damage = int(enemy.damage * GameConstants.ELITE_DAMAGE_MULT)
			enemy.speed *= GameConstants.ELITE_SPEED_MULT
			enemy.xp_drop = enemy.xp_drop * GameConstants.ELITE_XP_MULT
			enemy.enemy_color = GameConstants.ELITE_COLOR
			enemy.scale = GameConstants.ELITE_SCALE
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
	var spawn_pos = GameManager.get_annulus_position(pos)

	# Sorteia mini-boss aleatorio do pool da fenda
	var mb_pool = GameConstants.MINIBOSS_POOL.get(GameManager.selected_stage, GameConstants.MINIBOSS_POOL.get("cemetery", []))
	var mb_config: Dictionary
	if mb_pool.is_empty():
		mb_config = {"name": "Giant Zombie", "hp": 500, "dmg": 25, "spd": 2.5, "color": Color(0.4, 0.15, 0.15)}
	else:
		mb_config = mb_pool[rng.randi() % mb_pool.size()]

	# Mini-boss forte (min 20): mais HP, damage, rapido e maior
	var hp_mult := GameConstants.MINIBOSS_STRONG_HP_MULT if strong else 1.0
	var dmg_mult := GameConstants.MINIBOSS_STRONG_DMG_MULT if strong else 1.0
	var spd_mult := GameConstants.MINIBOSS_STRONG_SPD_MULT if strong else 1.0
	var scale_val := GameConstants.MINIBOSS_STRONG_SCALE if strong else GameConstants.MINIBOSS_NORMAL_SCALE
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
		boss.xp_drop = GameConstants.MINIBOSS_NORMAL_XP if not strong else GameConstants.MINIBOSS_STRONG_XP
		boss.enemy_color = mb_config["color"]
		boss.scale = Vector3(scale_val, scale_val, scale_val)
	get_parent().add_child(boss)
	boss.global_position = spawn_pos
	GameManager.enemies_alive += 1
	GameManager.miniboss_spawned.emit(boss_name)

	AudioManager.play_sfx("boss_appear")

	# Tambem spawna escoltas com o mini-boss forte
	if strong:
		for i in range(GameConstants.EVENT_STRONG_MINIBOSS_ESCORTS):
			var escort_angle = (float(i) / float(GameConstants.EVENT_STRONG_MINIBOSS_ESCORTS)) * TAU
			var escort_pos = spawn_pos + Vector3(cos(escort_angle), 0, sin(escort_angle)) * GameConstants.MINIBOSS_ESCORT_RADIUS
			var escort_scenes = [
				preload("res://scenes/enemies/skeleton.tscn"),
				preload("res://scenes/enemies/bomber.tscn"),
			]
			var escort = escort_scenes[rng.randi() % escort_scenes.size()].instantiate()
			if escort is EnemyBase3D:
				escort.max_hp = int(escort.max_hp * GameConstants.MINIBOSS_ESCORT_HP_MULT)
				escort.hp = escort.max_hp
				escort.damage = int(escort.damage * GameConstants.MINIBOSS_ESCORT_DMG_MULT)
				escort.enemy_color = mb_config["color"].lightened(0.3)
				escort.scale = GameConstants.MINIBOSS_ESCORT_SCALE
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
		goblin.speed = GameConstants.GOBLIN_SPEED
		goblin.max_hp = GameConstants.GOBLIN_HP
		goblin.hp = GameConstants.GOBLIN_HP
		goblin.xp_drop = GameConstants.GOBLIN_XP
		goblin.scale = GameConstants.GOBLIN_SCALE
	get_parent().add_child(goblin)
	goblin.global_position = GameManager.get_annulus_position(center)
	GameManager.enemies_alive += 1

func _spawn_merchant() -> void:
	var players = GameManager.get_players()
	if players.is_empty():
		return
	var center = players[0].global_position
	var angle = rng.randf() * TAU
	var dist = rng.randf_range(10.0, 15.0)
	var offset = Vector3(cos(angle) * dist, 0, sin(angle) * dist)

	# Cria NPC merchant visual — sprite pixel art
	_merchant_node = Node3D.new()
	_merchant_node.name = "Merchant"

	# Merchant sprite billboard
	var sprite = Sprite3D.new()
	var sprite_path = "res://assets/sprites/characters/necro.png"  # Hooded figure works as merchant
	if ResourceLoader.exists("res://assets/sprites/ui/merchant.png"):
		sprite_path = "res://assets/sprites/ui/merchant.png"
	if ResourceLoader.exists(sprite_path):
		sprite.texture = load(sprite_path)
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	sprite.pixel_size = 0.07  # Bigger than enemies
	sprite.shaded = false
	sprite.transparent = true
	sprite.modulate = Color(0.6, 0.8, 1.2)  # Blue tint
	sprite.position.y = 0.9
	sprite.name = "MerchantSprite"
	_merchant_node.add_child(sprite)

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
	area.monitoring = true
	area.monitorable = false
	var col = CollisionShape3D.new()
	var shape = SphereShape3D.new()
	shape.radius = 3.0  # Slightly larger for easier interaction
	col.shape = shape
	area.add_child(col)
	area.collision_layer = 0
	area.collision_mask = 1  # Detect players
	_merchant_node.add_child(area)

	get_parent().add_child(_merchant_node)
	_merchant_node.global_position = center + offset
	_merchant_node.add_to_group("merchant")

	# Generate 3 random items to sell (exclude disabled and already owned)
	_merchant_items.clear()
	var all_items = ItemDB.get_all_item_ids()
	var available_items: Array = []
	for iid in all_items:
		var data = ItemDB.get_item(iid)
		if data.is_empty():
			continue
		if data.get("disabled", false):
			continue
		available_items.append(iid)
	# Fallback: if all items filtered out, use all non-disabled as-is
	if available_items.is_empty():
		LogManager.warn("Event", "Merchant: no items available after filtering, using full pool")
		for iid in all_items:
			var data = ItemDB.get_item(iid)
			if not data.is_empty():
				available_items.append(iid)
	available_items.shuffle()
	for i in range(mini(3, available_items.size())):
		var item_data = ItemDB.get_item(available_items[i])
		_merchant_items.append({
			"id": available_items[i],
			"name": item_data.get("name", available_items[i]),
			"cost": rng.randi_range(5, 15),
		})
	LogManager.info("Event", "Merchant: %d items for sale" % _merchant_items.size())

	# Show merchant UI when player enters area
	area.body_entered.connect(_on_merchant_body_entered)
	# Check if player is already inside the area (spawned on top of player)
	call_deferred("_check_merchant_overlap")

func _check_merchant_overlap() -> void:
	if not is_instance_valid(_merchant_node):
		return
	var area = _merchant_node.get_node_or_null("InteractArea")
	if not area or not is_instance_valid(area):
		return
	# Wait for physics to detect overlaps (Area3D needs at least one physics frame)
	await get_tree().physics_frame
	await get_tree().physics_frame
	if not is_instance_valid(_merchant_node) or not is_instance_valid(area):
		return
	var bodies = area.get_overlapping_bodies()
	for body in bodies:
		if body.is_in_group("players"):
			_show_merchant_ui()
			return
	# Fallback: direct distance check since Area3D overlap may fail
	var players = GameManager.get_players()
	if not players.is_empty() and is_instance_valid(_merchant_node):
		var merchant_pos = _merchant_node.global_position
		for player in players:
			if is_instance_valid(player) and merchant_pos.distance_to(player.global_position) < 3.0:
				_show_merchant_ui()
				return

func _on_merchant_body_entered(body: Node3D) -> void:
	if not body.is_in_group("players"):
		return
	if _merchant_ui_cooldown > 0.0:
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

	# --- Dark overlay backdrop --- (STOP captures clicks so they don't reach the game)
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
	close_btn.text = LocaleManager.tr_key("merchant_close")
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
		_merchant_ui_cooldown = 2.0  # Impede reabertura por 2s
	)
	close_center.add_child(close_btn)

	# --- Keyboard hint ---
	var hint = Label.new()
	hint.text = LocaleManager.tr_key("esc_to_close")
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
			_merchant_ui_cooldown = 2.0

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
			GameManager.speed_mult += GameConstants.ROULETTE_SPEED_BOOST
		"damage_boost":
			GameManager.perm_damage_mult += GameConstants.ROULETTE_DAMAGE_BOOST
		"heal":
			GameManager.heal(GameConstants.ROULETTE_HEAL_AMOUNT)
		"slow":
			GameManager.speed_mult = maxf(GameConstants.ROULETTE_SLOW_MIN, GameManager.speed_mult - GameConstants.ROULETTE_SLOW_AMOUNT)

# ---- Eclipse Total (min 8) ----
# Darken the stage, enemies get a glow effect, bonus XP for 15 seconds
func _start_eclipse() -> void:
	# Reduce DirectionalLight energy
	var dir_light = _find_directional_light()
	if dir_light:
		_eclipse_original_energy = dir_light.light_energy
		dir_light.light_energy = GameConstants.ECLIPSE_LIGHT_ENERGY

	# Darken the stage by modulating the current scene (only if it supports modulate)
	var root = get_tree().current_scene
	if root and "modulate" in root:
		_eclipse_original_modulate = root.modulate
		var tween = create_tween()
		tween.tween_property(root, "modulate", GameConstants.ECLIPSE_DARKEN_COLOR, 1.0)
	else:
		_eclipse_original_modulate = Color.WHITE

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

	# Make enemies glow via their Sprite3D child (Node3D itself has no modulate)
	_eclipse_glowing_enemies.clear()
	var enemies = GameManager.get_enemies()
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		var sprite = enemy.get_node_or_null("EnemySprite")
		if sprite and "modulate" in sprite:
			sprite.modulate = GameConstants.ECLIPSE_ENEMY_GLOW
			_eclipse_glowing_enemies.append(enemy)

	# Bonus XP during eclipse (1.5x multiplier)
	_eclipse_xp_bonus_active = true
	_eclipse_prev_xp_mult = GameManager.xp_mult
	GameManager.xp_mult = _eclipse_prev_xp_mult * GameConstants.ECLIPSE_XP_MULT

func _end_eclipse() -> void:
	# Restore DirectionalLight
	var dir_light = _find_directional_light()
	if dir_light and _eclipse_original_energy >= 0:
		dir_light.light_energy = _eclipse_original_energy
		_eclipse_original_energy = -1.0

	# Restore stage modulate (only if supported)
	var root = get_tree().current_scene
	if root and "modulate" in root:
		var tween = create_tween()
		tween.tween_property(root, "modulate", _eclipse_original_modulate, 1.0)

	# Remove dark overlay
	var canvas = get_node_or_null("EclipseCanvas")
	if canvas:
		canvas.queue_free()

	# Remove enemy glow via Sprite3D child
	for enemy in _eclipse_glowing_enemies:
		if not is_instance_valid(enemy):
			continue
		var sprite = enemy.get_node_or_null("EnemySprite")
		if sprite and "modulate" in sprite:
			sprite.modulate = Color.WHITE
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
	_meteor_spawns_remaining = GameConstants.METEOR_COUNT
	_meteor_spawn_interval = GameConstants.METEOR_SPAWN_DURATION / float(GameConstants.METEOR_COUNT)
	_meteor_spawn_timer = 0.0  # Spawn first immediately

func _spawn_single_meteor() -> void:
	var players = GameManager.get_players()
	if players.is_empty():
		return
	var center = players[0].global_position

	# Random position near player
	var offset = Vector3(rng.randf_range(-GameConstants.METEOR_OFFSET_RANGE, GameConstants.METEOR_OFFSET_RANGE), 0, rng.randf_range(-GameConstants.METEOR_OFFSET_RANGE, GameConstants.METEOR_OFFSET_RANGE))
	var target_pos = center + offset
	target_pos.y = 0.0

	# Create meteor Area3D
	var meteor = Area3D.new()
	meteor.name = "Meteor"

	# Collision shape (sphere radius 2.0 for damage area)
	var col_shape = CollisionShape3D.new()
	var sphere_shape = SphereShape3D.new()
	sphere_shape.radius = GameConstants.METEOR_RADIUS
	col_shape.shape = sphere_shape
	meteor.add_child(col_shape)

	# Visual: sprite de meteoro
	var meteor_sprite_path = "res://assets/sprites/effects/meteor.png"
	if ResourceLoader.exists(meteor_sprite_path):
		var sprite = Sprite3D.new()
		sprite.texture = load(meteor_sprite_path)
		sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		sprite.pixel_size = 0.06
		sprite.shaded = false
		sprite.transparent = true
		meteor.add_child(sprite)
	else:
		# Fallback: mesh laranja
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
	meteor.global_position = target_pos + Vector3(0, GameConstants.METEOR_FALL_HEIGHT, 0)

	# Animate falling with a tween
	var tween = create_tween()
	tween.tween_property(meteor, "global_position", target_pos, 1.0).set_ease(Tween.EASE_IN)
	tween.tween_callback(_meteor_impact.bind(meteor, target_pos))

func _meteor_impact(meteor: Node3D, impact_pos: Vector3) -> void:
	if not is_instance_valid(meteor):
		return

	var damage := GameConstants.METEOR_DAMAGE
	var radius := GameConstants.METEOR_RADIUS

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

	# Explosion particles
	ParticleFactory.spawn_explosion_particles(impact_pos, radius)

	# Remove meteor
	meteor.queue_free()

	# Spawn crater with fire at impact site
	_spawn_meteor_crater(impact_pos)

func _spawn_meteor_crater(pos: Vector3) -> void:
	var crater_root = Node3D.new()
	crater_root.name = "MeteorCrater"
	get_parent().add_child(crater_root)
	crater_root.global_position = pos

	# --- Crater ring (torus-like rim using dark scorched ring) ---
	var rim = MeshInstance3D.new()
	var torus_mesh = TorusMesh.new()
	torus_mesh.inner_radius = 0.8
	torus_mesh.outer_radius = 1.6
	torus_mesh.rings = 16
	torus_mesh.ring_segments = 12
	rim.mesh = torus_mesh
	var rim_mat = StandardMaterial3D.new()
	rim_mat.albedo_color = Color(0.15, 0.08, 0.02)
	rim_mat.roughness = 1.0
	rim_mat.metallic = 0.0
	rim.material_override = rim_mat
	rim.position = Vector3(0, 0.02, 0)
	rim.rotation_degrees.x = 90.0
	crater_root.add_child(rim)

	# --- Scorched ground (dark disc inside crater) ---
	var scorch = MeshInstance3D.new()
	var disc_mesh = CylinderMesh.new()
	disc_mesh.top_radius = 1.0
	disc_mesh.bottom_radius = 1.0
	disc_mesh.height = 0.05
	disc_mesh.radial_segments = 16
	scorch.mesh = disc_mesh
	var scorch_mat = StandardMaterial3D.new()
	scorch_mat.albedo_color = Color(0.08, 0.04, 0.01)
	scorch_mat.roughness = 1.0
	scorch_mat.emission_enabled = true
	scorch_mat.emission = Color(0.3, 0.08, 0.0)
	scorch_mat.emission_energy_multiplier = 0.5
	scorch.material_override = scorch_mat
	scorch.position = Vector3(0, -0.05, 0)
	crater_root.add_child(scorch)

	# --- Fire particles inside crater ---
	var fire = GPUParticles3D.new()
	fire.name = "CraterFire"
	fire.emitting = true
	fire.amount = 12
	fire.lifetime = 0.8
	fire.explosiveness = 0.1
	fire.randomness = 0.5
	fire.visibility_aabb = AABB(Vector3(-2, -1, -2), Vector3(4, 4, 4))

	var fire_mat = ParticleProcessMaterial.new()
	fire_mat.direction = Vector3(0, 1, 0)
	fire_mat.spread = 15.0
	fire_mat.initial_velocity_min = 1.0
	fire_mat.initial_velocity_max = 2.5
	fire_mat.gravity = Vector3(0, 0.5, 0)
	fire_mat.scale_min = 0.08
	fire_mat.scale_max = 0.2
	fire_mat.damping_min = 1.0
	fire_mat.damping_max = 2.0

	# Fire color gradient: bright yellow core → orange → red tips → fade out
	var color_ramp = GradientTexture1D.new()
	var gradient = Gradient.new()
	gradient.set_offset(0, 0.0)
	gradient.set_color(0, Color(1.0, 0.95, 0.4, 1.0))  # bright yellow core
	gradient.add_point(0.3, Color(1.0, 0.5, 0.05, 0.9))  # orange
	gradient.add_point(0.7, Color(0.8, 0.15, 0.0, 0.6))  # dark red
	gradient.set_offset(1, 1.0)
	gradient.set_color(1, Color(0.3, 0.05, 0.0, 0.0))  # fade out
	color_ramp.gradient = gradient
	fire_mat.color_ramp = color_ramp

	fire.process_material = fire_mat

	# Fire draw pass (small sphere billboard)
	var fire_mesh = SphereMesh.new()
	fire_mesh.radius = 0.15
	fire_mesh.height = 0.3
	var fire_draw_mat = StandardMaterial3D.new()
	fire_draw_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	fire_draw_mat.albedo_color = Color(1.0, 0.7, 0.2, 0.9)
	fire_draw_mat.emission_enabled = true
	fire_draw_mat.emission = Color(1.0, 0.4, 0.05)
	fire_draw_mat.emission_energy_multiplier = 4.0
	fire_draw_mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	fire_draw_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	fire_mesh.surface_set_material(0, fire_draw_mat)
	fire.draw_pass_1 = fire_mesh

	fire.position = Vector3(0, 0.1, 0)
	crater_root.add_child(fire)

	# --- Ember sparks (small rising sparks) ---
	var embers = GPUParticles3D.new()
	embers.name = "CraterEmbers"
	embers.emitting = true
	embers.amount = 6
	embers.lifetime = 1.2
	embers.explosiveness = 0.0
	embers.randomness = 0.8
	embers.visibility_aabb = AABB(Vector3(-2, -1, -2), Vector3(4, 5, 4))

	var ember_mat = ParticleProcessMaterial.new()
	ember_mat.direction = Vector3(0, 1, 0)
	ember_mat.spread = 30.0
	ember_mat.initial_velocity_min = 0.5
	ember_mat.initial_velocity_max = 1.5
	ember_mat.gravity = Vector3(0, -0.3, 0)
	ember_mat.scale_min = 0.02
	ember_mat.scale_max = 0.05
	ember_mat.color = Color(1.0, 0.6, 0.1, 0.8)
	embers.process_material = ember_mat

	var ember_mesh = SphereMesh.new()
	ember_mesh.radius = 0.04
	ember_mesh.height = 0.08
	var ember_draw_mat = StandardMaterial3D.new()
	ember_draw_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ember_draw_mat.albedo_color = Color(1.0, 0.8, 0.3, 1.0)
	ember_draw_mat.emission_enabled = true
	ember_draw_mat.emission = Color(1.0, 0.6, 0.1)
	ember_draw_mat.emission_energy_multiplier = 5.0
	ember_draw_mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	ember_draw_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ember_mesh.surface_set_material(0, ember_draw_mat)
	embers.draw_pass_1 = ember_mesh

	embers.position = Vector3(0, 0.15, 0)
	crater_root.add_child(embers)

	# --- Point light for fire glow ---
	var light = OmniLight3D.new()
	light.light_color = Color(1.0, 0.5, 0.1)
	light.light_energy = 2.0
	light.omni_range = 3.0
	light.omni_attenuation = 1.5
	light.position = Vector3(0, 0.5, 0)
	crater_root.add_child(light)

	# --- Accessibility: reduced motion = less particles ---
	if AccessibilityManager.reduced_motion:
		fire.amount = 4
		embers.amount = 2

	# --- Fade out and remove after 8 seconds ---
	var fade_tween = create_tween()
	# Hold visible for 5 seconds
	fade_tween.tween_interval(5.0)
	# Then fade fire and light over 3 seconds
	fade_tween.tween_callback(func():
		fire.emitting = false
		embers.emitting = false
	)
	fade_tween.tween_property(light, "light_energy", 0.0, 3.0).set_ease(Tween.EASE_IN)
	fade_tween.parallel().tween_property(rim_mat, "albedo_color:a", 0.0, 3.0)
	fade_tween.parallel().tween_property(scorch_mat, "albedo_color:a", 0.0, 3.0)
	fade_tween.parallel().tween_property(scorch_mat, "emission_energy_multiplier", 0.0, 3.0)
	fade_tween.tween_callback(crater_root.queue_free)

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
	GameManager.perm_damage_mult *= GameConstants.FEVER_DAMAGE_MULT
	GameManager.speed_mult *= GameConstants.FEVER_SPEED_MULT
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
	var timer = get_tree().create_timer(GameConstants.FEVER_DURATION)
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
	var dungeon_pos = GameConstants.PORTAL_DUNGEON_POS
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
	_portal_enemies_remaining = GameConstants.EVENT_PORTAL_ENEMY_COUNT
	var enemy_scenes = [
		preload("res://scenes/enemies/skeleton.tscn"),
		preload("res://scenes/enemies/zombie_runner.tscn"),
		preload("res://scenes/enemies/bomber.tscn"),
		preload("res://scenes/enemies/ghost.tscn"),
	]

	for i in range(GameConstants.EVENT_PORTAL_ENEMY_COUNT):
		var spawn_pos = GameManager.get_annulus_position(dungeon_pos, GameConstants.PORTAL_SPAWN_MIN, GameConstants.PORTAL_SPAWN_MAX)
		var enemy = enemy_scenes[rng.randi() % enemy_scenes.size()].instantiate()
		# Faz todos elite
		if enemy is EnemyBase3D:
			enemy.max_hp = int(enemy.max_hp * GameConstants.ELITE_HP_MULT)
			enemy.hp = enemy.max_hp
			enemy.damage = int(enemy.damage * GameConstants.ELITE_DAMAGE_MULT)
			enemy.xp_drop = enemy.xp_drop * GameConstants.ELITE_XP_MULT
			enemy.enemy_color = Color(0.6, 0.2, 0.9)  # Roxo portal
			enemy.scale = GameConstants.ELITE_SCALE
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
	GameManager.add_xp(GameConstants.PORTAL_REWARD_XP)

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
		mimic.max_hp = GameConstants.MIMIC_HP
		mimic.hp = GameConstants.MIMIC_HP
		mimic.damage = GameConstants.MIMIC_DAMAGE
		mimic.xp_drop = GameConstants.MIMIC_XP
		mimic.scale = GameConstants.MIMIC_SCALE
	get_parent().add_child(mimic)
	mimic.global_position = GameManager.get_annulus_position(center)
	GameManager.enemies_alive += 1
