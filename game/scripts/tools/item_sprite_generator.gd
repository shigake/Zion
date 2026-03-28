extends SceneTree

## Generates 16x16 pixel art sprites for all 19 items and 12 evolutions.
## Run: godot --headless --script res://scripts/tools/item_sprite_generator.gd

const S := 16  # Sprite size

func _init() -> void:
	_generate_all()
	quit()

func _generate_all() -> void:
	DirAccess.make_dir_recursive_absolute("res://assets/sprites/items")
	DirAccess.make_dir_recursive_absolute("res://assets/sprites/evolutions")

	# Items (19)
	_gen_boots()
	_gen_glove()
	_gen_heart()
	_gen_crystal()
	_gen_magnet()
	_gen_clock()
	_gen_cape()
	_gen_xp_amulet()
	_gen_gunpowder()
	_gen_tesla()
	_gen_vampire_blood()
	_gen_thorn_shield()
	_gen_lucky_coin()
	_gen_quiver()
	_gen_grimoire()
	_gen_giant_elixir()
	_gen_gasoline()
	_gen_crown()
	_gen_laser_sight()

	# Evolutions (12)
	_gen_zangetsu()
	_gen_apocalypse_staff()
	_gen_death_scythe()
	_gen_nuke_launcher()
	_gen_ragnarok_axe()
	_gen_blizzard_star()
	_gen_minigun_infernal()
	_gen_lord_of_dead()
	_gen_inferno_walker()
	_gen_vampire_whip()
	_gen_electric_storm()
	_gen_arrow_storm()

	print("All item and evolution sprites generated!")

# ==================== HELPERS ====================
func _img() -> Image:
	return Image.create(S, S, false, Image.FORMAT_RGBA8)

func _fill(img: Image, x: int, y: int, w: int, h: int, color: Color) -> void:
	for px in range(maxi(x, 0), mini(x + w, S)):
		for py in range(maxi(y, 0), mini(y + h, S)):
			img.set_pixel(px, py, color)

func _px(img: Image, x: int, y: int, color: Color) -> void:
	if x >= 0 and x < S and y >= 0 and y < S:
		img.set_pixel(x, y, color)

func _outline(img: Image, color: Color) -> void:
	var out = Image.create(S, S, false, Image.FORMAT_RGBA8)
	for x in range(S):
		for y in range(S):
			if img.get_pixel(x, y).a > 0:
				continue
			for off in [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]:
				var nx = x + off.x
				var ny = y + off.y
				if nx >= 0 and nx < S and ny >= 0 and ny < S:
					if img.get_pixel(nx, ny).a > 0:
						out.set_pixel(x, y, color)
						break
	for x in range(S):
		for y in range(S):
			if out.get_pixel(x, y).a > 0:
				img.set_pixel(x, y, out.get_pixel(x, y))

func _save(img: Image, path: String) -> void:
	img.save_png(path)
	print("Saved: ", path)

# ==================== ITEMS (19) ====================

func _gen_boots() -> void:
	var img = _img()
	var brown = Color(0.55, 0.35, 0.18)
	var brown_hi = Color(0.7, 0.48, 0.25)
	var sole = Color(0.3, 0.18, 0.08)
	var wing = Color(0.9, 0.88, 0.78)
	var wing_hi = Color(1.0, 1.0, 0.95)

	# Left boot
	_fill(img, 2, 8, 4, 5, brown)
	_fill(img, 1, 13, 5, 2, sole)
	_fill(img, 2, 8, 2, 1, brown_hi)
	# Right boot
	_fill(img, 9, 8, 4, 5, brown)
	_fill(img, 9, 13, 5, 2, sole)
	_fill(img, 9, 8, 2, 1, brown_hi)
	# Wings on left boot
	_px(img, 0, 7, wing)
	_px(img, 0, 8, wing_hi)
	_px(img, 0, 9, wing)
	_px(img, 1, 6, wing_hi)
	_px(img, 1, 7, wing)
	# Wings on right boot
	_px(img, 14, 7, wing)
	_px(img, 14, 8, wing_hi)
	_px(img, 14, 9, wing)
	_px(img, 15, 6, wing_hi)
	_px(img, 15, 7, wing)

	_outline(img, Color(0.15, 0.08, 0.04))
	_save(img, "res://assets/sprites/items/boots.png")

func _gen_glove() -> void:
	var img = _img()
	var red = Color(0.85, 0.15, 0.15)
	var red_hi = Color(1.0, 0.35, 0.3)
	var red_dk = Color(0.6, 0.08, 0.08)
	var cuff = Color(0.9, 0.85, 0.7)

	# Glove body
	_fill(img, 4, 5, 8, 8, red)
	_fill(img, 5, 13, 6, 2, red_dk)
	# Fingers
	_fill(img, 4, 3, 2, 3, red)
	_fill(img, 6, 2, 2, 4, red)
	_fill(img, 8, 3, 2, 3, red)
	_fill(img, 10, 4, 2, 2, red)
	# Thumb
	_fill(img, 2, 6, 2, 3, red)
	# Highlight
	_fill(img, 5, 5, 2, 3, red_hi)
	_px(img, 5, 3, red_hi)
	_px(img, 7, 2, red_hi)
	# Cuff
	_fill(img, 4, 13, 8, 1, cuff)

	_outline(img, Color(0.2, 0.02, 0.02))
	_save(img, "res://assets/sprites/items/glove.png")

func _gen_heart() -> void:
	var img = _img()
	var red = Color(0.9, 0.15, 0.2)
	var red_hi = Color(1.0, 0.4, 0.45)
	var glow = Color(1.0, 0.6, 0.6, 0.5)

	# Heart shape
	_fill(img, 2, 4, 4, 2, red)
	_fill(img, 9, 4, 4, 2, red)
	_fill(img, 1, 5, 6, 3, red)
	_fill(img, 8, 5, 6, 3, red)
	_fill(img, 2, 8, 11, 2, red)
	_fill(img, 3, 10, 9, 1, red)
	_fill(img, 4, 11, 7, 1, red)
	_fill(img, 5, 12, 5, 1, red)
	_fill(img, 6, 13, 3, 1, red)
	_fill(img, 7, 14, 1, 1, red)
	# Highlight
	_px(img, 3, 5, red_hi)
	_px(img, 4, 5, red_hi)
	_px(img, 3, 6, red_hi)
	# Glow
	_px(img, 1, 3, glow)
	_px(img, 0, 5, glow)
	_px(img, 14, 5, glow)

	_outline(img, Color(0.25, 0.02, 0.05))
	_save(img, "res://assets/sprites/items/heart.png")

