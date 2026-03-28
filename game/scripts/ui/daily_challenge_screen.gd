extends Control

## Tela do Desafio Diario — mostra info do dia, personagem fixo, arma inicial,
## mutacoes ativas, streak, countdown ate reset, e leaderboard local (top 10).

# --- Colors (matching main_menu theme) ---
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

# --- Node refs (built programmatically) ---
var _title_label: Label
var _countdown_label: Label
var _stage_label: Label
var _character_label: Label
var _weapon_label: Label
var _mutations_label: Label
var _streak_label: Label
var _best_score_label: Label
var _play_btn: Button
var _leaderboard_container: VBoxContainer
var _leaderboard_title: Label
var _status_label: Label
var _back_btn: Button


func _ready() -> void:
	get_tree().paused = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	_populate_daily_info()
	_populate_local_leaderboard()
	GamepadUI.notify_menu_opened()


func _process(_delta: float) -> void:
	_update_countdown()


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

	# Main scroll container
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
	main_vbox.add_theme_constant_override("separation", 16)
	scroll.add_child(main_vbox)

	# Title
	_title_label = Label.new()
	_title_label.text = "Desafio diario"
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.add_theme_font_size_override("font_size", 36)
	_title_label.add_theme_color_override("font_color", COLOR_GOLD)
	main_vbox.add_child(_title_label)

	# Countdown
	_countdown_label = Label.new()
	_countdown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_countdown_label.add_theme_font_size_override("font_size", 14)
	_countdown_label.add_theme_color_override("font_color", COLOR_SUBTITLE)
	main_vbox.add_child(_countdown_label)

	# --- Info panel ---
	var info_panel := _create_panel()
	main_vbox.add_child(info_panel)

	var info_vbox := VBoxContainer.new()
	info_vbox.add_theme_constant_override("separation", 10)
	info_panel.add_child(info_vbox)

	# Stage
	_stage_label = _create_info_label()
	info_vbox.add_child(_stage_label)

	# Character (fixed for the day)
	_character_label = _create_info_label()
	info_vbox.add_child(_character_label)

	# Starting weapon
	_weapon_label = _create_info_label()
	info_vbox.add_child(_weapon_label)

	# Mutations
	_mutations_label = _create_info_label()
	info_vbox.add_child(_mutations_label)

	# --- Streak panel ---
	var streak_panel := _create_panel()
	main_vbox.add_child(streak_panel)

	var streak_hbox := HBoxContainer.new()
	streak_hbox.add_theme_constant_override("separation", 20)
	streak_panel.add_child(streak_hbox)

	_streak_label = _create_info_label()
	streak_hbox.add_child(_streak_label)

	_best_score_label = _create_info_label()
	streak_hbox.add_child(_best_score_label)

	# --- Status ---
	_status_label = Label.new()
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_label.add_theme_font_size_override("font_size", 16)
	main_vbox.add_child(_status_label)

	# --- Play button ---
	_play_btn = Button.new()
	_play_btn.text = "Jogar desafio diario"
	_play_btn.custom_minimum_size = Vector2(300, 52)
	_play_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_play_btn.focus_mode = Control.FOCUS_ALL
	_play_btn.add_theme_font_size_override("font_size", 20)
	_style_play_button(_play_btn)
	_play_btn.pressed.connect(_on_play)
	main_vbox.add_child(_play_btn)

	# --- Local Leaderboard ---
	_leaderboard_title = Label.new()
	_leaderboard_title.text = "Top 10 de hoje"
	_leaderboard_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_leaderboard_title.add_theme_font_size_override("font_size", 22)
	_leaderboard_title.add_theme_color_override("font_color", COLOR_GOLD)
	main_vbox.add_child(_leaderboard_title)

	var lb_panel := _create_panel()
	main_vbox.add_child(lb_panel)

	_leaderboard_container = VBoxContainer.new()
	_leaderboard_container.add_theme_constant_override("separation", 4)
	lb_panel.add_child(_leaderboard_container)

	# --- Back button ---
	_back_btn = Button.new()
	_back_btn.text = "Voltar"
	_back_btn.custom_minimum_size = Vector2(200, 44)
	_back_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_back_btn.focus_mode = Control.FOCUS_ALL
	_back_btn.add_theme_font_size_override("font_size", 16)
	_style_menu_button(_back_btn)
	_back_btn.pressed.connect(_on_back)
	main_vbox.add_child(_back_btn)



