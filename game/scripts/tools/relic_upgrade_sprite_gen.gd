extends SceneTree

## Generates 64x64 pixel art sprites for 7 relics + 12 upgrades.
## Replaces tiny 16x16 stubs with detailed pixel art.
## Run: godot --headless --path game --script res://scripts/tools/relic_upgrade_sprite_gen.gd

const S := 64
const RELIC_DIR := "res://assets/sprites/relics/"
const UPGRADE_DIR := "res://assets/sprites/upgrades/"

func _init() -> void:
	DirAccess.make_dir_recursive_absolute(RELIC_DIR)
	DirAccess.make_dir_recursive_absolute(UPGRADE_DIR)
	_gen_hourglass()
	_gen_golden_dice()
	_gen_extra_heart()
	_gen_compass()
	_gen_scroll()
	_gen_veteran_medal()
	_gen_master_key()
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
	print("Generated 7 relic + 12 upgrade sprites at 64x64!")
	quit()

func _img() -> Image:
	return Image.create(S, S, false, Image.FORMAT_RGBA8)
func _fill(img: Image, x: int, y: int, w: int, h: int, c: Color) -> void:
	for px in range(maxi(x, 0), mini(x + w, S)):
		for py in range(maxi(y, 0), mini(y + h, S)):
			img.set_pixel(px, py, c)
func _px(img: Image, x: int, y: int, c: Color) -> void:
	if x >= 0 and x < S and y >= 0 and y < S:
		img.set_pixel(x, y, c)
func _circle(img: Image, cx: int, cy: int, r: int, c: Color) -> void:
	for x in range(maxi(cx - r, 0), mini(cx + r + 1, S)):
		for y in range(maxi(cy - r, 0), mini(cy + r + 1, S)):
			if (x - cx) * (x - cx) + (y - cy) * (y - cy) <= r * r:
				img.set_pixel(x, y, c)
func _line_h(img: Image, x1: int, x2: int, y: int, c: Color) -> void:
	for x in range(maxi(x1, 0), mini(x2 + 1, S)):
		_px(img, x, y, c)
func _line_v(img: Image, x: int, y1: int, y2: int, c: Color) -> void:
	for y in range(maxi(y1, 0), mini(y2 + 1, S)):
		_px(img, x, y, c)
func _outline(img: Image, color: Color) -> void:
	var copy = img.duplicate()
	for x in range(S):
		for y in range(S):
			if copy.get_pixel(x, y).a > 0:
				for d in [Vector2i(-1,0), Vector2i(1,0), Vector2i(0,-1), Vector2i(0,1)]:
					var nx = x + d.x
					var ny = y + d.y
					if nx >= 0 and nx < S and ny >= 0 and ny < S and copy.get_pixel(nx, ny).a == 0:
						img.set_pixel(nx, ny, color)
func _save_r(img: Image, n: String) -> void:
	img.save_png(RELIC_DIR + n)
	print("Saved: %s%s" % [RELIC_DIR, n])
func _save_u(img: Image, n: String) -> void:
	img.save_png(UPGRADE_DIR + n)
	print("Saved: %s%s" % [UPGRADE_DIR, n])

