extends Control

## Tela de Ranking Global — tabs por modo de jogo, dados mockados para teste.
## Segue PRD: docs/prd_leaderboard_online.md

# --- Colors (matching daily_challenge / main_menu theme) ---
const COLOR_BG := Color(0.04, 0.04, 0.06)
const COLOR_GOLD := Color(0.9, 0.8, 0.3)
const COLOR_GOLD_DIM := Color(0.7, 0.62, 0.22)
const COLOR_TEXT := Color(0.88, 0.88, 0.92)
const COLOR_SUBTITLE := Color(0.55, 0.55, 0.65)
const COLOR_ACCENT := Color(0.45, 0.85, 0.95)
const COLOR_GREEN := Color(0.4, 0.9, 0.4)
const COLOR_RED := Color(0.9, 0.35, 0.3)
const COLOR_PANEL := Color(0.08, 0.08, 0.12)
const COLOR_BORDER := Color(0.22, 0.21, 0.28)
const COLOR_BTN_NORMAL := Color(0.12, 0.12, 0.16)
const COLOR_BTN_HOVER := Color(0.18, 0.17, 0.24)
const COLOR_HIGHLIGHT := Color(0.15, 0.22, 0.15)
const COLOR_TAB_ACTIVE := Color(0.18, 0.17, 0.24)
const COLOR_TAB_INACTIVE := Color(0.08, 0.08, 0.10)

# --- Tabs ---
enum Mode { DAILY, ENDLESS, NORMAL, BOSS_RUSH }
var _current_mode: int = Mode.DAILY
var _tab_buttons: Array[Button] = []
var _entries_container: VBoxContainer
var _player_rank_label: Label
var _title_label: Label
var _back_btn: Button
var _refresh_btn: Button

# --- Player name (mockado por enquanto) ---
const MOCK_PLAYER_NAME := "VoceAqui"

# --- Mock data ---
# Nomes ficticios para popular o leaderboard
const MOCK_NAMES := [
	"xXSlayerXx", "BrunoGamer", "Ana_BR", "KillMaster99", "ShadowNinja",
	"DragonFire", "PixelHero", "GamerPro", "NightHunter", "StormBlade",
	"CyberWolf", "DarkMage", "IronFist", "ThunderGod", "BlazeSword",
	"FrostBite", "VenomStrike", "SteelHeart", "PhantomX", "SkullCrusher",
	"MysticArcher", "BladeDancer", "SoulReaper", "WarMachine", "FlameKnight",
	"IceQueen", "RogueOne", "DeathWish", "LightBringer", "ChaosLord",
	"StarDust", "MoonWalker", "SunFire", "WindRunner", "EarthShaker",
	"AquaMarine", "RubyRose", "EmeraldEye", "SapphireStorm", "DiamondDust",
	"GoldenEagle", "SilverFang", "BronzeKnight", "PlatinumStar", "CopperHead",
	"JadeWarrior", "OnyxShadow", "AmberGlow", "CoralReef", "PearlDiver",
]

const MOCK_CHARACTERS := ["ronin", "soldado", "mago", "berserker", "ninja", "necro",
	"pirata", "engenheiro", "vampiro", "gladiador", "chef", "mystery"]

const MOCK_STAGES := ["cemetery", "forest", "farm", "tokyo", "volcano",
	"ocean", "arena", "space", "castle", "candy"]

var _mock_data: Dictionary = {}


func _ready() -> void:
	get_tree().paused = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	_generate_mock_data()
	_build_ui()
	_show_mode(Mode.DAILY)
	GamepadUI.notify_menu_opened()


# ---------------------------------------------------------------------------
# Mock data generation
# ---------------------------------------------------------------------------

