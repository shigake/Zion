extends SceneTree

func _init() -> void:
	var img = Image.create(32, 32, false, Image.FORMAT_RGBA8)
	var robe = Color(0.12, 0.18, 0.4)
	var robe_light = Color(0.18, 0.25, 0.5)
	var hood = Color(0.08, 0.12, 0.3)
	var skin = Color(0.85, 0.75, 0.65)
	var gold = Color(0.9, 0.75, 0.2)
	var crystal = Color(0.3, 0.7, 1.0)
	var outline = Color(0.05, 0.05, 0.15)

	# Hood (pointy)
	_fill(img, 13, 2, 6, 2, hood)
	_fill(img, 12, 4, 8, 3, hood)
	_fill(img, 11, 7, 10, 2, hood)
	img.set_pixel(15, 1, hood)
	img.set_pixel(16, 1, hood)

	# Face (partially hidden in hood)
	_fill(img, 13, 7, 6, 3, skin)
	# Eyes (glowing blue)
	img.set_pixel(14, 8, crystal)
	img.set_pixel(17, 8, crystal)

	# Robe body
	_fill(img, 11, 10, 10, 4, robe)
	_fill(img, 12, 10, 8, 3, robe_light)
	# Gold trim
	_fill(img, 11, 13, 10, 1, gold)

	# Robe skirt (wide, flowing)
	_fill(img, 9, 14, 14, 6, robe)
	_fill(img, 10, 20, 12, 3, robe)
	# Gold trim bottom
	_fill(img, 9, 19, 14, 1, gold)
	# Robe folds
	for y in range(14, 20):
		img.set_pixel(13, y, robe_light)
		img.set_pixel(18, y, robe_light)

	# Sleeves
	_fill(img, 8, 10, 3, 5, robe)
	_fill(img, 21, 10, 3, 5, robe)
	# Hands holding crystal
	_fill(img, 8, 15, 2, 1, skin)
	_fill(img, 22, 15, 2, 1, skin)

	# Floating crystal (between hands)
	_fill(img, 14, 14, 4, 4, crystal)
	img.set_pixel(15, 13, crystal)
	img.set_pixel(16, 13, crystal)
	img.set_pixel(15, 18, crystal)
	img.set_pixel(16, 18, crystal)
	# Crystal glow
	img.set_pixel(15, 15, Color(0.8, 0.95, 1.0))
	img.set_pixel(16, 15, Color(0.8, 0.95, 1.0))

	# Gold necklace
	img.set_pixel(14, 10, gold)
	img.set_pixel(15, 10, gold)
	img.set_pixel(16, 10, gold)
	img.set_pixel(17, 10, gold)

	# Boots
	_fill(img, 11, 23, 3, 1, Color(0.15, 0.1, 0.25))
	_fill(img, 18, 23, 3, 1, Color(0.15, 0.1, 0.25))

	# Magic sparkles
	img.set_pixel(7, 12, Color(0.5, 0.8, 1.0, 0.7))
	img.set_pixel(24, 13, Color(0.5, 0.8, 1.0, 0.7))
	img.set_pixel(10, 6, Color(0.9, 0.8, 0.3, 0.5))

	_outline(img, outline)

	DirAccess.make_dir_recursive_absolute("res://assets/sprites/ui/")
	img.save_png("res://assets/sprites/ui/merchant.png")
	print("Saved: merchant.png")
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
