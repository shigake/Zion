extends Control

## Tela de selecao de personagem com pixel art sprites.
## Sprite grande no centro-esquerda, strip de personagens na direita, info overlay.

var all_character_ids: Array[String] = []
var current_index: int = 0
var _bob_tween: Tween = null

# UI refs
var _sprite_container: CenterContainer
var _sprite_display: TextureRect
var _bg_gradient: ColorRect
var _char_strip: VBoxContainer
var _char_buttons: Array[Button] = []
var _name_label: Label
var _passive_label: Label
var _weapon_label: Label
var _weapon_icon: TextureRect
var _element_badge: Label
var _lock_label: Label
var _start_btn: Button
var _back_btn: Button

func _ready() -> void:
	get_tree().paused = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_character_list()
	_find_first_unlocked()
	_build_ui()
	_update_selection()
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

func _build_ui() -> void:
	# Background gradient (changes with character color)
	_bg_gradient = ColorRect.new()
	_bg_gradient.set_anchors_preset(Control.PRESET_FULL_RECT)
	_bg_gradient.color = Color(0.03, 0.03, 0.06)
	add_child(_bg_gradient)

	# Dark overlay for contrast
	var overlay = ColorRect.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0, 0, 0, 0.3)
	add_child(overlay)

	# Sprite preview area (center-left, takes 65% of screen)
	_sprite_container = CenterContainer.new()
	_sprite_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	_sprite_container.anchor_right = 0.65
	_sprite_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_sprite_container)

	_sprite_display = TextureRect.new()
	_sprite_display.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_sprite_display.custom_minimum_size = Vector2(160, 160)
	_sprite_display.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_sprite_display.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_sprite_container.add_child(_sprite_display)

	# --- Right side panel (character info + strip) ---
	var right_panel = PanelContainer.new()
	right_panel.anchor_left = 0.65
	right_panel.anchor_right = 1.0
	right_panel.anchor_top = 0.0
	right_panel.anchor_bottom = 1.0
	right_panel.offset_left = 0
	right_panel.offset_right = 0
	var rp_style = StyleBoxFlat.new()
	rp_style.bg_color = Color(0.03, 0.03, 0.05, 0.92)
	rp_style.border_width_left = 1
	rp_style.border_color = Color(0.15, 0.15, 0.25, 0.5)
	rp_style.content_margin_left = 20
	rp_style.content_margin_right = 16
	rp_style.content_margin_top = 20
	rp_style.content_margin_bottom = 16
	right_panel.add_theme_stylebox_override("panel", rp_style)
	add_child(right_panel)

	var right_vbox = VBoxContainer.new()
	right_vbox.add_theme_constant_override("separation", 8)
	right_panel.add_child(right_vbox)

	# Character name (large)
	_name_label = Label.new()
	_name_label.add_theme_font_size_override("font_size", 28)
	_name_label.add_theme_color_override("font_color", Color.WHITE)
	right_vbox.add_child(_name_label)

	# Element badge
	_element_badge = Label.new()
	_element_badge.add_theme_font_size_override("font_size", 12)
	_element_badge.add_theme_color_override("font_color", Color(0.6, 0.65, 0.8))
	right_vbox.add_child(_element_badge)

	# Separator
	var sep1 = HSeparator.new()
	sep1.add_theme_constant_override("separation", 8)
	right_vbox.add_child(sep1)

	# Passive ability
	var passive_title = Label.new()
	passive_title.text = "Habilidade passiva"
	passive_title.add_theme_font_size_override("font_size", 10)
	passive_title.add_theme_color_override("font_color", Color(0.45, 0.45, 0.55))
	right_vbox.add_child(passive_title)

	_passive_label = Label.new()
	_passive_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_passive_label.add_theme_font_size_override("font_size", 13)
	_passive_label.add_theme_color_override("font_color", Color(0.7, 0.9, 0.6))
	right_vbox.add_child(_passive_label)

	# Weapon row
	var weapon_title = Label.new()
	weapon_title.text = "Arma inicial"
	weapon_title.add_theme_font_size_override("font_size", 10)
	weapon_title.add_theme_color_override("font_color", Color(0.45, 0.45, 0.55))
	right_vbox.add_child(weapon_title)

	var weapon_row = HBoxContainer.new()
	weapon_row.add_theme_constant_override("separation", 8)
	right_vbox.add_child(weapon_row)

	_weapon_icon = TextureRect.new()
	_weapon_icon.custom_minimum_size = Vector2(28, 28)
	_weapon_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	weapon_row.add_child(_weapon_icon)

	_weapon_label = Label.new()
	_weapon_label.add_theme_font_size_override("font_size", 14)
	_weapon_label.add_theme_color_override("font_color", Color(0.9, 0.85, 0.6))
	weapon_row.add_child(_weapon_label)

	# Lock label
	_lock_label = Label.new()
	_lock_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_lock_label.add_theme_font_size_override("font_size", 12)
	_lock_label.add_theme_color_override("font_color", Color(1.0, 0.5, 0.5))
	_lock_label.visible = false
	right_vbox.add_child(_lock_label)

	# Spacer
	var spacer = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_vbox.add_child(spacer)

	# Character strip (scrollable grid of small icons)
	var strip_label = Label.new()
	strip_label.text = "Personagens"
	strip_label.add_theme_font_size_override("font_size", 10)
	strip_label.add_theme_color_override("font_color", Color(0.45, 0.45, 0.55))
	right_vbox.add_child(strip_label)

	var strip_scroll = ScrollContainer.new()
	strip_scroll.custom_minimum_size = Vector2(0, 180)
	strip_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	strip_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	right_vbox.add_child(strip_scroll)

	# Grid (3 columns)
	var grid = GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	strip_scroll.add_child(grid)

	_build_character_strip(grid)

	# Bottom buttons
	var btn_row = HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 12)
	btn_row.alignment = BoxContainer.ALIGNMENT_END
	right_vbox.add_child(btn_row)

	_back_btn = _make_btn("Voltar", Color(0.12, 0.1, 0.1))
	_back_btn.pressed.connect(_on_back)
	btn_row.add_child(_back_btn)

	var random_btn = _make_btn("Aleatorio", Color(0.4, 0.2, 0.1))
	random_btn.pressed.connect(_on_random_start)
	btn_row.add_child(random_btn)

	_start_btn = _make_btn("Jogar", Color(0.15, 0.25, 0.4))
	_start_btn.pressed.connect(_on_start)
	btn_row.add_child(_start_btn)

