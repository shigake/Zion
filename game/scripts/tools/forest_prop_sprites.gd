extends SceneTree

## Generates 32x32 pixel art sprites for forest stage decoration props,
## plus a 64x64 tiled ground texture.
## Run: godot --headless --script res://scripts/tools/forest_prop_sprites.gd

const S := 32  # Prop sprite size
const G := 64  # Ground tile size

func _init() -> void:
	_generate_all()
	quit()

func _generate_all() -> void:
	DirAccess.make_dir_recursive_absolute("res://assets/sprites/props/forest")

	_gen_tree1()
	_gen_tree2()
	_gen_mushroom_red()
	_gen_mushroom_cluster()
	_gen_bush()
	_gen_rock()
	_gen_flower()
	_gen_log()
	_gen_fairy_circle()
	_gen_ground_forest()

	print("All forest prop sprites generated!")

# ==================== HELPERS ====================

func _img(size: int = S) -> Image:
	return Image.create(size, size, false, Image.FORMAT_RGBA8)

func _fill(img: Image, x: int, y: int, w: int, h: int, color: Color) -> void:
	var sz = img.get_width()
	for px in range(maxi(x, 0), mini(x + w, sz)):
		for py in range(maxi(y, 0), mini(y + h, sz)):
			img.set_pixel(px, py, color)

func _px(img: Image, x: int, y: int, color: Color) -> void:
	var sz = img.get_width()
	if x >= 0 and x < sz and y >= 0 and y < sz:
		img.set_pixel(x, y, color)

func _outline(img: Image, color: Color) -> void:
	var sz = img.get_width()
	var out = Image.create(sz, sz, false, Image.FORMAT_RGBA8)
	for x in range(sz):
		for y in range(sz):
			if img.get_pixel(x, y).a > 0:
				continue
			for off in [Vector2i(-1,0), Vector2i(1,0), Vector2i(0,-1), Vector2i(0,1)]:
				var nx = x + off.x
				var ny = y + off.y
				if nx >= 0 and nx < sz and ny >= 0 and ny < sz:
					if img.get_pixel(nx, ny).a > 0:
						out.set_pixel(x, y, color)
						break
	for x in range(sz):
		for y in range(sz):
			if out.get_pixel(x, y).a > 0:
				img.set_pixel(x, y, out.get_pixel(x, y))

func _circle(img: Image, cx: int, cy: int, r: int, color: Color) -> void:
	for x in range(cx - r, cx + r + 1):
		for y in range(cy - r, cy + r + 1):
			if (x - cx) * (x - cx) + (y - cy) * (y - cy) <= r * r:
				_px(img, x, y, color)

func _save(img: Image, name: String) -> void:
	var path = "res://assets/sprites/props/forest/" + name
	img.save_png(path)
	print("Saved: ", path)

# ==================== TREE1 — tall pine ====================

func _gen_tree1() -> void:
	var img = _img()
	var trunk = Color(0.4, 0.25, 0.12)
	var trunk_dark = Color(0.3, 0.18, 0.08)
	var leaf = Color(0.15, 0.45, 0.12)
	var leaf_light = Color(0.22, 0.55, 0.18)
	var leaf_dark = Color(0.1, 0.35, 0.08)

	# Trunk
	_fill(img, 14, 20, 4, 10, trunk)
	_fill(img, 16, 20, 2, 10, trunk_dark)
	# Base
	_fill(img, 12, 28, 8, 2, Color(0.3, 0.2, 0.1))
	_fill(img, 13, 30, 6, 1, Color(0.25, 0.18, 0.08))

	# Pine layers (triangles, wide at bottom narrow at top)
	# Bottom layer
	_fill(img, 8, 16, 16, 4, leaf)
	_fill(img, 9, 15, 14, 1, leaf)
	_fill(img, 10, 14, 12, 1, leaf_light)
	_fill(img, 8, 19, 16, 1, leaf_dark)

	# Middle layer
	_fill(img, 10, 10, 12, 4, leaf)
	_fill(img, 11, 9, 10, 1, leaf)
	_fill(img, 12, 8, 8, 1, leaf_light)
	_fill(img, 10, 13, 12, 1, leaf_dark)

	# Top layer
	_fill(img, 12, 5, 8, 3, leaf)
	_fill(img, 13, 4, 6, 1, leaf)
	_fill(img, 14, 3, 4, 1, leaf_light)
	_fill(img, 15, 2, 2, 1, leaf_light)

	# Snow/light spots
	_px(img, 14, 4, leaf_light)
	_px(img, 12, 9, leaf_light)
	_px(img, 10, 15, leaf_light)

	_outline(img, Color(0.06, 0.2, 0.04))
	_save(img, "tree1.png")

