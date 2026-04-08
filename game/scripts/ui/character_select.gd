extends Control

## Tela de selecao de personagem — layout profissional.
## Grid 5x3 centralizado, info panel horizontal, design limpo.

var all_character_ids: Array[String] = []
var current_index: int = 0
var _confirmed_index: int = -1
var _bob_tween: Tween = null
var _glow_tween: Tween = null
var _play_pulse_tween: Tween = null
var _title_label: Label = null

# -- UI refs --
var _bg_gradient: ColorRect
var _grid: GridContainer
var _char_buttons: Array[Button] = []
var _tile_sprites: Array[TextureRect] = []

# Info panel refs
var _info_panel: PanelContainer
var _info_sprite: TextureRect
var _name_label: Label

# 3D model preview
var _3d_viewport: SubViewport = null
var _3d_container: SubViewportContainer = null
var _3d_model: Node3D = null
var _3d_pivot: Node3D = null
var _3d_rotation_tween: Tween = null
var _has_3d_preview: bool = false
var _passive_label: Label
var _weapon_label: Label
var _weapon_icon: TextureRect
var _element_badge: Label
var _lock_label: Label

# Action buttons
var _start_btn: Button
var _back_btn: Button

# Gold color constant
const GOLD := Color(0.85, 0.72, 0.25)
const GOLD_BRIGHT := Color(1.0, 0.88, 0.35)
const GOLD_DARK := Color(0.55, 0.45, 0.12)
const BG_COLOR := Color(0.03, 0.03, 0.06)

# Grid config
const GRID_COLS := 5
const TILE_SIZE := Vector2(80, 90)
const TILE_SPACING := 8
const INFO_SPRITE_SIZE := 128.0

func _ready() -> void:
	get_tree().paused = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_character_list()
	_find_first_unlocked()
	_build_ui()
	_update_selection()
	_animate_grid_entrance()
	_start_play_button_pulse()
	GamepadUI.notify_menu_opened()

func _load_character_list() -> void:
	all_character_ids.clear()
	for char_id in CharacterDB.get_all_character_ids():
		all_character_ids.append(char_id)

func _find_first_unlocked() -> void:
	for i in range(all_character_ids.size()):
		if SaveManager.is_character_unlocked(all_character_ids[i]):
			current_index = i
			return
	current_index = 0

# ===========================================================================
#  BUILD UI — full redesign
# ===========================================================================
func _build_ui() -> void:
	# -- Pixel art background texture (fallback to solid color) --
	_bg_gradient = ColorRect.new()
	_bg_gradient.set_anchors_preset(Control.PRESET_FULL_RECT)
	_bg_gradient.color = BG_COLOR
	add_child(_bg_gradient)

	var bg_tex_path := "res://assets/sprites/ui/menu_bg.png"
	if ResourceLoader.exists(bg_tex_path):
		var bg_tex := TextureRect.new()
		bg_tex.name = "CharSelectBgTexture"
		bg_tex.texture = load(bg_tex_path)
		bg_tex.set_anchors_preset(Control.PRESET_FULL_RECT)
		bg_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		bg_tex.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		bg_tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(bg_tex)

	# Dark overlay for depth
	var overlay := ColorRect.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0, 0, 0, 0.25)
	add_child(overlay)

	# -- Main vertical layout (margin container for padding) --
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 40)
	margin.add_theme_constant_override("margin_right", 40)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	add_child(margin)

	var main_vbox := VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 12)
	margin.add_child(main_vbox)

	# ---- TOP BAR: Back button + Title ----
	_build_top_bar(main_vbox)

	# ---- CHARACTER GRID (center, 5 columns) ----
	var grid_center := CenterContainer.new()
	grid_center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(grid_center)

	_grid = GridContainer.new()
	_grid.columns = GRID_COLS
	_grid.add_theme_constant_override("h_separation", TILE_SPACING)
	_grid.add_theme_constant_override("v_separation", TILE_SPACING)
	grid_center.add_child(_grid)

	_build_character_grid()

	# ---- INFO PANEL (horizontal, below grid) ----
	_build_info_panel(main_vbox)

	# ---- ACTION BUTTONS ----
	_build_action_buttons(main_vbox)

	# ---- EXTRA NAV (tiny, at very bottom) ----
	_build_extra_nav(main_vbox)


