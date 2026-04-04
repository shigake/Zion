extends CanvasLayer

## Inventory overlay — TAB to open/close during gameplay.
## Shows weapons (with DPS), items, active synergies, and evolution progress.

var overlay: ColorRect
var panel: PanelContainer
var _is_open: bool = false
var _was_gm_paused_before: bool = false

func _ready() -> void:
	layer = 6
	process_mode = Node.PROCESS_MODE_ALWAYS

	# Register "inventory" input action (TAB key)
	_register_inventory_action()

	# Build UI
	_build_overlay()
	_hide()

func _register_inventory_action() -> void:
	if not InputMap.has_action("inventory"):
		InputMap.add_action("inventory")
	# Teclado — TAB
	var event = InputEventKey.new()
	event.physical_keycode = KEY_TAB
	InputMap.action_add_event("inventory", event)
	# Gamepad — Select/Back button (Bug 7 fix)
	var joy_event = InputEventJoypadButton.new()
	joy_event.button_index = JOY_BUTTON_BACK
	InputMap.action_add_event("inventory", joy_event)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("inventory") and not GameManager.is_game_over:
		if _is_open:
			_close()
		else:
			_open()
		if get_viewport():
			get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel") and _is_open:
		_close()
		if get_viewport():
			get_viewport().set_input_as_handled()
	elif event.is_action_pressed("pause") and _is_open:
		_close()
		if get_viewport():
			get_viewport().set_input_as_handled()

func _build_overlay() -> void:
	# Dark semi-transparent background
	overlay = ColorRect.new()
	overlay.name = "Overlay"
	overlay.color = Color(0, 0, 0, 0.65)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)

	# Centered panel 600x400
	panel = PanelContainer.new()
	panel.name = "InventoryPanel"
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -300
	panel.offset_top = -200
	panel.offset_right = 300
	panel.offset_bottom = 200
	overlay.add_child(panel)

func _open() -> void:
	if _is_open:
		return
	_is_open = true
	_was_gm_paused_before = GameManager.paused
	GameManager.paused = true
	get_tree().paused = true
	_rebuild_content()
	_show()
	# Bug 8 fix — grab focus on close button for gamepad
	if GamepadUI.is_gamepad_mode:
		var close = panel.get_node_or_null("MarginContainer/ScrollContainer/VBoxContainer/HBoxContainer")
		if close and close.get_child_count() > 1:
			close.get_child(close.get_child_count() - 1).call_deferred("grab_focus")
	AudioManager.play_sfx("menu_click")

func _close() -> void:
	if not _is_open:
		return
	_is_open = false
	_hide()
	get_tree().paused = false
	GameManager.paused = _was_gm_paused_before
	AudioManager.play_sfx("menu_click")

func _show() -> void:
	overlay.visible = true

func _hide() -> void:
	overlay.visible = false

