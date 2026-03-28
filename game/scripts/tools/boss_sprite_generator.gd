extends SceneTree

## Generates pixel art sprites for ALL 10 boss types at 64x64.
## Run headless: godot --headless --path game --script res://scripts/tools/boss_sprite_generator.gd

const SPRITE_SIZE := 64
const OUT_DIR := "res://assets/sprites/bosses/"

func _init() -> void:
	_generate_necromancer()
	_generate_fairy_queen()
	_generate_alien_cow()
	_generate_ai_overlord()
	_generate_demon_lord()
	_generate_leviathan()
	_generate_emperor()
	_generate_singularity()
	_generate_dracula()
	_generate_sugar_king()
	print("All boss sprites generated!")
	quit()

func _save_sprite(img: Image, filename: String) -> void:
	DirAccess.make_dir_recursive_absolute(OUT_DIR)
	var path = OUT_DIR + filename
	img.save_png(path)
	print("Saved: ", path)

# ==================== HELPERS ====================
func _fill_rect(img: Image, x: int, y: int, w: int, h: int, color: Color) -> void:
	for px in range(x, mini(x + w, SPRITE_SIZE)):
		for py in range(y, mini(y + h, SPRITE_SIZE)):
			if px >= 0 and py >= 0:
				img.set_pixel(px, py, color)

func _add_outline(img: Image, color: Color) -> void:
	var outline_img = Image.create(SPRITE_SIZE, SPRITE_SIZE, false, Image.FORMAT_RGBA8)
	for x in range(SPRITE_SIZE):
		for y in range(SPRITE_SIZE):
			if img.get_pixel(x, y).a > 0:
				continue
			var has_neighbor := false
			for offset in [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]:
				var nx = x + offset.x
				var ny = y + offset.y
				if nx >= 0 and nx < SPRITE_SIZE and ny >= 0 and ny < SPRITE_SIZE:
					if img.get_pixel(nx, ny).a > 0:
						has_neighbor = true
						break
			if has_neighbor:
				outline_img.set_pixel(x, y, color)
	for x in range(SPRITE_SIZE):
		for y in range(SPRITE_SIZE):
			if outline_img.get_pixel(x, y).a > 0:
				img.set_pixel(x, y, outline_img.get_pixel(x, y))

func _set_px(img: Image, x: int, y: int, color: Color) -> void:
	if x >= 0 and x < SPRITE_SIZE and y >= 0 and y < SPRITE_SIZE:
		img.set_pixel(x, y, color)

func _draw_circle(img: Image, cx: int, cy: int, r: int, color: Color) -> void:
	for x in range(cx - r, cx + r + 1):
		for y in range(cy - r, cy + r + 1):
			if (x - cx) * (x - cx) + (y - cy) * (y - cy) <= r * r:
				_set_px(img, x, y, color)

func _draw_line_h(img: Image, x1: int, x2: int, y: int, color: Color) -> void:
	for x in range(x1, x2 + 1):
		_set_px(img, x, y, color)

func _draw_line_v(img: Image, x: int, y1: int, y2: int, color: Color) -> void:
	for y in range(y1, y2 + 1):
		_set_px(img, x, y, color)

# ==================== BOSS 1: NECROMANCER ====================
func _generate_necromancer() -> void:
	var img = Image.create(SPRITE_SIZE, SPRITE_SIZE, false, Image.FORMAT_RGBA8)
	var robe = Color(0.22, 0.08, 0.30)
	var robe_dark = Color(0.12, 0.04, 0.18)
	var robe_light = Color(0.35, 0.15, 0.45)
	var skin = Color(0.55, 0.65, 0.55)
	var eye_glow = Color(0.2, 0.95, 0.2)
	var eye_glow_bright = Color(0.5, 1.0, 0.5)
	var skull = Color(0.85, 0.85, 0.78)
	var skull_dark = Color(0.6, 0.58, 0.52)
	var staff = Color(0.35, 0.25, 0.18)
	var staff_dark = Color(0.22, 0.15, 0.1)
	var aura = Color(0.3, 0.9, 0.3, 0.25)
	var aura_bright = Color(0.4, 1.0, 0.5, 0.4)
	var outline = Color(0.08, 0.02, 0.12)

	# Ghostly aura (background glow)
	_draw_circle(img, 32, 30, 26, aura)
	_draw_circle(img, 32, 28, 20, aura_bright)

	# Hood (large pointed hood)
	_fill_rect(img, 22, 4, 20, 3, robe_dark)
	_fill_rect(img, 20, 7, 24, 3, robe)
	_fill_rect(img, 18, 10, 28, 5, robe)
	_fill_rect(img, 17, 15, 30, 3, robe)
	# Hood point
	_fill_rect(img, 29, 1, 6, 3, robe_dark)
	_fill_rect(img, 30, 0, 4, 2, robe_dark)
	_fill_rect(img, 31, 0, 2, 1, robe)

	# Face in shadow (just eyes visible)
	_fill_rect(img, 22, 12, 20, 8, robe_dark)
	# Glowing green eyes
	_fill_rect(img, 25, 14, 4, 3, eye_glow)
	_fill_rect(img, 35, 14, 4, 3, eye_glow)
	_fill_rect(img, 26, 15, 2, 1, eye_glow_bright)
	_fill_rect(img, 36, 15, 2, 1, eye_glow_bright)

	# Robes body (flowing)
	_fill_rect(img, 16, 18, 32, 6, robe)
	_fill_rect(img, 14, 24, 36, 6, robe)
	_fill_rect(img, 13, 30, 38, 6, robe_dark)
	_fill_rect(img, 12, 36, 40, 8, robe)
	_fill_rect(img, 11, 44, 42, 6, robe_dark)
	_fill_rect(img, 10, 50, 44, 4, robe)
	_fill_rect(img, 12, 54, 40, 4, robe_dark)
	_fill_rect(img, 14, 58, 36, 4, robe)

	# Robe highlights (folds)
	_fill_rect(img, 20, 26, 3, 14, robe_light)
	_fill_rect(img, 38, 28, 3, 12, robe_light)
	_fill_rect(img, 28, 44, 4, 10, robe_light)

	# Hands (skeletal/green)
	_fill_rect(img, 12, 30, 4, 5, skin)
	_fill_rect(img, 48, 30, 4, 5, skin)

	# Staff (right side)
	_fill_rect(img, 50, 6, 3, 50, staff)
	_fill_rect(img, 49, 8, 1, 46, staff_dark)

	# Skull on top of staff
	_fill_rect(img, 48, 2, 7, 6, skull)
	_fill_rect(img, 49, 1, 5, 2, skull)
	_fill_rect(img, 50, 0, 3, 2, skull)
	# Skull eyes
	_fill_rect(img, 49, 3, 2, 2, robe_dark)
	_fill_rect(img, 52, 3, 2, 2, robe_dark)
	# Skull nose
	_set_px(img, 51, 5, skull_dark)
	# Skull teeth
	_fill_rect(img, 49, 6, 5, 1, skull)
	_set_px(img, 50, 7, skull)
	_set_px(img, 52, 7, skull)
	# Skull glow
	_fill_rect(img, 49, 3, 2, 2, eye_glow)
	_fill_rect(img, 52, 3, 2, 2, eye_glow)

	# Bottom robe tattered edges
	for i in range(6):
		var bx = 14 + i * 7
		_fill_rect(img, bx, 60, 3, 3, robe_dark)
		_fill_rect(img, bx + 3, 61, 2, 2, robe)

	_add_outline(img, outline)
	_save_sprite(img, "boss_necromancer.png")

