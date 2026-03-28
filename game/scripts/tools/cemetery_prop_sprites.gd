extends SceneTree

## Generates 32x32 pixel art sprites for cemetery stage decoration props,
## plus a 64x64 tiled ground texture.
## Run: godot --headless --script res://scripts/tools/cemetery_prop_sprites.gd

const S := 32  # Prop sprite size
const G := 64  # Ground tile size

func _init() -> void:
	_generate_all()
	quit()

func _generate_all() -> void:
	DirAccess.make_dir_recursive_absolute("res://assets/sprites/props/cemetery")

	_gen_tombstone1()
	_gen_tombstone2()
	_gen_tombstone3()
	_gen_dead_tree1()
	_gen_dead_tree2()
	_gen_iron_fence()
	_gen_cross()
	_gen_skull_pile()
	_gen_lantern()
	_gen_coffin()
	_gen_pumpkin()
	_gen_mushroom()
	_gen_ground_cemetery()

	print("All cemetery prop sprites generated!")

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
	var path = "res://assets/sprites/props/cemetery/" + name
	img.save_png(path)
	print("Saved: ", path)

# ==================== TOMBSTONES ====================

func _gen_tombstone1() -> void:
	# Classic gray rounded tombstone with "RIP" text, moss at base, cracks
	var img = _img()
	var stone = Color(0.55, 0.55, 0.58)
	var stone_dark = Color(0.42, 0.42, 0.45)
	var stone_light = Color(0.65, 0.65, 0.68)
	var moss = Color(0.25, 0.45, 0.2)
	var moss_dark = Color(0.18, 0.35, 0.15)
	var crack = Color(0.32, 0.32, 0.35)
	var text_col = Color(0.3, 0.3, 0.32)

	# Rounded top
	_fill(img, 11, 4, 10, 2, stone)
	_fill(img, 10, 6, 12, 1, stone)
	_fill(img, 9, 7, 14, 1, stone)
	# Semi-circle top cap
	_fill(img, 13, 2, 6, 2, stone)
	_fill(img, 12, 3, 8, 1, stone)
	_px(img, 14, 1, stone)
	_px(img, 15, 1, stone)
	_px(img, 16, 1, stone)
	_px(img, 17, 1, stone)

	# Main body
	_fill(img, 9, 8, 14, 16, stone)

	# Left edge shading
	_fill(img, 9, 8, 2, 16, stone_dark)
	_px(img, 10, 6, stone_dark)
	_px(img, 11, 4, stone_dark)
	_px(img, 11, 5, stone_dark)

	# Right edge highlight
	_fill(img, 21, 8, 2, 16, stone_light)
	_px(img, 21, 6, stone_light)
	_px(img, 20, 4, stone_light)
	_px(img, 20, 5, stone_light)

	# "R I P" text
	# R
	_fill(img, 12, 10, 1, 5, text_col)
	_px(img, 13, 10, text_col)
	_px(img, 14, 11, text_col)
	_px(img, 13, 12, text_col)
	_px(img, 14, 13, text_col)
	_px(img, 14, 14, text_col)
	# I
	_px(img, 16, 10, text_col)
	_fill(img, 16, 10, 1, 5, text_col)
	# P
	_fill(img, 18, 10, 1, 5, text_col)
	_px(img, 19, 10, text_col)
	_px(img, 20, 11, text_col)
	_px(img, 19, 12, text_col)

	# Cracks
	_px(img, 11, 15, crack)
	_px(img, 12, 16, crack)
	_px(img, 12, 17, crack)
	_px(img, 13, 18, crack)
	_px(img, 19, 17, crack)
	_px(img, 20, 18, crack)
	_px(img, 20, 19, crack)

	# Moss at base
	_fill(img, 9, 22, 14, 2, moss)
	_fill(img, 10, 21, 4, 1, moss)
	_fill(img, 18, 21, 3, 1, moss)
	_px(img, 11, 20, moss_dark)
	_px(img, 19, 20, moss_dark)
	_fill(img, 9, 23, 14, 1, moss_dark)

	# Ground base
	_fill(img, 7, 24, 18, 2, Color(0.3, 0.25, 0.18))
	_fill(img, 8, 26, 16, 2, Color(0.25, 0.2, 0.15))

	_outline(img, Color(0.12, 0.12, 0.14))
	_save(img, "tombstone1.png")

