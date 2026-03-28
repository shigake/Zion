extends SceneTree

## Generates 32x32 pixel art sprites for castle stage decoration props,
## plus a 64x64 tiled ground texture.
## Run: godot --headless --script res://scripts/tools/castle_prop_sprites.gd

const S := 32  # Prop sprite size
const G := 64  # Ground tile size

func _init() -> void:
	_generate_all()
	quit()

func _generate_all() -> void:
	DirAccess.make_dir_recursive_absolute("res://assets/sprites/props/castle")

	_gen_ground_castle()
	_gen_candelabra()
	_gen_coffin_vampire()
	_gen_pillar()
	_gen_stained_glass()
	_gen_armor_stand()
	_gen_painting()
	_gen_cobweb()
	_gen_gargoyle()
	_gen_throne()

	print("All castle prop sprites generated!")

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
	var path = "res://assets/sprites/props/castle/" + name
	img.save_png(path)
	print("Saved: ", path)

# ==================== GROUND ====================

func _gen_ground_castle() -> void:
	# 64x64 dark stone floor with tile pattern and cracks
	var img = _img(G)
	var stone = Color(0.18, 0.16, 0.16)
	var stone2 = Color(0.2, 0.18, 0.17)
	var stone_dark = Color(0.12, 0.1, 0.1)
	var grout = Color(0.08, 0.07, 0.07)
	var crack = Color(0.1, 0.08, 0.08)
	var moss = Color(0.12, 0.2, 0.1)

	# Base fill
	_fill(img, 0, 0, G, G, stone)

	# Stone variation noise
	var rng = RandomNumberGenerator.new()
	rng.seed = 55
	for i in range(120):
		_px(img, rng.randi_range(0, G - 1), rng.randi_range(0, G - 1), stone2)
	for i in range(60):
		_px(img, rng.randi_range(0, G - 1), rng.randi_range(0, G - 1), stone_dark)

	# Tile grid (16x16 tiles)
	for i in range(0, G, 16):
		_fill(img, i, 0, 1, G, grout)
		_fill(img, 0, i, G, 1, grout)

	# Offset alternate rows by 8px for brick pattern
	for row in [16, 48]:
		_fill(img, 8, row, 1, 1, grout)
		_fill(img, 24, row, 1, 1, grout)
		_fill(img, 40, row, 1, 1, grout)
		_fill(img, 56, row, 1, 1, grout)

	# Cracks in various tiles
	# Crack 1 (top-left tile)
	_px(img, 5, 5, crack)
	_px(img, 6, 6, crack)
	_px(img, 7, 7, crack)
	_px(img, 7, 8, crack)
	_px(img, 8, 9, crack)

	# Crack 2 (center tile)
	_px(img, 34, 34, crack)
	_px(img, 35, 35, crack)
	_px(img, 35, 36, crack)
	_px(img, 36, 37, crack)

	# Crack 3 (bottom-right)
	_px(img, 52, 50, crack)
	_px(img, 53, 51, crack)
	_px(img, 53, 52, crack)
	_px(img, 54, 53, crack)
	_px(img, 55, 53, crack)

	# Moss in grout lines
	_px(img, 0, 10, moss)
	_px(img, 0, 11, moss)
	_px(img, 16, 25, moss)
	_px(img, 16, 26, moss)
	_px(img, 32, 5, moss)
	_px(img, 48, 42, moss)
	_px(img, 48, 43, moss)

	_save(img, "ground_castle.png")

# ==================== CANDELABRA ====================

