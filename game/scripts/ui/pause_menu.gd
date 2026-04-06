extends CanvasLayer

## Pause menu — ESC para pausar/despausar.
## Visual: dark+gold aesthetic matching main menu.

@onready var panel: PanelContainer = $Panel
@onready var overlay: ColorRect = $Overlay
@onready var resume_btn: Button = $Panel/VBox/ResumeButton
@onready var menu_btn: Button = $Panel/VBox/MenuButton

var options_panel: PanelContainer = null
var options_btn_ref: Button = null
var quit_btn_ref: Button = null
var waiting_for_key: String = ""
var keybind_buttons: Dictionary = {}
# Guarda se o jogo ja estava "pausado" antes do pause ser aberto
# (ex: levelup aberto). Ao retomar, restaura esse estado.
var _was_gm_paused_before: bool = false
var _vignette: ColorRect = null
var _gold_line: ColorRect = null
var _title_ref: Label = null
var _separator_line: ColorRect = null
var _original_panel_y: float = 0.0

func _ready() -> void:
	panel.visible = false
	overlay.visible = false
	resume_btn.pressed.connect(_on_resume)
	menu_btn.pressed.connect(_on_menu)

	if not InputMap.has_action("pause"):
		InputMap.add_action("pause")
	# Always ensure ESC is mapped (GameManager may have created the action with only gamepad)
	var already_has_key := false
	for ev in InputMap.action_get_events("pause"):
		if ev is InputEventKey and ev.physical_keycode == KEY_ESCAPE:
			already_has_key = true
			break
	if not already_has_key:
		var event = InputEventKey.new()
		event.physical_keycode = KEY_ESCAPE
		InputMap.action_add_event("pause", event)

	# ---- Apply dark+gold visual styling ----
	_apply_overlay_style()
	_apply_panel_style()
	_apply_title_style()
	_apply_gold_line()
	_apply_separator_style()

	# Aplica texto localizado nos botoes da cena
	resume_btn.text = LocaleManager.tr_key("resume")
	menu_btn.text = LocaleManager.tr_key("quit_to_menu")
	# Atualiza textos quando o idioma mudar
	LocaleManager.locale_changed.connect(_on_locale_changed)

	# Style resume button (highlighted golden)
	_apply_resume_button_style(resume_btn)

	# Style menu button (quit/reddish)
	_apply_quit_button_style(menu_btn)

	# Options button
	options_btn_ref = Button.new()
	options_btn_ref.text = LocaleManager.tr_key("options")
	options_btn_ref.custom_minimum_size = Vector2(0, 44)
	options_btn_ref.pressed.connect(_on_options)
	_apply_normal_button_style(options_btn_ref)
	$Panel/VBox.add_child(options_btn_ref)
	$Panel/VBox.move_child(options_btn_ref, 2)  # After Resume, before Menu

	# Quit button (fecha a aplicacao)
	quit_btn_ref = Button.new()
	quit_btn_ref.text = LocaleManager.tr_key("quit_game")
	quit_btn_ref.custom_minimum_size = Vector2(0, 44)
	quit_btn_ref.pressed.connect(_on_quit)
	_apply_quit_button_style(quit_btn_ref)
	$Panel/VBox.add_child(quit_btn_ref)

	# Apply style to existing scene buttons
	resume_btn.custom_minimum_size = Vector2(0, 44)
	menu_btn.custom_minimum_size = Vector2(0, 44)
	resume_btn.add_theme_font_size_override("font_size", 18)
	menu_btn.add_theme_font_size_override("font_size", 18)

# ---- Overlay: two layers (solid bg + central vignette) ----
func _apply_overlay_style() -> void:
	overlay.color = Color(0.0, 0.0, 0.0, 0.72)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE

	_vignette = ColorRect.new()
	_vignette.name = "Vignette"
	_vignette.color = Color(0.05, 0.04, 0.10, 0.55)
	_vignette.anchors_preset = Control.PRESET_CENTER
	_vignette.set_anchors_preset(Control.PRESET_CENTER)
	_vignette.offset_left = -300.0
	_vignette.offset_top = -250.0
	_vignette.offset_right = 300.0
	_vignette.offset_bottom = 250.0
	_vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vignette.visible = false
	add_child(_vignette)
	# Make sure vignette is behind the panel
	if panel.get_index() >= 0:
		move_child(_vignette, panel.get_index())

