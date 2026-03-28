extends SceneTree

## Generates 32x32 pixel art sprites for tokyo stage decoration props,
## plus a 64x64 tiled ground texture.
## Run: godot --headless --script res://scripts/tools/tokyo_prop_sprites.gd

const S := 32  # Prop sprite size
const G := 64  # Ground tile size

func _init() -> void:
	_generate_all()
	quit()

func _generate_all() -> void:
	DirAccess.make_dir_recursive_absolute("res://assets/sprites/props/tokyo")

	_gen_neon_sign1()
	_gen_neon_sign2()
	_gen_vending_machine()
	_gen_lamppost()
	_gen_car()
	_gen_trash_can()
	_gen_manhole()
	_gen_billboard()
	_gen_barrier()
	_gen_ground_tokyo()

	print("All tokyo prop sprites generated!")

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
	var path = "res://assets/sprites/props/tokyo/" + name
	img.save_png(path)
	print("Saved: ", path)

# ==================== NEON SIGN 1 — pink/cyan ====================

func _gen_neon_sign1() -> void:
	var img = _img()
	var bg = Color(0.12, 0.1, 0.15)
	var frame = Color(0.3, 0.3, 0.35)
	var neon_pink = Color(1.0, 0.3, 0.6)
	var neon_cyan = Color(0.2, 0.9, 0.95)
	var glow_pink = Color(0.8, 0.2, 0.45, 0.6)
	var glow_cyan = Color(0.15, 0.7, 0.75, 0.5)

	# Background panel
	_fill(img, 6, 6, 20, 16, bg)
	# Frame
	_fill(img, 5, 5, 22, 1, frame)
	_fill(img, 5, 22, 22, 1, frame)
	_fill(img, 5, 5, 1, 18, frame)
	_fill(img, 26, 5, 1, 18, frame)

	# Neon letter shapes: "BAR" in pink
	# B
	_fill(img, 8, 8, 1, 5, neon_pink)
	_px(img, 9, 8, neon_pink)
	_px(img, 10, 9, neon_pink)
	_px(img, 9, 10, neon_pink)
	_px(img, 10, 11, neon_pink)
	_px(img, 9, 12, neon_pink)
	# A
	_px(img, 13, 12, neon_pink)
	_px(img, 14, 11, neon_pink)
	_px(img, 15, 10, neon_pink)
	_px(img, 16, 9, neon_pink)
	_px(img, 17, 10, neon_pink)
	_px(img, 18, 11, neon_pink)
	_px(img, 19, 12, neon_pink)
	_fill(img, 14, 11, 4, 1, neon_pink)
	# R
	_fill(img, 21, 8, 1, 5, neon_pink)
	_px(img, 22, 8, neon_pink)
	_px(img, 23, 9, neon_pink)
	_px(img, 22, 10, neon_pink)
	_px(img, 23, 11, neon_pink)
	_px(img, 23, 12, neon_pink)

	# Cyan decorative line below
	_fill(img, 8, 16, 16, 1, neon_cyan)
	_fill(img, 10, 18, 12, 1, neon_cyan)

	# Glow around neon
	for x in range(7, 25):
		for y in range(7, 14):
			if img.get_pixel(x, y).a == 0:
				_px(img, x, y, glow_pink)
	for x in range(8, 24):
		if img.get_pixel(x, 15).a == 0:
			_px(img, x, 15, glow_cyan)
		if img.get_pixel(x, 17).a == 0:
			_px(img, x, 17, glow_cyan)
		if img.get_pixel(x, 19).a == 0:
			_px(img, x, 19, glow_cyan)

	# Mount pole
	_fill(img, 15, 23, 2, 6, frame)

	_outline(img, Color(0.5, 0.15, 0.3))
	_save(img, "neon_sign1.png")

# ==================== NEON SIGN 2 — purple/green kanji ====================

func _gen_neon_sign2() -> void:
	var img = _img()
	var bg = Color(0.1, 0.08, 0.14)
	var frame = Color(0.28, 0.25, 0.35)
	var neon_purple = Color(0.7, 0.2, 0.9)
	var neon_green = Color(0.2, 0.95, 0.4)

	# Background panel
	_fill(img, 7, 4, 18, 20, bg)
	# Frame
	_fill(img, 6, 3, 20, 1, frame)
	_fill(img, 6, 24, 20, 1, frame)
	_fill(img, 6, 3, 1, 22, frame)
	_fill(img, 25, 3, 1, 22, frame)

	# Simplified kanji-like shapes in purple
	# Top character (simplified "fire" radical)
	_px(img, 16, 6, neon_purple)
	_px(img, 15, 7, neon_purple)
	_px(img, 17, 7, neon_purple)
	_px(img, 14, 8, neon_purple)
	_px(img, 18, 8, neon_purple)
	_px(img, 13, 9, neon_purple)
	_px(img, 19, 9, neon_purple)
	_fill(img, 12, 10, 9, 1, neon_purple)
	_px(img, 16, 8, neon_purple)
	_px(img, 16, 9, neon_purple)

	# Bottom character (horizontal strokes)
	_fill(img, 10, 14, 12, 1, neon_green)
	_fill(img, 12, 17, 8, 1, neon_green)
	_fill(img, 10, 20, 12, 1, neon_green)
	# Vertical stroke
	_fill(img, 16, 14, 1, 7, neon_green)

	# Mount pole
	_fill(img, 15, 25, 2, 5, frame)

	_outline(img, Color(0.35, 0.1, 0.45))
	_save(img, "neon_sign2.png")

