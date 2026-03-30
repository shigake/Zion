extends SceneTree

func _init() -> void:
	var img = Image.create(32, 32, false, Image.FORMAT_RGBA8)
	var skin = Color(0.35, 0.22, 0.15)
	var skin_light = Color(0.42, 0.28, 0.18)
	var hair = Color(0.12, 0.06, 0.18)  # Dark purple-black
	var hat = Color(0.18, 0.08, 0.28)
	var hat_dark = Color(0.12, 0.05, 0.2)
	var hat_band = Color(0.55, 0.18, 0.65)
	var moon = Color(0.95, 0.9, 0.5)  # Moon crescent on hat
	var dress = Color(0.22, 0.08, 0.32)
	var dress_light = Color(0.35, 0.15, 0.48)
	var dress_accent = Color(0.5, 0.2, 0.6)
	var cape = Color(0.12, 0.04, 0.18)
	var glow = Color(0.4, 0.85, 0.25)  # Green magic
	var glow_purple = Color(0.6, 0.3, 0.9)
	var cat_black = Color(0.08, 0.06, 0.1)
	var cat_eye = Color(0.9, 0.75, 0.1)  # Yellow cat eyes
	var wand = Color(0.35, 0.18, 0.08)
	var wand_gem = Color(0.3, 0.9, 0.4)
	var gold = Color(0.9, 0.8, 0.2)
	var outline = Color(0.06, 0.03, 0.08)

	# === POINTY HAT (taller, more detailed) ===
	img.set_pixel(15, 0, hat)
	_fill(img, 14, 1, 3, 1, hat)
	_fill(img, 13, 2, 5, 1, hat)
	_fill(img, 12, 3, 7, 1, hat)
	_fill(img, 11, 4, 9, 2, hat)
	# Hat brim (wider)
	_fill(img, 8, 6, 15, 1, hat_dark)
	# Hat band with moon crescent
	_fill(img, 11, 5, 9, 1, hat_band)
	# Moon crescent on hat
	img.set_pixel(14, 4, moon)
	img.set_pixel(15, 3, moon)
	img.set_pixel(15, 4, moon)
	# Hat tip star
	img.set_pixel(15, 0, glow_purple)

	# === HAIR (flowing, longer) ===
	_fill(img, 10, 7, 2, 5, hair)
	_fill(img, 19, 7, 2, 5, hair)
	# Hair strands flowing down
	_fill(img, 9, 9, 1, 4, hair)
	_fill(img, 20, 9, 1, 4, hair)

	# === FACE (more detailed) ===
	_fill(img, 12, 7, 7, 3, skin)
	_fill(img, 13, 7, 5, 1, skin_light)  # Forehead highlight
	# Eyes (bright green, witchy)
	img.set_pixel(13, 8, Color(0.15, 0.75, 0.2))
	img.set_pixel(14, 8, Color(0.05, 0.15, 0.05))  # pupil
	img.set_pixel(17, 8, Color(0.15, 0.75, 0.2))
	img.set_pixel(16, 8, Color(0.05, 0.15, 0.05))  # pupil
	# Eye shine
	img.set_pixel(13, 7, Color(0.9, 0.95, 1.0, 0.4))
	img.set_pixel(17, 7, Color(0.9, 0.95, 1.0, 0.4))
	# Lips
	img.set_pixel(14, 9, Color(0.5, 0.2, 0.25))
	img.set_pixel(15, 9, Color(0.5, 0.2, 0.25))
	img.set_pixel(16, 9, Color(0.5, 0.2, 0.25))

	# === NECK + NECKLACE ===
	_fill(img, 14, 10, 3, 1, skin)
	img.set_pixel(14, 10, gold)
	img.set_pixel(16, 10, gold)
	img.set_pixel(15, 10, glow)  # Gem pendant

	# === DRESS BODY (corset style) ===
	_fill(img, 11, 11, 9, 3, dress)
	# Corset lacing
	img.set_pixel(15, 11, dress_accent)
	img.set_pixel(15, 12, dress_accent)
	img.set_pixel(15, 13, dress_accent)
	# Dress accent trim
	_fill(img, 11, 11, 1, 3, dress_accent)
	_fill(img, 19, 11, 1, 3, dress_accent)

	# === CAPE/SHAWL ===
	_fill(img, 9, 11, 2, 6, cape)
	_fill(img, 20, 11, 2, 6, cape)
	# Cape inner glow
	img.set_pixel(9, 13, dress_light)
	img.set_pixel(20, 13, dress_light)

	# === BELT with potions ===
	_fill(img, 11, 14, 9, 1, Color(0.35, 0.2, 0.08))
	img.set_pixel(12, 14, Color(0.3, 0.85, 0.3))   # Green potion
	img.set_pixel(14, 14, Color(0.85, 0.3, 0.85))   # Purple potion
	img.set_pixel(16, 14, Color(0.3, 0.5, 0.9))     # Blue potion
	img.set_pixel(18, 14, gold)                       # Belt buckle

	# === ARMS ===
	_fill(img, 8, 12, 1, 3, skin)   # Left arm
	_fill(img, 21, 11, 1, 4, skin)  # Right arm (raised with wand)

	# === MAGIC WAND (right hand, taller) ===
	_fill(img, 22, 8, 1, 4, wand)
	img.set_pixel(22, 7, wand_gem)
	img.set_pixel(23, 7, wand_gem)
	img.set_pixel(22, 6, glow)  # Wand glow tip

	# === DRESS SKIRT (flowing, layered) ===
	_fill(img, 10, 15, 11, 2, dress)
	_fill(img, 9, 17, 13, 2, dress)
	_fill(img, 10, 19, 11, 1, dress_light)
	# Skirt flowing details
	for y in range(15, 20):
		img.set_pixel(12, y, dress_light)
		img.set_pixel(15, y, dress_accent)
		img.set_pixel(18, y, dress_light)
	# Skirt bottom wave
	img.set_pixel(9, 19, dress)
	img.set_pixel(21, 19, dress)

	# === BOOTS (heeled) ===
	_fill(img, 11, 20, 3, 2, Color(0.15, 0.08, 0.12))
	_fill(img, 17, 20, 3, 2, Color(0.15, 0.08, 0.12))
	# Boot buckles
	img.set_pixel(12, 20, gold)
	img.set_pixel(18, 20, gold)

	# === BLACK CAT (sitting at her feet, left side) ===
	# Cat body
	_fill(img, 3, 24, 4, 3, cat_black)
	# Cat head
	_fill(img, 3, 22, 4, 2, cat_black)
	# Cat ears (pointy)
	img.set_pixel(3, 21, cat_black)
	img.set_pixel(6, 21, cat_black)
	# Cat eyes (yellow, glowing)
	img.set_pixel(4, 23, cat_eye)
	img.set_pixel(5, 23, cat_eye)
	# Cat tail (curving up)
	img.set_pixel(7, 25, cat_black)
	img.set_pixel(8, 24, cat_black)
	img.set_pixel(8, 23, cat_black)
	img.set_pixel(7, 22, cat_black)
	# Cat paws
	img.set_pixel(3, 27, cat_black)
	img.set_pixel(6, 27, cat_black)

	# === MAGIC SPARKLES ===
	img.set_pixel(7, 8, glow)
	img.set_pixel(24, 10, glow_purple)
	img.set_pixel(6, 16, glow_purple)
	img.set_pixel(25, 14, glow)
	# Stars
	img.set_pixel(26, 6, Color(1.0, 1.0, 0.7, 0.7))
	img.set_pixel(5, 5, Color(0.8, 0.7, 1.0, 0.6))

	_outline(img, outline)
	img.save_png("res://assets/sprites/characters/bruxa.png")
	print("Saved: bruxa.png (Moon Witch with black cat)")
	quit()

func _fill(img: Image, x: int, y: int, w: int, h: int, c: Color) -> void:
	for px in range(x, mini(x + w, 32)):
		for py in range(y, mini(y + h, 32)):
			if px >= 0 and py >= 0:
				img.set_pixel(px, py, c)

func _outline(img: Image, color: Color) -> void:
	var out = Image.create(32, 32, false, Image.FORMAT_RGBA8)
	for x in range(32):
		for y in range(32):
			if img.get_pixel(x, y).a > 0:
				continue
			for off in [Vector2i(-1,0), Vector2i(1,0), Vector2i(0,-1), Vector2i(0,1)]:
				var nx = x + off.x
				var ny = y + off.y
				if nx >= 0 and nx < 32 and ny >= 0 and ny < 32:
					if img.get_pixel(nx, ny).a > 0:
						out.set_pixel(x, y, color)
						break
	for x in range(32):
		for y in range(32):
			if out.get_pixel(x, y).a > 0:
				img.set_pixel(x, y, out.get_pixel(x, y))