func _build_top_bar(parent: VBoxContainer) -> void:
	var top_bar := HBoxContainer.new()
	top_bar.add_theme_constant_override("separation", 16)
	top_bar.alignment = BoxContainer.ALIGNMENT_CENTER
	parent.add_child(top_bar)

	# Back button (left-aligned via spacer trick)
	_back_btn = Button.new()
	_back_btn.text = "<  Voltar"
	_back_btn.custom_minimum_size = Vector2(90, 32)
	_back_btn.add_theme_font_size_override("font_size", 12)
	_back_btn.add_theme_color_override("font_color", Color(0.55, 0.55, 0.65))
	_back_btn.add_theme_color_override("font_hover_color", Color(0.9, 0.85, 0.7))
	var back_style := StyleBoxFlat.new()
	back_style.bg_color = Color(0.06, 0.06, 0.09, 0.8)
	back_style.set_corner_radius_all(4)
	back_style.set_border_width_all(1)
	back_style.border_color = Color(0.15, 0.15, 0.22)
	back_style.content_margin_left = 8
	back_style.content_margin_right = 8
	back_style.content_margin_top = 4
	back_style.content_margin_bottom = 4
	_back_btn.add_theme_stylebox_override("normal", back_style)
	var back_hover := back_style.duplicate()
	back_hover.bg_color = Color(0.10, 0.10, 0.14, 0.9)
	back_hover.border_color = Color(0.3, 0.3, 0.4)
	_back_btn.add_theme_stylebox_override("hover", back_hover)
	_back_btn.add_theme_stylebox_override("focus", back_hover.duplicate())
	_back_btn.add_theme_stylebox_override("pressed", back_style.duplicate())
	_back_btn.pressed.connect(_on_back)
	top_bar.add_child(_back_btn)

	# Spacer left
	var spacer_l := Control.new()
	spacer_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_bar.add_child(spacer_l)

	# Title — bigger and gold
	_title_label = Label.new()
	_title_label.text = "ESCOLHA SEU HEROI"
	_title_label.add_theme_font_size_override("font_size", 28)
	_title_label.add_theme_color_override("font_color", GOLD_BRIGHT)
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	top_bar.add_child(_title_label)

	# Spacer right (balance)
	var spacer_r := Control.new()
	spacer_r.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_bar.add_child(spacer_r)

	# Invisible placeholder to balance the back button width
	var placeholder := Control.new()
	placeholder.custom_minimum_size = Vector2(90, 0)
	top_bar.add_child(placeholder)


func _build_character_grid() -> void:
	_char_buttons.clear()
	_tile_sprites.clear()

	for i in range(all_character_ids.size()):
		var char_id := all_character_ids[i]
		var data: Dictionary = CharacterDB.get_character(char_id)
		var is_locked := not SaveManager.is_character_unlocked(char_id)
		var char_color: Color = data.get("color", Color(0.5, 0.5, 0.5))

		# -- Tile button --
		var btn := Button.new()
		btn.custom_minimum_size = TILE_SIZE
		btn.clip_contents = true

		# Normal style — with subtle depth shadow
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.06, 0.06, 0.10, 0.95)
		style.set_corner_radius_all(8)
		style.set_border_width_all(2)
		style.shadow_color = Color(0, 0, 0, 0.25)
		style.shadow_size = 3
		style.shadow_offset = Vector2(0, 2)
		if is_locked:
			style.border_color = Color(0.12, 0.12, 0.18)
		else:
			style.border_color = char_color.darkened(0.5)
		btn.add_theme_stylebox_override("normal", style)

		# Hover style
		var hover := style.duplicate()
		hover.bg_color = Color(0.10, 0.10, 0.16, 0.98)
		if is_locked:
			hover.border_color = Color(0.22, 0.22, 0.30)
		else:
			hover.border_color = char_color.darkened(0.2)
		btn.add_theme_stylebox_override("hover", hover)
		btn.add_theme_stylebox_override("focus", hover.duplicate())
		btn.add_theme_stylebox_override("pressed", style.duplicate())

		# -- Sprite inside tile --
		var tex := TextureRect.new()
		tex.custom_minimum_size = Vector2(56, 56)
		tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tex.set_anchors_preset(Control.PRESET_CENTER)
		tex.offset_left = -28
		tex.offset_top = -34
		tex.offset_right = 28
		tex.offset_bottom = 22

		var sprite_path := "res://assets/sprites/characters/%s.png" % char_id
		if ResourceLoader.exists(sprite_path):
			tex.texture = load(sprite_path)
		var is_teaser := is_locked and char_id in ["mystery", "fragmentado"]
		if is_locked:
			if is_teaser:
				tex.modulate = Color(0, 0, 0, 0.85)  # PRD 46: silhueta preta
			else:
				tex.modulate = Color(0.2, 0.2, 0.25)
		btn.add_child(tex)
		_tile_sprites.append(tex)

		# -- Name label below sprite --
		var name_lbl := Label.new()
		var display_name: String = data.get("name", char_id)
		# Truncate long names for tile
		if display_name.length() > 6:
			name_lbl.text = display_name.left(5) + "."
		else:
			name_lbl.text = display_name
		name_lbl.add_theme_font_size_override("font_size", 9)
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		name_lbl.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
		name_lbl.offset_top = -18
		name_lbl.offset_bottom = -2
		if is_locked:
			name_lbl.add_theme_color_override("font_color", Color(0.3, 0.3, 0.35))
		else:
			name_lbl.add_theme_color_override("font_color", Color(0.65, 0.65, 0.72))
		btn.add_child(name_lbl)

		# -- Lock icon overlay --
		if is_locked:
			var lock_icon := Label.new()
			if is_teaser:
				lock_icon.text = "◈"  # PRD 46: cristal de Zion
				lock_icon.add_theme_color_override("font_color", Color(0.5, 0.3, 0.8, 0.7))
			else:
				lock_icon.text = "🔒"
			lock_icon.add_theme_font_size_override("font_size", 14)
			lock_icon.set_anchors_preset(Control.PRESET_CENTER)
			lock_icon.offset_left = -10
			lock_icon.offset_top = -10
			lock_icon.offset_right = 10
			lock_icon.offset_bottom = 10
			lock_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
			btn.add_child(lock_icon)

		# -- PRD 46: Teaser glow + glitch for mystery/fragmentado --
		if is_teaser:
			# Pulsating glow background
			var glow := ColorRect.new()
			glow.name = "TeaserGlow"
			glow.set_anchors_preset(Control.PRESET_FULL_RECT)
			glow.color = Color(GameConstants.TEASER_GLOW_COLOR.r, GameConstants.TEASER_GLOW_COLOR.g, GameConstants.TEASER_GLOW_COLOR.b, 0.0)
			glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
			btn.add_child(glow)
			btn.move_child(glow, 0)  # Atras do sprite

			if not AccessibilityManager.reduced_motion:
				var pulse := create_tween()
				pulse.set_loops()
				pulse.tween_property(glow, "color:a", GameConstants.TEASER_GLOW_MAX_ALPHA, GameConstants.TEASER_PULSE_IN)
				pulse.tween_property(glow, "color:a", 0.0, GameConstants.TEASER_PULSE_OUT)

				# Glitch effect
				_start_teaser_glitch(tex, name_lbl, char_id)

		var idx := i
		btn.pressed.connect(func(): _select_character(idx))
		_grid.add_child(btn)
		_char_buttons.append(btn)


