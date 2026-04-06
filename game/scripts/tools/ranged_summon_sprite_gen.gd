extends SceneTree

## Generates 64x64 pixel art sprites for 21 ranged + summon weapons.
## Replaces the tiny 16x16 stubs with detailed pixel art matching melee quality.
## Run: godot --headless --path game --script res://scripts/tools/ranged_summon_sprite_gen.gd

const S := 64
const OUT := "res://assets/sprites/weapons/"

func _init() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	# Ranged (11)
	_gen_machinegun()
	_gen_staff()
	_gen_bazooka()
	_gen_shuriken()
	_gen_dual_pistol()
	_gen_flamethrower()
	_gen_ice_staff()
	_gen_crossbow()
	_gen_plasma_cannon()
	_gen_elven_bow()
	_gen_boomerang()
	# Summon/Special (10)
	_gen_necro()
	_gen_drone()
	_gen_totem()
	_gen_poison_bottle()
	_gen_lightning_chain()
	_gen_time_bomb()
	_gen_portal_weapon()
	_gen_tornado()
	_gen_blood_orb()
	# magic_book already 64x64 — skip
	print("Generated 20 ranged/summon weapon sprites at 64x64!")
	quit()

# ==================== HELPERS ====================
func _img() -> Image:
	return Image.create(S, S, false, Image.FORMAT_RGBA8)

func _fill(img: Image, x: int, y: int, w: int, h: int, c: Color) -> void:
	for px in range(maxi(x, 0), mini(x + w, S)):
		for py in range(maxi(y, 0), mini(y + h, S)):
			img.set_pixel(px, py, c)

func _px(img: Image, x: int, y: int, c: Color) -> void:
	if x >= 0 and x < S and y >= 0 and y < S:
		img.set_pixel(x, y, c)

func _circle(img: Image, cx: int, cy: int, r: int, c: Color) -> void:
	for x in range(maxi(cx - r, 0), mini(cx + r + 1, S)):
		for y in range(maxi(cy - r, 0), mini(cy + r + 1, S)):
			if (x - cx) * (x - cx) + (y - cy) * (y - cy) <= r * r:
				img.set_pixel(x, y, c)

func _line_h(img: Image, x1: int, x2: int, y: int, c: Color) -> void:
	for x in range(maxi(x1, 0), mini(x2 + 1, S)):
		_px(img, x, y, c)

func _line_v(img: Image, x: int, y1: int, y2: int, c: Color) -> void:
	for y in range(maxi(y1, 0), mini(y2 + 1, S)):
		_px(img, x, y, c)

func _outline(img: Image, color: Color) -> void:
	var copy = img.duplicate()
	for x in range(S):
		for y in range(S):
			if copy.get_pixel(x, y).a > 0:
				for d in [Vector2i(-1,0), Vector2i(1,0), Vector2i(0,-1), Vector2i(0,1)]:
					var nx = x + d.x
					var ny = y + d.y
					if nx >= 0 and nx < S and ny >= 0 and ny < S and copy.get_pixel(nx, ny).a == 0:
						img.set_pixel(nx, ny, color)

func _save(img: Image, name: String) -> void:
	img.save_png(OUT + name)
	print("Saved: %s%s" % [OUT, name])

# ==================== RANGED WEAPONS ====================

func _gen_machinegun() -> void:
	var img = _img()
	var metal = Color(0.4, 0.4, 0.45)
	var metal_dk = Color(0.25, 0.25, 0.3)
	var metal_lt = Color(0.55, 0.55, 0.6)
	var barrel = Color(0.3, 0.3, 0.35)
	var handle = Color(0.35, 0.22, 0.12)
	var handle_dk = Color(0.22, 0.14, 0.06)
	var muzzle = Color(0.2, 0.2, 0.22)
	var ol = Color(0.12, 0.12, 0.15)

	# Main barrel (horizontal)
	_fill(img, 10, 26, 40, 6, barrel)
	_fill(img, 12, 24, 36, 2, metal_dk)
	_fill(img, 12, 32, 36, 2, metal_dk)
	# Barrel highlight
	_fill(img, 14, 27, 34, 2, metal)

	# Muzzle
	_fill(img, 50, 24, 8, 10, muzzle)
	_fill(img, 52, 22, 4, 2, muzzle)
	_fill(img, 52, 34, 4, 2, muzzle)
	# Flash hider slits
	_px(img, 54, 26, metal_lt)
	_px(img, 54, 32, metal_lt)

	# Receiver body
	_fill(img, 14, 20, 24, 6, metal)
	_fill(img, 16, 18, 20, 4, metal_dk)
	_fill(img, 18, 20, 16, 2, metal_lt)

	# Magazine
	_fill(img, 22, 34, 10, 14, metal_dk)
	_fill(img, 24, 36, 6, 10, metal)
	# Magazine curve
	_fill(img, 20, 44, 4, 4, metal_dk)

	# Stock
	_fill(img, 4, 22, 10, 10, handle)
	_fill(img, 2, 24, 4, 6, handle_dk)
	_fill(img, 6, 24, 6, 6, handle)
	# Stock pad
	_fill(img, 2, 26, 3, 3, Color(0.15, 0.15, 0.18))

	# Grip
	_fill(img, 16, 34, 5, 10, handle)
	_fill(img, 17, 36, 3, 6, handle_dk)

	# Sight
	_fill(img, 32, 16, 4, 4, metal)
	_fill(img, 33, 14, 2, 2, metal_lt)

	_outline(img, ol)
	_save(img, "machinegun.png")

