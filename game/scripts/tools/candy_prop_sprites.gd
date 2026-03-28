extends SceneTree

## Generates 32x32 pixel art sprites for candy stage decoration props,
## plus a 64x64 tiled ground texture.
## Run: godot --headless --script res://scripts/tools/candy_prop_sprites.gd

const S := 32  # Prop sprite size
const G := 64  # Ground tile size

func _init() -> void:
	_generate_all()
	quit()

func _generate_all() -> void:
	DirAccess.make_dir_recursive_absolute("res://assets/sprites/props/candy")

	_gen_ground_candy()
	_gen_candy_cane()
	_gen_lollipop()
	_gen_gummy_bear()
	_gen_cupcake()
	_gen_ice_cream()
	_gen_chocolate()
	_gen_cotton_candy()
	_gen_donut()
	_gen_cookie()

	print("All candy prop sprites generated!")

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
	var path = "res://assets/sprites/props/candy/" + name
	img.save_png(path)
	print("Saved: ", path)

# ==================== GROUND ====================

func _gen_ground_candy() -> void:
	# 64x64 pink/white checkered candy floor with sprinkles
	var img = _img(G)
	var pink = Color(0.9, 0.6, 0.7)
	var white = Color(0.95, 0.9, 0.92)
	var pink_dark = Color(0.8, 0.5, 0.6)
	var sprinkle_r = Color(0.9, 0.2, 0.2)
	var sprinkle_g = Color(0.2, 0.8, 0.3)
	var sprinkle_b = Color(0.2, 0.4, 0.9)
	var sprinkle_y = Color(0.95, 0.85, 0.2)

	# Checkerboard pattern (8x8 tiles)
	for tx in range(8):
		for ty in range(8):
			var col = pink if (tx + ty) % 2 == 0 else white
			_fill(img, tx * 8, ty * 8, 8, 8, col)

	# Subtle grid lines
	for i in range(0, G, 8):
		_fill(img, i, 0, 1, G, pink_dark)
		_fill(img, 0, i, G, 1, pink_dark)

	# Sprinkles scattered
	var rng = RandomNumberGenerator.new()
	rng.seed = 99
	var sprinkle_colors = [sprinkle_r, sprinkle_g, sprinkle_b, sprinkle_y]
	for i in range(30):
		var sx = rng.randi_range(1, G - 2)
		var sy = rng.randi_range(1, G - 2)
		var sc = sprinkle_colors[rng.randi_range(0, 3)]
		# Each sprinkle is 2px long (horizontal or vertical)
		if rng.randi_range(0, 1) == 0:
			_px(img, sx, sy, sc)
			_px(img, sx + 1, sy, sc)
		else:
			_px(img, sx, sy, sc)
			_px(img, sx, sy + 1, sc)

	_save(img, "ground_candy.png")

# ==================== CANDY CANE ====================

func _gen_candy_cane() -> void:
	# Red and white striped candy cane
	var img = _img()
	var red = Color(0.85, 0.15, 0.15)
	var white = Color(0.95, 0.92, 0.92)
	var red_dark = Color(0.65, 0.1, 0.1)

	# Hook (top curve)
	_fill(img, 14, 3, 6, 2, white)
	_fill(img, 12, 5, 2, 2, red)
	_fill(img, 14, 5, 2, 2, white)
	_fill(img, 16, 5, 2, 2, red)
	_fill(img, 18, 5, 2, 2, white)
	_fill(img, 20, 3, 2, 4, red)
	_fill(img, 20, 3, 2, 2, white)

	# Curve connection
	_fill(img, 11, 7, 2, 2, white)
	_fill(img, 10, 9, 2, 2, red)

	# Straight shaft (vertical, alternating stripes)
	var y_pos = 9
	var stripe_on = true
	while y_pos < 29:
		var col = red if stripe_on else white
		_fill(img, 14, y_pos, 4, 2, col)
		y_pos += 2
		stripe_on = not stripe_on

	# Connection from hook to shaft
	_fill(img, 11, 7, 3, 2, white)
	_fill(img, 12, 9, 2, 2, red)
	_fill(img, 13, 9, 2, 2, white)

	# Shadow on left side
	_px(img, 14, 11, red_dark)
	_px(img, 14, 15, red_dark)
	_px(img, 14, 19, red_dark)
	_px(img, 14, 23, red_dark)
	_px(img, 14, 27, red_dark)

	_outline(img, Color(0.3, 0.05, 0.05))
	_save(img, "candy_cane.png")