func _gen_crystal() -> void:
	var img = _img()
	var purple = Color(0.55, 0.2, 0.75)
	var purple_hi = Color(0.75, 0.4, 0.95)
	var purple_dk = Color(0.35, 0.1, 0.5)
	var sparkle = Color(0.95, 0.85, 1.0)

	# Main crystal body (hexagonal shape)
	_fill(img, 6, 2, 4, 2, purple_hi)
	_fill(img, 5, 4, 6, 4, purple)
	_fill(img, 4, 6, 8, 3, purple)
	_fill(img, 5, 9, 6, 3, purple_dk)
	_fill(img, 6, 12, 4, 2, purple_dk)
	# Highlight facet
	_fill(img, 6, 3, 2, 3, purple_hi)
	_px(img, 7, 2, sparkle)
	_px(img, 6, 5, sparkle)
	# Dark facet
	_fill(img, 9, 7, 2, 3, purple_dk)

	_outline(img, Color(0.15, 0.05, 0.22))
	_save(img, "res://assets/sprites/items/crystal.png")

func _gen_magnet() -> void:
	var img = _img()
	var gray = Color(0.55, 0.55, 0.58)
	var gray_hi = Color(0.7, 0.7, 0.75)
	var red_tip = Color(0.85, 0.15, 0.15)
	var blue_tip = Color(0.15, 0.15, 0.85)

	# Left arm of horseshoe
	_fill(img, 2, 3, 3, 8, gray)
	_fill(img, 2, 3, 2, 3, gray_hi)
	# Right arm
	_fill(img, 10, 3, 3, 8, gray)
	_fill(img, 10, 3, 2, 3, gray_hi)
	# Top curve
	_fill(img, 5, 1, 5, 2, gray)
	_fill(img, 4, 2, 2, 2, gray)
	_fill(img, 9, 2, 2, 2, gray)
	_fill(img, 5, 1, 3, 1, gray_hi)
	# Red tip (left)
	_fill(img, 2, 11, 3, 3, red_tip)
	# Blue tip (right)
	_fill(img, 10, 11, 3, 3, blue_tip)

	_outline(img, Color(0.12, 0.12, 0.15))
	_save(img, "res://assets/sprites/items/magnet.png")

func _gen_clock() -> void:
	var img = _img()
	var brown = Color(0.6, 0.42, 0.2)
	var face = Color(0.95, 0.92, 0.82)
	var hand = Color(0.15, 0.12, 0.1)
	var gold = Color(0.85, 0.75, 0.3)

	# Clock body (circle-ish)
	_fill(img, 4, 2, 8, 2, brown)
	_fill(img, 3, 4, 10, 8, brown)
	_fill(img, 4, 12, 8, 2, brown)
	# Clock face (inner)
	_fill(img, 5, 4, 6, 2, face)
	_fill(img, 4, 5, 8, 5, face)
	_fill(img, 5, 10, 6, 1, face)
	# Hour hand (pointing up)
	_px(img, 7, 4, hand)
	_px(img, 7, 5, hand)
	_px(img, 7, 6, hand)
	# Minute hand (pointing right)
	_px(img, 8, 7, hand)
	_px(img, 9, 7, hand)
	_px(img, 10, 7, hand)
	# Center dot
	_px(img, 7, 7, hand)
	_px(img, 8, 8, hand)
	# Top knob
	_fill(img, 6, 1, 4, 1, gold)
	_fill(img, 7, 0, 2, 1, gold)
	# Hour marks
	_px(img, 7, 4, hand)
	_px(img, 11, 7, hand)
	_px(img, 7, 10, hand)
	_px(img, 4, 7, hand)

	_outline(img, Color(0.18, 0.12, 0.05))
	_save(img, "res://assets/sprites/items/clock.png")

func _gen_cape() -> void:
	var img = _img()
	var purple = Color(0.35, 0.12, 0.45)
	var purple_hi = Color(0.5, 0.2, 0.6)
	var purple_dk = Color(0.22, 0.06, 0.3)
	var clasp = Color(0.85, 0.75, 0.3)

	# Cape body (flowing shape)
	_fill(img, 4, 3, 8, 2, purple_hi)
	_fill(img, 3, 5, 10, 4, purple)
	_fill(img, 2, 9, 12, 3, purple)
	_fill(img, 1, 12, 14, 2, purple_dk)
	_fill(img, 2, 14, 12, 1, purple_dk)
	# Folds/highlights
	_fill(img, 5, 4, 2, 4, purple_hi)
	_fill(img, 9, 5, 2, 3, purple_hi)
	# Dark folds
	_fill(img, 7, 7, 1, 5, purple_dk)
	_fill(img, 4, 10, 1, 3, purple_dk)
	_fill(img, 11, 10, 1, 3, purple_dk)
	# Gold clasp at top
	_fill(img, 5, 2, 6, 1, clasp)
	_px(img, 7, 1, clasp)
	_px(img, 8, 1, clasp)

	_outline(img, Color(0.1, 0.02, 0.12))
	_save(img, "res://assets/sprites/items/cape.png")

