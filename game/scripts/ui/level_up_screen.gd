extends CanvasLayer

## Tela de Level Up: 3 opcoes (arma ou item) em cards visuais. Pausa o jogo.

signal choice_made()

@onready var overlay: ColorRect = $Overlay
@onready var panel: PanelContainer = $Panel
@onready var option1_btn: Button = $Panel/VBox/CardArea/Options/Option1
@onready var option2_btn: Button = $Panel/VBox/CardArea/Options/Option2
@onready var option3_btn: Button = $Panel/VBox/CardArea/Options/Option3
@onready var title_label: Label = $Panel/VBox/TitleLabel
@onready var subtitle_label: Label = $Panel/VBox/SubtitleLabel
@onready var options_container: HBoxContainer = $Panel/VBox/CardArea/Options
@onready var reroll_btn: Button = $Panel/VBox/ButtonRow/RerollButton
@onready var banish_btn: Button = $Panel/VBox/ButtonRow/BanishButton

var options: Array = []
var pending_levels: int = 0
var banish_mode: bool = false
var _card_buttons: Array[Button] = []
var _card_panels: Array[PanelContainer] = []
var _auto_check: CheckBox = null

# Multiplayer waiting overlay
var _waiting_overlay: ColorRect = null
var _waiting_label: Label = null

# Async level up (multiplayer)
var _async_mode: bool = false  # true when levelup_sync option is OFF
var _async_timer: float = 0.0
const ASYNC_TIMEOUT: float = 10.0
const ASYNC_INVULN_TIME: float = 3.0
var _choosing_label: Label = null  # "escolhendo..." label shown over player sprite

const TYPE_COLORS = {
	"melee": Color(0.85, 0.25, 0.2),
	"ranged": Color(0.2, 0.5, 0.85),
	"summon": Color(0.6, 0.3, 0.8),
	"item": Color(0.2, 0.75, 0.35),
}
const TYPE_GLOW_COLORS = {
	"melee": Color(0.3, 0.08, 0.05),
	"ranged": Color(0.05, 0.08, 0.3),
	"summon": Color(0.15, 0.05, 0.3),
	"item": Color(0.05, 0.2, 0.08),
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
const ELEMENT_ICONS = {
	"fire": "🔥",
	"ice": "❄",
	"electric": "⚡",
	"dark": "🌑",
	"poison": "☠",
	"arcane": "🔮",
}

func _ready() -> void:
	panel.visible = false
	overlay.visible = false
	# Esconde os botoes originais (usaremos cards dinamicos)
	option1_btn.visible = false
	option2_btn.visible = false
	option3_btn.visible = false
	GameManager.player_leveled_up.connect(_on_level_up)
	reroll_btn.pressed.connect(_on_reroll)
	banish_btn.pressed.connect(_on_banish)

	# Style the panel to be transparent (we handle background ourselves)
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0, 0, 0, 0)
	panel.add_theme_stylebox_override("panel", panel_style)

	# Style title
	title_label.add_theme_font_size_override("font_size", 28)
	title_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))

	# Style subtitle
	subtitle_label.add_theme_font_size_override("font_size", 14)
	subtitle_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))

	# Style reroll button
	_style_action_button(reroll_btn, Color(0.15, 0.25, 0.45), Color(0.3, 0.5, 0.85))
	# Style banish button
	_style_action_button(banish_btn, Color(0.4, 0.12, 0.12), Color(0.85, 0.25, 0.2))

	# Auto-pick checkbox (toggle random auto-selection)
	_auto_check = CheckBox.new()
	_auto_check.text = "Auto"
	_auto_check.button_pressed = GameManager.auto_play
	_auto_check.add_theme_font_size_override("font_size", 12)
	_auto_check.add_theme_color_override("font_color", Color(0.5, 0.5, 0.55))
	_auto_check.toggled.connect(_on_auto_toggled)
	var btn_parent = reroll_btn.get_parent()
	if btn_parent:
		btn_parent.add_child(_auto_check)

	# Build waiting overlay (hidden by default)
	_build_waiting_overlay()

	# Multiplayer signals
	MultiplayerManager.level_up_show.connect(_on_mp_level_up_show)
	MultiplayerManager.level_up_waiting.connect(_on_mp_waiting)
	MultiplayerManager.level_up_resumed.connect(_on_mp_resumed)

