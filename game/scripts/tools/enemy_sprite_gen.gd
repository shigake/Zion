extends SceneTree

## Generates pixel art sprites for generic, cemetery, and forest enemies + bosses.
## Generic/themed enemies are 32x32, bosses are 64x64.
## Run: godot --headless --path game --script res://scripts/tools/enemy_sprite_gen.gd

const S32 := 32
const S64 := 64

const DIR_GENERIC := "res://assets/sprites/enemies/"
const DIR_CEMETERY := "res://assets/sprites/enemies/cemetery/"
const DIR_FOREST := "res://assets/sprites/enemies/forest/"
const DIR_BOSSES := "res://assets/sprites/bosses/"

func _init() -> void:
	DirAccess.make_dir_recursive_absolute(DIR_GENERIC)
	DirAccess.make_dir_recursive_absolute(DIR_CEMETERY)
	DirAccess.make_dir_recursive_absolute(DIR_FOREST)
	DirAccess.make_dir_recursive_absolute(DIR_BOSSES)

	# Generic enemies (32x32)
	print("=== Generic Enemies ===")
	_gen_slime()
	_gen_slime_big()
	_gen_skeleton()
	_gen_skeleton_archer()
	_gen_bat()
	_gen_ghost()
	_gen_zombie_runner()
	_gen_tank()
	_gen_bomber()

	# Cemetery enemies (32x32)
	print("=== Cemetery Enemies ===")
	_gen_cemetery_zombie()
	_gen_cemetery_banshee()
	_gen_cemetery_bone_knight()
	_gen_cemetery_ghoul()
	_gen_cemetery_gravedigger()
	_gen_cemetery_hand()
	_gen_cemetery_rat_swarm()
	_gen_cemetery_wraith()
	_gen_cemetery_reaper()

	# Forest enemies (32x32)
	print("=== Forest Enemies ===")
	_gen_forest_bear()
	_gen_forest_fairy()
	_gen_forest_mushroom()
	_gen_forest_owl()
	_gen_forest_spider()
	_gen_forest_treant()
	_gen_forest_vine()
	_gen_forest_wisp()
	_gen_forest_wolf()

	# Bosses (64x64)
	print("=== Bosses ===")
	_gen_cemetery_lich()
	_gen_cemetery_reaper_boss()
	_gen_forest_elder()
	_gen_forest_spider_boss()

	print("All 31 enemy sprites generated!")
	quit()

# ==================== HELPERS ====================

func _img32() -> Image:
	return Image.create(S32, S32, false, Image.FORMAT_RGBA8)

func _img64() -> Image:
	return Image.create(S64, S64, false, Image.FORMAT_RGBA8)

func _px(img: Image, x: int, y: int, color: Color) -> void:
	var s = img.get_width()
	if x >= 0 and x < s and y >= 0 and y < s:
		img.set_pixel(x, y, color)

func _fill(img: Image, x: int, y: int, w: int, h: int, color: Color) -> void:
	var s = img.get_width()
	for px in range(maxi(x, 0), mini(x + w, s)):
		for py in range(maxi(y, 0), mini(y + h, s)):
			img.set_pixel(px, py, color)

func _circle(img: Image, cx: int, cy: int, r: int, color: Color) -> void:
	var s = img.get_width()
	for x in range(maxi(cx - r, 0), mini(cx + r + 1, s)):
		for y in range(maxi(cy - r, 0), mini(cy + r + 1, s)):
			if (x - cx) * (x - cx) + (y - cy) * (y - cy) <= r * r:
				img.set_pixel(x, y, color)

func _ellipse(img: Image, cx: int, cy: int, rx: int, ry: int, color: Color) -> void:
	var s = img.get_width()
	for x in range(maxi(cx - rx, 0), mini(cx + rx + 1, s)):
		for y in range(maxi(cy - ry, 0), mini(cy + ry + 1, s)):
			var dx = float(x - cx) / float(rx) if rx > 0 else 0.0
			var dy = float(y - cy) / float(ry) if ry > 0 else 0.0
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

func _triangle(img: Image, x0: int, y0: int, x1: int, y1: int, x2: int, y2: int, color: Color) -> void:
	var s = img.get_width()
	var min_x = maxi(mini(mini(x0, x1), x2), 0)
	var max_x = mini(maxi(maxi(x0, x1), x2), s - 1)
	var min_y = maxi(mini(mini(y0, y1), y2), 0)
	var max_y = mini(maxi(maxi(y0, y1), y2), s - 1)
	for x in range(min_x, max_x + 1):
		for y in range(min_y, max_y + 1):
			var d1 = (x - x1) * (y0 - y1) - (x0 - x1) * (y - y1)
			var d2 = (x - x2) * (y1 - y2) - (x1 - x2) * (y - y2)
			var d3 = (x - x0) * (y2 - y0) - (x2 - x0) * (y - y0)
			var has_neg = (d1 < 0) or (d2 < 0) or (d3 < 0)
			var has_pos = (d1 > 0) or (d2 > 0) or (d3 > 0)
			if not (has_neg and has_pos):
				_px(img, x, y, color)

func _outline(img: Image, color: Color) -> void:
	var s = img.get_width()
	var copy = img.duplicate()
	for x in range(s):
		for y in range(s):
			if copy.get_pixel(x, y).a > 0:
				continue
			for off in [Vector2i(-1,0), Vector2i(1,0), Vector2i(0,-1), Vector2i(0,1)]:
				var nx = x + off.x
				var ny = y + off.y
				if nx >= 0 and nx < s and ny >= 0 and ny < s:
					if copy.get_pixel(nx, ny).a > 0:
						img.set_pixel(x, y, color)
						break

func _save32(img: Image, dir: String, name: String) -> void:
	_outline(img, Color.BLACK)
	img.save_png(dir + name + ".png")
	print("  Saved: ", dir, name, ".png")

func _save64(img: Image, dir: String, name: String) -> void:
	_outline(img, Color.BLACK)
	img.save_png(dir + name + ".png")
	print("  Saved: ", dir, name, ".png")

# ==================== GENERIC ENEMIES (32x32) ====================

func _gen_slime() -> void:
	var img = _img32()
	var body = Color(0.25, 0.65, 0.2)
	var light = Color(0.4, 0.8, 0.35)
	var dark = Color(0.15, 0.45, 0.12)
	# Blob body
	_fill(img, 11, 10, 10, 2, body)
	_fill(img, 9, 12, 14, 2, body)
	_fill(img, 7, 14, 18, 8, body)
	_fill(img, 9, 22, 14, 3, dark)
	_fill(img, 11, 25, 10, 2, dark)
	# Highlight
	_fill(img, 10, 12, 4, 3, light)
	_circle(img, 12, 11, 2, light)
	# Big eyes
	_fill(img, 10, 16, 4, 4, Color.WHITE)
	_fill(img, 18, 16, 4, 4, Color.WHITE)
	_fill(img, 11, 17, 2, 2, Color(0.05, 0.05, 0.1))
	_fill(img, 19, 17, 2, 2, Color(0.05, 0.05, 0.1))
	# Eye shine
	_px(img, 10, 16, Color(1, 1, 1, 0.9))
	_px(img, 18, 16, Color(1, 1, 1, 0.9))
	# Mouth
	_fill(img, 14, 21, 4, 1, dark)
	_save32(img, DIR_GENERIC, "slime")

func _gen_slime_big() -> void:
	var img = _img32()
	var body = Color(0.2, 0.6, 0.2)
	var light = Color(0.3, 0.7, 0.3)
	var dark = Color(0.12, 0.45, 0.12)
	# Larger blob
	_fill(img, 10, 5, 12, 2, body)
	_fill(img, 7, 7, 18, 2, body)
	_fill(img, 5, 9, 22, 2, body)
	_fill(img, 4, 11, 24, 10, body)
	_fill(img, 5, 21, 22, 2, dark)
	_fill(img, 6, 23, 20, 2, dark)
	_fill(img, 8, 25, 16, 2, dark)
	_fill(img, 10, 27, 12, 2, dark)
	# Highlight
	_fill(img, 9, 7, 4, 3, light)
	# Angry eyes
	_fill(img, 9, 14, 4, 4, Color.WHITE)
	_fill(img, 10, 15, 2, 2, Color(0.1, 0.1, 0.1))
	_fill(img, 19, 14, 4, 4, Color.WHITE)
	_fill(img, 20, 15, 2, 2, Color(0.1, 0.1, 0.1))
	# Angry eyebrows
	_px(img, 9, 13, Color(0.1, 0.1, 0.1))
	_px(img, 10, 12, Color(0.1, 0.1, 0.1))
	_px(img, 22, 13, Color(0.1, 0.1, 0.1))
	_px(img, 21, 12, Color(0.1, 0.1, 0.1))
	# Teeth mouth
	_fill(img, 12, 20, 8, 2, Color(0.1, 0.35, 0.1))
	_px(img, 13, 20, Color.WHITE)
	_px(img, 15, 20, Color.WHITE)
	_px(img, 17, 20, Color.WHITE)
	_save32(img, DIR_GENERIC, "slime_big")

