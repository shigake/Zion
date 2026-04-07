extends Node

## Gerencia o modo Fenda Infinita (endless mode).
## Ativado apos o jogador derrotar o Sentinela e escolher continuar.
## Escala dificuldade infinitamente por ondas de 60s cada.
## Leaderboard separado salvo via SaveManager.

signal wave_changed(wave: int)

# -- Constantes de balanceamento (locais para evitar conflito com GameConstants) --
const ENDLESS_WAVE_DURATION := 60.0
const ENDLESS_HP_SCALE := 0.2       # +20% HP por onda
const ENDLESS_DMG_SCALE := 0.1      # +10% dano por onda
const ENDLESS_SPEED_SCALE := 0.05   # +5% velocidade por onda
const ENDLESS_SPEED_CAP := 2.0      # Cap de multiplicador de velocidade
const ENDLESS_CRYSTAL_BONUS := 0.1  # +10% bonus de cristais por onda
const ENDLESS_MINIBOSS_WAVE := 7    # Primeira onda com mini-boss
const ENDLESS_CROSS_FENDA_WAVE := 4 # Primeira onda com inimigos cross-fenda
const ENDLESS_BOSS_RETURN_WAVE := 20 # Onda em que o Sentinela retorna fortalecido
const ENDLESS_DIFFICULTY_SCALE := 0.25 # +25% por min no endless (vs 15% normal)

# -- Estado --
var is_endless_active: bool = false
var endless_wave: int = 0
var endless_start_time: float = 0.0
var boss_kill_time: float = 0.0

# Tempo acumulado dentro da onda atual
var _wave_elapsed: float = 0.0


func _ready() -> void:
	set_process(false)
	LogManager.info("EndlessMode", "Endless mode system ready")


func _process(delta: float) -> void:
	if not is_endless_active:
		return

	_wave_elapsed += delta

	if _wave_elapsed >= ENDLESS_WAVE_DURATION:
		_wave_elapsed -= ENDLESS_WAVE_DURATION
		endless_wave += 1
		_on_wave_advanced()


# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

func activate_endless() -> void:
	## Chamado quando o jogador escolhe "Fenda Infinita" apos matar o boss.
	is_endless_active = true
	endless_wave = 1
	endless_start_time = GameManager.game_time
	boss_kill_time = GameManager.game_time
	_wave_elapsed = 0.0
	set_process(true)

	LogManager.info("EndlessMode", "Endless mode activated at game_time=%.1f" % endless_start_time)
	wave_changed.emit(endless_wave)


func get_endless_multipliers() -> Dictionary:
	## Retorna multiplicadores de dificuldade baseados na onda atual.
	## EnemySpawner e outros sistemas devem consultar este metodo.
	if not is_endless_active:
		return {"hp_mult": 1.0, "dmg_mult": 1.0, "speed_mult": 1.0, "crystal_bonus": 1.0}

	var w := endless_wave
	var hp_mult := pow(1.0 + ENDLESS_HP_SCALE, w)
	var dmg_mult := pow(1.0 + ENDLESS_DMG_SCALE, w)
	var speed_mult := minf(pow(1.0 + ENDLESS_SPEED_SCALE, w), ENDLESS_SPEED_CAP)
	var crystal_bonus := 1.0 + w * ENDLESS_CRYSTAL_BONUS

	return {
		"hp_mult": hp_mult,
		"dmg_mult": dmg_mult,
		"speed_mult": speed_mult,
		"crystal_bonus": crystal_bonus,
	}


func get_endless_wave_time() -> float:
	## Retorna o tempo decorrido dentro da onda atual (0..ENDLESS_WAVE_DURATION).
	if not is_endless_active:
		return 0.0
	return _wave_elapsed


func get_total_endless_time() -> float:
	## Retorna o tempo total desde que o endless foi ativado.
	if not is_endless_active:
		return 0.0
	return GameManager.game_time - endless_start_time


func should_spawn_miniboss() -> bool:
	## Retorna true se a onda atual permite spawn de mini-bosses.
	return is_endless_active and endless_wave >= ENDLESS_MINIBOSS_WAVE


func should_spawn_cross_fenda() -> bool:
	## Retorna true se deve misturar inimigos de outras fendas.
	return is_endless_active and endless_wave >= ENDLESS_CROSS_FENDA_WAVE


func should_boss_return() -> bool:
	## Retorna true se o Sentinela deve retornar fortalecido.
	return is_endless_active and endless_wave >= ENDLESS_BOSS_RETURN_WAVE


func get_classification() -> String:
	## Retorna a classificacao (rank) baseada na onda maxima alcancada.
	if endless_wave >= 20:
		return "cristal"
	elif endless_wave >= 15:
		return "diamante"
	elif endless_wave >= 10:
		return "ouro"
	elif endless_wave >= 5:
		return "prata"
	else:
		return "bronze"


# ---------------------------------------------------------------------------
# Leaderboard
# ---------------------------------------------------------------------------

func save_endless_result() -> void:
	## Salva o resultado da run endless no leaderboard persistente.
	if not is_endless_active:
		return

	var entry := {
		"character": GameManager.selected_character,
		"stage": GameManager.selected_stage,
		"total_time": GameManager.game_time,
		"endless_waves": endless_wave,
		"total_kills": GameManager.total_kills,
		"date": Time.get_datetime_string_from_system(true).left(10),
		"classification": get_classification(),
	}

	if not SaveManager.data.has("endless_leaderboard"):
		SaveManager.data["endless_leaderboard"] = []

	SaveManager.data["endless_leaderboard"].append(entry)

	# Manter apenas top 50 ordenados por ondas desc
	var lb: Array = SaveManager.data["endless_leaderboard"]
	lb.sort_custom(func(a, b): return a["endless_waves"] > b["endless_waves"])
	if lb.size() > 50:
		SaveManager.data["endless_leaderboard"] = lb.slice(0, 50)

	SaveManager.save_data()
	LogManager.info("EndlessMode", "Endless result saved: wave %d, class %s" % [endless_wave, get_classification()])


func get_endless_leaderboard() -> Array:
	## Retorna o leaderboard de endless ordenado por ondas (desc).
	if not SaveManager.data.has("endless_leaderboard"):
		return []
	var lb: Array = SaveManager.data["endless_leaderboard"].duplicate()
	lb.sort_custom(func(a, b): return a["endless_waves"] > b["endless_waves"])
	return lb


# ---------------------------------------------------------------------------
# Reset
# ---------------------------------------------------------------------------

func reset() -> void:
	## Reseta todo o estado para uma nova run.
	is_endless_active = false
	endless_wave = 0
	endless_start_time = 0.0
	boss_kill_time = 0.0
	_wave_elapsed = 0.0
	set_process(false)


# ---------------------------------------------------------------------------
# Internal
# ---------------------------------------------------------------------------

func _on_wave_advanced() -> void:
	## Chamado internamente quando uma nova onda comeca.
	LogManager.info("EndlessMode", "Wave %d started | mults: %s" % [endless_wave, str(get_endless_multipliers())])

	wave_changed.emit(endless_wave)

	# Checar achievements de endless
	if AchievementManager.has_method("check_endless"):
		AchievementManager.check_endless(endless_wave)