# ==================== RELICS ====================
func _gen_hourglass() -> void:
	var img = _img()
	var gold = Color(0.82, 0.68, 0.15)
	var gold_dk = Color(0.6, 0.48, 0.08)
	var glass = Color(0.7, 0.75, 0.82, 0.6)
	var sand = Color(0.85, 0.72, 0.35)
	var sand_dk = Color(0.7, 0.55, 0.2)
	# Top frame
	_fill(img, 14, 4, 36, 4, gold)
	_fill(img, 16, 2, 32, 3, gold_dk)
	# Bottom frame
	_fill(img, 14, 56, 36, 4, gold)
	_fill(img, 16, 59, 32, 3, gold_dk)
	# Glass body (top bulb)
	_fill(img, 18, 8, 28, 6, glass)
	_fill(img, 20, 14, 24, 6, glass)
	_fill(img, 24, 20, 16, 4, glass)
	_fill(img, 28, 24, 8, 4, glass)
	# Glass body (bottom bulb)
	_fill(img, 28, 36, 8, 4, glass)
	_fill(img, 24, 40, 16, 4, glass)
	_fill(img, 20, 44, 24, 6, glass)
	_fill(img, 18, 50, 28, 6, glass)
	# Neck
	_fill(img, 30, 28, 4, 8, glass)
	# Sand (top, partially emptied)
	_fill(img, 22, 16, 20, 4, sand)
	_fill(img, 26, 20, 12, 3, sand)
	# Sand stream
	_fill(img, 31, 26, 2, 12, sand_dk)
	# Sand pile (bottom)
	_fill(img, 22, 50, 20, 4, sand)
	_fill(img, 24, 48, 16, 3, sand)
	_fill(img, 28, 46, 8, 3, sand_dk)
	# Pillars
	_fill(img, 14, 6, 4, 52, gold_dk)
	_fill(img, 46, 6, 4, 52, gold_dk)
	_fill(img, 15, 8, 2, 48, gold)
	_fill(img, 47, 8, 2, 48, gold)
	_outline(img, Color(0.28, 0.2, 0.05))
	_save_r(img, "hourglass.png")

func _gen_golden_dice() -> void:
	var img = _img()
	var gold = Color(0.85, 0.72, 0.18)
	var gold_dk = Color(0.65, 0.52, 0.1)
	var gold_lt = Color(0.95, 0.85, 0.3)
	var dot = Color(0.15, 0.1, 0.05)
	# Dice body (3D perspective — top, front, right)
	# Front face
	_fill(img, 12, 22, 26, 26, gold)
	_fill(img, 14, 24, 22, 22, gold_dk)
	# Top face (parallelogram)
	_fill(img, 18, 10, 26, 12, gold_lt)
	_fill(img, 12, 22, 6, 2, gold)
	# Right face
	_fill(img, 38, 22, 14, 26, gold_dk)
	_fill(img, 40, 12, 12, 12, gold)
	# Dots on front (5 = quincunx)
	_circle(img, 18, 28, 2, dot)
	_circle(img, 34, 28, 2, dot)
	_circle(img, 26, 35, 2, dot)
	_circle(img, 18, 42, 2, dot)
	_circle(img, 34, 42, 2, dot)
	# Dots on top (6)
	_px(img, 24, 13, dot)
	_px(img, 32, 13, dot)
	_px(img, 40, 13, dot)
	_px(img, 24, 18, dot)
	_px(img, 32, 18, dot)
	_px(img, 40, 18, dot)
	# Shine
	_circle(img, 16, 24, 2, Color(1.0, 0.95, 0.5))
	_outline(img, Color(0.3, 0.22, 0.05))
	_save_r(img, "golden_dice.png")

func _gen_extra_heart() -> void:
	var img = _img()
	var pink = Color(1.0, 0.4, 0.5)
	var pink_lt = Color(1.0, 0.6, 0.65)
	var pink_dk = Color(0.7, 0.2, 0.25)
	var gold = Color(0.85, 0.72, 0.18)
	var glow = Color(1.0, 0.5, 0.5, 0.2)
	_circle(img, 32, 32, 26, glow)
	# Heart shape
	_circle(img, 22, 22, 12, pink)
	_circle(img, 42, 22, 12, pink)
	_fill(img, 22, 22, 20, 12, pink)
	for i in range(22):
		var w = 22 - i
		_fill(img, 32 - w / 2, 32 + i, w, 1, pink)
	# Highlight
	_circle(img, 20, 18, 5, pink_lt)
	_circle(img, 18, 16, 3, Color(1.0, 0.75, 0.78))
	_px(img, 17, 15, Color.WHITE)
	# Shadow
	_circle(img, 40, 28, 5, pink_dk)
	# Gold border glow
	_circle(img, 22, 22, 13, Color(0, 0, 0, 0))
	# Plus sign (extra)
	_fill(img, 48, 6, 10, 4, gold)
	_fill(img, 51, 2, 4, 12, gold)
	_outline(img, Color(0.3, 0.08, 0.1))
	_save_r(img, "extra_heart.png")

