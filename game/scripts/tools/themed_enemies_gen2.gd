extends SceneTree

## Generates 32x32 pixel art sprites for themed enemies (Gen 2):
## Arena, Space, Castle, Candy, Cemetery stages.
## Run: godot --headless --path game --script res://scripts/tools/themed_enemies_gen2.gd

const S := 32

func _init() -> void:
	# Create all directories
	DirAccess.make_dir_recursive_absolute("res://assets/sprites/enemies/arena")
	DirAccess.make_dir_recursive_absolute("res://assets/sprites/enemies/space")
	DirAccess.make_dir_recursive_absolute("res://assets/sprites/enemies/castle")
	DirAccess.make_dir_recursive_absolute("res://assets/sprites/enemies/candy")
	DirAccess.make_dir_recursive_absolute("res://assets/sprites/enemies/cemetery")

	# Arena
	_gen_arena_gladiator()
	_gen_arena_lion()
	_gen_arena_centurion()
	_gen_arena_chariot()

	# Space
	_gen_space_alien()
	_gen_space_parasite()
	_gen_space_drone_enemy()
	_gen_space_xenomorph()

	# Castle
	_gen_castle_vampire()
	_gen_castle_werewolf()
	_gen_castle_knight()
	_gen_castle_gargoyle()

	# Candy
	_gen_candy_gummy()
	_gen_candy_cupcake()
	_gen_candy_jawbreaker()
	_gen_candy_licorice()

	# Cemetery
	_gen_cemetery_zombie()
	_gen_cemetery_wraith()
	_gen_cemetery_hand()
	_gen_cemetery_reaper()

	print("All themed enemy sprites (gen2) generated!")
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

# ==================== ARENA ====================

func _gen_arena_gladiator() -> void:
	var img = _img()
	var skin = Color(0.78, 0.6, 0.44)
	var armor = Color(0.82, 0.72, 0.2)
	var armor_dark = Color(0.65, 0.55, 0.12)
	var skirt = Color(0.7, 0.15, 0.1)
	var sword = Color(0.8, 0.82, 0.85)
	var shield = Color(0.75, 0.65, 0.15)
	var shield_dark = Color(0.55, 0.45, 0.1)
	var eye = Color(0.1, 0.1, 0.1)
	var hair = Color(0.35, 0.2, 0.1)

	# Head
	_fill(img, 13, 3, 6, 6, skin)
	_fill(img, 12, 5, 8, 3, skin)
	# Hair
	_fill(img, 13, 2, 6, 2, hair)
	_px(img, 12, 3, hair)
	_px(img, 19, 3, hair)
	# Eyes
	_px(img, 14, 6, eye)
	_px(img, 17, 6, eye)
	# Mouth
	_px(img, 15, 8, Color(0.6, 0.3, 0.25))
	_px(img, 16, 8, Color(0.6, 0.3, 0.25))

	# Gold chest armor
	_fill(img, 12, 10, 8, 5, armor)
	_fill(img, 11, 11, 10, 3, armor)
	# Armor details
	_fill(img, 14, 11, 4, 3, armor_dark)
	_px(img, 16, 10, armor_dark)

	# Shoulder pads
	_fill(img, 9, 10, 3, 3, armor)
	_fill(img, 20, 10, 3, 3, armor)

	# Arms (skin)
	_fill(img, 8, 13, 3, 6, skin)
	_fill(img, 21, 13, 3, 6, skin)

	# Red battle skirt
	_fill(img, 12, 15, 8, 4, skirt)
	_fill(img, 11, 16, 10, 3, skirt)
	_fill(img, 11, 19, 3, 1, skirt)
	_fill(img, 18, 19, 3, 1, skirt)

	# Legs
	_fill(img, 13, 20, 3, 5, skin)
	_fill(img, 17, 20, 3, 5, skin)
	# Sandals
	_fill(img, 12, 25, 4, 2, Color(0.45, 0.3, 0.15))
	_fill(img, 17, 25, 4, 2, Color(0.45, 0.3, 0.15))

	# Sword in right hand
	for i in range(10):
		_px(img, 7, 8 + i, sword)
		_px(img, 8, 8 + i, sword)
	_px(img, 7, 7, Color(0.9, 0.9, 0.95))
	_px(img, 8, 7, Color(0.9, 0.9, 0.95))
	# Sword guard
	_fill(img, 6, 17, 4, 1, armor)

	# Shield in left hand
	_fill(img, 22, 13, 5, 7, shield)
	_fill(img, 23, 12, 3, 9, shield)
	_fill(img, 24, 15, 2, 3, shield_dark)
	_px(img, 25, 16, Color(0.9, 0.1, 0.1))

	_outline(img, Color(0.15, 0.1, 0.05))
	_save(img, "res://assets/sprites/enemies/arena/arena_gladiator.png")

func _gen_arena_lion() -> void:
	var img = _img()
	var body = Color(0.85, 0.68, 0.3)
	var mane = Color(0.72, 0.45, 0.12)
	var mane_dark = Color(0.55, 0.32, 0.08)
	var belly = Color(0.92, 0.82, 0.55)
	var eye = Color(0.9, 0.75, 0.1)
	var pupil = Color(0.1, 0.1, 0.1)
	var nose = Color(0.3, 0.18, 0.12)
	var mouth = Color(0.7, 0.2, 0.15)

	# Mane (large circle behind head)
	_fill(img, 7, 3, 18, 3, mane)
	_fill(img, 5, 6, 22, 4, mane)
	_fill(img, 4, 10, 24, 3, mane)
	_fill(img, 5, 13, 22, 2, mane)
	_fill(img, 7, 15, 18, 1, mane)
	# Darker mane edges
	_fill(img, 4, 10, 2, 3, mane_dark)
	_fill(img, 26, 10, 2, 3, mane_dark)
	_fill(img, 6, 14, 3, 1, mane_dark)
	_fill(img, 23, 14, 3, 1, mane_dark)

	# Face
	_fill(img, 10, 6, 12, 8, body)
	_fill(img, 9, 8, 14, 5, body)

	# Eyes (fierce)
	_fill(img, 12, 8, 3, 2, eye)
	_fill(img, 18, 8, 3, 2, eye)
	_px(img, 13, 9, pupil)
	_px(img, 19, 9, pupil)
	# Angry brows
	_px(img, 12, 7, pupil)
	_px(img, 13, 7, pupil)
	_px(img, 19, 7, pupil)
	_px(img, 20, 7, pupil)

	# Nose
	_fill(img, 15, 11, 2, 1, nose)
	# Open roaring mouth
	_fill(img, 12, 12, 8, 3, mouth)
	_fill(img, 13, 12, 6, 1, Color(0.95, 0.95, 0.9))
	# Teeth
	_px(img, 13, 12, Color(0.95, 0.95, 0.95))
	_px(img, 15, 12, Color(0.95, 0.95, 0.95))
	_px(img, 17, 12, Color(0.95, 0.95, 0.95))
	_px(img, 19, 12, Color(0.95, 0.95, 0.95))

	# Body
	_fill(img, 9, 16, 14, 6, body)
	_fill(img, 10, 17, 12, 4, belly)

	# Front legs
	_fill(img, 8, 22, 4, 6, body)
	_fill(img, 20, 22, 4, 6, body)
	# Paws
	_fill(img, 7, 27, 5, 2, body)
	_fill(img, 19, 27, 5, 2, body)

	# Tail
	_px(img, 23, 17, body)
	_px(img, 24, 16, body)
	_px(img, 25, 15, mane)
	_px(img, 26, 15, mane_dark)

	_outline(img, Color(0.2, 0.12, 0.04))
	_save(img, "res://assets/sprites/enemies/arena/arena_lion.png")

