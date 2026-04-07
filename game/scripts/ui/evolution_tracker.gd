extends Control

## PRD 57 — Painel "proxima evolucao" no HUD.
## Mostra para cada arma equipada qual item e necessario para evoluir.

const UPDATE_INTERVAL := 1.0  # Atualiza a cada 1s (nao precisa ser todo frame)
const BG_COLOR := Color(0.08, 0.08, 0.12, 0.9)
const BORDER_COLOR := Color(0.3, 0.25, 0.1, 0.6)
const TITLE_COLOR := Color(1.0, 0.85, 0.3)
const READY_COLOR := Color(0.3, 1.0, 0.3)
const MISSING_COLOR := Color(0.6, 0.6, 0.6)
const EVOLVED_COLOR := Color(1.0, 0.85, 0.3)

var _update_timer := 0.0
var _expanded := false
var _panel: PanelContainer = null
var _content: VBoxContainer = null
var _evo_cache: Array[Dictionary] = []
var _notify_timer := 0.0
var _notify_text := ""

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_expanded_panel()
	GameManager.weapon_upgraded.connect(func(_wid, _lvl): _force_update())
	GameManager.weapon_added.connect(func(_wid): _force_update())

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
	_panel.anchor_right = 1.0
	_panel.anchor_bottom = 1.0
	_panel.offset_left = -300
	_panel.offset_top = 80
	_panel.offset_right = -10
	_panel.offset_bottom = -200
	_panel.visible = false
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_panel)

	_content = VBoxContainer.new()
	_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(_content)

func _process(delta: float) -> void:
	# Toggle expanded panel with Tab
	if Input.is_action_just_pressed("ui_focus_next"):
		_expanded = not _expanded
		_panel.visible = _expanded
		if _expanded:
			_force_update()

	_update_timer += delta
	if _update_timer >= UPDATE_INTERVAL:
		_update_timer = 0.0
		_update_evolution_data()

	# Notification fade
	if _notify_timer > 0:
		_notify_timer -= delta
		if _notify_timer <= 0:
			_notify_text = ""
		queue_redraw()

func _force_update() -> void:
	_update_timer = UPDATE_INTERVAL  # Force next frame update

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

	if _expanded:
		_rebuild_panel()

	queue_redraw()

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

func _create_evo_row(info: Dictionary) -> HBoxContainer:
	var row = HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 8)

	var weapon_data = WeaponDB.get_weapon(info["weapon_id"])
	var weapon_name: String = weapon_data.get("name", info["weapon_id"]) if not weapon_data.is_empty() else info["weapon_id"]

	# Weapon name + level
	var name_label = Label.new()
	name_label.add_theme_font_size_override("font_size", 13)
	name_label.add_theme_constant_override("outline_size", 1)
	name_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.5))
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_label.custom_minimum_size.x = 140

	if info.get("is_evolved", false):
		var evo_data = EvolutionDB.get_evolution(info.get("evolution_id", ""))
		name_label.text = evo_data.get("name", weapon_name) if not evo_data.is_empty() else weapon_name
		name_label.add_theme_color_override("font_color", EVOLVED_COLOR)
	else:
		name_label.text = "%s Lv %d/8" % [weapon_name, info["weapon_level"]]
		name_label.add_theme_color_override("font_color", Color.WHITE)
	row.add_child(name_label)

	# Arrow
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

	# Item needed
	var item_label = Label.new()
	item_label.add_theme_font_size_override("font_size", 13)
	item_label.add_theme_constant_override("outline_size", 1)
	item_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.5))
	item_label.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if info.get("is_evolved", false):
		item_label.text = "evoluida"
		item_label.add_theme_color_override("font_color", EVOLVED_COLOR)
	elif info.get("is_ready", false):
		item_label.text = "%s PRONTO" % info.get("item_name", "?")
		item_label.add_theme_color_override("font_color", READY_COLOR)
	elif info.get("has_evolution", false):
		var has_it: bool = info.get("has_item", false)
		var symbol := "●" if has_it else "○"
		item_label.text = "%s %s" % [info.get("item_name", "?"), symbol]
		item_label.add_theme_color_override("font_color", EVOLVED_COLOR if has_it else MISSING_COLOR)
	else:
		item_label.text = "(sem evolucao)"
		item_label.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
	row.add_child(item_label)

	return row

func _get_evolution_info(weapon_id: String) -> Dictionary:
	for evo_id in EvolutionDB.evolutions:
		var evo: Dictionary = EvolutionDB.evolutions[evo_id]
		if evo.get("weapon_required") == weapon_id:
			var item_id: String = evo.get("item_required", "")
			var item_data = ItemDB.get_item(item_id)
			var weapon_level := GameManager.get_weapon_level(weapon_id)
			var has_item := GameManager.has_item(item_id)
			return {
				"has_evolution": true,
				"evolution_id": evo_id,
				"item_needed": item_id,
				"item_name": item_data.get("name", item_id) if not item_data.is_empty() else item_id,
				"has_item": has_item,
				"is_ready": weapon_level >= 8 and has_item,
				"is_evolved": evo_id in EvolutionDB.evolved_weapons,
			}
	return {"has_evolution": false}

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
