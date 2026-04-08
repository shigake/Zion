extends SceneTree

## Generates 64x64 pixel art sprites for all 16 playable characters.
## Each character has a clear silhouette, dominant color, black outline,
## face with eyes, body/arms/legs, and signature weapon/accessory.
## Also generates walk frames with slightly shifted pose.
## Run: godot --headless --script res://scripts/tools/character_sprite_gen.gd

const S := 64
const DIR := "res://assets/sprites/characters/"

func _init() -> void:
	DirAccess.make_dir_recursive_absolute(DIR)
	_gen_amazona()
	_gen_bruxa()
	_gen_lealith()
	_gen_ronin()
	_gen_soldado()
	_gen_mago()
	_gen_berserker()
	_gen_ninja()
	_gen_necro()
	_gen_pirata()
	_gen_engenheiro()
	_gen_vampiro()
	_gen_gladiador()
	_gen_chef()
	_gen_mystery()
	_gen_fragmentado()
	print("All 16 character sprites generated (64x64)!")
	quit()

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

func _circle(img: Image, cx: int, cy: int, r: int, color: Color) -> void:
	for x in range(maxi(cx - r, 0), mini(cx + r + 1, S)):
		for y in range(maxi(cy - r, 0), mini(cy + r + 1, S)):
			if (x - cx) * (x - cx) + (y - cy) * (y - cy) <= r * r:
				img.set_pixel(x, y, color)

func _ellipse(img: Image, cx: int, cy: int, rx: int, ry: int, color: Color) -> void:
	for x in range(maxi(cx - rx, 0), mini(cx + rx + 1, S)):
		for y in range(maxi(cy - ry, 0), mini(cy + ry + 1, S)):
			var dx = float(x - cx) / float(rx)
			var dy = float(y - cy) / float(ry)
			if dx * dx + dy * dy <= 1.0:
				img.set_pixel(x, y, color)

func _line(img: Image, x0: int, y0: int, x1: int, y1: int, color: Color) -> void:
	var dx = absi(x1 - x0)
	var dy = absi(y1 - y0)
	var sx = 1 if x0 < x1 else -1
	var sy = 1 if y0 < y1 else -1
	var err = dx - dy
	while true:
		_px(img, x0, y0, color)
		if x0 == x1 and y0 == y1:
			break
		var e2 = 2 * err
		if e2 > -dy:
			err -= dy
			x0 += sx
		if e2 < dx:
			err += dx
			y0 += sy

func _thick_line(img: Image, x0: int, y0: int, x1: int, y1: int, color: Color, thickness: int = 2) -> void:
	for ox in range(-thickness / 2, thickness / 2 + 1):
		for oy in range(-thickness / 2, thickness / 2 + 1):
			_line(img, x0 + ox, y0 + oy, x1 + ox, y1 + oy, color)

func _outline(img: Image, color: Color) -> void:
	var copy = img.duplicate()
	for x in range(S):
		for y in range(S):
			if copy.get_pixel(x, y).a > 0:
				continue
			for off in [Vector2i(-1,0), Vector2i(1,0), Vector2i(0,-1), Vector2i(0,1)]:
				var nx = x + off.x
				var ny = y + off.y
				if nx >= 0 and nx < S and ny >= 0 and ny < S:
					if copy.get_pixel(nx, ny).a > 0:
						img.set_pixel(x, y, color)
						break

func _triangle(img: Image, x0: int, y0: int, x1: int, y1: int, x2: int, y2: int, color: Color) -> void:
	var min_x = maxi(mini(mini(x0, x1), x2), 0)
	var max_x = mini(maxi(maxi(x0, x1), x2), S - 1)
	var min_y = maxi(mini(mini(y0, y1), y2), 0)
	var max_y = mini(maxi(maxi(y0, y1), y2), S - 1)
	for x in range(min_x, max_x + 1):
		for y in range(min_y, max_y + 1):
			var d1 = (x - x1) * (y0 - y1) - (x0 - x1) * (y - y1)
			var d2 = (x - x2) * (y1 - y2) - (x1 - x2) * (y - y2)
			var d3 = (x - x0) * (y2 - y0) - (x2 - x0) * (y - y0)
			var has_neg = (d1 < 0) or (d2 < 0) or (d3 < 0)
			var has_pos = (d1 > 0) or (d2 > 0) or (d3 > 0)
			if not (has_neg and has_pos):
				_px(img, x, y, color)

func _save(img: Image, name: String) -> void:
	_outline(img, Color(0.0, 0.0, 0.0))
	img.save_png(DIR + name + ".png")
	print("  Saved: ", name, ".png")

func _make_walk(img: Image, name: String) -> void:
	# Walk frame: shift legs slightly, tilt arms
	var walk = img.duplicate()
	# Shift bottom quarter 1px right
	var tmp = Image.create(S, S, false, Image.FORMAT_RGBA8)
	for x in range(S):
		for y in range(S):
			if y >= S * 3 / 4:
				if x > 0:
					var c = img.get_pixel(x - 1, y)
					if c.a > 0:
						tmp.set_pixel(x, y, c)
				var c2 = walk.get_pixel(x, y)
				if c2.a > 0 and x < S - 1:
					tmp.set_pixel(x, y, c2)
			else:
				tmp.set_pixel(x, y, walk.get_pixel(x, y))
	# Re-outline
	_outline(tmp, Color(0.0, 0.0, 0.0))
	tmp.save_png(DIR + name + "_walk.png")
	print("  Saved: ", name, "_walk.png")

# ==================== BODY TEMPLATE HELPERS ====================
# Standard body proportions for 64x64:
# Head: y=4..18 (14px tall), center at x=32
# Body: y=19..38 (20px tall)
# Legs: y=39..58 (20px tall)
# Arms alongside body

func _draw_head(img: Image, cx: int, skin: Color, skin_shade: Color) -> void:
	# Head oval ~12px wide, 12px tall
	_ellipse(img, cx, 12, 6, 6, skin)
	# Slight shade on sides
	_fill(img, cx - 6, 10, 2, 6, skin_shade)
	_fill(img, cx + 5, 10, 2, 6, skin_shade)

func _draw_eyes(img: Image, cx: int, eye_color: Color) -> void:
	# Left eye
	_fill(img, cx - 3, 11, 2, 2, Color(1, 1, 1))
	_px(img, cx - 3, 12, eye_color)
	_px(img, cx - 2, 12, Color(0.05, 0.05, 0.1))
	# Eye shine
	_px(img, cx - 3, 11, Color(1, 1, 1, 0.9))
	# Right eye
	_fill(img, cx + 2, 11, 2, 2, Color(1, 1, 1))
	_px(img, cx + 3, 12, eye_color)
	_px(img, cx + 2, 12, Color(0.05, 0.05, 0.1))
	_px(img, cx + 2, 11, Color(1, 1, 1, 0.9))

func _draw_mouth(img: Image, cx: int, color: Color) -> void:
	_fill(img, cx - 1, 15, 3, 1, color)

func _draw_legs(img: Image, cx: int, pants_color: Color, boot_color: Color) -> void:
	# Left leg
	_fill(img, cx - 5, 40, 4, 10, pants_color)
	_fill(img, cx - 6, 50, 6, 4, boot_color)
	# Right leg
	_fill(img, cx + 2, 40, 4, 10, pants_color)
	_fill(img, cx + 1, 50, 6, 4, boot_color)

func _draw_arms(img: Image, cx: int, arm_color: Color, hand_color: Color) -> void:
	# Left arm
	_fill(img, cx - 10, 20, 3, 12, arm_color)
	_fill(img, cx - 10, 32, 3, 3, hand_color)
	# Right arm
	_fill(img, cx + 8, 20, 3, 12, arm_color)
	_fill(img, cx + 8, 32, 3, 3, hand_color)

func _draw_torso(img: Image, cx: int, color: Color) -> void:
	_fill(img, cx - 7, 19, 15, 20, color)


# ==================== AMAZONA ====================
func _gen_amazona() -> void:
	var img = _img()
	var cx = 32
	var skin = Color(0.75, 0.55, 0.4)
	var skin_shade = Color(0.6, 0.42, 0.3)
	var hair = Color(0.15, 0.08, 0.04)
	var armor = Color(0.85, 0.55, 0.2)
	var armor_dk = Color(0.65, 0.4, 0.15)
	var leather = Color(0.45, 0.28, 0.12)
	var leather_dk = Color(0.35, 0.2, 0.08)
	var headband = Color(0.9, 0.2, 0.15)
	var feather1 = Color(0.9, 0.3, 0.1)
	var feather2 = Color(0.2, 0.7, 0.3)
	var lance_shaft = Color(0.5, 0.35, 0.2)
	var lance_tip = Color(0.8, 0.82, 0.88)
	var skirt = Color(0.55, 0.35, 0.15)

	# Hair (long braided, flowing)
	_fill(img, cx - 6, 4, 12, 4, hair)
	_fill(img, cx - 7, 7, 14, 8, hair)
	# Braid going down back right
	_fill(img, cx + 6, 14, 3, 14, hair)
	_fill(img, cx + 7, 16, 2, 12, hair)
	# Braid ties
	_px(img, cx + 7, 20, headband)
	_px(img, cx + 7, 25, headband)

	# Headband with feathers
	_fill(img, cx - 7, 7, 14, 2, headband)
	# Feathers sticking up
	_fill(img, cx + 4, 2, 2, 5, feather1)
	_fill(img, cx + 6, 3, 2, 4, feather2)
	_fill(img, cx + 3, 3, 1, 4, feather2)
	_px(img, cx + 5, 1, feather1)

	# Face
	_draw_head(img, cx, skin, skin_shade)
	_draw_eyes(img, cx, Color(0.15, 0.5, 0.25))
	# War paint lines under eyes
	_fill(img, cx - 4, 13, 2, 1, headband)
	_fill(img, cx + 3, 13, 2, 1, headband)
	_draw_mouth(img, cx, Color(0.55, 0.3, 0.25))

	# Neck
	_fill(img, cx - 2, 17, 5, 2, skin)
	# Necklace (bone/teeth)
	for i in range(5):
		_px(img, cx - 2 + i, 18, Color(0.9, 0.88, 0.8))

	# Leather armor top
	_fill(img, cx - 7, 19, 15, 8, leather)
	_fill(img, cx - 6, 19, 13, 2, armor)
	# Shoulder pads
	_fill(img, cx - 9, 19, 3, 4, armor)
	_fill(img, cx + 7, 19, 3, 4, armor)
	_fill(img, cx - 9, 19, 3, 2, armor_dk)
	_fill(img, cx + 7, 19, 3, 2, armor_dk)
	# Chest detail
	_fill(img, cx - 3, 21, 7, 1, armor_dk)

	# Belt
	_fill(img, cx - 7, 27, 15, 2, leather_dk)
	_px(img, cx, 27, Color(0.8, 0.7, 0.2))  # buckle

	# Arms (muscular, skin showing)
	_fill(img, cx - 11, 20, 3, 12, skin)
	_fill(img, cx + 9, 20, 3, 12, skin)
	# Arm bands
	_fill(img, cx - 11, 24, 3, 1, leather)
	_fill(img, cx + 9, 24, 3, 1, leather)
	# Hands
	_fill(img, cx - 11, 32, 3, 3, skin)
	_fill(img, cx + 9, 32, 3, 3, skin)

	# Skirt (leather strips)
	_fill(img, cx - 7, 29, 15, 10, skirt)
	# Strips detail
	for i in range(5):
		var sx = cx - 6 + i * 3
		_fill(img, sx, 30, 1, 9, leather_dk)
	# Skirt trim
	_fill(img, cx - 7, 29, 15, 1, armor)

	# Legs
	_fill(img, cx - 5, 39, 4, 10, skin)
	_fill(img, cx + 2, 39, 4, 10, skin)
	# Sandals/wraps
	_fill(img, cx - 6, 49, 6, 5, leather)
	_fill(img, cx + 1, 49, 6, 5, leather)
	# Ankle wraps
	_fill(img, cx - 5, 47, 4, 2, leather)
	_fill(img, cx + 2, 47, 4, 2, leather)

	# Spear (held in right hand, vertical)
	_fill(img, cx + 11, 5, 2, 40, lance_shaft)
	# Spear tip
	_triangle(img, cx + 10, 5, cx + 13, 5, cx + 12, 0, lance_tip)
	_fill(img, cx + 11, 1, 2, 5, lance_tip)
	# Spear tip highlight
	_px(img, cx + 11, 2, Color(0.95, 0.95, 1.0))

	_save(img, "amazona")
	_make_walk(img, "amazona")

