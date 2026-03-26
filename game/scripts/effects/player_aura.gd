extends MeshInstance3D

## Aura visual ao redor do jogador. Pulsa suavemente.

var base_color: Color = Color(0.2, 0.8, 0.3, 0.15)

func _ready() -> void:
	# Flat ring mesh
	var torus = TorusMesh.new()
	torus.inner_radius = 0.8
	torus.outer_radius = 1.0
	torus.rings = 16
	torus.ring_segments = 8
	mesh = torus

	var mat = StandardMaterial3D.new()
	mat.albedo_color = base_color
	mat.emission_enabled = true
	mat.emission = Color(base_color.r, base_color.g, base_color.b)
	mat.emission_energy_multiplier = 1.5
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.no_depth_test = true
	material_override = mat

	position.y = 0.05  # Just above ground
	rotation.x = 0  # Flat

func _process(delta: float) -> void:
	# Gentle pulse
	var pulse = sin(Time.get_ticks_msec() * 0.003) * 0.1 + 0.9
	scale = Vector3(pulse, 1.0, pulse)

	# Rotate slowly
	rotation.y += delta * 0.5
