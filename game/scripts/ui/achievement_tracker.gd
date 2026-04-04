extends Control

## Achievement progress tracker HUD — shows nearest achievements with progress bars.
## Mini-tracker (1-3 items) top-left. Tab expands to full overlay list.

# -- Mini tracker items --
var _tracker_items: Array[Dictionary] = []  # {panel, name_label, progress_label, bar, percent_label, target_bar_value}
var _tracker_data: Array[Dictionary] = []  # current nearest achievements

# -- Expanded overlay --
var _expanded_panel: PanelContainer = null
var _expanded_vbox: VBoxContainer = null
var _expanded_visible: bool = false

# -- "Almost there" notification --
var _almost_notified: Dictionary = {}  # achievement_id -> true (once per session)
var _almost_panel: PanelContainer = null
var _almost_timer: float = 0.0

# -- Update timer --
var _update_timer: float = 0.0

# -- Lerp targets for smooth bars --
var _bar_targets: Array[float] = []

# -- Colors --
const COLOR_GOLD = Color(1.0, 0.85, 0.2)
const COLOR_GREEN = Color(0.3, 1.0, 0.4)
const COLOR_GRAY = Color(0.5, 0.5, 0.5)
const COLOR_BAR_BG = Color(0.15, 0.15, 0.18)
const COLOR_BAR_FILL = Color(1.0, 0.85, 0.2)
const COLOR_ALMOST_BORDER = Color(1.0, 0.85, 0.2)

func _ready() -> void:
	# Position: top-left below quest tracker area
	anchor_left = 0.0
	anchor_top = 0.0
	anchor_right = 0.0
	anchor_bottom = 0.0
	offset_left = 10.0
	offset_top = 90.0
	offset_right = 10.0 + GameConstants.ACH_TRACKER_WIDTH
	offset_bottom = 90.0 + GameConstants.ACH_TRACKER_ITEM_HEIGHT * GameConstants.ACH_TRACKER_MAX_VISIBLE + 16
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	_build_mini_tracker()
	_build_expanded_overlay()
	_build_almost_notification()

	# Connect achievement unlocked signal
	AchievementManager.achievement_unlocked.connect(_on_achievement_unlocked)

	# Initial data load
	_refresh_tracker_data()

func _build_mini_tracker() -> void:
	for i in range(GameConstants.ACH_TRACKER_MAX_VISIBLE):
		var panel = PanelContainer.new()
		panel.name = "TrackerItem%d" % i
		panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.custom_minimum_size = Vector2(GameConstants.ACH_TRACKER_WIDTH, GameConstants.ACH_TRACKER_ITEM_HEIGHT)
		panel.position = Vector2(0, i * (GameConstants.ACH_TRACKER_ITEM_HEIGHT + 2))
		panel.visible = false

		var bg = StyleBoxFlat.new()
		bg.bg_color = Color(0.0, 0.0, 0.0, GameConstants.ACH_TRACKER_BG_ALPHA)
		bg.set_corner_radius_all(6)
		bg.content_margin_left = 4
		bg.content_margin_right = 4
		bg.content_margin_top = 2
		bg.content_margin_bottom = 2
		panel.add_theme_stylebox_override("panel", bg)

		var hbox = HBoxContainer.new()
		hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hbox.add_theme_constant_override("separation", 4)
		panel.add_child(hbox)

		# Trophy icon
		var icon_label = Label.new()
		icon_label.text = "T"  # Trophy placeholder (no emoji per rules)
		icon_label.add_theme_font_size_override("font_size", 10)
		icon_label.add_theme_color_override("font_color", COLOR_GOLD)
		icon_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hbox.add_child(icon_label)

		# Name
		var name_label = Label.new()
		name_label.name = "NameLabel"
		name_label.add_theme_font_size_override("font_size", GameConstants.ACH_TRACKER_FONT_SIZE_NAME)
		name_label.add_theme_color_override("font_color", Color.WHITE)
		name_label.custom_minimum_size = Vector2(80, 0)
		name_label.clip_text = true
		name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hbox.add_child(name_label)

		# Progress text ("8.4K/10K")
		var progress_label = Label.new()
		progress_label.name = "ProgressLabel"
		progress_label.add_theme_font_size_override("font_size", GameConstants.ACH_TRACKER_FONT_SIZE_PROGRESS)
		progress_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		progress_label.custom_minimum_size = Vector2(50, 0)
		progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		progress_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hbox.add_child(progress_label)

		# Progress bar
		var bar = ProgressBar.new()
		bar.name = "Bar"
		bar.custom_minimum_size = Vector2(GameConstants.ACH_TRACKER_BAR_WIDTH, GameConstants.ACH_TRACKER_BAR_HEIGHT)
		bar.show_percentage = false
		bar.max_value = 1.0
		bar.value = 0.0
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE

		var fill = StyleBoxFlat.new()
		fill.bg_color = COLOR_BAR_FILL
		fill.set_corner_radius_all(3)
		bar.add_theme_stylebox_override("fill", fill)

		var bar_bg = StyleBoxFlat.new()
		bar_bg.bg_color = COLOR_BAR_BG
		bar_bg.set_corner_radius_all(3)
		bar.add_theme_stylebox_override("background", bar_bg)
		hbox.add_child(bar)

		# Percentage label
		var percent_label = Label.new()
		percent_label.name = "PercentLabel"
		percent_label.add_theme_font_size_override("font_size", GameConstants.ACH_TRACKER_FONT_SIZE_PROGRESS)
		percent_label.add_theme_color_override("font_color", COLOR_GOLD)
		percent_label.custom_minimum_size = Vector2(30, 0)
		percent_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		percent_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hbox.add_child(percent_label)

		add_child(panel)
		_tracker_items.append({
			"panel": panel,
			"name_label": name_label,
			"progress_label": progress_label,
			"bar": bar,
			"percent_label": percent_label,
		})
		_bar_targets.append(0.0)

