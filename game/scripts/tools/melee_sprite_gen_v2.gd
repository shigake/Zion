extends SceneTree

## Generates 64x64 pixel art sprites for 12 melee weapons and 11 slash effects.
## Replaces the tiny 16x16 stubs with properly sized, detailed pixel art.
## Run: godot --headless --script res://scripts/tools/melee_sprite_gen_v2.gd

const S := 64  # Sprite size (64x64)
const WEAPONS_DIR := "res://assets/sprites/weapons/"
const SLASHES_DIR := "res://assets/sprites/effects/slashes/"

func _init() -> void:
	DirAccess.make_dir_recursive_absolute(WEAPONS_DIR)
	DirAccess.make_dir_recursive_absolute(SLASHES_DIR)
	_generate_weapons()
	_generate_slashes()
	print("All 12 melee weapon sprites and 11 slash effects generated (64x64)!")
	quit()

# ==================== HELPERS ====================
func _img() -> Image:
	return Image.create(S, S, false, Image.FORMAT_RGBA8)

func _fill(img: Image, x: int, y: int, w: int, h: int, color: Color) -> void:
	for px in range(maxi(x, 0), mini(x + w, S)):
		for py in range(maxi(y, 0), mini(y + h, S)):
			img.set_pixel(px, py, color)

func _px(img: Image, x: int, y: int, color: Color) -> void:
	if x >= 0 and x < S and y >= 0 and y < S:
		img.set_pixel(x, y, color)

func _circle(img: Image, cx: int, cy: int, r: int, color: Color) -> void:
	for x in range(maxi(cx - r, 0), mini(cx + r + 1, S)):
		for y in range(maxi(cy - r, 0), mini(cy + r + 1, S)):
			if (x - cx) * (x - cx) + (y - cy) * (y - cy) <= r * r:
				img.set_pixel(x, y, color)

func _ring(img: Image, cx: int, cy: int, r_outer: int, r_inner: int, color: Color) -> void:
	for x in range(maxi(cx - r_outer, 0), mini(cx + r_outer + 1, S)):
		for y in range(maxi(cy - r_outer, 0), mini(cy + r_outer + 1, S)):
			var dist_sq = (x - cx) * (x - cx) + (y - cy) * (y - cy)
			if dist_sq <= r_outer * r_outer and dist_sq >= r_inner * r_inner:
				img.set_pixel(x, y, color)

func _line(img: Image, x0: int, y0: int, x1: int, y1: int, color: Color) -> void:
	var dx = absi(x1 - x0)
	var dy = absi(y1 - y0)
	var sx = 1 if x0 < x1 else -1
	var sy = 1 if y0 < y1 else -1
	var err = dx - dy
	while true:
		_px(img, x0, y0, color)
		if x0 == x1 and y0 == y1:
			break
		var e2 = 2 * err
		if e2 > -dy:
			err -= dy
			x0 += sx
		if e2 < dx:
			err += dx
			y0 += sy

func _thick_line(img: Image, x0: int, y0: int, x1: int, y1: int, color: Color, thickness: int = 2) -> void:
	for ox in range(-thickness / 2, thickness / 2 + 1):
		for oy in range(-thickness / 2, thickness / 2 + 1):
			_line(img, x0 + ox, y0 + oy, x1 + ox, y1 + oy, color)

func _outline(img: Image, color: Color) -> void:
	var copy = img.duplicate()
	for x in range(S):
		for y in range(S):
			if copy.get_pixel(x, y).a > 0:
				continue
			for off in [Vector2i(-1,0), Vector2i(1,0), Vector2i(0,-1), Vector2i(0,1)]:
				var nx = x + off.x
				var ny = y + off.y
				if nx >= 0 and nx < S and ny >= 0 and ny < S:
					if copy.get_pixel(nx, ny).a > 0:
						img.set_pixel(x, y, color)
						break

func _draw_arc(img: Image, cx: int, cy: int, r_inner: float, r_outer: float, angle_start: float, angle_end: float, color: Color, steps: int = 80) -> void:
	for i in range(steps):
		var t = float(i) / float(steps - 1)
		var angle = lerp(angle_start, angle_end, t)
		for ri in range(int(r_inner), int(r_outer) + 1):
			var rf = float(ri) + 0.5
			var px = cx + int(round(cos(angle) * rf))
			var py = cy + int(round(sin(angle) * rf))
			_px(img, px, py, color)

func _save_weapon(img: Image, name: String) -> void:
	img.save_png(WEAPONS_DIR + name + ".png")
	print("  Saved weapon: ", name)

func _save_slash(img: Image, name: String) -> void:
	img.save_png(SLASHES_DIR + name + ".png")
	print("  Saved slash: ", name)

# ==================== WEAPONS (12) ====================
func _generate_weapons() -> void:
	_gen_katana()
	_gen_scythe()
	_gen_shadow_claw()
	_gen_magic_book()
	_gen_whip()
	_gen_lance()
	_gen_hammer()
	_gen_nunchaku()
	_gen_dual_katana()
	_gen_cloud_sword()
	_gen_boxing_gloves()
	_gen_chain_whip()