func _generate_mock_data() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 42  # Seed fixa para consistencia

	# Daily - scores do dia
	var daily_entries := []
	for i in range(50):
		var kills := rng.randi_range(200, 2500)
		var time_s := rng.randi_range(300, 1500)
		var crystals := rng.randi_range(50, 800)
		var score := kills * 10 + time_s + crystals
		daily_entries.append({
			"rank": i + 1,
			"player_name": MOCK_NAMES[i % MOCK_NAMES.size()],
			"score": score,
			"kills": kills,
			"time": time_s,
			"character": MOCK_CHARACTERS[rng.randi_range(0, MOCK_CHARACTERS.size() - 1)],
			"is_player": false,
		})
	# Sort by score desc
	daily_entries.sort_custom(func(a, b): return a["score"] > b["score"])
	# Inject player at rank ~23
	var player_daily := {
		"rank": 0,
		"player_name": MOCK_PLAYER_NAME,
		"score": 12450,
		"kills": 890,
		"time": 1120,
		"character": "ronin",
		"is_player": true,
	}
	daily_entries.insert(22, player_daily)
	# Re-rank
	for i in range(daily_entries.size()):
		daily_entries[i]["rank"] = i + 1
	_mock_data[Mode.DAILY] = daily_entries

	# Endless - by survived time
	var endless_entries := []
	for i in range(50):
		var time_s := rng.randi_range(600, 3600)
		var kills := rng.randi_range(500, 5000)
		endless_entries.append({
			"rank": i + 1,
			"player_name": MOCK_NAMES[i % MOCK_NAMES.size()],
			"score": time_s,  # Score = survived seconds in endless
			"kills": kills,
			"time": time_s,
			"character": MOCK_CHARACTERS[rng.randi_range(0, MOCK_CHARACTERS.size() - 1)],
			"is_player": false,
		})
	endless_entries.sort_custom(func(a, b): return a["time"] > b["time"])
	var player_endless := {
		"rank": 0,
		"player_name": MOCK_PLAYER_NAME,
		"score": 1820,
		"kills": 1456,
		"time": 1820,
		"character": "mago",
		"is_player": true,
	}
	endless_entries.insert(14, player_endless)
	for i in range(endless_entries.size()):
		endless_entries[i]["rank"] = i + 1
	_mock_data[Mode.ENDLESS] = endless_entries

	# Normal - by score
	var normal_entries := []
	for i in range(50):
		var kills := rng.randi_range(300, 3000)
		var time_s := rng.randi_range(400, 1800)
		var score := kills * 10 + time_s
		normal_entries.append({
			"rank": i + 1,
			"player_name": MOCK_NAMES[i % MOCK_NAMES.size()],
			"score": score,
			"kills": kills,
			"time": time_s,
			"character": MOCK_CHARACTERS[rng.randi_range(0, MOCK_CHARACTERS.size() - 1)],
			"stage": MOCK_STAGES[rng.randi_range(0, MOCK_STAGES.size() - 1)],
			"is_player": false,
		})
	normal_entries.sort_custom(func(a, b): return a["score"] > b["score"])
	var player_normal := {
		"rank": 0,
		"player_name": MOCK_PLAYER_NAME,
		"score": 15200,
		"kills": 1200,
		"time": 1400,
		"character": "ninja",
		"stage": "cemetery",
		"is_player": true,
	}
	normal_entries.insert(9, player_normal)
	for i in range(normal_entries.size()):
		normal_entries[i]["rank"] = i + 1
	_mock_data[Mode.NORMAL] = normal_entries

	# Boss Rush - by time (fastest)
	var boss_entries := []
	for i in range(50):
		var time_s := rng.randi_range(120, 900)
		var kills := rng.randi_range(10, 50)
		boss_entries.append({
			"rank": i + 1,
			"player_name": MOCK_NAMES[i % MOCK_NAMES.size()],
			"score": time_s,
			"kills": kills,
			"time": time_s,
			"character": MOCK_CHARACTERS[rng.randi_range(0, MOCK_CHARACTERS.size() - 1)],
			"is_player": false,
		})
	boss_entries.sort_custom(func(a, b): return a["time"] < b["time"])
	var player_boss := {
		"rank": 0,
		"player_name": MOCK_PLAYER_NAME,
		"score": 445,
		"kills": 28,
		"time": 445,
		"character": "berserker",
		"is_player": true,
	}
	boss_entries.insert(17, player_boss)
	for i in range(boss_entries.size()):
		boss_entries[i]["rank"] = i + 1
	_mock_data[Mode.BOSS_RUSH] = boss_entries


