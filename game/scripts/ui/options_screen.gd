extends Control

## Tela de opcoes completa com abas: Video, Graficos, Audio, Gameplay, Controles, Acessibilidade, Idioma.

var waiting_for_key: String = ""
var keybind_buttons: Dictionary = {}
var tab_container: TabContainer
var tab_controls: Dictionary = {}  # tab_index -> Array of {key, default, node, type}

# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------
func _ready() -> void:
	# Safety: garante que nao esta pausado
	get_tree().paused = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	GamepadUI.notify_menu_opened()

# ---------------------------------------------------------------------------
# Helpers — save / load
# ---------------------------------------------------------------------------
func _save(key: String, value: Variant) -> void:
	SaveManager.data[key] = value
	SaveManager.save_game()

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
	title.text = "Opcoes"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	root_vbox.add_child(title)

	# Tab container
	tab_container = TabContainer.new()
	tab_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tab_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tab_container.add_theme_font_size_override("font_size", 14)
	root_vbox.add_child(tab_container)

	_build_tab_video()
	_build_tab_graficos()
	_build_tab_audio()
	_build_tab_gameplay()
	_build_tab_controles()
	_build_tab_acessibilidade()
	_build_tab_idioma()

	# Footer
	var footer := HBoxContainer.new()
	footer.alignment = BoxContainer.ALIGNMENT_END
	footer.add_theme_constant_override("separation", 12)

	var reset_btn := Button.new()
	reset_btn.text = "Restaurar padrao"
	reset_btn.pressed.connect(_on_reset_tab)
	footer.add_child(reset_btn)

	var back_btn := Button.new()
	back_btn.text = "Voltar"
	back_btn.pressed.connect(_on_back)
	footer.add_child(back_btn)

	root_vbox.add_child(footer)

# ---------------------------------------------------------------------------
# TAB 1 — Video
# ---------------------------------------------------------------------------
func _build_tab_video() -> void:
	var t := 0
	var vbox := _make_tab_content("Video")

	# Window Mode
	_add_dropdown(vbox, "Modo de janela", "video_window_mode",
		["Janela", "Tela cheia", "Sem bordas"], 0,
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
	var all_resolutions: Array[Vector2i] = [
		Vector2i(854, 480),
		Vector2i(1024, 576),
		Vector2i(1280, 720),
		Vector2i(1366, 768),
		Vector2i(1600, 900),
		Vector2i(1920, 1080),
		Vector2i(2560, 1440),
		Vector2i(3840, 2160),
	]
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

	_add_dropdown(vbox, "Resolucao", "video_resolution",
		res_labels, default_res_idx,
		func(idx: int) -> void:
			if idx < resolutions.size():
				var r := resolutions[idx]
				DisplayServer.window_set_size(r)
				var ss := DisplayServer.screen_get_size()
				DisplayServer.window_set_position((ss - r) / 2),
		t)

	# V-Sync
	_add_toggle(vbox, "V-Sync", "video_vsync", true,
		func(on: bool) -> void:
			if on:
				DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
			else:
				DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED),
		t)

	# FPS Limit
	var fps_options := ["30", "60", "120", "144", "240", "Ilimitado"]
	var fps_values := [30, 60, 120, 144, 240, 0]
	_add_dropdown(vbox, "Limite de FPS", "video_fps_limit",
		fps_options, 1,
		func(idx: int) -> void:
			if idx < fps_values.size():
				Engine.max_fps = fps_values[idx],
		t)

	# Brightness
	_add_slider(vbox, "Brilho", "video_brightness", 0.5, 2.0, 0.05, 1.0, Callable(), t)

# ---------------------------------------------------------------------------
# TAB 2 — Graficos
# ---------------------------------------------------------------------------
var _gfx_controls: Dictionary = {}

