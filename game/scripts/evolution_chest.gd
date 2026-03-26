extends Area3D

## Bau de evolucao. Aparece quando arma + item estao max level.
## Jogador interage (E) para evoluir a arma.

@export var evolution_id: String = ""

@onready var mesh: MeshInstance3D = $Mesh
@onready var label_3d: Label3D = $Label3D

var player_nearby: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	var evo = EvolutionDB.get_evolution(evolution_id)
	if not evo.is_empty():
		label_3d.text = "[E] %s" % evo["name"]

func _process(_delta: float) -> void:
	if GameManager.paused:
		return

	# Rotacao do bau
	mesh.rotation.y += _delta * 2.0

	# Interacao: E ou clique
	if player_nearby and (Input.is_action_just_pressed("interact") or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)):
		_evolve()

func _evolve() -> void:
	AudioManager.play_sfx("evolve")
	EvolutionDB.evolve_weapon(evolution_id)
	var evo = EvolutionDB.get_evolution(evolution_id)

	# Aumenta dano da arma evoluida
	for w in GameManager.player_weapons:
		if w["id"] == evo["weapon_required"]:
			w["level"] = 9  # Level 9 = evoluido
			break

	queue_free()

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("players"):
		player_nearby = true
		label_3d.visible = true

func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("players"):
		player_nearby = false
		label_3d.visible = false
