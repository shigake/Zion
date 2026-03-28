extends SceneTree

## Generates 32x32 pixel art sprites for farm stage decoration props,
## plus a 64x64 tiled ground texture.
## Run: godot --headless --script res://scripts/tools/farm_prop_sprites.gd

const S := 32  # Prop sprite size
const G := 64  # Ground tile size

func _init() -> void:
	_generate_all()
	quit()

func _generate_all() -> void:
	DirAccess.make_dir_recursive_absolute("res://assets/sprites/props/farm")

	_gen_hay_bale()
	_gen_corn()
	_gen_fence()
	_gen_scarecrow()
	_gen_silo()
	_gen_windmill()
	_gen_tractor()
	_gen_barrel()
	_gen_wheat()
	_gen_ground_farm()

	print("All farm prop sprites generated!")

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
	var path = "res://assets/sprites/props/farm/" + name
	img.save_png(path)
	print("Saved: ", path)

# ==================== HAY BALE ====================

func _gen_hay_bale() -> void:
	var img = _img()
	var hay = Color(0.82, 0.7, 0.3)
	var hay_light = Color(0.9, 0.8, 0.4)
	var hay_dark = Color(0.65, 0.55, 0.22)
	var band = Color(0.5, 0.35, 0.15)

	# Main bale body (rectangular)
	_fill(img, 6, 12, 20, 14, hay)
	# Top highlight
	_fill(img, 6, 12, 20, 3, hay_light)
	# Bottom shadow
	_fill(img, 6, 23, 20, 3, hay_dark)
	# Left shadow
	_fill(img, 6, 12, 3, 14, hay_dark)
	# Right highlight
	_fill(img, 23, 12, 3, 14, hay_light)

	# Binding bands
	_fill(img, 6, 16, 20, 1, band)
	_fill(img, 6, 21, 20, 1, band)

	# Hay texture lines
	_px(img, 10, 14, hay_dark)
	_px(img, 15, 13, hay_dark)
	_px(img, 20, 15, hay_dark)
	_px(img, 12, 19, hay_dark)
	_px(img, 18, 18, hay_dark)
	_px(img, 22, 20, hay_dark)

	# Ground
	_fill(img, 5, 26, 22, 2, Color(0.35, 0.28, 0.14))
	_fill(img, 6, 28, 20, 2, Color(0.3, 0.24, 0.12))

	_outline(img, Color(0.35, 0.28, 0.1))
	_save(img, "hay_bale.png")

# ==================== CORN ====================

func _gen_corn() -> void:
	var img = _img()
	var stalk = Color(0.25, 0.5, 0.15)
	var stalk_dark = Color(0.18, 0.38, 0.1)
	var ear = Color(0.85, 0.78, 0.3)
	var ear_dark = Color(0.7, 0.62, 0.22)
	var silk = Color(0.7, 0.55, 0.25)
	var leaf_col = Color(0.3, 0.55, 0.18)

	# Main stalk
	_fill(img, 15, 8, 2, 20, stalk)
	_px(img, 16, 8, stalk_dark)

	# Leaves
	# Left leaf
	_px(img, 14, 14, leaf_col)
	_px(img, 13, 13, leaf_col)
	_px(img, 12, 13, leaf_col)
	_px(img, 11, 14, leaf_col)
	_px(img, 10, 15, leaf_col)
	# Right leaf
	_px(img, 17, 18, leaf_col)
	_px(img, 18, 17, leaf_col)
	_px(img, 19, 17, leaf_col)
	_px(img, 20, 18, leaf_col)
	_px(img, 21, 19, leaf_col)

	# Corn ear (left side)
	_fill(img, 11, 16, 3, 5, ear)
	_fill(img, 11, 19, 3, 2, ear_dark)
	# Silk on top
	_px(img, 11, 15, silk)
	_px(img, 12, 14, silk)
	_px(img, 10, 15, silk)

	# Top tassel
	_px(img, 15, 7, stalk)
	_px(img, 14, 6, silk)
	_px(img, 16, 5, silk)
	_px(img, 15, 4, silk)
	_px(img, 13, 5, silk)
	_px(img, 17, 6, silk)

	# Base
	_fill(img, 13, 28, 6, 2, Color(0.3, 0.25, 0.12))

	_outline(img, Color(0.1, 0.25, 0.05))
	_save(img, "corn.png")