func _build_tab_graficos() -> void:
	var t := 1
	var vbox := _make_tab_content("Graficos")

	# Quality Preset
	_add_dropdown(vbox, "Predefinicao de qualidade", "gfx_preset",
		["Baixo", "Medio", "Alto", "Ultra", "Personalizado"], 2,
		func(idx: int) -> void:
			_apply_gfx_preset(idx),
		t)

	# MSAA
	var msaa_dd := _add_dropdown(vbox, "MSAA", "gfx_msaa",
		["Desligado", "2x", "4x", "8x"], 1,
		func(idx: int) -> void:
			_apply_msaa(idx),
		t)
	_gfx_controls["msaa"] = msaa_dd

	# Bloom
	var bloom_toggle := _add_toggle(vbox, "Bloom / Glow", "gfx_bloom", true, Callable(), t)
	_gfx_controls["bloom"] = bloom_toggle

	# Bloom Intensity
	var bloom_slider := _add_slider(vbox, "Intensidade do bloom", "gfx_bloom_intensity", 0.0, 2.0, 0.05, 1.0, Callable(), t)
	_gfx_controls["bloom_intensity"] = bloom_slider

	# SSAO
	var ssao_dd := _add_dropdown(vbox, "SSAO", "gfx_ssao",
		["Desligado", "Baixo", "Medio", "Alto"], 0, Callable(), t)
	_gfx_controls["ssao"] = ssao_dd

	# Shadow Quality
	var shadow_dd := _add_dropdown(vbox, "Qualidade de sombras", "gfx_shadows",
		["Desligado", "Baixo", "Medio", "Alto"], 2, Callable(), t)
	_gfx_controls["shadows"] = shadow_dd

	# Tone Mapping
	_add_dropdown(vbox, "Tone mapping", "gfx_tonemap",
		["Linear", "Reinhardt", "Filmic", "ACES"], 3, Callable(), t)

	# Particles
	var particles_dd := _add_dropdown(vbox, "Particulas", "gfx_particles",
		["Baixo", "Medio", "Alto"], 2, Callable(), t)
	_gfx_controls["particles"] = particles_dd

	# Screen Shake
	_add_dropdown(vbox, "Tremor de tela", "gfx_screen_shake",
		["Desligado", "Leve", "Normal", "Forte"], 2, Callable(), t)

	# Hit Freeze
	_add_toggle(vbox, "Congelamento de hit", "gfx_hit_freeze", true, Callable(), t)

	# Cel Shader
	_add_toggle(vbox, "Cel shader", "gfx_cel_shader", true, Callable(), t)

	# Outline
	_add_toggle(vbox, "Contorno", "gfx_outline", true, Callable(), t)

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
	var vbox := _make_tab_content("Audio")

	_add_slider(vbox, "Volume master", "audio_master", 0, 100, 5, 100,
		func(val: float) -> void:
			_apply_audio_bus("Master", val / 100.0),
		t)

	_add_slider(vbox, "Volume musica", "audio_music", 0, 100, 5, 80,
		func(val: float) -> void:
			_apply_audio_bus("Music", val / 100.0),
		t)

	_add_slider(vbox, "Volume efeitos", "audio_sfx", 0, 100, 5, 100,
		func(val: float) -> void:
			_apply_audio_bus("SFX", val / 100.0),
		t)

	_add_slider(vbox, "Volume interface", "audio_ui", 0, 100, 5, 100,
		func(val: float) -> void:
			_apply_audio_bus("UI", val / 100.0),
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
	var vbox := _make_tab_content("Gameplay")

	# Section: HUD
	_add_section(vbox, "HUD")
	_add_toggle(vbox, "Numeros de dano", "hud_damage_numbers", true, Callable(), t)
	_add_toggle(vbox, "Barra de HP inimigo", "hud_enemy_hp", true, Callable(), t)
	_add_toggle(vbox, "Contador de FPS", "hud_fps", false, Callable(), t)
	_add_toggle(vbox, "Timer", "hud_timer", true, Callable(), t)
	_add_toggle(vbox, "Contador de kills", "hud_kills", true, Callable(), t)
	_add_toggle(vbox, "Direcao do boss", "hud_boss_direction", true, Callable(), t)

	# Section: Jogo
	_add_section(vbox, "Jogo")
	_add_toggle(vbox, "Pausar ao perder foco", "game_pause_focus_loss", true, Callable(), t)
	_add_toggle(vbox, "Confirmar ao sair", "game_confirm_exit", true, Callable(), t)

	# Section: Telemetria
	_add_section(vbox, "Telemetria")
	_add_toggle(vbox, "Enviar dados anonimos", "telemetry_enabled", true,
		func(on: bool) -> void:
			Telemetry.set_enabled(on),
		t)

# ---------------------------------------------------------------------------
# TAB 5 — Controles
# ---------------------------------------------------------------------------
func _build_tab_controles() -> void:
	var t := 4
	var vbox := _make_tab_content("Controles")

	# Section: Teclado
	_add_section(vbox, "Teclado")

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
	reset_keys_btn.text = "Restaurar controles padrao"
	reset_keys_btn.pressed.connect(func() -> void:
		KeybindingManager.reset_defaults()
		for act in keybind_buttons:
			keybind_buttons[act].text = KeybindingManager.get_key_name(act)
	)
	vbox.add_child(reset_keys_btn)

	# Section: Gamepad
	_add_section(vbox, "Gamepad")

	_add_slider(vbox, "Zona morta do analogico", "input_deadzone", 0.05, 0.5, 0.01, 0.15, Callable(), t)
	_add_toggle(vbox, "Vibracao", "input_vibration", true, Callable(), t)

# ---------------------------------------------------------------------------
# TAB 6 — Acessibilidade
# ---------------------------------------------------------------------------
func _build_tab_acessibilidade() -> void:
	var t := 5
	var vbox := _make_tab_content("Acessibilidade")

	_add_dropdown(vbox, "Tamanho da fonte", "access_font_size",
		["80%", "100%", "120%", "150%"], 1, Callable(), t)

	_add_dropdown(vbox, "Escala da interface", "access_ui_scale",
		["80%", "100%", "120%", "150%"], 1, Callable(), t)

	_add_toggle(vbox, "Movimento reduzido", "access_reduced_motion", false, Callable(), t)
	_add_toggle(vbox, "Flash reduzido", "access_reduced_flash", false, Callable(), t)
	_add_toggle(vbox, "Alto contraste", "access_high_contrast", false, Callable(), t)

	_add_dropdown(vbox, "Modo daltonico", "access_colorblind",
		["Desligado", "Protanopia", "Deuteranopia", "Tritanopia"], 0, Callable(), t)

# ---------------------------------------------------------------------------
# TAB 7 — Idioma
# ---------------------------------------------------------------------------
func _build_tab_idioma() -> void:
	var t := 6
	var vbox := _make_tab_content("Idioma")

	var locales := LocaleManager.get_available_locales()
	var locale_names: Array[String] = []
	var current_idx := 0
	for i in range(locales.size()):
		locale_names.append(LocaleManager.get_locale_name(locales[i]))
		if locales[i] == LocaleManager.get_locale():
			current_idx = i

	_add_dropdown(vbox, "Idioma", "locale_index",
		locale_names, current_idx,
		func(idx: int) -> void:
			if idx < locales.size():
				LocaleManager.set_locale(locales[idx]),
		t)

# ---------------------------------------------------------------------------
# Keybinding rebind
# ---------------------------------------------------------------------------
func _start_rebind(action: String, btn: Button) -> void:
	waiting_for_key = action
	btn.text = "..."

func _unhandled_input(event: InputEvent) -> void:
	if waiting_for_key.is_empty():
		if event.is_action_pressed("ui_cancel"):
			_on_back()
			get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed:
		KeybindingManager.rebind_action(waiting_for_key, event.physical_keycode)
		keybind_buttons[waiting_for_key].text = KeybindingManager.get_key_name(waiting_for_key)
		waiting_for_key = ""
		get_viewport().set_input_as_handled()

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
# Back
# ---------------------------------------------------------------------------
func _on_back() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
