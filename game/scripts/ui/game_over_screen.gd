extends CanvasLayer

## Tela de Game Over com stats da run em 2 abas:
##   Aba 1 — Resumo (dados principais + best run comparison)
##   Aba 2 — Registro Dimensional (breakdown detalhado por arma, sinergia, economia)
## PRD 28 §4 — Expanded Post-Run Stats

@onready var panel: PanelContainer = $Panel
@onready var _content_vbox: VBoxContainer = $Panel/MarginContainer/VBox/ScrollContainer/ContentVBox
@onready var time_label: Label = $Panel/MarginContainer/VBox/ScrollContainer/ContentVBox/StatsRow1/TimeLabel
@onready var level_label: Label = $Panel/MarginContainer/VBox/ScrollContainer/ContentVBox/StatsRow1/LevelLabel
@onready var kills_label: Label = $Panel/MarginContainer/VBox/ScrollContainer/ContentVBox/StatsRow2/KillsLabel
@onready var crystals_label: Label = $Panel/MarginContainer/VBox/ScrollContainer/ContentVBox/StatsRow2/CrystalsLabel
@onready var title_label: Label = $Panel/MarginContainer/VBox/ScrollContainer/ContentVBox/TitleLabel
@onready var weapons_title: Label = $Panel/MarginContainer/VBox/ScrollContainer/ContentVBox/WeaponsTitle
@onready var weapons_container: VBoxContainer = $Panel/MarginContainer/VBox/ScrollContainer/ContentVBox/WeaponsContainer
@onready var items_title: Label = $Panel/MarginContainer/VBox/ScrollContainer/ContentVBox/ItemsTitle
@onready var items_container: VBoxContainer = $Panel/MarginContainer/VBox/ScrollContainer/ContentVBox/ItemsContainer
@onready var evolutions_title: Label = $Panel/MarginContainer/VBox/ScrollContainer/ContentVBox/EvolutionsTitle
@onready var evolutions_container: VBoxContainer = $Panel/MarginContainer/VBox/ScrollContainer/ContentVBox/EvolutionsContainer
@onready var unlock_label: Label = $Panel/MarginContainer/VBox/ScrollContainer/ContentVBox/UnlockLabel
@onready var screenshot_btn: Button = $Panel/MarginContainer/VBox/ButtonRow/ScreenshotButton
@onready var retry_btn: Button = $Panel/MarginContainer/VBox/ButtonRow/RetryButton
@onready var menu_btn: Button = $Panel/MarginContainer/VBox/ButtonRow/MenuButton
@onready var char_icon: TextureRect = $Panel/MarginContainer/VBox/ScrollContainer/ContentVBox/CharacterRow/CharIcon
@onready var char_name_label: Label = $Panel/MarginContainer/VBox/ScrollContainer/ContentVBox/CharacterRow/CharNameLabel

@onready var overlay: ColorRect = $Overlay

# Seed display and copy
var _seed_row: HBoxContainer = null
var _seed_label: Label = null
var _seed_copy_btn: Button = null

# Tab system — PRD 28 §4
var _current_tab: int = 0  # 0 = Resumo, 1 = Registro Dimensional
var _tab_bar: HBoxContainer = null
var _tab_resumo_btn: Button = null
var _tab_detail_btn: Button = null
var _tab_hint_label: Label = null
var _narrative_label: Label = null
var _best_run_grid: GridContainer = null
var _detail_container: Control = null  # StatsDetailTab instance
var _stats_container: VBoxContainer = null  # Expanded stats (inline in tab 1)

# Nodes that belong to tab 1 only (hidden when on tab 2)
var _summary_nodes: Array[Node] = []
# Nodes that belong to tab 2 only (hidden when on tab 1)
var _detail_nodes: Array[Node] = []


func _ready() -> void:
	overlay.visible = false
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.visible = false
	GameManager.game_over.connect(_show)
	retry_btn.pressed.connect(_on_retry)
	menu_btn.pressed.connect(_on_menu)
	screenshot_btn.pressed.connect(_take_screenshot)
	_build_seed_row()
	_build_tab_bar()
	_build_narrative_label()
	_build_best_run_section()
	_build_detail_tab()