func _gen_xp_amulet() -> void:
	var img = _img()
	var blue = Color(0.2, 0.4, 0.9)
	var blue_hi = Color(0.45, 0.65, 1.0)
	var gold = Color(0.85, 0.75, 0.3)
	var chain = Color(0.7, 0.6, 0.25)
	var glow = Color(0.6, 0.8, 1.0, 0.5)

	# Chain
	_px(img, 5, 1, chain)
	_px(img, 6, 2, chain)
	_px(img, 10, 1, chain)
	_px(img, 9, 2, chain)
	_px(img, 7, 3, chain)
	_px(img, 8, 3, chain)
	# Amulet frame (gold)
	_fill(img, 5, 5, 6, 1, gold)
	_fill(img, 4, 6, 8, 5, gold)
	_fill(img, 5, 11, 6, 1, gold)
	# Blue gem center
	_fill(img, 6, 6, 4, 1, blue)
	_fill(img, 5, 7, 6, 3, blue)
	_fill(img, 6, 10, 4, 1, blue)
	# Highlight
	_px(img, 6, 7, blue_hi)
	_px(img, 7, 7, blue_hi)
	_px(img, 6, 8, blue_hi)
	# Glow
	_px(img, 3, 7, glow)
	_px(img, 12, 8, glow)
	_px(img, 7, 12, glow)

	_outline(img, Color(0.05, 0.1, 0.25))
	_save(img, "res://assets/sprites/items/xp_amulet.png")

func _gen_gunpowder() -> void:
	var img = _img()
	var gray = Color(0.45, 0.42, 0.4)
	var gray_dk = Color(0.3, 0.28, 0.25)
	var wood = Color(0.55, 0.38, 0.2)
	var fuse = Color(0.8, 0.65, 0.3)
	var spark = Color(1.0, 0.85, 0.3)

	# Keg body
	_fill(img, 4, 5, 8, 8, gray)
	_fill(img, 3, 6, 10, 6, gray)
	# Darker bands
	_fill(img, 4, 7, 8, 1, gray_dk)
	_fill(img, 4, 10, 8, 1, gray_dk)
	# Top
	_fill(img, 5, 4, 6, 1, gray)
	# Wood lid
	_fill(img, 5, 4, 6, 1, wood)
	# Fuse
	_px(img, 8, 3, fuse)
	_px(img, 9, 2, fuse)
	_px(img, 10, 1, fuse)
	# Spark at tip
	_px(img, 11, 0, spark)
	_px(img, 10, 0, spark)
	_px(img, 11, 1, spark)

	_outline(img, Color(0.12, 0.1, 0.08))
	_save(img, "res://assets/sprites/items/gunpowder.png")

func _gen_tesla() -> void:
	var img = _img()
	var yellow = Color(0.9, 0.85, 0.2)
	var yellow_hi = Color(1.0, 1.0, 0.5)
	var body = Color(0.35, 0.35, 0.38)
	var body_hi = Color(0.5, 0.5, 0.55)
	var bolt = Color(1.0, 0.95, 0.3)

	# Battery body
	_fill(img, 4, 4, 8, 10, body)
	_fill(img, 5, 3, 6, 1, body)
	# Top terminal
	_fill(img, 6, 1, 4, 2, body_hi)
	_fill(img, 7, 0, 2, 1, yellow)
	# Highlight
	_fill(img, 5, 4, 2, 5, body_hi)
	# Lightning bolt symbol
	_px(img, 8, 5, bolt)
	_px(img, 7, 6, bolt)
	_px(img, 6, 7, bolt)
	_fill(img, 6, 8, 4, 1, bolt)
	_px(img, 9, 9, bolt)
	_px(img, 8, 10, bolt)
	_px(img, 7, 11, bolt)
	# Yellow band at bottom
	_fill(img, 4, 12, 8, 2, yellow)
	_fill(img, 5, 12, 4, 1, yellow_hi)

	_outline(img, Color(0.1, 0.1, 0.12))
	_save(img, "res://assets/sprites/items/tesla.png")

func _gen_vampire_blood() -> void:
	var img = _img()
	var glass = Color(0.7, 0.65, 0.75)
	var blood = Color(0.75, 0.08, 0.12)
	var blood_hi = Color(0.9, 0.2, 0.25)
	var cork = Color(0.6, 0.45, 0.25)

	# Vial body
	_fill(img, 5, 6, 6, 7, glass)
	_fill(img, 4, 7, 8, 5, glass)
	# Neck
	_fill(img, 6, 3, 4, 3, glass)
	# Cork
	_fill(img, 6, 1, 4, 2, cork)
	# Blood inside
	_fill(img, 5, 8, 6, 5, blood)
	_fill(img, 6, 7, 4, 1, blood)
	# Blood highlight
	_px(img, 6, 8, blood_hi)
	_px(img, 7, 8, blood_hi)
	_px(img, 6, 9, blood_hi)
	# Glass highlight
	_px(img, 5, 7, Color(0.85, 0.85, 0.9))
	_px(img, 5, 6, Color(0.85, 0.85, 0.9))

	_outline(img, Color(0.2, 0.02, 0.05))
	_save(img, "res://assets/sprites/items/vampire_blood.png")

func _gen_thorn_shield() -> void:
	var img = _img()
	var green = Color(0.2, 0.55, 0.18)
	var green_hi = Color(0.35, 0.7, 0.3)
	var green_dk = Color(0.1, 0.35, 0.08)
	var thorn = Color(0.45, 0.65, 0.25)

	# Shield body
	_fill(img, 4, 2, 8, 2, green)
	_fill(img, 3, 4, 10, 4, green)
	_fill(img, 4, 8, 8, 2, green)
	_fill(img, 5, 10, 6, 2, green)
	_fill(img, 6, 12, 4, 1, green)
	_fill(img, 7, 13, 2, 1, green)
	# Highlight
	_fill(img, 5, 3, 3, 3, green_hi)
	# Dark edge
	_fill(img, 9, 6, 2, 3, green_dk)
	# Thorns poking out
	_px(img, 2, 5, thorn)
	_px(img, 1, 6, thorn)
	_px(img, 13, 5, thorn)
	_px(img, 14, 6, thorn)
	_px(img, 2, 8, thorn)
	_px(img, 13, 8, thorn)
	_px(img, 4, 11, thorn)
	_px(img, 11, 11, thorn)
	_px(img, 3, 3, thorn)
	_px(img, 12, 3, thorn)

	_outline(img, Color(0.04, 0.15, 0.02))
	_save(img, "res://assets/sprites/items/thorn_shield.png")

