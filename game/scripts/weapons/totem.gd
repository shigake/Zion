extends Node3D

## Totem — planta uma torreta estacionaria que causa dano em area.

var place_timer: float = 0.0
var active_totems: Array = []

func _process(delta: float) -> void:
	if not is_inside_tree():
		return
	if GameManager.paused or GameManager.is_game_over:
		return

	var level = GameManager.get_weapon_level("totem")
	if level <= 0:
		return

	# Clean up destroyed totems
	active_totems = active_totems.filter(func(t): return is_instance_valid(t))

	var max_totems = 1
	if level >= 5:
		max_totems = 2

	var cooldown = WeaponDB.get_cooldown("totem", level) * GameManager.cooldown_mult
	place_timer -= delta
	if place_timer <= 0 and active_totems.size() < max_totems:
		place_timer = cooldown
		_place_totem(level)

func _get_player_node() -> Node3D:
	var candidate = get_parent().get_parent() if get_parent() else null
	if candidate is CharacterBody3D:
		return candidate
	return null

func _place_totem(level: int) -> void:
	if not is_inside_tree():
		return
	var player = _get_player_node()
	if not player:
		return
	var player_pos = player.global_position

	var totem = Node3D.new()
	totem.name = "Totem"
	totem.global_position = player_pos

	# --- Full 3D procedural totem (no Sprite3D) ---
	# Base stake (wooden pole)
	var stake_mi = MeshInstance3D.new()
	var stake_mesh = CylinderMesh.new()
	stake_mesh.top_radius = 0.06
	stake_mesh.bottom_radius = 0.10
	stake_mesh.height = 0.6
	stake_mesh.radial_segments = 6
	stake_mi.mesh = stake_mesh
	stake_mi.position.y = 0.3
	var stake_mat = StandardMaterial3D.new()
	stake_mat.albedo_color = Color(0.35, 0.2, 0.08)
	stake_mat.roughness = 0.9
	stake_mat.metallic = 0.0
	stake_mi.material_override = stake_mat
	stake_mi.name = "TotemStake"
	totem.add_child(stake_mi)

	# Central orb (electric crystal — pulsing)
	var orb_mi = MeshInstance3D.new()
	var orb_mesh = SphereMesh.new()
	orb_mesh.radius = 0.22
	orb_mesh.height = 0.44
	orb_mesh.radial_segments = 8
	orb_mesh.rings = 4
	orb_mi.mesh = orb_mesh
	orb_mi.position.y = 0.75
	var orb_mat = StandardMaterial3D.new()
	orb_mat.albedo_color = Color(0.3, 0.7, 1.0, 0.85)
	orb_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	orb_mat.emission_enabled = true
	orb_mat.emission = Color(0.4, 0.8, 1.0)
	orb_mat.emission_energy_multiplier = 2.0
	orb_mat.metallic = 0.5
	orb_mat.roughness = 0.2
	orb_mi.material_override = orb_mat
	orb_mi.name = "TotemOrb"
	totem.add_child(orb_mi)

	# Damage area
	var area = Area3D.new()
	area.collision_layer = 8
	area.collision_mask = 2
	area.monitoring = true
	var shape = CollisionShape3D.new()
	var sphere = SphereShape3D.new()
	var area_radius = 4.0 + (level - 1) * 0.5
	sphere.radius = area_radius
	shape.shape = sphere
	area.add_child(shape)
	totem.add_child(area)

	# --- Electric arcs (3D procedural zigzag lines orbiting totem) ---
	var arc_mat = StandardMaterial3D.new()
	arc_mat.albedo_color = Color(0.4, 0.85, 1.0, 0.8)
	arc_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	arc_mat.emission_enabled = true
	arc_mat.emission = Color(0.5, 0.9, 1.0)
	arc_mat.emission_energy_multiplier = 3.0
	arc_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	arc_mat.no_depth_test = true
	for i in range(3):
		var arc_mi = MeshInstance3D.new()
		# Create zigzag arc mesh (6 segments of small boxes)
		var arc_parent = Node3D.new()
		arc_parent.name = "ArcParent_%d" % i
		var angle = i * TAU / 3.0
		arc_parent.position = Vector3(cos(angle) * area_radius * 0.5, 0.5, sin(angle) * area_radius * 0.5)
		for j in range(6):
			var seg = MeshInstance3D.new()
			var seg_mesh = BoxMesh.new()
			seg_mesh.size = Vector3(0.03, 0.12, 0.03)
			seg.mesh = seg_mesh
			seg.material_override = arc_mat
			seg.position = Vector3(randf_range(-0.06, 0.06), j * 0.12 - 0.3, randf_range(-0.06, 0.06))
			seg.rotation.z = randf_range(-0.5, 0.5)
			seg.name = "ArcSeg_%d" % j
			arc_parent.add_child(seg)
		totem.add_child(arc_parent)

	# --- Area ring (flat torus showing damage radius) ---
	var ring_mi = MeshInstance3D.new()
	var ring_mesh = TorusMesh.new()
	ring_mesh.inner_radius = area_radius - 0.05
	ring_mesh.outer_radius = area_radius
	ring_mesh.ring_segments = 6
	ring_mesh.rings = 24
	ring_mi.mesh = ring_mesh
	ring_mi.position.y = 0.02
	var ring_mat = StandardMaterial3D.new()
	ring_mat.albedo_color = Color(0.3, 0.7, 1.0, 0.12)
	ring_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ring_mat.emission_enabled = true
	ring_mat.emission = Color(0.4, 0.8, 1.0)
	ring_mat.emission_energy_multiplier = 0.5
	ring_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ring_mi.material_override = ring_mat
	ring_mi.name = "AreaRing"
	totem.add_child(ring_mi)

	# Attach damage script behavior via timer
	var damage = int(WeaponDB.get_damage("totem", level))
	var lifetime = 15.0 + level * 2.0

	var script_node = Node.new()
	script_node.set_script(_TotemBehavior)
	script_node.set_meta("damage", damage)
	script_node.set_meta("lifetime", lifetime)
	script_node.set_meta("area", area)
	totem.add_child(script_node)

	active_totems.append(totem)
	get_tree().current_scene.call_deferred("add_child", totem)

	AudioManager.play_sfx("electric_zap")
	ParticleFactory.spawn_hit_particles(player_pos + Vector3(0, 0.5, 0), Color(0.2, 0.6, 1.0))

# Inner class for totem behavior
var _TotemBehavior: GDScript = preload("res://scripts/weapons/totem_behavior.gd")
