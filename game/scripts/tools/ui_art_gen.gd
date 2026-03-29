extends SceneTree

## Generates pixel art UI assets for menus: backgrounds, buttons, panels, etc.

var rng := RandomNumberGenerator.new()

func _init() -> void:
	rng.seed = 42  # Deterministic for reproducibility

	print("=== UI Art Generator ===")
	_gen_menu_bg()
	_gen_btn_normal()
	_gen_btn_hover()
	_gen_btn_primary()
	_gen_btn_primary_hover()
	_gen_panel_bg()
	_gen_panel_header()
	_gen_shop_bg()
	_gen_divider()
	_gen_crystal_icon()
	print("=== All UI assets generated! ===")
	quit()


# ── Helpers ──────────────────────────────────────────────────────────────────

func _save(img: Image, path: String) -> void:
	var dir := path.get_base_dir()
	if not DirAccess.dir_exists_absolute(dir):
		DirAccess.make_dir_recursive_absolute(dir)
	img.save_png(path)
	print("  Saved: ", path)

func _lerp_color(a: Color, b: Color, t: float) -> Color:
	return Color(
		lerpf(a.r, b.r, t),
		lerpf(a.g, b.g, t),
		lerpf(a.b, b.b, t),
		lerpf(a.a, b.a, t)
	)

func _blend(base: Color, over: Color) -> Color:
	var a := over.a
	return Color(
		base.r * (1.0 - a) + over.r * a,
		base.g * (1.0 - a) + over.g * a,
		base.b * (1.0 - a) + over.b * a,
		clampf(base.a + a, 0.0, 1.0)
	)

func _set_px(img: Image, x: int, y: int, c: Color) -> void:
	if x >= 0 and x < img.get_width() and y >= 0 and y < img.get_height():
		img.set_pixel(x, y, c)

func _blend_px(img: Image, x: int, y: int, c: Color) -> void:
	if x >= 0 and x < img.get_width() and y >= 0 and y < img.get_height():
		var existing := img.get_pixel(x, y)
		img.set_pixel(x, y, _blend(existing, c))

func _fill_rect(img: Image, rx: int, ry: int, rw: int, rh: int, c: Color) -> void:
	for yy in range(ry, ry + rh):
		for xx in range(rx, rx + rw):
			_set_px(img, xx, yy, c)

func _blend_rect(img: Image, rx: int, ry: int, rw: int, rh: int, c: Color) -> void:
	for yy in range(ry, ry + rh):
		for xx in range(rx, rx + rw):
			_blend_px(img, xx, yy, c)

func _fill_circle(img: Image, cx: int, cy: int, radius: int, c: Color) -> void:
	for yy in range(cy - radius, cy + radius + 1):
		for xx in range(cx - radius, cx + radius + 1):
			var dist := sqrt(float((xx - cx) * (xx - cx) + (yy - cy) * (yy - cy)))
			if dist <= float(radius):
				_set_px(img, xx, yy, c)

func _blend_circle(img: Image, cx: int, cy: int, radius: int, c: Color) -> void:
	for yy in range(cy - radius, cy + radius + 1):
		for xx in range(cx - radius, cx + radius + 1):
			var dist := sqrt(float((xx - cx) * (xx - cx) + (yy - cy) * (yy - cy)))
			if dist <= float(radius):
				_blend_px(img, xx, yy, c)

func _draw_rounded_border(img: Image, w: int, h: int, border_c: Color, radius: int, thickness: int = 1) -> void:
	# Top and bottom edges
	for x in range(radius, w - radius):
		for t in range(thickness):
			_set_px(img, x, t, border_c)
			_set_px(img, x, h - 1 - t, border_c)
	# Left and right edges
	for y in range(radius, h - radius):
		for t in range(thickness):
			_set_px(img, t, y, border_c)
			_set_px(img, w - 1 - t, y, border_c)
	# Rounded corners using quarter circles
	for i in range(4):
		var cx := radius if (i == 0 or i == 2) else w - 1 - radius
		var cy := radius if (i == 0 or i == 1) else h - 1 - radius
		for angle_step in range(91):
			var a := deg_to_rad(float(angle_step) + i * 90.0)
			for t in range(thickness):
				var r := float(radius - t)
				var px := cx + int(round(cos(a) * r))
				var py := cy - int(round(sin(a) * r))
				_set_px(img, px, py, border_c)

func _clear_outside_rounded(img: Image, w: int, h: int, radius: int) -> void:
	# Make pixels outside rounded corners transparent
	for corner in range(4):
		var cx := radius if (corner == 0 or corner == 2) else w - 1 - radius
		var cy := radius if (corner == 0 or corner == 1) else h - 1 - radius
		var sx := 0 if (corner == 0 or corner == 2) else w - radius
		var sy := 0 if (corner == 0 or corner == 1) else h - radius
		for yy in range(sy, sy + radius + 1):
			for xx in range(sx, sx + radius + 1):
				var dx := float(xx - cx)
				var dy := float(yy - cy)
				if sqrt(dx * dx + dy * dy) > float(radius) + 0.5:
					_set_px(img, xx, yy, Color(0, 0, 0, 0))


# ── 1. Menu Background (1280x720) ───────────────────────────────────────────

