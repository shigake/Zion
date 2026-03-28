extends Node

## Manages MultiMeshInstance3D for rendering large enemy hordes efficiently.
## When enemy count exceeds THRESHOLD, switches to MultiMesh rendering
## using a cel-shaded sphere mesh for visual consistency.

const THRESHOLD := 200  # Switch to multimesh above this count
const HYSTERESIS := 20  # Prevent flickering near threshold

var _multimesh_instance: MultiMeshInstance3D = null
var _multimesh: MultiMesh = null
var _active: bool = false
var _cel_material: ShaderMaterial = null
var _hidden_meshes: Array[Dictionary] = []  # Track hidden meshes for restoration

func _ready() -> void:
	_create_cel_material()

func _create_cel_material() -> void:
	var shader = load("res://assets/materials/cel_shader.gdshader")
	if shader:
		_cel_material = ShaderMaterial.new()
		_cel_material.shader = shader
		_cel_material.set_shader_parameter("albedo_color", Color(0.8, 0.2, 0.2))
		_cel_material.set_shader_parameter("toon_steps", 3.0)
		_cel_material.set_shader_parameter("shadow_color", Color(0.15, 0.1, 0.2))
		_cel_material.set_shader_parameter("rim_amount", 0.4)
		_cel_material.set_shader_parameter("rim_color", Color(1.0, 1.0, 1.0, 0.6))
		_cel_material.set_shader_parameter("rim_threshold", 0.5)
	else:
		# Fallback: standard toon material
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(0.8, 0.2, 0.2)
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX
		_cel_material = null

func _process(_delta: float) -> void:
	if GameManager.paused or GameManager.is_game_over:
		return

	var enemy_count = GameManager.enemies_alive
	if enemy_count >= THRESHOLD:
		if not _active:
			_activate()
		_update_transforms()
	elif _active and enemy_count < (THRESHOLD - HYSTERESIS):
		_deactivate()

func _activate() -> void:
	_active = true
	if _multimesh_instance and is_instance_valid(_multimesh_instance):
		return

	_multimesh_instance = MultiMeshInstance3D.new()
	_multimesh = MultiMesh.new()
	_multimesh.transform_format = MultiMesh.TRANSFORM_3D
	_multimesh.use_colors = true

	# Sphere mesh as stand-in for all enemies
	var sphere = SphereMesh.new()
	sphere.radius = 0.4
	sphere.height = 0.8
	sphere.radial_segments = 8
	sphere.rings = 4
	_multimesh.mesh = sphere
	_multimesh.instance_count = 0

	_multimesh_instance.multimesh = _multimesh
	_multimesh_instance.name = "EnemyMultiMesh"
	_multimesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	# Apply cel-shader material for visual consistency
	if _cel_material:
		_multimesh_instance.material_override = _cel_material

	var scene = get_tree().current_scene
	if scene:
		scene.add_child(_multimesh_instance)
	_hidden_meshes.clear()

func _deactivate() -> void:
	_active = false
	# Restore individual mesh visibility before removing multimesh
	_restore_individual_meshes()
	if _multimesh_instance and is_instance_valid(_multimesh_instance):
		_multimesh_instance.queue_free()
		_multimesh_instance = null
		_multimesh = null
	_hidden_meshes.clear()

func _restore_individual_meshes() -> void:
	var enemies = GameManager.get_enemies()
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		var mesh_node = enemy.get_node_or_null("Mesh")
		if mesh_node:
			mesh_node.visible = true
		var proc_model = enemy.get_node_or_null("ProceduralModel")
		if proc_model:
			proc_model.visible = true

func _update_transforms() -> void:
	if not _multimesh or not _multimesh_instance or not is_instance_valid(_multimesh_instance):
		return

	var enemies = GameManager.get_enemies()
	var count = enemies.size()
	if count == 0:
		if _multimesh.instance_count != 0:
			_multimesh.instance_count = 0
		return

	# Resize multimesh if needed (batch resize to avoid frequent reallocs)
	var needed = count
	if _multimesh.instance_count < needed or _multimesh.instance_count > needed * 2:
		# Allocate with some headroom to reduce reallocations
		_multimesh.instance_count = int(needed * 1.25)

	# Update transforms and colors; hide individual meshes
	var valid_idx := 0
	for i in range(count):
		var enemy = enemies[i]
		if not is_instance_valid(enemy):
			continue

		_multimesh.set_instance_transform(valid_idx, enemy.global_transform)

		if enemy is EnemyBase3D:
			_multimesh.set_instance_color(valid_idx, enemy.enemy_color)
		else:
			_multimesh.set_instance_color(valid_idx, Color.RED)

		# Hide individual mesh to avoid double rendering
		var mesh_node = enemy.get_node_or_null("Mesh")
		if mesh_node and mesh_node.visible:
			mesh_node.visible = false
		var proc_model = enemy.get_node_or_null("ProceduralModel")
		if proc_model and proc_model.visible:
			proc_model.visible = false

		valid_idx += 1

	# Hide unused instances by scaling them to zero
	for j in range(valid_idx, _multimesh.instance_count):
		_multimesh.set_instance_transform(j, Transform3D(Basis.IDENTITY.scaled(Vector3.ZERO), Vector3(0, -1000, 0)))

func on_scene_changed() -> void:
	_deactivate()
