extends SceneTree

## Generates 24x24 pixel art sprites for all projectiles with glow effects.
## Run: godot --headless --path game --script res://scripts/tools/projectile_sprite_gen_v2.gd

const S := 24  # Sprite size (up from 16)

func _init() -> void:
	_generate_all()
	quit()

func _generate_all() -> void:
	DirAccess.make_dir_recursive_absolute("res://assets/sprites/projectiles")

	_gen_bullet()
	_gen_staff_projectile()
	_gen_ice_crystal()
	_gen_arrow()
	_gen_rocket()
	_gen_shuriken_projectile()
	_gen_axe_thrown()
	_gen_poison_cloud()
	_gen_fireball()
	_gen_plasma_bolt()
	_gen_lightning_bolt()
	_gen_magic_orb()
	_gen_crossbow_bolt()

	print("All 13 projectile sprites regenerated at 24x24 with glow!")

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

func _get_px(img: Image, x: int, y: int) -> Color:
	if x >= 0 and x < S and y >= 0 and y < S:
		return img.get_pixel(x, y)
	return Color(0, 0, 0, 0)

## Draw a filled circle
func _circle(img: Image, cx: int, cy: int, r: int, color: Color) -> void:
	for x in range(maxi(cx - r, 0), mini(cx + r + 1, S)):
		for y in range(maxi(cy - r, 0), mini(cy + r + 1, S)):
			var dx := float(x - cx)
			var dy := float(y - cy)
			if dx * dx + dy * dy <= float(r * r):
				img.set_pixel(x, y, color)

## Draw a circle ring (outline only)
func _circle_ring(img: Image, cx: int, cy: int, r: int, color: Color) -> void:
	for x in range(maxi(cx - r - 1, 0), mini(cx + r + 2, S)):
		for y in range(maxi(cy - r - 1, 0), mini(cy + r + 2, S)):
			var dx := float(x - cx)
			var dy := float(y - cy)
			var dist := dx * dx + dy * dy
			var r_sq := float(r * r)
			if dist <= r_sq and dist >= float((r - 1) * (r - 1)):
				img.set_pixel(x, y, color)

## Add a glow halo around all opaque pixels
func _add_glow(img: Image, color: Color, radius: int = 2) -> void:
	var glow_img = Image.create(S, S, false, Image.FORMAT_RGBA8)
	for x in range(S):
		for y in range(S):
			if img.get_pixel(x, y).a > 0.1:
				for gx in range(maxi(x - radius, 0), mini(x + radius + 1, S)):
					for gy in range(maxi(y - radius, 0), mini(y + radius + 1, S)):
						var dx := float(gx - x)
						var dy := float(gy - y)
						var dist := sqrt(dx * dx + dy * dy)
						if dist <= float(radius) and img.get_pixel(gx, gy).a < 0.1:
							var alpha_val := (1.0 - dist / float(radius)) * color.a
							var existing := glow_img.get_pixel(gx, gy)
							if alpha_val > existing.a:
								glow_img.set_pixel(gx, gy, Color(color.r, color.g, color.b, alpha_val))
	# Apply glow under existing pixels
	for x in range(S):
		for y in range(S):
			if glow_img.get_pixel(x, y).a > 0.05 and img.get_pixel(x, y).a < 0.1:
				img.set_pixel(x, y, glow_img.get_pixel(x, y))

## 1px dark outline for readability
func _outline(img: Image, color: Color) -> void:
	var out = Image.create(S, S, false, Image.FORMAT_RGBA8)
	for x in range(S):
		for y in range(S):
			if img.get_pixel(x, y).a > 0.5:
				continue
			for off in [Vector2i(-1,0), Vector2i(1,0), Vector2i(0,-1), Vector2i(0,1)]:
				var nx = x + off.x
				var ny = y + off.y
				if nx >= 0 and nx < S and ny >= 0 and ny < S:
					if img.get_pixel(nx, ny).a > 0.5:
						out.set_pixel(x, y, color)
						break
	for x in range(S):
		for y in range(S):
			if out.get_pixel(x, y).a > 0:
				img.set_pixel(x, y, out.get_pixel(x, y))

## Draw motion streaks behind a projectile (left side = trailing)
func _motion_streaks(img: Image, y_center: int, color: Color, count: int = 3) -> void:
	var positions = [
		[1, y_center - 2],
		[0, y_center],
		[2, y_center + 2],
	]
	for i in range(mini(count, positions.size())):
		var px_x: int = positions[i][0]
		var px_y: int = positions[i][1]
		for sx in range(3):
			var alpha_val := (1.0 - float(sx) / 3.0) * 0.5
			_px(img, px_x - sx, px_y, Color(color.r, color.g, color.b, alpha_val))