func _build_character_strip(grid: GridContainer) -> void:
	_char_buttons.clear()
	for i in range(all_character_ids.size()):
		var char_id = all_character_ids[i]
		var data = CharacterDB.get_character(char_id)
		var is_locked = not SaveManager.is_character_unlocked(char_id)
		var char_color = data.get("color", Color(0.5, 0.5, 0.5))

		var btn = Button.new()
		btn.custom_minimum_size = Vector2(68, 68)

		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.06, 0.06, 0.1, 0.9)
		style.set_corner_radius_all(8)
		style.set_border_width_all(2)
		style.border_color = Color(0.12, 0.12, 0.18) if is_locked else char_color.darkened(0.4)
		btn.add_theme_stylebox_override("normal", style)

		var hover = style.duplicate()
		hover.bg_color = Color(0.1, 0.1, 0.16)
		hover.border_color = char_color if not is_locked else Color(0.2, 0.2, 0.28)
		btn.add_theme_stylebox_override("hover", hover)
		btn.add_theme_stylebox_override("focus", hover.duplicate())
		btn.add_theme_stylebox_override("pressed", style.duplicate())

		# Sprite thumbnail (pixel art at 2x scale)
		var sprite_path = "res://assets/sprites/characters/%s.png" % char_id
		if ResourceLoader.exists(sprite_path):
			var tex = TextureRect.new()
			tex.texture = load(sprite_path)
			tex.custom_minimum_size = Vector2(64, 64)
			tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			tex.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			tex.set_anchors_preset(Control.PRESET_CENTER)
			tex.offset_left = -32
			tex.offset_top = -32
			tex.offset_right = 32
			tex.offset_bottom = 32
			tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
			if is_locked:
				tex.modulate = Color(0.25, 0.25, 0.25)
			btn.add_child(tex)

		if is_locked:
			var lock = Label.new()
			lock.text = "🔒"
			lock.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
			lock.offset_left = -16
			lock.offset_top = -16
			lock.add_theme_font_size_override("font_size", 10)
			lock.mouse_filter = Control.MOUSE_FILTER_IGNORE
			btn.add_child(lock)

		var idx = i
		btn.pressed.connect(func(): _select_character(idx))
		grid.add_child(btn)
		_char_buttons.append(btn)

func _load_sprite(char_id: String) -> void:
	var sprite_path = "res://assets/sprites/characters/%s.png" % char_id
	if ResourceLoader.exists(sprite_path):
		_sprite_display.texture = load(sprite_path)
	else:
		_sprite_display.texture = null

	# Start bob animation
	_start_bob_animation()