# ==================== LOLLIPOP ====================

func _gen_lollipop() -> void:
	# Colorful spiral lollipop on a stick
	var img = _img()
	var stick = Color(0.85, 0.8, 0.7)
	var stick_dark = Color(0.7, 0.65, 0.55)
	var red = Color(0.9, 0.2, 0.2)
	var yellow = Color(0.95, 0.85, 0.2)
	var green = Color(0.2, 0.8, 0.3)
	var blue = Color(0.2, 0.4, 0.9)
	var white = Color(0.95, 0.95, 0.95)

	# Stick
	_fill(img, 15, 18, 2, 12, stick)
	_px(img, 15, 18, stick_dark)

	# Candy circle base
	_circle(img, 16, 10, 8, red)
	_circle(img, 16, 10, 6, yellow)
	_circle(img, 16, 10, 4, green)
	_circle(img, 16, 10, 2, blue)
	_px(img, 16, 10, white)

	# Spiral lines (overwrites to create spiral effect)
	# Diagonal spiral strokes
	for i in range(7):
		_px(img, 16 + i, 10 - i, white)
		_px(img, 16 - i, 10 + i, white)
	for i in range(5):
		_px(img, 16 + i, 10 + i, white)
		_px(img, 16 - i, 10 - i, white)

	# Highlight
	_px(img, 13, 7, Color(1.0, 1.0, 1.0, 0.8))
	_px(img, 14, 6, Color(1.0, 1.0, 1.0, 0.8))

	_outline(img, Color(0.2, 0.05, 0.05))
	_save(img, "lollipop.png")

# ==================== GUMMY BEAR ====================

func _gen_gummy_bear() -> void:
	# Translucent colored gummy bear
	var img = _img()
	var body = Color(0.8, 0.2, 0.25, 0.85)
	var body_light = Color(0.9, 0.4, 0.4, 0.9)
	var body_dark = Color(0.6, 0.12, 0.15, 0.85)
	var eye = Color(0.15, 0.1, 0.1)
	var shine = Color(1.0, 0.8, 0.8, 0.6)

	# Ears
	_fill(img, 11, 4, 3, 3, body)
	_fill(img, 18, 4, 3, 3, body)

	# Head
	_fill(img, 10, 6, 12, 8, body)
	_fill(img, 12, 5, 8, 1, body)

	# Head highlight
	_fill(img, 18, 6, 3, 3, body_light)

	# Eyes
	_px(img, 13, 9, eye)
	_px(img, 18, 9, eye)

	# Mouth
	_px(img, 15, 11, body_dark)
	_px(img, 16, 11, body_dark)

	# Body (torso)
	_fill(img, 10, 14, 12, 8, body)
	_fill(img, 10, 14, 2, 8, body_dark)
	_fill(img, 20, 14, 2, 8, body_light)

	# Belly highlight
	_fill(img, 14, 16, 4, 4, body_light)

	# Arms
	_fill(img, 7, 14, 3, 6, body)
	_fill(img, 22, 14, 3, 6, body)
	_fill(img, 7, 14, 1, 6, body_dark)
	_fill(img, 24, 14, 1, 6, body_light)

	# Legs
	_fill(img, 10, 22, 5, 5, body)
	_fill(img, 17, 22, 5, 5, body)
	_fill(img, 10, 22, 1, 5, body_dark)
	_fill(img, 21, 22, 1, 5, body_light)

	# Feet
	_fill(img, 9, 26, 6, 2, body_dark)
	_fill(img, 17, 26, 6, 2, body_dark)

	# Shine/gloss
	_px(img, 13, 7, shine)
	_px(img, 14, 7, shine)
	_px(img, 13, 15, shine)

	_outline(img, Color(0.3, 0.08, 0.1))
	_save(img, "gummy_bear.png")

# ==================== CUPCAKE ====================