func _gen_skeleton() -> void:
	var img = _img32()
	var bone = Color(0.9, 0.88, 0.8)
	var bone_dk = Color(0.7, 0.65, 0.55)
	var eye = Color(0.9, 0.15, 0.1)
	var sword = Color(0.75, 0.78, 0.82)
	# Skull
	_fill(img, 12, 3, 8, 8, bone)
	_fill(img, 11, 5, 10, 5, bone)
	# Eye sockets
	_fill(img, 13, 5, 2, 2, Color(0.15, 0.1, 0.1))
	_px(img, 13, 5, eye)
	_fill(img, 17, 5, 2, 2, Color(0.15, 0.1, 0.1))
	_px(img, 18, 5, eye)
	# Jaw
	_fill(img, 13, 9, 6, 2, bone_dk)
	_px(img, 14, 10, Color(0.2, 0.15, 0.1))
	_px(img, 16, 10, Color(0.2, 0.15, 0.1))
	# Spine
	_fill(img, 15, 11, 2, 3, bone_dk)
	# Ribcage
	_fill(img, 11, 14, 10, 6, bone)
	_fill(img, 13, 15, 1, 4, bone_dk)
	_fill(img, 15, 15, 2, 4, Color(0.2, 0.15, 0.1))
	_fill(img, 18, 15, 1, 4, bone_dk)
	# Arms
	_fill(img, 8, 14, 3, 2, bone)
	_fill(img, 7, 16, 2, 6, bone)
	_fill(img, 21, 14, 3, 2, bone)
	_fill(img, 22, 16, 2, 6, bone)
	# Legs
	_fill(img, 12, 20, 3, 7, bone)
	_fill(img, 17, 20, 3, 7, bone)
	# Feet
	_fill(img, 11, 27, 4, 2, bone_dk)
	_fill(img, 17, 27, 4, 2, bone_dk)
	# Sword in right hand
	_fill(img, 23, 8, 2, 14, sword)
	_fill(img, 22, 7, 4, 2, Color(0.55, 0.4, 0.2))
	_px(img, 24, 7, sword)
	_save32(img, DIR_GENERIC, "skeleton")

func _gen_skeleton_archer() -> void:
	var img = _img32()
	var bone = Color(0.9, 0.88, 0.8)
	var bone_dk = Color(0.7, 0.65, 0.55)
	var eye = Color(0.9, 0.15, 0.1)
	var bow = Color(0.5, 0.32, 0.15)
	# Skull
	_fill(img, 12, 3, 8, 8, bone)
	_fill(img, 11, 5, 10, 5, bone)
	# Eye sockets
	_fill(img, 13, 5, 2, 2, Color(0.15, 0.1, 0.1))
	_px(img, 13, 5, eye)
	_fill(img, 17, 5, 2, 2, Color(0.15, 0.1, 0.1))
	_px(img, 18, 5, eye)
	# Jaw
	_fill(img, 13, 9, 6, 2, bone_dk)
	# Spine
	_fill(img, 15, 11, 2, 3, bone_dk)
	# Ribcage
	_fill(img, 11, 14, 10, 6, bone)
	_fill(img, 15, 15, 2, 4, Color(0.2, 0.15, 0.1))
	# Arms (one holding bow)
	_fill(img, 8, 14, 3, 2, bone)
	_fill(img, 7, 16, 2, 6, bone)
	_fill(img, 21, 14, 3, 2, bone)
	_fill(img, 22, 16, 2, 6, bone)
	# Legs
	_fill(img, 12, 20, 3, 7, bone)
	_fill(img, 17, 20, 3, 7, bone)
	_fill(img, 11, 27, 4, 2, bone_dk)
	_fill(img, 17, 27, 4, 2, bone_dk)
	# Bow (left side)
	_line(img, 5, 10, 5, 24, bow)
	_line(img, 5, 10, 7, 13, bow)
	_line(img, 5, 24, 7, 21, bow)
	# Bowstring
	_line(img, 7, 11, 7, 23, Color(0.8, 0.8, 0.75))
	# Arrow nocked
	_line(img, 7, 17, 3, 17, Color(0.5, 0.32, 0.15))
	_px(img, 2, 17, Color(0.7, 0.7, 0.75))
	_save32(img, DIR_GENERIC, "skeleton_archer")

func _gen_bat() -> void:
	var img = _img32()
	var body = Color(0.4, 0.2, 0.5)
	var wing = Color(0.5, 0.28, 0.6)
	var wing_dk = Color(0.3, 0.14, 0.4)
	var eye = Color(0.95, 0.85, 0.1)
	# Body (small oval center)
	_fill(img, 13, 12, 6, 8, body)
	_fill(img, 12, 14, 8, 4, body)
	# Head
	_fill(img, 12, 9, 8, 5, body)
	_fill(img, 13, 8, 6, 1, body)
	# Ears
	_px(img, 12, 7, body)
	_px(img, 11, 6, body)
	_px(img, 19, 7, body)
	_px(img, 20, 6, body)
	# Eyes
	_fill(img, 13, 11, 2, 2, eye)
	_fill(img, 17, 11, 2, 2, eye)
	_px(img, 13, 11, Color(1, 1, 0.5))
	_px(img, 17, 11, Color(1, 1, 0.5))
	# Fangs
	_px(img, 14, 14, Color.WHITE)
	_px(img, 17, 14, Color.WHITE)
	# Wings
	_fill(img, 4, 11, 8, 2, wing)
	_fill(img, 2, 13, 10, 2, wing)
	_fill(img, 1, 15, 11, 2, wing_dk)
	_fill(img, 2, 17, 10, 2, wing_dk)
	_fill(img, 20, 11, 8, 2, wing)
	_fill(img, 20, 13, 10, 2, wing)
	_fill(img, 20, 15, 11, 2, wing_dk)
	_fill(img, 20, 17, 10, 2, wing_dk)
	_save32(img, DIR_GENERIC, "bat")

func _gen_ghost() -> void:
	var img = _img32()
	var body = Color(0.9, 0.92, 0.95, 0.75)
	var light = Color(0.95, 0.97, 1.0, 0.85)
	var eye = Color(0.3, 0.5, 0.9)
	# Ghostly body tapering down
	_fill(img, 10, 4, 12, 4, light)
	_fill(img, 8, 8, 16, 10, body)
	_fill(img, 9, 18, 14, 3, body)
	_fill(img, 10, 21, 12, 2, body)
	# Wavy bottom
	_fill(img, 8, 23, 4, 2, body)
	_fill(img, 14, 24, 3, 2, body)
	_fill(img, 20, 23, 4, 2, body)
	# Eyes
	_fill(img, 11, 10, 3, 3, eye)
	_fill(img, 18, 10, 3, 3, eye)
	_px(img, 12, 11, Color(0.15, 0.25, 0.7))
	_px(img, 19, 11, Color(0.15, 0.25, 0.7))
	# Eye shine
	_px(img, 11, 10, Color(1, 1, 1, 0.9))
	_px(img, 18, 10, Color(1, 1, 1, 0.9))
	# Mouth (oval)
	_fill(img, 14, 14, 4, 3, Color(0.2, 0.2, 0.3, 0.6))
	_save32(img, DIR_GENERIC, "ghost")

func _gen_zombie_runner() -> void:
	var img = _img32()
	var skin = Color(0.4, 0.55, 0.3)
	var skin_dk = Color(0.3, 0.4, 0.2)
	var cloth = Color(0.35, 0.25, 0.2)
	var eye = Color(0.9, 0.2, 0.15)
	# Head
	_fill(img, 12, 2, 8, 7, skin)
	# Exposed bone on top
	_fill(img, 14, 2, 3, 2, Color(0.85, 0.82, 0.75))
	# Eyes (red, one bigger)
	_fill(img, 13, 4, 2, 2, eye)
	_fill(img, 17, 5, 2, 2, eye)
	_px(img, 14, 5, Color(0.1, 0.05, 0.05))
	_px(img, 18, 6, Color(0.1, 0.05, 0.05))
	# Mouth (open, groaning)
	_fill(img, 14, 7, 4, 2, Color(0.3, 0.15, 0.1))
	_px(img, 15, 7, Color.WHITE)
	_px(img, 17, 7, Color.WHITE)
	# Torso (tattered)
	_fill(img, 11, 10, 10, 8, cloth)
	_fill(img, 12, 11, 8, 6, skin_dk)
	# Arms (running pose - forward and back)
	_fill(img, 7, 11, 4, 2, skin)
	_fill(img, 5, 13, 3, 5, skin)
	_fill(img, 21, 13, 4, 2, skin)
	_fill(img, 23, 10, 3, 4, skin)
	# Legs (running stride)
	_fill(img, 11, 18, 3, 7, skin)
	_fill(img, 9, 25, 4, 3, skin_dk)
	_fill(img, 18, 18, 3, 7, skin)
	_fill(img, 20, 22, 4, 3, skin_dk)
	# Blood splatters
	_px(img, 13, 12, Color(0.6, 0.1, 0.05))
	_px(img, 17, 14, Color(0.6, 0.1, 0.05))
	_px(img, 15, 16, Color(0.6, 0.1, 0.05))
	_save32(img, DIR_GENERIC, "zombie_runner")

func _gen_tank() -> void:
	var img = _img32()
	var iron = Color(0.3, 0.3, 0.35)
	var iron_dk = Color(0.2, 0.2, 0.25)
	var iron_lt = Color(0.45, 0.45, 0.5)
	var eye = Color(0.85, 0.15, 0.1)
	# Large body
	_fill(img, 6, 4, 20, 6, iron)
	_fill(img, 4, 10, 24, 12, iron)
	_fill(img, 6, 22, 20, 4, iron_dk)
	# Head (small atop body)
	_fill(img, 11, 1, 10, 5, iron_dk)
	# Small red eyes
	_fill(img, 12, 3, 2, 2, eye)
	_fill(img, 18, 3, 2, 2, eye)
	# Shoulder plates
	_fill(img, 3, 8, 5, 5, iron_lt)
	_fill(img, 24, 8, 5, 5, iron_lt)
	# Chest rivets
	_px(img, 12, 13, iron_lt)
	_px(img, 16, 13, iron_lt)
	_px(img, 20, 13, iron_lt)
	_px(img, 14, 17, iron_lt)
	_px(img, 18, 17, iron_lt)
	# Arms (thick)
	_fill(img, 2, 14, 4, 8, iron)
	_fill(img, 26, 14, 4, 8, iron)
	# Fists
	_fill(img, 1, 22, 5, 3, iron_dk)
	_fill(img, 26, 22, 5, 3, iron_dk)
	# Legs (thick pillars)
	_fill(img, 8, 26, 5, 4, iron_dk)
	_fill(img, 19, 26, 5, 4, iron_dk)
	_save32(img, DIR_GENERIC, "tank")