# ==================== BRUXA ====================
func _gen_bruxa() -> void:
	var img = _img()
	var cx = 32
	var skin = Color(0.72, 0.6, 0.52)
	var skin_shade = Color(0.58, 0.46, 0.38)
	var hair = Color(0.12, 0.06, 0.18)
	var hat = Color(0.18, 0.08, 0.28)
	var hat_dk = Color(0.12, 0.05, 0.2)
	var hat_band = Color(0.55, 0.18, 0.65)
	var moon = Color(0.95, 0.9, 0.5)
	var dress = Color(0.22, 0.08, 0.32)
	var dress_lt = Color(0.35, 0.15, 0.48)
	var dress_acc = Color(0.5, 0.2, 0.6)
	var cape = Color(0.12, 0.04, 0.18)
	var glow = Color(0.4, 0.85, 0.25)
	var glow_p = Color(0.6, 0.3, 0.9)
	var cat_blk = Color(0.08, 0.06, 0.1)
	var cat_eye = Color(0.9, 0.75, 0.1)
	var wand = Color(0.35, 0.18, 0.08)
	var wand_gem = Color(0.3, 0.9, 0.4)
	var gold = Color(0.9, 0.8, 0.2)

	# Pointy hat (tall)
	_fill(img, cx - 1, 0, 3, 1, hat)
	_fill(img, cx - 2, 1, 5, 1, hat)
	_fill(img, cx - 3, 2, 7, 2, hat)
	_fill(img, cx - 4, 4, 9, 2, hat)
	_fill(img, cx - 5, 6, 11, 2, hat)
	_fill(img, cx - 6, 8, 13, 2, hat_dk)
	# Hat brim
	_fill(img, cx - 10, 10, 21, 2, hat_dk)
	# Hat band
	_fill(img, cx - 5, 7, 11, 1, hat_band)
	# Moon crescent
	_px(img, cx - 1, 5, moon)
	_px(img, cx, 4, moon)
	_px(img, cx, 5, moon)
	# Star on tip
	_px(img, cx, 0, glow_p)

	# Hair flowing
	_fill(img, cx - 7, 11, 3, 10, hair)
	_fill(img, cx + 5, 11, 3, 10, hair)
	_fill(img, cx - 8, 14, 2, 8, hair)
	_fill(img, cx + 7, 14, 2, 8, hair)

	# Face
	_ellipse(img, cx, 15, 5, 5, skin)
	_fill(img, cx - 5, 14, 2, 4, skin_shade)
	_fill(img, cx + 4, 14, 2, 4, skin_shade)
	# Eyes (green, witchy)
	_fill(img, cx - 3, 14, 2, 2, Color(0.15, 0.75, 0.2))
	_px(img, cx - 2, 15, Color(0.05, 0.15, 0.05))
	_fill(img, cx + 2, 14, 2, 2, Color(0.15, 0.75, 0.2))
	_px(img, cx + 3, 15, Color(0.05, 0.15, 0.05))
	# Eye shine
	_px(img, cx - 3, 14, Color(0.95, 1, 1, 0.8))
	_px(img, cx + 2, 14, Color(0.95, 1, 1, 0.8))
	# Lips
	_fill(img, cx - 1, 18, 3, 1, Color(0.5, 0.2, 0.3))

	# Neck + necklace
	_fill(img, cx - 2, 20, 5, 2, skin)
	_px(img, cx - 1, 21, gold)
	_px(img, cx + 1, 21, gold)
	_px(img, cx, 21, glow)  # Gem

	# Dress body (corset)
	_fill(img, cx - 7, 22, 15, 8, dress)
	# Corset lacing
	for y in range(22, 30):
		_px(img, cx, y, dress_acc)
	# Accent trim sides
	_fill(img, cx - 7, 22, 2, 8, dress_acc)
	_fill(img, cx + 6, 22, 2, 8, dress_acc)

	# Cape
	_fill(img, cx - 10, 22, 4, 14, cape)
	_fill(img, cx + 7, 22, 4, 14, cape)
	# Cape inner shimmer
	_px(img, cx - 9, 28, dress_lt)
	_px(img, cx + 8, 28, dress_lt)

	# Belt with potions
	_fill(img, cx - 7, 30, 15, 2, Color(0.35, 0.2, 0.08))
	_px(img, cx - 4, 30, Color(0.3, 0.85, 0.3))  # green potion
	_px(img, cx - 2, 30, Color(0.85, 0.3, 0.85))  # purple potion
	_px(img, cx + 2, 30, Color(0.3, 0.5, 0.9))    # blue potion
	_px(img, cx + 4, 30, gold)  # buckle

	# Arms
	_fill(img, cx - 12, 23, 3, 8, dress)
	_fill(img, cx + 10, 22, 3, 10, dress)
	# Hands
	_fill(img, cx - 12, 31, 3, 3, skin)
	_fill(img, cx + 10, 32, 3, 3, skin)

	# Wand (right hand raised)
	_fill(img, cx + 12, 18, 2, 14, wand)
	_fill(img, cx + 11, 16, 3, 3, wand_gem)
	_px(img, cx + 12, 15, glow)  # glow tip

	# Dress skirt (flowing)
	_fill(img, cx - 8, 32, 17, 4, dress)
	_fill(img, cx - 10, 36, 21, 4, dress)
	_fill(img, cx - 9, 40, 19, 3, dress_lt)
	# Flowing details
	for y in range(32, 43):
		_px(img, cx - 3, y, dress_lt)
		_px(img, cx, y, dress_acc)
		_px(img, cx + 3, y, dress_lt)

	# Boots (heeled)
	_fill(img, cx - 5, 43, 4, 4, Color(0.15, 0.08, 0.12))
	_fill(img, cx + 2, 43, 4, 4, Color(0.15, 0.08, 0.12))
	_px(img, cx - 4, 43, gold)
	_px(img, cx + 3, 43, gold)

	# Black cat (sitting near feet, left side)
	# Cat body
	_fill(img, cx - 18, 46, 6, 5, cat_blk)
	# Cat head
	_fill(img, cx - 17, 43, 5, 3, cat_blk)
	# Cat ears
	_px(img, cx - 17, 42, cat_blk)
	_px(img, cx - 13, 42, cat_blk)
	# Cat eyes
	_px(img, cx - 16, 44, cat_eye)
	_px(img, cx - 14, 44, cat_eye)
	# Cat tail
	_line(img, cx - 12, 49, cx - 9, 44, cat_blk)

	# Magic sparkles
	_px(img, cx - 14, 12, glow)
	_px(img, cx + 14, 16, glow_p)
	_px(img, cx - 12, 30, glow_p)
	_px(img, cx + 16, 26, glow)
	_px(img, cx + 18, 20, Color(1, 1, 0.7, 0.7))

	_save(img, "bruxa")
	_make_walk(img, "bruxa")

