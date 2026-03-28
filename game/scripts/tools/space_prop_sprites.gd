extends SceneTree

## Generates 32x32 pixel art sprites for space station stage decoration props,
## plus a 64x64 tiled ground texture.
## Run: godot --headless --script res://scripts/tools/space_prop_sprites.gd

const S := 32  # Prop sprite size
const G := 64  # Ground tile size

func _init() -> void:
	_generate_all()
	quit()

func _generate_all() -> void:
	DirAccess.make_dir_recursive_absolute("res://assets/sprites/props/space")

	_gen_ground_space()
	_gen_console()
	_gen_crate()
	_gen_pipe()
	_gen_antenna()
	_gen_pod()
	_gen_barrel_toxic()
	_gen_light_panel()
	_gen_debris()
	_gen_portal()

	print("All space prop sprites generated!")

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
	var path = "res://assets/sprites/props/space/" + name
	img.save_png(path)
	print("Saved: ", path)

# ==================== GROUND ====================

func _gen_ground_space() -> void:
	# 64x64 dark metal floor with grid lines and panel seams
	var img = _img(G)
	var base = Color(0.12, 0.11, 0.15)
	var base2 = Color(0.14, 0.13, 0.17)
	var grid = Color(0.2, 0.19, 0.24)
	var seam = Color(0.08, 0.07, 0.1)
	var rivet = Color(0.25, 0.24, 0.28)

	# Base fill
	_fill(img, 0, 0, G, G, base)

	# Variation noise
	var rng = RandomNumberGenerator.new()
	rng.seed = 77
	for i in range(100):
		_px(img, rng.randi_range(0, G - 1), rng.randi_range(0, G - 1), base2)

	# Grid lines every 16 pixels
	for i in range(0, G, 16):
		_fill(img, i, 0, 1, G, grid)
		_fill(img, 0, i, G, 1, grid)

	# Panel seams (thinner, darker lines at 32px)
	_fill(img, 0, 0, G, 1, seam)
	_fill(img, 0, 32, G, 1, seam)
	_fill(img, 0, 0, 1, G, seam)
	_fill(img, 32, 0, 1, G, seam)

	# Corner rivets at panel intersections
	var rivet_pos = [
		Vector2i(2, 2), Vector2i(14, 2), Vector2i(18, 2), Vector2i(30, 2),
		Vector2i(34, 2), Vector2i(46, 2), Vector2i(50, 2), Vector2i(62, 2),
		Vector2i(2, 14), Vector2i(30, 14), Vector2i(34, 14), Vector2i(62, 14),
		Vector2i(2, 18), Vector2i(30, 18), Vector2i(34, 18), Vector2i(62, 18),
		Vector2i(2, 30), Vector2i(14, 30), Vector2i(18, 30), Vector2i(30, 30),
		Vector2i(34, 30), Vector2i(46, 30), Vector2i(50, 30), Vector2i(62, 30),
		Vector2i(2, 34), Vector2i(14, 34), Vector2i(18, 34), Vector2i(30, 34),
		Vector2i(34, 34), Vector2i(46, 34), Vector2i(50, 34), Vector2i(62, 34),
		Vector2i(2, 46), Vector2i(30, 46), Vector2i(34, 46), Vector2i(62, 46),
		Vector2i(2, 50), Vector2i(30, 50), Vector2i(34, 50), Vector2i(62, 50),
		Vector2i(2, 62), Vector2i(14, 62), Vector2i(18, 62), Vector2i(30, 62),
		Vector2i(34, 62), Vector2i(46, 62), Vector2i(50, 62), Vector2i(62, 62),
	]
	for p in rivet_pos:
		_px(img, p.x, p.y, rivet)

	_save(img, "ground_space.png")

# ==================== CONSOLE ====================

