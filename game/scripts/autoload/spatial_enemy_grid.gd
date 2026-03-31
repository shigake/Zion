class_name SpatialEnemyGrid
extends RefCounted

## Grid espacial para queries eficientes de inimigos por posicao.
## Usado internamente pelo GameManager — nao e autoload separado.

const CELL_SIZE: float = 3.0

var _grid: Dictionary = {}
var _grid_frame: int = -1

func rebuild(enemies: Array) -> void:
	var frame = Engine.get_process_frames()
	if frame == _grid_frame:
		return
	_grid_frame = frame
	_grid.clear()
	for e in enemies:
		if not is_instance_valid(e) or e.is_dead:
			continue
		var cell = _pos_to_cell(e.global_position)
		if not _grid.has(cell):
			_grid[cell] = []
		_grid[cell].append(e)

func get_nearby(pos: Vector3, radius: float) -> Array:
	var cell = _pos_to_cell(pos)
	var cells_to_check = int(ceil(radius / CELL_SIZE))
	var result: Array = []
	for dx in range(-cells_to_check, cells_to_check + 1):
		for dz in range(-cells_to_check, cells_to_check + 1):
			var check_cell = Vector2i(cell.x + dx, cell.y + dz)
			if _grid.has(check_cell):
				result.append_array(_grid[check_cell])
	return result

func get_in_radius(pos: Vector3, radius: float) -> Array:
	var candidates = get_nearby(pos, radius)
	var result: Array = []
	var radius_sq = radius * radius
	for e in candidates:
		if is_instance_valid(e) and not e.is_dead:
			var diff = pos - e.global_position
			diff.y = 0
			if diff.length_squared() <= radius_sq:
				result.append(e)
	return result

func _pos_to_cell(pos: Vector3) -> Vector2i:
	return Vector2i(int(floor(pos.x / CELL_SIZE)), int(floor(pos.z / CELL_SIZE)))