func _gen_bomber() -> void:
	var img = _img32()
	var skin = Color(0.4, 0.6, 0.3)
	var skin_dk = Color(0.3, 0.45, 0.2)
	var cloth = Color(0.5, 0.35, 0.2)
	var bomb = Color(0.2, 0.2, 0.22)
	# Head (small, pointy ears)
	_fill(img, 12, 5, 8, 7, skin)
	_px(img, 10, 5, skin)
	_px(img, 9, 4, skin)
	_px(img, 21, 5, skin)
	_px(img, 22, 4, skin)
	# Big eyes (mischievous)
	_fill(img, 13, 7, 3, 3, Color(0.95, 0.9, 0.1))
	_fill(img, 18, 7, 3, 3, Color(0.95, 0.9, 0.1))
	_px(img, 14, 8, Color(0.1, 0.1, 0.1))
	_px(img, 19, 8, Color(0.1, 0.1, 0.1))
	# Grin
	_fill(img, 14, 10, 4, 1, Color(0.2, 0.1, 0.05))
	_px(img, 15, 11, Color.WHITE)
	_px(img, 17, 11, Color.WHITE)
	# Body (small)
	_fill(img, 11, 13, 10, 7, cloth)
	# Belt
	_fill(img, 11, 18, 10, 2, Color(0.35, 0.2, 0.1))
	_px(img, 16, 18, Color(0.8, 0.7, 0.2))
	# Arms
	_fill(img, 8, 13, 3, 5, skin)
	_fill(img, 21, 13, 3, 5, skin)
	# Legs
	_fill(img, 12, 20, 3, 6, cloth)
	_fill(img, 17, 20, 3, 6, cloth)
	_fill(img, 11, 26, 4, 2, skin_dk)
	_fill(img, 17, 26, 4, 2, skin_dk)
	# Round bomb (held above head)
	_circle(img, 8, 10, 4, bomb)
	# Fuse
	_line(img, 8, 6, 10, 3, Color(0.5, 0.35, 0.15))
	# Spark on fuse
	_px(img, 10, 3, Color(1.0, 0.8, 0.1))
	_px(img, 11, 2, Color(1.0, 0.5, 0.1))
	_save32(img, DIR_GENERIC, "bomber")

# ==================== CEMETERY ENEMIES (32x32) ====================

func _gen_cemetery_zombie() -> void:
	var img = _img32()
	var skin = Color(0.45, 0.55, 0.4)
	var skin_dk = Color(0.35, 0.42, 0.3)
	var cloth = Color(0.3, 0.28, 0.25)
	var cloth_dk = Color(0.22, 0.2, 0.18)
	var eye = Color(0.8, 0.8, 0.2)
	# Head
	_fill(img, 12, 3, 8, 7, skin)
	# Missing chunk on head
	_fill(img, 17, 3, 3, 2, skin_dk)
	# Eyes (yellow, blank)
	_fill(img, 13, 5, 2, 2, eye)
	_fill(img, 17, 5, 2, 2, eye)
	_px(img, 14, 6, Color(0.1, 0.1, 0.05))
	_px(img, 18, 6, Color(0.1, 0.1, 0.05))
	# Mouth (hanging open)
	_fill(img, 14, 8, 4, 2, Color(0.25, 0.15, 0.1))
	_px(img, 15, 8, Color(0.8, 0.78, 0.7))
	# Tattered shirt
	_fill(img, 10, 11, 12, 8, cloth)
	_fill(img, 11, 12, 10, 6, cloth_dk)
	# Tears in cloth
	_px(img, 13, 15, skin_dk)
	_px(img, 18, 13, skin_dk)
	# Arms (one limp)
	_fill(img, 7, 12, 3, 7, skin)
	_fill(img, 22, 11, 3, 8, skin)
	_fill(img, 22, 19, 2, 3, skin_dk)
	# Legs
	_fill(img, 11, 19, 4, 7, cloth)
	_fill(img, 17, 19, 4, 7, cloth)
	_fill(img, 10, 26, 5, 2, skin_dk)
	_fill(img, 17, 26, 5, 2, skin_dk)
	# Blood stains
	_px(img, 14, 14, Color(0.5, 0.1, 0.05))
	_px(img, 19, 16, Color(0.5, 0.1, 0.05))
	_save32(img, DIR_CEMETERY, "cemetery_zombie")

func _gen_cemetery_banshee() -> void:
	var img = _img32()
	var body = Color(0.85, 0.88, 0.92, 0.7)
	var light = Color(0.92, 0.95, 1.0, 0.8)
	var hair = Color(0.75, 0.78, 0.85, 0.6)
	var eye = Color(0.6, 0.85, 1.0)
	# Long flowing hair
	_fill(img, 9, 2, 14, 6, hair)
	_fill(img, 7, 6, 4, 12, hair)
	_fill(img, 21, 6, 4, 12, hair)
	# Head
	_fill(img, 11, 4, 10, 8, body)
	# Wide glowing eyes
	_fill(img, 12, 7, 3, 2, eye)
	_fill(img, 17, 7, 3, 2, eye)
	_px(img, 13, 7, Color(0.3, 0.6, 1.0))
	_px(img, 18, 7, Color(0.3, 0.6, 1.0))
	# Screaming mouth (wide open oval)
	_fill(img, 13, 10, 6, 3, Color(0.2, 0.2, 0.3, 0.8))
	_fill(img, 14, 10, 4, 1, Color(0.1, 0.1, 0.2))
	# Flowing dress body
	_fill(img, 10, 13, 12, 6, body)
	_fill(img, 8, 19, 16, 4, light)
	_fill(img, 7, 23, 18, 3, body)
	# Wispy bottom (fading)
	_fill(img, 9, 26, 4, 2, Color(0.85, 0.88, 0.92, 0.4))
	_fill(img, 15, 27, 3, 2, Color(0.85, 0.88, 0.92, 0.3))
	_fill(img, 20, 26, 4, 2, Color(0.85, 0.88, 0.92, 0.4))
	# Raised arms (screaming pose)
	_fill(img, 5, 10, 3, 6, body)
	_fill(img, 4, 8, 2, 3, light)
	_fill(img, 24, 10, 3, 6, body)
	_fill(img, 26, 8, 2, 3, light)
	_save32(img, DIR_CEMETERY, "cemetery_banshee")

func _gen_cemetery_bone_knight() -> void:
	var img = _img32()
	var armor = Color(0.25, 0.22, 0.3)
	var armor_lt = Color(0.35, 0.32, 0.4)
	var bone = Color(0.88, 0.85, 0.78)
	var eye = Color(0.9, 0.2, 0.15)
	var sword = Color(0.7, 0.72, 0.78)
	# Helmet
	_fill(img, 11, 2, 10, 8, armor)
	_fill(img, 12, 3, 8, 6, armor_lt)
	# Visor slit with red eyes
	_fill(img, 13, 5, 6, 2, Color(0.1, 0.08, 0.12))
	_px(img, 14, 5, eye)
	_px(img, 17, 5, eye)
	# Helmet crest
	_fill(img, 15, 0, 2, 3, armor)
	# Neck bone
	_fill(img, 14, 10, 4, 2, bone)
	# Dark armor torso
	_fill(img, 9, 12, 14, 8, armor)
	_fill(img, 10, 13, 12, 6, armor_lt)
	# Chest emblem
	_fill(img, 14, 14, 4, 3, Color(0.5, 0.15, 0.1))
	# Shoulder pads
	_fill(img, 6, 11, 4, 4, armor)
	_fill(img, 22, 11, 4, 4, armor)
	# Arms (bone visible)
	_fill(img, 5, 15, 3, 6, bone)
	_fill(img, 24, 15, 3, 6, bone)
	# Legs in armor
	_fill(img, 10, 20, 5, 7, armor)
	_fill(img, 17, 20, 5, 7, armor)
	_fill(img, 10, 27, 5, 2, armor_lt)
	_fill(img, 17, 27, 5, 2, armor_lt)
	# Sword in right hand
	_fill(img, 26, 6, 2, 16, sword)
	_fill(img, 25, 5, 4, 2, Color(0.45, 0.3, 0.2))
	_save32(img, DIR_CEMETERY, "cemetery_bone_knight")