# ==================== FENCE ====================

func _gen_fence() -> void:
	var img = _img()
	var wood = Color(0.55, 0.38, 0.2)
	var wood_light = Color(0.65, 0.48, 0.28)
	var wood_dark = Color(0.4, 0.28, 0.14)

	# Left post
	_fill(img, 4, 8, 3, 18, wood)
	_fill(img, 5, 8, 2, 18, wood_light)
	# Pointed top
	_px(img, 5, 7, wood)
	_px(img, 5, 6, wood_light)

	# Right post
	_fill(img, 25, 8, 3, 18, wood)
	_fill(img, 26, 8, 2, 18, wood_light)
	# Pointed top
	_px(img, 26, 7, wood)
	_px(img, 26, 6, wood_light)

	# Horizontal rails
	_fill(img, 4, 12, 24, 2, wood)
	_fill(img, 4, 12, 24, 1, wood_light)
	_fill(img, 4, 20, 24, 2, wood)
	_fill(img, 4, 20, 24, 1, wood_light)

	# Wood grain details
	_px(img, 10, 12, wood_dark)
	_px(img, 18, 12, wood_dark)
	_px(img, 14, 20, wood_dark)
	_px(img, 22, 20, wood_dark)

	# Ground
	_fill(img, 3, 26, 26, 2, Color(0.35, 0.28, 0.14))

	_outline(img, Color(0.25, 0.18, 0.08))
	_save(img, "fence.png")

# ==================== SCARECROW ====================

func _gen_scarecrow() -> void:
	var img = _img()
	var shirt = Color(0.3, 0.45, 0.65)
	var shirt_dark = Color(0.22, 0.35, 0.5)
	var pants = Color(0.5, 0.38, 0.2)
	var hat = Color(0.45, 0.3, 0.15)
	var hat_dark = Color(0.35, 0.22, 0.1)
	var face = Color(0.82, 0.72, 0.5)
	var straw = Color(0.8, 0.7, 0.35)
	var pole = Color(0.4, 0.28, 0.15)

	# Pole
	_fill(img, 15, 12, 2, 18, pole)

	# Hat
	_fill(img, 10, 4, 12, 3, hat)
	_fill(img, 12, 2, 8, 2, hat)
	_fill(img, 13, 1, 6, 1, hat_dark)
	_fill(img, 10, 6, 12, 1, hat_dark)

	# Face
	_fill(img, 12, 7, 8, 5, face)
	# Eyes (X shaped)
	_px(img, 14, 9, Color(0.1, 0.1, 0.1))
	_px(img, 13, 8, Color(0.1, 0.1, 0.1))
	_px(img, 13, 10, Color(0.1, 0.1, 0.1))
	_px(img, 18, 9, Color(0.1, 0.1, 0.1))
	_px(img, 17, 8, Color(0.1, 0.1, 0.1))
	_px(img, 17, 10, Color(0.1, 0.1, 0.1))
	# Mouth
	_fill(img, 14, 11, 4, 1, Color(0.1, 0.1, 0.1))

	# Shirt body
	_fill(img, 11, 13, 10, 6, shirt)
	_fill(img, 11, 13, 3, 6, shirt_dark)

	# Arms (horizontal)
	_fill(img, 4, 14, 7, 2, shirt)
	_fill(img, 21, 14, 7, 2, shirt)

	# Straw sticking out
	_px(img, 3, 13, straw)
	_px(img, 2, 14, straw)
	_px(img, 28, 13, straw)
	_px(img, 29, 14, straw)
	_px(img, 11, 12, straw)
	_px(img, 20, 12, straw)

	# Patches
	_fill(img, 13, 15, 2, 2, Color(0.7, 0.3, 0.15))
	_fill(img, 18, 16, 2, 2, Color(0.2, 0.5, 0.2))

	# Pants
	_fill(img, 12, 19, 8, 4, pants)

	# Ground
	_fill(img, 13, 28, 6, 2, Color(0.3, 0.25, 0.12))

	_outline(img, Color(0.15, 0.12, 0.06))
	_save(img, "scarecrow.png")

