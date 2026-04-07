extends SceneTree

## Generates pixel art sprites for stages (32x32), UI icons (16x16), and effects (16x16).
## Run: godot --headless --script res://scripts/tools/ui_sprite_generator.gd

func _init() -> void:
	_generate_all()
	quit()

func _generate_all() -> void:
	DirAccess.make_dir_recursive_absolute("res://assets/sprites/stages")
	DirAccess.make_dir_recursive_absolute("res://assets/sprites/ui")
	DirAccess.make_dir_recursive_absolute("res://assets/sprites/effects")

	# Stages (32x32) - 10
	_gen_cemetery()
	_gen_forest()
	_gen_farm()
	_gen_tokyo()
	_gen_volcano()
	_gen_ocean()
	_gen_arena()
	_gen_space()
	_gen_castle()
	_gen_candy()

	# UI Icons (16x16) - 12
	_gen_lock()
	_gen_currency()
	_gen_hp()
	_gen_xp()
	_gen_timer()
	_gen_kill_count()
	_gen_element_fire()
	_gen_element_ice()
	_gen_element_electric()
	_gen_element_dark()
	_gen_element_poison()
	_gen_element_physical()

	# Effects (16x16) - 6
	_gen_hit_spark()
	_gen_death_poof()
	_gen_level_up_flash()
	_gen_dash_trail()
	_gen_collect_sparkle()
	_gen_damage_number_bg()

	print("All stage, UI, and effect sprites generated!")

# ==================== HELPERS ====================

func _img16() -> Image:
	return Image.create(16, 16, false, Image.FORMAT_RGBA8)

func _img32() -> Image:
	return Image.create(32, 32, false, Image.FORMAT_RGBA8)

func _fill(img: Image, x: int, y: int, w: int, h: int, color: Color) -> void:
	var s = img.get_width()
	for px in range(maxi(x, 0), mini(x + w, s)):
		for py in range(maxi(y, 0), mini(y + h, s)):
			img.set_pixel(px, py, color)

func _px(img: Image, x: int, y: int, color: Color) -> void:
	var s = img.get_width()
	if x >= 0 and x < s and y >= 0 and y < s:
		img.set_pixel(x, y, color)

func _outline(img: Image, color: Color) -> void:
	var s = img.get_width()
	var out = Image.create(s, s, false, Image.FORMAT_RGBA8)
	for x in range(s):
		for y in range(s):
			if img.get_pixel(x, y).a > 0:
				continue
			for off in [Vector2i(-1,0), Vector2i(1,0), Vector2i(0,-1), Vector2i(0,1)]:
				var nx = x + off.x
				var ny = y + off.y
				if nx >= 0 and nx < s and ny >= 0 and ny < s:
					if img.get_pixel(nx, ny).a > 0:
						out.set_pixel(x, y, color)
						break
	for x in range(s):
		for y in range(s):
			if out.get_pixel(x, y).a > 0:
				img.set_pixel(x, y, out.get_pixel(x, y))

func _save(img: Image, path: String) -> void:
	img.save_png(path)
	print("Saved: ", path)

# ==================== STAGES (32x32) ====================

func _gen_cemetery() -> void:
	var img = _img32()
	var ground = Color(0.25, 0.28, 0.2)
	var stone = Color(0.55, 0.55, 0.58)
	var stone_hi = Color(0.7, 0.7, 0.73)
	var cross_c = Color(0.45, 0.45, 0.48)
	var moon_c = Color(0.95, 0.93, 0.7)
	var sky = Color(0.1, 0.08, 0.18)

	# Sky background
	_fill(img, 0, 0, 32, 24, sky)
	# Ground
	_fill(img, 0, 24, 32, 8, ground)
	# Moon top-right
	for dx in range(-3, 4):
		for dy in range(-3, 4):
			if dx * dx + dy * dy <= 9:
				_px(img, 27 + dx, 4 + dy, moon_c)
	# Tombstone (center)
	_fill(img, 12, 15, 8, 9, stone)
	_fill(img, 13, 14, 6, 1, stone)
	_fill(img, 14, 13, 4, 1, stone_hi)
	# Cross on tombstone
	_fill(img, 15, 16, 2, 5, cross_c)
	_fill(img, 14, 17, 4, 1, cross_c)
	# Smaller tombstone left
	_fill(img, 3, 19, 5, 5, stone)
	_fill(img, 4, 18, 3, 1, stone_hi)
	# Grass tufts
	_px(img, 1, 23, Color(0.2, 0.35, 0.15))
	_px(img, 10, 23, Color(0.2, 0.35, 0.15))
	_px(img, 22, 23, Color(0.2, 0.35, 0.15))

	_outline(img, Color(0.05, 0.05, 0.08))
	_save(img, "res://assets/sprites/stages/cemetery.png")