func _gen_arena_centurion() -> void:
	var img = _img()
	var skin = Color(0.75, 0.58, 0.42)
	var helmet = Color(0.65, 0.62, 0.58)
	var plume = Color(0.8, 0.12, 0.08)
	var plume_dark = Color(0.6, 0.08, 0.05)
	var armor = Color(0.6, 0.58, 0.55)
	var armor_light = Color(0.72, 0.7, 0.65)
	var skirt = Color(0.75, 0.15, 0.1)
	var eye = Color(0.1, 0.1, 0.1)

	# Red plume on top
	_fill(img, 14, 0, 4, 2, plume)
	_fill(img, 13, 2, 6, 2, plume)
	_fill(img, 14, 1, 4, 1, plume_dark)

	# Helmet
	_fill(img, 11, 4, 10, 6, helmet)
	_fill(img, 12, 3, 8, 1, helmet)
	# Helmet visor slit
	_fill(img, 13, 7, 6, 1, Color(0.15, 0.15, 0.15))
	# Face visible below
	_fill(img, 13, 8, 6, 2, skin)
	# Eyes in visor
	_px(img, 14, 7, eye)
	_px(img, 17, 7, eye)
	# Chin guard
	_fill(img, 11, 9, 2, 2, helmet)
	_fill(img, 19, 9, 2, 2, helmet)

	# Chest armor (segmented)
	_fill(img, 11, 11, 10, 6, armor)
	_fill(img, 10, 12, 12, 4, armor)
	# Armor segments
	_fill(img, 11, 13, 10, 1, armor_light)
	_fill(img, 11, 15, 10, 1, armor_light)
	# Center line
	for y in range(11, 17):
		_px(img, 16, y, armor_light)

	# Shoulder guards
	_fill(img, 7, 11, 4, 3, armor)
	_fill(img, 21, 11, 4, 3, armor)
	_fill(img, 8, 11, 2, 1, armor_light)
	_fill(img, 22, 11, 2, 1, armor_light)

	# Arms
	_fill(img, 7, 14, 3, 5, skin)
	_fill(img, 22, 14, 3, 5, skin)

	# Red skirt
	_fill(img, 11, 17, 10, 4, skirt)
	_fill(img, 10, 18, 12, 2, skirt)
	# Skirt strips
	for x in [11, 13, 15, 17, 19]:
		_px(img, x, 20, Color(0.55, 0.1, 0.08))

	# Legs with greaves
	_fill(img, 12, 21, 3, 5, armor)
	_fill(img, 17, 21, 3, 5, armor)
	# Sandals
	_fill(img, 11, 26, 4, 2, Color(0.45, 0.3, 0.15))
	_fill(img, 17, 26, 4, 2, Color(0.45, 0.3, 0.15))

	# Spear in right hand
	for i in range(14):
		_px(img, 6, 5 + i, Color(0.5, 0.35, 0.2))
	_fill(img, 5, 3, 3, 3, Color(0.7, 0.72, 0.75))
	_px(img, 6, 2, Color(0.8, 0.82, 0.85))

	_outline(img, Color(0.12, 0.1, 0.08))
	_save(img, "res://assets/sprites/enemies/arena/arena_centurion.png")

func _gen_arena_chariot() -> void:
	var img = _img()
	var wood = Color(0.55, 0.35, 0.18)
	var wood_dark = Color(0.4, 0.25, 0.1)
	var gold = Color(0.85, 0.72, 0.2)
	var horse = Color(0.5, 0.35, 0.2)
	var horse_dark = Color(0.38, 0.25, 0.14)
	var wheel = Color(0.45, 0.3, 0.15)
	var eye = Color(0.1, 0.1, 0.1)
	var mane = Color(0.25, 0.15, 0.08)

	# Horse body (left side)
	_fill(img, 2, 10, 12, 8, horse)
	_fill(img, 3, 9, 10, 1, horse)
	_fill(img, 4, 8, 8, 1, horse)
	# Horse belly lighter
	_fill(img, 4, 15, 8, 2, Color(0.58, 0.42, 0.28))

	# Horse head and neck
	_fill(img, 1, 5, 5, 5, horse)
	_fill(img, 0, 3, 4, 3, horse)
	# Ear
	_px(img, 0, 2, horse_dark)
	_px(img, 1, 2, horse_dark)
	# Eye
	_px(img, 1, 5, eye)
	# Nose
	_px(img, 0, 7, Color(0.3, 0.18, 0.1))

	# Mane
	for i in range(6):
		_px(img, 3, 4 + i, mane)
		_px(img, 4, 5 + i, mane)

	# Horse legs
	_fill(img, 3, 18, 2, 7, horse_dark)
	_fill(img, 8, 18, 2, 7, horse_dark)
	# Hooves
	_fill(img, 3, 25, 2, 2, Color(0.25, 0.18, 0.1))
	_fill(img, 8, 25, 2, 2, Color(0.25, 0.18, 0.1))

	# Chariot body (right side)
	_fill(img, 15, 10, 12, 8, wood)
	_fill(img, 14, 11, 14, 6, wood)
	# Chariot rim
	_fill(img, 15, 10, 12, 1, gold)
	_fill(img, 26, 10, 2, 8, gold)
	# Chariot inner
	_fill(img, 16, 12, 9, 4, wood_dark)

	# Connection beam
	_fill(img, 12, 14, 4, 2, wood_dark)

	# Wheel (right side)
	_fill(img, 18, 19, 8, 2, wheel)
	_fill(img, 19, 18, 6, 4, wheel)
	_fill(img, 20, 17, 4, 6, wheel)
	# Wheel hub
	_fill(img, 21, 19, 2, 2, gold)
	# Spokes
	_px(img, 22, 17, gold)
	_px(img, 22, 22, gold)
	_px(img, 19, 20, gold)
	_px(img, 25, 20, gold)

	# Small rider silhouette in chariot
	_fill(img, 19, 7, 4, 4, Color(0.75, 0.58, 0.42))
	_fill(img, 18, 10, 6, 2, Color(0.6, 0.55, 0.5))

	_outline(img, Color(0.15, 0.1, 0.05))
	_save(img, "res://assets/sprites/enemies/arena/arena_chariot.png")

# ==================== SPACE ====================