func _gen_cemetery_ghoul() -> void:
	var img = _img32()
	var skin = Color(0.5, 0.48, 0.45)
	var skin_dk = Color(0.38, 0.35, 0.32)
	var eye = Color(0.9, 0.7, 0.1)
	var claw = Color(0.85, 0.82, 0.75)
	# Head (slightly hunched forward)
	_fill(img, 13, 5, 8, 6, skin)
	_fill(img, 12, 6, 10, 4, skin)
	# Sunken eyes
	_fill(img, 14, 7, 2, 2, Color(0.15, 0.12, 0.1))
	_px(img, 14, 7, eye)
	_fill(img, 18, 7, 2, 2, Color(0.15, 0.12, 0.1))
	_px(img, 19, 7, eye)
	# Snarling mouth
	_fill(img, 15, 10, 4, 1, Color(0.3, 0.15, 0.1))
	_px(img, 15, 9, claw)
	_px(img, 18, 9, claw)
	# Hunched body
	_fill(img, 11, 11, 12, 7, skin_dk)
	_fill(img, 13, 12, 8, 5, skin)
	# Long arms with claws
	_fill(img, 6, 12, 4, 8, skin)
	_fill(img, 4, 20, 3, 3, skin_dk)
	# Claws left
	_px(img, 3, 22, claw)
	_px(img, 4, 23, claw)
	_px(img, 5, 23, claw)
	_fill(img, 22, 12, 4, 8, skin)
	_fill(img, 25, 20, 3, 3, skin_dk)
	# Claws right
	_px(img, 27, 22, claw)
	_px(img, 26, 23, claw)
	_px(img, 25, 23, claw)
	# Short legs (hunched)
	_fill(img, 12, 18, 4, 6, skin_dk)
	_fill(img, 18, 18, 4, 6, skin_dk)
	_fill(img, 11, 24, 5, 2, skin)
	_fill(img, 18, 24, 5, 2, skin)
	_save32(img, DIR_CEMETERY, "cemetery_ghoul")

func _gen_cemetery_gravedigger() -> void:
	var img = _img32()
	var skin = Color(0.6, 0.52, 0.42)
	var skin_dk = Color(0.45, 0.38, 0.3)
	var cloth = Color(0.3, 0.28, 0.22)
	var hat = Color(0.2, 0.18, 0.15)
	var shovel = Color(0.55, 0.55, 0.6)
	# Hat (wide brim)
	_fill(img, 8, 3, 16, 2, hat)
	_fill(img, 11, 1, 10, 4, hat)
	# Face (old, wrinkled)
	_fill(img, 12, 5, 8, 6, skin)
	# Eyes (small, tired)
	_fill(img, 13, 7, 2, 1, Color(0.3, 0.3, 0.3))
	_fill(img, 17, 7, 2, 1, Color(0.3, 0.3, 0.3))
	# Nose
	_px(img, 16, 8, skin_dk)
	# Beard (scraggly)
	_fill(img, 12, 10, 8, 2, Color(0.55, 0.5, 0.45))
	_px(img, 12, 12, Color(0.55, 0.5, 0.45))
	_px(img, 19, 12, Color(0.55, 0.5, 0.45))
	# Body (coat)
	_fill(img, 10, 12, 12, 8, cloth)
	_fill(img, 11, 13, 10, 6, Color(0.25, 0.22, 0.18))
	# Arms
	_fill(img, 7, 12, 3, 7, cloth)
	_fill(img, 22, 12, 3, 7, cloth)
	# Hands
	_fill(img, 6, 19, 3, 2, skin_dk)
	_fill(img, 23, 19, 3, 2, skin_dk)
	# Legs
	_fill(img, 11, 20, 4, 6, cloth)
	_fill(img, 17, 20, 4, 6, cloth)
	_fill(img, 10, 26, 5, 2, Color(0.3, 0.2, 0.12))
	_fill(img, 17, 26, 5, 2, Color(0.3, 0.2, 0.12))
	# Shovel (right side)
	_fill(img, 25, 4, 2, 20, Color(0.45, 0.3, 0.18))
	_fill(img, 23, 22, 6, 4, shovel)
	_fill(img, 24, 23, 4, 2, Color(0.45, 0.45, 0.5))
	_save32(img, DIR_CEMETERY, "cemetery_gravedigger")

func _gen_cemetery_hand() -> void:
	var img = _img32()
	var skin = Color(0.45, 0.5, 0.38)
	var skin_dk = Color(0.35, 0.38, 0.28)
	var bone = Color(0.85, 0.82, 0.75)
	var dirt = Color(0.35, 0.28, 0.18)
	# Ground/dirt at bottom
	_fill(img, 4, 22, 24, 8, dirt)
	_fill(img, 6, 20, 20, 3, Color(0.3, 0.24, 0.15))
	# Wrist emerging from ground
	_fill(img, 13, 16, 6, 6, skin)
	_fill(img, 14, 17, 4, 4, skin_dk)
	# Palm
	_fill(img, 11, 10, 10, 7, skin)
	_fill(img, 12, 11, 8, 5, skin_dk)
	# Fingers reaching up
	_fill(img, 10, 4, 3, 7, skin)
	_fill(img, 13, 2, 3, 9, skin)
	_fill(img, 16, 3, 3, 8, skin)
	_fill(img, 19, 5, 3, 6, skin)
	# Finger tips (nails)
	_px(img, 11, 4, bone)
	_px(img, 14, 2, bone)
	_px(img, 17, 3, bone)
	_px(img, 20, 5, bone)
	# Thumb
	_fill(img, 8, 10, 3, 4, skin)
	_px(img, 8, 10, bone)
	# Dirt particles
	_px(img, 10, 19, dirt)
	_px(img, 22, 18, dirt)
	_px(img, 8, 21, Color(0.4, 0.32, 0.2))
	_save32(img, DIR_CEMETERY, "cemetery_hand")

func _gen_cemetery_rat_swarm() -> void:
	var img = _img32()
	var rat = Color(0.45, 0.42, 0.38)
	var rat_dk = Color(0.32, 0.3, 0.27)
	var eye = Color(0.85, 0.2, 0.15)
	var tail = Color(0.6, 0.45, 0.4)
	# Rat 1 (front left)
	_fill(img, 4, 16, 6, 4, rat)
	_fill(img, 3, 17, 2, 2, rat_dk)
	_px(img, 3, 17, eye)
	_line(img, 10, 18, 14, 20, tail)
	# Rat 2 (center)
	_fill(img, 12, 14, 7, 5, rat)
	_fill(img, 11, 15, 2, 3, rat_dk)
	_px(img, 11, 15, eye)
	_line(img, 19, 16, 23, 14, tail)
	# Rat 3 (right)
	_fill(img, 20, 17, 6, 4, rat_dk)
	_fill(img, 19, 18, 2, 2, rat)
	_px(img, 19, 18, eye)
	_line(img, 26, 19, 29, 21, tail)
	# Rat 4 (back left)
	_fill(img, 6, 10, 5, 4, rat_dk)
	_fill(img, 5, 11, 2, 2, rat)
	_px(img, 5, 11, eye)
	_line(img, 11, 12, 14, 10, tail)
	# Rat 5 (back right)
	_fill(img, 18, 10, 6, 3, rat)
	_fill(img, 17, 11, 2, 2, rat_dk)
	_px(img, 17, 11, eye)
	_line(img, 24, 11, 27, 9, tail)
	# Small legs (dots)
	_px(img, 5, 20, rat_dk)
	_px(img, 8, 20, rat_dk)
	_px(img, 13, 19, rat_dk)
	_px(img, 17, 19, rat_dk)
	_px(img, 21, 21, rat_dk)
	_px(img, 24, 21, rat_dk)
	_save32(img, DIR_CEMETERY, "cemetery_rat_swarm")

func _gen_cemetery_wraith() -> void:
	var img = _img32()
	var shadow = Color(0.12, 0.1, 0.15, 0.8)
	var shadow_dk = Color(0.08, 0.06, 0.1, 0.9)
	var eye = Color(0.6, 0.2, 0.8)
	var eye_glow = Color(0.75, 0.35, 0.95)
	# Hood
	_fill(img, 10, 2, 12, 5, shadow_dk)
	_fill(img, 9, 4, 14, 6, shadow)
	_fill(img, 11, 3, 10, 3, shadow_dk)
	# Face void
	_fill(img, 12, 5, 8, 4, Color(0.05, 0.03, 0.08))
	# Purple glowing eyes
	_fill(img, 13, 6, 2, 2, eye_glow)
	_fill(img, 17, 6, 2, 2, eye_glow)
	_px(img, 13, 6, eye)
	_px(img, 18, 6, eye)
	# Flowing robe body
	_fill(img, 9, 10, 14, 8, shadow)
	_fill(img, 8, 18, 16, 4, shadow)
	_fill(img, 7, 22, 18, 3, shadow_dk)
	# Wispy tendrils at bottom
	_fill(img, 6, 25, 4, 3, Color(0.1, 0.08, 0.12, 0.5))
	_fill(img, 13, 26, 3, 2, Color(0.1, 0.08, 0.12, 0.4))
	_fill(img, 22, 25, 4, 3, Color(0.1, 0.08, 0.12, 0.5))
	# Spectral arms
	_fill(img, 5, 12, 4, 5, shadow)
	_fill(img, 23, 12, 4, 5, shadow)
	_fill(img, 3, 15, 3, 3, Color(0.1, 0.08, 0.12, 0.6))
	_fill(img, 26, 15, 3, 3, Color(0.1, 0.08, 0.12, 0.6))
	_save32(img, DIR_CEMETERY, "cemetery_wraith")