func _gen_cupcake() -> void:
	# Frosted cupcake with cherry on top
	var img = _img()
	var wrapper = Color(0.7, 0.5, 0.15)
	var wrapper_dark = Color(0.55, 0.38, 0.1)
	var cake = Color(0.75, 0.6, 0.4)
	var frost = Color(0.9, 0.5, 0.7)
	var frost_light = Color(0.95, 0.7, 0.8)
	var frost_dark = Color(0.75, 0.35, 0.55)
	var cherry = Color(0.85, 0.1, 0.15)
	var cherry_dark = Color(0.6, 0.05, 0.1)
	var stem = Color(0.2, 0.5, 0.15)

	# Cherry stem
	_px(img, 16, 3, stem)
	_px(img, 16, 4, stem)
	_px(img, 17, 2, stem)

	# Cherry
	_circle(img, 16, 6, 2, cherry)
	_px(img, 15, 5, cherry_dark)
	_px(img, 17, 5, Color(0.95, 0.3, 0.3)) # highlight

	# Frosting (swirly mound)
	_fill(img, 10, 9, 12, 3, frost)
	_fill(img, 9, 11, 14, 2, frost)
	_fill(img, 11, 8, 10, 1, frost)
	_fill(img, 13, 7, 6, 1, frost_light)
	_fill(img, 9, 12, 2, 1, frost_dark)
	_fill(img, 21, 12, 2, 1, frost_dark)
	# Frosting swirl details
	_px(img, 12, 10, frost_light)
	_px(img, 15, 9, frost_light)
	_px(img, 18, 10, frost_light)
	_px(img, 14, 11, frost_dark)
	_px(img, 17, 11, frost_dark)

	# Cake body
	_fill(img, 10, 13, 12, 6, cake)

	# Wrapper (fluted)
	_fill(img, 9, 16, 14, 8, wrapper)
	_fill(img, 8, 18, 1, 5, wrapper_dark)
	_fill(img, 23, 18, 1, 5, wrapper_dark)
	# Wrapper ridges
	for wx in range(9, 23, 2):
		_fill(img, wx, 16, 1, 8, wrapper_dark)

	# Base
	_fill(img, 8, 24, 16, 2, wrapper_dark)

	# Sprinkles on frosting
	_px(img, 11, 10, Color(0.2, 0.4, 0.9))
	_px(img, 14, 9, Color(0.9, 0.85, 0.2))
	_px(img, 19, 10, Color(0.2, 0.8, 0.3))
	_px(img, 17, 8, Color(0.9, 0.2, 0.2))

	_outline(img, Color(0.25, 0.15, 0.05))
	_save(img, "cupcake.png")

# ==================== ICE CREAM ====================

func _gen_ice_cream() -> void:
	# Ice cream cone with two scoops
	var img = _img()
	var cone = Color(0.75, 0.55, 0.25)
	var cone_dark = Color(0.6, 0.42, 0.18)
	var cone_light = Color(0.85, 0.65, 0.35)
	var scoop1 = Color(0.95, 0.75, 0.8)  # strawberry
	var scoop1_dark = Color(0.8, 0.55, 0.6)
	var scoop2 = Color(0.85, 0.7, 0.4)  # vanilla
	var scoop2_dark = Color(0.7, 0.55, 0.3)
	var shine = Color(1.0, 1.0, 1.0, 0.5)

	# Cone (triangle, wider at top)
	_fill(img, 13, 18, 6, 2, cone)
	_fill(img, 14, 20, 4, 2, cone)
	_fill(img, 14, 22, 4, 2, cone)
	_fill(img, 15, 24, 2, 2, cone)
	_fill(img, 15, 26, 2, 2, cone)
	_px(img, 15, 28, cone)

	# Cone cross-hatch pattern
	_px(img, 14, 19, cone_dark)
	_px(img, 16, 19, cone_dark)
	_px(img, 15, 21, cone_dark)
	_px(img, 17, 21, cone_dark)
	_px(img, 15, 23, cone_dark)
	_px(img, 14, 20, cone_light)
	_px(img, 16, 22, cone_light)

	# Bottom scoop (vanilla)
	_circle(img, 16, 14, 5, scoop2)
	_fill(img, 12, 14, 3, 4, scoop2_dark)
	_px(img, 18, 11, shine)
	_px(img, 19, 12, shine)

	# Top scoop (strawberry)
	_circle(img, 16, 8, 5, scoop1)
	_fill(img, 12, 8, 3, 4, scoop1_dark)
	_px(img, 18, 5, shine)
	_px(img, 19, 6, shine)

	_outline(img, Color(0.25, 0.15, 0.08))
	_save(img, "ice_cream.png")

# ==================== CHOCOLATE ====================