func _style_action_button(btn: Button, bg_color: Color, border_color: Color) -> void:
	var normal = StyleBoxFlat.new()
	normal.bg_color = bg_color
	normal.border_color = border_color
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(8)
	normal.content_margin_left = 16
	normal.content_margin_right = 16
	normal.content_margin_top = 8
	normal.content_margin_bottom = 8
	btn.add_theme_stylebox_override("normal", normal)

	var hover = normal.duplicate()
	hover.bg_color = bg_color.lightened(0.15)
	hover.border_color = border_color.lightened(0.2)
	btn.add_theme_stylebox_override("hover", hover)

	var pressed = normal.duplicate()
	pressed.bg_color = bg_color.darkened(0.1)
	btn.add_theme_stylebox_override("pressed", pressed)

	var focus = hover.duplicate()
	focus.border_color = border_color.lightened(0.4)
	focus.set_border_width_all(2)
	btn.add_theme_stylebox_override("focus", focus)

	btn.add_theme_font_size_override("font_size", 13)
	btn.add_theme_color_override("font_color", Color(0.9, 0.9, 0.95))
	btn.add_theme_color_override("font_hover_color", Color.WHITE)

func _on_level_up(_new_level: int) -> void:
	pending_levels += 1
	_async_mode = MultiplayerManager.is_online and not SaveManager.data.get("levelup_sync", true)
	if MultiplayerManager.is_online:
		if _async_mode:
			# Async mode: don't pause, give invulnerability, show choices immediately
			if not panel.visible:
				_start_async_levelup()
			return
		# Sync mode: notify Host to pause globally and coordinate
		MultiplayerManager.request_level_up_pause(MultiplayerManager.local_player_id)
		# Don't show choices yet; wait for Host's RPC signal
		return
	# Solo: show choices immediately (original behavior)
	if not panel.visible:
		_show_choices()
	elif panel.visible and GameManager.paused:
		panel.visible = true

func _process(delta: float) -> void:
	if _async_mode and panel.visible and _async_timer > 0.0:
		_async_timer -= delta
		if _async_timer <= 0.0:
			# Auto-pick after timeout
			if not options.is_empty():
				var rand_idx = randi() % options.size()
				_choose(rand_idx)

func _start_async_levelup() -> void:
	# Give the player invulnerability
	var player = get_tree().get_first_node_in_group("players")
	if player:
		player.can_be_hurt = false
		player.hurt_cooldown = ASYNC_INVULN_TIME
		# Show "escolhendo..." label over the player sprite
		_show_choosing_label(player)
	_async_timer = ASYNC_TIMEOUT
	_show_choices()

func _show_choosing_label(player: Node3D) -> void:
	if _choosing_label and is_instance_valid(_choosing_label):
		_choosing_label.queue_free()
	var label3d = Label3D.new()
	label3d.text = "escolhendo..."
	label3d.font_size = 32
	label3d.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label3d.modulate = Color(1.0, 0.9, 0.3, 0.9)
	label3d.position = Vector3(0, 2.0, 0)
	label3d.name = "ChoosingLabel"
	label3d.no_depth_test = true
	player.add_child(label3d)
	_choosing_label = label3d

func _hide_choosing_label() -> void:
	if _choosing_label and is_instance_valid(_choosing_label):
		_choosing_label.queue_free()
		_choosing_label = null

