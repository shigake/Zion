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
	_shuriken_mat.emission = Color(0.3, 0.6, 1.0)
	_shuriken_mat.emission_energy_multiplier = 0.5

func _process(delta: float) -> void:
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

func _fire(level: int) -> void:
	var player_pos = get_parent().get_parent().global_position

	# At level 4+, fire in 8 directions instead of 4
	var dirs: Array[Vector3] = directions_4 if level < 4 else directions_8

	var dmg = int(WeaponDB.get_damage("shuriken", level))
	var speed = 18.0 + (level - 1) * 1.0

	for dir in dirs:
		var bullet = ObjectPool.get_instance(projectile_scene)
		bullet.global_position = player_pos + Vector3(0, 0.5, 0)
		bullet.direction = dir.normalized()
		bullet.damage = dmg
		bullet.speed = speed
		bullet.lifetime = 2.5
		bullet.damage_type = "ice"
		_apply_shuriken_mesh(bullet)
		get_tree().current_scene.call_deferred("add_child", bullet)

func _apply_shuriken_mesh(bullet: Node) -> void:
	## Replace bullet's default mesh with a spinning ninja-star shape.
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

	# Blade 1 — horizontal bar
	var blade1_mesh = BoxMesh.new()
	blade1_mesh.size = Vector3(0.01, 0.15, 0.05)
	var blade1 = MeshInstance3D.new()
	blade1.mesh = blade1_mesh
	blade1.material_override = _shuriken_mat
	spin_node.add_child(blade1)

	# Blade 2 — vertical bar (crossed)
	var blade2_mesh = BoxMesh.new()
	blade2_mesh.size = Vector3(0.01, 0.05, 0.15)
	var blade2 = MeshInstance3D.new()
	blade2.mesh = blade2_mesh
	blade2.material_override = _shuriken_mat
	spin_node.add_child(blade2)

# Inline spin script for the shuriken star
var _ShurikenSpinScript: GDScript = null

func _init() -> void:
	_ShurikenSpinScript = GDScript.new()
	_ShurikenSpinScript.source_code = """extends Node3D
func _process(delta: float) -> void:
	rotation.y += 20.0 * delta
"""
	_ShurikenSpinScript.reload()
