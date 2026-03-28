extends SceneTree

## Generates 32x32 pixel art sprites for arena stage decoration props,
## plus a 64x64 tiled ground texture.
## Run: godot --headless --script res://scripts/tools/arena_prop_sprites.gd

const S := 32  # Prop sprite size
const G := 64  # Ground tile size

func _init() -> void:
	_generate_all()
	quit()

func _generate_all() -> void:
	DirAccess.make_dir_recursive_absolute("res://assets/sprites/props/arena")

	_gen_column()
	_gen_broken_column()
	_gen_torch()
	_gen_shield_wall()
	_gen_banner()
	_gen_statue()
	_gen_gate()
	_gen_chain()
	_gen_skull_pike()
	_gen_ground_arena()

	print("All arena prop sprites generated!")

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
	var path = "res://assets/sprites/props/arena/" + name
	img.save_png(path)
	print("Saved: ", path)

# ==================== COLUMN ====================

func _gen_column() -> void:
	# Roman stone column - tall, fluted
	var img = _img()
	var stone = Color(0.72, 0.68, 0.6)
	var stone_light = Color(0.82, 0.78, 0.7)
	var stone_dark = Color(0.55, 0.52, 0.45)

	# Capital (top)
	_fill(img, 9, 2, 14, 3, stone)
	_fill(img, 10, 1, 12, 1, stone_light)
	_fill(img, 9, 2, 14, 1, stone_light)
	_fill(img, 9, 4, 14, 1, stone_dark)

	# Shaft
	_fill(img, 11, 5, 10, 18, stone)

	# Fluting (vertical grooves)
	_fill(img, 13, 5, 1, 18, stone_dark)
	_fill(img, 16, 5, 1, 18, stone_dark)
	_fill(img, 19, 5, 1, 18, stone_dark)

	# Right highlight
	_fill(img, 20, 5, 1, 18, stone_light)

	# Left shadow
	_fill(img, 11, 5, 1, 18, stone_dark)

	# Base
	_fill(img, 9, 23, 14, 2, stone)
	_fill(img, 8, 25, 16, 2, stone)
	_fill(img, 9, 23, 14, 1, stone_light)
	_fill(img, 8, 26, 16, 1, stone_dark)

	# Ground
	_fill(img, 7, 27, 18, 3, Color(0.55, 0.48, 0.35))
	_fill(img, 8, 29, 16, 2, Color(0.48, 0.42, 0.3))

	_outline(img, Color(0.3, 0.28, 0.22))
	_save(img, "column.png")

# ==================== BROKEN COLUMN ====================

func _gen_broken_column() -> void:
	# Crumbled column ruins - broken shaft with rubble
	var img = _img()
	var stone = Color(0.68, 0.64, 0.56)
	var stone_light = Color(0.78, 0.74, 0.66)
	var stone_dark = Color(0.5, 0.46, 0.4)
	var rubble = Color(0.58, 0.54, 0.46)

	# Broken shaft (shorter, jagged top)
	_fill(img, 11, 12, 10, 12, stone)
	# Jagged break at top
	_fill(img, 11, 10, 4, 2, stone)
	_fill(img, 17, 11, 4, 1, stone)
	_px(img, 13, 9, stone)
	_px(img, 14, 9, stone_dark)
	_px(img, 18, 10, stone_dark)

	# Fluting
	_fill(img, 13, 12, 1, 12, stone_dark)
	_fill(img, 16, 12, 1, 12, stone_dark)
	_fill(img, 19, 12, 1, 12, stone_dark)

	# Right highlight
	_fill(img, 20, 12, 1, 12, stone_light)

	# Base
	_fill(img, 9, 24, 14, 2, stone)
	_fill(img, 9, 24, 14, 1, stone_light)

	# Scattered rubble pieces
	_fill(img, 4, 24, 4, 3, rubble)
	_fill(img, 5, 23, 2, 1, rubble)
	_fill(img, 23, 23, 4, 3, rubble)
	_fill(img, 24, 22, 2, 1, rubble)
	_fill(img, 7, 26, 3, 2, stone_dark)
	_fill(img, 22, 25, 3, 2, stone_dark)

	# Fallen capital piece
	_fill(img, 22, 20, 5, 3, stone)
	_fill(img, 22, 20, 5, 1, stone_light)

	# Ground
	_fill(img, 3, 27, 26, 3, Color(0.52, 0.45, 0.32))
	_fill(img, 5, 29, 22, 2, Color(0.46, 0.4, 0.28))

	_outline(img, Color(0.28, 0.25, 0.2))
	_save(img, "broken_column.png")

