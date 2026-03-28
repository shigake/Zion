extends SceneTree

## Generates 32x32 pixel art sprites for volcano stage decoration props,
## plus a 64x64 tiled ground texture.
## Run: godot --headless --script res://scripts/tools/volcano_prop_sprites.gd

const S := 32  # Prop sprite size
const G := 64  # Ground tile size

func _init() -> void:
	_generate_all()
	quit()

func _generate_all() -> void:
	DirAccess.make_dir_recursive_absolute("res://assets/sprites/props/volcano")

	_gen_lava_rock()
	_gen_obsidian()
	_gen_fire_geyser()
	_gen_skull_rock()
	_gen_magma_pool()
	_gen_dead_bush()
	_gen_bone_pile()
	_gen_crystal_red()
	_gen_volcanic_vent()
	_gen_ground_volcano()

	print("All volcano prop sprites generated!")

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
	var path = "res://assets/sprites/props/volcano/" + name
	img.save_png(path)
	print("Saved: ", path)

# ==================== LAVA ROCK ====================

func _gen_lava_rock() -> void:
	# Dark jagged rock with red glow at base
	var img = _img()
	var rock = Color(0.18, 0.12, 0.1)
	var rock_light = Color(0.28, 0.18, 0.14)
	var rock_dark = Color(0.1, 0.06, 0.05)
	var glow = Color(0.9, 0.25, 0.05)
	var glow_dim = Color(0.6, 0.15, 0.03)

	# Main rock body - jagged shape
	_fill(img, 10, 8, 12, 16, rock)
	_fill(img, 8, 12, 16, 12, rock)
	# Jagged top peaks
	_fill(img, 12, 5, 4, 3, rock)
	_fill(img, 18, 6, 3, 4, rock)
	_fill(img, 9, 9, 3, 3, rock)
	_px(img, 13, 4, rock)
	_px(img, 14, 4, rock)
	_px(img, 19, 5, rock)

	# Shading - left dark
	_fill(img, 8, 12, 2, 12, rock_dark)
	_fill(img, 10, 8, 2, 4, rock_dark)
	# Right highlight
	_fill(img, 20, 10, 2, 14, rock_light)
	_fill(img, 18, 6, 1, 4, rock_light)

	# Red glow at base
	_fill(img, 8, 24, 16, 2, glow)
	_fill(img, 9, 23, 14, 1, glow_dim)
	_fill(img, 10, 26, 12, 2, glow_dim)

	# Cracks with glow
	_px(img, 14, 12, glow_dim)
	_px(img, 15, 13, glow)
	_px(img, 15, 14, glow_dim)
	_px(img, 16, 15, glow_dim)
	_px(img, 12, 18, glow_dim)
	_px(img, 13, 19, glow)
	_px(img, 13, 20, glow_dim)

	_outline(img, Color(0.05, 0.02, 0.01))
	_save(img, "lava_rock.png")

# ==================== OBSIDIAN ====================

func _gen_obsidian() -> void:
	# Shiny black crystal formation with purple-blue highlights
	var img = _img()
	var obsid = Color(0.08, 0.06, 0.1)
	var obsid_light = Color(0.2, 0.15, 0.3)
	var shine = Color(0.5, 0.4, 0.7)
	var base = Color(0.15, 0.1, 0.12)

	# Tall central crystal
	_fill(img, 13, 4, 5, 20, obsid)
	_fill(img, 14, 2, 3, 2, obsid)
	_px(img, 15, 1, obsid)
	# Right crystal
	_fill(img, 19, 10, 4, 14, obsid)
	_fill(img, 20, 8, 3, 2, obsid)
	_px(img, 21, 7, obsid)
	# Left crystal
	_fill(img, 8, 12, 4, 12, obsid)
	_fill(img, 9, 10, 3, 2, obsid)
	_px(img, 10, 9, obsid)

	# Shiny highlights - center
	_fill(img, 16, 3, 1, 8, shine)
	_px(img, 16, 2, obsid_light)
	# Right crystal highlight
	_fill(img, 22, 9, 1, 6, shine)
	# Left crystal highlight
	_fill(img, 11, 11, 1, 5, obsid_light)

	# Edge lighting
	_fill(img, 17, 4, 1, 18, obsid_light)
	_fill(img, 22, 10, 1, 12, obsid_light)

	# Base
	_fill(img, 7, 24, 17, 3, base)
	_fill(img, 9, 27, 13, 2, Color(0.12, 0.08, 0.1))

	_outline(img, Color(0.03, 0.02, 0.05))
	_save(img, "obsidian.png")

