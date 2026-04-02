extends CanvasLayer

## Tela de Game Over com stats essenciais da run.

@onready var panel: PanelContainer = $Panel
@onready var time_label: Label = $Panel/MarginContainer/VBox/StatsRow1/TimeLabel
@onready var level_label: Label = $Panel/MarginContainer/VBox/StatsRow1/LevelLabel
@onready var kills_label: Label = $Panel/MarginContainer/VBox/StatsRow2/KillsLabel
@onready var crystals_label: Label = $Panel/MarginContainer/VBox/StatsRow2/CrystalsLabel
@onready var title_label: Label = $Panel/MarginContainer/VBox/TitleLabel
@onready var weapons_title: Label = $Panel/MarginContainer/VBox/WeaponsTitle
@onready var weapons_container: VBoxContainer = $Panel/MarginContainer/VBox/WeaponsContainer
@onready var items_title: Label = $Panel/MarginContainer/VBox/ItemsTitle
@onready var items_container: VBoxContainer = $Panel/MarginContainer/VBox/ItemsContainer
@onready var evolutions_title: Label = $Panel/MarginContainer/VBox/EvolutionsTitle
@onready var evolutions_container: VBoxContainer = $Panel/MarginContainer/VBox/EvolutionsContainer
@onready var unlock_label: Label = $Panel/MarginContainer/VBox/UnlockLabel
@onready var screenshot_btn: Button = $Panel/MarginContainer/VBox/ButtonRow/ScreenshotButton
@onready var retry_btn: Button = $Panel/MarginContainer/VBox/ButtonRow/RetryButton
@onready var menu_btn: Button = $Panel/MarginContainer/VBox/ButtonRow/MenuButton
@onready var char_icon: TextureRect = $Panel/MarginContainer/VBox/CharacterRow/CharIcon
@onready var char_name_label: Label = $Panel/MarginContainer/VBox/CharacterRow/CharNameLabel

@onready var overlay: ColorRect = $Overlay

# Seed display and copy
var _seed_row: HBoxContainer = null
var _seed_label: Label = null
var _seed_copy_btn: Button = null

func _ready() -> void:
	overlay.visible = false
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.visible = false
	GameManager.game_over.connect(_show)
	retry_btn.pressed.connect(_on_retry)
	menu_btn.pressed.connect(_on_menu)
	screenshot_btn.pressed.connect(_take_screenshot)
	_build_seed_row()

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

	# Title
	if GameManager.is_victory:
		var all_complete := true
		var all_stages := GameConstants.ALL_STAGES
		for s in all_stages:
			if s not in SaveManager.data.get("completed_stages", []):
				all_complete = false
				break
		if all_complete and GameManager.game_mode == "normal":
			title_label.text = LocaleManager.tr_key("victory_all_stages")
		else:
			var victory_key = "victory_lore_" + GameManager.selected_stage
			var victory_text = LocaleManager.tr_key(victory_key)
			if victory_text == victory_key:
				victory_text = LocaleManager.tr_key("lore_victory")
			title_label.text = victory_text
	else:
		title_label.text = LocaleManager.tr_key("lore_death")

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

	if GameManager.is_victory:
		AudioManager.play_music("victory")
	else:
		AudioManager.play_music("game_over_music")
	overlay.visible = true
	panel.visible = true
	GameManager.paused = true
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

func _on_menu() -> void:
	AudioManager.play_sfx("menu_click")
	get_tree().paused = false
	if MultiplayerManager.is_online:
		MultiplayerManager.disconnect_from_game()
	LoadingScreen.transition_to("res://scenes/ui/main_menu.tscn")


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
	var vbox = $Panel/MarginContainer/VBox
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