func _gen_candelabra() -> void:
	# Tall candelabra with 3 candles and flames
	var img = _img()
	var gold = Color(0.6, 0.5, 0.2)
	var gold_dark = Color(0.45, 0.35, 0.12)
	var gold_light = Color(0.75, 0.65, 0.3)
	var candle = Color(0.85, 0.82, 0.7)
	var candle_dark = Color(0.7, 0.65, 0.55)
	var flame = Color(0.95, 0.7, 0.1)
	var flame_tip = Color(0.95, 0.4, 0.1)

	# Central pole
	_fill(img, 15, 10, 2, 18, gold)
	_px(img, 15, 10, gold_dark)

	# Base (wide tripod)
	_fill(img, 10, 27, 12, 2, gold)
	_fill(img, 8, 29, 16, 2, gold_dark)
	_fill(img, 12, 26, 8, 1, gold)

	# Arms (left and right)
	# Left arm
	_fill(img, 8, 10, 7, 2, gold)
	_fill(img, 8, 10, 1, 2, gold_light)
	_fill(img, 8, 8, 2, 2, gold) # cup

	# Right arm
	_fill(img, 17, 10, 7, 2, gold)
	_fill(img, 23, 10, 1, 2, gold_light)
	_fill(img, 22, 8, 2, 2, gold) # cup

	# Center cup
	_fill(img, 14, 8, 4, 2, gold)

	# Candles
	_fill(img, 8, 4, 2, 4, candle)
	_px(img, 8, 4, candle_dark)
	_fill(img, 15, 4, 2, 4, candle)
	_px(img, 15, 4, candle_dark)
	_fill(img, 22, 4, 2, 4, candle)
	_px(img, 22, 4, candle_dark)

	# Flames
	_px(img, 8, 3, flame)
	_px(img, 9, 3, flame)
	_px(img, 8, 2, flame_tip)

	_px(img, 15, 3, flame)
	_px(img, 16, 3, flame)
	_px(img, 15, 2, flame_tip)
	_px(img, 16, 1, flame_tip)

	_px(img, 22, 3, flame)
	_px(img, 23, 3, flame)
	_px(img, 23, 2, flame_tip)

	_outline(img, Color(0.1, 0.08, 0.04))
	_save(img, "candelabra.png")

# ==================== COFFIN VAMPIRE ====================

func _gen_coffin_vampire() -> void:
	# Ornate red/black vampire coffin, viewed from front/side
	var img = _img()
	var wood = Color(0.2, 0.08, 0.08)
	var wood_dark = Color(0.12, 0.04, 0.04)
	var wood_light = Color(0.3, 0.12, 0.1)
	var red = Color(0.6, 0.1, 0.1)
	var red_dark = Color(0.45, 0.08, 0.08)
	var gold = Color(0.7, 0.6, 0.2)
	var gold_dark = Color(0.5, 0.4, 0.12)

	# Main coffin body (hexagonal shape)
	_fill(img, 10, 4, 12, 24, wood)
	_fill(img, 8, 8, 2, 16, wood)
	_fill(img, 22, 8, 2, 16, wood)
	_fill(img, 12, 2, 8, 2, wood)
	_fill(img, 12, 28, 8, 2, wood)

	# Side shading
	_fill(img, 8, 8, 2, 16, wood_dark)
	_fill(img, 22, 8, 2, 16, wood_light)

	# Red velvet interior visible (center panel)
	_fill(img, 12, 6, 8, 18, red)
	_fill(img, 12, 6, 2, 18, red_dark)

	# Cross on lid
	_fill(img, 15, 8, 2, 12, gold)
	_fill(img, 12, 12, 8, 2, gold)
	# Cross shadow
	_px(img, 15, 8, gold_dark)
	_px(img, 12, 12, gold_dark)

	# Gold trim on edges
	_fill(img, 10, 4, 12, 1, gold)
	_fill(img, 10, 27, 12, 1, gold)
	_fill(img, 10, 4, 1, 24, gold_dark)
	_fill(img, 21, 4, 1, 24, gold)

	# Handles
	_fill(img, 7, 14, 2, 4, gold)
	_fill(img, 23, 14, 2, 4, gold)

	_outline(img, Color(0.05, 0.02, 0.02))
	_save(img, "coffin_vampire.png")

