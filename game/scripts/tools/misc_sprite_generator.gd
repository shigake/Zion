extends SceneTree

## Generates 16x16 pixel art sprites for upgrades, relics, and achievements.
## Run: godot --headless --script res://scripts/tools/misc_sprite_generator.gd

const S := 16  # Sprite size

func _init() -> void:
	_generate_all()
	quit()

func _generate_all() -> void:
	DirAccess.make_dir_recursive_absolute("res://assets/sprites/upgrades")
	DirAccess.make_dir_recursive_absolute("res://assets/sprites/relics")
	DirAccess.make_dir_recursive_absolute("res://assets/sprites/achievements")

	# Upgrades (12)
	_gen_max_hp()
	_gen_speed()
	_gen_damage()
	_gen_armor()
	_gen_xp_bonus()
	_gen_magnetism()
	_gen_cooldown_reduction()
	_gen_luck()
	_gen_revive()
	_gen_weapon_slots()
	_gen_reroll_shop()
	_gen_banish_shop()

	# Relics (7)
	_gen_hourglass()
	_gen_golden_dice()
	_gen_extra_heart()
	_gen_compass()
	_gen_scroll()
	_gen_veteran_medal()
	_gen_master_key()

	# Achievements (13)
	_gen_first_walk()
	_gen_evolved_6()
	_gen_speedrunner()
	_gen_collector()
	_gen_cow_brejo()
	_gen_nobody_deserves()
	_gen_genocide()
	_gen_sweet_revenge()
	_gen_storm()
	_gen_pacifist()
	_gen_matrix()
	_gen_one_punch()
	_gen_lucky_day()

	print("All misc sprites generated!")

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

# ==================== UPGRADES (12) ====================

func _gen_max_hp() -> void:
	var img = _img()
	var red = Color(0.85, 0.15, 0.15)
	var red_hi = Color(1.0, 0.3, 0.3)
	var white = Color(1.0, 1.0, 1.0)

	# Heart shape
	# Top bumps
	_fill(img, 2, 4, 3, 2, red)
	_fill(img, 6, 4, 1, 1, red)
	_fill(img, 7, 4, 3, 2, red)
	_fill(img, 3, 3, 2, 1, red)
	_fill(img, 8, 3, 2, 1, red)
	# Middle
	_fill(img, 1, 5, 10, 1, red)
	_fill(img, 2, 6, 8, 1, red)
	_fill(img, 2, 7, 8, 1, red)
	_fill(img, 3, 8, 6, 1, red)
	_fill(img, 4, 9, 4, 1, red)
	_fill(img, 5, 10, 2, 1, red)
	# Highlight
	_px(img, 3, 4, red_hi)
	_px(img, 4, 3, red_hi)
	# Plus sign (white)
	_fill(img, 12, 1, 2, 5, white)
	_fill(img, 11, 2, 4, 3, white)

	_outline(img, Color(0.3, 0.05, 0.05))
	_save(img, "res://assets/sprites/upgrades/max_hp.png")

func _gen_speed() -> void:
	var img = _img()
	var blue = Color(0.2, 0.5, 0.95)
	var blue_hi = Color(0.4, 0.7, 1.0)

	# Right-pointing arrow
	# Shaft
	_fill(img, 2, 7, 8, 2, blue)
	# Arrowhead
	_fill(img, 10, 5, 1, 6, blue)
	_fill(img, 11, 6, 1, 4, blue)
	_fill(img, 12, 7, 1, 2, blue)
	_px(img, 13, 7, blue)
	_px(img, 13, 8, blue)
	# Speed lines
	_fill(img, 1, 4, 3, 1, blue_hi)
	_fill(img, 0, 11, 3, 1, blue_hi)

	_outline(img, Color(0.05, 0.15, 0.35))
	_save(img, "res://assets/sprites/upgrades/speed.png")

func _gen_damage() -> void:
	var img = _img()
	var blade = Color(0.8, 0.2, 0.2)
	var blade_hi = Color(1.0, 0.4, 0.4)
	var handle = Color(0.5, 0.3, 0.15)
	var guard = Color(0.7, 0.65, 0.2)

	# Blade (vertical, going up)
	_fill(img, 7, 1, 2, 8, blade)
	_px(img, 7, 0, blade)
	_px(img, 8, 0, blade)
	# Blade highlight
	_px(img, 7, 1, blade_hi)
	_px(img, 7, 2, blade_hi)
	# Guard
	_fill(img, 5, 9, 6, 1, guard)
	# Handle
	_fill(img, 7, 10, 2, 4, handle)
	# Pommel
	_fill(img, 6, 14, 4, 1, guard)

	_outline(img, Color(0.3, 0.05, 0.05))
	_save(img, "res://assets/sprites/upgrades/damage.png")

func _gen_armor() -> void:
	var img = _img()
	var gray = Color(0.55, 0.58, 0.62)
	var gray_hi = Color(0.75, 0.78, 0.82)
	var gray_dk = Color(0.4, 0.42, 0.45)

	# Shield shape
	_fill(img, 4, 2, 8, 2, gray)
	_fill(img, 3, 4, 10, 3, gray)
	_fill(img, 4, 7, 8, 2, gray)
	_fill(img, 5, 9, 6, 2, gray)
	_fill(img, 6, 11, 4, 1, gray)
	_fill(img, 7, 12, 2, 1, gray)
	# Top edge
	_fill(img, 5, 2, 6, 1, gray_hi)
	# Center cross emblem
	_fill(img, 7, 4, 2, 6, gray_dk)
	_fill(img, 5, 5, 6, 2, gray_dk)

	_outline(img, Color(0.2, 0.2, 0.22))
	_save(img, "res://assets/sprites/upgrades/armor.png")