func _gen_tombstone2() -> void:
	# Tall cross-shaped tombstone, dark gray stone, slightly tilted
	var img = _img()
	var stone = Color(0.4, 0.4, 0.44)
	var stone_light = Color(0.52, 0.52, 0.56)
	var stone_dark = Color(0.3, 0.3, 0.33)

	# Vertical shaft (slightly tilted - shifted 1px right at top)
	_fill(img, 14, 5, 4, 20, stone)
	_fill(img, 15, 3, 4, 2, stone) # top of shaft shifted right

	# Cross arms
	_fill(img, 9, 9, 14, 3, stone)

	# Left arm shading
	_fill(img, 9, 9, 2, 3, stone_dark)
	# Right arm highlight
	_fill(img, 21, 9, 2, 3, stone_light)

	# Top highlight
	_fill(img, 17, 3, 2, 6, stone_light)
	# Left shaft shadow
	_fill(img, 14, 5, 1, 20, stone_dark)

	# Slight tilt: top-left pixel adjustments
	_px(img, 15, 2, stone)
	_px(img, 16, 2, stone)
	_px(img, 17, 2, stone_light)

	# Texture cracks
	_px(img, 15, 14, stone_dark)
	_px(img, 16, 15, stone_dark)
	_px(img, 15, 16, stone_dark)

	# Ground base
	_fill(img, 11, 25, 10, 2, Color(0.3, 0.25, 0.18))
	_fill(img, 12, 27, 8, 2, Color(0.25, 0.2, 0.15))

	_outline(img, Color(0.1, 0.1, 0.12))
	_save(img, "tombstone2.png")

func _gen_tombstone3() -> void:
	# Wide flat tombstone with angel figure on top, weathered
	var img = _img()
	var stone = Color(0.5, 0.5, 0.52)
	var stone_light = Color(0.62, 0.62, 0.64)
	var stone_dark = Color(0.38, 0.38, 0.4)
	var angel = Color(0.7, 0.7, 0.72)
	var angel_dark = Color(0.58, 0.58, 0.6)

	# Wide flat base stone
	_fill(img, 5, 14, 22, 10, stone)
	_fill(img, 6, 13, 20, 1, stone)

	# Top ledge
	_fill(img, 4, 24, 24, 2, stone_dark)

	# Weathering spots
	_fill(img, 8, 16, 3, 2, stone_dark)
	_fill(img, 19, 18, 2, 3, stone_dark)
	_px(img, 12, 20, stone_dark)
	_px(img, 15, 17, stone_dark)

	# Right side highlight
	_fill(img, 24, 14, 3, 10, stone_light)
	_fill(img, 23, 13, 3, 1, stone_light)

	# Angel figure on top (small simplified silhouette)
	# Head
	_circle(img, 16, 6, 2, angel)
	# Body
	_fill(img, 15, 8, 3, 4, angel)
	# Wings left
	_px(img, 12, 8, angel)
	_px(img, 11, 7, angel)
	_px(img, 13, 9, angel)
	_px(img, 13, 8, angel)
	_px(img, 10, 7, angel_dark)
	# Wings right
	_px(img, 19, 8, angel)
	_px(img, 20, 7, angel)
	_px(img, 18, 9, angel)
	_px(img, 18, 8, angel)
	_px(img, 21, 7, angel_dark)
	# Angel base
	_fill(img, 14, 12, 5, 1, angel_dark)

	# Ground base
	_fill(img, 3, 26, 26, 2, Color(0.3, 0.25, 0.18))
	_fill(img, 4, 28, 24, 2, Color(0.25, 0.2, 0.15))

	_outline(img, Color(0.1, 0.1, 0.12))
	_save(img, "tombstone3.png")

# ==================== TREES ====================

