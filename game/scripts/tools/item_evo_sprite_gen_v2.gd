extends SceneTree

## Generates 64x64 pixel art sprites for 19 items + 12 evolutions.
## Replaces tiny 16x16 stubs with detailed pixel art.
## Run: godot --headless --path game --script res://scripts/tools/item_evo_sprite_gen_v2.gd

const S := 64
const ITEMS_DIR := "res://assets/sprites/items/"
const EVO_DIR := "res://assets/sprites/evolutions/"

func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ITEMS_DIR)
	DirAccess.make_dir_recursive_absolute(EVO_DIR)
	# Items (19)
	_gen_boots()
	_gen_cape()
	_gen_clock()
	_gen_crown()
	_gen_crystal()
	_gen_gasoline()
	_gen_giant_elixir()
	_gen_glove()
	_gen_grimoire()
	_gen_gunpowder()
	_gen_heart()
	_gen_laser_sight()
	_gen_lucky_coin()
	_gen_magnet()
	_gen_quiver()
	_gen_tesla()
	_gen_thorn_shield()
	_gen_vampire_blood()
	_gen_xp_amulet()
	# Evolutions (12)
	_gen_apocalypse_staff()
	_gen_arrow_storm()
	_gen_blizzard_star()
	_gen_death_scythe()
	_gen_electric_storm()
	_gen_inferno_walker()
	_gen_lord_of_dead()
	_gen_minigun_infernal()
	_gen_nuke_launcher()
	_gen_ragnarok_axe()
	_gen_vampire_whip()
	_gen_zangetsu()
	print("Generated 19 item + 12 evolution sprites at 64x64!")
	quit()

# ==================== HELPERS ====================
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

func _save_item(img: Image, name: String) -> void:
	img.save_png(ITEMS_DIR + name)
	print("Saved: %s%s" % [ITEMS_DIR, name])

func _save_evo(img: Image, name: String) -> void:
	img.save_png(EVO_DIR + name)
	print("Saved: %s%s" % [EVO_DIR, name])

# ==================== ITEMS ====================

func _gen_boots() -> void:
	var img = _img()
	var leather = Color(0.5, 0.32, 0.15)
	var leather_dk = Color(0.35, 0.2, 0.08)
	var leather_lt = Color(0.62, 0.42, 0.22)
	var sole = Color(0.25, 0.18, 0.1)
	var buckle = Color(0.75, 0.65, 0.2)
	var ol = Color(0.18, 0.1, 0.04)
	# Left boot
	_fill(img, 6, 18, 18, 28, leather)
	_fill(img, 8, 16, 14, 4, leather)
	_fill(img, 4, 42, 22, 8, leather_dk)
	_fill(img, 2, 46, 26, 6, sole)
	_fill(img, 10, 20, 10, 6, leather_lt)
	_fill(img, 6, 32, 18, 3, buckle)
	_px(img, 14, 33, Color(0.9, 0.8, 0.3))
	# Right boot
	_fill(img, 34, 18, 18, 28, leather)
	_fill(img, 36, 16, 14, 4, leather)
	_fill(img, 32, 42, 22, 8, leather_dk)
	_fill(img, 30, 46, 26, 6, sole)
	_fill(img, 38, 20, 10, 6, leather_lt)
	_fill(img, 34, 32, 18, 3, buckle)
	_px(img, 42, 33, Color(0.9, 0.8, 0.3))
	# Speed lines
	_line_h(img, 56, 62, 36, Color(0.8, 0.8, 0.3, 0.5))
	_line_h(img, 58, 63, 40, Color(0.8, 0.8, 0.3, 0.4))
	_outline(img, ol)
	_save_item(img, "boots.png")

func _gen_cape() -> void:
	var img = _img()
	var fabric = Color(0.2, 0.25, 0.6)
	var fabric_dk = Color(0.12, 0.15, 0.42)
	var fabric_lt = Color(0.3, 0.38, 0.72)
	var clasp = Color(0.8, 0.7, 0.2)
	var ol = Color(0.06, 0.08, 0.2)
	_fill(img, 20, 4, 24, 6, fabric)
	_fill(img, 18, 10, 28, 10, fabric)
	_fill(img, 14, 20, 36, 10, fabric_dk)
	_fill(img, 10, 30, 44, 10, fabric)
	_fill(img, 8, 40, 48, 10, fabric_dk)
	_fill(img, 6, 50, 52, 8, fabric)
	_fill(img, 22, 12, 20, 4, fabric_lt)
	_fill(img, 16, 24, 8, 12, fabric_lt)
	_fill(img, 40, 28, 8, 10, fabric_lt)
	# Tattered bottom
	for i in range(8):
		_fill(img, 6 + i * 7, 56 + (i % 2) * 2, 4, 4 - (i % 2), fabric_dk)
	# Clasp
	_circle(img, 32, 6, 4, clasp)
	_circle(img, 32, 6, 2, Color(0.9, 0.8, 0.3))
	_outline(img, ol)
	_save_item(img, "cape.png")

func _gen_clock() -> void:
	var img = _img()
	var gold = Color(0.8, 0.65, 0.15)
	var gold_dk = Color(0.6, 0.48, 0.08)
	var face = Color(0.92, 0.9, 0.82)
	var hand = Color(0.15, 0.12, 0.1)
	var ol = Color(0.3, 0.22, 0.05)
	# Pocket watch body
	_circle(img, 32, 34, 22, gold)
	_circle(img, 32, 34, 20, gold_dk)
	_circle(img, 32, 34, 18, face)
	_circle(img, 32, 34, 17, Color(0.95, 0.93, 0.88))
	# Clock hands
	_line_v(img, 32, 20, 34, hand)
	_line_h(img, 32, 42, 34, hand)
	_circle(img, 32, 34, 2, hand)
	# Hour marks
	for i in range(12):
		var angle = i * PI / 6.0
		var mx = int(32 + cos(angle) * 15)
		var my = int(34 + sin(angle) * 15)
		_px(img, mx, my, gold_dk)
	# Chain
	_fill(img, 30, 8, 4, 6, gold)
	_circle(img, 32, 6, 3, gold)
	_circle(img, 32, 6, 1, gold_dk)
	# Crown/knob
	_fill(img, 30, 12, 4, 3, gold_dk)
	_outline(img, ol)
	_save_item(img, "clock.png")

