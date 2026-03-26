extends CanvasLayer

## Tela de Level Up: 3 opcoes (arma ou item) em cards visuais. Pausa o jogo.

signal choice_made()

@onready var panel: PanelContainer = $Panel
@onready var option1_btn: Button = $Panel/VBox/Options/Option1
@onready var option2_btn: Button = $Panel/VBox/Options/Option2
@onready var option3_btn: Button = $Panel/VBox/Options/Option3
@onready var title_label: Label = $Panel/VBox/TitleLabel
@onready var options_container: HBoxContainer = $Panel/VBox/Options
@onready var reroll_btn: Button = $Panel/VBox/RerollButton
@onready var banish_btn: Button = $Panel/VBox/BanishButton

var options: Array = []
var pending_levels: int = 0
var banish_mode: bool = false
var _card_buttons: Array[Button] = []

const TYPE_COLORS = {
	"melee": Color(0.85, 0.25, 0.2),
	"ranged": Color(0.2, 0.5, 0.85),
	"summon": Color(0.6, 0.3, 0.8),
	"item": Color(0.2, 0.75, 0.35),
}
const ELEMENT_COLORS = {
	"fire": Color(1.0, 0.4, 0.1),
	"ice": Color(0.3, 0.7, 1.0),
	"electric": Color(1.0, 0.9, 0.2),
	"dark": Color(0.6, 0.2, 0.8),
	"physical": Color(0.7, 0.7, 0.7),
	"poison": Color(0.3, 0.8, 0.2),
	"arcane": Color(0.8, 0.3, 0.9),
}
const TYPE_ICONS = {
	"melee": "⚔",
	"ranged": "🏹",
	"summon": "✨",
	"item": "💎",
}

func _ready() -> void:
	panel.visible = false
	# Esconde os botoes originais (usaremos cards dinamicos)
	option1_btn.visible = false
	option2_btn.visible = false
	option3_btn.visible = false
	GameManager.player_leveled_up.connect(_on_level_up)
	reroll_btn.pressed.connect(_on_reroll)
	banish_btn.pressed.connect(_on_banish)

func _on_level_up(_new_level: int) -> void:
	pending_levels += 1
	if not panel.visible:
		_show_choices()

func _show_choices() -> void:
	options = _generate_options()
	if options.is_empty():
		pending_levels = 0
		return

	title_label.text = LocaleManager.tr_key("level_up_title") % GameManager.player_level

	# Limpa cards antigos
	_card_buttons.clear()
	for child in options_container.get_children():
		if child != option1_btn and child != option2_btn and child != option3_btn:
			child.queue_free()

	# Cria cards visuais
	for i in range(options.size()):
		_build_card(options[i], i)

	# Reroll button
	if GameManager.rerolls > 0:
		reroll_btn.visible = true
		reroll_btn.text = LocaleManager.tr_key("reroll") % GameManager.rerolls
	else:
		reroll_btn.visible = false

	# Banish button
	if GameManager.banishes > 0:
		banish_btn.visible = true
		banish_btn.text = LocaleManager.tr_key("banish") % GameManager.banishes
	else:
		banish_btn.visible = false

	banish_mode = false
	panel.visible = true
	GameManager.paused = true
	# Gamepad: foca na primeira opcao
	_setup_levelup_focus()
	GamepadUI.notify_menu_opened()

func _setup_levelup_focus() -> void:
	var focusable: Array[Button] = []
	for btn in _card_buttons:
		if is_instance_valid(btn) and btn.visible:
			btn.focus_mode = Control.FOCUS_ALL
			focusable.append(btn)
	if reroll_btn.visible:
		reroll_btn.focus_mode = Control.FOCUS_ALL
		focusable.append(reroll_btn)
	if banish_btn.visible:
		banish_btn.focus_mode = Control.FOCUS_ALL
		focusable.append(banish_btn)
	for i in range(focusable.size()):
		var btn = focusable[i]
		if i > 0:
			btn.focus_neighbor_left = focusable[i - 1].get_path()
			btn.focus_neighbor_top = focusable[i - 1].get_path()
		if i < focusable.size() - 1:
			btn.focus_neighbor_right = focusable[i + 1].get_path()
			btn.focus_neighbor_bottom = focusable[i + 1].get_path()
	if not focusable.is_empty():
		focusable[0].grab_focus()