func _gen_dead_tree1() -> void:
	# Leafless dark brown tree, twisted branches, spooky silhouette
	var img = _img()
	var bark = Color(0.3, 0.2, 0.12)
	var bark_light = Color(0.4, 0.28, 0.16)
	var bark_dark = Color(0.2, 0.13, 0.08)

	# Trunk (thick, slightly curved)
	_fill(img, 14, 14, 4, 14, bark)
	_fill(img, 13, 18, 1, 10, bark)
	_fill(img, 18, 20, 1, 8, bark)
	# Trunk highlight
	_fill(img, 16, 14, 2, 14, bark_light)

	# Trunk base (wider)
	_fill(img, 12, 26, 8, 2, bark)
	_fill(img, 11, 28, 10, 2, bark_dark)
	_fill(img, 10, 29, 12, 2, bark_dark)

	# Main branch left
	_px(img, 13, 13, bark)
	_px(img, 12, 12, bark)
	_px(img, 11, 11, bark)
	_px(img, 10, 10, bark)
	_px(img, 9, 9, bark)
	_px(img, 8, 8, bark)
	_px(img, 7, 7, bark)
	# Left branch sub-branch up
	_px(img, 9, 8, bark)
	_px(img, 8, 7, bark)
	_px(img, 8, 6, bark)
	_px(img, 7, 5, bark)
	# Left branch sub-branch down
	_px(img, 7, 8, bark_dark)
	_px(img, 6, 9, bark_dark)
	_px(img, 5, 10, bark_dark)

	# Main branch right
	_px(img, 18, 13, bark)
	_px(img, 19, 12, bark)
	_px(img, 20, 11, bark)
	_px(img, 21, 10, bark)
	_px(img, 22, 9, bark)
	_px(img, 23, 8, bark)
	_px(img, 24, 7, bark)
	_px(img, 25, 6, bark)
	# Right branch sub-branch up
	_px(img, 22, 8, bark)
	_px(img, 23, 7, bark)
	_px(img, 23, 6, bark)
	_px(img, 24, 5, bark)
	_px(img, 24, 4, bark)
	# Right branch sub-branch down
	_px(img, 24, 8, bark_dark)
	_px(img, 25, 9, bark_dark)
	_px(img, 26, 9, bark_dark)

	# Top branches
	_px(img, 15, 13, bark)
	_px(img, 15, 12, bark)
	_px(img, 14, 11, bark)
	_px(img, 14, 10, bark)
	_px(img, 13, 9, bark)
	_px(img, 13, 8, bark_dark)
	# Top right
	_px(img, 17, 13, bark)
	_px(img, 17, 12, bark)
	_px(img, 18, 11, bark)
	_px(img, 19, 10, bark_light)
	_px(img, 19, 9, bark)
	_px(img, 20, 8, bark)

	# Small twigs
	_px(img, 6, 6, bark_dark)
	_px(img, 5, 5, bark_dark)
	_px(img, 26, 5, bark_dark)
	_px(img, 27, 4, bark_dark)

	_outline(img, Color(0.08, 0.05, 0.03))
	_save(img, "dead_tree1.png")

func _gen_dead_tree2() -> void:
	# Smaller dead tree/bush, dark brown, few crooked branches
	var img = _img()
	var bark = Color(0.32, 0.22, 0.13)
	var bark_light = Color(0.42, 0.3, 0.18)
	var bark_dark = Color(0.22, 0.15, 0.08)

	# Short trunk
	_fill(img, 14, 18, 3, 10, bark)
	_fill(img, 15, 18, 2, 10, bark_light)
	# Base wider
	_fill(img, 12, 27, 7, 2, bark)
	_fill(img, 11, 29, 9, 2, bark_dark)

	# Branch left - crooked
	_px(img, 13, 17, bark)
	_px(img, 12, 16, bark)
	_px(img, 11, 15, bark)
	_px(img, 10, 14, bark)
	_px(img, 9, 14, bark)
	_px(img, 8, 13, bark)
	_px(img, 10, 13, bark_dark)
	_px(img, 9, 12, bark_dark)

	# Branch right - crooked
	_px(img, 17, 17, bark)
	_px(img, 18, 16, bark)
	_px(img, 19, 15, bark)
	_px(img, 20, 14, bark)
	_px(img, 21, 14, bark)
	_px(img, 22, 13, bark)
	_px(img, 21, 12, bark_dark)

	# Top branch
	_px(img, 15, 17, bark)
	_px(img, 15, 16, bark)
	_px(img, 14, 15, bark)
	_px(img, 14, 14, bark)
	_px(img, 15, 13, bark)
	_px(img, 15, 12, bark_dark)
	_px(img, 16, 15, bark_light)
	_px(img, 16, 14, bark)
	_px(img, 17, 13, bark)

	# Small twigs
	_px(img, 7, 12, bark_dark)
	_px(img, 23, 12, bark_dark)
	_px(img, 14, 13, bark_dark)

	_outline(img, Color(0.08, 0.05, 0.03))
	_save(img, "dead_tree2.png")