func _gen_cemetery_reaper() -> void:
	var img = _img32()
	var robe = Color(0.1, 0.08, 0.12)
	var robe_dk = Color(0.06, 0.04, 0.08)
	var bone = Color(0.88, 0.85, 0.78)
	var scythe = Color(0.7, 0.72, 0.78)
	var eye = Color(0.9, 0.2, 0.15)
	# Hood
	_fill(img, 10, 2, 12, 6, robe)
	_fill(img, 11, 1, 10, 3, robe_dk)
	# Face (skull visible)
	_fill(img, 12, 4, 8, 5, bone)
	# Eye sockets
	_fill(img, 13, 5, 2, 2, Color(0.05, 0.02, 0.02))
	_px(img, 13, 5, eye)
	_fill(img, 17, 5, 2, 2, Color(0.05, 0.02, 0.02))
	_px(img, 18, 5, eye)
	# Nose hole
	_px(img, 15, 7, Color(0.05, 0.02, 0.02))
	_px(img, 16, 7, Color(0.05, 0.02, 0.02))
	# Jaw
	_fill(img, 13, 8, 6, 1, bone)
	# Robe body
	_fill(img, 9, 10, 14, 10, robe)
	_fill(img, 8, 20, 16, 5, robe)
	_fill(img, 9, 25, 14, 4, robe_dk)
	# Bony hands
	_fill(img, 6, 14, 3, 3, bone)
	_fill(img, 23, 14, 3, 3, bone)
	# Scythe (left side, curved blade)
	_fill(img, 4, 2, 2, 22, Color(0.4, 0.3, 0.2))
	# Scythe blade
	_fill(img, 1, 2, 6, 2, scythe)
	_fill(img, 0, 4, 4, 2, scythe)
	_px(img, 0, 6, scythe)
	_px(img, 1, 6, scythe)
	_save32(img, DIR_CEMETERY, "cemetery_reaper")

# ==================== FOREST ENEMIES (32x32) ====================

func _gen_forest_bear() -> void:
	var img = _img32()
	var fur = Color(0.45, 0.3, 0.18)
	var fur_dk = Color(0.32, 0.2, 0.1)
	var fur_lt = Color(0.55, 0.38, 0.22)
	var eye = Color(0.15, 0.1, 0.08)
	var nose = Color(0.12, 0.08, 0.05)
	# Head
	_fill(img, 10, 2, 12, 8, fur)
	# Ears
	_fill(img, 9, 1, 4, 3, fur)
	_fill(img, 10, 2, 2, 1, fur_dk)
	_fill(img, 19, 1, 4, 3, fur)
	_fill(img, 20, 2, 2, 1, fur_dk)
	# Muzzle
	_fill(img, 12, 6, 8, 4, fur_lt)
	# Eyes
	_fill(img, 12, 4, 2, 2, eye)
	_fill(img, 18, 4, 2, 2, eye)
	_px(img, 12, 4, Color(0.3, 0.2, 0.1))
	_px(img, 18, 4, Color(0.3, 0.2, 0.1))
	# Nose
	_fill(img, 15, 6, 2, 2, nose)
	# Mouth
	_px(img, 15, 8, Color(0.2, 0.1, 0.05))
	_px(img, 16, 8, Color(0.2, 0.1, 0.05))
	# Big body
	_fill(img, 6, 10, 20, 10, fur)
	_fill(img, 8, 11, 16, 8, fur_dk)
	# Chest lighter patch
	_fill(img, 13, 12, 6, 5, fur_lt)
	# Arms
	_fill(img, 3, 11, 4, 8, fur)
	_fill(img, 25, 11, 4, 8, fur)
	# Paws
	_fill(img, 2, 19, 5, 3, fur_dk)
	_fill(img, 25, 19, 5, 3, fur_dk)
	# Legs (thick)
	_fill(img, 8, 20, 6, 7, fur)
	_fill(img, 18, 20, 6, 7, fur)
	# Feet
	_fill(img, 7, 27, 7, 2, fur_dk)
	_fill(img, 18, 27, 7, 2, fur_dk)
	# Claw marks
	_px(img, 3, 21, Color(0.8, 0.78, 0.7))
	_px(img, 4, 21, Color(0.8, 0.78, 0.7))
	_px(img, 27, 21, Color(0.8, 0.78, 0.7))
	_px(img, 28, 21, Color(0.8, 0.78, 0.7))
	_save32(img, DIR_FOREST, "forest_bear")

func _gen_forest_fairy() -> void:
	var img = _img32()
	var skin = Color(0.55, 0.8, 0.5)
	var wing = Color(0.4, 0.85, 0.45, 0.6)
	var wing_lt = Color(0.6, 0.95, 0.65, 0.5)
	var dress = Color(0.3, 0.7, 0.35)
	var eye = Color(0.2, 0.6, 0.9)
	var glow = Color(0.7, 1.0, 0.5, 0.3)
	# Glow aura
	_circle(img, 16, 14, 10, glow)
	# Wings (left)
	_ellipse(img, 8, 12, 5, 7, wing)
	_ellipse(img, 8, 12, 3, 5, wing_lt)
	# Wings (right)
	_ellipse(img, 24, 12, 5, 7, wing)
	_ellipse(img, 24, 12, 3, 5, wing_lt)
	# Tiny body
	_fill(img, 14, 10, 4, 3, skin)
	# Head
	_circle(img, 16, 8, 3, skin)
	# Eyes (big for fairy)
	_fill(img, 14, 7, 2, 2, eye)
	_fill(img, 17, 7, 2, 2, eye)
	_px(img, 15, 8, Color(0.05, 0.05, 0.1))
	_px(img, 18, 8, Color(0.05, 0.05, 0.1))
	_px(img, 14, 7, Color(0.9, 0.95, 1.0))
	_px(img, 17, 7, Color(0.9, 0.95, 1.0))
	# Hair
	_fill(img, 13, 5, 6, 2, Color(0.2, 0.55, 0.25))
	# Dress
	_fill(img, 13, 13, 6, 5, dress)
	_fill(img, 12, 17, 8, 2, dress)
	# Tiny legs
	_fill(img, 14, 19, 2, 3, skin)
	_fill(img, 17, 19, 2, 3, skin)
	# Sparkles
	_px(img, 6, 8, Color(1, 1, 0.7, 0.8))
	_px(img, 26, 9, Color(1, 1, 0.7, 0.8))
	_px(img, 10, 20, Color(1, 1, 0.7, 0.8))
	_px(img, 22, 18, Color(1, 1, 0.7, 0.8))
	_save32(img, DIR_FOREST, "forest_fairy")

func _gen_forest_mushroom() -> void:
	var img = _img32()
	var cap = Color(0.85, 0.2, 0.15)
	var cap_dk = Color(0.65, 0.12, 0.1)
	var spot = Color(0.95, 0.92, 0.85)
	var stem = Color(0.88, 0.85, 0.75)
	var stem_dk = Color(0.7, 0.65, 0.55)
	var eye = Color(0.15, 0.1, 0.08)
	# Cap (dome)
	_fill(img, 6, 2, 20, 4, cap)
	_fill(img, 4, 6, 24, 4, cap)
	_fill(img, 3, 8, 26, 3, cap_dk)
	_fill(img, 8, 3, 16, 2, cap)
	# White spots on cap
	_fill(img, 9, 3, 3, 2, spot)
	_fill(img, 18, 4, 3, 2, spot)
	_fill(img, 13, 6, 2, 2, spot)
	_fill(img, 6, 7, 2, 2, spot)
	_fill(img, 22, 6, 2, 2, spot)
	# Face on stem
	_fill(img, 10, 11, 12, 8, stem)
	_fill(img, 11, 12, 10, 6, stem_dk)
	# Eyes (cute beady)
	_fill(img, 12, 13, 2, 2, eye)
	_fill(img, 18, 13, 2, 2, eye)
	_px(img, 12, 13, Color(0.3, 0.2, 0.15))
	_px(img, 18, 13, Color(0.3, 0.2, 0.15))
	# Smile
	_px(img, 14, 16, eye)
	_px(img, 15, 17, eye)
	_px(img, 16, 17, eye)
	_px(img, 17, 16, eye)
	# Legs (stubby)
	_fill(img, 11, 19, 4, 6, stem)
	_fill(img, 17, 19, 4, 6, stem)
	_fill(img, 10, 25, 5, 3, stem_dk)
	_fill(img, 17, 25, 5, 3, stem_dk)
	_save32(img, DIR_FOREST, "forest_mushroom")

func _gen_forest_owl() -> void:
	var img = _img32()
	var body = Color(0.45, 0.32, 0.2)
	var body_dk = Color(0.32, 0.22, 0.12)
	var breast = Color(0.65, 0.55, 0.4)
	var eye = Color(0.95, 0.85, 0.1)
	var beak = Color(0.7, 0.5, 0.2)
	# Head (round)
	_fill(img, 8, 3, 16, 10, body)
	_fill(img, 10, 2, 12, 3, body)
	# Ear tufts
	_fill(img, 8, 1, 3, 4, body_dk)
	_fill(img, 21, 1, 3, 4, body_dk)
	# Face disc
	_fill(img, 10, 5, 12, 6, breast)
	# Big eyes
	_circle(img, 13, 7, 3, Color.WHITE)
	_circle(img, 19, 7, 3, Color.WHITE)
	_circle(img, 13, 7, 2, eye)
	_circle(img, 19, 7, 2, eye)
	_fill(img, 12, 6, 2, 2, Color(0.1, 0.1, 0.1))
	_fill(img, 18, 6, 2, 2, Color(0.1, 0.1, 0.1))
	# Eye shine
	_px(img, 12, 6, Color(1, 1, 1))
	_px(img, 18, 6, Color(1, 1, 1))
	# Beak
	_fill(img, 15, 9, 2, 2, beak)
	_px(img, 16, 11, beak)
	# Body
	_fill(img, 9, 13, 14, 10, body)
	_fill(img, 11, 14, 10, 8, breast)
	# Breast pattern (V lines)
	for i in range(4):
		_px(img, 13 + i, 15 + i, body_dk)
		_px(img, 19 - i, 15 + i, body_dk)
	# Wings
	_fill(img, 5, 13, 5, 8, body_dk)
	_fill(img, 22, 13, 5, 8, body_dk)
	# Wing tips
	_fill(img, 4, 20, 4, 2, body_dk)
	_fill(img, 24, 20, 4, 2, body_dk)
	# Talons
	_fill(img, 11, 23, 3, 4, Color(0.5, 0.4, 0.2))
	_fill(img, 18, 23, 3, 4, Color(0.5, 0.4, 0.2))
	_px(img, 10, 26, Color(0.5, 0.4, 0.2))
	_px(img, 13, 26, Color(0.5, 0.4, 0.2))
	_px(img, 18, 26, Color(0.5, 0.4, 0.2))
	_px(img, 21, 26, Color(0.5, 0.4, 0.2))
	_save32(img, DIR_FOREST, "forest_owl")