func _save(img: Image, path: String) -> void:
	img.save_png(path)
	print("Saved: ", path)

# ==================== PROJECTILES (13) ====================

func _gen_bullet() -> void:
	var img = _img()
	var gold = Color(0.9, 0.75, 0.25)
	var gold_bright = Color(1.0, 0.88, 0.4)
	var gold_dark = Color(0.65, 0.5, 0.12)
	var gold_shadow = Color(0.5, 0.35, 0.08)
	var tip_white = Color(1.0, 1.0, 0.9)
	var tip_bright = Color(1.0, 0.95, 0.7)
	var casing = Color(0.75, 0.6, 0.18)

	# Main body (pointing right)
	_fill(img, 5, 9, 11, 6, gold)
	# Top highlight band
	_fill(img, 5, 9, 11, 2, gold_bright)
	# Bottom shadow band
	_fill(img, 5, 13, 11, 2, gold_shadow)
	# Middle gradient
	_fill(img, 5, 11, 11, 2, gold)
	# Dark bottom edge
	_fill(img, 5, 14, 11, 1, gold_dark)

	# Rounded nose (right side, 3px rounding)
	_fill(img, 16, 10, 2, 4, gold)
	_fill(img, 18, 10, 1, 4, gold_bright)
	_fill(img, 19, 11, 1, 2, gold_bright)
	_px(img, 20, 11, gold_bright)
	_px(img, 20, 12, gold)

	# Bright white tip with glint
	_px(img, 21, 11, tip_white)
	_px(img, 21, 12, tip_white)
	_px(img, 20, 11, tip_white)
	_px(img, 20, 12, tip_bright)
	_px(img, 19, 10, tip_white)
	_px(img, 19, 11, tip_bright)

	# Flat back with casing line
	_fill(img, 4, 10, 1, 4, gold_dark)
	_fill(img, 5, 9, 1, 6, casing)
	_fill(img, 6, 9, 1, 6, Color(0.8, 0.65, 0.2))

	# Metallic gradient line across middle
	_fill(img, 7, 11, 9, 1, Color(1.0, 0.92, 0.55))

	# Shell casing groove
	_fill(img, 8, 9, 1, 6, Color(0.7, 0.55, 0.15))

	# Motion streaks
	_px(img, 3, 10, Color(1.0, 0.9, 0.4, 0.3))
	_px(img, 2, 10, Color(1.0, 0.9, 0.4, 0.15))
	_px(img, 3, 13, Color(1.0, 0.9, 0.4, 0.3))
	_px(img, 2, 13, Color(1.0, 0.9, 0.4, 0.15))
	_px(img, 1, 12, Color(1.0, 0.9, 0.4, 0.1))

	_outline(img, Color(0.3, 0.22, 0.05))
	_add_glow(img, Color(1.0, 0.85, 0.3, 0.35), 2)
	_save(img, "res://assets/sprites/projectiles/bullet.png")

func _gen_staff_projectile() -> void:
	var img = _img()
	var blue_deep = Color(0.1, 0.25, 0.85)
	var blue = Color(0.25, 0.45, 0.95)
	var blue_light = Color(0.5, 0.7, 1.0)
	var core = Color(0.85, 0.92, 1.0)
	var white = Color(1.0, 1.0, 1.0)
	var sparkle = Color(1.0, 1.0, 1.0, 0.9)

	# Outer sphere
	_circle(img, 11, 11, 8, blue_deep)
	# Mid sphere
	_circle(img, 11, 11, 6, blue)
	# Inner bright sphere
	_circle(img, 11, 11, 4, blue_light)
	# White core
	_circle(img, 11, 11, 2, core)
	# Center white pixel
	_px(img, 11, 11, white)
	_px(img, 11, 10, white)

	# Highlight arc (top-left)
	_px(img, 8, 7, core)
	_px(img, 9, 6, core)
	_px(img, 10, 6, blue_light)
	_px(img, 7, 8, blue_light)

	# Sparkle dots around orb
	_px(img, 5, 5, sparkle)
	_px(img, 17, 5, sparkle)
	_px(img, 4, 12, sparkle)
	_px(img, 18, 10, sparkle)
	_px(img, 14, 4, sparkle)
	_px(img, 8, 17, sparkle)
	_px(img, 16, 16, sparkle)

	# Cross sparkle at center
	_px(img, 11, 9, Color(1.0, 1.0, 1.0, 0.7))
	_px(img, 11, 13, Color(1.0, 1.0, 1.0, 0.7))
	_px(img, 9, 11, Color(1.0, 1.0, 1.0, 0.7))
	_px(img, 13, 11, Color(1.0, 1.0, 1.0, 0.7))

	_outline(img, Color(0.05, 0.1, 0.4))
	_add_glow(img, Color(0.3, 0.5, 1.0, 0.4), 3)
	_save(img, "res://assets/sprites/projectiles/staff_projectile.png")