# ==================== LEALITH ====================
func _gen_lealith() -> void:
	var img = _img()
	var cx = 32
	var skin = Color(0.82, 0.72, 0.62)
	var skin_shade = Color(0.68, 0.58, 0.48)
	var hair_blk = Color(0.08, 0.06, 0.1)
	var hair_blue = Color(0.15, 0.3, 0.85)
	var ear_out = Color(0.06, 0.04, 0.08)
	var ear_in = Color(0.9, 0.82, 0.78)
	var eye_blue = Color(0.25, 0.55, 0.95)
	var bell = Color(0.9, 0.75, 0.15)
	var collar = Color(0.7, 0.12, 0.12)
	var jacket = Color(0.05, 0.05, 0.12)
	var jacket_blue = Color(0.12, 0.22, 0.52)
	var shirt = Color(0.15, 0.15, 0.22)
	var pants = Color(0.08, 0.08, 0.16)
	var pants_stripe = Color(0.1, 0.15, 0.42)
	var boots = Color(0.06, 0.06, 0.12)
	var boot_acc = Color(0.15, 0.25, 0.55)
	var tail = Color(0.06, 0.04, 0.08)
	var cuff = Color(0.85, 0.82, 0.78)

	# Cat ears
	# Left ear
	_fill(img, cx - 6, 1, 4, 5, ear_out)
	_fill(img, cx - 5, 2, 2, 3, ear_in)
	# Right ear
	_fill(img, cx + 3, 1, 4, 5, ear_out)
	_fill(img, cx + 4, 2, 2, 3, ear_in)

	# Hair
	_fill(img, cx - 6, 6, 12, 5, hair_blk)
	# Blue streak right side
	_fill(img, cx + 2, 6, 5, 5, hair_blue)
	_fill(img, cx + 6, 8, 3, 8, hair_blue)
	# Hair strands flowing
	_fill(img, cx - 7, 9, 2, 8, hair_blk)
	_fill(img, cx + 7, 10, 2, 7, hair_blue)
	# Ahoge (spiky tuft)
	_px(img, cx, 4, hair_blk)
	_px(img, cx + 1, 3, hair_blk)
	_px(img, cx + 1, 2, hair_blk)

	# Face
	_ellipse(img, cx, 13, 5, 5, skin)
	# Eyes
	_fill(img, cx - 3, 12, 2, 2, Color(1, 1, 1))
	_px(img, cx - 3, 13, eye_blue)
	_px(img, cx - 2, 13, Color(0.08, 0.12, 0.3))
	_fill(img, cx + 2, 12, 2, 2, Color(1, 1, 1))
	_px(img, cx + 3, 13, eye_blue)
	_px(img, cx + 2, 13, Color(0.08, 0.12, 0.3))
	# Eye shine
	_px(img, cx - 3, 12, Color(0.95, 1, 1, 0.9))
	_px(img, cx + 2, 12, Color(0.95, 1, 1, 0.9))
	# Smirk
	_px(img, cx, 16, Color(0.6, 0.35, 0.35))
	_px(img, cx + 1, 16, Color(0.6, 0.35, 0.35))

	# Bell earring on right ear
	_px(img, cx + 5, 7, bell)
	_px(img, cx + 5, 8, bell)

	# Neck + collar
	_fill(img, cx - 2, 18, 5, 2, skin)
	_fill(img, cx - 3, 19, 7, 1, collar)
	_px(img, cx, 20, bell)  # bell on collar

	# Jacket (black with blue accents)
	_fill(img, cx - 7, 20, 15, 10, jacket)
	# Blue lapels
	_fill(img, cx - 7, 20, 3, 6, jacket_blue)
	_fill(img, cx + 5, 20, 3, 6, jacket_blue)
	# Shirt V visible
	_fill(img, cx - 1, 21, 3, 3, shirt)
	# Shoulder stripes
	_fill(img, cx - 8, 20, 2, 3, jacket_blue)
	_fill(img, cx + 7, 20, 2, 3, jacket_blue)

	# Arms
	_fill(img, cx - 10, 22, 3, 10, jacket)
	_fill(img, cx + 8, 22, 3, 10, jacket)
	# White cuffs
	_fill(img, cx - 10, 31, 3, 1, cuff)
	_fill(img, cx + 8, 31, 3, 1, cuff)
	# Hands
	_fill(img, cx - 10, 32, 3, 3, skin)
	_fill(img, cx + 8, 32, 3, 3, skin)

	# Belt
	_fill(img, cx - 7, 30, 15, 2, jacket_blue)
	_px(img, cx, 30, bell)
	_px(img, cx + 1, 30, bell)

	# Pants
	_fill(img, cx - 5, 32, 4, 10, pants)
	_fill(img, cx + 2, 32, 4, 10, pants)
	# Blue stripes
	for y in range(32, 42):
		_px(img, cx - 3, y, pants_stripe)
		_px(img, cx + 4, y, pants_stripe)

	# Boots
	_fill(img, cx - 6, 42, 6, 6, boots)
	_fill(img, cx + 1, 42, 6, 6, boots)
	# Boot accents
	_fill(img, cx - 6, 42, 6, 1, boot_acc)
	_fill(img, cx + 1, 42, 6, 1, boot_acc)
	_px(img, cx - 4, 46, boot_acc)
	_px(img, cx + 3, 46, boot_acc)

	# Cat tail (curving left)
	_line(img, cx - 7, 28, cx - 12, 22, tail)
	_line(img, cx - 12, 22, cx - 13, 20, tail)
	# Blue tip
	_px(img, cx - 13, 20, hair_blue)
	_px(img, cx - 12, 21, hair_blue)

	# Sparkles
	_px(img, cx + 14, 30, Color(0.4, 0.6, 1, 0.8))
	_px(img, cx + 15, 28, Color(0.5, 0.7, 1, 0.6))

	_save(img, "lealith")
	_make_walk(img, "lealith")

# ==================== RONIN ====================
func _gen_ronin() -> void:
	var img = _img()
	var cx = 32
	var skin = Color(0.78, 0.65, 0.5)
	var skin_shade = Color(0.62, 0.5, 0.38)
	var hat_straw = Color(0.82, 0.72, 0.45)
	var hat_dk = Color(0.65, 0.55, 0.32)
	var kimono = Color(0.18, 0.55, 0.25)
	var kimono_dk = Color(0.12, 0.4, 0.18)
	var kimono_lt = Color(0.25, 0.65, 0.32)
	var sash = Color(0.2, 0.15, 0.1)
	var hakama = Color(0.15, 0.35, 0.18)
	var sandal = Color(0.55, 0.4, 0.22)
	var katana_blade = Color(0.8, 0.82, 0.88)
	var katana_guard = Color(0.72, 0.65, 0.18)
	var katana_handle = Color(0.18, 0.08, 0.12)

	# Straw hat (wide, conical)
	_fill(img, cx - 2, 2, 5, 2, hat_straw)
	_fill(img, cx - 4, 4, 9, 2, hat_straw)
	_fill(img, cx - 6, 6, 13, 2, hat_straw)
	_fill(img, cx - 9, 8, 19, 2, hat_dk)
	# Hat stripes
	_fill(img, cx - 5, 5, 11, 1, hat_dk)
	# Hat string
	_line(img, cx - 9, 10, cx - 5, 16, hat_dk)
	_line(img, cx + 9, 10, cx + 5, 16, hat_dk)

	# Hair underneath
	_fill(img, cx - 5, 10, 11, 3, Color(0.12, 0.1, 0.08))

	# Face
	_ellipse(img, cx, 14, 5, 4, skin)
	# Eyes (determined)
	_fill(img, cx - 3, 13, 2, 2, Color(1, 1, 1))
	_px(img, cx - 3, 14, Color(0.2, 0.15, 0.1))
	_px(img, cx - 2, 14, Color(0.05, 0.05, 0.05))
	_fill(img, cx + 2, 13, 2, 2, Color(1, 1, 1))
	_px(img, cx + 3, 14, Color(0.2, 0.15, 0.1))
	_px(img, cx + 2, 14, Color(0.05, 0.05, 0.05))
	# Serious mouth
	_fill(img, cx - 1, 17, 3, 1, Color(0.5, 0.35, 0.28))

	# Neck
	_fill(img, cx - 2, 18, 5, 2, skin)

	# Kimono top (V-neck)
	_fill(img, cx - 8, 20, 17, 10, kimono)
	# V-neck detail
	_line(img, cx, 20, cx - 3, 26, kimono_dk)
	_line(img, cx, 20, cx + 3, 26, kimono_dk)
	# Inner kimono visible at V
	_fill(img, cx - 2, 21, 5, 4, Color(0.85, 0.82, 0.75))
	# Kimono fold lines
	_fill(img, cx - 7, 22, 1, 8, kimono_dk)
	_fill(img, cx + 7, 22, 1, 8, kimono_dk)

	# Sash/obi
	_fill(img, cx - 8, 30, 17, 3, sash)

	# Arms (kimono sleeves, wide)
	_fill(img, cx - 12, 21, 5, 10, kimono)
	_fill(img, cx + 8, 21, 5, 10, kimono)
	# Sleeve borders
	_fill(img, cx - 12, 21, 5, 1, kimono_dk)
	_fill(img, cx + 8, 21, 5, 1, kimono_dk)
	# Hands
	_fill(img, cx - 11, 31, 3, 3, skin)
	_fill(img, cx + 9, 31, 3, 3, skin)

	# Hakama (wide pants)
	_fill(img, cx - 8, 33, 17, 12, hakama)
	# Hakama pleats
	for i in range(4):
		var lx = cx - 6 + i * 4
		_fill(img, lx, 33, 1, 12, kimono_dk)

	# Sandals
	_fill(img, cx - 7, 45, 6, 4, sandal)
	_fill(img, cx + 2, 45, 6, 4, sandal)
	# Sandal straps
	_px(img, cx - 5, 46, sash)
	_px(img, cx + 4, 46, sash)

	# Katana at hip (left side, in sash)
	_fill(img, cx - 14, 28, 2, 16, katana_handle)
	_fill(img, cx - 14, 26, 3, 2, katana_guard)
	# Blade going up
	_fill(img, cx - 14, 12, 2, 14, katana_blade)
	# Blade highlight
	_px(img, cx - 13, 14, Color(0.95, 0.97, 1.0))
	_px(img, cx - 13, 18, Color(0.95, 0.97, 1.0))

	_save(img, "ronin")
	_make_walk(img, "ronin")

# ==================== SOLDADO ====================
func _gen_soldado() -> void:
	var img = _img()
	var cx = 32
	var skin = Color(0.72, 0.58, 0.45)
	var skin_shade = Color(0.58, 0.44, 0.32)
	var helmet = Color(0.3, 0.45, 0.65)
	var helmet_dk = Color(0.22, 0.35, 0.52)
	var visor = Color(0.15, 0.2, 0.35)
	var armor = Color(0.35, 0.5, 0.72)
	var armor_dk = Color(0.25, 0.38, 0.55)
	var vest = Color(0.28, 0.42, 0.62)
	var pants = Color(0.22, 0.32, 0.48)
	var boots = Color(0.18, 0.22, 0.32)
	var belt = Color(0.25, 0.2, 0.15)
	var rifle_metal = Color(0.4, 0.42, 0.48)
	var rifle_stock = Color(0.35, 0.22, 0.12)
	var ammo = Color(0.5, 0.45, 0.2)

	# Helmet
	_ellipse(img, cx, 8, 7, 6, helmet)
	_fill(img, cx - 7, 6, 14, 3, helmet_dk)
	# Visor
	_fill(img, cx - 5, 10, 11, 3, visor)
	# Helmet top ridge
	_fill(img, cx - 1, 3, 3, 3, helmet)

	# Face (visible below visor)
	_fill(img, cx - 4, 13, 9, 4, skin)
	# Eyes through visor
	_fill(img, cx - 3, 11, 2, 1, Color(0.9, 0.9, 0.95))
	_fill(img, cx + 2, 11, 2, 1, Color(0.9, 0.9, 0.95))
	# Chin
	_fill(img, cx - 3, 16, 7, 1, skin_shade)

	# Neck guard
	_fill(img, cx - 5, 17, 11, 2, helmet_dk)

	# Tactical vest/body armor
	_fill(img, cx - 8, 19, 17, 12, vest)
	# Chest plate
	_fill(img, cx - 6, 19, 13, 4, armor)
	# Pouches
	_fill(img, cx - 7, 25, 4, 3, belt)
	_fill(img, cx + 4, 25, 4, 3, belt)
	# Ammo detail
	_px(img, cx - 6, 26, ammo)
	_px(img, cx + 5, 26, ammo)
	# Center line
	_fill(img, cx - 1, 19, 2, 10, armor_dk)
	# Shoulder pads
	_fill(img, cx - 10, 19, 3, 4, armor)
	_fill(img, cx + 8, 19, 3, 4, armor)

	# Belt
	_fill(img, cx - 8, 31, 17, 2, belt)
	_px(img, cx, 31, Color(0.7, 0.65, 0.2))  # buckle

	# Arms
	_fill(img, cx - 12, 20, 3, 12, armor_dk)
	_fill(img, cx + 10, 20, 3, 12, armor_dk)
	# Gloves
	_fill(img, cx - 12, 32, 3, 3, Color(0.2, 0.2, 0.2))
	_fill(img, cx + 10, 32, 3, 3, Color(0.2, 0.2, 0.2))

	# Pants (cargo)
	_fill(img, cx - 6, 33, 5, 12, pants)
	_fill(img, cx + 2, 33, 5, 12, pants)
	# Cargo pockets
	_fill(img, cx - 5, 37, 3, 3, pants.lightened(0.1))
	_fill(img, cx + 3, 37, 3, 3, pants.lightened(0.1))

	# Boots (combat)
	_fill(img, cx - 7, 45, 6, 6, boots)
	_fill(img, cx + 2, 45, 6, 6, boots)
	# Boot laces
	for i in range(3):
		_px(img, cx - 5, 46 + i * 2, Color(0.4, 0.38, 0.3))
		_px(img, cx + 4, 46 + i * 2, Color(0.4, 0.38, 0.3))

	# Rifle (held across body)
	# Stock
	_fill(img, cx + 10, 24, 3, 8, rifle_stock)
	# Body
	_fill(img, cx + 9, 20, 2, 5, rifle_metal)
	# Barrel (going up)
	_fill(img, cx + 10, 12, 2, 9, rifle_metal)
	# Muzzle
	_px(img, cx + 10, 11, Color(0.3, 0.3, 0.35))
	_px(img, cx + 11, 11, Color(0.3, 0.3, 0.35))

	_save(img, "soldado")
	_make_walk(img, "soldado")