# ==================== FENCE & CROSS ====================

func _gen_iron_fence() -> void:
	# Black iron fence section with pointed tops, rusty brown spots
	var img = _img()
	var iron = Color(0.18, 0.18, 0.2)
	var iron_light = Color(0.28, 0.28, 0.3)
	var rust = Color(0.45, 0.28, 0.15)

	# Horizontal bars
	_fill(img, 1, 14, 30, 2, iron)
	_fill(img, 1, 24, 30, 2, iron)

	# Vertical bars with pointed tops (5 bars)
	for i in range(5):
		var bx = 3 + i * 6
		_fill(img, bx, 7, 2, 20, iron)
		# Pointed top (spear)
		_px(img, bx, 6, iron)
		_px(img, bx + 1, 6, iron)
		_px(img, bx, 5, iron_light)
		_px(img, bx + 1, 5, iron_light)
		_px(img, bx, 4, iron_light)

	# Highlight on horizontal bars
	_fill(img, 1, 14, 30, 1, iron_light)
	_fill(img, 1, 24, 30, 1, iron_light)

	# Rust spots
	_px(img, 4, 18, rust)
	_px(img, 10, 20, rust)
	_px(img, 16, 16, rust)
	_px(img, 22, 22, rust)
	_px(img, 28, 19, rust)
	_px(img, 3, 10, rust)
	_px(img, 15, 9, rust)
	_px(img, 27, 11, rust)

	_outline(img, Color(0.06, 0.06, 0.08))
	_save(img, "iron_fence.png")

func _gen_cross() -> void:
	# Wooden cross, dark brown, slightly crooked, vines growing on it
	var img = _img()
	var wood = Color(0.38, 0.25, 0.14)
	var wood_light = Color(0.48, 0.34, 0.2)
	var wood_dark = Color(0.28, 0.18, 0.1)
	var vine = Color(0.2, 0.45, 0.18)
	var vine_dark = Color(0.15, 0.35, 0.12)

	# Vertical beam (slightly crooked - shifts 1px at middle)
	_fill(img, 14, 3, 3, 12, wood)
	_fill(img, 13, 15, 3, 13, wood)

	# Horizontal beam
	_fill(img, 7, 9, 17, 3, wood)

	# Wood grain / highlight
	_fill(img, 15, 3, 1, 25, wood_light)
	_fill(img, 8, 10, 15, 1, wood_light)

	# Dark edges
	_fill(img, 14, 3, 1, 12, wood_dark)
	_fill(img, 13, 15, 1, 13, wood_dark)
	_fill(img, 7, 9, 1, 3, wood_dark)

	# Crookedness: offset top slightly
	_px(img, 15, 2, wood)
	_px(img, 16, 2, wood_light)

	# Vine wrapping around
	_px(img, 12, 16, vine)
	_px(img, 13, 17, vine_dark)
	_px(img, 16, 18, vine)
	_px(img, 17, 19, vine)
	_px(img, 16, 20, vine_dark)
	_px(img, 12, 21, vine)
	_px(img, 13, 22, vine)
	_px(img, 16, 23, vine_dark)
	_px(img, 17, 24, vine)
	# Vine on crossbar
	_px(img, 9, 8, vine)
	_px(img, 10, 9, vine_dark)
	_px(img, 20, 8, vine)
	_px(img, 21, 9, vine_dark)

	# Ground base
	_fill(img, 11, 28, 7, 2, Color(0.3, 0.25, 0.18))
	_fill(img, 10, 29, 9, 2, Color(0.25, 0.2, 0.15))

	_outline(img, Color(0.1, 0.07, 0.04))
	_save(img, "cross.png")

# ==================== SKULL PILE ====================