func _gen_xp_bonus() -> void:
	var img = _img()
	var blue = Color(0.3, 0.5, 1.0)
	var blue_hi = Color(0.5, 0.7, 1.0)

	# 5-pointed star
	# Center
	_fill(img, 6, 5, 4, 5, blue)
	_fill(img, 5, 6, 6, 3, blue)
	# Top spike
	_fill(img, 7, 1, 2, 4, blue)
	_px(img, 7, 0, blue)
	# Bottom-left spike
	_px(img, 3, 11, blue)
	_fill(img, 4, 10, 2, 2, blue)
	# Bottom-right spike
	_px(img, 12, 11, blue)
	_fill(img, 10, 10, 2, 2, blue)
	# Left spike
	_fill(img, 2, 6, 3, 2, blue)
	_px(img, 1, 6, blue)
	# Right spike
	_fill(img, 11, 6, 3, 2, blue)
	_px(img, 14, 7, blue)
	# Highlight
	_px(img, 7, 2, blue_hi)
	_px(img, 6, 6, blue_hi)

	_outline(img, Color(0.1, 0.15, 0.35))
	_save(img, "res://assets/sprites/upgrades/xp_bonus.png")

func _gen_magnetism() -> void:
	var img = _img()
	var purple = Color(0.6, 0.2, 0.75)
	var purple_hi = Color(0.8, 0.4, 0.95)
	var red = Color(0.85, 0.2, 0.2)
	var blue = Color(0.2, 0.4, 0.85)

	# U-shaped magnet
	# Left arm
	_fill(img, 3, 2, 3, 8, purple)
	# Right arm
	_fill(img, 10, 2, 3, 8, purple)
	# Bottom curve
	_fill(img, 5, 9, 6, 2, purple)
	_fill(img, 6, 10, 4, 2, purple)
	_fill(img, 6, 11, 4, 1, purple)
	# Tips: red and blue
	_fill(img, 3, 2, 3, 2, red)
	_fill(img, 10, 2, 3, 2, blue)
	# Highlight
	_px(img, 4, 4, purple_hi)
	_px(img, 11, 4, purple_hi)

	_outline(img, Color(0.2, 0.08, 0.28))
	_save(img, "res://assets/sprites/upgrades/magnetism.png")

func _gen_cooldown_reduction() -> void:
	var img = _img()
	var blue = Color(0.3, 0.55, 0.9)
	var blue_hi = Color(0.5, 0.75, 1.0)
	var face = Color(0.9, 0.92, 0.95)
	var hand = Color(0.15, 0.15, 0.2)
	var arrow_col = Color(0.2, 0.8, 0.3)

	# Clock circle (outer)
	_fill(img, 4, 1, 7, 1, blue)
	_fill(img, 3, 2, 9, 1, blue)
	_fill(img, 2, 3, 11, 1, blue)
	_fill(img, 1, 4, 13, 7, blue)
	_fill(img, 2, 11, 11, 1, blue)
	_fill(img, 3, 12, 9, 1, blue)
	_fill(img, 4, 13, 7, 1, blue)
	# Clock face (inner)
	_fill(img, 4, 3, 7, 1, face)
	_fill(img, 3, 4, 9, 6, face)
	_fill(img, 4, 10, 7, 1, face)
	# Clock hands
	_fill(img, 7, 4, 1, 4, hand)  # minute (up)
	_fill(img, 7, 7, 3, 1, hand)  # hour (right)
	# Small arrow (counter-clockwise) top-right
	_px(img, 11, 2, arrow_col)
	_px(img, 12, 2, arrow_col)
	_px(img, 13, 2, arrow_col)
	_px(img, 13, 1, arrow_col)
	_px(img, 13, 3, arrow_col)

	_outline(img, Color(0.1, 0.18, 0.35))
	_save(img, "res://assets/sprites/upgrades/cooldown_reduction.png")

func _gen_luck() -> void:
	var img = _img()
	var green = Color(0.2, 0.7, 0.25)
	var green_hi = Color(0.35, 0.85, 0.4)
	var stem = Color(0.15, 0.5, 0.18)

	# Four-leaf clover (4 circles around center)
	# Top leaf
	_fill(img, 6, 1, 4, 3, green)
	_px(img, 7, 0, green)
	_px(img, 8, 0, green)
	# Bottom leaf
	_fill(img, 6, 8, 4, 3, green)
	_px(img, 7, 11, green)
	_px(img, 8, 11, green)
	# Left leaf
	_fill(img, 2, 4, 3, 4, green)
	_px(img, 1, 5, green)
	_px(img, 1, 6, green)
	# Right leaf
	_fill(img, 10, 4, 3, 4, green)
	_px(img, 13, 5, green)
	_px(img, 13, 6, green)
	# Center
	_fill(img, 5, 4, 6, 4, green)
	# Highlights
	_px(img, 6, 2, green_hi)
	_px(img, 3, 5, green_hi)
	_px(img, 11, 5, green_hi)
	_px(img, 6, 9, green_hi)
	# Stem
	_fill(img, 8, 12, 1, 3, stem)
	_px(img, 9, 14, stem)

	_outline(img, Color(0.05, 0.25, 0.08))
	_save(img, "res://assets/sprites/upgrades/luck.png")

