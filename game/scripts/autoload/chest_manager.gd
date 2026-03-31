extends Node

## Gerencia baus de recompensa que spawnam durante a run.
## Baus aparecem periodicamente, com setas no HUD apontando para eles.

signal chest_spawned(chest: Node3D)
signal chest_collected(reward: Dictionary)

var _chest_timer: float = 0.0
var _active_chests: Array[Node3D] = []
var _chest_mesh: BoxMesh = null
var _chest_mat: StandardMaterial3D = null

func _ready() -> void:
	# Pre-create shared mesh/material
	_chest_mesh = BoxMesh.new()
	_chest_mesh.size = Vector3(0.6, 0.5, 0.4)
	_chest_mat = StandardMaterial3D.new()
	_chest_mat.albedo_color = Color(0.7, 0.5, 0.15)
	_chest_mat.emission_enabled = true
	_chest_mat.emission = Color(1.0, 0.85, 0.2)
	_chest_mat.emission_energy_multiplier = 1.5
	_chest_mat.roughness = 0.4

func _spawn_chest() -> void:
	var players = GameManager.get_players()
	if players.is_empty():
		return
	var player_pos = players[0].global_position
	# Spawna em posicao aleatoria entre 15-25 unidades do jogador
	var angle = randf() * TAU
	var dist = randf_range(15.0, 25.0)
	var spawn_pos = player_pos + Vector3(cos(angle), 0, sin(angle)) * dist
	spawn_pos.y = 0.3

	var chest = _create_chest_node()
	chest.global_position = spawn_pos
	get_tree().current_scene.add_child(chest)
	_active_chests.append(chest)
	chest_spawned.emit(chest)
	AudioManager.play_sfx("chest_open")
	LogManager.info("Chest", "Reward chest spawned at %.0f, %.0f" % [spawn_pos.x, spawn_pos.z])

func _create_chest_node() -> Node3D:
	# Usa Node3D puro — coleta por distância no _process (sem Area3D)
	var chest = Node3D.new()
	chest.name = "RewardChest"
	chest.add_to_group("reward_chests")

	# Visual: sprite do baú
	var chest_sprite_path = "res://assets/sprites/pickups/chest.png"
	if ResourceLoader.exists(chest_sprite_path):
		var sprite = Sprite3D.new()
		sprite.texture = load(chest_sprite_path)
		sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		sprite.pixel_size = 0.06
		sprite.shaded = false
		sprite.transparent = true
		sprite.position.y = 0.5
		sprite.name = "ChestSprite"
		sprite.modulate = Color(1.2, 1.1, 0.9)  # Slight golden boost
		chest.add_child(sprite)
	else:
		var mesh_inst = MeshInstance3D.new()
		mesh_inst.mesh = _chest_mesh
		mesh_inst.material_override = _chest_mat
		mesh_inst.position.y = 0.25
		chest.add_child(mesh_inst)

	# Glow aura
	var aura = OmniLight3D.new()
	aura.light_color = Color(1.0, 0.85, 0.2)
	aura.light_energy = 2.0
	aura.omni_range = 3.0
	aura.position.y = 0.5
	chest.add_child(aura)

	chest.set_meta("despawn_timer", GameConstants.CHEST_DESPAWN_TIME)
	chest.set_meta("time", 0.0)
	return chest

func _process(delta: float) -> void:
	if GameManager.paused or GameManager.is_game_over:
		return
	if GameManager.game_time < 10.0:
		return

	_chest_timer += delta
	if _chest_timer >= GameConstants.CHEST_SPAWN_INTERVAL:
		_chest_timer = 0.0
		_spawn_chest()

	# Coleta por distância (método principal — sem Area3D)
	var players = GameManager.get_players()
	if not players.is_empty():
		var player_pos = players[0].global_position
		for chest in _active_chests.duplicate():
			if is_instance_valid(chest) and chest.is_inside_tree():
				if player_pos.distance_to(chest.global_position) < 2.0:
					_collect_chest(chest)
					break

	# Update chest animations + despawn
	for i in range(_active_chests.size() - 1, -1, -1):
		var chest = _active_chests[i]
		if not is_instance_valid(chest) or not chest.is_inside_tree():
			_active_chests.remove_at(i)
			continue
		var t = chest.get_meta("time", 0.0) + delta
		chest.set_meta("time", t)
		var dt = chest.get_meta("despawn_timer", 20.0) - delta
		chest.set_meta("despawn_timer", dt)
		# Bobbing + rotation (funciona com Sprite3D ou MeshInstance3D)
		var visual = chest.get_child(0) if chest.get_child_count() > 0 else null
		if visual:
			if visual is Sprite3D:
				visual.position.y = 0.5 + sin(t * 2.0) * 0.1
			elif visual is MeshInstance3D:
				visual.position.y = 0.25 + sin(t * 2.0) * 0.1
				visual.rotation.y += delta * 1.5
		# Blink when about to despawn
		if dt < 5.0:
			chest.visible = int(t * 6.0) % 2 == 0
		if dt <= 0:
			_active_chests.remove_at(i)
			chest.queue_free()

func _collect_chest(chest: Node3D) -> void:
	if not is_instance_valid(chest):
		return

	# Gera recompensa
	var reward := {}
	var roll = randf()
	if roll < 0.3:
		# Cristais
		var crystals = randi_range(GameConstants.CHEST_REWARD_CRYSTALS_MIN, GameConstants.CHEST_REWARD_CRYSTALS_MAX)
		GameManager.crystals_this_run += crystals
		SaveManager.data["crystals"] = SaveManager.data.get("crystals", 0) + crystals
		reward = {"type": "crystals", "amount": crystals}
	elif roll < 0.6:
		# XP
		GameManager.add_xp(GameConstants.CHEST_REWARD_XP)
		reward = {"type": "xp", "amount": GameConstants.CHEST_REWARD_XP}
	elif roll < 0.85:
		# Cura
		var heal = int(GameManager.get_effective_max_hp() * 0.25)
		GameManager.heal(heal)
		reward = {"type": "heal", "amount": heal}
	else:
		# Reroll gratis
		GameManager.rerolls += 1
		reward = {"type": "reroll", "amount": 1}

	# VFX
	ParticleFactory.spawn_collect_particles(chest.global_position, Color(1.0, 0.85, 0.2))
	AudioManager.play_sfx("collect_crystal")
	ScreenEffects.shake(0.05)

	# Damage number mostrando recompensa
	var text = ""
	match reward["type"]:
		"crystals": text = "+%d cristais" % reward["amount"]
		"xp": text = "+%d XP" % reward["amount"]
		"heal": text = "+%d HP" % reward["amount"]
		"reroll": text = "+1 Reroll"
	ParticleFactory.spawn_damage_number(chest.global_position + Vector3(0, 1, 0), text, Color(1.0, 0.85, 0.2))

	chest_collected.emit(reward)
	_active_chests.erase(chest)
	chest.queue_free()

func get_active_chests() -> Array[Node3D]:
	return _active_chests

func reset() -> void:
	_chest_timer = 0.0
	for chest in _active_chests:
		if is_instance_valid(chest):
			chest.queue_free()
	_active_chests.clear()
