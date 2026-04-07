extends Control

## PRD 59 — Expanded post-run stats panel with two tabs: Combate and Resumo.
## Usage: PostRunStats.show_stats() creates and displays the panel as an overlay.
## Press any key or click to dismiss (after 1s delay).

const BG_COLOR := Color(0.06, 0.06, 0.1, 0.92)
const GOLD := Color(1.0, 0.85, 0.3)
const TEXT_COLOR := Color(0.9, 0.9, 0.95)
const LABEL_COLOR := Color(0.7, 0.7, 0.8)
const SEPARATOR_COLOR := Color(1.0, 0.85, 0.3, 0.4)

const GRADE_COLORS := {
	"S": Color(1.0, 0.85, 0.3),
	"A": Color(0.3, 0.9, 0.4),
	"B": Color(0.4, 0.7, 0.9),
	"C": Color(0.6, 0.6, 0.7),
	"D": Color(0.9, 0.3, 0.3),
}

const PANEL_SIZE := Vector2(520, 420)

var _current_tab: int = 0
var _can_close: bool = false
var _canvas_layer: CanvasLayer = null

# Tab containers
var _tab_combate_container: VBoxContainer = null
var _tab_resumo_container: VBoxContainer = null
var _tab_combate_btn: Button = null
var _tab_resumo_btn: Button = null


## Static entry point — creates the panel, adds it to the scene tree, and shows it.
static func show_stats() -> Control:
	var scene_root = Engine.get_main_loop().current_scene
	if not scene_root:
		return null

	var canvas := CanvasLayer.new()
	canvas.layer = 100
	scene_root.add_child(canvas)

	var script_res = load("res://scripts/ui/post_run_stats.gd")
	var instance := Control.new()
	instance.set_script(script_res)
	instance._canvas_layer = canvas
	canvas.add_child(instance)
	return instance


func _ready() -> void:
	# Full-screen anchor
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP

	_build_ui()

	# Delay before allowing close
	await get_tree().create_timer(1.0).timeout
	_can_close = true


func _build_ui() -> void:
	# Dark overlay background
	var overlay := ColorRect.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.color = BG_COLOR
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(overlay)

	# Centered panel
	var panel := PanelContainer.new()
	panel.custom_minimum_size = PANEL_SIZE
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.offset_left = -PANEL_SIZE.x / 2.0
	panel.offset_right = PANEL_SIZE.x / 2.0
	panel.offset_top = -PANEL_SIZE.y / 2.0
	panel.offset_bottom = PANEL_SIZE.y / 2.0

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.08, 0.08, 0.14, 0.95)
	panel_style.border_color = GOLD * Color(1, 1, 1, 0.5)
	panel_style.border_width_top = 2
	panel_style.border_width_bottom = 2
	panel_style.border_width_left = 2
	panel_style.border_width_right = 2
	panel_style.corner_radius_top_left = 8
	panel_style.corner_radius_top_right = 8
	panel_style.corner_radius_bottom_left = 8
	panel_style.corner_radius_bottom_right = 8
	panel_style.content_margin_left = 16
	panel_style.content_margin_right = 16
	panel_style.content_margin_top = 12
	panel_style.content_margin_bottom = 12
	panel.add_theme_stylebox_override("panel", panel_style)
	add_child(panel)

	var main_vbox := VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 6)
	panel.add_child(main_vbox)

	# Title
	var title := Label.new()
	title.text = _get_title_text()
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", GOLD)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(title)

	# Tab bar
	var tab_bar := HBoxContainer.new()
	tab_bar.alignment = BoxContainer.ALIGNMENT_CENTER
	tab_bar.add_theme_constant_override("separation", 8)
	main_vbox.add_child(tab_bar)

	_tab_combate_btn = _make_tab_button(_tr("Combate", "Combat"), 0)
	tab_bar.add_child(_tab_combate_btn)

	_tab_resumo_btn = _make_tab_button(_tr("Resumo", "Summary"), 1)
	tab_bar.add_child(_tab_resumo_btn)

	var sep := HSeparator.new()
	sep.add_theme_constant_override("separation", 2)
	main_vbox.add_child(sep)

	# Scroll container for tab content
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	main_vbox.add_child(scroll)

	var scroll_vbox := VBoxContainer.new()
	scroll_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll_vbox.add_theme_constant_override("separation", 4)
	scroll.add_child(scroll_vbox)

	# Build tab contents
	_tab_combate_container = VBoxContainer.new()
	_tab_combate_container.add_theme_constant_override("separation", 4)
	_tab_combate_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll_vbox.add_child(_tab_combate_container)
	_build_combate_tab()

	_tab_resumo_container = VBoxContainer.new()
	_tab_resumo_container.add_theme_constant_override("separation", 4)
	_tab_resumo_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll_vbox.add_child(_tab_resumo_container)
	_build_resumo_tab()

	# Close hint
	var hint := Label.new()
	hint.text = _tr("Pressione qualquer tecla para fechar", "Press any key to close")
	hint.add_theme_font_size_override("font_size", 10)
	hint.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6, 0.7))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(hint)

	# Default tab
	_switch_tab(0)