# ==================== TREE2 — wide oak ====================

func _gen_tree2() -> void:
	var img = _img()
	var trunk = Color(0.45, 0.3, 0.15)
	var trunk_dark = Color(0.35, 0.22, 0.1)
	var leaf = Color(0.18, 0.5, 0.15)
	var leaf_light = Color(0.28, 0.6, 0.22)
	var leaf_dark = Color(0.12, 0.38, 0.1)

	# Thick trunk
	_fill(img, 13, 18, 6, 10, trunk)
	_fill(img, 17, 18, 2, 10, trunk_dark)
	# Base roots
	_fill(img, 11, 27, 10, 2, Color(0.35, 0.22, 0.1))
	_fill(img, 10, 29, 12, 2, Color(0.28, 0.18, 0.08))

	# Wide canopy (oval)
	_circle(img, 16, 10, 10, leaf)
	_circle(img, 12, 12, 5, leaf_dark)
	_circle(img, 20, 8, 4, leaf_light)
	_circle(img, 16, 6, 4, leaf_light)
	# Bottom canopy shading
	_fill(img, 7, 14, 18, 3, leaf_dark)
	# Top highlights
	_px(img, 14, 2, leaf_light)
	_px(img, 15, 1, leaf_light)
	_px(img, 16, 1, leaf_light)
	_px(img, 17, 2, leaf_light)

	_outline(img, Color(0.06, 0.22, 0.04))
	_save(img, "tree2.png")

# ==================== MUSHROOM RED ====================

func _gen_mushroom_red() -> void:
	var img = _img()
	var stem = Color(0.85, 0.82, 0.75)
	var stem_dark = Color(0.7, 0.68, 0.6)
	var cap = Color(0.85, 0.15, 0.1)
	var cap_dark = Color(0.65, 0.1, 0.08)
	var spot = Color(0.95, 0.92, 0.85)

	# Stem
	_fill(img, 14, 20, 4, 8, stem)
	_fill(img, 16, 20, 2, 8, stem_dark)
	# Base
	_fill(img, 12, 27, 8, 2, Color(0.3, 0.22, 0.12))

	# Cap (dome shape)
	_fill(img, 9, 16, 14, 4, cap)
	_fill(img, 10, 14, 12, 2, cap)
	_fill(img, 12, 13, 8, 1, cap)
	_fill(img, 13, 12, 6, 1, cap)
	# Bottom rim darker
	_fill(img, 9, 19, 14, 1, cap_dark)
	_fill(img, 10, 18, 12, 1, cap_dark)

	# White spots
	_px(img, 13, 14, spot)
	_px(img, 14, 14, spot)
	_px(img, 18, 15, spot)
	_px(img, 19, 15, spot)
	_px(img, 15, 13, spot)
	_px(img, 11, 17, spot)
	_px(img, 20, 17, spot)

	_outline(img, Color(0.4, 0.08, 0.05))
	_save(img, "mushroom_red.png")

# ==================== MUSHROOM CLUSTER ====================