func _gen_chocolate() -> void:
	# Chocolate bar piece (few squares)
	var img = _img()
	var choc = Color(0.35, 0.18, 0.08)
	var choc_dark = Color(0.25, 0.12, 0.05)
	var choc_light = Color(0.48, 0.28, 0.14)
	var shine = Color(0.55, 0.38, 0.2)

	# Main bar shape
	_fill(img, 6, 8, 20, 16, choc)

	# Left shadow
	_fill(img, 6, 8, 2, 16, choc_dark)
	# Right highlight
	_fill(img, 24, 8, 2, 16, choc_light)
	# Top highlight
	_fill(img, 6, 8, 20, 2, choc_light)
	# Bottom shadow
	_fill(img, 6, 22, 20, 2, choc_dark)

	# Square divisions (grid lines)
	_fill(img, 6, 14, 20, 1, choc_dark)
	_fill(img, 6, 18, 20, 1, choc_dark)
	_fill(img, 12, 8, 1, 16, choc_dark)
	_fill(img, 19, 8, 1, 16, choc_dark)

	# Shine spots on squares
	_px(img, 9, 10, shine)
	_px(img, 10, 10, shine)
	_px(img, 15, 10, shine)
	_px(img, 16, 10, shine)
	_px(img, 22, 10, shine)

	# Broken edge (right side, jagged)
	_px(img, 25, 10, Color(0, 0, 0, 0))
	_px(img, 25, 11, Color(0, 0, 0, 0))
	_px(img, 25, 14, Color(0, 0, 0, 0))
	_px(img, 25, 15, Color(0, 0, 0, 0))
	_px(img, 24, 12, Color(0, 0, 0, 0))
	_px(img, 24, 19, Color(0, 0, 0, 0))
	_px(img, 25, 20, Color(0, 0, 0, 0))

	_outline(img, Color(0.12, 0.06, 0.02))
	_save(img, "chocolate.png")

# ==================== COTTON CANDY ====================

func _gen_cotton_candy() -> void:
	# Pink fluffy cotton candy on a stick
	var img = _img()
	var pink = Color(0.95, 0.6, 0.75)
	var pink_light = Color(1.0, 0.8, 0.88)
	var pink_dark = Color(0.8, 0.45, 0.6)
	var stick = Color(0.85, 0.8, 0.7)
	var stick_dark = Color(0.7, 0.65, 0.55)

	# Stick
	_fill(img, 15, 20, 2, 10, stick)
	_px(img, 15, 20, stick_dark)

	# Main fluffy cloud shape (irregular)
	_circle(img, 16, 10, 8, pink)
	_circle(img, 13, 8, 5, pink)
	_circle(img, 19, 8, 5, pink)
	_circle(img, 16, 6, 5, pink)
	_circle(img, 14, 13, 4, pink)
	_circle(img, 18, 13, 4, pink)

	# Lighter fluffy highlights
	_circle(img, 14, 7, 3, pink_light)
	_circle(img, 19, 6, 2, pink_light)
	_circle(img, 12, 11, 2, pink_light)

	# Darker shadow areas
	_circle(img, 18, 13, 3, pink_dark)
	_circle(img, 13, 14, 2, pink_dark)
	_fill(img, 10, 15, 12, 2, pink_dark)

	# Wispy edges
	_px(img, 7, 9, pink)
	_px(img, 24, 9, pink)
	_px(img, 8, 6, pink)
	_px(img, 23, 7, pink)
	_px(img, 16, 2, pink_light)
	_px(img, 15, 1, pink_light)

	_outline(img, Color(0.35, 0.2, 0.28))
	_save(img, "cotton_candy.png")

# ==================== DONUT ====================