func _gen_staff() -> void:
	var img = _img()
	var wood = Color(0.5, 0.32, 0.18)
	var wood_dk = Color(0.35, 0.22, 0.10)
	var wood_lt = Color(0.62, 0.42, 0.25)
	var gem = Color(0.3, 0.5, 0.9)
	var gem_br = Color(0.5, 0.7, 1.0)
	var gold = Color(0.85, 0.72, 0.18)
	var gold_dk = Color(0.65, 0.52, 0.10)
	var glow = Color(0.3, 0.5, 0.9, 0.3)
	var ol = Color(0.2, 0.12, 0.06)

	# Staff shaft (vertical)
	_fill(img, 29, 12, 6, 48, wood)
	_fill(img, 28, 14, 1, 44, wood_dk)
	_fill(img, 31, 14, 2, 44, wood_lt)

	# Gold bands
	_fill(img, 27, 20, 10, 3, gold)
	_fill(img, 27, 40, 10, 3, gold)
	_fill(img, 28, 21, 8, 1, gold_dk)
	_fill(img, 28, 41, 8, 1, gold_dk)

	# Orb holder (gold crown)
	_fill(img, 26, 10, 12, 4, gold)
	_fill(img, 24, 8, 16, 3, gold_dk)
	_fill(img, 25, 6, 3, 4, gold)
	_fill(img, 36, 6, 3, 4, gold)
	_fill(img, 28, 5, 8, 2, gold)

	# Magic orb
	_circle(img, 32, 4, 6, glow)
	_circle(img, 32, 3, 4, gem)
	_circle(img, 32, 2, 2, gem_br)
	_px(img, 31, 1, Color.WHITE)

	# Bottom cap
	_fill(img, 28, 58, 8, 4, gold)
	_fill(img, 29, 60, 6, 2, gold_dk)

	_outline(img, ol)
	_save(img, "staff.png")

func _gen_bazooka() -> void:
	var img = _img()
	var tube = Color(0.3, 0.35, 0.2)
	var tube_dk = Color(0.2, 0.24, 0.12)
	var tube_lt = Color(0.4, 0.45, 0.28)
	var metal = Color(0.45, 0.45, 0.48)
	var metal_dk = Color(0.3, 0.3, 0.33)
	var handle = Color(0.3, 0.2, 0.1)
	var sight = Color(0.5, 0.5, 0.55)
	var ol = Color(0.1, 0.12, 0.06)

	# Main tube (angled diagonal for dramatic look)
	_fill(img, 6, 24, 48, 10, tube)
	_fill(img, 8, 22, 44, 2, tube_dk)
	_fill(img, 8, 34, 44, 2, tube_dk)
	# Tube highlight
	_fill(img, 10, 26, 40, 3, tube_lt)

	# Front opening
	_fill(img, 52, 22, 6, 14, tube_dk)
	_circle(img, 55, 29, 5, Color(0.1, 0.1, 0.12))
	_circle(img, 55, 29, 3, Color(0.15, 0.15, 0.18))

	# Rear flare
	_fill(img, 2, 22, 6, 14, tube_dk)
	_fill(img, 0, 24, 4, 10, tube)

	# Grip/trigger assembly
	_fill(img, 24, 34, 6, 12, handle)
	_fill(img, 25, 36, 4, 8, Color(0.25, 0.15, 0.06))

	# Front grip
	_fill(img, 38, 34, 5, 8, handle)

	# Iron sight
	_fill(img, 30, 18, 4, 6, sight)
	_fill(img, 31, 16, 2, 2, metal)

	# Shoulder rest
	_fill(img, 6, 34, 10, 4, metal_dk)
	_fill(img, 8, 36, 6, 3, metal)

	# Warning stripes (military look)
	for i in range(3):
		_fill(img, 42 + i * 3, 26, 2, 1, Color(0.8, 0.7, 0.1))

	_outline(img, ol)
	_save(img, "bazooka.png")

func _gen_shuriken() -> void:
	var img = _img()
	var blade = Color(0.6, 0.62, 0.65)
	var blade_dk = Color(0.4, 0.42, 0.45)
	var blade_lt = Color(0.78, 0.80, 0.85)
	var center = Color(0.3, 0.3, 0.35)
	var ol = Color(0.15, 0.15, 0.2)

	# 4-pointed star shape
	# Center
	_circle(img, 32, 32, 5, center)
	_circle(img, 32, 32, 3, blade_dk)

	# Top blade
	_fill(img, 29, 8, 6, 20, blade)
	_fill(img, 30, 4, 4, 6, blade)
	_fill(img, 31, 2, 2, 3, blade_lt)
	_fill(img, 28, 12, 2, 14, blade_dk)
	_fill(img, 34, 12, 2, 14, blade_dk)

	# Bottom blade
	_fill(img, 29, 36, 6, 20, blade)
	_fill(img, 30, 54, 4, 6, blade)
	_fill(img, 31, 59, 2, 3, blade_lt)
	_fill(img, 28, 38, 2, 14, blade_dk)
	_fill(img, 34, 38, 2, 14, blade_dk)

	# Left blade
	_fill(img, 8, 29, 20, 6, blade)
	_fill(img, 4, 30, 6, 4, blade)
	_fill(img, 2, 31, 3, 2, blade_lt)
	_fill(img, 12, 28, 14, 2, blade_dk)
	_fill(img, 12, 34, 14, 2, blade_dk)

	# Right blade
	_fill(img, 36, 29, 20, 6, blade)
	_fill(img, 54, 30, 6, 4, blade)
	_fill(img, 59, 31, 3, 2, blade_lt)
	_fill(img, 38, 28, 14, 2, blade_dk)
	_fill(img, 38, 34, 14, 2, blade_dk)

	# Center hole
	_circle(img, 32, 32, 2, Color(0.15, 0.15, 0.18))

	# Edge highlights
	_px(img, 31, 2, Color.WHITE)
	_px(img, 31, 61, Color.WHITE)
	_px(img, 2, 31, Color.WHITE)
	_px(img, 61, 31, Color.WHITE)

	_outline(img, ol)
	_save(img, "shuriken.png")