func _gen_compass() -> void:
	var img = _img()
	var gold = Color(0.8, 0.65, 0.15)
	var gold_dk = Color(0.6, 0.48, 0.08)
	var face = Color(0.9, 0.88, 0.8)
	var red = Color(0.8, 0.15, 0.1)
	var blue = Color(0.15, 0.2, 0.7)
	var needle = Color(0.5, 0.5, 0.55)
	# Body
	_circle(img, 32, 32, 24, gold)
	_circle(img, 32, 32, 22, gold_dk)
	_circle(img, 32, 32, 20, face)
	# Cardinal marks
	_fill(img, 30, 12, 4, 4, red)  # N
	_fill(img, 30, 48, 4, 4, Color(0.3, 0.3, 0.35))  # S
	_fill(img, 48, 30, 4, 4, Color(0.3, 0.3, 0.35))  # E
	_fill(img, 12, 30, 4, 4, Color(0.3, 0.3, 0.35))  # W
	# Needle (N=red, S=blue)
	_fill(img, 31, 16, 2, 16, red)
	_fill(img, 30, 14, 4, 3, red)
	_fill(img, 31, 32, 2, 16, blue)
	_fill(img, 30, 47, 4, 3, blue)
	# Center pin
	_circle(img, 32, 32, 3, needle)
	_circle(img, 32, 32, 1, gold)
	# Degree ticks
	for i in range(8):
		var angle = i * PI / 4.0
		var tx = int(32 + cos(angle) * 18)
		var ty = int(32 + sin(angle) * 18)
		_px(img, tx, ty, gold_dk)
	# Glass reflection
	_circle(img, 24, 24, 4, Color(1.0, 1.0, 1.0, 0.15))
	# Ring knob
	_circle(img, 32, 6, 4, gold)
	_circle(img, 32, 6, 2, gold_dk)
	_outline(img, Color(0.28, 0.2, 0.04))
	_save_r(img, "compass.png")

func _gen_scroll() -> void:
	var img = _img()
	var parch = Color(0.85, 0.78, 0.6)
	var parch_dk = Color(0.7, 0.62, 0.45)
	var parch_lt = Color(0.92, 0.88, 0.72)
	var wood = Color(0.5, 0.35, 0.18)
	var ink = Color(0.15, 0.1, 0.08)
	# Top roll
	_fill(img, 8, 6, 48, 8, wood)
	_fill(img, 10, 4, 44, 3, Color(0.55, 0.38, 0.2))
	_fill(img, 10, 8, 44, 2, Color(0.4, 0.28, 0.12))
	# Scroll face (unrolled)
	_fill(img, 12, 14, 40, 34, parch)
	_fill(img, 14, 16, 36, 30, parch_lt)
	_fill(img, 12, 44, 40, 4, parch_dk)
	# Bottom roll
	_fill(img, 8, 48, 48, 8, wood)
	_fill(img, 10, 48, 44, 2, Color(0.55, 0.38, 0.2))
	_fill(img, 10, 54, 44, 3, Color(0.4, 0.28, 0.12))
	# Roll end caps
	_fill(img, 6, 6, 4, 8, Color(0.6, 0.5, 0.2))
	_fill(img, 54, 6, 4, 8, Color(0.6, 0.5, 0.2))
	_fill(img, 6, 48, 4, 8, Color(0.6, 0.5, 0.2))
	_fill(img, 54, 48, 4, 8, Color(0.6, 0.5, 0.2))
	# Mystical text lines
	for i in range(5):
		_fill(img, 18, 20 + i * 5, 28, 2, ink)
	# Seal/stamp
	_circle(img, 40, 38, 4, Color(0.7, 0.15, 0.1))
	_circle(img, 40, 38, 2, Color(0.85, 0.25, 0.15))
	_outline(img, Color(0.25, 0.18, 0.08))
	_save_r(img, "scroll.png")

