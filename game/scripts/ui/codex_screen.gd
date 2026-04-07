extends Control

## Codex de armas — catalogo de todas as armas com stats e info de evolucao.
## Ao clicar numa arma, exibe detalhes e visual no painel direito.

const COLUMNS := 5
const CARD_SIZE := Vector2(145, 100)

var grid: GridContainer
var back_btn: Button
var scroll: ScrollContainer
var detail_panel: PanelContainer
var detail_portrait: Control
var detail_name: Label
var detail_type_lbl: Label
var detail_dmg: Label
var detail_desc: Label
var detail_evo: Label
var detail_viewport: SubViewport
var detail_model_root: Node3D
var current_model: Node3D = null

func _ready() -> void:
	get_tree().paused = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	_populate_grid()
	GamepadUI.notify_menu_opened()

func _build_ui() -> void:
	# Background
	var bg = ColorRect.new()
	bg.color = Color(0.08, 0.08, 0.12, 1.0)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var main_vbox = VBoxContainer.new()
	main_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	main_vbox.offset_left = 24
	main_vbox.offset_right = -24
	main_vbox.offset_top = 16
	main_vbox.offset_bottom = -16
	main_vbox.add_theme_constant_override("separation", 10)
	add_child(main_vbox)

	# Title
	var title = Label.new()
	title.text = "Codex de armas"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(0.4, 0.7, 1.0))
	main_vbox.add_child(title)

	# Conteudo: grid a esquerda + detalhe a direita
	var content_hbox = HBoxContainer.new()
	content_hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_hbox.add_theme_constant_override("separation", 16)
	main_vbox.add_child(content_hbox)

	# --- Lado esquerdo: scroll com grid ---
	scroll = ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content_hbox.add_child(scroll)

	grid = GridContainer.new()
	grid.columns = COLUMNS
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	scroll.add_child(grid)

	# --- Lado direito: painel de detalhe ---
	detail_panel = PanelContainer.new()
	detail_panel.custom_minimum_size = Vector2(260, 0)
	detail_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var dp_style = StyleBoxFlat.new()
	dp_style.bg_color = Color(0.1, 0.1, 0.16)
	dp_style.set_corner_radius_all(8)
	dp_style.set_border_width_all(2)
	dp_style.border_color = Color(0.25, 0.35, 0.5)
	detail_panel.add_theme_stylebox_override("panel", dp_style)
	content_hbox.add_child(detail_panel)

	var dp_margin = MarginContainer.new()
	dp_margin.add_theme_constant_override("margin_left", 16)
	dp_margin.add_theme_constant_override("margin_right", 16)
	dp_margin.add_theme_constant_override("margin_top", 16)
	dp_margin.add_theme_constant_override("margin_bottom", 16)
	detail_panel.add_child(dp_margin)

	var dp_vbox = VBoxContainer.new()
	dp_vbox.add_theme_constant_override("separation", 10)
	dp_margin.add_child(dp_vbox)

	# Instrucao inicial
	var hint = Label.new()
	hint.text = "Selecione uma arma\npara ver detalhes."
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 14)
	hint.add_theme_color_override("font_color", Color(0.45, 0.55, 0.7))
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.name = "Hint"
	dp_vbox.add_child(hint)

	# Portrait (SubViewport para modelo 3D da arma)
	var svc = SubViewportContainer.new()
	svc.custom_minimum_size = Vector2(220, 150)
	svc.stretch = true
	svc.visible = false
	svc.name = "DetailPortrait"
	svc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dp_vbox.add_child(svc)
	detail_portrait = svc

	detail_viewport = SubViewport.new()
	detail_viewport.size = Vector2(220, 150)
	detail_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	svc.add_child(detail_viewport)

	detail_model_root = Node3D.new()
	detail_viewport.add_child(detail_model_root)

	# Camera para visualizar o modelo
	var cam = Camera3D.new()
	cam.position = Vector3(0, 0.5, 1.5)
	detail_viewport.add_child(cam)
	cam.look_at(Vector3(0, 0.3, 0), Vector3.UP)
	cam.current = true

	# Luz ambiente
	var ambient = WorldEnvironment.new()
	var env = Environment.new()
	ambient.environment = env
	detail_viewport.add_child(ambient)

	# Luz direcional
	var light = DirectionalLight3D.new()
	light.position = Vector3(2, 2, 2)
	light.light_energy = 1.5
	detail_viewport.add_child(light)
	light.look_at(Vector3(0, 0, 0), Vector3.UP)

	detail_name = Label.new()
	detail_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	detail_name.add_theme_font_size_override("font_size", 20)
	detail_name.add_theme_color_override("font_color", Color(1.0, 0.95, 0.8))
	detail_name.visible = false
	dp_vbox.add_child(detail_name)

	detail_type_lbl = Label.new()
	detail_type_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	detail_type_lbl.add_theme_font_size_override("font_size", 13)
	detail_type_lbl.visible = false
	dp_vbox.add_child(detail_type_lbl)

	detail_dmg = Label.new()
	detail_dmg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	detail_dmg.add_theme_font_size_override("font_size", 14)
	detail_dmg.add_theme_color_override("font_color", Color(0.9, 0.7, 0.3))
	detail_dmg.visible = false
	dp_vbox.add_child(detail_dmg)

	detail_desc = Label.new()
	detail_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	detail_desc.add_theme_font_size_override("font_size", 12)
	detail_desc.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	detail_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_desc.visible = false
	dp_vbox.add_child(detail_desc)

	detail_evo = Label.new()
	detail_evo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	detail_evo.add_theme_font_size_override("font_size", 12)
	detail_evo.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	detail_evo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_evo.visible = false
	dp_vbox.add_child(detail_evo)

	# Back button
	back_btn = Button.new()
	back_btn.text = "Voltar"
	back_btn.custom_minimum_size = Vector2(120, 40)
	back_btn.pressed.connect(_on_back)
	back_btn.focus_mode = Control.FOCUS_ALL
	main_vbox.add_child(back_btn)