func _gen_revive() -> void:
	var img = _img()
	var yellow = Color(0.95, 0.8, 0.2)
	var yellow_hi = Color(1.0, 0.95, 0.5)
	var orange = Color(0.9, 0.55, 0.1)

	# Phoenix / angel wings
	# Left wing
	_fill(img, 1, 4, 2, 5, yellow)
	_fill(img, 3, 3, 2, 6, yellow)
	_px(img, 2, 3, yellow)
	_px(img, 1, 3, yellow)
	_px(img, 0, 4, yellow)
	# Right wing
	_fill(img, 13, 4, 2, 5, yellow)
	_fill(img, 11, 3, 2, 6, yellow)
	_px(img, 13, 3, yellow)
	_px(img, 14, 3, yellow)
	_px(img, 15, 4, yellow)
	# Body center
	_fill(img, 6, 3, 4, 7, yellow)
	_fill(img, 5, 4, 6, 5, yellow)
	# Head halo
	_fill(img, 6, 1, 4, 1, yellow_hi)
	_fill(img, 7, 0, 2, 1, yellow_hi)
	# Head
	_fill(img, 7, 2, 2, 2, orange)
	# Lower body
	_fill(img, 7, 10, 2, 3, yellow)
	_px(img, 6, 11, yellow)
	_px(img, 9, 11, yellow)
	# Wing highlights
	_px(img, 2, 5, yellow_hi)
	_px(img, 13, 5, yellow_hi)

	_outline(img, Color(0.35, 0.3, 0.05))
	_save(img, "res://assets/sprites/upgrades/revive.png")

func _gen_weapon_slots() -> void:
	var img = _img()
	var gray = Color(0.5, 0.52, 0.55)
	var gray_hi = Color(0.7, 0.72, 0.75)
	var plus_col = Color(0.85, 0.85, 0.9)

	# Box outline
	_fill(img, 2, 2, 12, 1, gray)
	_fill(img, 2, 13, 12, 1, gray)
	_fill(img, 2, 2, 1, 12, gray)
	_fill(img, 13, 2, 1, 12, gray)
	# Inner highlight
	_fill(img, 3, 3, 10, 1, gray_hi)
	_fill(img, 3, 3, 1, 10, gray_hi)
	# Plus sign inside
	_fill(img, 7, 5, 2, 6, plus_col)
	_fill(img, 5, 7, 6, 2, plus_col)

	_outline(img, Color(0.2, 0.2, 0.22))
	_save(img, "res://assets/sprites/upgrades/weapon_slots.png")

func _gen_reroll_shop() -> void:
	var img = _img()
	var blue = Color(0.3, 0.6, 0.95)
	var blue_hi = Color(0.5, 0.8, 1.0)

	# Circular arrows (refresh icon)
	# Top arc (going right)
	_fill(img, 5, 2, 6, 2, blue)
	_fill(img, 10, 4, 2, 2, blue)
	# Arrow tip top-right
	_px(img, 12, 3, blue)
	_px(img, 12, 4, blue)
	_px(img, 11, 2, blue)
	_px(img, 11, 1, blue)
	# Bottom arc (going left)
	_fill(img, 5, 12, 6, 2, blue)
	_fill(img, 4, 10, 2, 2, blue)
	# Arrow tip bottom-left
	_px(img, 3, 11, blue)
	_px(img, 3, 12, blue)
	_px(img, 4, 13, blue)
	_px(img, 4, 14, blue)
	# Left side
	_fill(img, 3, 5, 2, 3, blue)
	# Right side
	_fill(img, 11, 8, 2, 3, blue)
	# Highlights
	_px(img, 6, 2, blue_hi)
	_px(img, 9, 13, blue_hi)

	_outline(img, Color(0.1, 0.2, 0.35))
	_save(img, "res://assets/sprites/upgrades/reroll_shop.png")

func _gen_banish_shop() -> void:
	var img = _img()
	var red = Color(0.85, 0.15, 0.15)
	var red_hi = Color(1.0, 0.35, 0.35)

	# X mark
	# Top-left to bottom-right diagonal
	for i in range(12):
		_px(img, 2 + i, 2 + i, red)
		_px(img, 3 + i, 2 + i, red)
		_px(img, 2 + i, 3 + i, red)
	# Top-right to bottom-left diagonal
	for i in range(12):
		_px(img, 13 - i, 2 + i, red)
		_px(img, 12 - i, 2 + i, red)
		_px(img, 13 - i, 3 + i, red)
	# Highlight on top ends
	_px(img, 3, 2, red_hi)
	_px(img, 12, 2, red_hi)

	_outline(img, Color(0.3, 0.05, 0.05))
	_save(img, "res://assets/sprites/upgrades/banish_shop.png")

# ==================== RELICS (7) ====================