## PRD 46: Glitch effect for teaser characters (mystery/fragmentado)
func _start_teaser_glitch(sprite: TextureRect, name_lbl: Label, char_id: String) -> void:
	var glitch_tween := create_tween()
	glitch_tween.set_loops()
	var glitch_chars := ["▓", "░", "█", "◈", "⬡", "⟐"]
	var original_name: String = name_lbl.text

	# Espera tempo aleatorio entre glitches
	glitch_tween.tween_interval(randf_range(GameConstants.TEASER_GLITCH_MIN_WAIT, GameConstants.TEASER_GLITCH_MAX_WAIT))

	# Revela o sprite real brevemente
	glitch_tween.tween_callback(func():
		var offset_x := randf_range(-3.0, 3.0)
		var offset_y := randf_range(-2.0, 2.0)
		sprite.position.x += offset_x
		sprite.position.y += offset_y
		sprite.modulate = Color(1, 1, 1, 0.6)  # Semi-transparente
		if char_id == "mystery":
			name_lbl.text = glitch_chars[randi() % glitch_chars.size()]
		# Agenda restauracao
		get_tree().create_timer(GameConstants.TEASER_GLITCH_DURATION).timeout.connect(func():
			if is_instance_valid(sprite):
				sprite.modulate = Color(0, 0, 0, 0.85)
				sprite.position.x -= offset_x
				sprite.position.y -= offset_y
			if is_instance_valid(name_lbl):
				name_lbl.text = original_name
		)
	)
	# Intervalo para o proximo ciclo
	glitch_tween.tween_interval(GameConstants.TEASER_GLITCH_DURATION + 0.05)


