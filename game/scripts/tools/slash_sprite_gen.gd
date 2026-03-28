extends SceneTree

## Generates 16x32 pixel art slash trail sprites for all 10 melee weapons.
## Run: godot --headless --script res://scripts/tools/slash_sprite_gen.gd

const W := 16  # Width
const H := 32  # Height

func _init() -> void:
	_generate_all()
	quit()

func _generate_all() -> void:
	DirAccess.make_dir_recursive_absolute("res://assets/sprites/effects/slashes")

	_gen_katana_slash()
	_gen_scythe_slash()
	_gen_axe_slash()
	_gen_hammer_slam()
	_gen_whip_crack()
	_gen_lance_thrust()
	_gen_nunchaku_swing()
	_gen_dual_katana_slash()
	_gen_cloud_sword_wave()
	_gen_boxing_punch()

	print("All slash trail sprites generated!")

# ==================== HELPERS ====================
func _img() -> Image:
	return Image.create(W, H, false, Image.FORMAT_RGBA8)

func _fill(img: Image, x: int, y: int, w: int, h: int, color: Color) -> void:
	for px in range(maxi(x, 0), mini(x + w, W)):
		for py in range(maxi(y, 0), mini(y + h, H)):
			img.set_pixel(px, py, color)

func _px(img: Image, x: int, y: int, color: Color) -> void:
	if x >= 0 and x < W and y >= 0 and y < H:
		img.set_pixel(x, y, color)

func _save(img: Image, name: String) -> void:
	var path = "res://assets/sprites/effects/slashes/" + name + ".png"
	img.save_png(path)
	print("  Saved: ", path)

func _draw_arc(img: Image, cx: int, cy: int, r_inner: float, r_outer: float, angle_start: float, angle_end: float, color: Color, steps: int = 60) -> void:
	## Draw a filled arc segment between two radii and two angles
	for i in range(steps):
		var t = float(i) / float(steps - 1)
		var angle = lerp(angle_start, angle_end, t)
		for ri in range(int(r_inner), int(r_outer) + 1):
			var rf = float(ri) + 0.5
			var px = cx + int(round(cos(angle) * rf))
			var py = cy + int(round(sin(angle) * rf))
			_px(img, px, py, color)

func _draw_line(img: Image, x0: int, y0: int, x1: int, y1: int, color: Color) -> void:
	## Bresenham line
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

func _draw_thick_line(img: Image, x0: int, y0: int, x1: int, y1: int, color: Color, thickness: int = 2) -> void:
	for ox in range(-thickness / 2, thickness / 2 + 1):
		for oy in range(-thickness / 2, thickness / 2 + 1):
			_draw_line(img, x0 + ox, y0 + oy, x1 + ox, y1 + oy, color)

# ==================== SPRITES ====================

func _gen_katana_slash() -> void:
	## White/blue arc sweep
	var img = _img()
	var white = Color(1.0, 1.0, 1.0, 0.95)
	var blue_light = Color(0.7, 0.85, 1.0, 0.8)
	var blue_tip = Color(0.5, 0.7, 1.0, 0.6)

	# Main arc sweep from top-left to bottom-right
	_draw_arc(img, 2, 8, 5.0, 8.0, -0.3, 1.8, white, 50)
	_draw_arc(img, 2, 8, 6.0, 9.0, -0.1, 1.6, blue_light, 40)
	# Bright core
	_draw_arc(img, 2, 8, 6.5, 7.5, 0.2, 1.2, white, 30)
	# Fading tip
	_draw_arc(img, 2, 8, 8.0, 10.0, 0.8, 1.5, blue_tip, 20)

	_save(img, "katana_slash")

func _gen_scythe_slash() -> void:
	## Purple circular arc
	var img = _img()
	var purple = Color(0.6, 0.15, 0.85, 0.9)
	var purple_light = Color(0.75, 0.3, 1.0, 0.7)
	var purple_dark = Color(0.35, 0.05, 0.55, 0.5)

	# Full circular arc
	_draw_arc(img, 8, 16, 6.0, 9.0, 0.0, PI * 1.5, purple, 80)
	_draw_arc(img, 8, 16, 7.0, 8.0, 0.0, PI * 1.5, purple_light, 70)
	# Inner glow
	_draw_arc(img, 8, 16, 5.0, 6.5, 0.3, PI * 1.2, purple_dark, 50)
	# Bright highlight on leading edge
	_draw_arc(img, 8, 16, 7.0, 8.5, PI * 1.0, PI * 1.5, Color(0.9, 0.5, 1.0, 0.95), 20)

	_save(img, "scythe_slash")

