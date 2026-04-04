extends Node

## Manages MultiMeshInstance3D for rendering large enemy hordes and pickups efficiently.
## When count exceeds THRESHOLD, switches from individual Sprite3D nodes
## to a single MultiMesh draw call using a billboard QuadMesh with per-instance colors.
## Below THRESHOLD: individual Sprite3D per node (looks good, shows unique textures).
## Above THRESHOLD: MultiMesh with shared sprite texture (performance mode).

# --- Enemy MultiMesh ---
const THRESHOLD := 50  # Switch to multimesh above this count (was 100)
const HYSTERESIS := 25  # Prevent flickering near threshold (was 15, increased to reduce oscillation)

var _multimesh_instance: MultiMeshInstance3D = null
var _multimesh: MultiMesh = null
var _active: bool = false
var _billboard_material: StandardMaterial3D = null
var _fallback_texture: Texture2D = null

# --- Pickup MultiMesh ---
const PICKUP_THRESHOLD := 60
const PICKUP_HYSTERESIS := 15

var _pickup_mm_instance: MultiMeshInstance3D = null
var _pickup_mm: MultiMesh = null
var _pickup_active: bool = false

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

var _pickup_check_timer: float = 0.0
const PICKUP_CHECK_INTERVAL := 0.5  # Check pickups every 0.5s instead of every frame

func _process(delta: float) -> void:
	if GameManager.paused or GameManager.is_game_over:
		return

	var enemy_count = GameManager.enemies_alive
	if enemy_count >= THRESHOLD:
		if not _active:
			_activate()
		_update_transforms()
	elif _active and enemy_count < (THRESHOLD - HYSTERESIS):
		_deactivate()

	# Pickups: check activation less frequently, update transforms every frame when active
	_pickup_check_timer += delta
	if _pickup_active:
		_process_pickups()
	elif _pickup_check_timer >= PICKUP_CHECK_INTERVAL:
		_pickup_check_timer = 0.0
		_process_pickups()

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
	# Spread over multiple frames to avoid a single-frame stutter
	_restore_individual_visuals_batched()
	if _multimesh_instance and is_instance_valid(_multimesh_instance):
		_multimesh_instance.queue_free()
		_multimesh_instance = null
		_multimesh = null

func _restore_individual_visuals_batched() -> void:
	## Re-show the individual sprites in batches to avoid frame stutter.
	## Uses enemy's cached sprite when available (EnemyBase3D._get_cached_sprite).
	var enemies = GameManager.get_enemies()
	var batch_size := 15
	var idx := 0
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		# Use the enemy's cached sprite reference if available
		if enemy is EnemyBase3D:
			var cached = enemy._get_cached_sprite()
			if cached:
				cached.visible = true
				idx += 1
				continue
		# Fallback: check nodes directly
		var sprite_node = enemy.get_node_or_null("EnemySprite")
		if sprite_node:
			sprite_node.visible = true
			idx += 1
			continue
		var proc_model = enemy.get_node_or_null("ProceduralModel")
		if proc_model:
			proc_model.visible = true
			idx += 1
			continue
		var mesh_node = enemy.get_node_or_null("Mesh")
		if mesh_node:
			mesh_node.visible = true
			idx += 1

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
	# Uses enemy's cached sprite to avoid get_node_or_null every frame per enemy
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
			# Hide individual sprite using cached reference (no get_node_or_null)
			var cached_sprite = enemy._get_cached_sprite()
			if cached_sprite:
				if cached_sprite.visible:
					cached_sprite.visible = false
			else:
				# Fallback for enemies without cached sprite
				var proc_model = enemy.get_node_or_null("ProceduralModel")
				if proc_model and proc_model.visible:
					proc_model.visible = false
				else:
					var mesh_node = enemy.get_node_or_null("Mesh")
					if mesh_node and mesh_node.visible:
						mesh_node.visible = false
		else:
			_multimesh.set_instance_color(valid_idx, Color.RED)

		valid_idx += 1

	# Hide unused instances by moving them far away with zero scale
	for j in range(valid_idx, _multimesh.instance_count):
		_multimesh.set_instance_transform(j, Transform3D(Basis.IDENTITY.scaled(Vector3.ZERO), Vector3(0, -1000, 0)))

