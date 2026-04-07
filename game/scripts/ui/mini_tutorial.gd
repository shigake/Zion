extends CanvasLayer

## Contextual mini-tutorial system — first-time hint balloons.
## Shows floating hints on the HUD when the player encounters a system for the first time.
## Each hint appears only once per save file. Queues extras if multiple trigger at once.
## Persistence: SaveManager.data["tutorial_hints_shown"] (Array of hint IDs).

# -- Constants --
const FADE_IN_DURATION := 0.3
const DISPLAY_DURATION := 3.5
const FADE_OUT_DURATION := 0.5
const QUEUE_GAP := 1.0
const PANEL_WIDTH := 500.0
const PANEL_HEIGHT := 52.0
const MARGIN_TOP := 60.0

# Colors (Zion crystalline theme)
const COLOR_BG := Color(0.1, 0.1, 0.15, 0.85)
const COLOR_BORDER := Color(0.4, 0.7, 1.0, 0.6)
const COLOR_TEXT := Color(0.95, 0.95, 0.97)

# -- Hint catalog --
# Each entry: { id, message, connected (bool, whether signal is already wired) }
var HINTS: Array[Dictionary] = [
	{
		"id": "first_chest",
		"message": "Siga a seta dourada para encontrar baus de recompensa!",
	},
	{
		"id": "first_level_up",
		"message": "Escolha armas e itens ao subir de nivel",
	},
	{
		"id": "first_dash",
		"message": "Pressione ESPACO para dar um dash e desviar de inimigos",
	},
	{
		"id": "first_evolution_ready",
		"message": "Sua arma pode evoluir! Continue lutando para ativar a ressonancia cristalina",
	},
	{
		"id": "first_synergy",
		"message": "Sinergia ativada! Armas do mesmo elemento criam efeitos bonus",
	},
	{
		"id": "first_boss",
		"message": "Sentinela detectado! Prepare-se para o guardiao desta fenda",
	},
	{
		"id": "first_quest",
		"message": "Quest recebida! Complete objetivos para ganhar cristais extras",
	},
	{
		"id": "first_merchant",
		"message": "Mercante dimensional apareceu! Siga a seta azul para negociar",
	},
	{
		"id": "first_relic",
		"message": "Reliquia equipada: seu poder ressonara durante toda a fissura",
	},
	{
		"id": "first_elite",
		"message": "Inimigo de elite! Mais forte, mas da muito mais XP",
	},
]

# -- State --
var _hint_queue: Array[String] = []
var _is_showing: bool = false
var _panel: PanelContainer = null
var _label: Label = null
var _dash_timer_started: bool = false
var _dash_elapsed: float = 0.0


func _ready() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	# Defer signal connections to next frame so all autoloads are ready
	call_deferred("_connect_signals")


func _connect_signals() -> void:
	# Signal-based hints
	if GameManager.player_leveled_up.is_connected(_on_player_leveled_up) == false:
		GameManager.player_leveled_up.connect(_on_player_leveled_up)
	if GameManager.boss_spawned.is_connected(_on_boss_spawned) == false:
		GameManager.boss_spawned.connect(_on_boss_spawned)
	if GameManager.miniboss_spawned.is_connected(_on_elite_spawned) == false:
		GameManager.miniboss_spawned.connect(_on_elite_spawned)
	if SynergySystem.synergy_activated.is_connected(_on_synergy_activated) == false:
		SynergySystem.synergy_activated.connect(_on_synergy_activated)
	if ChestManager.chest_spawned.is_connected(_on_chest_spawned) == false:
		ChestManager.chest_spawned.connect(_on_chest_spawned)
	if QuestManager.quest_started.is_connected(_on_quest_started) == false:
		QuestManager.quest_started.connect(_on_quest_started)

	# Event manager is not autoload — connect when available
	var event_mgr = _find_event_manager()
	if event_mgr and event_mgr.has_signal("event_started"):
		if not event_mgr.event_started.is_connected(_on_event_started):
			event_mgr.event_started.connect(_on_event_started)


func _find_event_manager() -> Node:
	# EventManager lives inside the stage scene tree, try to find it
	var root = get_tree().root if get_tree() else null
	if root:
		var nodes = root.find_children("*", "Node", true, false)
		for n in nodes:
			if n.name == "EventManager" and n.has_signal("event_started"):
				return n
	return null