func _gen_axe_slash() -> void:
	## Red heavy arc
	var img = _img()
	var red = Color(1.0, 0.2, 0.1, 0.9)
	var red_dark = Color(0.7, 0.1, 0.05, 0.7)
	var orange = Color(1.0, 0.5, 0.15, 0.8)

	# Heavy wide arc
	_draw_arc(img, 4, 10, 5.0, 10.0, -0.2, 1.6, red_dark, 50)
	_draw_arc(img, 4, 10, 6.0, 9.0, 0.0, 1.4, red, 50)
	# Orange hot center
	_draw_arc(img, 4, 10, 7.0, 8.0, 0.3, 1.1, orange, 30)
	# White-hot core line
	_draw_arc(img, 4, 10, 7.5, 8.0, 0.4, 1.0, Color(1.0, 0.8, 0.6, 0.95), 20)

	_save(img, "axe_slash")

func _gen_hammer_slam() -> void:
	## Brown ground impact shockwave — concentric rings
	var img = _img()
	var brown = Color(0.65, 0.45, 0.2, 0.85)
	var brown_light = Color(0.8, 0.6, 0.3, 0.7)
	var tan = Color(0.9, 0.75, 0.5, 0.5)

	# Outer ring
	_draw_arc(img, 8, 16, 10.0, 12.0, 0.0, PI * 2.0, tan, 80)
	# Middle ring
	_draw_arc(img, 8, 16, 7.0, 9.0, 0.0, PI * 2.0, brown_light, 70)
	# Inner ring
	_draw_arc(img, 8, 16, 4.0, 6.0, 0.0, PI * 2.0, brown, 60)
	# Bright impact center
	_fill(img, 6, 14, 4, 4, Color(1.0, 0.9, 0.7, 0.9))
	# Cracks radiating outward
	_draw_line(img, 8, 16, 2, 6, brown)
	_draw_line(img, 8, 16, 14, 6, brown)
	_draw_line(img, 8, 16, 0, 16, brown_light)
	_draw_line(img, 8, 16, 15, 16, brown_light)
	_draw_line(img, 8, 16, 4, 2, brown_light)
	_draw_line(img, 8, 16, 12, 2, brown_light)

	_save(img, "hammer_slam")

func _gen_whip_crack() -> void:
	## Brown wavy line
	var img = _img()
	var brown = Color(0.55, 0.35, 0.15, 0.9)
	var brown_light = Color(0.75, 0.55, 0.3, 0.7)
	var flash = Color(1.0, 1.0, 0.9, 0.85)

	# Wavy S-curve line from left to right, top to bottom
	for i in range(30):
		var t = float(i) / 29.0
		var x = int(lerp(1.0, 14.0, t))
		var wave = sin(t * PI * 3.0) * 3.0
		var y = int(lerp(2.0, 28.0, t) + wave)
		# Thicker at base, thinner at tip
		var c = brown if t < 0.7 else brown_light
		_px(img, x, y, c)
		_px(img, x + 1, y, c)
		if t < 0.5:
			_px(img, x, y + 1, c)

	# Crack flash at the tip
	_px(img, 13, 26, flash)
	_px(img, 14, 25, flash)
	_px(img, 14, 27, flash)
	_px(img, 12, 26, flash)
	_px(img, 15, 26, flash)

	_save(img, "whip_crack")

func _gen_lance_thrust() -> void:
	## Silver straight thrust line
	var img = _img()
	var silver = Color(0.85, 0.85, 0.9, 0.9)
	var silver_bright = Color(1.0, 1.0, 1.0, 0.95)
	var silver_dark = Color(0.6, 0.6, 0.7, 0.6)

	# Central thrust line — vertical, narrow
	_fill(img, 7, 2, 2, 26, silver)
	# Bright core
	_fill(img, 7, 4, 2, 20, silver_bright)
	# Side highlights
	_fill(img, 6, 6, 1, 18, silver_dark)
	_fill(img, 9, 6, 1, 18, silver_dark)
	# Pointed tip at top
	_px(img, 7, 1, silver)
	_px(img, 8, 1, silver)
	_px(img, 7, 0, silver_dark)
	# Speed lines flanking
	_draw_line(img, 4, 10, 5, 24, Color(0.7, 0.7, 0.8, 0.3))
	_draw_line(img, 11, 10, 10, 24, Color(0.7, 0.7, 0.8, 0.3))
	# Arrow tip
	_px(img, 6, 2, silver)
	_px(img, 9, 2, silver)
	_px(img, 5, 3, silver_dark)
	_px(img, 10, 3, silver_dark)

	_save(img, "lance_thrust")