func _gen_skull_pile() -> void:
	# Pile of 3-4 white/bone colored skulls with some bones
	var img = _img()
	var bone = Color(0.85, 0.82, 0.72)
	var bone_dark = Color(0.7, 0.67, 0.58)
	var bone_light = Color(0.92, 0.9, 0.82)
	var eye = Color(0.15, 0.12, 0.1)

	# Bottom skull left
	_circle(img, 10, 22, 4, bone)
	_circle(img, 10, 22, 3, bone_light)
	_px(img, 8, 21, eye)
	_px(img, 11, 21, eye)
	_fill(img, 9, 24, 3, 1, bone_dark) # jaw
	_px(img, 9, 23, bone_dark)
	_px(img, 11, 23, bone_dark)

	# Bottom skull right
	_circle(img, 22, 23, 4, bone)
	_circle(img, 22, 23, 3, bone_light)
	_px(img, 20, 22, eye)
	_px(img, 23, 22, eye)
	_fill(img, 21, 25, 3, 1, bone_dark)
	_px(img, 21, 24, bone_dark)
	_px(img, 23, 24, bone_dark)

	# Top skull (sitting on top)
	_circle(img, 16, 16, 4, bone)
	_circle(img, 16, 16, 3, bone_light)
	_px(img, 14, 15, eye)
	_px(img, 17, 15, eye)
	_fill(img, 15, 18, 3, 1, bone_dark)
	_px(img, 15, 17, bone_dark)
	_px(img, 17, 17, bone_dark)

	# Small skull behind (partial)
	_circle(img, 8, 17, 3, bone_dark)
	_px(img, 7, 16, eye)
	_px(img, 9, 16, eye)

	# Scattered bones
	# Bone 1 (horizontal)
	_fill(img, 4, 26, 5, 1, bone)
	_px(img, 3, 25, bone_dark)
	_px(img, 3, 27, bone_dark)
	_px(img, 9, 25, bone_dark)
	_px(img, 9, 27, bone_dark)
	# Bone 2 (diagonal)
	_px(img, 25, 18, bone)
	_px(img, 26, 19, bone)
	_px(img, 27, 20, bone)
	_px(img, 28, 21, bone)
	# Bone knobs
	_px(img, 24, 17, bone_dark)
	_px(img, 29, 22, bone_dark)

	# Ground shadow
	_fill(img, 5, 27, 22, 2, Color(0.2, 0.18, 0.14))

	_outline(img, Color(0.12, 0.1, 0.08))
	_save(img, "skull_pile.png")

# ==================== LANTERN ====================

func _gen_lantern() -> void:
	# Old hanging lantern with orange/yellow glow, rusty metal
	var img = _img()
	var metal = Color(0.35, 0.3, 0.25)
	var metal_light = Color(0.5, 0.42, 0.32)
	var rust = Color(0.5, 0.32, 0.18)
	var glow = Color(1.0, 0.75, 0.25)
	var glow_dim = Color(0.9, 0.6, 0.15)
	var glow_outer = Color(0.6, 0.4, 0.1, 0.5)

	# Hook at top
	_px(img, 15, 2, metal)
	_px(img, 16, 2, metal)
	_px(img, 14, 3, metal)
	_px(img, 17, 3, metal)
	_px(img, 15, 4, metal_light)
	_px(img, 16, 4, metal_light)

	# Chain
	_px(img, 15, 5, metal)
	_px(img, 16, 5, metal)
	_px(img, 15, 6, metal_light)
	_px(img, 16, 6, metal_light)

	# Lantern top cap
	_fill(img, 12, 7, 8, 2, metal)
	_fill(img, 13, 7, 6, 1, metal_light)

	# Lantern body (glass area with glow)
	_fill(img, 12, 9, 1, 10, metal) # left frame
	_fill(img, 19, 9, 1, 10, metal) # right frame
	_fill(img, 13, 9, 6, 10, glow_dim) # inner glow
	_fill(img, 14, 11, 4, 6, glow) # bright center

	# Glow highlights
	_px(img, 15, 13, Color(1.0, 0.95, 0.7))
	_px(img, 16, 13, Color(1.0, 0.95, 0.7))
	_px(img, 15, 14, Color(1.0, 0.9, 0.6))
	_px(img, 16, 14, Color(1.0, 0.9, 0.6))

	# Outer glow aura
	for dx in range(-2, 3):
		for dy in range(-2, 3):
			var px_x = 16 + dx
			var px_y = 14 + dy
			if img.get_pixel(px_x, px_y).a < 0.1:
				_px(img, px_x, px_y, glow_outer)

	# Bottom cap
	_fill(img, 12, 19, 8, 2, metal)
	_fill(img, 13, 19, 6, 1, metal_light)

	# Bottom point
	_fill(img, 14, 21, 4, 1, metal)
	_fill(img, 15, 22, 2, 1, metal)

	# Rust spots
	_px(img, 12, 10, rust)
	_px(img, 19, 15, rust)
	_px(img, 13, 20, rust)
	_px(img, 18, 8, rust)

	_outline(img, Color(0.1, 0.08, 0.06))
	_save(img, "lantern.png")