func _gen_mushroom_cluster() -> void:
	var img = _img()
	var stem = Color(0.75, 0.68, 0.55)
	var stem_dark = Color(0.6, 0.55, 0.42)
	var cap = Color(0.55, 0.4, 0.25)
	var cap_light = Color(0.65, 0.5, 0.32)
	var cap_dark = Color(0.42, 0.3, 0.18)

	# Left small mushroom
	_fill(img, 8, 22, 3, 6, stem)
	_fill(img, 5, 19, 8, 3, cap)
	_fill(img, 6, 18, 6, 1, cap)
	_fill(img, 7, 17, 4, 1, cap_light)
	_fill(img, 5, 21, 8, 1, cap_dark)

	# Center mushroom (tallest)
	_fill(img, 14, 18, 3, 10, stem)
	_fill(img, 16, 18, 1, 10, stem_dark)
	_fill(img, 11, 14, 9, 4, cap)
	_fill(img, 12, 13, 7, 1, cap)
	_fill(img, 13, 12, 5, 1, cap_light)
	_fill(img, 11, 17, 9, 1, cap_dark)

	# Right small mushroom
	_fill(img, 21, 21, 3, 7, stem)
	_fill(img, 18, 18, 8, 3, cap)
	_fill(img, 19, 17, 6, 1, cap)
	_fill(img, 20, 16, 4, 1, cap_light)
	_fill(img, 18, 20, 8, 1, cap_dark)

	# Ground
	_fill(img, 4, 28, 24, 2, Color(0.25, 0.2, 0.12))

	_outline(img, Color(0.22, 0.15, 0.08))
	_save(img, "mushroom_cluster.png")

# ==================== BUSH ====================

func _gen_bush() -> void:
	var img = _img()
	var leaf = Color(0.2, 0.5, 0.15)
	var leaf_light = Color(0.3, 0.6, 0.22)
	var leaf_dark = Color(0.12, 0.38, 0.1)

	# Main bush body (rounded)
	_circle(img, 16, 18, 8, leaf)
	_circle(img, 12, 17, 5, leaf_dark)
	_circle(img, 20, 16, 4, leaf_light)
	_circle(img, 16, 14, 5, leaf_light)

	# Bottom shadow
	_fill(img, 8, 24, 16, 2, leaf_dark)

	# Leaf detail highlights
	_px(img, 14, 12, leaf_light)
	_px(img, 18, 13, leaf_light)
	_px(img, 11, 16, leaf_light)
	_px(img, 21, 18, leaf_light)

	# Ground base
	_fill(img, 7, 26, 18, 2, Color(0.25, 0.2, 0.1))
	_fill(img, 8, 28, 16, 2, Color(0.2, 0.16, 0.08))

	_outline(img, Color(0.06, 0.2, 0.04))
	_save(img, "bush.png")

# ==================== ROCK ====================

func _gen_rock() -> void:
	var img = _img()
	var stone = Color(0.5, 0.5, 0.48)
	var stone_light = Color(0.62, 0.62, 0.58)
	var stone_dark = Color(0.38, 0.38, 0.36)
	var moss = Color(0.25, 0.45, 0.18)
	var moss_dark = Color(0.18, 0.35, 0.12)

	# Main rock body (irregular)
	_fill(img, 8, 16, 16, 10, stone)
	_fill(img, 10, 14, 12, 2, stone)
	_fill(img, 12, 13, 8, 1, stone)
	# Left shadow
	_fill(img, 8, 16, 3, 10, stone_dark)
	# Right highlight
	_fill(img, 21, 16, 3, 8, stone_light)
	# Top highlight
	_fill(img, 13, 13, 4, 2, stone_light)

	# Moss patches
	_fill(img, 9, 22, 6, 3, moss)
	_fill(img, 17, 23, 4, 2, moss)
	_px(img, 10, 21, moss_dark)
	_px(img, 18, 22, moss_dark)

	# Ground base
	_fill(img, 6, 26, 20, 2, Color(0.3, 0.22, 0.12))
	_fill(img, 7, 28, 18, 2, Color(0.25, 0.18, 0.1))

	_outline(img, Color(0.2, 0.2, 0.18))
	_save(img, "rock.png")

# ==================== FLOWER ====================

