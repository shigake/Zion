extends Control

## Minimapa hexagonal — mostra player, inimigos, itens e aliados.
## Posicionado no canto inferior direito do HUD.

const RADIUS: float = 70.0  # Raio do hexagono em pixels
const MAP_RANGE: float = 60.0  # Distancia do mundo coberta pelo minimap (unidades 3D)
const DOT_RADIUS: float = 2.5
const PLAYER_DOT_RADIUS: float = 4.0
const BORDER_WIDTH: float = 2.0
const UPDATE_INTERVAL: float = 0.1  # Atualiza posicoes a cada 100ms

# Cores
const COLOR_BG := Color(0.05, 0.06, 0.08, 0.65)
const COLOR_BORDER := Color(0.3, 0.5, 0.7, 0.8)
const COLOR_PLAYER := Color(1.0, 1.0, 1.0, 1.0)
const COLOR_ENEMY := Color(0.9, 0.2, 0.15, 0.85)
const COLOR_ITEM := Color(1.0, 0.85, 0.1, 0.9)
const COLOR_ALLY := Color(0.2, 0.85, 0.4, 0.9)
const COLOR_BOSS := Color(1.0, 0.1, 0.5, 1.0)
const COLOR_BOUNDARY := Color(0.4, 0.5, 0.6, 0.3)

var _hex_points: PackedVector2Array = PackedVector2Array()
var _update_timer: float = 0.0

# Cached positions (mundo -> minimap)
var _enemy_dots: PackedVector2Array = PackedVector2Array()
var _item_dots: PackedVector2Array = PackedVector2Array()
var _ally_dots: PackedVector2Array = PackedVector2Array()
var _boss_dots: PackedVector2Array = PackedVector2Array()

func _ready() -> void:
	# Gera os 6 pontos do hexagono (flat-top)
	_hex_points.clear()
	for i in 6:
		var angle = deg_to_rad(60.0 * i - 30.0)  # Flat-top: começa -30 graus
		_hex_points.append(Vector2(cos(angle), sin(angle)) * RADIUS)

	# Tamanho do control
	custom_minimum_size = Vector2(RADIUS * 2 + 10, RADIUS * 2 + 10)
	size = custom_minimum_size
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(delta: float) -> void:
	_update_timer += delta
	if _update_timer >= UPDATE_INTERVAL:
		_update_timer = 0.0
		_refresh_dots()
		queue_redraw()

func _refresh_dots() -> void:
	var player = _get_local_player()
	if not player:
		return

	var player_pos = player.global_position
	_enemy_dots.clear()
	_item_dots.clear()
	_ally_dots.clear()
	_boss_dots.clear()

	# Inimigos
	var enemies = GameManager.get_enemies()
	for e in enemies:
		if not is_instance_valid(e):
			continue
		var dot = _world_to_minimap(e.global_position, player_pos)
		if dot != Vector2.INF:
			_enemy_dots.append(dot)

	# Bosses
	var bosses = get_tree().get_nodes_in_group("boss")
	for b in bosses:
		if not is_instance_valid(b):
			continue
		var dot = _world_to_minimap(b.global_position, player_pos)
		if dot != Vector2.INF:
			_boss_dots.append(dot)

	# Pickups / itens no chao
	var pickups = get_tree().get_nodes_in_group("pickups")
	for p in pickups:
		if not is_instance_valid(p):
			continue
		var dot = _world_to_minimap(p.global_position, player_pos)
		if dot != Vector2.INF:
			_item_dots.append(dot)

	# XP gems
	var xp_gems = get_tree().get_nodes_in_group("xp_gems")
	for g in xp_gems:
		if not is_instance_valid(g):
			continue
		var dot = _world_to_minimap(g.global_position, player_pos)
		if dot != Vector2.INF:
			_item_dots.append(dot)

	# Aliados (multiplayer)
	if MultiplayerManager.is_online:
		var players = GameManager.get_players()
		for p in players:
			if not is_instance_valid(p) or p == player:
				continue
			var dot = _world_to_minimap(p.global_position, player_pos)
			if dot != Vector2.INF:
				_ally_dots.append(dot)

func _world_to_minimap(world_pos: Vector3, player_pos: Vector3) -> Vector2:
	# Offset relativo ao jogador (X, Z do mundo -> X, Y do minimap)
	var dx = world_pos.x - player_pos.x
	var dz = world_pos.z - player_pos.z

	# Normaliza para o raio do minimap
	var nx = (dx / MAP_RANGE) * RADIUS
	var ny = (dz / MAP_RANGE) * RADIUS

	var point = Vector2(nx, ny)

	# Verifica se esta dentro do hexagono
	if not _is_inside_hexagon(point):
		return Vector2.INF

	return point