func _gen_veteran_medal() -> void:
	var img = _img()
	var gold = Color(0.85, 0.72, 0.18)
	var gold_dk = Color(0.65, 0.52, 0.1)
	var gold_lt = Color(0.95, 0.85, 0.3)
	var ribbon = Color(0.15, 0.2, 0.6)
	var ribbon_lt = Color(0.25, 0.35, 0.75)
	var star_c = Color(0.9, 0.8, 0.2)
	# Ribbon (V-shape at top)
	_fill(img, 18, 2, 10, 20, ribbon)
	_fill(img, 36, 2, 10, 20, ribbon)
	_fill(img, 20, 4, 6, 16, ribbon_lt)
	_fill(img, 38, 4, 6, 16, ribbon_lt)
	# Ribbon drape connecting
	_fill(img, 26, 16, 12, 6, ribbon)
	_fill(img, 28, 18, 8, 2, ribbon_lt)
	# Medal body (circular)
	_circle(img, 32, 38, 16, gold)
	_circle(img, 32, 38, 14, gold_dk)
	_circle(img, 32, 38, 12, gold)
	# Star emblem
	_fill(img, 30, 28, 4, 4, star_c)
	_fill(img, 26, 32, 12, 4, star_c)
	_fill(img, 28, 30, 8, 8, star_c)
	_fill(img, 30, 36, 4, 8, star_c)
	_fill(img, 26, 38, 4, 4, star_c)
	_fill(img, 34, 38, 4, 4, star_c)
	# Center of star
	_circle(img, 32, 36, 3, gold_lt)
	# Shine
	_circle(img, 26, 30, 2, Color(1.0, 0.95, 0.5))
	# Medal ring
	_circle(img, 32, 22, 3, gold)
	_circle(img, 32, 22, 1, gold_dk)
	_outline(img, Color(0.3, 0.22, 0.05))
	_save_r(img, "veteran_medal.png")

func _gen_master_key() -> void:
	var img = _img()
	var gold = Color(0.85, 0.72, 0.18)
	var gold_dk = Color(0.62, 0.5, 0.1)
	var gold_lt = Color(0.95, 0.85, 0.3)
	var gem = Color(0.3, 0.5, 0.9)
	# Key bow (ornate ring)
	_circle(img, 20, 18, 12, gold)
	_circle(img, 20, 18, 8, Color(0, 0, 0, 0))
	_circle(img, 20, 18, 10, gold_dk)
	_circle(img, 20, 18, 8, Color(0, 0, 0, 0))
	# Crown on bow
	_fill(img, 14, 6, 4, 5, gold_lt)
	_fill(img, 20, 4, 4, 5, gold_lt)
	_fill(img, 26, 6, 4, 5, gold_lt)
	# Gem in center of bow
	_circle(img, 20, 18, 4, gem)
	_circle(img, 20, 18, 2, Color(0.5, 0.7, 1.0))
	_px(img, 19, 17, Color.WHITE)
	# Key shaft
	_fill(img, 30, 16, 26, 5, gold)
	_fill(img, 32, 14, 22, 2, gold_dk)
	_fill(img, 32, 18, 2, 2, gold_lt)
	# Key teeth (3 teeth at end)
	_fill(img, 50, 20, 4, 8, gold)
	_fill(img, 44, 20, 4, 6, gold)
	_fill(img, 38, 20, 4, 4, gold_dk)
	# Teeth notches
	_fill(img, 48, 22, 2, 4, gold_dk)
	_fill(img, 42, 22, 2, 2, gold_dk)
	# Decorative groove on shaft
	_line_h(img, 32, 54, 17, gold_dk)
	_line_h(img, 32, 54, 19, gold_dk)
	# Sparkle
	_px(img, 16, 12, Color.WHITE)
	_outline(img, Color(0.3, 0.22, 0.05))
	_save_r(img, "master_key.png")

