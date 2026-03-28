extends SceneTree

## Generates 32x32 pixel art sprites for ocean stage decoration props,
## plus a 64x64 tiled ground texture.
## Run: godot --headless --script res://scripts/tools/ocean_prop_sprites.gd

const S := 32  # Prop sprite size
const G := 64  # Ground tile size

func _init() -> void:
	_generate_all()
	quit()

func _generate_all() -> void:
	DirAccess.make_dir_recursive_absolute("res://assets/sprites/props/ocean")

	_gen_coral_pink()
	_gen_coral_blue()
	_gen_seaweed()
	_gen_shell()
	_gen_anchor()
	_gen_treasure_chest()
	_gen_jellyfish()
	_gen_starfish()
	_gen_bubble_column()
	_gen_ground_ocean()

	print("All ocean prop sprites generated!")

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
	var path = "res://assets/sprites/props/ocean/" + name
	img.save_png(path)
	print("Saved: ", path)

# ==================== CORAL PINK ====================

func _gen_coral_pink() -> void:
	# Pink branching coral
	var img = _img()
	var coral = Color(0.9, 0.4, 0.5)
	var coral_light = Color(1.0, 0.6, 0.65)
	var coral_dark = Color(0.7, 0.25, 0.35)
	var base_col = Color(0.6, 0.55, 0.45)

	# Main trunk
	_fill(img, 14, 14, 4, 12, coral)
	_fill(img, 15, 12, 3, 2, coral)

	# Left branch
	_fill(img, 10, 8, 3, 6, coral)
	_fill(img, 12, 12, 3, 2, coral)
	_fill(img, 9, 6, 2, 3, coral)
	_px(img, 9, 5, coral_light)
	# Left sub-branch
	_fill(img, 7, 10, 3, 2, coral)
	_px(img, 6, 9, coral_light)

	# Right branch
	_fill(img, 19, 9, 3, 5, coral)
	_fill(img, 17, 12, 3, 2, coral)
	_fill(img, 20, 7, 2, 3, coral)
	_px(img, 21, 6, coral_light)
	# Right sub-branch
	_fill(img, 22, 11, 3, 2, coral)
	_px(img, 24, 10, coral_light)

	# Top branch
	_fill(img, 15, 6, 2, 6, coral)
	_fill(img, 14, 4, 3, 2, coral)
	_px(img, 15, 3, coral_light)

	# Highlights
	_fill(img, 17, 14, 1, 8, coral_light)
	_fill(img, 21, 9, 1, 4, coral_light)
	_fill(img, 12, 8, 1, 4, coral_light)

	# Dark edges
	_fill(img, 14, 14, 1, 12, coral_dark)
	_fill(img, 10, 8, 1, 6, coral_dark)
	_fill(img, 19, 9, 1, 5, coral_dark)

	# Tips - bumpy coral texture
	_circle(img, 9, 5, 1, coral_light)
	_circle(img, 21, 6, 1, coral_light)
	_circle(img, 6, 9, 1, coral_light)
	_circle(img, 24, 10, 1, coral_light)
	_circle(img, 15, 3, 1, coral_light)

	# Base rock
	_fill(img, 11, 26, 10, 2, base_col)
	_fill(img, 12, 28, 8, 2, Color(0.5, 0.45, 0.38))

	_outline(img, Color(0.4, 0.15, 0.2))
	_save(img, "coral_pink.png")

# ==================== CORAL BLUE ====================

func _gen_coral_blue() -> void:
	# Blue fan coral - flat spreading shape
	var img = _img()
	var coral = Color(0.2, 0.45, 0.75)
	var coral_light = Color(0.35, 0.6, 0.9)
	var coral_dark = Color(0.12, 0.3, 0.55)
	var base_col = Color(0.5, 0.48, 0.42)

	# Fan shape - wide at top, narrow at bottom
	_fill(img, 14, 18, 4, 8, coral)  # Stem

	# Fan layers (wider as you go up)
	_fill(img, 12, 14, 8, 4, coral)
	_fill(img, 10, 10, 12, 4, coral)
	_fill(img, 8, 6, 16, 4, coral)
	_fill(img, 7, 4, 18, 2, coral)

	# Horizontal veins
	_fill(img, 8, 5, 16, 1, coral_light)
	_fill(img, 9, 8, 14, 1, coral_light)
	_fill(img, 11, 11, 10, 1, coral_light)
	_fill(img, 13, 15, 6, 1, coral_light)

	# Dark edges
	_fill(img, 7, 4, 1, 6, coral_dark)
	_fill(img, 8, 6, 1, 4, coral_dark)
	_fill(img, 10, 10, 1, 4, coral_dark)

	# Right highlights
	_fill(img, 24, 4, 1, 2, coral_light)
	_fill(img, 23, 6, 1, 4, coral_light)
	_fill(img, 21, 10, 1, 4, coral_light)

	# Top edge detail
	_px(img, 9, 3, coral_light)
	_px(img, 13, 3, coral_light)
	_px(img, 18, 3, coral_light)
	_px(img, 22, 3, coral_light)

	# Base
	_fill(img, 12, 26, 8, 2, base_col)
	_fill(img, 13, 28, 6, 2, Color(0.42, 0.4, 0.35))

	_outline(img, Color(0.06, 0.15, 0.3))
	_save(img, "coral_blue.png")

