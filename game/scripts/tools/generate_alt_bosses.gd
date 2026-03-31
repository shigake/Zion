@tool
extends SceneTree

## Gera cenas .tscn para todos os bosses alternativos.
## Rodar: godot --headless --path game --script res://scripts/tools/generate_alt_bosses.gd

const BOSS_GENERIC_SCRIPT = "res://scripts/enemies/boss_generic.gd"
const BASE_ENEMY_SCENE = "res://scenes/enemies/zombie_runner.tscn"

const ALT_BOSSES := {
	# Cemetery
	"boss_cemetery_lich": {"name": "Lich King", "color": Color(0.3, 0.8, 0.3), "hp": 3000, "dmg": 35, "spd": 3.0, "style": "summoner"},
	"boss_cemetery_reaper": {"name": "Death Reaper", "color": Color(0.1, 0.1, 0.15), "hp": 2500, "dmg": 50, "spd": 5.0, "style": "melee"},
	# Forest
	"boss_forest_elder": {"name": "Elder Treant", "color": Color(0.2, 0.5, 0.1), "hp": 4000, "dmg": 25, "spd": 1.5, "style": "summoner"},
	"boss_forest_spider": {"name": "Spider Queen", "color": Color(0.4, 0.1, 0.5), "hp": 2800, "dmg": 40, "spd": 4.5, "style": "ranged"},
	# Farm
	"boss_farm_scarecrow": {"name": "Scarecrow King", "color": Color(0.6, 0.4, 0.1), "hp": 2500, "dmg": 45, "spd": 4.0, "style": "melee"},
	"boss_farm_harvester": {"name": "The Harvester", "color": Color(0.3, 0.3, 0.3), "hp": 3500, "dmg": 35, "spd": 3.0, "style": "balanced"},
	# Tokyo
	"boss_tokyo_shogun": {"name": "Cyber Shogun", "color": Color(0.8, 0.1, 0.3), "hp": 3000, "dmg": 45, "spd": 5.0, "style": "melee"},
	"boss_tokyo_kaiju": {"name": "Mini Kaiju", "color": Color(0.2, 0.6, 0.3), "hp": 5000, "dmg": 30, "spd": 2.0, "style": "balanced"},
	# Volcano
	"boss_volcano_phoenix": {"name": "Ash Phoenix", "color": Color(1.0, 0.5, 0.0), "hp": 2500, "dmg": 40, "spd": 6.0, "style": "ranged"},
	"boss_volcano_titan": {"name": "Magma Titan", "color": Color(0.5, 0.1, 0.0), "hp": 5000, "dmg": 25, "spd": 1.5, "style": "summoner"},
	# Ocean
	"boss_ocean_siren": {"name": "Siren Queen", "color": Color(0.3, 0.7, 0.9), "hp": 2800, "dmg": 35, "spd": 4.0, "style": "ranged"},
	"boss_ocean_hydra": {"name": "Deep Hydra", "color": Color(0.1, 0.2, 0.4), "hp": 4500, "dmg": 30, "spd": 2.5, "style": "summoner"},
	# Arena
	"boss_arena_minotaur": {"name": "Minotaur Champion", "color": Color(0.6, 0.3, 0.1), "hp": 3500, "dmg": 50, "spd": 5.0, "style": "melee"},
	"boss_arena_chimera": {"name": "Chimera", "color": Color(0.5, 0.2, 0.6), "hp": 3000, "dmg": 40, "spd": 4.0, "style": "balanced"},
	# Space
	"boss_space_hivemind": {"name": "Hive Mind", "color": Color(0.2, 0.8, 0.2), "hp": 3000, "dmg": 30, "spd": 2.0, "style": "summoner"},
	"boss_space_warden": {"name": "Void Warden", "color": Color(0.4, 0.2, 0.8), "hp": 3500, "dmg": 45, "spd": 3.5, "style": "ranged"},
	# Castle
	"boss_castle_werewolf": {"name": "Alpha Werewolf", "color": Color(0.4, 0.3, 0.2), "hp": 2800, "dmg": 55, "spd": 7.0, "style": "melee"},
	"boss_castle_banshee": {"name": "Banshee Queen", "color": Color(0.5, 0.7, 0.9), "hp": 2500, "dmg": 35, "spd": 5.0, "style": "ranged"},
	# Candy
	"boss_candy_witch": {"name": "Candy Witch", "color": Color(0.9, 0.3, 0.7), "hp": 2800, "dmg": 40, "spd": 4.0, "style": "ranged"},
	"boss_candy_dragon": {"name": "Gummy Dragon", "color": Color(0.2, 0.8, 0.4), "hp": 4000, "dmg": 35, "spd": 3.0, "style": "balanced"},
}

func _init() -> void:
	var base_scene = load(BASE_ENEMY_SCENE) as PackedScene
	if not base_scene:
		print("ERROR: Cannot load base scene")
		quit()
		return

	var script = load(BOSS_GENERIC_SCRIPT) as GDScript
	if not script:
		print("ERROR: Cannot load boss_generic.gd")
		quit()
		return

	for boss_id in ALT_BOSSES:
		var config = ALT_BOSSES[boss_id]
		var scene_path = "res://scenes/enemies/%s.tscn" % boss_id

		# Instancia a cena base e configura
		var node = base_scene.instantiate()
		node.set_script(script)
		node.name = config["name"].replace(" ", "")

		# Configura exports
		node.set("boss_name", config["name"])
		node.set("boss_color", config["color"])
		node.set("attack_style", config["style"])

		# Stats de boss
		if "max_hp" in node:
			node.max_hp = config["hp"]
			node.hp = config["hp"]
		if "damage" in node:
			node.damage = config["dmg"]
		if "speed" in node:
			node.speed = config["spd"]

		# Salva como PackedScene
		var packed = PackedScene.new()
		packed.pack(node)
		var err = ResourceSaver.save(packed, scene_path)
		if err == OK:
			print("Created: %s" % scene_path)
		else:
			print("ERROR creating %s: %s" % [scene_path, err])

		node.queue_free()

	print("Done! Created %d alt boss scenes." % ALT_BOSSES.size())
	quit()
