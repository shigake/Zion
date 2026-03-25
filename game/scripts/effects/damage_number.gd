extends Label3D

## Numero de dano flutuante. Pop up, sobe e desaparece.

var velocity: Vector3 = Vector3(0, 3, 0)
var lifetime: float = 0.8
var timer: float = 0.0

func setup(value: int, color: Color = Color.WHITE, is_crit: bool = false) -> void:
	text = str(value)
	modulate = color
	if is_crit:
		text = str(value) + "!"
		font_size = 48
	else:
		font_size = 32
	outline_size = 8
	billboard = BaseMaterial3D.BILLBOARD_ENABLED

func _process(delta: float) -> void:
	timer += delta
	global_position += velocity * delta
	velocity.y -= 5.0 * delta  # Gravidade

	# Fade out
	var alpha = 1.0 - (timer / lifetime)
	modulate.a = alpha

	if timer >= lifetime:
		queue_free()
