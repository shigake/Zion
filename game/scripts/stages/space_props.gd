extends Node3D

## Estacao Espacial — chao roxo-escuro/preto com iluminacao azul fria.

@export var area_size: float = 80.0

func _ready() -> void:
	# Ground plane
	var ground = MeshInstance3D.new()
	var plane = PlaneMesh.new()
	plane.size = Vector2(area_size * 2, area_size * 2)
	ground.mesh = plane
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.05, 0.03, 0.08)
	mat.roughness = 1.0
	ground.material_override = mat
	add_child(ground)