func _gen_lucky_coin() -> void:
	var img = _img()
	var gold = Color(0.85, 0.75, 0.2)
	var gold_hi = Color(1.0, 0.9, 0.4)
	var gold_dk = Color(0.65, 0.55, 0.12)
	var clover = Color(0.2, 0.7, 0.15)

	# Coin (circle)
	_fill(img, 5, 2, 6, 2, gold)
	_fill(img, 4, 4, 8, 1, gold)
	_fill(img, 3, 5, 10, 6, gold)
	_fill(img, 4, 11, 8, 1, gold)
	_fill(img, 5, 12, 6, 2, gold)
	# Highlight
	_fill(img, 5, 3, 3, 2, gold_hi)
	_fill(img, 4, 5, 2, 3, gold_hi)
	# Dark edge
	_fill(img, 10, 8, 2, 3, gold_dk)
	_fill(img, 8, 12, 3, 1, gold_dk)
	# Clover (center)
	_px(img, 7, 6, clover)
	_px(img, 8, 6, clover)
	_px(img, 6, 7, clover)
	_px(img, 9, 7, clover)
	_px(img, 7, 8, clover)
	_px(img, 8, 8, clover)
	_px(img, 7, 7, clover)
	_px(img, 8, 7, clover)
	# Stem
	_px(img, 7, 9, clover)
	_px(img, 7, 10, clover)

	_outline(img, Color(0.22, 0.18, 0.04))
	_save(img, "res://assets/sprites/items/lucky_coin.png")

func _gen_quiver() -> void:
	var img = _img()
	var brown = Color(0.55, 0.35, 0.18)
	var brown_hi = Color(0.7, 0.48, 0.25)
	var arrow_shaft = Color(0.6, 0.5, 0.3)
	var arrow_tip = Color(0.7, 0.72, 0.75)
	var feather = Color(0.9, 0.3, 0.2)

	# Quiver body
	_fill(img, 5, 5, 6, 10, brown)
	_fill(img, 6, 4, 4, 1, brown)
	_fill(img, 4, 6, 1, 8, brown)
	# Highlight
	_fill(img, 6, 6, 2, 5, brown_hi)
	# Strap
	_px(img, 4, 4, brown_hi)
	_px(img, 3, 3, brown_hi)
	_px(img, 2, 2, brown_hi)
	# Arrows sticking out
	_px(img, 6, 3, arrow_shaft)
	_px(img, 6, 2, arrow_shaft)
	_px(img, 6, 1, arrow_tip)
	_px(img, 8, 3, arrow_shaft)
	_px(img, 8, 2, arrow_shaft)
	_px(img, 8, 1, arrow_tip)
	_px(img, 10, 4, arrow_shaft)
	_px(img, 10, 3, arrow_shaft)
	_px(img, 10, 2, arrow_tip)
	# Feathers
	_px(img, 5, 3, feather)
	_px(img, 7, 3, feather)
	_px(img, 9, 4, feather)

	_outline(img, Color(0.15, 0.08, 0.04))
	_save(img, "res://assets/sprites/items/quiver.png")

func _gen_grimoire() -> void:
	var img = _img()
	var green_dk = Color(0.12, 0.3, 0.12)
	var green = Color(0.18, 0.42, 0.18)
	var green_hi = Color(0.25, 0.55, 0.22)
	var pages = Color(0.92, 0.88, 0.78)
	var symbol = Color(0.6, 0.85, 0.4)

	# Book cover
	_fill(img, 3, 3, 10, 11, green_dk)
	_fill(img, 4, 2, 9, 1, green_dk)
	_fill(img, 4, 14, 9, 1, green_dk)
	# Front face
	_fill(img, 4, 3, 8, 10, green)
	# Highlight
	_fill(img, 5, 4, 3, 4, green_hi)
	# Pages (visible on left spine)
	_fill(img, 3, 4, 1, 9, pages)
	# Arcane symbol (star/pentagram)
	_px(img, 8, 5, symbol)
	_px(img, 7, 6, symbol)
	_px(img, 9, 6, symbol)
	_px(img, 6, 7, symbol)
	_px(img, 10, 7, symbol)
	_px(img, 7, 8, symbol)
	_px(img, 9, 8, symbol)
	_px(img, 8, 9, symbol)
	_px(img, 8, 7, symbol)
	# Clasp
	_px(img, 12, 7, Color(0.7, 0.6, 0.2))
	_px(img, 12, 8, Color(0.7, 0.6, 0.2))

	_outline(img, Color(0.04, 0.1, 0.04))
	_save(img, "res://assets/sprites/items/grimoire.png")

func _gen_giant_elixir() -> void:
	var img = _img()
	var glass = Color(0.65, 0.55, 0.75)
	var purple = Color(0.6, 0.15, 0.75)
	var purple_hi = Color(0.8, 0.35, 0.95)
	var cork = Color(0.6, 0.45, 0.25)

	# Bottle body (round bottom)
	_fill(img, 4, 7, 8, 5, glass)
	_fill(img, 3, 8, 10, 3, glass)
	_fill(img, 5, 12, 6, 2, glass)
	# Neck
	_fill(img, 6, 3, 4, 4, glass)
	# Cork
	_fill(img, 6, 1, 4, 2, cork)
	# Purple liquid
	_fill(img, 4, 9, 8, 3, purple)
	_fill(img, 5, 12, 6, 1, purple)
	_fill(img, 3, 9, 1, 2, purple)
	_fill(img, 12, 9, 1, 2, purple)
	# Highlight
	_px(img, 5, 9, purple_hi)
	_px(img, 5, 10, purple_hi)
	# Bubbles
	_px(img, 8, 10, purple_hi)
	_px(img, 10, 9, purple_hi)
	# Glass shine
	_px(img, 4, 7, Color(0.85, 0.82, 0.9))
	_px(img, 6, 4, Color(0.85, 0.82, 0.9))

	_outline(img, Color(0.15, 0.04, 0.2))
	_save(img, "res://assets/sprites/items/giant_elixir.png")