func _gen_space_alien() -> void:
	var img = _img()
	var skin = Color(0.3, 0.75, 0.3)
	var skin_light = Color(0.4, 0.85, 0.4)
	var skin_dark = Color(0.2, 0.55, 0.2)
	var eye_black = Color(0.02, 0.02, 0.05)
	var eye_shine = Color(0.15, 0.15, 0.2)

	# Big head (top heavy)
	_fill(img, 8, 2, 16, 4, skin)
	_fill(img, 6, 6, 20, 5, skin)
	_fill(img, 7, 4, 18, 2, skin)
	_fill(img, 8, 11, 16, 2, skin)
	# Head highlight
	_fill(img, 10, 3, 6, 2, skin_light)

	# Large black almond eyes
	_fill(img, 8, 7, 6, 3, eye_black)
	_fill(img, 18, 7, 6, 3, eye_black)
	_fill(img, 9, 6, 4, 1, eye_black)
	_fill(img, 19, 6, 4, 1, eye_black)
	_fill(img, 9, 10, 4, 1, eye_black)
	_fill(img, 19, 10, 4, 1, eye_black)
	# Eye shine
	_px(img, 10, 7, eye_shine)
	_px(img, 20, 7, eye_shine)

	# Small nostrils
	_px(img, 15, 10, skin_dark)
	_px(img, 16, 10, skin_dark)

	# Thin mouth
	_fill(img, 14, 12, 4, 1, skin_dark)

	# Thin neck
	_fill(img, 14, 13, 4, 2, skin)

	# Small body
	_fill(img, 12, 15, 8, 6, skin)
	_fill(img, 11, 16, 10, 4, skin)

	# Thin arms
	_fill(img, 8, 16, 3, 2, skin)
	_fill(img, 7, 18, 3, 2, skin)
	_fill(img, 6, 20, 3, 1, skin)
	# Long fingers
	_px(img, 5, 21, skin_light)
	_px(img, 6, 21, skin_light)
	_px(img, 7, 21, skin_light)

	_fill(img, 21, 16, 3, 2, skin)
	_fill(img, 22, 18, 3, 2, skin)
	_fill(img, 23, 20, 3, 1, skin)
	_px(img, 24, 21, skin_light)
	_px(img, 25, 21, skin_light)
	_px(img, 26, 21, skin_light)

	# Thin legs
	_fill(img, 13, 21, 2, 5, skin)
	_fill(img, 17, 21, 2, 5, skin)
	# Feet
	_fill(img, 12, 26, 3, 2, skin_dark)
	_fill(img, 17, 26, 3, 2, skin_dark)

	_outline(img, Color(0.08, 0.25, 0.08))
	_save(img, "res://assets/sprites/enemies/space/space_alien.png")

func _gen_space_parasite() -> void:
	var img = _img()
	var body = Color(0.5, 0.15, 0.6)
	var body_light = Color(0.65, 0.25, 0.75)
	var body_dark = Color(0.35, 0.08, 0.42)
	var legs = Color(0.4, 0.1, 0.5)
	var eye = Color(0.95, 0.85, 0.1)
	var mandible = Color(0.6, 0.2, 0.15)

	# Oval bug body
	_fill(img, 10, 8, 12, 4, body)
	_fill(img, 8, 12, 16, 6, body)
	_fill(img, 9, 10, 14, 2, body)
	_fill(img, 9, 18, 14, 2, body)
	_fill(img, 10, 20, 12, 2, body)
	# Carapace segments
	_fill(img, 12, 10, 8, 1, body_dark)
	_fill(img, 10, 14, 12, 1, body_dark)
	_fill(img, 10, 18, 12, 1, body_dark)
	# Light strip
	_fill(img, 14, 9, 4, 12, body_light)

	# Head section
	_fill(img, 12, 5, 8, 4, body)
	_fill(img, 13, 4, 6, 1, body)
	# Eyes (yellow compound)
	_fill(img, 12, 6, 3, 2, eye)
	_fill(img, 17, 6, 3, 2, eye)
	_px(img, 13, 6, Color(0.3, 0.1, 0.1))
	_px(img, 18, 6, Color(0.3, 0.1, 0.1))

	# Mandibles
	_px(img, 13, 9, mandible)
	_px(img, 14, 10, mandible)
	_px(img, 18, 9, mandible)
	_px(img, 17, 10, mandible)

	# Antennae
	_px(img, 12, 3, legs)
	_px(img, 11, 2, legs)
	_px(img, 19, 3, legs)
	_px(img, 20, 2, legs)

	# Six legs (3 per side)
	for i in range(3):
		var yoff = 12 + i * 3
		# Left legs
		_fill(img, 5, yoff, 4, 1, legs)
		_px(img, 4, yoff + 1, legs)
		# Right legs
		_fill(img, 23, yoff, 4, 1, legs)
		_px(img, 27, yoff + 1, legs)

	# Tail stinger
	_px(img, 16, 22, body_dark)
	_px(img, 16, 23, mandible)

	_outline(img, Color(0.18, 0.04, 0.22))
	_save(img, "res://assets/sprites/enemies/space/space_parasite.png")

func _gen_space_drone_enemy() -> void:
	var img = _img()
	var hull = Color(0.55, 0.12, 0.12)
	var hull_light = Color(0.7, 0.2, 0.18)
	var hull_dark = Color(0.4, 0.08, 0.08)
	var metal = Color(0.5, 0.5, 0.52)
	var light_red = Color(1.0, 0.2, 0.15)
	var light_glow = Color(1.0, 0.5, 0.3)
	var gun = Color(0.35, 0.35, 0.38)

	# Central body (hexagonal-ish)
	_fill(img, 12, 10, 8, 12, hull)
	_fill(img, 10, 12, 12, 8, hull)
	_fill(img, 11, 11, 10, 10, hull)
	# Top dome
	_fill(img, 13, 8, 6, 3, hull_light)
	_fill(img, 14, 7, 4, 1, hull_light)

	# Central eye/sensor
	_fill(img, 14, 14, 4, 4, Color(0.1, 0.1, 0.12))
	_fill(img, 15, 15, 2, 2, light_red)
	_px(img, 15, 15, light_glow)

	# Side weapon pods
	_fill(img, 4, 13, 6, 3, metal)
	_fill(img, 22, 13, 6, 3, metal)
	# Gun barrels
	_fill(img, 2, 14, 3, 1, gun)
	_fill(img, 27, 14, 3, 1, gun)
	# Red lights on pods
	_px(img, 5, 14, light_red)
	_px(img, 26, 14, light_red)

	# Propulsion vents (bottom)
	_fill(img, 13, 22, 2, 3, light_red)
	_fill(img, 17, 22, 2, 3, light_red)
	_fill(img, 13, 25, 2, 1, light_glow)
	_fill(img, 17, 25, 2, 1, light_glow)

	# Antenna on top
	_px(img, 16, 5, metal)
	_px(img, 16, 6, metal)
	_px(img, 15, 4, light_red)
	_px(img, 16, 4, light_red)

	# Hull panel lines
	_fill(img, 12, 16, 8, 1, hull_dark)
	for y in range(10, 22):
		_px(img, 16, y, hull_dark)

	_outline(img, Color(0.15, 0.05, 0.05))
	_save(img, "res://assets/sprites/enemies/space/space_drone_enemy.png")

func _gen_space_xenomorph() -> void:
	var img = _img()
	var body = Color(0.12, 0.12, 0.18)
	var body_light = Color(0.2, 0.2, 0.28)
	var body_dark = Color(0.06, 0.06, 0.1)
	var teeth = Color(0.85, 0.85, 0.82)
	var drool = Color(0.5, 0.7, 0.5, 0.6)

	# Elongated head (banana shape)
	_fill(img, 10, 1, 6, 2, body)
	_fill(img, 8, 3, 8, 2, body)
	_fill(img, 12, 5, 6, 2, body)
	_fill(img, 13, 7, 5, 2, body)
	# Head ridge
	_fill(img, 11, 2, 3, 1, body_light)

	# Mouth area
	_fill(img, 14, 9, 4, 2, body)
	# Teeth
	_px(img, 14, 9, teeth)
	_px(img, 15, 10, teeth)
	_px(img, 17, 9, teeth)
	_px(img, 16, 10, teeth)
	# Drool
	_px(img, 15, 11, drool)
	_px(img, 17, 11, drool)

	# Neck
	_fill(img, 14, 11, 3, 2, body)

	# Torso (lean/thin)
	_fill(img, 13, 13, 5, 5, body)
	_fill(img, 12, 14, 7, 3, body)
	# Ribbed chest
	for y in [14, 16]:
		_fill(img, 14, y, 3, 1, body_light)

	# Arms (long, thin, clawed)
	_fill(img, 9, 14, 3, 2, body)
	_fill(img, 7, 16, 3, 2, body)
	_fill(img, 6, 18, 2, 1, body)
	_px(img, 5, 18, body_light)  # claw
	_px(img, 5, 19, body_light)

	_fill(img, 19, 14, 3, 2, body)
	_fill(img, 21, 16, 3, 2, body)
	_fill(img, 23, 18, 2, 1, body)
	_px(img, 25, 18, body_light)
	_px(img, 25, 19, body_light)

	# Legs (digitigrade)
	_fill(img, 12, 18, 3, 3, body)
	_fill(img, 11, 21, 3, 3, body)
	_fill(img, 10, 24, 3, 3, body)
	_fill(img, 9, 27, 4, 2, body_dark)

	_fill(img, 17, 18, 3, 3, body)
	_fill(img, 18, 21, 3, 3, body)
	_fill(img, 19, 24, 3, 3, body)
	_fill(img, 19, 27, 4, 2, body_dark)

	# Long tail curving back
	_fill(img, 11, 17, 2, 2, body)
	_px(img, 9, 18, body)
	_px(img, 8, 19, body)
	_px(img, 7, 20, body)
	_px(img, 6, 21, body)
	_px(img, 5, 22, body)
	_px(img, 4, 23, body)
	_px(img, 3, 23, body)
	_px(img, 3, 24, body_light)  # tail tip (blade)
	_px(img, 2, 24, body_light)

	_outline(img, Color(0.04, 0.04, 0.08))
	_save(img, "res://assets/sprites/enemies/space/space_xenomorph.png")