# ---------------------------------------------------------------------------
# Tab: Combate
# ---------------------------------------------------------------------------

func _build_combate_tab() -> void:
	var vbox := _tab_combate_container
	var stats := GameManager.get_run_stats()

	# DPS average
	var avg_dps := 0.0
	if GameManager.game_time > 0:
		avg_dps = float(GameManager.total_damage_dealt) / GameManager.game_time

	_add_section_header(vbox, _tr("Estatisticas de combate", "Combat statistics"))

	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 3)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	_add_stat_row(grid, _tr("Dano total", "Total damage"), _format_number(GameManager.total_damage_dealt))
	_add_stat_row(grid, _tr("Kills totais", "Total kills"), str(GameManager.total_kills))
	_add_stat_row(grid, _tr("DPS medio", "Average DPS"), "%.1f/s" % avg_dps, avg_dps > 200.0)
	_add_stat_row(grid, _tr("Pico DPS", "Peak DPS"), _format_number(int(stats.get("dps_peak", 0.0))), stats.get("dps_peak", 0.0) > 500.0)
	_add_stat_row(grid, _tr("Maior hit", "Best hit"), _format_number(stats.get("highest_single_hit", 0)), stats.get("highest_single_hit", 0) > 1000)

	vbox.add_child(grid)

	# Weapon ranking by damage — top 3
	var dmg_per_weapon: Dictionary = stats.get("damage_per_weapon", {})
	if not dmg_per_weapon.is_empty():
		_add_section_header(vbox, _tr("Ranking de armas (dano)", "Weapon ranking (damage)"))

		var total_dmg: float = 0.0
		for wid in dmg_per_weapon:
			total_dmg += dmg_per_weapon[wid]

		# Sort weapons by damage descending
		var weapon_list: Array = []
		for wid in dmg_per_weapon:
			weapon_list.append({"id": wid, "damage": dmg_per_weapon[wid]})
		weapon_list.sort_custom(func(a, b): return a["damage"] > b["damage"])

		var rank := 1
		for entry in weapon_list:
			if rank > 3:
				break
			var w_data = WeaponDB.weapons.get(entry["id"], {})
			var wname = w_data.get("name", entry["id"])
			var pct := 0.0
			if total_dmg > 0:
				pct = (entry["damage"] / total_dmg) * 100.0
			_add_weapon_bar(vbox, rank, wname, int(entry["damage"]), pct)
			rank += 1

	# Synergy stats
	var syn_procs: Dictionary = SynergySystem.synergy_proc_counts.duplicate() if SynergySystem else {}
	var syn_damage: Dictionary = SynergySystem.synergy_total_damage.duplicate() if SynergySystem else {}
	if not syn_procs.is_empty():
		_add_section_header(vbox, _tr("Sinergias", "Synergies"))
		for syn_name in syn_procs:
			var procs: int = syn_procs[syn_name]
			var dmg: float = syn_damage.get(syn_name, 0.0)
			var display_name: String = syn_name.capitalize()
			var line := "%s: %d procs, %s %s" % [
				display_name,
				procs,
				_format_number(int(dmg)),
				_tr("dano", "damage"),
			]
			_add_info_label(vbox, line)


# ---------------------------------------------------------------------------
# Tab: Resumo
# ---------------------------------------------------------------------------

