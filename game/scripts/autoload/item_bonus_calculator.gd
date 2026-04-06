class_name ItemBonusCalculator

## Recalcula todos os bonus de itens passivos do jogador.
## Chamado pelo GameManager quando um item e adicionado/atualizado.

static func recalculate(gm: Node, items: Array) -> void:
	# Reset all bonuses to base
	gm.speed_mult = 1.0
	gm.attack_speed_mult = 1.0
	gm.max_hp_mult = 1.0
	gm.area_mult = 1.0
	gm.magnet_mult = 1.0
	gm.cooldown_mult = 1.0
	gm.dodge_chance = 0.0
	gm.lifesteal = 0.0
	gm.thorns_mult = 0.0
	gm.luck_mult = 1.0
	gm.extra_projectiles = 0
	gm.summon_damage_mult = 1.0
	gm.attack_size_mult = 1.0
	gm.explosion_damage_mult = 1.0
	gm.fire_ground_active = false
	gm.master_key_active = false
	gm.weapon_level_bonus = 0
	gm.accuracy_mult = 1.0
	gm.xp_mult = 1.0
	gm.electric_damage_mult = 1.0

	for it in items:
		var data = ItemDB.get_item(it["id"])
		if data.is_empty():
			continue
		var level = it["level"]
		var value = data["value_per_level"] * level
		match data["stat"]:
			"speed":
				gm.speed_mult += value
			"attack_speed":
				gm.attack_speed_mult += value
			"max_hp":
				gm.max_hp_mult += value
				var new_max = gm.get_effective_max_hp()
				gm.player_hp = mini(gm.player_hp + int(gm.player_max_hp * data["value_per_level"]), new_max)
			"area":
				gm.area_mult += value
			"magnet":
				gm.magnet_mult += value
			"cooldown":
				gm.cooldown_mult = maxf(0.3, gm.cooldown_mult - value)
			"dodge":
				gm.dodge_chance = minf(0.7, gm.dodge_chance + value)
			"xp_bonus":
				gm.xp_mult += value
			"explosion_damage":
				gm.explosion_damage_mult += value
			"lifesteal":
				gm.lifesteal += value
			"thorns":
				gm.thorns_mult += value
			"luck":
				gm.luck_mult += value
			"extra_projectiles":
				gm.extra_projectiles += int(value)
			"summon_damage":
				gm.summon_damage_mult += value
			"attack_size":
				gm.attack_size_mult += value
			"fire_ground":
				gm.fire_ground_active = level > 0
			"weapon_level_bonus":
				gm.weapon_level_bonus = int(value)
			"accuracy":
				gm.accuracy_mult += value
			"electric_damage":
				gm.electric_damage_mult += value