func _build_expanded_overlay() -> void:
	_expanded_panel = PanelContainer.new()
	_expanded_panel.name = "ExpandedAchievements"
	_expanded_panel.visible = false
	_expanded_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_expanded_panel.anchor_left = 0.15
	_expanded_panel.anchor_right = 0.85
	_expanded_panel.anchor_top = 0.1
	_expanded_panel.anchor_bottom = 0.9
	_expanded_panel.set_anchors_preset(Control.PRESET_CENTER)
	_expanded_panel.offset_left = -300
	_expanded_panel.offset_right = 300
	_expanded_panel.offset_top = -250
	_expanded_panel.offset_bottom = 250

	var bg = StyleBoxFlat.new()
	bg.bg_color = Color(0.0, 0.0, 0.0, GameConstants.ACH_EXPANDED_BG_ALPHA)
	bg.set_corner_radius_all(10)
	bg.set_border_width_all(2)
	bg.border_color = Color(0.4, 0.35, 0.2)
	bg.content_margin_left = 16
	bg.content_margin_right = 16
	bg.content_margin_top = 12
	bg.content_margin_bottom = 12
	_expanded_panel.add_theme_stylebox_override("panel", bg)

	var scroll = ScrollContainer.new()
	scroll.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_expanded_panel.add_child(scroll)

	_expanded_vbox = VBoxContainer.new()
	_expanded_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_expanded_vbox.add_theme_constant_override("separation", 6)
	scroll.add_child(_expanded_vbox)

	# Add to the HUD's CanvasLayer parent so it overlays correctly
	# We defer this to ensure parent is ready
	call_deferred("_add_expanded_to_parent")

func _add_expanded_to_parent() -> void:
	var hud = get_parent()
	if hud:
		hud.add_child(_expanded_panel)