# ==================== BOSS 2: FAIRY QUEEN ====================
func _generate_fairy_queen() -> void:
	var img = Image.create(SPRITE_SIZE, SPRITE_SIZE, false, Image.FORMAT_RGBA8)
	var dress = Color(0.2, 0.55, 0.25)
	var dress_light = Color(0.3, 0.7, 0.35)
	var dress_dark = Color(0.12, 0.4, 0.15)
	var skin = Color(0.95, 0.82, 0.72)
	var skin_shadow = Color(0.82, 0.68, 0.58)
	var hair = Color(0.95, 0.85, 0.4)
	var hair_dark = Color(0.8, 0.7, 0.3)
	var wing_pink = Color(0.95, 0.5, 0.65, 0.7)
	var wing_pink_light = Color(1.0, 0.7, 0.8, 0.5)
	var wing_green = Color(0.4, 0.85, 0.5, 0.7)
	var wing_green_light = Color(0.6, 1.0, 0.7, 0.5)
	var crown_flower = Color(0.95, 0.4, 0.5)
	var crown_leaf = Color(0.3, 0.7, 0.3)
	var crown_yellow = Color(1.0, 0.9, 0.3)
	var eye = Color(0.2, 0.6, 0.9)
	var lip = Color(0.85, 0.4, 0.45)
	var outline = Color(0.1, 0.25, 0.1)

	# Left wing (butterfly shape - pink/green)
	# Upper left wing
	_fill_rect(img, 2, 10, 14, 4, wing_pink)
	_fill_rect(img, 4, 8, 10, 3, wing_pink)
	_fill_rect(img, 6, 6, 8, 3, wing_pink_light)
	_fill_rect(img, 3, 14, 12, 3, wing_green)
	_fill_rect(img, 5, 11, 6, 2, wing_pink_light)
	# Lower left wing
	_fill_rect(img, 4, 20, 12, 4, wing_green)
	_fill_rect(img, 6, 24, 10, 3, wing_green_light)
	_fill_rect(img, 8, 27, 6, 2, wing_green)
	_fill_rect(img, 6, 21, 4, 2, wing_green_light)

	# Right wing (mirror)
	_fill_rect(img, 48, 10, 14, 4, wing_pink)
	_fill_rect(img, 50, 8, 10, 3, wing_pink)
	_fill_rect(img, 50, 6, 8, 3, wing_pink_light)
	_fill_rect(img, 49, 14, 12, 3, wing_green)
	_fill_rect(img, 52, 11, 6, 2, wing_pink_light)
	_fill_rect(img, 48, 20, 12, 4, wing_green)
	_fill_rect(img, 48, 24, 10, 3, wing_green_light)
	_fill_rect(img, 50, 27, 6, 2, wing_green)
	_fill_rect(img, 54, 21, 4, 2, wing_green_light)

	# Head
	_fill_rect(img, 26, 8, 12, 12, skin)
	_fill_rect(img, 25, 10, 14, 8, skin)
	_fill_rect(img, 27, 7, 10, 2, skin)
	# Face shadow
	_fill_rect(img, 26, 16, 12, 2, skin_shadow)

	# Hair (flowing golden)
	_fill_rect(img, 24, 6, 16, 4, hair)
	_fill_rect(img, 23, 8, 4, 10, hair)
	_fill_rect(img, 37, 8, 4, 10, hair)
	_fill_rect(img, 23, 5, 18, 3, hair_dark)
	# Hair flowing down sides
	_fill_rect(img, 22, 16, 3, 14, hair)
	_fill_rect(img, 39, 16, 3, 14, hair)
	_fill_rect(img, 21, 22, 2, 10, hair_dark)
	_fill_rect(img, 41, 22, 2, 10, hair_dark)

	# Flower crown
	_fill_rect(img, 25, 5, 3, 3, crown_flower)
	_fill_rect(img, 30, 4, 4, 3, crown_yellow)
	_fill_rect(img, 36, 5, 3, 3, crown_flower)
	_fill_rect(img, 28, 5, 2, 2, crown_leaf)
	_fill_rect(img, 34, 5, 2, 2, crown_leaf)
	_set_px(img, 31, 3, crown_yellow)
	_set_px(img, 32, 3, crown_yellow)

	# Eyes
	_fill_rect(img, 28, 12, 3, 3, Color.WHITE)
	_fill_rect(img, 34, 12, 3, 3, Color.WHITE)
	_fill_rect(img, 29, 13, 2, 2, eye)
	_fill_rect(img, 35, 13, 2, 2, eye)
	_set_px(img, 29, 13, Color(0.1, 0.1, 0.1))
	_set_px(img, 35, 13, Color(0.1, 0.1, 0.1))
	# Eyelashes
	_set_px(img, 27, 12, Color(0.1, 0.1, 0.1))
	_set_px(img, 37, 12, Color(0.1, 0.1, 0.1))

	# Small nose and lips
	_set_px(img, 32, 15, skin_shadow)
	_fill_rect(img, 30, 17, 4, 1, lip)

	# Dress body
	_fill_rect(img, 25, 20, 14, 6, dress)
	_fill_rect(img, 23, 26, 18, 6, dress)
	_fill_rect(img, 21, 32, 22, 6, dress_light)
	_fill_rect(img, 19, 38, 26, 6, dress)
	_fill_rect(img, 18, 44, 28, 6, dress_dark)
	_fill_rect(img, 17, 50, 30, 6, dress)
	_fill_rect(img, 19, 56, 26, 4, dress_light)
	_fill_rect(img, 21, 60, 22, 3, dress)

	# Dress details (leaf patterns)
	_fill_rect(img, 27, 34, 2, 4, crown_leaf)
	_fill_rect(img, 35, 36, 2, 4, crown_leaf)
	_fill_rect(img, 24, 42, 2, 3, crown_leaf)
	_fill_rect(img, 38, 44, 2, 3, crown_leaf)

	# Arms
	_fill_rect(img, 19, 22, 4, 3, skin)
	_fill_rect(img, 41, 22, 4, 3, skin)
	_fill_rect(img, 17, 25, 4, 8, dress)
	_fill_rect(img, 43, 25, 4, 8, dress)
	_fill_rect(img, 16, 32, 3, 3, skin)
	_fill_rect(img, 45, 32, 3, 3, skin)

	_add_outline(img, outline)
	_save_sprite(img, "boss_fairy_queen.png")

