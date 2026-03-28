extends Node

## Manages MultiMeshInstance3D for rendering large enemy hordes efficiently.
## When enemy count exceeds THRESHOLD, switches from individual Sprite3D nodes
## to a single MultiMesh draw call using a billboard QuadMesh with per-instance colors.
## Below THRESHOLD: individual Sprite3D per enemy (looks good, shows unique textures).
## Above THRESHOLD: MultiMesh with shared sprite texture (performance mode).

const THRESHOLD := 100  # Switch to multimesh above this count
const HYSTERESIS := 20  # Prevent flickering near threshold

var _multimesh_instance: MultiMeshInstance3D = null
var _multimesh: MultiMesh = null
var _active: bool = false
var _billboard_material: StandardMaterial3D = null
var _fallback_texture: Texture2D = null

func _ready() -> void:
	_create_billboard_material()

func _create_billboard_material() -> void:
	## Create a billboard material for the QuadMesh that:
	## - Always faces the camera (billboard mode)
	## - Uses vertex colors for per-instance tinting
	## - Renders the enemy sprite texture with alpha discard
	_billboard_material = StandardMaterial3D.new()
	_billboard_material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	_billboard_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_billboard_material.vertex_color_use_as_albedo = true
	_billboard_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	_billboard_material.alpha_scissor_threshold = 0.5
	_billboard_material.no_depth_test = false
	_billboard_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	# Load fallback sprite texture (slime) for the shared multimesh
	_fallback_texture = load("res://assets/sprites/enemies/slime.png") as Texture2D
	if _fallback_texture:
		_billboard_material.albedo_texture = _fallback_texture

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

	# Billboard QuadMesh — a flat plane that faces the camera via the material
	var quad = QuadMesh.new()
	quad.size = Vector2(1.2, 1.2)  # Roughly matches enemy sprite pixel_size * texture dimensions
	_multimesh.mesh = quad
	_multimesh.instance_count = 0

	_multimesh_instance.multimesh = _multimesh
	_multimesh_instance.name = "EnemyMultiMesh"
	_multimesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	# Apply billboard material with shared sprite texture
	if _billboard_material:
		_multimesh_instance.material_override = _billboard_material

	var scene = get_tree().current_scene
	if scene:
		scene.add_child(_multimesh_instance)

func _deactivate() -> void:
	_active = false
	# Restore individual sprite/mesh visibility before removing multimesh
	_restore_individual_visuals()
	if _multimesh_instance and is_instance_valid(_multimesh_instance):
		_multimesh_instance.queue_free()
		_multimesh_instance = null
		_multimesh = null

func _restore_individual_visuals() -> void:
	## Re-show the individual Sprite3D (EnemySprite) or ProceduralModel/Mesh nodes
	## that were hidden when multimesh took over rendering.
	var enemies = GameManager.get_enemies()
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		var sprite_node = enemy.get_node_or_null("EnemySprite")
		if sprite_node:
			sprite_node.visible = true
			continue
		var proc_model = enemy.get_node_or_null("ProceduralModel")
		if proc_model:
			proc_model.visible = true
			continue
		var mesh_node = enemy.get_node_or_null("Mesh")
		if mesh_node:
			mesh_node.visible = true

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

	# Update transforms and colors; hide individual sprites
	var valid_idx := 0
	for i in range(count):
		var enemy = enemies[i]
		if not is_instance_valid(enemy):
			continue

		# Offset the quad upward to match the EnemySprite position (y=0.65)
		var t = enemy.global_transform
		t.origin.y += 0.65
		_multimesh.set_instance_transform(valid_idx, t)

		# Per-instance color tint — uses enemy_color from EnemyBase3D
		if enemy is EnemyBase3D:
			_multimesh.set_instance_color(valid_idx, enemy.enemy_color)
		else:
			_multimesh.set_instance_color(valid_idx, Color.RED)

		# Hide individual sprite/mesh to avoid double rendering
		var sprite_node = enemy.get_node_or_null("EnemySprite")
		if sprite_node and sprite_node.visible:
			sprite_node.visible = false
		else:
			# Fallback: hide ProceduralModel or Mesh if no sprite
			var proc_model = enemy.get_node_or_null("ProceduralModel")
			if proc_model and proc_model.visible:
				proc_model.visible = false
			else:
				var mesh_node = enemy.get_node_or_null("Mesh")
				if mesh_node and mesh_node.visible:
					mesh_node.visible = false

		valid_idx += 1

	# Hide unused instances by moving them far away with zero scale
	for j in range(valid_idx, _multimesh.instance_count):
		_multimesh.set_instance_transform(j, Transform3D(Basis.IDENTITY.scaled(Vector3.ZERO), Vector3(0, -1000, 0)))

func on_scene_changed() -> void:
	_deactivate()