# ==================== SILO ====================

func _gen_silo() -> void:
	var img = _img()
	var body = Color(0.7, 0.25, 0.2)
	var body_light = Color(0.8, 0.35, 0.28)
	var body_dark = Color(0.55, 0.18, 0.14)
	var roof = Color(0.5, 0.5, 0.52)
	var roof_dark = Color(0.38, 0.38, 0.4)

	# Silo body (tall cylinder)
	_fill(img, 10, 10, 12, 16, body)
	_fill(img, 10, 10, 3, 16, body_dark)
	_fill(img, 19, 10, 3, 16, body_light)

	# Roof (dome)
	_fill(img, 9, 8, 14, 2, roof)
	_fill(img, 10, 6, 12, 2, roof)
	_fill(img, 12, 5, 8, 1, roof)
	_fill(img, 13, 4, 6, 1, roof)
	_fill(img, 14, 3, 4, 1, roof_dark)
	_px(img, 15, 2, roof_dark)
	_px(img, 16, 2, roof_dark)

	# Metal bands
	_fill(img, 10, 14, 12, 1, roof)
	_fill(img, 10, 20, 12, 1, roof)

	# Door at base
	_fill(img, 13, 22, 6, 4, body_dark)
	_fill(img, 14, 22, 4, 3, Color(0.3, 0.1, 0.08))

	# Ground
	_fill(img, 8, 26, 16, 2, Color(0.35, 0.28, 0.14))
	_fill(img, 9, 28, 14, 2, Color(0.3, 0.24, 0.12))

	_outline(img, Color(0.3, 0.1, 0.08))
	_save(img, "silo.png")

# ==================== WINDMILL ====================

func _gen_windmill() -> void:
	var img = _img()
	var body = Color(0.6, 0.55, 0.48)
	var body_dark = Color(0.48, 0.44, 0.38)
	var blade = Color(0.75, 0.7, 0.62)
	var blade_dark = Color(0.6, 0.55, 0.48)
	var roof_col = Color(0.5, 0.3, 0.15)

	# Tower body (tapered)
	_fill(img, 12, 14, 8, 12, body)
	_fill(img, 13, 12, 6, 2, body)
	_fill(img, 11, 22, 10, 4, body)
	# Shadow
	_fill(img, 12, 14, 2, 12, body_dark)
	_fill(img, 11, 22, 2, 4, body_dark)

	# Roof
	_fill(img, 11, 11, 10, 1, roof_col)
	_fill(img, 13, 10, 6, 1, roof_col)
	_fill(img, 14, 9, 4, 1, roof_col)

	# Blades (X pattern from center hub)
	var hub_x = 16
	var hub_y = 10
	_px(img, hub_x, hub_y, Color(0.3, 0.3, 0.3))
	# Top blade
	_px(img, hub_x, hub_y - 1, blade)
	_px(img, hub_x, hub_y - 2, blade)
	_px(img, hub_x + 1, hub_y - 3, blade)
	_px(img, hub_x + 1, hub_y - 4, blade)
	_px(img, hub_x + 2, hub_y - 5, blade_dark)
	# Right blade
	_px(img, hub_x + 1, hub_y, blade)
	_px(img, hub_x + 2, hub_y, blade)
	_px(img, hub_x + 3, hub_y + 1, blade)
	_px(img, hub_x + 4, hub_y + 1, blade)
	_px(img, hub_x + 5, hub_y + 2, blade_dark)
	# Bottom blade
	_px(img, hub_x, hub_y + 1, blade)
	_px(img, hub_x, hub_y + 2, blade)
	_px(img, hub_x - 1, hub_y + 3, blade)
	_px(img, hub_x - 1, hub_y + 4, blade_dark)
	# Left blade
	_px(img, hub_x - 1, hub_y, blade)
	_px(img, hub_x - 2, hub_y, blade)
	_px(img, hub_x - 3, hub_y - 1, blade)
	_px(img, hub_x - 4, hub_y - 1, blade)
	_px(img, hub_x - 5, hub_y - 2, blade_dark)

	# Window
	_fill(img, 15, 17, 2, 2, Color(0.3, 0.4, 0.55))

	# Door
	_fill(img, 14, 23, 4, 3, Color(0.4, 0.25, 0.12))

	# Ground
	_fill(img, 10, 26, 12, 2, Color(0.35, 0.28, 0.14))

	_outline(img, Color(0.25, 0.2, 0.15))
	_save(img, "windmill.png")