func _gen_crown() -> void:
	var img = _img()
	var gold = Color(0.85, 0.72, 0.18)
	var gold_dk = Color(0.65, 0.52, 0.1)
	var gold_lt = Color(0.95, 0.85, 0.3)
	var gem_r = Color(0.85, 0.15, 0.15)
	var gem_b = Color(0.2, 0.3, 0.85)
	var gem_g = Color(0.15, 0.7, 0.2)
	var velvet = Color(0.55, 0.1, 0.15)
	var ol = Color(0.3, 0.22, 0.05)
	# Crown base band
	_fill(img, 10, 36, 44, 10, gold)
	_fill(img, 12, 34, 40, 4, gold)
	_fill(img, 14, 38, 36, 4, gold_dk)
	# Crown points (5)
	_fill(img, 12, 20, 8, 16, gold)
	_fill(img, 14, 14, 4, 8, gold)
	_fill(img, 15, 10, 2, 5, gold_lt)
	_fill(img, 22, 22, 8, 14, gold)
	_fill(img, 24, 16, 4, 8, gold)
	_fill(img, 25, 12, 2, 5, gold_lt)
	_fill(img, 28, 18, 8, 18, gold)
	_fill(img, 30, 8, 4, 12, gold)
	_fill(img, 31, 4, 2, 5, gold_lt)
	_fill(img, 34, 22, 8, 14, gold)
	_fill(img, 36, 16, 4, 8, gold)
	_fill(img, 37, 12, 2, 5, gold_lt)
	_fill(img, 44, 20, 8, 16, gold)
	_fill(img, 46, 14, 4, 8, gold)
	_fill(img, 47, 10, 2, 5, gold_lt)
	# Gems
	_circle(img, 16, 12, 2, gem_r)
	_circle(img, 26, 14, 2, gem_b)
	_circle(img, 32, 6, 3, gem_r)
	_px(img, 32, 5, Color(1.0, 0.4, 0.4))
	_circle(img, 38, 14, 2, gem_g)
	_circle(img, 48, 12, 2, gem_b)
	# Velvet interior
	_fill(img, 14, 44, 36, 8, velvet)
	_fill(img, 16, 42, 32, 4, velvet)
	_outline(img, ol)
	_save_item(img, "crown.png")

func _gen_crystal() -> void:
	var img = _img()
	var cyan = Color(0.3, 0.8, 0.9)
	var cyan_dk = Color(0.15, 0.55, 0.65)
	var cyan_lt = Color(0.5, 0.92, 1.0)
	var white = Color(0.9, 0.95, 1.0)
	var glow = Color(0.3, 0.7, 0.9, 0.25)
	var ol = Color(0.08, 0.25, 0.3)
	_circle(img, 32, 32, 20, glow)
	# Main crystal (hexagonal)
	_fill(img, 26, 10, 12, 40, cyan)
	_fill(img, 24, 14, 16, 32, cyan)
	_fill(img, 22, 18, 20, 24, cyan_dk)
	# Facets
	_fill(img, 28, 12, 4, 14, cyan_lt)
	_fill(img, 34, 16, 4, 20, cyan_dk)
	_fill(img, 24, 28, 4, 12, cyan_dk)
	# Top point
	_fill(img, 28, 6, 8, 6, cyan)
	_fill(img, 30, 2, 4, 5, cyan_lt)
	_fill(img, 31, 0, 2, 3, white)
	# Bottom point
	_fill(img, 28, 48, 8, 6, cyan_dk)
	_fill(img, 30, 52, 4, 5, cyan)
	_fill(img, 31, 56, 2, 3, cyan_dk)
	# Sparkle
	_px(img, 29, 8, white)
	_px(img, 26, 22, white)
	_outline(img, ol)
	_save_item(img, "crystal.png")

func _gen_gasoline() -> void:
	var img = _img()
	var can = Color(0.7, 0.15, 0.1)
	var can_dk = Color(0.5, 0.08, 0.06)
	var can_lt = Color(0.85, 0.25, 0.15)
	var metal = Color(0.6, 0.58, 0.52)
	var label = Color(0.85, 0.75, 0.2)
	var ol = Color(0.25, 0.06, 0.04)
	# Can body
	_fill(img, 14, 16, 32, 36, can)
	_fill(img, 16, 14, 28, 4, can)
	_fill(img, 16, 50, 28, 4, can_dk)
	_fill(img, 18, 18, 6, 30, can_lt)
	_fill(img, 38, 20, 6, 26, can_dk)
	# Handle on top
	_fill(img, 22, 8, 16, 4, metal)
	_fill(img, 20, 10, 4, 6, metal)
	_fill(img, 36, 10, 4, 6, metal)
	_fill(img, 22, 6, 16, 2, Color(0.5, 0.48, 0.42))
	# Spout
	_fill(img, 40, 6, 6, 12, metal)
	_fill(img, 42, 4, 4, 4, metal)
	_fill(img, 44, 2, 3, 3, Color(0.5, 0.48, 0.42))
	# Label
	_fill(img, 20, 28, 20, 12, label)
	_fill(img, 22, 30, 16, 8, Color(0.9, 0.82, 0.3))
	# Fire icon on label
	_fill(img, 28, 31, 4, 5, Color(1.0, 0.5, 0.1))
	_fill(img, 29, 29, 2, 3, Color(1.0, 0.7, 0.2))
	_outline(img, ol)
	_save_item(img, "gasoline.png")

func _gen_giant_elixir() -> void:
	var img = _img()
	var glass = Color(0.4, 0.2, 0.6, 0.8)
	var glass_lt = Color(0.55, 0.35, 0.75, 0.7)
	var liquid = Color(0.6, 0.15, 0.7)
	var liquid_br = Color(0.8, 0.3, 0.9)
	var cork = Color(0.55, 0.4, 0.2)
	var ol = Color(0.18, 0.08, 0.25)
	# Bottle body (round potion)
	_circle(img, 32, 38, 16, glass)
	_circle(img, 32, 36, 14, glass)
	_circle(img, 32, 40, 13, liquid)
	_circle(img, 32, 38, 10, liquid_br)
	_fill(img, 20, 38, 24, 14, liquid)
	# Neck
	_fill(img, 28, 16, 8, 14, glass)
	_fill(img, 30, 14, 4, 4, glass)
	_fill(img, 29, 18, 2, 8, glass_lt)
	# Cork
	_fill(img, 28, 10, 8, 6, cork)
	_fill(img, 30, 8, 4, 4, cork)
	# Size-up arrows
	_fill(img, 8, 28, 4, 12, Color(0.9, 0.8, 0.2, 0.6))
	_fill(img, 6, 28, 8, 3, Color(0.9, 0.8, 0.2, 0.6))
	_fill(img, 52, 28, 4, 12, Color(0.9, 0.8, 0.2, 0.6))
	_fill(img, 50, 28, 8, 3, Color(0.9, 0.8, 0.2, 0.6))
	# Sparkles
	_px(img, 24, 34, Color.WHITE)
	_px(img, 38, 42, Color(0.9, 0.7, 1.0))
	_outline(img, ol)
	_save_item(img, "giant_elixir.png")

