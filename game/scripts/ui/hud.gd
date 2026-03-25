extends CanvasLayer

## HUD: HP, XP, level, timer, kills, dash cooldown.

@onready var hp_bar: ProgressBar = $MarginContainer/VBox/HPBar
@onready var xp_bar: ProgressBar = $MarginContainer/VBox/XPBar
@onready var level_label: Label = $MarginContainer/VBox/LevelLabel
@onready var time_label: Label = $TopRight/TimeLabel
@onready var kill_label: Label = $TopRight/KillLabel
@onready var dash_label: Label = $BottomCenter/DashLabel
@onready var event_label: Label = $EventNotification/EventLabel

var event_display_timer: float = 0.0

func _ready() -> void:
	GameManager.player_leveled_up.connect(_on_level_up)
	GameManager.game_over.connect(_on_game_over)
	event_label.visible = false

	# Conecta ao EventManager se existir
	await get_tree().process_frame
	var em = get_tree().current_scene.get_node_or_null("EventManager")
	if em:
		em.event_started.connect(_on_event_started)
		em.event_ended.connect(_on_event_ended)

func _process(_delta: float) -> void:
	_update_hp()
	_update_xp()
	_update_time()
	_update_kills()

func _update_hp() -> void:
	var max_hp = int(GameManager.player_max_hp * GameManager.max_hp_mult)
	hp_bar.max_value = max_hp
	hp_bar.value = GameManager.player_hp

func _update_xp() -> void:
	xp_bar.max_value = GameManager.player_xp_to_next
	xp_bar.value = GameManager.player_xp

func _update_time() -> void:
	var t = int(GameManager.game_time)
	time_label.text = "%02d:%02d" % [t / 60, t % 60]

func _update_kills() -> void:
	kill_label.text = "Kills: %d | Cristais: %d" % [GameManager.total_kills, GameManager.crystals_this_run]

func _on_level_up(_new_level: int) -> void:
	level_label.text = "Lv. %d" % _new_level

func _on_game_over() -> void:
	pass

func _on_event_started(event_name: String) -> void:
	var display_names = {
		"golden_horde": "HORDA DOURADA!",
		"treasure_goblin": "TREASURE GOBLIN!",
		"merchant": "MERCADOR APARECEU!",
		"roulette": "RODA DA FORTUNA!",
	}
	event_label.text = display_names.get(event_name, event_name.to_upper())
	event_label.visible = true

func _on_event_ended(_event_name: String) -> void:
	event_label.visible = false
