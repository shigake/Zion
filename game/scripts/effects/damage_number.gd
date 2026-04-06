extends Label3D

## Numero de dano flutuante. Pop up, sobe e desaparece.
## Usa pool do ParticleFactory para evitar alocacoes constantes.

var velocity: Vector3 = Vector3(0, 5, 0)
var lifetime: float = 1.2
var timer: float = 0.0

func setup(value: int, color: Color = Color.WHITE, is_crit: bool = false) -> void:
	text = str(value)
	modulate = color
	if is_crit:
		text = str(value) + "!"
		font_size = 860
	else:
		font_size = 640
	outline_size = 40
	billboard = BaseMaterial3D.BILLBOARD_ENABLED
	visible = true

func setup_text(msg: String, color: Color = Color.WHITE, size: int = 28) -> void:
	text = msg
	modulate = color
	font_size = size
	outline_size = 8
	billboard = BaseMaterial3D.BILLBOARD_ENABLED
	velocity = Vector3(0, 2, 0)  # Sobe mais devagar que dano
	lifetime = 1.2  # Dura mais para dar tempo de ler
	visible = true

func _reset_for_reuse() -> void:
	timer = 0.0
	velocity = Vector3(0, 5, 0)
	modulate = Color.WHITE
	modulate.a = 1.0
	visible = false
	text = ""
	font_size = 640
	set_process(false)

func _process(delta: float) -> void:
	if not is_inside_tree():
		return
	timer += delta
	global_position += velocity * delta
	velocity.y -= 5.0 * delta  # Gravidade

	# Fade out
	var alpha = 1.0 - (timer / lifetime)
	modulate.a = alpha

	if timer >= lifetime:
		set_process(false)
		visible = false
		ParticleFactory.return_damage_number(self)