func _show_choices() -> void:
	options = UpgradeOptionGenerator.generate_options()
	if options.is_empty():
		pending_levels = 0
		return

	# Auto-pick random if auto_play is enabled
	if GameManager.auto_play:
		var rand_idx = randi() % options.size()
		call_deferred("_choose", rand_idx)
		return

	# --- Animate overlay fade in ---
	overlay.visible = true
	overlay.color = Color(0, 0, 0, 0)
	var overlay_tween = create_tween()
	overlay_tween.tween_property(overlay, "color", Color(0, 0, 0, 0.6), 0.25)

	# Title with level number
	if banish_mode:
		title_label.text = LocaleManager.tr_key("banish_select")
		subtitle_label.text = ""
	else:
		title_label.text = "NIVEL %d!" % GameManager.player_level
		subtitle_label.text = "Escolha um upgrade"

	# Title bounce animation
	title_label.pivot_offset = title_label.size / 2.0
	title_label.scale = Vector2(0.5, 0.5)
	var title_tween = create_tween()
	title_tween.set_ease(Tween.EASE_OUT)
	title_tween.set_trans(Tween.TRANS_BACK)
	title_tween.tween_property(title_label, "scale", Vector2.ONE, 0.4)

	# Limpa cards antigos
	_card_buttons.clear()
	_card_panels.clear()
	for child in options_container.get_children():
		if child != option1_btn and child != option2_btn and child != option3_btn:
			child.queue_free()

	# Cria cards visuais com animacao staggered
	for i in range(options.size()):
		_build_card(options[i], i)

	# Reroll button
	if GameManager.rerolls > 0:
		reroll_btn.visible = true
		reroll_btn.text = "🎲 " + LocaleManager.tr_key("reroll") % GameManager.rerolls + " [ESPAÇO]"
	else:
		reroll_btn.visible = false

	# Banish button
	if GameManager.banishes > 0:
		banish_btn.visible = true
		banish_btn.text = "✕ " + LocaleManager.tr_key("banish") % GameManager.banishes
	else:
		banish_btn.visible = false

	banish_mode = false
	panel.visible = true
	if not _async_mode:
		GameManager.paused = true
		if not MultiplayerManager.is_online:
			get_tree().paused = false
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

func _input(event: InputEvent) -> void:
	# Apenas processa se o painel de level up estiver visivel
	if not panel.visible:
		return

	# Intercepta ESPAÇO antes dos botoes (senao ui_accept seleciona o card focado)
	if event is InputEventKey and event.pressed and event.keycode == KEY_SPACE:
		if reroll_btn.visible:
			_on_reroll()
		# Sempre consome o espaco para nao ativar o botao focado
		if get_viewport(): get_viewport().set_input_as_handled()
		return

	# Atalhos numericos para escolher opcoes (1, 2, 3)
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1:
				if options.size() > 0:
					_choose(0)
					if get_viewport(): get_viewport().set_input_as_handled()
			KEY_2:
				if options.size() > 1:
					_choose(1)
					if get_viewport(): get_viewport().set_input_as_handled()
			KEY_3:
				if options.size() > 2:
					_choose(2)
					if get_viewport(): get_viewport().set_input_as_handled()