func _gen_ice_crystal() -> void:
	var img = _img()
	var cyan = Color(0.4, 0.8, 0.95)
	var cyan_deep = Color(0.2, 0.55, 0.85)
	var white = Color(0.92, 0.96, 1.0)
	var ice_hi = Color(1.0, 1.0, 1.0)
	var frost = Color(0.7, 0.9, 1.0, 0.5)

	# Main shard body (diamond pointing right)
	# Build the angular crystal from center-left to right tip
	var cx := 10
	var cy := 11
	# Central thick part
	_fill(img, cx - 3, cy - 3, 6, 6, cyan)
	# Wider middle
	_fill(img, cx - 4, cy - 2, 8, 4, cyan)
	_fill(img, cx - 2, cy - 4, 4, 8, cyan)
	# Right point (sharp tip)
	_fill(img, cx + 4, cy - 1, 3, 2, cyan)
	_fill(img, cx + 6, cy - 1, 2, 2, cyan_deep)
	_px(img, cx + 8, cy, cyan_deep)
	_px(img, cx + 7, cy, white)
	# Left back
	_fill(img, cx - 5, cy - 1, 2, 2, cyan_deep)
	_px(img, cx - 6, cy, cyan_deep)

	# Top facet (lighter)
	_fill(img, cx - 2, cy - 4, 4, 3, white)
	_fill(img, cx - 1, cy - 5, 2, 1, white)
	# Bottom facet (darker)
	_fill(img, cx - 2, cy + 2, 4, 2, cyan_deep)
	_fill(img, cx - 1, cy + 4, 2, 1, cyan_deep)

	# Crystal highlight streaks
	_px(img, cx - 1, cy - 3, ice_hi)
	_px(img, cx, cy - 4, ice_hi)
	_px(img, cx + 1, cy - 2, ice_hi)
	_px(img, cx + 3, cy - 1, ice_hi)
	_px(img, cx + 5, cy, ice_hi)

	# Inner refraction line
	_fill(img, cx - 2, cy, 7, 1, Color(0.85, 0.95, 1.0))

	# Frost particles around crystal
	_px(img, 3, 5, frost)
	_px(img, 19, 7, frost)
	_px(img, 5, 16, frost)
	_px(img, 17, 15, frost)
	_px(img, 2, 10, frost)
	_px(img, 21, 12, frost)

	_outline(img, Color(0.1, 0.25, 0.45))
	_add_glow(img, Color(0.5, 0.85, 1.0, 0.35), 2)
	_save(img, "res://assets/sprites/projectiles/ice_crystal.png")

func _gen_arrow() -> void:
	var img = _img()
	var shaft = Color(0.6, 0.42, 0.22)
	var shaft_hi = Color(0.72, 0.55, 0.32)
	var shaft_dk = Color(0.42, 0.28, 0.12)
	var head = Color(0.62, 0.64, 0.68)
	var head_hi = Color(0.88, 0.9, 0.95)
	var head_dk = Color(0.45, 0.47, 0.5)
	var fletch_red = Color(0.85, 0.15, 0.15)
	var fletch_dk = Color(0.65, 0.1, 0.1)
	var motion = Color(0.6, 0.42, 0.22, 0.3)

	# Wood shaft (thick 3px, pointing right)
	_fill(img, 4, 10, 14, 3, shaft)
	# Top highlight on shaft
	_fill(img, 4, 10, 14, 1, shaft_hi)
	# Bottom shadow on shaft
	_fill(img, 4, 12, 14, 1, shaft_dk)
	# Wood grain lines
	_px(img, 8, 11, shaft_dk)
	_px(img, 12, 11, shaft_dk)
	_px(img, 16, 11, shaft_dk)

	# Iron arrowhead (right, triangular)
	_fill(img, 18, 9, 1, 5, head)
	_fill(img, 19, 10, 1, 3, head)
	_fill(img, 20, 10, 1, 3, head_hi)
	_fill(img, 21, 11, 1, 1, head_hi)
	_px(img, 22, 11, head_hi)  # Sharp tip with glint
	# Dark edge on arrowhead bottom
	_px(img, 18, 13, head_dk)
	_px(img, 19, 12, head_dk)
	_px(img, 20, 12, head_dk)
	# Tip glint
	_px(img, 22, 11, Color(1.0, 1.0, 1.0))

	# Red feathers (left side, V-shape)
	_fill(img, 2, 7, 3, 3, fletch_red)
	_fill(img, 2, 13, 3, 3, fletch_dk)
	_px(img, 1, 7, fletch_red)
	_px(img, 1, 8, fletch_red)
	_px(img, 1, 15, fletch_dk)
	_px(img, 1, 14, fletch_dk)
	# Feather detail lines
	_px(img, 3, 8, fletch_dk)
	_px(img, 3, 14, Color(0.55, 0.08, 0.08))
	# Nock at tail
	_px(img, 3, 10, shaft_dk)
	_px(img, 3, 12, shaft_dk)

	# Motion lines
	_px(img, 0, 9, motion)
	_px(img, 0, 11, motion)
	_px(img, 0, 14, motion)

	_outline(img, Color(0.18, 0.12, 0.05))
	_save(img, "res://assets/sprites/projectiles/arrow.png")

