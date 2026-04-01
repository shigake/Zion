extends Control

## Tela de opcoes completa com abas: Video, Graficos, Audio, Gameplay, Controles, Acessibilidade, Idioma.

var waiting_for_key: String = ""
var keybind_buttons: Dictionary = {}
var tab_container: TabContainer
var tab_controls: Dictionary = {}  # tab_index -> Array of {key, default, node, type}
var _pending_changes: Dictionary = {}  # key -> value (not yet saved to disk)
var _original_values: Dictionary = {}  # key -> value (snapshot when opened)
var _save_btn: Button = null

# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------
func _ready() -> void:
	# Safety: garante que nao esta pausado
	get_tree().paused = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Registra input actions para bumpers R1/L1
	if not InputMap.has_action("ui_tab_next"):
		InputMap.add_action("ui_tab_next")
		var ev_r1 = InputEventJoypadButton.new()
		ev_r1.button_index = JOY_BUTTON_RIGHT_SHOULDER
		InputMap.action_add_event("ui_tab_next", ev_r1)
	if not InputMap.has_action("ui_tab_prev"):
		InputMap.add_action("ui_tab_prev")
		var ev_l1 = InputEventJoypadButton.new()
		ev_l1.button_index = JOY_BUTTON_LEFT_SHOULDER
		InputMap.action_add_event("ui_tab_prev", ev_l1)
	_build_ui()
	GamepadUI.notify_menu_opened()
	# Foco inicial no primeiro controle da aba ativa
	call_deferred("_set_tab_focus")
	# Quando trocar de aba, mover foco para o primeiro controle
	tab_container.tab_changed.connect(func(_tab: int) -> void:
		call_deferred("_set_tab_focus")
	)

# ---------------------------------------------------------------------------
# Helpers — save / load
# ---------------------------------------------------------------------------
func _save(key: String, value: Variant) -> void:
	# Armazena em pending — so persiste quando clicar "Salvar"
	_pending_changes[key] = value
	# Aplica preview imediato (ex: volume, resolucao)
	SaveManager.data[key] = value
	_update_save_btn_label()

func _load_setting(key: String, default: Variant = null) -> Variant:
	return SaveManager.data.get(key, default)

# ---------------------------------------------------------------------------
# Helpers — register control for per-tab reset
# ---------------------------------------------------------------------------
func _register(tab_idx: int, key: String, default_val: Variant, node: Control, type: String) -> void:
	if not tab_controls.has(tab_idx):
		tab_controls[tab_idx] = []
	tab_controls[tab_idx].append({"key": key, "default": default_val, "node": node, "type": type})

# ---------------------------------------------------------------------------
# Helpers — UI builders
# ---------------------------------------------------------------------------
func _add_section(parent: Control, title: String) -> void:
	var label := Label.new()
	label.text = title
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color(0.6, 0.8, 1.0))
	label.add_theme_constant_override("margin_top", 12)
	parent.add_child(label)
	parent.add_child(HSeparator.new())

func _add_toggle(parent: Control, label_text: String, key: String, default_val: bool, callback: Callable = Callable(), tab_idx: int = -1) -> CheckButton:
	var hbox := HBoxContainer.new()
	var label := Label.new()
	label.text = label_text
	label.add_theme_font_size_override("font_size", 13)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(label)

	var btn := CheckButton.new()
	btn.focus_mode = Control.FOCUS_ALL
	btn.button_pressed = _load_setting(key, default_val)
	btn.toggled.connect(func(pressed: bool) -> void:
		_save(key, pressed)
		if callback.is_valid():
			callback.call(pressed)
	)
	hbox.add_child(btn)
	parent.add_child(hbox)
	if tab_idx >= 0:
		_register(tab_idx, key, default_val, btn, "toggle")
	return btn