func _gen_forest_spider() -> void:
	var img = _img32()
	var body = Color(0.18, 0.32, 0.15)
	var body_dk = Color(0.12, 0.22, 0.1)
	var eye = Color(0.85, 0.15, 0.1)
	var leg = Color(0.15, 0.28, 0.12)
	# Abdomen (back, larger)
	_ellipse(img, 16, 18, 6, 5, body)
	_ellipse(img, 16, 18, 4, 3, body_dk)
	# Cephalothorax (front, smaller)
	_ellipse(img, 16, 11, 4, 3, body)
	# Eyes (multiple - 4 pairs)
	_px(img, 14, 9, eye)
	_px(img, 15, 9, eye)
	_px(img, 17, 9, eye)
	_px(img, 18, 9, eye)
	_px(img, 13, 10, eye)
	_px(img, 19, 10, eye)
	_px(img, 14, 11, Color(0.6, 0.1, 0.08))
	_px(img, 18, 11, Color(0.6, 0.1, 0.08))
	# Fangs
	_px(img, 15, 13, Color(0.85, 0.82, 0.75))
	_px(img, 17, 13, Color(0.85, 0.82, 0.75))
	# 8 legs (4 per side)
	# Left legs
	_line(img, 12, 11, 4, 6, leg)
	_line(img, 12, 12, 3, 10, leg)
	_line(img, 12, 13, 5, 16, leg)
	_line(img, 12, 14, 6, 22, leg)
	# Right legs
	_line(img, 20, 11, 28, 6, leg)
	_line(img, 20, 12, 29, 10, leg)
	_line(img, 20, 13, 27, 16, leg)
	_line(img, 20, 14, 26, 22, leg)
	# Pattern on abdomen
	_px(img, 16, 16, Color(0.3, 0.5, 0.25))
	_px(img, 14, 18, Color(0.3, 0.5, 0.25))
	_px(img, 18, 18, Color(0.3, 0.5, 0.25))
	_px(img, 16, 20, Color(0.3, 0.5, 0.25))
	_save32(img, DIR_FOREST, "forest_spider")

func _gen_forest_treant() -> void:
	var img = _img32()
	var bark = Color(0.4, 0.28, 0.15)
	var bark_dk = Color(0.28, 0.18, 0.08)
	var leaf = Color(0.25, 0.55, 0.2)
	var leaf_dk = Color(0.18, 0.4, 0.12)
	var eye = Color(0.7, 0.85, 0.3)
	# Canopy (leaves on top)
	_fill(img, 6, 0, 20, 5, leaf)
	_fill(img, 4, 3, 24, 5, leaf)
	_fill(img, 8, 1, 16, 3, leaf_dk)
	# Some leaf detail
	_px(img, 7, 2, leaf_dk)
	_px(img, 22, 4, leaf_dk)
	_px(img, 12, 1, Color(0.35, 0.65, 0.3))
	# Face in trunk
	_fill(img, 9, 8, 14, 10, bark)
	_fill(img, 10, 9, 12, 8, bark_dk)
	# Eyes (glowing, in bark)
	_fill(img, 11, 10, 3, 3, eye)
	_fill(img, 18, 10, 3, 3, eye)
	_px(img, 12, 11, Color(0.3, 0.5, 0.15))
	_px(img, 19, 11, Color(0.3, 0.5, 0.15))
	# Mouth (knothole)
	_fill(img, 14, 14, 4, 2, Color(0.15, 0.1, 0.05))
	# Trunk body
	_fill(img, 10, 18, 12, 6, bark)
	_fill(img, 11, 19, 10, 4, bark_dk)
	# Branch arms
	_fill(img, 4, 10, 5, 3, bark)
	_fill(img, 2, 9, 3, 2, bark_dk)
	_fill(img, 1, 7, 2, 3, leaf)
	_fill(img, 23, 10, 5, 3, bark)
	_fill(img, 27, 9, 3, 2, bark_dk)
	_fill(img, 29, 7, 2, 3, leaf)
	# Root legs
	_fill(img, 8, 24, 5, 5, bark)
	_fill(img, 19, 24, 5, 5, bark)
	_fill(img, 6, 27, 4, 2, bark_dk)
	_fill(img, 22, 27, 4, 2, bark_dk)
	# Moss patches
	_px(img, 10, 16, leaf)
	_px(img, 20, 20, leaf)
	_save32(img, DIR_FOREST, "forest_treant")

func _gen_forest_vine() -> void:
	var img = _img32()
	var vine = Color(0.2, 0.5, 0.15)
	var vine_dk = Color(0.12, 0.35, 0.08)
	var thorn = Color(0.55, 0.35, 0.2)
	var tip = Color(0.35, 0.6, 0.25)
	# Main vine tendril (curving upward)
	_fill(img, 14, 24, 4, 6, vine_dk)
	_fill(img, 13, 20, 5, 5, vine)
	_fill(img, 12, 16, 5, 5, vine)
	_fill(img, 11, 12, 5, 5, vine)
	_fill(img, 12, 8, 5, 5, vine)
	_fill(img, 14, 4, 5, 5, vine)
	_fill(img, 16, 2, 4, 3, tip)
	# Tip (pointing, aggressive)
	_fill(img, 18, 1, 3, 2, tip)
	_px(img, 20, 0, tip)
	# Thorns
	_px(img, 10, 14, thorn)
	_px(img, 9, 13, thorn)
	_px(img, 17, 10, thorn)
	_px(img, 18, 9, thorn)
	_px(img, 11, 19, thorn)
	_px(img, 10, 18, thorn)
	_px(img, 19, 5, thorn)
	_px(img, 20, 4, thorn)
	# Secondary smaller vine
	_fill(img, 18, 18, 3, 3, vine_dk)
	_fill(img, 20, 15, 3, 4, vine_dk)
	_fill(img, 22, 12, 3, 4, vine)
	_fill(img, 23, 10, 3, 3, tip)
	# Leaves
	_fill(img, 7, 11, 3, 2, Color(0.3, 0.6, 0.2))
	_fill(img, 21, 6, 3, 2, Color(0.3, 0.6, 0.2))
	_save32(img, DIR_FOREST, "forest_vine")

func _gen_forest_wisp() -> void:
	var img = _img32()
	var core = Color(0.3, 0.85, 0.65)
	var glow = Color(0.25, 0.7, 0.5, 0.5)
	var glow2 = Color(0.2, 0.6, 0.4, 0.3)
	var eye = Color(0.9, 0.95, 1.0)
	# Outer glow
	_circle(img, 16, 14, 10, glow2)
	_circle(img, 16, 14, 7, glow)
	# Core orb
	_circle(img, 16, 14, 4, core)
	_circle(img, 16, 13, 2, Color(0.5, 0.95, 0.8))
	# Eyes (tiny bright dots)
	_px(img, 14, 13, eye)
	_px(img, 18, 13, eye)
	# Wispy trail below
	_fill(img, 14, 19, 4, 2, glow)
	_fill(img, 13, 21, 3, 2, Color(0.2, 0.6, 0.4, 0.4))
	_fill(img, 16, 22, 3, 2, Color(0.2, 0.6, 0.4, 0.3))
	_fill(img, 12, 23, 2, 2, Color(0.2, 0.6, 0.4, 0.2))
	# Sparkle particles
	_px(img, 9, 8, Color(0.8, 1.0, 0.9, 0.7))
	_px(img, 23, 10, Color(0.8, 1.0, 0.9, 0.7))
	_px(img, 7, 16, Color(0.8, 1.0, 0.9, 0.7))
	_px(img, 25, 18, Color(0.8, 1.0, 0.9, 0.7))
	_px(img, 11, 22, Color(0.8, 1.0, 0.9, 0.6))
	_save32(img, DIR_FOREST, "forest_wisp")