# ==================== PILLAR ====================

func _gen_pillar() -> void:
	# Gothic stone pillar with capital detail
	var img = _img()
	var stone = Color(0.4, 0.38, 0.36)
	var stone_dark = Color(0.28, 0.26, 0.24)
	var stone_light = Color(0.52, 0.5, 0.48)
	var crack = Color(0.22, 0.2, 0.18)

	# Shaft
	_fill(img, 12, 6, 8, 20, stone)
	_fill(img, 12, 6, 2, 20, stone_dark)
	_fill(img, 18, 6, 2, 20, stone_light)

	# Capital (top, wider)
	_fill(img, 9, 2, 14, 4, stone)
	_fill(img, 9, 2, 2, 4, stone_dark)
	_fill(img, 21, 2, 2, 4, stone_light)
	# Capital scroll details
	_px(img, 10, 3, stone_light)
	_px(img, 11, 2, stone_light)
	_px(img, 21, 3, stone_light)
	_px(img, 20, 2, stone_light)

	# Base (wider)
	_fill(img, 9, 26, 14, 4, stone)
	_fill(img, 9, 26, 2, 4, stone_dark)
	_fill(img, 21, 26, 2, 4, stone_light)

	# Fluting lines on shaft
	_fill(img, 14, 6, 1, 20, stone_dark)
	_fill(img, 17, 6, 1, 20, stone_light)

	# Cracks
	_px(img, 13, 12, crack)
	_px(img, 14, 13, crack)
	_px(img, 14, 14, crack)
	_px(img, 15, 15, crack)
	_px(img, 16, 20, crack)
	_px(img, 17, 21, crack)

	_outline(img, Color(0.1, 0.09, 0.08))
	_save(img, "pillar.png")

# ==================== STAINED GLASS ====================

func _gen_stained_glass() -> void:
	# Colorful stained glass window (gothic arch shape)
	var img = _img()
	var frame = Color(0.25, 0.22, 0.2)
	var frame_dark = Color(0.15, 0.12, 0.1)
	var red = Color(0.7, 0.15, 0.1, 0.85)
	var blue = Color(0.1, 0.2, 0.7, 0.85)
	var gold = Color(0.8, 0.7, 0.2, 0.85)
	var green = Color(0.1, 0.5, 0.15, 0.85)
	var white = Color(0.9, 0.9, 0.85, 0.9)
	var purple = Color(0.45, 0.1, 0.55, 0.85)

	# Frame shape (pointed arch)
	_fill(img, 8, 8, 16, 20, frame)
	_fill(img, 10, 6, 12, 2, frame)
	_fill(img, 12, 4, 8, 2, frame)
	_fill(img, 14, 2, 4, 2, frame)
	_px(img, 15, 1, frame)
	_px(img, 16, 1, frame)

	# Glass panels (inside the frame)
	# Top section - gold/white (trinity symbol area)
	_fill(img, 14, 3, 4, 3, gold)
	_fill(img, 12, 5, 8, 2, gold)
	_px(img, 15, 4, white)
	_px(img, 16, 4, white)

	# Left panels
	_fill(img, 9, 8, 7, 5, blue)
	_fill(img, 9, 14, 7, 5, red)
	_fill(img, 9, 20, 7, 4, green)

	# Right panels
	_fill(img, 16, 8, 7, 5, red)
	_fill(img, 16, 14, 7, 5, blue)
	_fill(img, 16, 20, 7, 4, purple)

	# Bottom center
	_fill(img, 11, 24, 10, 3, gold)

	# Lead lines (dividers)
	_fill(img, 15, 3, 2, 24, frame_dark)
	_fill(img, 9, 13, 14, 1, frame_dark)
	_fill(img, 9, 19, 14, 1, frame_dark)
	_fill(img, 9, 24, 14, 1, frame_dark)

	# Highlight spots (light shining through)
	_px(img, 12, 10, white)
	_px(img, 19, 16, white)
	_px(img, 13, 22, white)

	_outline(img, Color(0.08, 0.06, 0.05))
	_save(img, "stained_glass.png")