func _gen_katana() -> void:
	var img = _img()
	var blade = Color(0.78, 0.82, 0.88)
	var blade_lt = Color(0.88, 0.92, 0.96)
	var blade_dk = Color(0.6, 0.65, 0.72)
	var edge = Color(0.95, 0.97, 1.0)
	var hamon = Color(0.68, 0.72, 0.8)
	var handle = Color(0.18, 0.08, 0.12)
	var handle_wrap = Color(0.55, 0.1, 0.1)
	var handle_wrap_dk = Color(0.38, 0.06, 0.06)
	var guard = Color(0.72, 0.65, 0.18)
	var guard_hi = Color(0.88, 0.82, 0.3)
	var guard_dk = Color(0.52, 0.45, 0.1)

	# Blade — slightly curved, diagonal from top-right to bottom-left
	# Wide blade (6px wide) with proper taper
	for i in range(38):
		var bx = 48 - i
		var by = 2 + i
		var w = 6 if i < 32 else (6 - (i - 32))  # taper at base
		if i < 3:
			w = 2 + i  # taper at tip
		_fill(img, bx, by, w, 1, blade)
		# Sharp edge (bright side)
		_px(img, bx + w - 1, by, edge)
		# Back of blade (darker)
		_px(img, bx, by, blade_dk)
	# Hamon line (wavy temper line along blade)
	for i in range(30):
		var bx = 46 - i
		var by = 5 + i
		var wave = 1 if (i % 6 < 3) else 2
		_px(img, bx + wave, by, hamon)
		_px(img, bx + wave + 1, by, Color(0.72, 0.76, 0.84, 0.6))
	# Blade highlight (specular)
	for i in range(20):
		var bx = 44 - i
		var by = 6 + i
		_px(img, bx + 3, by, blade_lt)
	# Tip highlight
	_px(img, 49, 2, Color.WHITE)
	_px(img, 50, 1, edge)

	# Tsuba (guard) — oval/rectangular with ornament
	_fill(img, 8, 38, 18, 5, guard)
	_fill(img, 10, 37, 14, 2, guard)
	_fill(img, 10, 43, 14, 1, guard_dk)
	_fill(img, 12, 39, 10, 2, guard_hi)
	# Guard ornament (flower pattern)
	_px(img, 14, 39, guard_dk)
	_px(img, 18, 40, guard_dk)
	_px(img, 16, 38, guard_hi)

	# Tsuka (handle) — wrapped with ito (diamond pattern)
	for i in range(18):
		var hx = 8 - int(i * 0.3)
		var hy = 43 + i
		_fill(img, hx, hy, 7, 1, handle)
		# Diamond wrap pattern
		if i % 4 == 0:
			_fill(img, hx + 1, hy, 5, 1, handle_wrap)
		elif i % 4 == 2:
			_fill(img, hx + 1, hy, 5, 1, handle_wrap_dk)
		else:
			_fill(img, hx + 2, hy, 3, 1, handle_wrap)
	# Menuki (handle ornament)
	_px(img, 7, 50, guard_hi)
	_px(img, 6, 54, guard_hi)

	# Kashira (pommel cap)
	_fill(img, 2, 60, 8, 3, guard)
	_fill(img, 3, 61, 6, 1, guard_hi)

	_outline(img, Color(0.08, 0.08, 0.1))
	_save_weapon(img, "katana")

func _gen_scythe() -> void:
	var img = _img()
	var blade = Color(0.6, 0.3, 0.7)
	var blade_edge = Color(0.8, 0.5, 0.9)
	var blade_dk = Color(0.4, 0.15, 0.5)
	var handle = Color(0.5, 0.35, 0.2)
	var handle_dk = Color(0.38, 0.25, 0.12)

	# Long handle (vertical shaft)
	_fill(img, 28, 16, 4, 44, handle)
	_fill(img, 29, 16, 2, 44, handle_dk)
	# Curved blade at top
	# Blade base connects to shaft
	_fill(img, 30, 8, 14, 6, blade)
	_fill(img, 42, 12, 8, 4, blade)
	_fill(img, 48, 14, 6, 4, blade)
	_fill(img, 52, 17, 5, 3, blade)
	_fill(img, 54, 20, 4, 3, blade)
	_fill(img, 55, 23, 3, 3, blade)
	_fill(img, 54, 26, 3, 2, blade)
	# Edge highlight (inner curve)
	_fill(img, 30, 8, 14, 2, blade_edge)
	_fill(img, 42, 10, 8, 2, blade_edge)
	_fill(img, 48, 12, 6, 2, blade_edge)
	_fill(img, 52, 15, 5, 2, blade_edge)
	_fill(img, 54, 18, 4, 2, blade_edge)
	_fill(img, 55, 21, 3, 2, blade_edge)
	# Dark outer edge
	_fill(img, 30, 13, 14, 2, blade_dk)
	_fill(img, 42, 15, 8, 2, blade_dk)
	# Pommel at bottom
	_fill(img, 27, 58, 6, 4, Color(0.6, 0.5, 0.15))

	_outline(img, Color(0.15, 0.08, 0.18))
	_save_weapon(img, "scythe")