# ---------------------------------------------------------------------------
# Daily info
# ---------------------------------------------------------------------------

func _populate_daily_info() -> void:
	# Stage
	var stage := DailyChallenge.get_daily_stage()
	var stage_display := stage.replace("_", " ").capitalize()
	_stage_label.text = "Fase: %s" % stage_display

	# Fixed character for the day
	var char_id := DailyChallenge.get_daily_character()
	var char_data: Dictionary = CharacterDB.get_character(char_id)
	var char_name: String = char_data.get("name", char_id.capitalize())
	_character_label.text = "Personagem: %s" % char_name
	_character_label.add_theme_color_override("font_color", COLOR_ACCENT)

	# Starting weapon
	var weapon_id := DailyChallenge.get_daily_starting_weapon()
	var weapon_data: Dictionary = WeaponDB.get_weapon(weapon_id)
	var weapon_name: String = weapon_data.get("name", weapon_id.capitalize())
	_weapon_label.text = "Arma inicial: %s" % weapon_name

	# Mutations
	var mutations := DailyChallenge.get_daily_mutations()
	if mutations.is_empty():
		_mutations_label.text = "Mutacoes: nenhuma"
		_mutations_label.add_theme_color_override("font_color", COLOR_GREEN)
	else:
		var mut_names: Array[String] = []
		for mut_id in mutations:
			mut_names.append(mut_id.replace("_", " ").capitalize())
		_mutations_label.text = "Mutacoes: %s" % ", ".join(mut_names)
		_mutations_label.add_theme_color_override("font_color", COLOR_RED)

	# Streak
	var streak := DailyChallenge.get_streak()
	var best_streak := DailyChallenge.get_best_streak()
	_streak_label.text = "Sequencia: %d dias" % streak
	if streak >= 3:
		_streak_label.add_theme_color_override("font_color", COLOR_GOLD)
	_best_score_label.text = "Melhor sequencia: %d dias" % best_streak

	# Best score today
	var best := DailyChallenge.get_today_best_score()
	if not best.is_empty():
		_best_score_label.text += "\nMelhor hoje: %d pts" % best.get("score", 0)

	# Scoring formula hint
	_status_label.add_theme_font_size_override("font_size", 13)

	# Play availability
	if DailyChallenge.can_play_daily():
		_play_btn.disabled = false
		_status_label.text = "Score = kills x 10 + tempo (s) + cristais"
		_status_label.add_theme_color_override("font_color", COLOR_SUBTITLE)
	else:
		_play_btn.disabled = true
		_status_label.text = "Desafio ja completado hoje"
		_status_label.add_theme_color_override("font_color", COLOR_RED)


func _update_countdown() -> void:
	var secs := DailyChallenge.get_time_until_reset()
	var h := secs / 3600
	var m := (secs % 3600) / 60
	var s := secs % 60
	_countdown_label.text = "Proximo desafio em %02d:%02d:%02d" % [h, m, s]


# ---------------------------------------------------------------------------
# Local leaderboard (top 10)
# ---------------------------------------------------------------------------