# ==================== ARMOR STAND ====================

func _gen_armor_stand() -> void:
	# Empty suit of armor (standing)
	var img = _img()
	var armor = Color(0.45, 0.45, 0.48)
	var armor_dark = Color(0.3, 0.3, 0.33)
	var armor_light = Color(0.6, 0.6, 0.65)
	var visor = Color(0.15, 0.15, 0.18)

	# Helmet
	_fill(img, 12, 2, 8, 6, armor)
	_fill(img, 11, 4, 1, 3, armor)
	_fill(img, 20, 4, 1, 3, armor)
	_fill(img, 14, 1, 4, 1, armor_light)
	# Visor slit
	_fill(img, 13, 5, 6, 1, visor)
	# Helmet plume/crest
	_fill(img, 15, 0, 2, 2, armor_light)

	# Neck
	_fill(img, 14, 8, 4, 2, armor_dark)

	# Pauldrons (shoulders)
	_fill(img, 7, 10, 7, 4, armor)
	_fill(img, 18, 10, 7, 4, armor)
	_fill(img, 7, 10, 2, 4, armor_dark)
	_fill(img, 23, 10, 2, 4, armor_light)

	# Breastplate
	_fill(img, 11, 10, 10, 10, armor)
	_fill(img, 11, 10, 2, 10, armor_dark)
	_fill(img, 19, 10, 2, 10, armor_light)
	# Center line
	_fill(img, 15, 11, 2, 8, armor_light)

	# Gauntlets
	_fill(img, 7, 14, 4, 6, armor)
	_fill(img, 21, 14, 4, 6, armor)
	_fill(img, 7, 14, 1, 6, armor_dark)
	_fill(img, 24, 14, 1, 6, armor_light)

	# Tasset/skirt
	_fill(img, 10, 20, 12, 4, armor)
	_fill(img, 10, 20, 2, 4, armor_dark)
	_fill(img, 20, 20, 2, 4, armor_light)

	# Greaves/legs
	_fill(img, 11, 24, 4, 6, armor)
	_fill(img, 17, 24, 4, 6, armor)
	_fill(img, 11, 24, 1, 6, armor_dark)
	_fill(img, 17, 24, 1, 6, armor_dark)

	# Base
	_fill(img, 9, 29, 14, 2, Color(0.25, 0.22, 0.2))

	_outline(img, Color(0.08, 0.08, 0.1))
	_save(img, "armor_stand.png")

# ==================== PAINTING ====================

func _gen_painting() -> void:
	# Dark painting in ornate frame
	var img = _img()
	var frame = Color(0.5, 0.35, 0.12)
	var frame_dark = Color(0.35, 0.24, 0.08)
	var frame_light = Color(0.65, 0.48, 0.18)
	var canvas = Color(0.12, 0.08, 0.06)
	var canvas_dark = Color(0.08, 0.05, 0.04)
	var red = Color(0.4, 0.1, 0.08)
	var skin = Color(0.55, 0.4, 0.3)

	# Frame outer
	_fill(img, 4, 4, 24, 22, frame)
	_fill(img, 4, 4, 24, 2, frame_light)
	_fill(img, 4, 24, 24, 2, frame_dark)
	_fill(img, 4, 4, 2, 22, frame_dark)
	_fill(img, 26, 4, 2, 22, frame_light)

	# Canvas
	_fill(img, 7, 7, 18, 16, canvas)

	# Vague portrait figure (dark, mysterious)
	# Face oval
	_fill(img, 14, 9, 4, 5, skin)
	_px(img, 13, 10, skin)
	_px(img, 18, 10, skin)
	# Eyes (dark)
	_px(img, 15, 11, canvas_dark)
	_px(img, 17, 11, canvas_dark)
	# Robe body
	_fill(img, 12, 14, 8, 8, red)
	_fill(img, 11, 16, 1, 6, red)
	_fill(img, 20, 16, 1, 6, red)

	# Dark background fade
	_fill(img, 7, 7, 5, 16, canvas_dark)
	_fill(img, 20, 7, 5, 16, canvas_dark)

	# Hanging wire
	_fill(img, 15, 2, 2, 2, frame_dark)
	_px(img, 14, 1, frame_dark)
	_px(img, 17, 1, frame_dark)

	# Frame corner ornaments
	_px(img, 5, 5, frame_light)
	_px(img, 26, 5, frame_light)
	_px(img, 5, 24, frame_light)
	_px(img, 26, 24, frame_light)

	_outline(img, Color(0.08, 0.05, 0.02))
	_save(img, "painting.png")