func _rebuild_content() -> void:
	# Clear previous content
	for child in panel.get_children():
		child.queue_free()

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)

	var scroll = ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(scroll)

	var main_vbox = VBoxContainer.new()
	main_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_vbox.add_theme_constant_override("separation", 6)
	scroll.add_child(main_vbox)

	# ---- Header ----
	var header = HBoxContainer.new()
	main_vbox.add_child(header)

	var title = Label.new()
	title.text = "Inventario"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	header.add_child(title)

	var close_btn = Button.new()
	close_btn.text = "X"
	close_btn.custom_minimum_size = Vector2(32, 32)
	close_btn.focus_mode = Control.FOCUS_ALL
	close_btn.pressed.connect(_close)
	header.add_child(close_btn)

	main_vbox.add_child(HSeparator.new())

	# ---- Weapons + Items side by side ----
	var columns = HBoxContainer.new()
	columns.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.add_theme_constant_override("separation", 12)
	main_vbox.add_child(columns)

	# Left: Weapons
	var weapons_vbox = VBoxContainer.new()
	weapons_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	weapons_vbox.add_theme_constant_override("separation", 4)
	columns.add_child(weapons_vbox)

	var weapons_title = Label.new()
	weapons_title.text = "Armas"
	weapons_title.add_theme_font_size_override("font_size", 18)
	weapons_title.add_theme_color_override("font_color", Color(0.6, 0.85, 1.0))
	weapons_vbox.add_child(weapons_title)

	if GameManager.player_weapons.is_empty():
		var empty_lbl = Label.new()
		empty_lbl.text = "Nenhuma arma"
		empty_lbl.add_theme_font_size_override("font_size", 13)
		empty_lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		weapons_vbox.add_child(empty_lbl)
	else:
		for w in GameManager.player_weapons:
			_add_weapon_entry(weapons_vbox, w)

	# Vertical separator
	var vsep = VSeparator.new()
	columns.add_child(vsep)

	# Right: Items
	var items_vbox = VBoxContainer.new()
	items_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	items_vbox.add_theme_constant_override("separation", 4)
	columns.add_child(items_vbox)

	var items_title = Label.new()
	items_title.text = "Itens"
	items_title.add_theme_font_size_override("font_size", 18)
	items_title.add_theme_color_override("font_color", Color(0.85, 0.7, 1.0))
	items_vbox.add_child(items_title)

	if GameManager.player_items.is_empty():
		var empty_lbl = Label.new()
		empty_lbl.text = "Nenhum item"
		empty_lbl.add_theme_font_size_override("font_size", 13)
		empty_lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		items_vbox.add_child(empty_lbl)
	else:
		for it in GameManager.player_items:
			_add_item_entry(items_vbox, it)

	# ---- Synergies ----
	var synergies = SynergySystem.active_synergies
	if not synergies.is_empty():
		main_vbox.add_child(HSeparator.new())

		var syn_title = Label.new()
		syn_title.text = "Sinergias ativas"
		syn_title.add_theme_font_size_override("font_size", 18)
		syn_title.add_theme_color_override("font_color", Color(1.0, 0.6, 0.3))
		main_vbox.add_child(syn_title)

		for syn_id in synergies:
			var desc = SynergySystem.get_synergy_description(syn_id)
			if desc != "":
				var syn_lbl = Label.new()
				syn_lbl.text = desc
				syn_lbl.add_theme_font_size_override("font_size", 13)
				syn_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
				main_vbox.add_child(syn_lbl)

	# ---- Evolution progress ----
	var possible_evos = _get_possible_evolutions()
	if not possible_evos.is_empty():
		main_vbox.add_child(HSeparator.new())

		var evo_title = Label.new()
		evo_title.text = LocaleManager.tr_key("evo_tree_possible")
		evo_title.add_theme_font_size_override("font_size", 18)
		evo_title.add_theme_color_override("font_color", Color(0.3, 1.0, 0.5))
		main_vbox.add_child(evo_title)

		for evo in possible_evos:
			_add_evolution_entry(main_vbox, evo)

	# ---- Evolution tree (compact) ----
	main_vbox.add_child(HSeparator.new())

	var evo_tree_title = Label.new()
	evo_tree_title.text = LocaleManager.tr_key("evo_tree_title")
	evo_tree_title.add_theme_font_size_override("font_size", 18)
	evo_tree_title.add_theme_color_override("font_color", Color(0.9, 0.8, 0.3))
	main_vbox.add_child(evo_tree_title)

	# Compact list of all evolutions
	for evo_id in EvolutionDB.get_all_evolution_ids():
		var evo = EvolutionDB.get_evolution(evo_id)
		var state = _get_evo_tree_state(evo_id)
		var entry_hbox = HBoxContainer.new()
		entry_hbox.add_theme_constant_override("separation", 6)
		main_vbox.add_child(entry_hbox)

		# Available indicator
		if state == "available":
			var star = Label.new()
			star.text = "!"
			star.add_theme_font_size_override("font_size", 14)
			star.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
			entry_hbox.add_child(star)

		# Name
		var name_lbl = Label.new()
		if state == "locked":
			name_lbl.text = "???"
			name_lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		else:
			name_lbl.text = evo.get("name", evo_id.capitalize())
			match state:
				"discovered":
					name_lbl.add_theme_color_override("font_color", Color(0.6, 0.85, 1.0))
				"available":
					name_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
				"evolved":
					name_lbl.add_theme_color_override("font_color", Color(0.3, 1.0, 0.4))
		name_lbl.add_theme_font_size_override("font_size", 13)
		entry_hbox.add_child(name_lbl)

		# Recipe with current levels
		if state != "locked":
			var weapon_id = evo.get("weapon_required", "")
			var item_id = evo.get("item_required", "")
			var weapon_data = WeaponDB.get_weapon(weapon_id)
			var item_data = ItemDB.get_item(item_id)
			var wname = weapon_data.get("name", weapon_id.capitalize()) if not weapon_data.is_empty() else weapon_id.capitalize()
			var iname = item_data.get("name", item_id.capitalize()) if not item_data.is_empty() else item_id.capitalize()
			var wlv = GameManager.get_weapon_level(weapon_id)
			var ilv = GameManager.get_item_level(item_id)

			var recipe_lbl = Label.new()
			recipe_lbl.text = "(%s %d/6 + %s %d/3)" % [wname, wlv, iname, ilv]
			recipe_lbl.add_theme_font_size_override("font_size", 11)
			recipe_lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
			entry_hbox.add_child(recipe_lbl)

		if state == "evolved":
			var check = Label.new()
			check.text = "[OK]"
			check.add_theme_font_size_override("font_size", 11)
			check.add_theme_color_override("font_color", Color(0.3, 1.0, 0.4))
			entry_hbox.add_child(check)