func _populate_local_leaderboard() -> void:
	## Mostra o top 10 local para o dia de hoje.
	for child in _leaderboard_container.get_children():
		child.queue_free()

	var scores := DailyChallenge.get_leaderboard()
	if scores.is_empty():
		var empty_label := Label.new()
		empty_label.text = "Nenhum score hoje. Seja o primeiro!"
		empty_label.add_theme_color_override("font_color", COLOR_SUBTITLE)
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_leaderboard_container.add_child(empty_label)
		return

	# Header
	var header := Label.new()
	header.text = "  #   |  Score  |  Kills  |  Tempo   |  Personagem"
	header.add_theme_font_size_override("font_size", 14)
	header.add_theme_color_override("font_color", COLOR_SUBTITLE)
	_leaderboard_container.add_child(header)

	var sep := HSeparator.new()
	_leaderboard_container.add_child(sep)

	var rank_colors := [
		Color(1.0, 0.85, 0.2),   # Gold
		Color(0.8, 0.8, 0.8),    # Silver
		Color(0.8, 0.5, 0.2),    # Bronze
	]

	for i in range(mini(scores.size(), 10)):
		var entry: Dictionary = scores[i]
		var total_score: int = entry.get("score", 0)
		var kills: int = entry.get("kills", 0)
		var t := int(entry.get("time", 0))
		var time_str := "%02d:%02d" % [t / 60, t % 60]
		var character: String = entry.get("character", "???")

		var label := Label.new()
		label.text = "  %d   |  %d  |  %d  |  %s   |  %s" % [i + 1, total_score, kills, time_str, character.capitalize()]
		label.add_theme_font_size_override("font_size", 15)

		if i < rank_colors.size():
			label.add_theme_color_override("font_color", rank_colors[i])
		else:
			label.add_theme_color_override("font_color", COLOR_TEXT)

		_leaderboard_container.add_child(label)


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
	sb.content_margin_left = 20
	sb.content_margin_right = 20
	sb.content_margin_top = 14
	sb.content_margin_bottom = 14
	panel.add_theme_stylebox_override("panel", sb)
	return panel


func _create_info_label() -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", COLOR_TEXT)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label


func _style_play_button(btn: Button) -> void:
	var sb_normal := StyleBoxFlat.new()
	sb_normal.bg_color = Color(0.15, 0.35, 0.15)
	sb_normal.border_color = COLOR_GREEN
	sb_normal.set_border_width_all(2)
	sb_normal.set_corner_radius_all(8)
	sb_normal.content_margin_left = 24
	sb_normal.content_margin_right = 24
	sb_normal.content_margin_top = 10
	sb_normal.content_margin_bottom = 10
	btn.add_theme_stylebox_override("normal", sb_normal)
	btn.add_theme_color_override("font_color", COLOR_GREEN)

	var sb_hover := sb_normal.duplicate()
	sb_hover.bg_color = Color(0.2, 0.45, 0.2)
	btn.add_theme_stylebox_override("hover", sb_hover)
	btn.add_theme_color_override("font_hover_color", Color(0.5, 1.0, 0.5))

	var sb_pressed := sb_normal.duplicate()
	sb_pressed.bg_color = Color(0.1, 0.25, 0.1)
	btn.add_theme_stylebox_override("pressed", sb_pressed)

	var sb_disabled := StyleBoxFlat.new()
	sb_disabled.bg_color = Color(0.08, 0.08, 0.10)
	sb_disabled.border_color = Color(0.15, 0.15, 0.18)
	sb_disabled.set_border_width_all(1)
	sb_disabled.set_corner_radius_all(8)
	sb_disabled.content_margin_left = 24
	sb_disabled.content_margin_right = 24
	sb_disabled.content_margin_top = 10
	sb_disabled.content_margin_bottom = 10
	btn.add_theme_stylebox_override("disabled", sb_disabled)
	btn.add_theme_color_override("font_disabled_color", Color(0.35, 0.35, 0.40))


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

func _on_play() -> void:
	AudioManager.play_sfx("menu_click")
	if not DailyChallenge.can_play_daily():
		return
	# Character is fixed by the daily seed — start_daily_run sets it automatically
	DailyChallenge.start_daily_run()


func _on_back() -> void:
	AudioManager.play_sfx("menu_click")
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if get_viewport(): get_viewport().set_input_as_handled()
		_on_back()
