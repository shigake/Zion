extends Node
class_name EnemyCuller

## Culling de inimigos distantes para otimizar performance.
## Inimigos longe de todos os jogadores sao colocados para dormir (sem IA)
## ou despawnados e devolvidos ao ObjectPool.
##
## Regras:
##   - Distancia > 60: inimigo dorme (sem _physics_process, sem animacao)
##   - Distancia > 80: inimigo despawnado e devolvido ao pool
##   - Bosses NUNCA sao culled (grupo "bosses")
##   - Processa em batches para evitar spikes de frame
##
## Uso: Adicionar como filho do EnemySpawner ou de qualquer Node na cena.
##   var culler = EnemyCuller.new()
##   add_child(culler)

# ---- Constantes ----
## Distancia ao quadrado para dormir inimigos (32^2 = 1024)
const SLEEP_DIST_SQ := 1024.0

## Distancia ao quadrado para despawnar inimigos (45^2 = 2025)
const DESPAWN_DIST_SQ := 2025.0

## Distancia ao quadrado para acordar inimigos dormindo (28^2 = 784)
## Um pouco menor que SLEEP para criar histerese e evitar oscilacao
const WAKE_DIST_SQ := 784.0

## Maximo de inimigos processados por frame
const BATCH_SIZE := 200

## Intervalo base entre checagens (segundos) — adaptativo com FPS
const CHECK_INTERVAL_BASE := 0.25
const CHECK_INTERVAL_FAST := 0.2  # Usado quando FPS < 30

# ---- Estado ----
var _timer: float = 0.0
var _batch_index: int = 0

## Inimigos atualmente dormindo (referencia -> estado anterior)
var _sleeping_enemies: Dictionary = {}
# Formato: {node_id: {node: Node, was_processing: bool}}

## Estatisticas
var _stats := {
	"sleeping": 0,
	"despawned_total": 0,
	"active": 0,
}


func _ready() -> void:
	LogManager.info("Culler", "EnemyCuller inicializado — sleep=%dm, despawn=%dm, batch=%d, adaptive_interval" % [
		int(sqrt(SLEEP_DIST_SQ)), int(sqrt(DESPAWN_DIST_SQ)), BATCH_SIZE
	])


func _process(delta: float) -> void:
	if GameManager.paused or GameManager.is_game_over:
		return

	_timer += delta
	var check_interval := CHECK_INTERVAL_BASE
	# Cull mais agressivamente quando FPS esta baixo
	if Engine.get_frames_per_second() < 30:
		check_interval = CHECK_INTERVAL_FAST
	if _timer < check_interval:
		return
	_timer = 0.0

	_process_cull_batch()


# ===========================================================================
# API Publica
# ===========================================================================

func get_stats() -> Dictionary:
	## Retorna estatisticas de culling.
	_stats.sleeping = _sleeping_enemies.size()
	return _stats.duplicate()


# ===========================================================================
# Processamento de Culling em Batches
# ===========================================================================

func _process_cull_batch() -> void:
	var tree := get_tree()
	if not tree:
		return

	var enemies := GameManager.get_enemies()
	var players := GameManager.get_players()

	if players.is_empty() or enemies.is_empty():
		return

	# Cache posicoes dos jogadores
	var player_positions: Array[Vector3] = []
	for player in players:
		if is_instance_valid(player) and player is Node3D and player.is_inside_tree():
			player_positions.append(player.global_position)

	if player_positions.is_empty():
		return

	var total := enemies.size()
	if _batch_index >= total:
		_batch_index = 0

	var count := 0
	var active_count := 0

	while count < BATCH_SIZE and count < total:
		var idx := _batch_index
		if idx >= enemies.size():
			_batch_index = 0
			break

		var enemy: Node = enemies[idx]

		if is_instance_valid(enemy) and enemy is Node3D and enemy.is_inside_tree():
			# NUNCA fazer cull de bosses
			if enemy.is_in_group("bosses"):
				_batch_index = (_batch_index + 1) % maxi(total, 1)
				count += 1
				active_count += 1
				continue

			# Verifica se inimigo esta morto
			if enemy.has_method("is_dead") or (enemy.get("is_dead") != null and enemy.is_dead):
				_batch_index = (_batch_index + 1) % maxi(total, 1)
				count += 1
				continue

			# Distancia minima ao quadrado ate qualquer jogador
			var min_dist_sq := _min_distance_sq_to_players(enemy, player_positions)

			# Decisao de culling
			var enemy_id := enemy.get_instance_id()

			if min_dist_sq > DESPAWN_DIST_SQ:
				# Muito longe — despawnar e devolver ao pool
				_despawn_enemy(enemy)
			elif min_dist_sq > SLEEP_DIST_SQ:
				# Longe — colocar para dormir
				if enemy_id not in _sleeping_enemies:
					_sleep_enemy(enemy)
			elif min_dist_sq < WAKE_DIST_SQ:
				# Perto o suficiente — acordar se dormindo
				if enemy_id in _sleeping_enemies:
					_wake_enemy(enemy)
				active_count += 1
			else:
				active_count += 1

		_batch_index = (_batch_index + 1) % maxi(total, 1)
		count += 1

	_stats.active = active_count