# ---- Panel central: dark bg, golden border, shadow ----
func _apply_panel_style() -> void:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.03, 0.03, 0.06, 0.97)
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.9, 0.8, 0.3)
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	style.shadow_color = Color(0.9, 0.75, 0.2, 0.18)
	style.shadow_size = 12
	style.content_margin_left = 20
	style.content_margin_right = 20
	style.content_margin_top = 16
	style.content_margin_bottom = 16
	panel.add_theme_stylebox_override("panel", style)

# ---- Title: golden, localized ----
func _apply_title_style() -> void:
	_title_ref = $Panel/VBox/Title
	_title_ref.text = "PAUSA"
	_title_ref.add_theme_font_size_override("font_size", 28)
	_title_ref.add_theme_color_override("font_color", Color(0.9, 0.8, 0.3))
	_title_ref.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

# ---- Golden decorative line below title ----
func _apply_gold_line() -> void:
	_gold_line = ColorRect.new()
	_gold_line.name = "GoldLine"
	_gold_line.color = Color(0.9, 0.8, 0.3, 0.6)
	_gold_line.custom_minimum_size = Vector2(200, 2)
	_gold_line.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	# Insert right after the title (index 1 in VBox)
	$Panel/VBox.add_child(_gold_line)
	$Panel/VBox.move_child(_gold_line, 1)

# ---- Replace HSeparator with thin gold ColorRect ----
func _apply_separator_style() -> void:
	# Find any HSeparator in the VBox and replace
	for child in $Panel/VBox.get_children():
		if child is HSeparator:
			var idx = child.get_index()
			child.queue_free()
			var sep = ColorRect.new()
			sep.name = "GoldSeparator"
			sep.color = Color(0.9, 0.8, 0.3, 0.25)
			sep.custom_minimum_size = Vector2(0, 1)
			$Panel/VBox.add_child(sep)
			$Panel/VBox.move_child(sep, idx)

# ---- Button styles ----
func _make_button_stylebox(bg: Color, border: Color, corner: int = 5) -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color = bg
	s.border_width_left = 1
	s.border_width_right = 1
	s.border_width_top = 1
	s.border_width_bottom = 1
	s.border_color = border
	s.corner_radius_top_left = corner
	s.corner_radius_top_right = corner
	s.corner_radius_bottom_left = corner
	s.corner_radius_bottom_right = corner
	s.content_margin_left = 12
	s.content_margin_right = 12
	s.content_margin_top = 6
	s.content_margin_bottom = 6
	return s

func _apply_normal_button_style(btn: Button) -> void:
	btn.add_theme_stylebox_override("normal", _make_button_stylebox(
		Color(0.10, 0.09, 0.14), Color(0.28, 0.26, 0.35, 0.7)))
	btn.add_theme_stylebox_override("hover", _make_button_stylebox(
		Color(0.16, 0.14, 0.22), Color(0.9, 0.8, 0.3, 0.75)))
	btn.add_theme_stylebox_override("pressed", _make_button_stylebox(
		Color(0.20, 0.18, 0.28), Color(0.95, 0.85, 0.35, 0.9)))
	btn.add_theme_stylebox_override("focus", _make_button_stylebox(
		Color(0.16, 0.14, 0.22), Color(0.9, 0.8, 0.3, 0.75)))
	btn.add_theme_color_override("font_color", Color(0.82, 0.82, 0.88))
	btn.add_theme_color_override("font_hover_color", Color(1.0, 0.95, 0.7))
	btn.add_theme_color_override("font_pressed_color", Color(1.0, 0.95, 0.7))
	btn.add_theme_color_override("font_focus_color", Color(1.0, 0.95, 0.7))
	btn.add_theme_font_size_override("font_size", 18)
	btn.custom_minimum_size = Vector2(0, 44)

