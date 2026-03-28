extends Node3D

## Castelo do Vampiro — chao cinza-escuro/pedra com iluminacao vermelha fraca.

@export var area_size: float = 80.0

func _ready() -> void:
	# Ground plane
	var ground = MeshInstance3D.new()
	var plane = PlaneMesh.new()
	plane.size = Vector2(area_size * 2, area_size * 2)
	ground.mesh = plane
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.1, 0.08, 0.08)
	mat.roughness = 1.0
	ground.material_override = mat
	add_child(ground)

	# Stage light — dim red
	var light = DirectionalLight3D.new()
	light.rotation.x = deg_to_rad(-45)
	light.light_color = Color(0.8, 0.3, 0.2)
	light.light_energy = 1.5
	add_child(light)