func _gen_hourglass() -> void:
	var img = _img()
	var brown = Color(0.6, 0.4, 0.2)
	var brown_hi = Color(0.75, 0.55, 0.3)
	var glass = Color(0.85, 0.88, 0.9)
	var sand = Color(0.9, 0.75, 0.35)

	# Top/bottom frames
	_fill(img, 3, 1, 10, 2, brown)
	_fill(img, 3, 13, 10, 2, brown)
	# Top bulb (glass)
	_fill(img, 4, 3, 8, 2, glass)
	_fill(img, 5, 5, 6, 1, glass)
	_fill(img, 6, 6, 4, 1, glass)
	# Neck
	_fill(img, 7, 7, 2, 2, glass)
	# Bottom bulb (glass)
	_fill(img, 6, 9, 4, 1, glass)
	_fill(img, 5, 10, 6, 1, glass)
	_fill(img, 4, 11, 8, 2, glass)
	# Sand (top - partially drained)
	_fill(img, 5, 4, 6, 1, sand)
	_fill(img, 6, 5, 4, 1, sand)
	# Sand (bottom - accumulated)
	_fill(img, 5, 11, 6, 1, sand)
	_fill(img, 6, 10, 4, 1, sand)
	# Falling sand grain
	_px(img, 7, 8, sand)
	# Frame highlight
	_fill(img, 4, 1, 8, 1, brown_hi)
	_fill(img, 4, 13, 8, 1, brown_hi)

	_outline(img, Color(0.25, 0.15, 0.05))
	_save(img, "res://assets/sprites/relics/hourglass.png")

func _gen_golden_dice() -> void:
	var img = _img()
	var gold = Color(0.9, 0.75, 0.2)
	var gold_hi = Color(1.0, 0.9, 0.45)
	var dark = Color(0.3, 0.2, 0.05)

	# Cube face (front - slightly angled)
	_fill(img, 3, 4, 10, 10, gold)
	# Top face (parallelogram for 3D look)
	_fill(img, 4, 2, 10, 2, gold_hi)
	_fill(img, 5, 1, 8, 1, gold_hi)
	# Right edge darkened
	_fill(img, 12, 5, 1, 9, Color(0.7, 0.55, 0.12))
	# Dots showing 6 (2 columns of 3)
	# Left column
	_px(img, 5, 6, dark)
	_px(img, 5, 8, dark)
	_px(img, 5, 10, dark)
	# Right column
	_px(img, 10, 6, dark)
	_px(img, 10, 8, dark)
	_px(img, 10, 10, dark)
	# Extra size for dots
	_px(img, 6, 6, dark)
	_px(img, 6, 8, dark)
	_px(img, 6, 10, dark)
	_px(img, 11, 6, dark)
	_px(img, 11, 8, dark)
	_px(img, 11, 10, dark)

	_outline(img, Color(0.3, 0.25, 0.05))
	_save(img, "res://assets/sprites/relics/golden_dice.png")

func _gen_extra_heart() -> void:
	var img = _img()
	var pink = Color(0.95, 0.45, 0.6)
	var pink_hi = Color(1.0, 0.65, 0.75)
	var halo = Color(1.0, 0.95, 0.5)

	# Heart shape
	_fill(img, 2, 5, 3, 2, pink)
	_fill(img, 6, 5, 1, 1, pink)
	_fill(img, 7, 5, 3, 2, pink)
	_fill(img, 3, 4, 2, 1, pink)
	_fill(img, 8, 4, 2, 1, pink)
	_fill(img, 1, 6, 10, 1, pink)
	_fill(img, 2, 7, 8, 1, pink)
	_fill(img, 2, 8, 8, 1, pink)
	_fill(img, 3, 9, 6, 1, pink)
	_fill(img, 4, 10, 4, 1, pink)
	_fill(img, 5, 11, 2, 1, pink)
	# Highlight
	_px(img, 3, 5, pink_hi)
	_px(img, 4, 4, pink_hi)
	# Halo above heart
	_fill(img, 4, 1, 5, 1, halo)
	_fill(img, 3, 2, 1, 1, halo)
	_fill(img, 9, 2, 1, 1, halo)
	_fill(img, 4, 3, 5, 1, halo)

	_outline(img, Color(0.35, 0.12, 0.2))
	_save(img, "res://assets/sprites/relics/extra_heart.png")

func _gen_compass() -> void:
	var img = _img()
	var brown = Color(0.55, 0.38, 0.2)
	var brown_hi = Color(0.7, 0.5, 0.28)
	var face = Color(0.9, 0.88, 0.8)
	var red = Color(0.85, 0.15, 0.15)
	var white = Color(0.9, 0.9, 0.95)

	# Circular body (brown ring)
	_fill(img, 4, 1, 8, 1, brown)
	_fill(img, 3, 2, 10, 1, brown)
	_fill(img, 2, 3, 12, 1, brown)
	_fill(img, 1, 4, 14, 8, brown)
	_fill(img, 2, 12, 12, 1, brown)
	_fill(img, 3, 13, 10, 1, brown)
	_fill(img, 4, 14, 8, 1, brown)
	# Inner face
	_fill(img, 4, 3, 8, 1, face)
	_fill(img, 3, 4, 10, 8, face)
	_fill(img, 4, 12, 8, 1, face)
	# Needle (red north, white south)
	_fill(img, 7, 3, 2, 5, red)  # North (red)
	_fill(img, 7, 8, 2, 5, white)  # South (white)
	# Center dot
	_px(img, 7, 7, Color(0.2, 0.2, 0.2))
	_px(img, 8, 7, Color(0.2, 0.2, 0.2))
	# Frame highlight
	_fill(img, 5, 1, 6, 1, brown_hi)

	_outline(img, Color(0.2, 0.12, 0.05))
	_save(img, "res://assets/sprites/relics/compass.png")