func _apply_resume_button_style(btn: Button) -> void:
	btn.add_theme_stylebox_override("normal", _make_button_stylebox(
		Color(0.14, 0.12, 0.08), Color(0.85, 0.72, 0.22, 0.7)))
	btn.add_theme_stylebox_override("hover", _make_button_stylebox(
		Color(0.20, 0.17, 0.10), Color(0.95, 0.82, 0.30, 0.95)))
	btn.add_theme_stylebox_override("pressed", _make_button_stylebox(
		Color(0.20, 0.18, 0.28), Color(0.95, 0.85, 0.35, 0.9)))
	btn.add_theme_stylebox_override("focus", _make_button_stylebox(
		Color(0.20, 0.17, 0.10), Color(0.95, 0.82, 0.30, 0.95)))
	btn.add_theme_color_override("font_color", Color(0.82, 0.82, 0.88))
	btn.add_theme_color_override("font_hover_color", Color(1.0, 0.92, 0.55))
	btn.add_theme_color_override("font_pressed_color", Color(1.0, 0.92, 0.55))
	btn.add_theme_color_override("font_focus_color", Color(1.0, 0.92, 0.55))
	btn.add_theme_font_size_override("font_size", 18)
	btn.custom_minimum_size = Vector2(0, 44)

func _apply_quit_button_style(btn: Button) -> void:
	btn.add_theme_stylebox_override("normal", _make_button_stylebox(
		Color(0.08, 0.07, 0.08), Color(0.30, 0.22, 0.22, 0.6)))
	btn.add_theme_stylebox_override("hover", _make_button_stylebox(
		Color(0.14, 0.09, 0.09), Color(0.85, 0.45, 0.40, 0.8)))
	btn.add_theme_stylebox_override("pressed", _make_button_stylebox(
		Color(0.20, 0.14, 0.14), Color(0.90, 0.50, 0.45, 0.9)))
	btn.add_theme_stylebox_override("focus", _make_button_stylebox(
		Color(0.14, 0.09, 0.09), Color(0.85, 0.45, 0.40, 0.8)))
	btn.add_theme_color_override("font_color", Color(0.82, 0.82, 0.88))
	btn.add_theme_color_override("font_hover_color", Color(0.95, 0.60, 0.55))
	btn.add_theme_color_override("font_pressed_color", Color(0.95, 0.60, 0.55))
	btn.add_theme_color_override("font_focus_color", Color(0.95, 0.60, 0.55))
	btn.add_theme_font_size_override("font_size", 18)
	btn.custom_minimum_size = Vector2(0, 44)

# ---- Stats panel style (dark+gold) ----
func _apply_stats_panel_style(sp: PanelContainer) -> void:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.04, 0.10, 0.95)
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.9, 0.8, 0.3, 0.35)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.shadow_color = Color(0.9, 0.75, 0.2, 0.12)
	style.shadow_size = 8
	sp.add_theme_stylebox_override("panel", style)

func _unhandled_input(event: InputEvent) -> void:
	# Handle keybinding rebind
	if not waiting_for_key.is_empty():
		if event is InputEventKey and event.pressed:
			KeybindingManager.rebind_action(waiting_for_key, event.physical_keycode)
			keybind_buttons[waiting_for_key].text = KeybindingManager.get_key_name(waiting_for_key)
			waiting_for_key = ""
			if get_viewport(): get_viewport().set_input_as_handled()
		return

	# ui_cancel: if merchant is open, close it first
	if event.is_action_pressed("ui_cancel"):
		var merchant_ui_uc = get_tree().root.find_child("MerchantUI", true, false)
		if merchant_ui_uc and is_instance_valid(merchant_ui_uc):
			AudioManager.play_sfx("menu_click")
			merchant_ui_uc.queue_free()
			GameManager.paused = false
			get_tree().paused = false
			var event_mgr_uc = get_tree().root.find_child("EventManager", true, false)
			if event_mgr_uc:
				event_mgr_uc._merchant_ui_cooldown = 2.0
			if get_viewport(): get_viewport().set_input_as_handled()
			return

	# ui_cancel fecha opcoes se estiverem abertas
	if event.is_action_pressed("ui_cancel") and options_panel and is_instance_valid(options_panel):
		options_panel.queue_free()
		options_panel = null
		# Restaurar foco no pause menu
		_setup_pause_focus()
		if $Panel/VBox.get_child_count() > 0:
			for child in $Panel/VBox.get_children():
				if child is Button:
					child.grab_focus()
					break
		if get_viewport(): get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("pause") and not GameManager.is_game_over:
		# Block pause if level-up screen is showing
		var lvl_screen = get_tree().root.find_child("LevelUpScreen", true, false)
		if lvl_screen and is_instance_valid(lvl_screen) and lvl_screen.get("panel") and lvl_screen.panel.visible:
			if get_viewport(): get_viewport().set_input_as_handled()
			return
		# If merchant UI is open, close it instead of opening pause
		var merchant_ui = get_tree().root.find_child("MerchantUI", true, false)
		if merchant_ui and is_instance_valid(merchant_ui):
			AudioManager.play_sfx("menu_click")
			merchant_ui.queue_free()
			GameManager.paused = false
			get_tree().paused = false
			# Set cooldown on event_manager to prevent immediate reopen
			var event_mgr = get_tree().root.find_child("EventManager", true, false)
			if event_mgr and event_mgr.has_method("set"):
				event_mgr._merchant_ui_cooldown = 2.0
			if get_viewport(): get_viewport().set_input_as_handled()
			return
		if options_panel and is_instance_valid(options_panel):
			options_panel.queue_free()
			options_panel = null
			return
		if panel.visible:
			_on_resume()
		else:
			_pause()