# ==================== VENDING MACHINE ====================

func _gen_vending_machine() -> void:
	var img = _img()
	var body_col = Color(0.2, 0.35, 0.7)
	var body_dark = Color(0.15, 0.25, 0.55)
	var body_light = Color(0.3, 0.45, 0.8)
	var glass = Color(0.6, 0.75, 0.85, 0.8)
	var drink1 = Color(0.9, 0.2, 0.2)
	var drink2 = Color(0.2, 0.8, 0.3)
	var drink3 = Color(0.9, 0.7, 0.1)
	var light = Color(0.9, 0.9, 0.95)

	# Main body
	_fill(img, 8, 4, 16, 24, body_col)
	_fill(img, 8, 4, 3, 24, body_dark)
	_fill(img, 21, 4, 3, 24, body_light)

	# Top light strip
	_fill(img, 9, 5, 14, 2, light)

	# Glass display area
	_fill(img, 10, 8, 12, 10, glass)

	# Drink rows
	# Row 1
	_fill(img, 11, 9, 2, 4, drink1)
	_fill(img, 14, 9, 2, 4, drink2)
	_fill(img, 17, 9, 2, 4, drink3)
	# Row 2
	_fill(img, 11, 14, 2, 3, drink3)
	_fill(img, 14, 14, 2, 3, drink1)
	_fill(img, 17, 14, 2, 3, drink2)

	# Dispenser slot
	_fill(img, 12, 20, 8, 3, Color(0.1, 0.1, 0.12))
	_fill(img, 13, 21, 6, 1, Color(0.15, 0.15, 0.18))

	# Coin slot
	_fill(img, 21, 14, 2, 1, Color(0.3, 0.3, 0.32))
	_circle(img, 22, 16, 1, Color(0.5, 0.5, 0.52))

	# Ground
	_fill(img, 7, 28, 18, 2, Color(0.15, 0.15, 0.18))

	_outline(img, Color(0.08, 0.15, 0.35))
	_save(img, "vending_machine.png")

# ==================== LAMPPOST ====================

func _gen_lamppost() -> void:
	var img = _img()
	var pole_col = Color(0.35, 0.35, 0.38)
	var pole_light = Color(0.45, 0.45, 0.5)
	var lamp = Color(0.95, 0.92, 0.8)
	var lamp_glow = Color(0.95, 0.85, 0.5, 0.6)

	# Tall pole
	_fill(img, 15, 8, 2, 20, pole_col)
	_px(img, 16, 8, pole_light)

	# Base (wider)
	_fill(img, 13, 26, 6, 2, pole_col)
	_fill(img, 12, 28, 8, 2, Color(0.3, 0.3, 0.32))

	# Lamp head
	_fill(img, 11, 5, 10, 3, pole_col)
	_fill(img, 12, 4, 8, 1, pole_col)

	# Light panel
	_fill(img, 12, 6, 8, 2, lamp)

	# Glow effect
	_fill(img, 10, 8, 12, 2, lamp_glow)
	_px(img, 14, 10, lamp_glow)
	_px(img, 15, 10, lamp_glow)
	_px(img, 16, 10, lamp_glow)
	_px(img, 17, 10, lamp_glow)

	_outline(img, Color(0.18, 0.18, 0.2))
	_save(img, "lamppost.png")

# ==================== CAR ====================