func _build_info_panel(parent: VBoxContainer) -> void:
	_info_panel = PanelContainer.new()
	_info_panel.custom_minimum_size = Vector2(0, 130)
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.05, 0.04, 0.09, 0.95)
	panel_style.set_corner_radius_all(12)
	panel_style.set_border_width_all(1)
	panel_style.border_color = Color(0.2, 0.18, 0.3, 0.5)
	panel_style.content_margin_left = 24
	panel_style.content_margin_right = 24
	panel_style.content_margin_top = 14
	panel_style.content_margin_bottom = 14
	# Subtle gradient via shadow for depth
	panel_style.shadow_color = Color(0.06, 0.04, 0.12, 0.4)
	panel_style.shadow_size = 8
	panel_style.shadow_offset = Vector2(0, 3)
	_info_panel.add_theme_stylebox_override("panel", panel_style)
	parent.add_child(_info_panel)

	# Horizontal layout: sprite | text info
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 20)
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	_info_panel.add_child(hbox)

	# -- Character preview container (holds either 3D viewport or 2D sprite) --
	var preview_container := Control.new()
	preview_container.custom_minimum_size = Vector2(INFO_SPRITE_SIZE, INFO_SPRITE_SIZE)
	preview_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(preview_container)

	# 3D SubViewport for model preview
	_3d_container = SubViewportContainer.new()
	_3d_container.custom_minimum_size = Vector2(INFO_SPRITE_SIZE, INFO_SPRITE_SIZE)
	_3d_container.size = Vector2(INFO_SPRITE_SIZE, INFO_SPRITE_SIZE)
	_3d_container.stretch = true
	_3d_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_3d_container.visible = false
	preview_container.add_child(_3d_container)

	_3d_viewport = SubViewport.new()
	_3d_viewport.size = Vector2i(int(INFO_SPRITE_SIZE * 2), int(INFO_SPRITE_SIZE * 2))
	_3d_viewport.transparent_bg = true
	_3d_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_3d_viewport.msaa_3d = Viewport.MSAA_2X
	_3d_container.add_child(_3d_viewport)

	# Camera for 3D preview
	var cam := Camera3D.new()
	cam.name = "PreviewCamera"
	cam.transform.origin = Vector3(0, 0.8, 2.2)
	cam.rotation_degrees = Vector3(-10, 0, 0)
	cam.fov = 30.0
	cam.current = true
	_3d_viewport.add_child(cam)

	# Lighting for 3D preview
	var light := DirectionalLight3D.new()
	light.name = "PreviewLight"
	light.transform.origin = Vector3(2, 3, 2)
	light.rotation_degrees = Vector3(-40, 30, 0)
	light.light_energy = 1.2
	light.shadow_enabled = false
	_3d_viewport.add_child(light)

	# Fill light from opposite side
	var fill_light := DirectionalLight3D.new()
	fill_light.name = "PreviewFillLight"
	fill_light.rotation_degrees = Vector3(-20, -150, 0)
	fill_light.light_energy = 0.4
	fill_light.shadow_enabled = false
	_3d_viewport.add_child(fill_light)

	# Pivot node for rotation
	_3d_pivot = Node3D.new()
	_3d_pivot.name = "ModelPivot"
	_3d_viewport.add_child(_3d_pivot)

	# Fallback 2D sprite (hidden when 3D is active)
	_info_sprite = TextureRect.new()
	_info_sprite.custom_minimum_size = Vector2(INFO_SPRITE_SIZE, INFO_SPRITE_SIZE)
	_info_sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_info_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_info_sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview_container.add_child(_info_sprite)

	# -- Vertical separator line --
	var vsep := VSeparator.new()
	vsep.add_theme_constant_override("separation", 4)
	hbox.add_child(vsep)

	# -- Text info column --
	var info_vbox := VBoxContainer.new()
	info_vbox.add_theme_constant_override("separation", 4)
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(info_vbox)

	# Character name
	_name_label = Label.new()
	_name_label.add_theme_font_size_override("font_size", 24)
	_name_label.add_theme_color_override("font_color", Color.WHITE)
	info_vbox.add_child(_name_label)

	# Weapon row
	var weapon_row := HBoxContainer.new()
	weapon_row.add_theme_constant_override("separation", 6)
	info_vbox.add_child(weapon_row)

	var weapon_prefix := Label.new()
	weapon_prefix.text = "Arma:"
	weapon_prefix.add_theme_font_size_override("font_size", 12)
	weapon_prefix.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
	weapon_row.add_child(weapon_prefix)

	_weapon_icon = TextureRect.new()
	_weapon_icon.custom_minimum_size = Vector2(32, 32)
	_weapon_icon.size = Vector2(32, 32)
	_weapon_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_weapon_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_weapon_icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_weapon_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	weapon_row.add_child(_weapon_icon)

	_weapon_label = Label.new()
	_weapon_label.add_theme_font_size_override("font_size", 14)
	_weapon_label.add_theme_color_override("font_color", GOLD_BRIGHT)
	weapon_row.add_child(_weapon_label)

	# Passive ability — bigger and more prominent
	_passive_label = Label.new()
	_passive_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_passive_label.add_theme_font_size_override("font_size", 14)
	_passive_label.add_theme_color_override("font_color", Color(0.5, 0.95, 0.4))
	info_vbox.add_child(_passive_label)

	# Element badge
	_element_badge = Label.new()
	_element_badge.add_theme_font_size_override("font_size", 12)
	_element_badge.add_theme_color_override("font_color", Color(0.55, 0.6, 0.75))
	info_vbox.add_child(_element_badge)

	# Lock label (shown only when character locked)
	_lock_label = Label.new()
	_lock_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_lock_label.add_theme_font_size_override("font_size", 12)
	_lock_label.add_theme_color_override("font_color", Color(1.0, 0.5, 0.5))
	_lock_label.visible = false
	info_vbox.add_child(_lock_label)