# ==================== CASTLE ====================

func _gen_castle_vampire() -> void:
	var img = _img()
	var skin = Color(0.82, 0.78, 0.82)
	var hair = Color(0.12, 0.1, 0.15)
	var cape = Color(0.35, 0.05, 0.1)
	var cape_inner = Color(0.6, 0.08, 0.15)
	var suit = Color(0.15, 0.12, 0.18)
	var eye_red = Color(0.9, 0.12, 0.08)
	var fang = Color(0.95, 0.95, 0.95)

	# Hair (slicked back)
	_fill(img, 12, 3, 8, 3, hair)
	_fill(img, 11, 4, 10, 2, hair)
	# Widow's peak
	_px(img, 16, 4, hair)
	_px(img, 15, 3, hair)

	# Face
	_fill(img, 12, 6, 8, 6, skin)
	_fill(img, 13, 5, 6, 1, skin)
	# Red eyes
	_fill(img, 13, 8, 2, 1, eye_red)
	_fill(img, 17, 8, 2, 1, eye_red)
	_px(img, 14, 8, Color(0.5, 0.05, 0.05))
	_px(img, 18, 8, Color(0.5, 0.05, 0.05))
	# Eyebrows
	_px(img, 13, 7, hair)
	_px(img, 14, 7, hair)
	_px(img, 17, 7, hair)
	_px(img, 18, 7, hair)

	# Mouth and fangs
	_fill(img, 14, 10, 4, 1, Color(0.3, 0.05, 0.08))
	_px(img, 14, 11, fang)
	_px(img, 17, 11, fang)

	# Cape (spread wide)
	_fill(img, 5, 10, 7, 14, cape)
	_fill(img, 20, 10, 7, 14, cape)
	_fill(img, 4, 12, 3, 12, cape)
	_fill(img, 25, 12, 3, 12, cape)
	# Cape inner lining
	_fill(img, 8, 13, 4, 10, cape_inner)
	_fill(img, 20, 13, 4, 10, cape_inner)
	# Cape bottom
	_fill(img, 4, 24, 5, 3, cape)
	_fill(img, 23, 24, 5, 3, cape)

	# Body (suit)
	_fill(img, 12, 12, 8, 8, suit)
	# Vest detail
	_fill(img, 15, 13, 2, 5, Color(0.5, 0.05, 0.1))
	# Collar
	_px(img, 12, 12, Color(0.95, 0.95, 0.95))
	_px(img, 19, 12, Color(0.95, 0.95, 0.95))

	# Legs
	_fill(img, 13, 20, 3, 6, suit)
	_fill(img, 17, 20, 3, 6, suit)
	# Shoes
	_fill(img, 12, 26, 4, 2, Color(0.1, 0.08, 0.12))
	_fill(img, 17, 26, 4, 2, Color(0.1, 0.08, 0.12))

	_outline(img, Color(0.05, 0.03, 0.08))
	_save(img, "res://assets/sprites/enemies/castle/castle_vampire.png")

func _gen_castle_werewolf() -> void:
	var img = _img()
	var fur = Color(0.45, 0.42, 0.4)
	var fur_light = Color(0.58, 0.55, 0.52)
	var fur_dark = Color(0.3, 0.28, 0.26)
	var eye = Color(0.9, 0.75, 0.1)
	var nose = Color(0.2, 0.15, 0.12)
	var claw = Color(0.9, 0.88, 0.85)
	var mouth = Color(0.4, 0.1, 0.1)

	# Pointed ears
	_px(img, 10, 2, fur)
	_fill(img, 10, 3, 2, 2, fur)
	_px(img, 21, 2, fur)
	_fill(img, 20, 3, 2, 2, fur)

	# Head (snout shape)
	_fill(img, 11, 4, 10, 6, fur)
	_fill(img, 12, 3, 8, 1, fur)
	# Snout protrusion
	_fill(img, 13, 10, 6, 3, fur_light)

	# Eyes (yellow, fierce)
	_fill(img, 12, 6, 2, 2, eye)
	_fill(img, 18, 6, 2, 2, eye)
	_px(img, 13, 7, Color(0.1, 0.1, 0.1))
	_px(img, 19, 7, Color(0.1, 0.1, 0.1))
	# Brow ridge
	_fill(img, 12, 5, 3, 1, fur_dark)
	_fill(img, 17, 5, 3, 1, fur_dark)

	# Nose
	_fill(img, 15, 10, 2, 1, nose)
	# Open mouth with teeth
	_fill(img, 14, 11, 4, 2, mouth)
	_px(img, 14, 11, claw)
	_px(img, 15, 12, claw)
	_px(img, 16, 11, claw)
	_px(img, 17, 12, claw)

	# Muscular torso
	_fill(img, 10, 13, 12, 7, fur)
	_fill(img, 11, 12, 10, 1, fur)
	# Chest lighter
	_fill(img, 13, 14, 6, 4, fur_light)

	# Broad shoulders
	_fill(img, 7, 13, 4, 3, fur)
	_fill(img, 21, 13, 4, 3, fur)

	# Arms (muscular, claws out)
	_fill(img, 5, 16, 4, 5, fur)
	_fill(img, 23, 16, 4, 5, fur)
	# Claws - left
	_px(img, 4, 21, claw)
	_px(img, 5, 21, claw)
	_px(img, 6, 21, claw)
	_px(img, 4, 22, claw)
	# Claws - right
	_px(img, 25, 21, claw)
	_px(img, 26, 21, claw)
	_px(img, 27, 21, claw)
	_px(img, 27, 22, claw)

	# Legs
	_fill(img, 11, 20, 4, 6, fur)
	_fill(img, 17, 20, 4, 6, fur)
	# Digitigrade feet
	_fill(img, 10, 26, 5, 2, fur_dark)
	_fill(img, 17, 26, 5, 2, fur_dark)
	# Toe claws
	_px(img, 10, 28, claw)
	_px(img, 14, 28, claw)
	_px(img, 17, 28, claw)
	_px(img, 21, 28, claw)

	_outline(img, Color(0.12, 0.1, 0.1))
	_save(img, "res://assets/sprites/enemies/castle/castle_werewolf.png")