# ==================== BOSS 3: ALIEN COW ====================
func _generate_alien_cow() -> void:
	var img = Image.create(SPRITE_SIZE, SPRITE_SIZE, false, Image.FORMAT_RGBA8)
	var body = Color(0.92, 0.92, 0.90)
	var body_shadow = Color(0.78, 0.78, 0.76)
	var spots = Color(0.15, 0.15, 0.15)
	var tech_green = Color(0.1, 0.9, 0.3)
	var tech_green_bright = Color(0.3, 1.0, 0.5)
	var tech_dark = Color(0.15, 0.2, 0.15)
	var eye_green = Color(0.0, 1.0, 0.2)
	var nose_pink = Color(0.9, 0.65, 0.65)
	var horn = Color(0.7, 0.7, 0.65)
	var antenna_metal = Color(0.6, 0.65, 0.6)
	var hoof = Color(0.4, 0.35, 0.3)
	var outline = Color(0.1, 0.15, 0.1)

	# Body (large cow shape)
	_fill_rect(img, 12, 22, 40, 24, body)
	_fill_rect(img, 14, 20, 36, 4, body)
	_fill_rect(img, 10, 26, 44, 16, body)
	_fill_rect(img, 14, 46, 36, 4, body_shadow)

	# Head (front facing, large)
	_fill_rect(img, 18, 8, 28, 16, body)
	_fill_rect(img, 20, 6, 24, 4, body)
	_fill_rect(img, 22, 5, 20, 2, body)

	# Horns
	_fill_rect(img, 16, 6, 4, 3, horn)
	_fill_rect(img, 14, 4, 4, 3, horn)
	_fill_rect(img, 44, 6, 4, 3, horn)
	_fill_rect(img, 46, 4, 4, 3, horn)

	# Antenna (alien tech)
	_fill_rect(img, 31, 0, 2, 6, antenna_metal)
	_draw_circle(img, 32, 0, 2, tech_green_bright)
	_set_px(img, 32, 0, tech_green)

	# Black cow spots
	_fill_rect(img, 16, 28, 6, 5, spots)
	_fill_rect(img, 38, 26, 7, 6, spots)
	_fill_rect(img, 26, 36, 8, 5, spots)
	_fill_rect(img, 14, 38, 5, 4, spots)
	_fill_rect(img, 44, 34, 5, 5, spots)

	# Glowing green eyes (alien)
	_fill_rect(img, 22, 11, 6, 5, eye_green)
	_fill_rect(img, 36, 11, 6, 5, eye_green)
	_fill_rect(img, 23, 12, 4, 3, tech_green_bright)
	_fill_rect(img, 37, 12, 4, 3, tech_green_bright)
	_fill_rect(img, 24, 13, 2, 1, Color(1.0, 1.0, 1.0))
	_fill_rect(img, 38, 13, 2, 1, Color(1.0, 1.0, 1.0))

	# Nose/snout
	_fill_rect(img, 26, 18, 12, 5, nose_pink)
	_fill_rect(img, 28, 17, 8, 2, nose_pink)
	_fill_rect(img, 29, 20, 2, 2, spots)
	_fill_rect(img, 33, 20, 2, 2, spots)

	# Tech implants (green circuits on body)
	_fill_rect(img, 10, 30, 3, 8, tech_dark)
	_fill_rect(img, 11, 31, 1, 6, tech_green)
	_fill_rect(img, 51, 30, 3, 8, tech_dark)
	_fill_rect(img, 52, 31, 1, 6, tech_green)
	# Circuit lines on sides
	_draw_line_h(img, 13, 18, 32, tech_green)
	_draw_line_h(img, 46, 51, 32, tech_green)
	_draw_line_h(img, 13, 16, 36, tech_green)
	_draw_line_h(img, 48, 51, 36, tech_green)

	# Legs
	_fill_rect(img, 16, 46, 6, 12, body_shadow)
	_fill_rect(img, 42, 46, 6, 12, body_shadow)
	_fill_rect(img, 26, 48, 5, 10, body_shadow)
	_fill_rect(img, 35, 48, 5, 10, body_shadow)
	# Hooves
	_fill_rect(img, 16, 56, 6, 4, hoof)
	_fill_rect(img, 42, 56, 6, 4, hoof)
	_fill_rect(img, 26, 56, 5, 4, hoof)
	_fill_rect(img, 35, 56, 5, 4, hoof)

	# Udder tech (glowing)
	_fill_rect(img, 28, 46, 8, 3, tech_dark)
	_fill_rect(img, 29, 47, 6, 1, tech_green)

	_add_outline(img, outline)
	_save_sprite(img, "boss_alien_cow.png")

# ==================== BOSS 4: AI OVERLORD ====================
func _generate_ai_overlord() -> void:
	var img = Image.create(SPRITE_SIZE, SPRITE_SIZE, false, Image.FORMAT_RGBA8)
	var monitor = Color(0.15, 0.15, 0.18)
	var monitor_edge = Color(0.25, 0.25, 0.3)
	var screen = Color(0.05, 0.12, 0.15)
	var cyan = Color(0.0, 0.9, 0.95)
	var cyan_bright = Color(0.4, 1.0, 1.0)
	var cyan_dim = Color(0.0, 0.5, 0.55)
	var body_dark = Color(0.08, 0.08, 0.12)
	var body_poly = Color(0.12, 0.18, 0.22)
	var body_edge = Color(0.0, 0.6, 0.7, 0.6)
	var outline = Color(0.0, 0.3, 0.35)

	# Monitor/TV head
	_fill_rect(img, 16, 2, 32, 24, monitor)
	_fill_rect(img, 18, 4, 28, 20, screen)
	# Monitor frame highlights
	_draw_line_h(img, 16, 47, 2, monitor_edge)
	_draw_line_h(img, 16, 47, 25, monitor_edge)
	_draw_line_v(img, 16, 2, 25, monitor_edge)
	_draw_line_v(img, 47, 2, 25, monitor_edge)

	# Face on screen (digital, cyan)
	# Eyes (rectangular, glitchy)
	_fill_rect(img, 22, 10, 6, 4, cyan)
	_fill_rect(img, 36, 10, 6, 4, cyan)
	_fill_rect(img, 23, 11, 4, 2, cyan_bright)
	_fill_rect(img, 37, 11, 4, 2, cyan_bright)
	# Angry eyebrow lines
	_draw_line_h(img, 22, 27, 8, cyan)
	_draw_line_h(img, 36, 41, 8, cyan)
	_set_px(img, 22, 9, cyan)
	_set_px(img, 41, 9, cyan)

	# Mouth (digital grin)
	_draw_line_h(img, 24, 39, 18, cyan)
	_draw_line_h(img, 24, 39, 19, cyan_dim)
	_set_px(img, 23, 17, cyan)
	_set_px(img, 40, 17, cyan)
	# Teeth-like segments
	for i in range(8):
		_set_px(img, 25 + i * 2, 17, cyan_bright)

	# Static/scan lines on screen
	for y_line in range(5, 23, 3):
		for x_scan in range(19, 46, 4):
			_set_px(img, x_scan, y_line, cyan_dim)

	# Neck connection
	_fill_rect(img, 28, 26, 8, 4, monitor)

	# Floating polygonal body (geometric torso)
	# Main diamond/polygon shape
	_fill_rect(img, 24, 30, 16, 4, body_poly)
	_fill_rect(img, 20, 34, 24, 8, body_poly)
	_fill_rect(img, 18, 38, 28, 6, body_dark)
	_fill_rect(img, 20, 44, 24, 4, body_poly)
	_fill_rect(img, 22, 48, 20, 4, body_dark)
	_fill_rect(img, 24, 52, 16, 3, body_poly)
	_fill_rect(img, 26, 55, 12, 2, body_dark)

	# Edge glow lines (wireframe effect)
	_draw_line_v(img, 20, 34, 44, body_edge)
	_draw_line_v(img, 43, 34, 44, body_edge)
	_draw_line_h(img, 20, 43, 34, body_edge)
	_draw_line_h(img, 22, 41, 48, body_edge)
	# Diagonal wireframe lines
	for i in range(8):
		_set_px(img, 24 - i / 2, 30 + i, body_edge)
		_set_px(img, 39 + i / 2, 30 + i, body_edge)

	# Floating arm-like extensions (left)
	_fill_rect(img, 8, 32, 10, 3, body_poly)
	_fill_rect(img, 4, 34, 8, 3, body_dark)
	_fill_rect(img, 2, 36, 6, 3, body_poly)
	_draw_line_h(img, 2, 17, 33, body_edge)

	# Right arm
	_fill_rect(img, 46, 32, 10, 3, body_poly)
	_fill_rect(img, 52, 34, 8, 3, body_dark)
	_fill_rect(img, 56, 36, 6, 3, body_poly)
	_draw_line_h(img, 46, 61, 33, body_edge)

	# Glowing core in chest
	_draw_circle(img, 32, 40, 3, cyan)
	_draw_circle(img, 32, 40, 1, cyan_bright)

	# Floating particles around
	_set_px(img, 6, 20, cyan)
	_set_px(img, 58, 16, cyan)
	_set_px(img, 10, 50, cyan_dim)
	_set_px(img, 54, 48, cyan_dim)
	_set_px(img, 14, 8, cyan)
	_set_px(img, 50, 54, cyan)

	_add_outline(img, outline)
	_save_sprite(img, "boss_ai_overlord.png")

