extends SceneTree

func _init() -> void:
	var img = Image.create(32, 32, false, Image.FORMAT_RGBA8)
	var skin = Color(0.82, 0.7, 0.6)
	var hair_black = Color(0.08, 0.06, 0.1)
	var hair_blue = Color(0.15, 0.3, 0.85)
	var ear_outer = Color(0.06, 0.04, 0.08)
	var ear_inner = Color(0.9, 0.85, 0.82)
	var eye_blue = Color(0.25, 0.55, 0.95)
	var bell = Color(0.9, 0.75, 0.15)
	var collar = Color(0.7, 0.12, 0.12)
	var jacket = Color(0.05, 0.05, 0.1)
	var jacket_blue = Color(0.12, 0.2, 0.5)
	var shirt = Color(0.15, 0.15, 0.2)
	var pants = Color(0.08, 0.08, 0.15)
	var pants_stripe = Color(0.1, 0.15, 0.4)
	var boots = Color(0.06, 0.06, 0.12)
	var boot_accent = Color(0.15, 0.25, 0.55)
	var tail = Color(0.06, 0.04, 0.08)
	var cuff = Color(0.85, 0.82, 0.78)
	var outline = Color(0.03, 0.02, 0.05)

	# --- Cat ears ---
	# Left ear (outer black)
	img.set_pixel(11, 1, ear_outer)
	_fill(img, 10, 2, 3, 2, ear_outer)
	# Left ear inner
	img.set_pixel(11, 2, ear_inner)
	img.set_pixel(11, 3, ear_inner)
	# Right ear (outer black)
	img.set_pixel(20, 1, ear_outer)
	_fill(img, 19, 2, 3, 2, ear_outer)
	# Right ear inner
	img.set_pixel(20, 2, ear_inner)
	img.set_pixel(20, 3, ear_inner)

	# --- Hair ---
	# Black hair base (left side)
	_fill(img, 10, 4, 6, 3, hair_black)
	_fill(img, 9, 5, 2, 4, hair_black)
	# Blue streak (right side of hair)
	_fill(img, 16, 4, 5, 3, hair_blue)
	_fill(img, 20, 5, 2, 4, hair_blue)
	# Hair top/fringe
	_fill(img, 12, 3, 8, 1, hair_black)
	# Ahoge (hair spike on top)
	img.set_pixel(15, 2, hair_black)
	img.set_pixel(16, 1, hair_black)
	# Back hair strands
	_fill(img, 9, 8, 2, 3, hair_black)
	_fill(img, 21, 8, 2, 3, hair_blue)

	# --- Face ---
	_fill(img, 12, 7, 8, 3, skin)
	# Eyes (bright blue)
	img.set_pixel(13, 8, eye_blue)
	img.set_pixel(14, 8, Color(0.1, 0.15, 0.3))  # pupil
	img.set_pixel(18, 8, eye_blue)
	img.set_pixel(17, 8, Color(0.1, 0.15, 0.3))  # pupil
	# Eye shine
	img.set_pixel(13, 7, Color(0.9, 0.95, 1.0, 0.5))
	img.set_pixel(18, 7, Color(0.9, 0.95, 1.0, 0.5))
	# Mouth (smirk)
	img.set_pixel(15, 9, Color(0.65, 0.35, 0.35))
	img.set_pixel(16, 9, Color(0.65, 0.35, 0.35))

	# --- Bell earring (right ear) ---
	img.set_pixel(21, 5, bell)
	img.set_pixel(21, 6, bell)
	img.set_pixel(22, 6, bell.darkened(0.2))

	# --- Neck ---
	_fill(img, 14, 10, 4, 1, skin)
	# Red collar
	_fill(img, 13, 10, 6, 1, collar)
	# Small bell on collar
	img.set_pixel(16, 11, bell)

	# --- Jacket (black with blue accents) ---
	_fill(img, 10, 11, 12, 4, jacket)
	# Blue lapels/accents
	_fill(img, 10, 11, 2, 3, jacket_blue)
	_fill(img, 20, 11, 2, 3, jacket_blue)
	# Shirt V visible
	img.set_pixel(15, 11, shirt)
	img.set_pixel(16, 11, shirt)
	img.set_pixel(15, 12, shirt)
	img.set_pixel(16, 12, shirt)
	# Shoulder blue stripes
	_fill(img, 9, 11, 1, 2, jacket_blue)
	_fill(img, 22, 11, 1, 2, jacket_blue)

	# --- Arms ---
	# Left arm (jacket sleeve)
	_fill(img, 8, 13, 2, 4, jacket)
	# Right arm (jacket sleeve)
	_fill(img, 22, 13, 2, 4, jacket)
	# White cuffs
	_fill(img, 8, 16, 2, 1, cuff)
	_fill(img, 22, 16, 2, 1, cuff)
	# Hands
	img.set_pixel(8, 17, skin)
	img.set_pixel(9, 17, skin)
	img.set_pixel(22, 17, skin)
	img.set_pixel(23, 17, skin)

	# --- Belt ---
	_fill(img, 10, 15, 12, 1, jacket_blue)
	# Belt buckle
	img.set_pixel(15, 15, bell)
	img.set_pixel(16, 15, bell)

	# --- Pants (dark with blue stripes) ---
	_fill(img, 11, 16, 4, 5, pants)
	_fill(img, 17, 16, 4, 5, pants)
	# Blue stripes
	for y in range(16, 21):
		img.set_pixel(12, y, pants_stripe)
		img.set_pixel(19, y, pants_stripe)

	# --- Boots ---
	_fill(img, 10, 21, 5, 3, boots)
	_fill(img, 17, 21, 5, 3, boots)
	# Boot accents (blue trim)
	_fill(img, 10, 21, 5, 1, boot_accent)
	_fill(img, 17, 21, 5, 1, boot_accent)
	# Boot sole detail
	img.set_pixel(11, 23, boot_accent)
	img.set_pixel(12, 23, boot_accent)
	img.set_pixel(18, 23, boot_accent)
	img.set_pixel(19, 23, boot_accent)

	# --- Cat tail (curving to the left) ---
	_fill(img, 6, 15, 2, 1, tail)
	_fill(img, 5, 14, 2, 1, tail)
	_fill(img, 4, 13, 2, 1, tail)
	_fill(img, 4, 12, 1, 1, tail)
	_fill(img, 5, 11, 1, 1, tail)
	img.set_pixel(6, 10, tail)
	# Tail blue tip
	img.set_pixel(6, 10, hair_blue)
	img.set_pixel(5, 11, hair_blue)

	# --- Star/sparkle near hand (magical) ---
	img.set_pixel(25, 15, Color(0.4, 0.6, 1.0, 0.8))
	img.set_pixel(26, 14, Color(0.5, 0.7, 1.0, 0.6))
	img.set_pixel(26, 16, Color(0.5, 0.7, 1.0, 0.6))
	img.set_pixel(27, 15, Color(0.4, 0.6, 1.0, 0.8))

	_outline(img, outline)
	img.save_png("res://assets/sprites/characters/lealith.png")
	print("Saved: lealith.png")
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