func _gen_shadow_claw() -> void:
	var img = _img()
	var claw = Color(0.5, 0.1, 0.8)
	var claw_hi = Color(0.7, 0.3, 1.0)
	var shadow = Color(0.2, 0.05, 0.4)
	var tip = Color(0.9, 0.5, 1.0)
	var palm = Color(0.35, 0.1, 0.5)

	# Shadow aura base (hand shape)
	_fill(img, 14, 24, 36, 28, shadow)
	_fill(img, 18, 20, 28, 4, shadow)
	# Palm
	_fill(img, 18, 30, 28, 16, palm)
	_circle(img, 32, 38, 12, palm)

	# Five claw fingers spreading upward
	# Left outer claw
	for i in range(24):
		var cx = 10 + int(i * 0.3)
		var cy = 28 - i
		_fill(img, cx, cy, 4, 1, claw)
		if i < 4:
			_fill(img, cx, cy, 4, 1, tip)
		elif i < 8:
			_fill(img, cx + 1, cy, 2, 1, claw_hi)
	# Left inner claw
	for i in range(26):
		var cx = 18 + int(i * 0.15)
		var cy = 26 - i
		_fill(img, cx, cy, 4, 1, claw)
		if i < 4:
			_fill(img, cx, cy, 4, 1, tip)
		elif i < 8:
			_fill(img, cx + 1, cy, 2, 1, claw_hi)
	# Center claw (longest)
	for i in range(30):
		var cx = 28
		var cy = 26 - i
		_fill(img, cx, cy, 5, 1, claw)
		if i < 4:
			_fill(img, cx, cy, 5, 1, tip)
		elif i < 10:
			_fill(img, cx + 1, cy, 3, 1, claw_hi)
	# Right inner claw
	for i in range(26):
		var cx = 38 - int(i * 0.15)
		var cy = 26 - i
		_fill(img, cx, cy, 4, 1, claw)
		if i < 4:
			_fill(img, cx, cy, 4, 1, tip)
		elif i < 8:
			_fill(img, cx + 1, cy, 2, 1, claw_hi)
	# Right outer claw
	for i in range(24):
		var cx = 46 - int(i * 0.3)
		var cy = 28 - i
		_fill(img, cx, cy, 4, 1, claw)
		if i < 4:
			_fill(img, cx, cy, 4, 1, tip)
		elif i < 8:
			_fill(img, cx + 1, cy, 2, 1, claw_hi)

	# Energy glow between claws
	for i in range(6):
		_px(img, 20 + i * 4, 22, claw_hi)
		_px(img, 20 + i * 4, 23, Color(0.9, 0.5, 1.0, 0.5))

	_outline(img, Color(0.1, 0.02, 0.18))
	_save_weapon(img, "shadow_claw")

func _gen_magic_book() -> void:
	var img = _img()
	var cover = Color(0.2, 0.15, 0.55)
	var cover_hi = Color(0.3, 0.22, 0.7)
	var pages = Color(0.9, 0.88, 0.8)
	var pages_dk = Color(0.75, 0.72, 0.65)
	var glow = Color(0.4, 0.6, 1.0)
	var glow_hi = Color(0.6, 0.8, 1.0)
	var gold = Color(0.85, 0.75, 0.2)

	# Book open — left cover
	_fill(img, 4, 14, 26, 38, cover)
	_fill(img, 6, 14, 22, 2, cover_hi)
	# Right cover
	_fill(img, 34, 14, 26, 38, cover)
	_fill(img, 36, 14, 22, 2, cover_hi)
	# Spine
	_fill(img, 30, 12, 4, 42, Color(0.15, 0.1, 0.4))
	# Pages (left)
	_fill(img, 8, 18, 22, 30, pages)
	_fill(img, 10, 20, 18, 2, pages_dk)
	_fill(img, 10, 24, 18, 1, pages_dk)
	_fill(img, 10, 28, 18, 1, pages_dk)
	_fill(img, 10, 32, 18, 1, pages_dk)
	_fill(img, 10, 36, 18, 1, pages_dk)
	_fill(img, 10, 40, 18, 1, pages_dk)
	# Pages (right)
	_fill(img, 36, 18, 22, 30, pages)
	_fill(img, 38, 20, 18, 2, pages_dk)
	_fill(img, 38, 24, 18, 1, pages_dk)
	_fill(img, 38, 28, 18, 1, pages_dk)
	_fill(img, 38, 32, 18, 1, pages_dk)
	_fill(img, 38, 36, 18, 1, pages_dk)
	_fill(img, 38, 40, 18, 1, pages_dk)

	# Magic symbol on right page — glowing rune
	_circle(img, 47, 30, 6, glow)
	_circle(img, 47, 30, 4, glow_hi)
	_circle(img, 47, 30, 2, Color(0.8, 0.9, 1.0))
	# Sparkle lines from symbol
	_line(img, 47, 22, 47, 18, glow)
	_line(img, 47, 38, 47, 42, glow)
	_line(img, 39, 30, 35, 30, glow)
	_line(img, 55, 30, 59, 30, glow)
	# Rune on left page
	_line(img, 14, 24, 24, 34, Color(0.3, 0.5, 0.9, 0.6))
	_line(img, 24, 24, 14, 34, Color(0.3, 0.5, 0.9, 0.6))
	_circle(img, 19, 29, 4, Color(0.3, 0.5, 0.9, 0.4))

	# Gold corner ornaments
	_fill(img, 4, 14, 4, 4, gold)
	_fill(img, 26, 14, 4, 4, gold)
	_fill(img, 4, 48, 4, 4, gold)
	_fill(img, 26, 48, 4, 4, gold)
	_fill(img, 34, 14, 4, 4, gold)
	_fill(img, 56, 14, 4, 4, gold)
	_fill(img, 34, 48, 4, 4, gold)
	_fill(img, 56, 48, 4, 4, gold)

	# Magical glow particles above the book
	for i in range(5):
		var gx = 20 + i * 6
		var gy = 8 + (i % 3) * 2
		_px(img, gx, gy, glow_hi)
		_px(img, gx + 1, gy, glow)

	_outline(img, Color(0.08, 0.05, 0.2))
	_save_weapon(img, "magic_book")