func _gen_castle_knight() -> void:
	var img = _img()
	var armor = Color(0.2, 0.18, 0.22)
	var armor_light = Color(0.3, 0.28, 0.32)
	var armor_dark = Color(0.1, 0.08, 0.12)
	var visor = Color(0.8, 0.1, 0.08)
	var sword = Color(0.55, 0.52, 0.58)
	var cape = Color(0.25, 0.05, 0.05)

	# Helmet
	_fill(img, 12, 3, 8, 7, armor)
	_fill(img, 11, 5, 10, 4, armor)
	_fill(img, 13, 2, 6, 1, armor_light)
	# Visor slit (glowing red)
	_fill(img, 13, 7, 6, 2, visor)
	_px(img, 14, 7, Color(1.0, 0.3, 0.2))
	_px(img, 17, 7, Color(1.0, 0.3, 0.2))
	# Helmet crest
	_fill(img, 15, 1, 2, 2, armor_light)

	# Neck
	_fill(img, 14, 10, 4, 1, armor)

	# Chest plate
	_fill(img, 10, 11, 12, 7, armor)
	_fill(img, 11, 10, 10, 1, armor)
	# Armor detail lines
	_fill(img, 15, 12, 2, 5, armor_light)
	_fill(img, 10, 14, 12, 1, armor_dark)

	# Shoulder pauldrons (large)
	_fill(img, 6, 10, 5, 4, armor)
	_fill(img, 7, 9, 3, 1, armor_light)
	_fill(img, 21, 10, 5, 4, armor)
	_fill(img, 22, 9, 3, 1, armor_light)

	# Arms
	_fill(img, 6, 14, 4, 5, armor)
	_fill(img, 22, 14, 4, 5, armor)
	# Gauntlets
	_fill(img, 5, 19, 4, 2, armor_dark)
	_fill(img, 23, 19, 4, 2, armor_dark)

	# Cape behind
	_fill(img, 10, 18, 12, 8, cape)
	_fill(img, 11, 17, 10, 1, cape)
	_fill(img, 9, 20, 2, 6, cape)
	_fill(img, 21, 20, 2, 6, cape)

	# Legs (armored)
	_fill(img, 12, 18, 3, 6, armor)
	_fill(img, 17, 18, 3, 6, armor)
	# Sabatons
	_fill(img, 11, 24, 4, 3, armor_dark)
	_fill(img, 17, 24, 4, 3, armor_dark)

	# Dark sword in right hand
	for i in range(12):
		_px(img, 4, 6 + i, sword)
		_px(img, 5, 6 + i, sword)
	# Sword guard
	_fill(img, 3, 18, 4, 1, armor_light)
	# Pommel
	_px(img, 4, 5, Color(0.7, 0.1, 0.08))
	_px(img, 5, 5, Color(0.7, 0.1, 0.08))

	_outline(img, Color(0.04, 0.03, 0.06))
	_save(img, "res://assets/sprites/enemies/castle/castle_knight.png")

func _gen_castle_gargoyle() -> void:
	var img = _img()
	var stone = Color(0.48, 0.46, 0.44)
	var stone_light = Color(0.58, 0.56, 0.52)
	var stone_dark = Color(0.35, 0.33, 0.32)
	var eye = Color(0.85, 0.5, 0.1)
	var wing_membrane = Color(0.42, 0.4, 0.38)

	# Horns
	_px(img, 10, 3, stone_dark)
	_px(img, 11, 2, stone_dark)
	_px(img, 21, 3, stone_dark)
	_px(img, 20, 2, stone_dark)

	# Head (angular, stone-like)
	_fill(img, 12, 4, 8, 6, stone)
	_fill(img, 11, 5, 10, 4, stone)
	# Brow ridge
	_fill(img, 11, 5, 10, 1, stone_dark)

	# Glowing eyes
	_fill(img, 13, 6, 2, 2, eye)
	_fill(img, 17, 6, 2, 2, eye)
	_px(img, 13, 6, Color(1.0, 0.7, 0.2))
	_px(img, 17, 6, Color(1.0, 0.7, 0.2))

	# Grimace mouth
	_fill(img, 13, 9, 6, 1, Color(0.2, 0.18, 0.18))
	_px(img, 14, 9, Color(0.9, 0.88, 0.85))
	_px(img, 16, 9, Color(0.9, 0.88, 0.85))

	# Muscular torso
	_fill(img, 11, 11, 10, 7, stone)
	_fill(img, 12, 10, 8, 1, stone)
	# Chest cracks
	_px(img, 14, 13, stone_dark)
	_px(img, 15, 14, stone_dark)
	_px(img, 18, 12, stone_dark)
	_px(img, 17, 13, stone_dark)

	# Wings spread wide
	# Left wing
	_fill(img, 2, 8, 9, 2, stone)
	_fill(img, 1, 10, 10, 2, wing_membrane)
	_fill(img, 2, 12, 9, 2, wing_membrane)
	_fill(img, 3, 14, 8, 2, wing_membrane)
	_fill(img, 4, 16, 7, 1, wing_membrane)
	# Wing bones
	_px(img, 3, 9, stone_dark)
	_px(img, 4, 10, stone_dark)
	_px(img, 5, 11, stone_dark)
	_px(img, 6, 12, stone_dark)

	# Right wing
	_fill(img, 21, 8, 9, 2, stone)
	_fill(img, 21, 10, 10, 2, wing_membrane)
	_fill(img, 21, 12, 9, 2, wing_membrane)
	_fill(img, 21, 14, 8, 2, wing_membrane)
	_fill(img, 21, 16, 7, 1, wing_membrane)
	_px(img, 28, 9, stone_dark)
	_px(img, 27, 10, stone_dark)
	_px(img, 26, 11, stone_dark)
	_px(img, 25, 12, stone_dark)

	# Arms/claws
	_fill(img, 8, 12, 3, 4, stone)
	_fill(img, 21, 12, 3, 4, stone)
	# Claws
	_px(img, 7, 16, stone_light)
	_px(img, 8, 16, stone_light)
	_px(img, 23, 16, stone_light)
	_px(img, 24, 16, stone_light)

	# Crouched legs
	_fill(img, 11, 18, 4, 4, stone)
	_fill(img, 17, 18, 4, 4, stone)
	# Clawed feet
	_fill(img, 10, 22, 5, 3, stone_dark)
	_fill(img, 17, 22, 5, 3, stone_dark)
	_px(img, 9, 24, stone_light)
	_px(img, 14, 24, stone_light)
	_px(img, 17, 24, stone_light)
	_px(img, 22, 24, stone_light)

	# Tail curling
	_px(img, 15, 22, stone)
	_px(img, 14, 23, stone)
	_px(img, 13, 24, stone)
	_px(img, 12, 25, stone_dark)

	# Stone texture spots
	_px(img, 12, 14, stone_light)
	_px(img, 19, 15, stone_light)
	_px(img, 15, 17, stone_light)

	_outline(img, Color(0.15, 0.14, 0.13))
	_save(img, "res://assets/sprites/enemies/castle/castle_gargoyle.png")

# ==================== CANDY ====================