var _already_shown: bool = false

func _show() -> void:
	if _already_shown:
		return
	# PRD 61: Intercept victory to offer endless mode
	if GameManager.is_victory and not EndlessMode.is_endless_active:
		_already_shown = true
		# Show endless prompt instead of game over
		var prompt_script = load("res://scripts/ui/endless_prompt.gd")
		if prompt_script:
			var prompt = Control.new()
			prompt.set_script(prompt_script)
			get_tree().current_scene.add_child(prompt)
			# Reset flag so game_over can be shown later (when player chooses to end or dies in endless)
			_already_shown = false
			return
	_already_shown = true
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

	# Title — header claro (GAME OVER / WIN) + lore
	if GameManager.is_victory:
		var header = "WIN!"
		var all_complete := true
		var all_stages := GameConstants.ALL_STAGES
		for s in all_stages:
			if s not in SaveManager.data.get("completed_stages", []):
				all_complete = false
				break
		if all_complete and GameManager.game_mode == "normal":
			title_label.text = header + "\n" + LocaleManager.tr_key("victory_all_stages")
		else:
			var victory_key = "victory_lore_" + GameManager.selected_stage
			var victory_text = LocaleManager.tr_key(victory_key)
			if victory_text == victory_key:
				victory_text = LocaleManager.tr_key("lore_victory")
			title_label.text = header + "\n" + victory_text
	else:
		title_label.text = "GAME OVER\n" + LocaleManager.tr_key("lore_death")

	# Stats
	var t = int(GameManager.game_time)
	var time_str = "%02d:%02d" % [t / 60, t % 60]
	time_label.text = LocaleManager.tr_key("time") % time_str
	level_label.text = LocaleManager.tr_key("level_stat") % GameManager.player_level
	kills_label.text = LocaleManager.tr_key("kills_stat") % GameManager.total_kills
	var crystal_mult = MutationManager.get_crystal_multiplier()
	crystals_label.text = LocaleManager.tr_key("crystals_earned") % GameManager.crystals_this_run
	if crystal_mult > 1.0:
		crystals_label.text += " (x%.1f)" % crystal_mult

	# PRD 28 §4 — Expanded post-run stats (inline in tab 1)
	_build_expanded_stats()

	# PRD 28 §4 — Best run comparison arrows
	_populate_best_run_comparison()

	# PRD 28 §4 — Narrative label
	_populate_narrative()

	# PRD 28 §4 — Detail tab
	_populate_detail_tab()

	# Character sprite
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

	# Weapons — compact icon grid
	if GameManager.player_weapons.is_empty():
		weapons_title.visible = false
		weapons_container.visible = false
	else:
		weapons_title.text = "Armas:"
		weapons_title.visible = true
		weapons_container.visible = true
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

	# Items — compact icon grid
	if GameManager.player_items.is_empty():
		items_title.visible = false
		items_container.visible = false
	else:
		items_title.text = "Itens:"
		items_title.visible = true
		items_container.visible = true
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

	# Evolutions — compact icon grid
	if EvolutionDB.evolved_weapons.is_empty():
		evolutions_title.visible = false
		evolutions_container.visible = false
	else:
		evolutions_title.text = "Evolucoes:"
		evolutions_title.visible = true
		evolutions_container.visible = true
		var evo_grid = GridContainer.new()
		evo_grid.columns = 6
		evo_grid.add_theme_constant_override("h_separation", 8)
		evo_grid.add_theme_constant_override("v_separation", 4)
		for evo_id in EvolutionDB.evolved_weapons:
			var evo = EvolutionDB.get_evolution(evo_id)
			var evo_name = evo.get("name", evo_id)
			var icon_path = "res://assets/sprites/weapons/%s.png" % evo_id
			var tex = TextureRect.new()
			tex.custom_minimum_size = Vector2(32, 32)
			tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			tex.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			if ResourceLoader.exists(icon_path):
				tex.texture = load(icon_path)
			tex.tooltip_text = evo_name
			evo_grid.add_child(tex)
		evolutions_container.add_child(evo_grid)

	# Leaderboard rank for endless mode
	unlock_label.text = ""
	if GameManager.game_mode == "endless":
		var leaderboard = SaveManager.get_leaderboard()
		for i in range(leaderboard.size()):
			if absf(leaderboard[i].get("time", 0) - GameManager.game_time) < 1.0:
				unlock_label.text = LocaleManager.tr_key("leaderboard_rank") % (i + 1)
				break
	# Stage completion (only on victory)
	if GameManager.is_victory:
		var stage_key = "stage_" + GameManager.selected_stage
		var stage_name = LocaleManager.tr_key(stage_key)
		if unlock_label.text != "":
			unlock_label.text += "\n"
		unlock_label.text += LocaleManager.tr_key("stage_complete") % stage_name
	# Unlocks
	if not _unlocked_chars.is_empty():
		# Mystery character cutscene (plays once before showing unlock text)
		if "mystery" in _unlocked_chars and not SaveManager.data.get("mystery_cutscene_seen", false):
			var cutscene = preload("res://scenes/ui/mystery_cutscene.tscn").instantiate()
			add_child(cutscene)
			await cutscene.cutscene_finished
		for char_id in _unlocked_chars:
			var unlocked_data = CharacterDB.get_character(char_id)
			if unlock_label.text != "":
				unlock_label.text += "\n"
			unlock_label.text += LocaleManager.tr_key("unlocked") % unlocked_data["name"]
			if char_id == "mystery":
				unlock_label.text += "\n" + LocaleManager.tr_key("lore_mystery_unlock")
	unlock_label.visible = unlock_label.text != ""

	# Seed display
	_update_seed_display()

	# PRD 61: Endless mode stats
	if EndlessMode.is_endless_active and EndlessMode.endless_wave > 0:
		var endless_label = Label.new()
		endless_label.add_theme_font_size_override("font_size", 14)
		endless_label.add_theme_color_override("font_color", Color(0.8, 0.6, 1.0))
		endless_label.add_theme_constant_override("outline_size", 2)
		endless_label.add_theme_color_override("font_outline_color", Color(0.1, 0.0, 0.15))
		var classification = EndlessMode.get_classification()
		var endless_time = GameManager.game_time - EndlessMode.endless_start_time
		var et = int(endless_time)
		endless_label.text = "Fenda infinita: onda %d | %02d:%02d | %s" % [
			EndlessMode.endless_wave, et / 60, et % 60, classification
		]
		_content_vbox.add_child(endless_label)
		EndlessMode.save_endless_result()

	if GameManager.is_victory:
		AudioManager.play_music("victory")
	else:
		AudioManager.play_music("game_over_music")
	overlay.visible = true
	panel.visible = true
	GameManager.paused = true

	# Entrance animation — fade overlay + slide panel up
	overlay.color.a = 0.0
	panel.modulate.a = 0.0
	var _panel_target_top = panel.offset_top
	panel.offset_top += 30
	var tw = create_tween()
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.set_parallel(true)
	tw.tween_property(overlay, "color:a", 0.85, 0.4).set_ease(Tween.EASE_OUT)
	tw.tween_property(panel, "modulate:a", 1.0, 0.35).set_ease(Tween.EASE_OUT)
	tw.tween_property(panel, "offset_top", _panel_target_top, 0.4).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

	# Default to tab 1 (Resumo)
	_switch_tab(0)

	# Gamepad: focus on Retry (retry -> screenshot -> menu cycle)
	retry_btn.focus_mode = Control.FOCUS_ALL
	screenshot_btn.focus_mode = Control.FOCUS_ALL
	menu_btn.focus_mode = Control.FOCUS_ALL
	retry_btn.focus_neighbor_right = screenshot_btn.get_path()
	retry_btn.focus_neighbor_left = menu_btn.get_path()
	screenshot_btn.focus_neighbor_right = menu_btn.get_path()
	screenshot_btn.focus_neighbor_left = retry_btn.get_path()
	menu_btn.focus_neighbor_right = retry_btn.get_path()
	menu_btn.focus_neighbor_left = screenshot_btn.get_path()
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
		return
	# L1/R1 or Tab to switch tabs
	if event.is_action_pressed("ui_page_up") or event.is_action_pressed("ui_focus_prev"):
		_switch_tab(0)
		if get_viewport(): get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_page_down") or event.is_action_pressed("ui_focus_next"):
		_switch_tab(1)
		if get_viewport(): get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and event.keycode == KEY_TAB:
		_switch_tab(1 - _current_tab)
		if get_viewport(): get_viewport().set_input_as_handled()

