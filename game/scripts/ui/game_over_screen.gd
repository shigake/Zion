extends CanvasLayer

## Tela de Game Over com stats detalhados da run.

@onready var panel: PanelContainer = $Panel
@onready var time_label: Label = $Panel/ScrollContainer/VBox/TimeLabel
@onready var kills_label: Label = $Panel/ScrollContainer/VBox/KillsLabel
@onready var level_label: Label = $Panel/ScrollContainer/VBox/LevelLabel
@onready var crystals_label: Label = $Panel/ScrollContainer/VBox/CrystalsLabel
@onready var dps_label: Label = $Panel/ScrollContainer/VBox/DPSLabel
@onready var peak_enemies_label: Label = $Panel/ScrollContainer/VBox/PeakEnemiesLabel
@onready var weapons_title: Label = $Panel/ScrollContainer/VBox/WeaponsTitle
@onready var weapons_container: VBoxContainer = $Panel/ScrollContainer/VBox/WeaponsContainer
@onready var items_title: Label = $Panel/ScrollContainer/VBox/ItemsTitle
@onready var items_container: VBoxContainer = $Panel/ScrollContainer/VBox/ItemsContainer
@onready var evolutions_title: Label = $Panel/ScrollContainer/VBox/EvolutionsTitle
@onready var evolutions_container: VBoxContainer = $Panel/ScrollContainer/VBox/EvolutionsContainer
@onready var events_label: Label = $Panel/ScrollContainer/VBox/EventsLabel
@onready var retry_btn: Button = $Panel/ScrollContainer/VBox/RetryButton
@onready var menu_btn: Button = $Panel/ScrollContainer/VBox/MenuButton
@onready var char_icon: TextureRect = $Panel/ScrollContainer/VBox/CharacterRow/CharIcon
@onready var char_name_label: Label = $Panel/ScrollContainer/VBox/CharacterRow/CharNameLabel

@onready var overlay: ColorRect = $Overlay

func _ready() -> void:
	overlay.visible = false
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.visible = false
	GameManager.game_over.connect(_show)
	retry_btn.pressed.connect(_on_retry)
	menu_btn.pressed.connect(_on_menu)

func _show() -> void:
	GameManager.end_run()
	AchievementManager.check_achievements()
	# Submit daily challenge score
	if GameManager.game_mode == "daily":
		DailyChallenge.submit_daily_score(
			GameManager.game_time,
			GameManager.total_kills,
			GameManager.selected_character
		)
		_submit_daily_score_online()
	# Auto crash report if player died very fast (possible bug)
	if not GameManager.is_victory and GameManager.game_time < 30.0:
		LogManager.report_crash("GameOver", "Player died very fast (%.1fs)" % GameManager.game_time)
	await get_tree().create_timer(1.0).timeout
	var t = int(GameManager.game_time)
	var time_str = "%02d:%02d" % [t / 60, t % 60]
	if GameManager.is_victory:
		time_label.text = LocaleManager.tr_key("victory_time") % time_str
	else:
		time_label.text = LocaleManager.tr_key("time") % time_str
	kills_label.text = LocaleManager.tr_key("kills_stat") % GameManager.total_kills
	level_label.text = LocaleManager.tr_key("level_stat") % GameManager.player_level
	var crystal_mult = MutationManager.get_crystal_multiplier()
	crystals_label.text = LocaleManager.tr_key("crystals_earned") % GameManager.crystals_this_run
	if crystal_mult > 1.0:
		crystals_label.text += " (x%.1f mutacoes)" % crystal_mult

	# DPS
	var dps: float = 0.0
	if GameManager.game_time > 0:
		dps = GameManager.total_damage_dealt / GameManager.game_time
	dps_label.text = "DPS: %d" % int(dps)

	# Peak enemies
	peak_enemies_label.text = "Peak Enemies: %d" % GameManager.peak_enemies

	# Character sprite at top of summary
	var char_path = "res://assets/sprites/characters/%s.png" % GameManager.selected_character
	if ResourceLoader.exists(char_path):
		char_icon.texture = load(char_path)
	else:
		char_icon.texture = null
	var char_data = CharacterDB.get_character(GameManager.selected_character)
	char_name_label.text = char_data.get("name", GameManager.selected_character)

	# Clear previous dynamic rows
	_clear_container(weapons_container)
	_clear_container(items_container)
	_clear_container(evolutions_container)

	# Weapons obtained with levels + icons
	if GameManager.player_weapons.is_empty():
		weapons_title.text = "Armas: -"
	else:
		weapons_title.text = "Armas:"
		for w in GameManager.player_weapons:
			var data = WeaponDB.weapons.get(w["id"], {})
			var wname = data.get("name", w["id"])
			var row = _create_icon_row(
				"res://assets/sprites/weapons/%s.png" % w["id"],
				"%s Lv.%d" % [wname, w["level"]]
			)
			weapons_container.add_child(row)

	# Items obtained with levels + icons
	if GameManager.player_items.is_empty():
		items_title.text = "Itens: -"
	else:
		items_title.text = "Itens:"
		for it in GameManager.player_items:
			var data = ItemDB.get_item(it["id"])
			var iname = data.get("name", it["id"])
			var row = _create_icon_row(
				"res://assets/sprites/items/%s.png" % it["id"],
				"%s Lv.%d" % [iname, it["level"]]
			)
			items_container.add_child(row)

	# Evolutions triggered + icons
	if EvolutionDB.evolved_weapons.is_empty():
		evolutions_title.text = ""
		evolutions_title.visible = false
		evolutions_container.visible = false
	else:
		evolutions_title.text = "Evolucoes:"
		evolutions_title.visible = true
		evolutions_container.visible = true
		for evo_id in EvolutionDB.evolved_weapons:
			var evo = EvolutionDB.get_evolution(evo_id)
			var evo_name = evo.get("name", evo_id)
			var row = _create_icon_row(
				"res://assets/sprites/weapons/%s.png" % evo_id,
				evo_name
			)
			evolutions_container.add_child(row)

	# Events that happened
	if GameManager.events_triggered.is_empty():
		events_label.text = ""
		events_label.visible = false
	else:
		# Deduplicate and capitalize event names
		var unique_events: Array[String] = []
		for ev in GameManager.events_triggered:
			var display = ev.replace("_", " ").capitalize()
			if display not in unique_events:
				unique_events.append(display)
		events_label.text = "Eventos: " + ", ".join(unique_events)
		events_label.visible = true

	# Leaderboard rank para endless mode
	if GameManager.game_mode == "endless":
		var leaderboard = SaveManager.get_leaderboard()
		for i in range(leaderboard.size()):
			if absf(leaderboard[i].get("time", 0) - GameManager.game_time) < 1.0:
				crystals_label.text += "\n" + LocaleManager.tr_key("leaderboard_rank") % (i + 1)
				break
	# Stage completion check (only on victory)
	if GameManager.game_mode == "normal" and GameManager.is_victory:
		var stage_key = "stage_" + GameManager.selected_stage
		var stage_name = LocaleManager.tr_key(stage_key)
		crystals_label.text += "\n" + LocaleManager.tr_key("stage_complete") % stage_name
	# Show total damage dealt
	crystals_label.text += "\n" + LocaleManager.tr_key("total_damage") % GameManager.total_damage_dealt
	# Unlocks
	var unlocked = SaveManager.check_unlocks()
	if not unlocked.is_empty():
		for char_id in unlocked:
			var unlocked_data = CharacterDB.get_character(char_id)
			crystals_label.text += "\n" + LocaleManager.tr_key("unlocked") % unlocked_data["name"]
	overlay.visible = true
	panel.visible = true
	GameManager.paused = true
	# Gamepad: foca no Retry
	retry_btn.focus_mode = Control.FOCUS_ALL
	menu_btn.focus_mode = Control.FOCUS_ALL
	retry_btn.focus_neighbor_bottom = menu_btn.get_path()
	retry_btn.focus_neighbor_top = menu_btn.get_path()
	menu_btn.focus_neighbor_top = retry_btn.get_path()
	menu_btn.focus_neighbor_bottom = retry_btn.get_path()
	GamepadUI.notify_menu_opened()