func _gen_flower() -> void:
	var img = _img()
	var stem_col = Color(0.2, 0.5, 0.15)
	var stem_dark = Color(0.15, 0.38, 0.1)

	# Stems (3 flowers)
	# Left flower (red)
	_fill(img, 10, 18, 1, 8, stem_col)
	_px(img, 9, 17, stem_dark)
	_circle(img, 10, 15, 2, Color(0.9, 0.2, 0.15))
	_px(img, 10, 15, Color(0.95, 0.85, 0.2))

	# Center flower (yellow)
	_fill(img, 16, 16, 1, 10, stem_col)
	_px(img, 15, 15, stem_dark)
	_circle(img, 16, 13, 2, Color(0.95, 0.85, 0.2))
	_px(img, 16, 13, Color(0.9, 0.5, 0.1))

	# Right flower (purple)
	_fill(img, 22, 19, 1, 7, stem_col)
	_px(img, 21, 18, stem_dark)
	_circle(img, 22, 16, 2, Color(0.65, 0.2, 0.75))
	_px(img, 22, 16, Color(0.95, 0.85, 0.3))

	# Small leaves
	_px(img, 9, 22, stem_col)
	_px(img, 11, 21, stem_col)
	_px(img, 15, 20, stem_col)
	_px(img, 17, 19, stem_col)
	_px(img, 21, 23, stem_col)
	_px(img, 23, 22, stem_col)

	# Ground
	_fill(img, 7, 26, 18, 2, Color(0.25, 0.2, 0.1))

	_outline(img, Color(0.08, 0.18, 0.04))
	_save(img, "flower.png")

# ==================== LOG ====================

func _gen_log() -> void:
	var img = _img()
	var bark = Color(0.4, 0.28, 0.15)
	var bark_light = Color(0.52, 0.38, 0.2)
	var bark_dark = Color(0.3, 0.2, 0.1)
	var inner = Color(0.6, 0.45, 0.25)
	var inner_dark = Color(0.48, 0.35, 0.18)
	var moss = Color(0.22, 0.42, 0.15)

	# Fallen log body (horizontal)
	_fill(img, 3, 18, 26, 6, bark)
	_fill(img, 3, 18, 26, 2, bark_light)
	_fill(img, 3, 22, 26, 2, bark_dark)

	# End cross-section (left side visible)
	_circle(img, 5, 20, 4, inner)
	_circle(img, 5, 20, 2, inner_dark)
	_px(img, 5, 20, bark_dark)  # center ring

	# Moss on top
	_fill(img, 10, 17, 8, 1, moss)
	_fill(img, 20, 17, 5, 1, moss)
	_px(img, 12, 16, moss)
	_px(img, 22, 16, moss)

	# Bark texture lines
	_px(img, 14, 20, bark_dark)
	_px(img, 18, 19, bark_dark)
	_px(img, 22, 21, bark_dark)
	_px(img, 26, 20, bark_dark)

	# Ground
	_fill(img, 2, 24, 28, 2, Color(0.25, 0.2, 0.1))
	_fill(img, 3, 26, 26, 2, Color(0.2, 0.16, 0.08))

	_outline(img, Color(0.15, 0.1, 0.05))
	_save(img, "log.png")

# ==================== FAIRY CIRCLE ====================

