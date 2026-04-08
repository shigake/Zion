extends Control

## PRD 57 — Painel "proxima evolucao" no HUD.
## Mostra para cada arma equipada qual item e necessario para evoluir.
## Compact mode: small panel bottom-left showing closest evolution.
## Expanded mode (Tab): full list of all weapons and their evolution status.

const UPDATE_INTERVAL := 1.0  # Atualiza a cada 1s
const BG_COLOR := Color(0.08, 0.08, 0.12, 0.9)
const BORDER_COLOR := Color(0.3, 0.25, 0.1, 0.6)
const TITLE_COLOR := Color(1.0, 0.85, 0.3)
const READY_COLOR := Color(0.3, 1.0, 0.3)
const MISSING_COLOR := Color(0.6, 0.6, 0.6)
const EVOLVED_COLOR := Color(1.0, 0.85, 0.3)
const GLOW_COLOR := Color(1.0, 0.9, 0.4, 0.6)

var _update_timer := 0.0
var _expanded := false
var _panel: PanelContainer = null
var _content: VBoxContainer = null
var _evo_cache: Array[Dictionary] = []
var _notify_timer := 0.0
var _notify_text := ""

# Compact panel (always visible, shows closest evolution)
var _compact_panel: PanelContainer = null
var _compact_weapon_icon: TextureRect = null
var _compact_arrow: Label = null
var _compact_item_icon: TextureRect = null
var _compact_weapon_label: Label = null
var _compact_item_label: Label = null
var _compact_evo_name: Label = null
var _compact_status_label: Label = null
var _glow_timer := 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_compact_panel()
	_build_expanded_panel()
	GameManager.weapon_upgraded.connect(func(_wid, _lvl): _force_update())
	GameManager.weapon_added.connect(func(_wid): _force_update())

# --------------- Compact Panel (always visible) ---------------

func _build_compact_panel() -> void:
	_compact_panel = PanelContainer.new()
	_compact_panel.name = "EvoCompactPanel"
	var style = StyleBoxFlat.new()
	style.bg_color = BG_COLOR
	style.set_border_width_all(1)
	style.border_color = BORDER_COLOR
	style.set_corner_radius_all(6)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	_compact_panel.add_theme_stylebox_override("panel", style)

	# Position: top-right area, below timer/kills, above minimap
	_compact_panel.anchor_left = 1.0
	_compact_panel.anchor_top = 0.0
	_compact_panel.anchor_right = 1.0
	_compact_panel.anchor_bottom = 0.0
	_compact_panel.offset_left = -220.0
	_compact_panel.offset_top = 70.0
	_compact_panel.offset_right = -10.0
	_compact_panel.offset_bottom = 148.0
	_compact_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_compact_panel.visible = false
	add_child(_compact_panel)

	var vbox = VBoxContainer.new()
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_theme_constant_override("separation", 2)
	_compact_panel.add_child(vbox)

	# Top row: weapon icon + arrow + item icon
	var hbox = HBoxContainer.new()
	hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_theme_constant_override("separation", 6)
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(hbox)

	_compact_weapon_icon = TextureRect.new()
	_compact_weapon_icon.custom_minimum_size = Vector2(24, 24)
	_compact_weapon_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_compact_weapon_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_compact_weapon_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(_compact_weapon_icon)

	_compact_weapon_label = Label.new()
	_compact_weapon_label.add_theme_font_size_override("font_size", 11)
	_compact_weapon_label.add_theme_constant_override("outline_size", 1)
	_compact_weapon_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.6))
	_compact_weapon_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(_compact_weapon_label)

	_compact_arrow = Label.new()
	_compact_arrow.text = "+"
	_compact_arrow.add_theme_font_size_override("font_size", 12)
	_compact_arrow.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	_compact_arrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(_compact_arrow)

	_compact_item_icon = TextureRect.new()
	_compact_item_icon.custom_minimum_size = Vector2(24, 24)
	_compact_item_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_compact_item_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_compact_item_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(_compact_item_icon)

	_compact_item_label = Label.new()
	_compact_item_label.add_theme_font_size_override("font_size", 11)
	_compact_item_label.add_theme_constant_override("outline_size", 1)
	_compact_item_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.6))
	_compact_item_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(_compact_item_label)

	# Evolution name row
	_compact_evo_name = Label.new()
	_compact_evo_name.add_theme_font_size_override("font_size", 12)
	_compact_evo_name.add_theme_color_override("font_color", TITLE_COLOR)
	_compact_evo_name.add_theme_constant_override("outline_size", 1)
	_compact_evo_name.add_theme_color_override("font_outline_color", Color(0.2, 0.1, 0.0))
	_compact_evo_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_compact_evo_name.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(_compact_evo_name)

	# Status row (progress or READY!)
	_compact_status_label = Label.new()
	_compact_status_label.add_theme_font_size_override("font_size", 10)
	_compact_status_label.add_theme_constant_override("outline_size", 1)
	_compact_status_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.5))
	_compact_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_compact_status_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(_compact_status_label)