func _gen_menu_bg() -> void:
	print("Generating menu background...")
	var w := 1280
	var h := 720
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)

	# Sky gradient: dark purple-blue
	var sky_top := Color(0.02, 0.01, 0.06)
	var sky_bot := Color(0.06, 0.04, 0.14)
	for y in range(h):
		var t := float(y) / float(h)
		var c := _lerp_color(sky_top, sky_bot, t)
		for x in range(w):
			img.set_pixel(x, y, c)

	# Stars: tiny dots in upper 65%
	var star_colors := [
		Color(1.0, 1.0, 1.0, 0.9),
		Color(0.8, 0.85, 1.0, 0.8),
		Color(0.7, 0.8, 1.0, 0.7),
		Color(1.0, 0.95, 0.8, 0.6),
		Color(0.9, 0.9, 1.0, 0.5),
	]
	for i in range(55):
		var sx := rng.randi_range(10, w - 10)
		var sy := rng.randi_range(5, int(h * 0.6))
		var sc: Color = star_colors[rng.randi_range(0, star_colors.size() - 1)]
		_set_px(img, sx, sy, sc)
		# Some stars are 2px (brighter cross pattern)
		if rng.randf() < 0.3:
			var dim := Color(sc.r, sc.g, sc.b, sc.a * 0.4)
			_set_px(img, sx + 1, sy, dim)
			_set_px(img, sx - 1, sy, dim)
			_set_px(img, sx, sy + 1, dim)
			_set_px(img, sx, sy - 1, dim)

	# Nebula / subtle color clouds in sky
	for i in range(8):
		var nx := rng.randi_range(100, w - 100)
		var ny := rng.randi_range(40, int(h * 0.45))
		var nr := rng.randi_range(40, 100)
		var nebula_c := Color(0.15, 0.05, 0.2, 0.02) if rng.randf() < 0.5 else Color(0.05, 0.08, 0.2, 0.02)
		for yy in range(ny - nr, ny + nr):
			for xx in range(nx - nr, nx + nr):
				var dist := sqrt(float((xx - nx) * (xx - nx) + (yy - ny) * (yy - ny)))
				if dist < float(nr):
					var fade := 1.0 - dist / float(nr)
					var nc := Color(nebula_c.r, nebula_c.g, nebula_c.b, nebula_c.a * fade * fade)
					_blend_px(img, xx, yy, nc)

	# Moon: top-right, pale glow
	var moon_cx := 1050
	var moon_cy := 110
	var moon_r := 38
	# Moon glow (outer)
	for yy in range(moon_cy - 80, moon_cy + 81):
		for xx in range(moon_cx - 80, moon_cx + 81):
			var dist := sqrt(float((xx - moon_cx) * (xx - moon_cx) + (yy - moon_cy) * (yy - moon_cy)))
			if dist < 80.0:
				var fade := 1.0 - dist / 80.0
				var glow_c := Color(0.6, 0.6, 0.8, 0.06 * fade * fade)
				_blend_px(img, xx, yy, glow_c)
	# Moon disc
	for yy in range(moon_cy - moon_r, moon_cy + moon_r + 1):
		for xx in range(moon_cx - moon_r, moon_cx + moon_r + 1):
			var dist: float = sqrt(float((xx - moon_cx) * (xx - moon_cx) + (yy - moon_cy) * (yy - moon_cy)))
			if dist <= float(moon_r):
				var edge_fade: float = 1.0 - maxf(0.0, (dist - float(moon_r - 3)) / 3.0)
				var base_c := Color(0.75, 0.75, 0.85, edge_fade)
				# Add craters (darker spots)
				var craters: Array = [[moon_cx - 10, moon_cy - 8, 6], [moon_cx + 12, moon_cy + 5, 5],
								[moon_cx - 5, moon_cy + 12, 4], [moon_cx + 5, moon_cy - 15, 3],
								[moon_cx + 15, moon_cy - 10, 4]]
				for cr: Array in craters:
					var cd: float = sqrt(float((xx - int(cr[0])) * (xx - int(cr[0])) + (yy - int(cr[1])) * (yy - int(cr[1]))))
					if cd < float(int(cr[2])):
						base_c = Color(0.6, 0.6, 0.7, edge_fade)
				_blend_px(img, xx, yy, base_c)

	# Far mountains (background layer) — darker, further back
	var far_mt_base_y := 460
	for x in range(w):
		var mh := 0.0
		mh += sin(float(x) * 0.003) * 70.0
		mh += sin(float(x) * 0.007 + 1.5) * 40.0
		mh += sin(float(x) * 0.015 + 3.0) * 20.0
		mh += sin(float(x) * 0.002 + 0.5) * 50.0
		var peak_y := far_mt_base_y - int(mh) - 40
		for y in range(peak_y, far_mt_base_y + 30):
			if y >= 0 and y < h:
				var mt_c := Color(0.04, 0.03, 0.07)
				# Snow caps on peaks
				if y < peak_y + 4 and mh > 80:
					mt_c = Color(0.12, 0.12, 0.16)
				_set_px(img, x, y, mt_c)

	# Near mountains (foreground layer) — slightly lighter
	var mt_base_y := 520
	for x in range(w):
		var mh := 0.0
		mh += sin(float(x) * 0.005 + 2.0) * 80.0
		mh += sin(float(x) * 0.012 + 0.7) * 35.0
		mh += sin(float(x) * 0.025 + 4.0) * 15.0
		var peak_y := mt_base_y - int(mh)
		for y in range(peak_y, mt_base_y + 10):
			if y >= 0 and y < h:
				var depth: float = float(y - peak_y) / maxf(float(mt_base_y - peak_y), 1.0)
				var mt_c := _lerp_color(Color(0.06, 0.05, 0.1), Color(0.05, 0.04, 0.08), depth)
				_set_px(img, x, y, mt_c)

	# Ruins silhouettes on mountain peaks
	_draw_ruin_pillar(img, 320, 430, 6, 35)
	_draw_ruin_pillar(img, 330, 425, 5, 28)
	_draw_ruin_pillar(img, 345, 432, 7, 22)  # Broken shorter
	_draw_ruin_pillar(img, 360, 428, 5, 32)
	# Arch between two pillars
	_draw_ruin_arch(img, 320, 430 - 35, 360, 428 - 32)
	# Second ruin cluster
	_draw_ruin_pillar(img, 880, 445, 6, 30)
	_draw_ruin_pillar(img, 895, 440, 5, 25)
	_draw_ruin_pillar(img, 910, 448, 7, 18)
	# Scattered broken stone blocks
	_fill_rect(img, 340, 432, 8, 4, Color(0.06, 0.05, 0.09))
	_fill_rect(img, 352, 435, 5, 3, Color(0.06, 0.05, 0.09))
	_fill_rect(img, 898, 448, 6, 3, Color(0.06, 0.05, 0.09))

	# Ground: bottom 15%
	var ground_y := int(h * 0.83)
	for y in range(ground_y, h):
		var gt := float(y - ground_y) / float(h - ground_y)
		var gc := _lerp_color(Color(0.05, 0.04, 0.07), Color(0.03, 0.02, 0.05), gt)
		for x in range(w):
			# Add subtle terrain variation
			var noise_val := sin(float(x) * 0.05) * 0.01 + sin(float(x) * 0.13) * 0.005
			var final_c := Color(gc.r + noise_val, gc.g + noise_val, gc.b + noise_val + 0.005)
			_set_px(img, x, y, final_c)
	# Ground edge: uneven top line
	for x in range(w):
		var edge_offset := int(sin(float(x) * 0.02) * 3.0 + sin(float(x) * 0.07) * 2.0)
		var ey := ground_y + edge_offset
		for dy in range(-1, 2):
			if ey + dy >= 0 and ey + dy < h:
				_set_px(img, x, ey + dy, Color(0.05, 0.04, 0.07))

	# Ground details: small grass tufts, rocks
	for i in range(80):
		var gx := rng.randi_range(0, w - 1)
		var gy := rng.randi_range(ground_y + 2, h - 4)
		var detail_c := Color(0.07, 0.06, 0.1)
		# Small grass tuft (3px tall)
		_set_px(img, gx, gy, detail_c)
		_set_px(img, gx, gy - 1, detail_c)
		if rng.randf() < 0.4:
			_set_px(img, gx, gy - 2, detail_c)
			_set_px(img, gx + 1, gy - 1, Color(detail_c.r, detail_c.g, detail_c.b, 0.6))

	# Mist band near ground
	var mist_y := ground_y - 20
	for y in range(mist_y, mist_y + 40):
		if y < 0 or y >= h:
			continue
		var mist_t: float = 1.0 - absf(float(y - mist_y - 20) / 20.0)
		for x in range(w):
			var wave: float = sin(float(x) * 0.008 + float(y) * 0.05) * 0.3 + 0.7
			var mist_a: float = 0.06 * mist_t * mist_t * wave
			var mist_c := Color(0.3, 0.3, 0.45, mist_a)
			_blend_px(img, x, y, mist_c)

	# Distant mist layers on mountains
	for layer in range(3):
		var ly := 480 + layer * 25
		for y in range(ly, ly + 15):
			if y >= h:
				continue
			var lt: float = 1.0 - absf(float(y - ly - 7) / 7.0)
			for x in range(w):
				var lwave: float = sin(float(x) * 0.004 + float(layer) * 2.0) * 0.5 + 0.5
				var la: float = 0.03 * lt * lwave
				_blend_px(img, x, y, Color(0.2, 0.2, 0.35, la))

	# Vignette: darken edges
	for y in range(h):
		for x in range(w):
			var dx := float(x - w / 2) / float(w / 2)
			var dy := float(y - h / 2) / float(h / 2)
			var vignette: float = sqrt(dx * dx + dy * dy) * 0.4
			vignette = clampf(vignette - 0.3, 0.0, 0.5)
			if vignette > 0.001:
				_blend_px(img, x, y, Color(0, 0, 0, vignette))

	_save(img, "res://assets/sprites/ui/menu_bg.png")

