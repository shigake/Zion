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
@onready var dps_ranking_title: Label = $Panel/ScrollContainer/VBox/DPSRankingTitle
@onready var dps_ranking_container: VBoxContainer = $Panel/ScrollContainer/VBox/DPSRankingContainer
@onready var best_run_title: Label = $Panel/ScrollContainer/VBox/BestRunTitle
@onready var best_run_container: VBoxContainer = $Panel/ScrollContainer/VBox/BestRunContainer
@onready var timeline_title: Label = $Panel/ScrollContainer/VBox/TimelineTitle
@onready var timeline_scroll: ScrollContainer = $Panel/ScrollContainer/VBox/TimelineScroll
@onready var timeline_container: HBoxContainer = $Panel/ScrollContainer/VBox/TimelineScroll/TimelineContainer
@onready var screenshot_btn: Button = $Panel/ScrollContainer/VBox/ScreenshotButton
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
	screenshot_btn.pressed.connect(_take_screenshot)

func _show() -> void:
	GameManager.end_run()
	AchievementManager.check_achievements()
	var _unlocked_chars := SaveManager.check_unlocks()
	# Submit daily challenge score
	if GameManager.game_mode == "daily":
		DailyChallenge.submit_daily_score(
			GameManager.game_time,
			GameManager.total_kills,
			GameManager.selected_character
		)
		_submit_daily_score_online()
	# Auto-submit score to online leaderboard (all modes)
	_submit_leaderboard_online()
	# Auto crash report if player died very fast (possible bug)
	if not GameManager.is_victory and GameManager.game_time < 30.0:
		LogManager.report_crash("GameOver", "Player died very fast (%.1fs)" % GameManager.game_time)
	await get_tree().create_timer(1.0).timeout
	var t = int(GameManager.game_time)
	var time_str = "%02d:%02d" % [t / 60, t % 60]
	if GameManager.is_victory:
		# Check if ALL stages are now complete (final victory)
		var all_complete := true
		var all_stages := GameConstants.ALL_STAGES
		for s in all_stages:
			if s not in SaveManager.data.get("completed_stages", []):
				all_complete = false
				break
		if all_complete and GameManager.game_mode == "normal":
			# Final victory — all fragments restored
			time_label.text = LocaleManager.tr_key("victory_all_stages") + "\n\n" + LocaleManager.tr_key("victory_time") % time_str
		else:
			# Per-stage victory lore
			var victory_key = "victory_lore_" + GameManager.selected_stage
			var victory_text = LocaleManager.tr_key(victory_key)
			if victory_text == victory_key:
				victory_text = LocaleManager.tr_key("lore_victory")
			time_label.text = victory_text + "\n" + LocaleManager.tr_key("victory_time") % time_str
	else:
		# Narrative flavor: death message with lore
		time_label.text = LocaleManager.tr_key("lore_death") + "\n" + LocaleManager.tr_key("time") % time_str
	kills_label.text = LocaleManager.tr_key("kills_stat") % GameManager.total_kills
	level_label.text = LocaleManager.tr_key("level_stat") % GameManager.player_level
	var crystal_mult = MutationManager.get_crystal_multiplier()
	crystals_label.text = LocaleManager.tr_key("crystals_earned") % GameManager.crystals_this_run
	if crystal_mult > 1.0:
		crystals_label.text += " (x%.1f mutacoes)" % crystal_mult

	# DPS e Peak enemies ocultos — info desnecessaria
	dps_label.visible = false
	peak_enemies_label.visible = false

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
	_clear_container(dps_ranking_container)
	_clear_container(best_run_container)
	_clear_container(timeline_container)

	# Weapons — grid compacto de icones
	if GameManager.player_weapons.is_empty():
		weapons_title.text = "Armas: -"
	else:
		weapons_title.text = "Armas:"
		var grid = GridContainer.new()
		grid.columns = 6
		grid.add_theme_constant_override("h_separation", 8)
		grid.add_theme_constant_override("v_separation", 4)
		for w in GameManager.player_weapons:
			var w_data = WeaponDB.weapons.get(w["id"], {})
			var wname = w_data.get("name", w["id"])
			var icon_path = "res://assets/sprites/weapons/%s.png" % w["id"]
			var tex = TextureRect.new()
			tex.custom_minimum_size = Vector2(32, 32)
			tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			tex.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			if ResourceLoader.exists(icon_path):
				tex.texture = load(icon_path)
			tex.tooltip_text = "%s Lv.%d" % [wname, w["level"]]
			grid.add_child(tex)
		weapons_container.add_child(grid)

	# Items — grid compacto de icones
	if GameManager.player_items.is_empty():
		items_title.text = "Itens: -"
	else:
		items_title.text = "Itens:"
		var items_grid = GridContainer.new()
		items_grid.columns = 6
		items_grid.add_theme_constant_override("h_separation", 8)
		items_grid.add_theme_constant_override("v_separation", 4)
		for it in GameManager.player_items:
			var data = ItemDB.get_item(it["id"])
			var iname = data.get("name", it["id"])
			var icon_path = "res://assets/sprites/items/%s.png" % it["id"]
			var tex = TextureRect.new()
			tex.custom_minimum_size = Vector2(32, 32)
			tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			tex.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			if ResourceLoader.exists(icon_path):
				tex.texture = load(icon_path)
			tex.tooltip_text = "%s Lv.%d" % [iname, it["level"]]
			items_grid.add_child(tex)
		items_container.add_child(items_grid)

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

	# Events ocultos — info desnecessaria
	events_label.visible = false

	# Secoes detalhadas ocultas para manter a tela limpa
	dps_ranking_title.visible = false
	dps_ranking_container.visible = false
	best_run_title.visible = false
	best_run_container.visible = false
	timeline_title.visible = false
	timeline_scroll.visible = false

	# Leaderboard rank para endless mode
	if GameManager.game_mode == "endless":
		var leaderboard = SaveManager.get_leaderboard()
		for i in range(leaderboard.size()):
			if absf(leaderboard[i].get("time", 0) - GameManager.game_time) < 1.0:
				crystals_label.text += "\n" + LocaleManager.tr_key("leaderboard_rank") % (i + 1)
				break
	# Stage completion check (only on victory)
	if GameManager.is_victory:
		var stage_key = "stage_" + GameManager.selected_stage
		var stage_name = LocaleManager.tr_key(stage_key)
		crystals_label.text += "\n" + LocaleManager.tr_key("stage_complete") % stage_name
	# Show total damage dealt
	crystals_label.text += "\n" + LocaleManager.tr_key("total_damage") % GameManager.total_damage_dealt
	# Unlocks (computed earlier, before UI setup)
	if not _unlocked_chars.is_empty():
		for char_id in _unlocked_chars:
			var unlocked_data = CharacterDB.get_character(char_id)
			crystals_label.text += "\n" + LocaleManager.tr_key("unlocked") % unlocked_data["name"]
			# Special narrative for mystery character unlock
			if char_id == "mystery":
				crystals_label.text += "\n\n" + LocaleManager.tr_key("lore_mystery_unlock")
	if GameManager.is_victory:
		AudioManager.play_music("victory")
	else:
		AudioManager.play_music("game_over_music")
	overlay.visible = true
	panel.visible = true
	GameManager.paused = true
	# Gamepad: foca no Retry (screenshot -> retry -> menu cycle)
	screenshot_btn.focus_mode = Control.FOCUS_ALL
	retry_btn.focus_mode = Control.FOCUS_ALL
	menu_btn.focus_mode = Control.FOCUS_ALL
	screenshot_btn.focus_neighbor_bottom = retry_btn.get_path()
	screenshot_btn.focus_neighbor_top = menu_btn.get_path()
	retry_btn.focus_neighbor_bottom = menu_btn.get_path()
	retry_btn.focus_neighbor_top = screenshot_btn.get_path()
	menu_btn.focus_neighbor_top = retry_btn.get_path()
	menu_btn.focus_neighbor_bottom = screenshot_btn.get_path()
	GamepadUI.notify_menu_opened()