func _gen_dual_pistol() -> void:
	var img = _img()
	var metal = Color(0.35, 0.35, 0.4)
	var metal_dk = Color(0.2, 0.2, 0.25)
	var metal_lt = Color(0.5, 0.5, 0.55)
	var handle = Color(0.3, 0.18, 0.08)
	var handle_dk = Color(0.2, 0.12, 0.05)
	var gold = Color(0.75, 0.62, 0.15)
	var ol = Color(0.1, 0.1, 0.14)

	# Left pistol (top)
	_fill(img, 8, 10, 28, 5, metal)
	_fill(img, 10, 8, 24, 2, metal_dk)
	_fill(img, 36, 10, 6, 4, metal_dk)
	_fill(img, 10, 12, 2, 2, metal_lt)
	# Left barrel
	_fill(img, 38, 10, 10, 4, metal)
	_fill(img, 40, 8, 6, 2, metal_dk)
	# Left muzzle
	_fill(img, 46, 9, 4, 6, Color(0.18, 0.18, 0.2))
	# Left grip
	_fill(img, 12, 15, 6, 14, handle)
	_fill(img, 13, 17, 4, 10, handle_dk)
	# Left trigger guard
	_fill(img, 18, 15, 8, 2, metal_dk)
	_fill(img, 20, 17, 4, 4, metal_dk)
	# Left trigger
	_px(img, 22, 18, gold)

	# Right pistol (bottom, offset)
	_fill(img, 12, 36, 28, 5, metal)
	_fill(img, 14, 34, 24, 2, metal_dk)
	_fill(img, 40, 36, 6, 4, metal_dk)
	_fill(img, 14, 38, 2, 2, metal_lt)
	# Right barrel
	_fill(img, 42, 36, 10, 4, metal)
	_fill(img, 44, 34, 6, 2, metal_dk)
	# Right muzzle
	_fill(img, 50, 35, 4, 6, Color(0.18, 0.18, 0.2))
	# Right grip
	_fill(img, 16, 41, 6, 14, handle)
	_fill(img, 17, 43, 4, 10, handle_dk)
	# Right trigger guard
	_fill(img, 22, 41, 8, 2, metal_dk)
	_fill(img, 24, 43, 4, 4, metal_dk)
	# Right trigger
	_px(img, 26, 44, gold)

	# Gold accents
	_fill(img, 10, 14, 2, 1, gold)
	_fill(img, 14, 40, 2, 1, gold)

	_outline(img, ol)
	_save(img, "dual_pistol.png")

func _gen_flamethrower() -> void:
	var img = _img()
	var metal = Color(0.45, 0.35, 0.25)
	var metal_dk = Color(0.3, 0.22, 0.15)
	var metal_lt = Color(0.58, 0.48, 0.35)
	var tank = Color(0.5, 0.2, 0.1)
	var tank_dk = Color(0.35, 0.12, 0.06)
	var nozzle = Color(0.3, 0.3, 0.33)
	var fire = Color(1.0, 0.6, 0.1)
	var fire_br = Color(1.0, 0.85, 0.3)
	var ol = Color(0.18, 0.12, 0.06)

	# Fuel tank (back)
	_fill(img, 2, 18, 14, 24, tank)
	_fill(img, 4, 16, 10, 4, tank)
	_fill(img, 4, 42, 10, 2, tank_dk)
	_fill(img, 6, 20, 8, 18, tank_dk)
	# Tank highlight
	_fill(img, 4, 22, 3, 12, Color(0.6, 0.25, 0.12))
	# Tank straps
	_line_h(img, 2, 16, 22, metal)
	_line_h(img, 2, 16, 36, metal)

	# Barrel
	_fill(img, 16, 26, 32, 6, metal)
	_fill(img, 18, 24, 28, 2, metal_dk)
	_fill(img, 18, 32, 28, 2, metal_dk)
	_fill(img, 20, 27, 26, 2, metal_lt)

	# Nozzle (flared)
	_fill(img, 48, 22, 8, 14, nozzle)
	_fill(img, 50, 20, 6, 4, nozzle)
	_fill(img, 50, 34, 6, 4, nozzle)
	_fill(img, 54, 24, 4, 10, Color(0.2, 0.2, 0.22))

	# Fire coming out
	_fill(img, 56, 24, 4, 2, fire)
	_fill(img, 58, 26, 4, 2, fire_br)
	_fill(img, 56, 30, 4, 2, fire)
	_fill(img, 60, 28, 3, 2, fire_br)

	# Grip
	_fill(img, 26, 34, 6, 12, Color(0.3, 0.2, 0.1))
	_fill(img, 27, 36, 4, 8, Color(0.22, 0.14, 0.06))

	# Pilot light
	_fill(img, 46, 22, 3, 2, fire)
	_px(img, 47, 21, fire_br)

	_outline(img, ol)
	_save(img, "flamethrower.png")

func _gen_ice_staff() -> void:
	var img = _img()
	var wood = Color(0.35, 0.4, 0.5)
	var wood_dk = Color(0.22, 0.28, 0.38)
	var wood_lt = Color(0.48, 0.52, 0.62)
	var ice = Color(0.5, 0.8, 1.0)
	var ice_br = Color(0.75, 0.92, 1.0)
	var ice_dk = Color(0.3, 0.6, 0.85)
	var frost = Color(0.7, 0.9, 1.0, 0.4)
	var silver = Color(0.7, 0.72, 0.78)
	var ol = Color(0.12, 0.18, 0.25)

	# Staff shaft
	_fill(img, 29, 14, 6, 46, wood)
	_fill(img, 28, 16, 1, 42, wood_dk)
	_fill(img, 31, 16, 2, 42, wood_lt)

	# Ice crystal top (large, faceted)
	_fill(img, 26, 4, 12, 12, ice)
	_fill(img, 28, 2, 8, 4, ice)
	_fill(img, 30, 0, 4, 3, ice_br)
	_fill(img, 24, 6, 4, 8, ice_dk)
	_fill(img, 36, 6, 4, 8, ice_dk)
	# Crystal facets
	_fill(img, 28, 6, 2, 6, ice_br)
	_fill(img, 34, 8, 2, 4, ice_dk)
	# Inner glow
	_circle(img, 32, 8, 3, frost)
	_px(img, 31, 6, Color.WHITE)

	# Silver mounting
	_fill(img, 26, 14, 12, 3, silver)
	_fill(img, 28, 12, 8, 2, silver)

	# Frost accents on shaft
	_px(img, 27, 24, frost)
	_px(img, 35, 32, frost)
	_px(img, 27, 40, frost)

	# Silver bands
	_fill(img, 27, 28, 10, 2, silver)
	_fill(img, 27, 44, 10, 2, silver)

	# Bottom cap
	_fill(img, 28, 58, 8, 4, silver)

	_outline(img, ol)
	_save(img, "ice_staff.png")