# ---------------------------------------------------------------------------
# UI Construction
# ---------------------------------------------------------------------------

func _build_ui() -> void:
	# Background
	var bg := ColorRect.new()
	bg.color = COLOR_BG
	bg.anchors_preset = Control.PRESET_FULL_RECT
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	add_child(bg)

	# Main scroll
	var scroll := ScrollContainer.new()
	scroll.anchors_preset = Control.PRESET_FULL_RECT
	scroll.anchor_right = 1.0
	scroll.anchor_bottom = 1.0
	scroll.offset_left = 40
	scroll.offset_top = 20
	scroll.offset_right = -40
	scroll.offset_bottom = -20
	add_child(scroll)

	var main_vbox := VBoxContainer.new()
	main_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_vbox.add_theme_constant_override("separation", 12)
	scroll.add_child(main_vbox)

	# Title
	_title_label = Label.new()
	_title_label.text = "Ranking global"
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.add_theme_font_size_override("font_size", 32)
	_title_label.add_theme_color_override("font_color", COLOR_GOLD)
	main_vbox.add_child(_title_label)

	# Subtitle (mock notice)
	var mock_notice := Label.new()
	mock_notice.text = "Dados de teste (mockados)"
	mock_notice.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mock_notice.add_theme_font_size_override("font_size", 12)
	mock_notice.add_theme_color_override("font_color", COLOR_SUBTITLE)
	main_vbox.add_child(mock_notice)

	# --- Tab bar ---
	var tab_panel := _create_panel()
	main_vbox.add_child(tab_panel)

	var tab_hbox := HBoxContainer.new()
	tab_hbox.add_theme_constant_override("separation", 8)
	tab_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	tab_panel.add_child(tab_hbox)

	var tab_names := ["Diario", "Endless", "Normal", "Boss rush"]
	var tab_icons := ["☀", "∞", "⚔", "👑"]
	_tab_buttons.clear()
	for i in range(tab_names.size()):
		var btn := Button.new()
		btn.text = "%s  %s" % [tab_icons[i], tab_names[i]]
		btn.custom_minimum_size = Vector2(150, 40)
		btn.focus_mode = Control.FOCUS_ALL
		btn.add_theme_font_size_override("font_size", 15)
		btn.pressed.connect(_on_tab_pressed.bind(i))
		_style_tab_button(btn, i == 0)
		tab_hbox.add_child(btn)
		_tab_buttons.append(btn)

	# --- Entries panel ---
	var entries_panel := _create_panel()
	main_vbox.add_child(entries_panel)

	_entries_container = VBoxContainer.new()
	_entries_container.add_theme_constant_override("separation", 2)
	entries_panel.add_child(_entries_container)

	# --- Player rank summary ---
	_player_rank_label = Label.new()
	_player_rank_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_player_rank_label.add_theme_font_size_override("font_size", 16)
	_player_rank_label.add_theme_color_override("font_color", COLOR_ACCENT)
	main_vbox.add_child(_player_rank_label)

	# --- Bottom buttons ---
	var btn_hbox := HBoxContainer.new()
	btn_hbox.add_theme_constant_override("separation", 16)
	btn_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	main_vbox.add_child(btn_hbox)

	_refresh_btn = Button.new()
	_refresh_btn.text = "Atualizar"
	_refresh_btn.custom_minimum_size = Vector2(160, 44)
	_refresh_btn.focus_mode = Control.FOCUS_ALL
	_refresh_btn.add_theme_font_size_override("font_size", 16)
	_style_menu_button(_refresh_btn)
	_refresh_btn.pressed.connect(_on_refresh)
	btn_hbox.add_child(_refresh_btn)

	_back_btn = Button.new()
	_back_btn.text = "Voltar"
	_back_btn.custom_minimum_size = Vector2(160, 44)
	_back_btn.focus_mode = Control.FOCUS_ALL
	_back_btn.add_theme_font_size_override("font_size", 16)
	_style_menu_button(_back_btn)
	_back_btn.pressed.connect(_on_back)
	btn_hbox.add_child(_back_btn)


