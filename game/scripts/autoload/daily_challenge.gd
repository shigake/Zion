extends Node

## Gerencia o sistema de Desafio Diario.
## Gera uma seed diaria baseada na data UTC que determina stage, personagens,
## mutacoes e padroes de spawn. Jogador pode jogar uma vez por dia.
## Persistencia propria em user://daily_challenge.json.

signal daily_completed(score: Dictionary)
signal streak_updated(new_streak: int)

const SAVE_PATH := "user://daily_challenge.json"

# Stages e personagens disponiveis para sorteio
var ALL_STAGES: Array[String] = GameConstants.ENABLED_STAGES

const ALL_CHARACTERS: Array[String] = [
	"ronin", "soldado", "mago", "berserker", "ninja", "bruxa",
	"pirata", "engenheiro", "vampiro", "gladiador", "chef", "mystery",
	"amazona", "lealith",
]

const ALL_MUTATIONS: Array[String] = [
	"explosive_enemies", "furious_bosses", "weakened_healing",
	"speed_demons", "endless_horde", "no_evolution",
]

# Multiplicador de cristais no modo daily
const CRYSTAL_MULTIPLIER := 1.5

# Tempo minimo antes de permitir retry (5 minutos em segundos)
const RETRY_GRACE_PERIOD := 300.0

# Dados persistentes
var data: Dictionary = {
	"daily_scores": {},    # date_string -> Array[Dictionary]
	"streak": 0,           # Dias consecutivos jogados
	"last_daily_date": "", # Ultima data jogada (YYYY-MM-DD)
	"best_streak": 0,      # Maior sequencia ja alcancada
}

# Estado da run atual
var _daily_rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _current_daily_active: bool = false
var _retry_allowed: bool = true  # Permite retry se morrer antes de 5 min


func _ready() -> void:
	_load_data()
	_update_streak()
	LogManager.info("DailyChallenge", "Daily challenge ready. Seed: %d, Stage: %s, Char: %s" % [
		get_daily_seed(), get_daily_stage(), get_daily_character()
	])


# --------------------------------------------------------------------------
# Seed e geracao deterministica
# --------------------------------------------------------------------------

func get_today_string() -> String:
	## Retorna a data UTC atual no formato YYYY-MM-DD.
	var dt := Time.get_datetime_dict_from_system(true)  # UTC
	return "%04d-%02d-%02d" % [dt["year"], dt["month"], dt["day"]]


func get_daily_seed() -> int:
	## Gera seed deterministica baseada na data UTC.
	## Formula: year * 10000 + month * 100 + day
	var dt := Time.get_datetime_dict_from_system(true)
	return dt["year"] * 10000 + dt["month"] * 100 + dt["day"]


func get_daily_stage() -> String:
	## Retorna o stage determinado pela seed diaria via modulo.
	var seed_val := get_daily_seed()
	return ALL_STAGES[seed_val % ALL_STAGES.size()]


func get_daily_character() -> String:
	## Retorna o personagem fixo do dia determinado pela seed via modulo.
	var seed_val := get_daily_seed()
	return ALL_CHARACTERS[(seed_val / ALL_STAGES.size()) % ALL_CHARACTERS.size()]


func get_daily_characters() -> Array[String]:
	## Retrocompatibilidade — retorna array com o personagem unico do dia.
	return [get_daily_character()]


func get_daily_starting_weapon() -> String:
	## Retorna a arma inicial do personagem do dia.
	var char_id := get_daily_character()
	var char_data: Dictionary = CharacterDB.get_character(char_id)
	return char_data.get("starting_weapon", "katana")


func get_daily_mutations() -> Array[String]:
	## Retorna 0-2 mutacoes determinadas pela seed diaria.
	var seed_val := get_daily_seed()
	_daily_rng.seed = seed_val
	# Avanca o RNG (stage + character = 2 chamadas consumidas)
	for i in range(2):
		_daily_rng.randi()

	var mutation_count := _daily_rng.randi() % 3  # 0, 1, ou 2 mutacoes
	if mutation_count == 0:
		return []

	var available: Array[String] = ALL_MUTATIONS.duplicate()
	var result: Array[String] = []
	for i in range(mutation_count):
		if available.is_empty():
			break
		var idx := _daily_rng.randi() % available.size()
		result.append(available[idx])
		available.remove_at(idx)
	return result


func get_daily_rng() -> RandomNumberGenerator:
	## Retorna um RNG com seed diaria para uso no enemy_spawner.
	## Deve ser chamado no inicio da run para garantir determinismo.
	var rng := RandomNumberGenerator.new()
	rng.seed = get_daily_seed()
	return rng


# --------------------------------------------------------------------------
# Estado do desafio
# --------------------------------------------------------------------------

func is_daily_completed() -> bool:
	## Verifica se o jogador ja completou o desafio de hoje.
	var today := get_today_string()
	if not data["daily_scores"].has(today):
		return false
	var scores: Array = data["daily_scores"][today]
	# Considera completo se ha pelo menos um score com tempo >= 5 min
	for score in scores:
		if score.get("time", 0.0) >= RETRY_GRACE_PERIOD:
			return true
	return false


