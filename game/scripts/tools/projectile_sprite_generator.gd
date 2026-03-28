extends SceneTree

## Generates 16x16 pixel art sprites for all projectiles.
## Run: godot --headless --path game --script res://scripts/tools/projectile_sprite_generator.gd

const S := 16  # Sprite size

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

	print("All projectile sprites generated!")

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

# ==================== PROJECTILES (13) ====================

func _gen_bullet() -> void:
	var img = _img()
	var gold = Color(0.85, 0.7, 0.2)
	var gold_dark = Color(0.65, 0.5, 0.1)
	var tip = Color(1.0, 0.95, 0.6)

	# Elongated bullet pointing right — body
	_fill(img, 4, 6, 7, 4, gold)
	# Darker bottom half for depth
	_fill(img, 4, 8, 7, 2, gold_dark)
	# Rounded nose (right side)
	_fill(img, 11, 7, 1, 2, gold)
	_px(img, 12, 7, gold)
	_px(img, 12, 8, gold)
	# Bright tip highlight
	_px(img, 12, 7, tip)
	_px(img, 11, 7, tip)
	_px(img, 11, 6, tip)
	# Flat back (left side)
	_fill(img, 3, 7, 1, 2, gold_dark)
	# Shell casing line
	_fill(img, 5, 6, 1, 4, Color(0.75, 0.6, 0.15))

	_outline(img, Color(0.3, 0.22, 0.05))
	_save(img, "res://assets/sprites/projectiles/bullet.png")

func _gen_staff_projectile() -> void:
	var img = _img()
	var blue = Color(0.2, 0.4, 0.95)
	var blue_light = Color(0.5, 0.7, 1.0)
	var core = Color(0.8, 0.9, 1.0)
	var sparkle = Color(1.0, 1.0, 1.0)

	# Magic orb — circular shape
	_fill(img, 5, 5, 6, 6, blue)
	_fill(img, 6, 4, 4, 8, blue)
	_fill(img, 4, 6, 8, 4, blue)
	# Lighter inner ring
	_fill(img, 6, 6, 4, 4, blue_light)
	# Bright core
	_fill(img, 7, 7, 2, 2, core)
	# Sparkle pixels
	_px(img, 6, 5, sparkle)
	_px(img, 9, 5, sparkle)
	_px(img, 5, 8, sparkle)
	_px(img, 10, 7, sparkle)

	_outline(img, Color(0.08, 0.12, 0.35))
	_save(img, "res://assets/sprites/projectiles/staff_projectile.png")

func _gen_ice_crystal() -> void:
	var img = _img()
	var ice = Color(0.5, 0.85, 0.95)
	var ice_dark = Color(0.3, 0.6, 0.8)
	var white = Color(0.9, 0.95, 1.0)

	# Angular shard pointing right — main body (diamond-ish)
	# Top edge
	_px(img, 8, 2, ice)
	_fill(img, 7, 3, 3, 1, ice)
	_fill(img, 6, 4, 5, 1, ice)
	_fill(img, 5, 5, 7, 1, ice)
	_fill(img, 4, 6, 9, 1, ice)
	_fill(img, 3, 7, 10, 2, ice)
	_fill(img, 4, 9, 9, 1, ice)
	_fill(img, 5, 10, 7, 1, ice)
	_fill(img, 6, 11, 5, 1, ice)
	_fill(img, 7, 12, 3, 1, ice)
	_px(img, 8, 13, ice)
	# Pointy right tip
	_px(img, 13, 7, ice)
	_px(img, 13, 8, ice)
	# Dark facet on bottom
	_fill(img, 5, 9, 5, 2, ice_dark)
	_fill(img, 6, 11, 3, 1, ice_dark)
	# Highlight facet on top
	_fill(img, 7, 4, 2, 2, white)
	_px(img, 8, 3, white)
	_px(img, 6, 6, white)

	_outline(img, Color(0.1, 0.25, 0.4))
	_save(img, "res://assets/sprites/projectiles/ice_crystal.png")