func _gen_scroll() -> void:
	var img = _img()
	var tan = Color(0.85, 0.75, 0.55)
	var tan_hi = Color(0.95, 0.88, 0.7)
	var tan_dk = Color(0.65, 0.55, 0.38)
	var text_col = Color(0.3, 0.25, 0.15)

	# Scroll body (rolled)
	_fill(img, 4, 3, 8, 10, tan)
	# Top roll
	_fill(img, 3, 2, 10, 2, tan_dk)
	_fill(img, 4, 2, 8, 1, tan_hi)
	# Bottom roll
	_fill(img, 3, 12, 10, 2, tan_dk)
	_fill(img, 4, 13, 8, 1, tan_hi)
	# Text lines
	_fill(img, 5, 5, 6, 1, text_col)
	_fill(img, 5, 7, 5, 1, text_col)
	_fill(img, 5, 9, 6, 1, text_col)
	# Roll ends (caps)
	_fill(img, 2, 2, 1, 2, tan_dk)
	_fill(img, 13, 2, 1, 2, tan_dk)
	_fill(img, 2, 12, 1, 2, tan_dk)
	_fill(img, 13, 12, 1, 2, tan_dk)

	_outline(img, Color(0.25, 0.2, 0.1))
	_save(img, "res://assets/sprites/relics/scroll.png")

func _gen_veteran_medal() -> void:
	var img = _img()
	var gold = Color(0.9, 0.75, 0.15)
	var gold_hi = Color(1.0, 0.9, 0.4)
	var ribbon = Color(0.2, 0.3, 0.7)
	var ribbon_hi = Color(0.35, 0.45, 0.85)

	# Ribbon (top)
	_fill(img, 4, 1, 8, 3, ribbon)
	_fill(img, 5, 1, 6, 1, ribbon_hi)
	# Ribbon tails
	_fill(img, 4, 4, 2, 2, ribbon)
	_fill(img, 10, 4, 2, 2, ribbon)
	# Medal circle
	_fill(img, 5, 6, 6, 1, gold)
	_fill(img, 4, 7, 8, 4, gold)
	_fill(img, 5, 11, 6, 1, gold)
	_fill(img, 6, 12, 4, 1, gold)
	# Star on medal
	_px(img, 7, 7, gold_hi)
	_px(img, 8, 7, gold_hi)
	_fill(img, 6, 8, 4, 1, gold_hi)
	_px(img, 7, 9, gold_hi)
	_px(img, 8, 9, gold_hi)
	_px(img, 6, 9, gold_hi)
	_px(img, 9, 9, gold_hi)
	_px(img, 7, 10, gold_hi)
	_px(img, 8, 10, gold_hi)

	_outline(img, Color(0.3, 0.25, 0.05))
	_save(img, "res://assets/sprites/relics/veteran_medal.png")

func _gen_master_key() -> void:
	var img = _img()
	var gold = Color(0.9, 0.72, 0.15)
	var gold_hi = Color(1.0, 0.88, 0.35)
	var gold_dk = Color(0.7, 0.52, 0.08)

	# Key head (circle/oval)
	_fill(img, 2, 2, 5, 1, gold)
	_fill(img, 1, 3, 7, 4, gold)
	_fill(img, 2, 7, 5, 1, gold)
	# Hole in key head
	_fill(img, 3, 4, 3, 2, Color(0, 0, 0, 0))
	# Shaft
	_fill(img, 7, 5, 7, 2, gold)
	# Teeth
	_fill(img, 12, 7, 2, 2, gold)
	_fill(img, 10, 7, 1, 2, gold)
	# Highlights
	_fill(img, 3, 2, 3, 1, gold_hi)
	_fill(img, 2, 3, 1, 2, gold_hi)
	_fill(img, 8, 5, 4, 1, gold_hi)
	# Dark edge
	_fill(img, 2, 7, 5, 1, gold_dk)
	_fill(img, 7, 6, 7, 1, gold_dk)

	_outline(img, Color(0.28, 0.2, 0.03))
	_save(img, "res://assets/sprites/relics/master_key.png")

# ==================== ACHIEVEMENTS (13) ====================

func _gen_first_walk() -> void:
	var img = _img()
	var green = Color(0.3, 0.7, 0.3)
	var green_dk = Color(0.2, 0.5, 0.2)

	# Two footprints
	# Left foot
	_fill(img, 2, 4, 3, 5, green)
	_fill(img, 3, 3, 2, 1, green)
	_fill(img, 2, 9, 1, 1, green_dk)
	# Left toes
	_px(img, 2, 2, green)
	_px(img, 4, 2, green)
	# Right foot (offset down-right)
	_fill(img, 8, 7, 3, 5, green)
	_fill(img, 9, 6, 2, 1, green)
	_fill(img, 8, 12, 1, 1, green_dk)
	# Right toes
	_px(img, 8, 5, green)
	_px(img, 10, 5, green)

	_outline(img, Color(0.08, 0.25, 0.08))
	_save(img, "res://assets/sprites/achievements/first_walk.png")