var stats_panel: PanelContainer = null

func _pause() -> void:
	# Salva se GameManager ja estava pausado (ex: levelup aberto)
	_was_gm_paused_before = GameManager.paused
	panel.visible = true
	overlay.visible = true
	if _vignette:
		_vignette.visible = true
	GameManager.paused = true
	get_tree().paused = true
	# Show run stats
	_show_stats()
	# Gamepad: foco no Resume
	_setup_pause_focus()
	GamepadUI.notify_menu_opened()
	# Entry animation
	_animate_panel_in()

func _animate_panel_in() -> void:
	_original_panel_y = panel.offset_top
	panel.modulate.a = 0.0
	panel.offset_top += 18
	panel.offset_bottom += 18
	var tw = create_tween()
	tw.set_parallel(true)
	tw.tween_property(panel, "modulate:a", 1.0, 0.18)
	tw.tween_property(panel, "offset_top", _original_panel_y, 0.18).set_ease(Tween.EASE_OUT)
	tw.tween_property(panel, "offset_bottom", _original_panel_y + 280.0, 0.18).set_ease(Tween.EASE_OUT)

func _setup_pause_focus() -> void:
	var buttons := []
	for child in $Panel/VBox.get_children():
		if child is Button:
			child.focus_mode = Control.FOCUS_ALL
			buttons.append(child)
	for i in range(buttons.size()):
		var btn: Button = buttons[i]
		if i > 0:
			btn.focus_neighbor_top = buttons[i - 1].get_path()
		else:
			btn.focus_neighbor_top = buttons[buttons.size() - 1].get_path()
		if i < buttons.size() - 1:
			btn.focus_neighbor_bottom = buttons[i + 1].get_path()
		else:
			btn.focus_neighbor_bottom = buttons[0].get_path()

func _on_resume() -> void:
	AudioManager.play_sfx("menu_click")
	if options_panel and is_instance_valid(options_panel):
		options_panel.queue_free()
		options_panel = null
	if stats_panel and is_instance_valid(stats_panel):
		stats_panel.queue_free()
		stats_panel = null
	# Animated fade-out
	var tw = create_tween()
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.set_parallel(true)
	tw.tween_property(panel, "modulate:a", 0.0, 0.15)
	tw.tween_property(overlay, "color:a", 0.0, 0.15)
	if _vignette:
		tw.tween_property(_vignette, "color:a", 0.0, 0.15)
	tw.chain().tween_callback(func():
		panel.visible = false
		panel.modulate.a = 1.0
		overlay.visible = false
		overlay.color.a = 0.72
		if _vignette:
			_vignette.visible = false
			_vignette.color.a = 0.55
		get_tree().paused = false
		GameManager.paused = _was_gm_paused_before
	)

