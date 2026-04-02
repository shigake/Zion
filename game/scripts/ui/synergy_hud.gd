extends Control

## Icon-based synergy display for the HUD.
## Replaces the old text-based VBoxContainer with colored icon panels,
## hover tooltips, flash-on-proc feedback, and a first-activation banner.

const MAX_VISIBLE_ICONS = 6
const ICON_SIZE = 36
const ICON_SPACING = 4
const FLASH_DURATION = 0.3
const BANNER_DURATION = 2.0

var _synergy_icons: Dictionary = {}  # synergy_name -> Panel
var _first_procs: Dictionary = {}  # track first proc per run
var _icon_container: HBoxContainer
var _tooltip_panel: PanelContainer
var _tooltip_name_label: Label
var _tooltip_type_label: Label
var _tooltip_effect_label: Label
var _tooltip_trigger_label: Label
var _tooltip_cooldown_label: Label
var _banner_label: Label

func _ready() -> void:
	_build_ui()
	SynergySystem.synergy_activated.connect(_on_synergy_activated)
	SynergySystem.synergy_procced.connect(_on_synergy_procced)

func _build_ui() -> void:
	# Main container — anchored bottom-left, above weapon panel area
	_icon_container = HBoxContainer.new()
	_icon_container.add_theme_constant_override("separation", ICON_SPACING)
	add_child(_icon_container)

	# Tooltip panel (hidden by default)
	_build_tooltip()

	# Banner for first activation (centered top)
	_build_banner()

func _build_tooltip() -> void:
	_tooltip_panel = PanelContainer.new()
	_tooltip_panel.visible = false
	_tooltip_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tooltip_panel.z_index = 50

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.05, 0.1, 0.92)
	style.border_color = Color(0.4, 0.5, 0.7, 0.8)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(8)
	_tooltip_panel.add_theme_stylebox_override("panel", style)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 3)

	_tooltip_name_label = Label.new()
	_tooltip_name_label.add_theme_font_size_override("font_size", 15)
	_tooltip_name_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.5))
	vbox.add_child(_tooltip_name_label)

	_tooltip_type_label = Label.new()
	_tooltip_type_label.add_theme_font_size_override("font_size", 12)
	_tooltip_type_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	vbox.add_child(_tooltip_type_label)

	var sep = HSeparator.new()
	sep.add_theme_constant_override("separation", 4)
	vbox.add_child(sep)

	_tooltip_effect_label = Label.new()
	_tooltip_effect_label.add_theme_font_size_override("font_size", 13)
	_tooltip_effect_label.add_theme_color_override("font_color", Color.WHITE)
	_tooltip_effect_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_tooltip_effect_label.custom_minimum_size.x = 200
	vbox.add_child(_tooltip_effect_label)

	_tooltip_trigger_label = Label.new()
	_tooltip_trigger_label.add_theme_font_size_override("font_size", 11)
	_tooltip_trigger_label.add_theme_color_override("font_color", Color(0.6, 0.8, 0.6))
	vbox.add_child(_tooltip_trigger_label)

	_tooltip_cooldown_label = Label.new()
	_tooltip_cooldown_label.add_theme_font_size_override("font_size", 11)
	_tooltip_cooldown_label.add_theme_color_override("font_color", Color(0.6, 0.7, 0.9))
	vbox.add_child(_tooltip_cooldown_label)

	_tooltip_panel.add_child(vbox)
	add_child(_tooltip_panel)

func _build_banner() -> void:
	_banner_label = Label.new()
	_banner_label.visible = false
	_banner_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_banner_label.add_theme_font_size_override("font_size", 24)
	_banner_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.4))
	_banner_label.add_theme_constant_override("outline_size", 3)
	_banner_label.add_theme_color_override("font_outline_color", Color(0.1, 0.05, 0.0))
	# Position: centered horizontally, near top of screen
	_banner_label.anchor_left = 0.0
	_banner_label.anchor_right = 1.0
	_banner_label.anchor_top = 0.0
	_banner_label.anchor_bottom = 0.0
	_banner_label.offset_top = 60.0
	_banner_label.offset_bottom = 100.0
	add_child(_banner_label)

func _on_synergy_activated(synergy_name: String, synergy_data: Dictionary) -> void:
	if synergy_name in _synergy_icons:
		return  # Already displayed
	_add_synergy_icon(synergy_name, synergy_data)