# ==================== BOSS 5: DEMON LORD ====================
func _generate_demon_lord() -> void:
	var img = Image.create(SPRITE_SIZE, SPRITE_SIZE, false, Image.FORMAT_RGBA8)
	var skin = Color(0.75, 0.15, 0.12)
	var skin_dark = Color(0.55, 0.1, 0.08)
	var skin_light = Color(0.9, 0.25, 0.18)
	var horn = Color(0.3, 0.12, 0.08)
	var horn_tip = Color(0.15, 0.06, 0.04)
	var eye_yellow = Color(1.0, 0.9, 0.1)
	var eye_red = Color(1.0, 0.1, 0.0)
	var teeth = Color(0.95, 0.95, 0.9)
	var wing_membrane = Color(0.5, 0.1, 0.08, 0.85)
	var wing_bone = Color(0.3, 0.08, 0.05)
	var fire = Color(1.0, 0.6, 0.0)
	var fire_bright = Color(1.0, 0.9, 0.2)
	var fire_dark = Color(0.9, 0.3, 0.0)
	var sword = Color(0.7, 0.7, 0.72)
	var sword_glow = Color(1.0, 0.5, 0.1)
	var muscle = Color(0.65, 0.12, 0.1)
	var outline = Color(0.2, 0.02, 0.0)

	# Horns (large, curving up)
	# Left horn
	_fill_rect(img, 14, 8, 4, 3, horn)
	_fill_rect(img, 12, 5, 4, 4, horn)
	_fill_rect(img, 10, 2, 4, 4, horn_tip)
	_fill_rect(img, 8, 0, 4, 3, horn_tip)
	# Right horn
	_fill_rect(img, 46, 8, 4, 3, horn)
	_fill_rect(img, 48, 5, 4, 4, horn)
	_fill_rect(img, 50, 2, 4, 4, horn_tip)
	_fill_rect(img, 52, 0, 4, 3, horn_tip)

	# Head
	_fill_rect(img, 22, 6, 20, 14, skin)
	_fill_rect(img, 20, 8, 24, 10, skin)
	_fill_rect(img, 18, 10, 28, 6, skin)

	# Brow ridge (menacing)
	_fill_rect(img, 20, 8, 24, 2, skin_dark)

	# Eyes (fierce yellow/red)
	_fill_rect(img, 24, 11, 5, 4, eye_yellow)
	_fill_rect(img, 36, 11, 5, 4, eye_yellow)
	_fill_rect(img, 25, 12, 3, 2, eye_red)
	_fill_rect(img, 37, 12, 3, 2, eye_red)
	_set_px(img, 26, 12, Color(0.1, 0.0, 0.0))
	_set_px(img, 38, 12, Color(0.1, 0.0, 0.0))

	# Mouth with fangs
	_fill_rect(img, 24, 17, 16, 3, Color(0.3, 0.02, 0.0))
	# Upper fangs
	_fill_rect(img, 25, 17, 2, 3, teeth)
	_fill_rect(img, 29, 17, 2, 2, teeth)
	_fill_rect(img, 33, 17, 2, 2, teeth)
	_fill_rect(img, 37, 17, 2, 3, teeth)

	# Muscular torso
	_fill_rect(img, 18, 20, 28, 8, skin)
	_fill_rect(img, 16, 24, 32, 10, skin)
	_fill_rect(img, 18, 34, 28, 8, skin_dark)
	_fill_rect(img, 20, 42, 24, 6, skin)

	# Chest muscles / abs definition
	_draw_line_v(img, 32, 22, 38, muscle)
	_draw_line_h(img, 24, 40, 28, muscle)
	_draw_line_h(img, 24, 40, 32, muscle)
	_draw_line_h(img, 26, 38, 36, muscle)
	# Pecs
	_fill_rect(img, 22, 22, 8, 4, skin_light)
	_fill_rect(img, 34, 22, 8, 4, skin_light)

	# Arms (bulky)
	_fill_rect(img, 8, 22, 8, 6, skin)
	_fill_rect(img, 6, 28, 8, 8, skin_dark)
	_fill_rect(img, 4, 36, 8, 4, skin)
	_fill_rect(img, 48, 22, 8, 6, skin)
	_fill_rect(img, 50, 28, 8, 8, skin_dark)
	_fill_rect(img, 52, 36, 8, 4, skin)

	# Bat wings (behind body)
	# Left wing
	_fill_rect(img, 0, 14, 16, 3, wing_bone)
	_fill_rect(img, 0, 17, 14, 8, wing_membrane)
	_fill_rect(img, 2, 25, 12, 6, wing_membrane)
	_fill_rect(img, 4, 31, 8, 4, wing_membrane)
	# Wing bone lines
	_draw_line_v(img, 4, 14, 30, wing_bone)
	_draw_line_v(img, 8, 14, 28, wing_bone)
	_draw_line_v(img, 12, 14, 24, wing_bone)

	# Right wing
	_fill_rect(img, 48, 14, 16, 3, wing_bone)
	_fill_rect(img, 50, 17, 14, 8, wing_membrane)
	_fill_rect(img, 50, 25, 12, 6, wing_membrane)
	_fill_rect(img, 52, 31, 8, 4, wing_membrane)
	_draw_line_v(img, 52, 14, 24, wing_bone)
	_draw_line_v(img, 56, 14, 28, wing_bone)
	_draw_line_v(img, 60, 14, 30, wing_bone)

	# Fire sword (right hand)
	_fill_rect(img, 56, 20, 3, 18, sword)
	_fill_rect(img, 55, 16, 5, 5, sword)
	_fill_rect(img, 56, 12, 3, 5, sword)
	_fill_rect(img, 57, 8, 1, 5, sword_glow)
	# Fire effect on sword
	_fill_rect(img, 54, 10, 2, 6, fire)
	_fill_rect(img, 59, 12, 2, 5, fire)
	_fill_rect(img, 55, 8, 2, 3, fire_bright)
	_fill_rect(img, 58, 9, 2, 3, fire_bright)
	_set_px(img, 56, 7, fire_dark)
	_set_px(img, 58, 7, fire_dark)
	_set_px(img, 57, 6, fire_bright)

	# Legs
	_fill_rect(img, 20, 48, 8, 10, skin_dark)
	_fill_rect(img, 36, 48, 8, 10, skin_dark)
	# Hooves
	_fill_rect(img, 18, 58, 10, 4, horn)
	_fill_rect(img, 36, 58, 10, 4, horn)

	_add_outline(img, outline)
	_save_sprite(img, "boss_demon_lord.png")