# ==================== COBWEB ====================

func _gen_cobweb() -> void:
	# White spider web, corner style
	var img = _img()
	var web = Color(0.8, 0.8, 0.82, 0.7)
	var web_bright = Color(0.95, 0.95, 0.97, 0.85)

	# Radial threads from top-left corner
	# Main diagonal
	for i in range(28):
		_px(img, i, i, web)
	# Thread toward right
	for i in range(28):
		_px(img, i, i / 3, web)
	# Thread toward bottom
	for i in range(28):
		_px(img, i / 3, i, web)
	# Mid-angle threads
	for i in range(24):
		_px(img, i, i / 2, web)
	for i in range(24):
		_px(img, i / 2, i, web)
	# Another angle
	for i in range(20):
		_px(img, i, i * 2 / 3, web)
	for i in range(20):
		_px(img, i * 2 / 3, i, web)

	# Concentric arcs (connecting threads)
	# Arc at distance ~8
	for i in range(9):
		var ax = 8 - i
		var ay = i
		if ax >= 0:
			_px(img, ax, ay, web_bright)
	# Arc at distance ~14
	for i in range(15):
		var ax = 14 - i
		var ay = i
		if ax >= 0:
			_px(img, ax, ay, web_bright)
	# Arc at distance ~20
	for i in range(21):
		var ax = 20 - i
		var ay = i
		if ax >= 0:
			_px(img, ax, ay, web_bright)
	# Arc at distance ~26
	for i in range(27):
		var ax = 26 - i
		var ay = i
		if ax >= 0 and ax < S and ay < S:
			_px(img, ax, ay, web_bright)

	# Small spider (optional, 3 pixels)
	_px(img, 12, 12, Color(0.2, 0.15, 0.1))
	_px(img, 13, 12, Color(0.2, 0.15, 0.1))
	_px(img, 12, 13, Color(0.2, 0.15, 0.1))

	_save(img, "cobweb.png")

# ==================== GARGOYLE ====================