func _gen_whip() -> void:
	var img = _img()
	var leather = Color(0.55, 0.35, 0.18)
	var leather_hi = Color(0.7, 0.48, 0.25)
	var leather_dk = Color(0.38, 0.22, 0.1)
	var handle = Color(0.4, 0.22, 0.1)
	var handle_hi = Color(0.55, 0.38, 0.22)
	var tip_color = Color(0.8, 0.6, 0.3)

	# Handle (bottom left, thick)
	_fill(img, 4, 48, 10, 12, handle)
	_fill(img, 6, 46, 6, 2, handle)
	_fill(img, 5, 50, 4, 6, handle_hi)
	# Metal cap at handle bottom
	_fill(img, 5, 58, 8, 3, Color(0.6, 0.6, 0.65))

	# Whip coil curving up and right (thick, braided look)
	var points = []
	for i in range(40):
		var t = float(i) / 39.0
		var x = int(lerp(12.0, 56.0, t))
		var y = int(lerp(44.0, 6.0, t) + sin(t * PI * 2.5) * 6.0)
		points.append(Vector2i(x, y))
		# Main leather body (tapers from thick to thin)
		var thickness = int(lerp(4.0, 1.0, t))
		for th in range(-thickness, thickness + 1):
			_px(img, x, y + th, leather)
		# Highlight on top edge
		_px(img, x, y - thickness, leather_hi)
		# Dark on bottom edge
		_px(img, x, y + thickness, leather_dk)
		# Braid marks every few pixels
		if i % 5 == 0 and thickness > 1:
			_px(img, x, y, leather_dk)

	# Cracker / tip
	_px(img, 56, 6, tip_color)
	_px(img, 57, 5, tip_color)
	_px(img, 58, 4, tip_color)
	_px(img, 59, 3, Color(1.0, 0.9, 0.6))

	_outline(img, Color(0.15, 0.1, 0.05))
	_save_weapon(img, "whip")

func _gen_lance() -> void:
	var img = _img()
	var tip = Color(0.85, 0.75, 0.2)
	var tip_hi = Color(1.0, 0.9, 0.4)
	var tip_dk = Color(0.65, 0.55, 0.15)
	var shaft = Color(0.55, 0.4, 0.25)
	var shaft_dk = Color(0.4, 0.28, 0.15)
	var guard_color = Color(0.7, 0.6, 0.15)

	# Tip (top, pointed — spearhead)
	_px(img, 30, 0, tip_hi)
	_px(img, 31, 0, tip_hi)
	_fill(img, 29, 1, 4, 2, tip_hi)
	_fill(img, 28, 3, 6, 2, tip)
	_fill(img, 27, 5, 8, 3, tip)
	_fill(img, 26, 8, 10, 3, tip)
	_fill(img, 27, 11, 8, 2, tip_dk)
	# Tip center highlight
	_fill(img, 30, 2, 2, 8, tip_hi)

	# Guard wings
	_fill(img, 20, 13, 22, 3, guard_color)
	_fill(img, 22, 12, 18, 1, Color(0.85, 0.75, 0.25))

	# Shaft (long vertical)
	_fill(img, 28, 16, 6, 44, shaft)
	# Shaft grain/detail
	for i in range(22):
		var sy = 18 + i * 2
		_fill(img, 28, sy, 6, 1, shaft_dk)
	# Shaft highlight (left side)
	_fill(img, 29, 16, 2, 44, Color(0.62, 0.48, 0.3))
	# Pommel at bottom
	_fill(img, 27, 58, 8, 4, Color(0.6, 0.5, 0.15))
	_fill(img, 28, 62, 6, 2, shaft_dk)

	_outline(img, Color(0.12, 0.1, 0.05))
	_save_weapon(img, "lance")

func _gen_hammer() -> void:
	var img = _img()
	var head = Color(0.6, 0.62, 0.65)
	var head_hi = Color(0.8, 0.82, 0.88)
	var head_dk = Color(0.42, 0.44, 0.48)
	var handle = Color(0.5, 0.35, 0.2)
	var handle_dk = Color(0.38, 0.25, 0.12)

	# Handle (vertical)
	_fill(img, 28, 28, 8, 32, handle)
	_fill(img, 29, 28, 4, 32, handle_dk)
	# Handle wrap marks
	for i in range(8):
		_fill(img, 28, 34 + i * 4, 8, 1, Color(0.42, 0.28, 0.14))

	# Hammer head (wide rectangle on top)
	_fill(img, 6, 6, 52, 22, head)
	# Top highlight
	_fill(img, 6, 6, 52, 4, head_hi)
	# Bottom shadow
	_fill(img, 6, 24, 52, 4, head_dk)
	# Left face
	_fill(img, 6, 10, 8, 12, head_dk)
	# Right face
	_fill(img, 50, 10, 8, 12, head_dk)
	# Center cross detail
	_fill(img, 26, 10, 12, 2, Color(0.5, 0.52, 0.56))
	# Face impact marks
	_fill(img, 10, 14, 4, 4, Color(0.5, 0.52, 0.56))
	_fill(img, 50, 14, 4, 4, Color(0.5, 0.52, 0.56))
	# Pommel
	_fill(img, 27, 58, 10, 4, Color(0.55, 0.5, 0.2))

	_outline(img, Color(0.1, 0.1, 0.1))
	_save_weapon(img, "hammer")

func _gen_nunchaku() -> void:
	var img = _img()
	var wood = Color(0.55, 0.35, 0.18)
	var wood_hi = Color(0.7, 0.48, 0.25)
	var wood_dk = Color(0.4, 0.25, 0.1)
	var chain = Color(0.7, 0.7, 0.72)
	var chain_hi = Color(0.85, 0.85, 0.88)
	var cap = Color(0.65, 0.6, 0.2)

	# Left stick (angled, upper-left)
	for i in range(24):
		var sx = 8 + int(i * 0.4)
		var sy = 6 + i
		_fill(img, sx, sy, 6, 1, wood)
		_fill(img, sx + 1, sy, 2, 1, wood_hi)
		if i % 4 == 0:
			_fill(img, sx, sy, 6, 1, wood_dk)
	# Left cap
	_fill(img, 7, 4, 8, 3, cap)

	# Right stick (angled, lower-right)
	for i in range(24):
		var sx = 38 + int(i * 0.4)
		var sy = 32 + i
		_fill(img, sx, sy, 6, 1, wood)
		_fill(img, sx + 1, sy, 2, 1, wood_hi)
		if i % 4 == 0:
			_fill(img, sx, sy, 6, 1, wood_dk)
	# Right cap
	_fill(img, 46, 54, 8, 3, cap)

	# Chain connecting them (links)
	var chain_pts = [
		Vector2i(18, 30), Vector2i(20, 31), Vector2i(22, 31),
		Vector2i(24, 32), Vector2i(26, 32), Vector2i(28, 33),
		Vector2i(30, 33), Vector2i(32, 32), Vector2i(34, 32),
		Vector2i(36, 32), Vector2i(38, 32)
	]
	for pt in chain_pts:
		_fill(img, pt.x, pt.y, 3, 2, chain)
		_px(img, pt.x + 1, pt.y, chain_hi)

	_outline(img, Color(0.15, 0.1, 0.05))
	_save_weapon(img, "nunchaku")