# ==================== UPGRADES ====================
func _gen_max_hp() -> void:
	var img = _img()
	var red = Color(0.85, 0.12, 0.15)
	var red_lt = Color(0.95, 0.3, 0.28)
	var red_dk = Color(0.6, 0.06, 0.08)
	var white = Color(0.95, 0.95, 0.95)
	_circle(img, 22, 24, 12, red)
	_circle(img, 42, 24, 12, red)
	_fill(img, 22, 24, 20, 10, red)
	for i in range(18):
		_fill(img, 32 - (18 - i) / 2, 32 + i, 18 - i, 1, red)
	_circle(img, 20, 20, 5, red_lt)
	_px(img, 18, 18, Color.WHITE)
	_circle(img, 38, 30, 5, red_dk)
	# Plus symbol
	_fill(img, 46, 6, 12, 4, white)
	_fill(img, 50, 2, 4, 12, white)
	_outline(img, Color(0.3, 0.04, 0.05))
	_save_u(img, "max_hp.png")

func _gen_speed() -> void:
	var img = _img()
	var blue = Color(0.2, 0.5, 0.9)
	var blue_lt = Color(0.4, 0.7, 1.0)
	var yellow = Color(1.0, 0.85, 0.2)
	# Wing/speed boot silhouette
	_fill(img, 12, 24, 20, 22, Color(0.55, 0.35, 0.15))
	_fill(img, 8, 42, 26, 8, Color(0.4, 0.25, 0.1))
	_fill(img, 14, 26, 14, 6, Color(0.65, 0.45, 0.22))
	# Speed lines (horizontal streaks)
	for i in range(5):
		var y = 18 + i * 8
		var alpha = 0.8 - i * 0.12
		_fill(img, 36, y, 20 - i * 2, 3, Color(blue.r, blue.g, blue.b, alpha))
		_fill(img, 40, y + 1, 14 - i * 2, 1, Color(blue_lt.r, blue_lt.g, blue_lt.b, alpha * 0.8))
	# Lightning bolt accent
	_fill(img, 42, 10, 6, 4, yellow)
	_fill(img, 38, 14, 6, 4, yellow)
	_fill(img, 44, 18, 6, 4, yellow)
	_fill(img, 40, 22, 6, 4, yellow)
	_outline(img, Color(0.06, 0.15, 0.35))
	_save_u(img, "speed.png")

func _gen_damage() -> void:
	var img = _img()
	var blade = Color(0.65, 0.68, 0.72)
	var blade_lt = Color(0.82, 0.85, 0.9)
	var red = Color(0.8, 0.15, 0.1)
	var red_br = Color(1.0, 0.3, 0.2)
	# Sword (vertical, simple)
	_fill(img, 28, 4, 8, 32, blade)
	_fill(img, 30, 2, 4, 4, blade)
	_fill(img, 31, 0, 2, 3, blade_lt)
	_fill(img, 30, 6, 2, 26, blade_lt)
	# Guard
	_fill(img, 18, 36, 28, 4, Color(0.7, 0.6, 0.15))
	_fill(img, 20, 37, 24, 2, Color(0.85, 0.75, 0.2))
	# Handle
	_fill(img, 28, 40, 8, 14, Color(0.35, 0.2, 0.1))
	for i in range(3):
		_fill(img, 28, 42 + i * 4, 8, 2, Color(0.25, 0.14, 0.06))
	# Pommel
	_fill(img, 28, 54, 8, 4, Color(0.7, 0.6, 0.15))
	# Red damage aura/arrows
	_fill(img, 10, 16, 8, 4, red)
	_fill(img, 6, 18, 4, 4, red_br)
	_fill(img, 46, 16, 8, 4, red)
	_fill(img, 54, 18, 4, 4, red_br)
	# Up arrows
	_fill(img, 8, 10, 4, 8, red)
	_fill(img, 6, 12, 8, 2, red)
	_fill(img, 52, 10, 4, 8, red)
	_fill(img, 50, 12, 8, 2, red)
	_outline(img, Color(0.2, 0.2, 0.25))
	_save_u(img, "damage.png")

