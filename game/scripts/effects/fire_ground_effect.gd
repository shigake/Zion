extends Area3D

## Fire ground effect from Gasoline item. Damages enemies standing on it.
## Enhanced with flickering flames, ember particles, and heat haze.

var lifetime: float = 3.0
var timer: float = 0.0
var tick_timer: float = 0.0
var _flames: GPUParticles3D = null
var _embers: GPUParticles3D = null
var _heat_glow: MeshInstance3D = null

func _ready() -> void:
	_setup_visual_effects()

func _setup_visual_effects() -> void:
	# --- Flickering flame particles ---
	_flames = GPUParticles3D.new()
	_flames.name = "Flames"
	_flames.amount = 12
	_flames.lifetime = 0.6
	_flames.emitting = true
	_flames.one_shot = false
	_flames.position.y = 0.05
	var flame_mat = ParticleProcessMaterial.new()
	flame_mat.direction = Vector3(0, 1, 0)
	flame_mat.spread = 30.0
	flame_mat.initial_velocity_min = 0.5
	flame_mat.initial_velocity_max = 1.5
	flame_mat.gravity = Vector3(0, 1.0, 0)
	flame_mat.scale_min = 0.15
	flame_mat.scale_max = 0.4
	flame_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	flame_mat.emission_sphere_radius = 1.5
	flame_mat.damping_min = 1.0
	flame_mat.damping_max = 3.0
	# Fire color ramp: yellow core -> orange -> red -> transparent
	var flame_color = GradientTexture1D.new()
	var flame_grad = Gradient.new()
	flame_grad.set_color(0, Color(1.0, 0.9, 0.3, 0.7))
	flame_grad.add_point(0.3, Color(1.0, 0.5, 0.05, 0.6))
	flame_grad.set_color(2, Color(0.8, 0.1, 0.02, 0.0))
	flame_color.gradient = flame_grad
	flame_mat.color_ramp = flame_color
	var flame_scale_c = CurveTexture.new()
	var fsc = Curve.new()
	fsc.add_point(Vector2(0.0, 0.5))
	fsc.add_point(Vector2(0.2, 1.0))
	fsc.add_point(Vector2(0.7, 0.6))
	fsc.add_point(Vector2(1.0, 0.0))
	flame_scale_c.curve = fsc
	flame_mat.scale_curve = flame_scale_c
	_flames.process_material = flame_mat
	var flame_draw = SphereMesh.new()
	flame_draw.radius = 0.08
	flame_draw.height = 0.14  # Tall — flame tongue shape
	flame_draw.radial_segments = 4
	flame_draw.rings = 2
	var flame_draw_mat = StandardMaterial3D.new()
	flame_draw_mat.albedo_color = Color(1.0, 0.7, 0.1, 0.6)
	flame_draw_mat.emission_enabled = true
	flame_draw_mat.emission = Color(1.0, 0.5, 0.0)
	flame_draw_mat.emission_energy_multiplier = 4.0
	flame_draw_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	flame_draw_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	flame_draw.surface_set_material(0, flame_draw_mat)
	_flames.draw_pass_1 = flame_draw
	add_child(_flames)

	# --- Rising ember particles ---
	_embers = GPUParticles3D.new()
	_embers.name = "Embers"
	_embers.amount = 6
	_embers.lifetime = 1.0
	_embers.emitting = true
	_embers.one_shot = false
	_embers.position.y = 0.3
	var ember_mat = ParticleProcessMaterial.new()
	ember_mat.direction = Vector3(0, 1, 0)
	ember_mat.spread = 60.0
	ember_mat.initial_velocity_min = 1.0
	ember_mat.initial_velocity_max = 2.5
	ember_mat.gravity = Vector3(0, 0.5, 0)
	ember_mat.scale_min = 0.03
	ember_mat.scale_max = 0.06
	ember_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	ember_mat.emission_sphere_radius = 1.0
	ember_mat.angular_velocity_min = -200.0
	ember_mat.angular_velocity_max = 200.0
	var ember_color = GradientTexture1D.new()
	var ember_grad = Gradient.new()
	ember_grad.set_color(0, Color(1.0, 0.7, 0.1, 0.9))
	ember_grad.set_color(1, Color(0.8, 0.2, 0.0, 0.0))
	ember_color.gradient = ember_grad
	ember_mat.color_ramp = ember_color
	_embers.process_material = ember_mat
	var ember_draw = SphereMesh.new()
	ember_draw.radius = 0.01
	ember_draw.height = 0.02
	var ember_draw_mat = StandardMaterial3D.new()
	ember_draw_mat.albedo_color = Color(1.0, 0.6, 0.1, 0.9)
	ember_draw_mat.emission_enabled = true
	ember_draw_mat.emission = Color(1.0, 0.4, 0.0)
	ember_draw_mat.emission_energy_multiplier = 6.0
	ember_draw_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ember_draw_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ember_draw.surface_set_material(0, ember_draw_mat)
	_embers.draw_pass_1 = ember_draw
	add_child(_embers)

	# --- Heat glow disc on ground ---
	_heat_glow = MeshInstance3D.new()
	_heat_glow.name = "HeatGlow"
	var glow_cyl = CylinderMesh.new()
	glow_cyl.top_radius = 1.8
	glow_cyl.bottom_radius = 1.8
	glow_cyl.height = 0.02
	_heat_glow.mesh = glow_cyl
	_heat_glow.position.y = 0.01
	var glow_mat = StandardMaterial3D.new()
	glow_mat.albedo_color = Color(1.0, 0.3, 0.0, 0.2)
	glow_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glow_mat.emission_enabled = true
	glow_mat.emission = Color(1.0, 0.4, 0.0)
	glow_mat.emission_energy_multiplier = 2.0
	glow_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	glow_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_heat_glow.material_override = glow_mat
	add_child(_heat_glow)

func _process(delta: float) -> void:
	timer += delta
	if timer >= lifetime:
		queue_free()
		return
	# Damage tick every 0.5s
	tick_timer += delta
	if tick_timer >= 0.5:
		tick_timer = 0.0
		for body in get_overlapping_bodies():
			if body.is_in_group("enemies") and body.has_method("take_damage"):
				body.call_deferred("take_damage", 8, "fire")
	# Fade out
	var alpha = 1.0 - (timer / lifetime)
	for child in get_children():
		if child is MeshInstance3D and child.material_override:
			child.material_override.albedo_color.a = alpha * 0.3
		if child is GPUParticles3D:
			# Stop emitting near end of life so particles wind down naturally
			if timer >= lifetime * 0.7:
				child.emitting = false
	# Flickering intensity on heat glow
	if _heat_glow and _heat_glow.material_override:
		var flicker = 1.5 + sin(timer * 15.0) * 0.5 + sin(timer * 23.0) * 0.3
		_heat_glow.material_override.emission_energy_multiplier = flicker * alpha
