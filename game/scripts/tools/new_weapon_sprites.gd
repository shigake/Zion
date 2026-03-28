extends SceneTree

## Generates 16x16 pixel art sprites for 4 new weapons.
## Run: godot --headless --script res://scripts/tools/new_weapon_sprites.gd

const S := 16  # Sprite size

func _init() -> void:
	_generate_all()
	quit()

func _generate_all() -> void:
	DirAccess.make_dir_recursive_absolute("res://assets/sprites/weapons")

	_gen_boomerang()
	_gen_tornado()
	_gen_chain_whip()
	_gen_blood_orb()

	print("All 4 new weapon sprites generated!")

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

func _outline(img: Image, color: Color) -> void:
	var out = Image.create(S, S, false, Image.FORMAT_RGBA8)
	for x in range(S):
		for y in range(S):
			if img.get_pixel(x, y).a > 0:
				continue
			for off in [Vector2i(-1,0), Vector2i(1,0), Vector2i(0,-1), Vector2i(0,1)]:
				var nx = x + off.x
				var ny = y + off.y
				if nx >= 0 and nx < S and ny >= 0 and ny < S:
					if img.get_pixel(nx, ny).a > 0:
						out.set_pixel(x, y, color)
						break
	for x in range(S):
		for y in range(S):
			if out.get_pixel(x, y).a > 0:
				img.set_pixel(x, y, out.get_pixel(x, y))

func _save(img: Image, path: String) -> void:
	img.save_png(path)
	print("Saved: ", path)

# Helper: draw a circle (filled)
func _circle(img: Image, cx: int, cy: int, r: int, color: Color) -> void:
	for x in range(maxi(cx - r, 0), mini(cx + r + 1, S)):
		for y in range(maxi(cy - r, 0), mini(cy + r + 1, S)):
			if (x - cx) * (x - cx) + (y - cy) * (y - cy) <= r * r:
				img.set_pixel(x, y, color)

# Helper: draw a ring (circle outline only)
func _ring(img: Image, cx: int, cy: int, r_outer: int, r_inner: int, color: Color) -> void:
	for x in range(maxi(cx - r_outer, 0), mini(cx + r_outer + 1, S)):
		for y in range(maxi(cy - r_outer, 0), mini(cy + r_outer + 1, S)):
			var dist_sq = (x - cx) * (x - cx) + (y - cy) * (y - cy)
			if dist_sq <= r_outer * r_outer and dist_sq >= r_inner * r_inner:
				img.set_pixel(x, y, color)

# ==================== WEAPON SPRITES ====================

func _gen_boomerang() -> void:
	var img = _img()
	var wood_dark = Color(0.45, 0.28, 0.12)
	var wood_mid = Color(0.6, 0.38, 0.15)
	var wood_light = Color(0.75, 0.52, 0.22)
	var highlight = Color(0.85, 0.65, 0.3)

	# Boomerang is a curved V-shape pointing right
	# Top arm: going from center-left upward to right
	# Elbow at about (5, 4)
	# Top arm pixels
	_px(img, 5, 4, wood_dark)
	_px(img, 6, 3, wood_mid)
	_px(img, 7, 3, wood_mid)
	_px(img, 8, 2, wood_mid)
	_px(img, 9, 2, wood_light)
	_px(img, 10, 1, wood_light)
	_px(img, 11, 1, highlight)
	_px(img, 12, 1, wood_mid)
	# Top arm thickness (second row)
	_px(img, 5, 5, wood_mid)
	_px(img, 6, 4, wood_light)
	_px(img, 7, 4, wood_light)
	_px(img, 8, 3, wood_light)
	_px(img, 9, 3, highlight)
	_px(img, 10, 2, highlight)
	_px(img, 11, 2, wood_light)
	_px(img, 12, 2, wood_mid)

	# Elbow/bend area (thicker)
	_px(img, 4, 5, wood_dark)
	_px(img, 4, 6, wood_dark)
	_px(img, 5, 6, wood_mid)
	_px(img, 5, 7, wood_mid)
	_px(img, 4, 7, wood_dark)

	# Bottom arm: going from center-left downward to right
	_px(img, 6, 7, wood_mid)
	_px(img, 6, 8, wood_mid)
	_px(img, 7, 8, wood_light)
	_px(img, 7, 9, wood_light)
	_px(img, 8, 9, wood_light)
	_px(img, 8, 10, wood_mid)
	_px(img, 9, 10, highlight)
	_px(img, 9, 11, wood_light)
	_px(img, 10, 11, wood_mid)
	_px(img, 10, 12, wood_mid)
	_px(img, 11, 12, wood_dark)
	_px(img, 11, 13, wood_dark)
	# Bottom arm thickness
	_px(img, 7, 7, wood_light)
	_px(img, 8, 8, highlight)
	_px(img, 9, 9, highlight)
	_px(img, 10, 10, wood_light)
	_px(img, 11, 11, wood_mid)

	# Decorative stripes on arms
	_px(img, 8, 2, Color(0.35, 0.2, 0.08))
	_px(img, 8, 3, Color(0.35, 0.2, 0.08))
	_px(img, 8, 9, Color(0.35, 0.2, 0.08))
	_px(img, 8, 10, Color(0.35, 0.2, 0.08))

	_outline(img, Color(0.2, 0.12, 0.05))
	_save(img, "res://assets/sprites/weapons/boomerang.png")