func _gen_glove() -> void:
	var img = _img()
	var leather = Color(0.55, 0.2, 0.15)
	var leather_dk = Color(0.38, 0.12, 0.08)
	var leather_lt = Color(0.68, 0.3, 0.22)
	var metal = Color(0.6, 0.58, 0.52)
	var ol = Color(0.2, 0.08, 0.05)
	# Palm
	_fill(img, 16, 24, 28, 24, leather)
	_fill(img, 18, 22, 24, 4, leather)
	_fill(img, 20, 26, 20, 8, leather_lt)
	# Fingers
	_fill(img, 14, 10, 6, 16, leather)
	_fill(img, 22, 8, 6, 18, leather)
	_fill(img, 30, 6, 6, 20, leather)
	_fill(img, 38, 10, 6, 16, leather)
	_fill(img, 15, 8, 4, 4, leather_lt)
	_fill(img, 23, 6, 4, 4, leather_lt)
	_fill(img, 31, 4, 4, 4, leather_lt)
	_fill(img, 39, 8, 4, 4, leather_lt)
	# Thumb
	_fill(img, 8, 28, 8, 6, leather)
	_fill(img, 4, 26, 6, 6, leather)
	_fill(img, 2, 24, 4, 6, leather_dk)
	# Metal studs on knuckles
	_circle(img, 17, 22, 2, metal)
	_circle(img, 25, 20, 2, metal)
	_circle(img, 33, 20, 2, metal)
	_circle(img, 41, 22, 2, metal)
	# Wrist
	_fill(img, 18, 48, 24, 8, leather_dk)
	_fill(img, 20, 50, 20, 4, leather)
	_outline(img, ol)
	_save_item(img, "glove.png")

func _gen_grimoire() -> void:
	var img = _img()
	var cover = Color(0.35, 0.12, 0.42)
	var cover_dk = Color(0.22, 0.06, 0.28)
	var pages = Color(0.88, 0.85, 0.75)
	var pages_dk = Color(0.72, 0.68, 0.58)
	var gold = Color(0.82, 0.7, 0.18)
	var gem = Color(0.3, 0.8, 0.4)
	var ol = Color(0.12, 0.04, 0.15)
	# Back cover
	_fill(img, 12, 8, 38, 48, cover_dk)
	# Pages (side visible)
	_fill(img, 14, 10, 34, 44, pages)
	_fill(img, 50, 12, 2, 40, pages_dk)
	# Front cover
	_fill(img, 10, 6, 38, 48, cover)
	_fill(img, 12, 8, 34, 44, cover)
	# Spine
	_fill(img, 10, 6, 4, 48, cover_dk)
	# Gold trim
	_fill(img, 14, 8, 30, 2, gold)
	_fill(img, 14, 50, 30, 2, gold)
	_fill(img, 14, 8, 2, 44, gold)
	_fill(img, 42, 8, 2, 44, gold)
	# Central emblem
	_circle(img, 30, 30, 8, gold)
	_circle(img, 30, 30, 6, cover_dk)
	_circle(img, 30, 30, 4, gem)
	_px(img, 29, 28, Color(0.5, 1.0, 0.6))
	# Corner ornaments
	_fill(img, 16, 10, 3, 3, gold)
	_fill(img, 39, 10, 3, 3, gold)
	_fill(img, 16, 47, 3, 3, gold)
	_fill(img, 39, 47, 3, 3, gold)
	_outline(img, ol)
	_save_item(img, "grimoire.png")

func _gen_gunpowder() -> void:
	var img = _img()
	var barrel = Color(0.4, 0.28, 0.15)
	var barrel_dk = Color(0.28, 0.18, 0.08)
	var barrel_lt = Color(0.52, 0.38, 0.22)
	var band = Color(0.5, 0.48, 0.42)
	var powder = Color(0.2, 0.2, 0.22)
	var ol = Color(0.15, 0.1, 0.05)
	# Barrel body
	_fill(img, 14, 14, 36, 36, barrel)
	_fill(img, 16, 12, 32, 4, barrel)
	_fill(img, 16, 48, 32, 4, barrel_dk)
	_fill(img, 12, 18, 4, 28, barrel_dk)
	_fill(img, 48, 18, 4, 28, barrel_dk)
	_fill(img, 18, 16, 8, 30, barrel_lt)
	# Metal bands
	_fill(img, 12, 20, 40, 3, band)
	_fill(img, 12, 40, 40, 3, band)
	# Powder visible on top
	_circle(img, 32, 14, 10, powder)
	_circle(img, 32, 12, 8, Color(0.25, 0.25, 0.28))
	# Fuse
	_fill(img, 30, 4, 3, 10, Color(0.6, 0.5, 0.3))
	_px(img, 31, 2, Color(1.0, 0.6, 0.1))
	_px(img, 30, 3, Color(1.0, 0.8, 0.3))
	_outline(img, ol)
	_save_item(img, "gunpowder.png")

func _gen_heart() -> void:
	var img = _img()
	var red = Color(0.85, 0.12, 0.18)
	var red_dk = Color(0.6, 0.06, 0.1)
	var red_lt = Color(0.95, 0.25, 0.3)
	var pink = Color(1.0, 0.5, 0.55)
	var ol = Color(0.3, 0.04, 0.06)
	# Heart shape (two circles + triangle)
	_circle(img, 22, 20, 12, red)
	_circle(img, 42, 20, 12, red)
	# Fill gap between circles
	_fill(img, 22, 20, 20, 12, red)
	# Bottom point
	for i in range(20):
		var w = 20 - i
		_fill(img, 32 - w / 2, 30 + i, w, 1, red)
	# Highlight
	_circle(img, 20, 16, 5, red_lt)
	_circle(img, 18, 14, 3, pink)
	_px(img, 17, 13, Color.WHITE)
	# Depth shadow
	_circle(img, 40, 24, 6, red_dk)
	_fill(img, 30, 38, 6, 6, red_dk)
	_outline(img, ol)
	_save_item(img, "heart.png")