func _gen_arrow() -> void:
	var img = _img()
	var shaft = Color(0.55, 0.4, 0.2)
	var shaft_dark = Color(0.4, 0.28, 0.12)
	var head = Color(0.6, 0.62, 0.65)
	var head_hi = Color(0.8, 0.82, 0.88)
	var fletch = Color(0.8, 0.15, 0.15)

	# Shaft (horizontal, pointing right)
	_fill(img, 3, 7, 10, 2, shaft)
	_fill(img, 3, 8, 10, 1, shaft_dark)
	# Arrowhead (right side, triangular)
	_fill(img, 12, 6, 1, 4, head)
	_fill(img, 13, 7, 1, 2, head)
	_px(img, 14, 7, head)
	_px(img, 14, 8, head)
	_px(img, 12, 6, head_hi)
	_px(img, 13, 7, head_hi)
	# Fletching (left side)
	_px(img, 2, 5, fletch)
	_px(img, 3, 6, fletch)
	_px(img, 2, 6, fletch)
	_px(img, 2, 10, fletch)
	_px(img, 3, 9, fletch)
	_px(img, 2, 9, fletch)
	_px(img, 1, 5, fletch)
	_px(img, 1, 10, fletch)

	_outline(img, Color(0.15, 0.1, 0.05))
	_save(img, "res://assets/sprites/projectiles/arrow.png")

func _gen_rocket() -> void:
	var img = _img()
	var body = Color(0.25, 0.55, 0.2)
	var body_dark = Color(0.18, 0.4, 0.14)
	var nose = Color(0.85, 0.15, 0.1)
	var nose_hi = Color(1.0, 0.35, 0.2)
	var fire = Color(1.0, 0.6, 0.0)
	var fire_core = Color(1.0, 0.9, 0.3)

	# Cylindrical body (pointing right)
	_fill(img, 4, 5, 7, 6, body)
	_fill(img, 4, 7, 7, 2, body_dark)
	# Nose cone (right)
	_fill(img, 11, 6, 1, 4, nose)
	_fill(img, 12, 7, 1, 2, nose)
	_px(img, 13, 7, nose)
	_px(img, 13, 8, nose)
	_px(img, 11, 6, nose_hi)
	_px(img, 12, 7, nose_hi)
	# Fins at back (left)
	_fill(img, 3, 3, 2, 2, body)
	_fill(img, 3, 11, 2, 2, body)
	# Exhaust fire trail (left)
	_px(img, 2, 7, fire_core)
	_px(img, 2, 8, fire_core)
	_px(img, 1, 7, fire)
	_px(img, 1, 8, fire)
	_px(img, 0, 8, fire)
	_px(img, 3, 6, fire)
	_px(img, 3, 9, fire)

	_outline(img, Color(0.08, 0.18, 0.06))
	_save(img, "res://assets/sprites/projectiles/rocket.png")

func _gen_shuriken_projectile() -> void:
	var img = _img()
	var silver = Color(0.72, 0.74, 0.78)
	var silver_hi = Color(0.9, 0.92, 0.96)
	var silver_dk = Color(0.5, 0.52, 0.56)

	# 4-point star centered at (7,7)
	# Center
	_fill(img, 6, 6, 4, 4, silver)
	# Top point
	_fill(img, 7, 1, 2, 5, silver)
	_px(img, 7, 1, silver_hi)
	_px(img, 8, 2, silver_dk)
	# Bottom point
	_fill(img, 7, 10, 2, 5, silver)
	_px(img, 8, 14, silver_hi)
	_px(img, 7, 13, silver_dk)
	# Left point
	_fill(img, 1, 7, 5, 2, silver)
	_px(img, 1, 7, silver_hi)
	_px(img, 2, 8, silver_dk)
	# Right point
	_fill(img, 10, 7, 5, 2, silver)
	_px(img, 14, 8, silver_hi)
	_px(img, 13, 7, silver_dk)
	# Center highlight
	_fill(img, 7, 7, 2, 2, silver_hi)
	# Center dot
	_px(img, 7, 7, silver_dk)
	_px(img, 8, 8, silver_dk)

	_outline(img, Color(0.2, 0.2, 0.25))
	_save(img, "res://assets/sprites/projectiles/shuriken_projectile.png")

func _gen_axe_thrown() -> void:
	var img = _img()
	var blade = Color(0.6, 0.62, 0.65)
	var blade_hi = Color(0.8, 0.82, 0.88)
	var handle = Color(0.5, 0.35, 0.2)
	var handle_dk = Color(0.38, 0.25, 0.12)

	# Handle (diagonal, spinning feel)
	for i in range(7):
		_px(img, 4 + i, 10 - i, handle)
		_px(img, 5 + i, 10 - i, handle_dk)
	# Axe head (upper-right area, double-sided)
	_fill(img, 9, 1, 3, 2, blade)
	_fill(img, 8, 3, 4, 2, blade)
	_fill(img, 9, 5, 3, 1, blade)
	_fill(img, 12, 2, 2, 3, blade)
	# Highlight on edge
	_fill(img, 9, 1, 2, 1, blade_hi)
	_px(img, 13, 2, blade_hi)
	_px(img, 13, 3, blade_hi)
	# Lower axe blade (for double-head look when spinning)
	_fill(img, 2, 10, 3, 2, blade)
	_fill(img, 1, 11, 2, 2, blade)
	_fill(img, 3, 12, 2, 1, blade)
	_px(img, 1, 11, blade_hi)

	_outline(img, Color(0.18, 0.15, 0.1))
	_save(img, "res://assets/sprites/projectiles/axe_thrown.png")