func _gen_tornado() -> void:
	var img = _img()
	var cyan_dark = Color(0.15, 0.4, 0.55)
	var cyan_mid = Color(0.3, 0.6, 0.8)
	var cyan_light = Color(0.5, 0.8, 0.95)
	var white = Color(0.85, 0.95, 1.0)

	# Tornado: wide at top, narrow at bottom, swirling
	# Top row (widest part)
	_fill(img, 2, 1, 12, 1, cyan_mid)
	_fill(img, 3, 1, 10, 1, cyan_light)
	_px(img, 7, 1, white)
	_px(img, 8, 1, white)

	# Row 2
	_fill(img, 3, 2, 10, 1, cyan_mid)
	_fill(img, 4, 2, 8, 1, cyan_light)
	_px(img, 5, 2, white)
	_px(img, 10, 2, white)

	# Row 3
	_fill(img, 3, 3, 10, 1, cyan_dark)
	_fill(img, 4, 3, 8, 1, cyan_mid)
	_px(img, 8, 3, cyan_light)
	_px(img, 9, 3, cyan_light)

	# Row 4
	_fill(img, 4, 4, 9, 1, cyan_mid)
	_fill(img, 5, 4, 6, 1, cyan_light)
	_px(img, 6, 4, white)

	# Row 5
	_fill(img, 4, 5, 8, 1, cyan_dark)
	_fill(img, 5, 5, 6, 1, cyan_mid)
	_px(img, 10, 5, cyan_light)

	# Row 6
	_fill(img, 5, 6, 7, 1, cyan_mid)
	_fill(img, 6, 6, 4, 1, cyan_light)
	_px(img, 7, 6, white)

	# Row 7
	_fill(img, 5, 7, 6, 1, cyan_dark)
	_fill(img, 6, 7, 4, 1, cyan_mid)

	# Row 8
	_fill(img, 5, 8, 6, 1, cyan_mid)
	_fill(img, 6, 8, 3, 1, cyan_light)
	_px(img, 9, 8, cyan_light)

	# Row 9
	_fill(img, 6, 9, 4, 1, cyan_dark)
	_fill(img, 7, 9, 2, 1, cyan_mid)

	# Row 10
	_fill(img, 6, 10, 4, 1, cyan_mid)
	_px(img, 7, 10, cyan_light)
	_px(img, 8, 10, cyan_light)

	# Row 11 (narrowing)
	_fill(img, 7, 11, 3, 1, cyan_mid)
	_px(img, 8, 11, cyan_light)

	# Row 12
	_fill(img, 7, 12, 2, 1, cyan_dark)
	_px(img, 8, 12, cyan_mid)

	# Row 13 (narrow funnel)
	_fill(img, 7, 13, 2, 1, cyan_mid)

	# Row 14 (tip)
	_px(img, 8, 14, cyan_dark)

	# Swirl highlights - diagonal white streaks for motion
	_px(img, 4, 2, white)
	_px(img, 5, 3, white)
	_px(img, 6, 5, white)
	_px(img, 7, 7, white)
	_px(img, 11, 4, white)
	_px(img, 10, 6, white)
	_px(img, 9, 9, white)

	_outline(img, Color(0.08, 0.2, 0.35))
	_save(img, "res://assets/sprites/weapons/tornado.png")