func _build_action_buttons(parent: VBoxContainer) -> void:
	var btn_center := CenterContainer.new()
	parent.add_child(btn_center)

	var btn_row := HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 16)
	btn_center.add_child(btn_row)

	# -- JOGAR button (big, gold, glowing) --
	_start_btn = Button.new()
	_start_btn.text = "JOGAR"
	_start_btn.custom_minimum_size = Vector2(200, 52)
	_start_btn.add_theme_font_size_override("font_size", 20)
	_start_btn.add_theme_color_override("font_color", Color(0.1, 0.08, 0.02))
	_start_btn.add_theme_color_override("font_hover_color", Color(0.05, 0.04, 0.01))

	var gold_style := StyleBoxFlat.new()
	gold_style.bg_color = GOLD_BRIGHT
	gold_style.set_corner_radius_all(10)
	gold_style.set_border_width_all(2)
	gold_style.border_color = Color(1.0, 0.95, 0.6)
	gold_style.content_margin_left = 32
	gold_style.content_margin_right = 32
	gold_style.content_margin_top = 12
	gold_style.content_margin_bottom = 12
	gold_style.shadow_color = Color(0.85, 0.72, 0.25, 0.35)
	gold_style.shadow_size = 6
	gold_style.shadow_offset = Vector2(0, 2)
	_start_btn.add_theme_stylebox_override("normal", gold_style)

	var gold_hover := gold_style.duplicate()
	gold_hover.bg_color = Color(1.0, 0.92, 0.45)
	gold_hover.border_color = Color.WHITE
	gold_hover.shadow_color = Color(1.0, 0.88, 0.35, 0.5)
	gold_hover.shadow_size = 10
	_start_btn.add_theme_stylebox_override("hover", gold_hover)
	_start_btn.add_theme_stylebox_override("focus", gold_hover.duplicate())

	var gold_pressed := gold_style.duplicate()
	gold_pressed.bg_color = GOLD.darkened(0.15)
	_start_btn.add_theme_stylebox_override("pressed", gold_pressed)

	var gold_disabled := gold_style.duplicate()
	gold_disabled.bg_color = Color(0.3, 0.3, 0.3)
	gold_disabled.border_color = Color(0.4, 0.4, 0.4)
	_start_btn.add_theme_stylebox_override("disabled", gold_disabled)
	_start_btn.add_theme_color_override("font_disabled_color", Color(0.55, 0.55, 0.55))

	_start_btn.pressed.connect(_on_start)
	btn_row.add_child(_start_btn)

	# -- Aleatorio button (secondary) --
	var random_btn := _make_secondary_btn("Aleatorio")
	random_btn.pressed.connect(_on_random_start)
	btn_row.add_child(random_btn)


func _build_extra_nav(parent: VBoxContainer) -> void:
	var nav_center := CenterContainer.new()
	parent.add_child(nav_center)

	var nav_row := HBoxContainer.new()
	nav_row.add_theme_constant_override("separation", 12)
	nav_center.add_child(nav_row)

	var nav_items := [
		{"label": "Diario", "scene": "res://scenes/ui/daily_challenge_screen.tscn"},
		{"label": "Ranking", "scene": "res://scenes/ui/leaderboard_screen.tscn"},
		{"label": "Bestiario", "scene": "res://scenes/ui/bestiary_screen.tscn"},
		{"label": "Codex", "scene": "res://scenes/ui/codex_screen.tscn"},
		{"label": "Conquistas", "scene": "res://scenes/ui/achievements_screen.tscn"},
	]

	for item in nav_items:
		var btn := Button.new()
		btn.text = item["label"]
		btn.custom_minimum_size = Vector2(0, 24)
		btn.add_theme_font_size_override("font_size", 10)
		btn.add_theme_color_override("font_color", Color(0.4, 0.4, 0.48))
		btn.add_theme_color_override("font_hover_color", Color(0.75, 0.7, 0.5))

		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.0, 0.0, 0.0, 0.0)
		sb.set_corner_radius_all(3)
		sb.set_border_width_all(0)
		sb.content_margin_left = 6
		sb.content_margin_right = 6
		sb.content_margin_top = 2
		sb.content_margin_bottom = 2
		btn.add_theme_stylebox_override("normal", sb)

		var sb_h := sb.duplicate()
		sb_h.bg_color = Color(0.08, 0.08, 0.12, 0.6)
		sb_h.set_border_width_all(1)
		sb_h.border_color = Color(0.2, 0.2, 0.28)
		btn.add_theme_stylebox_override("hover", sb_h)
		btn.add_theme_stylebox_override("focus", sb_h.duplicate())
		btn.add_theme_stylebox_override("pressed", sb.duplicate())

		var scene_path: String = item["scene"]
		btn.pressed.connect(func():
			AudioManager.play_sfx("menu_click")
			LoadingScreen.transition_to(scene_path)
		)
		nav_row.add_child(btn)


