extends CanvasLayer

## Tela de Level Up: 3 opcoes (arma ou item). Pausa o jogo.

signal choice_made()

@onready var panel: PanelContainer = $Panel
@onready var option1_btn: Button = $Panel/VBox/Options/Option1
@onready var option2_btn: Button = $Panel/VBox/Options/Option2
@onready var option3_btn: Button = $Panel/VBox/Options/Option3
@onready var title_label: Label = $Panel/VBox/TitleLabel
@onready var reroll_btn: Button = $Panel/VBox/RerollButton
@onready var banish_btn: Button = $Panel/VBox/BanishButton

var options: Array = []
var pending_levels: int = 0
var banish_mode: bool = false

func _ready() -> void:
	panel.visible = false
	GameManager.player_leveled_up.connect(_on_level_up)
	option1_btn.pressed.connect(func(): _choose(0))
	option2_btn.pressed.connect(func(): _choose(1))
	reroll_btn.pressed.connect(_on_reroll)
	banish_btn.pressed.connect(_on_banish)
	option3_btn.pressed.connect(func(): _choose(2))

func _on_level_up(_new_level: int) -> void:
	pending_levels += 1
	if not panel.visible:
		_show_choices()

func _show_choices() -> void:
	options = _generate_options()
	if options.is_empty():
		pending_levels = 0
		return

	title_label.text = "LEVEL UP! (Lv. %d)" % GameManager.player_level

	var buttons = [option1_btn, option2_btn, option3_btn]
	for i in range(3):
		if i < options.size():
			buttons[i].visible = true
			buttons[i].text = options[i]["label"]
		else:
			buttons[i].visible = false

	# Reroll button
	if GameManager.rerolls > 0:
		reroll_btn.visible = true
		reroll_btn.text = "Reroll (%d)" % GameManager.rerolls
	else:
		reroll_btn.visible = false

	# Banish button
	if GameManager.banishes > 0:
		banish_btn.visible = true
		banish_btn.text = "Banish (%d)" % GameManager.banishes
	else:
		banish_btn.visible = false

	banish_mode = false
	panel.visible = true
	GameManager.paused = true
	get_tree().paused = true

func _choose(index: int) -> void:
	if index >= options.size():
		return

	if banish_mode:
		_banish_option(index)
		return

	var opt = options[index]
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

	panel.visible = false
	pending_levels -= 1

	if pending_levels > 0:
		# Mostra proxima escolha
		call_deferred("_show_choices")
	else:
		GameManager.paused = false
		get_tree().paused = false
	choice_made.emit()

func _generate_options() -> Array:
	var pool: Array = []

	# Armas que o jogador ja tem (upgrade)
	for w in GameManager.player_weapons:
		if w["level"] < 8:
			var data = WeaponDB.get_weapon(w["id"])
			pool.append({
				"type": "weapon",
				"id": w["id"],
				"label": "%s (Lv.%d → %d)" % [data["name"], w["level"], w["level"] + 1],
				"weight": 10,
			})

	# Armas novas (se tem slot)
	if GameManager.player_weapons.size() < GameManager.MAX_WEAPONS:
		for wid in WeaponDB.get_all_weapon_ids():
			if not GameManager.has_weapon(wid):
				var data = WeaponDB.get_weapon(wid)
				pool.append({
					"type": "weapon",
					"id": wid,
					"label": "%s (NOVO!)" % data["name"],
					"weight": 8,
				})

	# Itens que o jogador ja tem (upgrade)
	for it in GameManager.player_items:
		if it["level"] < 5:
			var data = ItemDB.get_item(it["id"])
			pool.append({
				"type": "item",
				"id": it["id"],
				"label": "%s (Lv.%d → %d)" % [data["name"], it["level"], it["level"] + 1],
				"weight": 10,
			})

	# Itens novos (se tem slot)
	if GameManager.player_items.size() < GameManager.MAX_ITEMS:
		for iid in ItemDB.get_all_item_ids():
			if not GameManager.has_item(iid):
				var data = ItemDB.get_item(iid)
				pool.append({
					"type": "item",
					"id": iid,
					"label": "%s (NOVO!)" % data["name"],
					"weight": 8,
				})

	# Filter banished options
	pool = pool.filter(func(opt): return opt["id"] not in GameManager.banished_options)

	# Shuffle e pega 3
	pool.shuffle()
	return pool.slice(0, 3)

func _on_reroll() -> void:
	if GameManager.rerolls <= 0:
		return
	GameManager.rerolls -= 1
	_show_choices()

func _on_banish() -> void:
	if GameManager.banishes <= 0:
		return
	banish_mode = true
	title_label.text = "BANISH: Escolha uma opcao para remover"
	banish_btn.visible = false

func _banish_option(index: int) -> void:
	var opt = options[index]
	GameManager.banished_options.append(opt["id"])
	GameManager.banishes -= 1
	banish_mode = false
	_show_choices()