func _add_synergy_icon(synergy_name: String, data: Dictionary) -> void:
	if _synergy_icons.size() >= MAX_VISIBLE_ICONS:
		return  # Cap visible icons

	var panel = Panel.new()
	panel.custom_minimum_size = Vector2(ICON_SIZE, ICON_SIZE)

	# Colored background with border
	var style = StyleBoxFlat.new()
	var color: Color = data.get("color", Color.WHITE)
	style.bg_color = color * 0.4
	style.bg_color.a = 0.85
	style.border_color = color
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	panel.add_theme_stylebox_override("panel", style)

	# Symbol label centered inside the panel
	var label = Label.new()
	label.text = data.get("icon_symbol", "?")
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 18)
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.add_child(label)

	# Mouse hover for tooltip
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.mouse_entered.connect(_show_tooltip.bind(synergy_name, panel))
	panel.mouse_exited.connect(_hide_tooltip)

	_icon_container.add_child(panel)
	_synergy_icons[synergy_name] = panel

	# Entry animation — scale from zero
	panel.pivot_offset = Vector2(ICON_SIZE / 2.0, ICON_SIZE / 2.0)
	panel.scale = Vector2.ZERO
	var tween = create_tween()
	tween.tween_property(panel, "scale", Vector2.ONE, 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

func _on_synergy_procced(synergy_name: String, damage: float) -> void:
	# Flash the icon
	if synergy_name in _synergy_icons:
		_flash_icon(_synergy_icons[synergy_name])

	# First proc banner
	if synergy_name not in _first_procs:
		_first_procs[synergy_name] = true
		_show_activation_banner(synergy_name)

func _flash_icon(panel: Panel) -> void:
	var tween = create_tween()
	tween.tween_property(panel, "modulate", Color(2.0, 2.0, 2.0, 1.0), FLASH_DURATION * 0.5)
	tween.tween_property(panel, "modulate", Color.WHITE, FLASH_DURATION * 0.5)

func _show_tooltip(synergy_name: String, anchor: Panel) -> void:
	var info = SynergySystem.get_synergy_info(synergy_name)

	# Localized synergy name (fallback to SYNERGY_INFO name)
	var loc_name_key = "synergy_name_" + synergy_name
	var loc_name = LocaleManager.tr_key(loc_name_key)
	if loc_name == loc_name_key:
		loc_name = info.get("name", synergy_name)
	_tooltip_name_label.text = "%s  %s" % [info.get("icon_symbol", ""), loc_name]

	# Type label
	var type_key := "synergy_tooltip_type_base"
	match info.get("type", "base"):
		"water":
			type_key = "synergy_tooltip_type_water"
		"cross":
			type_key = "synergy_tooltip_type_cross"
	_tooltip_type_label.text = LocaleManager.tr_key(type_key)

	# Localized synergy effect (fallback to SYNERGY_INFO effect)
	var loc_effect_key = "synergy_effect_" + synergy_name
	var loc_effect = LocaleManager.tr_key(loc_effect_key)
	if loc_effect == loc_effect_key:
		loc_effect = info.get("effect", "")
	_tooltip_effect_label.text = loc_effect

	# Color the effect text with the synergy color for visual clarity
	var syn_color: Color = info.get("color", Color.WHITE)
	_tooltip_effect_label.add_theme_color_override("font_color", syn_color.lightened(0.3))

	_tooltip_trigger_label.text = info.get("trigger", "")

	var cd: float = info.get("cooldown", 0.0)
	if cd > 0.0:
		_tooltip_cooldown_label.text = LocaleManager.tr_key("synergy_tooltip_cooldown") % cd
		_tooltip_cooldown_label.visible = true
	else:
		_tooltip_cooldown_label.visible = false

	# Position tooltip above the icon
	var anchor_rect = anchor.get_global_rect()
	_tooltip_panel.reset_size()
	# Force layout update
	await get_tree().process_frame
	var tp_size = _tooltip_panel.size
	var tp_x = anchor_rect.position.x
	var tp_y = anchor_rect.position.y - tp_size.y - 6
	# Clamp to screen
	if tp_x + tp_size.x > 1280:
		tp_x = 1280 - tp_size.x - 4
	if tp_x < 0:
		tp_x = 4
	if tp_y < 0:
		tp_y = anchor_rect.position.y + anchor_rect.size.y + 6
	_tooltip_panel.global_position = Vector2(tp_x, tp_y)
	_tooltip_panel.visible = true

func _hide_tooltip() -> void:
	_tooltip_panel.visible = false

func _show_activation_banner(synergy_name: String) -> void:
	var info = SynergySystem.get_synergy_info(synergy_name)
	var resonance_text = LocaleManager.tr_key("crystal_resonance")
	# Use localized name for the banner
	var loc_name_key = "synergy_name_" + synergy_name
	var display_name = LocaleManager.tr_key(loc_name_key)
	if display_name == loc_name_key:
		display_name = info.get("name", synergy_name)
	_banner_label.text = "%s: %s!" % [resonance_text, display_name]
	# Color the banner with synergy color
	var syn_color: Color = info.get("color", Color(1.0, 0.9, 0.4))
	_banner_label.add_theme_color_override("font_color", syn_color.lightened(0.2))
	_banner_label.visible = true
	_banner_label.modulate.a = 1.0

	AudioManager.play_sfx("crystal_pickup")

	var tween = create_tween()
	tween.tween_interval(BANNER_DURATION - 0.5)
	tween.tween_property(_banner_label, "modulate:a", 0.0, 0.5)
	tween.tween_callback(func(): _banner_label.visible = false)

func remove_stale_synergies() -> void:
	## Called when synergies change — remove icons for synergies no longer active.
	var to_remove: Array[String] = []
	for syn_id in _synergy_icons:
		if syn_id not in SynergySystem.active_synergies:
			to_remove.append(syn_id)
	for syn_id in to_remove:
		var icon = _synergy_icons[syn_id]
		if is_instance_valid(icon):
			icon.queue_free()
		_synergy_icons.erase(syn_id)

func reset() -> void:
	_first_procs.clear()
	for icon in _synergy_icons.values():
		if is_instance_valid(icon):
			icon.queue_free()
	_synergy_icons.clear()
	_hide_tooltip()
	_banner_label.visible = false