func _populate_grid() -> void:
	var codex = SaveManager.get_codex()
	var all_weapons = WeaponDB.weapons
	var type_colors := {
		"melee": Color(0.9, 0.3, 0.3),
		"ranged": Color(0.3, 0.5, 1.0),
		"summon": Color(0.3, 0.9, 0.4),
	}
	var type_icons := {
		"melee": "⚔",
		"ranged": "🏹",
		"summon": "✨",
	}

	for weapon_id in all_weapons:
		var data = all_weapons[weapon_id]
		var is_unlocked = true  # Todas desbloqueadas no codex

		var weapon_type: String = data.get("type", "melee")
		var type_color: Color = type_colors.get(weapon_type, Color.WHITE)
		var type_icon: String = type_icons.get(weapon_type, "?")

		var border = type_color if is_unlocked else Color(0.2, 0.2, 0.2)
		var bg = UITheme.BG_PANEL if is_unlocked else Color(0.08, 0.08, 0.1)
		var card_btn = UICardBuilder.create_card(CARD_SIZE, border, bg)
		var vbox = UICardBuilder.create_card_vbox(card_btn)

		UICardBuilder.add_color_swatch(vbox, type_color if is_unlocked else Color(0.3, 0.3, 0.3), 6.0)

		# Pixel art sprite da arma
		var icon_path := "res://assets/sprites/weapons/%s.png" % weapon_id
		if ResourceLoader.exists(icon_path):
			var icon_tex = load(icon_path)
			if icon_tex:
				var icon_rect = TextureRect.new()
				icon_rect.texture = icon_tex
				icon_rect.custom_minimum_size = Vector2(40, 40)
				icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				icon_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
				icon_rect.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
				icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
				if not is_unlocked:
					icon_rect.modulate = Color(0.3, 0.3, 0.3)
				vbox.add_child(icon_rect)

		var name_text = (type_icon + " " + data.get("name", weapon_id)) if is_unlocked else "???"
		var name_color = Color(1.0, 0.95, 0.8) if is_unlocked else Color(0.4, 0.4, 0.4)
		var name_lbl = UICardBuilder.add_label(vbox, name_text, 14, name_color)
		name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		name_lbl.clip_text = true
		name_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS

		if is_unlocked:
			UICardBuilder.add_label(vbox, "%s | %s" % [weapon_type.capitalize(), data.get("element", "physical").capitalize()], 10, type_color)
			UICardBuilder.add_label(vbox, "Dano: %d" % data.get("base_damage", 0), 11, Color(0.7, 0.7, 0.7))
		else:
			var locked_lbl = UICardBuilder.add_label(vbox, "Use para desbloquear.", 10, Color(0.4, 0.4, 0.4))
			locked_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

		card_btn.focus_mode = Control.FOCUS_ALL
		card_btn.pressed.connect(_show_weapon_details.bind(weapon_id, data, is_unlocked, type_color, type_icon))
		grid.add_child(card_btn)

	# Bug 2 fix — setup focus_neighbors for grid navigation
	_setup_grid_focus(grid, COLUMNS)
	# Connect last row to back_btn
	var cards = grid.get_children()
	if not cards.is_empty():
		var last_row_start = (cards.size() - 1) / COLUMNS * COLUMNS
		for i in range(last_row_start, cards.size()):
			cards[i].focus_neighbor_bottom = back_btn.get_path()
		back_btn.focus_neighbor_top = cards[last_row_start].get_path()
		# First row wraps to back_btn
		for i in range(mini(COLUMNS, cards.size())):
			cards[i].focus_neighbor_top = back_btn.get_path()
		back_btn.focus_neighbor_bottom = cards[0].get_path()
		if GamepadUI.is_gamepad_mode:
			cards[0].call_deferred("grab_focus")

