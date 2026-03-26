extends EnemyBase3D

## Mimic: parece um bau mas ataca o jogador quando se aproxima.
## Fica parado ate o jogador chegar perto, entao ativa e persegue.

@export var activation_range: float = 4.0

var is_activated: bool = false
var _chest_mat: StandardMaterial3D

func _ready() -> void:
	speed = 6.0
	max_hp = 150
	hp = max_hp
	damage = 20
	xp_drop = 15
	enemy_color = Color(0.6, 0.4, 0.15)  # Cor de bau/madeira
	resistances = {
		"physical": 0.7,  # Resistente a fisico (armadura de madeira)
		"fire": 1.5,      # Fraco a fogo (madeira)
	}
	super._ready()
	# Começa parado
	speed = 0.0

func _physics_process(delta: float) -> void:
	if is_dead or GameManager.paused:
		return

	if not is_activated:
		_find_target()
		if target and is_instance_valid(target):
			var dist = global_position.distance_to(target.global_position)
			if dist <= activation_range:
				_activate()
		return

	super._physics_process(delta)

func _activate() -> void:
	is_activated = true
	speed = 6.0
	# Flash e muda cor para vermelho escuro
	enemy_color = Color(0.7, 0.15, 0.1)
	var mat = mesh.get_surface_override_material(0)
	if mat is StandardMaterial3D:
		mat.albedo_color = enemy_color
	# Efeito visual
	ParticleFactory.spawn_death_particles(global_position + Vector3(0, 0.5, 0), Color(0.6, 0.4, 0.15))
	ScreenEffects.shake(0.1)
	# Scale up
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector3(1.3, 1.3, 1.3), 0.3)