func _add_slider(parent: Control, label_text: String, key: String, min_val: float, max_val: float, step_val: float, default_val: float, callback: Callable = Callable(), tab_idx: int = -1) -> HSlider:
	var hbox := HBoxContainer.new()
	var label := Label.new()
	label.text = label_text
	label.add_theme_font_size_override("font_size", 13)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(label)

	var value_label := Label.new()
	value_label.add_theme_font_size_override("font_size", 13)
	value_label.custom_minimum_size = Vector2(50, 0)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

	var slider := HSlider.new()
	slider.focus_mode = Control.FOCUS_ALL
	slider.custom_minimum_size = Vector2(200, 0)
	slider.min_value = min_val
	slider.max_value = max_val
	slider.step = step_val
	slider.value = _load_setting(key, default_val)
	value_label.text = str(snapped(slider.value, step_val))
	slider.value_changed.connect(func(val: float) -> void:
		_save(key, val)
		value_label.text = str(snapped(val, step_val))
		if callback.is_valid():
			callback.call(val)
	)
	hbox.add_child(slider)
	hbox.add_child(value_label)
	parent.add_child(hbox)
	if tab_idx >= 0:
		_register(tab_idx, key, default_val, slider, "slider")
	return slider

func _add_dropdown(parent: Control, label_text: String, key: String, options: Array, default_idx: int, callback: Callable = Callable(), tab_idx: int = -1) -> OptionButton:
	var hbox := HBoxContainer.new()
	var label := Label.new()
	label.text = label_text
	label.add_theme_font_size_override("font_size", 13)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(label)

	var option_btn := OptionButton.new()
	option_btn.focus_mode = Control.FOCUS_ALL
	option_btn.custom_minimum_size = Vector2(160, 0)
	for i in range(options.size()):
		option_btn.add_item(str(options[i]), i)
	option_btn.selected = _load_setting(key, default_idx)
	option_btn.item_selected.connect(func(idx: int) -> void:
		_save(key, idx)
		if callback.is_valid():
			callback.call(idx)
	)
	hbox.add_child(option_btn)
	parent.add_child(hbox)
	if tab_idx >= 0:
		_register(tab_idx, key, default_idx, option_btn, "dropdown")
	return option_btn

# ---------------------------------------------------------------------------
# Tab content container helper
# ---------------------------------------------------------------------------
func _make_tab_content(tab_name: String) -> VBoxContainer:
	var scroll := ScrollContainer.new()
	scroll.name = tab_name
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_theme_constant_override("margin_left", 30)
	margin.add_theme_constant_override("margin_right", 30)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	scroll.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 6)
	margin.add_child(vbox)

	tab_container.add_child(scroll)
	return vbox

# ---------------------------------------------------------------------------
# Build UI
# ---------------------------------------------------------------------------
func _build_ui() -> void:
	# Root background
	var bg := ColorRect.new()
	bg.color = Color(0.08, 0.08, 0.1, 1.0)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# Main layout
	var root_vbox := VBoxContainer.new()
	root_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_vbox.set_anchor_and_offset(SIDE_LEFT, 0, 40)
	root_vbox.set_anchor_and_offset(SIDE_RIGHT, 1, -40)
	root_vbox.set_anchor_and_offset(SIDE_TOP, 0, 20)
	root_vbox.set_anchor_and_offset(SIDE_BOTTOM, 1, -20)
	root_vbox.add_theme_constant_override("separation", 10)
	add_child(root_vbox)

	# Title
	var title := Label.new()
	title.text = LocaleManager.tr_key("opt_title")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	root_vbox.add_child(title)

	# Tab container
	tab_container = TabContainer.new()
	tab_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tab_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tab_container.add_theme_font_size_override("font_size", 14)
	root_vbox.add_child(tab_container)

	# Hint visual para navegacao com gamepad
	var tab_hint = Label.new()
	tab_hint.text = "[L1] ◄  ► [R1]"
	tab_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tab_hint.add_theme_font_size_override("font_size", 12)
	tab_hint.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
	tab_hint.visible = Input.get_connected_joypads().size() > 0
	root_vbox.add_child(tab_hint)
	root_vbox.move_child(tab_hint, tab_container.get_index())

	_build_tab_video()
	_build_tab_graficos()
	_build_tab_audio()
	_build_tab_gameplay()
	_build_tab_controles()
	_build_tab_acessibilidade()
	_build_tab_idioma()

	# Snapshot dos valores originais para poder reverter
	_original_values = SaveManager.data.duplicate()

	# Footer
	var footer := HBoxContainer.new()
	footer.alignment = BoxContainer.ALIGNMENT_END
	footer.add_theme_constant_override("separation", 12)

	var reset_btn := Button.new()
	reset_btn.text = LocaleManager.tr_key("opt_reset_defaults")
	reset_btn.focus_mode = Control.FOCUS_ALL
	reset_btn.pressed.connect(_on_reset_tab)
	footer.add_child(reset_btn)

	_save_btn = Button.new()
	_save_btn.text = LocaleManager.tr_key("opt_save")
	_save_btn.focus_mode = Control.FOCUS_ALL
	_save_btn.pressed.connect(_on_save_settings)
	var save_style = StyleBoxFlat.new()
	save_style.bg_color = Color(0.12, 0.35, 0.12)
	save_style.set_corner_radius_all(6)
	save_style.set_border_width_all(1)
	save_style.border_color = Color(0.3, 0.8, 0.3)
	_save_btn.add_theme_stylebox_override("normal", save_style)
	footer.add_child(_save_btn)

	var back_btn := Button.new()
	back_btn.text = LocaleManager.tr_key("opt_back")
	back_btn.focus_mode = Control.FOCUS_ALL
	back_btn.pressed.connect(_on_back)
	footer.add_child(back_btn)

	root_vbox.add_child(footer)