func _gen_crossbow() -> void:
	var img = _img()
	var wood = Color(0.45, 0.3, 0.15)
	var wood_dk = Color(0.3, 0.2, 0.08)
	var wood_lt = Color(0.58, 0.4, 0.22)
	var metal = Color(0.5, 0.5, 0.55)
	var metal_dk = Color(0.35, 0.35, 0.4)
	var string_c = Color(0.7, 0.65, 0.55)
	var bolt = Color(0.55, 0.45, 0.3)
	var ol = Color(0.15, 0.1, 0.05)

	# Stock (horizontal)
	_fill(img, 4, 28, 36, 6, wood)
	_fill(img, 6, 26, 32, 2, wood_dk)
	_fill(img, 6, 34, 32, 2, wood_dk)
	_fill(img, 8, 29, 28, 2, wood_lt)

	# Bow arms (curved outward from front)
	# Top arm
	_fill(img, 36, 14, 4, 14, metal)
	_fill(img, 38, 10, 4, 6, metal)
	_fill(img, 40, 6, 4, 6, metal_dk)
	_fill(img, 42, 4, 4, 4, metal)
	_fill(img, 44, 2, 4, 3, metal_dk)
	# Bottom arm
	_fill(img, 36, 36, 4, 14, metal)
	_fill(img, 38, 48, 4, 6, metal)
	_fill(img, 40, 52, 4, 6, metal_dk)
	_fill(img, 42, 56, 4, 4, metal)
	_fill(img, 44, 59, 4, 3, metal_dk)

	# String
	_line_v(img, 44, 5, 30, string_c)
	_line_v(img, 44, 34, 59, string_c)

	# Bolt (loaded)
	_fill(img, 14, 30, 36, 2, bolt)
	_fill(img, 48, 29, 6, 4, metal)
	# Arrowhead
	_fill(img, 52, 30, 4, 2, metal)
	_px(img, 56, 31, metal_dk)

	# Trigger mechanism
	_fill(img, 14, 34, 6, 8, metal_dk)
	_fill(img, 15, 36, 4, 4, metal)
	# Trigger
	_px(img, 16, 42, metal)

	# Grip
	_fill(img, 4, 28, 6, 8, wood_dk)
	_fill(img, 2, 30, 4, 4, wood)

	_outline(img, ol)
	_save(img, "crossbow.png")

func _gen_plasma_cannon() -> void:
	var img = _img()
	var body = Color(0.2, 0.15, 0.35)
	var body_dk = Color(0.12, 0.08, 0.25)
	var body_lt = Color(0.3, 0.22, 0.48)
	var glow = Color(0.5, 0.3, 0.9)
	var glow_br = Color(0.7, 0.5, 1.0)
	var metal = Color(0.45, 0.45, 0.5)
	var metal_dk = Color(0.3, 0.3, 0.35)
	var ol = Color(0.08, 0.05, 0.15)

	# Main body
	_fill(img, 8, 22, 36, 14, body)
	_fill(img, 10, 20, 32, 2, body_dk)
	_fill(img, 10, 36, 32, 2, body_dk)
	_fill(img, 12, 24, 28, 4, body_lt)

	# Barrel (wide, futuristic)
	_fill(img, 42, 18, 14, 22, body)
	_fill(img, 44, 16, 10, 4, body_dk)
	_fill(img, 44, 38, 10, 4, body_dk)
	# Barrel opening
	_fill(img, 54, 20, 6, 18, metal_dk)
	_circle(img, 57, 29, 6, Color(0.08, 0.06, 0.12))
	_circle(img, 57, 29, 4, glow)
	_circle(img, 57, 29, 2, glow_br)

	# Glow lines on body
	_line_h(img, 14, 40, 26, glow)
	_line_h(img, 14, 40, 32, glow)
	_px(img, 38, 26, glow_br)
	_px(img, 38, 32, glow_br)

	# Power cell (back)
	_fill(img, 2, 24, 8, 10, metal)
	_fill(img, 4, 26, 4, 6, glow)
	_px(img, 5, 28, glow_br)

	# Grip
	_fill(img, 20, 38, 6, 12, body_dk)
	_fill(img, 21, 40, 4, 8, body)

	# Top rail
	_fill(img, 16, 18, 20, 2, metal)
	_fill(img, 24, 16, 8, 2, metal_dk)

	_outline(img, ol)
	_save(img, "plasma_cannon.png")

func _gen_elven_bow() -> void:
	var img = _img()
	var wood = Color(0.55, 0.4, 0.2)
	var wood_dk = Color(0.38, 0.28, 0.12)
	var wood_lt = Color(0.68, 0.52, 0.3)
	var leaf = Color(0.2, 0.6, 0.2)
	var leaf_lt = Color(0.3, 0.75, 0.3)
	var gold = Color(0.82, 0.7, 0.18)
	var string_c = Color(0.8, 0.78, 0.7)
	var ol = Color(0.18, 0.12, 0.05)

	# Bow body (elegant curve, vertical)
	# Upper limb
	_fill(img, 28, 4, 4, 8, wood)
	_fill(img, 26, 8, 4, 8, wood)
	_fill(img, 24, 14, 4, 8, wood_dk)
	_fill(img, 26, 20, 4, 6, wood)
	# Handle
	_fill(img, 28, 26, 6, 12, wood)
	_fill(img, 30, 28, 4, 8, wood_lt)
	# Lower limb
	_fill(img, 26, 38, 4, 6, wood)
	_fill(img, 24, 42, 4, 8, wood_dk)
	_fill(img, 26, 48, 4, 8, wood)
	_fill(img, 28, 54, 4, 8, wood)

	# Bow tips
	_fill(img, 28, 2, 4, 3, gold)
	_fill(img, 28, 60, 4, 3, gold)

	# String
	_line_v(img, 34, 3, 61, string_c)

	# Leaf decorations
	_fill(img, 22, 18, 4, 3, leaf)
	_fill(img, 20, 19, 2, 1, leaf_lt)
	_fill(img, 22, 44, 4, 3, leaf)
	_fill(img, 20, 45, 2, 1, leaf_lt)

	# Gold grip wrapping
	_fill(img, 28, 28, 6, 2, gold)
	_fill(img, 28, 34, 6, 2, gold)

	_outline(img, ol)
	_save(img, "elven_bow.png")