func _on_menu() -> void:
	AudioManager.play_sfx("menu_click")
	get_tree().paused = false
	Engine.time_scale = 1.0  # Restore in case game ended during slow-mo
	if MultiplayerManager.is_online:
		MultiplayerManager.disconnect_from_game()
	LoadingScreen.transition_to("res://scenes/ui/main_menu.tscn")


# ---------------------------------------------------------------------------
# Tab System — PRD 28 §4
# ---------------------------------------------------------------------------

## Build tab bar with two buttons (Resumo | Registro Dimensional).
func _build_tab_bar() -> void:
	var vbox = _content_vbox
	_tab_bar = HBoxContainer.new()
	_tab_bar.name = "TabBar"
	_tab_bar.alignment = BoxContainer.ALIGNMENT_CENTER
	_tab_bar.add_theme_constant_override("separation", 4)

	_tab_resumo_btn = Button.new()
	_tab_resumo_btn.text = LocaleManager.tr_key("stats_summary")
	_tab_resumo_btn.add_theme_font_size_override("font_size", 12)
	_tab_resumo_btn.custom_minimum_size = Vector2(110, 28)
	_tab_resumo_btn.pressed.connect(_switch_tab.bind(0))
	_tab_bar.add_child(_tab_resumo_btn)

	_tab_detail_btn = Button.new()
	_tab_detail_btn.text = LocaleManager.tr_key("stats_details")
	_tab_detail_btn.add_theme_font_size_override("font_size", 12)
	_tab_detail_btn.custom_minimum_size = Vector2(140, 28)
	_tab_detail_btn.pressed.connect(_switch_tab.bind(1))
	_tab_bar.add_child(_tab_detail_btn)

	# Insert after CharacterRow (index 1 in VBox children)
	var char_row_idx = _content_vbox.get_node("CharacterRow").get_index()
	vbox.add_child(_tab_bar)
	vbox.move_child(_tab_bar, char_row_idx + 1)

	# Tab hint (L1/R1)
	_tab_hint_label = Label.new()
	_tab_hint_label.text = LocaleManager.tr_key("stats_tab_hint")
	_tab_hint_label.add_theme_font_size_override("font_size", 10)
	_tab_hint_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6, 0.7))
	_tab_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_tab_hint_label)
	vbox.move_child(_tab_hint_label, char_row_idx + 2)