# ---------------------------------------------------------------------------
# TAB 1 — Video
# ---------------------------------------------------------------------------
func _build_tab_video() -> void:
	var t := 0
	var vbox := _make_tab_content(LocaleManager.tr_key("opt_tab_video"))

	# Window Mode
	_add_dropdown(vbox, LocaleManager.tr_key("opt_window_mode"), "video_window_mode",
		[LocaleManager.tr_key("opt_window_windowed"), LocaleManager.tr_key("opt_window_fullscreen"), LocaleManager.tr_key("opt_window_borderless")], 0,
		func(idx: int) -> void:
			if idx == 0:
				DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			elif idx == 1:
				DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
			elif idx == 2:
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
				DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true),
		t)

	# Resolution — detect screen and build list
	var screen_size := DisplayServer.screen_get_size()
	var all_resolutions: Array[Vector2i] = GameConstants.RESOLUTIONS
	var resolutions: Array[Vector2i] = []
	var res_labels: Array[String] = []
	for r in all_resolutions:
		if r.x <= screen_size.x and r.y <= screen_size.y:
			resolutions.append(r)
			res_labels.append("%dx%d" % [r.x, r.y])
	var default_res_idx := 0
	var current_res := DisplayServer.window_get_size()
	for i in range(resolutions.size()):
		if resolutions[i].x == current_res.x and resolutions[i].y == current_res.y:
			default_res_idx = i
			break
		if resolutions[i] == Vector2i(1920, 1080):
			default_res_idx = i

	_add_dropdown(vbox, LocaleManager.tr_key("opt_resolution"), "video_resolution",
		res_labels, default_res_idx,
		func(idx: int) -> void:
			if idx < resolutions.size():
				var r := resolutions[idx]
				DisplayServer.window_set_size(r)
				var ss := DisplayServer.screen_get_size()
				DisplayServer.window_set_position((ss - r) / 2),
		t)

	# V-Sync
	_add_toggle(vbox, LocaleManager.tr_key("opt_vsync"), "video_vsync", true,
		func(on: bool) -> void:
			if on:
				DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
			else:
				DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED),
		t)

	# FPS Limit
	var fps_options := GameConstants.FPS_LABELS
	var fps_values := GameConstants.FPS_OPTIONS
	_add_dropdown(vbox, LocaleManager.tr_key("opt_fps_limit"), "video_fps_limit",
		fps_options, 1,
		func(idx: int) -> void:
			if idx < fps_values.size():
				Engine.max_fps = fps_values[idx],
		t)

	# Brightness
	_add_slider(vbox, LocaleManager.tr_key("opt_brightness"), "video_brightness", 0.5, 2.0, 0.05, 1.0, Callable(), t)