func _gen_boomerang() -> void:
	var img = _img()
	var wood = Color(0.6, 0.4, 0.15)
	var wood_dk = Color(0.42, 0.28, 0.08)
	var wood_lt = Color(0.75, 0.55, 0.25)
	var stripe = Color(0.2, 0.5, 0.8)
	var stripe_lt = Color(0.3, 0.6, 0.9)
	var ol = Color(0.2, 0.12, 0.04)

	# Boomerang V-shape (angled)
	# Left arm (going up-left)
	_fill(img, 8, 12, 6, 4, wood)
	_fill(img, 12, 14, 6, 4, wood)
	_fill(img, 16, 16, 6, 4, wood)
	_fill(img, 20, 18, 6, 4, wood)
	_fill(img, 24, 20, 6, 4, wood)
	# Corner (thicker)
	_fill(img, 28, 22, 8, 6, wood)
	_fill(img, 30, 24, 4, 2, wood_lt)
	# Right arm (going down-right)
	_fill(img, 34, 24, 6, 4, wood)
	_fill(img, 38, 26, 6, 4, wood)
	_fill(img, 42, 28, 6, 4, wood)
	_fill(img, 46, 30, 6, 4, wood)
	_fill(img, 50, 32, 6, 4, wood)

	# Dark edge (bottom of each arm)
	_fill(img, 8, 16, 6, 1, wood_dk)
	_fill(img, 12, 18, 6, 1, wood_dk)
	_fill(img, 16, 20, 6, 1, wood_dk)
	_fill(img, 20, 22, 6, 1, wood_dk)
	_fill(img, 38, 30, 6, 1, wood_dk)
	_fill(img, 42, 32, 6, 1, wood_dk)
	_fill(img, 46, 34, 6, 1, wood_dk)
	_fill(img, 50, 36, 6, 1, wood_dk)

	# Light edge (top)
	_fill(img, 8, 12, 6, 1, wood_lt)
	_fill(img, 12, 14, 6, 1, wood_lt)
	_fill(img, 34, 24, 6, 1, wood_lt)
	_fill(img, 46, 30, 6, 1, wood_lt)

	# Blue stripe decorations
	_fill(img, 10, 13, 4, 2, stripe)
	_fill(img, 18, 17, 4, 2, stripe)
	_fill(img, 40, 27, 4, 2, stripe)
	_fill(img, 48, 31, 4, 2, stripe)
	# Tips
	_fill(img, 6, 12, 3, 3, stripe_lt)
	_fill(img, 54, 33, 3, 3, stripe_lt)

	_outline(img, ol)
	_save(img, "boomerang.png")

# ==================== SUMMON/SPECIAL WEAPONS ====================

func _gen_necro() -> void:
	var img = _img()
	var bone = Color(0.82, 0.78, 0.68)
	var bone_dk = Color(0.62, 0.58, 0.48)
	var bone_lt = Color(0.92, 0.88, 0.80)
	var green = Color(0.2, 0.8, 0.3)
	var green_br = Color(0.4, 1.0, 0.5)
	var dark = Color(0.15, 0.1, 0.2)
	var ol = Color(0.2, 0.18, 0.12)

	# Skull
	_fill(img, 20, 6, 24, 18, bone)
	_fill(img, 22, 4, 20, 4, bone)
	_fill(img, 18, 10, 28, 12, bone)
	# Skull shading
	_fill(img, 18, 10, 4, 6, bone_dk)
	_fill(img, 42, 10, 4, 6, bone_dk)

	# Eye sockets
	_fill(img, 22, 10, 6, 6, dark)
	_fill(img, 36, 10, 6, 6, dark)
	# Green glow in eyes
	_fill(img, 23, 11, 4, 4, green)
	_fill(img, 37, 11, 4, 4, green)
	_px(img, 24, 12, green_br)
	_px(img, 38, 12, green_br)

	# Nose
	_fill(img, 30, 16, 4, 4, bone_dk)

	# Teeth
	_fill(img, 24, 22, 16, 3, bone)
	for i in range(4):
		_px(img, 25 + i * 4, 25, bone)
		_px(img, 25 + i * 4, 22, bone_dk)

	# Jaw
	_fill(img, 22, 24, 20, 4, bone_dk)
	_fill(img, 24, 26, 16, 2, bone)

	# Crossed bones below skull
	# Bone 1 (diagonal \)
	for i in range(20):
		_fill(img, 12 + i * 2, 30 + i, 3, 2, bone)
	# Bone 2 (diagonal /)
	for i in range(20):
		_fill(img, 50 - i * 2, 30 + i, 3, 2, bone)
	# Bone knobs
	_circle(img, 12, 30, 3, bone_lt)
	_circle(img, 52, 30, 3, bone_lt)
	_circle(img, 12, 50, 3, bone_lt)
	_circle(img, 52, 50, 3, bone_lt)

	# Green aura
	_circle(img, 32, 14, 18, Color(0.2, 0.7, 0.3, 0.15))

	_outline(img, ol)
	_save(img, "necro.png")