func _gen_rocket() -> void:
	var img = _img()
	var body = Color(0.28, 0.52, 0.22)
	var body_hi = Color(0.38, 0.65, 0.3)
	var body_dk = Color(0.18, 0.38, 0.14)
	var nose = Color(0.88, 0.18, 0.1)
	var nose_hi = Color(1.0, 0.4, 0.22)
	var fire = Color(1.0, 0.55, 0.0)
	var fire_core = Color(1.0, 0.92, 0.4)
	var fire_red = Color(0.95, 0.25, 0.0)
	var band = Color(0.7, 0.7, 0.72)

	# Main body cylinder
	_fill(img, 5, 7, 11, 9, body)
	# Top highlight
	_fill(img, 5, 7, 11, 3, body_hi)
	# Bottom shadow
	_fill(img, 5, 13, 11, 3, body_dk)
	# Metal band near nose
	_fill(img, 14, 7, 1, 9, band)

	# Red nose cone (right side)
	_fill(img, 16, 8, 2, 7, nose)
	_fill(img, 18, 9, 1, 5, nose)
	_fill(img, 19, 10, 1, 3, nose)
	_px(img, 20, 11, nose)
	# Nose highlight
	_px(img, 16, 8, nose_hi)
	_px(img, 17, 8, nose_hi)
	_px(img, 18, 9, nose_hi)
	_px(img, 19, 10, nose_hi)
	_px(img, 20, 11, nose_hi)

	# Fins at back (left, top and bottom)
	_fill(img, 3, 3, 3, 4, body)
	_fill(img, 3, 4, 2, 3, body_hi)
	_fill(img, 3, 16, 3, 4, body)
	_fill(img, 3, 17, 2, 3, body_dk)
	# Center fin
	_fill(img, 4, 10, 1, 3, body_dk)

	# Exhaust flame (left side, multi-layered)
	# Core (bright yellow-white)
	_fill(img, 3, 10, 2, 3, fire_core)
	# Mid flame (orange)
	_fill(img, 1, 9, 3, 5, fire)
	_fill(img, 2, 10, 2, 3, fire_core)
	# Outer flame (red)
	_px(img, 0, 9, fire_red)
	_px(img, 0, 10, fire)
	_px(img, 0, 11, fire_core)
	_px(img, 0, 12, fire)
	_px(img, 0, 13, fire_red)
	# Flame tips
	_px(img, 1, 8, Color(1.0, 0.4, 0.0, 0.6))
	_px(img, 1, 14, Color(1.0, 0.4, 0.0, 0.6))

	_outline(img, Color(0.08, 0.2, 0.06))
	_add_glow(img, Color(1.0, 0.6, 0.1, 0.3), 2)
	_save(img, "res://assets/sprites/projectiles/rocket.png")

func _gen_shuriken_projectile() -> void:
	var img = _img()
	var silver = Color(0.75, 0.77, 0.82)
	var silver_hi = Color(0.92, 0.94, 0.98)
	var silver_dk = Color(0.5, 0.52, 0.58)
	var ice_glow = Color(0.4, 0.7, 1.0, 0.5)
	var center = Color(0.6, 0.62, 0.68)

	var cx := 11
	var cy := 11

	# Center hub
	_circle(img, cx, cy, 3, silver)
	_circle(img, cx, cy, 2, silver_hi)
	_px(img, cx, cy, silver_dk)

	# Top blade
	_fill(img, cx - 1, 1, 3, 8, silver)
	_fill(img, cx, 1, 1, 3, silver_hi)
	_fill(img, cx + 1, 3, 1, 3, silver_dk)
	_px(img, cx, 0, silver_hi)
	# Right blade
	_fill(img, 15, cy - 1, 8, 3, silver)
	_fill(img, 18, cy, 3, 1, silver_hi)
	_fill(img, 17, cy + 1, 3, 1, silver_dk)
	_px(img, 23, cy, silver_hi)
	# Bottom blade
	_fill(img, cx - 1, 15, 3, 8, silver)
	_fill(img, cx, 19, 1, 3, silver_hi)
	_fill(img, cx - 1, 17, 1, 3, silver_dk)
	_px(img, cx, 23, silver_hi)
	# Left blade
	_fill(img, 0, cy - 1, 8, 3, silver)
	_fill(img, 1, cy, 3, 1, silver_hi)
	_fill(img, 2, cy - 1, 3, 1, silver_dk)
	_px(img, 0, cy, silver_hi)

	# Ice glow edges on blade tips
	_px(img, cx - 2, 1, ice_glow)
	_px(img, cx + 2, 1, ice_glow)
	_px(img, cx - 2, 22, ice_glow)
	_px(img, cx + 2, 22, ice_glow)
	_px(img, 1, cy - 2, ice_glow)
	_px(img, 1, cy + 2, ice_glow)
	_px(img, 22, cy - 2, ice_glow)
	_px(img, 22, cy + 2, ice_glow)

	# Diagonal bevels between blades
	_px(img, cx + 3, cy - 3, silver_dk)
	_px(img, cx - 3, cy - 3, silver_dk)
	_px(img, cx + 3, cy + 3, silver_dk)
	_px(img, cx - 3, cy + 3, silver_dk)

	_outline(img, Color(0.22, 0.22, 0.28))
	_add_glow(img, Color(0.4, 0.65, 1.0, 0.3), 2)
	_save(img, "res://assets/sprites/projectiles/shuriken_projectile.png")