# ---------------------------------------------------------------------------
# Populate entries for selected mode
# ---------------------------------------------------------------------------

func _show_mode(mode: int) -> void:
	_current_mode = mode

	# Update tab visuals
	for i in range(_tab_buttons.size()):
		_style_tab_button(_tab_buttons[i], i == mode)

	# Clear entries
	for child in _entries_container.get_children():
		child.queue_free()

	var entries: Array = _mock_data.get(mode, [])
	if entries.is_empty():
		var empty_label := Label.new()
		empty_label.text = LocaleManager.tr_key("leaderboard_empty")
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_label.add_theme_color_override("font_color", COLOR_SUBTITLE)
		_entries_container.add_child(empty_label)
		_player_rank_label.text = ""
		return

	# Header
	var header := Label.new()
	if mode == Mode.NORMAL:
		header.text = "  #    Nome              Score     Kills   Tempo    Char       Fase"
	elif mode == Mode.BOSS_RUSH:
		header.text = "  #    Nome              Tempo     Kills   Char"
	elif mode == Mode.ENDLESS:
		header.text = "  #    Nome              Tempo     Kills   Char"
	else:
		header.text = "  #    Nome              Score     Kills   Tempo    Char"
	header.add_theme_font_size_override("font_size", 13)
	header.add_theme_color_override("font_color", COLOR_SUBTITLE)
	_entries_container.add_child(header)

	var sep := HSeparator.new()
	_entries_container.add_child(sep)

	var rank_colors := [
		Color(1.0, 0.85, 0.2),   # Gold
		Color(0.8, 0.8, 0.8),    # Silver
		Color(0.8, 0.5, 0.2),    # Bronze
	]

	var player_rank := -1
	var player_score := 0

	# Show top 50 entries
	for i in range(mini(entries.size(), 50)):
		var entry: Dictionary = entries[i]
		var is_player: bool = entry.get("is_player", false)

		if is_player:
			player_rank = entry["rank"]
			player_score = entry["score"]

		var rank: int = entry["rank"]
		var name_str: String = entry["player_name"]
		var kills: int = entry.get("kills", 0)
		var t := int(entry.get("time", 0))
		var time_str := "%02d:%02d" % [t / 60, t % 60]
		var character: String = entry.get("character", "???").capitalize()
		var score: int = entry.get("score", 0)

		# Rank medal
		var rank_prefix := ""
		if rank == 1:
			rank_prefix = "🥇"
		elif rank == 2:
			rank_prefix = "🥈"
		elif rank == 3:
			rank_prefix = "🥉"
		else:
			rank_prefix = "%3d" % rank

		# Build row
		var row_panel := PanelContainer.new()
		var row_sb := StyleBoxFlat.new()
		if is_player:
			row_sb.bg_color = COLOR_HIGHLIGHT
			row_sb.border_color = COLOR_GOLD_DIM
			row_sb.set_border_width_all(1)
		else:
			row_sb.bg_color = Color.TRANSPARENT
			row_sb.border_color = Color.TRANSPARENT
			row_sb.set_border_width_all(0)
		row_sb.set_corner_radius_all(4)
		row_sb.content_margin_left = 8
		row_sb.content_margin_right = 8
		row_sb.content_margin_top = 3
		row_sb.content_margin_bottom = 3
		row_panel.add_theme_stylebox_override("panel", row_sb)

		var label := Label.new()
		if mode == Mode.NORMAL:
			var stage_str: String = entry.get("stage", "???").replace("_", " ").capitalize()
			label.text = " %s  %-16s  %6d    %4d    %s    %-10s %s" % [
				rank_prefix, name_str, score, kills, time_str, character, stage_str]
		elif mode == Mode.BOSS_RUSH:
			label.text = " %s  %-16s  %s    %4d    %s" % [
				rank_prefix, name_str, time_str, kills, character]
		elif mode == Mode.ENDLESS:
			label.text = " %s  %-16s  %s    %4d    %s" % [
				rank_prefix, name_str, time_str, kills, character]
		else:
			label.text = " %s  %-16s  %6d    %4d    %s    %s" % [
				rank_prefix, name_str, score, kills, time_str, character]

		label.add_theme_font_size_override("font_size", 14)

		# Color
		if is_player:
			label.add_theme_color_override("font_color", COLOR_GOLD)
			# Add star indicator
			label.text += "  ★"
		elif rank <= 3:
			label.add_theme_color_override("font_color", rank_colors[rank - 1])
		else:
			label.add_theme_color_override("font_color", COLOR_TEXT)

		row_panel.add_child(label)
		_entries_container.add_child(row_panel)

	# Player rank summary
	if player_rank > 0:
		var mode_names := ["diario", "endless", "normal", "boss rush"]
		if mode == Mode.ENDLESS or mode == Mode.BOSS_RUSH:
			var t := int(player_score)
			_player_rank_label.text = "Seu melhor (%s): #%d — %02d:%02d" % [
				mode_names[mode], player_rank, t / 60, t % 60]
		else:
			_player_rank_label.text = "Seu melhor (%s): #%d — %d pts" % [
				mode_names[mode], player_rank, player_score]
	else:
		_player_rank_label.text = ""