func _gen_drone() -> void:
	var img = _img()
	var body = Color(0.35, 0.38, 0.42)
	var body_dk = Color(0.22, 0.24, 0.28)
	var body_lt = Color(0.48, 0.50, 0.55)
	var prop = Color(0.5, 0.52, 0.55)
	var prop_dk = Color(0.35, 0.36, 0.4)
	var light_c = Color(0.2, 0.8, 1.0)
	var light_br = Color(0.4, 0.9, 1.0)
	var lens = Color(0.1, 0.1, 0.12)
	var ol = Color(0.1, 0.1, 0.14)

	# Main body (compact diamond/square shape)
	_fill(img, 22, 24, 20, 14, body)
	_fill(img, 24, 22, 16, 4, body_dk)
	_fill(img, 24, 36, 16, 4, body_dk)
	_fill(img, 26, 26, 12, 8, body_lt)

	# Camera/lens (center front)
	_circle(img, 32, 30, 4, lens)
	_circle(img, 32, 30, 2, light_c)
	_px(img, 32, 30, light_br)

	# Propeller arms (4 arms extending diagonally)
	# Top-left
	_fill(img, 12, 16, 12, 3, body_dk)
	_fill(img, 8, 12, 10, 3, prop)
	_fill(img, 6, 10, 12, 2, prop_dk)
	# Top-right
	_fill(img, 40, 16, 12, 3, body_dk)
	_fill(img, 46, 12, 10, 3, prop)
	_fill(img, 46, 10, 12, 2, prop_dk)
	# Bottom-left
	_fill(img, 12, 38, 12, 3, body_dk)
	_fill(img, 8, 42, 10, 3, prop)
	_fill(img, 6, 44, 12, 2, prop_dk)
	# Bottom-right
	_fill(img, 40, 38, 12, 3, body_dk)
	_fill(img, 46, 42, 10, 3, prop)
	_fill(img, 46, 44, 12, 2, prop_dk)

	# Propeller circles (blur effect)
	_circle(img, 12, 11, 6, Color(0.6, 0.62, 0.65, 0.3))
	_circle(img, 52, 11, 6, Color(0.6, 0.62, 0.65, 0.3))
	_circle(img, 12, 45, 6, Color(0.6, 0.62, 0.65, 0.3))
	_circle(img, 52, 45, 6, Color(0.6, 0.62, 0.65, 0.3))

	# LED lights
	_px(img, 22, 28, light_c)
	_px(img, 42, 28, light_c)
	_px(img, 22, 34, Color(1.0, 0.2, 0.1))
	_px(img, 42, 34, Color(1.0, 0.2, 0.1))

	# Landing gear (small feet)
	_fill(img, 24, 40, 4, 2, body_dk)
	_fill(img, 36, 40, 4, 2, body_dk)

	_outline(img, ol)
	_save(img, "drone.png")

func _gen_totem() -> void:
	var img = _img()
	var wood = Color(0.5, 0.35, 0.2)
	var wood_dk = Color(0.35, 0.22, 0.12)
	var wood_lt = Color(0.62, 0.45, 0.28)
	var electric = Color(1.0, 0.9, 0.2)
	var electric_br = Color(1.0, 1.0, 0.5)
	var eye_c = Color(0.2, 0.7, 1.0)
	var rune = Color(0.3, 0.8, 0.9)
	var ol = Color(0.18, 0.12, 0.06)

	# Totem pole body
	_fill(img, 22, 8, 20, 48, wood)
	_fill(img, 20, 12, 24, 40, wood)
	# Vertical texture
	_line_v(img, 26, 10, 54, wood_dk)
	_line_v(img, 36, 10, 54, wood_dk)
	_line_v(img, 31, 12, 52, wood_lt)

	# Top face (eagle/thunder)
	_fill(img, 18, 4, 28, 8, wood)
	_fill(img, 20, 2, 24, 4, wood_dk)
	# Eyes
	_fill(img, 24, 8, 4, 3, eye_c)
	_fill(img, 36, 8, 4, 3, eye_c)
	_px(img, 25, 9, electric_br)
	_px(img, 37, 9, electric_br)
	# Beak
	_fill(img, 30, 12, 4, 3, wood_dk)

	# Middle face
	_fill(img, 26, 24, 4, 3, eye_c)
	_fill(img, 34, 24, 4, 3, eye_c)
	_fill(img, 28, 28, 8, 2, wood_dk)

	# Bottom face
	_fill(img, 26, 40, 4, 3, eye_c)
	_fill(img, 34, 40, 4, 3, eye_c)
	_fill(img, 28, 44, 8, 3, wood_dk)

	# Lightning runes
	_px(img, 20, 18, rune)
	_px(img, 21, 19, rune)
	_px(img, 20, 20, rune)
	_px(img, 42, 18, rune)
	_px(img, 41, 19, rune)
	_px(img, 42, 20, rune)

	# Electric glow on top
	_px(img, 30, 0, electric)
	_px(img, 32, 0, electric)
	_px(img, 31, 1, electric_br)

	# Base
	_fill(img, 18, 54, 28, 4, wood_dk)
	_fill(img, 16, 56, 32, 4, wood)

	_outline(img, ol)
	_save(img, "totem.png")

func _gen_poison_bottle() -> void:
	var img = _img()
	var glass = Color(0.3, 0.55, 0.2, 0.8)
	var glass_dk = Color(0.2, 0.4, 0.12, 0.8)
	var glass_lt = Color(0.4, 0.7, 0.3, 0.7)
	var liquid = Color(0.35, 0.7, 0.15)
	var liquid_br = Color(0.5, 0.85, 0.25)
	var cork = Color(0.55, 0.4, 0.2)
	var cork_dk = Color(0.4, 0.28, 0.12)
	var skull = Color(0.85, 0.82, 0.72)
	var ol = Color(0.12, 0.2, 0.06)

	# Bottle body (round)
	_circle(img, 32, 36, 14, glass)
	_circle(img, 32, 34, 12, glass)
	_circle(img, 32, 32, 10, glass_lt)

	# Liquid inside
	_circle(img, 32, 38, 11, liquid)
	_circle(img, 32, 36, 8, liquid_br)
	_fill(img, 22, 36, 20, 12, liquid)

	# Bottle neck
	_fill(img, 28, 16, 8, 10, glass)
	_fill(img, 30, 14, 4, 4, glass)
	_fill(img, 29, 18, 2, 6, glass_lt)

	# Cork
	_fill(img, 29, 10, 6, 6, cork)
	_fill(img, 30, 8, 4, 4, cork)
	_fill(img, 31, 10, 2, 4, cork_dk)

	# Skull label
	_fill(img, 28, 30, 8, 8, skull)
	_fill(img, 29, 32, 2, 2, Color(0.1, 0.1, 0.1))
	_fill(img, 33, 32, 2, 2, Color(0.1, 0.1, 0.1))
	_fill(img, 30, 36, 4, 1, Color(0.1, 0.1, 0.1))

	# Bubbles
	_circle(img, 26, 42, 2, Color(0.5, 0.9, 0.3, 0.5))
	_circle(img, 36, 40, 1, Color(0.5, 0.9, 0.3, 0.5))
	_px(img, 30, 44, Color(0.5, 0.9, 0.3, 0.5))

	# Drip
	_fill(img, 38, 44, 2, 4, liquid)
	_px(img, 39, 48, liquid_br)

	_outline(img, ol)
	_save(img, "poison_bottle.png")