func _gen_forest_wolf() -> void:
	var img = _img32()
	var fur = Color(0.5, 0.5, 0.52)
	var fur_dk = Color(0.35, 0.35, 0.38)
	var fur_lt = Color(0.65, 0.62, 0.6)
	var eye = Color(0.85, 0.65, 0.1)
	var nose = Color(0.12, 0.08, 0.05)
	# Head
	_fill(img, 3, 6, 10, 8, fur)
	_fill(img, 5, 5, 8, 2, fur)
	# Ears (pointed)
	_fill(img, 4, 2, 3, 4, fur)
	_px(img, 5, 2, fur_dk)
	_fill(img, 10, 2, 3, 4, fur)
	_px(img, 11, 2, fur_dk)
	# Muzzle
	_fill(img, 1, 10, 5, 4, fur_lt)
	# Eyes (amber)
	_fill(img, 5, 8, 2, 2, eye)
	_fill(img, 9, 8, 2, 2, eye)
	_px(img, 6, 9, Color(0.1, 0.08, 0.05))
	_px(img, 10, 9, Color(0.1, 0.08, 0.05))
	# Nose
	_fill(img, 2, 11, 2, 1, nose)
	# Mouth
	_px(img, 2, 12, Color(0.2, 0.1, 0.08))
	# Body (long, horizontal - wolf running/standing)
	_fill(img, 10, 10, 14, 8, fur)
	_fill(img, 12, 11, 10, 6, fur_dk)
	# Chest lighter
	_fill(img, 10, 12, 4, 4, fur_lt)
	# Tail (up and bushy)
	_fill(img, 24, 8, 4, 3, fur)
	_fill(img, 26, 6, 3, 3, fur_dk)
	_fill(img, 28, 5, 2, 2, fur_lt)
	# Front legs
	_fill(img, 10, 18, 3, 6, fur)
	_fill(img, 14, 18, 3, 6, fur)
	_fill(img, 10, 24, 3, 2, fur_dk)
	_fill(img, 14, 24, 3, 2, fur_dk)
	# Back legs
	_fill(img, 19, 18, 3, 6, fur)
	_fill(img, 23, 18, 3, 6, fur)
	_fill(img, 19, 24, 3, 2, fur_dk)
	_fill(img, 23, 24, 3, 2, fur_dk)
	_save32(img, DIR_FOREST, "forest_wolf")

# ==================== BOSSES (64x64) ====================

func _gen_cemetery_lich() -> void:
	var img = _img64()
	var robe = Color(0.35, 0.15, 0.5)
	var robe_dk = Color(0.22, 0.08, 0.35)
	var robe_lt = Color(0.48, 0.25, 0.62)
	var bone = Color(0.88, 0.85, 0.78)
	var bone_dk = Color(0.7, 0.65, 0.55)
	var eye = Color(0.3, 0.9, 0.2)
	var staff_wood = Color(0.35, 0.25, 0.12)
	var staff_gem = Color(0.2, 0.85, 0.3)
	var crown = Color(0.85, 0.82, 0.72)
	# Bone crown
	_fill(img, 22, 2, 20, 3, crown)
	_fill(img, 24, 0, 4, 4, crown)
	_fill(img, 30, 0, 4, 4, crown)
	_fill(img, 36, 0, 4, 4, crown)
	_px(img, 25, 0, bone_dk)
	_px(img, 31, 0, bone_dk)
	_px(img, 37, 0, bone_dk)
	# Skull head
	_fill(img, 23, 5, 18, 12, bone)
	_fill(img, 24, 6, 16, 10, bone_dk)
	_fill(img, 25, 5, 14, 2, bone)
	# Eye sockets (green glow)
	_fill(img, 26, 8, 4, 4, Color(0.05, 0.02, 0.02))
	_fill(img, 34, 8, 4, 4, Color(0.05, 0.02, 0.02))
	_fill(img, 27, 9, 2, 2, eye)
	_fill(img, 35, 9, 2, 2, eye)
	# Eye glow effect
	_px(img, 26, 8, Color(0.2, 0.7, 0.15, 0.5))
	_px(img, 30, 8, Color(0.2, 0.7, 0.15, 0.5))
	_px(img, 34, 8, Color(0.2, 0.7, 0.15, 0.5))
	_px(img, 38, 8, Color(0.2, 0.7, 0.15, 0.5))
	# Nose hole
	_fill(img, 31, 12, 2, 2, Color(0.05, 0.02, 0.02))
	# Jaw (skeletal grin)
	_fill(img, 25, 14, 14, 2, bone)
	for i in range(7):
		_px(img, 26 + i * 2, 15, Color(0.15, 0.1, 0.08))
	# Purple robes
	_fill(img, 20, 18, 24, 6, robe)
	_fill(img, 18, 24, 28, 10, robe)
	_fill(img, 16, 34, 32, 10, robe_dk)
	_fill(img, 14, 44, 36, 8, robe_dk)
	_fill(img, 12, 52, 40, 8, robe)
	# Robe highlights
	_fill(img, 28, 20, 8, 3, robe_lt)
	_fill(img, 26, 30, 4, 6, robe_lt)
	_fill(img, 34, 30, 4, 6, robe_lt)
	# Robe trim
	_fill(img, 12, 58, 40, 2, Color(0.6, 0.4, 0.15))
	# Collar
	_fill(img, 22, 17, 20, 2, robe_lt)
	# Bony hands
	_fill(img, 14, 32, 4, 5, bone)
	_fill(img, 46, 32, 4, 5, bone)
	# Fingers
	_fill(img, 13, 36, 2, 3, bone_dk)
	_fill(img, 15, 37, 2, 3, bone_dk)
	_fill(img, 17, 36, 2, 3, bone_dk)
	_fill(img, 45, 36, 2, 3, bone_dk)
	_fill(img, 47, 37, 2, 3, bone_dk)
	_fill(img, 49, 36, 2, 3, bone_dk)
	# Green staff (right side)
	_fill(img, 50, 8, 3, 46, staff_wood)
	_fill(img, 51, 10, 2, 42, Color(0.3, 0.2, 0.1))
	# Staff top - green gem
	_circle(img, 51, 6, 4, staff_gem)
	_circle(img, 51, 6, 2, Color(0.4, 1.0, 0.5))
	_px(img, 50, 5, Color(0.7, 1.0, 0.8))
	# Staff gem holder
	_fill(img, 49, 9, 2, 2, staff_wood)
	_fill(img, 53, 9, 2, 2, staff_wood)
	# Green magic particles
	_px(img, 48, 3, Color(0.3, 0.9, 0.2, 0.6))
	_px(img, 54, 4, Color(0.3, 0.9, 0.2, 0.6))
	_px(img, 47, 7, Color(0.3, 0.9, 0.2, 0.5))
	_px(img, 55, 8, Color(0.3, 0.9, 0.2, 0.5))
	# Soul orb floating near hand
	_circle(img, 16, 30, 3, Color(0.2, 0.8, 0.3, 0.5))
	_circle(img, 16, 30, 1, Color(0.5, 1.0, 0.6, 0.7))
	_save64(img, DIR_BOSSES, "cemetery_lich")

func _gen_cemetery_reaper_boss() -> void:
	var img = _img64()
	var robe = Color(0.08, 0.06, 0.1)
	var robe_dk = Color(0.04, 0.03, 0.06)
	var robe_edge = Color(0.15, 0.12, 0.2)
	var bone = Color(0.88, 0.85, 0.78)
	var bone_dk = Color(0.7, 0.65, 0.55)
	var eye = Color(0.95, 0.2, 0.1)
	var scythe_handle = Color(0.3, 0.2, 0.1)
	var scythe_blade = Color(0.72, 0.75, 0.8)
	var blade_edge = Color(0.85, 0.88, 0.92)
	# Large hood
	_fill(img, 18, 4, 28, 8, robe)
	_fill(img, 16, 8, 32, 6, robe)
	_fill(img, 20, 2, 24, 4, robe_dk)
	# Face void
	_fill(img, 22, 7, 20, 8, Color(0.02, 0.01, 0.04))
	# Skull visible
	_fill(img, 24, 8, 16, 6, bone)
	_fill(img, 25, 9, 14, 4, bone_dk)
	# Red glowing eyes
	_fill(img, 26, 10, 4, 3, eye)
	_fill(img, 34, 10, 4, 3, eye)
	_px(img, 27, 10, Color(1, 0.4, 0.3))
	_px(img, 35, 10, Color(1, 0.4, 0.3))
	# Nose
	_fill(img, 31, 12, 2, 2, Color(0.02, 0.01, 0.04))
	# Jaw
	_fill(img, 26, 14, 12, 1, bone)
	for i in range(6):
		_px(img, 27 + i * 2, 14, Color(0.05, 0.03, 0.03))
	# Massive flowing robe
	_fill(img, 14, 16, 36, 10, robe)
	_fill(img, 12, 26, 40, 10, robe)
	_fill(img, 10, 36, 44, 10, robe_dk)
	_fill(img, 8, 46, 48, 10, robe_dk)
	_fill(img, 6, 56, 52, 6, robe)
	# Robe edge highlights
	_fill(img, 6, 60, 52, 2, robe_edge)
	_fill(img, 12, 26, 2, 34, robe_edge)
	_fill(img, 50, 26, 2, 34, robe_edge)
	# Ghostly wisps at bottom
	_fill(img, 4, 58, 5, 4, Color(0.06, 0.04, 0.08, 0.5))
	_fill(img, 55, 58, 5, 4, Color(0.06, 0.04, 0.08, 0.5))
	_fill(img, 26, 60, 4, 3, Color(0.06, 0.04, 0.08, 0.4))
	# Bony hands
	_fill(img, 10, 28, 5, 5, bone)
	_fill(img, 49, 28, 5, 5, bone)
	# Fingers
	_fill(img, 9, 32, 2, 3, bone_dk)
	_fill(img, 11, 33, 2, 3, bone_dk)
	_fill(img, 13, 32, 2, 3, bone_dk)
	# Massive scythe
	_fill(img, 6, 4, 3, 50, scythe_handle)
	_fill(img, 7, 6, 2, 46, Color(0.25, 0.15, 0.08))
	# Scythe blade (large curved)
	_fill(img, 0, 2, 10, 3, scythe_blade)
	_fill(img, 0, 5, 6, 3, scythe_blade)
	_fill(img, 0, 8, 4, 2, blade_edge)
	_fill(img, 0, 10, 2, 2, blade_edge)
	# Blade edge glow
	_fill(img, 0, 2, 1, 10, Color(0.9, 0.92, 0.98))
	# Dark aura
	_px(img, 58, 20, Color(0.1, 0.05, 0.15, 0.4))
	_px(img, 60, 30, Color(0.1, 0.05, 0.15, 0.3))
	_px(img, 3, 40, Color(0.1, 0.05, 0.15, 0.3))
	_save64(img, DIR_BOSSES, "cemetery_reaper")