func _build_card(opt: Dictionary, index: int) -> void:
	# --- Determine card type and colors ---
	var opt_type = opt.get("type", "item")
	var weapon_type = ""
	if opt_type == "weapon":
		weapon_type = WeaponDB.get_weapon(opt["id"]).get("type", "melee")
	var card_type = weapon_type if opt_type == "weapon" else "item"
	var type_color = TYPE_COLORS.get(card_type, Color(0.4, 0.4, 0.4))
	var glow_color = TYPE_GLOW_COLORS.get(card_type, Color(0.1, 0.1, 0.1))

	# Check if this is an evolution (level 8 weapon upgrade)
	var is_evolution = false
	if opt_type == "weapon" and GameManager.has_weapon(opt["id"]):
		var w = GameManager.player_weapons.filter(func(x): return x["id"] == opt["id"])
		if not w.is_empty() and w[0]["level"] >= 7:
			is_evolution = true

	var is_new = not GameManager.has_weapon(opt["id"]) if opt_type == "weapon" else not GameManager.has_item(opt["id"])

	# --- Outer wrapper for glow effect ---
	var card_wrapper = Control.new()
	card_wrapper.custom_minimum_size = Vector2(220, 300)

	# Glow background (ColorRect behind the card)
	var glow_rect = ColorRect.new()
	glow_rect.custom_minimum_size = Vector2(240, 320)
	glow_rect.position = Vector2(-10, -10)
	glow_rect.color = Color(glow_color.r, glow_color.g, glow_color.b, 0.4)
	glow_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card_wrapper.add_child(glow_rect)

	# --- Card panel ---
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(220, 300)
	card.size = Vector2(220, 300)

	var border_color = Color(1.0, 0.85, 0.3) if is_evolution else type_color
	var style = StyleBoxFlat.new()
	# Dark gradient-like background
	style.bg_color = Color(glow_color.r * 0.5 + 0.08, glow_color.g * 0.5 + 0.08, glow_color.b * 0.5 + 0.1, 0.97)
	style.set_corner_radius_all(12)
	style.border_width_top = 2
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = border_color
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 12
	style.content_margin_bottom = 10
	# Shadow for depth
	style.shadow_color = Color(glow_color.r, glow_color.g, glow_color.b, 0.5)
	style.shadow_size = 8
	style.shadow_offset = Vector2(0, 4)
	card.add_theme_stylebox_override("panel", style)
	card_wrapper.add_child(card)

	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_BEGIN
	vbox.add_theme_constant_override("separation", 4)
	card.add_child(vbox)

	# --- 1. Type badge at top ---
	var badge_container = CenterContainer.new()
	vbox.add_child(badge_container)
	var badge_panel = PanelContainer.new()
	var badge_style = StyleBoxFlat.new()
	badge_style.bg_color = Color(type_color.r, type_color.g, type_color.b, 0.25)
	badge_style.set_corner_radius_all(4)
	badge_style.content_margin_left = 8
	badge_style.content_margin_right = 8
	badge_style.content_margin_top = 2
	badge_style.content_margin_bottom = 2
	badge_panel.add_theme_stylebox_override("panel", badge_style)
	badge_container.add_child(badge_panel)
	var badge = Label.new()
	var icon = TYPE_ICONS.get(card_type, "")
	badge.text = "%s %s" % [icon, card_type.to_upper()]
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge.add_theme_font_size_override("font_size", 10)
	badge.add_theme_color_override("font_color", type_color.lightened(0.4))
	badge_panel.add_child(badge)

	# --- Evolution badge ---
	if is_evolution:
		var evo_container = CenterContainer.new()
		vbox.add_child(evo_container)
		var evo_badge = Label.new()
		evo_badge.text = "★ EVOLUÇÃO ★"
		evo_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		evo_badge.add_theme_font_size_override("font_size", 10)
		evo_badge.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
		evo_container.add_child(evo_badge)

	# Small spacer
	var spacer1 = Control.new()
	spacer1.custom_minimum_size = Vector2(0, 4)
	vbox.add_child(spacer1)

	# --- 2. Weapon/Item sprite (64x64 at center) ---
	var icon_container = CenterContainer.new()
	icon_container.custom_minimum_size = Vector2(0, 80)
	vbox.add_child(icon_container)

	# Sprite background circle/glow
	var sprite_bg = ColorRect.new()
	sprite_bg.custom_minimum_size = Vector2(72, 72)
	sprite_bg.color = Color(glow_color.r * 2.0, glow_color.g * 2.0, glow_color.b * 2.0, 0.3)
	icon_container.add_child(sprite_bg)

	var _icon_category = "weapons" if opt_type == "weapon" else "items"
	var _icon_path = "res://assets/sprites/%s/%s.png" % [_icon_category, opt["id"]]
	var _icon_tex = load(_icon_path) if ResourceLoader.exists(_icon_path) else null
	if _icon_tex:
		var tex_rect = TextureRect.new()
		tex_rect.texture = _icon_tex
		tex_rect.custom_minimum_size = Vector2(64, 64)
		tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		tex_rect.anchors_preset = Control.PRESET_CENTER
		tex_rect.position = Vector2(4, 4)
		sprite_bg.add_child(tex_rect)
	else:
		var icon_label = Label.new()
		icon_label.text = TYPE_ICONS.get(card_type, "?")
		icon_label.add_theme_font_size_override("font_size", 36)
		icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		icon_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		icon_label.anchors_preset = Control.PRESET_FULL_RECT
		icon_label.anchor_right = 1.0
		icon_label.anchor_bottom = 1.0
		sprite_bg.add_child(icon_label)

	# --- 3. Name (bold white, 16pt) ---
	var name_label = Label.new()
	name_label.text = UpgradeOptionGenerator.get_opt_name(opt)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.add_theme_color_override("font_color", Color.WHITE if not is_evolution else Color(1.0, 0.92, 0.5))
	vbox.add_child(name_label)

	# --- 4. Level indicator (yellow, or green NEW) ---
	var level_label = Label.new()
	level_label.text = UpgradeOptionGenerator.get_level_text(opt)
	level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	level_label.add_theme_font_size_override("font_size", 12)
	if is_new:
		level_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.4))
	elif is_evolution:
		level_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	else:
		level_label.add_theme_color_override("font_color", Color(0.9, 0.85, 0.5))
	vbox.add_child(level_label)

	# --- 5. Description (11pt, gray) ---
	var desc_label = Label.new()
	desc_label.text = UpgradeOptionGenerator.get_description(opt)
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.add_theme_font_size_override("font_size", 11)
	desc_label.add_theme_color_override("font_color", Color(0.65, 0.65, 0.7))
	desc_label.custom_minimum_size = Vector2(190, 0)
	vbox.add_child(desc_label)

	# --- 6. Element icon badge ---
	var element = UpgradeOptionGenerator.get_element(opt)
	if element != "physical" and element != "":
		var elem_container = CenterContainer.new()
		vbox.add_child(elem_container)
		var elem_panel = PanelContainer.new()
		var elem_color = ELEMENT_COLORS.get(element, Color(0.5, 0.5, 0.5))
		var elem_style = StyleBoxFlat.new()
		elem_style.bg_color = Color(elem_color.r, elem_color.g, elem_color.b, 0.2)
		elem_style.set_corner_radius_all(4)
		elem_style.content_margin_left = 6
		elem_style.content_margin_right = 6
		elem_style.content_margin_top = 1
		elem_style.content_margin_bottom = 1
		elem_panel.add_theme_stylebox_override("panel", elem_style)
		elem_container.add_child(elem_panel)
		var elem_label = Label.new()
		var elem_icon = ELEMENT_ICONS.get(element, "")
		elem_label.text = "%s %s" % [elem_icon, element.capitalize()]
		elem_label.add_theme_font_size_override("font_size", 10)
		elem_label.add_theme_color_override("font_color", elem_color.lightened(0.3))
		elem_panel.add_child(elem_label)

	# --- 7. Stats preview (DPS change) ---
	var stats_text = UpgradeOptionGenerator.get_stats_preview(opt)
	if stats_text != "":
		var stats_label = Label.new()
		stats_label.text = stats_text
		stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		stats_label.add_theme_font_size_override("font_size", 10)
		stats_label.add_theme_color_override("font_color", Color(0.4, 0.9, 0.4))
		vbox.add_child(stats_label)

	# Flexible spacer to push shortcut to bottom
	var spacer_bottom = Control.new()
	spacer_bottom.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer_bottom)

	# --- Keyboard shortcut at bottom ---
	var shortcut_label = Label.new()
	shortcut_label.text = "[%d]" % (index + 1)
	shortcut_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	shortcut_label.add_theme_font_size_override("font_size", 11)
	shortcut_label.add_theme_color_override("font_color", Color(0.45, 0.55, 0.7))
	vbox.add_child(shortcut_label)

	# --- Clickable button overlay ---
	var btn = Button.new()
	btn.flat = true
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.anchors_preset = Control.PRESET_FULL_RECT
	btn.anchor_right = 1.0
	btn.anchor_bottom = 1.0
	# Make button transparent when focused too
	var btn_style_empty = StyleBoxEmpty.new()
	btn.add_theme_stylebox_override("normal", btn_style_empty)
	btn.add_theme_stylebox_override("hover", btn_style_empty)
	btn.add_theme_stylebox_override("pressed", btn_style_empty)
	var btn_focus_style = StyleBoxFlat.new()
	btn_focus_style.bg_color = Color(0, 0, 0, 0)
	btn_focus_style.border_color = Color(1.0, 1.0, 1.0, 0.5)
	btn_focus_style.set_border_width_all(2)
	btn_focus_style.set_corner_radius_all(12)
	btn.add_theme_stylebox_override("focus", btn_focus_style)

	var idx = index
	btn.pressed.connect(func(): _choose(idx))

	# Hover: scale up card + brighten border + increase glow
	var _style_ref = style
	var _glow_ref = glow_rect
	var _card_ref = card
	var _border_base = border_color
	var _glow_base_alpha = 0.4
	btn.mouse_entered.connect(func():
		var tw = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		tw.tween_property(card_wrapper, "scale", Vector2(1.05, 1.05), 0.15)
		# Center the scale from pivot
		card_wrapper.pivot_offset = card_wrapper.size / 2.0
		_style_ref.border_color = _border_base.lightened(0.35)
		_style_ref.shadow_size = 14
		_glow_ref.color.a = 0.65
		_card_ref.add_theme_stylebox_override("panel", _style_ref)
	)
	btn.mouse_exited.connect(func():
		var tw = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
		tw.tween_property(card_wrapper, "scale", Vector2.ONE, 0.15)
		_style_ref.border_color = _border_base
		_style_ref.shadow_size = 8
		_glow_ref.color.a = _glow_base_alpha
		_card_ref.add_theme_stylebox_override("panel", _style_ref)
	)
	card.add_child(btn)
	_card_buttons.append(btn)
	_card_panels.append(card)

	options_container.add_child(card_wrapper)

	# --- Slide-in animation (staggered from bottom with bounce) ---
	card_wrapper.pivot_offset = Vector2(110, 150)
	card_wrapper.modulate = Color(1, 1, 1, 0)
	card_wrapper.position.y += 60
	var slide_tween = create_tween()
	slide_tween.set_ease(Tween.EASE_OUT)
	slide_tween.set_trans(Tween.TRANS_BACK)
	var delay = index * 0.1
	slide_tween.tween_interval(delay)
	slide_tween.tween_property(card_wrapper, "position:y", card_wrapper.position.y - 60, 0.4)
	var fade_tween = create_tween()
	fade_tween.tween_interval(delay)
	fade_tween.tween_property(card_wrapper, "modulate:a", 1.0, 0.3)