func _show_stats() -> void:
	if stats_panel and is_instance_valid(stats_panel):
		stats_panel.queue_free()
		stats_panel = null

	stats_panel = PanelContainer.new()
	stats_panel.name = "StatsPanel"
	stats_panel.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	stats_panel.offset_left = -280
	stats_panel.offset_top = -200
	stats_panel.offset_right = -20
	stats_panel.offset_bottom = 200
	_apply_stats_panel_style(stats_panel)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	stats_panel.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	margin.add_child(vbox)

	var title = Label.new()
	title.text = LocaleManager.tr_key("stats_title")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color(0.9, 0.8, 0.3))
	vbox.add_child(title)

	# Golden separator instead of HSeparator
	var sep1 = ColorRect.new()
	sep1.color = Color(0.9, 0.8, 0.3, 0.25)
	sep1.custom_minimum_size = Vector2(0, 1)
	vbox.add_child(sep1)

	# DPS
	var dps = GameManager.total_damage_dealt / maxf(1.0, GameManager.game_time)
	_add_stat_line(vbox, LocaleManager.tr_key("stats_dps"), "%.1f" % dps)

	# Total kills
	_add_stat_line(vbox, LocaleManager.tr_key("stats_kills"), str(GameManager.total_kills))

	# Game time
	var t = int(GameManager.game_time)
	_add_stat_line(vbox, LocaleManager.tr_key("stats_time"), "%02d:%02d" % [t / 60, t % 60])

	# Total damage
	_add_stat_line(vbox, LocaleManager.tr_key("stats_total_dmg"), str(GameManager.total_damage_dealt))

	var sep2 = ColorRect.new()
	sep2.color = Color(0.9, 0.8, 0.3, 0.25)
	sep2.custom_minimum_size = Vector2(0, 1)
	vbox.add_child(sep2)

	# Current weapons and levels
	var weapons_title = Label.new()
	weapons_title.text = LocaleManager.tr_key("stats_weapons")
	weapons_title.add_theme_font_size_override("font_size", 16)
	weapons_title.add_theme_color_override("font_color", Color(0.6, 0.8, 1.0))
	vbox.add_child(weapons_title)

	for w in GameManager.player_weapons:
		var data = WeaponDB.weapons.get(w.id, {})
		var wname = data.get("name", w.id.capitalize())
		var whbox = HBoxContainer.new()
		var wicon_path = "res://assets/sprites/weapons/%s.png" % w.id
		var wicon_tex = load(wicon_path) if ResourceLoader.exists(wicon_path) else null
		if wicon_tex:
			var wicon = TextureRect.new()
			wicon.texture = wicon_tex
			wicon.custom_minimum_size = Vector2(20, 20)
			wicon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			wicon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			whbox.add_child(wicon)
		var wlbl = Label.new()
		wlbl.text = wname
		wlbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		wlbl.add_theme_font_size_override("font_size", 14)
		whbox.add_child(wlbl)
		var wval = Label.new()
		wval.text = "Lv.%d" % w.level
		wval.add_theme_font_size_override("font_size", 14)
		wval.add_theme_color_override("font_color", Color(0.9, 0.9, 0.5))
		whbox.add_child(wval)
		vbox.add_child(whbox)

	# Current items and levels
	var items = GameManager.player_items
	if not items.is_empty():
		var sep3 = ColorRect.new()
		sep3.color = Color(0.9, 0.8, 0.3, 0.25)
		sep3.custom_minimum_size = Vector2(0, 1)
		vbox.add_child(sep3)

		var items_title = Label.new()
		items_title.text = LocaleManager.tr_key("stats_items")
		items_title.add_theme_font_size_override("font_size", 16)
		items_title.add_theme_color_override("font_color", Color(0.6, 1.0, 0.8))
		vbox.add_child(items_title)

		for it in items:
			var idata = ItemDB.items.get(it.id, {})
			var iname = idata.get("name", it.id.capitalize())
			var ihbox = HBoxContainer.new()
			var iicon_path = "res://assets/sprites/items/%s.png" % it.id
			var iicon_tex = load(iicon_path) if ResourceLoader.exists(iicon_path) else null
			if iicon_tex:
				var iicon = TextureRect.new()
				iicon.texture = iicon_tex
				iicon.custom_minimum_size = Vector2(20, 20)
				iicon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				iicon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
				ihbox.add_child(iicon)
			var ilbl = Label.new()
			ilbl.text = iname
			ilbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			ilbl.add_theme_font_size_override("font_size", 14)
			ihbox.add_child(ilbl)
			var ival = Label.new()
			ival.text = "Lv.%d" % it.level
			ival.add_theme_font_size_override("font_size", 14)
			ival.add_theme_color_override("font_color", Color(0.5, 0.9, 1.0))
			ihbox.add_child(ival)
			vbox.add_child(ihbox)

	# Active synergies
	var synergies = SynergySystem.active_synergies
	if not synergies.is_empty():
		var sep4 = ColorRect.new()
		sep4.color = Color(0.9, 0.8, 0.3, 0.25)
		sep4.custom_minimum_size = Vector2(0, 1)
		vbox.add_child(sep4)

		var syn_title = Label.new()
		syn_title.text = LocaleManager.tr_key("stats_synergies")
		syn_title.add_theme_font_size_override("font_size", 16)
		syn_title.add_theme_color_override("font_color", Color(0.8, 0.6, 1.0))
		vbox.add_child(syn_title)

		for syn_id in synergies:
			var desc = SynergySystem.get_synergy_description(syn_id)
			if desc != "":
				var syn_lbl = Label.new()
				syn_lbl.text = desc
				syn_lbl.add_theme_font_size_override("font_size", 12)
				syn_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
				vbox.add_child(syn_lbl)

	add_child(stats_panel)