func _gen_nunchaku_swing() -> void:
	## Double brown arcs
	var img = _img()
	var brown = Color(0.6, 0.4, 0.15, 0.9)
	var brown_light = Color(0.8, 0.6, 0.3, 0.75)

	# First arc — upper portion
	_draw_arc(img, 4, 8, 4.0, 6.0, -0.5, 1.8, brown, 40)
	_draw_arc(img, 4, 8, 4.5, 5.5, -0.3, 1.5, brown_light, 30)

	# Second arc — lower portion, mirrored
	_draw_arc(img, 12, 22, 4.0, 6.0, PI + 0.5, PI + 2.8, brown, 40)
	_draw_arc(img, 12, 22, 4.5, 5.5, PI + 0.7, PI + 2.5, brown_light, 30)

	# Chain connecting the two arcs (dots)
	_px(img, 8, 14, Color(0.5, 0.5, 0.55, 0.8))
	_px(img, 8, 15, Color(0.5, 0.5, 0.55, 0.8))
	_px(img, 8, 16, Color(0.5, 0.5, 0.55, 0.8))

	_save(img, "nunchaku_swing")

func _gen_dual_katana_slash() -> void:
	## X cross pattern in white
	var img = _img()
	var white = Color(1.0, 1.0, 1.0, 0.9)
	var white_glow = Color(0.85, 0.9, 1.0, 0.6)

	# Top-left to bottom-right slash
	_draw_thick_line(img, 1, 3, 14, 28, white, 2)
	# Top-right to bottom-left slash
	_draw_thick_line(img, 14, 3, 1, 28, white, 2)

	# Glow around the X
	_draw_thick_line(img, 0, 2, 15, 29, white_glow, 1)
	_draw_thick_line(img, 15, 2, 0, 29, white_glow, 1)

	# Bright intersection at center
	_fill(img, 6, 14, 4, 3, Color(1.0, 1.0, 1.0, 1.0))

	# Small sparkle points at tips
	for pos in [Vector2i(1, 3), Vector2i(14, 3), Vector2i(1, 28), Vector2i(14, 28)]:
		_px(img, pos.x - 1, pos.y, white_glow)
		_px(img, pos.x + 1, pos.y, white_glow)
		_px(img, pos.x, pos.y - 1, white_glow)
		_px(img, pos.x, pos.y + 1, white_glow)

	_save(img, "dual_katana_slash")

func _gen_cloud_sword_wave() -> void:
	## Blue energy wave
	var img = _img()
	var blue = Color(0.3, 0.55, 1.0, 0.9)
	var blue_bright = Color(0.6, 0.8, 1.0, 0.95)
	var blue_dark = Color(0.15, 0.3, 0.7, 0.6)

	# Wide energy wave crescent
	_draw_arc(img, 8, 20, 8.0, 13.0, PI + 0.5, PI * 2 - 0.5, blue, 60)
	_draw_arc(img, 8, 20, 9.0, 12.0, PI + 0.7, PI * 2 - 0.7, blue_bright, 50)
	# Inner darker fill
	_draw_arc(img, 8, 20, 7.0, 9.0, PI + 0.6, PI * 2 - 0.6, blue_dark, 40)
	# Bright white-blue edge
	_draw_arc(img, 8, 20, 11.5, 12.5, PI + 0.8, PI * 2 - 0.8, Color(0.8, 0.9, 1.0, 0.95), 30)

	# Energy particles scattered
	_px(img, 3, 6, Color(0.5, 0.7, 1.0, 0.5))
	_px(img, 12, 5, Color(0.5, 0.7, 1.0, 0.5))
	_px(img, 5, 4, Color(0.6, 0.8, 1.0, 0.4))
	_px(img, 10, 3, Color(0.6, 0.8, 1.0, 0.4))

	_save(img, "cloud_sword_wave")

func _gen_boxing_punch() -> void:
	## Yellow star burst impact
	var img = _img()
	var yellow = Color(1.0, 0.9, 0.2, 0.9)
	var yellow_bright = Color(1.0, 1.0, 0.6, 0.95)
	var orange = Color(1.0, 0.6, 0.1, 0.7)

	var cx = 8
	var cy = 16

	# Star burst — 8 rays outward
	for i in range(8):
		var angle = float(i) / 8.0 * PI * 2.0
		var length = 8.0 if i % 2 == 0 else 5.0
		var ex = cx + int(round(cos(angle) * length))
		var ey = cy + int(round(sin(angle) * length))
		var c = yellow if i % 2 == 0 else orange
		_draw_thick_line(img, cx, cy, ex, ey, c, 1)

	# Bright center
	_fill(img, cx - 2, cy - 2, 4, 4, yellow_bright)
	_fill(img, cx - 1, cy - 1, 2, 2, Color(1.0, 1.0, 1.0, 1.0))

	# Impact circles
	_draw_arc(img, cx, cy, 3.0, 4.0, 0.0, PI * 2.0, Color(1.0, 0.85, 0.3, 0.5), 40)

	# Small sparkle dots at ray tips
	for i in range(4):
		var angle = float(i) / 4.0 * PI * 2.0
		var tx = cx + int(round(cos(angle) * 9.0))
		var ty = cy + int(round(sin(angle) * 9.0))
		_px(img, tx, ty, yellow_bright)

	_save(img, "boxing_punch")
