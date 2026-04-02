extends Control

## Tab "Registro dimensional" — detailed post-run stats breakdown.
## Built entirely in code to match the game_over_screen pattern.

var _vbox: VBoxContainer

func _ready() -> void:
	_build_ui()

func _build_ui() -> void:
	_vbox = VBoxContainer.new()
	_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_vbox.add_theme_constant_override("separation", 4)
	add_child(_vbox)

func populate(stats: Dictionary) -> void:
	# Clear previous content
	for child in _vbox.get_children():
		child.queue_free()

	# ── Combat section ──
	_add_section_header(LocaleManager.tr_key("stats_combat"))
	_add_stat_line(LocaleManager.tr_key("stats_total_damage"), _format_number(stats.get("total_damage_dealt", 0)))
	_add_stat_line(LocaleManager.tr_key("stats_damage_taken"), _format_number(stats.get("total_damage_taken", 0)))
	_add_stat_line(LocaleManager.tr_key("stats_dashes"), str(stats.get("dash_count", 0)))
	_add_stat_line(LocaleManager.tr_key("stats_overkill"), _format_number(stats.get("overkill_damage", 0)))
	_add_stat_line(LocaleManager.tr_key("stats_best_hit"), _format_number(stats.get("highest_single_hit", 0)))
	_add_stat_line(LocaleManager.tr_key("stats_peak_dps"), _format_number(int(stats.get("dps_peak", 0.0))))
	var streak = stats.get("longest_no_damage_streak", 0.0)
	if streak > 0:
		_add_stat_line(LocaleManager.tr_key("stats_no_damage_streak"), "%.1fs" % streak)

	# ── Weapons breakdown (sorted by damage) ──
	var dmg_per_weapon: Dictionary = stats.get("damage_per_weapon", {})
	if not dmg_per_weapon.is_empty():
		_add_section_header(LocaleManager.tr_key("stats_weapons"))
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
			if rank > 6:
				break  # Limit to top 6 to fit screen
			var w_data = WeaponDB.weapons.get(entry["id"], {})
			var wname = w_data.get("name", entry["id"])
			var pct = 0.0
			if total_dmg > 0:
				pct = (entry["damage"] / total_dmg) * 100.0
			_add_weapon_bar(rank, wname, int(entry["damage"]), pct)
			rank += 1

	# ── Synergies section ──
	var syn_procs: Dictionary = stats.get("synergy_procs", {})
	if not syn_procs.is_empty():
		_add_section_header(LocaleManager.tr_key("stats_synergies"))
		var syn_damage: Dictionary = stats.get("synergy_damage", {})
		for syn_name in syn_procs:
			var procs = syn_procs[syn_name]
			var dmg = syn_damage.get(syn_name, 0)
			var display_name = syn_name.capitalize()
			var text = "%s: %d %s (%s %s)" % [
				display_name,
				procs,
				LocaleManager.tr_key("stats_procs"),
				_format_number(dmg),
				LocaleManager.tr_key("stats_synergy_damage"),
			]
			_add_info_label(text)

	# ── Economy section ──
	_add_section_header(LocaleManager.tr_key("stats_economy"))
	var econ_parts: Array[String] = []
	econ_parts.append("XP: %s" % _format_number(stats.get("xp_collected", 0)))
	econ_parts.append("%s: %d" % [LocaleManager.tr_key("stats_chests_opened"), stats.get("chests_opened", 0)])
	econ_parts.append("%s: %d" % [LocaleManager.tr_key("stats_hp_pickups"), stats.get("health_pickups_used", 0)])
	econ_parts.append("%s: %d" % [LocaleManager.tr_key("stats_magnets"), stats.get("magnets_collected", 0)])
	_add_info_label("  |  ".join(econ_parts))


# ---------------------------------------------------------------------------
# UI building helpers
# ---------------------------------------------------------------------------

func _add_section_header(text: String) -> void:
	var sep = HSeparator.new()
	sep.add_theme_constant_override("separation", 2)
	_vbox.add_child(sep)
	var lbl = Label.new()
	lbl.text = "── %s ──" % text
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.add_theme_color_override("font_color", Color(0.9, 0.8, 0.5))
	_vbox.add_child(lbl)

func _add_stat_line(label_text: String, value_text: String) -> void:
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)
	var lbl = Label.new()
	lbl.text = label_text
	lbl.add_theme_font_size_override("font_size", 12)
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(lbl)
	var val = Label.new()
	val.text = value_text
	val.add_theme_font_size_override("font_size", 12)
	val.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hbox.add_child(val)
	_vbox.add_child(hbox)

func _add_weapon_bar(rank: int, wname: String, damage: int, pct: float) -> void:
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 4)
	hbox.custom_minimum_size.y = 16

	# Rank + name + damage
	var lbl = Label.new()
	lbl.text = "%d. %s  %s (%d%%)" % [rank, wname, _format_number(damage), int(pct)]
	lbl.add_theme_font_size_override("font_size", 11)
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(lbl)

	# Percentage bar
	var bar_bg = Panel.new()
	bar_bg.custom_minimum_size = Vector2(100, 12)
	bar_bg.size_flags_horizontal = Control.SIZE_SHRINK_END

	var style_bg = StyleBoxFlat.new()
	style_bg.bg_color = Color(0.2, 0.2, 0.2, 0.8)
	style_bg.corner_radius_top_left = 2
	style_bg.corner_radius_top_right = 2
	style_bg.corner_radius_bottom_left = 2
	style_bg.corner_radius_bottom_right = 2
	bar_bg.add_theme_stylebox_override("panel", style_bg)

	var bar_fill = Panel.new()
	var fill_width = maxf(2.0, 100.0 * (pct / 100.0))
	bar_fill.custom_minimum_size = Vector2(fill_width, 12)
	bar_fill.position = Vector2.ZERO
	bar_fill.size = Vector2(fill_width, 12)

	var style_fill = StyleBoxFlat.new()
	# Color gradient from green (top) to red (lower ranks)
	var bar_color: Color
	if rank <= 1:
		bar_color = Color(0.3, 0.9, 0.4)
	elif rank <= 3:
		bar_color = Color(0.4, 0.7, 0.9)
	else:
		bar_color = Color(0.6, 0.5, 0.8)
	style_fill.bg_color = bar_color
	style_fill.corner_radius_top_left = 2
	style_fill.corner_radius_top_right = 2
	style_fill.corner_radius_bottom_left = 2
	style_fill.corner_radius_bottom_right = 2
	bar_fill.add_theme_stylebox_override("panel", style_fill)

	bar_bg.add_child(bar_fill)
	hbox.add_child(bar_bg)
	_vbox.add_child(hbox)

func _add_info_label(text: String) -> void:
	var lbl = Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 11)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	_vbox.add_child(lbl)

func _format_number(value) -> String:
	var n := int(value)
	if n >= 1000000:
		return "%.1fM" % (n / 1000000.0)
	elif n >= 1000:
		return "%.1fK" % (n / 1000.0)
	return str(n)