func _gen_poison_cloud() -> void:
	var img = _img()
	var green = Color(0.25, 0.7, 0.15)
	var green_light = Color(0.4, 0.85, 0.3)
	var green_dark = Color(0.15, 0.5, 0.08)
	var bubble = Color(0.55, 0.95, 0.4, 0.8)

	# Blobby cloud shape
	_fill(img, 4, 6, 8, 5, green)
	_fill(img, 5, 4, 6, 8, green)
	_fill(img, 3, 7, 10, 3, green)
	_fill(img, 6, 3, 4, 1, green)
	_fill(img, 6, 13, 4, 1, green)
	# Darker puffs
	_fill(img, 4, 8, 3, 3, green_dark)
	_fill(img, 9, 5, 3, 3, green_dark)
	# Lighter highlights
	_fill(img, 6, 5, 3, 2, green_light)
	_px(img, 10, 7, green_light)
	# Toxic bubbles
	_px(img, 5, 5, bubble)
	_px(img, 11, 9, bubble)
	_px(img, 7, 11, bubble)

	_outline(img, Color(0.08, 0.25, 0.03))
	_save(img, "res://assets/sprites/projectiles/poison_cloud.png")

func _gen_fireball() -> void:
	var img = _img()
	var orange = Color(0.95, 0.45, 0.05)
	var red = Color(0.85, 0.15, 0.05)
	var yellow = Color(1.0, 0.85, 0.2)
	var core = Color(1.0, 1.0, 0.6)

	# Outer fire shape (circular-ish with trailing left)
	_fill(img, 5, 4, 7, 8, orange)
	_fill(img, 4, 5, 9, 6, orange)
	_fill(img, 6, 3, 5, 1, orange)
	_fill(img, 6, 12, 5, 1, orange)
	# Red outer edges
	_fill(img, 4, 5, 2, 6, red)
	_fill(img, 5, 4, 2, 1, red)
	_fill(img, 5, 11, 2, 2, red)
	# Trailing fire wisps (left)
	_px(img, 3, 6, red)
	_px(img, 2, 7, red)
	_px(img, 3, 9, red)
	_px(img, 2, 8, Color(0.9, 0.3, 0.0))
	# Yellow inner
	_fill(img, 7, 5, 4, 6, yellow)
	_fill(img, 6, 6, 6, 4, yellow)
	# Bright core
	_fill(img, 8, 7, 2, 2, core)
	_px(img, 9, 6, core)
	_px(img, 7, 7, core)

	_outline(img, Color(0.35, 0.05, 0.0))
	_save(img, "res://assets/sprites/projectiles/fireball.png")

func _gen_plasma_bolt() -> void:
	var img = _img()
	var purple = Color(0.6, 0.15, 0.85)
	var cyan = Color(0.2, 0.8, 0.95)
	var core = Color(0.8, 0.6, 1.0)
	var glow = Color(0.4, 0.9, 1.0, 0.7)

	# Outer energy shape
	_fill(img, 5, 5, 6, 6, purple)
	_fill(img, 6, 4, 4, 8, purple)
	_fill(img, 4, 6, 8, 4, purple)
	# Cyan ring
	_fill(img, 6, 5, 4, 1, cyan)
	_fill(img, 6, 10, 4, 1, cyan)
	_fill(img, 5, 6, 1, 4, cyan)
	_fill(img, 10, 6, 1, 4, cyan)
	# Core glow
	_fill(img, 7, 7, 2, 2, core)
	_fill(img, 6, 6, 4, 4, Color(0.7, 0.4, 0.95))
	_fill(img, 7, 7, 2, 2, core)
	# Glow aura pixels
	_px(img, 4, 4, glow)
	_px(img, 11, 4, glow)
	_px(img, 4, 11, glow)
	_px(img, 11, 11, glow)
	_px(img, 3, 7, glow)
	_px(img, 12, 8, glow)

	_outline(img, Color(0.2, 0.05, 0.35))
	_save(img, "res://assets/sprites/projectiles/plasma_bolt.png")