func _draw_ruin_pillar(img: Image, bx: int, by: int, width: int, height: int) -> void:
	var c := Color(0.05, 0.04, 0.08)
	var highlight := Color(0.07, 0.06, 0.1)
	# Main pillar body
	_fill_rect(img, bx, by - height, width, height, c)
	# Highlight left edge
	for y in range(by - height, by):
		_set_px(img, bx, y, highlight)
	# Capital (wider top)
	_fill_rect(img, bx - 1, by - height, width + 2, 3, c)
	_fill_rect(img, bx - 2, by - height, width + 4, 1, c)
	# Broken/jagged top for some
	if rng.randf() < 0.5:
		for i in range(width + 4):
			if rng.randf() < 0.4:
				_set_px(img, bx - 2 + i, by - height - 1, c)
			if rng.randf() < 0.2:
				_set_px(img, bx - 2 + i, by - height - 2, c)
	# Base
	_fill_rect(img, bx - 1, by - 2, width + 2, 3, c)

func _draw_ruin_arch(img: Image, x1: int, y1: int, x2: int, y2: int) -> void:
	var c := Color(0.05, 0.04, 0.08)
	var mid_x: int = (x1 + x2) / 2
	var top_y: int = mini(y1, y2) - 8
	# Draw simple arch using line segments
	var steps: int = absi(x2 - x1)
	for i in range(steps):
		var t: float = float(i) / float(steps)
		var ax := x1 + int(t * float(x2 - x1))
		var arch_h := sin(t * PI) * 8.0
		var ay := int(lerpf(float(y1), float(y2), t) - arch_h)
		_set_px(img, ax, ay, c)
		_set_px(img, ax, ay + 1, c)


