extends Node
class_name PerfMonitorClass

## Monitor de performance com auto-ajuste de qualidade.
## Rastreia FPS, frame time, contagem de inimigos, particulas, draw calls e memoria.
## Quando FPS cai abaixo de 30, reduz qualidade automaticamente.
##
## Uso:
##   PerfMonitor.get_perf_report() -> Dictionary
##   PerfMonitor.performance_warning.connect(func(metric, value): ...)
##   PerfMonitor.set_auto_adjust(true)

# ---- Sinais ----
signal performance_warning(metric: String, value: float)
signal quality_adjusted(new_level: int)  # 0=max, 1=medium, 2=low, 3=potato

# ---- Constantes ----
## Tamanho da janela para media movel
const MOVING_AVG_WINDOW := 60

## Limites de FPS para ajuste automatico
const FPS_CRITICAL := 20.0
const FPS_LOW := 30.0
const FPS_GOOD := 50.0

## Intervalo entre checagens de auto-ajuste (segundos)
const ADJUST_INTERVAL := 3.0

## Tempo minimo entre mudancas de qualidade (evita oscilar)
const ADJUST_COOLDOWN := 10.0

## Limites para avisos
const WARN_FRAME_TIME_MS := 33.3  # abaixo de 30 FPS
const WARN_ENEMY_COUNT := 400
const WARN_DRAW_CALLS := 2000
const WARN_MEMORY_MB := 1024.0

# ---- Estado ----
## Historico para media movel
var _fps_history: Array[float] = []
var _frame_time_history: Array[float] = []

## Metricas atuais
var current_fps: float = 60.0
var current_frame_time_ms: float = 16.6
var current_enemy_count: int = 0
var current_particle_count: int = 0
var current_draw_calls: int = 0
var current_memory_mb: float = 0.0
var current_objects: int = 0

## Medias moveis
var avg_fps: float = 60.0
var avg_frame_time_ms: float = 16.6

## Nivel de qualidade atual (0=max, 1=medium, 2=low, 3=potato)
var quality_level: int = 0

## Auto-ajuste
var auto_adjust_enabled: bool = true
var _adjust_timer: float = 0.0
var _last_adjust_time: float = 0.0
var _game_elapsed: float = 0.0

## Registro de avisos emitidos (evita spam)
var _warned_metrics: Dictionary = {}
const WARN_COOLDOWN := 30.0  # segundos entre avisos do mesmo tipo


func _ready() -> void:
	LogManager.info("Perf", "PerfMonitor inicializado — auto_adjust=%s" % str(auto_adjust_enabled))


func _process(delta: float) -> void:
	_game_elapsed += delta

	# Coleta metricas a cada frame
	_collect_metrics(delta)

	# Atualiza medias moveis
	_update_moving_averages()

	# Checagem periodica de auto-ajuste
	_adjust_timer += delta
	if _adjust_timer >= ADJUST_INTERVAL:
		_adjust_timer = 0.0
		_check_warnings()
		if auto_adjust_enabled:
			_auto_adjust_quality()


# ===========================================================================
# API Publica
# ===========================================================================

func get_perf_report() -> Dictionary:
	## Retorna relatorio completo de performance para debug overlay.
	var lod_stats := {}
	if has_node("/root/LODManager"):
		lod_stats = get_node("/root/LODManager").get_stats()

	return {
		"fps": snappedf(current_fps, 0.1),
		"avg_fps": snappedf(avg_fps, 0.1),
		"frame_time_ms": snappedf(current_frame_time_ms, 0.01),
		"avg_frame_time_ms": snappedf(avg_frame_time_ms, 0.01),
		"enemy_count": current_enemy_count,
		"particle_count": current_particle_count,
		"draw_calls": current_draw_calls,
		"memory_mb": snappedf(current_memory_mb, 0.1),
		"objects": current_objects,
		"quality_level": quality_level,
		"quality_name": _quality_name(quality_level),
		"auto_adjust": auto_adjust_enabled,
		"lod": lod_stats,
	}


