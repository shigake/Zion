@tool
extends Node

## Generates pixel art sprites for characters and enemies.
## Run from editor: attach to a Node, it generates PNGs on _ready.

const SPRITE_SIZE := 32

func _ready() -> void:
	_generate_ronin()
	_generate_soldado()
	_generate_mago()
	_generate_slime()
	print("All sprites generated!")

func _save_sprite(img: Image, path: String) -> void:
	img.save_png(path)
	print("Saved: ", path)

# ==================== RONIN ====================
func _generate_ronin() -> void:
	var img = Image.create(SPRITE_SIZE, SPRITE_SIZE, false, Image.FORMAT_RGBA8)
	var skin = Color(0.93, 0.8, 0.67)
	var hair = Color(0.15, 0.12, 0.1)
	var hakama_top = Color(0.2, 0.55, 0.3)  # Green
	var hakama_bot = Color(0.15, 0.4, 0.22)
	var belt = Color(0.6, 0.5, 0.2)
	var headband = Color(0.85, 0.15, 0.15)  # Red headband
	var katana = Color(0.75, 0.78, 0.82)
	var katana_handle = Color(0.3, 0.15, 0.1)
	var outline = Color(0.1, 0.1, 0.1)

	# Head (rows 4-9, cols 12-19)
	# Hair top
	_fill_rect(img, 12, 4, 8, 2, hair)
	# Headband
	_fill_rect(img, 12, 6, 8, 1, headband)
	# Face
	_fill_rect(img, 12, 7, 8, 3, skin)
	# Eyes
	img.set_pixel(14, 8, outline)
	img.set_pixel(17, 8, outline)
	# Mouth
	img.set_pixel(15, 9, Color(0.7, 0.4, 0.35))
	img.set_pixel(16, 9, Color(0.7, 0.4, 0.35))
	# Hair sides
	_fill_rect(img, 11, 5, 1, 5, hair)
	_fill_rect(img, 20, 5, 1, 5, hair)

	# Body / Hakama top (rows 10-16)
	_fill_rect(img, 11, 10, 10, 3, hakama_top)
	# Belt/obi
	_fill_rect(img, 11, 13, 10, 1, belt)
	# Hakama bottom (wide skirt)
	_fill_rect(img, 9, 14, 14, 6, hakama_bot)
	_fill_rect(img, 10, 20, 12, 2, hakama_bot)
	# Hakama folds (vertical lines)
	for y in range(14, 20):
		img.set_pixel(12, y, hakama_bot.darkened(0.2))
		img.set_pixel(16, y, hakama_bot.darkened(0.2))
		img.set_pixel(19, y, hakama_bot.darkened(0.2))

	# Arms (skin)
	_fill_rect(img, 9, 10, 2, 4, skin)
	_fill_rect(img, 21, 10, 2, 4, skin)

	# Katana on back (diagonal)
	for i in range(12):
		img.set_pixel(22 - i / 2, 3 + i, katana if i < 8 else katana_handle)

	# Feet
	_fill_rect(img, 11, 22, 3, 2, Color(0.25, 0.15, 0.1))
	_fill_rect(img, 18, 22, 3, 2, Color(0.25, 0.15, 0.1))

	# Outline
	_add_outline(img, outline)

	_save_sprite(img, "res://assets/sprites/characters/ronin.png")