# ── 2. Button Normal (256x48) ───────────────────────────────────────────────

func _gen_btn_normal() -> void:
	print("Generating button normal...")
	var w := 256
	var h := 48
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

	var bg := Color(0.1, 0.1, 0.15, 1.0)
	var border := Color(0.25, 0.25, 0.3)
	var radius := 3

	# Fill background with rounded rect
	_fill_rounded_rect(img, 0, 0, w, h, bg, radius)
	# Inner highlight at top (1px lighter line)
	for x in range(radius + 1, w - radius - 1):
		_set_px(img, x, 1, Color(0.16, 0.16, 0.22))
	# Border
	_draw_rounded_border(img, w, h, border, radius)
	# Clear outside corners
	_clear_outside_rounded(img, w, h, radius)

	_save(img, "res://assets/sprites/ui/btn_normal.png")


# ── 3. Button Hover (256x48) ────────────────────────────────────────────────

func _gen_btn_hover() -> void:
	print("Generating button hover...")
	var w := 256
	var h := 48
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

	var bg := Color(0.15, 0.14, 0.22, 1.0)
	var border := Color(0.8, 0.7, 0.25)
	var radius := 3

	_fill_rounded_rect(img, 0, 0, w, h, bg, radius)
	# Gold inner glow (2px inside border)
	var glow := Color(0.8, 0.7, 0.25, 0.12)
	for x in range(radius, w - radius):
		_blend_px(img, x, 1, glow)
		_blend_px(img, x, 2, Color(glow.r, glow.g, glow.b, glow.a * 0.5))
		_blend_px(img, x, h - 2, glow)
		_blend_px(img, x, h - 3, Color(glow.r, glow.g, glow.b, glow.a * 0.5))
	for y in range(radius, h - radius):
		_blend_px(img, 1, y, glow)
		_blend_px(img, 2, y, Color(glow.r, glow.g, glow.b, glow.a * 0.5))
		_blend_px(img, w - 2, y, glow)
		_blend_px(img, w - 3, y, Color(glow.r, glow.g, glow.b, glow.a * 0.5))

	_draw_rounded_border(img, w, h, border, radius)
	_clear_outside_rounded(img, w, h, radius)

	_save(img, "res://assets/sprites/ui/btn_hover.png")


# ── 4. Button Primary (320x56) ──────────────────────────────────────────────

func _gen_btn_primary() -> void:
	print("Generating button primary...")
	var w := 320
	var h := 56
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

	var top_c := Color(0.25, 0.2, 0.08, 1.0)
	var bot_c := Color(0.18, 0.15, 0.05, 1.0)
	var border := Color(0.9, 0.75, 0.2)
	var radius := 4

	# Gradient fill
	for y in range(h):
		var t := float(y) / float(h)
		var row_c := _lerp_color(top_c, bot_c, t)
		for x in range(w):
			_set_px(img, x, y, row_c)

	# Inner highlight
	for x in range(radius + 1, w - radius - 1):
		_set_px(img, x, 1, Color(0.35, 0.3, 0.15))
		_blend_px(img, x, 2, Color(0.3, 0.25, 0.12, 0.5))

	# Ornate corner accents (small L-shapes in gold)
	var accent := Color(0.9, 0.75, 0.2, 0.6)
	# Top-left
	_fill_rect(img, 4, 4, 8, 1, accent)
	_fill_rect(img, 4, 4, 1, 8, accent)
	# Top-right
	_fill_rect(img, w - 12, 4, 8, 1, accent)
	_fill_rect(img, w - 5, 4, 1, 8, accent)
	# Bottom-left
	_fill_rect(img, 4, h - 5, 8, 1, accent)
	_fill_rect(img, 4, h - 12, 1, 8, accent)
	# Bottom-right
	_fill_rect(img, w - 12, h - 5, 8, 1, accent)
	_fill_rect(img, w - 5, h - 12, 1, 8, accent)

	# Border (2px)
	_draw_rounded_border(img, w, h, border, radius, 2)
	_clear_outside_rounded(img, w, h, radius)

	_save(img, "res://assets/sprites/ui/btn_primary.png")