func _build_almost_notification() -> void:
	_almost_panel = PanelContainer.new()
	_almost_panel.name = "AlmostThereNotification"
	_almost_panel.visible = false
	_almost_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_almost_panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_almost_panel.offset_left = -160
	_almost_panel.offset_right = 160
	_almost_panel.offset_top = 120
	_almost_panel.offset_bottom = 190

	var bg = StyleBoxFlat.new()
	bg.bg_color = Color(0.1, 0.08, 0.0, 0.85)
	bg.set_corner_radius_all(8)
	bg.set_border_width_all(2)
	bg.border_color = COLOR_ALMOST_BORDER
	bg.content_margin_left = 12
	bg.content_margin_right = 12
	bg.content_margin_top = 8
	bg.content_margin_bottom = 8
	_almost_panel.add_theme_stylebox_override("panel", bg)

	var vbox = VBoxContainer.new()
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_almost_panel.add_child(vbox)

	var title = Label.new()
	title.name = "AlmostTitle"
	title.text = LocaleManager.tr_key("ach_almost_there")
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", COLOR_GOLD)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var detail = Label.new()
	detail.name = "AlmostDetail"
	detail.add_theme_font_size_override("font_size", 12)
	detail.add_theme_color_override("font_color", Color.WHITE)
	detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(detail)

	var bar = ProgressBar.new()
	bar.name = "AlmostBar"
	bar.custom_minimum_size = Vector2(200, 8)
	bar.show_percentage = false
	bar.max_value = 1.0
	var fill = StyleBoxFlat.new()
	fill.bg_color = COLOR_GOLD
	fill.set_corner_radius_all(4)
	bar.add_theme_stylebox_override("fill", fill)
	var bar_bg = StyleBoxFlat.new()
	bar_bg.bg_color = COLOR_BAR_BG
	bar_bg.set_corner_radius_all(4)
	bar.add_theme_stylebox_override("background", bar_bg)
	vbox.add_child(bar)

	call_deferred("_add_almost_to_parent")

func _add_almost_to_parent() -> void:
	var hud = get_parent()
	if hud:
		hud.add_child(_almost_panel)

func _process(delta: float) -> void:
	# Lerp progress bars smoothly
	for i in range(mini(_tracker_items.size(), _bar_targets.size())):
		var bar: ProgressBar = _tracker_items[i]["bar"]
		if bar.visible or _tracker_items[i]["panel"].visible:
			bar.value = lerpf(bar.value, _bar_targets[i], GameConstants.ACH_TRACKER_LERP_SPEED * delta)

	# Update data periodically
	_update_timer += delta
	if _update_timer >= GameConstants.ACH_TRACKER_UPDATE_INTERVAL:
		_update_timer = 0.0
		_refresh_tracker_data()

	# "Almost there" notification timer
	if _almost_panel and _almost_panel.visible:
		_almost_timer -= delta
		# Pulse border effect
		_almost_panel.modulate.a = 0.85 + sin(Time.get_ticks_msec() * 0.005) * 0.15
		if _almost_timer <= 0.0:
			_almost_panel.visible = false

	# Toggle expanded view with Tab
	if Input.is_action_just_pressed("ui_focus_next"):  # Tab key
		_toggle_expanded()

func _refresh_tracker_data() -> void:
	_tracker_data = _get_nearest_achievements(GameConstants.ACH_TRACKER_MAX_VISIBLE)
	_update_mini_tracker()
	_check_almost_there()

func _update_mini_tracker() -> void:
	for i in range(GameConstants.ACH_TRACKER_MAX_VISIBLE):
		if i < _tracker_data.size():
			var data = _tracker_data[i]
			var item = _tracker_items[i]
			item["panel"].visible = true
			item["name_label"].text = data["name"]
			item["progress_label"].text = _format_progress(data["current"], data["target"])
			_bar_targets[i] = data["percent"]
			item["percent_label"].text = "%d%%" % int(data["percent"] * 100)
		else:
			_tracker_items[i]["panel"].visible = false
			_bar_targets[i] = 0.0

	# Hide entire tracker if nothing to show
	visible = _tracker_data.size() > 0

func _check_almost_there() -> void:
	for data in _tracker_data:
		if data["percent"] >= GameConstants.ACH_ALMOST_THRESHOLD and data["id"] not in _almost_notified:
			_almost_notified[data["id"]] = true
			_show_almost_notification(data)
			break  # One at a time

func _show_almost_notification(data: Dictionary) -> void:
	if not _almost_panel:
		return
	var title_label = _almost_panel.get_node("VBoxContainer/AlmostTitle") if _almost_panel.get_child_count() > 0 else null
	# Access via hierarchy
	var vbox = _almost_panel.get_child(0)
	if vbox and vbox.get_child_count() >= 3:
		var title_node = vbox.get_child(0)
		var detail_node = vbox.get_child(1)
		var bar_node = vbox.get_child(2)
		title_node.text = LocaleManager.tr_key("ach_almost_there")
		detail_node.text = "%s — %s" % [data["name"], _format_progress(data["current"], data["target"])]
		bar_node.value = data["percent"]

	_almost_panel.visible = true
	_almost_timer = GameConstants.ACH_ALMOST_NOTIFICATION_DURATION

	# SFX: reuse quest_progress with higher pitch
	if AudioManager.has_method("play_sfx"):
		AudioManager.play_sfx("quest_progress", 1.0)