func _gen_axe_thrown() -> void:
	var img = _img()
	var blade = Color(0.62, 0.65, 0.7)
	var blade_hi = Color(0.85, 0.88, 0.95)
	var blade_dk = Color(0.42, 0.44, 0.48)
	var handle = Color(0.55, 0.38, 0.22)
	var handle_dk = Color(0.4, 0.26, 0.14)
	var motion_c = Color(0.6, 0.62, 0.68, 0.25)

	# Handle (diagonal from bottom-left to upper-right, thicker)
	for i in range(10):
		_px(img, 5 + i, 17 - i, handle)
		_px(img, 6 + i, 17 - i, handle_dk)
		_px(img, 5 + i, 16 - i, Color(0.62, 0.45, 0.28))  # highlight side
	# Handle wrap detail
	_px(img, 8, 14, Color(0.7, 0.5, 0.3))
	_px(img, 10, 12, Color(0.7, 0.5, 0.3))

	# Upper-right axe head (large, curved)
	_fill(img, 13, 2, 5, 3, blade)
	_fill(img, 12, 4, 6, 3, blade)
	_fill(img, 14, 1, 3, 2, blade)
	_fill(img, 15, 0, 2, 2, blade)
	_fill(img, 18, 3, 2, 3, blade)
	_fill(img, 19, 4, 2, 2, blade)
	# Blade highlight (cutting edge)
	_fill(img, 15, 0, 2, 1, blade_hi)
	_px(img, 19, 3, blade_hi)
	_px(img, 20, 4, blade_hi)
	_px(img, 20, 5, blade_hi)
	# Dark inner edge
	_fill(img, 13, 5, 3, 2, blade_dk)

	# Lower-left axe head (mirrored for spinning)
	_fill(img, 2, 18, 5, 3, blade)
	_fill(img, 3, 17, 5, 3, blade)
	_fill(img, 1, 19, 3, 2, blade)
	_fill(img, 0, 20, 2, 2, blade)
	# Blade highlight
	_px(img, 0, 20, blade_hi)
	_px(img, 0, 21, blade_hi)
	_fill(img, 1, 21, 2, 1, blade_hi)
	# Dark inner edge
	_fill(img, 5, 17, 2, 2, blade_dk)

	# Motion blur streaks
	_px(img, 10, 1, motion_c)
	_px(img, 20, 8, motion_c)
	_px(img, 1, 15, motion_c)
	_px(img, 11, 22, motion_c)

	_outline(img, Color(0.2, 0.18, 0.12))
	_save(img, "res://assets/sprites/projectiles/axe_thrown.png")