# ── 5. Button Primary Hover (320x56) ────────────────────────────────────────

func _gen_btn_primary_hover() -> void:
	print("Generating button primary hover...")
	var w := 320
	var h := 56
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

	var top_c := Color(0.35, 0.28, 0.1, 1.0)
	var bot_c := Color(0.25, 0.2, 0.07, 1.0)
	var border := Color(1.0, 0.85, 0.3)
	var radius := 4

	# Gradient fill
	for y in range(h):
		var t := float(y) / float(h)
		var row_c := _lerp_color(top_c, bot_c, t)
		for x in range(w):
			_set_px(img, x, y, row_c)

	# Stronger inner glow
	var glow := Color(1.0, 0.85, 0.3, 0.15)
	for x in range(radius, w - radius):
		for dy in range(3):
			_blend_px(img, x, 1 + dy, Color(glow.r, glow.g, glow.b, glow.a * (1.0 - float(dy) * 0.3)))
			_blend_px(img, x, h - 2 - dy, Color(glow.r, glow.g, glow.b, glow.a * (1.0 - float(dy) * 0.3)))
	for y in range(radius, h - radius):
		for dx in range(3):
			_blend_px(img, 1 + dx, y, Color(glow.r, glow.g, glow.b, glow.a * (1.0 - float(dx) * 0.3)))
			_blend_px(img, w - 2 - dx, y, Color(glow.r, glow.g, glow.b, glow.a * (1.0 - float(dx) * 0.3)))

	# Inner highlight
	for x in range(radius + 1, w - radius - 1):
		_set_px(img, x, 1, Color(0.5, 0.4, 0.2))

	# Ornate corner accents
	var accent := Color(1.0, 0.85, 0.3, 0.7)
	_fill_rect(img, 4, 4, 8, 1, accent)
	_fill_rect(img, 4, 4, 1, 8, accent)
	_fill_rect(img, w - 12, 4, 8, 1, accent)
	_fill_rect(img, w - 5, 4, 1, 8, accent)
	_fill_rect(img, 4, h - 5, 8, 1, accent)
	_fill_rect(img, 4, h - 12, 1, 8, accent)
	_fill_rect(img, w - 12, h - 5, 8, 1, accent)
	_fill_rect(img, w - 5, h - 12, 1, 8, accent)

	# Border (2px)
	_draw_rounded_border(img, w, h, border, radius, 2)
	_clear_outside_rounded(img, w, h, radius)

	_save(img, "res://assets/sprites/ui/btn_primary_hover.png")


# ── 6. Panel Background (400x300) ───────────────────────────────────────────

func _gen_panel_bg() -> void:
	print("Generating panel background...")
	var w := 400
	var h := 300
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

	var bg := Color(0.06, 0.06, 0.1, 0.92)
	var border := Color(0.2, 0.2, 0.28)
	var radius := 6

	_fill_rounded_rect(img, 0, 0, w, h, bg, radius)

	# Inner shadow at edges (darker band 3px inside)
	var shadow := Color(0.0, 0.0, 0.0, 0.15)
	for x in range(radius, w - radius):
		for dy in range(3):
			_blend_px(img, x, radius + dy, Color(shadow.r, shadow.g, shadow.b, shadow.a * (1.0 - float(dy) * 0.3)))
			_blend_px(img, x, h - radius - 1 - dy, Color(shadow.r, shadow.g, shadow.b, shadow.a * (1.0 - float(dy) * 0.3)))
	for y in range(radius, h - radius):
		for dx in range(3):
			_blend_px(img, radius + dx, y, Color(shadow.r, shadow.g, shadow.b, shadow.a * (1.0 - float(dx) * 0.3)))
			_blend_px(img, w - radius - 1 - dx, y, Color(shadow.r, shadow.g, shadow.b, shadow.a * (1.0 - float(dx) * 0.3)))

	# Subtle noise texture
	for y in range(radius, h - radius):
		for x in range(radius, w - radius):
			if rng.randf() < 0.08:
				var n := rng.randf_range(-0.015, 0.015)
				var existing := img.get_pixel(x, y)
				img.set_pixel(x, y, Color(existing.r + n, existing.g + n, existing.b + n, existing.a))

	_draw_rounded_border(img, w, h, border, radius)
	_clear_outside_rounded(img, w, h, radius)

	_save(img, "res://assets/sprites/ui/panel_bg.png")


# ── 7. Panel Header (400x40) ────────────────────────────────────────────────