func get_perf_summary() -> String:
	## Retorna resumo de uma linha para HUD.
	return "FPS: %d (avg: %d) | Q: %s | Enemies: %d | Mem: %.0fMB" % [
		int(current_fps),
		int(avg_fps),
		_quality_name(quality_level),
		current_enemy_count,
		current_memory_mb,
	]


func set_auto_adjust(enabled: bool) -> void:
	auto_adjust_enabled = enabled
	LogManager.info("Perf", "Auto-ajuste de qualidade: %s" % ("ativado" if enabled else "desativado"))


func set_quality_level(level: int) -> void:
	## Define nivel de qualidade manualmente (0-3).
	level = clampi(level, 0, 3)
	if level != quality_level:
		quality_level = level
		_apply_quality_settings(level)
		quality_adjusted.emit(level)
		LogManager.info("Perf", "Qualidade definida manualmente: %s (nivel %d)" % [_quality_name(level), level])


func reset_quality() -> void:
	## Reseta qualidade para maximo.
	set_quality_level(0)


# ===========================================================================
# Coleta de Metricas
# ===========================================================================

func _collect_metrics(_delta: float) -> void:
	# FPS e frame time
	current_fps = Engine.get_frames_per_second()
	current_frame_time_ms = 1000.0 / maxf(current_fps, 1.0)

	# Contagem de inimigos
	current_enemy_count = GameManager.enemies_alive

	# Contagem de particulas (GPUParticles3D ativas na cena)
	current_particle_count = _count_active_particles()

	# Draw calls via Performance monitor do Godot
	current_draw_calls = int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))

	# Memoria
	current_memory_mb = Performance.get_monitor(Performance.MEMORY_STATIC) / (1024.0 * 1024.0)

	# Objetos na cena
	current_objects = int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))


func _count_active_particles() -> int:
	## Conta particulas ativas na arvore de cena.
	var count := 0
	var tree := get_tree()
	if not tree:
		return 0

	for node in tree.get_nodes_in_group("particles"):
		if node is GPUParticles3D and node.emitting:
			count += 1
		elif node is CPUParticles3D and node.emitting:
			count += 1

	# Se nao ha grupo "particles", usa contagem do Performance
	if count == 0:
		count = int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)) / 100  # estimativa
		count = clampi(count, 0, 9999)

	return count


# ===========================================================================
# Media Movel
# ===========================================================================

func _update_moving_averages() -> void:
	_fps_history.append(current_fps)
	_frame_time_history.append(current_frame_time_ms)

	# Manter tamanho da janela
	while _fps_history.size() > MOVING_AVG_WINDOW:
		_fps_history.remove_at(0)
	while _frame_time_history.size() > MOVING_AVG_WINDOW:
		_frame_time_history.remove_at(0)

	# Calcular medias
	if _fps_history.size() > 0:
		var fps_sum := 0.0
		for v in _fps_history:
			fps_sum += v
		avg_fps = fps_sum / _fps_history.size()

	if _frame_time_history.size() > 0:
		var ft_sum := 0.0
		for v in _frame_time_history:
			ft_sum += v
		avg_frame_time_ms = ft_sum / _frame_time_history.size()


# ===========================================================================
# Avisos de Performance
# ===========================================================================

func _check_warnings() -> void:
	## Emite sinais de aviso quando metricas excedem limites.
	if avg_fps < FPS_LOW:
		_emit_warning("fps", avg_fps)

	if avg_frame_time_ms > WARN_FRAME_TIME_MS:
		_emit_warning("frame_time", avg_frame_time_ms)

	if current_enemy_count > WARN_ENEMY_COUNT:
		_emit_warning("enemy_count", float(current_enemy_count))

	if current_draw_calls > WARN_DRAW_CALLS:
		_emit_warning("draw_calls", float(current_draw_calls))

	if current_memory_mb > WARN_MEMORY_MB:
		_emit_warning("memory", current_memory_mb)


func _emit_warning(metric: String, value: float) -> void:
	## Emite aviso com cooldown para evitar spam.
	var now := _game_elapsed
	if metric in _warned_metrics:
		if now - _warned_metrics[metric] < WARN_COOLDOWN:
			return

	_warned_metrics[metric] = now
	performance_warning.emit(metric, value)
	LogManager.warn("Perf", "Performance warning: %s = %.1f" % [metric, value])