func _add_weapon_entry(parent: Control, w: Dictionary) -> void:
	var weapon_id: String = w["id"]
	var level: int = w["level"]
	var data = WeaponDB.get_weapon(weapon_id)
	var wname = data.get("name", weapon_id.capitalize()) if not data.is_empty() else weapon_id.capitalize()

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 1)
	parent.add_child(vbox)

	# Name + level row with icon
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 6)
	vbox.add_child(hbox)

	var icon_path = "res://assets/sprites/weapons/%s.png" % weapon_id
	if ResourceLoader.exists(icon_path):
		var tex = load(icon_path)
		if tex:
			var icon = TextureRect.new()
			icon.texture = tex
			icon.custom_minimum_size = Vector2(24, 24)
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			hbox.add_child(icon)

	var name_lbl = Label.new()
	name_lbl.text = "%s Lv.%d" % [wname, level]
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_lbl.add_theme_font_size_override("font_size", 14)
	hbox.add_child(name_lbl)

	# DPS line
	var dps = _calc_weapon_dps(weapon_id, level)
	var dps_lbl = Label.new()
	dps_lbl.text = "  DPS: %.1f" % dps
	dps_lbl.add_theme_font_size_override("font_size", 12)
	dps_lbl.add_theme_color_override("font_color", Color(0.9, 0.9, 0.5))
	vbox.add_child(dps_lbl)

func _add_item_entry(parent: Control, it: Dictionary) -> void:
	var item_id: String = it["id"]
	var level: int = it["level"]
	var data = ItemDB.get_item(item_id)
	var iname = data.get("name", item_id.capitalize()) if not data.is_empty() else item_id.capitalize()

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 1)
	parent.add_child(vbox)

	# Name + level row with icon
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 6)
	vbox.add_child(hbox)

	var icon_path = "res://assets/sprites/items/%s.png" % item_id
	if ResourceLoader.exists(icon_path):
		var tex = load(icon_path)
		if tex:
			var icon = TextureRect.new()
			icon.texture = tex
			icon.custom_minimum_size = Vector2(24, 24)
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			hbox.add_child(icon)

	var name_lbl = Label.new()
	name_lbl.text = "%s %d" % [iname, level]
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_lbl.add_theme_font_size_override("font_size", 14)
	hbox.add_child(name_lbl)

	# Effect description
	if not data.is_empty():
		var value = data["value_per_level"] * level
		var desc_text = ""
		match data["stat"]:
			"speed":
				desc_text = "+%d%% velocidade" % int(value * 100)
			"attack_speed":
				desc_text = "+%d%% attack speed" % int(value * 100)
			"max_hp":
				desc_text = "+%d%% HP" % int(value * 100)
			"area":
				desc_text = "+%d%% area" % int(value * 100)
			"magnet":
				desc_text = "+%d%% coleta" % int(value * 100)
			"cooldown":
				desc_text = "-%d%% cooldown" % int(value * 100)
			"dodge":
				desc_text = "%d%% dodge" % int(value * 100)
			"xp_bonus":
				desc_text = "+%d%% XP" % int(value * 100)
			"explosion_damage":
				desc_text = "+%d%% dano explosao" % int(value * 100)
			"electric_damage":
				desc_text = "+%d%% dano eletrico" % int(value * 100)
			"lifesteal":
				desc_text = "+%d%% lifesteal" % int(value * 100)
			"thorns":
				desc_text = "%d%% reflexo" % int(value * 100)
			"luck":
				desc_text = "+%d%% sorte" % int(value * 100)
			"extra_projectiles":
				desc_text = "+%d projeteis" % int(value)
			"summon_damage":
				desc_text = "+%d%% dano invocacoes" % int(value * 100)
			"attack_size":
				desc_text = "+%d%% tamanho" % int(value * 100)
			"fire_ground":
				desc_text = "Chao em fogo ativo" if level > 0 else ""
			"weapon_level_bonus":
				desc_text = "+%d nivel armas" % int(value)
			"accuracy":
				desc_text = "+%d%% precisao" % int(value * 100)
			_:
				desc_text = data.get("description", "")

		if desc_text != "":
			var desc_lbl = Label.new()
			desc_lbl.text = "  " + desc_text
			desc_lbl.add_theme_font_size_override("font_size", 12)
			desc_lbl.add_theme_color_override("font_color", Color(0.7, 0.9, 0.7))
			vbox.add_child(desc_lbl)