func _gen_panel_header() -> void:
	print("Generating panel header...")
	var w := 400
	var h := 40
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

	var bg := Color(0.1, 0.1, 0.16, 1.0)
	var border := Color(0.2, 0.2, 0.28)
	var gold_accent := Color(0.8, 0.65, 0.2)
	var radius := 6

	# Fill with rounded TOP corners only
	for y in range(h):
		for x in range(w):
			_set_px(img, x, y, bg)

	# Clear outside top corners
	for corner in range(2):  # Only top-left (0) and top-right (1)
		var cx := radius if corner == 0 else w - 1 - radius
		var cy := radius
		var sx := 0 if corner == 0 else w - radius
		for yy in range(0, radius + 1):
			for xx in range(sx, sx + radius + 1):
				var dx := float(xx - cx)
				var dy := float(yy - cy)
				if sqrt(dx * dx + dy * dy) > float(radius) + 0.5:
					_set_px(img, xx, yy, Color(0, 0, 0, 0))

	# Top border
	for x in range(radius, w - radius):
		_set_px(img, x, 0, border)
	# Side borders
	for y in range(radius, h):
		_set_px(img, 0, y, border)
		_set_px(img, w - 1, y, border)
	# Rounded top corner borders
	for corner in range(2):
		var cx := radius if corner == 0 else w - 1 - radius
		var cy := radius
		for angle_step in range(91):
			var a := deg_to_rad(float(angle_step) + 90.0) if corner == 0 else deg_to_rad(float(angle_step))
			var px := cx + int(round(cos(a) * float(radius)))
			var py := cy - int(round(sin(a) * float(radius)))
			_set_px(img, px, py, border)

	# Gold accent line at bottom
	for x in range(1, w - 1):
		_set_px(img, x, h - 1, gold_accent)
		# Fade at edges
		if x < 10:
			_set_px(img, x, h - 1, Color(gold_accent.r, gold_accent.g, gold_accent.b, float(x) / 10.0))
		elif x > w - 11:
			_set_px(img, x, h - 1, Color(gold_accent.r, gold_accent.g, gold_accent.b, float(w - 1 - x) / 10.0))

	# Subtle inner highlight
	for x in range(radius + 1, w - radius - 1):
		_set_px(img, x, 1, Color(0.14, 0.14, 0.22))

	_save(img, "res://assets/sprites/ui/panel_header.png")


# ── 8. Shop Background (1280x720) ───────────────────────────────────────────