# ==================== COFFIN ====================

func _gen_coffin() -> void:
	# Partially open wooden coffin, dark brown, tilted from ground
	var img = _img()
	var wood = Color(0.35, 0.22, 0.12)
	var wood_light = Color(0.45, 0.3, 0.18)
	var wood_dark = Color(0.25, 0.15, 0.08)
	var inside = Color(0.6, 0.55, 0.45)
	var inside_dark = Color(0.45, 0.4, 0.3)
	var nail = Color(0.5, 0.48, 0.42)

	# Coffin base (hexagonal shape, tilted slightly)
	# Bottom part of coffin
	_fill(img, 6, 18, 18, 8, wood)
	_fill(img, 8, 17, 14, 1, wood)
	_fill(img, 10, 16, 10, 1, wood)
	_fill(img, 7, 26, 16, 1, wood_dark)

	# Inside visible (lid open on left side)
	_fill(img, 7, 18, 16, 3, inside)
	_fill(img, 9, 17, 12, 1, inside)
	_fill(img, 10, 19, 8, 2, inside_dark)

	# Wood grain on coffin body
	_fill(img, 8, 22, 14, 1, wood_light)
	_fill(img, 8, 24, 14, 1, wood_dark)

	# Open lid (angled, going up-left)
	_fill(img, 2, 10, 10, 2, wood_light)
	_fill(img, 3, 12, 9, 2, wood)
	_fill(img, 4, 14, 8, 2, wood)
	_fill(img, 5, 16, 7, 2, wood_dark)
	# Lid edge
	_fill(img, 1, 10, 1, 2, wood_dark)
	_fill(img, 2, 12, 1, 2, wood_dark)

	# Nails / hardware
	_px(img, 8, 18, nail)
	_px(img, 22, 18, nail)
	_px(img, 8, 25, nail)
	_px(img, 22, 25, nail)
	# Cross on lid
	_fill(img, 6, 11, 1, 3, nail)
	_px(img, 5, 12, nail)
	_px(img, 7, 12, nail)

	# Ground
	_fill(img, 4, 27, 24, 2, Color(0.3, 0.25, 0.18))
	_fill(img, 3, 29, 26, 2, Color(0.25, 0.2, 0.15))

	_outline(img, Color(0.1, 0.07, 0.04))
	_save(img, "coffin.png")

# ==================== PUMPKIN ====================

func _gen_pumpkin() -> void:
	# Orange jack-o-lantern with carved face, green stem
	var img = _img()
	var orange = Color(0.9, 0.55, 0.1)
	var orange_dark = Color(0.75, 0.4, 0.05)
	var orange_light = Color(1.0, 0.7, 0.2)
	var stem = Color(0.2, 0.45, 0.1)
	var stem_dark = Color(0.15, 0.35, 0.08)
	var face = Color(0.95, 0.85, 0.2) # glowing yellow inside
	var face_dark = Color(0.3, 0.15, 0.05) # carved edge

	# Main pumpkin body
	_circle(img, 16, 19, 8, orange)
	_circle(img, 16, 19, 7, orange_light)

	# Pumpkin ridges (vertical dark lines)
	for y in range(12, 27):
		_px(img, 11, y, orange_dark)
		_px(img, 16, y, orange_dark)
		_px(img, 21, y, orange_dark)
	# Edge shading
	for y in range(14, 26):
		_px(img, 9, y, orange_dark)
		_px(img, 23, y, orange_dark)

	# Stem
	_fill(img, 15, 9, 3, 3, stem)
	_fill(img, 16, 8, 2, 1, stem)
	_px(img, 17, 7, stem_dark)
	_px(img, 16, 9, stem_dark)

	# Carved face - triangle eyes
	# Left eye
	_px(img, 13, 17, face)
	_px(img, 12, 18, face)
	_px(img, 13, 18, face)
	_px(img, 14, 18, face)
	_px(img, 13, 16, face_dark)

	# Right eye
	_px(img, 19, 17, face)
	_px(img, 18, 18, face)
	_px(img, 19, 18, face)
	_px(img, 20, 18, face)
	_px(img, 19, 16, face_dark)

	# Mouth (jagged grin)
	_fill(img, 12, 21, 9, 1, face)
	_fill(img, 13, 22, 7, 1, face)
	_px(img, 13, 21, face_dark)
	_px(img, 15, 21, face_dark)
	_px(img, 17, 21, face_dark)
	_px(img, 19, 21, face_dark)
	_px(img, 14, 20, face)
	_px(img, 18, 20, face)

	# Ground shadow
	_fill(img, 9, 27, 14, 2, Color(0.2, 0.18, 0.14))

	_outline(img, Color(0.15, 0.08, 0.02))
	_save(img, "pumpkin.png")