# ==================== SEAWEED ====================

func _gen_seaweed() -> void:
	# Green swaying seaweed - tall wavy strands
	var img = _img()
	var green = Color(0.15, 0.5, 0.2)
	var green_light = Color(0.25, 0.65, 0.3)
	var green_dark = Color(0.08, 0.35, 0.12)
	var base_col = Color(0.45, 0.42, 0.35)

	# Left strand (wavy)
	_fill(img, 11, 22, 3, 6, green)
	_fill(img, 10, 18, 3, 4, green)
	_fill(img, 11, 14, 3, 4, green)
	_fill(img, 10, 10, 3, 4, green)
	_fill(img, 11, 6, 3, 4, green)
	_fill(img, 10, 4, 2, 2, green_light)
	_px(img, 10, 3, green_light)

	# Right strand
	_fill(img, 18, 22, 3, 6, green)
	_fill(img, 19, 18, 3, 4, green)
	_fill(img, 18, 14, 3, 4, green)
	_fill(img, 19, 10, 3, 4, green)
	_fill(img, 18, 7, 3, 3, green)
	_fill(img, 19, 5, 2, 2, green_light)
	_px(img, 20, 4, green_light)

	# Middle short strand
	_fill(img, 14, 22, 3, 6, green_dark)
	_fill(img, 15, 18, 3, 4, green_dark)
	_fill(img, 14, 14, 3, 4, green)
	_fill(img, 15, 11, 2, 3, green)
	_px(img, 15, 10, green_light)

	# Leaf details / highlights
	_px(img, 12, 7, green_light)
	_px(img, 12, 11, green_light)
	_px(img, 12, 15, green_light)
	_px(img, 20, 8, green_light)
	_px(img, 20, 12, green_light)
	_px(img, 20, 16, green_light)

	# Dark side accents
	_px(img, 10, 19, green_dark)
	_px(img, 11, 15, green_dark)
	_px(img, 18, 19, green_dark)
	_px(img, 18, 15, green_dark)

	# Base rock
	_fill(img, 9, 28, 14, 2, base_col)
	_fill(img, 10, 27, 12, 1, Color(0.4, 0.38, 0.3))

	_outline(img, Color(0.04, 0.2, 0.08))
	_save(img, "seaweed.png")

# ==================== SHELL ====================

func _gen_shell() -> void:
	# White/pink spiral seashell
	var img = _img()
	var shell = Color(0.92, 0.85, 0.8)
	var shell_pink = Color(0.95, 0.7, 0.72)
	var shell_dark = Color(0.7, 0.6, 0.55)
	var shell_light = Color(1.0, 0.95, 0.9)
	var sand = Color(0.75, 0.68, 0.55)

	# Main shell body (conch shape)
	_fill(img, 10, 10, 14, 12, shell)
	_fill(img, 8, 12, 16, 8, shell)
	_fill(img, 12, 8, 10, 2, shell)

	# Spiral lines (pink ridges)
	_fill(img, 10, 12, 14, 1, shell_pink)
	_fill(img, 9, 15, 14, 1, shell_pink)
	_fill(img, 10, 18, 12, 1, shell_pink)

	# Opening (left side)
	_fill(img, 8, 13, 3, 5, shell_pink)
	_fill(img, 7, 14, 2, 3, Color(0.9, 0.55, 0.58))

	# Highlight ridge
	_fill(img, 22, 10, 1, 10, shell_light)
	_fill(img, 20, 8, 2, 2, shell_light)

	# Shadow
	_fill(img, 10, 10, 1, 10, shell_dark)
	_fill(img, 12, 8, 1, 2, shell_dark)

	# Spiral center point
	_fill(img, 18, 12, 3, 3, shell_pink)
	_px(img, 19, 13, Color(0.85, 0.5, 0.52))

	# Top point of shell
	_fill(img, 20, 6, 3, 2, shell)
	_px(img, 21, 5, shell_pink)

	# Sand base
	_fill(img, 7, 22, 18, 3, sand)
	_fill(img, 9, 25, 14, 3, Color(0.68, 0.6, 0.48))

	_outline(img, Color(0.4, 0.35, 0.3))
	_save(img, "shell.png")