func _gen_dual_katana() -> void:
	var img = _img()
	var blade = Color(0.82, 0.85, 0.9)
	var edge = Color(0.95, 0.97, 1.0)
	var blade_dk = Color(0.65, 0.68, 0.75)
	var handle = Color(0.6, 0.12, 0.12)
	var handle_dk = Color(0.4, 0.08, 0.08)
	var guard = Color(0.75, 0.7, 0.2)

	# Left blade (top-left to center, going down-right)
	for i in range(30):
		var bx = 8 + i
		var by = 4 + i
		_px(img, bx, by, blade)
		_px(img, bx + 1, by, blade)
		_px(img, bx + 2, by, edge)
		_px(img, bx - 1, by, blade_dk)
	# Left guard
	_fill(img, 36, 32, 6, 3, guard)
	# Left handle
	for i in range(10):
		_fill(img, 40 + i, 35 + i, 4, 1, handle)
		if i % 3 == 0:
			_fill(img, 40 + i, 35 + i, 4, 1, handle_dk)

	# Right blade (top-right to center, going down-left)
	for i in range(30):
		var bx = 55 - i
		var by = 4 + i
		_px(img, bx, by, blade)
		_px(img, bx - 1, by, blade)
		_px(img, bx - 2, by, edge)
		_px(img, bx + 1, by, blade_dk)
	# Right guard
	_fill(img, 22, 32, 6, 3, guard)
	# Right handle
	for i in range(10):
		_fill(img, 20 - i, 35 + i, 4, 1, handle)
		if i % 3 == 0:
			_fill(img, 20 - i, 35 + i, 4, 1, handle_dk)

	# Cross point sparkle
	_circle(img, 32, 20, 2, Color(1.0, 1.0, 1.0, 0.8))

	_outline(img, Color(0.1, 0.1, 0.12))
	_save_weapon(img, "dual_katana")

func _gen_cloud_sword() -> void:
	var img = _img()
	var blade = Color(0.3, 0.5, 0.9)
	var glow = Color(0.5, 0.7, 1.0)
	var glow_hi = Color(0.7, 0.85, 1.0)
	var blade_dk = Color(0.2, 0.35, 0.7)
	var handle = Color(0.35, 0.3, 0.25)
	var guard = Color(0.75, 0.7, 0.2)

	# Big wide blade (Buster Sword style)
	_fill(img, 18, 2, 28, 6, glow_hi)
	_fill(img, 16, 8, 32, 10, blade)
	_fill(img, 18, 18, 28, 8, blade)
	_fill(img, 20, 26, 24, 6, blade)
	_fill(img, 22, 32, 20, 4, blade)
	# Glow edge (left)
	_fill(img, 16, 8, 4, 10, glow)
	_fill(img, 18, 18, 4, 8, glow)
	# Glow edge (right)
	_fill(img, 44, 8, 4, 10, glow)
	_fill(img, 42, 18, 4, 8, glow)
	# Center fuller (groove)
	_fill(img, 30, 4, 4, 28, glow_hi)
	# Darker sides
	_fill(img, 16, 14, 6, 4, blade_dk)
	_fill(img, 42, 14, 6, 4, blade_dk)
	# Materia slots (circles on blade)
	_circle(img, 26, 14, 2, Color(0.2, 0.8, 0.3))
	_circle(img, 38, 14, 2, Color(0.8, 0.2, 0.3))

	# Guard
	_fill(img, 14, 36, 36, 3, guard)
	_fill(img, 16, 35, 32, 1, Color(0.85, 0.8, 0.3))

	# Handle
	_fill(img, 28, 39, 8, 16, handle)
	_fill(img, 29, 39, 4, 16, Color(0.4, 0.35, 0.3))
	# Handle wrapping
	for i in range(4):
		_fill(img, 28, 42 + i * 4, 8, 1, Color(0.28, 0.22, 0.18))

	# Pommel
	_fill(img, 26, 55, 12, 4, guard)
	_fill(img, 28, 59, 8, 3, guard)

	_outline(img, Color(0.1, 0.15, 0.3))
	_save_weapon(img, "cloud_sword")