func _gen_candy_gummy() -> void:
	var img = _img()
	var body = Color(0.85, 0.15, 0.12, 0.85)
	var body_light = Color(0.95, 0.3, 0.25, 0.8)
	var body_dark = Color(0.65, 0.08, 0.06, 0.9)
	var eye = Color(0.1, 0.1, 0.1)
	var highlight = Color(1.0, 0.6, 0.5, 0.5)

	# Bear head shape
	# Ears
	_fill(img, 9, 3, 4, 3, body)
	_fill(img, 19, 3, 4, 3, body)
	_fill(img, 10, 4, 2, 1, body_light)
	_fill(img, 20, 4, 2, 1, body_light)

	# Head
	_fill(img, 11, 5, 10, 7, body)
	_fill(img, 10, 7, 12, 4, body)

	# Angry eyes
	_fill(img, 13, 8, 2, 2, eye)
	_fill(img, 17, 8, 2, 2, eye)
	# Angry brows
	_px(img, 12, 7, eye)
	_px(img, 13, 7, eye)
	_px(img, 18, 7, eye)
	_px(img, 19, 7, eye)

	# Angry mouth (frown)
	_fill(img, 13, 11, 6, 1, eye)
	_px(img, 12, 10, eye)
	_px(img, 19, 10, eye)

	# Translucent body
	_fill(img, 11, 12, 10, 8, body)
	_fill(img, 10, 14, 12, 4, body)
	# Highlight/shine
	_fill(img, 12, 13, 3, 3, highlight)
	_px(img, 13, 14, Color(1.0, 0.8, 0.7, 0.4))

	# Belly lighter
	_fill(img, 14, 16, 4, 3, body_light)

	# Arms
	_fill(img, 7, 14, 3, 5, body)
	_fill(img, 22, 14, 3, 5, body)

	# Legs
	_fill(img, 11, 20, 4, 5, body)
	_fill(img, 17, 20, 4, 5, body)
	# Feet
	_fill(img, 10, 25, 5, 2, body_dark)
	_fill(img, 17, 25, 5, 2, body_dark)

	# Sugar coating sparkles
	_px(img, 19, 14, Color(1.0, 1.0, 1.0, 0.6))
	_px(img, 12, 18, Color(1.0, 1.0, 1.0, 0.6))
	_px(img, 20, 17, Color(1.0, 1.0, 1.0, 0.6))

	_outline(img, Color(0.4, 0.05, 0.04))
	_save(img, "res://assets/sprites/enemies/candy/candy_gummy.png")

func _gen_candy_cupcake() -> void:
	var img = _img()
	var wrapper = Color(0.85, 0.4, 0.55)
	var wrapper_dark = Color(0.65, 0.25, 0.4)
	var frosting = Color(0.95, 0.75, 0.85)
	var frosting_top = Color(1.0, 0.85, 0.92)
	var cherry = Color(0.9, 0.12, 0.15)
	var eye = Color(0.1, 0.1, 0.1)
	var teeth = Color(0.95, 0.95, 0.95)

	# Cherry on top
	_fill(img, 14, 2, 4, 3, cherry)
	_fill(img, 15, 1, 2, 1, cherry)
	_px(img, 15, 2, Color(1.0, 0.4, 0.3))
	# Stem
	_px(img, 16, 0, Color(0.2, 0.5, 0.15))
	_px(img, 17, 0, Color(0.2, 0.5, 0.15))

	# Frosting (swirled dome)
	_fill(img, 10, 5, 12, 3, frosting)
	_fill(img, 9, 7, 14, 3, frosting)
	_fill(img, 8, 10, 16, 2, frosting_top)
	# Frosting swirl details
	_fill(img, 12, 6, 3, 1, frosting_top)
	_fill(img, 17, 7, 3, 1, frosting_top)
	_fill(img, 11, 9, 3, 1, frosting_top)

	# Sharp frosting teeth (mouth)
	_fill(img, 11, 12, 10, 2, Color(0.2, 0.08, 0.1))
	# Pointed teeth
	_px(img, 12, 12, teeth)
	_px(img, 14, 12, teeth)
	_px(img, 16, 12, teeth)
	_px(img, 18, 12, teeth)
	_px(img, 20, 12, teeth)
	_px(img, 13, 13, teeth)
	_px(img, 15, 13, teeth)
	_px(img, 17, 13, teeth)
	_px(img, 19, 13, teeth)

	# Evil eyes (above frosting)
	_fill(img, 11, 8, 3, 2, eye)
	_fill(img, 18, 8, 3, 2, eye)
	_px(img, 12, 8, Color(0.9, 0.2, 0.15))
	_px(img, 19, 8, Color(0.9, 0.2, 0.15))

	# Wrapper/cup body
	_fill(img, 8, 14, 16, 8, wrapper)
	_fill(img, 9, 22, 14, 3, wrapper)
	_fill(img, 10, 25, 12, 2, wrapper)
	# Wrapper ridges
	for y in [16, 19, 22]:
		_fill(img, 8, y, 16, 1, wrapper_dark)
	# Wrapper vertical lines
	for x in [10, 13, 16, 19, 22]:
		for y in range(14, 27):
			if img.get_pixel(x, y).a > 0:
				_px(img, x, y, wrapper_dark)

	# Tiny arms from wrapper
	_fill(img, 5, 16, 3, 2, wrapper)
	_fill(img, 24, 16, 3, 2, wrapper)

	_outline(img, Color(0.3, 0.12, 0.18))
	_save(img, "res://assets/sprites/enemies/candy/candy_cupcake.png")

func _gen_candy_jawbreaker() -> void:
	var img = _img()
	var ring1 = Color(0.9, 0.2, 0.2)
	var ring2 = Color(0.2, 0.5, 0.9)
	var ring3 = Color(0.9, 0.85, 0.2)
	var ring4 = Color(0.3, 0.8, 0.3)
	var center = Color(0.95, 0.95, 0.9)
	var eye = Color(0.1, 0.1, 0.1)

	# Outer ring (red) - circle approximation
	_fill(img, 10, 3, 12, 2, ring1)
	_fill(img, 7, 5, 18, 2, ring1)
	_fill(img, 5, 7, 22, 2, ring1)
	_fill(img, 4, 9, 24, 2, ring1)
	_fill(img, 3, 11, 26, 2, ring1)
	_fill(img, 3, 13, 26, 2, ring1)
	_fill(img, 3, 15, 26, 2, ring1)
	_fill(img, 3, 17, 26, 2, ring1)
	_fill(img, 4, 19, 24, 2, ring1)
	_fill(img, 5, 21, 22, 2, ring1)
	_fill(img, 7, 23, 18, 2, ring1)
	_fill(img, 10, 25, 12, 2, ring1)

	# Second ring (blue)
	_fill(img, 11, 5, 10, 2, ring2)
	_fill(img, 9, 7, 14, 2, ring2)
	_fill(img, 7, 9, 18, 2, ring2)
	_fill(img, 6, 11, 20, 2, ring2)
	_fill(img, 6, 13, 20, 2, ring2)
	_fill(img, 6, 15, 20, 2, ring2)
	_fill(img, 7, 17, 18, 2, ring2)
	_fill(img, 9, 19, 14, 2, ring2)
	_fill(img, 11, 21, 10, 2, ring2)

	# Third ring (yellow)
	_fill(img, 12, 7, 8, 2, ring3)
	_fill(img, 10, 9, 12, 2, ring3)
	_fill(img, 9, 11, 14, 6, ring3)
	_fill(img, 10, 17, 12, 2, ring3)
	_fill(img, 12, 19, 8, 2, ring3)

	# Fourth ring (green)
	_fill(img, 13, 9, 6, 2, ring4)
	_fill(img, 12, 11, 8, 6, ring4)
	_fill(img, 13, 17, 6, 2, ring4)

	# Center
	_fill(img, 14, 12, 4, 4, center)

	# Angry face on center
	_px(img, 13, 13, eye)
	_px(img, 18, 13, eye)
	# Angry brows
	_px(img, 12, 12, eye)
	_px(img, 13, 12, eye)
	_px(img, 18, 12, eye)
	_px(img, 19, 12, eye)
	# Frown
	_px(img, 14, 16, eye)
	_px(img, 15, 17, eye)
	_px(img, 16, 17, eye)
	_px(img, 17, 16, eye)

	# Highlight/shine
	_px(img, 9, 7, Color(1.0, 1.0, 1.0, 0.5))
	_px(img, 10, 8, Color(1.0, 1.0, 1.0, 0.4))
	_px(img, 10, 7, Color(1.0, 1.0, 1.0, 0.3))

	_outline(img, Color(0.15, 0.08, 0.08))
	_save(img, "res://assets/sprites/enemies/candy/candy_jawbreaker.png")