# ---------------------------------------------------------------------------
# TAB 2 — Graficos
# ---------------------------------------------------------------------------
var _gfx_controls: Dictionary = {}

func _build_tab_graficos() -> void:
	var t := 1
	var vbox := _make_tab_content(LocaleManager.tr_key("opt_tab_graphics"))

	# Quality Preset
	_add_dropdown(vbox, LocaleManager.tr_key("opt_quality_preset"), "gfx_preset",
		[LocaleManager.tr_key("opt_quality_low"), LocaleManager.tr_key("opt_quality_medium"), LocaleManager.tr_key("opt_quality_high"), LocaleManager.tr_key("opt_quality_ultra"), LocaleManager.tr_key("opt_quality_custom")], 2,
		func(idx: int) -> void:
			_apply_gfx_preset(idx),
		t)

	# MSAA
	var msaa_dd := _add_dropdown(vbox, LocaleManager.tr_key("opt_msaa"), "gfx_msaa",
		[LocaleManager.tr_key("opt_off"), "2x", "4x", "8x"], 1,
		func(idx: int) -> void:
			_apply_msaa(idx),
		t)
	_gfx_controls["msaa"] = msaa_dd

	# Bloom
	var bloom_toggle := _add_toggle(vbox, LocaleManager.tr_key("opt_bloom"), "gfx_bloom", true, Callable(), t)
	_gfx_controls["bloom"] = bloom_toggle

	# Bloom Intensity
	var bloom_slider := _add_slider(vbox, LocaleManager.tr_key("opt_bloom_intensity"), "gfx_bloom_intensity", 0.0, 2.0, 0.05, 1.0, Callable(), t)
	_gfx_controls["bloom_intensity"] = bloom_slider

	# SSAO
	var ssao_dd := _add_dropdown(vbox, LocaleManager.tr_key("opt_ssao"), "gfx_ssao",
		[LocaleManager.tr_key("opt_off"), LocaleManager.tr_key("opt_quality_low"), LocaleManager.tr_key("opt_quality_medium"), LocaleManager.tr_key("opt_quality_high")], 0, Callable(), t)
	_gfx_controls["ssao"] = ssao_dd

	# Shadow Quality
	var shadow_dd := _add_dropdown(vbox, LocaleManager.tr_key("opt_shadow_quality"), "gfx_shadows",
		[LocaleManager.tr_key("opt_off"), LocaleManager.tr_key("opt_quality_low"), LocaleManager.tr_key("opt_quality_medium"), LocaleManager.tr_key("opt_quality_high")], 2, Callable(), t)
	_gfx_controls["shadows"] = shadow_dd

	# Tone Mapping
	_add_dropdown(vbox, LocaleManager.tr_key("opt_tone_mapping"), "gfx_tonemap",
		["Linear", "Reinhardt", "Filmic", "ACES"], 3, Callable(), t)

	# Particles
	var particles_dd := _add_dropdown(vbox, LocaleManager.tr_key("opt_particles"), "gfx_particles",
		[LocaleManager.tr_key("opt_quality_low"), LocaleManager.tr_key("opt_quality_medium"), LocaleManager.tr_key("opt_quality_high")], 2, Callable(), t)
	_gfx_controls["particles"] = particles_dd

	# Screen Shake
	_add_dropdown(vbox, LocaleManager.tr_key("opt_screen_shake"), "gfx_screen_shake",
		[LocaleManager.tr_key("opt_screen_shake_off"), LocaleManager.tr_key("opt_screen_shake_light"), LocaleManager.tr_key("opt_screen_shake_normal"), LocaleManager.tr_key("opt_screen_shake_strong")], 2, Callable(), t)

	# Hit Freeze
	_add_toggle(vbox, LocaleManager.tr_key("opt_hit_freeze"), "gfx_hit_freeze", true, Callable(), t)

	# Cel Shader
	_add_toggle(vbox, LocaleManager.tr_key("opt_cel_shader"), "gfx_cel_shader", true, Callable(), t)

	# Outline
	_add_toggle(vbox, LocaleManager.tr_key("opt_outline"), "gfx_outline", true, Callable(), t)