func _gen_evolved_6() -> void:
	var img = _img()
	var purple = Color(0.6, 0.2, 0.8)
	var purple_hi = Color(0.8, 0.45, 1.0)
	var white = Color(1.0, 0.9, 1.0)

	# Star burst (6 points radiating from center)
	# Center
	_fill(img, 6, 6, 4, 4, purple)
	# Top spike
	_fill(img, 7, 1, 2, 5, purple)
	_px(img, 7, 0, purple_hi)
	# Bottom spike
	_fill(img, 7, 10, 2, 5, purple)
	# Left spike
	_fill(img, 1, 7, 5, 2, purple)
	_px(img, 0, 7, purple_hi)
	# Right spike
	_fill(img, 10, 7, 5, 2, purple)
	# Top-left diagonal
	_px(img, 4, 3, purple)
	_px(img, 3, 2, purple)
	_px(img, 5, 4, purple)
	# Top-right diagonal
	_px(img, 11, 3, purple)
	_px(img, 12, 2, purple)
	_px(img, 10, 4, purple)
	# Bottom-left diagonal
	_px(img, 4, 12, purple)
	_px(img, 3, 13, purple)
	_px(img, 5, 11, purple)
	# Bottom-right diagonal
	_px(img, 11, 12, purple)
	_px(img, 12, 13, purple)
	_px(img, 10, 11, purple)
	# Center sparkle
	_px(img, 7, 7, white)
	_px(img, 8, 8, white)

	_outline(img, Color(0.2, 0.06, 0.3))
	_save(img, "res://assets/sprites/achievements/evolved_6.png")

func _gen_speedrunner() -> void:
	var img = _img()
	var blue = Color(0.3, 0.6, 1.0)
	var blue_hi = Color(0.55, 0.8, 1.0)
	var white = Color(0.9, 0.95, 1.0)

	# Lightning bolt
	_fill(img, 7, 1, 3, 2, blue_hi)
	_fill(img, 6, 3, 4, 2, blue)
	_fill(img, 5, 5, 5, 2, blue)
	_fill(img, 4, 7, 6, 1, blue)
	_fill(img, 7, 7, 4, 2, blue)
	_fill(img, 6, 9, 4, 2, blue)
	_fill(img, 5, 11, 3, 2, blue)
	_fill(img, 5, 13, 2, 2, blue)
	# Highlight
	_px(img, 7, 1, white)
	_px(img, 8, 2, blue_hi)

	_outline(img, Color(0.08, 0.18, 0.4))
	_save(img, "res://assets/sprites/achievements/speedrunner.png")

func _gen_collector() -> void:
	var img = _img()
	var gold = Color(0.85, 0.65, 0.1)
	var gold_hi = Color(1.0, 0.85, 0.3)
	var brown = Color(0.5, 0.32, 0.12)
	var dark = Color(0.3, 0.18, 0.05)

	# Chest body
	_fill(img, 2, 7, 12, 6, brown)
	# Chest lid (slightly raised)
	_fill(img, 2, 5, 12, 3, brown)
	_fill(img, 3, 4, 10, 1, brown)
	# Gold trim
	_fill(img, 2, 7, 12, 1, gold)
	# Lock/clasp
	_fill(img, 7, 8, 2, 2, gold)
	# Lid highlight
	_fill(img, 3, 5, 10, 1, gold_hi)
	# Gold coins peeking out
	_px(img, 5, 4, gold)
	_px(img, 6, 3, gold)
	_px(img, 7, 3, gold_hi)
	_px(img, 9, 4, gold)
	_px(img, 10, 3, gold)
	# Dark interior
	_fill(img, 3, 5, 3, 2, dark)
	_fill(img, 10, 5, 3, 2, dark)

	_outline(img, Color(0.2, 0.1, 0.02))
	_save(img, "res://assets/sprites/achievements/collector.png")

func _gen_cow_brejo() -> void:
	var img = _img()
	var brown = Color(0.55, 0.35, 0.18)
	var brown_hi = Color(0.7, 0.48, 0.25)
	var white = Color(0.92, 0.9, 0.85)
	var pink = Color(0.9, 0.55, 0.6)
	var dark = Color(0.15, 0.1, 0.05)

	# Head (brown)
	_fill(img, 4, 4, 8, 8, brown)
	_fill(img, 5, 3, 6, 1, brown)
	# White patch on forehead
	_fill(img, 6, 4, 4, 3, white)
	# Ears
	_fill(img, 2, 3, 2, 3, brown)
	_fill(img, 12, 3, 2, 3, brown)
	# Horns
	_px(img, 3, 1, brown_hi)
	_px(img, 3, 2, brown_hi)
	_px(img, 12, 1, brown_hi)
	_px(img, 12, 2, brown_hi)
	# Eyes
	_px(img, 6, 7, dark)
	_px(img, 10, 7, dark)
	# Snout
	_fill(img, 6, 9, 4, 2, pink)
	# Nostrils
	_px(img, 7, 10, dark)
	_px(img, 9, 10, dark)

	_outline(img, Color(0.18, 0.12, 0.05))
	_save(img, "res://assets/sprites/achievements/cow_brejo.png")

func _gen_nobody_deserves() -> void:
	var img = _img()
	var red = Color(0.75, 0.12, 0.12)
	var red_hi = Color(0.95, 0.25, 0.25)
	var dark = Color(0.2, 0.05, 0.05)

	# Skull shape
	_fill(img, 4, 2, 8, 2, red)
	_fill(img, 3, 4, 10, 5, red)
	_fill(img, 4, 9, 8, 2, red)
	_fill(img, 5, 11, 6, 1, red)
	# Eye sockets
	_fill(img, 5, 5, 2, 2, dark)
	_fill(img, 9, 5, 2, 2, dark)
	# Nose
	_px(img, 7, 8, dark)
	_px(img, 8, 8, dark)
	# Teeth
	_px(img, 5, 10, dark)
	_px(img, 7, 10, dark)
	_px(img, 9, 10, dark)
	# Highlight
	_px(img, 5, 3, red_hi)
	_px(img, 6, 2, red_hi)

	_outline(img, Color(0.25, 0.02, 0.02))
	_save(img, "res://assets/sprites/achievements/nobody_deserves.png")