func _min_distance_sq_to_players(enemy: Node3D, player_positions: Array[Vector3]) -> float:
	## Calcula a menor distancia ao quadrado entre o inimigo e qualquer jogador.
	var min_sq := INF
	var enemy_pos := enemy.global_position

	for pos in player_positions:
		var dist_sq := enemy_pos.distance_squared_to(pos)
		if dist_sq < min_sq:
			min_sq = dist_sq

	return min_sq


# ===========================================================================
# Sleep / Wake / Despawn
# ===========================================================================

func _sleep_enemy(enemy: Node) -> void:
	## Coloca inimigo para dormir: desativa processamento e animacao.
	var enemy_id := enemy.get_instance_id()

	_sleeping_enemies[enemy_id] = {
		"node": enemy,
		"was_physics_processing": enemy.is_physics_processing(),
		"was_processing": enemy.is_processing(),
	}

	# Desativa processamento (sem IA, sem movimento)
	enemy.set_physics_process(false)
	enemy.set_process(false)

	# Esconde visualmente (opcional, economiza draw calls)
	if enemy is Node3D:
		enemy.visible = false

	# Desativa colisao temporariamente
	if enemy is CollisionObject3D:
		enemy.set_deferred("process_mode", Node.PROCESS_MODE_DISABLED)


func _wake_enemy(enemy: Node) -> void:
	## Acorda inimigo: restaura processamento e visibilidade.
	var enemy_id := enemy.get_instance_id()

	if enemy_id not in _sleeping_enemies:
		return

	var state: Dictionary = _sleeping_enemies[enemy_id]

	# Restaura processamento
	enemy.set_physics_process(state.was_physics_processing)
	enemy.set_process(state.was_processing)

	# Restaura visibilidade
	if enemy is Node3D:
		enemy.visible = true

	# Restaura colisao
	if enemy is CollisionObject3D:
		enemy.set_deferred("process_mode", Node.PROCESS_MODE_INHERIT)

	_sleeping_enemies.erase(enemy_id)


func _despawn_enemy(enemy: Node) -> void:
	## Remove inimigo da cena e devolve ao ObjectPool.
	var enemy_id := enemy.get_instance_id()

	# Limpa do registro de sleeping se estava dormindo
	if enemy_id in _sleeping_enemies:
		_sleeping_enemies.erase(enemy_id)

	# Restaura estado antes de devolver ao pool
	enemy.set_physics_process(true)
	enemy.set_process(true)
	if enemy is Node3D:
		enemy.visible = true
	if enemy is CollisionObject3D:
		enemy.set_deferred("process_mode", Node.PROCESS_MODE_INHERIT)

	# Atualiza contagem de inimigos vivos
	GameManager.enemies_alive = maxi(0, GameManager.enemies_alive - 1)

	# Devolve ao ObjectPool
	var scene_path := ""
	if enemy.scene_file_path and not enemy.scene_file_path.is_empty():
		scene_path = enemy.scene_file_path

	ObjectPool.return_instance(enemy, scene_path)

	_stats.despawned_total += 1


# ===========================================================================
# Limpeza
# ===========================================================================

func _exit_tree() -> void:
	## Acorda todos os inimigos dormindo ao sair da cena.
	for enemy_id in _sleeping_enemies.keys():
		var state: Dictionary = _sleeping_enemies[enemy_id]
		var enemy: Node = state.node
		if is_instance_valid(enemy):
			_wake_enemy(enemy)
	_sleeping_enemies.clear()