# ==================== FIRE GEYSER ====================

func _gen_fire_geyser() -> void:
	# Column of fire and steam rising from the ground
	var img = _img()
	var fire_bright = Color(1.0, 0.85, 0.2)
	var fire_mid = Color(1.0, 0.5, 0.1)
	var fire_dark = Color(0.85, 0.2, 0.05)
	var smoke = Color(0.4, 0.35, 0.3, 0.6)
	var ground = Color(0.2, 0.1, 0.08)

	# Fire column core (bright yellow)
	_fill(img, 14, 4, 4, 18, fire_bright)
	_fill(img, 13, 8, 6, 12, fire_mid)

	# Fire edges (orange/red)
	_fill(img, 12, 10, 1, 10, fire_dark)
	_fill(img, 19, 10, 1, 10, fire_dark)
	_fill(img, 11, 14, 1, 6, fire_dark)
	_fill(img, 20, 14, 1, 6, fire_dark)

	# Flame tips at top
	_fill(img, 15, 2, 2, 2, fire_mid)
	_px(img, 15, 1, fire_dark)
	_px(img, 16, 1, fire_dark)
	_px(img, 13, 5, fire_dark)
	_px(img, 18, 6, fire_dark)

	# Fire detail flickers
	_px(img, 13, 7, fire_bright)
	_px(img, 18, 9, fire_bright)
	_px(img, 12, 12, fire_mid)
	_px(img, 19, 13, fire_mid)

	# Smoke wisps at top
	_px(img, 14, 3, smoke)
	_px(img, 17, 2, smoke)
	_px(img, 12, 5, smoke)
	_px(img, 19, 4, smoke)

	# Ground vent
	_fill(img, 10, 22, 12, 3, ground)
	_fill(img, 11, 25, 10, 2, Color(0.15, 0.07, 0.05))
	_fill(img, 12, 27, 8, 2, Color(0.12, 0.06, 0.04))

	# Glow around vent
	_fill(img, 11, 21, 10, 1, fire_dark)
	_px(img, 13, 20, fire_mid)
	_px(img, 18, 20, fire_mid)

	_outline(img, Color(0.08, 0.03, 0.01))
	_save(img, "fire_geyser.png")

# ==================== SKULL ROCK ====================

func _gen_skull_rock() -> void:
	# Rock formation shaped like a demon skull
	var img = _img()
	var rock = Color(0.25, 0.18, 0.15)
	var rock_dark = Color(0.15, 0.1, 0.08)
	var rock_light = Color(0.35, 0.28, 0.22)
	var eye_glow = Color(0.9, 0.2, 0.05)
	var eye_dim = Color(0.6, 0.1, 0.02)

	# Skull shape - rounded top
	_fill(img, 8, 6, 16, 14, rock)
	_fill(img, 10, 4, 12, 2, rock)
	_fill(img, 12, 3, 8, 1, rock)
	# Jaw area
	_fill(img, 10, 20, 12, 4, rock)
	_fill(img, 12, 24, 8, 2, rock_dark)

	# Shading
	_fill(img, 8, 6, 2, 14, rock_dark)
	_fill(img, 22, 6, 2, 14, rock_light)
	_fill(img, 10, 4, 2, 2, rock_dark)
	_fill(img, 20, 4, 2, 2, rock_light)

	# Eye sockets (left)
	_fill(img, 10, 10, 4, 4, Color(0.05, 0.02, 0.01))
	_px(img, 11, 11, eye_glow)
	_px(img, 12, 11, eye_glow)
	_px(img, 11, 12, eye_dim)

	# Eye sockets (right)
	_fill(img, 18, 10, 4, 4, Color(0.05, 0.02, 0.01))
	_px(img, 19, 11, eye_glow)
	_px(img, 20, 11, eye_glow)
	_px(img, 19, 12, eye_dim)

	# Nose cavity
	_fill(img, 14, 15, 3, 3, rock_dark)
	_px(img, 15, 14, rock_dark)

	# Teeth
	for tx in range(11, 21, 2):
		_fill(img, tx, 20, 1, 3, rock_light)

	# Horns
	_fill(img, 7, 4, 3, 5, rock)
	_fill(img, 6, 2, 2, 3, rock)
	_px(img, 6, 1, rock_dark)
	_fill(img, 22, 4, 3, 5, rock)
	_fill(img, 24, 2, 2, 3, rock)
	_px(img, 25, 1, rock_dark)

	# Ground
	_fill(img, 8, 26, 16, 2, Color(0.18, 0.1, 0.08))
	_fill(img, 10, 28, 12, 2, Color(0.14, 0.08, 0.06))

	_outline(img, Color(0.05, 0.03, 0.02))
	_save(img, "skull_rock.png")