func can_play_daily() -> bool:
	## Verifica se o jogador pode iniciar o desafio diario.
	## Pode jogar se nunca jogou hoje OU se morreu antes de 5 min.
	if not is_daily_completed():
		return true
	return false


func get_time_until_reset() -> int:
	## Retorna segundos ate a proxima meia-noite UTC.
	var dt := Time.get_datetime_dict_from_system(true)
	var seconds_today: int = dt["hour"] * 3600 + dt["minute"] * 60 + dt["second"]
	return 86400 - seconds_today


func get_streak() -> int:
	## Retorna a sequencia atual de dias consecutivos.
	return data.get("streak", 0)


func get_best_streak() -> int:
	## Retorna a maior sequencia ja alcancada.
	return data.get("best_streak", 0)


# --------------------------------------------------------------------------
# Iniciar e finalizar daily run
# --------------------------------------------------------------------------

func start_daily_run() -> void:
	## Configura GameManager para modo daily e inicia a run.
	if not can_play_daily():
		LogManager.warn("DailyChallenge", "Tentativa de jogar daily ja completado")
		return

	# Configurar GameManager com loadout fixo do dia
	GameManager.game_mode = "daily"
	GameManager.selected_stage = get_daily_stage()
	GameManager.selected_character = get_daily_character()

	# Aplicar mutacoes do dia
	MutationManager.reset()
	var mutations := get_daily_mutations()
	for mut_id in mutations:
		MutationManager.toggle_mutation(mut_id)

	_current_daily_active = true
	_retry_allowed = true

	LogManager.info("DailyChallenge", "Daily run started: stage=%s, char=%s, weapon=%s, mutations=%s" % [
		GameManager.selected_stage, GameManager.selected_character, get_daily_starting_weapon(), str(mutations)
	])

	# Navegar para o stage
	var scene_path: String = GameConstants.STAGE_SCENE_PATHS.get(GameManager.selected_stage, "res://scenes/stages/stage_cemetery.tscn")
	GameManager.reset()
	get_tree().change_scene_to_file(scene_path)


func calculate_score(kills: int, survived_seconds: float, crystals_earned: int) -> int:
	## Calcula score composto: kills * 10 + survived_seconds + crystals_earned
	return kills * 10 + int(survived_seconds) + crystals_earned


func submit_score(kills: int, survived_seconds: float, crystals_earned: int) -> Dictionary:
	## Salva o score da daily run e retorna o entry salvo.
	## Alias principal conforme spec. Mantem top 10 por dia.
	var today := get_today_string()
	var character := get_daily_character()
	var total_score := calculate_score(kills, survived_seconds, crystals_earned)

	var score := {
		"score": total_score,
		"kills": kills,
		"time": survived_seconds,
		"crystals": crystals_earned,
		"character": character,
		"date": today,
		"mutations": MutationManager.get_active_ids(),
		"stage": get_daily_stage(),
		"victory": GameManager.is_victory,
	}

	if not data["daily_scores"].has(today):
		data["daily_scores"][today] = []
	data["daily_scores"][today].append(score)

	# Ordenar por score descendente e manter top 10
	data["daily_scores"][today].sort_custom(func(a, b):
		return a.get("score", 0) > b.get("score", 0)
	)
	if data["daily_scores"][today].size() > 10:
		data["daily_scores"][today].resize(10)

	# Atualizar streak
	_record_daily_played(today)

	# Cristais bonus (1.5x)
	var base_crystals := GameManager.crystals_this_run
	var bonus := int(base_crystals * (CRYSTAL_MULTIPLIER - 1.0))
	if bonus > 0:
		SaveManager.add_crystals(bonus)
		LogManager.info("DailyChallenge", "Daily crystal bonus: +%d (total: %d)" % [bonus, base_crystals + bonus])

	_save_data()
	_current_daily_active = false
	daily_completed.emit(score)

	LogManager.info("DailyChallenge", "Daily score submitted: score=%d (kills=%d, time=%.1f, crystals=%d), char=%s" % [
		total_score, kills, survived_seconds, crystals_earned, character
	])
	return score


func submit_daily_score(time_survived: float, kills: int, character: String) -> void:
	## Retrocompatibilidade — redireciona para submit_score.
	submit_score(kills, time_survived, GameManager.crystals_this_run)


func is_daily_active() -> bool:
	## Verifica se uma daily run esta em andamento.
	return _current_daily_active and GameManager.game_mode == "daily"


func get_daily_crystal_multiplier() -> float:
	## Retorna o multiplicador de cristais do modo daily.
	if GameManager.game_mode == "daily":
		return CRYSTAL_MULTIPLIER
	return 1.0


# --------------------------------------------------------------------------
# Leaderboard local
# --------------------------------------------------------------------------

