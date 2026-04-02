class_name UpgradeOptionGenerator

## Gera e descreve opcoes de upgrade para a tela de level up.
## Extraido do level_up_screen.gd para separar logica de dados da UI.

static func generate_options() -> Array:
	var pool: Array = []

	# Armas que o jogador ja tem (upgrade)
	for w in GameManager.player_weapons:
		if w["level"] < 8:
			var data = WeaponDB.get_weapon(w["id"])
			pool.append({
				"type": "weapon",
				"id": w["id"],
				"label": "%s (Lv.%d → %d)" % [data["name"], w["level"], w["level"] + 1],
				"weight": 10,
			})

	# Armas novas (se tem slot, excluindo disabled)
	if GameManager.player_weapons.size() < GameManager.MAX_WEAPONS:
		for wid in WeaponDB.get_all_weapon_ids():
			if not GameManager.has_weapon(wid):
				var data = WeaponDB.get_weapon(wid)
				if data.get("disabled", false):
					continue
				pool.append({
					"type": "weapon",
					"id": wid,
					"label": "%s (%s)" % [data["name"], LocaleManager.tr_key("new")],
					"weight": 8,
				})

	# Itens que o jogador ja tem (upgrade)
	for it in GameManager.player_items:
		if it["level"] < 5:
			var data = ItemDB.get_item(it["id"])
			pool.append({
				"type": "item",
				"id": it["id"],
				"label": "%s (Lv.%d → %d)" % [data["name"], it["level"], it["level"] + 1],
				"weight": 10,
			})

	# Itens novos (se tem slot)
	if GameManager.player_items.size() < GameManager.MAX_ITEMS:
		for iid in ItemDB.get_all_item_ids():
			if not GameManager.has_item(iid):
				var data = ItemDB.get_item(iid)
				if data.get("disabled", false):
					continue
				pool.append({
					"type": "item",
					"id": iid,
					"label": "%s (%s)" % [data["name"], LocaleManager.tr_key("new")],
					"weight": 8,
				})

	# Filter banished options
	pool = pool.filter(func(opt): return opt["id"] not in GameManager.banished_options)

	# Weighted random selection (luck_mult increases rare weapon chance)
	# Uses seeded RNG for deterministic runs
	var selected: Array = []
	for _i in range(3):
		if pool.is_empty():
			break
		var total_weight = 0.0
		for opt in pool:
			total_weight += opt["weight"] * GameManager.luck_mult
		var roll = GameManager.seeded_rng.randf() * total_weight
		var cumulative = 0.0
		for j in range(pool.size()):
			cumulative += pool[j]["weight"] * GameManager.luck_mult
			if roll <= cumulative:
				selected.append(pool[j])
				pool.remove_at(j)
				break
	return selected

static func get_opt_name(opt: Dictionary) -> String:
	if opt["type"] == "weapon":
		return WeaponDB.get_weapon(opt["id"])["name"]
	return ItemDB.get_item(opt["id"])["name"]

static func get_level_text(opt: Dictionary) -> String:
	if opt["type"] == "weapon":
		if GameManager.has_weapon(opt["id"]):
			var w = GameManager.player_weapons.filter(func(x): return x["id"] == opt["id"])
			if not w.is_empty():
				return "Lv. %d → %d" % [w[0]["level"], w[0]["level"] + 1]
		return "★ " + LocaleManager.tr_key("new").to_upper()
	else:
		if GameManager.has_item(opt["id"]):
			var it = GameManager.player_items.filter(func(x): return x["id"] == opt["id"])
			if not it.is_empty():
				return "Lv. %d → %d" % [it[0]["level"], it[0]["level"] + 1]
		return "★ " + LocaleManager.tr_key("new").to_upper()

static func get_description(opt: Dictionary) -> String:
	if opt["type"] == "weapon":
		return WeaponDB.get_weapon(opt["id"]).get("description", "")
	return ItemDB.get_item(opt["id"]).get("description", "")

static func get_element(opt: Dictionary) -> String:
	if opt["type"] == "weapon":
		return WeaponDB.get_weapon(opt["id"]).get("element", "physical")
	return "physical"

static func get_stats_preview(opt: Dictionary) -> String:
	if opt["type"] != "weapon":
		return ""
	var wdata = WeaponDB.get_weapon(opt["id"])
	var damage = wdata.get("damage", 0)
	var cooldown = wdata.get("cooldown", 1.0)
	if damage <= 0 or cooldown <= 0:
		return ""
	var current_dps = damage / cooldown
	if GameManager.has_weapon(opt["id"]):
		var w = GameManager.player_weapons.filter(func(x): return x["id"] == opt["id"])
		if not w.is_empty():
			var lvl = w[0]["level"]
			var cur_dmg = damage * (1.0 + (lvl - 1) * 0.2)
			var next_dmg = damage * (1.0 + lvl * 0.2)
			var cur_dps_val = cur_dmg / cooldown
			var next_dps_val = next_dmg / cooldown
			return "DPS: %.0f → %.0f" % [cur_dps_val, next_dps_val]
	return "DPS: %.0f" % current_dps