func _add_stat_line(parent: Control, label_text: String, value_text: String) -> void:
	var hbox = HBoxContainer.new()
	var lbl = Label.new()
	lbl.text = label_text
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.add_theme_font_size_override("font_size", 14)
	hbox.add_child(lbl)
	var val = Label.new()
	val.text = value_text
	val.add_theme_font_size_override("font_size", 14)
	val.add_theme_color_override("font_color", Color(0.9, 0.9, 0.5))
	hbox.add_child(val)
	parent.add_child(hbox)

func _on_options() -> void:
	AudioManager.play_sfx("menu_click")
	if options_panel and is_instance_valid(options_panel):
		options_panel.queue_free()
		options_panel = null
		return

	options_panel = PanelContainer.new()
	options_panel.name = "OptionsPanel"
	options_panel.set_anchors_preset(Control.PRESET_CENTER)
	options_panel.offset_left = -250
	options_panel.offset_top = -280
	options_panel.offset_right = 250
	options_panel.offset_bottom = 280
	_apply_stats_panel_style(options_panel)

	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(480, 540)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	options_panel.add_child(scroll)

	var margin = MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	scroll.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 6)
	margin.add_child(vbox)

	var title = Label.new()
	title.text = LocaleManager.tr_key("options")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(0.9, 0.8, 0.3))
	vbox.add_child(title)

	var sep_opt = ColorRect.new()
	sep_opt.color = Color(0.9, 0.8, 0.3, 0.25)
	sep_opt.custom_minimum_size = Vector2(0, 1)
	vbox.add_child(sep_opt)

	# ---- Volume ----
	_add_slider(vbox, LocaleManager.tr_key("volume_master"), "master", 1.0)
	_add_slider(vbox, LocaleManager.tr_key("volume_music"), "music", 0.8)
	_add_slider(vbox, LocaleManager.tr_key("volume_sfx"), "sfx", 1.0)

	var sep_vol = ColorRect.new()
	sep_vol.color = Color(0.9, 0.8, 0.3, 0.25)
	sep_vol.custom_minimum_size = Vector2(0, 1)
	vbox.add_child(sep_vol)

	# ---- Fullscreen ----
	var fs_hbox = HBoxContainer.new()
	var fs_label = Label.new()
	fs_label.text = LocaleManager.tr_key("fullscreen")
	fs_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fs_hbox.add_child(fs_label)
	var fs_check = CheckButton.new()
	fs_check.button_pressed = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	fs_check.toggled.connect(func(pressed):
		if pressed:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		SaveManager.data["fullscreen"] = pressed
		SaveManager.save_game()
	)
	fs_hbox.add_child(fs_check)
	vbox.add_child(fs_hbox)

	# ---- Window Mode ----
	var wm_hbox = HBoxContainer.new()
	var wm_label = Label.new()
	wm_label.text = LocaleManager.tr_key("window_mode")
	wm_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	wm_hbox.add_child(wm_label)
	var wm_option = OptionButton.new()
	wm_option.add_item(LocaleManager.tr_key("window_windowed"), 0)
	wm_option.add_item(LocaleManager.tr_key("window_fullscreen"), 1)
	wm_option.add_item(LocaleManager.tr_key("window_borderless"), 2)
	var current_mode = DisplayServer.window_get_mode()
	if current_mode == DisplayServer.WINDOW_MODE_FULLSCREEN:
		wm_option.selected = 1
	elif current_mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
		wm_option.selected = 2
	else:
		wm_option.selected = 0
	wm_option.item_selected.connect(func(idx):
		match idx:
			0: DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			1: DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
			2:
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
				DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
		SaveManager.data["window_mode"] = idx
		SaveManager.save_game()
	)
	wm_hbox.add_child(wm_option)
	vbox.add_child(wm_hbox)

	# ---- Resolution ----
	var res_hbox = HBoxContainer.new()
	var res_label = Label.new()
	res_label.text = LocaleManager.tr_key("resolution")
	res_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	res_hbox.add_child(res_label)
	var res_option = OptionButton.new()
	var resolutions = GameConstants.RESOLUTIONS
	var current_res = DisplayServer.window_get_size()
	for i in range(resolutions.size()):
		var r = resolutions[i]
		res_option.add_item("%dx%d" % [r.x, r.y], i)
		if current_res.x == r.x and current_res.y == r.y:
			res_option.selected = i
	res_option.item_selected.connect(func(idx):
		var r = resolutions[idx]
		DisplayServer.window_set_size(r)
		var screen_size = DisplayServer.screen_get_size()
		DisplayServer.window_set_position((screen_size - r) / 2)
		SaveManager.data["resolution"] = idx
		SaveManager.save_game()
	)
	res_hbox.add_child(res_option)
	vbox.add_child(res_hbox)

	var sep_res = ColorRect.new()
	sep_res.color = Color(0.9, 0.8, 0.3, 0.25)
	sep_res.custom_minimum_size = Vector2(0, 1)
	vbox.add_child(sep_res)

	# ---- Language ----
	var lang_hbox = HBoxContainer.new()
	var lang_label = Label.new()
	lang_label.text = LocaleManager.tr_key("language")
	lang_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lang_hbox.add_child(lang_label)
	var lang_btn = OptionButton.new()
	var locales = LocaleManager.get_available_locales()
	for i in range(locales.size()):
		lang_btn.add_item(LocaleManager.get_locale_name(locales[i]), i)
		if locales[i] == LocaleManager.get_locale():
			lang_btn.selected = i
	lang_btn.item_selected.connect(func(idx):
		LocaleManager.set_locale(locales[idx])
		# Rebuild the options panel so all text updates to the new language
		if options_panel and is_instance_valid(options_panel):
			options_panel.queue_free()
			options_panel = null
		call_deferred("_on_options")
	)
	lang_hbox.add_child(lang_btn)
	vbox.add_child(lang_hbox)

	var sep_lang = ColorRect.new()
	sep_lang.color = Color(0.9, 0.8, 0.3, 0.25)
	sep_lang.custom_minimum_size = Vector2(0, 1)
	vbox.add_child(sep_lang)

	# ---- Keybindings ----
	var kb_title = Label.new()
	kb_title.text = LocaleManager.tr_key("controls_title")
	kb_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	kb_title.add_theme_color_override("font_color", Color(0.9, 0.8, 0.3))
	vbox.add_child(kb_title)

	keybind_buttons.clear()
	for action in KeybindingManager.get_rebindable_actions():
		var hbox = HBoxContainer.new()
		var action_label = Label.new()
		action_label.text = KeybindingManager.get_action_display_name(action)
		action_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(action_label)

		var key_btn = Button.new()
		key_btn.text = KeybindingManager.get_key_name(action)
		key_btn.custom_minimum_size = Vector2(120, 30)
		key_btn.pressed.connect(_start_rebind.bind(action, key_btn))
		_apply_normal_button_style(key_btn)
		hbox.add_child(key_btn)
		keybind_buttons[action] = key_btn
		vbox.add_child(hbox)

	var reset_btn = Button.new()
	reset_btn.text = LocaleManager.tr_key("reset_keybindings")
	reset_btn.pressed.connect(func():
		KeybindingManager.reset_defaults()
		for act in keybind_buttons:
			keybind_buttons[act].text = KeybindingManager.get_key_name(act)
	)
	_apply_normal_button_style(reset_btn)
	vbox.add_child(reset_btn)

	var sep_kb = ColorRect.new()
	sep_kb.color = Color(0.9, 0.8, 0.3, 0.25)
	sep_kb.custom_minimum_size = Vector2(0, 1)
	vbox.add_child(sep_kb)

	# Close button
	var close_btn = Button.new()
	close_btn.text = LocaleManager.tr_key("close")
	close_btn.pressed.connect(func():
		options_panel.queue_free()
		options_panel = null
	)
	_apply_normal_button_style(close_btn)
	vbox.add_child(close_btn)

	add_child(options_panel)

	# Gamepad focus: setar FOCUS_ALL em todos controles interativos e grab_focus no primeiro
	_setup_options_focus(vbox)

