extends Node3D
class_name BaseStage

## Base stage script — all stages inherit from this.
## Subclasses only need to set music_track before calling super._ready().

@export var music_track: String = "cemetery"

@onready var player: CharacterBody3D = $Player

var evolution_check_timer: float = 0.0
var chest_scene: PackedScene = preload("res://scenes/evolution_chest.tscn")

func _ready() -> void:
	GameManager.reset()
	EvolutionDB.reset()
	SynergySystem.reset()

	# Aplica iluminação e atmosfera da fenda
	load("res://scripts/stages/stage_atmosphere.gd").apply(self, GameManager.selected_stage)

	# Conecta signals para checar sinergias (usando Callable direto, não lambda)
	if not GameManager.weapon_added.is_connected(_on_weapon_changed):
		GameManager.weapon_added.connect(_on_weapon_changed)
	if not GameManager.weapon_upgraded.is_connected(_on_weapon_upgraded_synergy):
		GameManager.weapon_upgraded.connect(_on_weapon_upgraded_synergy)
	if not GameManager.enemy_killed.is_connected(_on_enemy_killed_synergy):
		GameManager.enemy_killed.connect(_on_enemy_killed_synergy)

	AudioManager.play_music(music_track)

	# Aplica personagem selecionado
	var char_data = CharacterDB.get_character(GameManager.selected_character)

	# Limpa o WeaponPivot garantidamente antes de configurar armas
	GameManager.player_weapons.clear()
	var weapon_pivot = player.get_node("WeaponPivot")
	for child in weapon_pivot.get_children():
		weapon_pivot.remove_child(child)
		child.queue_free()

	if not char_data.is_empty():
		# Cor
		if player.has_node("Mesh"):
			var mat = player.get_node("Mesh").get_surface_override_material(0)
			if mat is StandardMaterial3D:
				mat.albedo_color = char_data["color"]
				player.original_color = char_data["color"]

		# Arma inicial
		if GameManager.selected_character == "mystery":
			# Mystery: todas as armas no nivel 1
			for wid in WeaponDB.get_all_weapon_ids():
				GameManager.add_weapon(wid)
				player.add_weapon_node(wid)
		else:
			var start_wid: String = char_data.get("starting_weapon", "katana")
			GameManager.add_weapon(start_wid)
			player.add_weapon_node(start_wid)
	else:
		# Fallback de seguranca: personagem desconhecido, usa katana
		LogManager.warn("BaseStage", "Personagem desconhecido: '%s'. Usando katana como fallback." % GameManager.selected_character)
		GameManager.add_weapon("katana")
		player.add_weapon_node("katana")

	# New Game+: re-add weapons from previous run (capped at level 3)
	if GameManager.game_mode == "new_game_plus" and not GameManager.ng_plus_weapons.is_empty():
		for w in GameManager.ng_plus_weapons:
			var wid: String = w["id"]
			if not GameManager.has_weapon(wid):
				GameManager.add_weapon(wid)
				player.add_weapon_node(wid)
			# Upgrade to min(original_level, 3)
			var target_level = mini(w["level"], 3)
			while GameManager.get_weapon_level(wid) < target_level:
				GameManager.upgrade_weapon(wid)
		GameManager.new_game_plus = true
		LogManager.info("Game", "New Game+ applied: %d weapons carried over" % GameManager.ng_plus_weapons.size())

func _process(delta: float) -> void:
	if GameManager.paused or GameManager.is_game_over:
		return

	# Time limit: end the run as defeat when time expires (not in endless mode)
	if GameManager.game_mode != "endless" and GameManager.game_time >= GameManager.run_time_limit:
		GameManager.is_victory = false
		GameManager.is_game_over = true
		LogManager.info("Game", "Time limit reached (%.0fs). Run ended as defeat." % GameManager.run_time_limit)
		GameManager.game_over.emit()
		return

	# Checa evolucoes a cada 2 segundos
	evolution_check_timer += delta
	if evolution_check_timer >= 2.0:
		evolution_check_timer = 0.0
		_check_evolutions()

	# Sinergias passivas
	SynergySystem.apply_passive_synergies(player.global_position, delta)

func _check_evolutions() -> void:
	if not is_instance_valid(player) or not player.is_inside_tree():
		return
	var evo_id = EvolutionDB.check_evolution_available()
	if evo_id.is_empty():
		return

	# Spawna bau perto do jogador
	var pos = player.global_position
	var chest = chest_scene.instantiate()
	chest.evolution_id = evo_id
	var offset = Vector3(GameManager.seeded_rng.randf_range(-5, 5), 0, GameManager.seeded_rng.randf_range(-5, 5))
	add_child(chest)
	chest.global_position = pos + offset

func _on_weapon_changed(_id: String) -> void:
	SynergySystem.check_synergies()

func _on_weapon_upgraded_synergy(_id: String, _lv: int) -> void:
	SynergySystem.check_synergies()

func _exit_tree() -> void:
	if GameManager.weapon_added.is_connected(_on_weapon_changed):
		GameManager.weapon_added.disconnect(_on_weapon_changed)
	if GameManager.weapon_upgraded.is_connected(_on_weapon_upgraded_synergy):
		GameManager.weapon_upgraded.disconnect(_on_weapon_upgraded_synergy)
	if GameManager.enemy_killed.is_connected(_on_enemy_killed_synergy):
		GameManager.enemy_killed.disconnect(_on_enemy_killed_synergy)

func _on_enemy_killed_synergy(pos: Vector3, _xp: int) -> void:
	SynergySystem.apply_on_kill_synergies(pos)