# ==================== TORCH ====================

func _gen_torch() -> void:
	# Wall torch with flame
	var img = _img()
	var metal = Color(0.35, 0.3, 0.25)
	var metal_light = Color(0.48, 0.42, 0.35)
	var metal_dark = Color(0.22, 0.18, 0.14)
	var fire_bright = Color(1.0, 0.85, 0.2)
	var fire_mid = Color(1.0, 0.5, 0.1)
	var fire_dark = Color(0.85, 0.25, 0.05)

	# Torch handle/shaft
	_fill(img, 15, 14, 3, 12, metal)
	_fill(img, 14, 14, 1, 12, metal_dark)
	_fill(img, 17, 14, 1, 12, metal_light)

	# Bracket (wall mount)
	_fill(img, 12, 18, 8, 2, metal)
	_fill(img, 11, 17, 2, 4, metal_dark)

	# Torch cup
	_fill(img, 13, 12, 7, 2, metal)
	_fill(img, 12, 11, 9, 1, metal)
	_fill(img, 13, 12, 7, 1, metal_light)

	# Flame - core
	_fill(img, 14, 5, 4, 6, fire_bright)
	_fill(img, 15, 3, 2, 2, fire_mid)
	_px(img, 15, 2, fire_dark)
	_px(img, 16, 2, fire_dark)

	# Flame - outer
	_fill(img, 13, 7, 1, 4, fire_mid)
	_fill(img, 18, 7, 1, 4, fire_mid)
	_px(img, 13, 6, fire_dark)
	_px(img, 18, 6, fire_dark)
	_px(img, 14, 4, fire_mid)
	_px(img, 17, 4, fire_mid)

	# Flame tip
	_px(img, 15, 1, fire_dark)
	_px(img, 16, 1, fire_dark)

	# Embers
	_px(img, 12, 9, fire_dark)
	_px(img, 19, 8, fire_dark)
	_px(img, 14, 3, Color(1.0, 0.9, 0.5))

	# Bottom point
	_fill(img, 15, 26, 2, 2, metal)
	_px(img, 16, 28, metal_dark)

	_outline(img, Color(0.1, 0.08, 0.06))
	_save(img, "torch.png")

# ==================== SHIELD WALL ====================

func _gen_shield_wall() -> void:
	# Decorative round shield on wall
	var img = _img()
	var shield = Color(0.55, 0.15, 0.1)
	var shield_light = Color(0.7, 0.22, 0.15)
	var shield_dark = Color(0.35, 0.08, 0.05)
	var gold = Color(0.85, 0.7, 0.2)
	var gold_dark = Color(0.6, 0.45, 0.1)
	var metal = Color(0.5, 0.48, 0.42)

	# Shield body (round)
	_circle(img, 16, 14, 10, shield)
	_circle(img, 16, 14, 9, shield)
	_circle(img, 16, 14, 8, shield_light)

	# Gold rim
	for x in range(32):
		for y in range(32):
			var dx = x - 16
			var dy = y - 14
			var dist = dx * dx + dy * dy
			if dist >= 81 and dist <= 100:
				_px(img, x, y, gold)

	# Gold boss (center)
	_circle(img, 16, 14, 3, gold)
	_circle(img, 16, 14, 2, Color(0.95, 0.8, 0.3))
	_px(img, 16, 14, gold_dark)

	# Cross pattern on shield
	_fill(img, 15, 6, 2, 16, gold_dark)
	_fill(img, 8, 13, 16, 2, gold_dark)

	# Shield shading
	_fill(img, 8, 10, 3, 8, shield_dark)
	_fill(img, 21, 10, 3, 8, shield_light)

	# Highlight
	_px(img, 12, 8, shield_light)
	_px(img, 13, 7, shield_light)

	# Mounting nail
	_fill(img, 15, 25, 2, 2, metal)

	_outline(img, Color(0.2, 0.05, 0.03))
	_save(img, "shield_wall.png")

# ==================== BANNER ====================

