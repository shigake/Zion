extends CanvasLayer

## Tela de Game Over com stats detalhados da run.

@onready var panel: PanelContainer = $Panel
@onready var time_label: Label = $Panel/ScrollContainer/VBox/TimeLabel
@onready var kills_label: Label = $Panel/ScrollContainer/VBox/KillsLabel
@onready var level_label: Label = $Panel/ScrollContainer/VBox/LevelLabel
@onready var crystals_label: Label = $Panel/ScrollContainer/VBox/CrystalsLabel
@onready var dps_label: Label = $Panel/ScrollContainer/VBox/DPSLabel
@onready var peak_enemies_label: Label = $Panel/ScrollContainer/VBox/PeakEnemiesLabel
@onready var weapons_label: Label = $Panel/ScrollContainer/VBox/WeaponsLabel
@onready var items_label: Label = $Panel/ScrollContainer/VBox/ItemsLabel
@onready var evolutions_label: Label = $Panel/ScrollContainer/VBox/EvolutionsLabel
@onready var events_label: Label = $Panel/ScrollContainer/VBox/EventsLabel
@onready var retry_btn: Button = $Panel/ScrollContainer/VBox/RetryButton
@onready var menu_btn: Button = $Panel/ScrollContainer/VBox/MenuButton

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
	crystals_label.text = LocaleManager.tr_key("crystals_earned") % GameManager.crystals_this_run

	# DPS
	var dps: float = 0.0
	if GameManager.game_time > 0:
		dps = GameManager.total_damage_dealt / GameManager.game_time
	dps_label.text = "DPS: %d" % int(dps)

	# Peak enemies
	peak_enemies_label.text = "Peak Enemies: %d" % GameManager.peak_enemies

	# Weapons obtained with levels
	var weapon_strs: Array[String] = []
	for w in GameManager.player_weapons:
		var data = WeaponDB.weapons.get(w["id"], {})
		var wname = data.get("name", w["id"])
		weapon_strs.append("%s Lv.%d" % [wname, w["level"]])
	if weapon_strs.is_empty():
		weapons_label.text = "Armas: -"
	else:
		weapons_label.text = "Armas: " + ", ".join(weapon_strs)

	# Items obtained with levels
	var item_strs: Array[String] = []
	for it in GameManager.player_items:
		var data = ItemDB.get_item(it["id"])
		var iname = data.get("name", it["id"])
		item_strs.append("%s Lv.%d" % [iname, it["level"]])
	if item_strs.is_empty():
		items_label.text = "Itens: -"
	else:
		items_label.text = "Itens: " + ", ".join(item_strs)

	# Evolutions triggered
	if EvolutionDB.evolved_weapons.is_empty():
		evolutions_label.text = ""
		evolutions_label.visible = false
	else:
		var evo_names: Array[String] = []
		for evo_id in EvolutionDB.evolved_weapons:
			var evo = EvolutionDB.get_evolution(evo_id)
			evo_names.append(evo.get("name", evo_id))
		evolutions_label.text = "Evolucoes: " + ", ".join(evo_names)
		evolutions_label.visible = true

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
			var char_data = CharacterDB.get_character(char_id)
			crystals_label.text += "\n" + LocaleManager.tr_key("unlocked") % char_data["name"]
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

func _on_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