func _gen_laser_sight() -> void:
	var img = _img()
	var body = Color(0.3, 0.3, 0.35)
	var body_dk = Color(0.18, 0.18, 0.22)
	var body_lt = Color(0.45, 0.45, 0.5)
	var red = Color(0.9, 0.1, 0.08)
	var red_br = Color(1.0, 0.3, 0.2)
	var lens = Color(0.7, 0.15, 0.12)
	var ol = Color(0.1, 0.1, 0.12)
	# Cylindrical body (horizontal)
	_fill(img, 10, 24, 36, 14, body)
	_fill(img, 12, 22, 32, 2, body_dk)
	_fill(img, 12, 38, 32, 2, body_dk)
	_fill(img, 14, 26, 28, 4, body_lt)
	# Lens end
	_fill(img, 46, 22, 8, 18, body_dk)
	_circle(img, 50, 31, 6, lens)
	_circle(img, 50, 31, 3, red)
	_circle(img, 50, 31, 1, red_br)
	# Mount
	_fill(img, 8, 22, 6, 18, body_dk)
	_fill(img, 6, 26, 4, 10, body)
	# Laser beam
	for i in range(10):
		_px(img, 56 + i, 31, Color(1.0, 0.1, 0.05, 0.8 - i * 0.07))
	# Power button
	_fill(img, 22, 22, 4, 2, Color(0.2, 0.7, 0.2))
	# Rail grooves
	_fill(img, 6, 38, 40, 3, body_dk)
	_outline(img, ol)
	_save_item(img, "laser_sight.png")

func _gen_lucky_coin() -> void:
	var img = _img()
	var gold = Color(0.85, 0.72, 0.18)
	var gold_dk = Color(0.65, 0.52, 0.1)
	var gold_lt = Color(0.95, 0.85, 0.3)
	var face = Color(0.75, 0.62, 0.15)
	var ol = Color(0.3, 0.22, 0.05)
	# Coin body
	_circle(img, 32, 32, 22, gold)
	_circle(img, 32, 32, 20, gold_dk)
	_circle(img, 32, 32, 18, gold)
	# Inner ring
	_circle(img, 32, 32, 15, face)
	# Clover/star symbol
	_circle(img, 32, 26, 4, gold_lt)
	_circle(img, 26, 32, 4, gold_lt)
	_circle(img, 38, 32, 4, gold_lt)
	_circle(img, 32, 38, 4, gold_lt)
	_circle(img, 32, 32, 3, gold_lt)
	# Shine
	_circle(img, 24, 22, 3, Color(1.0, 0.95, 0.6))
	_px(img, 22, 20, Color.WHITE)
	# Edge serrations
	for i in range(16):
		var angle = i * PI / 8.0
		var ex = int(32 + cos(angle) * 21)
		var ey = int(32 + sin(angle) * 21)
		_px(img, ex, ey, gold_lt)
	_outline(img, ol)
	_save_item(img, "lucky_coin.png")

func _gen_magnet() -> void:
	var img = _img()
	var red = Color(0.8, 0.15, 0.12)
	var red_dk = Color(0.6, 0.08, 0.06)
	var blue = Color(0.15, 0.2, 0.7)
	var blue_dk = Color(0.08, 0.12, 0.5)
	var metal = Color(0.7, 0.68, 0.62)
	var ol = Color(0.25, 0.06, 0.05)
	# U-shape magnet
	# Left arm (red)
	_fill(img, 10, 8, 12, 36, red)
	_fill(img, 12, 6, 8, 4, red)
	_fill(img, 14, 10, 6, 30, red_dk)
	# Right arm (blue)
	_fill(img, 42, 8, 12, 36, blue)
	_fill(img, 44, 6, 8, 4, blue)
	_fill(img, 44, 10, 6, 30, blue_dk)
	# Bottom curve (connecting)
	_fill(img, 10, 42, 44, 12, Color(0.5, 0.15, 0.4))
	_fill(img, 14, 48, 36, 6, Color(0.45, 0.12, 0.35))
	_fill(img, 22, 42, 20, 6, Color(0, 0, 0, 0))  # hollow center
	# Metal tips
	_fill(img, 10, 6, 12, 6, metal)
	_fill(img, 42, 6, 12, 6, metal)
	# Magnetic field lines
	_px(img, 26, 14, Color(0.5, 0.5, 0.8, 0.4))
	_px(img, 32, 10, Color(0.5, 0.5, 0.8, 0.4))
	_px(img, 38, 14, Color(0.5, 0.5, 0.8, 0.4))
	_outline(img, ol)
	_save_item(img, "magnet.png")

func _gen_quiver() -> void:
	var img = _img()
	var leather = Color(0.5, 0.32, 0.15)
	var leather_dk = Color(0.35, 0.2, 0.08)
	var leather_lt = Color(0.62, 0.42, 0.22)
	var arrow_s = Color(0.55, 0.45, 0.3)
	var feather = Color(0.8, 0.2, 0.15)
	var metal = Color(0.6, 0.58, 0.52)
	var ol = Color(0.18, 0.1, 0.04)
	# Quiver body
	_fill(img, 20, 14, 20, 40, leather)
	_fill(img, 22, 12, 16, 4, leather)
	_fill(img, 18, 18, 24, 4, leather_dk)
	_fill(img, 22, 50, 16, 6, leather_dk)
	_fill(img, 24, 16, 6, 34, leather_lt)
	# Strap
	_fill(img, 10, 8, 4, 48, leather_dk)
	_fill(img, 8, 10, 4, 44, leather)
	# Belt buckle
	_fill(img, 18, 22, 24, 3, Color(0.7, 0.6, 0.2))
	# Arrows sticking out
	for i in range(4):
		var x = 24 + i * 4
		_line_v(img, x, 2, 16, arrow_s)
		_px(img, x, 2, metal)
		_px(img, x - 1, 4, feather)
		_px(img, x + 1, 4, feather)
	_outline(img, ol)
	_save_item(img, "quiver.png")

func _gen_tesla() -> void:
	var img = _img()
	var coil = Color(0.55, 0.35, 0.18)
	var coil_dk = Color(0.38, 0.22, 0.1)
	var metal = Color(0.5, 0.5, 0.55)
	var metal_dk = Color(0.35, 0.35, 0.4)
	var electric = Color(1.0, 0.9, 0.2)
	var electric_br = Color(1.0, 1.0, 0.5)
	var blue = Color(0.3, 0.5, 1.0)
	var ol = Color(0.2, 0.12, 0.06)
	# Base
	_fill(img, 16, 48, 32, 8, metal)
	_fill(img, 18, 46, 28, 4, metal_dk)
	_fill(img, 20, 50, 24, 4, metal)
	# Coil body (tapered)
	_fill(img, 24, 22, 16, 26, coil)
	_fill(img, 22, 26, 20, 18, coil)
	# Coil winding lines
	for i in range(8):
		_line_h(img, 22, 42, 26 + i * 3, coil_dk)
	# Top sphere
	_circle(img, 32, 16, 10, metal)
	_circle(img, 32, 14, 8, metal_dk)
	_circle(img, 32, 12, 5, Color(0.6, 0.6, 0.65))
	# Lightning bolts
	_px(img, 18, 10, electric)
	_px(img, 16, 12, electric)
	_px(img, 18, 14, electric_br)
	_px(img, 46, 8, electric)
	_px(img, 48, 10, electric)
	_px(img, 46, 12, electric_br)
	_px(img, 12, 18, blue)
	_px(img, 52, 16, blue)
	# Glow
	_circle(img, 32, 14, 12, Color(0.3, 0.5, 1.0, 0.15))
	_outline(img, ol)
	_save_item(img, "tesla.png")