func _build_resumo_tab() -> void:
	var vbox := _tab_resumo_container
	var stats := GameManager.get_run_stats()

	# Grade calculation and display
	var grade := _calculate_grade()
	var grade_color: Color = GRADE_COLORS.get(grade, Color.WHITE)

	var grade_label := Label.new()
	grade_label.text = grade
	grade_label.add_theme_font_size_override("font_size", 48)
	grade_label.add_theme_color_override("font_color", grade_color)
	grade_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(grade_label)

	var grade_desc := Label.new()
	grade_desc.text = _get_grade_description(grade)
	grade_desc.add_theme_font_size_override("font_size", 11)
	grade_desc.add_theme_color_override("font_color", grade_color * Color(1, 1, 1, 0.7))
	grade_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(grade_desc)

	# Victory/defeat
	var status_label := Label.new()
	if GameManager.is_victory:
		status_label.text = _tr("Vitoria!", "Victory!")
		status_label.add_theme_color_override("font_color", Color(0.3, 0.9, 0.4))
	else:
		status_label.text = _tr("Derrota", "Defeat")
		status_label.add_theme_color_override("font_color", Color(0.9, 0.3, 0.3))
	status_label.add_theme_font_size_override("font_size", 14)
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(status_label)

	_add_section_header(vbox, _tr("Resumo da run", "Run summary"))

	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 3)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	# Time survived
	var t := int(GameManager.game_time)
	var time_str := "%02d:%02d" % [t / 60, t % 60]
	_add_stat_row(grid, _tr("Tempo sobrevivido", "Time survived"), time_str)

	# Highest level
	_add_stat_row(grid, _tr("Nivel alcancado", "Level reached"), str(GameManager.player_level), GameManager.player_level >= 15)

	# Crystals earned
	_add_stat_row(grid, _tr("Cristais ganhos", "Crystals earned"), str(GameManager.crystals_this_run), GameManager.crystals_this_run > 300)

	# Near-deaths
	var near := GameManager.near_deaths
	if near > 0:
		_add_stat_row(grid, _tr("Quase-mortes", "Near-deaths"), str(near), true)

	# No-damage streak
	var streak: float = stats.get("longest_no_damage_streak", 0.0)
	if streak > 0:
		var streak_str: String
		if streak >= 60.0:
			streak_str = "%dm %ds" % [int(streak) / 60, int(streak) % 60]
		else:
			streak_str = "%.1fs" % streak
		_add_stat_row(grid, _tr("Sem dano (max)", "No damage (max)"), streak_str, streak > 30.0)

	# Chests opened
	_add_stat_row(grid, _tr("Baus abertos", "Chests opened"), str(stats.get("chests_opened", 0)))

	# XP collected
	_add_stat_row(grid, _tr("XP coletado", "XP collected"), _format_number(stats.get("xp_collected", 0)))

	vbox.add_child(grid)


# ---------------------------------------------------------------------------
# Grade calculation
# ---------------------------------------------------------------------------

func _calculate_grade() -> String:
	var victory := GameManager.is_victory
	var avg_dps := 0.0
	if GameManager.game_time > 0:
		avg_dps = float(GameManager.total_damage_dealt) / GameManager.game_time
	var kills := GameManager.total_kills
	var time_survived := GameManager.game_time

	# S: victory + high efficiency
	if victory and avg_dps > 500.0 and kills > 500:
		return "S"

	# A: victory or strong performance
	if victory or (avg_dps > 300.0 and kills > 300):
		return "A"

	# B: survived long enough with decent kills
	if time_survived > 600.0 and kills > 500:
		return "B"

	# C: survived a reasonable time
	if time_survived > 300.0 and kills > 200:
		return "C"

	return "D"


func _get_grade_description(grade: String) -> String:
	match grade:
		"S":
			return _tr("Restauracao perfeita", "Perfect restoration")
		"A":
			return _tr("Restauracao notavel", "Notable restoration")
		"B":
			return _tr("Restauracao parcial", "Partial restoration")
		"C":
			return _tr("Fragmento instavel", "Unstable fragment")
		_:
			return _tr("Fragmento perdido", "Lost fragment")


# ---------------------------------------------------------------------------
# Tab switching
# ---------------------------------------------------------------------------

func _switch_tab(idx: int) -> void:
	_current_tab = idx

	var active_color := GOLD
	var inactive_color := Color(0.6, 0.6, 0.7)

	_tab_combate_btn.add_theme_color_override("font_color", active_color if idx == 0 else inactive_color)
	_tab_resumo_btn.add_theme_color_override("font_color", active_color if idx == 1 else inactive_color)

	_tab_combate_container.visible = (idx == 0)
	_tab_resumo_container.visible = (idx == 1)


func _make_tab_button(text: String, tab_idx: int) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.add_theme_font_size_override("font_size", 13)
	btn.custom_minimum_size = Vector2(120, 30)
	btn.flat = true
	btn.pressed.connect(_switch_tab.bind(tab_idx))
	btn.mouse_filter = Control.MOUSE_FILTER_STOP
	return btn