func _gen_poison_cloud() -> void:
	var img = _img()
	var green = Color(0.28, 0.7, 0.18)
	var green_light = Color(0.45, 0.88, 0.35)
	var green_dark = Color(0.15, 0.48, 0.08)
	var green_deep = Color(0.1, 0.35, 0.05)
	var bubble = Color(0.6, 0.95, 0.45, 0.8)
	var bubble_hi = Color(0.8, 1.0, 0.7, 0.9)

	# Main cloud blobs (overlapping circles for puffy look)
	_circle(img, 9, 12, 5, green)
	_circle(img, 14, 13, 4, green)
	_circle(img, 11, 8, 5, green)
	_circle(img, 16, 9, 3, green)
	_circle(img, 7, 9, 4, green)

	# Darker centers for depth
	_circle(img, 10, 11, 3, green_dark)
	_circle(img, 14, 10, 2, green_deep)

	# Lighter puff tops
	_circle(img, 9, 7, 3, green_light)
	_circle(img, 14, 8, 2, green_light)
	_circle(img, 7, 8, 2, green_light)

	# Toxic bubbles with highlights
	_circle(img, 6, 14, 1, bubble)
	_px(img, 5, 13, bubble_hi)
	_circle(img, 16, 14, 1, bubble)
	_px(img, 15, 13, bubble_hi)
	_circle(img, 12, 6, 1, bubble)
	_px(img, 11, 5, bubble_hi)
	_px(img, 18, 11, bubble)
	_px(img, 4, 11, bubble)

	# Wispy edges
	_px(img, 3, 10, Color(0.25, 0.6, 0.15, 0.4))
	_px(img, 20, 10, Color(0.25, 0.6, 0.15, 0.4))
	_px(img, 11, 3, Color(0.25, 0.6, 0.15, 0.4))
	_px(img, 12, 18, Color(0.25, 0.6, 0.15, 0.4))

	_outline(img, Color(0.06, 0.22, 0.02))
	_add_glow(img, Color(0.3, 0.8, 0.15, 0.3), 2)
	_save(img, "res://assets/sprites/projectiles/poison_cloud.png")

func _gen_fireball() -> void:
	var img = _img()
	var red = Color(0.88, 0.15, 0.05)
	var red_dark = Color(0.65, 0.08, 0.02)
	var orange = Color(0.98, 0.5, 0.05)
	var yellow = Color(1.0, 0.88, 0.25)
	var core = Color(1.0, 1.0, 0.7)
	var white = Color(1.0, 1.0, 0.95)
	var spark = Color(1.0, 0.75, 0.15, 0.7)

	# Outer fire shape (large sphere-ish)
	_circle(img, 12, 11, 8, red)
	_circle(img, 12, 11, 7, red_dark)

	# Orange mid layer
	_circle(img, 13, 11, 6, orange)

	# Yellow hot inner
	_circle(img, 13, 11, 4, yellow)

	# Bright core
	_circle(img, 13, 11, 2, core)
	_px(img, 13, 10, white)
	_px(img, 14, 11, white)

	# Flame wisps extending outward (trailing left)
	_fill(img, 2, 9, 4, 2, red)
	_fill(img, 3, 8, 3, 1, red_dark)
	_fill(img, 1, 10, 3, 2, red_dark)
	_fill(img, 3, 12, 4, 2, red)
	_px(img, 1, 11, Color(0.7, 0.1, 0.0, 0.6))
	_px(img, 0, 10, Color(0.6, 0.08, 0.0, 0.4))

	# Top flame licks
	_px(img, 10, 3, orange)
	_px(img, 11, 2, red)
	_px(img, 14, 3, orange)
	_px(img, 13, 2, red)
	# Bottom flame licks
	_px(img, 10, 19, orange)
	_px(img, 14, 19, orange)
	_px(img, 12, 20, red)

	# Trailing sparks
	_px(img, 1, 7, spark)
	_px(img, 0, 13, spark)
	_px(img, 2, 15, spark)
	_px(img, 3, 5, spark)
	_px(img, 0, 8, Color(1.0, 0.6, 0.0, 0.4))

	_outline(img, Color(0.38, 0.05, 0.0))
	_add_glow(img, Color(1.0, 0.4, 0.05, 0.35), 3)
	_save(img, "res://assets/sprites/projectiles/fireball.png")

func _gen_plasma_bolt() -> void:
	var img = _img()
	var purple = Color(0.55, 0.12, 0.85)
	var purple_deep = Color(0.35, 0.05, 0.6)
	var cyan = Color(0.2, 0.82, 0.98)
	var cyan_bright = Color(0.5, 0.95, 1.0)
	var core = Color(0.85, 0.7, 1.0)
	var white = Color(1.0, 1.0, 1.0)
	var arc = Color(0.3, 0.9, 1.0, 0.6)

	# Outer energy sphere
	_circle(img, 11, 11, 8, purple_deep)
	# Mid sphere
	_circle(img, 11, 11, 6, purple)
	# Cyan energy ring
	_circle_ring(img, 11, 11, 7, cyan)
	_circle_ring(img, 11, 11, 5, cyan_bright)
	# Inner glow
	_circle(img, 11, 11, 3, core)
	# White-hot center
	_circle(img, 11, 11, 1, white)
	_px(img, 11, 11, white)

	# Electric arcs extending outward
	# Arc 1 (upper-right)
	_px(img, 16, 5, arc)
	_px(img, 17, 4, arc)
	_px(img, 18, 5, arc)
	_px(img, 15, 6, cyan)
	# Arc 2 (lower-left)
	_px(img, 6, 16, arc)
	_px(img, 5, 17, arc)
	_px(img, 7, 17, arc)
	_px(img, 7, 15, cyan)
	# Arc 3 (upper-left)
	_px(img, 5, 6, arc)
	_px(img, 4, 5, arc)
	_px(img, 6, 7, cyan)
	# Arc 4 (lower-right)
	_px(img, 17, 16, arc)
	_px(img, 18, 17, arc)
	_px(img, 16, 15, cyan)

	# Pulsing glow dots
	_px(img, 11, 3, Color(0.5, 0.3, 0.9, 0.5))
	_px(img, 11, 19, Color(0.5, 0.3, 0.9, 0.5))
	_px(img, 3, 11, Color(0.5, 0.3, 0.9, 0.5))
	_px(img, 19, 11, Color(0.5, 0.3, 0.9, 0.5))

	_outline(img, Color(0.18, 0.04, 0.35))
	_add_glow(img, Color(0.5, 0.2, 0.9, 0.4), 3)
	_save(img, "res://assets/sprites/projectiles/plasma_bolt.png")