func _gen_thorn_shield() -> void:
	var img = _img()
	var wood = Color(0.45, 0.3, 0.15)
	var wood_dk = Color(0.3, 0.2, 0.08)
	var wood_lt = Color(0.58, 0.4, 0.22)
	var thorn = Color(0.25, 0.5, 0.15)
	var thorn_dk = Color(0.15, 0.35, 0.08)
	var metal = Color(0.55, 0.52, 0.45)
	var ol = Color(0.15, 0.1, 0.04)
	# Shield body (kite shape)
	_fill(img, 18, 8, 28, 10, wood)
	_fill(img, 14, 14, 36, 12, wood)
	_fill(img, 16, 26, 32, 10, wood)
	_fill(img, 20, 36, 24, 8, wood_dk)
	_fill(img, 24, 44, 16, 6, wood_dk)
	_fill(img, 28, 50, 8, 4, wood)
	# Cross metal band
	_line_v(img, 32, 8, 52, metal)
	_line_v(img, 33, 8, 52, metal)
	_line_h(img, 16, 48, 22, metal)
	_line_h(img, 16, 48, 23, metal)
	# Wood highlights
	_fill(img, 20, 14, 6, 10, wood_lt)
	_fill(img, 36, 18, 6, 8, wood_lt)
	# Thorns (green vines with spikes)
	_fill(img, 10, 18, 6, 3, thorn)
	_px(img, 8, 17, thorn_dk)
	_fill(img, 48, 18, 6, 3, thorn)
	_px(img, 54, 17, thorn_dk)
	_fill(img, 12, 30, 5, 3, thorn)
	_px(img, 10, 29, thorn_dk)
	_fill(img, 46, 28, 5, 3, thorn)
	_px(img, 52, 27, thorn_dk)
	# Boss/center emblem
	_circle(img, 32, 22, 4, metal)
	_circle(img, 32, 22, 2, Color(0.3, 0.6, 0.2))
	_outline(img, ol)
	_save_item(img, "thorn_shield.png")

func _gen_vampire_blood() -> void:
	var img = _img()
	var glass = Color(0.5, 0.15, 0.15, 0.8)
	var blood = Color(0.7, 0.05, 0.05)
	var blood_dk = Color(0.5, 0.02, 0.02)
	var blood_br = Color(0.9, 0.15, 0.1)
	var cork = Color(0.55, 0.4, 0.2)
	var ol = Color(0.25, 0.04, 0.04)
	# Vial body (tall, narrow)
	_fill(img, 22, 14, 20, 36, glass)
	_fill(img, 24, 12, 16, 4, glass)
	_fill(img, 20, 18, 24, 28, glass)
	# Blood inside
	_fill(img, 24, 24, 16, 24, blood)
	_fill(img, 22, 28, 20, 18, blood)
	_fill(img, 26, 26, 8, 4, blood_br)
	# Neck
	_fill(img, 26, 8, 12, 6, glass)
	_fill(img, 28, 6, 8, 4, glass)
	# Cork
	_fill(img, 27, 4, 10, 5, cork)
	_fill(img, 29, 2, 6, 3, cork)
	# Drip
	_fill(img, 40, 38, 3, 6, blood)
	_px(img, 41, 44, blood_dk)
	# Bat emblem
	_fill(img, 28, 30, 8, 3, Color(0.2, 0.02, 0.02))
	_fill(img, 24, 31, 4, 2, Color(0.2, 0.02, 0.02))
	_fill(img, 36, 31, 4, 2, Color(0.2, 0.02, 0.02))
	_outline(img, ol)
	_save_item(img, "vampire_blood.png")

func _gen_xp_amulet() -> void:
	var img = _img()
	var gold = Color(0.82, 0.68, 0.15)
	var gold_dk = Color(0.6, 0.48, 0.08)
	var gold_lt = Color(0.95, 0.82, 0.28)
	var gem = Color(0.2, 0.5, 0.9)
	var gem_br = Color(0.4, 0.7, 1.0)
	var chain = Color(0.7, 0.6, 0.2)
	var ol = Color(0.28, 0.2, 0.05)
	# Chain (V-shape)
	for i in range(12):
		_px(img, 20 - i, 4 + i, chain)
		_px(img, 44 + i, 4 + i, chain)
	_line_h(img, 20, 44, 4, chain)
	# Amulet body
	_circle(img, 32, 36, 16, gold)
	_circle(img, 32, 36, 14, gold_dk)
	_circle(img, 32, 36, 12, gold)
	# Inner design
	_circle(img, 32, 36, 8, gold_dk)
	_circle(img, 32, 36, 6, gem)
	_circle(img, 32, 36, 3, gem_br)
	_px(img, 30, 34, Color.WHITE)
	# XP text
	_fill(img, 28, 34, 2, 4, gold_lt)
	_fill(img, 32, 34, 2, 4, gold_lt)
	_px(img, 30, 35, gold_lt)
	_px(img, 30, 37, gold_lt)
	_px(img, 34, 35, gold_lt)
	# Bail/loop at top
	_circle(img, 32, 20, 4, gold)
	_circle(img, 32, 20, 2, Color(0, 0, 0, 0))
	_outline(img, ol)
	_save_item(img, "xp_amulet.png")

# ==================== EVOLUTIONS ====================

func _gen_apocalypse_staff() -> void:
	var img = _img()
	var dark = Color(0.25, 0.1, 0.35)
	var dark_dk = Color(0.15, 0.05, 0.22)
	var fire = Color(1.0, 0.4, 0.1)
	var fire_br = Color(1.0, 0.7, 0.2)
	var skull = Color(0.82, 0.78, 0.68)
	var ol = Color(0.1, 0.04, 0.15)
	_fill(img, 29, 14, 6, 46, dark)
	_fill(img, 28, 16, 1, 42, dark_dk)
	_fill(img, 31, 16, 2, 42, Color(0.35, 0.15, 0.45))
	# Skull on top
	_fill(img, 22, 4, 20, 12, skull)
	_fill(img, 24, 2, 16, 4, skull)
	_fill(img, 25, 6, 4, 4, Color(0.1, 0.02, 0.02))
	_fill(img, 35, 6, 4, 4, Color(0.1, 0.02, 0.02))
	_fill(img, 26, 7, 2, 2, fire)
	_fill(img, 36, 7, 2, 2, fire)
	_fill(img, 28, 12, 8, 2, skull)
	# Fire crown
	_fill(img, 20, 0, 4, 5, fire)
	_fill(img, 26, 0, 3, 3, fire_br)
	_fill(img, 34, 0, 3, 3, fire_br)
	_fill(img, 40, 0, 4, 5, fire)
	_circle(img, 32, 2, 3, fire)
	_px(img, 32, 0, fire_br)
	_fill(img, 27, 30, 10, 3, Color(0.5, 0.2, 0.6))
	_fill(img, 27, 44, 10, 3, Color(0.5, 0.2, 0.6))
	_outline(img, ol)
	_save_evo(img, "apocalypse_staff.png")