func _toggle_expanded() -> void:
	_expanded_visible = not _expanded_visible
	if _expanded_panel:
		_expanded_panel.visible = _expanded_visible
		if _expanded_visible:
			_rebuild_expanded_list()

func _rebuild_expanded_list() -> void:
	if not _expanded_vbox:
		return
	# Clear previous entries
	for child in _expanded_vbox.get_children():
		child.queue_free()

	var unlocked_count = AchievementManager.get_unlocked_count()
	var total_count = AchievementManager.achievements.size()

	# Title
	var title = Label.new()
	title.text = "%s (%d/%d)" % [LocaleManager.tr_key("achievements_title"), unlocked_count, total_count]
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", COLOR_GOLD)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_expanded_vbox.add_child(title)

	# Separator
	var sep = HSeparator.new()
	_expanded_vbox.add_child(sep)

	# Completed achievements first
	var completed: Array[Dictionary] = []
	var in_progress: Array[Dictionary] = []
	var secret: Array[Dictionary] = []

	for id in AchievementManager.achievements:
		var ach = AchievementManager.achievements[id]
		if AchievementManager.is_unlocked(id):
			completed.append({"id": id, "name": ach["name"], "description": ach["description"]})
		else:
			var progress = _get_achievement_progress(id)
			if progress["percent"] > 0.0:
				in_progress.append(progress)
			else:
				secret.append({"id": id, "name": ach["name"], "description": ach["description"], "percent": 0.0})

	# Sort in-progress by percent descending
	in_progress.sort_custom(func(a, b): return a["percent"] > b["percent"])

	# Completed section
	for ach in completed:
		var row = _create_expanded_row(ach["name"], ach["description"], 1.0, true)
		_expanded_vbox.add_child(row)

	if completed.size() > 0 and (in_progress.size() > 0 or secret.size() > 0):
		_expanded_vbox.add_child(HSeparator.new())

	# In-progress section
	for ach in in_progress:
		var row = _create_expanded_row_with_bar(ach["name"], ach["current"], ach["target"], ach["percent"])
		_expanded_vbox.add_child(row)

	if in_progress.size() > 0 and secret.size() > 0:
		_expanded_vbox.add_child(HSeparator.new())

	# Secret/locked section
	for ach in secret:
		var row = _create_expanded_row("???", "???", 0.0, false)
		_expanded_vbox.add_child(row)

func _create_expanded_row(display_name: String, description: String, _percent: float, completed: bool) -> HBoxContainer:
	var hbox = HBoxContainer.new()
	hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_theme_constant_override("separation", 8)

	var icon = Label.new()
	if completed:
		icon.text = "[+]"
		icon.add_theme_color_override("font_color", COLOR_GREEN)
	else:
		icon.text = "[x]"
		icon.add_theme_color_override("font_color", COLOR_GRAY)
	icon.add_theme_font_size_override("font_size", 12)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(icon)

	var name_lbl = Label.new()
	name_lbl.text = "%s    %s" % [display_name, description]
	name_lbl.add_theme_font_size_override("font_size", 12)
	name_lbl.add_theme_color_override("font_color", COLOR_GREEN if completed else COLOR_GRAY)
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(name_lbl)

	return hbox

func _create_expanded_row_with_bar(display_name: String, current: int, target: int, pct: float) -> VBoxContainer:
	var vbox = VBoxContainer.new()
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_theme_constant_override("separation", 2)

	var hbox = HBoxContainer.new()
	hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_theme_constant_override("separation", 8)

	var icon = Label.new()
	icon.text = "[>]"
	icon.add_theme_font_size_override("font_size", 12)
	icon.add_theme_color_override("font_color", COLOR_GOLD)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(icon)

	var name_lbl = Label.new()
	name_lbl.text = "%s    %s" % [display_name, _format_progress(current, target)]
	name_lbl.add_theme_font_size_override("font_size", 12)
	name_lbl.add_theme_color_override("font_color", COLOR_GOLD)
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(name_lbl)

	vbox.add_child(hbox)

	# Progress bar
	var bar = ProgressBar.new()
	bar.custom_minimum_size = Vector2(300, 8)
	bar.show_percentage = false
	bar.max_value = 1.0
	bar.value = pct
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var fill = StyleBoxFlat.new()
	fill.bg_color = COLOR_GOLD
	fill.set_corner_radius_all(4)
	bar.add_theme_stylebox_override("fill", fill)
	var bar_bg = StyleBoxFlat.new()
	bar_bg.bg_color = COLOR_BAR_BG
	bar_bg.set_corner_radius_all(4)
	bar.add_theme_stylebox_override("background", bar_bg)
	vbox.add_child(bar)

	# Percentage text
	var pct_label = Label.new()
	pct_label.text = "%d%%" % int(pct * 100)
	pct_label.add_theme_font_size_override("font_size", 10)
	pct_label.add_theme_color_override("font_color", COLOR_GOLD)
	pct_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	pct_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(pct_label)

	return vbox