func _gen_chain_whip() -> void:
	var img = _img()
	var chain_dark = Color(0.55, 0.5, 0.15)
	var chain_mid = Color(0.75, 0.68, 0.2)
	var chain_light = Color(0.9, 0.85, 0.35)
	var electric_blue = Color(0.3, 0.6, 1.0)
	var electric_white = Color(0.7, 0.85, 1.0)
	var handle = Color(0.35, 0.2, 0.1)

	# Handle at bottom-left
	_fill(img, 1, 12, 2, 3, handle)
	_px(img, 1, 11, Color(0.5, 0.3, 0.12))  # Pommel

	# Chain links going diagonal from handle to upper-right
	# Each link is a small 2x2 block with alternating brightness
	var links = [
		Vector2i(3, 11), Vector2i(4, 10), Vector2i(5, 9),
		Vector2i(6, 8), Vector2i(7, 7), Vector2i(8, 6),
		Vector2i(9, 5), Vector2i(10, 4), Vector2i(11, 3),
		Vector2i(12, 2)
	]
	for idx in range(links.size()):
		var lk = links[idx]
		var col = chain_mid if idx % 2 == 0 else chain_light
		var col2 = chain_dark if idx % 2 == 0 else chain_mid
		_px(img, lk.x, lk.y, col)
		_px(img, lk.x + 1, lk.y, col2)
		# Chain link gap (darker between)
		if idx % 3 == 1:
			_px(img, lk.x, lk.y, chain_dark)

	# Electric sparks along the whip
	_px(img, 4, 9, electric_blue)
	_px(img, 5, 10, electric_blue)
	_px(img, 6, 7, electric_blue)
	_px(img, 7, 8, electric_white)
	_px(img, 8, 5, electric_blue)
	_px(img, 9, 6, electric_white)
	_px(img, 10, 3, electric_blue)
	_px(img, 11, 4, electric_white)
	_px(img, 12, 1, electric_blue)
	_px(img, 13, 2, electric_white)

	# Tip spark cluster (upper-right)
	_px(img, 13, 1, electric_white)
	_px(img, 14, 1, electric_blue)
	_px(img, 13, 0, electric_blue)
	_px(img, 12, 0, electric_white)
	_px(img, 14, 2, electric_blue)

	# Smaller spark branches
	_px(img, 3, 10, electric_blue)
	_px(img, 7, 6, electric_blue)
	_px(img, 11, 2, electric_blue)

	_outline(img, Color(0.15, 0.12, 0.05))
	_save(img, "res://assets/sprites/weapons/chain_whip.png")


func _gen_blood_orb() -> void:
	var img = _img()
	var dark_red = Color(0.35, 0.05, 0.08)
	var mid_red = Color(0.55, 0.08, 0.12)
	var bright_red = Color(0.75, 0.12, 0.15)
	var purple = Color(0.4, 0.08, 0.3)
	var dark_purple = Color(0.25, 0.05, 0.2)
	var highlight = Color(0.9, 0.25, 0.3)
	var core_glow = Color(0.85, 0.15, 0.2)

	# Main orb body (filled circle, radius ~5 centered at 7,7)
	_circle(img, 7, 7, 5, dark_red)
	_circle(img, 7, 7, 4, mid_red)
	_circle(img, 7, 7, 3, bright_red)
	_circle(img, 7, 7, 2, core_glow)

	# Inner highlight (upper-left for 3D shading)
	_px(img, 5, 5, highlight)
	_px(img, 6, 5, highlight)
	_px(img, 5, 6, Color(0.95, 0.35, 0.4))  # Brightest specular

	# Purple aura around the edges
	_ring(img, 7, 7, 6, 5, purple)
	# Fill gaps in aura with darker purple
	_px(img, 2, 6, dark_purple)
	_px(img, 2, 7, dark_purple)
	_px(img, 2, 8, dark_purple)
	_px(img, 12, 6, dark_purple)
	_px(img, 12, 7, dark_purple)
	_px(img, 12, 8, dark_purple)
	_px(img, 6, 2, dark_purple)
	_px(img, 7, 2, dark_purple)
	_px(img, 8, 2, dark_purple)
	_px(img, 6, 12, dark_purple)
	_px(img, 7, 12, dark_purple)
	_px(img, 8, 12, dark_purple)

	# Blood drips hanging from bottom
	_px(img, 6, 13, mid_red)
	_px(img, 6, 14, dark_red)
	_px(img, 8, 13, mid_red)
	_px(img, 8, 14, bright_red)
	_px(img, 8, 15, dark_red)
	_px(img, 7, 13, mid_red)

	# Small drip on left
	_px(img, 4, 12, mid_red)
	_px(img, 4, 13, dark_red)

	# Pulsing energy veins inside the orb
	_px(img, 6, 7, purple)
	_px(img, 8, 8, purple)
	_px(img, 7, 6, dark_purple)
	_px(img, 9, 7, dark_purple)

	_outline(img, Color(0.12, 0.02, 0.08))
	_save(img, "res://assets/sprites/weapons/blood_orb.png")