func _gen_genocide() -> void:
	var img = _img()
	var red_dk = Color(0.55, 0.08, 0.08)
	var red = Color(0.7, 0.15, 0.15)
	var gray = Color(0.5, 0.5, 0.55)

	# Pile of swords (3 crossing)
	# Sword 1 (left diagonal)
	for i in range(12):
		_px(img, 2 + i, 2 + i, gray)
		_px(img, 3 + i, 2 + i, gray)
	# Sword 2 (right diagonal)
	for i in range(12):
		_px(img, 13 - i, 2 + i, gray)
		_px(img, 12 - i, 2 + i, gray)
	# Sword 3 (vertical center)
	_fill(img, 7, 1, 2, 13, gray)
	# Blood splatter
	_fill(img, 5, 8, 6, 3, red_dk)
	_fill(img, 6, 7, 4, 1, red_dk)
	_px(img, 4, 9, red)
	_px(img, 11, 10, red)
	_px(img, 3, 11, red)
	_px(img, 12, 8, red)

	_outline(img, Color(0.18, 0.02, 0.02))
	_save(img, "res://assets/sprites/achievements/genocide.png")

func _gen_sweet_revenge() -> void:
	var img = _img()
	var pink = Color(0.9, 0.45, 0.6)
	var pink_hi = Color(1.0, 0.65, 0.78)
	var dark = Color(0.25, 0.08, 0.12)
	var white = Color(0.95, 0.9, 0.92)

	# Candy skull (skull shape with candy colors)
	_fill(img, 4, 2, 8, 2, pink)
	_fill(img, 3, 4, 10, 5, pink)
	_fill(img, 4, 9, 8, 2, pink)
	_fill(img, 5, 11, 6, 1, pink)
	# Eyes (heart-shaped)
	_px(img, 5, 5, dark)
	_px(img, 6, 5, dark)
	_px(img, 5, 6, dark)
	_px(img, 9, 5, dark)
	_px(img, 10, 5, dark)
	_px(img, 10, 6, dark)
	# Nose
	_px(img, 7, 8, dark)
	_px(img, 8, 8, dark)
	# Smile
	_fill(img, 5, 10, 6, 1, dark)
	# Candy swirl decorations
	_px(img, 5, 3, white)
	_px(img, 10, 3, white)
	_px(img, 7, 7, white)
	_px(img, 8, 7, white)
	# Highlight
	_px(img, 5, 2, pink_hi)
	_px(img, 6, 2, pink_hi)

	_outline(img, Color(0.3, 0.1, 0.15))
	_save(img, "res://assets/sprites/achievements/sweet_revenge.png")

func _gen_storm() -> void:
	var img = _img()
	var cloud = Color(0.55, 0.55, 0.62)
	var cloud_hi = Color(0.72, 0.72, 0.78)
	var yellow = Color(1.0, 0.9, 0.2)
	var yellow_dk = Color(0.85, 0.7, 0.1)

	# Cloud
	_fill(img, 3, 3, 10, 4, cloud)
	_fill(img, 2, 4, 12, 2, cloud)
	_fill(img, 5, 2, 4, 1, cloud)
	_fill(img, 9, 2, 3, 1, cloud)
	# Cloud highlight
	_fill(img, 5, 2, 4, 1, cloud_hi)
	_fill(img, 4, 3, 4, 1, cloud_hi)
	# Lightning bolt from cloud
	_fill(img, 7, 7, 3, 1, yellow)
	_fill(img, 6, 8, 3, 1, yellow)
	_fill(img, 5, 9, 3, 1, yellow)
	_fill(img, 7, 10, 3, 1, yellow)
	_fill(img, 6, 11, 3, 1, yellow)
	_fill(img, 5, 12, 2, 1, yellow)
	_px(img, 5, 13, yellow_dk)

	_outline(img, Color(0.18, 0.18, 0.22))
	_save(img, "res://assets/sprites/achievements/storm.png")

func _gen_pacifist() -> void:
	var img = _img()
	var white = Color(0.92, 0.92, 0.95)
	var white_hi = Color(1.0, 1.0, 1.0)
	var beak = Color(0.9, 0.7, 0.2)
	var eye = Color(0.15, 0.15, 0.2)

	# Dove body
	_fill(img, 5, 6, 7, 4, white)
	_fill(img, 4, 7, 9, 2, white)
	# Head
	_fill(img, 9, 4, 4, 3, white)
	_fill(img, 10, 3, 3, 1, white)
	# Beak
	_px(img, 13, 5, beak)
	_px(img, 14, 5, beak)
	# Eye
	_px(img, 11, 4, eye)
	# Left wing (raised up)
	_fill(img, 2, 3, 4, 3, white)
	_fill(img, 1, 4, 2, 2, white)
	_px(img, 1, 2, white)
	_px(img, 2, 2, white)
	# Tail
	_fill(img, 3, 10, 3, 1, white)
	_px(img, 2, 10, white)
	_px(img, 2, 11, white)
	# Wing highlight
	_px(img, 3, 3, white_hi)
	_px(img, 10, 4, white_hi)

	_outline(img, Color(0.35, 0.35, 0.4))
	_save(img, "res://assets/sprites/achievements/pacifist.png")