func _gen_gargoyle() -> void:
	# Stone gargoyle statue crouching
	var img = _img()
	var stone = Color(0.4, 0.38, 0.36)
	var stone_dark = Color(0.28, 0.26, 0.24)
	var stone_light = Color(0.52, 0.5, 0.48)
	var eye = Color(0.6, 0.15, 0.1)

	# Head
	_fill(img, 12, 4, 8, 6, stone)
	_fill(img, 11, 6, 1, 3, stone)
	_fill(img, 20, 6, 1, 3, stone)

	# Horns
	_px(img, 12, 3, stone_dark)
	_px(img, 11, 2, stone_dark)
	_px(img, 19, 3, stone_dark)
	_px(img, 20, 2, stone_dark)

	# Eyes
	_px(img, 14, 7, eye)
	_px(img, 18, 7, eye)

	# Snout/jaw
	_fill(img, 13, 9, 6, 2, stone)
	_px(img, 14, 10, stone_dark) # nostril
	_px(img, 17, 10, stone_dark)

	# Body (hunched)
	_fill(img, 10, 11, 12, 10, stone)
	_fill(img, 10, 11, 2, 10, stone_dark)
	_fill(img, 20, 11, 2, 10, stone_light)

	# Wings (folded)
	_fill(img, 6, 12, 4, 8, stone)
	_fill(img, 5, 14, 1, 5, stone_dark)
	_fill(img, 22, 12, 4, 8, stone)
	_fill(img, 26, 14, 1, 5, stone_light)
	# Wing tips
	_px(img, 5, 12, stone_dark)
	_px(img, 4, 13, stone_dark)
	_px(img, 26, 12, stone_light)
	_px(img, 27, 13, stone_light)

	# Clawed feet
	_fill(img, 10, 21, 5, 3, stone)
	_fill(img, 17, 21, 5, 3, stone)
	_px(img, 9, 23, stone_dark) # claws
	_px(img, 10, 24, stone_dark)
	_px(img, 22, 23, stone_dark)
	_px(img, 21, 24, stone_dark)

	# Tail curling
	_px(img, 22, 20, stone)
	_px(img, 23, 21, stone)
	_px(img, 24, 22, stone)
	_px(img, 25, 22, stone)
	_px(img, 26, 21, stone)

	# Base pedestal
	_fill(img, 8, 24, 16, 3, stone_dark)
	_fill(img, 7, 27, 18, 2, Color(0.22, 0.2, 0.18))

	_outline(img, Color(0.1, 0.09, 0.08))
	_save(img, "gargoyle.png")

# ==================== THRONE ====================

func _gen_throne() -> void:
	# Dark ornate throne
	var img = _img()
	var wood = Color(0.2, 0.1, 0.08)
	var wood_dark = Color(0.12, 0.06, 0.04)
	var wood_light = Color(0.3, 0.15, 0.1)
	var cushion = Color(0.5, 0.08, 0.08)
	var cushion_dark = Color(0.35, 0.05, 0.05)
	var gold = Color(0.7, 0.6, 0.2)

	# High back
	_fill(img, 9, 1, 14, 18, wood)
	_fill(img, 9, 1, 2, 18, wood_dark)
	_fill(img, 21, 1, 2, 18, wood_light)

	# Crown detail on top
	_px(img, 12, 0, gold)
	_px(img, 16, 0, gold)
	_px(img, 20, 0, gold)
	_fill(img, 11, 1, 10, 1, gold)

	# Back cushion
	_fill(img, 11, 4, 10, 12, cushion)
	_fill(img, 11, 4, 2, 12, cushion_dark)

	# Armrests
	_fill(img, 5, 16, 4, 3, wood)
	_fill(img, 23, 16, 4, 3, wood)
	_fill(img, 5, 16, 1, 3, wood_dark)
	_fill(img, 26, 16, 1, 3, wood_light)

	# Armrest tops (ornamental balls)
	_px(img, 5, 15, gold)
	_px(img, 6, 15, gold)
	_px(img, 26, 15, gold)
	_px(img, 25, 15, gold)

	# Seat
	_fill(img, 8, 19, 16, 4, wood)
	_fill(img, 9, 19, 14, 3, cushion)
	_fill(img, 9, 19, 2, 3, cushion_dark)

	# Front legs
	_fill(img, 8, 23, 3, 6, wood)
	_fill(img, 21, 23, 3, 6, wood)
	_fill(img, 8, 23, 1, 6, wood_dark)
	_fill(img, 23, 23, 1, 6, wood_light)

	# Claw feet
	_fill(img, 7, 28, 5, 2, wood_dark)
	_fill(img, 20, 28, 5, 2, wood_dark)

	# Gold trim
	_fill(img, 9, 18, 14, 1, gold)
	_fill(img, 9, 22, 14, 1, gold)

	_outline(img, Color(0.05, 0.03, 0.02))
	_save(img, "throne.png")