# --------------- Expanded Panel (Tab toggle) ---------------

func _build_expanded_panel() -> void:
	_panel = PanelContainer.new()
	_panel.name = "EvoPanel"
	var style = StyleBoxFlat.new()
	style.bg_color = BG_COLOR
	style.set_border_width_all(1)
	style.border_color = BORDER_COLOR
	style.set_corner_radius_all(6)
	style.set_content_margin_all(12)
	_panel.add_theme_stylebox_override("panel", style)
	_panel.anchor_left = 1.0
	_panel.anchor_top = 0.0
	_panel.anchor_right = 1.0
	_panel.anchor_bottom = 0.0
	_panel.offset_left = -310.0
	_panel.offset_top = 70.0
	_panel.offset_right = -10.0
	_panel.offset_bottom = 500.0
	_panel.visible = false
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_panel)

	_content = VBoxContainer.new()
	_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(_content)

# --------------- Process ---------------

func _process(delta: float) -> void:
	# Toggle expanded panel with Tab
	if Input.is_action_just_pressed("ui_focus_next"):
		_expanded = not _expanded
		_panel.visible = _expanded
		if _expanded:
			# Hide compact when expanded is shown (same area)
			_compact_panel.visible = false
			_force_update()
		else:
			# Re-show compact when closing expanded
			_update_compact_panel()

	_update_timer += delta
	if _update_timer >= UPDATE_INTERVAL:
		_update_timer = 0.0
		_update_evolution_data()

	# Glow animation for close-to-ready evolutions
	_glow_timer += delta

	# Notification fade
	if _notify_timer > 0:
		_notify_timer -= delta
		if _notify_timer <= 0:
			_notify_text = ""
		queue_redraw()

func _force_update() -> void:
	_update_timer = UPDATE_INTERVAL  # Force next frame update

# --------------- Data Update ---------------

func _update_evolution_data() -> void:
	var new_cache: Array[Dictionary] = []
	for w in GameManager.player_weapons:
		var info := _get_evolution_info(w["id"])
		info["weapon_id"] = w["id"]
		info["weapon_level"] = GameManager.get_weapon_level(w["id"])
		new_cache.append(info)

	# Check for newly ready evolutions
	for i in range(new_cache.size()):
		var nc = new_cache[i]
		if nc.get("is_ready", false):
			var was_ready := false
			for oc in _evo_cache:
				if oc.get("weapon_id") == nc["weapon_id"] and oc.get("is_ready", false):
					was_ready = true
					break
			if not was_ready:
				_notify_text = "Evolucao disponivel!"
				_notify_timer = 2.5
				AudioManager.play_sfx("level_up")

	_evo_cache = new_cache

	_update_compact_panel()

	if _expanded:
		_rebuild_panel()

	queue_redraw()