## Build narrative label (lore text for the detail tab).
func _build_narrative_label() -> void:
	var vbox = _content_vbox
	_narrative_label = Label.new()
	_narrative_label.name = "NarrativeLabel"
	_narrative_label.add_theme_font_size_override("font_size", 11)
	_narrative_label.add_theme_color_override("font_color", Color(0.6, 0.7, 0.9, 0.9))
	_narrative_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_narrative_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_narrative_label.visible = false
	vbox.add_child(_narrative_label)
	# Position after tab hint
	var hint_idx = _tab_hint_label.get_index()
	vbox.move_child(_narrative_label, hint_idx + 1)
	_detail_nodes.append(_narrative_label)


## Build best run comparison section (shown in tab 1).
func _build_best_run_section() -> void:
	var vbox = _content_vbox
	_best_run_grid = GridContainer.new()
	_best_run_grid.name = "BestRunComparison"
	_best_run_grid.columns = 2
	_best_run_grid.add_theme_constant_override("h_separation", 12)
	_best_run_grid.add_theme_constant_override("v_separation", 2)
	_best_run_grid.visible = false
	vbox.add_child(_best_run_grid)
	# Will be positioned in _show() after other elements are built
	_summary_nodes.append(_best_run_grid)


## Build the detail tab container (StatsDetailTab).
func _build_detail_tab() -> void:
	var vbox = _content_vbox
	var detail_script = load("res://scripts/ui/stats_detail_tab.gd")
	_detail_container = Control.new()
	_detail_container.set_script(detail_script)
	_detail_container.name = "StatsDetailTab"
	_detail_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_detail_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_detail_container.visible = false
	# Insert before UnlockLabel
	var unlock_idx = unlock_label.get_index()
	vbox.add_child(_detail_container)
	vbox.move_child(_detail_container, unlock_idx)
	_detail_nodes.append(_detail_container)