func _build_ui() -> void:
	_panel = PanelContainer.new()
	_panel.name = "MiniTutorialPanel"
	_panel.custom_minimum_size = Vector2(PANEL_WIDTH, PANEL_HEIGHT)

	# Stylebox
	var sb := StyleBoxFlat.new()
	sb.bg_color = COLOR_BG
	sb.border_color = COLOR_BORDER
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(8)
	sb.content_margin_left = 16
	sb.content_margin_right = 16
	sb.content_margin_top = 12
	sb.content_margin_bottom = 12
	_panel.add_theme_stylebox_override("panel", sb)

	# Label
	_label = Label.new()
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", 16)
	_label.add_theme_color_override("font_color", COLOR_TEXT)
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(_label)

	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.visible = false
	_panel.modulate = Color(1, 1, 1, 0)

	add_child(_panel)
	_position_panel()


func _position_panel() -> void:
	var vw := 1280.0
	if get_viewport():
		vw = get_viewport().get_visible_rect().size.x
	_panel.position = Vector2((vw - PANEL_WIDTH) / 2.0, MARGIN_TOP)


func _get_shown_hints() -> Array:
	if not SaveManager.data.has("tutorial_hints_shown"):
		SaveManager.data["tutorial_hints_shown"] = []
	return SaveManager.data["tutorial_hints_shown"]


func _mark_shown(hint_id: String) -> void:
	var shown := _get_shown_hints()
	if hint_id not in shown:
		shown.append(hint_id)
		SaveManager.data["tutorial_hints_shown"] = shown
		SaveManager.save_game()


func _is_hint_shown(hint_id: String) -> bool:
	return hint_id in _get_shown_hints()


func _get_hint_message(hint_id: String) -> String:
	for h in HINTS:
		if h["id"] == hint_id:
			return h["message"]
	return ""


## Public: try to show a hint. Skips if already shown. Queues if another is active.
func try_show_hint(hint_id: String) -> void:
	if _is_hint_shown(hint_id):
		return
	# Don't queue duplicates
	if hint_id in _hint_queue:
		return
	if _is_showing and _label.text == _get_hint_message(hint_id):
		return

	_hint_queue.append(hint_id)
	if not _is_showing:
		_show_next()


func _show_next() -> void:
	if _hint_queue.is_empty():
		_is_showing = false
		return
	_is_showing = true
	var hint_id: String = _hint_queue.pop_front()

	if _is_hint_shown(hint_id):
		# Already shown (could have been marked while queued), skip
		_show_next()
		return

	_mark_shown(hint_id)
	_display_hint(hint_id)


func _display_hint(hint_id: String) -> void:
	var message := _get_hint_message(hint_id)
	if message.is_empty():
		_show_next()
		return

	_label.text = message
	_position_panel()
	_panel.visible = true
	_panel.modulate = Color(1, 1, 1, 0)

	# Slide up 20px + fade in, stay, fade out
	var start_y := _panel.position.y + 20.0
	var target_y := _panel.position.y
	_panel.position.y = start_y

	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)

	# Fade in + slide up
	tween.tween_property(_panel, "modulate:a", 1.0, FADE_IN_DURATION) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.parallel().tween_property(_panel, "position:y", target_y, FADE_IN_DURATION) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)

	# Stay
	tween.tween_interval(DISPLAY_DURATION)

	# Fade out
	tween.tween_property(_panel, "modulate:a", 0.0, FADE_OUT_DURATION) \
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)

	# Hide and process queue
	tween.tween_callback(func():
		_panel.visible = false
	)
	tween.tween_interval(QUEUE_GAP)
	tween.tween_callback(_show_next)


# -- Process: dash timer hint (30s into gameplay) --
func _process(delta: float) -> void:
	if _is_hint_shown("first_dash"):
		return
	# Only count time during active gameplay
	if not GameManager.is_playing if GameManager.has_method("is_playing") else GameManager.game_time <= 0.0:
		return
	if GameManager.game_time >= 30.0:
		try_show_hint("first_dash")

	# Check relic at game start (first few seconds)
	if not _is_hint_shown("first_relic") and GameManager.game_time > 1.0 and GameManager.game_time < 5.0:
		if GameManager.selected_relic != "":
			try_show_hint("first_relic")


# -- Signal callbacks --
func _on_chest_spawned(_chest: Node3D) -> void:
	try_show_hint("first_chest")


func _on_player_leveled_up(_new_level: int) -> void:
	try_show_hint("first_level_up")


func _on_boss_spawned(_boss_name: String) -> void:
	try_show_hint("first_boss")


func _on_elite_spawned(_boss_name: String) -> void:
	try_show_hint("first_elite")


func _on_synergy_activated(_synergy_name: String, _synergy_data: Dictionary) -> void:
	try_show_hint("first_synergy")


func _on_quest_started(_quest: Dictionary) -> void:
	try_show_hint("first_quest")


func _on_event_started(event_name: String) -> void:
	if event_name == "merchant" or event_name == "mercante":
		try_show_hint("first_merchant")


## Called externally when an evolution becomes available
func notify_evolution_ready() -> void:
	try_show_hint("first_evolution_ready")