# --------------- Compact Panel Update ---------------

func _update_compact_panel() -> void:
	# Find the closest evolution candidate (best = highest combined progress)
	var best: Dictionary = {}
	var best_score := -1.0

	for info in _evo_cache:
		if not info.get("has_evolution", false):
			continue
		if info.get("is_evolved", false):
			continue

		# Score: weapon_level/8 + item_level/5 (higher = closer to ready)
		var w_progress: float = float(info.get("weapon_level", 0)) / 8.0
		var i_progress: float = float(info.get("item_level", 0)) / 5.0
		var score: float = w_progress + i_progress

		# Bonus for having both components
		if info.get("has_item", false):
			score += 1.0

		# Ready evolutions get top priority
		if info.get("is_ready", false):
			score += 10.0

		if score > best_score:
			best_score = score
			best = info

	if best.is_empty() or _expanded:
		_compact_panel.visible = false
		return

	_compact_panel.visible = true

	var weapon_id: String = best.get("weapon_id", "")
	var item_id: String = best.get("item_needed", "")
	var weapon_level: int = best.get("weapon_level", 0)
	var item_level: int = best.get("item_level", 0)
	var is_ready: bool = best.get("is_ready", false)
	var has_item: bool = best.get("has_item", false)

	# Load weapon icon
	var w_icon_path := "res://assets/sprites/weapons/%s.png" % weapon_id
	if ResourceLoader.exists(w_icon_path):
		_compact_weapon_icon.texture = load(w_icon_path)
	else:
		_compact_weapon_icon.texture = null

	# Load item icon
	var i_icon_path := "res://assets/sprites/items/%s.png" % item_id
	if ResourceLoader.exists(i_icon_path):
		_compact_item_icon.texture = load(i_icon_path)
	else:
		_compact_item_icon.texture = null

	# Weapon progress label
	var weapon_data = WeaponDB.get_weapon(weapon_id)
	var w_name: String = weapon_data.get("name", weapon_id) if not weapon_data.is_empty() else weapon_id
	_compact_weapon_label.text = "Lv%d/8" % weapon_level
	if weapon_level >= 8:
		_compact_weapon_label.add_theme_color_override("font_color", READY_COLOR)
	else:
		_compact_weapon_label.add_theme_color_override("font_color", Color.WHITE)

	# Item progress label
	_compact_item_label.text = "Lv%d/5" % item_level if has_item else "---"
	if has_item and item_level >= 5:
		_compact_item_label.add_theme_color_override("font_color", READY_COLOR)
	elif has_item:
		_compact_item_label.add_theme_color_override("font_color", Color.WHITE)
	else:
		_compact_item_label.add_theme_color_override("font_color", MISSING_COLOR)

	# Evolution name
	var evo_data = EvolutionDB.get_evolution(best.get("evolution_id", ""))
	var evo_name: String = evo_data.get("name", "???") if not evo_data.is_empty() else "???"
	_compact_evo_name.text = evo_name

	# Status text
	if is_ready:
		_compact_status_label.text = "PRONTO!"
		_compact_status_label.add_theme_color_override("font_color", READY_COLOR)
		# Gold glow pulse on panel border when ready
		var pulse = sin(_glow_timer * 4.0) * 0.3 + 0.7
		var glow_style = _compact_panel.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
		glow_style.border_color = Color(READY_COLOR.r, READY_COLOR.g, READY_COLOR.b, pulse)
		glow_style.set_border_width_all(2)
		_compact_panel.add_theme_stylebox_override("panel", glow_style)
	elif weapon_level >= 6 or (has_item and item_level >= 3):
		# Close to evolution — subtle glow
		var item_name: String = best.get("item_name", item_id)
		if has_item:
			_compact_status_label.text = "%s Lv%d/8 + %s Lv%d/5" % [w_name, weapon_level, item_name, item_level]
		else:
			_compact_status_label.text = "%s Lv%d/8 (precisa: %s)" % [w_name, weapon_level, item_name]
		_compact_status_label.add_theme_color_override("font_color", TITLE_COLOR)
		var pulse = sin(_glow_timer * 2.0) * 0.15 + 0.5
		var glow_style = StyleBoxFlat.new()
		glow_style.bg_color = BG_COLOR
		glow_style.set_border_width_all(1)
		glow_style.border_color = Color(GLOW_COLOR.r, GLOW_COLOR.g, GLOW_COLOR.b, pulse)
		glow_style.set_corner_radius_all(6)
		glow_style.content_margin_left = 8
		glow_style.content_margin_right = 8
		glow_style.content_margin_top = 6
		glow_style.content_margin_bottom = 6
		_compact_panel.add_theme_stylebox_override("panel", glow_style)
	else:
		var item_name: String = best.get("item_name", item_id)
		if has_item:
			_compact_status_label.text = "%s Lv%d/8 + %s Lv%d/5" % [w_name, weapon_level, item_name, item_level]
		else:
			_compact_status_label.text = "%s Lv%d/8 (precisa: %s)" % [w_name, weapon_level, item_name]
		_compact_status_label.add_theme_color_override("font_color", MISSING_COLOR)
		# Reset to default style
		var default_style = StyleBoxFlat.new()
		default_style.bg_color = BG_COLOR
		default_style.set_border_width_all(1)
		default_style.border_color = BORDER_COLOR
		default_style.set_corner_radius_all(6)
		default_style.content_margin_left = 8
		default_style.content_margin_right = 8
		default_style.content_margin_top = 6
		default_style.content_margin_bottom = 6
		_compact_panel.add_theme_stylebox_override("panel", default_style)