func _gen_boxing_gloves() -> void:
	var img = _img()
	var red = Color(0.82, 0.12, 0.12)
	var red_lt = Color(0.95, 0.28, 0.22)
	var red_dk = Color(0.55, 0.06, 0.06)
	var red_deep = Color(0.4, 0.04, 0.04)
	var lace = Color(0.92, 0.88, 0.82)
	var lace_dk = Color(0.72, 0.68, 0.6)
	var stitch = Color(0.8, 0.75, 0.65)
	var impact = Color(1.0, 1.0, 0.4)
	var impact_br = Color(1.0, 1.0, 0.8)

	# === Left glove (slightly angled, fist facing right) ===
	# Main fist body
	_fill(img, 4, 16, 22, 20, red)
	_fill(img, 6, 14, 18, 4, red)
	_fill(img, 6, 34, 18, 4, red_dk)
	# Highlight (top-left)
	_fill(img, 6, 16, 8, 6, red_lt)
	_circle(img, 10, 18, 4, red_lt)
	# Shadow (bottom-right)
	_fill(img, 18, 28, 6, 6, red_dk)
	_fill(img, 8, 34, 14, 3, red_deep)
	# Knuckle ridge
	_fill(img, 24, 18, 4, 14, red)
	_fill(img, 26, 20, 2, 10, red_dk)
	# Thumb
	_fill(img, 2, 22, 4, 10, red)
	_fill(img, 0, 24, 3, 6, red_dk)
	_fill(img, 3, 24, 1, 6, red_lt)
	# Wrist/cuff
	_fill(img, 6, 38, 18, 10, lace)
	_fill(img, 8, 40, 14, 6, lace_dk)
	# Lace X stitching
	for i in range(4):
		_px(img, 10 + i * 2, 40 + i, stitch)
		_px(img, 18 - i * 2, 40 + i, stitch)
	# Stitching lines on glove
	_fill(img, 10, 14, 10, 1, stitch)
	_fill(img, 14, 22, 1, 8, stitch)

	# === Right glove (fist facing left, slightly overlapping) ===
	_fill(img, 34, 14, 22, 20, red)
	_fill(img, 36, 12, 18, 4, red)
	_fill(img, 36, 32, 18, 4, red_dk)
	# Highlight
	_fill(img, 38, 14, 8, 6, red_lt)
	_circle(img, 42, 16, 4, red_lt)
	# Shadow
	_fill(img, 48, 26, 6, 6, red_dk)
	_fill(img, 38, 32, 14, 3, red_deep)
	# Knuckle ridge
	_fill(img, 34, 16, 4, 14, red)
	_fill(img, 34, 18, 2, 10, red_dk)
	# Thumb
	_fill(img, 56, 20, 4, 10, red)
	_fill(img, 58, 22, 3, 6, red_dk)
	_fill(img, 56, 22, 1, 6, red_lt)
	# Wrist/cuff
	_fill(img, 36, 36, 18, 10, lace)
	_fill(img, 38, 38, 14, 6, lace_dk)
	# Lace X stitching
	for i in range(4):
		_px(img, 40 + i * 2, 38 + i, stitch)
		_px(img, 48 - i * 2, 38 + i, stitch)
	# Stitching lines
	_fill(img, 40, 12, 10, 1, stitch)
	_fill(img, 46, 20, 1, 8, stitch)

	# === Impact effect between gloves ===
	_px(img, 31, 20, impact_br)
	_px(img, 32, 20, impact_br)
	_px(img, 31, 18, impact)
	_px(img, 32, 22, impact)
	_px(img, 29, 20, impact)
	_px(img, 34, 20, impact)
	# Small spark particles
	_px(img, 28, 16, Color(1.0, 0.9, 0.3, 0.6))
	_px(img, 35, 24, Color(1.0, 0.9, 0.3, 0.6))
	_px(img, 30, 14, Color(1.0, 0.9, 0.3, 0.4))

	_outline(img, Color(0.2, 0.04, 0.04))
	_save_weapon(img, "boxing_gloves")

func _gen_chain_whip() -> void:
	var img = _img()
	var chain = Color(0.6, 0.6, 0.65)
	var chain_hi = Color(0.78, 0.78, 0.84)
	var chain_dk = Color(0.42, 0.42, 0.48)
	var handle = Color(0.4, 0.25, 0.15)
	var handle_hi = Color(0.55, 0.38, 0.22)
	var spike = Color(0.5, 0.5, 0.55)
	var electric = Color(0.3, 0.6, 1.0)
	var electric_hi = Color(0.5, 0.8, 1.0)

	# Handle (bottom left, thick)
	_fill(img, 4, 48, 10, 12, handle)
	_fill(img, 6, 46, 6, 2, handle)
	_fill(img, 5, 50, 4, 6, handle_hi)
	# Metal cap
	_fill(img, 5, 58, 8, 3, Color(0.6, 0.6, 0.65))

	# Chain links curving up and right (thicker, more detailed)
	for i in range(18):
		var t = float(i) / 17.0
		var cx = int(lerp(14.0, 54.0, t))
		var cy = int(lerp(44.0, 6.0, t) + sin(t * PI * 1.5) * 4.0)
		# Chain link (oval shapes alternating horizontal/vertical)
		if i % 2 == 0:
			_fill(img, cx - 1, cy - 2, 4, 5, chain)
			_fill(img, cx, cy - 1, 2, 3, chain_hi)
		else:
			_fill(img, cx - 2, cy - 1, 5, 4, chain)
			_fill(img, cx - 1, cy, 3, 2, chain_hi)
		# Electric sparks along the chain
		if i % 3 == 0:
			_px(img, cx + 2, cy - 2, electric)
			_px(img, cx - 2, cy + 2, electric_hi)
			_px(img, cx + 3, cy - 1, electric_hi)

	# Spiked tip at end
	_fill(img, 54, 4, 4, 4, spike)
	_px(img, 58, 2, spike)
	_px(img, 56, 0, spike)
	_px(img, 60, 4, spike)
	_px(img, 52, 2, spike)
	# Electric glow at tip
	_circle(img, 56, 4, 3, Color(0.3, 0.6, 1.0, 0.5))
	_px(img, 56, 4, electric_hi)

	_outline(img, Color(0.12, 0.12, 0.14))
	_save_weapon(img, "chain_whip")

# ==================== SLASH EFFECTS (11) ====================
func _generate_slashes() -> void:
	_gen_katana_slash()
	_gen_scythe_slash()
	_gen_shadow_claw_slash()
	_gen_whip_crack()
	_gen_lance_thrust()
	_gen_hammer_slam()
	_gen_nunchaku_swing()
	_gen_dual_katana_slash()
	_gen_cloud_sword_wave()
	_gen_boxing_punch()
	_gen_chain_whip_slash()