# ==================== SOLDADO ====================
func _generate_soldado() -> void:
	var img = Image.create(SPRITE_SIZE, SPRITE_SIZE, false, Image.FORMAT_RGBA8)
	var skin = Color(0.85, 0.72, 0.58)
	var helmet = Color(0.35, 0.45, 0.35)  # Military green
	var armor = Color(0.3, 0.4, 0.3)
	var armor_light = Color(0.38, 0.48, 0.38)
	var pants = Color(0.25, 0.32, 0.25)
	var boots = Color(0.2, 0.15, 0.1)
	var backpack = Color(0.35, 0.3, 0.2)
	var outline = Color(0.08, 0.08, 0.08)

	# Helmet (rows 3-7)
	_fill_rect(img, 11, 3, 10, 2, helmet)
	_fill_rect(img, 10, 5, 12, 2, helmet)
	# Helmet visor
	_fill_rect(img, 12, 5, 8, 1, Color(0.15, 0.2, 0.15))

	# Face (rows 7-9)
	_fill_rect(img, 12, 7, 8, 3, skin)
	# Eyes
	img.set_pixel(14, 8, outline)
	img.set_pixel(17, 8, outline)

	# Body armor (rows 10-16)
	_fill_rect(img, 10, 10, 12, 4, armor)
	# Armor detail (chest plate)
	_fill_rect(img, 12, 10, 8, 3, armor_light)
	# Belt
	_fill_rect(img, 10, 14, 12, 1, Color(0.25, 0.2, 0.15))

	# Shoulder pads
	_fill_rect(img, 8, 10, 2, 3, armor_light)
	_fill_rect(img, 22, 10, 2, 3, armor_light)

	# Arms
	_fill_rect(img, 8, 13, 2, 3, armor)
	_fill_rect(img, 22, 13, 2, 3, armor)
	_fill_rect(img, 8, 16, 2, 1, skin)
	_fill_rect(img, 22, 16, 2, 1, skin)

	# Backpack
	_fill_rect(img, 22, 11, 3, 5, backpack)

	# Pants
	_fill_rect(img, 11, 15, 10, 5, pants)
	# Legs separation
	_fill_rect(img, 15, 17, 2, 3, pants.darkened(0.15))

	# Boots
	_fill_rect(img, 10, 20, 5, 4, boots)
	_fill_rect(img, 17, 20, 5, 4, boots)

	_add_outline(img, outline)
	_save_sprite(img, "res://assets/sprites/characters/soldado.png")

# ==================== MAGO ====================
func _generate_mago() -> void:
	var img = Image.create(SPRITE_SIZE, SPRITE_SIZE, false, Image.FORMAT_RGBA8)
	var skin = Color(0.9, 0.8, 0.7)
	var robe = Color(0.35, 0.2, 0.6)  # Purple
	var robe_dark = Color(0.25, 0.12, 0.45)
	var hat = Color(0.4, 0.22, 0.65)
	var hat_band = Color(0.8, 0.7, 0.2)  # Gold band
	var orb = Color(0.3, 0.6, 1.0)  # Blue orb
	var orb_glow = Color(0.5, 0.8, 1.0)
	var beard = Color(0.85, 0.85, 0.8)
	var outline = Color(0.08, 0.05, 0.12)

	# Pointy hat (rows 0-8)
	img.set_pixel(15, 0, hat)
	img.set_pixel(16, 0, hat)
	_fill_rect(img, 14, 1, 4, 1, hat)
	_fill_rect(img, 13, 2, 6, 1, hat)
	_fill_rect(img, 12, 3, 8, 1, hat)
	_fill_rect(img, 11, 4, 10, 1, hat)
	_fill_rect(img, 10, 5, 12, 1, hat)
	# Hat brim
	_fill_rect(img, 8, 6, 16, 2, hat)
	# Gold band
	_fill_rect(img, 10, 5, 12, 1, hat_band)

	# Face (rows 8-11)
	_fill_rect(img, 12, 8, 8, 3, skin)
	# Eyes
	img.set_pixel(14, 9, outline)
	img.set_pixel(17, 9, outline)
	# Beard
	_fill_rect(img, 13, 11, 6, 3, beard)
	_fill_rect(img, 14, 14, 4, 1, beard)
	img.set_pixel(15, 15, beard)

	# Robe body (rows 11-22)
	_fill_rect(img, 10, 11, 12, 4, robe)
	# Robe skirt (wider)
	_fill_rect(img, 8, 15, 16, 6, robe)
	_fill_rect(img, 9, 21, 14, 3, robe_dark)
	# Robe details (vertical trim)
	for y in range(11, 24):
		if y < 24:
			img.set_pixel(16, y, robe_dark.lightened(0.2))

	# Sleeves
	_fill_rect(img, 7, 11, 3, 5, robe)
	_fill_rect(img, 22, 11, 3, 5, robe)
	# Hands
	_fill_rect(img, 7, 16, 2, 1, skin)
	_fill_rect(img, 23, 16, 2, 1, skin)

	# Floating orb (left hand)
	_fill_rect(img, 5, 14, 3, 3, orb)
	img.set_pixel(5, 14, orb_glow)
	img.set_pixel(6, 14, orb_glow)

	# Shoes peek out
	_fill_rect(img, 11, 24, 3, 1, Color(0.3, 0.15, 0.1))
	_fill_rect(img, 18, 24, 3, 1, Color(0.3, 0.15, 0.1))

	_add_outline(img, outline)
	_save_sprite(img, "res://assets/sprites/characters/mago.png")

