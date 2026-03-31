extends Node

## Sistema de mini-quests durante a run.
## Objetivos simples que dao recompensas ao completar.

signal quest_started(quest: Dictionary)
signal quest_completed(quest: Dictionary)
signal quest_progress(quest: Dictionary, current: int, target: int)

var current_quest: Dictionary = {}
var _quest_timer: float = 0.0
var _quest_active: bool = false
var _quest_progress: int = 0
var _quests_completed: int = 0
var _kill_count_at_start: int = 0

# Pool de quests disponiveis
const QUEST_POOL := [
	{"type": "kill", "target": 30, "name": "Eliminar %d inimigos", "icon": "⚔"},
	{"type": "kill", "target": 50, "name": "Eliminar %d inimigos", "icon": "⚔"},
	{"type": "survive", "target": 30, "name": "Sobreviver %d segundos sem dano", "icon": "🛡"},
	{"type": "collect_xp", "target": 15, "name": "Coletar %d XP gems", "icon": "💎"},
	{"type": "kill_fast", "target": 10, "name": "Matar %d inimigos em 10s", "icon": "⚡"},
	{"type": "find_chest", "target": 1, "name": "Encontrar o bau de recompensa", "icon": "📦"},
	{"type": "reach_level", "target": 0, "name": "Alcancar nivel %d", "icon": "⭐"},
]

func _ready() -> void:
	GameManager.enemy_killed.connect(_on_enemy_killed)
	GameManager.player_leveled_up.connect(_on_level_up)
	ChestManager.chest_collected.connect(_on_chest_collected)

func _process(delta: float) -> void:
	if GameManager.paused or GameManager.is_game_over:
		return
	if GameManager.game_time < 15.0:
		return  # Primeira quest apos 15s

	if not _quest_active:
		_quest_timer += delta
		if _quest_timer >= GameConstants.QUEST_INTERVAL:
			_quest_timer = 0.0
			_start_random_quest()
	else:
		_update_quest_progress(delta)

func _start_random_quest() -> void:
	var template = QUEST_POOL[randi() % QUEST_POOL.size()].duplicate()
	current_quest = template.duplicate()
	_quest_progress = 0
	_quest_active = true

	match current_quest["type"]:
		"kill":
			_kill_count_at_start = GameManager.total_kills
		"survive":
			current_quest["_no_damage_timer"] = 0.0
		"collect_xp":
			current_quest["_xp_at_start"] = GameManager.player_xp
		"kill_fast":
			current_quest["_fast_kills"] = 0
			current_quest["_fast_timer"] = 10.0
		"find_chest":
			# Forca spawn de bau se nao tem nenhum ativo
			if ChestManager.get_active_chests().is_empty():
				ChestManager._spawn_chest()
		"reach_level":
			current_quest["target"] = GameManager.player_level + 2
			current_quest["name"] = "Alcancar nivel %d"

	current_quest["display_name"] = current_quest["icon"] + " " + current_quest["name"] % current_quest["target"]
	quest_started.emit(current_quest)
	LogManager.info("Quest", "Started: %s" % current_quest["display_name"])

func _update_quest_progress(delta: float) -> void:
	var completed = false

	match current_quest["type"]:
		"kill":
			_quest_progress = GameManager.total_kills - _kill_count_at_start
			completed = _quest_progress >= current_quest["target"]
		"survive":
			current_quest["_no_damage_timer"] += delta
			var survive_time: float = current_quest["_no_damage_timer"]
			_quest_progress = mini(ceili(survive_time), current_quest["target"])
			completed = survive_time >= float(current_quest["target"])
		"collect_xp":
			_quest_progress = mini(_quest_progress, current_quest["target"])
			completed = _quest_progress >= current_quest["target"]
		"kill_fast":
			current_quest["_fast_timer"] -= delta
			_quest_progress = current_quest.get("_fast_kills", 0)
			completed = _quest_progress >= current_quest["target"]
			if not completed and current_quest["_fast_timer"] <= 0:
				current_quest["_fast_kills"] = 0
				current_quest["_fast_timer"] = 10.0
		"find_chest":
			completed = _quest_progress >= 1
		"reach_level":
			_quest_progress = GameManager.player_level
			completed = _quest_progress >= current_quest["target"]

	quest_progress.emit(current_quest, _quest_progress, current_quest["target"])
	if completed:
		_complete_quest()

func _complete_quest() -> void:
	_quest_active = false
	_quests_completed += 1

	# Recompensa
	GameManager.crystals_this_run += GameConstants.QUEST_REWARD_CRYSTALS
	SaveManager.data["crystals"] = SaveManager.data.get("crystals", 0) + GameConstants.QUEST_REWARD_CRYSTALS
	GameManager.add_xp(GameConstants.QUEST_REWARD_XP)

	AudioManager.play_sfx("achievement")
	ScreenEffects.shake(0.08)

	var players = GameManager.get_players()
	if not players.is_empty():
		ParticleFactory.spawn_level_up_particles(players[0].global_position)
		ParticleFactory.spawn_damage_number(
			players[0].global_position + Vector3(0, 2, 0),
			"Quest completa! +%d cristais" % GameConstants.QUEST_REWARD_CRYSTALS,
			Color(0.3, 1.0, 0.4)
		)

	quest_completed.emit(current_quest)
	LogManager.info("Quest", "Completed: %s (total: %d)" % [current_quest["display_name"], _quests_completed])
	current_quest = {}

func _on_enemy_killed(_pos: Vector3, _xp: int) -> void:
	if not _quest_active:
		return
	match current_quest["type"]:
		"kill":
			# Checa imediatamente no signal para nao perder o ultimo kill
			_quest_progress = GameManager.total_kills - _kill_count_at_start
			quest_progress.emit(current_quest, _quest_progress, current_quest["target"])
			if _quest_progress >= current_quest["target"]:
				# Delay para HUD mostrar X/X antes de completar
				await get_tree().create_timer(0.4).timeout
				_complete_quest()
		"kill_fast":
			current_quest["_fast_kills"] = current_quest.get("_fast_kills", 0) + 1
		"collect_xp":
			_quest_progress += 1

func _on_level_up(_level: int) -> void:
	pass  # reach_level checked in _update_quest_progress

func _on_chest_collected(_reward: Dictionary) -> void:
	if _quest_active and current_quest["type"] == "find_chest":
		_quest_progress = 1

func on_player_damaged() -> void:
	## Chamado pelo GameManager quando o jogador toma dano.
	if _quest_active and current_quest["type"] == "survive":
		current_quest["_no_damage_timer"] = 0.0

func reset() -> void:
	_quest_timer = 0.0
	_quest_active = false
	_quest_progress = 0
	_quests_completed = 0
	current_quest = {}