func _gen_forest() -> void:
	var img = _img32()
	var sky = Color(0.3, 0.55, 0.75)
	var tree_trunk = Color(0.4, 0.28, 0.15)
	var leaves = Color(0.2, 0.55, 0.2)
	var leaves_hi = Color(0.3, 0.7, 0.3)
	var ground = Color(0.3, 0.4, 0.18)
	var mushroom_cap = Color(0.85, 0.2, 0.15)
	var mushroom_stem = Color(0.9, 0.85, 0.75)
	var mushroom_dot = Color(1.0, 1.0, 0.9)

	# Sky
	_fill(img, 0, 0, 32, 24, sky)
	# Ground
	_fill(img, 0, 24, 32, 8, ground)

	# Left tree
	_fill(img, 5, 14, 3, 10, tree_trunk)
	_fill(img, 1, 6, 11, 4, leaves)
	_fill(img, 2, 4, 9, 2, leaves)
	_fill(img, 3, 10, 7, 4, leaves)
	_fill(img, 3, 5, 7, 1, leaves_hi)

	# Right tree
	_fill(img, 23, 12, 3, 12, tree_trunk)
	_fill(img, 19, 5, 11, 4, leaves)
	_fill(img, 20, 3, 9, 2, leaves)
	_fill(img, 21, 9, 7, 3, leaves)
	_fill(img, 22, 4, 5, 1, leaves_hi)

	# Mushroom (center-bottom)
	_fill(img, 14, 26, 2, 3, mushroom_stem)
	_fill(img, 12, 24, 6, 2, mushroom_cap)
	_fill(img, 13, 23, 4, 1, mushroom_cap)
	_px(img, 13, 24, mushroom_dot)
	_px(img, 16, 24, mushroom_dot)

	_outline(img, Color(0.08, 0.12, 0.05))
	_save(img, "res://assets/sprites/stages/forest.png")

func _gen_farm() -> void:
	var img = _img32()
	var sky = Color(0.5, 0.7, 0.9)
	var ground = Color(0.55, 0.45, 0.25)
	var barn_red = Color(0.75, 0.15, 0.1)
	var barn_dark = Color(0.55, 0.1, 0.08)
	var roof = Color(0.6, 0.1, 0.08)
	var door_c = Color(0.35, 0.2, 0.1)
	var wheat = Color(0.85, 0.75, 0.3)
	var wheat_hi = Color(0.95, 0.85, 0.4)

	# Sky
	_fill(img, 0, 0, 32, 22, sky)
	# Ground
	_fill(img, 0, 22, 32, 10, ground)

	# Barn
	_fill(img, 4, 12, 14, 12, barn_red)
	_fill(img, 4, 12, 14, 2, barn_dark)
	# Roof (triangle)
	for i in range(8):
		_fill(img, 4 + i, 11 - i, 14 - i * 2, 1, roof)
		if 14 - i * 2 <= 0:
			break
	_fill(img, 6, 8, 10, 1, roof)
	_fill(img, 8, 6, 6, 2, roof)
	_fill(img, 9, 5, 4, 1, roof)
	_fill(img, 10, 4, 2, 1, roof)
	# Door
	_fill(img, 9, 18, 4, 6, door_c)

	# Wheat stalks (right side)
	for i in range(5):
		var bx = 22 + i * 2
		_fill(img, bx, 16 - i % 2, 1, 8 + i % 2, wheat)
		_fill(img, bx - 1, 15 - i % 2, 3, 2, wheat_hi)

	_outline(img, Color(0.1, 0.08, 0.05))
	_save(img, "res://assets/sprites/stages/farm.png")

func _gen_tokyo() -> void:
	var img = _img32()
	var sky = Color(0.08, 0.05, 0.15)
	var bld1 = Color(0.2, 0.15, 0.35)
	var bld2 = Color(0.15, 0.12, 0.3)
	var neon_p = Color(0.8, 0.2, 0.9)
	var neon_c = Color(0.2, 0.9, 0.95)
	var window = Color(0.9, 0.85, 0.4)

	# Sky
	_fill(img, 0, 0, 32, 32, sky)
	# Building 1 (left tall)
	_fill(img, 2, 6, 8, 26, bld1)
	# Building 2 (center short)
	_fill(img, 11, 14, 9, 18, bld2)
	# Building 3 (right tall)
	_fill(img, 22, 4, 8, 28, bld1)

	# Neon purple stripes
	_fill(img, 2, 10, 8, 1, neon_p)
	_fill(img, 2, 18, 8, 1, neon_p)
	_fill(img, 22, 8, 8, 1, neon_p)
	_fill(img, 22, 16, 8, 1, neon_p)

	# Neon cyan signs
	_fill(img, 12, 16, 7, 2, neon_c)
	_fill(img, 3, 12, 6, 1, neon_c)

	# Windows (yellow dots)
	for bx in [4, 6, 8]:
		for by in [8, 13, 15, 20, 22]:
			_px(img, bx, by, window)
	for bx in [13, 15, 17]:
		for by in [19, 21, 23, 25]:
			_px(img, bx, by, window)
	for bx in [24, 26, 28]:
		for by in [6, 10, 12, 18, 20, 24]:
			_px(img, bx, by, window)

	_outline(img, Color(0.03, 0.02, 0.06))
	_save(img, "res://assets/sprites/stages/tokyo.png")

func _gen_volcano() -> void:
	var img = _img32()
	var sky = Color(0.15, 0.05, 0.02)
	var mountain = Color(0.35, 0.2, 0.15)
	var mountain_hi = Color(0.45, 0.25, 0.18)
	var lava = Color(0.95, 0.4, 0.05)
	var lava_hi = Color(1.0, 0.7, 0.1)
	var smoke = Color(0.3, 0.25, 0.25, 0.6)

	# Sky (dark red-brown)
	_fill(img, 0, 0, 32, 32, sky)

	# Volcano shape (triangle)
	for row in range(20):
		var half_w = row + 2
		var cx = 16
		_fill(img, cx - half_w, 12 + row, half_w * 2, 1, mountain)
	# Highlight on left slope
	for row in range(15):
		_px(img, 16 - row - 2, 13 + row, mountain_hi)

	# Crater top
	_fill(img, 13, 12, 6, 2, Color(0.2, 0.1, 0.08))
	# Lava in crater
	_fill(img, 14, 12, 4, 1, lava)
	_fill(img, 14, 11, 4, 1, lava_hi)

	# Lava streams down the sides
	_fill(img, 15, 13, 2, 6, lava)
	_px(img, 14, 19, lava)
	_px(img, 17, 17, lava)
	_px(img, 18, 20, lava)
	# Lava glow
	_px(img, 15, 14, lava_hi)
	_px(img, 16, 16, lava_hi)

	# Smoke puffs above crater
	_fill(img, 14, 7, 4, 3, smoke)
	_fill(img, 13, 5, 5, 2, smoke)
	_fill(img, 15, 3, 3, 2, smoke)

	_outline(img, Color(0.05, 0.02, 0.01))
	_save(img, "res://assets/sprites/stages/volcano.png")

