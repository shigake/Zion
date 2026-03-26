extends Area3D

## Fire ground effect from Gasoline item. Damages enemies standing on it.

var lifetime: float = 3.0
var timer: float = 0.0
var tick_timer: float = 0.0

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
			child.material_override.albedo_color.a = alpha * 0.5