func _gen_donut() -> void:
	# Frosted donut with sprinkles
	var img = _img()
	var dough = Color(0.75, 0.55, 0.3)
	var dough_dark = Color(0.6, 0.42, 0.2)
	var frost = Color(0.9, 0.45, 0.55)
	var frost_light = Color(0.95, 0.6, 0.7)
	var frost_dark = Color(0.75, 0.3, 0.4)

	# Main donut shape (torus from top view)
	_circle(img, 16, 16, 11, dough)
	_circle(img, 16, 16, 4, Color(0, 0, 0, 0)) # hole

	# Darker bottom edge
	for x in range(5, 27):
		for y in range(18, 28):
			if img.get_pixel(x, y).a > 0:
				var existing = img.get_pixel(x, y)
				if existing == dough:
					_px(img, x, y, dough_dark)

	# Frosting on top half
	_circle(img, 16, 14, 10, frost)
	_circle(img, 16, 14, 5, Color(0, 0, 0, 0)) # frosting hole

	# Clean up frosting that goes beyond donut
	for x in range(S):
		for y in range(S):
			var dist_sq = (x - 16) * (x - 16) + (y - 16) * (y - 16)
			if dist_sq > 11 * 11:
				if img.get_pixel(x, y) == frost or img.get_pixel(x, y) == frost_light:
					img.set_pixel(x, y, Color(0, 0, 0, 0))

	# Frosting drips
	_px(img, 8, 20, frost)
	_px(img, 9, 21, frost)
	_px(img, 22, 19, frost)
	_px(img, 23, 20, frost)

	# Frosting highlight
	_fill(img, 12, 8, 4, 2, frost_light)
	_fill(img, 18, 10, 3, 2, frost_light)

	# Frosting shadow
	_fill(img, 10, 16, 3, 2, frost_dark)
	_fill(img, 19, 15, 3, 2, frost_dark)

	# Sprinkles on frosting
	_px(img, 10, 10, Color(0.2, 0.4, 0.9))
	_px(img, 11, 10, Color(0.2, 0.4, 0.9))
	_px(img, 14, 7, Color(0.9, 0.85, 0.2))
	_px(img, 14, 8, Color(0.9, 0.85, 0.2))
	_px(img, 20, 8, Color(0.2, 0.8, 0.3))
	_px(img, 20, 9, Color(0.2, 0.8, 0.3))
	_px(img, 18, 6, Color(0.9, 0.2, 0.2))
	_px(img, 12, 12, Color(0.9, 0.5, 0.1))
	_px(img, 13, 12, Color(0.9, 0.5, 0.1))
	_px(img, 22, 12, Color(0.6, 0.2, 0.8))
	_px(img, 22, 13, Color(0.6, 0.2, 0.8))

	_outline(img, Color(0.25, 0.15, 0.08))
	_save(img, "donut.png")

# ==================== COOKIE ====================

func _gen_cookie() -> void:
	# Brown cookie with chocolate chips
	var img = _img()
	var cookie = Color(0.72, 0.52, 0.28)
	var cookie_dark = Color(0.58, 0.4, 0.2)
	var cookie_light = Color(0.82, 0.62, 0.38)
	var chip = Color(0.3, 0.15, 0.06)
	var chip_light = Color(0.4, 0.22, 0.1)

	# Main cookie circle
	_circle(img, 16, 16, 10, cookie)

	# Edge darkening
	for x in range(S):
		for y in range(S):
			var dist_sq = (x - 16) * (x - 16) + (y - 16) * (y - 16)
			if dist_sq > 8 * 8 and dist_sq <= 10 * 10:
				if img.get_pixel(x, y).a > 0:
					_px(img, x, y, cookie_dark)

	# Top highlight
	_circle(img, 14, 13, 4, cookie_light)

	# Bumpy edge (irregular cookie shape)
	_px(img, 6, 14, cookie)
	_px(img, 26, 14, cookie)
	_px(img, 16, 5, cookie)
	_px(img, 14, 26, cookie)
	_px(img, 7, 10, cookie_dark)
	_px(img, 24, 20, cookie_dark)

	# Chocolate chips
	_fill(img, 11, 11, 2, 2, chip)
	_px(img, 12, 11, chip_light) # highlight
	_fill(img, 17, 9, 2, 2, chip)
	_px(img, 18, 9, chip_light)
	_fill(img, 14, 15, 2, 2, chip)
	_px(img, 15, 15, chip_light)
	_fill(img, 19, 14, 2, 2, chip)
	_px(img, 20, 14, chip_light)
	_fill(img, 12, 19, 2, 2, chip)
	_px(img, 13, 19, chip_light)
	_fill(img, 18, 18, 2, 2, chip)
	_px(img, 19, 18, chip_light)
	_fill(img, 15, 22, 2, 2, chip)
	_px(img, 16, 22, chip_light)

	# Crumb texture
	_px(img, 10, 16, cookie_dark)
	_px(img, 21, 12, cookie_dark)
	_px(img, 16, 20, cookie_dark)
	_px(img, 13, 13, cookie_light)
	_px(img, 20, 17, cookie_light)

	_outline(img, Color(0.22, 0.14, 0.06))
	_save(img, "cookie.png")