func _gen_candy_licorice() -> void:
	var img = _img()
	var body = Color(0.12, 0.1, 0.12)
	var body_light = Color(0.22, 0.18, 0.22)
	var body_dark = Color(0.06, 0.04, 0.06)
	var eye = Color(0.85, 0.2, 0.15)
	var highlight = Color(0.3, 0.25, 0.3)

	# Coiled body (spiral from bottom to top)
	# Bottom coil
	_fill(img, 8, 24, 16, 3, body)
	_fill(img, 7, 25, 18, 2, body)
	_fill(img, 9, 23, 14, 1, body)

	# Middle coil
	_fill(img, 6, 18, 16, 3, body)
	_fill(img, 5, 19, 18, 2, body)
	_fill(img, 7, 17, 14, 1, body)
	# Connection from bottom to middle
	_fill(img, 22, 20, 3, 4, body)

	# Upper coil
	_fill(img, 8, 12, 16, 3, body)
	_fill(img, 7, 13, 18, 2, body)
	_fill(img, 9, 11, 14, 1, body)
	# Connection from middle to upper
	_fill(img, 5, 14, 3, 4, body)

	# Head (raised from top coil)
	_fill(img, 20, 6, 6, 6, body)
	_fill(img, 19, 7, 8, 4, body)
	# Connection neck
	_fill(img, 22, 11, 3, 2, body)

	# Ridges on body
	_fill(img, 10, 24, 12, 1, body_light)
	_fill(img, 8, 18, 12, 1, body_light)
	_fill(img, 10, 12, 12, 1, body_light)

	# Highlight/sheen
	_px(img, 12, 23, highlight)
	_px(img, 10, 17, highlight)
	_px(img, 14, 11, highlight)

	# Angry eyes (red glow)
	_fill(img, 20, 8, 2, 2, eye)
	_fill(img, 24, 8, 2, 2, eye)
	_px(img, 21, 8, Color(1.0, 0.5, 0.3))
	_px(img, 25, 8, Color(1.0, 0.5, 0.3))

	# Mouth
	_fill(img, 21, 11, 4, 1, Color(0.4, 0.08, 0.08))

	# Tail tip (thin, whip-like at bottom)
	_px(img, 7, 26, body)
	_px(img, 6, 27, body)
	_px(img, 5, 28, body_light)

	_outline(img, Color(0.2, 0.15, 0.2))
	_save(img, "res://assets/sprites/enemies/candy/candy_licorice.png")

# ==================== CEMETERY ====================

func _gen_cemetery_zombie() -> void:
	var img = _img()
	var skin = Color(0.35, 0.55, 0.3)
	var skin_dark = Color(0.25, 0.42, 0.2)
	var shirt = Color(0.45, 0.42, 0.38)
	var shirt_torn = Color(0.35, 0.32, 0.28)
	var pants = Color(0.3, 0.28, 0.35)
	var eye = Color(0.9, 0.85, 0.2)
	var blood = Color(0.55, 0.1, 0.08)
	var hair = Color(0.25, 0.2, 0.18)

	# Messy hair
	_fill(img, 12, 2, 8, 3, hair)
	_px(img, 11, 3, hair)
	_px(img, 20, 3, hair)
	_px(img, 13, 1, hair)
	_px(img, 17, 1, hair)

	# Head
	_fill(img, 12, 4, 8, 7, skin)
	_fill(img, 11, 6, 10, 4, skin)
	# Sunken cheek
	_fill(img, 12, 8, 2, 2, skin_dark)

	# Glowing yellow eyes
	_fill(img, 13, 6, 2, 2, eye)
	_fill(img, 17, 6, 2, 2, eye)
	_px(img, 14, 7, Color(0.1, 0.1, 0.1))
	_px(img, 18, 7, Color(0.1, 0.1, 0.1))

	# Open mouth (groaning)
	_fill(img, 14, 9, 4, 2, Color(0.2, 0.1, 0.08))
	_px(img, 15, 9, Color(0.8, 0.78, 0.75))
	_px(img, 17, 9, Color(0.8, 0.78, 0.75))

	# Torn shirt
	_fill(img, 11, 11, 10, 7, shirt)
	_fill(img, 10, 12, 12, 5, shirt)
	# Torn edges
	_px(img, 10, 17, shirt_torn)
	_px(img, 21, 16, shirt_torn)
	_px(img, 11, 18, shirt_torn)
	# Blood stains
	_fill(img, 17, 13, 3, 2, blood)
	_px(img, 12, 15, blood)

	# Arms forward (zombie pose)
	_fill(img, 5, 12, 5, 2, skin)
	_fill(img, 3, 13, 4, 2, skin)
	_fill(img, 1, 14, 3, 2, skin)
	# Right arm forward
	_fill(img, 22, 12, 5, 2, skin)
	_fill(img, 25, 13, 4, 2, skin)
	_fill(img, 28, 14, 3, 2, skin)
	# Decayed fingers
	_px(img, 0, 14, skin_dark)
	_px(img, 0, 15, skin_dark)
	_px(img, 30, 14, skin_dark)
	_px(img, 30, 15, skin_dark)

	# Torn pants
	_fill(img, 12, 18, 3, 6, pants)
	_fill(img, 17, 18, 3, 6, pants)
	_px(img, 12, 23, shirt_torn)
	_px(img, 19, 22, shirt_torn)

	# Feet
	_fill(img, 11, 24, 4, 2, skin_dark)
	_fill(img, 17, 24, 4, 2, skin_dark)

	# Exposed bone on arm
	_px(img, 4, 12, Color(0.85, 0.82, 0.78))

	_outline(img, Color(0.1, 0.18, 0.08))
	_save(img, "res://assets/sprites/enemies/cemetery/cemetery_zombie.png")