# ==================== BOSS 6: LEVIATHAN ====================
func _generate_leviathan() -> void:
	var img = Image.create(SPRITE_SIZE, SPRITE_SIZE, false, Image.FORMAT_RGBA8)
	var body = Color(0.1, 0.25, 0.35)
	var body_light = Color(0.15, 0.35, 0.45)
	var belly = Color(0.2, 0.45, 0.5)
	var scale_dark = Color(0.06, 0.15, 0.22)
	var eye_glow = Color(0.2, 1.0, 0.8)
	var eye_bright = Color(0.6, 1.0, 0.9)
	var teeth_color = Color(0.9, 0.9, 0.85)
	var tentacle = Color(0.12, 0.3, 0.38)
	var tentacle_sucker = Color(0.25, 0.5, 0.55)
	var fin = Color(0.08, 0.2, 0.3)
	var outline = Color(0.03, 0.08, 0.12)

	# Main head (serpent, facing forward, large)
	_fill_rect(img, 14, 4, 36, 10, body)
	_fill_rect(img, 12, 8, 40, 14, body)
	_fill_rect(img, 10, 14, 44, 10, body)
	_fill_rect(img, 14, 24, 36, 6, body_light)

	# Top of head (ridged)
	_fill_rect(img, 18, 2, 28, 4, body)
	_fill_rect(img, 22, 0, 20, 3, scale_dark)
	# Head ridges/spines
	_fill_rect(img, 22, 0, 3, 3, fin)
	_fill_rect(img, 28, 0, 3, 2, fin)
	_fill_rect(img, 34, 0, 3, 3, fin)
	_fill_rect(img, 40, 1, 2, 2, fin)

	# Belly/underjaw lighter area
	_fill_rect(img, 16, 22, 32, 6, belly)
	_fill_rect(img, 20, 28, 24, 3, belly)

	# Glowing eyes (teal/cyan)
	_fill_rect(img, 18, 8, 8, 6, eye_glow)
	_fill_rect(img, 38, 8, 8, 6, eye_glow)
	_fill_rect(img, 20, 10, 4, 2, eye_bright)
	_fill_rect(img, 40, 10, 4, 2, eye_bright)
	# Pupils (vertical slit)
	_fill_rect(img, 21, 9, 2, 4, Color(0.02, 0.05, 0.08))
	_fill_rect(img, 41, 9, 2, 4, Color(0.02, 0.05, 0.08))

	# Nostrils
	_fill_rect(img, 22, 16, 2, 2, scale_dark)
	_fill_rect(img, 40, 16, 2, 2, scale_dark)

	# Open mouth with teeth
	_fill_rect(img, 16, 20, 32, 6, Color(0.15, 0.05, 0.08))
	# Upper teeth (jagged)
	for i in range(8):
		var tx = 18 + i * 4
		_fill_rect(img, tx, 20, 2, 3, teeth_color)
	# Lower teeth
	for i in range(7):
		var tx = 20 + i * 4
		_fill_rect(img, tx, 23, 2, 3, teeth_color)

	# Scale pattern on head
	for sx in range(14, 48, 4):
		for sy in range(4, 18, 4):
			_set_px(img, sx, sy, scale_dark)
			_set_px(img, sx + 1, sy, scale_dark)

	# Tentacles (below the head)
	# Tentacle 1 (left)
	_fill_rect(img, 8, 28, 4, 8, tentacle)
	_fill_rect(img, 6, 36, 4, 8, tentacle)
	_fill_rect(img, 4, 44, 4, 8, tentacle)
	_fill_rect(img, 2, 52, 4, 6, tentacle)
	_fill_rect(img, 1, 56, 3, 4, tentacle)
	# Suckers
	_fill_rect(img, 9, 30, 2, 2, tentacle_sucker)
	_fill_rect(img, 7, 38, 2, 2, tentacle_sucker)
	_fill_rect(img, 5, 46, 2, 2, tentacle_sucker)
	_fill_rect(img, 3, 54, 2, 2, tentacle_sucker)

	# Tentacle 2 (center-left)
	_fill_rect(img, 18, 30, 4, 8, tentacle)
	_fill_rect(img, 16, 38, 4, 8, tentacle)
	_fill_rect(img, 14, 46, 4, 8, tentacle)
	_fill_rect(img, 13, 54, 3, 6, tentacle)
	_fill_rect(img, 19, 32, 2, 2, tentacle_sucker)
	_fill_rect(img, 17, 40, 2, 2, tentacle_sucker)
	_fill_rect(img, 15, 48, 2, 2, tentacle_sucker)

	# Tentacle 3 (center)
	_fill_rect(img, 28, 28, 4, 10, tentacle)
	_fill_rect(img, 30, 38, 4, 8, tentacle)
	_fill_rect(img, 28, 46, 4, 8, tentacle)
	_fill_rect(img, 27, 54, 3, 6, tentacle)
	_fill_rect(img, 29, 30, 2, 2, tentacle_sucker)
	_fill_rect(img, 31, 40, 2, 2, tentacle_sucker)
	_fill_rect(img, 29, 48, 2, 2, tentacle_sucker)

	# Tentacle 4 (center-right)
	_fill_rect(img, 40, 30, 4, 8, tentacle)
	_fill_rect(img, 42, 38, 4, 8, tentacle)
	_fill_rect(img, 44, 46, 4, 8, tentacle)
	_fill_rect(img, 46, 54, 3, 6, tentacle)
	_fill_rect(img, 41, 32, 2, 2, tentacle_sucker)
	_fill_rect(img, 43, 40, 2, 2, tentacle_sucker)
	_fill_rect(img, 45, 48, 2, 2, tentacle_sucker)

	# Tentacle 5 (right)
	_fill_rect(img, 52, 28, 4, 8, tentacle)
	_fill_rect(img, 54, 36, 4, 8, tentacle)
	_fill_rect(img, 56, 44, 4, 8, tentacle)
	_fill_rect(img, 58, 52, 4, 6, tentacle)
	_fill_rect(img, 53, 30, 2, 2, tentacle_sucker)
	_fill_rect(img, 55, 38, 2, 2, tentacle_sucker)
	_fill_rect(img, 57, 46, 2, 2, tentacle_sucker)

	_add_outline(img, outline)
	_save_sprite(img, "boss_leviathan.png")