func _gen_shop_bg() -> void:
	print("Generating shop background...")
	var w := 1280
	var h := 720
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)

	# Base: dark stone interior
	var wall_top := Color(0.06, 0.05, 0.04)
	var wall_bot := Color(0.04, 0.03, 0.025)
	for y in range(h):
		var t := float(y) / float(h)
		var c := _lerp_color(wall_top, wall_bot, t)
		for x in range(w):
			img.set_pixel(x, y, c)

	# Stone wall texture: horizontal brick lines
	for row in range(0, h - 100, 24):
		var offset := 0 if (row / 24) % 2 == 0 else 40
		# Horizontal mortar line
		for x in range(w):
			var mortar := Color(0.03, 0.025, 0.02)
			_set_px(img, x, row, mortar)
		# Vertical mortar lines
		for col in range(offset, w, 80):
			for y in range(row, min(row + 24, h)):
				_set_px(img, col, y, Color(0.03, 0.025, 0.02))

	# Stone variation (subtle noise per brick)
	for row in range(0, h - 100, 24):
		var offset := 0 if (row / 24) % 2 == 0 else 40
		for col in range(offset, w, 80):
			var brick_tint := rng.randf_range(-0.01, 0.01)
			for yy in range(row + 1, min(row + 23, h)):
				for xx in range(col + 1, min(col + 79, w)):
					var existing := img.get_pixel(xx, yy)
					img.set_pixel(xx, yy, Color(
						clampf(existing.r + brick_tint, 0.0, 1.0),
						clampf(existing.g + brick_tint * 0.8, 0.0, 1.0),
						clampf(existing.b + brick_tint * 0.6, 0.0, 1.0),
						1.0
					))

	# Wooden counter at bottom
	var counter_y := 560
	var counter_c1 := Color(0.14, 0.08, 0.04)
	var counter_c2 := Color(0.1, 0.06, 0.03)
	_fill_rect(img, 200, counter_y, 880, 8, Color(0.18, 0.1, 0.05))  # Counter top (lighter)
	for y in range(counter_y + 8, h):
		var t := float(y - counter_y - 8) / float(h - counter_y - 8)
		var cc := _lerp_color(counter_c1, counter_c2, t)
		for x in range(200, 1080):
			img.set_pixel(x, y, cc)
	# Counter wood grain lines
	for y in range(counter_y + 12, h, 6):
		for x in range(200, 1080):
			_blend_px(img, x, y, Color(0.08, 0.04, 0.02, 0.3))
	# Counter edge highlight
	for x in range(200, 1080):
		_set_px(img, x, counter_y, Color(0.22, 0.14, 0.07))
	# Counter legs
	_fill_rect(img, 220, counter_y + 8, 12, h - counter_y - 8, Color(0.1, 0.06, 0.03))
	_fill_rect(img, 1056, counter_y + 8, 12, h - counter_y - 8, Color(0.1, 0.06, 0.03))

	# Shelves on back wall (left and right)
	for shelf_set in range(2):
		var base_x := 80 if shelf_set == 0 else 900
		var shelf_w := 280
		for shelf_i in range(3):
			var sy := 120 + shelf_i * 140
			# Shelf board
			_fill_rect(img, base_x, sy, shelf_w, 6, Color(0.12, 0.07, 0.04))
			_fill_rect(img, base_x, sy, shelf_w, 1, Color(0.16, 0.1, 0.06))  # Top highlight
			# Brackets
			_fill_rect(img, base_x + 20, sy + 6, 4, 12, Color(0.08, 0.06, 0.04))
			_fill_rect(img, base_x + shelf_w - 24, sy + 6, 4, 12, Color(0.08, 0.06, 0.04))
			# Silhouette items on shelf
			_draw_shelf_items(img, base_x + 10, sy, shelf_w - 20, shelf_i + shelf_set * 3)

	# Torchlight glow — left side
	_draw_torch_glow(img, 60, 250, 200, Color(0.4, 0.2, 0.05))
	# Torch on wall (left)
	_fill_rect(img, 56, 260, 8, 20, Color(0.1, 0.06, 0.03))  # Handle
	_fill_rect(img, 54, 255, 12, 6, Color(0.12, 0.08, 0.04))  # Cup
	# Flame
	_fill_rect(img, 57, 248, 6, 8, Color(0.9, 0.5, 0.1))
	_fill_rect(img, 58, 245, 4, 4, Color(1.0, 0.8, 0.2))
	_fill_rect(img, 59, 243, 2, 3, Color(1.0, 0.95, 0.5))

	# Torchlight glow — right side
	_draw_torch_glow(img, 1220, 250, 200, Color(0.4, 0.2, 0.05))
	# Torch on wall (right)
	_fill_rect(img, 1216, 260, 8, 20, Color(0.1, 0.06, 0.03))
	_fill_rect(img, 1214, 255, 12, 6, Color(0.12, 0.08, 0.04))
	_fill_rect(img, 1217, 248, 6, 8, Color(0.9, 0.5, 0.1))
	_fill_rect(img, 1218, 245, 4, 4, Color(1.0, 0.8, 0.2))
	_fill_rect(img, 1219, 243, 2, 3, Color(1.0, 0.95, 0.5))

	# Warm ambient light from torches — large soft overlays
	for y in range(h):
		for x in range(w):
			# Left torch warmth
			var dl := sqrt(float((x - 60) * (x - 60) + (y - 250) * (y - 250)))
			if dl < 350.0:
				var fade := 1.0 - dl / 350.0
				_blend_px(img, x, y, Color(0.3, 0.15, 0.02, 0.08 * fade * fade))
			# Right torch warmth
			var dr := sqrt(float((x - 1220) * (x - 1220) + (y - 250) * (y - 250)))
			if dr < 350.0:
				var fade := 1.0 - dr / 350.0
				_blend_px(img, x, y, Color(0.3, 0.15, 0.02, 0.08 * fade * fade))

	# Floor area (below counter)
	for y in range(counter_y + 8, h):
		for x in range(0, 200):
			_set_px(img, x, y, Color(0.04, 0.03, 0.025))
		for x in range(1080, w):
			_set_px(img, x, y, Color(0.04, 0.03, 0.025))

	# Vignette
	for y in range(h):
		for x in range(w):
			var dx := float(x - w / 2) / float(w / 2)
			var dy := float(y - h / 2) / float(h / 2)
			var vignette: float = sqrt(dx * dx + dy * dy) * 0.5
			vignette = clampf(vignette - 0.2, 0.0, 0.6)
			if vignette > 0.001:
				_blend_px(img, x, y, Color(0, 0, 0, vignette))

	_save(img, "res://assets/sprites/ui/shop_bg.png")

func _draw_torch_glow(img: Image, cx: int, cy: int, radius: int, color: Color) -> void:
	for yy in range(cy - radius, cy + radius + 1):
		for xx in range(cx - radius, cx + radius + 1):
			if xx < 0 or xx >= img.get_width() or yy < 0 or yy >= img.get_height():
				continue
			var dist := sqrt(float((xx - cx) * (xx - cx) + (yy - cy) * (yy - cy)))
			if dist < float(radius):
				var fade := 1.0 - dist / float(radius)
				_blend_px(img, xx, yy, Color(color.r, color.g, color.b, 0.12 * fade * fade))