# =============================================================================
# Pickup MultiMesh — renders XP gems + crystals as a single draw call
# =============================================================================

func _process_pickups() -> void:
	var pickups = get_tree().get_nodes_in_group("pickups")
	var count = pickups.size()

	if count >= PICKUP_THRESHOLD:
		if not _pickup_active:
			_activate_pickup_mm()
		_update_pickup_transforms(pickups)
	elif _pickup_active and count < (PICKUP_THRESHOLD - PICKUP_HYSTERESIS):
		_deactivate_pickup_mm()

func _activate_pickup_mm() -> void:
	_pickup_active = true
	if _pickup_mm_instance and is_instance_valid(_pickup_mm_instance):
		return

	_pickup_mm_instance = MultiMeshInstance3D.new()
	_pickup_mm = MultiMesh.new()
	_pickup_mm.transform_format = MultiMesh.TRANSFORM_3D
	_pickup_mm.use_colors = true

	# Use a small quad for billboard rendering
	var quad = QuadMesh.new()
	quad.size = Vector2(0.5, 0.5)
	_pickup_mm.mesh = quad
	_pickup_mm.instance_count = 0

	_pickup_mm_instance.multimesh = _pickup_mm
	_pickup_mm_instance.name = "PickupMultiMesh"
	_pickup_mm_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	# Billboard unshaded material with vertex colors
	var mat = StandardMaterial3D.new()
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	mat.alpha_scissor_threshold = 0.5
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_pickup_mm_instance.material_override = mat

	var scene = get_tree().current_scene
	if scene:
		scene.add_child(_pickup_mm_instance)

func _update_pickup_transforms(pickups: Array) -> void:
	if not _pickup_mm or not _pickup_mm_instance or not is_instance_valid(_pickup_mm_instance):
		return

	var count = pickups.size()
	if count == 0:
		if _pickup_mm.instance_count != 0:
			_pickup_mm.instance_count = 0
		return

	# Resize with headroom to reduce reallocations
	if _pickup_mm.instance_count < count or _pickup_mm.instance_count > count * 2:
		_pickup_mm.instance_count = int(count * 1.25)

	var idx := 0
	for pickup in pickups:
		if not is_instance_valid(pickup):
			continue
		# Position the quad slightly above ground
		_pickup_mm.set_instance_transform(idx, Transform3D(Basis(), pickup.global_position + Vector3(0, 0.3, 0)))
		# Color: blue for XP gems, gold for crystals
		if pickup.is_in_group("xp_gems"):
			_pickup_mm.set_instance_color(idx, Color(0.2, 0.6, 1.0))
		else:
			_pickup_mm.set_instance_color(idx, Color(1.0, 0.85, 0.2))
		# Hide individual sprite to avoid double rendering
		var sprite = pickup.get_node_or_null("PickupSprite")
		if sprite and sprite.visible:
			sprite.visible = false
		idx += 1

	# Hide unused instances by moving them far away with zero scale
	for j in range(idx, _pickup_mm.instance_count):
		_pickup_mm.set_instance_transform(j, Transform3D(Basis.IDENTITY.scaled(Vector3.ZERO), Vector3(0, -1000, 0)))

func _deactivate_pickup_mm() -> void:
	_pickup_active = false
	# Restore individual sprites
	var pickups = get_tree().get_nodes_in_group("pickups")
	for pickup in pickups:
		if not is_instance_valid(pickup):
			continue
		var sprite = pickup.get_node_or_null("PickupSprite")
		if sprite:
			sprite.visible = true
	if _pickup_mm_instance and is_instance_valid(_pickup_mm_instance):
		_pickup_mm_instance.queue_free()
		_pickup_mm_instance = null
		_pickup_mm = null

func on_scene_changed() -> void:
	_deactivate()
	_deactivate_pickup_mm()