func _gen_console() -> void:
	# Blinking computer console with screen and buttons
	var img = _img()
	var body = Color(0.25, 0.25, 0.3)
	var body_dark = Color(0.18, 0.18, 0.22)
	var body_light = Color(0.32, 0.32, 0.38)
	var screen = Color(0.1, 0.35, 0.2)
	var screen_bright = Color(0.2, 0.6, 0.3)
	var button_red = Color(0.7, 0.2, 0.15)
	var button_green = Color(0.2, 0.6, 0.25)
	var button_blue = Color(0.2, 0.3, 0.7)

	# Body
	_fill(img, 8, 8, 16, 18, body)
	_fill(img, 8, 8, 2, 18, body_dark)
	_fill(img, 22, 8, 2, 18, body_light)
	_fill(img, 8, 8, 16, 2, body_light)

	# Screen area
	_fill(img, 10, 10, 12, 8, Color(0.05, 0.08, 0.05))
	_fill(img, 11, 11, 10, 6, screen)

	# Scan lines on screen
	for row in range(11, 17, 2):
		_fill(img, 11, row, 10, 1, screen_bright)

	# Text-like dots on screen
	_px(img, 12, 12, screen_bright)
	_px(img, 14, 12, screen_bright)
	_px(img, 16, 12, screen_bright)
	_px(img, 18, 12, screen_bright)
	_px(img, 12, 14, screen_bright)
	_px(img, 14, 14, screen_bright)
	_px(img, 16, 14, screen_bright)

	# Buttons below screen
	_fill(img, 11, 20, 2, 2, button_red)
	_fill(img, 14, 20, 2, 2, button_green)
	_fill(img, 17, 20, 2, 2, button_blue)

	# Base/stand
	_fill(img, 10, 26, 12, 2, body_dark)
	_fill(img, 12, 28, 8, 2, Color(0.15, 0.15, 0.18))

	_outline(img, Color(0.05, 0.05, 0.08))
	_save(img, "console.png")

# ==================== CRATE ====================

func _gen_crate() -> void:
	# Metal cargo crate with reinforced edges
	var img = _img()
	var metal = Color(0.35, 0.35, 0.38)
	var metal_dark = Color(0.25, 0.25, 0.28)
	var metal_light = Color(0.45, 0.45, 0.5)
	var edge = Color(0.5, 0.48, 0.42)
	var stripe = Color(0.6, 0.4, 0.1)

	# Main box
	_fill(img, 6, 8, 20, 18, metal)
	_fill(img, 6, 8, 2, 18, metal_dark)
	_fill(img, 24, 8, 2, 18, metal_light)
	_fill(img, 6, 8, 20, 2, metal_light)
	_fill(img, 6, 24, 20, 2, metal_dark)

	# Reinforced corner edges
	_fill(img, 6, 8, 3, 3, edge)
	_fill(img, 23, 8, 3, 3, edge)
	_fill(img, 6, 23, 3, 3, edge)
	_fill(img, 23, 23, 3, 3, edge)

	# Hazard stripes in center
	_fill(img, 10, 15, 12, 2, stripe)
	_fill(img, 10, 18, 12, 2, stripe)

	# Cross detail on front
	_fill(img, 15, 10, 2, 14, metal_light)
	_fill(img, 10, 16, 12, 1, metal_light)

	_outline(img, Color(0.08, 0.08, 0.1))
	_save(img, "crate.png")

# ==================== PIPE ====================

func _gen_pipe() -> void:
	# Industrial pipe section, vertical, with joints
	var img = _img()
	var pipe_col = Color(0.4, 0.42, 0.45)
	var pipe_dark = Color(0.28, 0.3, 0.32)
	var pipe_light = Color(0.55, 0.57, 0.6)
	var joint = Color(0.5, 0.5, 0.52)
	var joint_dark = Color(0.35, 0.35, 0.37)
	var rust = Color(0.45, 0.3, 0.15)

	# Main pipe body (vertical)
	_fill(img, 12, 2, 8, 28, pipe_col)
	_fill(img, 12, 2, 2, 28, pipe_dark)
	_fill(img, 18, 2, 2, 28, pipe_light)

	# Highlight stripe
	_fill(img, 16, 2, 1, 28, pipe_light)

	# Joints (wider rings)
	_fill(img, 10, 4, 12, 3, joint)
	_fill(img, 10, 4, 2, 3, joint_dark)
	_fill(img, 10, 14, 12, 3, joint)
	_fill(img, 10, 14, 2, 3, joint_dark)
	_fill(img, 10, 25, 12, 3, joint)
	_fill(img, 10, 25, 2, 3, joint_dark)

	# Rust spots
	_px(img, 14, 9, rust)
	_px(img, 15, 10, rust)
	_px(img, 13, 20, rust)
	_px(img, 16, 21, rust)
	_px(img, 15, 22, rust)

	_outline(img, Color(0.08, 0.08, 0.1))
	_save(img, "pipe.png")