## Switch between tab 0 (Resumo) and tab 1 (Registro Dimensional).
func _switch_tab(idx: int) -> void:
	_current_tab = idx
	AudioManager.play_sfx("menu_click")

	# Update tab button styles
	var active_color := Color(1.0, 0.85, 0.3)
	var inactive_color := Color(0.6, 0.6, 0.7)
	_tab_resumo_btn.add_theme_color_override("font_color", active_color if idx == 0 else inactive_color)
	_tab_detail_btn.add_theme_color_override("font_color", active_color if idx == 1 else inactive_color)

	# Toggle summary nodes (tab 1)
	var summary_visible := (idx == 0)
	for node in _summary_nodes:
		if is_instance_valid(node):
			node.visible = summary_visible

	# Toggle detail nodes (tab 2)
	var detail_visible := (idx == 1)
	for node in _detail_nodes:
		if is_instance_valid(node):
			node.visible = detail_visible

	# StatsRow1/2, expanded stats, weapons/items/evolutions belong to tab 1
	_content_vbox.get_node("StatsRow1").visible = summary_visible
	_content_vbox.get_node("StatsRow2").visible = summary_visible
	if _stats_container and is_instance_valid(_stats_container):
		_stats_container.visible = summary_visible
	weapons_title.visible = summary_visible and not GameManager.player_weapons.is_empty()
	weapons_container.visible = summary_visible and not GameManager.player_weapons.is_empty()
	items_title.visible = summary_visible and not GameManager.player_items.is_empty()
	items_container.visible = summary_visible and not GameManager.player_items.is_empty()
	evolutions_title.visible = summary_visible and not EvolutionDB.evolved_weapons.is_empty()
	evolutions_container.visible = summary_visible and not EvolutionDB.evolved_weapons.is_empty()


## Populate narrative label based on victory/death.
func _populate_narrative() -> void:
	if GameManager.is_victory:
		_narrative_label.text = LocaleManager.tr_key("victory_lore")
	else:
		_narrative_label.text = LocaleManager.tr_key("death_lore")


## Populate best run comparison (▲▼ arrows) for 5 key metrics.
func _populate_best_run_comparison() -> void:
	# Clear previous
	for child in _best_run_grid.get_children():
		child.queue_free()

	var best = SaveManager.get_best_run(GameManager.selected_character)
	if best.is_empty():
		_best_run_grid.visible = false
		return

	var comparisons: Array[Dictionary] = [
		{"label": LocaleManager.tr_key("kills_stat") % GameManager.total_kills, "current": GameManager.total_kills, "best": best.get("kills", 0), "higher_is_better": true},
		{"label": LocaleManager.tr_key("level_stat") % GameManager.player_level, "current": GameManager.player_level, "best": best.get("level", 0), "higher_is_better": true},
		{"label": LocaleManager.tr_key("crystals_earned") % GameManager.crystals_this_run, "current": GameManager.crystals_this_run, "best": best.get("crystals", 0), "higher_is_better": true},
		{"label": LocaleManager.tr_key("stats_peak_dps"), "current": int(GameManager.dps_peak), "best": int(best.get("dps_peak", 0.0)), "higher_is_better": true},
	]

	var has_any_diff := false
	for comp in comparisons:
		var diff: int = comp["current"] - comp["best"]
		if diff != 0:
			has_any_diff = true
			break

	if not has_any_diff:
		_best_run_grid.visible = false
		return

	_best_run_grid.visible = true

	for comp in comparisons:
		var diff: int = comp["current"] - comp["best"]
		if diff == 0:
			continue

		var label := Label.new()
		label.text = comp["label"]
		label.add_theme_font_size_override("font_size", 11)
		label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
		_best_run_grid.add_child(label)

		var arrow_label := Label.new()
		arrow_label.add_theme_font_size_override("font_size", 11)
		arrow_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		var is_better: bool = (diff > 0) == comp["higher_is_better"]
		if is_better:
			arrow_label.text = "▲ +%s" % _format_number(absi(diff))
			arrow_label.add_theme_color_override("font_color", Color(0.3, 0.9, 0.4))
		else:
			arrow_label.text = "▼ -%s" % _format_number(absi(diff))
			arrow_label.add_theme_color_override("font_color", Color(0.9, 0.3, 0.3))
		_best_run_grid.add_child(arrow_label)

	# Position after StatsRow2
	var vbox = _content_vbox
	var stats_row2_idx = _content_vbox.get_node("StatsRow2").get_index()
	vbox.move_child(_best_run_grid, stats_row2_idx + 1)