func _draw_shelf_items(img: Image, base_x: int, shelf_y: int, shelf_w: int, seed_offset: int) -> void:
	# Draw 3-5 silhouette objects on the shelf
	var item_x := base_x + 10
	var item_count := 3 + (seed_offset % 3)
	for i in range(item_count):
		var shape := (seed_offset * 7 + i * 13) % 5
		var ic := Color(0.07, 0.05, 0.04)
		match shape:
			0:  # Potion bottle
				_fill_rect(img, item_x, shelf_y - 14, 6, 10, ic)
				_fill_rect(img, item_x + 1, shelf_y - 18, 4, 5, ic)
				_fill_rect(img, item_x + 2, shelf_y - 20, 2, 3, ic)
			1:  # Book (lying)
				_fill_rect(img, item_x, shelf_y - 6, 12, 5, ic)
				_fill_rect(img, item_x, shelf_y - 7, 12, 1, Color(0.09, 0.06, 0.04))
			2:  # Tall vase
				_fill_rect(img, item_x + 1, shelf_y - 18, 8, 14, ic)
				_fill_rect(img, item_x + 2, shelf_y - 20, 6, 3, ic)
				_fill_rect(img, item_x, shelf_y - 5, 10, 4, ic)
			3:  # Small box
				_fill_rect(img, item_x, shelf_y - 10, 10, 9, ic)
				_fill_rect(img, item_x, shelf_y - 10, 10, 1, Color(0.09, 0.06, 0.04))
			4:  # Skull
				_fill_rect(img, item_x + 1, shelf_y - 10, 8, 7, ic)
				_fill_rect(img, item_x + 2, shelf_y - 12, 6, 3, ic)
				_fill_rect(img, item_x + 3, shelf_y - 4, 4, 3, ic)
		item_x += shelf_w / item_count


# ── 9. Divider (256x2) ──────────────────────────────────────────────────────

func _gen_divider() -> void:
	print("Generating divider...")
	var w := 256
	var h := 2
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

	var gold := Color(0.8, 0.65, 0.2)
	var mid := w / 2
	for x in range(w):
		var dist: float = absf(float(x - mid)) / float(mid)
		var alpha: float = 1.0 - dist * dist  # Quadratic falloff
		var c := Color(gold.r, gold.g, gold.b, alpha)
		_set_px(img, x, 0, c)
		# Second row slightly dimmer
		_set_px(img, x, 1, Color(gold.r * 0.7, gold.g * 0.7, gold.b * 0.7, alpha * 0.6))

	_save(img, "res://assets/sprites/ui/divider.png")


# ── 10. Crystal Icon (16x16) ────────────────────────────────────────────────

func _gen_crystal_icon() -> void:
	print("Generating crystal icon...")
	var w := 16
	var h := 16
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

	# Crystal shape: hexagonal gem pointing up
	# Define crystal as pixel rows (centered in 16x16)
	var cyan := Color(0.2, 0.9, 0.85)
	var cyan_light := Color(0.5, 1.0, 0.95)
	var cyan_dark := Color(0.1, 0.5, 0.5)
	var cyan_mid := Color(0.15, 0.7, 0.65)
	var outline := Color(0.05, 0.3, 0.3)

	# Crystal outline shape (pixel art)
	var crystal_outline := [
		#   x positions for each row (top to bottom)
		[7, 8],            # row 1: tip
		[6, 9],            # row 2
		[5, 10],           # row 3
		[4, 11],           # row 4
		[4, 11],           # row 5
		[4, 11],           # row 6
		[4, 11],           # row 7
		[4, 11],           # row 8
		[5, 10],           # row 9
		[6, 9],            # row 10
		[7, 8],            # row 11: bottom tip
	]

	var start_y := 2
	# Draw outline
	for i in range(crystal_outline.size()):
		var row: Array = crystal_outline[i]
		var y := start_y + i
		var x_left: int = row[0]
		var x_right: int = row[1]
		_set_px(img, x_left, y, outline)
		_set_px(img, x_right, y, outline)
		# Top and bottom edges
		if i == 0 or i == crystal_outline.size() - 1:
			for x in range(x_left, x_right + 1):
				_set_px(img, x, y, outline)

	# Fill interior
	for i in range(1, crystal_outline.size() - 1):
		var row: Array = crystal_outline[i]
		var y := start_y + i
		var x_left: int = row[0] + 1
		var x_right: int = row[1] - 1
		for x in range(x_left, x_right + 1):
			# Gradient: lighter on left (highlight), darker on right
			var t: float = float(x - x_left) / maxf(float(x_right - x_left), 1.0)
			var yt: float = float(i) / float(crystal_outline.size())
			var c: Color
			if t < 0.35:
				c = _lerp_color(cyan_light, cyan, t / 0.35)
			elif t < 0.7:
				c = _lerp_color(cyan, cyan_mid, (t - 0.35) / 0.35)
			else:
				c = _lerp_color(cyan_mid, cyan_dark, (t - 0.7) / 0.3)
			# Vertical darkening toward bottom
			c = _lerp_color(c, cyan_dark, yt * 0.3)
			_set_px(img, x, y, c)

	# Central highlight facet line
	for i in range(2, crystal_outline.size() - 2):
		var y := start_y + i
		_set_px(img, 7, y, Color(cyan_light.r, cyan_light.g, cyan_light.b, 0.7))

	# Sparkle at top
	_set_px(img, 7, start_y - 1, Color(1.0, 1.0, 1.0, 0.5))
	_set_px(img, 8, start_y, Color(1.0, 1.0, 1.0, 0.6))

	_save(img, "res://assets/sprites/ui/crystal_icon.png")


# ── Rounded rect fill helper ────────────────────────────────────────────────

func _fill_rounded_rect(img: Image, rx: int, ry: int, rw: int, rh: int, c: Color, radius: int) -> void:
	# Fill the main body
	for y in range(ry, ry + rh):
		for x in range(rx, rx + rw):
			_set_px(img, x, y, c)
	# Clear corners
	_clear_outside_rounded(img, rw, rh, radius)