func _on_retry() -> void:
	AudioManager.play_sfx("menu_click")
	get_tree().paused = false
	var scene = GameConstants.STAGE_SCENE_PATHS.get(GameManager.selected_stage, "res://scenes/stages/stage_cemetery.tscn")
	LoadingScreen.load_stage(scene)

func _unhandled_input(event: InputEvent) -> void:
	if not panel.visible:
		return
	if event.is_action_pressed("ui_cancel"):
		if get_viewport(): get_viewport().set_input_as_handled()
		_on_menu()

func _on_menu() -> void:
	AudioManager.play_sfx("menu_click")
	get_tree().paused = false
	if MultiplayerManager.is_online:
		MultiplayerManager.disconnect_from_game()
	LoadingScreen.transition_to("res://scenes/ui/main_menu.tscn")


# ---------------------------------------------------------------------------
# Weapon DPS ranking
# ---------------------------------------------------------------------------

func _populate_dps_ranking() -> void:
	if GameManager.player_weapons.is_empty():
		dps_ranking_title.visible = false
		dps_ranking_container.visible = false
		return
	dps_ranking_title.text = "Ranking de dano:"
	dps_ranking_title.visible = true
	dps_ranking_container.visible = true

	var sorted_weapons: Array = []
	for w in GameManager.player_weapons:
		var dmg = GameManager.weapon_damage_dealt.get(w["id"], 0)
		sorted_weapons.append({"id": w["id"], "level": w["level"], "damage": dmg})
	sorted_weapons.sort_custom(func(a, b): return a["damage"] > b["damage"])

	var max_damage: int = 1
	if not sorted_weapons.is_empty():
		max_damage = maxi(sorted_weapons[0]["damage"], 1)

	for i in range(sorted_weapons.size()):
		var w = sorted_weapons[i]
		var w_data = WeaponDB.weapons.get(w["id"], {})
		var wname = w_data.get("name", w["id"])

		var row = VBoxContainer.new()
		row.add_theme_constant_override("separation", 2)

		# Weapon name + damage label
		var name_row = HBoxContainer.new()
		name_row.alignment = BoxContainer.ALIGNMENT_CENTER
		var rank_label = Label.new()
		rank_label.text = "#%d %s - %d dmg" % [i + 1, wname, w["damage"]]
		rank_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		rank_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_row.add_child(rank_label)
		row.add_child(name_row)

		# Damage bar
		var bar_bg = ColorRect.new()
		bar_bg.custom_minimum_size = Vector2(200, 8)
		bar_bg.color = Color(0.2, 0.2, 0.2, 0.6)
		row.add_child(bar_bg)

		var bar_fill = ColorRect.new()
		var fill_ratio = float(w["damage"]) / float(max_damage)
		bar_fill.custom_minimum_size = Vector2(200 * fill_ratio, 8)
		# Color gradient: #1 = gold, #2 = silver, #3 = bronze, rest = white
		match i:
			0: bar_fill.color = Color(1.0, 0.84, 0.0)
			1: bar_fill.color = Color(0.75, 0.75, 0.75)
			2: bar_fill.color = Color(0.8, 0.5, 0.2)
			_: bar_fill.color = Color(0.5, 0.7, 1.0)
		bar_bg.add_child(bar_fill)

		dps_ranking_container.add_child(row)