func _gen_banner() -> void:
	# Red and gold hanging banner
	var img = _img()
	var red = Color(0.7, 0.12, 0.1)
	var red_light = Color(0.85, 0.2, 0.15)
	var red_dark = Color(0.5, 0.08, 0.06)
	var gold = Color(0.85, 0.7, 0.2)
	var gold_dark = Color(0.6, 0.45, 0.1)
	var wood = Color(0.45, 0.3, 0.18)

	# Hanging rod
	_fill(img, 8, 2, 16, 2, wood)
	_fill(img, 8, 2, 16, 1, Color(0.55, 0.38, 0.22))

	# Banner fabric
	_fill(img, 10, 4, 12, 20, red)

	# Slight wave/fold
	_fill(img, 10, 4, 2, 20, red_dark)
	_fill(img, 20, 4, 2, 20, red_light)

	# Gold trim top
	_fill(img, 10, 4, 12, 2, gold)
	_fill(img, 10, 4, 12, 1, Color(0.95, 0.8, 0.3))

	# Gold trim bottom
	_fill(img, 10, 22, 12, 2, gold)

	# Gold symbol (Roman eagle/emblem simplified)
	_fill(img, 14, 10, 4, 1, gold)
	_fill(img, 15, 9, 2, 1, gold)
	_fill(img, 13, 11, 6, 1, gold)
	_fill(img, 12, 12, 8, 1, gold)
	_fill(img, 15, 13, 2, 3, gold)
	# Wings
	_px(img, 11, 11, gold)
	_px(img, 10, 10, gold_dark)
	_px(img, 20, 11, gold)
	_px(img, 21, 10, gold_dark)

	# Banner pointed bottom
	_fill(img, 10, 24, 5, 2, red)
	_fill(img, 17, 24, 5, 2, red)
	_fill(img, 11, 26, 3, 1, red)
	_fill(img, 18, 26, 3, 1, red)
	_px(img, 12, 27, red_dark)
	_px(img, 19, 27, red_dark)

	# Fabric fold shadows
	_px(img, 14, 8, red_dark)
	_px(img, 14, 16, red_dark)
	_px(img, 18, 12, red_light)

	_outline(img, Color(0.25, 0.05, 0.03))
	_save(img, "banner.png")

# ==================== STATUE ====================

func _gen_statue() -> void:
	# Warrior statue - simplified gladiator
	var img = _img()
	var stone = Color(0.6, 0.58, 0.52)
	var stone_light = Color(0.72, 0.7, 0.64)
	var stone_dark = Color(0.45, 0.42, 0.38)
	var base_col = Color(0.5, 0.46, 0.4)

	# Head
	_circle(img, 16, 5, 3, stone)
	_px(img, 15, 4, stone_light)
	# Helmet crest
	_fill(img, 15, 1, 2, 2, stone)
	_px(img, 15, 0, stone_dark)

	# Neck
	_fill(img, 15, 8, 2, 2, stone)

	# Torso
	_fill(img, 12, 10, 8, 8, stone)
	_fill(img, 11, 10, 1, 8, stone_dark)
	_fill(img, 19, 10, 1, 8, stone_light)

	# Chest plate detail
	_fill(img, 13, 11, 6, 1, stone_light)
	_fill(img, 13, 14, 6, 1, stone_dark)

	# Left arm with shield
	_fill(img, 8, 10, 3, 8, stone)
	_fill(img, 6, 12, 3, 5, stone_dark)  # shield
	_fill(img, 7, 13, 1, 3, stone)

	# Right arm with sword raised
	_fill(img, 20, 10, 3, 6, stone)
	_fill(img, 22, 8, 2, 3, stone)
	# Sword blade
	_fill(img, 23, 2, 1, 6, stone_light)
	_px(img, 23, 1, stone)
	_px(img, 22, 8, stone_dark)  # hilt

	# Legs
	_fill(img, 12, 18, 3, 6, stone)
	_fill(img, 17, 18, 3, 6, stone)
	_fill(img, 12, 18, 1, 6, stone_dark)
	_fill(img, 19, 18, 1, 6, stone_light)

	# Feet
	_fill(img, 11, 24, 4, 1, stone)
	_fill(img, 17, 24, 4, 1, stone)

	# Pedestal
	_fill(img, 9, 25, 14, 2, base_col)
	_fill(img, 8, 27, 16, 2, base_col)
	_fill(img, 8, 27, 16, 1, Color(0.55, 0.5, 0.44))
	_fill(img, 8, 28, 16, 1, Color(0.42, 0.38, 0.33))

	_outline(img, Color(0.25, 0.23, 0.2))
	_save(img, "statue.png")

# ==================== GATE ====================