func _gen_ocean() -> void:
	var img = _img32()
	var deep = Color(0.05, 0.15, 0.45)
	var water = Color(0.1, 0.35, 0.7)
	var wave = Color(0.3, 0.55, 0.85)
	var wave_hi = Color(0.6, 0.8, 0.95)
	var coral_r = Color(0.9, 0.3, 0.35)
	var coral_o = Color(0.95, 0.6, 0.2)
	var sand = Color(0.85, 0.78, 0.55)

	# Deep water background
	_fill(img, 0, 0, 32, 32, deep)
	# Mid water
	_fill(img, 0, 0, 32, 20, water)

	# Wave lines
	for x in range(32):
		var wy = 4 + int(sin(x * 0.8) * 1.5)
		_px(img, x, wy, wave_hi)
		_px(img, x, wy + 1, wave)
	for x in range(32):
		var wy = 12 + int(sin(x * 0.6 + 2.0) * 1.5)
		_px(img, x, wy, wave_hi)
		_px(img, x, wy + 1, wave)

	# Sandy bottom
	_fill(img, 0, 26, 32, 6, sand)
	_fill(img, 3, 25, 8, 1, sand)
	_fill(img, 20, 25, 10, 1, sand)

	# Coral left
	_fill(img, 6, 22, 2, 4, coral_r)
	_fill(img, 5, 21, 4, 1, coral_r)
	_fill(img, 4, 20, 2, 1, coral_r)
	_fill(img, 8, 20, 2, 2, coral_r)

	# Coral right
	_fill(img, 24, 22, 3, 4, coral_o)
	_fill(img, 23, 21, 5, 1, coral_o)
	_fill(img, 25, 19, 2, 2, coral_o)

	_outline(img, Color(0.02, 0.05, 0.15))
	_save(img, "res://assets/sprites/stages/ocean.png")

func _gen_arena() -> void:
	var img = _img32()
	var sky = Color(0.4, 0.6, 0.85)
	var stone = Color(0.75, 0.65, 0.45)
	var stone_dk = Color(0.55, 0.48, 0.32)
	var gold = Color(0.85, 0.7, 0.2)
	var gold_hi = Color(1.0, 0.85, 0.3)
	var ground = Color(0.7, 0.6, 0.4)

	# Sky
	_fill(img, 0, 0, 32, 16, sky)
	# Ground/sand
	_fill(img, 0, 22, 32, 10, ground)

	# Colosseum arch (center)
	# Pillars
	_fill(img, 6, 8, 4, 16, stone)
	_fill(img, 22, 8, 4, 16, stone)
	# Arch top
	_fill(img, 6, 6, 20, 3, stone)
	_fill(img, 8, 4, 16, 2, stone_dk)
	# Arch curve
	for i in range(8):
		var ax = 10 + i
		var ay = 9 + int(abs(i - 3.5) * 0.8)
		_fill(img, ax, ay, 2, 1, sky)

	# Gold trim on arch
	_fill(img, 6, 6, 20, 1, gold)
	_fill(img, 8, 4, 16, 1, gold_hi)

	# Pillar details
	_fill(img, 7, 8, 2, 1, gold)
	_fill(img, 23, 8, 2, 1, gold)
	_fill(img, 6, 22, 4, 2, stone_dk)
	_fill(img, 22, 22, 4, 2, stone_dk)

	_outline(img, Color(0.15, 0.12, 0.08))
	_save(img, "res://assets/sprites/stages/arena.png")

func _gen_space() -> void:
	var img = _img32()
	var bg = Color(0.05, 0.02, 0.12)
	var star = Color(1.0, 1.0, 1.0)
	var star_dim = Color(0.6, 0.6, 0.8)
	var ship_body = Color(0.5, 0.55, 0.65)
	var ship_hi = Color(0.7, 0.75, 0.85)
	var ship_window = Color(0.2, 0.8, 0.9)
	var exhaust = Color(0.9, 0.4, 0.1)
	var nebula = Color(0.2, 0.05, 0.25, 0.4)

	# Background
	_fill(img, 0, 0, 32, 32, bg)

	# Nebula haze
	_fill(img, 0, 10, 14, 8, nebula)
	_fill(img, 18, 18, 14, 10, nebula)

	# Stars scattered
	var star_positions = [
		Vector2i(3, 2), Vector2i(8, 5), Vector2i(15, 1), Vector2i(25, 3),
		Vector2i(29, 8), Vector2i(1, 14), Vector2i(12, 11), Vector2i(20, 7),
		Vector2i(28, 15), Vector2i(5, 22), Vector2i(18, 25), Vector2i(27, 28),
		Vector2i(10, 28), Vector2i(2, 8), Vector2i(22, 20), Vector2i(30, 22),
	]
	for p in star_positions:
		if (p.x + p.y) % 3 == 0:
			_px(img, p.x, p.y, star)
		else:
			_px(img, p.x, p.y, star_dim)

	# Spaceship (center-ish, facing right)
	_fill(img, 10, 15, 12, 4, ship_body)
	_fill(img, 11, 14, 10, 1, ship_body)
	_fill(img, 12, 19, 8, 1, ship_body)
	# Nose
	_fill(img, 22, 16, 3, 2, ship_hi)
	_fill(img, 25, 16, 2, 1, ship_hi)
	# Window
	_px(img, 19, 16, ship_window)
	_px(img, 20, 16, ship_window)
	# Exhaust
	_fill(img, 8, 16, 2, 2, exhaust)
	_px(img, 7, 16, Color(1.0, 0.7, 0.2))

	_outline(img, Color(0.02, 0.01, 0.05))
	_save(img, "res://assets/sprites/stages/space.png")