func _make_secondary_btn(text: String) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(120, 40)
	btn.add_theme_font_size_override("font_size", 13)
	btn.add_theme_color_override("font_color", Color(0.75, 0.72, 0.65))
	btn.add_theme_color_override("font_hover_color", Color(0.95, 0.9, 0.8))

	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.08, 0.08, 0.12, 0.9)
	s.set_corner_radius_all(6)
	s.set_border_width_all(1)
	s.border_color = Color(0.25, 0.25, 0.32)
	s.content_margin_left = 16
	s.content_margin_right = 16
	s.content_margin_top = 8
	s.content_margin_bottom = 8
	btn.add_theme_stylebox_override("normal", s)

	var h := s.duplicate()
	h.bg_color = Color(0.12, 0.12, 0.18, 0.95)
	h.border_color = Color(0.4, 0.38, 0.3)
	btn.add_theme_stylebox_override("hover", h)
	btn.add_theme_stylebox_override("focus", h.duplicate())
	btn.add_theme_stylebox_override("pressed", s.duplicate())
	return btn


# ===========================================================================
#  UPDATE SELECTION
# ===========================================================================
func _update_selection() -> void:
	var char_id := all_character_ids[current_index]
	var data: Dictionary = CharacterDB.get_character(char_id) if CharacterDB else {}
	if not data:
		data = {}
	var is_locked := not SaveManager.is_character_unlocked(char_id)
	var char_color: Color = data.get("color", Color(0.5, 0.5, 0.5))

	# -- Background tint --
	_bg_gradient.color = Color(
		char_color.r * 0.08,
		char_color.g * 0.08,
		char_color.b * 0.08
	)

	# -- Info panel sprite --
	_load_info_sprite(char_id)

	# -- Info text --
	_name_label.text = data.get("name", char_id).to_upper()
	_name_label.add_theme_color_override("font_color", char_color.lightened(0.3))

	# PRD 46: teaser characters show corrupted passive
	var _is_teaser := is_locked and char_id in ["mystery", "fragmentado"]
	if _is_teaser:
		_passive_label.text = "[dados corrompidos]"
		_passive_label.add_theme_color_override("font_color", Color(0.4, 0.3, 0.55))
	else:
		_passive_label.text = data.get("passive", "")
		_passive_label.add_theme_color_override("font_color", Color(0.6, 0.85, 0.5))

	# Weapon
	var weapon_id: String = data.get("starting_weapon", "katana")
	var weapon_data: Dictionary = WeaponDB.get_weapon(weapon_id) if WeaponDB else {}
	_weapon_label.text = weapon_data.get("name", "???") if weapon_data else "???"
	var weapon_icon_path := "res://assets/icons/weapons/%s.svg" % weapon_id
	if ResourceLoader.exists(weapon_icon_path):
		_weapon_icon.texture = load(weapon_icon_path)
	else:
		_weapon_icon.texture = null

	# Element
	var element: String = weapon_data.get("element", "physical") if weapon_data else "physical"
	var element_names := {
		"physical": "Fisico", "fire": "Fogo", "ice": "Gelo",
		"electric": "Eletrico", "dark": "Dark", "poison": "Veneno"
	}
	_element_badge.text = "Elemento: %s" % element_names.get(element, element)

	# Lock
	if is_locked:
		var unlock_desc = data.get("unlock_description", "???")
		if typeof(unlock_desc) != TYPE_STRING:
			unlock_desc = str(unlock_desc) if unlock_desc != null else "???"
		if _is_teaser:
			_lock_label.text = "◈ %s" % unlock_desc
		else:
			_lock_label.text = "🔒 %s" % unlock_desc
		_lock_label.visible = true
		_start_btn.disabled = true
		_start_btn.text = "BLOQUEADO"
	else:
		_lock_label.visible = false
		_start_btn.disabled = false
		_start_btn.text = "JOGAR"

	# -- Highlight tiles in grid --
	_update_tile_highlights(char_color)


