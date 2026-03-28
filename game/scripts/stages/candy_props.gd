extends Node3D

## Mundo Doce — chao rosa/pastel com iluminacao rosa brilhante.

@export var area_size: float = 80.0

func _ready() -> void:
	# Ground plane
	var ground = MeshInstance3D.new()
	var plane = PlaneMesh.new()
	plane.size = Vector2(area_size * 2, area_size * 2)
	ground.mesh = plane
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.35, 0.2, 0.25)
	mat.roughness = 1.0
	ground.material_override = mat
	add_child(ground)
