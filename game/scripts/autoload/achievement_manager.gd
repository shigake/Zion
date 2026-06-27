extends Node

## Achievement tracking and unlocking system.

signal achievement_unlocked(id: String, name: String)

var achievements: Dictionary = {
	"first_walk": {"name": "Meu Primeiro Passeio", "description": "Sobreviva 5 minutos"},
	"evolved_6": {"name": "Isso Escala", "description": "Tenha 6 armas evoluidas"},
	"speedrunner": {"name": "Speedrunner", "description": "Mate o boss em menos de 15 min"},
	"collector": {"name": "Colecionador", "description": "Desbloqueie todos os personagens"},
	"cow_brejo": {"name": "A Vaca Foi Pro Brejo", "description": "Complete Fazenda sem dano de vaca"},
	"nobody_deserves": {"name": "Ninguem Merece", "description": "Morra nos primeiros 10 segundos"},
	"genocide": {"name": "Genocidio", "description": "Mate 10.000 inimigos numa run"},
	"sweet_revenge": {"name": "Doce Vinganca", "description": "Complete o Mundo Doce"},
	"storm": {"name": "I Am The Storm", "description": "Tenha 3 armas eletricas evoluidas"},
	"pacifist": {"name": "Pacifista", "description": "Sobreviva 3 min sem atacar"},
	"matrix": {"name": "Matrix", "description": "Dodge 100 projeteis numa run"},
	"one_punch": {"name": "One Punch", "description": "Mate um boss com 1 hit"},
	"lucky_day": {"name": "Lucky Day", "description": "Pegue 5 itens lendarios numa run"},
	"treasure_hunter": {"name": "Treasure Hunter", "description": "Colete 10 baus numa run"},
	"quest_master": {"name": "Quest Master", "description": "Complete 5 quests numa run"},
	"boss_slayer": {"name": "Boss Slayer", "description": "Derrote 2 bosses numa run"},
	"completionist": {"name": "Completionist", "description": "Complete todas as 10 fendas"},
	"marathon": {"name": "Maratonista", "description": "Sobreviva 30 minutos numa run"},
	"dedicated": {"name": "Dedicado", "description": "Complete 100 runs no total"},
}

# Run-specific tracking
var _run_dodges: int = 0
var _run_chests_collected: int = 0
var _run_quests_completed: int = 0
var _run_bosses_killed: int = 0
var _run_no_cow_damage: bool = true
var _run_attacks: int = 0
var _run_legendary_items: int = 0

func check_achievements() -> void:
	# Called at end of run and periodically
	var unlocked = SaveManager.data.get("achievements", [])

	# Meu Primeiro Passeio: survive 5 minutes
	if "first_walk" not in unlocked and GameManager.game_time >= 300.0:
		_unlock("first_walk")

	# Speedrunner: kill boss in < 15 min
	if "speedrunner" not in unlocked and GameManager.is_victory and GameManager.game_time < 900.0:
		_unlock("speedrunner")

	# Ninguem Merece: die in first 10 seconds
	if "nobody_deserves" not in unlocked and GameManager.is_game_over and not GameManager.is_victory and GameManager.game_time < 10.0:
		_unlock("nobody_deserves")

	# Genocidio: 10000 kills in one run
	if "genocide" not in unlocked and GameManager.total_kills >= 10000:
		_unlock("genocide")

	# Doce Vinganca: complete Candy stage
	if "sweet_revenge" not in unlocked and GameManager.is_victory and GameManager.selected_stage == "candy":
		_unlock("sweet_revenge")

	# A Vaca Foi Pro Brejo: complete Farm without cow damage
	if "cow_brejo" not in unlocked and GameManager.is_victory and GameManager.selected_stage == "farm" and _run_no_cow_damage:
		_unlock("cow_brejo")

	# Colecionador: all characters unlocked
	if "collector" not in unlocked:
		var all_chars = CharacterDB.get_all_character_ids()
		var all_unlocked = true
		for cid in all_chars:
			if not SaveManager.is_character_unlocked(cid):
				all_unlocked = false
				break
		if all_unlocked:
			_unlock("collector")

	# Isso Escala: 6 evolved weapons
	if "evolved_6" not in unlocked and EvolutionDB.evolved_weapons.size() >= 6:
		_unlock("evolved_6")

	# Matrix: dodge 100 projectiles in one run
	if "matrix" not in unlocked and _run_dodges >= 100:
		_unlock("matrix")

	# Pacifista: survive 3 min without attacking
	if "pacifist" not in unlocked and GameManager.game_time >= 180.0 and _run_attacks == 0:
		_unlock("pacifist")

	# Lucky Day: 5 legendary items (level 5 items count as legendary)
	if "lucky_day" not in unlocked and _run_legendary_items >= 5:
		_unlock("lucky_day")

	# Treasure Hunter: collect 10 chests in one run
	if "treasure_hunter" not in unlocked and _run_chests_collected >= 10:
		_unlock("treasure_hunter")

	# Quest Master: complete 5 quests in one run
	if "quest_master" not in unlocked and _run_quests_completed >= 5:
		_unlock("quest_master")

	# Boss Slayer: defeat 2 bosses in one run
	if "boss_slayer" not in unlocked and _run_bosses_killed >= 2:
		_unlock("boss_slayer")

	# Completionist: complete all 10 stages
	if "completionist" not in unlocked:
		var completed = SaveManager.data.get("completed_stages", [])
		var all_done = true
		for stage in GameConstants.ENABLED_STAGES:
			if stage not in completed:
				all_done = false
				break
		if all_done:
			_unlock("completionist")

	# Maratonista: survive 30 minutes in one run
	if "marathon" not in unlocked and GameManager.game_time >= 1800.0:
		_unlock("marathon")

	# Dedicado: 100 total runs across all sessions
	if "dedicated" not in unlocked and SaveManager.data.get("total_runs", 0) >= 100:
		_unlock("dedicated")

	# I Am The Storm: 3 electric-type evolved weapons
	if "storm" not in unlocked:
		var electric_evos = 0
		for evo_id in EvolutionDB.evolved_weapons:
			var evo = EvolutionDB.get_evolution(evo_id)
			var weapon_id = evo.get("weapon_required", "")
			var weapon_data = WeaponDB.get_weapon(weapon_id)
			if weapon_data.get("damage_type", "") == "electric":
				electric_evos += 1
		if electric_evos >= 3:
			_unlock("storm")