func _setup_options_focus(container: Control) -> void:
	var focusable_controls: Array[Control] = []
	_collect_focusable(container, focusable_controls)

	for ctrl in focusable_controls:
		ctrl.focus_mode = Control.FOCUS_ALL

	# Conectar vizinhos de foco (cima/baixo)
	for i in range(focusable_controls.size()):
		var ctrl := focusable_controls[i]
		if i > 0:
			ctrl.focus_neighbor_top = focusable_controls[i - 1].get_path()
		else:
			ctrl.focus_neighbor_top = focusable_controls[focusable_controls.size() - 1].get_path()
		if i < focusable_controls.size() - 1:
			ctrl.focus_neighbor_bottom = focusable_controls[i + 1].get_path()
		else:
			ctrl.focus_neighbor_bottom = focusable_controls[0].get_path()

	# Foco inicial no primeiro controle
	if focusable_controls.size() > 0:
		focusable_controls[0].call_deferred("grab_focus")

func _collect_focusable(node: Node, result: Array[Control]) -> void:
	if node is HSlider or node is CheckButton or node is OptionButton or (node is Button and not node is CheckButton):
		result.append(node as Control)
	for child in node.get_children():
		_collect_focusable(child, result)

func _add_slider(parent: Control, label_text: String, bus_name: String, default_val: float) -> void:
	var hbox = HBoxContainer.new()
	var label = Label.new()
	label.text = label_text
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(label)

	var slider = HSlider.new()
	slider.custom_minimum_size = Vector2(180, 0)
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.value = SaveManager.data.get("volume_" + bus_name, default_val)
	slider.value_changed.connect(func(val):
		var bus_idx = AudioServer.get_bus_index(bus_name.capitalize())
		if bus_idx >= 0:
			AudioServer.set_bus_volume_db(bus_idx, linear_to_db(val))
		SaveManager.data["volume_" + bus_name] = val
		SaveManager.save_game()
	)
	hbox.add_child(slider)
	parent.add_child(hbox)