# ==================== TRACTOR ====================

func _gen_tractor() -> void:
	var img = _img()
	var body_col = Color(0.7, 0.22, 0.15)
	var body_dark = Color(0.55, 0.15, 0.1)
	var wheel = Color(0.2, 0.2, 0.22)
	var wheel_light = Color(0.35, 0.35, 0.38)
	var glass = Color(0.5, 0.65, 0.75)
	var rust = Color(0.6, 0.4, 0.2)

	# Main body
	_fill(img, 6, 14, 18, 8, body_col)
	_fill(img, 6, 14, 4, 8, body_dark)
	# Hood (front)
	_fill(img, 4, 16, 4, 6, body_col)
	_fill(img, 4, 16, 2, 6, body_dark)

	# Cabin
	_fill(img, 16, 8, 8, 6, body_col)
	_fill(img, 16, 8, 2, 6, body_dark)
	# Window
	_fill(img, 18, 9, 5, 4, glass)
	# Roof
	_fill(img, 15, 7, 10, 1, Color(0.3, 0.3, 0.32))

	# Exhaust pipe
	_fill(img, 7, 10, 2, 4, Color(0.3, 0.3, 0.32))
	_px(img, 7, 9, Color(0.25, 0.25, 0.28))

	# Rust spots
	_px(img, 10, 16, rust)
	_px(img, 14, 18, rust)
	_px(img, 8, 20, rust)

	# Big rear wheel
	_circle(img, 20, 24, 4, wheel)
	_circle(img, 20, 24, 2, wheel_light)
	_px(img, 20, 24, wheel)

	# Small front wheel
	_circle(img, 8, 24, 3, wheel)
	_circle(img, 8, 24, 1, wheel_light)

	# Ground
	_fill(img, 3, 28, 22, 2, Color(0.35, 0.28, 0.14))

	_outline(img, Color(0.3, 0.1, 0.06))
	_save(img, "tractor.png")

# ==================== BARREL ====================

func _gen_barrel() -> void:
	var img = _img()
	var wood = Color(0.55, 0.38, 0.2)
	var wood_light = Color(0.65, 0.48, 0.28)
	var wood_dark = Color(0.42, 0.28, 0.14)
	var band = Color(0.4, 0.4, 0.42)
	var band_light = Color(0.52, 0.52, 0.55)

	# Barrel body (slightly bulging)
	_fill(img, 10, 10, 12, 16, wood)
	_fill(img, 9, 12, 1, 12, wood)
	_fill(img, 22, 12, 1, 12, wood)
	# Left shadow
	_fill(img, 9, 12, 3, 12, wood_dark)
	_fill(img, 10, 10, 2, 2, wood_dark)
	# Right highlight
	_fill(img, 20, 12, 3, 12, wood_light)
	_fill(img, 20, 10, 2, 2, wood_light)

	# Metal bands
	_fill(img, 9, 13, 14, 1, band)
	_fill(img, 9, 13, 14, 1, band_light)
	_fill(img, 9, 19, 14, 1, band)
	_fill(img, 9, 23, 14, 1, band)

	# Top ellipse
	_fill(img, 11, 9, 10, 1, wood_dark)
	_fill(img, 12, 8, 8, 1, wood)

	# Plank lines
	_px(img, 14, 11, wood_dark)
	_px(img, 14, 15, wood_dark)
	_px(img, 14, 21, wood_dark)
	_px(img, 18, 12, wood_dark)
	_px(img, 18, 17, wood_dark)
	_px(img, 18, 22, wood_dark)

	# Ground
	_fill(img, 8, 26, 16, 2, Color(0.35, 0.28, 0.14))

	_outline(img, Color(0.25, 0.18, 0.08))
	_save(img, "barrel.png")