func _update_selection() -> void:
	var char_id = all_character_ids[current_index]
	var data = CharacterDB.get_character(char_id)
	var is_locked = not SaveManager.is_character_unlocked(char_id)
	var char_color = data.get("color", Color(0.5, 0.5, 0.5))

	# Load pixel art sprite
	_load_sprite(char_id)

	# Update background tint
	_bg_gradient.color = Color(
		char_color.r * 0.08,
		char_color.g * 0.08,
		char_color.b * 0.08
	)

	# Update info
	_name_label.text = data.get("name", char_id).to_upper()
	_name_label.add_theme_color_override("font_color", char_color.lightened(0.3))
	_passive_label.text = data.get("passive", "")

	# Weapon
	var weapon_id = data.get("starting_weapon", "katana")
	var weapon_data = WeaponDB.get_weapon(weapon_id)
	_weapon_label.text = weapon_data.get("name", "???")
	var weapon_icon_path = "res://assets/icons/weapons/%s.svg" % weapon_id
	if ResourceLoader.exists(weapon_icon_path):
		_weapon_icon.texture = load(weapon_icon_path)

	# Element
	var element = weapon_data.get("element", "physical")
	var element_names = {"physical": "Fisico", "fire": "Fogo", "ice": "Gelo", "electric": "Eletrico", "dark": "Dark", "poison": "Veneno"}
	_element_badge.text = "Elemento: %s" % element_names.get(element, element)

	# Lock
	if is_locked:
		_lock_label.text = "🔒 %s" % data.get("unlock_description", "???")
		_lock_label.visible = true
		_start_btn.disabled = true
		_start_btn.text = "Bloqueado"
	else:
		_lock_label.visible = false
		_start_btn.disabled = false
		_start_btn.text = "Jogar"

	# Highlight selected in strip
	for i in range(_char_buttons.size()):
		var btn = _char_buttons[i]
		var s = btn.get_theme_stylebox("normal") as StyleBoxFlat
		if s:
			if i == current_index:
				s.border_color = char_color
				s.bg_color = Color(char_color.r * 0.15, char_color.g * 0.15, char_color.b * 0.15, 0.95)
			else:
				var cid = all_character_ids[i]
				var cdata = CharacterDB.get_character(cid)
				var clocked = not SaveManager.is_character_unlocked(cid)
				var cc = cdata.get("color", Color(0.5, 0.5, 0.5))
				s.border_color = Color(0.12, 0.12, 0.18) if clocked else cc.darkened(0.4)
				s.bg_color = Color(0.06, 0.06, 0.1, 0.9)

func _start_bob_animation() -> void:
	if _bob_tween:
		_bob_tween.kill()
	# Reset position
	_sprite_display.position = Vector2.ZERO
	_bob_tween = create_tween().set_loops()
	_bob_tween.tween_property(_sprite_display, "position:y", -6.0, 0.8) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_bob_tween.tween_property(_sprite_display, "position:y", 0.0, 0.8) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _select_character(idx: int) -> void:
	current_index = idx
	_update_selection()

func _make_btn(text: String, base_color: Color) -> Button:
	var btn = Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(100, 38)
	var s = StyleBoxFlat.new()
	s.bg_color = base_color
	s.set_corner_radius_all(6)
	s.set_border_width_all(1)
	s.border_color = base_color.lightened(0.25)
	s.content_margin_left = 14
	s.content_margin_right = 14
	s.content_margin_top = 8
	s.content_margin_bottom = 8
	btn.add_theme_stylebox_override("normal", s)
	var h = s.duplicate()
	h.bg_color = base_color.lightened(0.15)
	h.border_color = base_color.lightened(0.4)
	btn.add_theme_stylebox_override("hover", h)
	btn.add_theme_stylebox_override("focus", h.duplicate())
	btn.add_theme_stylebox_override("pressed", s.duplicate())
	btn.add_theme_font_size_override("font_size", 14)
	btn.add_theme_color_override("font_color", Color(0.85, 0.85, 0.92))
	btn.add_theme_color_override("font_hover_color", Color.WHITE)
	return btn

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_left") or event.is_action_pressed("move_left"):
		current_index = (current_index - 1) % all_character_ids.size()
		_update_selection()
		if get_viewport(): get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_right") or event.is_action_pressed("move_right"):
		current_index = (current_index + 1) % all_character_ids.size()
		_update_selection()
		if get_viewport(): get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_accept"):
		_on_start()
		if get_viewport(): get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel"):
		_on_back()
		if get_viewport(): get_viewport().set_input_as_handled()

func _on_start() -> void:
	var char_id = all_character_ids[current_index]
	if SaveManager.is_character_unlocked(char_id):
		AudioManager.play_sfx("menu_click")
		GameManager.selected_character = char_id
		GameManager.auto_play = false
		get_tree().change_scene_to_file("res://scenes/ui/mutations_panel.tscn")

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
	var stages = ["cemetery", "forest", "farm", "tokyo", "volcano", "ocean", "arena", "space", "castle", "candy"]
	GameManager.selected_stage = stages[randi() % stages.size()]

	# No mutations, no relic, normal mode, auto-play ON
	MutationManager.reset()
	GameManager.selected_relic = ""
	GameManager.game_mode = "normal"
	GameManager.run_time_limit = 1800.0
	GameManager.auto_play = true

	# Go straight to game
	var stage_scenes = {
		"cemetery": "res://scenes/stages/stage_cemetery.tscn",
		"forest": "res://scenes/stages/stage_forest.tscn",
		"farm": "res://scenes/stages/stage_farm.tscn",
		"tokyo": "res://scenes/stages/stage_tokyo.tscn",
		"volcano": "res://scenes/stages/stage_volcano.tscn",
		"ocean": "res://scenes/stages/stage_ocean.tscn",
		"arena": "res://scenes/stages/stage_arena.tscn",
		"space": "res://scenes/stages/stage_space.tscn",
		"castle": "res://scenes/stages/stage_castle.tscn",
		"candy": "res://scenes/stages/stage_candy.tscn",
	}
	var scene_path = stage_scenes.get(GameManager.selected_stage, "res://scenes/stages/stage_cemetery.tscn")
	LoadingScreen.load_stage(scene_path)

func _on_back() -> void:
	AudioManager.play_sfx("menu_click")
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