# ==================== MAGO ====================
func _gen_mago() -> void:
	var img = _img()
	var cx = 32
	var skin = Color(0.78, 0.68, 0.58)
	var skin_shade = Color(0.62, 0.52, 0.42)
	var hat = Color(0.42, 0.15, 0.62)
	var hat_dk = Color(0.3, 0.1, 0.48)
	var hat_star = Color(0.95, 0.85, 0.25)
	var robe = Color(0.48, 0.2, 0.68)
	var robe_dk = Color(0.35, 0.12, 0.52)
	var robe_lt = Color(0.58, 0.3, 0.78)
	var sash_gold = Color(0.85, 0.75, 0.2)
	var beard = Color(0.82, 0.78, 0.72)
	var beard_dk = Color(0.65, 0.6, 0.55)
	var staff_wood = Color(0.4, 0.25, 0.12)
	var crystal = Color(0.6, 0.3, 0.9)
	var crystal_glow = Color(0.8, 0.5, 1.0)

	# Tall wizard hat
	_fill(img, cx, 0, 2, 1, hat)
	_fill(img, cx - 1, 1, 4, 2, hat)
	_fill(img, cx - 2, 3, 6, 2, hat)
	_fill(img, cx - 3, 5, 8, 2, hat)
	_fill(img, cx - 4, 7, 10, 3, hat)
	_fill(img, cx - 6, 10, 14, 2, hat_dk)
	# Hat brim
	_fill(img, cx - 10, 12, 22, 2, hat_dk)
	# Stars on hat
	_px(img, cx - 1, 5, hat_star)
	_px(img, cx + 2, 7, hat_star)
	_px(img, cx - 2, 8, hat_star)
	# Hat tip curve (wizard hats droop)
	_px(img, cx + 3, 0, hat)
	_px(img, cx + 2, 1, hat)

	# Long beard
	_fill(img, cx - 4, 18, 9, 3, beard)
	_fill(img, cx - 3, 21, 7, 4, beard)
	_fill(img, cx - 2, 25, 5, 4, beard)
	_fill(img, cx - 1, 29, 3, 2, beard)
	# Beard shading
	_fill(img, cx - 4, 19, 2, 3, beard_dk)
	_fill(img, cx + 3, 19, 2, 3, beard_dk)

	# Face (under hat brim)
	_ellipse(img, cx, 16, 5, 4, skin)
	# Eyes (wise, purple glow)
	_fill(img, cx - 3, 15, 2, 2, Color(1, 1, 1))
	_px(img, cx - 3, 16, Color(0.5, 0.2, 0.8))
	_px(img, cx - 2, 16, Color(0.15, 0.05, 0.2))
	_fill(img, cx + 2, 15, 2, 2, Color(1, 1, 1))
	_px(img, cx + 3, 16, Color(0.5, 0.2, 0.8))
	_px(img, cx + 2, 16, Color(0.15, 0.05, 0.2))
	# Bushy eyebrows
	_fill(img, cx - 4, 14, 3, 1, beard)
	_fill(img, cx + 2, 14, 3, 1, beard)
	# Nose
	_px(img, cx, 17, skin_shade)

	# Robe body
	_fill(img, cx - 8, 22, 17, 14, robe)
	# Robe V-neck detail
	_line(img, cx, 22, cx - 3, 28, robe_dk)
	_line(img, cx, 22, cx + 3, 28, robe_dk)
	# Robe trim
	_fill(img, cx - 8, 22, 1, 14, robe_lt)
	_fill(img, cx + 8, 22, 1, 14, robe_lt)
	# Stars embroidered on robe
	_px(img, cx - 4, 28, hat_star)
	_px(img, cx + 5, 32, hat_star)
	_px(img, cx - 2, 34, hat_star)

	# Gold sash
	_fill(img, cx - 8, 30, 17, 2, sash_gold)

	# Arms (wide sleeves)
	_fill(img, cx - 13, 23, 6, 10, robe)
	_fill(img, cx + 8, 23, 6, 10, robe)
	# Sleeve trim
	_fill(img, cx - 13, 32, 6, 1, robe_lt)
	_fill(img, cx + 8, 32, 6, 1, robe_lt)
	# Hands
	_fill(img, cx - 12, 33, 3, 3, skin)
	_fill(img, cx + 10, 33, 3, 3, skin)

	# Robe skirt
	_fill(img, cx - 10, 36, 21, 10, robe)
	_fill(img, cx - 9, 46, 19, 4, robe_dk)
	# Robe bottom trim
	_fill(img, cx - 10, 49, 21, 1, sash_gold)
	# Fold lines
	for i in range(4):
		var lx = cx - 7 + i * 5
		_fill(img, lx, 36, 1, 14, robe_dk)

	# Feet (peeking from robe)
	_fill(img, cx - 5, 50, 4, 3, Color(0.35, 0.2, 0.12))
	_fill(img, cx + 2, 50, 4, 3, Color(0.35, 0.2, 0.12))

	# Staff (left hand, tall)
	_fill(img, cx - 15, 6, 2, 38, staff_wood)
	# Staff knobs
	_fill(img, cx - 16, 18, 4, 2, staff_wood.darkened(0.2))
	# Crystal orb on top
	_circle(img, cx - 14, 5, 3, crystal)
	_circle(img, cx - 14, 5, 2, crystal_glow)
	_px(img, cx - 14, 4, Color(1, 0.9, 1, 0.9))  # shine

	_save(img, "mago")
	_make_walk(img, "mago")

# ==================== BERSERKER ====================
func _gen_berserker() -> void:
	var img = _img()
	var cx = 32
	var skin = Color(0.72, 0.48, 0.38)
	var skin_shade = Color(0.55, 0.35, 0.28)
	var skin_scar = Color(0.85, 0.5, 0.42)
	var hair = Color(0.7, 0.18, 0.08)
	var hair_dk = Color(0.5, 0.12, 0.05)
	var pants = Color(0.45, 0.2, 0.15)
	var pants_dk = Color(0.32, 0.14, 0.1)
	var belt_c = Color(0.35, 0.25, 0.15)
	var axe_handle = Color(0.4, 0.25, 0.12)
	var axe_blade = Color(0.65, 0.68, 0.75)
	var axe_edge = Color(0.82, 0.85, 0.9)
	var boots_c = Color(0.3, 0.2, 0.12)
	var fur = Color(0.6, 0.55, 0.45)
	var warpaint = Color(0.2, 0.15, 0.5)

	# Wild hair (big, spiky)
	_fill(img, cx - 7, 2, 15, 4, hair)
	_fill(img, cx - 8, 4, 17, 5, hair)
	_fill(img, cx - 9, 6, 19, 4, hair_dk)
	# Spiky tips
	_px(img, cx - 8, 1, hair)
	_px(img, cx - 5, 0, hair)
	_px(img, cx + 5, 0, hair)
	_px(img, cx + 8, 1, hair)
	_px(img, cx - 3, 1, hair)
	_px(img, cx + 3, 1, hair)
	_px(img, cx, 1, hair)

	# Face (wide, angry)
	_ellipse(img, cx, 13, 6, 5, skin)
	# Red angry eyes
	_fill(img, cx - 4, 12, 2, 2, Color(1, 1, 1))
	_px(img, cx - 4, 13, Color(0.9, 0.15, 0.1))
	_px(img, cx - 3, 13, Color(0.05, 0.05, 0.05))
	_fill(img, cx + 3, 12, 2, 2, Color(1, 1, 1))
	_px(img, cx + 4, 13, Color(0.9, 0.15, 0.1))
	_px(img, cx + 3, 13, Color(0.05, 0.05, 0.05))
	# Angry brow
	_line(img, cx - 5, 11, cx - 2, 12, Color(0.3, 0.15, 0.1))
	_line(img, cx + 5, 11, cx + 2, 12, Color(0.3, 0.15, 0.1))
	# War paint stripes
	_fill(img, cx - 5, 14, 2, 2, warpaint)
	_fill(img, cx + 4, 14, 2, 2, warpaint)
	# Snarling mouth with teeth
	_fill(img, cx - 2, 16, 5, 2, Color(0.3, 0.1, 0.08))
	_px(img, cx - 1, 16, Color(0.95, 0.95, 0.9))
	_px(img, cx + 1, 16, Color(0.95, 0.95, 0.9))
	_px(img, cx, 17, Color(0.95, 0.95, 0.9))

	# Neck (thick)
	_fill(img, cx - 3, 18, 7, 2, skin)

	# Bare muscular chest
	_fill(img, cx - 9, 20, 19, 12, skin)
	# Pectoral shading
	_fill(img, cx - 7, 22, 5, 2, skin_shade)
	_fill(img, cx + 3, 22, 5, 2, skin_shade)
	# Abs
	_fill(img, cx - 2, 26, 2, 1, skin_shade)
	_fill(img, cx + 1, 26, 2, 1, skin_shade)
	_fill(img, cx - 2, 28, 2, 1, skin_shade)
	_fill(img, cx + 1, 28, 2, 1, skin_shade)
	# Scars
	_line(img, cx - 5, 23, cx - 1, 27, skin_scar)
	_line(img, cx + 3, 24, cx + 6, 22, skin_scar)

	# Belt
	_fill(img, cx - 9, 32, 19, 2, belt_c)
	_px(img, cx, 32, Color(0.7, 0.6, 0.2))  # buckle
	# Skull on belt
	_circle(img, cx, 32, 2, Color(0.85, 0.82, 0.75))
	_px(img, cx - 1, 32, Color(0.2, 0.15, 0.1))
	_px(img, cx + 1, 32, Color(0.2, 0.15, 0.1))

	# Big arms (muscular)
	_fill(img, cx - 13, 20, 4, 14, skin)
	_fill(img, cx + 10, 20, 4, 14, skin)
	# Forearm bands
	_fill(img, cx - 13, 28, 4, 1, belt_c)
	_fill(img, cx + 10, 28, 4, 1, belt_c)
	# Fists
	_fill(img, cx - 13, 34, 4, 3, skin)
	_fill(img, cx + 10, 34, 4, 3, skin)

	# Pants
	_fill(img, cx - 7, 34, 6, 12, pants)
	_fill(img, cx + 2, 34, 6, 12, pants)
	# Leg separation
	_fill(img, cx - 1, 38, 3, 8, pants_dk)
	# Torn edges
	_px(img, cx - 7, 45, Color(0, 0, 0, 0))
	_px(img, cx + 7, 44, Color(0, 0, 0, 0))

	# Fur-trimmed boots
	_fill(img, cx - 8, 46, 7, 6, boots_c)
	_fill(img, cx + 2, 46, 7, 6, boots_c)
	# Fur trim
	_fill(img, cx - 8, 46, 7, 2, fur)
	_fill(img, cx + 2, 46, 7, 2, fur)

	# Battle axe (right side, huge)
	# Handle
	_fill(img, cx + 14, 10, 2, 30, axe_handle)
	# Axe head (large double-sided)
	_fill(img, cx + 12, 8, 6, 3, axe_blade)
	_fill(img, cx + 11, 10, 8, 3, axe_blade)
	_fill(img, cx + 12, 13, 6, 2, axe_blade)
	# Axe edge highlight
	_fill(img, cx + 11, 10, 1, 3, axe_edge)
	_fill(img, cx + 18, 10, 1, 3, axe_edge)

	_save(img, "berserker")
	_make_walk(img, "berserker")