func _gen_castle() -> void:
	var img = _img32()
	var sky = Color(0.06, 0.04, 0.1)
	var wall = Color(0.3, 0.3, 0.32)
	var wall_dk = Color(0.2, 0.2, 0.22)
	var wall_hi = Color(0.4, 0.4, 0.42)
	var window_r = Color(0.7, 0.1, 0.1)
	var window_glow = Color(0.9, 0.2, 0.15, 0.5)
	var roof = Color(0.22, 0.18, 0.25)

	# Sky
	_fill(img, 0, 0, 32, 32, sky)

	# Main tower (center)
	_fill(img, 10, 8, 12, 24, wall)
	# Left tower
	_fill(img, 2, 12, 8, 20, wall_dk)
	# Right tower
	_fill(img, 22, 10, 8, 22, wall_dk)

	# Battlements (center)
	_fill(img, 10, 6, 3, 2, wall_hi)
	_fill(img, 15, 6, 3, 2, wall_hi)
	_fill(img, 19, 6, 3, 2, wall_hi)

	# Pointed roof center
	_fill(img, 13, 3, 6, 3, roof)
	_fill(img, 14, 1, 4, 2, roof)
	_fill(img, 15, 0, 2, 1, roof)

	# Left tower top
	_fill(img, 2, 10, 3, 2, wall_hi)
	_fill(img, 7, 10, 3, 2, wall_hi)

	# Right tower top
	_fill(img, 22, 8, 3, 2, wall_hi)
	_fill(img, 27, 8, 3, 2, wall_hi)

	# Red windows
	_fill(img, 14, 12, 2, 3, window_r)
	_fill(img, 17, 12, 2, 3, window_r)
	_fill(img, 5, 16, 2, 3, window_r)
	_fill(img, 25, 14, 2, 3, window_r)
	# Glow around windows
	_px(img, 13, 13, window_glow)
	_px(img, 16, 13, window_glow)
	_px(img, 19, 13, window_glow)

	# Gate at bottom
	_fill(img, 14, 24, 4, 8, wall_dk)
	_fill(img, 15, 23, 2, 1, wall_dk)

	_outline(img, Color(0.02, 0.02, 0.04))
	_save(img, "res://assets/sprites/stages/castle.png")

func _gen_candy() -> void:
	var img = _img32()
	var bg = Color(1.0, 0.75, 0.85)
	var cane_w = Color(1.0, 1.0, 1.0)
	var cane_r = Color(0.95, 0.2, 0.3)
	var lolli_stick = Color(0.85, 0.8, 0.65)
	var lolli_1 = Color(0.9, 0.3, 0.7)
	var lolli_2 = Color(0.3, 0.8, 0.9)
	var lolli_3 = Color(1.0, 0.85, 0.2)
	var ground = Color(0.7, 0.9, 0.5)

	# Background
	_fill(img, 0, 0, 32, 26, bg)
	# Ground (green candy grass)
	_fill(img, 0, 26, 32, 6, ground)

	# Candy cane (left side)
	# Vertical part
	for y in range(10, 26):
		if (y / 2) % 2 == 0:
			_fill(img, 7, y, 3, 1, cane_w)
		else:
			_fill(img, 7, y, 3, 1, cane_r)
	# Curved top
	_fill(img, 9, 8, 4, 2, cane_w)
	_fill(img, 11, 10, 2, 2, cane_r)
	_fill(img, 12, 8, 1, 2, cane_r)
	_fill(img, 7, 8, 2, 2, cane_r)
	_fill(img, 10, 7, 2, 1, cane_w)

	# Lollipop (right side)
	_fill(img, 23, 16, 2, 10, lolli_stick)
	# Circle head
	for dx in range(-4, 5):
		for dy in range(-4, 5):
			if dx * dx + dy * dy <= 16:
				var c: Color
				if (dx + dy + 20) % 4 < 2:
					c = lolli_1
				else:
					c = lolli_2
				_px(img, 24 + dx, 11 + dy, c)
	# Center dot
	_px(img, 24, 11, lolli_3)
	_px(img, 23, 11, lolli_3)

	# Small candy pieces on ground
	_fill(img, 2, 27, 3, 2, Color(0.2, 0.7, 0.95))
	_fill(img, 16, 28, 2, 2, Color(1.0, 0.5, 0.2))

	_outline(img, Color(0.3, 0.2, 0.25))
	_save(img, "res://assets/sprites/stages/candy.png")

# ==================== UI ICONS (16x16) ====================

func _gen_lock() -> void:
	var img = _img16()
	var body = Color(0.5, 0.5, 0.55)
	var body_dk = Color(0.35, 0.35, 0.4)
	var shackle = Color(0.6, 0.6, 0.65)
	var keyhole = Color(0.2, 0.2, 0.22)

	# Shackle (U-shape at top)
	_fill(img, 5, 2, 2, 5, shackle)
	_fill(img, 9, 2, 2, 5, shackle)
	_fill(img, 5, 1, 6, 2, shackle)
	# Clear inside of shackle
	_fill(img, 7, 3, 2, 3, Color(0, 0, 0, 0))
	# Body
	_fill(img, 3, 6, 10, 8, body)
	_fill(img, 4, 7, 8, 6, body_dk)
	# Keyhole
	_fill(img, 7, 9, 2, 2, keyhole)
	_fill(img, 7, 11, 2, 1, keyhole)

	_outline(img, Color(0.15, 0.15, 0.18))
	_save(img, "res://assets/sprites/ui/lock.png")