# ==================== ANTENNA ====================

func _gen_antenna() -> void:
	# Satellite dish/antenna on a pole
	var img = _img()
	var pole = Color(0.4, 0.4, 0.42)
	var pole_dark = Color(0.3, 0.3, 0.32)
	var dish = Color(0.55, 0.55, 0.6)
	var dish_dark = Color(0.4, 0.4, 0.45)
	var dish_light = Color(0.7, 0.7, 0.75)
	var signal_col = Color(0.3, 0.6, 0.9)

	# Pole
	_fill(img, 15, 14, 2, 16, pole)
	_px(img, 15, 14, pole_dark)

	# Dish (arc shape)
	_fill(img, 6, 8, 20, 2, dish)
	_fill(img, 8, 6, 16, 2, dish)
	_fill(img, 10, 4, 12, 2, dish)
	_fill(img, 12, 3, 8, 1, dish)

	# Dish inner shading
	_fill(img, 10, 6, 6, 2, dish_dark)
	_fill(img, 8, 8, 6, 2, dish_dark)

	# Dish highlight
	_fill(img, 18, 5, 4, 2, dish_light)
	_fill(img, 20, 7, 4, 2, dish_light)

	# Feed horn (center)
	_fill(img, 15, 5, 2, 4, pole)
	_px(img, 15, 4, signal_col)
	_px(img, 16, 4, signal_col)

	# Signal waves
	_px(img, 14, 2, signal_col)
	_px(img, 17, 2, signal_col)
	_px(img, 13, 1, signal_col)
	_px(img, 18, 1, signal_col)

	# Base plate
	_fill(img, 12, 28, 8, 2, pole_dark)

	_outline(img, Color(0.05, 0.05, 0.08))
	_save(img, "antenna.png")

# ==================== POD ====================

func _gen_pod() -> void:
	# Cryo pod with window showing frost
	var img = _img()
	var body = Color(0.3, 0.32, 0.35)
	var body_dark = Color(0.2, 0.22, 0.25)
	var body_light = Color(0.42, 0.44, 0.48)
	var glass = Color(0.3, 0.5, 0.6, 0.8)
	var glass_light = Color(0.5, 0.7, 0.8, 0.9)
	var frost = Color(0.7, 0.85, 0.95)
	var inner = Color(0.08, 0.15, 0.2)

	# Main body (tall oval)
	_fill(img, 10, 4, 12, 24, body)
	_fill(img, 12, 2, 8, 2, body)
	_fill(img, 12, 28, 8, 2, body)

	# Left shadow
	_fill(img, 10, 4, 2, 24, body_dark)
	# Right highlight
	_fill(img, 20, 4, 2, 24, body_light)

	# Window (center oval)
	_fill(img, 12, 8, 8, 12, inner)
	_fill(img, 13, 7, 6, 1, inner)
	_fill(img, 13, 20, 6, 1, inner)

	# Glass tint
	_fill(img, 13, 9, 6, 10, glass)

	# Frost on glass
	_px(img, 13, 10, frost)
	_px(img, 14, 11, frost)
	_px(img, 13, 14, frost)
	_px(img, 18, 12, frost)
	_px(img, 17, 16, frost)
	_px(img, 18, 17, frost)

	# Glass highlight
	_fill(img, 17, 9, 1, 4, glass_light)

	# Control panel at bottom
	_fill(img, 12, 22, 8, 3, Color(0.22, 0.22, 0.25))
	_px(img, 13, 23, Color(0.2, 0.6, 0.2)) # green LED
	_px(img, 15, 23, Color(0.6, 0.2, 0.2)) # red LED
	_px(img, 17, 23, Color(0.2, 0.4, 0.7)) # blue LED

	# Base
	_fill(img, 9, 28, 14, 2, body_dark)

	_outline(img, Color(0.05, 0.05, 0.08))
	_save(img, "pod.png")