func _gen_car() -> void:
	var img = _img()
	var body_col = Color(0.2, 0.5, 0.7)
	var body_dark = Color(0.15, 0.38, 0.55)
	var body_light = Color(0.3, 0.6, 0.8)
	var wheel_col = Color(0.15, 0.15, 0.18)
	var glass = Color(0.5, 0.7, 0.82, 0.8)
	var headlight = Color(0.95, 0.9, 0.6)

	# Car body (side view)
	_fill(img, 4, 16, 24, 6, body_col)
	_fill(img, 4, 16, 24, 2, body_light)
	_fill(img, 4, 20, 24, 2, body_dark)

	# Cabin/roof
	_fill(img, 10, 10, 12, 6, body_col)
	_fill(img, 11, 9, 10, 1, body_col)
	_fill(img, 10, 10, 12, 2, body_light)

	# Windows
	_fill(img, 11, 11, 4, 4, glass)
	_fill(img, 17, 11, 4, 4, glass)

	# Headlight (front)
	_fill(img, 26, 17, 2, 2, headlight)
	# Taillight
	_fill(img, 4, 17, 2, 2, Color(0.9, 0.15, 0.1))

	# Wheels
	_circle(img, 10, 23, 3, wheel_col)
	_circle(img, 10, 23, 1, Color(0.35, 0.35, 0.38))
	_circle(img, 22, 23, 3, wheel_col)
	_circle(img, 22, 23, 1, Color(0.35, 0.35, 0.38))

	# Neon underglow
	_fill(img, 6, 22, 20, 1, Color(0.2, 0.8, 0.9, 0.5))

	# Ground
	_fill(img, 3, 26, 26, 2, Color(0.15, 0.15, 0.18))

	_outline(img, Color(0.08, 0.25, 0.35))
	_save(img, "car.png")

# ==================== TRASH CAN ====================

func _gen_trash_can() -> void:
	var img = _img()
	var metal = Color(0.5, 0.52, 0.55)
	var metal_dark = Color(0.38, 0.4, 0.42)
	var metal_light = Color(0.62, 0.65, 0.68)
	var lid = Color(0.45, 0.48, 0.5)

	# Body (cylinder)
	_fill(img, 10, 12, 12, 14, metal)
	_fill(img, 10, 12, 3, 14, metal_dark)
	_fill(img, 19, 12, 3, 14, metal_light)

	# Lid
	_fill(img, 9, 10, 14, 2, lid)
	_fill(img, 10, 9, 12, 1, lid)
	# Handle
	_fill(img, 14, 8, 4, 1, metal_dark)
	_px(img, 14, 7, metal_dark)
	_px(img, 17, 7, metal_dark)

	# Ridges
	_fill(img, 10, 16, 12, 1, metal_dark)
	_fill(img, 10, 20, 12, 1, metal_dark)

	# Ground
	_fill(img, 9, 26, 14, 2, Color(0.15, 0.15, 0.18))

	_outline(img, Color(0.2, 0.2, 0.22))
	_save(img, "trash_can.png")

# ==================== MANHOLE ====================

func _gen_manhole() -> void:
	var img = _img()
	var cover = Color(0.38, 0.38, 0.4)
	var cover_dark = Color(0.28, 0.28, 0.3)
	var cover_light = Color(0.48, 0.48, 0.52)
	var road = Color(0.22, 0.22, 0.25)

	# Road surface around it
	_fill(img, 4, 10, 24, 16, road)

	# Manhole cover (oval/circle for perspective)
	_circle(img, 16, 18, 8, cover)
	_circle(img, 16, 18, 7, cover_dark)
	_circle(img, 16, 18, 6, cover)

	# Cross pattern on cover
	_fill(img, 15, 12, 2, 12, cover_dark)
	_fill(img, 10, 17, 12, 2, cover_dark)

	# Highlight (top-right)
	_px(img, 18, 13, cover_light)
	_px(img, 19, 14, cover_light)
	_px(img, 20, 15, cover_light)

	# Rim
	_circle(img, 16, 18, 8, cover_light)
	_circle(img, 16, 18, 7, cover)
	# Redraw inner
	_circle(img, 16, 18, 6, cover)
	_fill(img, 15, 12, 2, 12, cover_dark)
	_fill(img, 10, 17, 12, 2, cover_dark)

	_outline(img, Color(0.15, 0.15, 0.18))
	_save(img, "manhole.png")

# ==================== BILLBOARD ====================