# ==================== MAGMA POOL ====================

func _gen_magma_pool() -> void:
	# Small glowing orange lava puddle
	var img = _img()
	var lava_bright = Color(1.0, 0.7, 0.1)
	var lava_mid = Color(0.95, 0.4, 0.05)
	var lava_dark = Color(0.7, 0.15, 0.02)
	var crust = Color(0.2, 0.1, 0.08)
	var crust_dark = Color(0.12, 0.06, 0.04)

	# Outer crust ring
	_circle(img, 16, 20, 10, crust)
	_circle(img, 16, 20, 9, crust_dark)
	# Lava surface
	_circle(img, 16, 20, 7, lava_dark)
	_circle(img, 16, 20, 5, lava_mid)
	_circle(img, 16, 20, 3, lava_bright)

	# Hot spots
	_px(img, 14, 19, lava_bright)
	_px(img, 18, 21, lava_bright)
	_px(img, 16, 18, Color(1.0, 0.95, 0.6))

	# Crust details
	_px(img, 10, 17, crust)
	_px(img, 22, 18, crust)
	_px(img, 12, 24, crust)
	_px(img, 20, 24, crust)

	# Bubbles
	_px(img, 13, 20, Color(1.0, 0.9, 0.5))
	_px(img, 19, 19, Color(1.0, 0.9, 0.5))

	_outline(img, Color(0.06, 0.03, 0.01))
	_save(img, "magma_pool.png")

# ==================== DEAD BUSH ====================

func _gen_dead_bush() -> void:
	# Charred black bush - twisted burnt branches
	var img = _img()
	var branch = Color(0.12, 0.08, 0.06)
	var branch_light = Color(0.2, 0.14, 0.1)
	var ash = Color(0.25, 0.22, 0.2)
	var ember = Color(0.8, 0.3, 0.05)

	# Main trunk
	_fill(img, 14, 16, 3, 10, branch)
	_fill(img, 15, 14, 2, 2, branch)

	# Left branches
	_fill(img, 10, 10, 5, 2, branch)
	_fill(img, 8, 8, 3, 2, branch)
	_px(img, 7, 7, branch)
	_fill(img, 11, 14, 3, 2, branch)
	_fill(img, 9, 12, 3, 2, branch)
	_px(img, 8, 11, branch_light)

	# Right branches
	_fill(img, 17, 11, 5, 2, branch)
	_fill(img, 21, 9, 3, 2, branch)
	_px(img, 23, 8, branch)
	_fill(img, 18, 14, 3, 2, branch)
	_fill(img, 20, 12, 3, 2, branch)
	_px(img, 22, 11, branch_light)

	# Top branches
	_fill(img, 14, 8, 2, 6, branch)
	_fill(img, 13, 6, 3, 2, branch)
	_px(img, 14, 5, branch)

	# Ember spots
	_px(img, 9, 9, ember)
	_px(img, 22, 10, ember)
	_px(img, 14, 6, ember)
	_px(img, 12, 13, ember)
	_px(img, 20, 13, ember)

	# Ash at base
	_fill(img, 11, 26, 10, 2, ash)
	_fill(img, 12, 28, 8, 2, Color(0.2, 0.18, 0.16))

	_outline(img, Color(0.05, 0.03, 0.02))
	_save(img, "dead_bush.png")

# ==================== BONE PILE ====================

