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
	# Inner arcs (close to totem)
	for i in range(3):
		var arc_parent = Node3D.new()
		arc_parent.name = "ArcParent_%d" % i
		var angle = i * TAU / 3.0
		arc_parent.position = Vector3(cos(angle) * area_radius * 0.35, 0.5, sin(angle) * area_radius * 0.35)
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
	# Outer arcs (near edge of circle)
	for i in range(3):
		var arc_parent = Node3D.new()
		arc_parent.name = "ArcOuter_%d" % i
		var angle = i * TAU / 3.0 + TAU / 6.0  # Offset from inner arcs
		arc_parent.position = Vector3(cos(angle) * area_radius * 0.8, 0.3, sin(angle) * area_radius * 0.8)
		for j in range(4):
			var seg = MeshInstance3D.new()
			var seg_mesh = BoxMesh.new()
			seg_mesh.size = Vector3(0.025, 0.10, 0.025)
			seg.mesh = seg_mesh
			seg.material_override = arc_mat
			seg.position = Vector3(randf_range(-0.05, 0.05), j * 0.10 - 0.2, randf_range(-0.05, 0.05))
			seg.rotation.z = randf_range(-0.6, 0.6)
			seg.name = "ArcSeg_%d" % j
			arc_parent.add_child(seg)
		totem.add_child(arc_parent)

	# --- Ground lightning bolts (flat zigzag lines from center to edge) ---
	var bolt_mat = StandardMaterial3D.new()
	bolt_mat.albedo_color = Color(0.5, 0.9, 1.0, 0.6)
	bolt_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	bolt_mat.emission_enabled = true
	bolt_mat.emission = Color(0.6, 0.95, 1.0)
	bolt_mat.emission_energy_multiplier = 4.0
	bolt_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bolt_mat.no_depth_test = true
	for i in range(6):
		var bolt = Node3D.new()
		bolt.name = "GroundBolt_%d" % i
		bolt.position.y = 0.05
		var bolt_angle = i * TAU / 6.0
		var bolt_len = area_radius * randf_range(0.5, 0.95)
		var seg_count = 5
		var prev_pos = Vector3.ZERO
		for j in range(seg_count):
			var t = float(j + 1) / float(seg_count)
			var base_pos = Vector3(cos(bolt_angle) * bolt_len * t, 0, sin(bolt_angle) * bolt_len * t)
			# Add zigzag offset perpendicular to bolt direction
			var perp = Vector3(-sin(bolt_angle), 0, cos(bolt_angle))
			base_pos += perp * randf_range(-0.3, 0.3)
			var seg = MeshInstance3D.new()
			var seg_mesh = BoxMesh.new()
			var seg_len = prev_pos.distance_to(base_pos)
			seg_mesh.size = Vector3(0.025, 0.015, maxf(seg_len, 0.05))
			seg.mesh = seg_mesh
			seg.material_override = bolt_mat
			# Position at midpoint between prev and current
			var mid = (prev_pos + base_pos) * 0.5
			seg.position = mid
			# Rotate to face from prev to current
			if seg_len > 0.01:
				var dir = (base_pos - prev_pos).normalized()
				seg.rotation.y = atan2(dir.x, dir.z)
			seg.name = "BoltSeg_%d" % j
			bolt.add_child(seg)
			prev_pos = base_pos
		totem.add_child(bolt)

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

	# --- Electric spark particles radiating outward from orb ---
	var spark_particles = GPUParticles3D.new()
	spark_particles.name = "ElectricSparks"
	spark_particles.amount = 12
	spark_particles.lifetime = 0.5
	spark_particles.emitting = true
	spark_particles.one_shot = false
	spark_particles.position.y = 0.75  # At orb height
	var spark_proc = ParticleProcessMaterial.new()
	spark_proc.direction = Vector3(0, 0.5, 0)
	spark_proc.spread = 180.0
	spark_proc.initial_velocity_min = 2.0
	spark_proc.initial_velocity_max = 5.0
	spark_proc.gravity = Vector3(0, -3.0, 0)
	spark_proc.scale_min = 0.08
	spark_proc.scale_max = 0.2
	spark_proc.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	spark_proc.emission_sphere_radius = 0.2
	spark_proc.radial_velocity_min = 1.0
	spark_proc.radial_velocity_max = 3.0
	spark_proc.color = Color(0.5, 0.9, 1.0, 0.85)
	var spark_scale_curve = CurveTexture.new()
	var ssc = Curve.new()
	ssc.add_point(Vector2(0.0, 1.0))
	ssc.add_point(Vector2(0.5, 0.6))
	ssc.add_point(Vector2(1.0, 0.0))
	spark_scale_curve.curve = ssc
	spark_proc.scale_curve = spark_scale_curve
	spark_particles.process_material = spark_proc
	var spark_draw = SphereMesh.new()
	spark_draw.radius = 0.015
	spark_draw.height = 0.03
	var spark_draw_mat = StandardMaterial3D.new()
	spark_draw_mat.albedo_color = Color(0.5, 0.95, 1.0, 0.9)
	spark_draw_mat.emission_enabled = true
	spark_draw_mat.emission = Color(0.4, 0.85, 1.0)
	spark_draw_mat.emission_energy_multiplier = 6.0
	spark_draw_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	spark_draw_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	spark_draw.surface_set_material(0, spark_draw_mat)
	spark_particles.draw_pass_1 = spark_draw
	totem.add_child(spark_particles)

	# --- Ground electric field particles (fill the entire circle) ---
	var field_particles = GPUParticles3D.new()
	field_particles.name = "ElectricField"
	field_particles.amount = 16
	field_particles.lifetime = 0.6
	field_particles.emitting = true
	field_particles.one_shot = false
	field_particles.position.y = 0.08
	var field_proc = ParticleProcessMaterial.new()
	field_proc.direction = Vector3(0, 0.3, 0)
	field_proc.spread = 180.0
	field_proc.initial_velocity_min = 0.3
	field_proc.initial_velocity_max = 1.5
	field_proc.gravity = Vector3(0, -1.0, 0)
	field_proc.scale_min = 0.04
	field_proc.scale_max = 0.12
	field_proc.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	field_proc.emission_sphere_radius = area_radius * 0.85  # Fill most of the circle
	field_proc.radial_velocity_min = 0.5
	field_proc.radial_velocity_max = 2.0
	var field_color = GradientTexture1D.new()
	var field_grad = Gradient.new()
	field_grad.set_color(0, Color(0.5, 0.9, 1.0, 0.8))
	field_grad.set_color(1, Color(0.3, 0.7, 1.0, 0.0))
	field_color.gradient = field_grad
	field_proc.color_ramp = field_color
	field_particles.process_material = field_proc
	var field_draw = SphereMesh.new()
	field_draw.radius = 0.02
	field_draw.height = 0.04
	var field_draw_mat = StandardMaterial3D.new()
	field_draw_mat.albedo_color = Color(0.6, 0.95, 1.0, 0.8)
	field_draw_mat.emission_enabled = true
	field_draw_mat.emission = Color(0.5, 0.9, 1.0)
	field_draw_mat.emission_energy_multiplier = 5.0
	field_draw_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	field_draw_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	field_draw.surface_set_material(0, field_draw_mat)
	field_particles.draw_pass_1 = field_draw
	totem.add_child(field_particles)

	# --- Ground glow disc (subtle electric glow below totem) ---
	var glow_disc = MeshInstance3D.new()
	glow_disc.name = "GroundGlow"
	var glow_mesh = CylinderMesh.new()
	glow_mesh.top_radius = 1.0
	glow_mesh.bottom_radius = 1.0
	glow_mesh.height = 0.02
	glow_disc.mesh = glow_mesh
	glow_disc.position.y = 0.01
	var glow_mat = StandardMaterial3D.new()
	glow_mat.albedo_color = Color(0.2, 0.6, 1.0, 0.15)
	glow_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glow_mat.emission_enabled = true
	glow_mat.emission = Color(0.3, 0.7, 1.0)
	glow_mat.emission_energy_multiplier = 1.5
	glow_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	glow_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	glow_disc.material_override = glow_mat
	totem.add_child(glow_disc)
	# Pulse the ground glow
	var glow_tw = totem.create_tween().set_loops()
	glow_tw.tween_property(glow_disc, "scale", Vector3(1.3, 1.0, 1.3), 0.6).set_trans(Tween.TRANS_SINE)
	glow_tw.tween_property(glow_disc, "scale", Vector3(0.8, 1.0, 0.8), 0.6).set_trans(Tween.TRANS_SINE)

	# --- Ambient electric hum particles (tiny dots floating around orb) ---
	var hum_particles = GPUParticles3D.new()
	hum_particles.name = "ElectricHum"
	hum_particles.amount = 5
	hum_particles.lifetime = 1.0
	hum_particles.emitting = true
	hum_particles.one_shot = false
	hum_particles.position.y = 0.75
	var hum_proc = ParticleProcessMaterial.new()
	hum_proc.direction = Vector3(0, 0, 0)
	hum_proc.spread = 180.0
	hum_proc.initial_velocity_min = 0.0
	hum_proc.initial_velocity_max = 0.1
	hum_proc.gravity = Vector3.ZERO
	hum_proc.scale_min = 0.02
	hum_proc.scale_max = 0.05
	hum_proc.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	hum_proc.emission_sphere_radius = 0.4
	hum_proc.radial_velocity_min = 0.5
	hum_proc.radial_velocity_max = 1.5
	var hum_color = GradientTexture1D.new()
	var hum_grad = Gradient.new()
	hum_grad.set_color(0, Color(0.4, 0.85, 1.0, 0.7))
	hum_grad.set_color(1, Color(0.3, 0.7, 1.0, 0.0))
	hum_color.gradient = hum_grad
	hum_proc.color_ramp = hum_color
	hum_particles.process_material = hum_proc
	var hum_draw = SphereMesh.new()
	hum_draw.radius = 0.012
	hum_draw.height = 0.024
	var hum_draw_mat = StandardMaterial3D.new()
	hum_draw_mat.albedo_color = Color(0.5, 0.9, 1.0, 0.7)
	hum_draw_mat.emission_enabled = true
	hum_draw_mat.emission = Color(0.4, 0.8, 1.0)
	hum_draw_mat.emission_energy_multiplier = 4.0
	hum_draw_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	hum_draw_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	hum_draw.surface_set_material(0, hum_draw_mat)
	hum_particles.draw_pass_1 = hum_draw
	totem.add_child(hum_particles)

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