func _apply_msaa(idx: int) -> void:
	match idx:
		0: get_viewport().msaa_3d = Viewport.MSAA_DISABLED
		1: get_viewport().msaa_3d = Viewport.MSAA_2X
		2: get_viewport().msaa_3d = Viewport.MSAA_4X
		3: get_viewport().msaa_3d = Viewport.MSAA_8X

func _apply_gfx_preset(idx: int) -> void:
	# idx: 0=Low, 1=Medium, 2=High, 3=Ultra, 4=Custom (no changes)
	if idx == 4:
		return
	var presets := {
		0: {"msaa": 0, "bloom": false, "bloom_intensity": 0.0, "ssao": 0, "shadows": 0, "particles": 0},
		1: {"msaa": 1, "bloom": true, "bloom_intensity": 0.5, "ssao": 1, "shadows": 1, "particles": 1},
		2: {"msaa": 1, "bloom": true, "bloom_intensity": 1.0, "ssao": 2, "shadows": 2, "particles": 2},
		3: {"msaa": 2, "bloom": true, "bloom_intensity": 1.5, "ssao": 3, "shadows": 3, "particles": 2},
	}
	var p: Dictionary = presets[idx]
	_save("gfx_msaa", p["msaa"])
	_save("gfx_bloom", p["bloom"])
	_save("gfx_bloom_intensity", p["bloom_intensity"])
	_save("gfx_ssao", p["ssao"])
	_save("gfx_shadows", p["shadows"])
	_save("gfx_particles", p["particles"])
	_apply_msaa(p["msaa"])

	# Update controls
	if _gfx_controls.has("msaa"):
		_gfx_controls["msaa"].selected = p["msaa"]
	if _gfx_controls.has("bloom"):
		_gfx_controls["bloom"].button_pressed = p["bloom"]
	if _gfx_controls.has("bloom_intensity"):
		_gfx_controls["bloom_intensity"].value = p["bloom_intensity"]
	if _gfx_controls.has("ssao"):
		_gfx_controls["ssao"].selected = p["ssao"]
	if _gfx_controls.has("shadows"):
		_gfx_controls["shadows"].selected = p["shadows"]
	if _gfx_controls.has("particles"):
		_gfx_controls["particles"].selected = p["particles"]

# ---------------------------------------------------------------------------
# TAB 3 — Audio
# ---------------------------------------------------------------------------
func _build_tab_audio() -> void:
	var t := 2
	var vbox := _make_tab_content(LocaleManager.tr_key("opt_tab_audio"))

	_add_slider(vbox, LocaleManager.tr_key("opt_volume_master"), "audio_master", 0, 100, 5, 100,
		func(val: float) -> void:
			_apply_audio_bus("Master", val / 100.0),
		t)

	_add_slider(vbox, LocaleManager.tr_key("opt_volume_music"), "audio_music", 0, 100, 5, 80,
		func(val: float) -> void:
			_apply_audio_bus("Music", val / 100.0),
		t)

	_add_slider(vbox, LocaleManager.tr_key("opt_volume_sfx"), "audio_sfx", 0, 100, 5, 100,
		func(val: float) -> void:
			_apply_audio_bus("SFX", val / 100.0)
			AudioManager.play_sfx("menu_click"),
		t)

	_add_slider(vbox, LocaleManager.tr_key("opt_volume_ui"), "audio_ui", 0, 100, 5, 100,
		func(val: float) -> void:
			_apply_audio_bus("UI", val / 100.0)
			AudioManager.play_sfx("menu_click"),
		t)

	_add_slider(vbox, LocaleManager.tr_key("opt_volume_combat"), "audio_combat", 0, 100, 5, 100,
		func(val: float) -> void:
			AudioManager.combat_volume = val / 100.0
			AudioManager.play_sfx("hit"),
		t)

	_add_slider(vbox, LocaleManager.tr_key("opt_volume_ambient"), "audio_ambient", 0, 100, 5, 100,
		func(val: float) -> void:
			AudioManager.ambient_volume = val / 100.0,
		t)

	_add_toggle(vbox, LocaleManager.tr_key("opt_ducking"), "audio_ducking", true,
		func(on: bool) -> void:
			AudioManager._ducking_enabled = on,
		t)