# ==================== NINJA ====================
func _gen_ninja() -> void:
	var img = _img()
	var cx = 32
	var cloth_dk = Color(0.08, 0.08, 0.1)
	var cloth = Color(0.15, 0.15, 0.18)
	var cloth_lt = Color(0.22, 0.22, 0.28)
	var scarf = Color(0.75, 0.12, 0.12)
	var scarf_dk = Color(0.55, 0.08, 0.08)
	var skin = Color(0.72, 0.58, 0.45)
	var eye_col = Color(0.9, 0.9, 0.95)
	var metal = Color(0.55, 0.58, 0.62)
	var metal_dk = Color(0.35, 0.38, 0.42)

	# Head wrap
	_ellipse(img, cx, 10, 6, 6, cloth_dk)
	# Eye slit
	_fill(img, cx - 4, 9, 9, 2, cloth)
	# Eyes visible through slit
	_fill(img, cx - 3, 9, 2, 2, eye_col)
	_px(img, cx - 3, 10, Color(0.15, 0.15, 0.2))
	_fill(img, cx + 2, 9, 2, 2, eye_col)
	_px(img, cx + 3, 10, Color(0.15, 0.15, 0.2))
	# Head wrap detail
	_fill(img, cx - 5, 7, 11, 1, cloth_lt)

	# Red scarf (flowing behind)
	_fill(img, cx + 5, 8, 3, 4, scarf)
	_fill(img, cx + 7, 12, 3, 8, scarf)
	_fill(img, cx + 8, 18, 3, 6, scarf_dk)
	# Scarf wrap around neck
	_fill(img, cx - 4, 14, 9, 3, scarf)
	_fill(img, cx - 3, 16, 7, 1, scarf_dk)

	# Neck
	_fill(img, cx - 2, 16, 5, 2, cloth_dk)

	# Ninja tunic
	_fill(img, cx - 7, 17, 15, 14, cloth_dk)
	# Chest wrap
	_line(img, cx - 5, 18, cx + 5, 22, cloth_lt)
	_line(img, cx - 5, 22, cx + 5, 18, cloth_lt)
	# Belt
	_fill(img, cx - 7, 28, 15, 2, cloth)

	# Arms
	_fill(img, cx - 10, 18, 3, 12, cloth_dk)
	_fill(img, cx + 8, 18, 3, 12, cloth_dk)
	# Arm wraps
	_fill(img, cx - 10, 26, 3, 1, cloth_lt)
	_fill(img, cx + 8, 26, 3, 1, cloth_lt)
	# Hands
	_fill(img, cx - 10, 30, 3, 3, skin)
	_fill(img, cx + 8, 30, 3, 3, skin)

	# Pants
	_fill(img, cx - 5, 31, 4, 12, cloth_dk)
	_fill(img, cx + 2, 31, 4, 12, cloth_dk)
	# Leg wraps
	for i in range(3):
		_fill(img, cx - 5, 36 + i * 3, 4, 1, cloth_lt)
		_fill(img, cx + 2, 37 + i * 3, 4, 1, cloth_lt)

	# Tabi boots (split toe)
	_fill(img, cx - 6, 43, 5, 5, cloth)
	_fill(img, cx + 2, 43, 5, 5, cloth)
	# Split toe
	_px(img, cx - 4, 47, Color(0, 0, 0, 0))
	_px(img, cx + 4, 47, Color(0, 0, 0, 0))

	# Shuriken (held in right hand)
	var sh_cx = cx + 10
	var sh_cy = 28
	# 4-point star shape
	_fill(img, sh_cx - 1, sh_cy - 3, 3, 7, metal)
	_fill(img, sh_cx - 3, sh_cy - 1, 7, 3, metal)
	_px(img, sh_cx, sh_cy, metal_dk)

	# Kunai on belt
	_fill(img, cx - 9, 27, 1, 5, metal)
	_px(img, cx - 9, 32, metal_dk)  # tip

	_save(img, "ninja")
	_make_walk(img, "ninja")

# ==================== NECRO ====================
func _gen_necro() -> void:
	var img = _img()
	var cx = 32
	var hood = Color(0.1, 0.06, 0.15)
	var hood_dk = Color(0.06, 0.03, 0.1)
	var robe = Color(0.12, 0.08, 0.18)
	var robe_dk = Color(0.08, 0.05, 0.12)
	var skull = Color(0.85, 0.82, 0.75)
	var skull_dk = Color(0.65, 0.6, 0.52)
	var eye_green = Color(0.2, 0.9, 0.3)
	var eye_glow = Color(0.3, 1.0, 0.4)
	var bone = Color(0.82, 0.78, 0.68)
	var bone_dk = Color(0.62, 0.58, 0.48)
	var staff_bone = Color(0.75, 0.7, 0.6)
	var soul_green = Color(0.15, 0.8, 0.25, 0.7)

	# Hood (large, pointed)
	_fill(img, cx - 1, 1, 3, 2, hood)
	_fill(img, cx - 3, 3, 7, 2, hood)
	_fill(img, cx - 5, 5, 11, 3, hood)
	_fill(img, cx - 7, 8, 15, 4, hood)
	_fill(img, cx - 8, 12, 17, 3, hood_dk)
	# Hood shadow
	_fill(img, cx - 6, 10, 13, 2, hood_dk)

	# Skull mask visible in hood
	_ellipse(img, cx, 14, 5, 4, skull)
	# Dark eye sockets
	_fill(img, cx - 3, 13, 2, 2, Color(0.05, 0.02, 0.08))
	_fill(img, cx + 2, 13, 2, 2, Color(0.05, 0.02, 0.08))
	# Glowing green eyes
	_px(img, cx - 3, 13, eye_green)
	_px(img, cx + 3, 13, eye_green)
	# Eye glow aura
	_px(img, cx - 4, 13, Color(0.1, 0.5, 0.15, 0.5))
	_px(img, cx + 4, 13, Color(0.1, 0.5, 0.15, 0.5))
	# Nose hole
	_px(img, cx, 15, skull_dk)
	# Teeth
	_fill(img, cx - 2, 17, 5, 1, skull)
	_px(img, cx - 1, 17, skull_dk)
	_px(img, cx + 1, 17, skull_dk)

	# Robe body
	_fill(img, cx - 8, 18, 17, 16, robe)
	# Robe collar high
	_fill(img, cx - 7, 15, 3, 3, hood)
	_fill(img, cx + 5, 15, 3, 3, hood)
	# Bone necklace
	for i in range(5):
		_px(img, cx - 2 + i, 19, bone)
	# Robe details
	_line(img, cx, 20, cx, 33, robe_dk)

	# Arms (skeletal hands visible)
	_fill(img, cx - 12, 20, 4, 12, robe)
	_fill(img, cx + 9, 20, 4, 12, robe)
	# Skeletal hands
	_fill(img, cx - 12, 32, 4, 2, bone)
	_fill(img, cx + 9, 32, 4, 2, bone)
	# Finger bones
	_px(img, cx - 13, 34, bone)
	_px(img, cx - 11, 34, bone)
	_px(img, cx + 9, 34, bone)
	_px(img, cx + 11, 34, bone)

	# Robe skirt
	_fill(img, cx - 10, 34, 21, 12, robe)
	_fill(img, cx - 9, 46, 19, 4, robe_dk)
	# Tattered bottom edges
	for i in range(5):
		var tx = cx - 9 + i * 4
		_px(img, tx, 49, Color(0, 0, 0, 0))
		_px(img, tx + 1, 50, Color(0, 0, 0, 0))

	# Bone staff (left hand)
	_fill(img, cx - 16, 8, 2, 36, staff_bone)
	# Skull on top of staff
	_circle(img, cx - 15, 7, 3, skull)
	_px(img, cx - 16, 6, Color(0.05, 0.02, 0.08))
	_px(img, cx - 14, 6, Color(0.05, 0.02, 0.08))
	_px(img, cx - 16, 6, eye_green)
	_px(img, cx - 14, 6, eye_green)
	_px(img, cx - 15, 8, skull_dk)  # nose

	# Floating soul wisps
	_circle(img, cx + 14, 14, 2, soul_green)
	_px(img, cx + 14, 13, eye_glow)
	_circle(img, cx + 16, 20, 1, soul_green)
	_px(img, cx - 14, 36, soul_green)

	_save(img, "necro")
	_make_walk(img, "necro")

