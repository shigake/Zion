extends Control

## Loja de upgrades permanentes entre runs.

@onready var crystals_label: Label = $VBox/CrystalsLabel
@onready var upgrade_container: VBoxContainer = $VBox/ScrollContainer/Upgrades
@onready var back_btn: Button = $VBox/BackButton

func _ready() -> void:
	get_tree().paused = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_texture_background()
	back_btn.pressed.connect(_on_back)
	_build_shop()
	GamepadUI.notify_menu_opened()
	AudioManager.play_music("shop")


func _setup_texture_background() -> void:
	var bg_tex_path := "res://assets/sprites/ui/shop_bg.png"
	if ResourceLoader.exists(bg_tex_path):
		var bg := TextureRect.new()
		bg.name = "ShopBgTexture"
		bg.texture = load(bg_tex_path)
		bg.set_anchors_preset(Control.PRESET_FULL_RECT)
		bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		bg.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(bg)
		move_child(bg, 0)

func _build_shop() -> void:
	_clear_upgrades()
	_update_crystals()

	for uid in ShopDB.get_all_upgrade_ids():
		var data = ShopDB.get_upgrade(uid)
		var current = SaveManager.get_upgrade_level(uid)
		var cost = ShopDB.get_cost(uid)
		var maxed = current >= data["max_level"]

		var panel := PanelContainer.new()
		var panel_tex_path := "res://assets/sprites/ui/panel_bg.png"
		if ResourceLoader.exists(panel_tex_path):
			var sb_panel := StyleBoxTexture.new()
			sb_panel.texture = load(panel_tex_path)
			sb_panel.texture_margin_left = 6
			sb_panel.texture_margin_right = 6
			sb_panel.texture_margin_top = 6
			sb_panel.texture_margin_bottom = 6
			sb_panel.content_margin_left = 8
			sb_panel.content_margin_right = 8
			sb_panel.content_margin_top = 4
			sb_panel.content_margin_bottom = 4
			panel.add_theme_stylebox_override("panel", sb_panel)

		var hbox = HBoxContainer.new()
		panel.add_child(hbox)

		var icon_path = "res://assets/sprites/upgrades/%s.png" % uid
		var icon_tex = load(icon_path) if ResourceLoader.exists(icon_path) else null
		if icon_tex:
			var icon = TextureRect.new()
			icon.texture = icon_tex
			icon.custom_minimum_size = Vector2(32, 32)
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			hbox.add_child(icon)
			hbox.add_theme_constant_override("separation", 4)

		var label = Label.new()
		label.custom_minimum_size = Vector2(300, 0)
		if maxed:
			label.text = "%s — Lv.%d (%s)" % [data["name"], current, LocaleManager.tr_key("max_level")]
		else:
			label.text = "%s — Lv.%d/%d — %s" % [data["name"], current, data["max_level"], data["description"]]
		hbox.add_child(label)

		var btn = Button.new()
		btn.custom_minimum_size = Vector2(120, 35)
		if maxed:
			btn.text = LocaleManager.tr_key("max_level")
			btn.disabled = true
		else:
			btn.text = LocaleManager.tr_key("buy") % cost
			btn.disabled = SaveManager.get_crystals() < cost
			var captured_uid = uid
			btn.pressed.connect(func(): _buy(captured_uid))
		hbox.add_child(btn)

		upgrade_container.add_child(panel)

func _buy(uid: String) -> void:
	var success = SaveManager.buy_upgrade(uid)
	if not success:
		AudioManager.play_sfx("error")
	_build_shop()

func _update_crystals() -> void:
	crystals_label.text = LocaleManager.tr_key("crystals") % SaveManager.get_crystals()

func _clear_upgrades() -> void:
	for child in upgrade_container.get_children():
		child.queue_free()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if get_viewport(): get_viewport().set_input_as_handled()
		_on_back()

func _on_back() -> void:
	AudioManager.play_sfx("menu_click")
	LoadingScreen.transition_to("res://scenes/ui/main_menu.tscn")