func _gen_arrow_storm() -> void:
	var img = _img()
	var shaft = Color(0.55, 0.42, 0.28)
	var head = Color(0.6, 0.62, 0.65)
	var feather = Color(0.2, 0.6, 0.2)
	var glow = Color(0.3, 0.8, 0.4, 0.2)
	var ol = Color(0.18, 0.14, 0.08)
	_circle(img, 32, 32, 24, glow)
	# Multiple arrows raining down
	for data in [[16, 6, 0], [28, 2, -1], [40, 8, 1], [10, 18, -1], [50, 16, 1], [22, 30, 0], [38, 26, 0], [32, 42, 0]]:
		var ax = data[0]
		var ay = data[1]
		var lean = data[2]
		_line_v(img, ax, ay, ay + 16, shaft)
		_line_v(img, ax + lean, ay, ay + 16, shaft)
		_px(img, ax, ay, head)
		_px(img, ax, ay + 1, head)
		_px(img, ax - 1, ay + 14, feather)
		_px(img, ax + 1, ay + 14, feather)
	_outline(img, ol)
	_save_evo(img, "arrow_storm.png")

func _gen_blizzard_star() -> void:
	var img = _img()
	var ice = Color(0.5, 0.8, 1.0)
	var ice_dk = Color(0.3, 0.6, 0.85)
	var ice_br = Color(0.75, 0.92, 1.0)
	var white = Color(0.9, 0.95, 1.0)
	var glow = Color(0.4, 0.7, 1.0, 0.2)
	var ol = Color(0.12, 0.25, 0.35)
	_circle(img, 32, 32, 26, glow)
	# 6-pointed ice star
	_circle(img, 32, 32, 6, ice_br)
	# Vertical spike
	_fill(img, 30, 4, 4, 24, ice)
	_fill(img, 31, 2, 2, 4, ice_br)
	_fill(img, 30, 36, 4, 24, ice)
	_fill(img, 31, 58, 2, 4, ice_dk)
	# Top-right spike
	for i in range(12):
		_fill(img, 34 + i * 2, 20 - i * 2, 3, 3, ice)
	# Top-left spike
	for i in range(12):
		_fill(img, 28 - i * 2, 20 - i * 2, 3, 3, ice)
	# Bottom-right spike
	for i in range(12):
		_fill(img, 34 + i * 2, 42 + i * 2, 3, 3, ice_dk)
	# Bottom-left spike
	for i in range(12):
		_fill(img, 28 - i * 2, 42 + i * 2, 3, 3, ice_dk)
	# Center gem
	_circle(img, 32, 32, 4, white)
	_circle(img, 32, 32, 2, ice_br)
	_px(img, 31, 31, Color.WHITE)
	_outline(img, ol)
	_save_evo(img, "blizzard_star.png")

func _gen_death_scythe() -> void:
	var img = _img()
	var shaft = Color(0.3, 0.2, 0.35)
	var shaft_dk = Color(0.18, 0.1, 0.22)
	var blade = Color(0.65, 0.68, 0.72)
	var blade_lt = Color(0.8, 0.82, 0.85)
	var blade_dk = Color(0.45, 0.48, 0.52)
	var purple = Color(0.5, 0.15, 0.6)
	var ol = Color(0.12, 0.06, 0.15)
	# Shaft (diagonal)
	for i in range(48):
		_fill(img, 8 + i, 56 - i, 3, 3, shaft)
	_fill(img, 10, 54, 2, 2, shaft_dk)
	# Blade (large curved)
	_fill(img, 36, 4, 20, 4, blade)
	_fill(img, 44, 6, 14, 4, blade)
	_fill(img, 50, 8, 10, 4, blade_dk)
	_fill(img, 54, 10, 8, 4, blade_dk)
	_fill(img, 56, 14, 6, 4, blade)
	_fill(img, 56, 18, 4, 4, blade)
	# Blade edge
	_line_h(img, 36, 56, 4, blade_lt)
	_line_h(img, 44, 58, 6, blade_lt)
	# Connection to shaft
	_fill(img, 34, 6, 6, 6, shaft)
	# Purple glow on blade
	_px(img, 42, 5, purple)
	_px(img, 50, 9, purple)
	_px(img, 56, 15, purple)
	# Skull at junction
	_fill(img, 30, 8, 8, 6, Color(0.8, 0.76, 0.66))
	_px(img, 31, 9, Color(0.1, 0.05, 0.12))
	_px(img, 35, 9, Color(0.1, 0.05, 0.12))
	_outline(img, ol)
	_save_evo(img, "death_scythe.png")

func _gen_electric_storm() -> void:
	var img = _img()
	var yellow = Color(1.0, 0.9, 0.2)
	var yellow_br = Color(1.0, 1.0, 0.5)
	var blue = Color(0.3, 0.5, 1.0)
	var dark = Color(0.15, 0.15, 0.3)
	var glow = Color(1.0, 0.9, 0.3, 0.2)
	var ol = Color(0.35, 0.3, 0.05)
	_circle(img, 32, 32, 26, glow)
	# Cloud at top
	_circle(img, 24, 10, 8, dark)
	_circle(img, 36, 12, 10, dark)
	_circle(img, 44, 10, 6, dark)
	_circle(img, 30, 14, 8, Color(0.2, 0.2, 0.35))
	# Main lightning bolt (thick, central)
	_fill(img, 26, 20, 8, 6, yellow)
	_fill(img, 22, 26, 8, 4, yellow)
	_fill(img, 28, 30, 10, 6, yellow_br)
	_fill(img, 24, 36, 8, 4, yellow)
	_fill(img, 30, 40, 8, 6, yellow)
	_fill(img, 26, 46, 8, 4, yellow_br)
	_fill(img, 32, 50, 6, 8, yellow)
	# Side bolts
	_fill(img, 10, 22, 4, 12, blue)
	_fill(img, 8, 26, 4, 4, yellow)
	_fill(img, 48, 24, 4, 12, blue)
	_fill(img, 50, 28, 4, 4, yellow)
	# Spark particles
	_px(img, 18, 32, yellow_br)
	_px(img, 44, 36, yellow_br)
	_px(img, 36, 56, yellow)
	_outline(img, ol)
	_save_evo(img, "electric_storm.png")