## Data helpers delegated to UpgradeOptionGenerator

func _choose(index: int) -> void:
	if index >= options.size():
		return

	if banish_mode:
		_banish_option(index)
		return

	AudioManager.play_sfx("select")
	var opt = options[index]

	# --- Click flash animation ---
	if index < _card_panels.size():
		var flash_card = _card_panels[index]
		var flash_tween = create_tween()
		flash_tween.tween_property(flash_card, "modulate", Color(2.0, 2.0, 2.0, 1.0), 0.05)
		flash_tween.tween_property(flash_card, "modulate", Color.WHITE, 0.15)

	# Apply the upgrade locally
	_apply_choice(opt)
	AudioManager.play_sfx("equip")

	# Small delay to show the flash before hiding
	await get_tree().create_timer(0.15).timeout

	# Fade out overlay
	var fade_tween = create_tween()
	fade_tween.tween_property(overlay, "color", Color(0, 0, 0, 0), 0.2)

	panel.visible = false
	pending_levels -= 1

	# Clean up async state
	if _async_mode:
		_async_timer = 0.0
		_hide_choosing_label()

	if MultiplayerManager.is_online:
		if _async_mode:
			if pending_levels > 0:
				call_deferred("_start_async_levelup")
		else:
			var choice_data = {"type": opt["type"], "id": opt["id"]}
			MultiplayerManager.submit_level_up_choice(MultiplayerManager.local_player_id, choice_data)
			if pending_levels > 0:
				MultiplayerManager.request_level_up_pause(MultiplayerManager.local_player_id)
	else:
		if pending_levels > 0:
			call_deferred("_show_choices")
		else:
			GameManager.paused = false
	choice_made.emit()