# ==================== BOSS 7: EMPEROR ====================
func _generate_emperor() -> void:
	var img = Image.create(SPRITE_SIZE, SPRITE_SIZE, false, Image.FORMAT_RGBA8)
	var armor_gold = Color(0.85, 0.72, 0.2)
	var armor_gold_light = Color(0.95, 0.85, 0.4)
	var armor_gold_dark = Color(0.65, 0.5, 0.1)
	var cape_red = Color(0.75, 0.1, 0.1)
	var cape_dark = Color(0.5, 0.06, 0.06)
	var skin = Color(0.7, 0.6, 0.7)
	var corruption = Color(0.3, 0.1, 0.4)
	var corruption_glow = Color(0.5, 0.15, 0.6)
	var crown = Color(0.9, 0.8, 0.25)
	var crown_jewel = Color(0.8, 0.1, 0.15)
	var eye_glow = Color(0.6, 0.1, 0.8)
	var steel = Color(0.6, 0.6, 0.62)
	var outline = Color(0.2, 0.1, 0.05)

	# Cape (behind everything, flowing)
	_fill_rect(img, 10, 18, 44, 8, cape_red)
	_fill_rect(img, 8, 26, 48, 10, cape_red)
	_fill_rect(img, 6, 36, 52, 10, cape_dark)
	_fill_rect(img, 8, 46, 48, 10, cape_red)
	_fill_rect(img, 10, 56, 44, 6, cape_dark)

	# Crown
	_fill_rect(img, 22, 2, 20, 4, crown)
	_fill_rect(img, 24, 0, 4, 3, crown)
	_fill_rect(img, 30, 0, 4, 2, crown)
	_fill_rect(img, 36, 0, 4, 3, crown)
	_set_px(img, 25, 0, crown_jewel)
	_fill_rect(img, 31, 0, 2, 1, crown_jewel)
	_set_px(img, 37, 0, crown_jewel)
	# Crown jewels
	_fill_rect(img, 28, 3, 2, 2, crown_jewel)
	_fill_rect(img, 34, 3, 2, 2, crown_jewel)

	# Head
	_fill_rect(img, 24, 6, 16, 12, skin)
	_fill_rect(img, 22, 8, 20, 8, skin)

	# Corruption spreading on face (right side)
	_fill_rect(img, 34, 8, 8, 8, corruption)
	_fill_rect(img, 36, 6, 4, 3, corruption)
	_fill_rect(img, 38, 14, 4, 4, corruption)
	# Corruption glow veins
	_set_px(img, 35, 9, corruption_glow)
	_set_px(img, 37, 11, corruption_glow)
	_set_px(img, 36, 14, corruption_glow)
	_set_px(img, 39, 10, corruption_glow)

	# Eyes
	_fill_rect(img, 26, 10, 4, 3, Color.WHITE)
	_fill_rect(img, 35, 10, 4, 3, eye_glow)
	_fill_rect(img, 27, 11, 2, 1, Color(0.1, 0.1, 0.1))
	_fill_rect(img, 36, 11, 2, 1, eye_glow)
	# Corrupted eye glows
	_set_px(img, 36, 10, Color(0.9, 0.2, 1.0))

	# Stern mouth
	_fill_rect(img, 28, 15, 8, 1, Color(0.4, 0.3, 0.4))

	# Gold armor (ornate breastplate)
	_fill_rect(img, 18, 18, 28, 6, armor_gold)
	_fill_rect(img, 16, 22, 32, 8, armor_gold)
	_fill_rect(img, 18, 30, 28, 6, armor_gold_dark)
	_fill_rect(img, 20, 36, 24, 6, armor_gold)
	# Armor details (ornamental lines)
	_draw_line_v(img, 32, 20, 38, armor_gold_light)
	_fill_rect(img, 24, 22, 16, 2, armor_gold_light)
	# Chest emblem
	_fill_rect(img, 29, 24, 6, 4, crown_jewel)
	_fill_rect(img, 30, 25, 4, 2, armor_gold_light)

	# Corruption on armor (spreading from right)
	_fill_rect(img, 40, 22, 8, 8, corruption)
	_fill_rect(img, 42, 30, 6, 6, corruption)
	_set_px(img, 41, 24, corruption_glow)
	_set_px(img, 43, 28, corruption_glow)
	_set_px(img, 44, 32, corruption_glow)

	# Pauldrons (shoulder armor)
	_fill_rect(img, 10, 18, 8, 6, armor_gold)
	_fill_rect(img, 46, 18, 8, 6, armor_gold)
	_fill_rect(img, 11, 19, 6, 4, armor_gold_light)
	_fill_rect(img, 47, 19, 6, 4, armor_gold_light)

	# Arms
	_fill_rect(img, 10, 24, 6, 12, steel)
	_fill_rect(img, 48, 24, 6, 12, steel)
	# Hands
	_fill_rect(img, 10, 36, 5, 4, skin)
	_fill_rect(img, 49, 36, 5, 4, skin)
	# Corruption on right arm
	_fill_rect(img, 50, 26, 4, 6, corruption)

	# Sword (left hand, imperial)
	_fill_rect(img, 8, 24, 2, 20, steel)
	_fill_rect(img, 6, 22, 6, 3, armor_gold)
	_fill_rect(img, 8, 14, 2, 9, steel)
	_set_px(img, 8, 12, steel)
	_set_px(img, 9, 12, steel)

	# Legs (armored)
	_fill_rect(img, 22, 42, 8, 14, armor_gold_dark)
	_fill_rect(img, 34, 42, 8, 14, armor_gold_dark)
	_fill_rect(img, 22, 56, 8, 4, armor_gold)
	_fill_rect(img, 34, 56, 8, 4, armor_gold)
	# Corruption on right leg
	_fill_rect(img, 38, 46, 4, 8, corruption)

	_add_outline(img, outline)
	_save_sprite(img, "boss_emperor.png")

# ==================== BOSS 8: SINGULARITY ====================
func _generate_singularity() -> void:
	var img = Image.create(SPRITE_SIZE, SPRITE_SIZE, false, Image.FORMAT_RGBA8)
	var void_black = Color(0.02, 0.02, 0.05)
	var void_dark = Color(0.05, 0.03, 0.1)
	var ring_purple = Color(0.5, 0.1, 0.7)
	var ring_bright = Color(0.7, 0.3, 0.95)
	var ring_hot = Color(0.9, 0.5, 1.0)
	var star = Color(1.0, 1.0, 0.9)
	var star_dim = Color(0.7, 0.7, 0.8)
	var distort_blue = Color(0.2, 0.15, 0.6, 0.5)
	var distort_purple = Color(0.4, 0.1, 0.5, 0.4)
	var outline = Color(0.15, 0.05, 0.25)

	# Stars being pulled in (background, before main sphere)
	var star_positions = [
		Vector2i(4, 6), Vector2i(58, 8), Vector2i(8, 52), Vector2i(56, 50),
		Vector2i(2, 28), Vector2i(60, 30), Vector2i(12, 4), Vector2i(52, 4),
		Vector2i(6, 58), Vector2i(58, 56), Vector2i(14, 54), Vector2i(50, 58),
		Vector2i(3, 16), Vector2i(61, 20), Vector2i(8, 42), Vector2i(56, 38),
	]
	for pos in star_positions:
		_set_px(img, pos.x, pos.y, star)
		# Streaks towards center
		var dx = sign(32 - pos.x)
		var dy = sign(32 - pos.y)
		_set_px(img, pos.x + dx, pos.y + dy, star_dim)
		_set_px(img, pos.x + dx * 2, pos.y + dy * 2, star_dim)

	# Distortion ring (gravitational lensing effect)
	for angle_i in range(64):
		var angle = angle_i * TAU / 64.0
		for r_off in range(24, 30):
			var dx = int(cos(angle) * r_off)
			var dy = int(sin(angle) * r_off)
			var intensity = 1.0 - abs(r_off - 27.0) / 6.0
			_set_px(img, 32 + dx, 32 + dy, distort_blue)

	# Accretion disk/ring (purple, elliptical)
	# Outer ring
	for angle_i in range(128):
		var angle = angle_i * TAU / 128.0
		var rx = cos(angle) * 22.0
		var ry = sin(angle) * 10.0
		for t in range(-2, 3):
			_set_px(img, 32 + int(rx), 32 + int(ry) + t, ring_purple)
	# Middle ring (brighter)
	for angle_i in range(128):
		var angle = angle_i * TAU / 128.0
		var rx = cos(angle) * 18.0
		var ry = sin(angle) * 7.0
		for t in range(-1, 2):
			_set_px(img, 32 + int(rx), 32 + int(ry) + t, ring_bright)
	# Inner ring (hottest)
	for angle_i in range(96):
		var angle = angle_i * TAU / 96.0
		var rx = cos(angle) * 14.0
		var ry = sin(angle) * 5.0
		_set_px(img, 32 + int(rx), 32 + int(ry), ring_hot)

	# Black hole sphere (center, pure black)
	_draw_circle(img, 32, 32, 10, void_black)
	_draw_circle(img, 32, 32, 8, Color(0.0, 0.0, 0.02))

	# Event horizon glow (subtle purple rim)
	for angle_i in range(64):
		var angle = angle_i * TAU / 64.0
		var ex = 32 + int(cos(angle) * 10)
		var ey = 32 + int(sin(angle) * 10)
		_set_px(img, ex, ey, ring_purple)
		ex = 32 + int(cos(angle) * 11)
		ey = 32 + int(sin(angle) * 11)
		_set_px(img, ex, ey, distort_purple)

	# Bright spots on accretion disk (asymmetric glow)
	_fill_rect(img, 10, 30, 4, 4, ring_hot)
	_fill_rect(img, 50, 30, 4, 4, ring_bright)
	_fill_rect(img, 14, 34, 3, 3, ring_bright)
	_fill_rect(img, 47, 28, 3, 3, ring_bright)

	# Jets (top and bottom)
	_fill_rect(img, 31, 2, 2, 10, ring_bright)
	_fill_rect(img, 30, 0, 4, 4, ring_hot)
	_fill_rect(img, 31, 52, 2, 10, ring_bright)
	_fill_rect(img, 30, 58, 4, 4, ring_hot)
	# Jet glow
	_set_px(img, 30, 6, ring_purple)
	_set_px(img, 33, 8, ring_purple)
	_set_px(img, 30, 56, ring_purple)
	_set_px(img, 33, 54, ring_purple)

	_add_outline(img, outline)
	_save_sprite(img, "boss_singularity.png")

