extends Node3D

## Fundo do Oceano — chao azul-escuro/teal com iluminacao azul.

@export var area_size: float = 80.0

func _ready() -> void:
	# Ground plane
	var ground = MeshInstance3D.new()
	var plane = PlaneMesh.new()
	plane.size = Vector2(area_size * 2, area_size * 2)
	ground.mesh = plane
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.05, 0.12, 0.2)
	mat.roughness = 1.0
	ground.material_override = mat
	add_child(ground)
