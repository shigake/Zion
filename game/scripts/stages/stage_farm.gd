extends Node3D

## Fase Fazenda do Apocalipse — inicializa a run com personagem e reliquia selecionados.
## Checa evolucoes disponiveis periodicamente.

@onready var player: CharacterBody3D = $Player

var evolution_check_timer: float = 0.0
var chest_scene: PackedScene = preload("res://scenes/evolution_chest.tscn")

func _ready() -> void:
	GameManager.reset()
	EvolutionDB.reset()
	SynergySystem.reset()

	# Conecta signals para checar sinergias quando armas mudam
	GameManager.weapon_added.connect(func(_id): SynergySystem.check_synergies())
	GameManager.weapon_upgraded.connect(func(_id, _lv): SynergySystem.check_synergies())

	# Conecta signal de kill para sinergias on-kill
	GameManager.enemy_killed.connect(_on_enemy_killed_synergy)

	AudioManager.play_music("farm")

	# Aplica personagem selecionado
	var char_data = CharacterDB.get_character(GameManager.selected_character)
	if not char_data.is_empty():
		# Cor
		if player.has_node("Mesh"):
			var mat = player.get_node("Mesh").get_surface_override_material(0)
			if mat is StandardMaterial3D:
				mat.albedo_color = char_data["color"]
				player.original_color = char_data["color"]

		# Arma inicial
		GameManager.player_weapons.clear()
		for child in player.get_node("WeaponPivot").get_children():
			child.queue_free()
		if GameManager.selected_character == "mystery":
			for wid in WeaponDB.get_all_weapon_ids():
				GameManager.add_weapon(wid)
				player.add_weapon_node(wid)
		else:
			GameManager.add_weapon(char_data["starting_weapon"])
			player.add_weapon_node(char_data["starting_weapon"])

func _process(delta: float) -> void:
	if GameManager.paused or GameManager.is_game_over:
		return

	# Checa evolucoes a cada 2 segundos
	evolution_check_timer += delta
	if evolution_check_timer >= 2.0:
		evolution_check_timer = 0.0
		_check_evolutions()

	# Sinergias passivas
	SynergySystem.apply_passive_synergies(player.global_position, delta)

func _check_evolutions() -> void:
	var evo_id = EvolutionDB.check_evolution_available()
	if evo_id.is_empty():
		return

	# Spawna bau perto do jogador
	var chest = chest_scene.instantiate()
	chest.evolution_id = evo_id
	var offset = Vector3(randf_range(-5, 5), 0, randf_range(-5, 5))
	chest.global_position = player.global_position + offset
	add_child(chest)

func _on_enemy_killed_synergy(pos: Vector3, _xp: int) -> void:
	SynergySystem.apply_on_kill_synergies(pos)