func _start_rebind(action: String, btn: Button) -> void:
	waiting_for_key = action
	btn.text = "..."

func _on_locale_changed(_new_locale: String) -> void:
	# Update pause menu button texts when language changes
	resume_btn.text = LocaleManager.tr_key("resume")
	menu_btn.text = LocaleManager.tr_key("quit_to_menu")
	if _title_ref and is_instance_valid(_title_ref):
		_title_ref.text = "PAUSA"
	if options_btn_ref and is_instance_valid(options_btn_ref):
		options_btn_ref.text = LocaleManager.tr_key("options")
	if quit_btn_ref and is_instance_valid(quit_btn_ref):
		quit_btn_ref.text = LocaleManager.tr_key("quit_game")

func _on_menu() -> void:
	AudioManager.play_sfx("menu_click")
	if options_panel and is_instance_valid(options_panel):
		options_panel.queue_free()
		options_panel = null
	if stats_panel and is_instance_valid(stats_panel):
		stats_panel.queue_free()
		stats_panel = null
	get_tree().paused = false
	GameManager.paused = false
	if MultiplayerManager.is_online:
		MultiplayerManager.disconnect_from_game()
	LoadingScreen.transition_to("res://scenes/ui/main_menu.tscn")

func _on_quit() -> void:
	AudioManager.play_sfx("menu_click")
	_show_quit_confirmation()

func _show_quit_confirmation() -> void:
	if has_node("QuitDialog"):
		return
	var dialog := AcceptDialog.new()
	dialog.name = "QuitDialog"
	dialog.title = LocaleManager.tr_key("quit_title")
	dialog.exclusive = true
	dialog.unresizable = true
	dialog.dialog_close_on_escape = true
	dialog.dialog_hide_on_ok = true
	# Esconde o botao X do titulo
	var _img := Image.create(1, 1, false, Image.FORMAT_RGBA8)
	var _tex := ImageTexture.create_from_image(_img)
	dialog.add_theme_icon_override("close", _tex)
	dialog.add_theme_icon_override("close_pressed", _tex)
	dialog.dialog_text = LocaleManager.tr_key("quit_confirm")
	dialog.ok_button_text = LocaleManager.tr_key("quit_ok")
	dialog.add_cancel_button(LocaleManager.tr_key("cancel"))
	dialog.confirmed.connect(func():
		get_tree().quit()
	)
	dialog.canceled.connect(func():
		dialog.queue_free()
	)
	add_child(dialog)
	dialog.popup_centered()