func _gen_armor() -> void:
	var img = _img()
	var metal = Color(0.5, 0.52, 0.58)
	var metal_dk = Color(0.35, 0.36, 0.42)
	var metal_lt = Color(0.65, 0.68, 0.74)
	var blue = Color(0.2, 0.3, 0.6)
	# Shield shape
	_fill(img, 12, 6, 40, 10, metal)
	_fill(img, 10, 12, 44, 14, metal)
	_fill(img, 12, 26, 40, 10, metal_dk)
	_fill(img, 16, 36, 32, 8, metal)
	_fill(img, 20, 44, 24, 6, metal_dk)
	_fill(img, 26, 50, 12, 4, metal)
	_fill(img, 30, 54, 4, 4, metal_dk)
	# Cross band (horizontal)
	_line_h(img, 12, 52, 22, metal_lt)
	_line_h(img, 12, 52, 23, metal_lt)
	# Cross band (vertical)
	_line_v(img, 32, 8, 52, metal_lt)
	_line_v(img, 33, 8, 52, metal_lt)
	# Highlights
	_fill(img, 14, 10, 10, 8, metal_lt)
	# Blue inner panels
	_fill(img, 16, 10, 14, 10, blue)
	_fill(img, 36, 10, 14, 10, blue)
	_fill(img, 16, 26, 14, 8, Color(0.15, 0.22, 0.5))
	_fill(img, 36, 26, 14, 8, Color(0.15, 0.22, 0.5))
	# Rivets
	_circle(img, 14, 8, 2, metal_lt)
	_circle(img, 50, 8, 2, metal_lt)
	_circle(img, 14, 34, 2, metal_lt)
	_circle(img, 50, 34, 2, metal_lt)
	_outline(img, Color(0.15, 0.15, 0.2))
	_save_u(img, "armor.png")

func _gen_xp_bonus() -> void:
	var img = _img()
	var blue = Color(0.2, 0.45, 0.9)
	var blue_lt = Color(0.4, 0.65, 1.0)
	var gold = Color(0.85, 0.75, 0.2)
	# XP gem (diamond)
	_fill(img, 24, 8, 16, 4, blue)
	_fill(img, 20, 12, 24, 8, blue)
	_fill(img, 16, 20, 32, 8, blue)
	_fill(img, 20, 28, 24, 8, blue)
	_fill(img, 24, 36, 16, 8, blue)
	_fill(img, 28, 44, 8, 4, blue)
	# Highlights
	_fill(img, 22, 14, 8, 6, blue_lt)
	_fill(img, 18, 22, 8, 4, blue_lt)
	_px(img, 22, 14, Color(0.6, 0.8, 1.0))
	# Up arrow
	_fill(img, 48, 12, 4, 16, gold)
	_fill(img, 44, 16, 12, 4, gold)
	_fill(img, 46, 10, 8, 4, gold)
	_fill(img, 48, 8, 4, 4, gold)
	# Sparkles
	_px(img, 12, 18, Color(0.5, 0.7, 1.0, 0.5))
	_px(img, 44, 36, Color(0.5, 0.7, 1.0, 0.5))
	_outline(img, Color(0.06, 0.15, 0.35))
	_save_u(img, "xp_bonus.png")

func _gen_magnetism() -> void:
	var img = _img()
	var red = Color(0.8, 0.15, 0.12)
	var blue = Color(0.15, 0.2, 0.7)
	var metal = Color(0.7, 0.68, 0.6)
	var field = Color(0.5, 0.5, 0.8, 0.3)
	# U-magnet
	_fill(img, 12, 10, 10, 32, red)
	_fill(img, 42, 10, 10, 32, blue)
	_fill(img, 12, 38, 40, 10, Color(0.5, 0.12, 0.4))
	_fill(img, 16, 42, 32, 6, Color(0.45, 0.1, 0.35))
	_fill(img, 22, 38, 20, 4, Color(0, 0, 0, 0))
	_fill(img, 12, 8, 10, 5, metal)
	_fill(img, 42, 8, 10, 5, metal)
	# Field lines
	for i in range(3):
		var r = 8 + i * 6
		for angle_i in range(8):
			var a = PI + angle_i * PI / 8.0
			var fx = int(32 + cos(a) * r)
			var fy = int(16 + sin(a) * r)
			_px(img, fx, fy, field)
	_outline(img, Color(0.25, 0.06, 0.05))
	_save_u(img, "magnetism.png")

