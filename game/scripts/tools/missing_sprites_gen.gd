extends SceneTree

## Gera sprites faltantes para elementos que usam mesh procedural.
## Run: godot --headless --path game --script res://scripts/tools/missing_sprites_gen.gd

const S32 := 32
const S64 := 64

func _init() -> void:
	_gen_meteor()
	_gen_boss_projectile()
	_gen_chest()
	_gen_lealith_walk()
	print("All missing sprites generated!")
	quit()

func _save(img: Image, path: String) -> void:
	var dir = path.get_base_dir()
	DirAccess.make_dir_recursive_absolute(dir)
	img.save_png(path)
	print("Saved: %s" % path)

func _fill(img: Image, x: int, y: int, w: int, h: int, c: Color, size: int) -> void:
	for px in range(maxi(x, 0), mini(x + w, size)):
		for py in range(maxi(y, 0), mini(y + h, size)):
			img.set_pixel(px, py, c)

func _outline(img: Image, color: Color, size: int) -> void:
	var copy = img.duplicate()
	for x in range(size):
		for y in range(size):
			if copy.get_pixel(x, y).a > 0:
				for dx in [-1, 0, 1]:
					for dy in [-1, 0, 1]:
						if dx == 0 and dy == 0: continue
						var nx = x + dx
						var ny = y + dy
						if nx >= 0 and nx < size and ny >= 0 and ny < size and copy.get_pixel(nx, ny).a == 0:
							img.set_pixel(nx, ny, color)

# ---- Meteor (32x32): fireball laranja com cauda) ----
func _gen_meteor() -> void:
	var img = Image.create(S32, S32, false, Image.FORMAT_RGBA8)
	# Core (bright yellow-white)
	_fill(img, 12, 10, 8, 8, Color(1.0, 0.9, 0.5), S32)
	# Inner flame (orange)
	_fill(img, 10, 8, 12, 12, Color(1.0, 0.5, 0.1), S32)
	# Core overlay (brightest)
	_fill(img, 13, 12, 6, 6, Color(1.0, 1.0, 0.7), S32)
	# Tail (upward, because meteor falls down)
	_fill(img, 13, 2, 2, 8, Color(1.0, 0.4, 0.0, 0.7), S32)
	_fill(img, 16, 3, 2, 7, Color(0.9, 0.3, 0.0, 0.5), S32)
	_fill(img, 11, 4, 2, 5, Color(0.8, 0.2, 0.0, 0.4), S32)
	# Smoke wisps
	_fill(img, 14, 0, 3, 3, Color(0.3, 0.3, 0.3, 0.3), S32)
	_outline(img, Color(0.4, 0.1, 0.0), S32)
	_save(img, "res://assets/sprites/effects/meteor.png")

# ---- Boss Projectile (16x16): energy orb ----
func _gen_boss_projectile() -> void:
	var img = Image.create(16, 16, false, Image.FORMAT_RGBA8)
	# Outer glow
	_fill(img, 3, 3, 10, 10, Color(0.8, 0.2, 0.2, 0.5), 16)
	# Core
	_fill(img, 5, 5, 6, 6, Color(1.0, 0.4, 0.3), 16)
	# Bright center
	_fill(img, 6, 6, 4, 4, Color(1.0, 0.8, 0.6), 16)
	# Brightest pixel
	img.set_pixel(7, 7, Color(1.0, 1.0, 0.9))
	img.set_pixel(8, 8, Color(1.0, 1.0, 0.9))
	_save(img, "res://assets/sprites/effects/boss_projectile.png")

# ---- Chest / Baú (32x32): golden treasure chest ----
func _gen_chest() -> void:
	var img = Image.create(S32, S32, false, Image.FORMAT_RGBA8)
	var gold = Color(0.85, 0.65, 0.1)
	var dark_gold = Color(0.6, 0.4, 0.05)
	var wood = Color(0.4, 0.25, 0.1)
	var dark_wood = Color(0.25, 0.15, 0.05)
	var metal = Color(0.5, 0.5, 0.55)
	# Body (wood)
	_fill(img, 4, 14, 24, 14, wood, S32)
	# Lid (wood, slightly lighter)
	_fill(img, 3, 8, 26, 7, wood.lightened(0.1), S32)
	# Lid top curve
	_fill(img, 5, 6, 22, 3, wood.lightened(0.15), S32)
	_fill(img, 8, 5, 16, 2, wood.lightened(0.2), S32)
	# Metal bands
	_fill(img, 4, 14, 24, 2, metal, S32)
	_fill(img, 4, 22, 24, 2, metal, S32)
	_fill(img, 4, 8, 24, 1, metal, S32)
	# Lock (gold)
	_fill(img, 13, 12, 6, 6, gold, S32)
	_fill(img, 14, 13, 4, 4, dark_gold, S32)
	# Keyhole
	img.set_pixel(15, 14, Color(0.1, 0.1, 0.1))
	img.set_pixel(16, 14, Color(0.1, 0.1, 0.1))
	img.set_pixel(15, 15, Color(0.1, 0.1, 0.1))
	img.set_pixel(16, 15, Color(0.1, 0.1, 0.1))
	# Corners (metal rivets)
	for cx in [5, 26]:
		for cy in [9, 15, 23]:
			img.set_pixel(cx, cy, Color(0.7, 0.7, 0.75))
	# Shine on lid
	_fill(img, 10, 6, 3, 1, Color(1.0, 0.9, 0.6, 0.6), S32)
	_outline(img, Color(0.15, 0.1, 0.05), S32)
	_save(img, "res://assets/sprites/pickups/chest.png")

# ---- Lealith Walk Spritesheet (128x32: 4 frames of 32x32) ----
func _gen_lealith_walk() -> void:
	# Load idle sprite as base
	var idle_path = "res://assets/sprites/characters/lealith.png"
	if not ResourceLoader.exists(idle_path):
		print("SKIP: lealith.png not found")
		return
	var idle = load(idle_path) as Texture2D
	var idle_img = idle.get_image()
	var w = idle_img.get_width()
	var h = idle_img.get_height()
	# Create 4-frame walk spritesheet (simple bob offsets)
	var sheet = Image.create(w * 4, h, false, Image.FORMAT_RGBA8)
	for frame in range(4):
		var offset_y = 0
		match frame:
			0: offset_y = 0
			1: offset_y = -1
			2: offset_y = 0
			3: offset_y = 1
		for x in range(w):
			for y in range(h):
				var src_y = clampi(y - offset_y, 0, h - 1)
				sheet.set_pixel(frame * w + x, y, idle_img.get_pixel(x, src_y))
	_save(sheet, "res://assets/sprites/characters/lealith_walk.png")