# ==================== MUSHROOM ====================

func _gen_mushroom() -> void:
	# Cluster of 3 small purple/gray mushrooms, slightly glowing
	var img = _img()
	var cap = Color(0.45, 0.25, 0.55)
	var cap_light = Color(0.6, 0.38, 0.7)
	var cap_dark = Color(0.32, 0.18, 0.4)
	var stem_col = Color(0.7, 0.68, 0.62)
	var stem_dark = Color(0.55, 0.52, 0.48)
	var glow = Color(0.55, 0.35, 0.65, 0.4)
	var spot = Color(0.72, 0.55, 0.8)

	# Mushroom 1 (center, tallest)
	# Stem
	_fill(img, 15, 18, 2, 8, stem_col)
	_fill(img, 15, 18, 1, 8, stem_dark)
	# Cap
	_circle(img, 16, 16, 4, cap)
	_fill(img, 13, 14, 7, 3, cap)
	_fill(img, 14, 13, 5, 1, cap_light)
	# Cap highlight
	_px(img, 15, 13, cap_light)
	_px(img, 16, 13, cap_light)
	# Spots
	_px(img, 14, 15, spot)
	_px(img, 17, 14, spot)
	_px(img, 16, 16, spot)

	# Mushroom 2 (left, shorter)
	# Stem
	_fill(img, 8, 22, 2, 5, stem_col)
	_px(img, 8, 22, stem_dark)
	# Cap
	_circle(img, 9, 20, 3, cap)
	_fill(img, 7, 19, 5, 2, cap)
	_px(img, 8, 18, cap_light)
	_px(img, 9, 18, cap_light)
	# Spot
	_px(img, 10, 19, spot)

	# Mushroom 3 (right, medium)
	# Stem
	_fill(img, 22, 21, 2, 6, stem_col)
	_px(img, 22, 21, stem_dark)
	# Cap
	_circle(img, 23, 19, 3, cap_dark)
	_fill(img, 21, 18, 5, 2, cap)
	_px(img, 22, 17, cap_light)
	_px(img, 23, 17, cap_light)
	# Spot
	_px(img, 24, 18, spot)

	# Glow effect around mushrooms
	for x in range(32):
		for y in range(32):
			if img.get_pixel(x, y).a < 0.1:
				# Check if near a mushroom cap pixel
				var near_cap = false
				for off in [Vector2i(-1,0), Vector2i(1,0), Vector2i(0,-1), Vector2i(0,1),
							Vector2i(-1,-1), Vector2i(1,-1), Vector2i(-1,1), Vector2i(1,1)]:
					var nx = x + off.x
					var ny = y + off.y
					if nx >= 0 and nx < 32 and ny >= 0 and ny < 32:
						var c = img.get_pixel(nx, ny)
						if c.a > 0.5 and c.b > 0.3 and c.r < 0.7:
							near_cap = true
							break
				if near_cap:
					_px(img, x, y, glow)

	# Ground
	_fill(img, 4, 27, 24, 2, Color(0.2, 0.18, 0.14))

	_outline(img, Color(0.12, 0.08, 0.15))
	_save(img, "mushroom.png")

# ==================== GROUND TILE ====================