func _gen_gasoline() -> void:
	var img = _img()
	var red = Color(0.8, 0.18, 0.12)
	var red_hi = Color(0.95, 0.35, 0.28)
	var red_dk = Color(0.55, 0.1, 0.08)
	var cap = Color(0.4, 0.4, 0.42)
	var label = Color(0.9, 0.85, 0.7)

	# Can body
	_fill(img, 3, 5, 10, 9, red)
	_fill(img, 4, 4, 8, 1, red)
	# Highlight
	_fill(img, 4, 5, 2, 5, red_hi)
	# Dark side
	_fill(img, 11, 6, 1, 7, red_dk)
	# Cap/nozzle
	_fill(img, 9, 2, 3, 3, cap)
	_fill(img, 10, 1, 2, 1, cap)
	# Handle
	_fill(img, 5, 2, 4, 1, red_dk)
	_fill(img, 5, 2, 1, 2, red_dk)
	# Label
	_fill(img, 5, 8, 6, 3, label)

	_outline(img, Color(0.2, 0.04, 0.02))
	_save(img, "res://assets/sprites/items/gasoline.png")

func _gen_crown() -> void:
	var img = _img()
	var gold = Color(0.85, 0.75, 0.2)
	var gold_hi = Color(1.0, 0.92, 0.45)
	var gold_dk = Color(0.65, 0.55, 0.12)
	var jewel_r = Color(0.85, 0.12, 0.15)
	var jewel_b = Color(0.15, 0.3, 0.85)
	var jewel_g = Color(0.15, 0.75, 0.2)

	# Crown base band
	_fill(img, 2, 9, 12, 4, gold)
	_fill(img, 3, 13, 10, 1, gold_dk)
	# Points
	_fill(img, 2, 5, 3, 4, gold)
	_fill(img, 7, 4, 2, 5, gold)
	_fill(img, 11, 5, 3, 4, gold)
	# Tips of points
	_px(img, 3, 4, gold_hi)
	_px(img, 7, 3, gold_hi)
	_px(img, 8, 3, gold_hi)
	_px(img, 12, 4, gold_hi)
	# Highlights
	_fill(img, 3, 6, 1, 3, gold_hi)
	_fill(img, 3, 9, 5, 1, gold_hi)
	# Jewels
	_px(img, 3, 10, jewel_r)
	_px(img, 3, 11, jewel_r)
	_px(img, 7, 10, jewel_b)
	_px(img, 8, 10, jewel_b)
	_px(img, 12, 10, jewel_g)
	_px(img, 12, 11, jewel_g)

	_outline(img, Color(0.22, 0.18, 0.04))
	_save(img, "res://assets/sprites/items/crown.png")

func _gen_laser_sight() -> void:
	var img = _img()
	var body = Color(0.35, 0.32, 0.35)
	var body_hi = Color(0.5, 0.48, 0.52)
	var red = Color(1.0, 0.1, 0.1)
	var red_glow = Color(1.0, 0.3, 0.3, 0.6)
	var beam = Color(1.0, 0.15, 0.15, 0.8)

	# Laser device body
	_fill(img, 2, 6, 6, 4, body)
	_fill(img, 3, 5, 4, 1, body)
	_fill(img, 3, 10, 4, 1, body)
	# Highlight
	_fill(img, 3, 6, 2, 2, body_hi)
	# Lens
	_px(img, 8, 7, red)
	_px(img, 8, 8, red)
	# Beam
	_px(img, 9, 7, beam)
	_px(img, 10, 7, beam)
	_px(img, 11, 8, beam)
	_px(img, 12, 8, beam)
	_px(img, 13, 8, beam)
	_px(img, 14, 8, beam)
	# Beam glow
	_px(img, 9, 8, red_glow)
	_px(img, 10, 8, red_glow)
	_px(img, 11, 7, red_glow)
	_px(img, 12, 7, red_glow)
	# Dot at end
	_px(img, 15, 8, red)
	_px(img, 15, 7, red_glow)

	_outline(img, Color(0.1, 0.08, 0.1))
	_save(img, "res://assets/sprites/items/laser_sight.png")

# ==================== EVOLUTIONS (12) ====================

func _gen_zangetsu() -> void:
	var img = _img()
	var blade = Color(0.12, 0.1, 0.15)
	var blade_hi = Color(0.25, 0.2, 0.3)
	var edge = Color(0.8, 0.15, 0.15)
	var energy = Color(0.9, 0.2, 0.25, 0.7)

	# Large blade (diagonal)
	for i in range(12):
		_px(img, 13 - i, 1 + i, blade)
		_px(img, 14 - i, 1 + i, blade)
		_px(img, 14 - i, 2 + i, blade)
	# Red energy edge
	for i in range(10):
		_px(img, 15 - i, 1 + i, edge)
	# Handle
	_fill(img, 1, 13, 2, 2, Color(0.5, 0.12, 0.12))
	# Energy glow
	_px(img, 13, 2, energy)
	_px(img, 11, 4, energy)
	_px(img, 9, 6, energy)
	_px(img, 7, 8, energy)

	_outline(img, Color(0.05, 0.04, 0.06))
	_save(img, "res://assets/sprites/evolutions/zangetsu.png")