## Populate the detail tab with full run stats.
func _populate_detail_tab() -> void:
	if _detail_container and is_instance_valid(_detail_container):
		var stats = GameManager.get_run_stats()
		_detail_container.populate(stats)


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
	screenshot_btn.text = "Salvo!"
	await get_tree().create_timer(2.0).timeout
	screenshot_btn.text = "Screenshot"


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

## Build seed display row (added to ButtonRow parent VBox).
func _build_seed_row() -> void:
	var vbox = _content_vbox
	_seed_row = HBoxContainer.new()
	_seed_row.name = "SeedRow"
	_seed_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_seed_row.add_theme_constant_override("separation", 8)
	_seed_row.visible = false
	vbox.add_child(_seed_row)

	_seed_label = Label.new()
	_seed_label.add_theme_font_size_override("font_size", 13)
	_seed_label.add_theme_color_override("font_color", Color(0.6, 0.75, 1.0))
	_seed_row.add_child(_seed_label)

	_seed_copy_btn = Button.new()
	_seed_copy_btn.text = LocaleManager.tr_key("seed_copy")
	_seed_copy_btn.add_theme_font_size_override("font_size", 12)
	_seed_copy_btn.focus_mode = Control.FOCUS_ALL
	_seed_copy_btn.pressed.connect(_on_copy_seed)
	_seed_row.add_child(_seed_copy_btn)

func _update_seed_display() -> void:
	if GameManager.current_seed != "":
		_seed_label.text = LocaleManager.tr_key("seed_coordinate_short") + ": " + GameManager.current_seed
		_seed_row.visible = true
	else:
		_seed_row.visible = false

func _on_copy_seed() -> void:
	var t = int(GameManager.game_time)
	var time_str = "%02d:%02d" % [t / 60, t % 60]
	var stage_key = "stage_" + GameManager.selected_stage
	var stage_name = LocaleManager.tr_key(stage_key)
	var text = "Zion | Seed: %s | %s | Lv.%d | %d kills | %s" % [
		GameManager.current_seed,
		stage_name,
		GameManager.player_level,
		GameManager.total_kills,
		time_str
	]
	DisplayServer.clipboard_set(text)
	AudioManager.play_sfx("menu_click")
	_seed_copy_btn.text = LocaleManager.tr_key("seed_copied")
	await get_tree().create_timer(2.0).timeout
	_seed_copy_btn.text = LocaleManager.tr_key("seed_copy")

## Remove all children from a container (used to reset between shows).
func _clear_container(container: Container) -> void:
	for child in container.get_children():
		child.queue_free()


# ---------------------------------------------------------------------------
# PRD 28 §4 — Expanded Post-Run Stats (inline in Tab 1)
# ---------------------------------------------------------------------------