func _apply_audio_bus(bus_name: String, linear: float) -> void:
	var bus_idx := AudioServer.get_bus_index(bus_name)
	if bus_idx >= 0:
		AudioServer.set_bus_volume_db(bus_idx, linear_to_db(linear))

# ---------------------------------------------------------------------------
# TAB 4 — Gameplay
# ---------------------------------------------------------------------------
func _build_tab_gameplay() -> void:
	var t := 3
	var vbox := _make_tab_content(LocaleManager.tr_key("opt_tab_gameplay"))

	# Section: HUD
	_add_section(vbox, LocaleManager.tr_key("opt_section_hud"))
	_add_toggle(vbox, LocaleManager.tr_key("opt_damage_numbers"), "hud_damage_numbers", true, Callable(), t)
	_add_toggle(vbox, LocaleManager.tr_key("opt_enemy_hp_bar"), "hud_enemy_hp", true, Callable(), t)
	_add_toggle(vbox, LocaleManager.tr_key("opt_fps_counter"), "hud_fps", false, Callable(), t)
	_add_toggle(vbox, LocaleManager.tr_key("opt_timer"), "hud_timer", true, Callable(), t)
	_add_toggle(vbox, LocaleManager.tr_key("opt_kill_counter"), "hud_kills", true, Callable(), t)
	_add_toggle(vbox, LocaleManager.tr_key("opt_boss_direction"), "hud_boss_direction", true, Callable(), t)

	# Section: Jogo
	_add_section(vbox, LocaleManager.tr_key("opt_section_game"))
	_add_toggle(vbox, LocaleManager.tr_key("opt_pause_focus_loss"), "game_pause_focus_loss", true, Callable(), t)
	_add_toggle(vbox, LocaleManager.tr_key("opt_confirm_exit"), "game_confirm_exit", true, Callable(), t)

	# Section: Multiplayer
	_add_section(vbox, LocaleManager.tr_key("opt_section_multiplayer"))
	_add_toggle(vbox, LocaleManager.tr_key("opt_sync_levelup"), "levelup_sync", true, Callable(), t)

	# Section: Telemetria
	_add_section(vbox, LocaleManager.tr_key("opt_section_telemetry"))
	_add_toggle(vbox, LocaleManager.tr_key("opt_send_anonymous"), "telemetry_enabled", true,
		func(on: bool) -> void:
			Telemetry.set_enabled(on),
		t)

# ---------------------------------------------------------------------------
# TAB 5 — Controles
# ---------------------------------------------------------------------------
func _build_tab_controles() -> void:
	var t := 4
	var vbox := _make_tab_content(LocaleManager.tr_key("opt_tab_controls"))

	# Section: Teclado
	_add_section(vbox, LocaleManager.tr_key("opt_section_keyboard"))

	for action in KeybindingManager.get_rebindable_actions():
		var hbox := HBoxContainer.new()
		var action_label := Label.new()
		action_label.text = KeybindingManager.get_action_display_name(action)
		action_label.add_theme_font_size_override("font_size", 13)
		action_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(action_label)

		var key_btn := Button.new()
		key_btn.text = KeybindingManager.get_key_name(action)
		key_btn.custom_minimum_size = Vector2(140, 30)
		key_btn.pressed.connect(_start_rebind.bind(action, key_btn))
		hbox.add_child(key_btn)
		keybind_buttons[action] = key_btn
		vbox.add_child(hbox)

	var reset_keys_btn := Button.new()
	reset_keys_btn.text = LocaleManager.tr_key("opt_reset_controls")
	reset_keys_btn.pressed.connect(func() -> void:
		KeybindingManager.reset_defaults()
		for act in keybind_buttons:
			keybind_buttons[act].text = KeybindingManager.get_key_name(act)
	)
	vbox.add_child(reset_keys_btn)

	# Section: Gamepad
	_add_section(vbox, LocaleManager.tr_key("opt_section_gamepad"))

	_add_slider(vbox, LocaleManager.tr_key("opt_analog_deadzone"), "input_deadzone", 0.05, 0.5, 0.01, 0.15, Callable(), t)
	_add_slider(vbox, LocaleManager.tr_key("opt_gamepad_sensitivity"), "gamepad_deadzone", 0.1, 0.5, 0.01, 0.3,
		Callable(),
		t)
	_add_toggle(vbox, LocaleManager.tr_key("opt_vibration"), "input_vibration", true, Callable(), t)