func _gen_matrix() -> void:
	var img = _img()
	var green = Color(0.1, 0.75, 0.2)
	var green_hi = Color(0.3, 1.0, 0.4)
	var green_dk = Color(0.05, 0.45, 0.1)

	# Falling code columns (matrix-style)
	# Column 1
	_px(img, 1, 2, green_dk)
	_px(img, 1, 4, green)
	_px(img, 1, 6, green_hi)
	_px(img, 1, 8, green)
	_px(img, 1, 10, green_dk)
	# Column 2
	_px(img, 4, 1, green)
	_px(img, 4, 3, green_hi)
	_px(img, 4, 5, green)
	_px(img, 4, 7, green_dk)
	_px(img, 4, 9, green)
	_px(img, 4, 11, green_hi)
	_px(img, 4, 13, green)
	# Column 3
	_px(img, 7, 0, green_dk)
	_px(img, 7, 2, green)
	_px(img, 7, 4, green)
	_px(img, 7, 6, green_hi)
	_px(img, 7, 8, green)
	_px(img, 7, 10, green)
	_px(img, 7, 12, green_dk)
	# Column 4
	_px(img, 10, 3, green)
	_px(img, 10, 5, green_dk)
	_px(img, 10, 7, green)
	_px(img, 10, 9, green_hi)
	_px(img, 10, 11, green)
	_px(img, 10, 13, green_dk)
	# Column 5
	_px(img, 13, 1, green_dk)
	_px(img, 13, 3, green)
	_px(img, 13, 5, green_hi)
	_px(img, 13, 7, green)
	_px(img, 13, 9, green_dk)
	_px(img, 13, 11, green)
	# Some wider glyphs for texture
	_px(img, 2, 4, green_dk)
	_px(img, 5, 3, green_dk)
	_px(img, 8, 6, green)
	_px(img, 11, 9, green)
	_px(img, 14, 5, green_dk)

	# No outline for matrix effect - keep it clean
	_save(img, "res://assets/sprites/achievements/matrix.png")

func _gen_one_punch() -> void:
	var img = _img()
	var red = Color(0.85, 0.2, 0.15)
	var red_hi = Color(1.0, 0.35, 0.3)
	var skin = Color(0.9, 0.72, 0.55)
	var skin_dk = Color(0.7, 0.52, 0.38)

	# Fist (front-facing)
	# Main fist block
	_fill(img, 3, 4, 10, 7, skin)
	# Fingers (curled, top)
	_fill(img, 3, 3, 10, 2, skin_dk)
	_fill(img, 4, 2, 8, 1, skin_dk)
	# Thumb (left side)
	_fill(img, 2, 7, 2, 3, skin)
	_px(img, 1, 8, skin)
	# Wrist
	_fill(img, 4, 11, 8, 2, skin)
	# Knuckle lines
	_px(img, 5, 4, skin_dk)
	_px(img, 7, 4, skin_dk)
	_px(img, 9, 4, skin_dk)
	_px(img, 11, 4, skin_dk)
	# Red impact lines around fist
	_px(img, 0, 2, red)
	_px(img, 1, 1, red)
	_px(img, 14, 1, red)
	_px(img, 15, 2, red)
	_px(img, 0, 13, red)
	_px(img, 15, 13, red)
	# Impact star behind
	_px(img, 14, 5, red_hi)
	_px(img, 15, 6, red_hi)
	_px(img, 0, 5, red_hi)

	_outline(img, Color(0.3, 0.08, 0.05))
	_save(img, "res://assets/sprites/achievements/one_punch.png")

func _gen_lucky_day() -> void:
	var img = _img()
	var gold = Color(0.9, 0.78, 0.15)
	var gold_hi = Color(1.0, 0.92, 0.4)
	var stem = Color(0.5, 0.65, 0.12)
	var sparkle = Color(1.0, 1.0, 0.7)

	# Gold four-leaf clover
	# Top leaf
	_fill(img, 6, 1, 4, 3, gold)
	_px(img, 7, 0, gold)
	_px(img, 8, 0, gold)
	# Bottom leaf
	_fill(img, 6, 8, 4, 3, gold)
	_px(img, 7, 11, gold)
	_px(img, 8, 11, gold)
	# Left leaf
	_fill(img, 2, 4, 3, 4, gold)
	_px(img, 1, 5, gold)
	_px(img, 1, 6, gold)
	# Right leaf
	_fill(img, 10, 4, 3, 4, gold)
	_px(img, 13, 5, gold)
	_px(img, 13, 6, gold)
	# Center
	_fill(img, 5, 4, 6, 4, gold)
	# Highlights
	_px(img, 6, 2, gold_hi)
	_px(img, 3, 5, gold_hi)
	_px(img, 11, 5, gold_hi)
	_px(img, 6, 9, gold_hi)
	# Stem
	_fill(img, 8, 12, 1, 3, stem)
	_px(img, 9, 14, stem)
	# Sparkles around
	_px(img, 0, 1, sparkle)
	_px(img, 14, 0, sparkle)
	_px(img, 15, 10, sparkle)
	_px(img, 0, 12, sparkle)

	_outline(img, Color(0.3, 0.25, 0.05))
	_save(img, "res://assets/sprites/achievements/lucky_day.png")