func _build_expanded_stats() -> void:
	# Remove previous stats container if it exists
	if _stats_container and is_instance_valid(_stats_container):
		_stats_container.queue_free()
		_stats_container = null

	var vbox = _content_vbox
	_stats_container = VBoxContainer.new()
	_stats_container.name = "ExpandedStats"
	_stats_container.add_theme_constant_override("separation", 2)

	# Section title with gold accent
	var section_label := Label.new()
	section_label.text = LocaleManager.tr_key("stat_combat_details")
	section_label.add_theme_font_size_override("font_size", 14)
	section_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	section_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_stats_container.add_child(section_label)

	var sep := HSeparator.new()
	sep.add_theme_color_override("separator", Color(1.0, 0.85, 0.3, 0.4))
	_stats_container.add_child(sep)

	# Grid for stat rows
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 3)

	var stats = GameManager.get_run_stats()

	# DPS peak
	_add_stat_row(grid, LocaleManager.tr_key("stat_dps_peak"), _format_number(int(stats.get("dps_peak", 0.0))), stats.get("dps_peak", 0.0) > 500.0)

	# Total damage dealt
	_add_stat_row(grid, LocaleManager.tr_key("stat_total_damage"), _format_number(stats.get("total_damage_dealt", 0)))

	# Highest single hit
	_add_stat_row(grid, LocaleManager.tr_key("stat_highest_hit"), _format_number(stats.get("highest_single_hit", 0)), stats.get("highest_single_hit", 0) > 1000)

	# Longest no-damage streak
	var streak_secs: float = stats.get("longest_no_damage_streak", 0.0)
	var streak_str: String
	if streak_secs >= 60.0:
		streak_str = "%dm %ds" % [int(streak_secs) / 60, int(streak_secs) % 60]
	else:
		streak_str = "%.1fs" % streak_secs
	_add_stat_row(grid, LocaleManager.tr_key("stat_no_damage_streak"), streak_str, streak_secs > 30.0)

	# Total damage taken
	_add_stat_row(grid, LocaleManager.tr_key("stat_damage_taken"), _format_number(stats.get("total_damage_taken", 0)))

	# Dash count
	_add_stat_row(grid, LocaleManager.tr_key("stat_dash_count"), str(stats.get("dash_count", 0)))

	# Overkill damage
	_add_stat_row(grid, LocaleManager.tr_key("stat_overkill"), _format_number(stats.get("overkill_damage", 0)), stats.get("overkill_damage", 0) > 5000)

	# Near deaths
	var near = stats.get("near_deaths", 0)
	if near > 0:
		_add_stat_row(grid, LocaleManager.tr_key("stats_near_deaths"), str(near), true)

	# Favorite weapon
	var fav = stats.get("favorite_weapon", "")
	if fav != "":
		_add_stat_row(grid, LocaleManager.tr_key("stats_favorite_weapon"), fav, true)

	_stats_container.add_child(grid)

	# Register as summary node
	if _stats_container not in _summary_nodes:
		_summary_nodes.append(_stats_container)

	# Insert before weapons section
	var weapons_idx = weapons_title.get_index()
	vbox.add_child(_stats_container)
	vbox.move_child(_stats_container, weapons_idx)


## Add a stat row to the grid: label on left, value on right.
## If highlight is true, value gets a gold accent color.
func _add_stat_row(grid: GridContainer, label_text: String, value_text: String, highlight: bool = false) -> void:
	var label := Label.new()
	label.text = label_text
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
	grid.add_child(label)

	var value := Label.new()
	value.text = value_text
	value.add_theme_font_size_override("font_size", 12)
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	if highlight:
		value.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	else:
		value.add_theme_color_override("font_color", Color(0.9, 0.9, 0.95))
	grid.add_child(value)


## Format large numbers with K/M suffixes.
func _format_number(n: int) -> String:
	if n >= 1000000:
		return "%.1fM" % (float(n) / 1000000.0)
	elif n >= 10000:
		return "%.1fK" % (float(n) / 1000.0)
	return str(n)


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

	# Submit to per-seed leaderboard if run had a seed
	if GameManager.current_seed != "":
		var seed_entry := {
			"score": score,
			"kills": kills,
			"time": survived,
			"crystals": crystals,
			"character": GameManager.selected_character,
			"level": GameManager.player_level,
			"date": Time.get_date_string_from_system(),
		}
		SaveManager.save_seed_score(GameManager.current_seed, seed_entry)