# ==================== ANCHOR ====================

func _gen_anchor() -> void:
	# Rusty iron anchor
	var img = _img()
	var iron = Color(0.35, 0.28, 0.22)
	var iron_light = Color(0.48, 0.38, 0.3)
	var iron_dark = Color(0.22, 0.16, 0.12)
	var rust = Color(0.55, 0.3, 0.15)
	var sand = Color(0.7, 0.63, 0.5)

	# Ring at top
	_fill(img, 14, 2, 4, 1, iron)
	_fill(img, 13, 3, 6, 1, iron)
	_fill(img, 12, 4, 2, 2, iron)
	_fill(img, 18, 4, 2, 2, iron)
	_fill(img, 13, 6, 6, 1, iron)
	_fill(img, 14, 5, 4, 1, Color(0, 0, 0, 0))  # hollow center
	# Top ring highlight
	_px(img, 18, 3, iron_light)
	_px(img, 19, 4, iron_light)

	# Shaft
	_fill(img, 15, 7, 2, 16, iron)
	_fill(img, 14, 7, 1, 16, iron_dark)

	# Cross bar
	_fill(img, 10, 12, 12, 2, iron)
	_fill(img, 10, 12, 12, 1, iron_light)

	# Bottom curve - left arm
	_fill(img, 9, 22, 7, 2, iron)
	_fill(img, 7, 20, 3, 2, iron)
	_fill(img, 7, 18, 2, 2, iron)
	# Fluke left
	_fill(img, 6, 17, 3, 2, iron_dark)
	_px(img, 5, 17, iron)

	# Bottom curve - right arm
	_fill(img, 16, 22, 7, 2, iron)
	_fill(img, 22, 20, 3, 2, iron)
	_fill(img, 23, 18, 2, 2, iron)
	# Fluke right
	_fill(img, 23, 17, 3, 2, iron_dark)
	_px(img, 26, 17, iron)

	# Rust spots
	_px(img, 15, 10, rust)
	_px(img, 16, 14, rust)
	_px(img, 11, 13, rust)
	_px(img, 20, 13, rust)
	_px(img, 8, 20, rust)
	_px(img, 23, 20, rust)

	# Sand at base
	_fill(img, 5, 24, 22, 3, sand)
	_fill(img, 7, 27, 18, 3, Color(0.62, 0.55, 0.42))

	_outline(img, Color(0.1, 0.08, 0.05))
	_save(img, "anchor.png")

# ==================== TREASURE CHEST ====================

func _gen_treasure_chest() -> void:
	# Half-buried golden chest
	var img = _img()
	var wood = Color(0.45, 0.25, 0.12)
	var wood_dark = Color(0.3, 0.16, 0.08)
	var gold = Color(0.85, 0.7, 0.2)
	var gold_light = Color(1.0, 0.85, 0.35)
	var gold_dark = Color(0.6, 0.45, 0.1)
	var sand = Color(0.7, 0.63, 0.5)

	# Chest body
	_fill(img, 8, 14, 16, 10, wood)
	# Rounded lid
	_fill(img, 8, 12, 16, 2, wood)
	_fill(img, 9, 10, 14, 2, wood)
	_fill(img, 10, 9, 12, 1, wood)

	# Dark wood planks
	_fill(img, 8, 14, 16, 1, wood_dark)
	_fill(img, 8, 18, 16, 1, wood_dark)
	_fill(img, 8, 22, 16, 1, wood_dark)

	# Gold trim bands
	_fill(img, 8, 12, 16, 1, gold)
	_fill(img, 8, 16, 16, 1, gold)
	_fill(img, 8, 20, 16, 1, gold)

	# Gold lock/clasp
	_fill(img, 14, 13, 4, 4, gold)
	_fill(img, 15, 14, 2, 2, gold_light)

	# Left edge shadow
	_fill(img, 8, 10, 1, 14, wood_dark)
	# Right edge highlight
	_fill(img, 23, 10, 1, 14, Color(0.55, 0.32, 0.16))

	# Gold corners
	_px(img, 8, 12, gold_dark)
	_px(img, 23, 12, gold_light)

	# Lid highlight
	_fill(img, 10, 9, 12, 1, Color(0.55, 0.32, 0.16))

	# Coins spilling out (lid slightly open)
	_px(img, 12, 11, gold_light)
	_px(img, 14, 10, gold)
	_px(img, 17, 11, gold_light)
	_px(img, 19, 10, gold)

	# Sand burying bottom half
	_fill(img, 6, 22, 20, 4, sand)
	_fill(img, 7, 21, 18, 1, sand)
	_fill(img, 8, 26, 16, 3, Color(0.62, 0.55, 0.42))

	_outline(img, Color(0.15, 0.08, 0.04))
	_save(img, "treasure_chest.png")