func _gen_inferno_walker() -> void:
	var img = _img()
	var boot = Color(0.4, 0.15, 0.08)
	var boot_dk = Color(0.25, 0.08, 0.04)
	var fire = Color(1.0, 0.5, 0.1)
	var fire_br = Color(1.0, 0.8, 0.2)
	var fire_dk = Color(0.8, 0.2, 0.05)
	var ol = Color(0.2, 0.06, 0.02)
	# Boot
	_fill(img, 16, 20, 24, 24, boot)
	_fill(img, 18, 18, 20, 4, boot)
	_fill(img, 10, 40, 30, 8, boot_dk)
	_fill(img, 8, 44, 34, 6, Color(0.2, 0.08, 0.04))
	_fill(img, 20, 22, 12, 8, Color(0.5, 0.2, 0.1))
	# Flames from boot
	_fill(img, 8, 32, 6, 12, fire)
	_fill(img, 4, 28, 6, 8, fire)
	_fill(img, 2, 24, 4, 8, fire_br)
	_fill(img, 0, 20, 4, 6, fire_dk)
	_fill(img, 40, 34, 6, 10, fire)
	_fill(img, 44, 30, 6, 8, fire)
	_fill(img, 48, 26, 6, 8, fire_br)
	_fill(img, 52, 22, 4, 6, fire_dk)
	# Fire trail below
	_fill(img, 10, 50, 32, 4, fire)
	_fill(img, 6, 52, 40, 4, fire_dk)
	_fill(img, 14, 54, 24, 4, fire_br)
	_fill(img, 8, 58, 36, 4, Color(1.0, 0.9, 0.3, 0.5))
	# Ember particles
	_px(img, 14, 18, fire_br)
	_px(img, 42, 20, fire)
	_px(img, 6, 16, fire_dk)
	_outline(img, ol)
	_save_evo(img, "inferno_walker.png")

func _gen_lord_of_dead() -> void:
	var img = _img()
	var green = Color(0.2, 0.7, 0.25)
	var green_br = Color(0.35, 0.9, 0.4)
	var green_dk = Color(0.1, 0.45, 0.12)
	var bone = Color(0.82, 0.78, 0.68)
	var dark = Color(0.12, 0.08, 0.15)
	var ol = Color(0.05, 0.2, 0.06)
	# Necromantic circle
	_circle(img, 32, 32, 26, Color(0.15, 0.5, 0.2, 0.15))
	_circle(img, 32, 32, 24, Color(0, 0, 0, 0))
	# Skulls in triangle formation
	for pos in [Vector2(32, 14), Vector2(18, 44), Vector2(46, 44)]:
		_circle(img, int(pos.x), int(pos.y), 7, bone)
		_px(img, int(pos.x) - 2, int(pos.y) - 1, dark)
		_px(img, int(pos.x) + 2, int(pos.y) - 1, dark)
		_px(img, int(pos.x) - 2, int(pos.y) - 1, green)
		_px(img, int(pos.x) + 2, int(pos.y) - 1, green)
		_fill(img, int(pos.x) - 2, int(pos.y) + 3, 5, 1, dark)
	# Green energy connecting them
	for i in range(16):
		_px(img, 24 - i / 2, 22 + i * 2, green)
	for i in range(16):
		_px(img, 40 + i / 2, 22 + i * 2, green)
	_line_h(img, 20, 44, 44, green)
	# Central orb
	_circle(img, 32, 34, 5, green_dk)
	_circle(img, 32, 34, 3, green)
	_circle(img, 32, 34, 1, green_br)
	_outline(img, ol)
	_save_evo(img, "lord_of_dead.png")

func _gen_minigun_infernal() -> void:
	var img = _img()
	var metal = Color(0.35, 0.2, 0.15)
	var metal_dk = Color(0.22, 0.12, 0.08)
	var metal_lt = Color(0.48, 0.3, 0.2)
	var fire = Color(1.0, 0.5, 0.1)
	var fire_br = Color(1.0, 0.8, 0.2)
	var barrel = Color(0.3, 0.15, 0.1)
	var ol = Color(0.15, 0.06, 0.04)
	# Multiple barrels (horizontal)
	for i in range(4):
		_fill(img, 20, 20 + i * 6, 34, 4, barrel)
	_fill(img, 52, 18, 6, 28, metal_dk)
	# Body
	_fill(img, 10, 22, 14, 20, metal)
	_fill(img, 8, 26, 16, 12, metal_dk)
	_fill(img, 12, 24, 8, 6, metal_lt)
	# Grip
	_fill(img, 14, 44, 6, 12, Color(0.3, 0.18, 0.08))
	# Flames from barrels
	_fill(img, 56, 20, 4, 4, fire)
	_fill(img, 58, 26, 4, 3, fire_br)
	_fill(img, 56, 32, 4, 4, fire)
	_fill(img, 60, 22, 3, 8, fire)
	_fill(img, 60, 30, 3, 6, fire_br)
	# Glow
	_circle(img, 58, 30, 6, Color(1.0, 0.5, 0.1, 0.2))
	# Ammo belt
	_fill(img, 4, 36, 8, 3, Color(0.6, 0.55, 0.2))
	_fill(img, 2, 38, 6, 8, Color(0.6, 0.55, 0.2))
	_outline(img, ol)
	_save_evo(img, "minigun_infernal.png")

func _gen_nuke_launcher() -> void:
	var img = _img()
	var tube = Color(0.3, 0.32, 0.2)
	var tube_dk = Color(0.18, 0.2, 0.1)
	var tube_lt = Color(0.4, 0.42, 0.28)
	var yellow = Color(0.9, 0.8, 0.1)
	var red = Color(0.8, 0.15, 0.1)
	var ol = Color(0.1, 0.1, 0.06)
	# Launcher tube
	_fill(img, 6, 22, 48, 12, tube)
	_fill(img, 8, 20, 44, 2, tube_dk)
	_fill(img, 8, 34, 44, 2, tube_dk)
	_fill(img, 10, 24, 40, 4, tube_lt)
	# Front opening
	_fill(img, 52, 20, 8, 16, tube_dk)
	_circle(img, 56, 28, 5, Color(0.1, 0.1, 0.08))
	# Nuke warhead visible inside
	_circle(img, 54, 28, 3, yellow)
	_circle(img, 54, 28, 1, red)
	# Radiation symbol on side
	_circle(img, 30, 28, 6, yellow)
	_circle(img, 30, 28, 4, tube)
	_circle(img, 30, 28, 2, yellow)
	# Handle
	_fill(img, 20, 36, 6, 10, Color(0.3, 0.2, 0.1))
	# Scope
	_fill(img, 34, 16, 6, 6, Color(0.4, 0.4, 0.45))
	_fill(img, 35, 14, 4, 2, Color(0.35, 0.35, 0.4))
	# Warning stripes
	for i in range(4):
		_fill(img, 8 + i * 4, 34, 2, 2, yellow)
	_outline(img, ol)
	_save_evo(img, "nuke_launcher.png")