func _gen_currency() -> void:
	var img = _img16()
	var gold = Color(0.95, 0.78, 0.15)
	var gold_hi = Color(1.0, 0.9, 0.4)
	var gold_dk = Color(0.7, 0.55, 0.1)
	var symbol = Color(0.6, 0.45, 0.05)

	# Circle coin
	for dx in range(-6, 7):
		for dy in range(-6, 7):
			if dx * dx + dy * dy <= 36:
				var c = gold
				if dx < -2:
					c = gold_dk
				elif dx > 2:
					c = gold_hi
				_px(img, 8 + dx, 8 + dy, c)
	# $ symbol
	_fill(img, 7, 4, 2, 1, symbol)
	_fill(img, 6, 5, 4, 1, symbol)
	_fill(img, 6, 6, 2, 1, symbol)
	_fill(img, 6, 7, 4, 1, symbol)
	_fill(img, 8, 8, 2, 1, symbol)
	_fill(img, 6, 9, 4, 1, symbol)
	_fill(img, 7, 10, 2, 1, symbol)
	# Vertical bar of $
	_fill(img, 7, 3, 2, 9, symbol)

	_outline(img, Color(0.3, 0.22, 0.02))
	_save(img, "res://assets/sprites/ui/currency.png")

func _gen_hp() -> void:
	var img = _img16()
	var red = Color(0.9, 0.15, 0.15)
	var red_hi = Color(1.0, 0.35, 0.35)
	var red_dk = Color(0.65, 0.08, 0.08)

	# Heart shape using pixel positions
	# Top bumps
	_fill(img, 2, 4, 4, 3, red)
	_fill(img, 10, 4, 4, 3, red)
	_fill(img, 3, 3, 3, 1, red)
	_fill(img, 10, 3, 3, 1, red)
	# Middle
	_fill(img, 1, 5, 14, 3, red)
	# Lower triangle
	_fill(img, 2, 8, 12, 2, red)
	_fill(img, 3, 10, 10, 1, red)
	_fill(img, 4, 11, 8, 1, red)
	_fill(img, 5, 12, 6, 1, red)
	_fill(img, 6, 13, 4, 1, red)
	_fill(img, 7, 14, 2, 1, red)
	# Highlight
	_fill(img, 3, 4, 2, 2, red_hi)
	_px(img, 4, 3, red_hi)
	# Shadow
	_fill(img, 11, 6, 2, 2, red_dk)
	_fill(img, 9, 9, 3, 1, red_dk)

	_outline(img, Color(0.25, 0.02, 0.02))
	_save(img, "res://assets/sprites/ui/hp.png")

func _gen_xp() -> void:
	var img = _img16()
	var blue = Color(0.2, 0.45, 0.95)
	var blue_hi = Color(0.45, 0.65, 1.0)
	var blue_dk = Color(0.1, 0.25, 0.7)

	# Diamond shape
	for i in range(7):
		var w = i + 1 if i < 4 else 7 - i
		_fill(img, 8 - w, 1 + i * 2, w * 2, 2, blue)
	# Highlight (upper left facet)
	_fill(img, 7, 3, 2, 4, blue_hi)
	_fill(img, 6, 5, 1, 2, blue_hi)
	_px(img, 8, 2, blue_hi)
	# Shadow (lower right)
	_fill(img, 9, 9, 2, 3, blue_dk)
	_fill(img, 8, 11, 1, 2, blue_dk)

	_outline(img, Color(0.05, 0.1, 0.3))
	_save(img, "res://assets/sprites/ui/xp.png")

func _gen_timer() -> void:
	var img = _img16()
	var face = Color(0.9, 0.9, 0.92)
	var rim = Color(0.7, 0.7, 0.75)
	var hand = Color(0.15, 0.15, 0.18)
	var center_c = Color(0.3, 0.3, 0.35)

	# Clock circle
	for dx in range(-6, 7):
		for dy in range(-6, 7):
			var dist = dx * dx + dy * dy
			if dist <= 36:
				if dist >= 28:
					_px(img, 8 + dx, 8 + dy, rim)
				else:
					_px(img, 8 + dx, 8 + dy, face)
	# Top knob
	_fill(img, 7, 1, 2, 1, rim)
	# Hour hand (pointing to 12, short)
	_fill(img, 8, 4, 1, 4, hand)
	# Minute hand (pointing to 3)
	_fill(img, 8, 8, 4, 1, hand)
	# Center dot
	_px(img, 8, 8, center_c)
	# Hour marks
	_px(img, 8, 3, hand)  # 12
	_px(img, 13, 8, hand)  # 3
	_px(img, 8, 13, hand)  # 6
	_px(img, 3, 8, hand)   # 9

	_outline(img, Color(0.2, 0.2, 0.22))
	_save(img, "res://assets/sprites/ui/timer.png")