# ==================== BOSS 9: DRACULA ====================
func _generate_dracula() -> void:
	var img = Image.create(SPRITE_SIZE, SPRITE_SIZE, false, Image.FORMAT_RGBA8)
	var cape_black = Color(0.08, 0.06, 0.1)
	var cape_inner_red = Color(0.6, 0.08, 0.1)
	var cape_inner_dark = Color(0.4, 0.05, 0.08)
	var suit = Color(0.12, 0.1, 0.14)
	var suit_light = Color(0.2, 0.18, 0.22)
	var skin = Color(0.85, 0.82, 0.88)
	var skin_shadow = Color(0.7, 0.65, 0.75)
	var hair = Color(0.1, 0.08, 0.12)
	var eye_red = Color(0.9, 0.1, 0.1)
	var eye_glow = Color(1.0, 0.3, 0.2)
	var fang = Color(0.95, 0.95, 0.92)
	var hat = Color(0.06, 0.05, 0.08)
	var hat_band = Color(0.5, 0.08, 0.1)
	var vest = Color(0.35, 0.08, 0.1)
	var shirt = Color(0.9, 0.88, 0.85)
	var outline = Color(0.04, 0.02, 0.06)

	# Cape spread wide (behind everything)
	_fill_rect(img, 2, 16, 60, 6, cape_black)
	_fill_rect(img, 0, 22, 64, 8, cape_black)
	_fill_rect(img, 0, 30, 64, 10, cape_black)
	_fill_rect(img, 2, 40, 60, 10, cape_black)
	_fill_rect(img, 4, 50, 56, 8, cape_black)
	_fill_rect(img, 6, 58, 52, 4, cape_black)
	# Cape inner red lining (visible on edges)
	_fill_rect(img, 2, 22, 6, 20, cape_inner_red)
	_fill_rect(img, 56, 22, 6, 20, cape_inner_red)
	_fill_rect(img, 4, 42, 8, 10, cape_inner_dark)
	_fill_rect(img, 52, 42, 8, 10, cape_inner_dark)
	# Cape collar (high, dramatic)
	_fill_rect(img, 12, 14, 6, 10, cape_black)
	_fill_rect(img, 46, 14, 6, 10, cape_black)
	_fill_rect(img, 13, 12, 4, 4, cape_black)
	_fill_rect(img, 47, 12, 4, 4, cape_black)
	_fill_rect(img, 13, 15, 3, 7, cape_inner_red)
	_fill_rect(img, 48, 15, 3, 7, cape_inner_red)

	# Top hat
	_fill_rect(img, 22, 0, 20, 2, hat)
	_fill_rect(img, 24, 2, 16, 10, hat)
	_fill_rect(img, 20, 12, 24, 3, hat)
	# Hat band
	_fill_rect(img, 24, 10, 16, 2, hat_band)

	# Hair (slicked back, dark)
	_fill_rect(img, 22, 14, 20, 3, hair)
	_fill_rect(img, 20, 14, 3, 6, hair)
	_fill_rect(img, 41, 14, 3, 6, hair)

	# Face (pale)
	_fill_rect(img, 24, 15, 16, 14, skin)
	_fill_rect(img, 22, 17, 20, 10, skin)
	# Cheek shadow
	_fill_rect(img, 22, 24, 3, 4, skin_shadow)
	_fill_rect(img, 39, 24, 3, 4, skin_shadow)

	# Widow's peak hairline
	_fill_rect(img, 24, 14, 16, 2, hair)
	_fill_rect(img, 30, 15, 4, 2, hair)

	# Red eyes (glowing)
	_fill_rect(img, 26, 20, 4, 3, Color.WHITE)
	_fill_rect(img, 34, 20, 4, 3, Color.WHITE)
	_fill_rect(img, 27, 21, 2, 1, eye_red)
	_fill_rect(img, 35, 21, 2, 1, eye_red)
	_set_px(img, 28, 21, Color(0.1, 0.0, 0.0))
	_set_px(img, 36, 21, Color(0.1, 0.0, 0.0))
	# Eye glow
	_set_px(img, 25, 20, eye_glow)
	_set_px(img, 38, 20, eye_glow)

	# Pointed nose
	_fill_rect(img, 31, 23, 2, 2, skin_shadow)

	# Mouth with fangs
	_fill_rect(img, 28, 26, 8, 2, Color(0.3, 0.05, 0.08))
	# Fangs (prominent)
	_fill_rect(img, 28, 26, 2, 3, fang)
	_fill_rect(img, 34, 26, 2, 3, fang)
	_set_px(img, 28, 29, fang)
	_set_px(img, 35, 29, fang)

	# Suit / vest
	_fill_rect(img, 20, 30, 24, 8, suit)
	_fill_rect(img, 22, 38, 20, 6, suit)
	_fill_rect(img, 24, 44, 16, 4, suit)

	# White shirt front
	_fill_rect(img, 29, 30, 6, 10, shirt)
	# Vest over shirt
	_fill_rect(img, 24, 30, 5, 8, vest)
	_fill_rect(img, 35, 30, 5, 8, vest)

	# Buttons
	_set_px(img, 32, 33, Color(0.1, 0.1, 0.1))
	_set_px(img, 32, 37, Color(0.1, 0.1, 0.1))

	# Arms (in cape)
	_fill_rect(img, 14, 28, 6, 14, suit)
	_fill_rect(img, 44, 28, 6, 14, suit)
	# Hands (pale, clawed)
	_fill_rect(img, 14, 42, 5, 4, skin)
	_fill_rect(img, 45, 42, 5, 4, skin)
	_set_px(img, 14, 46, skin)
	_set_px(img, 16, 46, skin)
	_set_px(img, 47, 46, skin)
	_set_px(img, 49, 46, skin)

	# Legs
	_fill_rect(img, 24, 48, 7, 10, suit)
	_fill_rect(img, 33, 48, 7, 10, suit)
	# Shoes
	_fill_rect(img, 23, 58, 8, 4, Color(0.06, 0.04, 0.08))
	_fill_rect(img, 33, 58, 8, 4, Color(0.06, 0.04, 0.08))

	_add_outline(img, outline)
	_save_sprite(img, "boss_dracula.png")