func _gen_ragnarok_axe() -> void:
	var img = _img()
	var handle = Color(0.4, 0.25, 0.12)
	var handle_dk = Color(0.28, 0.16, 0.06)
	var blade = Color(0.55, 0.58, 0.62)
	var blade_lt = Color(0.72, 0.75, 0.8)
	var blade_dk = Color(0.38, 0.4, 0.45)
	var fire = Color(1.0, 0.5, 0.1)
	var rune = Color(0.3, 0.6, 1.0)
	var ol = Color(0.18, 0.15, 0.05)
	# Handle (vertical)
	_fill(img, 29, 18, 6, 42, handle)
	_fill(img, 28, 20, 1, 38, handle_dk)
	_fill(img, 31, 20, 2, 38, Color(0.5, 0.32, 0.18))
	# Double axe head
	# Left blade
	_fill(img, 8, 6, 22, 6, blade)
	_fill(img, 6, 10, 24, 8, blade)
	_fill(img, 8, 16, 22, 4, blade_dk)
	_fill(img, 10, 8, 6, 4, blade_lt)
	# Right blade
	_fill(img, 34, 6, 22, 6, blade)
	_fill(img, 34, 10, 24, 8, blade)
	_fill(img, 34, 16, 22, 4, blade_dk)
	_fill(img, 48, 8, 6, 4, blade_lt)
	# Edge highlights
	_line_v(img, 6, 10, 16, blade_lt)
	_line_v(img, 57, 10, 16, blade_lt)
	# Rune markings
	_px(img, 14, 12, rune)
	_px(img, 16, 14, rune)
	_px(img, 14, 16, rune)
	_px(img, 48, 12, rune)
	_px(img, 46, 14, rune)
	_px(img, 48, 16, rune)
	# Fire on blade edges
	_px(img, 4, 12, fire)
	_px(img, 2, 14, fire)
	_px(img, 60, 12, fire)
	_px(img, 62, 14, fire)
	# Bottom grip wrapping
	_fill(img, 27, 54, 10, 3, Color(0.6, 0.5, 0.2))
	_fill(img, 27, 46, 10, 2, Color(0.6, 0.5, 0.2))
	_outline(img, ol)
	_save_evo(img, "ragnarok_axe.png")

func _gen_vampire_whip() -> void:
	var img = _img()
	var leather = Color(0.35, 0.12, 0.12)
	var leather_dk = Color(0.22, 0.06, 0.06)
	var leather_lt = Color(0.5, 0.2, 0.18)
	var blood = Color(0.7, 0.08, 0.08)
	var blood_br = Color(0.9, 0.15, 0.12)
	var gold = Color(0.8, 0.65, 0.15)
	var ol = Color(0.15, 0.04, 0.04)
	# Handle
	_fill(img, 6, 44, 8, 16, leather)
	_fill(img, 8, 42, 6, 4, leather)
	_fill(img, 7, 46, 4, 10, leather_dk)
	# Gold pommel
	_circle(img, 10, 58, 3, gold)
	# Whip curl (S-shape going up)
	_fill(img, 12, 38, 8, 4, leather)
	_fill(img, 18, 32, 8, 4, leather)
	_fill(img, 14, 34, 6, 4, leather_dk)
	_fill(img, 24, 26, 8, 4, leather)
	_fill(img, 20, 28, 6, 4, leather_lt)
	_fill(img, 30, 20, 8, 4, leather)
	_fill(img, 26, 22, 6, 4, leather_dk)
	_fill(img, 36, 14, 8, 4, leather)
	_fill(img, 42, 8, 8, 4, leather)
	_fill(img, 38, 10, 6, 4, leather_lt)
	_fill(img, 48, 4, 6, 4, leather)
	# Blood drips along whip
	_px(img, 16, 42, blood)
	_px(img, 24, 34, blood)
	_px(img, 32, 26, blood_br)
	_px(img, 40, 18, blood)
	_px(img, 50, 8, blood_br)
	# Tip (sharp, blood-soaked)
	_fill(img, 52, 2, 4, 4, blood)
	_px(img, 55, 2, blood_br)
	_outline(img, ol)
	_save_evo(img, "vampire_whip.png")

func _gen_zangetsu() -> void:
	var img = _img()
	var blade = Color(0.2, 0.2, 0.25)
	var blade_lt = Color(0.4, 0.42, 0.48)
	var blade_dk = Color(0.1, 0.1, 0.14)
	var edge = Color(0.65, 0.68, 0.72)
	var handle = Color(0.15, 0.08, 0.05)
	var wrap = Color(0.85, 0.82, 0.72)
	var aura = Color(0.2, 0.3, 0.8, 0.2)
	var ol = Color(0.05, 0.05, 0.08)
	_circle(img, 32, 30, 22, aura)
	# Massive cleaver blade (diagonal)
	_fill(img, 16, 2, 20, 6, blade)
	_fill(img, 14, 6, 22, 6, blade)
	_fill(img, 12, 12, 24, 8, blade)
	_fill(img, 14, 20, 22, 6, blade)
	_fill(img, 16, 26, 20, 6, blade)
	_fill(img, 18, 32, 18, 6, blade_dk)
	_fill(img, 20, 38, 16, 4, blade)
	# Edge highlight
	_fill(img, 36, 6, 2, 28, edge)
	_fill(img, 34, 4, 2, 4, edge)
	# Blade interior highlight
	_fill(img, 18, 10, 4, 16, blade_lt)
	# Guard
	_fill(img, 16, 40, 24, 4, Color(0.4, 0.35, 0.25))
	# Handle
	_fill(img, 26, 44, 8, 16, handle)
	# Wrap
	for i in range(4):
		_fill(img, 26, 46 + i * 4, 8, 2, wrap)
	# Bottom
	_fill(img, 28, 58, 4, 4, Color(0.4, 0.35, 0.25))
	_outline(img, ol)
	_save_evo(img, "zangetsu.png")