func _build_card(opt: Dictionary, index: int) -> void:
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(200, 260)

	# Card style
	var opt_type = opt.get("type", "item")
	var weapon_type = ""
	if opt_type == "weapon":
		weapon_type = WeaponDB.get_weapon(opt["id"]).get("type", "melee")
	var card_type = weapon_type if opt_type == "weapon" else "item"
	var type_color = TYPE_COLORS.get(card_type, Color(0.4, 0.4, 0.4))
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.12, 0.16, 0.95)
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	style.border_width_top = 3
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = type_color
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	card.add_theme_stylebox_override("panel", style)

	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 6)
	card.add_child(vbox)

	# Type badge
	var badge = Label.new()
	var icon = TYPE_ICONS.get(card_type, "")
	badge.text = "%s %s" % [icon, card_type.to_upper()]
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge.add_theme_font_size_override("font_size", 11)
	badge.add_theme_color_override("font_color", type_color.lightened(0.3))
	vbox.add_child(badge)

	# Icon area with element color
	var icon_container = CenterContainer.new()
	icon_container.custom_minimum_size = Vector2(0, 70)
	vbox.add_child(icon_container)
	var icon_rect = ColorRect.new()
	icon_rect.custom_minimum_size = Vector2(64, 64)
	var element = _get_element(opt)
	var elem_color = ELEMENT_COLORS.get(element, Color(0.5, 0.5, 0.5))
	icon_rect.color = elem_color.darkened(0.4)
	icon_container.add_child(icon_rect)
	# Type icon overlay
	var icon_label = Label.new()
	icon_label.text = TYPE_ICONS.get(card_type, "?")
	icon_label.add_theme_font_size_override("font_size", 28)
	icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	icon_label.anchors_preset = Control.PRESET_FULL_RECT
	icon_rect.add_child(icon_label)

	# Name
	var name_label = Label.new()
	name_label.text = _get_opt_name(opt)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 15)
	name_label.add_theme_color_override("font_color", Color.WHITE)
	vbox.add_child(name_label)

	# Level / New badge
	var level_label = Label.new()
	level_label.text = _get_level_text(opt)
	level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	level_label.add_theme_font_size_override("font_size", 12)
	var is_new = not GameManager.has_weapon(opt["id"]) if opt_type == "weapon" else not GameManager.has_item(opt["id"])
	level_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.4) if is_new else Color(0.9, 0.85, 0.5))
	vbox.add_child(level_label)

	# Description
	var desc_label = Label.new()
	desc_label.text = _get_description(opt)
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.add_theme_font_size_override("font_size", 11)
	desc_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	desc_label.custom_minimum_size = Vector2(170, 0)
	vbox.add_child(desc_label)

	# Clickable button overlay
	var btn = Button.new()
	btn.flat = true
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.anchors_preset = Control.PRESET_FULL_RECT
	btn.anchor_right = 1.0
	btn.anchor_bottom = 1.0
	var idx = index
	btn.pressed.connect(func(): _choose(idx))
	# Hover effect
	btn.mouse_entered.connect(func(): style.border_color = type_color.lightened(0.4); card.add_theme_stylebox_override("panel", style))
	btn.mouse_exited.connect(func(): style.border_color = type_color; card.add_theme_stylebox_override("panel", style))
	card.add_child(btn)
	_card_buttons.append(btn)

	options_container.add_child(card)

func _get_opt_name(opt: Dictionary) -> String:
	if opt["type"] == "weapon":
		return WeaponDB.get_weapon(opt["id"])["name"]
	else:
		return ItemDB.get_item(opt["id"])["name"]

func _get_level_text(opt: Dictionary) -> String:
	if opt["type"] == "weapon":
		if GameManager.has_weapon(opt["id"]):
			var w = GameManager.player_weapons.filter(func(x): return x["id"] == opt["id"])
			if not w.is_empty():
				return "Lv.%d → %d" % [w[0]["level"], w[0]["level"] + 1]
		return LocaleManager.tr_key("new").to_upper()
	else:
		if GameManager.has_item(opt["id"]):
			var it = GameManager.player_items.filter(func(x): return x["id"] == opt["id"])
			if not it.is_empty():
				return "Lv.%d → %d" % [it[0]["level"], it[0]["level"] + 1]
		return LocaleManager.tr_key("new").to_upper()