# ==================== SLIME ====================
func _generate_slime() -> void:
	var img = Image.create(SPRITE_SIZE, SPRITE_SIZE, false, Image.FORMAT_RGBA8)
	var body = Color(0.3, 0.8, 0.3)  # Green
	var body_light = Color(0.45, 0.9, 0.45)
	var body_dark = Color(0.2, 0.6, 0.2)
	var eye_white = Color(0.95, 0.95, 0.95)
	var pupil = Color(0.1, 0.1, 0.1)
	var mouth = Color(0.15, 0.5, 0.15)
	var highlight = Color(0.6, 1.0, 0.6, 0.7)
	var outline = Color(0.1, 0.3, 0.1)

	# Body (blob shape, rows 8-26)
	# Top curve
	_fill_rect(img, 12, 8, 8, 2, body)
	_fill_rect(img, 10, 10, 12, 2, body)
	_fill_rect(img, 8, 12, 16, 2, body)
	# Main body
	_fill_rect(img, 6, 14, 20, 8, body)
	# Bottom (wider, droopy)
	_fill_rect(img, 5, 22, 22, 2, body)
	_fill_rect(img, 6, 24, 20, 2, body_dark)
	_fill_rect(img, 8, 26, 16, 2, body_dark)

	# Highlight (top-left shine)
	_fill_rect(img, 11, 10, 3, 2, body_light)
	_fill_rect(img, 10, 12, 2, 2, body_light)
	img.set_pixel(11, 11, highlight)
	img.set_pixel(12, 11, highlight)

	# Eyes (big and cute)
	# Left eye
	_fill_rect(img, 10, 16, 4, 4, eye_white)
	_fill_rect(img, 11, 17, 2, 2, pupil)
	img.set_pixel(11, 17, Color(0.2, 0.2, 0.2))  # Pupil highlight
	# Right eye
	_fill_rect(img, 18, 16, 4, 4, eye_white)
	_fill_rect(img, 19, 17, 2, 2, pupil)
	img.set_pixel(19, 17, Color(0.2, 0.2, 0.2))

	# Mouth (simple smile)
	img.set_pixel(14, 21, mouth)
	img.set_pixel(15, 22, mouth)
	img.set_pixel(16, 22, mouth)
	img.set_pixel(17, 21, mouth)

	# Shading (bottom darker)
	for x in range(6, 26):
		for y in range(22, 28):
			var c = img.get_pixel(x, y)
			if c.a > 0:
				img.set_pixel(x, y, c.darkened(0.15))

	_add_outline(img, outline)
	_save_sprite(img, "res://assets/sprites/enemies/slime.png")

# ==================== HELPERS ====================
func _fill_rect(img: Image, x: int, y: int, w: int, h: int, color: Color) -> void:
	for px in range(x, mini(x + w, SPRITE_SIZE)):
		for py in range(y, mini(y + h, SPRITE_SIZE)):
			if px >= 0 and py >= 0:
				img.set_pixel(px, py, color)

func _add_outline(img: Image, color: Color) -> void:
	## Add 1px dark outline around all non-transparent pixels
	var outline_img = Image.create(SPRITE_SIZE, SPRITE_SIZE, false, Image.FORMAT_RGBA8)
	for x in range(SPRITE_SIZE):
		for y in range(SPRITE_SIZE):
			if img.get_pixel(x, y).a > 0:
				continue
			# Check 4 neighbors
			var has_neighbor := false
			for offset in [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]:
				var nx = x + offset.x
				var ny = y + offset.y
				if nx >= 0 and nx < SPRITE_SIZE and ny >= 0 and ny < SPRITE_SIZE:
					if img.get_pixel(nx, ny).a > 0:
						has_neighbor = true
						break
			if has_neighbor:
				outline_img.set_pixel(x, y, color)

	# Merge outline onto image
	for x in range(SPRITE_SIZE):
		for y in range(SPRITE_SIZE):
			if outline_img.get_pixel(x, y).a > 0:
				img.set_pixel(x, y, outline_img.get_pixel(x, y))