func _gen_bone_pile() -> void:
	# Bleached bones in volcanic ash
	var img = _img()
	var bone = Color(0.85, 0.8, 0.7)
	var bone_dark = Color(0.65, 0.6, 0.5)
	var bone_light = Color(0.95, 0.92, 0.85)
	var ash = Color(0.3, 0.25, 0.22)
	var ash_dark = Color(0.22, 0.18, 0.16)

	# Ash mound base
	_fill(img, 7, 22, 18, 4, ash)
	_fill(img, 9, 20, 14, 2, ash)
	_fill(img, 8, 26, 16, 2, ash_dark)

	# Long bone - horizontal
	_fill(img, 8, 18, 16, 2, bone)
	_fill(img, 8, 18, 16, 1, bone_light)
	# Knobs
	_circle(img, 8, 19, 2, bone)
	_circle(img, 24, 19, 2, bone)

	# Crossed bone
	for i in range(10):
		_px(img, 10 + i, 14 + i, bone)
		_px(img, 11 + i, 14 + i, bone)
		_px(img, 22 - i, 14 + i, bone_dark)
		_px(img, 23 - i, 14 + i, bone_dark)

	# Skull on top
	_circle(img, 16, 13, 4, bone)
	_circle(img, 16, 13, 3, bone_light)
	# Eye sockets
	_px(img, 14, 12, Color(0.15, 0.1, 0.08))
	_px(img, 18, 12, Color(0.15, 0.1, 0.08))
	# Nose
	_px(img, 16, 14, bone_dark)
	# Jaw
	_fill(img, 14, 16, 5, 1, bone_dark)

	_outline(img, Color(0.08, 0.06, 0.04))
	_save(img, "bone_pile.png")

# ==================== CRYSTAL RED ====================

func _gen_crystal_red() -> void:
	# Red glowing crystal formation
	var img = _img()
	var crystal = Color(0.7, 0.05, 0.05)
	var crystal_light = Color(0.95, 0.2, 0.15)
	var crystal_bright = Color(1.0, 0.5, 0.4)
	var crystal_dark = Color(0.4, 0.02, 0.02)
	var base = Color(0.2, 0.12, 0.1)

	# Main crystal (tall)
	_fill(img, 13, 4, 5, 18, crystal)
	_fill(img, 14, 2, 3, 2, crystal)
	_px(img, 15, 1, crystal_light)
	# Highlight
	_fill(img, 16, 3, 1, 10, crystal_bright)
	_fill(img, 17, 6, 1, 6, crystal_light)

	# Left crystal (shorter)
	_fill(img, 8, 12, 4, 10, crystal)
	_fill(img, 9, 10, 3, 2, crystal)
	_px(img, 10, 9, crystal_light)
	_fill(img, 11, 11, 1, 6, crystal_light)

	# Right crystal (medium)
	_fill(img, 19, 8, 4, 14, crystal)
	_fill(img, 20, 6, 3, 2, crystal)
	_px(img, 21, 5, crystal_light)
	_fill(img, 22, 7, 1, 8, crystal_bright)

	# Dark facets
	_fill(img, 13, 4, 1, 18, crystal_dark)
	_fill(img, 8, 12, 1, 10, crystal_dark)
	_fill(img, 19, 8, 1, 14, crystal_dark)

	# Base
	_fill(img, 7, 22, 18, 3, base)
	_fill(img, 9, 25, 14, 3, Color(0.15, 0.08, 0.07))

	_outline(img, Color(0.2, 0.01, 0.01))
	_save(img, "crystal_red.png")

# ==================== VOLCANIC VENT ====================