func _gen_cooldown_reduction() -> void:
	var img = _img()
	var blue = Color(0.2, 0.5, 0.85)
	var blue_lt = Color(0.4, 0.7, 1.0)
	var face = Color(0.88, 0.86, 0.8)
	var hand = Color(0.15, 0.12, 0.1)
	var green = Color(0.2, 0.8, 0.3)
	# Clock face
	_circle(img, 32, 32, 22, blue)
	_circle(img, 32, 32, 20, Color(0.15, 0.35, 0.65))
	_circle(img, 32, 32, 18, face)
	# Hands (fast — pointing to 12 and 3)
	_line_v(img, 32, 16, 32, hand)
	_line_h(img, 32, 46, 32, hand)
	_circle(img, 32, 32, 2, hand)
	# Speed arrows (clockwise)
	_fill(img, 50, 24, 8, 4, green)
	_fill(img, 54, 20, 4, 8, green)
	_fill(img, 56, 22, 4, 4, green)
	# Tick marks
	for i in range(12):
		var a = i * PI / 6.0
		var tx = int(32 + cos(a) * 16)
		var ty = int(32 + sin(a) * 16)
		_px(img, tx, ty, blue)
	_outline(img, Color(0.06, 0.18, 0.35))
	_save_u(img, "cooldown_reduction.png")

func _gen_luck() -> void:
	var img = _img()
	var green = Color(0.15, 0.6, 0.2)
	var green_lt = Color(0.25, 0.78, 0.32)
	var green_dk = Color(0.08, 0.4, 0.1)
	var gold = Color(0.85, 0.75, 0.2)
	# Four-leaf clover
	_circle(img, 24, 20, 10, green)
	_circle(img, 40, 20, 10, green)
	_circle(img, 24, 36, 10, green)
	_circle(img, 40, 36, 10, green)
	# Leaf highlights
	_circle(img, 22, 18, 4, green_lt)
	_circle(img, 38, 18, 4, green_lt)
	_circle(img, 22, 34, 4, green_lt)
	_circle(img, 38, 34, 4, green_lt)
	# Center
	_circle(img, 32, 28, 4, green_dk)
	# Stem
	_fill(img, 31, 40, 3, 18, green_dk)
	_fill(img, 30, 42, 2, 14, green)
	# Sparkles
	_px(img, 10, 12, gold)
	_px(img, 52, 10, gold)
	_px(img, 8, 44, gold)
	_px(img, 54, 42, gold)
	_outline(img, Color(0.04, 0.2, 0.06))
	_save_u(img, "luck.png")

func _gen_revive() -> void:
	var img = _img()
	var gold = Color(0.85, 0.75, 0.2)
	var gold_lt = Color(0.95, 0.9, 0.4)
	var white = Color(0.95, 0.95, 0.92)
	var glow = Color(0.9, 0.8, 0.3, 0.2)
	_circle(img, 32, 32, 26, glow)
	# Angel wings (left)
	_fill(img, 4, 22, 10, 4, white)
	_fill(img, 6, 18, 8, 4, white)
	_fill(img, 10, 14, 8, 6, white)
	_fill(img, 14, 20, 6, 10, white)
	_fill(img, 12, 26, 8, 6, white)
	# Angel wings (right)
	_fill(img, 50, 22, 10, 4, white)
	_fill(img, 50, 18, 8, 4, white)
	_fill(img, 46, 14, 8, 6, white)
	_fill(img, 44, 20, 6, 10, white)
	_fill(img, 44, 26, 8, 6, white)
	# Halo
	_circle(img, 32, 14, 8, gold)
	_circle(img, 32, 14, 5, Color(0, 0, 0, 0))
	_circle(img, 32, 14, 6, gold_lt)
	_circle(img, 32, 14, 5, Color(0, 0, 0, 0))
	# Cross/ankh body
	_fill(img, 30, 22, 4, 26, gold)
	_fill(img, 22, 30, 20, 4, gold)
	_fill(img, 31, 24, 2, 22, gold_lt)
	_fill(img, 24, 31, 16, 2, gold_lt)
	_outline(img, Color(0.28, 0.22, 0.05))
	_save_u(img, "revive.png")