# ==================== PIRATA ====================
func _gen_pirata() -> void:
	var img = _img()
	var cx = 32
	var skin = Color(0.72, 0.55, 0.4)
	var skin_shade = Color(0.58, 0.42, 0.3)
	var hat = Color(0.2, 0.15, 0.1)
	var hat_dk = Color(0.12, 0.08, 0.06)
	var hat_band = Color(0.75, 0.6, 0.15)
	var skull_white = Color(0.9, 0.88, 0.85)
	var coat = Color(0.5, 0.32, 0.15)
	var coat_dk = Color(0.38, 0.22, 0.1)
	var shirt = Color(0.85, 0.82, 0.75)
	var pants_c = Color(0.3, 0.22, 0.12)
	var boots_c = Color(0.18, 0.12, 0.08)
	var gold = Color(0.9, 0.78, 0.2)
	var belt_c = Color(0.22, 0.15, 0.08)
	var pistol = Color(0.4, 0.38, 0.35)
	var eyepatch = Color(0.08, 0.06, 0.05)

	# Tricorn hat
	_fill(img, cx - 7, 4, 15, 3, hat)
	_fill(img, cx - 9, 7, 19, 2, hat)
	# Hat brim (tricorn folds up on sides)
	_fill(img, cx - 10, 9, 4, 2, hat_dk)
	_fill(img, cx + 7, 9, 4, 2, hat_dk)
	_fill(img, cx - 5, 9, 11, 2, hat)
	# Gold band
	_fill(img, cx - 6, 7, 13, 1, hat_band)
	# Skull emblem
	_circle(img, cx, 5, 2, skull_white)
	_px(img, cx - 1, 5, Color(0.1, 0.08, 0.06))
	_px(img, cx + 1, 5, Color(0.1, 0.08, 0.06))
	# Feather
	_fill(img, cx + 5, 1, 2, 5, Color(0.85, 0.2, 0.15))
	_px(img, cx + 6, 0, Color(0.85, 0.2, 0.15))

	# Hair (messy, dark)
	_fill(img, cx - 6, 10, 13, 4, Color(0.15, 0.1, 0.06))

	# Face
	_ellipse(img, cx, 15, 5, 5, skin)
	# Good eye (left)
	_fill(img, cx - 3, 14, 2, 2, Color(1, 1, 1))
	_px(img, cx - 3, 15, Color(0.3, 0.2, 0.1))
	_px(img, cx - 2, 15, Color(0.05, 0.05, 0.05))
	# Eye patch (right)
	_fill(img, cx + 2, 13, 3, 3, eyepatch)
	_line(img, cx + 3, 10, cx + 3, 13, eyepatch)
	# Smirk
	_fill(img, cx - 1, 18, 4, 1, Color(0.5, 0.3, 0.2))
	_px(img, cx + 2, 17, Color(0.5, 0.3, 0.2))  # smirk upturn
	# Stubble
	for i in range(3):
		_px(img, cx - 2 + i * 2, 19, skin_shade)

	# Neck
	_fill(img, cx - 2, 20, 5, 2, skin)

	# Coat (long pirate coat)
	_fill(img, cx - 8, 22, 17, 14, coat)
	# Coat lapels
	_fill(img, cx - 8, 22, 3, 8, coat_dk)
	_fill(img, cx + 6, 22, 3, 8, coat_dk)
	# Shirt visible underneath
	_fill(img, cx - 3, 22, 7, 6, shirt)
	# Gold buttons
	for i in range(4):
		_px(img, cx - 4, 23 + i * 2, gold)
		_px(img, cx + 4, 23 + i * 2, gold)

	# Belt with buckle
	_fill(img, cx - 8, 30, 17, 2, belt_c)
	_fill(img, cx - 1, 30, 3, 2, gold)

	# Arms
	_fill(img, cx - 12, 22, 4, 12, coat)
	_fill(img, cx + 9, 22, 4, 12, coat)
	# Cuffs
	_fill(img, cx - 12, 32, 4, 2, shirt)
	_fill(img, cx + 9, 32, 4, 2, shirt)
	# Hands
	_fill(img, cx - 12, 34, 3, 3, skin)
	_fill(img, cx + 10, 34, 3, 3, skin)

	# Coat tails
	_fill(img, cx - 9, 36, 4, 10, coat)
	_fill(img, cx + 6, 36, 4, 10, coat)
	# Coat trim
	_fill(img, cx - 9, 36, 4, 1, gold)
	_fill(img, cx + 6, 36, 4, 1, gold)

	# Pants
	_fill(img, cx - 5, 36, 4, 10, pants_c)
	_fill(img, cx + 2, 36, 4, 10, pants_c)

	# Boots (tall)
	_fill(img, cx - 6, 46, 5, 6, boots_c)
	_fill(img, cx + 2, 46, 5, 6, boots_c)
	# Boot cuff
	_fill(img, cx - 6, 46, 5, 2, coat_dk)
	_fill(img, cx + 2, 46, 5, 2, coat_dk)

	# Pistol (right hand)
	_fill(img, cx + 12, 30, 2, 6, pistol)
	_fill(img, cx + 11, 29, 4, 2, pistol)  # barrel
	_px(img, cx + 11, 28, Color(0.6, 0.55, 0.2))  # flintlock

	_save(img, "pirata")
	_make_walk(img, "pirata")

# ==================== ENGENHEIRO ====================
func _gen_engenheiro() -> void:
	var img = _img()
	var cx = 32
	var skin = Color(0.75, 0.6, 0.48)
	var skin_shade = Color(0.6, 0.46, 0.35)
	var hair = Color(0.35, 0.22, 0.12)
	var goggles = Color(0.5, 0.35, 0.15)
	var goggle_lens = Color(0.4, 0.7, 0.85)
	var goggle_rim = Color(0.65, 0.5, 0.2)
	var vest = Color(0.88, 0.7, 0.2)
	var vest_dk = Color(0.72, 0.55, 0.15)
	var shirt_c = Color(0.55, 0.4, 0.22)
	var pants_c = Color(0.4, 0.3, 0.18)
	var boots_c = Color(0.3, 0.22, 0.12)
	var mech_arm = Color(0.5, 0.52, 0.55)
	var mech_dk = Color(0.35, 0.38, 0.42)
	var wrench = Color(0.55, 0.58, 0.62)
	var belt_c = Color(0.35, 0.25, 0.12)
	var gear_gold = Color(0.8, 0.68, 0.18)

	# Hair (messy, short)
	_fill(img, cx - 6, 4, 13, 5, hair)
	_px(img, cx - 4, 3, hair)
	_px(img, cx + 2, 3, hair)

	# Goggles on forehead
	_fill(img, cx - 5, 6, 4, 3, goggle_rim)
	_fill(img, cx + 2, 6, 4, 3, goggle_rim)
	_fill(img, cx - 4, 7, 2, 1, goggle_lens)
	_fill(img, cx + 3, 7, 2, 1, goggle_lens)
	# Strap
	_fill(img, cx - 1, 7, 3, 1, goggles)

	# Face
	_ellipse(img, cx, 13, 5, 5, skin)
	_draw_eyes(img, cx, Color(0.4, 0.55, 0.2))
	# Grin
	_fill(img, cx - 2, 16, 5, 1, Color(0.5, 0.32, 0.22))
	_px(img, cx - 2, 15, Color(0.5, 0.32, 0.22))
	_px(img, cx + 2, 15, Color(0.5, 0.32, 0.22))

	# Neck
	_fill(img, cx - 2, 18, 5, 2, skin)

	# Yellow safety vest
	_fill(img, cx - 7, 20, 15, 12, vest)
	# Vest stripes (reflective)
	_fill(img, cx - 6, 23, 13, 1, Color(0.95, 0.9, 0.7))
	_fill(img, cx - 6, 27, 13, 1, Color(0.95, 0.9, 0.7))
	# Pockets
	_fill(img, cx - 6, 25, 4, 3, vest_dk)
	_fill(img, cx + 3, 25, 4, 3, vest_dk)
	# Pocket flaps
	_fill(img, cx - 6, 25, 4, 1, vest)

	# Belt with tools
	_fill(img, cx - 7, 32, 15, 2, belt_c)
	_px(img, cx - 4, 32, gear_gold)  # gear
	_px(img, cx + 4, 32, wrench.darkened(0.2))  # tool

	# Left arm (normal, shirt sleeve)
	_fill(img, cx - 10, 20, 3, 12, shirt_c)
	_fill(img, cx - 10, 32, 3, 3, skin)

	# Right arm (mechanical!)
	_fill(img, cx + 8, 20, 4, 12, mech_arm)
	# Mechanical joints
	_fill(img, cx + 8, 24, 4, 1, mech_dk)
	_fill(img, cx + 8, 28, 4, 1, mech_dk)
	# Rivets
	_px(img, cx + 9, 22, gear_gold)
	_px(img, cx + 9, 26, gear_gold)
	# Mechanical hand
	_fill(img, cx + 8, 32, 4, 3, mech_arm)
	_fill(img, cx + 8, 34, 4, 1, mech_dk)

	# Wrench in mech hand
	_fill(img, cx + 12, 28, 2, 8, wrench)
	_fill(img, cx + 11, 27, 4, 2, wrench)
	# Wrench head opening
	_px(img, cx + 12, 27, Color(0, 0, 0, 0))

	# Pants
	_fill(img, cx - 5, 34, 4, 10, pants_c)
	_fill(img, cx + 2, 34, 4, 10, pants_c)
	# Knee patches
	_fill(img, cx - 4, 39, 2, 2, pants_c.lightened(0.15))
	_fill(img, cx + 3, 39, 2, 2, pants_c.lightened(0.15))

	# Work boots
	_fill(img, cx - 6, 44, 6, 5, boots_c)
	_fill(img, cx + 1, 44, 6, 5, boots_c)
	# Steel toes
	_fill(img, cx - 6, 47, 3, 2, mech_arm)
	_fill(img, cx + 4, 47, 3, 2, mech_arm)

	_save(img, "engenheiro")
	_make_walk(img, "engenheiro")

