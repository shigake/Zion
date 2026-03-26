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

	# Conecta signals para checar sinergias quando armas mudam
	GameManager.weapon_added.connect(func(_id): SynergySystem.check_synergies())
	GameManager.weapon_upgraded.connect(func(_id, _lv): SynergySystem.check_synergies())

	# Conecta signal de kill para sinergias on-kill
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
