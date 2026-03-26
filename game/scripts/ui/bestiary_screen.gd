extends Control

## Bestiario — catalogo de inimigos encontrados pelo jogador.

const COLUMNS := 4
const CARD_SIZE := Vector2(180, 120)

# All known enemies with descriptions
var enemy_data: Dictionary = {
	# Generic enemies
	"Slime": {"desc": "Basico e lento. Nao subestime em grupo.", "color": Color(0.2, 0.8, 0.2)},
	"Bat": {"desc": "Rapido e irritante. Mira ruim.", "color": Color(0.5, 0.3, 0.6)},
	"Skeleton": {"desc": "Guerreiro de ossos. Resiste a morte.", "color": Color(0.9, 0.9, 0.8)},
	"ZombieRunner": {"desc": "Corre mais rapido que parece. Cuidado.", "color": Color(0.4, 0.6, 0.3)},
	"Ghost": {"desc": "Fantasma transparente. Atravessa tudo.", "color": Color(0.6, 0.7, 0.9)},
	"SlimeBig": {"desc": "Versao gigante do slime. Tanque lento.", "color": Color(0.1, 0.6, 0.1)},
	"SkeletonArcher": {"desc": "Atira flechas de longe. Priorize.", "color": Color(0.8, 0.7, 0.6)},
	"Bomber": {"desc": "Explode perto de voce. Mantenha distancia.", "color": Color(0.9, 0.4, 0.1)},
	"Tank": {"desc": "Lento mas quase indestrutivel.", "color": Color(0.5, 0.5, 0.5)},
	"Swarm": {"desc": "Enxame de criaturas. Muitos, mas frageis.", "color": Color(0.7, 0.7, 0.2)},
	"Mimic": {"desc": "Parece um bau. Nao e um bau.", "color": Color(0.8, 0.6, 0.2)},
	# Bosses
	"BossNecromancer": {"desc": "Invoca mortos e drena vida. Boss do cemiterio.", "color": Color(0.3, 0.0, 0.5)},
	"BossFairyQueen": {"desc": "Rainha das fadas. Magias de natureza.", "color": Color(0.2, 0.8, 0.4)},
	"BossAlienCow": {"desc": "Vaca alienigena. Sim, e serio.", "color": Color(0.6, 0.9, 0.6)},
	"BossAIOverlord": {"desc": "Inteligencia artificial malvada. Lasers.", "color": Color(0.0, 0.8, 1.0)},
	"BossDemonLord": {"desc": "Senhor dos demonios. Fogo infernal.", "color": Color(0.9, 0.1, 0.0)},
	"BossLeviathan": {"desc": "Monstro marinho ancestral. Tentaculos.", "color": Color(0.1, 0.3, 0.7)},
	"BossEmperor": {"desc": "Imperador da arena. Combate honrado.", "color": Color(0.8, 0.6, 0.1)},
	"BossSingularity": {"desc": "Buraco negro vivo. Gravidade extrema.", "color": Color(0.4, 0.0, 0.6)},
	"BossDracula": {"desc": "Vampiro milenar. Drena vida sem parar.", "color": Color(0.5, 0.0, 0.1)},
	"BossSugarKing": {"desc": "Rei dos doces. Doce por fora, mortal por dentro.", "color": Color(1.0, 0.5, 0.7)},
}

var grid: GridContainer
var info_label: Label
var back_btn: Button
var scroll: ScrollContainer

func _ready() -> void:
	_build_ui()
	_populate_grid()
	GamepadUI.notify_menu_opened()

func _build_ui() -> void:
	# Background
	var bg = ColorRect.new()
	bg.color = Color(0.08, 0.08, 0.12, 1.0)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 30
	vbox.offset_right = -30
	vbox.offset_top = 20
	vbox.offset_bottom = -20
	vbox.add_theme_constant_override("separation", 10)
	add_child(vbox)

	# Title
	var title = Label.new()
	title.text = "Bestiario"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	vbox.add_child(title)

	# Info label
	info_label = Label.new()
	info_label.text = "Selecione um inimigo para ver detalhes."
	info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_label.add_theme_font_size_override("font_size", 16)
	info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(info_label)

	# Scroll + Grid
	scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)

	grid = GridContainer.new()
	grid.columns = COLUMNS
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	scroll.add_child(grid)

	# Back button
	back_btn = Button.new()
	back_btn.text = "Voltar"
	back_btn.custom_minimum_size = Vector2(120, 40)
	back_btn.pressed.connect(_on_back)
	back_btn.focus_mode = Control.FOCUS_ALL
	vbox.add_child(back_btn)

func _populate_grid() -> void:
	var bestiary = SaveManager.get_bestiary()

	for enemy_name in enemy_data:
		var data = enemy_data[enemy_name]
		var is_seen = _is_enemy_seen(enemy_name, bestiary)
		var kills = _get_enemy_kills(enemy_name, bestiary)

		var card = PanelContainer.new()
		card.custom_minimum_size = CARD_SIZE

		var card_style = StyleBoxFlat.new()
		card_style.bg_color = Color(0.12, 0.12, 0.18) if is_seen else Color(0.08, 0.08, 0.1)
		card_style.set_corner_radius_all(6)
		card_style.set_border_width_all(2)
		card_style.border_color = data["color"] if is_seen else Color(0.2, 0.2, 0.2)
		card.add_theme_stylebox_override("panel", card_style)

		var vbox = VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 4)
		card.add_child(vbox)

		# Color swatch
		var swatch = ColorRect.new()
		swatch.custom_minimum_size = Vector2(0, 8)
		swatch.color = data["color"] if is_seen else Color(0.3, 0.3, 0.3)
		vbox.add_child(swatch)

		# Name
		var name_lbl = Label.new()
		name_lbl.text = enemy_name if is_seen else "???"
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_lbl.add_theme_font_size_override("font_size", 16)
		name_lbl.add_theme_color_override("font_color", Color(1.0, 0.95, 0.8) if is_seen else Color(0.4, 0.4, 0.4))
		vbox.add_child(name_lbl)

		# Kills count
		var kills_lbl = Label.new()
		kills_lbl.text = "Kills: %d" % kills if is_seen else ""
		kills_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		kills_lbl.add_theme_font_size_override("font_size", 12)
		kills_lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		vbox.add_child(kills_lbl)

		# Description (short)
		var desc_lbl = Label.new()
		desc_lbl.text = data["desc"] if is_seen else "Encontre este inimigo para desbloquear."
		desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		desc_lbl.add_theme_font_size_override("font_size", 11)
		desc_lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		vbox.add_child(desc_lbl)

		grid.add_child(card)

func _is_enemy_seen(enemy_name: String, bestiary: Dictionary) -> bool:
	# Check direct name or any themed variant
	if enemy_name in bestiary:
		return true
	# Some enemies have themed names, check base types
	return false

func _get_enemy_kills(enemy_name: String, bestiary: Dictionary) -> int:
	if enemy_name in bestiary:
		return bestiary[enemy_name].get("kills", 0)
	return 0

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_back()
		get_viewport().set_input_as_handled()

func _on_back() -> void:
	AudioManager.play_sfx("menu_click")
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