func _gen_katana_slash() -> void:
	var img = _img()
	var white = Color(1.0, 1.0, 1.0, 0.95)
	var blue_light = Color(0.7, 0.85, 1.0, 0.8)
	var blue_tip = Color(0.5, 0.7, 1.0, 0.6)

	# Main arc sweep
	_draw_arc(img, 8, 32, 16.0, 28.0, -0.3, 1.8, white, 80)
	_draw_arc(img, 8, 32, 20.0, 30.0, -0.1, 1.6, blue_light, 60)
	# Bright core
	_draw_arc(img, 8, 32, 22.0, 26.0, 0.2, 1.2, white, 50)
	# Fading tip
	_draw_arc(img, 8, 32, 28.0, 32.0, 0.8, 1.5, blue_tip, 30)

	_save_slash(img, "katana_slash")

func _gen_scythe_slash() -> void:
	var img = _img()
	var purple = Color(0.6, 0.15, 0.85, 0.9)
	var purple_light = Color(0.75, 0.3, 1.0, 0.7)
	var purple_dark = Color(0.35, 0.05, 0.55, 0.5)

	_draw_arc(img, 32, 48, 18.0, 28.0, 0.0, PI * 1.5, purple, 100)
	_draw_arc(img, 32, 48, 22.0, 26.0, 0.0, PI * 1.5, purple_light, 80)
	_draw_arc(img, 32, 48, 16.0, 20.0, 0.3, PI * 1.2, purple_dark, 60)
	# Bright leading edge
	_draw_arc(img, 32, 48, 22.0, 27.0, PI * 1.0, PI * 1.5, Color(0.9, 0.5, 1.0, 0.95), 30)

	_save_slash(img, "scythe_slash")

func _gen_shadow_claw_slash() -> void:
	var img = _img()
	var purple = Color(0.6, 0.15, 0.9, 0.9)
	var light_purple = Color(0.8, 0.4, 1.0, 0.7)
	var dark_purple = Color(0.4, 0.1, 0.6, 0.5)

	# Three claw marks diagonal
	for claw in range(3):
		var offset_x = claw * 10 + 6
		var offset_y = claw * 6 + 4
		for i in range(40):
			var x = offset_x + i
			var y = offset_y + int(i * 0.7)
			_px(img, x, y, purple)
			_px(img, x + 1, y, purple)
			if x + 2 < S:
				_px(img, x + 2, y, light_purple)
			if y + 1 < S:
				_px(img, x, y + 1, dark_purple)
				_px(img, x + 1, y + 1, dark_purple)

	_outline(img, Color(0.2, 0.05, 0.3))
	_save_slash(img, "shadow_claw_slash")

func _gen_whip_crack() -> void:
	var img = _img()
	var brown = Color(0.55, 0.35, 0.15, 0.9)
	var brown_light = Color(0.75, 0.55, 0.3, 0.7)
	var flash = Color(1.0, 1.0, 0.9, 0.85)

	# Wavy S-curve
	for i in range(50):
		var t = float(i) / 49.0
		var x = int(lerp(4.0, 56.0, t))
		var wave = sin(t * PI * 3.0) * 8.0
		var y = int(lerp(8.0, 56.0, t) + wave)
		var thickness = int(lerp(4.0, 1.0, t))
		var c = brown if t < 0.7 else brown_light
		for th in range(-thickness, thickness + 1):
			_px(img, x, y + th, c)
		if t < 0.5:
			_px(img, x, y - thickness, Color(0.65, 0.45, 0.2, 0.8))

	# Crack flash at the tip
	_circle(img, 54, 52, 4, flash)
	_px(img, 56, 50, flash)
	_px(img, 52, 54, flash)

	_save_slash(img, "whip_crack")

func _gen_lance_thrust() -> void:
	var img = _img()
	var silver = Color(0.85, 0.85, 0.9, 0.9)
	var silver_bright = Color(1.0, 1.0, 1.0, 0.95)
	var silver_dark = Color(0.6, 0.6, 0.7, 0.6)

	# Central thrust line
	_fill(img, 28, 4, 8, 52, silver)
	_fill(img, 30, 8, 4, 44, silver_bright)
	# Side streaks
	_fill(img, 24, 16, 2, 36, silver_dark)
	_fill(img, 38, 16, 2, 36, silver_dark)
	# Pointed tip
	_fill(img, 29, 2, 6, 2, silver)
	_fill(img, 30, 0, 4, 2, silver_bright)
	# Arrow tip wings
	_fill(img, 24, 6, 4, 2, silver)
	_fill(img, 36, 6, 4, 2, silver)
	# Speed lines
	_line(img, 18, 20, 22, 52, Color(0.7, 0.7, 0.8, 0.3))
	_line(img, 46, 20, 42, 52, Color(0.7, 0.7, 0.8, 0.3))

	_save_slash(img, "lance_thrust")

func _gen_hammer_slam() -> void:
	var img = _img()
	var brown = Color(0.65, 0.45, 0.2, 0.85)
	var brown_light = Color(0.8, 0.6, 0.3, 0.7)
	var tan = Color(0.9, 0.75, 0.5, 0.5)

	# Concentric rings
	_ring(img, 32, 32, 28, 24, tan)
	_ring(img, 32, 32, 22, 18, brown_light)
	_ring(img, 32, 32, 16, 12, brown)
	# Bright impact center
	_circle(img, 32, 32, 8, Color(1.0, 0.9, 0.7, 0.9))
	_circle(img, 32, 32, 4, Color(1.0, 1.0, 0.9, 1.0))
	# Cracks radiating outward
	_thick_line(img, 32, 32, 8, 8, brown, 2)
	_thick_line(img, 32, 32, 56, 8, brown, 2)
	_thick_line(img, 32, 32, 4, 32, brown_light, 1)
	_thick_line(img, 32, 32, 60, 32, brown_light, 1)
	_thick_line(img, 32, 32, 12, 56, brown_light, 1)
	_thick_line(img, 32, 32, 52, 56, brown_light, 1)

	_save_slash(img, "hammer_slam")