func _gen_volcanic_vent() -> void:
	# Smoking ground vent / fumarole
	var img = _img()
	var rock = Color(0.2, 0.12, 0.1)
	var rock_dark = Color(0.12, 0.07, 0.05)
	var rock_light = Color(0.3, 0.2, 0.16)
	var smoke1 = Color(0.5, 0.48, 0.45, 0.7)
	var smoke2 = Color(0.6, 0.58, 0.55, 0.5)
	var smoke3 = Color(0.7, 0.68, 0.65, 0.3)
	var heat = Color(0.8, 0.3, 0.05, 0.6)

	# Ground mound
	_fill(img, 7, 20, 18, 4, rock)
	_fill(img, 9, 18, 14, 2, rock)
	_fill(img, 8, 24, 16, 3, rock_dark)

	# Vent opening
	_fill(img, 12, 18, 8, 3, Color(0.05, 0.02, 0.01))
	_fill(img, 13, 17, 6, 1, Color(0.08, 0.03, 0.01))

	# Rock rim
	_fill(img, 10, 17, 2, 4, rock_light)
	_fill(img, 20, 17, 2, 4, rock_light)

	# Heat glow from vent
	_fill(img, 13, 16, 6, 1, heat)
	_px(img, 14, 15, heat)
	_px(img, 17, 15, heat)

	# Smoke column
	_fill(img, 14, 10, 4, 6, smoke1)
	_fill(img, 13, 6, 5, 4, smoke2)
	_fill(img, 12, 3, 6, 3, smoke3)
	_px(img, 14, 2, smoke3)
	_px(img, 17, 2, smoke3)
	_px(img, 13, 1, Color(0.7, 0.68, 0.65, 0.15))
	_px(img, 16, 1, Color(0.7, 0.68, 0.65, 0.15))

	# Smoke wisps
	_px(img, 11, 5, smoke3)
	_px(img, 19, 4, smoke3)
	_px(img, 10, 3, Color(0.7, 0.68, 0.65, 0.15))

	_outline(img, Color(0.05, 0.03, 0.02))
	_save(img, "volcanic_vent.png")

# ==================== GROUND TEXTURE ====================

func _gen_ground_volcano() -> void:
	# 64x64 dark rocky ground with lava cracks (red/orange lines)
	var img = _img(G)
	var base1 = Color(0.18, 0.1, 0.07)
	var base2 = Color(0.22, 0.12, 0.08)
	var base3 = Color(0.15, 0.08, 0.05)
	var lava1 = Color(0.95, 0.4, 0.05)
	var lava2 = Color(1.0, 0.65, 0.1)
	var lava3 = Color(0.7, 0.2, 0.03)

	# Fill with dark rock base
	for x in range(G):
		for y in range(G):
			var noise_val = ((x * 7 + y * 13) % 17) / 17.0
			if noise_val < 0.4:
				img.set_pixel(x, y, base1)
			elif noise_val < 0.75:
				img.set_pixel(x, y, base2)
			else:
				img.set_pixel(x, y, base3)

	# Lava crack network - horizontal-ish crack
	for x in range(G):
		var y_off = 20 + int(sin(x * 0.3) * 3)
		if y_off >= 0 and y_off < G:
			img.set_pixel(x, y_off, lava1)
		if y_off + 1 >= 0 and y_off + 1 < G:
			img.set_pixel(x, y_off + 1, lava2)
		# Glow around crack
		if y_off - 1 >= 0 and y_off - 1 < G:
			img.set_pixel(x, y_off - 1, lava3)
		if y_off + 2 >= 0 and y_off + 2 < G:
			img.set_pixel(x, y_off + 2, lava3)

	# Vertical crack
	for y in range(G):
		var x_off = 45 + int(sin(y * 0.25) * 4)
		if x_off >= 0 and x_off < G:
			img.set_pixel(x_off, y, lava1)
		if x_off + 1 >= 0 and x_off + 1 < G:
			img.set_pixel(x_off + 1, y, lava2)
		if x_off - 1 >= 0 and x_off - 1 < G:
			img.set_pixel(x_off - 1, y, lava3)

	# Diagonal crack
	for i in range(G):
		var x_pos = i
		var y_pos = 40 + int(i * 0.5) + int(sin(i * 0.4) * 2)
		if x_pos >= 0 and x_pos < G and y_pos >= 0 and y_pos < G:
			img.set_pixel(x_pos, y_pos, lava1)
		if x_pos >= 0 and x_pos < G and y_pos + 1 >= 0 and y_pos + 1 < G:
			img.set_pixel(x_pos, y_pos + 1, lava3)

	# Small scattered rock highlights
	for i in range(30):
		var rx = (i * 37 + 11) % G
		var ry = (i * 23 + 7) % G
		img.set_pixel(rx, ry, Color(0.28, 0.18, 0.12))

	_save(img, "ground_volcano.png")