func _gen_kill_count() -> void:
	var img = _img16()
	var bone = Color(0.85, 0.82, 0.75)
	var bone_dk = Color(0.65, 0.6, 0.55)
	var eye = Color(0.7, 0.1, 0.1)
	var teeth = Color(0.75, 0.72, 0.68)

	# Skull dome
	_fill(img, 4, 2, 8, 5, bone)
	_fill(img, 3, 3, 10, 4, bone)
	_fill(img, 5, 1, 6, 1, bone)
	# Eye sockets
	_fill(img, 5, 4, 2, 2, eye)
	_fill(img, 9, 4, 2, 2, eye)
	# Nose
	_px(img, 7, 7, bone_dk)
	_px(img, 8, 7, bone_dk)
	# Jaw
	_fill(img, 4, 7, 8, 3, bone)
	_fill(img, 3, 8, 1, 2, bone_dk)
	_fill(img, 12, 8, 1, 2, bone_dk)
	# Teeth
	_px(img, 5, 9, teeth)
	_px(img, 7, 9, teeth)
	_px(img, 9, 9, teeth)
	_px(img, 11, 9, teeth)
	# Gaps between teeth
	_px(img, 6, 9, bone_dk)
	_px(img, 8, 9, bone_dk)
	_px(img, 10, 9, bone_dk)

	# Crossbones below
	for i in range(6):
		_px(img, 3 + i, 11 + i, bone_dk)
		_px(img, 12 - i, 11 + i, bone_dk)

	_outline(img, Color(0.2, 0.05, 0.05))
	_save(img, "res://assets/sprites/ui/kill_count.png")

func _gen_element_fire() -> void:
	var img = _img16()
	var orange = Color(1.0, 0.55, 0.05)
	var yellow = Color(1.0, 0.85, 0.15)
	var red = Color(0.9, 0.2, 0.05)

	# Flame body
	_fill(img, 5, 5, 6, 7, orange)
	_fill(img, 6, 4, 4, 1, orange)
	_fill(img, 6, 12, 4, 2, red)
	# Inner flame
	_fill(img, 7, 6, 3, 5, yellow)
	_fill(img, 7, 5, 2, 1, yellow)
	# Tip
	_fill(img, 7, 3, 2, 2, orange)
	_px(img, 7, 2, red)
	_px(img, 8, 1, red)
	# Flicker left
	_px(img, 4, 7, red)
	_px(img, 4, 6, red)
	# Flicker right
	_px(img, 11, 6, red)
	_px(img, 11, 8, red)

	_outline(img, Color(0.3, 0.08, 0.02))
	_save(img, "res://assets/sprites/ui/element_fire.png")

func _gen_element_ice() -> void:
	var img = _img16()
	var ice = Color(0.5, 0.8, 1.0)
	var ice_hi = Color(0.8, 0.95, 1.0)
	var ice_dk = Color(0.25, 0.5, 0.8)

	# Snowflake - 6 arms from center
	# Center
	_px(img, 7, 7, ice_hi)
	_px(img, 8, 8, ice_hi)
	_px(img, 7, 8, ice)
	_px(img, 8, 7, ice)

	# Vertical arm
	for i in range(1, 6):
		_px(img, 7, 7 - i, ice)
		_px(img, 8, 8 + i, ice)
	# Horizontal arm
	for i in range(1, 6):
		_px(img, 7 - i, 7, ice)
		_px(img, 8 + i, 8, ice)
	# Diagonal arms
	for i in range(1, 5):
		_px(img, 7 - i, 7 - i, ice_dk)
		_px(img, 8 + i, 8 + i, ice_dk)
		_px(img, 8 + i, 7 - i, ice_dk)
		_px(img, 7 - i, 8 + i, ice_dk)
	# Small branches on vertical arms
	_px(img, 6, 4, ice_dk)
	_px(img, 9, 4, ice_dk)
	_px(img, 6, 11, ice_dk)
	_px(img, 9, 11, ice_dk)
	# Small branches on horizontal arms
	_px(img, 4, 6, ice_dk)
	_px(img, 4, 9, ice_dk)
	_px(img, 11, 6, ice_dk)
	_px(img, 11, 9, ice_dk)

	_outline(img, Color(0.1, 0.2, 0.35))
	_save(img, "res://assets/sprites/ui/element_ice.png")

func _gen_element_electric() -> void:
	var img = _img16()
	var yellow = Color(1.0, 0.9, 0.15)
	var yellow_hi = Color(1.0, 1.0, 0.6)
	var yellow_dk = Color(0.8, 0.65, 0.05)

	# Lightning bolt shape
	_fill(img, 8, 1, 3, 2, yellow)
	_fill(img, 7, 3, 3, 2, yellow)
	_fill(img, 6, 5, 3, 2, yellow)
	# Wide mid-section
	_fill(img, 5, 7, 6, 2, yellow)
	# Lower part
	_fill(img, 7, 9, 3, 2, yellow)
	_fill(img, 8, 11, 3, 2, yellow)
	_fill(img, 9, 13, 2, 2, yellow_dk)
	# Highlight on upper part
	_px(img, 8, 2, yellow_hi)
	_px(img, 7, 4, yellow_hi)
	_px(img, 6, 6, yellow_hi)
	_px(img, 6, 8, yellow_hi)
	# Shadow on lower
	_px(img, 10, 8, yellow_dk)
	_px(img, 10, 12, yellow_dk)

	_outline(img, Color(0.3, 0.25, 0.02))
	_save(img, "res://assets/sprites/ui/element_electric.png")

func _gen_element_dark() -> void:
	var img = _img16()
	var purple = Color(0.5, 0.15, 0.7)
	var purple_hi = Color(0.7, 0.3, 0.9)
	var purple_dk = Color(0.3, 0.08, 0.45)

	# Crescent moon shape
	for dx in range(-6, 7):
		for dy in range(-6, 7):
			if dx * dx + dy * dy <= 36:
				_px(img, 8 + dx, 8 + dy, purple)
	# Cut out inner circle (shifted right) to make crescent
	for dx in range(-5, 6):
		for dy in range(-5, 6):
			if dx * dx + dy * dy <= 20:
				_px(img, 10 + dx, 7 + dy, Color(0, 0, 0, 0))
	# Highlight on outer edge
	_px(img, 3, 6, purple_hi)
	_px(img, 3, 7, purple_hi)
	_px(img, 3, 8, purple_hi)
	_px(img, 4, 5, purple_hi)
	_px(img, 4, 9, purple_hi)
	# Shadow
	_px(img, 5, 12, purple_dk)
	_px(img, 6, 13, purple_dk)
	_px(img, 7, 13, purple_dk)

	# Small stars near crescent
	_px(img, 12, 3, Color(0.9, 0.8, 1.0))
	_px(img, 14, 6, Color(0.8, 0.7, 0.95))

	_outline(img, Color(0.12, 0.04, 0.18))
	_save(img, "res://assets/sprites/ui/element_dark.png")

