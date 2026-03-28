extends SceneTree

func _init() -> void:
	var img = Image.create(32, 32, false, Image.FORMAT_RGBA8)
	var skin = Color(0.75, 0.55, 0.4)
	var hair = Color(0.2, 0.1, 0.05)
	var armor = Color(0.85, 0.55, 0.2)  # Bronze/gold
	var armor_dark = Color(0.65, 0.4, 0.12)
	var leather = Color(0.45, 0.28, 0.12)
	var skirt = Color(0.55, 0.35, 0.15)
	var lance_shaft = Color(0.5, 0.35, 0.2)
	var lance_tip = Color(0.8, 0.8, 0.85)
	var headband = Color(0.9, 0.2, 0.15)
	var outline = Color(0.1, 0.08, 0.05)

	# Hair (long, flowing)
	_fill(img, 12, 3, 8, 2, hair)
	_fill(img, 11, 5, 10, 3, hair)
	# Hair flowing down right side
	_fill(img, 20, 7, 2, 8, hair)
	_fill(img, 21, 9, 2, 6, hair)

	# Headband
	_fill(img, 11, 6, 10, 1, headband)

	# Face
	_fill(img, 12, 7, 8, 3, skin)
	# Eyes
	img.set_pixel(14, 8, Color(0.15, 0.4, 0.2))  # Green eyes
	img.set_pixel(17, 8, Color(0.15, 0.4, 0.2))
	# Lips
	img.set_pixel(15, 9, Color(0.7, 0.3, 0.3))
	img.set_pixel(16, 9, Color(0.7, 0.3, 0.3))

	# Neck
	_fill(img, 14, 10, 4, 1, skin)

	# Chest armor (bronze breastplate)
	_fill(img, 11, 11, 10, 3, armor)
	_fill(img, 12, 11, 8, 2, armor_dark)  # Shadow detail
	# Shoulder guards
	_fill(img, 9, 11, 2, 2, armor)
	_fill(img, 21, 11, 2, 2, armor)

	# Arms (skin)
	_fill(img, 8, 13, 2, 4, skin)
	_fill(img, 22, 13, 2, 3, skin)

	# Leather belt
	_fill(img, 11, 14, 10, 1, leather)

	# Warrior skirt (shorter, leather strips)
	_fill(img, 10, 15, 12, 4, skirt)
	# Skirt strips (vertical lines for leather straps)
	for y in range(15, 19):
		img.set_pixel(12, y, skirt.darkened(0.2))
		img.set_pixel(15, y, skirt.darkened(0.2))
		img.set_pixel(18, y, skirt.darkened(0.2))
		img.set_pixel(20, y, skirt.darkened(0.2))

	# Legs (skin, athletic)
	_fill(img, 11, 19, 3, 3, skin)
	_fill(img, 18, 19, 3, 3, skin)

	# Sandals/boots
	_fill(img, 10, 22, 4, 2, leather)
	_fill(img, 18, 22, 4, 2, leather)
	# Ankle wraps
	img.set_pixel(11, 21, Color(0.7, 0.65, 0.55))
	img.set_pixel(19, 21, Color(0.7, 0.65, 0.55))

	# Lance (held in right hand, pointing up-right)
	for i in range(16):
		var lx = 6 + i
		var ly = 2 + i / 2
		if lx < 32 and ly < 32:
			img.set_pixel(lx, ly, lance_shaft if i > 2 else lance_tip)
	# Lance tip (wider)
	img.set_pixel(6, 2, lance_tip)
	img.set_pixel(7, 2, lance_tip)
	img.set_pixel(7, 3, lance_tip)
	img.set_pixel(6, 3, lance_tip)

	# Shield (small, left arm)
	_fill(img, 5, 13, 3, 4, armor)
	_fill(img, 6, 12, 2, 1, armor)
	_fill(img, 6, 17, 2, 1, armor)
	# Shield emblem
	img.set_pixel(6, 14, headband)
	img.set_pixel(6, 15, headband)

	_outline(img, outline)
	img.save_png("res://assets/sprites/characters/amazona.png")
	print("Saved: amazona.png")
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