func _gen_lightning_bolt() -> void:
	var img = _img()
	var yellow = Color(1.0, 0.92, 0.2)
	var yellow_hi = Color(1.0, 1.0, 0.8)
	var white = Color(1.0, 1.0, 1.0)
	var yellow_dk = Color(0.85, 0.72, 0.0)
	var blue_glow = Color(0.4, 0.6, 1.0, 0.4)

	# Main zigzag bolt (top to bottom, thick)
	# Segment 1: top-right
	_fill(img, 8, 1, 4, 2, yellow)
	_fill(img, 9, 3, 4, 2, yellow)
	_fill(img, 10, 4, 4, 1, yellow)
	# Segment 2: horizontal bar going left
	_fill(img, 5, 5, 10, 3, yellow)
	# Segment 3: going down-right
	_fill(img, 7, 8, 4, 2, yellow)
	_fill(img, 8, 10, 4, 2, yellow)
	_fill(img, 9, 12, 4, 2, yellow)
	# Segment 4: bottom point
	_fill(img, 10, 14, 3, 2, yellow)
	_fill(img, 11, 16, 2, 2, yellow)
	_px(img, 12, 18, yellow)
	_px(img, 11, 17, yellow)

	# White core highlight running through center
	_px(img, 9, 1, white)
	_px(img, 10, 2, white)
	_px(img, 10, 3, white)
	_fill(img, 7, 6, 6, 1, white)
	_px(img, 8, 8, white)
	_px(img, 9, 9, white)
	_px(img, 9, 10, white)
	_px(img, 10, 11, white)
	_px(img, 10, 12, white)
	_px(img, 11, 14, white)
	_px(img, 11, 15, white)
	_px(img, 12, 17, white)

	# Yellow-hi edges for brightness
	_px(img, 8, 1, yellow_hi)
	_px(img, 5, 5, yellow_hi)
	_px(img, 14, 5, yellow_hi)
	_px(img, 7, 8, yellow_hi)
	_px(img, 12, 18, yellow_hi)

	# Dark edges for definition
	_px(img, 11, 1, yellow_dk)
	_px(img, 14, 7, yellow_dk)
	_px(img, 12, 13, yellow_dk)

	# Blue glow aura
	_px(img, 6, 2, blue_glow)
	_px(img, 13, 2, blue_glow)
	_px(img, 4, 4, blue_glow)
	_px(img, 16, 6, blue_glow)
	_px(img, 5, 9, blue_glow)
	_px(img, 13, 9, blue_glow)
	_px(img, 7, 13, blue_glow)
	_px(img, 14, 15, blue_glow)
	_px(img, 10, 19, blue_glow)

	_outline(img, Color(0.42, 0.38, 0.0))
	_add_glow(img, Color(0.8, 0.85, 1.0, 0.35), 2)
	_save(img, "res://assets/sprites/projectiles/lightning_bolt.png")