func _gen_gate() -> void:
	# Iron arena gate / portcullis
	var img = _img()
	var iron = Color(0.3, 0.28, 0.25)
	var iron_light = Color(0.42, 0.4, 0.36)
	var iron_dark = Color(0.18, 0.16, 0.14)
	var stone = Color(0.55, 0.5, 0.42)
	var stone_dark = Color(0.4, 0.36, 0.3)

	# Stone frame - left pillar
	_fill(img, 4, 2, 5, 26, stone)
	_fill(img, 4, 2, 5, 1, Color(0.62, 0.58, 0.5))
	_fill(img, 4, 2, 1, 26, stone_dark)

	# Stone frame - right pillar
	_fill(img, 23, 2, 5, 26, stone)
	_fill(img, 23, 2, 5, 1, Color(0.62, 0.58, 0.5))
	_fill(img, 27, 2, 1, 26, stone_dark)

	# Stone arch top
	_fill(img, 9, 2, 14, 3, stone)
	_fill(img, 9, 2, 14, 1, Color(0.62, 0.58, 0.5))

	# Vertical iron bars
	_fill(img, 10, 5, 2, 23, iron)
	_fill(img, 14, 5, 2, 23, iron)
	_fill(img, 18, 5, 2, 23, iron)
	_fill(img, 22, 5, 2, 23, iron)

	# Horizontal crossbar
	_fill(img, 9, 14, 14, 2, iron)
	_fill(img, 9, 14, 14, 1, iron_light)

	# Bar highlights
	_fill(img, 11, 5, 1, 23, iron_light)
	_fill(img, 15, 5, 1, 23, iron_light)
	_fill(img, 19, 5, 1, 23, iron_light)

	# Pointed bar tips at bottom
	_px(img, 10, 28, iron)
	_px(img, 14, 28, iron)
	_px(img, 18, 28, iron)
	_px(img, 22, 28, iron)

	# Rust spots
	_px(img, 11, 10, Color(0.5, 0.28, 0.12))
	_px(img, 15, 20, Color(0.5, 0.28, 0.12))
	_px(img, 19, 8, Color(0.5, 0.28, 0.12))

	# Ground
	_fill(img, 4, 28, 24, 2, Color(0.48, 0.42, 0.3))

	_outline(img, Color(0.1, 0.08, 0.06))
	_save(img, "gate.png")

# ==================== CHAIN ====================

func _gen_chain() -> void:
	# Hanging chain links
	var img = _img()
	var metal = Color(0.4, 0.38, 0.34)
	var metal_light = Color(0.55, 0.52, 0.48)
	var metal_dark = Color(0.25, 0.22, 0.2)

	# Chain links - alternating orientation
	# Link 1 (vertical, top)
	_fill(img, 14, 2, 4, 1, metal)
	_fill(img, 13, 3, 1, 4, metal)
	_fill(img, 18, 3, 1, 4, metal)
	_fill(img, 14, 7, 4, 1, metal)
	_px(img, 18, 3, metal_light)
	_px(img, 14, 2, metal_light)

	# Link 2 (horizontal-ish)
	_fill(img, 12, 8, 1, 4, metal)
	_fill(img, 19, 8, 1, 4, metal)
	_fill(img, 13, 8, 6, 1, metal)
	_fill(img, 13, 11, 6, 1, metal)
	_px(img, 13, 8, metal_light)

	# Link 3 (vertical)
	_fill(img, 14, 12, 4, 1, metal)
	_fill(img, 13, 13, 1, 4, metal)
	_fill(img, 18, 13, 1, 4, metal)
	_fill(img, 14, 17, 4, 1, metal)
	_px(img, 18, 13, metal_light)

	# Link 4
	_fill(img, 12, 18, 1, 4, metal)
	_fill(img, 19, 18, 1, 4, metal)
	_fill(img, 13, 18, 6, 1, metal)
	_fill(img, 13, 21, 6, 1, metal)
	_px(img, 13, 18, metal_light)

	# Link 5 (vertical, bottom)
	_fill(img, 14, 22, 4, 1, metal)
	_fill(img, 13, 23, 1, 4, metal)
	_fill(img, 18, 23, 1, 4, metal)
	_fill(img, 14, 27, 4, 1, metal)
	_px(img, 18, 23, metal_light)

	# Dark inner of links
	_fill(img, 15, 4, 2, 2, Color(0, 0, 0, 0))
	_fill(img, 14, 9, 4, 1, Color(0, 0, 0, 0))
	_fill(img, 15, 14, 2, 2, Color(0, 0, 0, 0))
	_fill(img, 14, 19, 4, 1, Color(0, 0, 0, 0))
	_fill(img, 15, 24, 2, 2, Color(0, 0, 0, 0))

	# Rust spots
	_px(img, 14, 6, Color(0.5, 0.3, 0.15))
	_px(img, 17, 16, Color(0.5, 0.3, 0.15))
	_px(img, 13, 26, Color(0.5, 0.3, 0.15))

	_outline(img, Color(0.12, 0.1, 0.08))
	_save(img, "chain.png")