## Setup focus_neighbors for a GridContainer with N columns
func _setup_grid_focus(g: GridContainer, cols: int) -> void:
	var children = g.get_children()
	for i in range(children.size()):
		var card = children[i]
		var col = i % cols
		var row = i / cols
		if col > 0:
			card.focus_neighbor_left = children[i - 1].get_path()
		if col < cols - 1 and i + 1 < children.size():
			card.focus_neighbor_right = children[i + 1].get_path()
		if row > 0:
			card.focus_neighbor_top = children[i - cols].get_path()
		if i + cols < children.size():
			card.focus_neighbor_bottom = children[i + cols].get_path()
		# Auto-scroll when focused
		card.focus_entered.connect(_on_card_focused.bind(card))

func _on_card_focused(card: Control) -> void:
	if scroll:
		var card_pos = card.global_position.y - scroll.global_position.y + scroll.scroll_vertical
		var card_bottom = card_pos + card.size.y
		if card_pos < scroll.scroll_vertical:
			scroll.scroll_vertical = int(card_pos)
		elif card_bottom > scroll.scroll_vertical + scroll.size.y:
			scroll.scroll_vertical = int(card_bottom - scroll.size.y)

func _show_weapon_details(weapon_id: String, data: Dictionary, is_unlocked: bool, type_color: Color, _type_icon: String) -> void:
	AudioManager.play_sfx("menu_click")

	# Esconde hint se existir
	for child in detail_panel.get_children():
		if child.name == "MarginContainer":
			for mc in child.get_children():
				if mc.name == "VBoxContainer":
					var hint = mc.get_node_or_null("Hint")
					if hint:
						hint.visible = false

	detail_portrait.visible = true

	if is_unlocked:
		# Carrega modelo 3D da arma
		_load_weapon_model(weapon_id)

		var weapon_type: String = data.get("type", "melee")
		var element: String = data.get("element", "physical")

		detail_name.text = data.get("name", weapon_id)
		detail_name.add_theme_color_override("font_color", type_color.lightened(0.25))
		detail_type_lbl.text = "%s | %s" % [weapon_type.capitalize(), element.capitalize()]
		detail_type_lbl.add_theme_color_override("font_color", type_color)
		detail_dmg.text = "Dano base: %d  |  CD: %.2fs" % [data.get("base_damage", 0), data.get("base_cooldown", 1.0)]
		detail_desc.text = data.get("description", "")

		var evo_text = _get_evolution_info(weapon_id)
		detail_evo.text = evo_text
		detail_evo.visible = not evo_text.is_empty()
	else:
		# Remove modelo anterior
		if current_model:
			current_model.queue_free()
			current_model = null

		detail_name.text = "???"
		detail_name.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		detail_type_lbl.text = ""
		detail_dmg.text = ""
		detail_desc.text = "Use esta arma numa partida para desbloquear as informacoes."
		detail_evo.visible = false

	detail_name.visible = true
	detail_type_lbl.visible = is_unlocked
	detail_dmg.visible = is_unlocked
	detail_desc.visible = true

func _load_weapon_model(weapon_id: String) -> void:
	# Remove modelo anterior
	if current_model:
		current_model.queue_free()
		current_model = null

	# Tenta carregar modelo da arma
	var model_path = "res://scenes/weapons/%s.tscn" % weapon_id.to_lower()
	if not ResourceLoader.exists(model_path):
		return

	var scene = load(model_path)
	if scene:
		current_model = scene.instantiate()
		detail_model_root.add_child(current_model)

		# Rotaciona e escala a arma para visualização
		if current_model is Node3D:
			current_model.rotation.y = 0.3
			current_model.scale = Vector3.ONE * 1.5

func _get_evolution_info(weapon_id: String) -> String:
	for evo_id in EvolutionDB.evolutions:
		var evo = EvolutionDB.evolutions[evo_id]
		if evo["weapon_required"] == weapon_id:
			var item_data = ItemDB.get_item(evo["item_required"])
			var item_name = item_data.get("name", evo["item_required"]) if not item_data.is_empty() else evo["item_required"]
			return "Evolui com %s → %s" % [item_name, evo["name"]]
	return ""

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if get_viewport(): get_viewport().set_input_as_handled()
		_on_back()

func _on_back() -> void:
	AudioManager.play_sfx("menu_click")
	LoadingScreen.transition_to("res://scenes/ui/main_menu.tscn")