# ==================== VAMPIRO ====================
func _gen_vampiro() -> void:
	var img = _img()
	var cx = 32
	var skin = Color(0.85, 0.8, 0.78)  # Very pale
	var skin_shade = Color(0.7, 0.65, 0.62)
	var hair = Color(0.12, 0.08, 0.1)
	var cape_out = Color(0.12, 0.02, 0.05)
	var cape_in = Color(0.55, 0.05, 0.12)
	var suit = Color(0.15, 0.08, 0.1)
	var suit_dk = Color(0.1, 0.05, 0.08)
	var vest_c = Color(0.45, 0.05, 0.1)
	var shirt_c = Color(0.88, 0.85, 0.82)
	var pants_c = Color(0.12, 0.08, 0.1)
	var boots_c = Color(0.08, 0.05, 0.06)
	var gold = Color(0.85, 0.72, 0.15)
	var blood = Color(0.7, 0.02, 0.05)

	# Hair (slicked back, widow's peak)
	_fill(img, cx - 6, 3, 13, 6, hair)
	_px(img, cx, 2, hair)  # widow's peak
	_px(img, cx - 1, 3, hair)
	_px(img, cx + 1, 3, hair)
	# Hair sides
	_fill(img, cx - 7, 8, 2, 6, hair)
	_fill(img, cx + 6, 8, 2, 6, hair)

	# Face (pale, angular)
	_ellipse(img, cx, 12, 5, 5, skin)
	# Red eyes
	_fill(img, cx - 3, 11, 2, 2, Color(1, 1, 1))
	_px(img, cx - 3, 12, Color(0.8, 0.1, 0.1))
	_px(img, cx - 2, 12, Color(0.2, 0.02, 0.02))
	_fill(img, cx + 2, 11, 2, 2, Color(1, 1, 1))
	_px(img, cx + 3, 12, Color(0.8, 0.1, 0.1))
	_px(img, cx + 2, 12, Color(0.2, 0.02, 0.02))
	# Eye shine
	_px(img, cx - 3, 11, Color(1, 0.9, 0.9, 0.9))
	_px(img, cx + 2, 11, Color(1, 0.9, 0.9, 0.9))
	# Sharp eyebrows
	_line(img, cx - 4, 10, cx - 2, 10, hair)
	_line(img, cx + 2, 10, cx + 4, 10, hair)
	# Thin smile with fangs
	_fill(img, cx - 2, 15, 5, 1, Color(0.4, 0.1, 0.12))
	_px(img, cx - 1, 16, Color(0.95, 0.95, 0.9))  # left fang
	_px(img, cx + 1, 16, Color(0.95, 0.95, 0.9))  # right fang
	# Blood drop on lip
	_px(img, cx + 2, 16, blood)

	# Neck
	_fill(img, cx - 2, 17, 5, 2, skin)

	# High collar cape
	_fill(img, cx - 8, 16, 4, 8, cape_out)
	_fill(img, cx + 5, 16, 4, 8, cape_out)
	# Collar inner
	_fill(img, cx - 7, 17, 2, 6, cape_in)
	_fill(img, cx + 6, 17, 2, 6, cape_in)

	# Suit jacket
	_fill(img, cx - 7, 19, 15, 12, suit)
	# Red vest
	_fill(img, cx - 4, 19, 9, 8, vest_c)
	# White shirt V
	_fill(img, cx - 1, 19, 3, 5, shirt_c)
	# Gold brooch
	_px(img, cx, 19, gold)
	# Suit buttons
	_px(img, cx - 4, 22, gold)
	_px(img, cx + 4, 22, gold)

	# Cape flowing behind (both sides)
	_fill(img, cx - 13, 20, 6, 26, cape_out)
	_fill(img, cx + 8, 20, 6, 26, cape_out)
	# Cape inner lining
	_fill(img, cx - 12, 22, 4, 22, cape_in)
	_fill(img, cx + 9, 22, 4, 22, cape_in)

	# Arms
	_fill(img, cx - 10, 20, 3, 12, suit)
	_fill(img, cx + 8, 20, 3, 12, suit)
	# Hands (pale)
	_fill(img, cx - 10, 32, 3, 3, skin)
	_fill(img, cx + 8, 32, 3, 3, skin)
	# Long nails
	_px(img, cx - 10, 35, Color(0.6, 0.58, 0.55))
	_px(img, cx + 8, 35, Color(0.6, 0.58, 0.55))

	# Pants
	_fill(img, cx - 5, 31, 4, 12, pants_c)
	_fill(img, cx + 2, 31, 4, 12, pants_c)

	# Tall boots
	_fill(img, cx - 6, 43, 5, 6, boots_c)
	_fill(img, cx + 2, 43, 5, 6, boots_c)
	# Boot tops
	_fill(img, cx - 6, 43, 5, 1, suit_dk)
	_fill(img, cx + 2, 43, 5, 1, suit_dk)

	# Whip coiled at belt
	_fill(img, cx - 8, 30, 3, 2, Color(0.35, 0.18, 0.1))
	_circle(img, cx - 7, 30, 2, Color(0.35, 0.18, 0.1))

	_save(img, "vampiro")
	_make_walk(img, "vampiro")

# ==================== GLADIADOR ====================
func _gen_gladiador() -> void:
	var img = _img()
	var cx = 32
	var skin = Color(0.72, 0.55, 0.42)
	var skin_shade = Color(0.58, 0.42, 0.3)
	var gold_armor = Color(0.82, 0.68, 0.2)
	var gold_dk = Color(0.62, 0.48, 0.12)
	var gold_lt = Color(0.92, 0.82, 0.35)
	var plume = Color(0.78, 0.12, 0.1)
	var plume_dk = Color(0.58, 0.08, 0.06)
	var leather_c = Color(0.45, 0.3, 0.15)
	var skirt_c = Color(0.65, 0.48, 0.15)
	var shield_c = Color(0.72, 0.58, 0.15)
	var sword_blade = Color(0.78, 0.8, 0.85)
	var sword_guard = Color(0.7, 0.6, 0.15)
	var sandal_c = Color(0.5, 0.35, 0.18)

	# Roman helmet
	_ellipse(img, cx, 9, 7, 6, gold_armor)
	_fill(img, cx - 7, 8, 14, 3, gold_dk)
	# Helmet cheek guards
	_fill(img, cx - 7, 12, 3, 5, gold_dk)
	_fill(img, cx + 5, 12, 3, 5, gold_dk)
	# Plume (red crest on top)
	_fill(img, cx - 1, 1, 3, 3, plume)
	_fill(img, cx - 2, 3, 5, 3, plume)
	_fill(img, cx - 1, 6, 3, 3, plume_dk)
	# Plume flowing back
	_fill(img, cx + 3, 3, 3, 6, plume_dk)
	_fill(img, cx + 5, 5, 2, 5, plume)

	# Face (visible through helmet)
	_fill(img, cx - 4, 12, 9, 5, skin)
	# Eyes (determined)
	_fill(img, cx - 3, 13, 2, 2, Color(1, 1, 1))
	_px(img, cx - 3, 14, Color(0.35, 0.25, 0.1))
	_px(img, cx - 2, 14, Color(0.08, 0.05, 0.05))
	_fill(img, cx + 2, 13, 2, 2, Color(1, 1, 1))
	_px(img, cx + 3, 14, Color(0.35, 0.25, 0.1))
	_px(img, cx + 2, 14, Color(0.08, 0.05, 0.05))
	# Strong jaw
	_fill(img, cx - 3, 16, 7, 1, skin_shade)

	# Neck
	_fill(img, cx - 2, 17, 5, 2, skin)

	# Golden chest armor (segmented)
	_fill(img, cx - 7, 19, 15, 12, gold_armor)
	# Chest muscle plate
	_fill(img, cx - 6, 19, 6, 4, gold_lt)
	_fill(img, cx + 1, 19, 6, 4, gold_lt)
	# Abdominal segments
	_fill(img, cx - 5, 24, 11, 1, gold_dk)
	_fill(img, cx - 5, 27, 11, 1, gold_dk)
	# Center line
	_fill(img, cx - 1, 19, 2, 12, gold_dk)
	# Shoulder pauldrons
	_fill(img, cx - 10, 19, 4, 5, gold_armor)
	_fill(img, cx + 7, 19, 4, 5, gold_armor)
	_fill(img, cx - 10, 19, 4, 2, gold_lt)
	_fill(img, cx + 7, 19, 4, 2, gold_lt)

	# Leather strips skirt (pteruges)
	_fill(img, cx - 8, 31, 17, 8, skirt_c)
	# Individual strips
	for i in range(5):
		var sx = cx - 7 + i * 3
		_fill(img, sx + 2, 32, 1, 7, leather_c.darkened(0.2))

	# Arms
	_fill(img, cx - 12, 22, 3, 10, skin)
	_fill(img, cx + 10, 22, 3, 10, skin)
	# Arm guards
	_fill(img, cx - 12, 22, 3, 3, gold_armor)
	_fill(img, cx + 10, 22, 3, 3, gold_armor)
	# Hands
	_fill(img, cx - 12, 32, 3, 3, skin)
	_fill(img, cx + 10, 32, 3, 3, skin)

	# Legs
	_fill(img, cx - 5, 39, 4, 8, skin)
	_fill(img, cx + 2, 39, 4, 8, skin)
	# Greaves (shin armor)
	_fill(img, cx - 5, 42, 4, 3, gold_armor)
	_fill(img, cx + 2, 42, 4, 3, gold_armor)

	# Sandals
	_fill(img, cx - 6, 47, 5, 4, sandal_c)
	_fill(img, cx + 2, 47, 5, 4, sandal_c)
	# Sandal straps
	_px(img, cx - 4, 45, sandal_c)
	_px(img, cx + 4, 45, sandal_c)

	# Shield (left side)
	_ellipse(img, cx - 16, 28, 5, 8, shield_c)
	_ellipse(img, cx - 16, 28, 3, 6, gold_lt)
	_circle(img, cx - 16, 28, 2, gold_dk)  # boss

	# Sword (right hand)
	# Handle
	_fill(img, cx + 12, 30, 2, 6, Color(0.35, 0.22, 0.1))
	# Guard
	_fill(img, cx + 10, 29, 6, 2, sword_guard)
	# Blade
	_fill(img, cx + 12, 16, 2, 13, sword_blade)
	# Blade tip
	_px(img, cx + 12, 15, Color(0.9, 0.92, 0.95))
	# Blade highlight
	_px(img, cx + 12, 20, Color(0.95, 0.97, 1.0))

	_save(img, "gladiador")
	_make_walk(img, "gladiador")