func _gen_fairy_circle() -> void:
	var img = _img()
	var glow1 = Color(0.4, 0.9, 0.5, 0.9)
	var glow2 = Color(0.3, 0.8, 0.9, 0.8)
	var glow3 = Color(0.9, 0.9, 0.4, 0.85)
	var mush = Color(0.8, 0.75, 0.65)
	var mush_dark = Color(0.6, 0.55, 0.45)

	# Ring of small mushrooms around center
	var ring_positions = [
		Vector2i(16, 10), Vector2i(22, 12), Vector2i(24, 18),
		Vector2i(22, 24), Vector2i(16, 26), Vector2i(10, 24),
		Vector2i(8, 18), Vector2i(10, 12),
	]

	for p in ring_positions:
		# Small mushroom (2px stem + 3px cap)
		_px(img, p.x, p.y + 1, mush)
		_px(img, p.x, p.y + 2, mush_dark)
		_px(img, p.x - 1, p.y, mush)
		_px(img, p.x, p.y, mush)
		_px(img, p.x + 1, p.y, mush)

	# Glowing dots scattered between mushrooms
	var glow_positions = [
		Vector2i(14, 11), Vector2i(19, 11), Vector2i(23, 15),
		Vector2i(23, 21), Vector2i(19, 25), Vector2i(13, 25),
		Vector2i(9, 21), Vector2i(9, 15), Vector2i(16, 18),
	]

	var glows = [glow1, glow2, glow3, glow1, glow2, glow3, glow1, glow2, glow3]
	for i in range(glow_positions.size()):
		var p = glow_positions[i]
		_px(img, p.x, p.y, glows[i])

	# Ground hint
	_fill(img, 6, 28, 20, 2, Color(0.2, 0.18, 0.1))

	_outline(img, Color(0.15, 0.3, 0.15))
	_save(img, "fairy_circle.png")

# ==================== GROUND TILE ====================

func _gen_ground_forest() -> void:
	# 64x64 bright green grass with moss patches, small flowers
	var img = _img(G)
	var grass = Color(0.2, 0.48, 0.12)
	var grass2 = Color(0.25, 0.52, 0.15)
	var grass_dark = Color(0.15, 0.38, 0.08)
	var moss = Color(0.18, 0.42, 0.22)
	var moss_dark = Color(0.12, 0.32, 0.16)
	var flower_r = Color(0.85, 0.25, 0.2)
	var flower_y = Color(0.9, 0.85, 0.2)
	var flower_w = Color(0.9, 0.9, 0.85)

	# Base fill: grass
	_fill(img, 0, 0, G, G, grass)

	# Grass variation
	var rng = RandomNumberGenerator.new()
	rng.seed = 101

	for i in range(100):
		var px_x = rng.randi_range(0, G - 1)
		var px_y = rng.randi_range(0, G - 1)
		_px(img, px_x, px_y, grass2)

	for i in range(60):
		var px_x = rng.randi_range(0, G - 1)
		var px_y = rng.randi_range(0, G - 1)
		_px(img, px_x, px_y, grass_dark)

	# Moss patches
	_fill(img, 8, 10, 7, 5, moss)
	_fill(img, 10, 8, 4, 2, moss)
	_fill(img, 7, 12, 2, 2, moss_dark)

	_fill(img, 40, 30, 8, 6, moss)
	_fill(img, 42, 28, 5, 2, moss)
	_fill(img, 39, 33, 2, 2, moss_dark)

	_fill(img, 20, 50, 6, 4, moss)
	_fill(img, 22, 48, 3, 2, moss)
	_fill(img, 19, 52, 2, 2, moss_dark)

	_fill(img, 52, 8, 5, 4, moss)
	_fill(img, 50, 10, 2, 2, moss_dark)

	# Small flowers scattered
	var flower_data = [
		[Vector2i(15, 25), flower_r],
		[Vector2i(30, 12), flower_y],
		[Vector2i(48, 45), flower_w],
		[Vector2i(8, 55), flower_r],
		[Vector2i(55, 22), flower_y],
		[Vector2i(35, 58), flower_w],
		[Vector2i(25, 38), flower_r],
		[Vector2i(58, 50), flower_y],
		[Vector2i(5, 35), flower_w],
		[Vector2i(42, 15), flower_r],
	]
	for fd in flower_data:
		_px(img, fd[0].x, fd[0].y, fd[1])

	# Edge tiling
	for i in range(G):
		if rng.randi_range(0, 3) == 0:
			_px(img, 0, i, grass2)
			_px(img, G - 1, i, grass2)
		if rng.randi_range(0, 3) == 0:
			_px(img, i, 0, grass2)
			_px(img, i, G - 1, grass2)

	_save(img, "ground_forest.png")