# --------------- Expanded Panel Rebuild ---------------

func _rebuild_panel() -> void:
	for c in _content.get_children():
		c.queue_free()

	# Title
	var title = Label.new()
	title.text = "Ressonancias cristalinas"
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", TITLE_COLOR)
	title.add_theme_constant_override("outline_size", 2)
	title.add_theme_color_override("font_outline_color", Color(0.2, 0.1, 0.0))
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content.add_child(title)

	# Separator
	var sep = HSeparator.new()
	sep.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content.add_child(sep)

	for info in _evo_cache:
		var row = _create_evo_row(info)
		_content.add_child(row)

	# Hint at bottom
	var hint = Label.new()
	hint.text = "Tab para fechar"
	hint.add_theme_font_size_override("font_size", 10)
	hint.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 0.6))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content.add_child(hint)

func _create_evo_row(info: Dictionary) -> VBoxContainer:
	var wrapper = VBoxContainer.new()
	wrapper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrapper.add_theme_constant_override("separation", 0)

	var row = HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 6)

	var weapon_id: String = info.get("weapon_id", "")
	var weapon_data = WeaponDB.get_weapon(weapon_id)
	var weapon_name: String = weapon_data.get("name", weapon_id) if not weapon_data.is_empty() else weapon_id

	# Weapon icon (small)
	var w_icon_path := "res://assets/sprites/weapons/%s.png" % weapon_id
	if ResourceLoader.exists(w_icon_path):
		var tex = TextureRect.new()
		tex.texture = load(w_icon_path)
		tex.custom_minimum_size = Vector2(20, 20)
		tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(tex)

	# Weapon name + level
	var name_label = Label.new()
	name_label.add_theme_font_size_override("font_size", 13)
	name_label.add_theme_constant_override("outline_size", 1)
	name_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.5))
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_label.custom_minimum_size.x = 120

	if info.get("is_evolved", false):
		var evo_data = EvolutionDB.get_evolution(info.get("evolution_id", ""))
		name_label.text = evo_data.get("name", weapon_name) if not evo_data.is_empty() else weapon_name
		name_label.add_theme_color_override("font_color", EVOLVED_COLOR)
	else:
		name_label.text = "%s Lv%d/8" % [weapon_name, info.get("weapon_level", 0)]
		if info.get("weapon_level", 0) >= 8:
			name_label.add_theme_color_override("font_color", READY_COLOR)
		else:
			name_label.add_theme_color_override("font_color", Color.WHITE)
	row.add_child(name_label)

	# Arrow or star
	var arrow = Label.new()
	arrow.add_theme_font_size_override("font_size", 13)
	arrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if info.get("is_evolved", false):
		arrow.text = "★"
		arrow.add_theme_color_override("font_color", EVOLVED_COLOR)
	elif info.get("has_evolution", false):
		arrow.text = "→"
		arrow.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	else:
		arrow.text = ""
	row.add_child(arrow)

	# Item info
	var item_label = Label.new()
	item_label.add_theme_font_size_override("font_size", 13)
	item_label.add_theme_constant_override("outline_size", 1)
	item_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.5))
	item_label.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if info.get("is_evolved", false):
		item_label.text = "evoluida"
		item_label.add_theme_color_override("font_color", EVOLVED_COLOR)
	elif info.get("is_ready", false):
		item_label.text = "%s Lv%d/5 PRONTO" % [info.get("item_name", "?"), info.get("item_level", 0)]
		item_label.add_theme_color_override("font_color", READY_COLOR)
	elif info.get("has_evolution", false):
		var has_it: bool = info.get("has_item", false)
		if has_it:
			item_label.text = "%s Lv%d/5" % [info.get("item_name", "?"), info.get("item_level", 0)]
			item_label.add_theme_color_override("font_color", EVOLVED_COLOR)
		else:
			item_label.text = "%s (precisa)" % info.get("item_name", "?")
			item_label.add_theme_color_override("font_color", MISSING_COLOR)
	else:
		item_label.text = "(sem evolucao)"
		item_label.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
	row.add_child(item_label)

	wrapper.add_child(row)

	# Add small separator between entries
	var spacer = Control.new()
	spacer.custom_minimum_size.y = 4
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrapper.add_child(spacer)

	return wrapper