func _gen_nunchaku_swing() -> void:
	var img = _img()
	var brown = Color(0.6, 0.4, 0.15, 0.9)
	var brown_light = Color(0.8, 0.6, 0.3, 0.75)

	# First arc — upper
	_draw_arc(img, 16, 24, 10.0, 18.0, -0.5, 1.8, brown, 60)
	_draw_arc(img, 16, 24, 12.0, 16.0, -0.3, 1.5, brown_light, 50)
	# Second arc — lower, mirrored
	_draw_arc(img, 48, 44, 10.0, 18.0, PI + 0.5, PI + 2.8, brown, 60)
	_draw_arc(img, 48, 44, 12.0, 16.0, PI + 0.7, PI + 2.5, brown_light, 50)
	# Chain dots connecting
	for i in range(5):
		_fill(img, 30 + i * 2, 32 + i, 2, 2, Color(0.5, 0.5, 0.55, 0.8))

	_save_slash(img, "nunchaku_swing")

func _gen_dual_katana_slash() -> void:
	var img = _img()
	var white = Color(1.0, 1.0, 1.0, 0.9)
	var white_glow = Color(0.85, 0.9, 1.0, 0.6)

	# X cross pattern
	_thick_line(img, 4, 8, 56, 56, white, 3)
	_thick_line(img, 56, 8, 4, 56, white, 3)
	# Glow
	_thick_line(img, 2, 6, 58, 58, white_glow, 1)
	_thick_line(img, 58, 6, 2, 58, white_glow, 1)
	# Bright intersection center
	_circle(img, 32, 32, 4, Color(1.0, 1.0, 1.0, 1.0))
	# Sparkle tips
	for pos in [Vector2i(4, 8), Vector2i(56, 8), Vector2i(4, 56), Vector2i(56, 56)]:
		_circle(img, pos.x, pos.y, 2, white_glow)

	_save_slash(img, "dual_katana_slash")

func _gen_cloud_sword_wave() -> void:
	var img = _img()
	var blue = Color(0.3, 0.55, 1.0, 0.9)
	var blue_bright = Color(0.6, 0.8, 1.0, 0.95)
	var blue_dark = Color(0.15, 0.3, 0.7, 0.6)

	# Wide energy wave crescent
	_draw_arc(img, 32, 48, 24.0, 38.0, PI + 0.5, PI * 2 - 0.5, blue, 80)
	_draw_arc(img, 32, 48, 28.0, 36.0, PI + 0.7, PI * 2 - 0.7, blue_bright, 60)
	_draw_arc(img, 32, 48, 22.0, 26.0, PI + 0.6, PI * 2 - 0.6, blue_dark, 50)
	# White-blue edge
	_draw_arc(img, 32, 48, 34.0, 38.0, PI + 0.8, PI * 2 - 0.8, Color(0.8, 0.9, 1.0, 0.9), 40)

	_save_slash(img, "cloud_sword_wave")

func _gen_boxing_punch() -> void:
	var img = _img()
	var yellow = Color(1.0, 0.9, 0.2, 0.9)
	var orange = Color(1.0, 0.6, 0.1, 0.8)
	var white = Color(1.0, 1.0, 1.0, 0.95)

	# Impact star burst
	# Center bright
	_circle(img, 32, 32, 6, white)
	_circle(img, 32, 32, 10, yellow)
	# Radiating spikes
	for angle_i in range(8):
		var angle = float(angle_i) * PI / 4.0
		for r in range(10, 28):
			var x = 32 + int(cos(angle) * r)
			var y = 32 + int(sin(angle) * r)
			var t = float(r - 10) / 18.0
			var c = yellow.lerp(orange, t)
			c.a = lerp(0.9, 0.2, t)
			_px(img, x, y, c)
			# Thicker spikes
			var perp_x = int(-sin(angle))
			var perp_y = int(cos(angle))
			_px(img, x + perp_x, y + perp_y, c)
	# Secondary smaller spikes between main ones
	for angle_i in range(8):
		var angle = float(angle_i) * PI / 4.0 + PI / 8.0
		for r in range(8, 18):
			var x = 32 + int(cos(angle) * r)
			var y = 32 + int(sin(angle) * r)
			var t = float(r - 8) / 10.0
			var c = orange
			c.a = lerp(0.7, 0.1, t)
			_px(img, x, y, c)

	_save_slash(img, "boxing_punch")

func _gen_chain_whip_slash() -> void:
	var img = _img()
	var yellow = Color(1.0, 0.9, 0.2, 0.9)
	var blue = Color(0.3, 0.6, 1.0, 0.7)
	var white = Color(1.0, 1.0, 0.9, 0.9)

	# Electric arc chain
	for i in range(40):
		var t = float(i) / 39.0
		var x = int(12 + t * 40)
		var y = int(32 - sin(t * PI) * 20)
		var c = yellow if i % 2 == 0 else blue
		_fill(img, x - 1, y - 1, 3, 3, c)
		if i % 2 == 0:
			_px(img, x, y, white)
		# Sparks branching off
		if i % 4 == 0:
			var spark_len = randi() % 6 + 3
			var spark_dir = 1 if i % 8 == 0 else -1
			for s in range(spark_len):
				_px(img, x + s, y + spark_dir * s, Color(0.5, 0.8, 1.0, 0.5))

	# Bright glow at center
	_circle(img, 32, 16, 4, Color(0.6, 0.8, 1.0, 0.4))

	_outline(img, Color(0.15, 0.1, 0.05))
	_save_slash(img, "chain_whip_slash")