## Applies the chosen upgrade to local GameManager state.
func _apply_choice(opt: Dictionary) -> void:
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

## Option generation delegated to UpgradeOptionGenerator

func _on_auto_toggled(enabled: bool) -> void:
	GameManager.auto_play = enabled
	# If just enabled and panel is visible, auto-pick immediately
	if enabled and panel.visible and not options.is_empty():
		var rand_idx = randi() % options.size()
		_choose(rand_idx)

func _on_reroll() -> void:
	if GameManager.rerolls <= 0:
		return
	GameManager.rerolls -= 1
	AudioManager.play_sfx("reroll")
	_show_choices()

func _on_banish() -> void:
	if GameManager.banishes <= 0:
		return
	AudioManager.play_sfx("banish")
	banish_mode = true
	title_label.text = LocaleManager.tr_key("banish_select")
	subtitle_label.text = ""
	banish_btn.visible = false

func _banish_option(index: int) -> void:
	var opt = options[index]
	GameManager.banished_options.append(opt["id"])
	GameManager.banishes -= 1
	banish_mode = false

	# Show banished name briefly before closing
	var banished_name = UpgradeOptionGenerator.get_opt_name(opt)
	title_label.text = "✕ %s banido" % banished_name
	subtitle_label.text = ""

	# Flash the card red
	if index < _card_panels.size():
		var flash_card = _card_panels[index]
		var flash_tween = create_tween()
		flash_tween.tween_property(flash_card, "modulate", Color(1.0, 0.3, 0.3, 0.6), 0.15)
		flash_tween.tween_property(flash_card, "modulate", Color(1.0, 0.3, 0.3, 0.0), 0.3)

	await get_tree().create_timer(0.6).timeout

	# Close level-up screen (banish consumes the level)
	var fade_tween = create_tween()
	fade_tween.tween_property(overlay, "color", Color(0, 0, 0, 0), 0.2)

	panel.visible = false
	pending_levels -= 1

	if _async_mode:
		_async_timer = 0.0
		_hide_choosing_label()

	if MultiplayerManager.is_online:
		if _async_mode:
			if pending_levels > 0:
				call_deferred("_start_async_levelup")
		else:
			var choice_data = {"type": "banish", "id": opt["id"]}
			MultiplayerManager.submit_level_up_choice(MultiplayerManager.local_player_id, choice_data)
			if pending_levels > 0:
				MultiplayerManager.request_level_up_pause(MultiplayerManager.local_player_id)
	else:
		if pending_levels > 0:
			call_deferred("_show_choices")
		else:
			GameManager.paused = false
	choice_made.emit()

