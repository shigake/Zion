extends Area3D

## Gema de XP 3D. Atraida ao jogador quando proximo.

@export var xp_value: int = 1
@export var attract_speed: float = 15.0
@export var attract_range: float = 4.0

var being_attracted: bool = false
var attract_target: Node3D = null

func _ready() -> void:
	add_to_group("xp_gems")
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	if GameManager.paused:
		return

	# Bobbing animation
	var bob = sin(GameManager.game_time * 4.0 + global_position.x) * 0.1
	position.y = 0.3 + bob

	# Procura jogador proximo
	if not being_attracted:
		var players = get_tree().get_nodes_in_group("players")
		for p in players:
			if is_instance_valid(p) and global_position.distance_to(p.global_position) < attract_range:
				being_attracted = true
				attract_target = p
				break

	# Atrai em direcao ao jogador
	if being_attracted and attract_target and is_instance_valid(attract_target):
		var dir = (attract_target.global_position - global_position).normalized()
		global_position += dir * attract_speed * delta

		if global_position.distance_to(attract_target.global_position) < 0.5:
			_collect()

func _collect() -> void:
	GameManager.add_xp(xp_value)
	queue_free()

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("players"):
		_collect()