func _gen_apocalypse_staff() -> void:
	var img = _img()
	var shaft = Color(0.4, 0.2, 0.5)
	var shaft_hi = Color(0.55, 0.3, 0.65)
	var orb = Color(0.7, 0.25, 0.1)
	var orb_hi = Color(1.0, 0.5, 0.2)
	var glow = Color(0.9, 0.4, 0.15, 0.5)

	# Staff shaft
	_fill(img, 7, 5, 2, 10, shaft)
	_px(img, 7, 5, shaft_hi)
	_px(img, 7, 6, shaft_hi)
	# Orb at top
	_fill(img, 6, 1, 4, 2, orb)
	_fill(img, 5, 2, 6, 3, orb)
	_fill(img, 6, 5, 4, 1, orb)
	# Orb highlight
	_px(img, 6, 2, orb_hi)
	_px(img, 7, 2, orb_hi)
	_px(img, 6, 3, orb_hi)
	# Glow
	_px(img, 4, 2, glow)
	_px(img, 11, 3, glow)
	_px(img, 5, 5, glow)
	_px(img, 10, 1, glow)
	# Prongs
	_px(img, 5, 5, shaft)
	_px(img, 10, 5, shaft)
	_px(img, 4, 4, shaft)
	_px(img, 11, 4, shaft)

	_outline(img, Color(0.12, 0.05, 0.15))
	_save(img, "res://assets/sprites/evolutions/apocalypse_staff.png")

func _gen_death_scythe() -> void:
	var img = _img()
	var blade = Color(0.45, 0.15, 0.55)
	var blade_hi = Color(0.65, 0.3, 0.75)
	var glow = Color(0.8, 0.45, 0.9, 0.6)
	var handle = Color(0.3, 0.22, 0.18)

	# Handle (vertical shaft)
	_fill(img, 7, 4, 2, 11, handle)
	# Blade (curved top, large)
	_fill(img, 8, 1, 6, 2, blade)
	_fill(img, 11, 3, 3, 1, blade)
	_fill(img, 12, 4, 2, 1, blade)
	_fill(img, 13, 5, 1, 2, blade)
	# Left extension
	_fill(img, 3, 1, 5, 1, blade)
	_fill(img, 2, 2, 3, 1, blade)
	# Edge highlight
	_fill(img, 8, 1, 6, 1, blade_hi)
	_px(img, 13, 3, blade_hi)
	_px(img, 14, 4, blade_hi)
	# Glow
	_px(img, 14, 2, glow)
	_px(img, 12, 5, glow)
	_px(img, 6, 1, glow)
	_px(img, 2, 1, glow)

	_outline(img, Color(0.12, 0.04, 0.15))
	_save(img, "res://assets/sprites/evolutions/death_scythe.png")

func _gen_nuke_launcher() -> void:
	var img = _img()
	var body = Color(0.25, 0.45, 0.2)
	var body_hi = Color(0.35, 0.6, 0.3)
	var barrel = Color(0.3, 0.3, 0.32)
	var rad = Color(0.9, 0.85, 0.15)
	var rad_dk = Color(0.1, 0.1, 0.1)

	# Launcher body
	_fill(img, 1, 7, 10, 4, body)
	_fill(img, 2, 6, 8, 1, body)
	# Barrel
	_fill(img, 10, 8, 5, 2, barrel)
	_fill(img, 15, 7, 1, 4, barrel)
	# Highlight
	_fill(img, 2, 7, 3, 1, body_hi)
	# Handle/grip
	_fill(img, 4, 11, 3, 3, body)
	_fill(img, 5, 11, 1, 3, body_hi)
	# Radiation symbol on side (simplified)
	_px(img, 6, 8, rad)
	_px(img, 7, 8, rad)
	_px(img, 6, 9, rad)
	_px(img, 7, 9, rad)
	_px(img, 5, 9, rad)
	_px(img, 8, 9, rad)
	# Center dot
	_px(img, 6, 9, rad_dk)

	_outline(img, Color(0.06, 0.12, 0.04))
	_save(img, "res://assets/sprites/evolutions/nuke_launcher.png")

func _gen_ragnarok_axe() -> void:
	var img = _img()
	var blade = Color(0.85, 0.72, 0.2)
	var blade_hi = Color(1.0, 0.9, 0.45)
	var fire = Color(0.95, 0.4, 0.1)
	var fire_hi = Color(1.0, 0.7, 0.2)
	var handle = Color(0.5, 0.35, 0.2)

	# Handle
	_fill(img, 7, 6, 2, 9, handle)
	# Axe head left
	_fill(img, 2, 1, 5, 2, blade)
	_fill(img, 3, 3, 5, 2, blade)
	_fill(img, 5, 5, 3, 1, blade)
	# Axe head right
	_fill(img, 9, 1, 5, 2, blade)
	_fill(img, 9, 3, 5, 2, blade)
	_fill(img, 9, 5, 2, 1, blade)
	# Highlights
	_fill(img, 2, 1, 3, 1, blade_hi)
	_fill(img, 11, 1, 3, 1, blade_hi)
	# Flames
	_px(img, 1, 1, fire)
	_px(img, 1, 0, fire_hi)
	_px(img, 14, 1, fire)
	_px(img, 14, 0, fire_hi)
	_px(img, 3, 0, fire)
	_px(img, 12, 0, fire)
	_px(img, 0, 2, fire_hi)
	_px(img, 15, 2, fire_hi)

	_outline(img, Color(0.22, 0.18, 0.04))
	_save(img, "res://assets/sprites/evolutions/ragnarok_axe.png")

func _gen_blizzard_star() -> void:
	var img = _img()
	var ice = Color(0.45, 0.7, 0.9)
	var ice_hi = Color(0.7, 0.9, 1.0)
	var ice_dk = Color(0.25, 0.45, 0.7)
	var sparkle = Color(0.95, 0.98, 1.0)

	# Star points (8 directions)
	# Center
	_fill(img, 6, 6, 4, 4, ice)
	_fill(img, 7, 7, 2, 2, ice_hi)
	# Up
	_fill(img, 7, 2, 2, 4, ice)
	_px(img, 7, 1, ice_hi)
	_px(img, 8, 1, ice_hi)
	# Down
	_fill(img, 7, 10, 2, 4, ice)
	_px(img, 7, 14, ice_dk)
	# Left
	_fill(img, 2, 7, 4, 2, ice)
	_px(img, 1, 7, ice_hi)
	# Right
	_fill(img, 10, 7, 4, 2, ice)
	_px(img, 14, 8, ice_dk)
	# Diagonal points
	_px(img, 4, 4, ice)
	_px(img, 3, 3, ice_hi)
	_px(img, 11, 4, ice)
	_px(img, 12, 3, ice_hi)
	_px(img, 4, 11, ice)
	_px(img, 3, 12, ice_dk)
	_px(img, 11, 11, ice)
	_px(img, 12, 12, ice_dk)
	# Sparkles
	_px(img, 0, 0, sparkle)
	_px(img, 15, 0, sparkle)
	_px(img, 0, 15, sparkle)
	_px(img, 15, 15, sparkle)

	_outline(img, Color(0.1, 0.2, 0.35))
	_save(img, "res://assets/sprites/evolutions/blizzard_star.png")