# ---------------------------------------------------------------------------
# TAB 6 — Acessibilidade
# ---------------------------------------------------------------------------
func _build_tab_acessibilidade() -> void:
	var t := 5
	var vbox := _make_tab_content(LocaleManager.tr_key("opt_tab_accessibility"))

	_add_dropdown(vbox, LocaleManager.tr_key("opt_font_size"), "access_font_size",
		["80%", "100%", "120%", "150%"], 1,
		func(idx: int) -> void:
			AccessibilityManager.set_font_scale(idx),
		t)

	_add_dropdown(vbox, LocaleManager.tr_key("opt_ui_scale"), "access_ui_scale",
		["80%", "100%", "120%", "150%"], 1,
		func(idx: int) -> void:
			AccessibilityManager.set_ui_scale(idx),
		t)

	_add_toggle(vbox, LocaleManager.tr_key("opt_reduced_motion"), "access_reduced_motion", false,
		func(on: bool) -> void:
			AccessibilityManager.set_reduced_motion(on),
		t)
	_add_toggle(vbox, LocaleManager.tr_key("opt_reduced_flash"), "access_reduced_flash", false,
		func(on: bool) -> void:
			AccessibilityManager.set_reduced_flash(on),
		t)
	_add_toggle(vbox, LocaleManager.tr_key("opt_high_contrast"), "access_high_contrast", false,
		func(on: bool) -> void:
			AccessibilityManager.set_high_contrast(on),
		t)

	_add_dropdown(vbox, LocaleManager.tr_key("opt_colorblind_mode"), "access_colorblind",
		[LocaleManager.tr_key("opt_colorblind_off"), "Protanopia", "Deuteranopia", "Tritanopia"], 0,
		func(idx: int) -> void:
			AccessibilityManager.set_colorblind_mode(idx),
		t)

# ---------------------------------------------------------------------------
# TAB 7 — Idioma
# ---------------------------------------------------------------------------
func _build_tab_idioma() -> void:
	var t := 6
	var vbox := _make_tab_content(LocaleManager.tr_key("opt_tab_language"))

	var locales := LocaleManager.get_available_locales()
	var locale_names: Array[String] = []
	var current_idx := 0
	for i in range(locales.size()):
		locale_names.append(LocaleManager.get_locale_name(locales[i]))
		if locales[i] == LocaleManager.get_locale():
			current_idx = i

	_add_dropdown(vbox, LocaleManager.tr_key("language"), "locale_index",
		locale_names, current_idx,
		func(idx: int) -> void:
			if idx < locales.size():
				LocaleManager.set_locale(locales[idx])
				# Rebuild entire UI so all labels update to new language
				_rebuild_ui(),
		t)

# ---------------------------------------------------------------------------
# Gamepad focus helpers
# ---------------------------------------------------------------------------
func _set_tab_focus() -> void:
	var tab_content := tab_container.get_current_tab_control()
	if tab_content:
		var focusable := _find_first_focusable(tab_content)
		if focusable:
			focusable.grab_focus()

func _find_first_focusable(node: Node) -> Control:
	if node is HSlider or node is CheckButton or node is OptionButton or (node is Button and not node is CheckButton):
		if (node as Control).focus_mode != Control.FOCUS_NONE:
			return node as Control
	for child in node.get_children():
		var result := _find_first_focusable(child)
		if result:
			return result
	return null

