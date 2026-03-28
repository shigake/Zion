extends SceneTree

func _init() -> void:
	var img = Image.create(32, 32, false, Image.FORMAT_RGBA8)
	var skin = Color(0.85, 0.78, 0.72)
	var hair = Color(0.15, 0.08, 0.2)  # Dark purple-black
	var hat = Color(0.2, 0.1, 0.3)
	var hat_band = Color(0.6, 0.2, 0.7)  # Purple band
	var dress = Color(0.25, 0.1, 0.35)
	var dress_light = Color(0.35, 0.15, 0.45)
	var cape = Color(0.15, 0.05, 0.2)
	var dog_white = Color(0.92, 0.9, 0.88)
	var dog_dark = Color(0.75, 0.72, 0.68)
	var familiar = Color(0.9, 0.75, 0.5)  # Small golden familiar
	var familiar_dark = Color(0.7, 0.55, 0.3)
	var familiar_outfit = Color(0.8, 0.2, 0.15)  # Red outfit
	var glow = Color(0.5, 0.9, 0.3)  # Green magic glow
	var outline = Color(0.08, 0.04, 0.1)

	# === WITCH (center) ===
	# Pointy hat
	img.set_pixel(14, 0, hat)
	img.set_pixel(15, 0, hat)
	_fill(img, 13, 1, 4, 1, hat)
	_fill(img, 12, 2, 6, 1, hat)
	_fill(img, 11, 3, 8, 1, hat)
	_fill(img, 10, 4, 10, 2, hat)
	# Hat brim
	_fill(img, 8, 6, 14, 1, hat)
	# Hat band
	_fill(img, 10, 5, 10, 1, hat_band)
	# Hat buckle
	img.set_pixel(15, 5, Color(0.9, 0.8, 0.2))

	# Face
	_fill(img, 12, 7, 6, 3, skin)
	# Hair sides
	_fill(img, 11, 7, 1, 4, hair)
	_fill(img, 18, 7, 1, 4, hair)
	# Eyes (green, witchy)
	img.set_pixel(13, 8, Color(0.2, 0.7, 0.2))
	img.set_pixel(16, 8, Color(0.2, 0.7, 0.2))
	# Smile
	img.set_pixel(14, 9, Color(0.6, 0.3, 0.35))
	img.set_pixel(15, 9, Color(0.6, 0.3, 0.35))

	# Dress body
	_fill(img, 11, 10, 8, 3, dress)
	_fill(img, 12, 10, 6, 2, dress_light)
	# Cape/shawl
	_fill(img, 9, 10, 2, 5, cape)
	_fill(img, 19, 10, 2, 5, cape)
	# Belt with potion bottles
	_fill(img, 11, 13, 8, 1, Color(0.4, 0.25, 0.1))
	img.set_pixel(13, 13, Color(0.3, 0.8, 0.3))  # Green potion
	img.set_pixel(16, 13, Color(0.8, 0.3, 0.8))  # Purple potion

	# Dress skirt (flowing)
	_fill(img, 10, 14, 10, 5, dress)
	_fill(img, 9, 16, 12, 3, dress)
	# Skirt details
	for y in range(14, 19):
		img.set_pixel(13, y, dress_light)
		img.set_pixel(16, y, dress_light)

	# Hands (holding wand)
	_fill(img, 9, 13, 1, 2, skin)
	_fill(img, 20, 13, 1, 2, skin)
	# Magic wand (right hand)
	_fill(img, 20, 10, 1, 4, Color(0.4, 0.2, 0.1))
	img.set_pixel(20, 9, glow)
	img.set_pixel(21, 9, glow)

	# Boots
	_fill(img, 11, 19, 3, 2, Color(0.2, 0.1, 0.15))
	_fill(img, 16, 19, 3, 2, Color(0.2, 0.1, 0.15))

	# === WHITE DOG (left side, small) ===
	# Dog body
	_fill(img, 2, 21, 5, 3, dog_white)
	# Dog head
	_fill(img, 2, 19, 3, 2, dog_white)
	# Dog ear
	img.set_pixel(2, 18, dog_dark)
	img.set_pixel(4, 18, dog_dark)
	# Dog eye
	img.set_pixel(3, 19, outline)
	# Dog nose
	img.set_pixel(2, 20, Color(0.2, 0.15, 0.15))
	# Dog tail
	img.set_pixel(7, 20, dog_white)
	img.set_pixel(7, 19, dog_white)
	# Dog legs
	img.set_pixel(3, 24, dog_dark)
	img.set_pixel(5, 24, dog_dark)
	# Dog collar (red)
	_fill(img, 2, 20, 3, 1, Color(0.8, 0.15, 0.1))
	# Chain from dog to familiar
	var chain_color = Color(0.5, 0.5, 0.55)
	for cx in range(7, 24):
		if cx % 2 == 0:
			img.set_pixel(cx, 23, chain_color)

	# === SMALL FAMILIAR (right side, collared) ===
	# Head
	_fill(img, 24, 19, 3, 3, familiar)
	# Conical hat (straw hat)
	_fill(img, 23, 17, 5, 2, Color(0.7, 0.6, 0.3))
	img.set_pixel(25, 16, Color(0.7, 0.6, 0.3))
	# Eyes (sad/submissive)
	img.set_pixel(24, 20, outline)
	img.set_pixel(26, 20, outline)
	# Collar (red leather with ring)
	_fill(img, 24, 22, 3, 1, Color(0.7, 0.1, 0.1))
	img.set_pixel(25, 22, Color(0.6, 0.6, 0.65))  # Metal ring
	# Body (tattered red outfit)
	_fill(img, 24, 23, 3, 3, familiar_outfit)
	# Legs
	img.set_pixel(24, 26, familiar_dark)
	img.set_pixel(26, 26, familiar_dark)
	# Small broom (sweeping)
	_fill(img, 27, 22, 1, 4, Color(0.5, 0.35, 0.2))
	_fill(img, 27, 26, 2, 1, Color(0.6, 0.5, 0.2))

	# Magic sparkles around witch
	img.set_pixel(8, 8, glow)
	img.set_pixel(21, 7, glow)
	img.set_pixel(10, 15, glow)

	_outline(img, outline)
	img.save_png("res://assets/sprites/characters/bruxa.png")
	print("Saved: bruxa.png")
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