func _update_tile_highlights(selected_color: Color) -> void:
	# Kill previous glow pulse tween
	if _glow_tween:
		_glow_tween.kill()
		_glow_tween = null

	for i in range(_char_buttons.size()):
		var btn := _char_buttons[i]
		var style := btn.get_theme_stylebox("normal") as StyleBoxFlat
		if not style:
			continue

		var cid := all_character_ids[i]
		var cdata: Dictionary = CharacterDB.get_character(cid)
		var clocked := not SaveManager.is_character_unlocked(cid)
		var cc: Color = cdata.get("color", Color(0.5, 0.5, 0.5))

		if i == current_index:
			# Selected: bright gold glow border, brighter bg, scale up
			style.border_color = GOLD_BRIGHT
			style.set_border_width_all(3)
			style.bg_color = Color(
				selected_color.r * 0.2,
				selected_color.g * 0.2,
				selected_color.b * 0.2, 0.98
			)
			# Add subtle shadow glow for selected tile
			style.shadow_color = Color(GOLD.r, GOLD.g, GOLD.b, 0.3)
			style.shadow_size = 4
			style.shadow_offset = Vector2(0, 0)
			btn.pivot_offset = TILE_SIZE / 2.0
			# Animate scale to 1.1
			var tw := create_tween()
			tw.tween_property(btn, "scale", Vector2(1.1, 1.1), 0.15) \
				.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

			# Animated gold pulse on the selected tile border
			if not AccessibilityManager.reduced_motion:
				_glow_tween = create_tween().set_loops()
				_glow_tween.tween_property(style, "border_color", GOLD_BRIGHT, 0.8) \
					.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
				_glow_tween.tween_property(style, "border_color", GOLD.darkened(0.15), 0.8) \
					.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		else:
			# Not selected: restore
			style.set_border_width_all(2)
			style.shadow_size = 0
			if clocked:
				style.border_color = Color(0.12, 0.12, 0.18)
			else:
				style.border_color = cc.darkened(0.5)
			style.bg_color = Color(0.06, 0.06, 0.10, 0.95)
			btn.pivot_offset = TILE_SIZE / 2.0
			var tw := create_tween()
			tw.tween_property(btn, "scale", Vector2.ONE, 0.1) \
				.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _load_info_sprite(char_id: String) -> void:
	# Always use 2D sprite preview (3D models disabled)
	_hide_3d_preview()
	var sprite_path := "res://assets/sprites/characters/%s.png" % char_id
	if ResourceLoader.exists(sprite_path):
		_info_sprite.texture = load(sprite_path)
	else:
		_info_sprite.texture = null
	_start_bob_animation()


func _show_3d_preview(model_path: String) -> void:
	# Remove old model
	if _3d_model and is_instance_valid(_3d_model):
		_3d_model.queue_free()
		_3d_model = null

	# Stop rotation tween
	if _3d_rotation_tween:
		_3d_rotation_tween.kill()
		_3d_rotation_tween = null

	# Stop bob animation on 2D sprite
	if _bob_tween:
		_bob_tween.kill()
		_bob_tween = null

	# Load and instance the 3D model
	var scene: PackedScene = load(model_path)
	if not scene:
		_hide_3d_preview()
		return

	_3d_model = scene.instantiate()
	_3d_pivot.add_child(_3d_model)

	# Reset pivot rotation for new character
	_3d_pivot.rotation = Vector3.ZERO

	# Show 3D, hide 2D
	_3d_container.visible = true
	_info_sprite.visible = false
	_has_3d_preview = true

	# Start slow rotation
	_start_model_rotation()


func _hide_3d_preview() -> void:
	if _3d_model and is_instance_valid(_3d_model):
		_3d_model.queue_free()
		_3d_model = null
	if _3d_rotation_tween:
		_3d_rotation_tween.kill()
		_3d_rotation_tween = null
	_3d_container.visible = false
	_info_sprite.visible = true
	_has_3d_preview = false


func _start_model_rotation() -> void:
	if _3d_rotation_tween:
		_3d_rotation_tween.kill()
	# Full 360 rotation over 8 seconds, looping forever
	_3d_rotation_tween = create_tween().set_loops()
	_3d_rotation_tween.tween_property(_3d_pivot, "rotation_degrees:y", 360.0, 8.0) \
		.from(0.0).set_trans(Tween.TRANS_LINEAR)
	_3d_rotation_tween.tween_callback(func():
		_3d_pivot.rotation_degrees.y = 0.0
	)


func _start_bob_animation() -> void:
	if _bob_tween:
		_bob_tween.kill()
	_info_sprite.position = Vector2.ZERO
	_bob_tween = create_tween().set_loops()
	_bob_tween.tween_property(_info_sprite, "position:y", -5.0, 0.9) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_bob_tween.tween_property(_info_sprite, "position:y", 0.0, 0.9) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