# --------------- Evolution Info Lookup ---------------

func _get_evolution_info(weapon_id: String) -> Dictionary:
	for evo_id in EvolutionDB.evolutions:
		var evo: Dictionary = EvolutionDB.evolutions[evo_id]
		if evo.get("weapon_required") == weapon_id:
			var item_id: String = evo.get("item_required", "")
			var item_data = ItemDB.get_item(item_id)
			var weapon_level := GameManager.get_weapon_level(weapon_id)
			var has_item := GameManager.has_item(item_id)
			var item_level := GameManager.get_item_level(item_id)
			return {
				"has_evolution": true,
				"evolution_id": evo_id,
				"item_needed": item_id,
				"item_name": item_data.get("name", item_id) if not item_data.is_empty() else item_id,
				"has_item": has_item,
				"item_level": item_level,
				"is_ready": weapon_level >= 8 and item_level >= 5,
				"is_evolved": evo_id in EvolutionDB.evolved_weapons,
			}
	return {"has_evolution": false}

# --------------- Draw (notification overlay) ---------------

func _draw() -> void:
	# Notification text (floating up)
	if _notify_timer > 0 and _notify_text != "":
		var alpha := clampf(_notify_timer / 0.5, 0.0, 1.0)
		var y_offset := (2.5 - _notify_timer) * 20.0
		var font := ThemeDB.fallback_font
		var pos := Vector2(size.x * 0.5 - 80, size.y * 0.4 - y_offset)
		# Outline
		draw_string(font, pos + Vector2(1, 1), _notify_text, HORIZONTAL_ALIGNMENT_CENTER, -1, 18, Color(0, 0, 0, alpha * 0.8))
		# Text
		draw_string(font, pos, _notify_text, HORIZONTAL_ALIGNMENT_CENTER, -1, 18, Color(READY_COLOR.r, READY_COLOR.g, READY_COLOR.b, alpha))