# ==================== BOSS 10: SUGAR KING ====================
func _generate_sugar_king() -> void:
	var img = Image.create(SPRITE_SIZE, SPRITE_SIZE, false, Image.FORMAT_RGBA8)
	var body_pink = Color(0.95, 0.55, 0.65)
	var body_light = Color(1.0, 0.75, 0.8)
	var body_dark = Color(0.8, 0.4, 0.5)
	var melt_drip = Color(0.9, 0.5, 0.6, 0.8)
	var crown_yellow = Color(1.0, 0.85, 0.15)
	var crown_orange = Color(1.0, 0.6, 0.1)
	var candy_red = Color(0.95, 0.15, 0.2)
	var candy_blue = Color(0.2, 0.6, 0.95)
	var candy_green = Color(0.2, 0.85, 0.3)
	var candy_yellow = Color(1.0, 0.95, 0.2)
	var lollipop_stick = Color(0.9, 0.85, 0.75)
	var lollipop_swirl1 = Color(0.95, 0.2, 0.3)
	var lollipop_swirl2 = Color(0.95, 0.95, 0.9)
	var eye_white = Color(0.95, 0.95, 0.95)
	var pupil = Color(0.1, 0.1, 0.1)
	var mouth = Color(0.6, 0.15, 0.2)
	var chocolate = Color(0.4, 0.22, 0.12)
	var outline = Color(0.5, 0.2, 0.25)

	# Body (melting, blobby candy shape)
	_fill_rect(img, 18, 14, 28, 6, body_pink)
	_fill_rect(img, 14, 18, 36, 8, body_pink)
	_fill_rect(img, 12, 24, 40, 10, body_pink)
	_fill_rect(img, 10, 30, 44, 10, body_light)
	_fill_rect(img, 10, 38, 44, 8, body_pink)
	_fill_rect(img, 12, 44, 40, 6, body_dark)
	_fill_rect(img, 14, 48, 36, 4, body_pink)

	# Melting drips (bottom)
	_fill_rect(img, 14, 52, 4, 6, melt_drip)
	_fill_rect(img, 24, 52, 3, 8, melt_drip)
	_fill_rect(img, 34, 52, 4, 7, melt_drip)
	_fill_rect(img, 44, 52, 3, 5, melt_drip)
	_fill_rect(img, 18, 52, 2, 4, melt_drip)
	_fill_rect(img, 40, 52, 2, 5, melt_drip)
	# Drip tips
	_set_px(img, 15, 58, melt_drip)
	_set_px(img, 25, 60, melt_drip)
	_set_px(img, 35, 59, melt_drip)
	_set_px(img, 45, 57, melt_drip)

	# Melting drips from sides
	_fill_rect(img, 8, 32, 3, 6, melt_drip)
	_fill_rect(img, 53, 30, 3, 7, melt_drip)
	_set_px(img, 9, 38, melt_drip)
	_set_px(img, 54, 37, melt_drip)

	# Candy crown
	_fill_rect(img, 18, 6, 28, 4, crown_yellow)
	_fill_rect(img, 20, 4, 24, 3, crown_yellow)
	# Crown spikes
	_fill_rect(img, 20, 2, 4, 3, crown_yellow)
	_fill_rect(img, 30, 0, 4, 4, crown_orange)
	_fill_rect(img, 40, 2, 4, 3, crown_yellow)
	# Crown jewels (candy pieces)
	_fill_rect(img, 21, 3, 2, 2, candy_red)
	_fill_rect(img, 31, 1, 2, 2, candy_blue)
	_fill_rect(img, 41, 3, 2, 2, candy_green)
	_fill_rect(img, 26, 7, 2, 2, candy_red)
	_fill_rect(img, 36, 7, 2, 2, candy_yellow)
	# Crown dripping (melting)
	_fill_rect(img, 22, 10, 2, 4, crown_yellow)
	_fill_rect(img, 38, 10, 2, 5, crown_yellow)

	# Face
	# Eyes (big, candy-like)
	_fill_rect(img, 20, 20, 6, 6, eye_white)
	_fill_rect(img, 38, 20, 6, 6, eye_white)
	_fill_rect(img, 22, 22, 3, 3, pupil)
	_fill_rect(img, 40, 22, 3, 3, pupil)
	_set_px(img, 22, 22, Color(0.3, 0.3, 0.3))
	_set_px(img, 40, 22, Color(0.3, 0.3, 0.3))
	# Eye shine
	_set_px(img, 23, 21, Color.WHITE)
	_set_px(img, 41, 21, Color.WHITE)

	# Rosy cheeks (candy blush)
	_fill_rect(img, 16, 26, 4, 3, candy_red)
	_fill_rect(img, 44, 26, 4, 3, candy_red)

	# Wide grinning mouth
	_fill_rect(img, 24, 30, 16, 4, mouth)
	_fill_rect(img, 22, 31, 20, 2, mouth)
	# Teeth (candy-like)
	_fill_rect(img, 25, 30, 3, 2, eye_white)
	_fill_rect(img, 30, 30, 4, 2, eye_white)
	_fill_rect(img, 36, 30, 3, 2, eye_white)

	# Colored candy pieces embedded in body
	_fill_rect(img, 16, 34, 3, 3, candy_blue)
	_fill_rect(img, 44, 28, 3, 3, candy_green)
	_fill_rect(img, 28, 42, 3, 3, candy_yellow)
	_fill_rect(img, 38, 38, 3, 3, candy_red)
	_fill_rect(img, 14, 24, 3, 3, candy_yellow)
	_fill_rect(img, 48, 36, 3, 3, candy_blue)

	# Chocolate drizzle lines
	_draw_line_h(img, 18, 46, 36, chocolate)
	_draw_line_h(img, 16, 48, 40, chocolate)
	_draw_line_h(img, 20, 42, 44, chocolate)

	# Arms (stubby, candy)
	_fill_rect(img, 4, 26, 8, 6, body_pink)
	_fill_rect(img, 2, 28, 6, 6, body_light)
	_fill_rect(img, 52, 26, 8, 6, body_pink)
	_fill_rect(img, 56, 28, 6, 6, body_light)
	# Melting arm drips
	_set_px(img, 3, 34, melt_drip)
	_set_px(img, 5, 35, melt_drip)
	_set_px(img, 58, 34, melt_drip)

	# Lollipop scepter (left hand)
	_fill_rect(img, 1, 22, 2, 20, lollipop_stick)
	# Lollipop head (circular swirl)
	_draw_circle(img, 2, 16, 6, lollipop_swirl1)
	_draw_circle(img, 2, 16, 4, lollipop_swirl2)
	_draw_circle(img, 2, 16, 2, lollipop_swirl1)
	_set_px(img, 2, 16, lollipop_swirl2)
	# Swirl details
	_set_px(img, 4, 14, lollipop_swirl1)
	_set_px(img, 0, 18, lollipop_swirl1)
	_set_px(img, 5, 17, lollipop_swirl1)

	# Little candy feet
	_fill_rect(img, 20, 50, 8, 4, body_dark)
	_fill_rect(img, 36, 50, 8, 4, body_dark)

	_add_outline(img, outline)
	_save_sprite(img, "boss_sugar_king.png")