func _gen_weapon_slots() -> void:
	var img = _img()
	var metal = Color(0.5, 0.5, 0.55)
	var metal_dk = Color(0.3, 0.3, 0.35)
	var metal_lt = Color(0.65, 0.65, 0.7)
	var gold = Color(0.8, 0.68, 0.15)
	var empty = Color(0.12, 0.12, 0.18)
	# 2x2 grid of weapon slots
	for gx in range(2):
		for gy in range(2):
			var sx = 6 + gx * 28
			var sy = 6 + gy * 28
			_fill(img, sx, sy, 24, 24, metal)
			_fill(img, sx + 2, sy + 2, 20, 20, empty)
			_fill(img, sx, sy, 24, 2, metal_lt)
			_fill(img, sx, sy + 22, 24, 2, metal_dk)
	# Weapon silhouettes inside
	# Slot 1: sword
	_fill(img, 16, 10, 2, 14, metal_lt)
	# Slot 2: bow
	_fill(img, 42, 12, 2, 10, metal_lt)
	_fill(img, 40, 14, 2, 6, metal_lt)
	# Slot 3: orb
	_circle(img, 18, 40, 4, metal_lt)
	# Slot 4: plus (new slot!)
	_fill(img, 42, 38, 8, 2, gold)
	_fill(img, 45, 35, 2, 8, gold)
	_outline(img, Color(0.15, 0.15, 0.2))
	_save_u(img, "weapon_slots.png")

func _gen_reroll_shop() -> void:
	var img = _img()
	var green = Color(0.2, 0.7, 0.3)
	var green_lt = Color(0.35, 0.85, 0.45)
	var white = Color(0.9, 0.9, 0.88)
	var arrow = Color(0.85, 0.75, 0.2)
	# Dice
	_fill(img, 16, 16, 26, 26, white)
	_fill(img, 18, 14, 22, 4, Color(0.85, 0.85, 0.82))
	_fill(img, 18, 40, 22, 4, Color(0.75, 0.75, 0.72))
	# Dots (showing different face = reroll concept)
	_circle(img, 24, 24, 2, Color(0.15, 0.15, 0.18))
	_circle(img, 34, 34, 2, Color(0.15, 0.15, 0.18))
	_circle(img, 24, 34, 2, Color(0.15, 0.15, 0.18))
	# Circular arrow (refresh)
	_fill(img, 42, 8, 14, 4, arrow)
	_fill(img, 52, 12, 4, 14, arrow)
	_fill(img, 42, 26, 14, 4, arrow)
	_fill(img, 42, 12, 4, 14, arrow)
	# Arrow head
	_fill(img, 54, 6, 4, 6, arrow)
	_fill(img, 56, 8, 4, 4, arrow)
	_outline(img, Color(0.06, 0.22, 0.08))
	_save_u(img, "reroll_shop.png")

func _gen_banish_shop() -> void:
	var img = _img()
	var red = Color(0.8, 0.15, 0.12)
	var red_dk = Color(0.55, 0.08, 0.06)
	var white = Color(0.9, 0.9, 0.88)
	# Circle with X (banish)
	_circle(img, 32, 32, 22, red)
	_circle(img, 32, 32, 18, red_dk)
	_circle(img, 32, 32, 16, Color(0.15, 0.05, 0.05))
	# X mark
	for i in range(24):
		_fill(img, 16 + i, 18 + i, 4, 4, white)
		_fill(img, 44 - i, 18 + i, 4, 4, white)
	# Inner glow
	_circle(img, 32, 32, 8, Color(0.4, 0.08, 0.06))
	_outline(img, Color(0.25, 0.05, 0.04))
	_save_u(img, "banish_shop.png")