func get_leaderboard(date: String = "") -> Array[Dictionary]:
	## Retorna o leaderboard local (top 10) para uma data especifica (padrao: hoje).
	## Ordenado por score composto descendente.
	if date.is_empty():
		date = get_today_string()
	if not data["daily_scores"].has(date):
		return []
	var scores: Array[Dictionary] = []
	for s in data["daily_scores"][date]:
		scores.append(s)
	# Ordenar por score composto descendente
	scores.sort_custom(func(a, b):
		return a.get("score", 0) > b.get("score", 0)
	)
	# Limitar a top 10
	if scores.size() > 10:
		scores.resize(10)
	return scores


func get_daily_leaderboard(date: String = "") -> Array[Dictionary]:
	## Alias para retrocompatibilidade.
	return get_leaderboard(date)


func get_today_best_score() -> Dictionary:
	## Retorna o melhor score de hoje (por score composto).
	var lb := get_leaderboard()
	if lb.is_empty():
		return {}
	return lb[0]


# --------------------------------------------------------------------------
# Streak (dias consecutivos)
# --------------------------------------------------------------------------

func _record_daily_played(date: String) -> void:
	## Registra que o jogador completou o daily nesta data.
	var last_date: String = data.get("last_daily_date", "")
	data["last_daily_date"] = date

	if last_date.is_empty():
		data["streak"] = 1
	else:
		var yesterday := _get_yesterday_string(date)
		if last_date == yesterday:
			data["streak"] = data.get("streak", 0) + 1
		elif last_date == date:
			pass  # Ja jogou hoje, nao incrementa
		else:
			data["streak"] = 1  # Sequencia quebrada

	# Atualizar melhor streak
	if data["streak"] > data.get("best_streak", 0):
		data["best_streak"] = data["streak"]

	streak_updated.emit(data["streak"])


func _update_streak() -> void:
	## Verifica e atualiza streak no startup (caso o jogador tenha perdido um dia).
	var today := get_today_string()
	var last_date: String = data.get("last_daily_date", "")
	if last_date.is_empty():
		return
	var yesterday := _get_yesterday_string(today)
	if last_date != today and last_date != yesterday:
		# Sequencia quebrada — mais de 1 dia sem jogar
		data["streak"] = 0
		_save_data()
		LogManager.info("DailyChallenge", "Streak reset (last played: %s)" % last_date)


func _get_yesterday_string(today_str: String) -> String:
	## Retorna a data de ontem a partir de uma string YYYY-MM-DD.
	var parts := today_str.split("-")
	if parts.size() != 3:
		return ""
	var year := int(parts[0])
	var month := int(parts[1])
	var day := int(parts[2])

	day -= 1
	if day < 1:
		month -= 1
		if month < 1:
			month = 12
			year -= 1
		# Dias no mes anterior
		var days_in_month := [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
		# Ano bissexto
		if month == 2 and (year % 4 == 0 and (year % 100 != 0 or year % 400 == 0)):
			day = 29
		else:
			day = days_in_month[month - 1]

	return "%04d-%02d-%02d" % [year, month, day]


# --------------------------------------------------------------------------
# Limpeza de dados antigos
# --------------------------------------------------------------------------

func _cleanup_old_scores() -> void:
	## Remove scores com mais de 30 dias para nao acumular indefinidamente.
	var today := get_today_string()
	var keys_to_remove: Array[String] = []
	for date_key in data["daily_scores"]:
		# Comparacao simples de strings funciona para YYYY-MM-DD
		# Manter ultimos 30 dias (aproximacao)
		if date_key < _get_date_n_days_ago(today, 30):
			keys_to_remove.append(date_key)
	for key in keys_to_remove:
		data["daily_scores"].erase(key)


func _get_date_n_days_ago(from_date: String, n: int) -> String:
	## Retorna a data N dias atras (aproximacao simples).
	var result := from_date
	for i in range(n):
		result = _get_yesterday_string(result)
	return result


# --------------------------------------------------------------------------
# Persistencia
# --------------------------------------------------------------------------

func _save_data() -> void:
	## Salva dados do daily challenge em arquivo separado.
	_cleanup_old_scores()
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))
		file.close()
	else:
		LogManager.error("DailyChallenge", "Falha ao salvar: %s" % SAVE_PATH)


func _load_data() -> void:
	## Carrega dados do daily challenge.
	if not FileAccess.file_exists(SAVE_PATH):
		LogManager.info("DailyChallenge", "Nenhum save de daily encontrado, usando defaults")
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		var json := JSON.new()
		var result := json.parse(file.get_as_text())
		if result == OK:
			var loaded = json.data
			if loaded is Dictionary:
				for key in loaded:
					data[key] = loaded[key]
				LogManager.info("DailyChallenge", "Daily data loaded: streak=%d, last=%s" % [
					data.get("streak", 0), data.get("last_daily_date", "none")
				])
			else:
				LogManager.error("DailyChallenge", "Formato invalido no save de daily")
		else:
			LogManager.error("DailyChallenge", "Erro ao parsear save de daily: %s" % json.get_error_message())
		file.close()
	else:
		LogManager.error("DailyChallenge", "Falha ao abrir save de daily: %s" % SAVE_PATH)