func _gen_lightning_bolt() -> void:
	var img = _img()
	var yellow = Color(1.0, 0.9, 0.15)
	var yellow_hi = Color(1.0, 1.0, 0.7)
	var yellow_dk = Color(0.85, 0.7, 0.0)

	# Zigzag lightning bolt shape (top to bottom)
	# Top segment going down-right
	_fill(img, 5, 1, 3, 2, yellow)
	_fill(img, 6, 3, 3, 1, yellow)
	_fill(img, 7, 4, 3, 1, yellow)
	# Middle bar going left
	_fill(img, 4, 5, 7, 2, yellow)
	# Bottom segment going down-right
	_fill(img, 5, 7, 3, 1, yellow)
	_fill(img, 6, 8, 3, 1, yellow)
	_fill(img, 7, 9, 3, 1, yellow)
	_fill(img, 8, 10, 2, 2, yellow)
	# Bottom point
	_px(img, 9, 12, yellow)
	_px(img, 8, 11, yellow)
	# Highlights along edge
	_px(img, 5, 1, yellow_hi)
	_px(img, 4, 5, yellow_hi)
	_px(img, 5, 7, yellow_hi)
	_px(img, 9, 12, yellow_hi)
	# Darker edge
	_px(img, 7, 2, yellow_dk)
	_px(img, 10, 5, yellow_dk)
	_px(img, 9, 9, yellow_dk)
	_px(img, 9, 11, yellow_dk)

	_outline(img, Color(0.4, 0.35, 0.0))
	_save(img, "res://assets/sprites/projectiles/lightning_bolt.png")

func _gen_magic_orb() -> void:
	var img = _img()
	var purple = Color(0.55, 0.1, 0.75)
	var purple_light = Color(0.7, 0.35, 0.9)
	var purple_dark = Color(0.35, 0.05, 0.5)
	var swirl = Color(0.85, 0.55, 1.0)
	var core = Color(0.95, 0.8, 1.0)

	# Sphere shape
	_fill(img, 5, 4, 6, 8, purple)
	_fill(img, 4, 5, 8, 6, purple)
	_fill(img, 6, 3, 4, 1, purple)
	_fill(img, 6, 12, 4, 1, purple)
	_fill(img, 3, 6, 1, 4, purple)
	_fill(img, 12, 6, 1, 4, purple)
	# Dark hemisphere (bottom)
	_fill(img, 5, 9, 6, 3, purple_dark)
	_fill(img, 6, 11, 4, 1, purple_dark)
	# Light hemisphere (top)
	_fill(img, 6, 4, 4, 3, purple_light)
	_fill(img, 5, 5, 2, 2, purple_light)
	# Swirl lines
	_px(img, 6, 6, swirl)
	_px(img, 7, 5, swirl)
	_px(img, 9, 6, swirl)
	_px(img, 10, 8, swirl)
	_px(img, 8, 9, swirl)
	_px(img, 6, 10, swirl)
	_px(img, 5, 8, swirl)
	# Core highlight
	_px(img, 7, 6, core)
	_px(img, 8, 7, core)

	_outline(img, Color(0.18, 0.02, 0.3))
	_save(img, "res://assets/sprites/projectiles/magic_orb.png")

func _gen_crossbow_bolt() -> void:
	var img = _img()
	var shaft = Color(0.55, 0.55, 0.6)
	var shaft_dk = Color(0.4, 0.4, 0.45)
	var head = Color(0.7, 0.72, 0.75)
	var head_hi = Color(0.88, 0.9, 0.95)
	var fin = Color(0.45, 0.35, 0.25)

	# Short bolt shaft (horizontal, pointing right)
	_fill(img, 4, 7, 8, 2, shaft)
	_fill(img, 4, 8, 8, 1, shaft_dk)
	# Metal head (right)
	_fill(img, 12, 6, 1, 4, head)
	_px(img, 13, 7, head)
	_px(img, 13, 8, head)
	_px(img, 14, 7, head_hi)
	_px(img, 12, 6, head_hi)
	# Fins at back (left)
	_fill(img, 3, 5, 2, 2, fin)
	_fill(img, 3, 9, 2, 2, fin)
	_px(img, 2, 5, fin)
	_px(img, 2, 10, fin)
	# Center groove on shaft
	_fill(img, 6, 7, 4, 1, Color(0.5, 0.5, 0.55))

	_outline(img, Color(0.15, 0.15, 0.18))
	_save(img, "res://assets/sprites/projectiles/crossbow_bolt.png")
