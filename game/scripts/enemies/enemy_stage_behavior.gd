class_name EnemyStageBehavior

## Dados de comportamento por inimigo tematico de fenda.
## Substitui o match de 100 linhas em enemy_base._apply_stage_behavior().

# Estrutura: {themed_name -> {behavior, timer?, cooldown?, extra_props?}}
const BEHAVIORS := {
	# Cemetery
	"cemetery_wraith": {"behavior": "teleport", "timer": 5.0, "cooldown": 5.0},
	"cemetery_banshee": {"behavior": ""},  # Banshees normais nao teleportam (so visual)
	"cemetery_bone_knight": {"behavior": "charge", "timer": 5.0, "cooldown": 5.0},
	# Forest
	"forest_treant": {"behavior": "ambush", "ambush_speed_mult": 3.0, "walk_speed": 1.0},
	"forest_bear": {"behavior": "charge", "timer": 6.0, "cooldown": 6.0},
	"forest_wisp": {"behavior": "flying"},
	# Farm
	"farm_scarecrow": {"behavior": "spawn_on_death"},
	"farm_phantom_horse": {"behavior": "charge", "timer": 3.0, "cooldown": 3.0},
	"farm_dynamite_goat": {"behavior": "explode_on_death"},
	# Tokyo
	"tokyo_drone": {"behavior": "ranged", "timer": 3.0, "cooldown": 3.0},
	"tokyo_hologram": {"behavior": "stealth", "stealth_range": 8.0},
	"tokyo_kamikaze_drone": {"behavior": "explode_on_death"},
	# Volcano
	"volcano_golem": {"behavior": "explode_on_death"},
	"volcano_ash_wraith": {"behavior": "teleport", "timer": 4.0, "cooldown": 4.0},
	"volcano_obsidian_titan": {"behavior": "ambush", "ambush_speed_mult": 2.5, "walk_speed": 0.8},
	# Ocean
	"ocean_jellyfish": {"behavior": "paralyze"},
	"ocean_pufferfish": {"behavior": "explode_on_death"},
	"ocean_piranha_swarm": {"behavior": "ambush", "ambush_speed_mult": 2.0, "walk_speed": 1.5},
	# Arena
	"arena_lion": {"behavior": "charge", "timer": 4.0, "cooldown": 4.0},
	"arena_phantom_champion": {"behavior": "stealth", "stealth_range": 7.0, "damage_mult": 2},
	"arena_war_elephant": {"behavior": "charge", "timer": 5.0, "cooldown": 5.0},
	# Space
	"space_xenomorph": {"behavior": "stealth", "stealth_range": 6.0, "damage_mult": 2},
	"space_void_specter": {"behavior": "teleport", "timer": 3.5, "cooldown": 3.5},
	"space_mine_layer": {"behavior": "ranged", "timer": 4.0, "cooldown": 4.0},
	# Castle
	"castle_gargoyle": {"behavior": "flying"},
	"castle_poltergeist": {"behavior": "flying"},
	"castle_iron_golem": {"behavior": "ambush", "ambush_speed_mult": 2.0, "walk_speed": 0.5},
	# Candy
	"candy_gummy": {"behavior": "split"},
	"candy_cotton_ghost": {"behavior": "flying"},
	"candy_popcorn_bomber": {"behavior": "explode_on_death"},
}

## Aplica comportamento tematico a um inimigo. Retorna true se aplicou.
static func apply(enemy: Node3D, themed_name: String) -> bool:
	if not BEHAVIORS.has(themed_name):
		return false
	var data = BEHAVIORS[themed_name]
	enemy._behavior = data["behavior"]
	if data.has("timer"):
		enemy._behavior_timer = data["timer"]
	if data.has("cooldown"):
		enemy._behavior_cooldown = data["cooldown"]
	if data.has("stealth_range"):
		enemy._stealth_range = data["stealth_range"]
	if data.has("damage_mult"):
		enemy.damage *= data["damage_mult"]
	if data.has("ambush_speed_mult"):
		enemy._ambush_speed = enemy.speed * data["ambush_speed_mult"]
		enemy.speed = data["walk_speed"]
	# Split precisa checar meta
	if data["behavior"] == "split" and enemy.has_meta("no_split"):
		enemy._behavior = ""
		return false
	return true