# ---------------------------------------------------------------------------
# Best run comparison
# ---------------------------------------------------------------------------

func _populate_best_run_comparison() -> void:
	var best = SaveManager.get_best_run()
	if best.is_empty():
		best_run_title.visible = false
		best_run_container.visible = false
		return
	best_run_title.text = "Comparacao com melhor run:"
	best_run_title.visible = true
	best_run_container.visible = true

	var current_dps: float = 0.0
	if GameManager.game_time > 0:
		current_dps = GameManager.total_damage_dealt / GameManager.game_time

	var comparisons = [
		{"label": "Tempo", "current": GameManager.game_time, "best": best.get("time", 0.0), "format": "time"},
		{"label": "Kills", "current": float(GameManager.total_kills), "best": float(best.get("kills", 0)), "format": "int"},
		{"label": "DPS", "current": current_dps, "best": best.get("dps", 0.0), "format": "float"},
		{"label": "Level", "current": float(GameManager.player_level), "best": float(best.get("level", 0)), "format": "int"},
		{"label": "Cristais", "current": float(GameManager.crystals_this_run), "best": float(best.get("crystals", 0)), "format": "int"},
	]

	for c in comparisons:
		var diff = c["current"] - c["best"]
		var arrow: String
		var diff_text: String
		var color: Color
		if diff > 0.01:
			arrow = "▲"
			color = Color(0.3, 1.0, 0.3)  # green
		elif diff < -0.01:
			arrow = "▼"
			color = Color(1.0, 0.3, 0.3)  # red
		else:
			arrow = "="
			color = Color(0.8, 0.8, 0.8)  # gray

		match c["format"]:
			"time":
				var dt = int(abs(diff))
				diff_text = "%02d:%02d" % [dt / 60, dt % 60]
				if diff > 0.01:
					diff_text += " mais"
				elif diff < -0.01:
					diff_text += " menos"
			"int":
				diff_text = "%d" % int(abs(diff))
				if diff > 0.01:
					diff_text += " mais"
				elif diff < -0.01:
					diff_text += " menos"
			"float":
				diff_text = "%.1f" % abs(diff)
				if diff > 0.01:
					diff_text += " mais"
				elif diff < -0.01:
					diff_text += " menos"

		var row = HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("separation", 8)

		var label = Label.new()
		label.text = "%s: %s %s" % [c["label"], arrow, diff_text]
		label.modulate = color
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		row.add_child(label)

		best_run_container.add_child(row)