# ==================== BARREL TOXIC ====================

func _gen_barrel_toxic() -> void:
	# Yellow hazard barrel with warning symbol
	var img = _img()
	var yellow = Color(0.75, 0.65, 0.1)
	var yellow_dark = Color(0.55, 0.48, 0.08)
	var yellow_light = Color(0.85, 0.78, 0.2)
	var black = Color(0.1, 0.1, 0.1)
	var band = Color(0.15, 0.15, 0.15)
	var rust = Color(0.5, 0.3, 0.1)

	# Barrel body
	_fill(img, 10, 6, 12, 20, yellow)
	_fill(img, 11, 4, 10, 2, yellow)
	_fill(img, 11, 26, 10, 2, yellow)

	# Side shading
	_fill(img, 10, 6, 2, 20, yellow_dark)
	_fill(img, 20, 6, 2, 20, yellow_light)

	# Metal bands
	_fill(img, 9, 7, 14, 2, band)
	_fill(img, 9, 23, 14, 2, band)

	# Hazard triangle (radioactive symbol simplified)
	# Triangle outline
	_fill(img, 14, 11, 4, 1, black)
	_fill(img, 13, 12, 6, 1, black)
	_fill(img, 12, 13, 8, 1, black)
	_fill(img, 11, 14, 10, 1, black)
	_fill(img, 11, 15, 10, 1, black)
	_fill(img, 11, 16, 10, 1, black)
	_fill(img, 11, 17, 10, 1, black)
	# Inner yellow
	_fill(img, 14, 13, 4, 1, yellow)
	_fill(img, 13, 14, 6, 1, yellow)
	_fill(img, 13, 15, 6, 1, yellow)
	_fill(img, 13, 16, 6, 1, yellow)
	# Exclamation mark inside
	_fill(img, 15, 13, 2, 3, black)
	_px(img, 15, 17, black)
	_px(img, 16, 17, black)

	# Rust spots
	_px(img, 12, 19, rust)
	_px(img, 13, 20, rust)
	_px(img, 19, 10, rust)

	# Lid top
	_fill(img, 12, 4, 8, 2, band)

	_outline(img, Color(0.05, 0.05, 0.05))
	_save(img, "barrel_toxic.png")

# ==================== LIGHT PANEL ====================

func _gen_light_panel() -> void:
	# Ceiling light panel, rectangular, glowing white-blue
	var img = _img()
	var frame = Color(0.3, 0.3, 0.33)
	var frame_dark = Color(0.2, 0.2, 0.22)
	var glow = Color(0.7, 0.8, 0.95)
	var glow_bright = Color(0.9, 0.95, 1.0)
	var glow_dim = Color(0.5, 0.6, 0.75)

	# Outer frame
	_fill(img, 4, 10, 24, 12, frame)
	_fill(img, 4, 10, 24, 1, frame_dark)
	_fill(img, 4, 21, 24, 1, frame_dark)
	_fill(img, 4, 10, 1, 12, frame_dark)
	_fill(img, 27, 10, 1, 12, frame_dark)

	# Light surface
	_fill(img, 6, 12, 20, 8, glow)

	# Bright center
	_fill(img, 10, 14, 12, 4, glow_bright)

	# Dim edges
	_fill(img, 6, 12, 4, 8, glow_dim)
	_fill(img, 22, 12, 4, 8, glow_dim)

	# Divider lines
	_fill(img, 12, 12, 1, 8, frame)
	_fill(img, 19, 12, 1, 8, frame)

	# Mounting brackets
	_fill(img, 8, 9, 3, 1, frame_dark)
	_fill(img, 21, 9, 3, 1, frame_dark)

	_outline(img, Color(0.08, 0.08, 0.1))
	_save(img, "light_panel.png")