func _gen_lightning_chain() -> void:
	var img = _img()
	var chain = Color(0.6, 0.58, 0.5)
	var chain_dk = Color(0.4, 0.38, 0.32)
	var chain_lt = Color(0.75, 0.72, 0.62)
	var electric = Color(1.0, 0.9, 0.2)
	var electric_br = Color(1.0, 1.0, 0.5)
	var blue = Color(0.3, 0.5, 1.0)
	var ol = Color(0.2, 0.18, 0.12)

	# Chain links (vertical, overlapping)
	for i in range(6):
		var y_off = i * 9
		var is_even = (i % 2 == 0)
		var x_off = 28 if is_even else 32
		# Link outline
		_fill(img, x_off, 4 + y_off, 8, 10, chain)
		_fill(img, x_off + 2, 6 + y_off, 4, 6, Color(0, 0, 0, 0))
		# Link shading
		_fill(img, x_off, 4 + y_off, 2, 10, chain_dk)
		_fill(img, x_off + 6, 4 + y_off, 2, 10, chain_lt)

	# Lightning bolts between links
	for i in range(5):
		var y = 12 + i * 9
		# Zigzag bolt
		_px(img, 24, y, electric)
		_px(img, 22, y + 1, electric)
		_px(img, 24, y + 2, electric)
		_px(img, 40, y, electric)
		_px(img, 42, y + 1, electric)
		_px(img, 40, y + 2, electric)
		# Bright center
		_px(img, 23, y + 1, electric_br)
		_px(img, 41, y + 1, electric_br)

	# Electric aura
	_circle(img, 32, 32, 22, Color(0.3, 0.5, 1.0, 0.1))

	# Top ring (handle)
	_circle(img, 32, 4, 5, chain)
	_circle(img, 32, 4, 3, Color(0, 0, 0, 0))

	# Bottom weight (charged orb)
	_circle(img, 32, 58, 5, chain_dk)
	_circle(img, 32, 58, 3, blue)
	_circle(img, 32, 58, 1, electric_br)

	_outline(img, ol)
	_save(img, "lightning_chain.png")

func _gen_time_bomb() -> void:
	var img = _img()
	var metal = Color(0.3, 0.3, 0.35)
	var metal_dk = Color(0.18, 0.18, 0.22)
	var metal_lt = Color(0.45, 0.45, 0.5)
	var red = Color(0.8, 0.15, 0.1)
	var red_br = Color(1.0, 0.3, 0.2)
	var clock = Color(0.85, 0.82, 0.75)
	var fuse = Color(0.6, 0.45, 0.2)
	var spark = Color(1.0, 0.8, 0.2)
	var ol = Color(0.1, 0.1, 0.12)

	# Bomb body (round, classic cartoon bomb)
	_circle(img, 32, 34, 18, metal)
	_circle(img, 32, 32, 16, metal)
	_circle(img, 32, 30, 12, metal_lt)

	# Metal rivet band (equator)
	_line_h(img, 16, 48, 34, metal_dk)
	_line_h(img, 16, 48, 35, metal_dk)
	for i in range(5):
		_circle(img, 18 + i * 7, 34, 1, metal_lt)

	# Clock face (center)
	_circle(img, 32, 30, 8, clock)
	_circle(img, 32, 30, 7, Color(0.92, 0.90, 0.85))
	# Clock hands
	_line_v(img, 32, 24, 30, metal_dk)
	_line_h(img, 32, 37, 30, metal_dk)
	# Center dot
	_circle(img, 32, 30, 1, red)
	# Hour marks
	_px(img, 32, 23, metal_dk)
	_px(img, 39, 30, metal_dk)
	_px(img, 32, 37, metal_dk)
	_px(img, 25, 30, metal_dk)

	# Red light (blinking)
	_circle(img, 32, 42, 3, red)
	_circle(img, 32, 42, 1, red_br)

	# Fuse (top)
	_fill(img, 30, 12, 4, 6, fuse)
	_fill(img, 28, 8, 4, 6, fuse)
	_fill(img, 26, 4, 4, 6, fuse)
	# Spark at tip
	_px(img, 26, 2, spark)
	_px(img, 28, 3, spark)
	_px(img, 25, 4, Color(1.0, 0.5, 0.1))

	# Top nozzle
	_fill(img, 28, 14, 8, 4, metal_dk)
	_fill(img, 30, 16, 4, 2, metal)

	_outline(img, ol)
	_save(img, "time_bomb.png")