# ---------------------------------------------------------------------------
# Run timeline
# ---------------------------------------------------------------------------

func _populate_timeline() -> void:
	if GameManager.run_timeline.is_empty():
		timeline_title.visible = false
		timeline_scroll.visible = false
		return
	timeline_title.text = "Timeline da run:"
	timeline_title.visible = true
	timeline_scroll.visible = true

	var total_time = maxf(GameManager.game_time, 1.0)
	var timeline_width: float = 460.0  # Total width of the timeline bar

	# Background line
	var bg_line = ColorRect.new()
	bg_line.custom_minimum_size = Vector2(timeline_width, 4)
	bg_line.color = Color(0.3, 0.3, 0.3, 0.8)
	bg_line.position = Vector2(0, 20)
	timeline_container.add_child(bg_line)

	# Event markers
	for entry in GameManager.run_timeline:
		var event_time: float = entry["time"]
		var event_text: String = entry["event"]
		var x_pos = (event_time / total_time) * timeline_width

		var marker = VBoxContainer.new()
		marker.position = Vector2(x_pos - 2, 0)
		marker.custom_minimum_size = Vector2(4, 0)

		# Dot
		var dot = ColorRect.new()
		dot.custom_minimum_size = Vector2(6, 6)
		dot.color = Color(1.0, 0.9, 0.3)
		marker.add_child(dot)

		# Time label
		var t = int(event_time)
		var time_lbl = Label.new()
		time_lbl.text = "%d:%02d" % [t / 60, t % 60]
		time_lbl.add_theme_font_size_override("font_size", 10)
		time_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		marker.add_child(time_lbl)

		# Event label
		var ev_lbl = Label.new()
		ev_lbl.text = event_text
		ev_lbl.add_theme_font_size_override("font_size", 10)
		ev_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		ev_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
		ev_lbl.custom_minimum_size = Vector2(60, 0)
		marker.add_child(ev_lbl)

		timeline_container.add_child(marker)


# ---------------------------------------------------------------------------
# Screenshot
# ---------------------------------------------------------------------------

func _take_screenshot() -> void:
	AudioManager.play_sfx("menu_click")
	var img = get_viewport().get_texture().get_image()
	var datetime_str = Time.get_datetime_string_from_system().replace(":", "-").replace("T", "_")
	var path = "user://screenshots/run_%s.png" % datetime_str
	DirAccess.make_dir_recursive_absolute("user://screenshots/")
	img.save_png(path)
	# Brief visual feedback
	screenshot_btn.text = "Screenshot salvo!"
	await get_tree().create_timer(2.0).timeout
	screenshot_btn.text = "Salvar screenshot"


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


# ---------------------------------------------------------------------------
# Online Leaderboard score submission (all modes)
# ---------------------------------------------------------------------------

func _submit_leaderboard_online() -> void:
	var kills: int = GameManager.total_kills
	var survived: float = GameManager.game_time
	var crystals: int = GameManager.crystals_this_run
	# Score formula: kills * 10 + survived_seconds + crystals_earned
	var score: int = kills * 10 + int(survived) + crystals

	var player_name: String = SaveManager.data.get("player_name", "Anonymous")
	var version_str := ""
	var file := FileAccess.open("res://VERSION", FileAccess.READ)
	if file:
		version_str = file.get_as_text().strip_edges()

	var daily_seed: int = 0
	if GameManager.game_mode == "daily":
		daily_seed = DailyChallenge.get_daily_seed()

	var score_data := {
		"player_name": player_name,
		"score": score,
		"kills": kills,
		"survived_seconds": survived,
		"character": GameManager.selected_character,
		"stage": GameManager.selected_stage,
		"game_mode": GameManager.game_mode,
		"daily_seed": daily_seed,
		"version": version_str,
	}
	Telemetry.submit_leaderboard(score_data)
