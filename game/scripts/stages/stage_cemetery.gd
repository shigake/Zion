extends Node3D

## Fase Cemiterio — inicializa a run com personagem e reliquia selecionados.

@onready var player: CharacterBody3D = $Player

func _ready() -> void:
	GameManager.reset()

	# Aplica cor do personagem
	var char_data = CharacterDB.get_character(GameManager.selected_character)
	if not char_data.is_empty() and player.has_node("Mesh"):
		var mat = player.get_node("Mesh").get_surface_override_material(0)
		if mat is StandardMaterial3D:
			mat.albedo_color = char_data["color"]
			player.original_color = char_data["color"]

	# Aplica arma inicial do personagem
	if not char_data.is_empty():
		# Remove arma default se diferente
		GameManager.player_weapons.clear()
		GameManager.add_weapon(char_data["starting_weapon"])
		# Limpa weapon pivot e spawna a certa
		for child in player.get_node("WeaponPivot").get_children():
			child.queue_free()
		player.add_weapon_node(char_data["starting_weapon"])