# ---------------------------------------------------------------------------
# Input — close on any key/click after delay
# ---------------------------------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	if not _can_close:
		return

	# Ignore tab button clicks
	if event is InputEventMouseButton and event.pressed:
		_close()
	elif event is InputEventKey and event.pressed:
		# Do not close on Tab (used for tab switching)
		if event.keycode == KEY_TAB:
			_switch_tab(1 - _current_tab)
			get_viewport().set_input_as_handled()
			return
		_close()


func _close() -> void:
	if get_viewport():
		get_viewport().set_input_as_handled()
	if _canvas_layer and is_instance_valid(_canvas_layer):
		_canvas_layer.queue_free()
	else:
		queue_free()


# ---------------------------------------------------------------------------
# UI helpers
# ---------------------------------------------------------------------------

func _add_section_header(parent: VBoxContainer, text: String) -> void:
	var sep := HSeparator.new()
	sep.add_theme_constant_override("separation", 2)
	parent.add_child(sep)

	var lbl := Label.new()
	lbl.text = "-- %s --" % text
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.add_theme_color_override("font_color", GOLD * Color(1, 1, 1, 0.8))
	parent.add_child(lbl)


func _add_stat_row(grid: GridContainer, label_text: String, value_text: String, highlight: bool = false) -> void:
	var label := Label.new()
	label.text = label_text
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", LABEL_COLOR)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_child(label)

	var value := Label.new()
	value.text = value_text
	value.add_theme_font_size_override("font_size", 12)
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value.add_theme_color_override("font_color", GOLD if highlight else TEXT_COLOR)
	grid.add_child(value)


func _add_weapon_bar(parent: VBoxContainer, rank: int, wname: String, damage: int, pct: float) -> void:
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 4)
	hbox.custom_minimum_size.y = 18
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	# Rank + name + damage
	var lbl := Label.new()
	lbl.text = "%d. %s  %s (%d%%)" % [rank, wname, _format_number(damage), int(pct)]
	lbl.add_theme_font_size_override("font_size", 11)
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(lbl)

	# Progress bar
	var bar_bg := Panel.new()
	bar_bg.custom_minimum_size = Vector2(120, 14)
	bar_bg.size_flags_horizontal = Control.SIZE_SHRINK_END

	var style_bg := StyleBoxFlat.new()
	style_bg.bg_color = Color(0.2, 0.2, 0.2, 0.8)
	style_bg.corner_radius_top_left = 3
	style_bg.corner_radius_top_right = 3
	style_bg.corner_radius_bottom_left = 3
	style_bg.corner_radius_bottom_right = 3
	bar_bg.add_theme_stylebox_override("panel", style_bg)

	var bar_fill := Panel.new()
	var fill_width := maxf(3.0, 120.0 * (pct / 100.0))
	bar_fill.custom_minimum_size = Vector2(fill_width, 14)
	bar_fill.position = Vector2.ZERO
	bar_fill.size = Vector2(fill_width, 14)

	var style_fill := StyleBoxFlat.new()
	var bar_color: Color
	if rank == 1:
		bar_color = Color(0.3, 0.9, 0.4)  # Green for #1
	elif rank == 2:
		bar_color = Color(0.4, 0.7, 0.9)  # Blue for #2
	else:
		bar_color = Color(0.6, 0.5, 0.8)  # Purple for #3
	style_fill.bg_color = bar_color
	style_fill.corner_radius_top_left = 3
	style_fill.corner_radius_top_right = 3
	style_fill.corner_radius_bottom_left = 3
	style_fill.corner_radius_bottom_right = 3
	bar_fill.add_theme_stylebox_override("panel", style_fill)

	bar_bg.add_child(bar_fill)
	hbox.add_child(bar_bg)
	parent.add_child(hbox)


func _add_info_label(parent: VBoxContainer, text: String) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 11)
	lbl.add_theme_color_override("font_color", TEXT_COLOR)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	parent.add_child(lbl)


func _format_number(n: int) -> String:
	if n >= 1000000:
		return "%.1fM" % (float(n) / 1000000.0)
	elif n >= 10000:
		return "%.1fK" % (float(n) / 1000.0)
	return str(n)


## Simple bilingual text helper. Returns pt_BR or en based on LocaleManager.
func _tr(pt: String, en: String) -> String:
	if LocaleManager and LocaleManager.current_locale == "en":
		return en
	return pt


func _get_title_text() -> String:
	return _tr("Estatisticas da run", "Run statistics")
