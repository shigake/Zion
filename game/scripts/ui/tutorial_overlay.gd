extends CanvasLayer

## Overlay de tutorial. Mostra mensagens progressivas na primeira run.

@onready var center: CenterContainer = $CenterContainer
@onready var panel: PanelContainer = $CenterContainer/PanelContainer
@onready var label: Label = $CenterContainer/PanelContainer/Label

var tutorial_steps: Array[Dictionary] = [
	{"id": "move", "text": "WASD para mover, SPACE para dash", "duration": 5.0},
	{"id": "dash_tip", "text": "Dash te deixa invulneravel! Use para esquivar", "duration": 4.0},
	{"id": "xp", "text": "Inimigos dropam XP! Colete para subir de nivel", "duration": 5.0},
	{"id": "levelup", "text": "Escolha um upgrade! Armas ou itens passivos", "duration": 5.0},
	{"id": "crystals", "text": "Cristais dropam dos inimigos. Gaste na loja entre runs!", "duration": 5.0},
	{"id": "events", "text": "Eventos especiais acontecem durante a run!", "duration": 4.0},
	{"id": "synergy", "text": "2 armas do mesmo elemento = sinergia bonus!", "duration": 5.0},
	{"id": "evolution", "text": "Arma max + Item max = Evolucao! Aperte E", "duration": 5.0},
]

var shown_steps: Dictionary = {}  # step_id -> true
var current_timer: Timer = null
var first_kill_connected: bool = false
var first_levelup_connected: bool = false
var events_checked: bool = false
var evolution_checked: bool = false
var synergy_checked: bool = false
var tutorial_active: bool = false


func _ready() -> void:
	center.visible = false

	# Check if tutorial was already completed
	if SaveManager.data.get("tutorial_complete", false):
		set_process(false)
		return

	tutorial_active = true

	# Step 1: movement (at game start, 0s delay)
	_show_step_delayed("move", 0.5)

	# Step 2: first kill
	GameManager.enemy_killed.connect(_on_first_kill)
	first_kill_connected = true

	# Step 3: first level up
	GameManager.player_leveled_up.connect(_on_first_levelup)
	first_levelup_connected = true


func _process(delta: float) -> void:
	if not tutorial_active:
		return

	# Dash tip: after 15 seconds
	if "dash_tip" not in shown_steps and GameManager.game_time >= 15.0:
		_show_step("dash_tip")

	# Crystals tip: after first crystal drop (~30s into game)
	if "crystals" not in shown_steps and GameManager.crystals_this_run > 0:
		_show_step("crystals")

	# Synergy tip: at minute 3
	if not synergy_checked and GameManager.game_time >= 180.0:
		synergy_checked = true
		_show_step("synergy")

	# Events tip: at minute 5
	if not events_checked and GameManager.game_time >= 300.0:
		events_checked = true
		_show_step("events")


func _show_step_delayed(step_id: String, delay: float) -> void:
	var t = get_tree().create_timer(delay, false, true)
	t.timeout.connect(func(): _show_step(step_id))


func _show_step(step_id: String) -> void:
	if step_id in shown_steps:
		return
	shown_steps[step_id] = true

	var step: Dictionary = {}
	for s in tutorial_steps:
		if s["id"] == step_id:
			step = s
			break

	if step.is_empty():
		return

	label.text = step["text"]
	center.visible = true

	# Create hide timer
	if current_timer and current_timer.time_left > 0:
		current_timer.timeout.disconnect(_hide_message)
		current_timer.queue_free()

	current_timer = Timer.new()
	current_timer.wait_time = step["duration"]
	current_timer.one_shot = true
	add_child(current_timer)
	current_timer.timeout.connect(_hide_message)
	current_timer.start()

	# Check if all steps done
	if shown_steps.size() == tutorial_steps.size():
		_complete_tutorial()


func _hide_message() -> void:
	center.visible = false
	if current_timer:
		current_timer.queue_free()
		current_timer = null


func _on_first_kill(_position: Vector3, _xp_value: int) -> void:
	if first_kill_connected:
		GameManager.enemy_killed.disconnect(_on_first_kill)
		first_kill_connected = false
	_show_step("xp")


func _on_first_levelup(_new_level: int) -> void:
	if first_levelup_connected:
		GameManager.player_leveled_up.disconnect(_on_first_levelup)
		first_levelup_connected = false
	_show_step("levelup")


func show_evolution_step() -> void:
	## Called externally when player encounters first evolution chest.
	_show_step("evolution")


func _complete_tutorial() -> void:
	tutorial_active = false
	SaveManager.data["tutorial_complete"] = true
	SaveManager.save_game()
	set_process(false)
