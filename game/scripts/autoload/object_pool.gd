extends Node

## Object Pool para reutilizar inimigos e projeteis.
## Evita alocacoes durante gameplay, melhorando performance com 1000+ entidades.

var _pools: Dictionary = {}  # scene_path -> Array[Node]
var _active: Dictionary = {}  # scene_path -> int (count of active instances)

## Pre-warm the pool by instantiating `count` copies of a scene ahead of time.
## Call during loading screens or _ready() to avoid first-spawn stutters.
func prewarm(scene: PackedScene, count: int) -> void:
	var path = scene.resource_path
	if path not in _pools:
		_pools[path] = []
		_active[path] = 0
	var pool: Array = _pools[path]
	for _i in range(count):
		var instance = scene.instantiate()
		# Disable processing so pre-warmed instances don't run logic
		instance.set_process(false)
		instance.set_physics_process(false)
		pool.append(instance)

func get_instance(scene: PackedScene) -> Node:
	var path = scene.resource_path
	if path not in _pools:
		_pools[path] = []
		_active[path] = 0

	# Try to reuse from pool
	var pool: Array = _pools[path]
	while not pool.is_empty():
		var instance = pool.pop_back()
		if is_instance_valid(instance):
			# Ensure it's not still in the scene tree
			if instance.get_parent():
				instance.get_parent().remove_child(instance)
			# Reset for reuse if method exists
			if instance.has_method("_reset_for_reuse"):
				instance._reset_for_reuse()
			_active[path] += 1
			return instance

	# Create new instance
	var instance = scene.instantiate()
	_active[path] += 1
	return instance

func return_instance(instance: Node, scene_path: String = "") -> void:
	if not is_instance_valid(instance):
		return

	# Remove from scene tree
	if instance.get_parent():
		instance.get_parent().remove_child(instance)

	# Determine pool key
	var path = scene_path
	if path.is_empty() and instance.scene_file_path:
		path = instance.scene_file_path

	if path.is_empty():
		# Can't pool without a key, just free it
		instance.queue_free()
		return

	if path not in _pools:
		_pools[path] = []
		_active[path] = 0

	_active[path] = maxi(0, _active[path] - 1)
	_pools[path].append(instance)

func clear_all() -> void:
	for path in _pools:
		for instance in _pools[path]:
			if is_instance_valid(instance):
				instance.queue_free()
	_pools.clear()
	_active.clear()

func get_stats() -> Dictionary:
	var stats = {}
	for path in _pools:
		var name = path.get_file()
		stats[name] = {"pooled": _pools[path].size(), "active": _active.get(path, 0)}
	return stats