# ---------------------------------------------------------------------------
# Styling helpers
# ---------------------------------------------------------------------------

func _create_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = COLOR_PANEL
	sb.border_color = COLOR_BORDER
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(8)
	sb.content_margin_left = 16
	sb.content_margin_right = 16
	sb.content_margin_top = 12
	sb.content_margin_bottom = 12
	panel.add_theme_stylebox_override("panel", sb)
	return panel


func _style_tab_button(btn: Button, active: bool) -> void:
	var sb := StyleBoxFlat.new()
	if active:
		sb.bg_color = COLOR_TAB_ACTIVE
		sb.border_color = COLOR_GOLD_DIM
		sb.set_border_width_all(2)
		btn.add_theme_color_override("font_color", COLOR_GOLD)
	else:
		sb.bg_color = COLOR_TAB_INACTIVE
		sb.border_color = COLOR_BORDER
		sb.set_border_width_all(1)
		btn.add_theme_color_override("font_color", COLOR_SUBTITLE)
	sb.set_corner_radius_all(6)
	sb.content_margin_left = 16
	sb.content_margin_right = 16
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	btn.add_theme_stylebox_override("normal", sb)

	var sb_hover := sb.duplicate()
	sb_hover.bg_color = COLOR_BTN_HOVER
	sb_hover.border_color = COLOR_GOLD_DIM
	btn.add_theme_stylebox_override("hover", sb_hover)
	btn.add_theme_color_override("font_hover_color", COLOR_GOLD)


func _style_menu_button(btn: Button) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = COLOR_BTN_NORMAL
	sb.border_color = COLOR_BORDER
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(6)
	sb.content_margin_left = 20
	sb.content_margin_right = 20
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	btn.add_theme_stylebox_override("normal", sb)
	btn.add_theme_color_override("font_color", COLOR_TEXT)

	var sb_hover := sb.duplicate()
	sb_hover.bg_color = COLOR_BTN_HOVER
	sb_hover.border_color = COLOR_GOLD_DIM
	btn.add_theme_stylebox_override("hover", sb_hover)
	btn.add_theme_color_override("font_hover_color", COLOR_GOLD)


# ---------------------------------------------------------------------------
# Actions
# ---------------------------------------------------------------------------

func _on_tab_pressed(mode: int) -> void:
	AudioManager.play_sfx("menu_click")
	_show_mode(mode)


func _on_refresh() -> void:
	AudioManager.play_sfx("menu_click")
	# No futuro: request HTTP ao servidor
	# Por enquanto: regenera mock data
	_generate_mock_data()
	_show_mode(_current_mode)


func _on_back() -> void:
	AudioManager.play_sfx("menu_click")
	LoadingScreen.transition_to("res://scenes/ui/main_menu.tscn")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if get_viewport(): get_viewport().set_input_as_handled()
		_on_back()