# ==================== CHEF ====================
func _gen_chef() -> void:
	var img = _img()
	var cx = 32
	var skin = Color(0.72, 0.58, 0.45)
	var skin_shade = Color(0.58, 0.44, 0.32)
	var hat_white = Color(0.95, 0.93, 0.9)
	var hat_shade = Color(0.82, 0.8, 0.75)
	var coat_white = Color(0.92, 0.9, 0.85)
	var coat_shade = Color(0.78, 0.75, 0.7)
	var apron = Color(0.88, 0.85, 0.8)
	var pants_c = Color(0.2, 0.2, 0.22)
	var shoes_c = Color(0.12, 0.12, 0.14)
	var neckerchief = Color(0.85, 0.15, 0.1)
	var button = Color(0.15, 0.15, 0.18)
	var pan_metal = Color(0.4, 0.42, 0.45)
	var pan_handle = Color(0.25, 0.15, 0.08)

	# Chef hat (toque - tall, puffy)
	_ellipse(img, cx, 6, 6, 5, hat_white)
	_fill(img, cx - 5, 4, 11, 4, hat_white)
	_fill(img, cx - 4, 1, 9, 4, hat_white)
	# Hat puffiness
	_fill(img, cx - 3, 2, 3, 3, hat_shade)
	_fill(img, cx + 2, 3, 3, 2, hat_shade)
	# Hat band
	_fill(img, cx - 6, 9, 13, 2, hat_shade)

	# Hair (sides visible)
	_fill(img, cx - 6, 10, 2, 4, Color(0.3, 0.2, 0.1))
	_fill(img, cx + 5, 10, 2, 4, Color(0.3, 0.2, 0.1))

	# Face
	_ellipse(img, cx, 14, 5, 5, skin)
	# Friendly eyes
	_draw_eyes(img, cx, Color(0.3, 0.45, 0.2))
	# Big smile
	_fill(img, cx - 2, 17, 5, 1, Color(0.5, 0.3, 0.2))
	_px(img, cx - 3, 16, Color(0.5, 0.3, 0.2))
	_px(img, cx + 3, 16, Color(0.5, 0.3, 0.2))
	# Moustache
	_fill(img, cx - 3, 15, 3, 1, Color(0.3, 0.2, 0.1))
	_fill(img, cx + 1, 15, 3, 1, Color(0.3, 0.2, 0.1))

	# Neck + neckerchief
	_fill(img, cx - 2, 19, 5, 2, skin)
	_fill(img, cx - 4, 19, 9, 2, neckerchief)
	# Neckerchief knot
	_fill(img, cx - 1, 21, 3, 2, neckerchief)

	# Chef coat (double-breasted)
	_fill(img, cx - 8, 21, 17, 14, coat_white)
	# Lapels
	_line(img, cx, 21, cx - 4, 28, coat_shade)
	_line(img, cx, 21, cx + 4, 28, coat_shade)
	# Double-breasted buttons
	for i in range(4):
		_px(img, cx - 3, 23 + i * 2, button)
		_px(img, cx + 3, 23 + i * 2, button)
	# Pocket
	_fill(img, cx + 4, 24, 3, 2, coat_shade)

	# Apron (white, tied at waist)
	_fill(img, cx - 6, 30, 13, 16, apron)
	# Apron string
	_line(img, cx - 6, 30, cx - 8, 32, coat_shade)
	_line(img, cx + 6, 30, cx + 8, 32, coat_shade)
	# Apron pocket
	_fill(img, cx - 3, 35, 7, 3, coat_shade)

	# Arms
	_fill(img, cx - 11, 22, 3, 12, coat_white)
	_fill(img, cx + 9, 22, 3, 12, coat_white)
	# Sleeves rolled up
	_fill(img, cx - 11, 22, 3, 2, coat_shade)
	_fill(img, cx + 9, 22, 3, 2, coat_shade)
	# Hands
	_fill(img, cx - 11, 34, 3, 3, skin)
	_fill(img, cx + 9, 34, 3, 3, skin)

	# Pants
	_fill(img, cx - 5, 46, 4, 6, pants_c)
	_fill(img, cx + 2, 46, 4, 6, pants_c)

	# Shoes
	_fill(img, cx - 6, 52, 5, 3, shoes_c)
	_fill(img, cx + 2, 52, 5, 3, shoes_c)

	# Frying pan (right hand, raised)
	# Handle
	_fill(img, cx + 11, 26, 2, 8, pan_handle)
	# Pan (circular)
	_circle(img, cx + 12, 22, 4, pan_metal)
	_circle(img, cx + 12, 22, 3, pan_metal.lightened(0.1))
	# Shine
	_px(img, cx + 11, 21, Color(0.7, 0.72, 0.75))

	_save(img, "chef")
	_make_walk(img, "chef")

# ==================== MYSTERY ====================
func _gen_mystery() -> void:
	var img = _img()
	var cx = 32
	var shadow_dk = Color(0.12, 0.12, 0.15)
	var shadow = Color(0.2, 0.2, 0.25)
	var shadow_lt = Color(0.3, 0.3, 0.38)
	var question = Color(0.8, 0.8, 0.85)
	var question_glow = Color(0.6, 0.6, 0.7, 0.5)
	var eye_glow = Color(0.7, 0.7, 0.8)

	# Dark shadowy silhouette — humanoid shape
	# Head
	_ellipse(img, cx, 12, 7, 7, shadow_dk)
	_ellipse(img, cx, 12, 6, 6, shadow)

	# Glowing eyes (subtle)
	_fill(img, cx - 3, 11, 2, 2, eye_glow)
	_fill(img, cx + 2, 11, 2, 2, eye_glow)
	_px(img, cx - 3, 12, Color(0.5, 0.5, 0.55))
	_px(img, cx + 3, 12, Color(0.5, 0.5, 0.55))

	# Body (formless, shadowy)
	_fill(img, cx - 8, 18, 17, 18, shadow_dk)
	_fill(img, cx - 7, 19, 15, 16, shadow)
	# Darker center
	_fill(img, cx - 4, 22, 9, 10, shadow_dk)

	# Arms (vague)
	_fill(img, cx - 12, 20, 5, 14, shadow_dk)
	_fill(img, cx + 8, 20, 5, 14, shadow_dk)
	_fill(img, cx - 11, 22, 3, 10, shadow)
	_fill(img, cx + 9, 22, 3, 10, shadow)

	# Legs (shadowy)
	_fill(img, cx - 6, 36, 5, 14, shadow_dk)
	_fill(img, cx + 2, 36, 5, 14, shadow_dk)
	_fill(img, cx - 5, 38, 3, 10, shadow)
	_fill(img, cx + 3, 38, 3, 10, shadow)

	# Feet (fading)
	_fill(img, cx - 7, 50, 6, 3, shadow_dk)
	_fill(img, cx + 2, 50, 6, 3, shadow_dk)

	# Giant "?" symbol on chest
	# Top curve of ?
	_fill(img, cx - 3, 22, 7, 2, question)
	_fill(img, cx + 2, 24, 3, 2, question)
	_fill(img, cx - 1, 26, 4, 2, question)
	_fill(img, cx, 28, 2, 2, question)
	# Dot of ?
	_fill(img, cx, 32, 2, 2, question)
	# Question mark glow
	_px(img, cx - 4, 21, question_glow)
	_px(img, cx + 5, 23, question_glow)
	_px(img, cx + 1, 31, question_glow)

	# Smoke/shadow wisps around edges
	_px(img, cx - 13, 22, shadow_lt)
	_px(img, cx + 13, 24, shadow_lt)
	_px(img, cx - 10, 35, shadow_lt)
	_px(img, cx + 10, 36, shadow_lt)
	_px(img, cx - 7, 52, shadow_lt)
	_px(img, cx + 8, 51, shadow_lt)

	_save(img, "mystery")
	_make_walk(img, "mystery")

# ==================== FRAGMENTADO ====================
func _gen_fragmentado() -> void:
	var img = _img()
	var cx = 32
	var skin = Color(0.55, 0.5, 0.48)
	var skin_shade = Color(0.42, 0.38, 0.35)
	var hood = Color(0.15, 0.18, 0.12)
	var hood_dk = Color(0.1, 0.12, 0.08)
	var robe_c = Color(0.12, 0.15, 0.1)
	var robe_dk = Color(0.08, 0.1, 0.06)
	var crystal_green = Color(0.0, 1.0, 0.6)
	var crystal_dk = Color(0.0, 0.65, 0.4)
	var crystal_glow = Color(0.2, 1.0, 0.7, 0.6)
	var crack_green = Color(0.0, 0.85, 0.5, 0.8)
	var eye_green = Color(0.1, 0.95, 0.55)

	# Hood
	_fill(img, cx - 2, 2, 5, 2, hood)
	_fill(img, cx - 4, 4, 9, 2, hood)
	_fill(img, cx - 6, 6, 13, 3, hood)
	_fill(img, cx - 7, 9, 15, 4, hood_dk)
	# Hood shadow depth
	_fill(img, cx - 6, 10, 13, 2, Color(0.05, 0.06, 0.04))

	# Face (partially visible in hood)
	_ellipse(img, cx, 14, 5, 4, skin)
	# Glowing green eyes (intense)
	_fill(img, cx - 3, 13, 2, 2, eye_green)
	_px(img, cx - 3, 14, Color(0.05, 0.4, 0.2))
	_fill(img, cx + 2, 13, 2, 2, eye_green)
	_px(img, cx + 3, 14, Color(0.05, 0.4, 0.2))
	# Green crystal cracks on face
	_line(img, cx - 4, 12, cx - 6, 8, crack_green)
	_line(img, cx + 4, 14, cx + 6, 10, crack_green)
	_px(img, cx - 1, 16, crack_green)

	# Neck
	_fill(img, cx - 2, 17, 5, 2, skin)

	# Robe body
	_fill(img, cx - 8, 19, 17, 16, robe_c)
	# Green energy cracks on robe
	_line(img, cx - 5, 22, cx - 7, 28, crack_green)
	_line(img, cx + 5, 24, cx + 7, 30, crack_green)
	_line(img, cx - 2, 26, cx + 2, 32, crack_green)
	# Robe detail
	_fill(img, cx - 8, 19, 1, 16, robe_dk)
	_fill(img, cx + 8, 19, 1, 16, robe_dk)

	# Belt (with crystal shard)
	_fill(img, cx - 8, 31, 17, 2, hood_dk)
	_fill(img, cx - 1, 30, 3, 3, crystal_green)
	_px(img, cx, 30, crystal_dk)

	# Arms
	_fill(img, cx - 12, 20, 4, 12, robe_c)
	_fill(img, cx + 9, 20, 4, 12, robe_c)
	# Hands (with green energy cracks)
	_fill(img, cx - 12, 32, 4, 3, skin)
	_fill(img, cx + 9, 32, 4, 3, skin)
	_px(img, cx - 11, 33, crack_green)
	_px(img, cx + 10, 33, crack_green)

	# Robe skirt
	_fill(img, cx - 9, 35, 19, 12, robe_c)
	_fill(img, cx - 8, 47, 17, 4, robe_dk)
	# Energy cracks on lower robe
	_line(img, cx - 6, 38, cx - 3, 46, crack_green)
	_line(img, cx + 4, 36, cx + 6, 44, crack_green)
	# Tattered bottom
	_px(img, cx - 8, 50, Color(0, 0, 0, 0))
	_px(img, cx + 7, 49, Color(0, 0, 0, 0))
	_px(img, cx - 4, 50, Color(0, 0, 0, 0))

	# Feet
	_fill(img, cx - 5, 51, 4, 3, Color(0.2, 0.22, 0.18))
	_fill(img, cx + 2, 51, 4, 3, Color(0.2, 0.22, 0.18))

	# Floating crystal shards around body
	# Shard 1 (top right)
	_fill(img, cx + 12, 10, 2, 4, crystal_green)
	_px(img, cx + 12, 10, crystal_dk)
	_px(img, cx + 13, 13, crystal_dk)
	# Shard 2 (top left)
	_fill(img, cx - 14, 14, 2, 3, crystal_green)
	_px(img, cx - 14, 14, crystal_dk)
	# Shard 3 (right mid)
	_fill(img, cx + 14, 26, 2, 3, crystal_green)
	_px(img, cx + 15, 26, crystal_dk)
	# Shard 4 (left low)
	_fill(img, cx - 15, 32, 2, 3, crystal_green)
	_px(img, cx - 14, 32, crystal_dk)
	# Shard 5 (bottom right)
	_fill(img, cx + 13, 40, 2, 3, crystal_green)

	# Glow aura around shards
	_px(img, cx + 11, 11, crystal_glow)
	_px(img, cx + 14, 12, crystal_glow)
	_px(img, cx - 15, 15, crystal_glow)
	_px(img, cx - 13, 13, crystal_glow)
	_px(img, cx + 13, 25, crystal_glow)
	_px(img, cx + 16, 27, crystal_glow)
	_px(img, cx - 16, 33, crystal_glow)
	_px(img, cx + 12, 39, crystal_glow)
	_px(img, cx + 15, 42, crystal_glow)

	_save(img, "fragmentado")
	_make_walk(img, "fragmentado")