# ===========================================================================
#  ENTRANCE & PULSE ANIMATIONS
# ===========================================================================

## Grid cascade entrance — each tile fades in + scales from 0.8 with stagger
func _animate_grid_entrance() -> void:
	if AccessibilityManager.reduced_motion:
		return
	for i in range(_char_buttons.size()):
		var btn := _char_buttons[i]
		btn.modulate = Color(1, 1, 1, 0)
		btn.scale = Vector2(0.8, 0.8)
		btn.pivot_offset = TILE_SIZE / 2.0
		var delay := i * 0.03
		var tw := create_tween()
		tw.set_parallel(true)
		tw.tween_property(btn, "modulate:a", 1.0, 0.25) \
			.set_delay(delay).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(btn, "scale", Vector2.ONE, 0.3) \
			.set_delay(delay).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	# After entrance completes, re-apply current selection scale
	var total_delay := _char_buttons.size() * 0.03 + 0.3
	get_tree().create_timer(total_delay).timeout.connect(func():
		_update_selection()
	)


## Subtle pulse on the JOGAR button — scale oscillation
func _start_play_button_pulse() -> void:
	if AccessibilityManager.reduced_motion:
		return
	_start_btn.pivot_offset = _start_btn.custom_minimum_size / 2.0
	_play_pulse_tween = create_tween().set_loops()
	_play_pulse_tween.tween_property(_start_btn, "scale", Vector2(1.04, 1.04), 0.9) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_play_pulse_tween.tween_property(_start_btn, "scale", Vector2(1.0, 1.0), 0.9) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


# ===========================================================================
#  INPUT & NAVIGATION
# ===========================================================================
func _select_character(idx: int) -> void:
	if idx != current_index:
		_confirmed_index = -1
	current_index = idx
	_update_selection()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_left") or event.is_action_pressed("move_left"):
		current_index = (current_index - 1) % all_character_ids.size()
		if current_index < 0:
			current_index = all_character_ids.size() - 1
		_confirmed_index = -1
		_update_selection()
		if get_viewport(): get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_right") or event.is_action_pressed("move_right"):
		current_index = (current_index + 1) % all_character_ids.size()
		_confirmed_index = -1
		_update_selection()
		if get_viewport(): get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_up") or event.is_action_pressed("move_up"):
		var new_idx := current_index - GRID_COLS
		if new_idx >= 0:
			current_index = new_idx
			_confirmed_index = -1
			_update_selection()
		if get_viewport(): get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_down") or event.is_action_pressed("move_down"):
		var new_idx := current_index + GRID_COLS
		if new_idx < all_character_ids.size():
			current_index = new_idx
			_confirmed_index = -1
			_update_selection()
		if get_viewport(): get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_accept"):
		if current_index == _confirmed_index:
			# Segunda confirmacao no mesmo personagem → jogar
			_on_start()
		else:
			# Primeira confirmacao → apenas seleciona
			_confirmed_index = current_index
			_update_selection()
			AudioManager.play_sfx("menu_click")
		if get_viewport(): get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel"):
		_on_back()
		if get_viewport(): get_viewport().set_input_as_handled()


# ===========================================================================
#  ACTIONS (game logic preserved exactly)
# ===========================================================================
func _on_start() -> void:
	var char_id = all_character_ids[current_index]
	if SaveManager.is_character_unlocked(char_id):
		AudioManager.play_sfx("menu_click")
		GameManager.selected_character = char_id
		GameManager.auto_play = false
		MutationManager.reset()  # Skip mutations panel
		LoadingScreen.transition_to("res://scenes/ui/stage_select.tscn")
	else:
		AudioManager.play_sfx("error")

func _on_random_start() -> void:
	# Pick random unlocked character
	var unlocked: Array[String] = []
	for cid in all_character_ids:
		if SaveManager.is_character_unlocked(cid):
			unlocked.append(cid)
	if unlocked.is_empty():
		return
	var char_id = unlocked[randi() % unlocked.size()]
	GameManager.selected_character = char_id

	# Pick random stage
	var stages = GameConstants.ENABLED_STAGES
	GameManager.selected_stage = stages[randi() % stages.size()]

	# No mutations, no relic, normal mode, auto-play ON
	MutationManager.reset()
	GameManager.selected_relic = ""
	GameManager.game_mode = "normal"
	GameManager.run_time_limit = 900.0
	GameManager.auto_play = true

	# Go straight to game
	var scene_path = GameConstants.STAGE_SCENE_PATHS.get(GameManager.selected_stage, "res://scenes/stages/stage_cemetery.tscn")
	LoadingScreen.load_stage(scene_path)

func _on_back() -> void:
	AudioManager.play_sfx("menu_click")
	LoadingScreen.transition_to("res://scenes/ui/main_menu.tscn")