func _gen_cemetery_wraith() -> void:
	var img = _img()
	var body = Color(0.18, 0.08, 0.25, 0.75)
	var body_light = Color(0.3, 0.15, 0.4, 0.6)
	var body_dark = Color(0.1, 0.04, 0.15, 0.85)
	var eye = Color(0.6, 0.2, 0.8)
	var eye_glow = Color(0.8, 0.4, 1.0)

	# Floating hood/head
	_fill(img, 11, 3, 10, 3, body_dark)
	_fill(img, 10, 6, 12, 5, body)
	_fill(img, 9, 8, 14, 3, body)
	# Hood peak
	_fill(img, 14, 1, 4, 2, body_dark)
	_fill(img, 13, 2, 6, 1, body_dark)

	# Glowing eyes (purple/violet)
	_fill(img, 12, 7, 3, 2, eye)
	_fill(img, 17, 7, 3, 2, eye)
	_px(img, 13, 7, eye_glow)
	_px(img, 18, 7, eye_glow)
	# Eye glow effect
	_px(img, 11, 7, Color(0.4, 0.15, 0.6, 0.4))
	_px(img, 15, 7, Color(0.4, 0.15, 0.6, 0.4))
	_px(img, 16, 7, Color(0.4, 0.15, 0.6, 0.4))
	_px(img, 20, 7, Color(0.4, 0.15, 0.6, 0.4))

	# Flowing body (tapers down, tattered)
	_fill(img, 10, 11, 12, 4, body)
	_fill(img, 9, 15, 14, 3, body)
	_fill(img, 8, 18, 16, 3, body_light)
	_fill(img, 7, 21, 18, 2, body_light)

	# Tattered bottom edges (wispy)
	_px(img, 6, 23, body_light)
	_px(img, 8, 24, body_light)
	_px(img, 11, 23, body)
	_px(img, 14, 24, body_light)
	_px(img, 17, 23, body)
	_px(img, 20, 24, body_light)
	_px(img, 23, 23, body_light)
	_px(img, 25, 23, body_light)
	_px(img, 10, 25, Color(0.2, 0.1, 0.3, 0.3))
	_px(img, 16, 25, Color(0.2, 0.1, 0.3, 0.3))
	_px(img, 22, 25, Color(0.2, 0.1, 0.3, 0.3))

	# Ghostly arms reaching out
	_fill(img, 5, 12, 5, 2, body)
	_fill(img, 3, 14, 4, 2, body_light)
	_px(img, 2, 15, body_light)
	_px(img, 1, 16, Color(0.25, 0.12, 0.35, 0.4))

	_fill(img, 22, 12, 5, 2, body)
	_fill(img, 25, 14, 4, 2, body_light)
	_px(img, 29, 15, body_light)
	_px(img, 30, 16, Color(0.25, 0.12, 0.35, 0.4))

	# Dark inner shadow
	_fill(img, 13, 10, 6, 2, body_dark)

	_outline(img, Color(0.06, 0.02, 0.1))
	_save(img, "res://assets/sprites/enemies/cemetery/cemetery_wraith.png")

func _gen_cemetery_hand() -> void:
	var img = _img()
	var bone = Color(0.85, 0.82, 0.75)
	var bone_dark = Color(0.65, 0.6, 0.55)
	var bone_light = Color(0.92, 0.9, 0.85)
	var ground = Color(0.35, 0.25, 0.18)
	var ground_dark = Color(0.25, 0.18, 0.12)
	var dirt = Color(0.45, 0.35, 0.22)

	# Ground/dirt at bottom
	_fill(img, 0, 22, 32, 10, ground)
	_fill(img, 0, 23, 32, 9, ground_dark)
	# Dirt mound around hand
	_fill(img, 8, 20, 16, 3, dirt)
	_fill(img, 10, 19, 12, 1, dirt)
	_fill(img, 6, 21, 20, 2, ground)
	# Scattered dirt particles
	_px(img, 7, 19, dirt)
	_px(img, 24, 19, dirt)
	_px(img, 5, 20, ground)
	_px(img, 26, 20, ground)

	# Wrist/forearm coming from ground
	_fill(img, 14, 16, 4, 5, bone)
	_fill(img, 13, 18, 6, 3, bone)
	# Joint detail
	_fill(img, 14, 17, 4, 1, bone_dark)

	# Palm
	_fill(img, 12, 12, 8, 5, bone)
	_fill(img, 11, 13, 10, 3, bone)

	# Fingers (spread, reaching)
	# Index finger (leftmost)
	_fill(img, 10, 6, 2, 7, bone)
	_fill(img, 10, 5, 2, 1, bone_light)
	_px(img, 10, 4, bone_light)
	# Knuckle
	_px(img, 10, 10, bone_dark)

	# Middle finger (tallest)
	_fill(img, 13, 4, 2, 9, bone)
	_fill(img, 13, 2, 2, 2, bone_light)
	_px(img, 13, 1, bone_light)
	_px(img, 13, 8, bone_dark)

	# Ring finger
	_fill(img, 16, 5, 2, 8, bone)
	_fill(img, 16, 3, 2, 2, bone_light)
	_px(img, 16, 9, bone_dark)

	# Pinky
	_fill(img, 19, 7, 2, 6, bone)
	_fill(img, 19, 6, 2, 1, bone_light)
	_px(img, 19, 10, bone_dark)

	# Thumb (to the side)
	_fill(img, 8, 12, 3, 2, bone)
	_fill(img, 7, 10, 2, 3, bone)
	_px(img, 6, 10, bone_light)

	# Cracks on bones
	_px(img, 14, 14, bone_dark)
	_px(img, 15, 15, bone_dark)
	_px(img, 11, 7, bone_dark)
	_px(img, 17, 6, bone_dark)

	_outline(img, Color(0.2, 0.18, 0.15))
	_save(img, "res://assets/sprites/enemies/cemetery/cemetery_hand.png")

func _gen_cemetery_reaper() -> void:
	var img = _img()
	var robe = Color(0.1, 0.08, 0.12)
	var robe_dark = Color(0.05, 0.03, 0.06)
	var robe_edge = Color(0.18, 0.15, 0.2)
	var scythe_handle = Color(0.4, 0.25, 0.15)
	var scythe_blade = Color(0.7, 0.72, 0.75)
	var scythe_edge = Color(0.85, 0.87, 0.9)
	var eye = Color(0.9, 0.2, 0.1)

	# Hood
	_fill(img, 12, 3, 8, 4, robe)
	_fill(img, 11, 5, 10, 3, robe)
	_fill(img, 13, 2, 6, 1, robe)
	# Hood shadow inside
	_fill(img, 13, 5, 6, 3, robe_dark)

	# Glowing red eyes in hood
	_fill(img, 14, 6, 2, 1, eye)
	_fill(img, 18, 6, 2, 1, eye)
	_px(img, 14, 6, Color(1.0, 0.4, 0.2))
	_px(img, 18, 6, Color(1.0, 0.4, 0.2))

	# Robe body
	_fill(img, 11, 8, 10, 10, robe)
	_fill(img, 10, 10, 12, 6, robe)
	# Robe widens at bottom
	_fill(img, 9, 18, 14, 3, robe)
	_fill(img, 8, 21, 16, 3, robe)
	_fill(img, 7, 24, 18, 3, robe_edge)

	# Tattered bottom
	_px(img, 7, 27, robe)
	_px(img, 9, 27, robe_edge)
	_px(img, 12, 27, robe)
	_px(img, 16, 27, robe_edge)
	_px(img, 20, 27, robe)
	_px(img, 24, 27, robe_edge)

	# Robe fold details
	_fill(img, 15, 10, 2, 10, robe_dark)
	_px(img, 12, 14, robe_edge)
	_px(img, 19, 16, robe_edge)

	# Skeletal hand holding scythe
	_fill(img, 7, 12, 3, 2, Color(0.85, 0.82, 0.78))
	_px(img, 6, 12, Color(0.85, 0.82, 0.78))

	# Scythe handle (long diagonal)
	for i in range(18):
		_px(img, 4 + i, 4 + i, scythe_handle)
		if i < 17:
			_px(img, 5 + i, 4 + i, scythe_handle)

	# Scythe blade (curved at top)
	_fill(img, 2, 2, 4, 2, scythe_blade)
	_fill(img, 0, 3, 4, 2, scythe_blade)
	_fill(img, 0, 5, 3, 1, scythe_blade)
	_px(img, 0, 6, scythe_blade)
	# Blade edge (brighter)
	_px(img, 0, 3, scythe_edge)
	_px(img, 0, 4, scythe_edge)
	_px(img, 0, 5, scythe_edge)
	_px(img, 0, 6, scythe_edge)
	_px(img, 1, 2, scythe_edge)

	_outline(img, Color(0.03, 0.02, 0.05))
	_save(img, "res://assets/sprites/enemies/cemetery/cemetery_reaper.png")