func _is_inside_hexagon(point: Vector2) -> bool:
	# Teste ponto-em-poligono usando cross products
	var n = _hex_points.size()
	for i in n:
		var a = _hex_points[i]
		var b = _hex_points[(i + 1) % n]
		var edge = b - a
		var to_point = point - a
		if edge.cross(to_point) < 0:
			return false
	return true

func _draw() -> void:
	var center = size / 2.0

	# Fundo do hexagono
	var hex_global = PackedVector2Array()
	for p in _hex_points:
		hex_global.append(center + p)
	draw_colored_polygon(hex_global, COLOR_BG)

	# Borda do hexagono
	for i in _hex_points.size():
		var a = center + _hex_points[i]
		var b = center + _hex_points[(i + 1) % _hex_points.size()]
		draw_line(a, b, COLOR_BORDER, BORDER_WIDTH, true)

	# Linhas de grid sutis (cruz no centro)
	draw_line(center + Vector2(-RADIUS * 0.5, 0), center + Vector2(RADIUS * 0.5, 0), COLOR_BOUNDARY, 1.0)
	draw_line(center + Vector2(0, -RADIUS * 0.5), center + Vector2(0, RADIUS * 0.5), COLOR_BOUNDARY, 1.0)

	# Indicador de limite do mapa
	var half = GameManager.map_half_size
	var map_scale = RADIUS / MAP_RANGE
	var player = _get_local_player()
	if player:
		var px = player.global_position.x
		var pz = player.global_position.z
		# Desenha bordas do mapa que estao dentro do range do minimap
		_draw_map_boundary_line(center, px, pz, map_scale, -half, -half, half, -half)  # Top
		_draw_map_boundary_line(center, px, pz, map_scale, half, -half, half, half)    # Right
		_draw_map_boundary_line(center, px, pz, map_scale, -half, half, half, half)    # Bottom
		_draw_map_boundary_line(center, px, pz, map_scale, -half, -half, -half, half)  # Left

	# Dots: inimigos
	for dot in _enemy_dots:
		draw_circle(center + dot, DOT_RADIUS, COLOR_ENEMY)

	# Dots: bosses (maiores, pulsantes)
	for dot in _boss_dots:
		draw_circle(center + dot, DOT_RADIUS * 2.0, COLOR_BOSS)

	# Dots: itens
	for dot in _item_dots:
		draw_circle(center + dot, DOT_RADIUS * 0.8, COLOR_ITEM)

	# Dots: aliados
	for dot in _ally_dots:
		draw_circle(center + dot, DOT_RADIUS * 1.3, COLOR_ALLY)

	# Player no centro (sempre)
	draw_circle(center, PLAYER_DOT_RADIUS, COLOR_PLAYER)
	# Borda do player dot
	_draw_circle_outline(center, PLAYER_DOT_RADIUS + 1.0, Color(0.3, 0.5, 0.8, 0.6), 1.5)

func _draw_map_boundary_line(center: Vector2, px: float, pz: float, scale: float, x1: float, z1: float, x2: float, z2: float) -> void:
	var a = Vector2((x1 - px) * scale, (z1 - pz) * scale)
	var b = Vector2((x2 - px) * scale, (z2 - pz) * scale)

	# Clipa ao hexagono (simplificado: so desenha se pelo menos um ponto esta perto)
	if a.length() > RADIUS * 1.5 and b.length() > RADIUS * 1.5:
		return

	# Clamp ao raio
	if a.length() > RADIUS:
		a = a.normalized() * RADIUS
	if b.length() > RADIUS:
		b = b.normalized() * RADIUS

	draw_line(center + a, center + b, COLOR_BORDER.lerp(Color.RED, 0.3), 1.5)

func _draw_circle_outline(center_pos: Vector2, radius: float, color: Color, width: float) -> void:
	var points = 24
	for i in points:
		var angle_a = TAU * i / points
		var angle_b = TAU * (i + 1) / points
		var a = center_pos + Vector2(cos(angle_a), sin(angle_a)) * radius
		var b = center_pos + Vector2(cos(angle_b), sin(angle_b)) * radius
		draw_line(a, b, color, width)

func _get_local_player() -> Node3D:
	var players = GameManager.get_players()
	for p in players:
		if is_instance_valid(p) and "is_local" in p and p.is_local:
			return p
	# Fallback: primeiro player
	if not players.is_empty() and is_instance_valid(players[0]):
		return players[0]
	return null