func _gen_element_poison() -> void:
	var img = _img16()
	var green = Color(0.2, 0.8, 0.15)
	var green_hi = Color(0.4, 0.95, 0.3)
	var green_dk = Color(0.1, 0.55, 0.08)

	# Drop/droplet shape
	# Top point
	_fill(img, 7, 1, 2, 2, green)
	# Expanding middle
	_fill(img, 6, 3, 4, 2, green)
	_fill(img, 5, 5, 6, 2, green)
	_fill(img, 4, 7, 8, 2, green)
	# Wide bottom
	_fill(img, 3, 9, 10, 2, green)
	_fill(img, 4, 11, 8, 2, green)
	_fill(img, 5, 13, 6, 1, green)
	_fill(img, 6, 14, 4, 1, green)

	# Highlight
	_fill(img, 5, 6, 2, 3, green_hi)
	_px(img, 6, 5, green_hi)
	_px(img, 7, 3, green_hi)

	# Shadow
	_fill(img, 9, 9, 2, 3, green_dk)
	_px(img, 8, 12, green_dk)

	_outline(img, Color(0.05, 0.2, 0.03))
	_save(img, "res://assets/sprites/ui/element_poison.png")

func _gen_element_physical() -> void:
	var img = _img16()
	var blade = Color(0.7, 0.72, 0.75)
	var blade_hi = Color(0.88, 0.9, 0.95)
	var handle = Color(0.5, 0.35, 0.2)
	var guard = Color(0.65, 0.55, 0.15)

	# Blade (diagonal upper-right to lower-center)
	for i in range(8):
		_px(img, 10 - i, 2 + i, blade)
		_px(img, 11 - i, 2 + i, blade)
	# Blade highlight edge
	for i in range(7):
		_px(img, 12 - i, 2 + i, blade_hi)
	# Guard
	_fill(img, 2, 9, 5, 2, guard)
	# Handle
	for i in range(4):
		_px(img, 2 - i, 11 + i, handle)
		_px(img, 3 - i, 11 + i, handle)
	# Pommel
	_px(img, 0, 14, Color(0.6, 0.5, 0.1))
	_px(img, 0, 15, Color(0.6, 0.5, 0.1))

	_outline(img, Color(0.15, 0.15, 0.15))
	_save(img, "res://assets/sprites/ui/element_physical.png")

# ==================== EFFECTS (16x16) ====================

func _gen_hit_spark() -> void:
	var img = _img16()
	var white = Color(1.0, 1.0, 1.0)
	var yellow = Color(1.0, 0.9, 0.3)
	var yellow_dk = Color(0.9, 0.7, 0.15)

	# Star burst from center
	# Center bright core
	_fill(img, 7, 7, 2, 2, white)
	# 4 main spikes
	for i in range(1, 6):
		_px(img, 7, 7 - i, yellow)  # up
		_px(img, 8, 8 + i, yellow)  # down
		_px(img, 7 - i, 7, yellow)  # left
		_px(img, 8 + i, 8, yellow)  # right
	# 4 diagonal shorter spikes
	for i in range(1, 4):
		_px(img, 7 - i, 7 - i, yellow_dk)
		_px(img, 8 + i, 8 + i, yellow_dk)
		_px(img, 8 + i, 7 - i, yellow_dk)
		_px(img, 7 - i, 8 + i, yellow_dk)
	# Extra glow pixels around center
	_px(img, 6, 7, white)
	_px(img, 9, 8, white)
	_px(img, 7, 6, white)
	_px(img, 8, 9, white)

	_save(img, "res://assets/sprites/effects/hit_spark.png")

func _gen_death_poof() -> void:
	var img = _img16()
	var smoke = Color(0.55, 0.55, 0.55)
	var smoke_hi = Color(0.72, 0.72, 0.72)
	var smoke_dk = Color(0.38, 0.38, 0.38)

	# Cloud puffs overlapping
	# Bottom-center puff
	for dx in range(-4, 5):
		for dy in range(-3, 4):
			if dx * dx + dy * dy <= 12:
				_px(img, 8 + dx, 10 + dy, smoke)
	# Top-left puff
	for dx in range(-3, 4):
		for dy in range(-3, 4):
			if dx * dx + dy * dy <= 9:
				_px(img, 5 + dx, 6 + dy, smoke_hi)
	# Top-right puff
	for dx in range(-3, 4):
		for dy in range(-3, 4):
			if dx * dx + dy * dy <= 9:
				_px(img, 11 + dx, 7 + dy, smoke)
	# Upper highlight
	_px(img, 5, 4, smoke_hi)
	_px(img, 6, 3, smoke_hi)
	_px(img, 7, 4, smoke_hi)
	# Lower shadow
	_fill(img, 6, 12, 5, 1, smoke_dk)
	_fill(img, 7, 13, 3, 1, smoke_dk)

	_save(img, "res://assets/sprites/effects/death_poof.png")