func _gen_billboard() -> void:
	var img = _img()
	var frame = Color(0.3, 0.3, 0.35)
	var screen_bg = Color(0.08, 0.05, 0.12)
	var holo1 = Color(0.3, 0.8, 0.95, 0.8)
	var holo2 = Color(0.9, 0.3, 0.7, 0.7)
	var holo3 = Color(0.4, 0.95, 0.5, 0.6)

	# Support poles
	_fill(img, 10, 18, 2, 10, frame)
	_fill(img, 20, 18, 2, 10, frame)

	# Screen frame
	_fill(img, 4, 2, 24, 16, frame)
	# Screen
	_fill(img, 5, 3, 22, 14, screen_bg)

	# Holographic content (scan lines + shapes)
	# Horizontal scan lines
	for y_line in [5, 8, 11, 14]:
		for x_line in range(6, 26, 2):
			_px(img, x_line, y_line, holo1)

	# Abstract holographic shape (triangle)
	_px(img, 16, 5, holo2)
	_px(img, 15, 6, holo2)
	_px(img, 17, 6, holo2)
	_px(img, 14, 7, holo2)
	_px(img, 18, 7, holo2)
	_fill(img, 13, 8, 7, 1, holo2)

	# Text-like dots
	_fill(img, 8, 11, 6, 1, holo3)
	_fill(img, 8, 13, 8, 1, holo3)
	_fill(img, 18, 11, 5, 1, holo3)

	# Glitch effect (offset pixels)
	_px(img, 7, 6, holo1)
	_px(img, 24, 9, holo2)
	_px(img, 10, 14, holo3)

	# Ground
	_fill(img, 8, 28, 16, 2, Color(0.15, 0.15, 0.18))

	_outline(img, Color(0.15, 0.15, 0.2))
	_save(img, "billboard.png")

# ==================== BARRIER ====================

func _gen_barrier() -> void:
	var img = _img()
	var orange = Color(0.95, 0.5, 0.1)
	var orange_dark = Color(0.75, 0.38, 0.08)
	var white = Color(0.9, 0.9, 0.92)
	var white_dark = Color(0.75, 0.75, 0.78)
	var post = Color(0.5, 0.5, 0.55)

	# Left post
	_fill(img, 6, 10, 3, 16, post)
	# Right post
	_fill(img, 23, 10, 3, 16, post)

	# Barrier beam (striped orange/white)
	_fill(img, 6, 12, 20, 4, orange)
	# White stripes (diagonal effect)
	_fill(img, 9, 12, 3, 4, white)
	_fill(img, 15, 12, 3, 4, white)
	_fill(img, 21, 12, 3, 4, white)

	# Shadow on stripes
	_fill(img, 9, 15, 3, 1, white_dark)
	_fill(img, 15, 15, 3, 1, white_dark)
	_fill(img, 21, 15, 3, 1, white_dark)
	_fill(img, 6, 15, 3, 1, orange_dark)
	_fill(img, 12, 15, 3, 1, orange_dark)
	_fill(img, 18, 15, 3, 1, orange_dark)

	# Reflector dots
	_px(img, 7, 13, Color(0.95, 0.3, 0.15))
	_px(img, 24, 13, Color(0.95, 0.3, 0.15))

	# Base feet
	_fill(img, 4, 26, 8, 2, post)
	_fill(img, 20, 26, 8, 2, post)

	_outline(img, Color(0.4, 0.25, 0.05))
	_save(img, "barrier.png")

# ==================== GROUND TILE ====================

func _gen_ground_tokyo() -> void:
	# 64x64 dark gray asphalt with road markings
	var img = _img(G)
	var asphalt = Color(0.18, 0.18, 0.2)
	var asphalt2 = Color(0.2, 0.2, 0.22)
	var asphalt_dark = Color(0.14, 0.14, 0.16)
	var marking = Color(0.85, 0.85, 0.8)
	var marking_dim = Color(0.6, 0.6, 0.55)
	var crack = Color(0.12, 0.12, 0.13)

	# Base fill: asphalt
	_fill(img, 0, 0, G, G, asphalt)

	# Asphalt texture variation
	var rng = RandomNumberGenerator.new()
	rng.seed = 303

	for i in range(120):
		var px_x = rng.randi_range(0, G - 1)
		var px_y = rng.randi_range(0, G - 1)
		_px(img, px_x, px_y, asphalt2)

	for i in range(80):
		var px_x = rng.randi_range(0, G - 1)
		var px_y = rng.randi_range(0, G - 1)
		_px(img, px_x, px_y, asphalt_dark)

	# Road lane marking (dashed center line)
	for seg in range(0, G, 12):
		_fill(img, 31, seg, 2, 6, marking)

	# Crosswalk stripes (bottom area)
	for stripe_x in range(8, 56, 6):
		_fill(img, stripe_x, 54, 4, 8, marking_dim)

	# Small cracks
	_px(img, 15, 20, crack)
	_px(img, 16, 21, crack)
	_px(img, 17, 22, crack)
	_px(img, 18, 22, crack)

	_px(img, 42, 35, crack)
	_px(img, 43, 36, crack)
	_px(img, 43, 37, crack)

	# Edge tiling
	for i in range(G):
		if rng.randi_range(0, 3) == 0:
			_px(img, 0, i, asphalt2)
			_px(img, G - 1, i, asphalt2)
		if rng.randi_range(0, 3) == 0:
			_px(img, i, 0, asphalt2)
			_px(img, i, G - 1, asphalt2)

	_save(img, "ground_tokyo.png")