func _gen_forest_elder() -> void:
	var img = _img64()
	var bark = Color(0.38, 0.26, 0.14)
	var bark_dk = Color(0.25, 0.16, 0.08)
	var bark_lt = Color(0.5, 0.36, 0.2)
	var leaf = Color(0.22, 0.55, 0.18)
	var leaf_dk = Color(0.15, 0.4, 0.1)
	var leaf_lt = Color(0.35, 0.7, 0.3)
	var moss = Color(0.3, 0.5, 0.25)
	var eye = Color(0.6, 0.85, 0.3)
	var beard_moss = Color(0.4, 0.55, 0.35)
	# Massive canopy
	_fill(img, 6, 0, 52, 6, leaf)
	_fill(img, 4, 4, 56, 6, leaf)
	_fill(img, 2, 8, 60, 4, leaf_dk)
	_fill(img, 8, 1, 48, 4, leaf_lt)
	# Canopy detail
	_circle(img, 15, 3, 4, leaf_lt)
	_circle(img, 32, 2, 5, leaf)
	_circle(img, 50, 4, 4, leaf_lt)
	_fill(img, 10, 6, 6, 3, leaf_dk)
	_fill(img, 42, 5, 8, 3, leaf_dk)
	# Face area (ancient tree)
	_fill(img, 18, 12, 28, 16, bark)
	_fill(img, 20, 14, 24, 12, bark_dk)
	# Large glowing eyes
	_fill(img, 22, 16, 6, 5, eye)
	_fill(img, 36, 16, 6, 5, eye)
	_circle(img, 25, 18, 2, Color(0.3, 0.6, 0.15))
	_circle(img, 39, 18, 2, Color(0.3, 0.6, 0.15))
	# Pupil
	_fill(img, 24, 17, 2, 2, Color(0.15, 0.3, 0.08))
	_fill(img, 38, 17, 2, 2, Color(0.15, 0.3, 0.08))
	# Knothole mouth
	_fill(img, 28, 23, 8, 4, Color(0.12, 0.08, 0.04))
	_fill(img, 29, 24, 6, 2, Color(0.08, 0.05, 0.02))
	# Mossy beard
	_fill(img, 22, 28, 20, 6, beard_moss)
	_fill(img, 24, 34, 16, 4, beard_moss)
	_fill(img, 26, 38, 12, 3, moss)
	# Beard strands
	_fill(img, 22, 33, 3, 6, Color(0.35, 0.5, 0.3))
	_fill(img, 39, 33, 3, 6, Color(0.35, 0.5, 0.3))
	_fill(img, 30, 40, 2, 4, Color(0.3, 0.45, 0.25))
	_fill(img, 34, 39, 2, 5, Color(0.3, 0.45, 0.25))
	# Massive trunk body
	_fill(img, 16, 28, 32, 16, bark)
	_fill(img, 18, 30, 28, 12, bark_dk)
	# Bark texture
	_fill(img, 20, 32, 2, 6, bark_lt)
	_fill(img, 30, 34, 2, 4, bark_lt)
	_fill(img, 40, 31, 2, 8, bark_lt)
	# Branch arms
	_fill(img, 6, 16, 12, 4, bark)
	_fill(img, 2, 14, 6, 3, bark)
	_fill(img, 0, 12, 4, 3, bark_dk)
	# Left arm leaves
	_fill(img, 0, 10, 6, 3, leaf)
	_fill(img, 2, 8, 4, 3, leaf_lt)
	_fill(img, 46, 16, 12, 4, bark)
	_fill(img, 56, 14, 6, 3, bark)
	_fill(img, 60, 12, 4, 3, bark_dk)
	# Right arm leaves
	_fill(img, 58, 10, 6, 3, leaf)
	_fill(img, 58, 8, 4, 3, leaf_lt)
	# Root legs
	_fill(img, 12, 44, 10, 12, bark)
	_fill(img, 42, 44, 10, 12, bark)
	_fill(img, 8, 52, 8, 8, bark_dk)
	_fill(img, 48, 52, 8, 8, bark_dk)
	# Root tendrils
	_fill(img, 4, 58, 6, 4, bark_dk)
	_fill(img, 54, 58, 6, 4, bark_dk)
	_fill(img, 22, 56, 6, 6, bark)
	_fill(img, 36, 56, 6, 6, bark)
	# Moss patches
	_fill(img, 16, 36, 4, 3, moss)
	_fill(img, 42, 38, 4, 3, moss)
	_fill(img, 26, 48, 3, 2, moss)
	# Glowing sap
	_px(img, 20, 20, Color(0.7, 0.9, 0.3, 0.6))
	_px(img, 44, 22, Color(0.7, 0.9, 0.3, 0.6))
	_px(img, 32, 42, Color(0.7, 0.9, 0.3, 0.5))
	_save64(img, DIR_BOSSES, "forest_elder")

func _gen_forest_spider_boss() -> void:
	var img = _img64()
	var body = Color(0.15, 0.3, 0.12)
	var body_dk = Color(0.1, 0.2, 0.08)
	var body_lt = Color(0.25, 0.42, 0.2)
	var eye = Color(0.9, 0.15, 0.1)
	var eye_glow = Color(1.0, 0.3, 0.2)
	var leg = Color(0.12, 0.25, 0.1)
	var leg_dk = Color(0.08, 0.18, 0.06)
	var fang = Color(0.88, 0.85, 0.78)
	var venom = Color(0.4, 0.85, 0.2)
	# Large abdomen
	_ellipse(img, 32, 38, 14, 12, body)
	_ellipse(img, 32, 38, 10, 8, body_dk)
	# Abdomen pattern (hourglass)
	_fill(img, 30, 32, 4, 2, Color(0.7, 0.15, 0.1))
	_fill(img, 29, 34, 6, 2, Color(0.7, 0.15, 0.1))
	_fill(img, 30, 36, 4, 2, Color(0.7, 0.15, 0.1))
	# Pattern spots
	_px(img, 25, 35, body_lt)
	_px(img, 39, 35, body_lt)
	_px(img, 28, 42, body_lt)
	_px(img, 36, 42, body_lt)
	# Cephalothorax
	_ellipse(img, 32, 22, 10, 7, body)
	_ellipse(img, 32, 22, 7, 5, body_lt)
	# Large queen eyes (8 total)
	# Main pair
	_fill(img, 27, 18, 4, 3, eye_glow)
	_fill(img, 33, 18, 4, 3, eye_glow)
	_fill(img, 28, 19, 2, 1, Color(0.1, 0.05, 0.05))
	_fill(img, 34, 19, 2, 1, Color(0.1, 0.05, 0.05))
	# Secondary pair
	_fill(img, 25, 16, 2, 2, eye)
	_fill(img, 37, 16, 2, 2, eye)
	# Small pair top
	_px(img, 29, 16, eye)
	_px(img, 35, 16, eye)
	# Small pair bottom
	_px(img, 27, 22, eye)
	_px(img, 37, 22, eye)
	# Massive fangs
	_fill(img, 28, 25, 3, 6, fang)
	_fill(img, 33, 25, 3, 6, fang)
	_fill(img, 29, 30, 2, 2, fang)
	_fill(img, 34, 30, 2, 2, fang)
	# Venom drips
	_px(img, 29, 32, venom)
	_px(img, 30, 33, venom)
	_px(img, 34, 32, venom)
	_px(img, 35, 33, venom)
	# 8 legs (4 per side) - large and imposing
	# Left legs
	_line(img, 22, 20, 8, 8, leg)
	_line(img, 8, 8, 4, 12, leg_dk)
	_line(img, 22, 22, 6, 14, leg)
	_line(img, 6, 14, 2, 20, leg_dk)
	_line(img, 22, 26, 8, 28, leg)
	_line(img, 8, 28, 4, 38, leg_dk)
	_line(img, 22, 30, 10, 40, leg)
	_line(img, 10, 40, 6, 52, leg_dk)
	# Right legs
	_line(img, 42, 20, 56, 8, leg)
	_line(img, 56, 8, 60, 12, leg_dk)
	_line(img, 42, 22, 58, 14, leg)
	_line(img, 58, 14, 62, 20, leg_dk)
	_line(img, 42, 26, 56, 28, leg)
	_line(img, 56, 28, 60, 38, leg_dk)
	_line(img, 42, 30, 54, 40, leg)
	_line(img, 54, 40, 58, 52, leg_dk)
	# Leg joint highlights
	_px(img, 8, 8, body_lt)
	_px(img, 6, 14, body_lt)
	_px(img, 56, 8, body_lt)
	_px(img, 58, 14, body_lt)
	# Silk thread from spinnerets
	_line(img, 32, 50, 32, 62, Color(0.8, 0.8, 0.78, 0.4))
	_line(img, 30, 50, 28, 60, Color(0.8, 0.8, 0.78, 0.3))
	_line(img, 34, 50, 36, 60, Color(0.8, 0.8, 0.78, 0.3))
	# Crown marking (queen)
	_fill(img, 29, 14, 2, 2, Color(0.9, 0.75, 0.1))
	_fill(img, 33, 14, 2, 2, Color(0.9, 0.75, 0.1))
	_px(img, 31, 14, Color(0.9, 0.75, 0.1))
	_save64(img, DIR_BOSSES, "forest_spider")