func _gen_magic_orb() -> void:
	var img = _img()
	var purple = Color(0.5, 0.1, 0.72)
	var purple_light = Color(0.68, 0.35, 0.88)
	var purple_dark = Color(0.3, 0.05, 0.45)
	var swirl = Color(0.85, 0.55, 1.0)
	var core = Color(0.95, 0.82, 1.0)
	var white = Color(1.0, 1.0, 1.0)
	var ring = Color(0.75, 0.4, 0.95, 0.6)

	# Outer sphere
	_circle(img, 11, 11, 8, purple_dark)
	_circle(img, 11, 11, 7, purple)
	# Light hemisphere (top-left)
	_circle(img, 10, 10, 5, purple_light)
	# Dark hemisphere (bottom-right)
	# (already dark from outer sphere)

	# Swirl pattern (rune-like curved lines)
	_px(img, 8, 7, swirl)
	_px(img, 9, 6, swirl)
	_px(img, 11, 6, swirl)
	_px(img, 13, 7, swirl)
	_px(img, 14, 9, swirl)
	_px(img, 14, 11, swirl)
	_px(img, 13, 13, swirl)
	_px(img, 11, 14, swirl)
	_px(img, 9, 14, swirl)
	_px(img, 7, 13, swirl)
	_px(img, 7, 11, swirl)
	_px(img, 7, 9, swirl)

	# Inner rune symbol (simple cross/star)
	_px(img, 11, 8, swirl)
	_px(img, 11, 14, swirl)
	_px(img, 8, 11, swirl)
	_px(img, 14, 11, swirl)
	_px(img, 9, 9, swirl)
	_px(img, 13, 9, swirl)
	_px(img, 9, 13, swirl)
	_px(img, 13, 13, swirl)

	# Core glow
	_circle(img, 11, 11, 2, core)
	_px(img, 11, 11, white)
	_px(img, 10, 10, white)

	# Outer magic ring (orbit line)
	_circle_ring(img, 11, 11, 9, ring)
	# Ring sparkle points
	_px(img, 11, 2, Color(1.0, 0.8, 1.0, 0.8))
	_px(img, 20, 11, Color(1.0, 0.8, 1.0, 0.8))
	_px(img, 11, 20, Color(1.0, 0.8, 1.0, 0.8))
	_px(img, 2, 11, Color(1.0, 0.8, 1.0, 0.8))

	_outline(img, Color(0.15, 0.02, 0.28))
	_add_glow(img, Color(0.6, 0.2, 0.9, 0.35), 3)
	_save(img, "res://assets/sprites/projectiles/magic_orb.png")

func _gen_crossbow_bolt() -> void:
	var img = _img()
	var shaft = Color(0.55, 0.55, 0.62)
	var shaft_hi = Color(0.68, 0.68, 0.75)
	var shaft_dk = Color(0.4, 0.4, 0.48)
	var head = Color(0.72, 0.74, 0.78)
	var head_hi = Color(0.92, 0.94, 0.98)
	var fin = Color(0.48, 0.38, 0.28)
	var fin_dk = Color(0.35, 0.25, 0.18)
	var glint = Color(1.0, 1.0, 1.0)

	# Metal shaft (thick, pointing right)
	_fill(img, 5, 10, 13, 4, shaft)
	# Top highlight
	_fill(img, 5, 10, 13, 1, shaft_hi)
	# Bottom shadow
	_fill(img, 5, 13, 13, 1, shaft_dk)
	# Center groove
	_fill(img, 7, 11, 9, 1, Color(0.5, 0.5, 0.58))
	# Groove highlight
	_fill(img, 7, 12, 9, 1, Color(0.6, 0.6, 0.68))

	# Sharp metal head (right, pointed)
	_fill(img, 18, 9, 1, 6, head)
	_fill(img, 19, 10, 1, 4, head)
	_fill(img, 20, 10, 1, 4, head_hi)
	_fill(img, 21, 11, 1, 2, head_hi)
	_px(img, 22, 11, head_hi)
	_px(img, 22, 12, head)
	# Tip glint
	_px(img, 22, 11, glint)
	_px(img, 21, 11, glint)

	# Metal fins (left side, angular)
	_fill(img, 3, 6, 3, 4, fin)
	_fill(img, 3, 14, 3, 4, fin)
	_px(img, 2, 7, fin)
	_px(img, 2, 8, fin)
	_px(img, 2, 15, fin)
	_px(img, 2, 16, fin)
	_px(img, 1, 7, fin_dk)
	_px(img, 1, 16, fin_dk)
	# Fin highlights
	_px(img, 3, 6, Color(0.55, 0.45, 0.35))
	_px(img, 3, 14, Color(0.55, 0.45, 0.35))
	# Fin dark edges
	_fill(img, 4, 9, 2, 1, fin_dk)
	_fill(img, 4, 14, 2, 1, fin_dk)

	# Nock (back cap)
	_fill(img, 4, 10, 1, 4, shaft_dk)

	# Motion lines
	_px(img, 1, 10, Color(0.5, 0.5, 0.58, 0.3))
	_px(img, 0, 12, Color(0.5, 0.5, 0.58, 0.2))
	_px(img, 1, 13, Color(0.5, 0.5, 0.58, 0.25))

	_outline(img, Color(0.18, 0.18, 0.22))
	_add_glow(img, Color(0.7, 0.72, 0.8, 0.25), 1)
	_save(img, "res://assets/sprites/projectiles/crossbow_bolt.png")