func _on_achievement_unlocked(id: String, _name: String) -> void:
	# Refresh tracker to remove completed achievement
	_refresh_tracker_data()
	# Flash animation on the item that just completed (if visible)
	for i in range(mini(_tracker_items.size(), _tracker_data.size())):
		# The completed one was already removed from tracker_data, so just refresh
		pass

# ================ Progress calculation ================

func _get_nearest_achievements(count: int) -> Array[Dictionary]:
	var incomplete: Array[Dictionary] = []
	for id in AchievementManager.achievements:
		if AchievementManager.is_unlocked(id):
			continue
		var progress = _get_achievement_progress(id)
		if progress["percent"] > 0.0:
			incomplete.append(progress)
	incomplete.sort_custom(func(a, b): return a["percent"] > b["percent"])
	return incomplete.slice(0, count) as Array[Dictionary]

func _get_achievement_progress(id: String) -> Dictionary:
	var ach = AchievementManager.achievements.get(id, {})
	var ach_name = ach.get("name", id)
	var current: int = 0
	var target: int = 1

	match id:
		"genocide":
			current = GameManager.total_kills
			target = 10000
		"collector":
			var all_chars = CharacterDB.get_all_character_ids()
			var unlocked = 0
			for cid in all_chars:
				if SaveManager.is_character_unlocked(cid):
					unlocked += 1
			current = unlocked
			target = 15
		"completionist":
			var completed_stages = SaveManager.data.get("completed_stages", [])
			current = completed_stages.size()
			target = 10
		"treasure_hunter":
			current = AchievementManager._run_chests_collected
			target = 10
		"quest_master":
			current = AchievementManager._run_quests_completed
			target = 5
		"boss_slayer":
			current = AchievementManager._run_bosses_killed
			target = 2
		"matrix":
			current = AchievementManager._run_dodges
			target = 100
		"evolved_6":
			current = EvolutionDB.evolved_weapons.size()
			target = 6
		"storm":
			var electric_evos = 0
			for evo_id in EvolutionDB.evolved_weapons:
				var evo = EvolutionDB.get_evolution(evo_id)
				var weapon_id = evo.get("weapon_required", "")
				var weapon_data = WeaponDB.get_weapon(weapon_id)
				if weapon_data.get("damage_type", "") == "electric":
					electric_evos += 1
			current = electric_evos
			target = 3
		"lucky_day":
			current = AchievementManager._run_legendary_items
			target = 5
		"first_walk":
			current = mini(int(GameManager.game_time), 300)
			target = 300
		"speedrunner":
			# Progress toward beating boss under 15min; only meaningful when close
			if GameManager.is_victory:
				current = 1
				target = 1
			else:
				current = mini(int(GameManager.game_time), 900)
				target = 900
		"pacifist":
			# 3 min without attacking — track time without attacks
			if AchievementManager._run_attacks == 0:
				current = mini(int(GameManager.game_time), 180)
				target = 180
			else:
				current = 0
				target = 180
		"nobody_deserves", "one_punch", "cow_brejo", "sweet_revenge":
			# Binary / conditional — not trackable as percentage
			current = 0
			target = 1

	var percent = minf(1.0, float(current) / maxf(float(target), 1.0))
	return {"id": id, "name": ach_name, "current": current, "target": target, "percent": percent}

# ================ Formatting ================

func _format_progress(current: int, target: int) -> String:
	return "%s/%s" % [_format_number(current), _format_number(target)]

func _format_number(n: int) -> String:
	if n >= 10000:
		return "%.1fK" % (n / 1000.0)
	elif n >= 1000:
		return "%.1fK" % (n / 1000.0)
	return str(n)