func _gen_ground_cemetery() -> void:
	# 64x64 dark green/brown grass with dirt patches, pebbles, dead leaves
	var img = _img(G)
	var grass = Color(0.22, 0.32, 0.15)
	var grass2 = Color(0.2, 0.28, 0.13)
	var grass_dark = Color(0.16, 0.24, 0.1)
	var dirt = Color(0.35, 0.28, 0.18)
	var dirt_dark = Color(0.28, 0.22, 0.14)
	var pebble = Color(0.45, 0.42, 0.38)
	var pebble_dark = Color(0.35, 0.32, 0.28)
	var leaf = Color(0.5, 0.3, 0.1)
	var leaf_dark = Color(0.4, 0.22, 0.08)

	# Base fill: grass
	_fill(img, 0, 0, G, G, grass)

	# Grass variation patches
	var rng = RandomNumberGenerator.new()
	rng.seed = 42  # Deterministic

	for i in range(80):
		var px_x = rng.randi_range(0, G - 1)
		var px_y = rng.randi_range(0, G - 1)
		_px(img, px_x, px_y, grass2)

	for i in range(50):
		var px_x = rng.randi_range(0, G - 1)
		var px_y = rng.randi_range(0, G - 1)
		_px(img, px_x, px_y, grass_dark)

	# Dirt patches (several irregular areas)
	# Patch 1 (top-left area)
	_fill(img, 5, 8, 8, 6, dirt)
	_fill(img, 7, 6, 5, 2, dirt)
	_fill(img, 6, 14, 6, 2, dirt)
	_fill(img, 4, 10, 2, 3, dirt_dark)
	_fill(img, 12, 9, 2, 4, dirt_dark)

	# Patch 2 (center-right)
	_fill(img, 38, 28, 10, 8, dirt)
	_fill(img, 40, 26, 7, 2, dirt)
	_fill(img, 39, 36, 8, 2, dirt)
	_fill(img, 37, 30, 2, 4, dirt_dark)
	_fill(img, 47, 29, 2, 5, dirt_dark)

	# Patch 3 (bottom-left)
	_fill(img, 12, 48, 7, 5, dirt)
	_fill(img, 14, 46, 4, 2, dirt)
	_fill(img, 13, 53, 5, 2, dirt_dark)

	# Patch 4 (top-right)
	_fill(img, 50, 5, 6, 5, dirt)
	_fill(img, 48, 7, 2, 3, dirt_dark)

	# Pebbles scattered
	var pebble_positions = [
		Vector2i(20, 15), Vector2i(21, 15),
		Vector2i(35, 42), Vector2i(36, 42),
		Vector2i(55, 30), Vector2i(55, 31),
		Vector2i(10, 38),
		Vector2i(45, 12), Vector2i(46, 12),
		Vector2i(28, 55),
		Vector2i(3, 50),
		Vector2i(58, 58), Vector2i(59, 58),
		Vector2i(30, 25),
		Vector2i(50, 50),
		Vector2i(15, 30), Vector2i(16, 30),
	]
	for p in pebble_positions:
		_px(img, p.x, p.y, pebble)
	# Darker pebble shadows
	for p in pebble_positions:
		_px(img, p.x, p.y + 1, pebble_dark)

	# Dead leaves scattered
	var leaf_data = [
		Vector2i(25, 10), Vector2i(8, 42), Vector2i(52, 20),
		Vector2i(32, 50), Vector2i(42, 8), Vector2i(18, 58),
		Vector2i(55, 48), Vector2i(5, 25), Vector2i(60, 15),
		Vector2i(38, 55), Vector2i(22, 35), Vector2i(48, 38),
	]
	for p in leaf_data:
		# Small 2-3 pixel leaf shape
		_px(img, p.x, p.y, leaf)
		_px(img, p.x + 1, p.y, leaf)
		_px(img, p.x, p.y + 1, leaf_dark)

	# Edge blending: ensure it tiles well by making edges similar
	# Copy some grass variation to edges
	for i in range(G):
		if rng.randi_range(0, 3) == 0:
			_px(img, 0, i, grass2)
			_px(img, G - 1, i, grass2)
		if rng.randi_range(0, 3) == 0:
			_px(img, i, 0, grass2)
			_px(img, i, G - 1, grass2)

	# No outline for ground tile (it tiles)
	_save(img, "ground_cemetery.png")