func _gen_minigun_infernal() -> void:
	var img = _img()
	var metal = Color(0.55, 0.25, 0.2)
	var metal_hi = Color(0.75, 0.35, 0.28)
	var glow = Color(1.0, 0.35, 0.1)
	var glow_hi = Color(1.0, 0.6, 0.2, 0.6)
	var barrel = Color(0.4, 0.15, 0.12)

	# Body
	_fill(img, 1, 6, 9, 5, metal)
	_fill(img, 2, 5, 7, 1, metal)
	# Highlight
	_fill(img, 2, 6, 3, 2, metal_hi)
	# Barrels (3 horizontal tubes)
	_fill(img, 10, 6, 5, 1, barrel)
	_fill(img, 10, 8, 5, 1, barrel)
	_fill(img, 10, 10, 5, 1, barrel)
	# Barrel tips glow
	_px(img, 15, 6, glow)
	_px(img, 15, 8, glow)
	_px(img, 15, 10, glow)
	# Glow aura
	_px(img, 14, 5, glow_hi)
	_px(img, 14, 11, glow_hi)
	_px(img, 15, 7, glow_hi)
	_px(img, 15, 9, glow_hi)
	# Handle
	_fill(img, 3, 11, 3, 3, metal)
	_fill(img, 4, 11, 1, 3, metal_hi)

	_outline(img, Color(0.15, 0.05, 0.04))
	_save(img, "res://assets/sprites/evolutions/minigun_infernal.png")

func _gen_lord_of_dead() -> void:
	var img = _img()
	var skull = Color(0.7, 0.78, 0.65)
	var skull_hi = Color(0.85, 0.9, 0.8)
	var eye = Color(0.2, 0.8, 0.15)
	var eye_glow = Color(0.3, 1.0, 0.2, 0.5)
	var crown = Color(0.7, 0.6, 0.15)

	# Skull
	_fill(img, 4, 5, 8, 4, skull)
	_fill(img, 3, 6, 10, 3, skull)
	_fill(img, 5, 9, 6, 2, skull)
	_fill(img, 5, 4, 6, 1, skull)
	# Highlight
	_fill(img, 5, 5, 3, 2, skull_hi)
	# Eyes
	_fill(img, 5, 6, 2, 2, eye)
	_fill(img, 9, 6, 2, 2, eye)
	# Nose
	_px(img, 7, 8, Color(0.4, 0.45, 0.35))
	_px(img, 8, 8, Color(0.4, 0.45, 0.35))
	# Teeth
	_px(img, 5, 9, skull_hi)
	_px(img, 7, 9, skull_hi)
	_px(img, 9, 9, skull_hi)
	# Crown on top
	_fill(img, 3, 2, 10, 2, crown)
	_px(img, 4, 1, crown)
	_px(img, 8, 1, crown)
	_px(img, 12, 1, crown)
	_px(img, 4, 0, crown)
	_px(img, 8, 0, crown)
	_px(img, 12, 0, crown)
	# Eye glow
	_px(img, 4, 6, eye_glow)
	_px(img, 11, 6, eye_glow)
	_px(img, 5, 5, eye_glow)
	_px(img, 10, 5, eye_glow)
	# Jaw
	_fill(img, 5, 11, 6, 1, skull)
	_fill(img, 6, 12, 4, 1, skull)

	_outline(img, Color(0.08, 0.12, 0.05))
	_save(img, "res://assets/sprites/evolutions/lord_of_dead.png")

func _gen_inferno_walker() -> void:
	var img = _img()
	var boot = Color(0.55, 0.2, 0.1)
	var boot_hi = Color(0.7, 0.3, 0.15)
	var fire = Color(1.0, 0.45, 0.1)
	var fire_hi = Color(1.0, 0.7, 0.2)
	var fire_dk = Color(0.8, 0.2, 0.05)

	# Boot
	_fill(img, 4, 6, 7, 5, boot)
	_fill(img, 3, 11, 9, 2, boot)
	_fill(img, 5, 5, 4, 1, boot)
	# Highlight
	_fill(img, 5, 6, 2, 3, boot_hi)
	# Sole
	_fill(img, 3, 13, 9, 1, Color(0.3, 0.1, 0.05))
	# Fire trail behind/below
	_px(img, 2, 12, fire)
	_px(img, 1, 11, fire_hi)
	_px(img, 1, 12, fire)
	_px(img, 0, 11, fire_hi)
	_px(img, 0, 10, fire_hi)
	_px(img, 12, 12, fire)
	_px(img, 13, 11, fire_hi)
	_px(img, 13, 12, fire)
	_px(img, 14, 10, fire_hi)
	# Fire on top
	_px(img, 5, 4, fire)
	_px(img, 6, 3, fire_hi)
	_px(img, 7, 2, fire)
	_px(img, 8, 3, fire_hi)
	_px(img, 9, 4, fire)
	_px(img, 7, 1, fire_hi)
	# Embers
	_px(img, 4, 1, fire_dk)
	_px(img, 10, 2, fire_dk)
	_px(img, 15, 9, fire_dk)

	_outline(img, Color(0.18, 0.06, 0.02))
	_save(img, "res://assets/sprites/evolutions/inferno_walker.png")

