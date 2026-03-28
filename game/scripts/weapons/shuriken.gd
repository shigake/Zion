extends Node3D

## Shuriken — dispara projeteis em 4 (ou 8) direcoes simultaneamente.
## Visual: estrela ninja giratoria com brilho azul (gelo).

var attack_timer: float = 0.0
var projectile_scene: PackedScene = preload("res://scenes/weapons/bullet.tscn")

# Cached shuriken material (shared across all projectiles)
var _shuriken_mat: StandardMaterial3D = null

var directions_4: Array[Vector3] = [
	Vector3(0, 0, -1),   # up (north)
	Vector3(0, 0, 1),    # down (south)
	Vector3(-1, 0, 0),   # left (west)
	Vector3(1, 0, 0),    # right (east)
]

var directions_8: Array[Vector3] = [
	Vector3(0, 0, -1),          # up
	Vector3(0, 0, 1),           # down
	Vector3(-1, 0, 0),          # left
	Vector3(1, 0, 0),           # right
	Vector3(-0.707, 0, -0.707), # up-left
	Vector3(0.707, 0, -0.707),  # up-right
	Vector3(-0.707, 0, 0.707),  # down-left
	Vector3(0.707, 0, 0.707),   # down-right
]

func _ready() -> void:
	# Pre-build the shuriken material (dark metal + ice emission)
	_shuriken_mat = StandardMaterial3D.new()
	_shuriken_mat.albedo_color = Color(0.25, 0.25, 0.3)
	_shuriken_mat.metallic = 0.9
	_shuriken_mat.roughness = 0.2
	_shuriken_mat.emission_enabled = true
	_shuriken_mat.emission = Color(0.3, 0.7, 1.0)
	_shuriken_mat.emission_energy_multiplier = 0.8

func _process(delta: float) -> void:
	if not is_inside_tree():
		return
	if GameManager.paused or GameManager.is_game_over:
		return

	var level = GameManager.get_weapon_level("shuriken")
	if level <= 0:
		return

	var cooldown = WeaponDB.get_cooldown("shuriken", level) / GameManager.attack_speed_mult * GameManager.cooldown_mult

	attack_timer -= delta
	if attack_timer <= 0:
		attack_timer = cooldown
		_fire(level)

func _get_player_node() -> Node3D:
	var candidate = get_parent().get_parent() if get_parent() else null
	if candidate is CharacterBody3D:
		return candidate
	return null

func _fire(level: int) -> void:
	if not is_inside_tree():
		return

	# In multiplayer, only host fires real projectiles
	if MultiplayerManager.is_online and not multiplayer.is_server():
		_fire_visual_only(level)
		return

	var player = _get_player_node()
	if not player:
		return
	var player_pos = player.global_position

	# At level 4+, fire in 8 directions instead of 4
	var dirs: Array[Vector3] = directions_4 if level < 4 else directions_8

	var dmg = int(WeaponDB.get_damage("shuriken", level))
	var speed = 18.0 + (level - 1) * 1.0

	var scene_root = get_tree().current_scene
	if not is_instance_valid(scene_root):
		return

	for dir in dirs:
		var bullet = ObjectPool.get_instance(projectile_scene)
		var pos = player_pos + Vector3(0, 0.5, 0)
		bullet.direction = dir.normalized()
		bullet.damage = dmg
		bullet.speed = speed
		bullet.lifetime = 2.5
		bullet.damage_type = "ice"
		bullet.weapon_id = "shuriken"
		_apply_shuriken_mesh(bullet)
		bullet.position = pos
		scene_root.add_child(bullet)

## Client-only: spawns visual shurikens without collision (no damage).
func _fire_visual_only(level: int) -> void:
	var player = _get_player_node()
	if not player:
		return
	var player_pos = player.global_position
	var dirs: Array[Vector3] = directions_4 if level < 4 else directions_8
	var speed = 18.0 + (level - 1) * 1.0

	var scene_root = get_tree().current_scene
	if not is_instance_valid(scene_root):
		return

	for dir in dirs:
		var proj = ObjectPool.get_instance(projectile_scene)
		var pos = player_pos + Vector3(0, 0.5, 0)
		proj.direction = dir.normalized()
		proj.damage = 0
		proj.speed = speed
		proj.lifetime = 2.5
		# Disable collision for visual-only projectile
		proj.collision_layer = 0
		proj.collision_mask = 0
		proj.set_deferred("monitorable", false)
		proj.set_deferred("monitoring", false)
		_apply_shuriken_mesh(proj)
		proj.position = pos
		scene_root.add_child(proj)

func _apply_shuriken_mesh(bullet: Node) -> void:
	## Replace bullet's default mesh with a billboard sprite or spinning ninja-star shape.
	# Try billboard sprite first
	var sprite_path = "res://assets/sprites/projectiles/shuriken_projectile.png"
	if ResourceLoader.exists(sprite_path):
		var existing_mesh = bullet.get_node_or_null("Mesh")
		if not existing_mesh:
			existing_mesh = bullet.get_node_or_null("MeshInstance3D")
		if existing_mesh:
			existing_mesh.visible = false
		# Check if already has sprite (reused from pool)
		var existing_sprite = bullet.get_node_or_null("ProjectileSprite")
		if existing_sprite:
			existing_sprite.visible = true
			return
		var sprite = Sprite3D.new()
		sprite.texture = load(sprite_path)
		sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		sprite.pixel_size = 0.02
		sprite.shaded = false
		sprite.transparent = true
		sprite.name = "ProjectileSprite"
		bullet.add_child(sprite)
		return

	# Fallback: procedural mesh
	var mesh_node = bullet.get_node_or_null("Mesh")
	if not mesh_node:
		mesh_node = bullet.get_node_or_null("MeshInstance3D")
	if not mesh_node:
		return

	# Check if already converted (reused from pool)
	if mesh_node.has_meta("shuriken_star"):
		return

	# Hide the original mesh
	mesh_node.mesh = null
	mesh_node.rotation = Vector3.ZERO
	mesh_node.set_meta("shuriken_star", true)

	# Create a spinning container node
	var spin_node = Node3D.new()
	spin_node.name = "ShurikenSpin"
	spin_node.set_script(_ShurikenSpinScript)
	mesh_node.add_child(spin_node)

	# 4 thin blades at 0, 45, 90, 135 degrees forming a proper 4-point star
	var blade_angles := [0.0, 45.0, 90.0, 135.0]
	for angle in blade_angles:
		var blade_mesh = BoxMesh.new()
		blade_mesh.size = Vector3(0.22, 0.008, 0.04)  # long, very thin, narrow
		var blade = MeshInstance3D.new()
		blade.mesh = blade_mesh
		blade.material_override = _shuriken_mat
		blade.rotation.y = deg_to_rad(angle)
		spin_node.add_child(blade)

	# Center hub — small metallic sphere
	var hub_mesh = SphereMesh.new()
	hub_mesh.radius = 0.02
	hub_mesh.height = 0.04
	var hub = MeshInstance3D.new()
	hub.mesh = hub_mesh
	hub.material_override = _shuriken_mat
	spin_node.add_child(hub)

# Inline spin script for the shuriken star
var _ShurikenSpinScript: GDScript = null

func _init() -> void:
	_ShurikenSpinScript = GDScript.new()
	_ShurikenSpinScript.source_code = """extends Node3D
func _process(delta: float) -> void:
	rotation.y += 20.0 * delta
"""
	_ShurikenSpinScript.reload()
