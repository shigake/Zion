extends Control

## Loja de upgrades permanentes entre runs.

@onready var crystals_label: Label = $VBox/CrystalsLabel
@onready var upgrade_container: VBoxContainer = $VBox/ScrollContainer/Upgrades
@onready var back_btn: Button = $VBox/BackButton

func _ready() -> void:
	back_btn.pressed.connect(_on_back)
	_build_shop()
	GamepadUI.notify_menu_opened()

func _build_shop() -> void:
	_clear_upgrades()
	_update_crystals()

	for uid in ShopDB.get_all_upgrade_ids():
		var data = ShopDB.get_upgrade(uid)
		var current = SaveManager.get_upgrade_level(uid)
		var cost = ShopDB.get_cost(uid)
		var maxed = current >= data["max_level"]

		var hbox = HBoxContainer.new()

		var label = Label.new()
		label.custom_minimum_size = Vector2(300, 0)
		if maxed:
			label.text = "%s — Lv.%d (MAX)" % [data["name"], current]
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

		upgrade_container.add_child(hbox)

func _buy(uid: String) -> void:
	SaveManager.buy_upgrade(uid)
	_build_shop()

func _update_crystals() -> void:
	crystals_label.text = LocaleManager.tr_key("crystals") % SaveManager.get_crystals()

func _clear_upgrades() -> void:
	for child in upgrade_container.get_children():
		child.queue_free()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_back()
		get_viewport().set_input_as_handled()

func _on_back() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