# ===========================================================================
# Auto-Ajuste de Qualidade
# ===========================================================================

func _auto_adjust_quality() -> void:
	## Ajusta qualidade automaticamente baseado no FPS medio.
	## Usa cooldown para evitar oscilacao rapida.
	var now := _game_elapsed
	if now - _last_adjust_time < ADJUST_COOLDOWN:
		return

	# Precisa de dados suficientes
	if _fps_history.size() < MOVING_AVG_WINDOW / 2:
		return

	var new_level := quality_level

	if avg_fps < FPS_CRITICAL:
		# FPS critico — reduzir ao maximo
		new_level = mini(quality_level + 2, 3)
	elif avg_fps < FPS_LOW:
		# FPS baixo — reduzir um nivel
		new_level = mini(quality_level + 1, 3)
	elif avg_fps > FPS_GOOD and quality_level > 0:
		# FPS bom — tentar restaurar qualidade (um nivel por vez)
		new_level = quality_level - 1

	if new_level != quality_level:
		_last_adjust_time = now
		quality_level = new_level
		_apply_quality_settings(new_level)
		quality_adjusted.emit(new_level)
		LogManager.info("Perf", "Auto-ajuste: qualidade -> %s (nivel %d, avg_fps=%.1f)" % [
			_quality_name(new_level), new_level, avg_fps
		])


func _apply_quality_settings(level: int) -> void:
	## Aplica configuracoes de qualidade ao jogo.
	match level:
		0:  # Maximo
			_set_particle_budget(1.0)
			_set_lod_multiplier(1.0)
			_set_shadow_quality(true)
			_set_msaa(true)
		1:  # Medio
			_set_particle_budget(0.7)
			_set_lod_multiplier(0.7)  # LODs mais proximos
			_set_shadow_quality(true)
			_set_msaa(false)
		2:  # Baixo
			_set_particle_budget(0.4)
			_set_lod_multiplier(0.5)
			_set_shadow_quality(false)
			_set_msaa(false)
		3:  # Potato
			_set_particle_budget(0.1)
			_set_lod_multiplier(0.3)
			_set_shadow_quality(false)
			_set_msaa(false)


func _set_particle_budget(multiplier: float) -> void:
	## Reduz quantidade de particulas globalmente.
	## Usa grupos para encontrar emissores registrados.
	var tree := get_tree()
	if not tree:
		return

	for node in tree.get_nodes_in_group("particles"):
		if node is GPUParticles3D:
			# Reduz amount baseado no multiplicador
			if node.has_meta("original_amount"):
				node.amount = int(node.get_meta("original_amount") * multiplier)
			else:
				node.set_meta("original_amount", node.amount)
				node.amount = int(node.amount * multiplier)
			node.amount = maxi(node.amount, 1)


func _set_lod_multiplier(multiplier: float) -> void:
	## Ajusta multiplicador de distancia do LODManager.
	## Multiplicador < 1.0 = LODs trocam mais perto (mais agressivo).
	if has_node("/root/LODManager"):
		var lod_mgr = get_node("/root/LODManager")
		# Invertemos: multiplier menor = mais agressivo = distancias menores
		lod_mgr.lod_distance_multiplier = multiplier


func _set_shadow_quality(enabled: bool) -> void:
	## Ativa/desativa sombras direcionais.
	var viewport := get_viewport()
	if viewport:
		if enabled:
			viewport.positional_shadow_atlas_size = 4096
		else:
			viewport.positional_shadow_atlas_size = 1024


func _set_msaa(enabled: bool) -> void:
	## Ativa/desativa MSAA.
	var viewport := get_viewport()
	if viewport:
		if enabled:
			viewport.msaa_3d = Viewport.MSAA_2X
		else:
			viewport.msaa_3d = Viewport.MSAA_DISABLED


func _quality_name(level: int) -> String:
	match level:
		0: return "Maximo"
		1: return "Medio"
		2: return "Baixo"
		3: return "Potato"
		_: return "Desconhecido"