func _unlock(id: String) -> void:
	var unlocked = SaveManager.data.get("achievements", [])
	if id in unlocked:
		return
	if "achievements" not in SaveManager.data:
		SaveManager.data["achievements"] = []
	SaveManager.data["achievements"].append(id)
	SaveManager.save_game()
	var ach = achievements.get(id, {})
	achievement_unlocked.emit(id, ach.get("name", id))
	LogManager.info("Achievement", "Unlocked: %s" % ach.get("name", id))
	# Sync with Steam
	SteamManager.set_achievement(id)

func on_attack() -> void:
	_run_attacks += 1

func on_boss_killed_one_hit() -> void:
	var unlocked = SaveManager.data.get("achievements", [])
	if "one_punch" not in unlocked:
		_unlock("one_punch")

func _ready() -> void:
	ChestManager.chest_collected.connect(func(_r): _run_chests_collected += 1)
	QuestManager.quest_completed.connect(func(_q): _run_quests_completed += 1)
	GameManager.boss_died.connect(func(_n): _run_bosses_killed += 1)

func reset_run() -> void:
	_run_dodges = 0
	_run_no_cow_damage = true
	_run_attacks = 0
	_run_legendary_items = 0
	_run_chests_collected = 0
	_run_quests_completed = 0
	_run_bosses_killed = 0

func on_cow_damage() -> void:
	_run_no_cow_damage = false

func on_legendary_item() -> void:
	_run_legendary_items += 1

func is_unlocked(id: String) -> bool:
	return id in SaveManager.data.get("achievements", [])

func get_all_achievements() -> Dictionary:
	return achievements

func get_unlocked_count() -> int:
	return SaveManager.data.get("achievements", []).size()

## Returns progress data for a single achievement.
## {id, name, current, target, percent}
func get_progress(id: String) -> Dictionary:
	var ach = achievements.get(id, {})
	var ach_name = ach.get("name", id)
	var current: int = 0
	var target: int = 1

	match id:
		"genocide":
			current = GameManager.total_kills
			target = 10000
		"collector":
			var all_chars = CharacterDB.get_all_character_ids()
			var unlocked = 0
			for cid in all_chars:
				if SaveManager.is_character_unlocked(cid):
					unlocked += 1
			current = unlocked
			target = all_chars.size()
		"completionist":
			var completed_stages = SaveManager.data.get("completed_stages", [])
			current = completed_stages.size()
			target = 10
		"treasure_hunter":
			current = _run_chests_collected
			target = 10
		"quest_master":
			current = _run_quests_completed
			target = 5
		"boss_slayer":
			current = _run_bosses_killed
			target = 2
		"matrix":
			current = _run_dodges
			target = 100
		"evolved_6":
			current = EvolutionDB.evolved_weapons.size()
			target = 6
		"storm":
			var electric_evos = 0
			for evo_id in EvolutionDB.evolved_weapons:
				var evo = EvolutionDB.get_evolution(evo_id)
				var weapon_id = evo.get("weapon_required", "")
				var weapon_data = WeaponDB.get_weapon(weapon_id)
				if weapon_data.get("damage_type", "") == "electric":
					electric_evos += 1
			current = electric_evos
			target = 3
		"lucky_day":
			current = _run_legendary_items
			target = 5
		"first_walk":
			current = mini(int(GameManager.game_time), 300)
			target = 300
		"marathon":
			current = mini(int(GameManager.game_time), 1800)
			target = 1800
		"dedicated":
			current = mini(SaveManager.data.get("total_runs", 0), 100)
			target = 100
		"speedrunner":
			if GameManager.is_victory:
				current = 1
				target = 1
			else:
				current = mini(int(GameManager.game_time), 900)
				target = 900
		"pacifist":
			if _run_attacks == 0:
				current = mini(int(GameManager.game_time), 180)
				target = 180
			else:
				current = 0
				target = 180
		"nobody_deserves", "one_punch", "cow_brejo", "sweet_revenge":
			current = 0
			target = 1

	var pct = minf(1.0, float(current) / maxf(float(target), 1.0))
	return {"id": id, "name": ach_name, "current": current, "target": target, "percent": pct}

## Returns the N incomplete achievements with the highest progress percentage.
func get_nearest_achievements(count: int = 3) -> Array[Dictionary]:
	var incomplete: Array[Dictionary] = []
	for id in achievements:
		if is_unlocked(id):
			continue
		var progress = get_progress(id)
		if progress["percent"] > 0.0:
			incomplete.append(progress)
	incomplete.sort_custom(func(a, b): return a["percent"] > b["percent"])
	return incomplete.slice(0, count) as Array[Dictionary]