func _gen_portal_weapon() -> void:
	var img = _img()
	var ring = Color(0.4, 0.2, 0.7)
	var ring_dk = Color(0.25, 0.1, 0.5)
	var ring_lt = Color(0.6, 0.35, 0.85)
	var void_c = Color(0.05, 0.02, 0.1)
	var star = Color(0.8, 0.6, 1.0)
	var rune = Color(0.7, 0.4, 1.0)
	var rune_br = Color(0.9, 0.6, 1.0)
	var ol = Color(0.15, 0.08, 0.25)

	# Outer ring
	_circle(img, 32, 32, 24, ring)
	_circle(img, 32, 32, 20, ring_dk)
	_circle(img, 32, 32, 18, void_c)

	# Inner swirl/void
	_circle(img, 32, 32, 16, Color(0.08, 0.04, 0.15))
	_circle(img, 32, 32, 12, Color(0.12, 0.06, 0.22))
	_circle(img, 30, 30, 6, Color(0.2, 0.1, 0.35))
	_circle(img, 34, 34, 4, Color(0.15, 0.08, 0.28))

	# Stars inside portal
	_px(img, 28, 28, star)
	_px(img, 36, 30, star)
	_px(img, 30, 36, star)
	_px(img, 34, 26, star)
	_px(img, 26, 34, Color(0.6, 0.4, 0.8))

	# Ring highlight
	_circle(img, 32, 32, 22, Color(0, 0, 0, 0))  # clear inner part of outer ring
	# Top highlight arc
	for i in range(8):
		var angle = -1.2 + i * 0.15
		var x = int(32 + cos(angle) * 21)
		var y = int(32 + sin(angle) * 21)
		_px(img, x, y, ring_lt)

	# Rune markings on ring
	for i in range(6):
		var angle = i * PI / 3.0
		var x = int(32 + cos(angle) * 21)
		var y = int(32 + sin(angle) * 21)
		_px(img, x, y, rune)
		_px(img, x + 1, y, rune_br)

	# Energy wisps emanating
	_px(img, 10, 20, Color(0.6, 0.3, 0.9, 0.4))
	_px(img, 54, 22, Color(0.6, 0.3, 0.9, 0.4))
	_px(img, 12, 44, Color(0.6, 0.3, 0.9, 0.4))
	_px(img, 52, 42, Color(0.6, 0.3, 0.9, 0.4))

	_outline(img, ol)
	_save(img, "portal_weapon.png")

func _gen_tornado() -> void:
	var img = _img()
	var wind = Color(0.5, 0.7, 0.8)
	var wind_dk = Color(0.35, 0.55, 0.65)
	var wind_lt = Color(0.65, 0.82, 0.9)
	var white = Color(0.8, 0.9, 0.95)
	var debris = Color(0.5, 0.4, 0.3)
	var ol = Color(0.2, 0.3, 0.35)

	# Tornado funnel (wide at top, narrow at bottom)
	# Top (widest)
	_fill(img, 4, 4, 56, 6, wind)
	_fill(img, 6, 2, 52, 3, wind_dk)
	_fill(img, 8, 6, 48, 2, wind_lt)

	_fill(img, 8, 10, 48, 5, wind_dk)
	_fill(img, 10, 12, 44, 2, wind)

	_fill(img, 12, 16, 40, 5, wind)
	_fill(img, 14, 18, 36, 2, wind_lt)

	_fill(img, 16, 22, 32, 5, wind_dk)
	_fill(img, 18, 24, 28, 2, wind)

	_fill(img, 20, 28, 24, 5, wind)
	_fill(img, 22, 30, 20, 2, wind_lt)

	_fill(img, 24, 34, 16, 5, wind_dk)
	_fill(img, 26, 36, 12, 2, wind)

	_fill(img, 26, 40, 12, 5, wind)
	_fill(img, 28, 42, 8, 2, wind_lt)

	_fill(img, 28, 46, 8, 5, wind_dk)
	_fill(img, 30, 48, 4, 2, wind)

	# Bottom tip
	_fill(img, 30, 52, 4, 4, wind)
	_fill(img, 31, 56, 2, 4, wind_dk)

	# Swirl lines (white streaks)
	_line_h(img, 8, 20, 5, white)
	_line_h(img, 36, 50, 8, white)
	_line_h(img, 14, 26, 17, white)
	_line_h(img, 32, 42, 23, white)
	_line_h(img, 22, 30, 29, white)
	_line_h(img, 26, 34, 41, white)

	# Debris
	_px(img, 16, 8, debris)
	_px(img, 42, 14, debris)
	_px(img, 24, 22, debris)
	_px(img, 38, 32, debris)

	_outline(img, ol)
	_save(img, "tornado.png")

func _gen_blood_orb() -> void:
	var img = _img()
	var blood = Color(0.6, 0.05, 0.05)
	var blood_dk = Color(0.4, 0.02, 0.02)
	var blood_lt = Color(0.8, 0.12, 0.1)
	var blood_br = Color(0.95, 0.2, 0.15)
	var glow = Color(0.7, 0.1, 0.1, 0.3)
	var dark = Color(0.2, 0.02, 0.02)
	var ol = Color(0.25, 0.02, 0.02)

	# Red aura
	_circle(img, 32, 32, 26, glow)
	_circle(img, 32, 30, 20, Color(0.6, 0.08, 0.08, 0.2))

	# Orb body
	_circle(img, 32, 32, 16, blood)
	_circle(img, 32, 30, 14, blood)
	_circle(img, 32, 28, 10, blood_lt)

	# Specular highlight
	_circle(img, 28, 24, 4, blood_br)
	_circle(img, 26, 22, 2, Color(0.95, 0.4, 0.35))
	_px(img, 25, 21, Color(1.0, 0.6, 0.5))

	# Dark depth
	_circle(img, 36, 38, 6, blood_dk)
	_circle(img, 34, 36, 4, dark)

	# Blood drips (bottom)
	_fill(img, 26, 46, 3, 6, blood)
	_fill(img, 27, 52, 1, 3, blood_dk)
	_fill(img, 34, 44, 3, 8, blood)
	_fill(img, 35, 52, 1, 4, blood_dk)
	_fill(img, 30, 48, 2, 4, blood)

	# Pulsing veins on surface
	_px(img, 22, 30, blood_dk)
	_px(img, 21, 32, blood_dk)
	_px(img, 42, 28, blood_dk)
	_px(img, 43, 30, blood_dk)

	_outline(img, ol)
	_save(img, "blood_orb.png")
