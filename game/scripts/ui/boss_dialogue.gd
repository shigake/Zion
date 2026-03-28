extends CanvasLayer

## Boss dialogue overlay — shows intro line when boss spawns, death line when boss dies.
## Auto-dismisses after 3 seconds or on any input.

const BOSS_LINES := {
	"BossNecromancer": {
		"intro": "Eu guardava a fronteira entre vida e morte.\nAgora SOU a fronteira!",
		"death": "Livre... finalmente livre.\nObrigado, Fragmentado...",
	},
	"BossFairyQueen": {
		"intro": "A floresta era minha para proteger.\nAgora é minha para devorar!",
		"death": "A harmonia... eu lembro agora.\nEu era... a guardiã...",
	},
	"BossAlienCow": {
		"intro": "MUUUU! O cristal me deu\nconsciência! E FOME!",
		"death": "Muu... o brilho... está sumindo...\n*static*",
	},
	"BossAiOverlord": {
		"intro": "SENTINELA DA LÓGICA ONLINE.\nVARIÁVEIS ORGÂNICAS: ELIMINAR.",
		"death": "ERRO... eu era protetor?\nDados corrompidos... restaurando...",
	},
	"BossDemonLord": {
		"intro": "Não fui corrompido. EU NASCI\nda destruição de Zion!",
		"death": "A raiva se dissolve...\nO que resta... é vazio...",
	},
	"BossLeviathan": {
		"intro": "Eu existo desde antes de Zion ter nome.\nVocês são efêmeros!",
		"death": "As profundezas... se aquietam.\nO mais antigo... descansa...",
	},
	"BossEmperor": {
		"intro": "Ajoelhem-se! Nesta arena,\nEU SOU ETERNO!",
		"death": "O loop... se quebra.\nRoma... pode descansar...",
	},
	"BossSingularity": {
		"intro": "EU GUARDO AS FRONTEIRAS DO ESPAÇO-TEMPO.\nNADA PASSA.",
		"death": "O horizonte... colapsa.\nAs fronteiras... se abrem...",
	},
	"BossDracula": {
		"intro": "Eu não fui corrompido. Eu ESCOLHI.\nZion não deve ser restaurado!",
		"death": "Talvez... eu estivesse errado.\nTalvez vocês mereçam... um novo Zion...",
	},
	"BossSugarKing": {
		"intro": "Eu sou tudo que resta do Coração!\nE NÃO VOU SER CONSERTADO!",
		"death": "O último fragmento...\nO coração... bate de novo...",
	},
}

var _panel: PanelContainer
var _label: Label
var _dismiss_timer: Timer
var _visible: bool = false

func _ready() -> void:
	layer = 8
	process_mode = Node.PROCESS_MODE_ALWAYS

	# Build UI
	_panel = PanelContainer.new()
	_panel.name = "BossDialoguePanel"
	var stylebox = StyleBoxFlat.new()
	stylebox.bg_color = Color(0.0, 0.0, 0.0, 0.85)
	stylebox.corner_radius_top_left = 8
	stylebox.corner_radius_top_right = 8
	stylebox.corner_radius_bottom_left = 8
	stylebox.corner_radius_bottom_right = 8
	stylebox.content_margin_left = 24.0
	stylebox.content_margin_right = 24.0
	stylebox.content_margin_top = 16.0
	stylebox.content_margin_bottom = 16.0
	stylebox.border_width_top = 2
	stylebox.border_width_bottom = 2
	stylebox.border_width_left = 2
	stylebox.border_width_right = 2
	stylebox.border_color = Color(0.8, 0.2, 0.2, 0.7)
	_panel.add_theme_stylebox_override("panel", stylebox)

	_label = Label.new()
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", 22)
	_label.add_theme_color_override("font_color", Color.WHITE)
	_panel.add_child(_label)

	# Center at bottom of screen
	_panel.anchors_preset = Control.PRESET_CENTER_BOTTOM
	_panel.anchor_left = 0.5
	_panel.anchor_right = 0.5
	_panel.anchor_top = 1.0
	_panel.anchor_bottom = 1.0
	_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_panel.offset_bottom = -40.0
	_panel.offset_top = -120.0

	_panel.visible = false
	add_child(_panel)

	# Auto-dismiss timer
	_dismiss_timer = Timer.new()
	_dismiss_timer.one_shot = true
	_dismiss_timer.wait_time = 3.0
	_dismiss_timer.timeout.connect(_dismiss)
	add_child(_dismiss_timer)

	# Connect signals
	GameManager.boss_spawned.connect(_on_boss_spawned)
	GameManager.boss_died.connect(_on_boss_died)

func _on_boss_spawned(boss_name: String) -> void:
	var key = _normalize_boss_name(boss_name)
	if BOSS_LINES.has(key):
		_show_dialogue(BOSS_LINES[key]["intro"])

func _on_boss_died(boss_name: String) -> void:
	var key = _normalize_boss_name(boss_name)
	if BOSS_LINES.has(key):
		_show_dialogue(BOSS_LINES[key]["death"])

func _normalize_boss_name(boss_name: String) -> String:
	## Boss node names may have @-suffix or spaces. Convert to dict key format.
	## e.g. "BossNecromancer", "BossNecromancer@2", "Boss Necromancer" -> "BossNecromancer"
	var clean = boss_name.split("@")[0].strip_edges()
	clean = clean.replace(" ", "")
	return clean

func _show_dialogue(text: String) -> void:
	_label.text = text
	_panel.visible = true
	_visible = true
	_dismiss_timer.start()
	# Fade-in via modulate
	_panel.modulate = Color(1, 1, 1, 0)
	var tween = create_tween()
	tween.tween_property(_panel, "modulate", Color(1, 1, 1, 1), 0.3)

func _dismiss() -> void:
	if not _visible:
		return
	_visible = false
	_dismiss_timer.stop()
	var tween = create_tween()
	tween.tween_property(_panel, "modulate", Color(1, 1, 1, 0), 0.25)
	tween.tween_callback(func(): _panel.visible = false)

func _unhandled_input(event: InputEvent) -> void:
	if _visible and (event is InputEventKey or event is InputEventMouseButton or event is InputEventJoypadButton):
		if event.is_pressed():
			_dismiss()
			get_viewport().set_input_as_handled()