func _on_retry() -> void:
	AudioManager.play_sfx("menu_click")
	get_tree().paused = false
	var stage_scenes = {
		"cemetery": "res://scenes/stages/stage_cemetery.tscn",
		"forest": "res://scenes/stages/stage_forest.tscn",
		"farm": "res://scenes/stages/stage_farm.tscn",
		"tokyo": "res://scenes/stages/stage_tokyo.tscn",
		"volcano": "res://scenes/stages/stage_volcano.tscn",
		"ocean": "res://scenes/stages/stage_ocean.tscn",
		"arena": "res://scenes/stages/stage_arena.tscn",
		"space": "res://scenes/stages/stage_space.tscn",
		"castle": "res://scenes/stages/stage_castle.tscn",
		"candy": "res://scenes/stages/stage_candy.tscn",
	}
	var scene = stage_scenes.get(GameManager.selected_stage, "res://scenes/stages/stage_cemetery.tscn")
	get_tree().change_scene_to_file(scene)

func _unhandled_input(event: InputEvent) -> void:
	if not panel.visible:
		return
	if event.is_action_pressed("ui_cancel"):
		if get_viewport(): get_viewport().set_input_as_handled()
		_on_menu()

func _on_menu() -> void:
	AudioManager.play_sfx("menu_click")
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")


# ---------------------------------------------------------------------------
# Icon row helpers
# ---------------------------------------------------------------------------

## Create an HBoxContainer with [icon + label] for a weapon/item entry.
func _create_icon_row(icon_path: String, display_text: String) -> HBoxContainer:
	var row = HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 6)

	var tex_rect = TextureRect.new()
	tex_rect.custom_minimum_size = Vector2(24, 24)
	tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tex_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if ResourceLoader.exists(icon_path):
		tex_rect.texture = load(icon_path)
	else:
		tex_rect.texture = null
	row.add_child(tex_rect)

	var lbl = Label.new()
	lbl.text = display_text
	lbl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(lbl)

	return row

## Remove all children from a container (used to reset between shows).
func _clear_container(container: Container) -> void:
	for child in container.get_children():
		child.queue_free()

# ---------------------------------------------------------------------------
# Daily Challenge online score submission
# ---------------------------------------------------------------------------

func _submit_daily_score_online() -> void:
	var url := Telemetry.server_url + "/daily-score"
	var body := {
		"date": DailyChallenge.get_today_string(),
		"character": GameManager.selected_character,
		"stage": GameManager.selected_stage,
		"survived_seconds": GameManager.game_time,
		"total_kills": GameManager.total_kills,
		"victory": GameManager.is_victory,
		"mutations": MutationManager.get_active_ids(),
		"version": "",
	}
	# Read version
	var file := FileAccess.open("res://VERSION", FileAccess.READ)
	if file:
		body["version"] = file.get_as_text().strip_edges()

	var http := HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(func(_result, _code, _headers, _body):
		http.queue_free()
	)
	var json_body := JSON.stringify(body)
	var headers := ["Content-Type: application/json"]
	http.request(url, headers, HTTPClient.METHOD_POST, json_body)