# ==================== DEBRIS ====================

func _gen_debris() -> void:
	# Floating space debris - metal chunks
	var img = _img()
	var metal = Color(0.38, 0.38, 0.4)
	var metal_dark = Color(0.25, 0.25, 0.28)
	var metal_light = Color(0.52, 0.52, 0.56)
	var wire = Color(0.6, 0.3, 0.15)

	# Chunk 1 (irregular shape top-left)
	_fill(img, 4, 6, 8, 6, metal)
	_fill(img, 6, 4, 5, 2, metal)
	_fill(img, 4, 6, 2, 6, metal_dark)
	_fill(img, 10, 6, 2, 4, metal_light)

	# Chunk 2 (bottom-right, rotated feel)
	_fill(img, 18, 16, 10, 8, metal)
	_fill(img, 20, 14, 7, 2, metal)
	_fill(img, 18, 16, 2, 8, metal_dark)
	_fill(img, 26, 16, 2, 6, metal_light)
	_fill(img, 19, 24, 8, 2, metal_dark)

	# Chunk 3 (small piece center)
	_fill(img, 14, 12, 5, 4, metal)
	_fill(img, 14, 12, 1, 4, metal_dark)

	# Dangling wires
	_px(img, 12, 10, wire)
	_px(img, 12, 11, wire)
	_px(img, 13, 12, wire)
	_px(img, 13, 13, wire)

	_px(img, 22, 24, wire)
	_px(img, 23, 25, wire)
	_px(img, 23, 26, wire)

	# Scratches
	_px(img, 6, 8, metal_light)
	_px(img, 7, 9, metal_light)
	_px(img, 21, 18, metal_light)
	_px(img, 22, 19, metal_light)

	_outline(img, Color(0.08, 0.08, 0.1))
	_save(img, "debris.png")

# ==================== PORTAL ====================

func _gen_portal() -> void:
	# Glowing blue portal ring
	var img = _img()
	var ring = Color(0.15, 0.3, 0.8)
	var ring_light = Color(0.3, 0.5, 1.0)
	var ring_bright = Color(0.6, 0.8, 1.0)
	var core = Color(0.1, 0.2, 0.5, 0.6)
	var glow = Color(0.2, 0.4, 0.9, 0.4)

	# Outer glow ring (large circle)
	_circle(img, 16, 16, 13, glow)

	# Main ring (donut shape - outer then clear inner)
	_circle(img, 16, 16, 12, ring)
	_circle(img, 16, 16, 9, Color(0, 0, 0, 0)) # clear center

	# Light side of ring
	_circle(img, 16, 16, 12, ring) # redraw base
	_circle(img, 16, 16, 9, Color(0, 0, 0, 0))

	# Bright highlights on ring
	# Top-right arc
	for angle_i in range(8):
		var ax = 16 + int(10.5 * cos(angle_i * 0.3 - 0.5))
		var ay = 16 + int(10.5 * sin(angle_i * 0.3 - 0.5))
		_px(img, ax, ay, ring_light)

	# Bottom-left bright
	for angle_i in range(6):
		var ax = 16 + int(11.0 * cos(angle_i * 0.3 + 2.5))
		var ay = 16 + int(11.0 * sin(angle_i * 0.3 + 2.5))
		_px(img, ax, ay, ring_bright)

	# Core swirl (inner area)
	_circle(img, 16, 16, 8, core)
	# Swirl lines
	_px(img, 14, 13, ring_light)
	_px(img, 15, 12, ring_light)
	_px(img, 17, 14, ring_light)
	_px(img, 18, 15, ring_light)
	_px(img, 16, 17, ring_light)
	_px(img, 14, 18, ring_light)
	_px(img, 13, 16, ring_light)
	_px(img, 19, 14, ring_light)

	# Bright center point
	_px(img, 16, 16, ring_bright)
	_px(img, 15, 16, ring_bright)
	_px(img, 16, 15, ring_bright)

	_outline(img, Color(0.05, 0.1, 0.3))
	_save(img, "portal.png")