# ==================== SKULL PIKE ====================

func _gen_skull_pike() -> void:
	# Skull mounted on a pike/pole
	var img = _img()
	var bone = Color(0.82, 0.78, 0.68)
	var bone_dark = Color(0.6, 0.55, 0.48)
	var bone_light = Color(0.92, 0.88, 0.8)
	var wood = Color(0.4, 0.25, 0.14)
	var wood_dark = Color(0.28, 0.16, 0.08)
	var eye = Color(0.1, 0.05, 0.02)

	# Pike pole
	_fill(img, 15, 14, 2, 16, wood)
	_fill(img, 14, 14, 1, 16, wood_dark)

	# Skull
	_circle(img, 16, 8, 5, bone)
	_circle(img, 16, 8, 4, bone_light)

	# Eye sockets
	_fill(img, 13, 6, 2, 3, eye)
	_fill(img, 17, 6, 2, 3, eye)

	# Nose
	_px(img, 15, 10, bone_dark)
	_px(img, 16, 10, bone_dark)
	_px(img, 16, 11, bone_dark)

	# Jaw
	_fill(img, 13, 12, 6, 2, bone)
	_fill(img, 13, 12, 6, 1, bone_dark)
	# Teeth
	_px(img, 14, 12, bone_light)
	_px(img, 16, 12, bone_light)
	_px(img, 18, 12, bone_light)

	# Jaw gap
	_px(img, 15, 12, eye)
	_px(img, 17, 12, eye)

	# Skull cracks
	_px(img, 14, 4, bone_dark)
	_px(img, 15, 5, bone_dark)
	_px(img, 19, 6, bone_dark)

	# Shading on skull
	_fill(img, 11, 6, 2, 4, bone_dark)
	_fill(img, 20, 6, 1, 4, bone_light)

	# Ground base
	_fill(img, 12, 28, 8, 2, Color(0.48, 0.42, 0.3))

	_outline(img, Color(0.15, 0.12, 0.08))
	_save(img, "skull_pike.png")

# ==================== GROUND TEXTURE ====================

func _gen_ground_arena() -> void:
	# 64x64 sandy/stone floor with tile pattern
	var img = _img(G)
	var stone1 = Color(0.55, 0.48, 0.35)
	var stone2 = Color(0.5, 0.44, 0.32)
	var stone3 = Color(0.6, 0.52, 0.38)
	var grout = Color(0.38, 0.32, 0.24)
	var sand = Color(0.65, 0.58, 0.42)

	# Fill with sandy stone base
	for x in range(G):
		for y in range(G):
			var noise_val = ((x * 13 + y * 7) % 23) / 23.0
			if noise_val < 0.35:
				img.set_pixel(x, y, stone1)
			elif noise_val < 0.7:
				img.set_pixel(x, y, stone2)
			else:
				img.set_pixel(x, y, stone3)

	# Tile grid pattern (16x16 tiles)
	var tile_size = 16
	for x in range(G):
		for y in range(G):
			if x % tile_size == 0 or y % tile_size == 0:
				img.set_pixel(x, y, grout)

	# Sand accumulation in some grout lines
	for i in range(20):
		var rx = (i * 31 + 3) % G
		var ry = (i * 19 + 11) % G
		img.set_pixel(rx, ry, sand)

	# Worn/lighter patches in high-traffic center
	for x in range(24, 40):
		for y in range(24, 40):
			var dx = x - 32
			var dy = y - 32
			if dx * dx + dy * dy < 100:
				var c = img.get_pixel(x, y)
				img.set_pixel(x, y, Color(c.r + 0.05, c.g + 0.04, c.b + 0.02))

	# Small dark stain spots (blood/dirt)
	for i in range(8):
		var sx = (i * 47 + 7) % G
		var sy = (i * 33 + 19) % G
		img.set_pixel(sx, sy, Color(0.35, 0.2, 0.15))
		if sx + 1 < G:
			img.set_pixel(sx + 1, sy, Color(0.38, 0.22, 0.16))

	_save(img, "ground_arena.png")