func _gen_level_up_flash() -> void:
	var img = _img16()
	var gold = Color(1.0, 0.85, 0.15)
	var gold_hi = Color(1.0, 0.95, 0.5)
	var gold_core = Color(1.0, 1.0, 0.8)
	var gold_dk = Color(0.9, 0.7, 0.1)

	# Starburst pattern (8 pointed)
	# Center glow
	_fill(img, 6, 6, 4, 4, Color(1.0, 0.9, 0.3, 0.4))
	_fill(img, 7, 7, 2, 2, gold_core)

	# Cardinal spikes (longer, thicker)
	for i in range(1, 7):
		var alpha = maxf(1.0 - i * 0.1, 0.35)
		var c = Color(gold.r, gold.g, gold.b, alpha)
		_px(img, 7, 7 - i, c)
		_px(img, 8, 7 - i, c)
		_px(img, 8, 8 + i, c)
		_px(img, 7, 8 + i, c)
		_px(img, 7 - i, 8, c)
		_px(img, 7 - i, 7, c)
		_px(img, 8 + i, 7, c)
		_px(img, 8 + i, 8, c)
	# Diagonal spikes (shorter)
	for i in range(1, 5):
		var alpha = maxf(1.0 - i * 0.12, 0.4)
		var c = Color(gold_dk.r, gold_dk.g, gold_dk.b, alpha)
		_px(img, 7 - i, 7 - i, c)
		_px(img, 8 + i, 8 + i, c)
		_px(img, 8 + i, 7 - i, c)
		_px(img, 7 - i, 8 + i, c)
	# Extra glow around center
	_px(img, 6, 7, gold_hi)
	_px(img, 9, 8, gold_hi)
	_px(img, 7, 6, gold_hi)
	_px(img, 8, 9, gold_hi)
	_px(img, 6, 8, gold)
	_px(img, 9, 7, gold)

	_save(img, "res://assets/sprites/effects/level_up_flash.png")

func _gen_dash_trail() -> void:
	var img = _img16()
	var cyan_core = Color(0.6, 0.95, 1.0, 1.0)
	var cyan = Color(0.3, 0.7, 1.0, 0.9)
	var cyan_mid = Color(0.25, 0.55, 0.9, 0.75)
	var cyan_fade = Color(0.2, 0.4, 0.8, 0.5)

	# Horizontal streak, bright on right fading left
	# Core streak (right/front is bright)
	_fill(img, 10, 7, 5, 2, cyan_core)
	_fill(img, 6, 7, 4, 2, cyan)
	_fill(img, 2, 7, 4, 2, cyan_mid)

	# Wider middle section
	_fill(img, 8, 6, 6, 1, cyan)
	_fill(img, 8, 9, 6, 1, cyan)
	# Tapered front
	_px(img, 15, 7, cyan_core)
	_px(img, 15, 8, cyan)
	# Faded tail
	_px(img, 1, 7, cyan_fade)
	_px(img, 1, 8, cyan_fade)
	_px(img, 0, 8, Color(0.2, 0.4, 0.8, 0.3))

	# Speed lines above and below
	_fill(img, 3, 5, 4, 1, Color(0.3, 0.6, 0.9, 0.55))
	_fill(img, 4, 10, 3, 1, Color(0.3, 0.6, 0.9, 0.55))

	_save(img, "res://assets/sprites/effects/dash_trail.png")

func _gen_collect_sparkle() -> void:
	var img = _img16()
	var white = Color(1.0, 1.0, 1.0)
	var white_dim = Color(0.85, 0.85, 0.95, 0.7)

	# 4-pointed sparkle star
	# Center
	_px(img, 7, 7, white)
	_px(img, 8, 8, white)
	_px(img, 7, 8, white)
	_px(img, 8, 7, white)

	# Vertical spike
	_px(img, 7, 5, white)
	_px(img, 8, 5, white)
	_px(img, 7, 3, white_dim)
	_px(img, 8, 10, white)
	_px(img, 7, 10, white)
	_px(img, 8, 12, white_dim)

	# Horizontal spike
	_px(img, 5, 7, white)
	_px(img, 5, 8, white)
	_px(img, 3, 7, white_dim)
	_px(img, 10, 7, white)
	_px(img, 10, 8, white)
	_px(img, 12, 8, white_dim)

	# Small diagonal accents
	_px(img, 5, 5, white_dim)
	_px(img, 10, 10, white_dim)
	_px(img, 10, 5, white_dim)
	_px(img, 5, 10, white_dim)

	# Tiny extra sparkles
	_px(img, 2, 2, Color(1.0, 1.0, 1.0, 0.4))
	_px(img, 13, 3, Color(1.0, 1.0, 1.0, 0.4))
	_px(img, 3, 13, Color(1.0, 1.0, 1.0, 0.4))
	_px(img, 12, 12, Color(1.0, 1.0, 1.0, 0.4))

	_save(img, "res://assets/sprites/effects/collect_sparkle.png")

func _gen_damage_number_bg() -> void:
	var img = _img16()
	var bg = Color(0.1, 0.1, 0.12, 0.75)
	var edge = Color(0.15, 0.15, 0.18, 0.6)

	# Rounded rectangle background
	_fill(img, 2, 3, 12, 10, bg)
	_fill(img, 3, 2, 10, 12, bg)
	# Rounded corners
	_px(img, 2, 2, edge)
	_px(img, 13, 2, edge)
	_px(img, 2, 13, edge)
	_px(img, 13, 13, edge)
	# Top/bottom edge rows
	_fill(img, 3, 1, 10, 1, edge)
	_fill(img, 3, 14, 10, 1, edge)
	# Left/right edge cols
	_fill(img, 1, 3, 1, 10, edge)
	_fill(img, 14, 3, 1, 10, edge)

	_save(img, "res://assets/sprites/effects/damage_number_bg.png")