func _get_description(opt: Dictionary) -> String:
	if opt["type"] == "weapon":
		return WeaponDB.get_weapon(opt["id"]).get("description", "")
	else:
		return ItemDB.get_item(opt["id"]).get("description", "")

func _get_element(opt: Dictionary) -> String:
	if opt["type"] == "weapon":
		return WeaponDB.get_weapon(opt["id"]).get("element", "physical")
	return "physical"
	# ja impede gameplay de rodar.

func _choose(index: int) -> void:
	if index >= options.size():
		return

	if banish_mode:
		_banish_option(index)
		return

	var opt = options[index]
	match opt["type"]:
		"weapon":
			if GameManager.has_weapon(opt["id"]):
				GameManager.upgrade_weapon(opt["id"])
			else:
				GameManager.add_weapon(opt["id"])
				# Spawna o node da arma no player
				var player = get_tree().get_first_node_in_group("players")
				if player and player.has_method("add_weapon_node"):
					player.add_weapon_node(opt["id"])
		"item":
			GameManager.add_item(opt["id"])

	panel.visible = false
	pending_levels -= 1

	if pending_levels > 0:
		# Mostra proxima escolha
		call_deferred("_show_choices")
	else:
		GameManager.paused = false
	choice_made.emit()

func _generate_options() -> Array:
	var pool: Array = []

	# Armas que o jogador ja tem (upgrade)
	for w in GameManager.player_weapons:
		if w["level"] < 8:
			var data = WeaponDB.get_weapon(w["id"])
			pool.append({
				"type": "weapon",
				"id": w["id"],
				"label": "%s (Lv.%d → %d)" % [data["name"], w["level"], w["level"] + 1],
				"weight": 10,
			})

	# Armas novas (se tem slot)
	if GameManager.player_weapons.size() < GameManager.MAX_WEAPONS:
		for wid in WeaponDB.get_all_weapon_ids():
			if not GameManager.has_weapon(wid):
				var data = WeaponDB.get_weapon(wid)
				pool.append({
					"type": "weapon",
					"id": wid,
					"label": "%s (%s)" % [data["name"], LocaleManager.tr_key("new")],
					"weight": 8,
				})

	# Itens que o jogador ja tem (upgrade)
	for it in GameManager.player_items:
		if it["level"] < 5:
			var data = ItemDB.get_item(it["id"])
			pool.append({
				"type": "item",
				"id": it["id"],
				"label": "%s (Lv.%d → %d)" % [data["name"], it["level"], it["level"] + 1],
				"weight": 10,
			})

	# Itens novos (se tem slot)
	if GameManager.player_items.size() < GameManager.MAX_ITEMS:
		for iid in ItemDB.get_all_item_ids():
			if not GameManager.has_item(iid):
				var data = ItemDB.get_item(iid)
				pool.append({
					"type": "item",
					"id": iid,
					"label": "%s (%s)" % [data["name"], LocaleManager.tr_key("new")],
					"weight": 8,
				})

	# Filter banished options
	pool = pool.filter(func(opt): return opt["id"] not in GameManager.banished_options)

	# Weighted random selection (luck_mult increases rare weapon chance)
	var selected: Array = []
	for _i in range(3):
		if pool.is_empty():
			break
		var total_weight = 0.0
		for opt in pool:
			total_weight += opt["weight"] * GameManager.luck_mult
		var roll = randf() * total_weight
		var cumulative = 0.0
		for j in range(pool.size()):
			cumulative += pool[j]["weight"] * GameManager.luck_mult
			if roll <= cumulative:
				selected.append(pool[j])
				pool.remove_at(j)
				break
	return selected

func _on_reroll() -> void:
	if GameManager.rerolls <= 0:
		return
	GameManager.rerolls -= 1
	_show_choices()

func _on_banish() -> void:
	if GameManager.banishes <= 0:
		return
	banish_mode = true
	title_label.text = LocaleManager.tr_key("banish_select")
	banish_btn.visible = false

func _banish_option(index: int) -> void:
	var opt = options[index]
	GameManager.banished_options.append(opt["id"])
	GameManager.banishes -= 1
	banish_mode = false
	_show_choices()