# ==================== JELLYFISH ====================

func _gen_jellyfish() -> void:
	# Translucent purple jellyfish
	var img = _img()
	var body = Color(0.6, 0.3, 0.75, 0.8)
	var body_light = Color(0.8, 0.5, 0.9, 0.7)
	var body_core = Color(0.9, 0.7, 1.0, 0.6)
	var tentacle = Color(0.5, 0.25, 0.65, 0.6)
	var tentacle_light = Color(0.7, 0.45, 0.85, 0.5)

	# Bell/dome
	_fill(img, 10, 6, 12, 8, body)
	_fill(img, 8, 8, 16, 4, body)
	_fill(img, 12, 4, 8, 2, body)
	_fill(img, 14, 3, 4, 1, body)

	# Inner glow
	_fill(img, 12, 6, 8, 6, body_light)
	_fill(img, 14, 5, 4, 2, body_core)

	# Bell rim
	_fill(img, 7, 12, 18, 2, body)
	_fill(img, 8, 14, 16, 1, body)

	# Tentacles - wavy lines going down
	# Left tentacles
	_fill(img, 9, 15, 2, 3, tentacle)
	_fill(img, 8, 18, 2, 3, tentacle)
	_fill(img, 9, 21, 2, 3, tentacle)
	_fill(img, 8, 24, 2, 3, tentacle_light)
	_px(img, 8, 27, tentacle_light)

	# Center-left tentacles
	_fill(img, 13, 15, 2, 3, tentacle)
	_fill(img, 12, 18, 2, 3, tentacle)
	_fill(img, 13, 21, 2, 4, tentacle)
	_px(img, 12, 25, tentacle_light)
	_px(img, 13, 26, tentacle_light)

	# Center-right tentacles
	_fill(img, 17, 15, 2, 3, tentacle)
	_fill(img, 18, 18, 2, 3, tentacle)
	_fill(img, 17, 21, 2, 3, tentacle)
	_px(img, 18, 24, tentacle_light)
	_px(img, 17, 25, tentacle_light)

	# Right tentacles
	_fill(img, 21, 15, 2, 3, tentacle)
	_fill(img, 22, 18, 2, 3, tentacle)
	_fill(img, 21, 21, 2, 3, tentacle_light)
	_px(img, 22, 24, tentacle_light)

	# Spots on bell
	_px(img, 12, 7, body_core)
	_px(img, 18, 8, body_core)
	_px(img, 15, 10, body_core)

	_outline(img, Color(0.3, 0.12, 0.4, 0.5))
	_save(img, "jellyfish.png")

# ==================== STARFISH ====================

func _gen_starfish() -> void:
	# Orange five-pointed starfish
	var img = _img()
	var star = Color(0.9, 0.5, 0.15)
	var star_light = Color(1.0, 0.65, 0.25)
	var star_dark = Color(0.7, 0.35, 0.1)
	var dot = Color(0.95, 0.75, 0.4)
	var sand = Color(0.7, 0.63, 0.5)

	# Center body
	_circle(img, 16, 16, 4, star)
	_circle(img, 16, 16, 2, star_light)

	# Five arms
	# Top arm
	_fill(img, 15, 6, 3, 6, star)
	_fill(img, 15, 4, 2, 2, star)
	_px(img, 15, 3, star_dark)
	_px(img, 17, 7, star_light)

	# Top-right arm
	_fill(img, 20, 9, 3, 3, star)
	_fill(img, 22, 7, 3, 3, star)
	_px(img, 24, 6, star_dark)
	_px(img, 21, 10, star_light)

	# Bottom-right arm
	_fill(img, 20, 18, 3, 3, star)
	_fill(img, 22, 20, 3, 3, star)
	_px(img, 24, 22, star_dark)
	_px(img, 21, 19, star_light)

	# Bottom-left arm
	_fill(img, 9, 18, 3, 3, star)
	_fill(img, 7, 20, 3, 3, star)
	_px(img, 7, 22, star_dark)
	_px(img, 10, 19, star_light)

	# Top-left arm
	_fill(img, 9, 9, 3, 3, star)
	_fill(img, 7, 7, 3, 3, star)
	_px(img, 7, 6, star_dark)
	_px(img, 10, 10, star_light)

	# Texture dots on arms
	_px(img, 16, 7, dot)
	_px(img, 22, 9, dot)
	_px(img, 22, 21, dot)
	_px(img, 9, 20, dot)
	_px(img, 9, 9, dot)
	_px(img, 16, 16, dot)

	# Sand beneath
	_fill(img, 6, 24, 20, 3, sand)
	_fill(img, 8, 27, 16, 3, Color(0.62, 0.55, 0.42))

	_outline(img, Color(0.45, 0.2, 0.05))
	_save(img, "starfish.png")