# ---------------------------------------------------------------------------
# Keybinding rebind
# ---------------------------------------------------------------------------
func _start_rebind(action: String, btn: Button) -> void:
	waiting_for_key = action
	btn.text = "..."

func _unhandled_input(event: InputEvent) -> void:
	# Navegacao de abas com R1/L1 (apenas fora de rebind)
	if waiting_for_key.is_empty():
		if event.is_action_pressed("ui_tab_next"):
			tab_container.current_tab = (tab_container.current_tab + 1) % tab_container.get_tab_count()
			AudioManager.play_sfx("menu_click")
			call_deferred("_set_tab_focus")
			if get_viewport(): get_viewport().set_input_as_handled()
			return
		if event.is_action_pressed("ui_tab_prev"):
			tab_container.current_tab = (tab_container.current_tab - 1 + tab_container.get_tab_count()) % tab_container.get_tab_count()
			AudioManager.play_sfx("menu_click")
			call_deferred("_set_tab_focus")
			if get_viewport(): get_viewport().set_input_as_handled()
			return
		if event.is_action_pressed("ui_cancel"):
			_on_back()
			if get_viewport(): get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed:
		KeybindingManager.rebind_action(waiting_for_key, event.physical_keycode)
		keybind_buttons[waiting_for_key].text = KeybindingManager.get_key_name(waiting_for_key)
		waiting_for_key = ""
		if get_viewport(): get_viewport().set_input_as_handled()

# ---------------------------------------------------------------------------
# Reset current tab defaults
# ---------------------------------------------------------------------------
func _on_reset_tab() -> void:
	var current_tab: int = tab_container.current_tab
	if not tab_controls.has(current_tab):
		return
	for entry in tab_controls[current_tab]:
		var key: String = entry["key"]
		var default_val: Variant = entry["default"]
		var node: Control = entry["node"]
		var type: String = entry["type"]
		_save(key, default_val)
		match type:
			"toggle":
				(node as CheckButton).button_pressed = default_val
			"slider":
				(node as HSlider).value = default_val
			"dropdown":
				(node as OptionButton).selected = default_val

# ---------------------------------------------------------------------------
# Rebuild UI (after language change)
# ---------------------------------------------------------------------------
func _rebuild_ui() -> void:
	var current_tab := tab_container.current_tab
	# Remove all children and rebuild
	for child in get_children():
		child.queue_free()
	tab_controls.clear()
	_gfx_controls.clear()
	keybind_buttons.clear()
	_save_btn = null
	call_deferred("_deferred_rebuild", current_tab)

func _deferred_rebuild(restore_tab: int) -> void:
	_build_ui()
	_original_values = SaveManager.data.duplicate()
	if restore_tab < tab_container.get_tab_count():
		tab_container.current_tab = restore_tab
	call_deferred("_set_tab_focus")

# ---------------------------------------------------------------------------
# Back
# ---------------------------------------------------------------------------
func _on_back() -> void:
	AudioManager.play_sfx("menu_click")
	# Reverter mudancas nao salvas (restaura previews ao estado original)
	if not _pending_changes.is_empty():
		for key in _pending_changes:
			if _original_values.has(key):
				SaveManager.data[key] = _original_values[key]
		# Re-aplicar configuracoes originais para reverter previews visuais/audio
		SaveManager._restore_settings()
		_pending_changes.clear()
	LoadingScreen.transition_to("res://scenes/ui/main_menu.tscn")

func _on_save_settings() -> void:
	AudioManager.play_sfx("menu_click")
	SaveManager.save_game()
	_original_values = SaveManager.data.duplicate()
	_pending_changes.clear()
	_update_save_btn_label()

func _update_save_btn_label() -> void:
	if _save_btn and is_instance_valid(_save_btn):
		if _pending_changes.is_empty():
			_save_btn.text = LocaleManager.tr_key("opt_save")
		else:
			_save_btn.text = LocaleManager.tr_key("opt_save_pending")