# ==================== WHEAT ====================

func _gen_wheat() -> void:
	var img = _img()
	var stalk = Color(0.7, 0.6, 0.25)
	var stalk_dark = Color(0.58, 0.48, 0.18)
	var grain = Color(0.85, 0.75, 0.35)
	var grain_dark = Color(0.72, 0.62, 0.28)

	# Three wheat stalks
	# Left stalk
	_fill(img, 10, 12, 1, 16, stalk)
	_px(img, 9, 14, stalk_dark)
	_px(img, 11, 18, stalk_dark)
	# Grain head
	_fill(img, 9, 8, 3, 4, grain)
	_px(img, 9, 7, grain)
	_px(img, 11, 7, grain)
	_px(img, 10, 6, grain_dark)
	_fill(img, 9, 11, 3, 1, grain_dark)

	# Center stalk (taller)
	_fill(img, 16, 10, 1, 18, stalk)
	_px(img, 15, 13, stalk_dark)
	_px(img, 17, 16, stalk_dark)
	# Grain head
	_fill(img, 15, 5, 3, 5, grain)
	_px(img, 15, 4, grain)
	_px(img, 17, 4, grain)
	_px(img, 16, 3, grain_dark)
	_fill(img, 15, 9, 3, 1, grain_dark)

	# Right stalk
	_fill(img, 22, 13, 1, 15, stalk)
	_px(img, 21, 16, stalk_dark)
	_px(img, 23, 19, stalk_dark)
	# Grain head
	_fill(img, 21, 9, 3, 4, grain)
	_px(img, 21, 8, grain)
	_px(img, 23, 8, grain)
	_px(img, 22, 7, grain_dark)
	_fill(img, 21, 12, 3, 1, grain_dark)

	# Ground
	_fill(img, 8, 28, 16, 2, Color(0.35, 0.28, 0.14))

	_outline(img, Color(0.35, 0.3, 0.1))
	_save(img, "wheat.png")

# ==================== GROUND TILE ====================

func _gen_ground_farm() -> void:
	# 64x64 yellow/brown dirt with wheat stubble
	var img = _img(G)
	var dirt = Color(0.45, 0.38, 0.2)
	var dirt2 = Color(0.5, 0.42, 0.24)
	var dirt_dark = Color(0.35, 0.28, 0.14)
	var stubble = Color(0.6, 0.52, 0.25)
	var stubble_dark = Color(0.5, 0.42, 0.2)

	# Base fill: dirt
	_fill(img, 0, 0, G, G, dirt)

	# Dirt variation
	var rng = RandomNumberGenerator.new()
	rng.seed = 202

	for i in range(90):
		var px_x = rng.randi_range(0, G - 1)
		var px_y = rng.randi_range(0, G - 1)
		_px(img, px_x, px_y, dirt2)

	for i in range(60):
		var px_x = rng.randi_range(0, G - 1)
		var px_y = rng.randi_range(0, G - 1)
		_px(img, px_x, px_y, dirt_dark)

	# Wheat stubble (short vertical dashes scattered)
	for i in range(40):
		var sx = rng.randi_range(1, G - 2)
		var sy = rng.randi_range(1, G - 2)
		_px(img, sx, sy, stubble)
		_px(img, sx, sy - 1, stubble_dark)

	# Furrow lines (horizontal rows)
	for row in [12, 28, 44, 60]:
		for x in range(0, G, 3):
			_px(img, x, row, dirt_dark)
			if x + 1 < G:
				_px(img, x + 1, row, dirt_dark)

	# Edge tiling
	for i in range(G):
		if rng.randi_range(0, 3) == 0:
			_px(img, 0, i, dirt2)
			_px(img, G - 1, i, dirt2)
		if rng.randi_range(0, 3) == 0:
			_px(img, i, 0, dirt2)
			_px(img, i, G - 1, dirt2)

	_save(img, "ground_farm.png")