func _gen_vampire_whip() -> void:
	var img = _img()
	var blood = Color(0.75, 0.08, 0.12)
	var blood_hi = Color(0.95, 0.25, 0.3)
	var blood_dk = Color(0.5, 0.04, 0.08)
	var handle = Color(0.3, 0.08, 0.05)

	# Handle (bottom left)
	_fill(img, 1, 12, 3, 3, handle)
	_fill(img, 2, 11, 2, 1, handle)
	# Blood whip coiling up and right
	_px(img, 3, 10, blood)
	_px(img, 4, 9, blood)
	_px(img, 4, 10, blood_dk)
	_px(img, 5, 8, blood)
	_px(img, 5, 9, blood_dk)
	_px(img, 5, 7, blood)
	_px(img, 6, 6, blood)
	_px(img, 7, 5, blood)
	_px(img, 8, 4, blood)
	_px(img, 9, 3, blood)
	_px(img, 10, 2, blood)
	_px(img, 11, 1, blood)
	_px(img, 12, 1, blood_hi)
	_px(img, 13, 2, blood_hi)
	# Blood drips
	_px(img, 6, 7, blood_dk)
	_px(img, 8, 5, blood_dk)
	_px(img, 10, 3, blood_dk)
	_px(img, 12, 2, blood_hi)
	# Extra thickness
	_px(img, 7, 6, blood)
	_px(img, 9, 4, blood)
	_px(img, 11, 2, blood)
	# Splatter
	_px(img, 14, 1, blood_hi)
	_px(img, 13, 0, blood)
	_px(img, 14, 3, blood_dk)

	_outline(img, Color(0.2, 0.02, 0.04))
	_save(img, "res://assets/sprites/evolutions/vampire_whip.png")

func _gen_electric_storm() -> void:
	var img = _img()
	var yellow = Color(1.0, 0.9, 0.2)
	var yellow_hi = Color(1.0, 1.0, 0.6)
	var blue = Color(0.4, 0.6, 1.0)
	var white = Color(0.95, 0.95, 1.0)
	var glow = Color(1.0, 0.95, 0.5, 0.4)

	# Vortex center
	_fill(img, 6, 6, 4, 4, yellow)
	_fill(img, 7, 7, 2, 2, white)
	# Lightning bolts radiating out
	# Top bolt
	_px(img, 7, 5, yellow)
	_px(img, 6, 4, yellow)
	_px(img, 7, 3, yellow_hi)
	_px(img, 6, 2, yellow)
	_px(img, 7, 1, yellow_hi)
	# Right bolt
	_px(img, 10, 7, yellow)
	_px(img, 11, 6, yellow)
	_px(img, 12, 7, yellow_hi)
	_px(img, 13, 6, yellow)
	# Bottom bolt
	_px(img, 8, 10, yellow)
	_px(img, 9, 11, yellow)
	_px(img, 8, 12, yellow_hi)
	_px(img, 9, 13, yellow)
	# Left bolt
	_px(img, 5, 8, yellow)
	_px(img, 4, 9, yellow)
	_px(img, 3, 8, yellow_hi)
	_px(img, 2, 9, yellow)
	# Blue electric arcs
	_px(img, 4, 3, blue)
	_px(img, 12, 4, blue)
	_px(img, 11, 12, blue)
	_px(img, 3, 11, blue)
	# Glow
	_px(img, 5, 5, glow)
	_px(img, 10, 5, glow)
	_px(img, 5, 10, glow)
	_px(img, 10, 10, glow)

	_outline(img, Color(0.25, 0.22, 0.05))
	_save(img, "res://assets/sprites/evolutions/electric_storm.png")

func _gen_arrow_storm() -> void:
	var img = _img()
	var shaft = Color(0.3, 0.55, 0.25)
	var shaft_hi = Color(0.45, 0.7, 0.35)
	var tip = Color(0.7, 0.72, 0.75)
	var feather = Color(0.2, 0.45, 0.18)

	# Multiple arrows raining down at slight angles
	# Arrow 1 (left)
	_px(img, 2, 2, tip)
	_px(img, 2, 3, shaft)
	_px(img, 2, 4, shaft)
	_px(img, 2, 5, shaft)
	_px(img, 2, 6, shaft)
	_px(img, 1, 6, feather)
	_px(img, 3, 6, feather)
	# Arrow 2 (center-left)
	_px(img, 5, 4, tip)
	_px(img, 5, 5, shaft)
	_px(img, 5, 6, shaft)
	_px(img, 5, 7, shaft)
	_px(img, 5, 8, shaft)
	_px(img, 4, 8, feather)
	_px(img, 6, 8, feather)
	# Arrow 3 (center)
	_px(img, 8, 1, tip)
	_px(img, 8, 2, shaft_hi)
	_px(img, 8, 3, shaft)
	_px(img, 8, 4, shaft)
	_px(img, 8, 5, shaft)
	_px(img, 7, 5, feather)
	_px(img, 9, 5, feather)
	# Arrow 4 (center-right)
	_px(img, 11, 5, tip)
	_px(img, 11, 6, shaft)
	_px(img, 11, 7, shaft)
	_px(img, 11, 8, shaft)
	_px(img, 11, 9, shaft)
	_px(img, 10, 9, feather)
	_px(img, 12, 9, feather)
	# Arrow 5 (right)
	_px(img, 14, 3, tip)
	_px(img, 14, 4, shaft)
	_px(img, 14, 5, shaft)
	_px(img, 14, 6, shaft)
	_px(img, 14, 7, shaft)
	_px(img, 13, 7, feather)
	_px(img, 15, 7, feather)
	# Additional arrows (lower, more spread)
	_px(img, 4, 10, tip)
	_px(img, 4, 11, shaft)
	_px(img, 4, 12, shaft)
	_px(img, 4, 13, shaft)
	_px(img, 3, 13, feather)
	# Arrow lower right
	_px(img, 10, 11, tip)
	_px(img, 10, 12, shaft)
	_px(img, 10, 13, shaft)
	_px(img, 10, 14, shaft)
	_px(img, 9, 14, feather)
	_px(img, 11, 14, feather)

	_outline(img, Color(0.06, 0.15, 0.04))
	_save(img, "res://assets/sprites/evolutions/arrow_storm.png")