func _calc_weapon_dps(weapon_id: String, level: int) -> float:
	var data = WeaponDB.get_weapon(weapon_id)
	if data.is_empty():
		return 0.0
	var base_damage: float = data.get("base_damage", 0)
	var damage_per_level: float = data.get("damage_per_level", 0)
	var base_cooldown: float = data.get("base_cooldown", 1.0)
	var cooldown_per_level: float = data.get("cooldown_per_level", 0)

	var damage = base_damage + damage_per_level * (level - 1)
	var cooldown = maxf(0.05, base_cooldown + cooldown_per_level * (level - 1))
	return damage / cooldown

func _get_possible_evolutions() -> Array:
	var result: Array = []
	for evo_id in EvolutionDB.evolutions:
		if evo_id in EvolutionDB.evolved_weapons:
			continue
		var evo = EvolutionDB.evolutions[evo_id]
		var weapon_id: String = evo["weapon_required"]
		var item_id: String = evo["item_required"]
		var weapon_level = GameManager.get_weapon_level(weapon_id)
		var item_level = GameManager.get_item_level(item_id)
		# Show only if player has the weapon or item
		if weapon_level > 0 or item_level > 0:
			result.append({
				"evo_id": evo_id,
				"name": evo["name"],
				"weapon_id": weapon_id,
				"item_id": item_id,
				"weapon_level": weapon_level,
				"item_level": item_level,
			})
	return result

func _add_evolution_entry(parent: Control, evo: Dictionary) -> void:
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	parent.add_child(vbox)

	var weapon_data = WeaponDB.get_weapon(evo["weapon_id"])
	var weapon_name = weapon_data.get("name", evo["weapon_id"].capitalize()) if not weapon_data.is_empty() else evo["weapon_id"].capitalize()
	var item_data = ItemDB.get_item(evo["item_id"])
	var item_name = item_data.get("name", evo["item_id"].capitalize()) if not item_data.is_empty() else evo["item_id"].capitalize()

	# Evolution name + requirements
	var name_lbl = Label.new()
	name_lbl.text = "%s: %s %d/8 + %s %d/5" % [
		evo["name"], weapon_name, evo["weapon_level"], item_name, evo["item_level"]
	]
	name_lbl.add_theme_font_size_override("font_size", 13)
	name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(name_lbl)

	# Progress bars
	var bars_hbox = HBoxContainer.new()
	bars_hbox.add_theme_constant_override("separation", 8)
	vbox.add_child(bars_hbox)

	# Weapon progress bar
	var wpn_bar = ProgressBar.new()
	wpn_bar.min_value = 0
	wpn_bar.max_value = 6
	wpn_bar.value = evo["weapon_level"]
	wpn_bar.custom_minimum_size = Vector2(120, 14)
	wpn_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	wpn_bar.show_percentage = false
	# Color: green if complete, yellow otherwise
	var wpn_style = StyleBoxFlat.new()
	if evo["weapon_level"] >= 6:
		wpn_style.bg_color = Color(0.2, 0.9, 0.3)
	else:
		wpn_style.bg_color = Color(0.9, 0.8, 0.2)
	wpn_bar.add_theme_stylebox_override("fill", wpn_style)
	var wpn_bg = StyleBoxFlat.new()
	wpn_bg.bg_color = Color(0.15, 0.15, 0.15)
	wpn_bar.add_theme_stylebox_override("background", wpn_bg)
	bars_hbox.add_child(wpn_bar)

	# Item progress bar
	var item_bar = ProgressBar.new()
	item_bar.min_value = 0
	item_bar.max_value = 3
	item_bar.value = evo["item_level"]
	item_bar.custom_minimum_size = Vector2(120, 14)
	item_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	item_bar.show_percentage = false
	var item_style = StyleBoxFlat.new()
	if evo["item_level"] >= 3:
		item_style.bg_color = Color(0.2, 0.9, 0.3)
	else:
		item_style.bg_color = Color(0.7, 0.5, 1.0)
	item_bar.add_theme_stylebox_override("fill", item_style)
	var item_bg = StyleBoxFlat.new()
	item_bg.bg_color = Color(0.15, 0.15, 0.15)
	item_bar.add_theme_stylebox_override("background", item_bg)
	bars_hbox.add_child(item_bar)

func _get_evo_tree_state(evo_id: String) -> String:
	## Returns evolution state: "locked", "discovered", "available", "evolved"
	if evo_id in EvolutionDB.evolved_weapons:
		return "evolved"
	var evo = EvolutionDB.get_evolution(evo_id)
	if not evo.is_empty():
		var weapon_level = GameManager.get_weapon_level(evo["weapon_required"])
		var item_level = GameManager.get_item_level(evo["item_required"])
		if weapon_level >= 6 and item_level >= 3:
			return "available"
	var history = SaveManager.data.get("evolution_history", {})
	if evo_id in history:
		return "discovered"
	return "locked"