# ==================== BUBBLE COLUMN ====================

func _gen_bubble_column() -> void:
	# Rising air bubbles column
	var img = _img()
	var bubble = Color(0.6, 0.8, 0.95, 0.5)
	var bubble_light = Color(0.8, 0.92, 1.0, 0.6)
	var bubble_bright = Color(0.95, 1.0, 1.0, 0.8)

	# Large bottom bubble
	_circle(img, 16, 24, 4, bubble)
	_circle(img, 16, 24, 3, bubble_light)
	_px(img, 14, 22, bubble_bright)
	_px(img, 15, 22, bubble_bright)

	# Medium middle bubble
	_circle(img, 14, 16, 3, bubble)
	_circle(img, 14, 16, 2, bubble_light)
	_px(img, 13, 14, bubble_bright)

	# Medium-small bubble
	_circle(img, 17, 10, 2, bubble)
	_px(img, 16, 9, bubble_light)
	_px(img, 17, 9, bubble_bright)

	# Small top bubble
	_circle(img, 15, 5, 2, bubble)
	_px(img, 14, 4, bubble_bright)

	# Tiny bubbles
	_px(img, 12, 20, bubble)
	_px(img, 19, 14, bubble)
	_px(img, 13, 8, bubble)
	_px(img, 18, 3, bubble)
	_px(img, 11, 12, bubble)
	_px(img, 20, 7, bubble)

	# No outline for translucent bubbles - just subtle border
	_save(img, "bubble_column.png")

# ==================== GROUND TEXTURE ====================

func _gen_ground_ocean() -> void:
	# 64x64 sandy blue-teal ocean floor with seaweed patches
	var img = _img(G)
	var sand1 = Color(0.15, 0.3, 0.35)
	var sand2 = Color(0.12, 0.28, 0.32)
	var sand3 = Color(0.18, 0.33, 0.38)
	var weed = Color(0.1, 0.35, 0.18)
	var weed_light = Color(0.15, 0.42, 0.22)

	# Fill with sandy ocean floor
	for x in range(G):
		for y in range(G):
			var noise_val = ((x * 11 + y * 17) % 19) / 19.0
			if noise_val < 0.4:
				img.set_pixel(x, y, sand1)
			elif noise_val < 0.75:
				img.set_pixel(x, y, sand2)
			else:
				img.set_pixel(x, y, sand3)

	# Seaweed patches - cluster 1
	for x in range(10, 20):
		for y in range(8, 18):
			var d = ((x - 15) * (x - 15) + (y - 13) * (y - 13))
			if d < 20:
				img.set_pixel(x, y, weed)
			elif d < 28:
				if (x + y) % 3 == 0:
					img.set_pixel(x, y, weed_light)

	# Cluster 2
	for x in range(40, 52):
		for y in range(35, 48):
			var d = ((x - 46) * (x - 46) + (y - 42) * (y - 42))
			if d < 25:
				img.set_pixel(x, y, weed)
			elif d < 35:
				if (x + y) % 4 == 0:
					img.set_pixel(x, y, weed_light)

	# Cluster 3
	for x in range(5, 15):
		for y in range(45, 55):
			var d = ((x - 10) * (x - 10) + (y - 50) * (y - 50))
			if d < 18:
				img.set_pixel(x, y, weed)

	# Sand ripple lines
	for x in range(G):
		var y_rip = 25 + int(sin(x * 0.2) * 2)
		if y_rip >= 0 and y_rip < G:
			img.set_pixel(x, y_rip, sand3)
		y_rip = 55 + int(sin(x * 0.3) * 1.5)
		if y_rip >= 0 and y_rip < G:
			img.set_pixel(x, y_rip, sand3)

	# Small shell/rock highlights
	for i in range(15):
		var rx = (i * 41 + 5) % G
		var ry = (i * 29 + 13) % G
		img.set_pixel(rx, ry, Color(0.5, 0.48, 0.4))

	_save(img, "ground_ocean.png")