# ---- Multiplayer Level Up Coordination ----

## Build the "Aguardando..." overlay (created once, shown/hidden as needed).
func _build_waiting_overlay() -> void:
	_waiting_overlay = ColorRect.new()
	_waiting_overlay.name = "WaitingOverlay"
	_waiting_overlay.color = Color(0, 0, 0, 0.7)
	_waiting_overlay.anchors_preset = Control.PRESET_FULL_RECT
	_waiting_overlay.anchor_right = 1.0
	_waiting_overlay.anchor_bottom = 1.0
	_waiting_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_waiting_overlay.visible = false
	# Must work while tree is paused
	_waiting_overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_waiting_overlay)

	_waiting_label = Label.new()
	_waiting_label.text = "Aguardando..."
	_waiting_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_waiting_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_waiting_label.anchors_preset = Control.PRESET_CENTER
	_waiting_label.anchor_left = 0.5
	_waiting_label.anchor_top = 0.5
	_waiting_label.anchor_right = 0.5
	_waiting_label.anchor_bottom = 0.5
	_waiting_label.offset_left = -200
	_waiting_label.offset_top = -30
	_waiting_label.offset_right = 200
	_waiting_label.offset_bottom = 30
	_waiting_label.add_theme_font_size_override("font_size", 28)
	_waiting_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	_waiting_overlay.add_child(_waiting_label)

## Host tells this player to show their level-up choices.
func _on_mp_level_up_show(_peer_id: int) -> void:
	_waiting_overlay.visible = false
	if pending_levels > 0 and not panel.visible:
		_show_choices()

## Another player is leveling up; show "Aguardando..." overlay.
func _on_mp_waiting() -> void:
	if not panel.visible:
		_waiting_overlay.visible = true

## Host has unpaused the game; hide all overlays.
func _on_mp_resumed() -> void:
	_waiting_overlay.visible = false
	GameManager.paused = false
