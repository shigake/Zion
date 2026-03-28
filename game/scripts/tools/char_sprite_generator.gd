extends SceneTree

## Generates pixel art PNG sprites for the 9 remaining characters.
## Run: godot --headless --script res://scripts/tools/char_sprite_generator.gd

const SPRITE_SIZE := 32

func _init() -> void:
	_generate_berserker()
	_generate_ninja()
	_generate_necro()
	_generate_pirata()
	_generate_engenheiro()
	_generate_vampiro()
	_generate_gladiador()
	_generate_chef()
	_generate_mystery()
	print("All 9 character sprites generated!")
	quit()

func _save_sprite(img: Image, path: String) -> void:
	var dir = path.get_base_dir()
	if not DirAccess.dir_exists_absolute(dir):
		DirAccess.make_dir_recursive_absolute(dir)
	img.save_png(path)
	print("Saved: ", path)

# ==================== HELPERS ====================
func _fill_rect(img: Image, x: int, y: int, w: int, h: int, color: Color) -> void:
	for px in range(x, mini(x + w, SPRITE_SIZE)):
		for py in range(y, mini(y + h, SPRITE_SIZE)):
			if px >= 0 and py >= 0:
				img.set_pixel(px, py, color)

func _add_outline(img: Image, color: Color) -> void:
	var outline_img = Image.create(SPRITE_SIZE, SPRITE_SIZE, false, Image.FORMAT_RGBA8)
	for x in range(SPRITE_SIZE):
		for y in range(SPRITE_SIZE):
			if img.get_pixel(x, y).a > 0:
				continue
			var has_neighbor := false
			for offset in [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]:
				var nx = x + offset.x
				var ny = y + offset.y
				if nx >= 0 and nx < SPRITE_SIZE and ny >= 0 and ny < SPRITE_SIZE:
					if img.get_pixel(nx, ny).a > 0:
						has_neighbor = true
						break
			if has_neighbor:
				outline_img.set_pixel(x, y, color)
	for x in range(SPRITE_SIZE):
		for y in range(SPRITE_SIZE):
			if outline_img.get_pixel(x, y).a > 0:
				img.set_pixel(x, y, outline_img.get_pixel(x, y))

func _set_px(img: Image, x: int, y: int, color: Color) -> void:
	if x >= 0 and x < SPRITE_SIZE and y >= 0 and y < SPRITE_SIZE:
		img.set_pixel(x, y, color)

# ==================== BERSERKER ====================
func _generate_berserker() -> void:
	var img = Image.create(SPRITE_SIZE, SPRITE_SIZE, false, Image.FORMAT_RGBA8)
	var skin = Color(0.72, 0.45, 0.35)  # Dark reddish skin
	var skin_scar = Color(0.85, 0.5, 0.4)
	var hair = Color(0.6, 0.3, 0.15)  # Reddish brown
	var helmet = Color(0.5, 0.5, 0.45)  # Metal grey
	var horn = Color(0.75, 0.7, 0.55)  # Bone color
	var pants = Color(0.45, 0.2, 0.15)  # Dark red-brown
	var belt_col = Color(0.35, 0.25, 0.15)
	var axe_handle = Color(0.4, 0.25, 0.12)
	var axe_blade = Color(0.65, 0.68, 0.72)
	var boots = Color(0.3, 0.2, 0.12)
	var outline = Color(0.12, 0.06, 0.04)

	# Horns (rows 1-5)
	_fill_rect(img, 9, 2, 2, 1, horn)
	_fill_rect(img, 8, 3, 2, 1, horn)
	img.set_pixel(7, 4, horn)
	_fill_rect(img, 21, 2, 2, 1, horn)
	_fill_rect(img, 22, 3, 2, 1, horn)
	img.set_pixel(24, 4, horn)

	# Helmet (rows 3-6)
	_fill_rect(img, 11, 3, 10, 2, helmet)
	_fill_rect(img, 10, 5, 12, 1, helmet)
	# Helmet band
	_fill_rect(img, 10, 5, 12, 1, helmet.darkened(0.2))

	# Hair sides
	_fill_rect(img, 10, 6, 1, 3, hair)
	_fill_rect(img, 21, 6, 1, 3, hair)

	# Face (rows 6-9)
	_fill_rect(img, 11, 6, 10, 4, skin)
	# Eyes — angry
	img.set_pixel(13, 7, Color(0.9, 0.15, 0.1))  # Red eyes
	img.set_pixel(18, 7, Color(0.9, 0.15, 0.1))
	img.set_pixel(13, 8, outline)
	img.set_pixel(18, 8, outline)
	# Mouth / teeth
	_fill_rect(img, 14, 9, 4, 1, Color(0.3, 0.1, 0.08))
	img.set_pixel(15, 9, Color(0.9, 0.9, 0.85))
	img.set_pixel(16, 9, Color(0.9, 0.9, 0.85))

	# Bare chest (rows 10-14, wide muscular)
	_fill_rect(img, 9, 10, 14, 5, skin)
	# Scars on chest
	for i in range(4):
		_set_px(img, 12 + i, 11 + (i % 2), skin_scar)
	for i in range(3):
		_set_px(img, 18 + i, 12, skin_scar)
	# Pectoral shading
	_fill_rect(img, 11, 11, 3, 1, skin.darkened(0.1))
	_fill_rect(img, 18, 11, 3, 1, skin.darkened(0.1))
	# Abs
	_set_px(img, 15, 13, skin.darkened(0.12))
	_set_px(img, 16, 13, skin.darkened(0.12))

	# Belt
	_fill_rect(img, 9, 15, 14, 1, belt_col)
	_set_px(img, 16, 15, Color(0.7, 0.6, 0.2))  # Buckle

	# Arms (big muscular)
	_fill_rect(img, 7, 10, 2, 5, skin)
	_fill_rect(img, 23, 10, 2, 5, skin)
	# Forearm bands
	_fill_rect(img, 7, 13, 2, 1, belt_col)
	_fill_rect(img, 23, 13, 2, 1, belt_col)
	# Fists
	_fill_rect(img, 6, 15, 2, 2, skin)
	_fill_rect(img, 24, 15, 2, 2, skin)

	# Pants
	_fill_rect(img, 10, 16, 12, 5, pants)
	# Legs separation
	_fill_rect(img, 15, 18, 2, 3, pants.darkened(0.15))

	# Boots
	_fill_rect(img, 9, 21, 5, 3, boots)
	_fill_rect(img, 18, 21, 5, 3, boots)
	# Boot fur trim
	_fill_rect(img, 9, 21, 5, 1, Color(0.6, 0.55, 0.45))
	_fill_rect(img, 18, 21, 5, 1, Color(0.6, 0.55, 0.45))

	# Axe (right side)
	# Handle
	for i in range(10):
		_set_px(img, 5, 8 + i, axe_handle)
	# Blade (top)
	_fill_rect(img, 2, 7, 3, 2, axe_blade)
	_fill_rect(img, 1, 8, 4, 3, axe_blade)
	_fill_rect(img, 2, 11, 3, 1, axe_blade)
	# Blade edge highlight
	img.set_pixel(1, 9, axe_blade.lightened(0.3))

	_add_outline(img, outline)
	_save_sprite(img, "res://assets/sprites/characters/berserker.png")

# ==================== NINJA ====================
func _generate_ninja() -> void:
	var img = Image.create(SPRITE_SIZE, SPRITE_SIZE, false, Image.FORMAT_RGBA8)
	var cloth = Color(0.12, 0.12, 0.15)  # Near black
	var cloth_light = Color(0.2, 0.2, 0.25)
	var scarf = Color(0.85, 0.12, 0.12)  # Red scarf
	var eyes = Color(0.9, 0.15, 0.1)  # Red glowing eyes
	var skin = Color(0.8, 0.7, 0.6)
	var star = Color(0.7, 0.72, 0.75)  # Metal shuriken
	var outline = Color(0.05, 0.05, 0.08)

	# Head wrap (rows 4-9)
	_fill_rect(img, 12, 4, 8, 2, cloth)
	_fill_rect(img, 11, 6, 10, 4, cloth)
	# Eye slit (exposed skin strip)
	_fill_rect(img, 12, 7, 8, 2, skin.darkened(0.15))
	# Glowing red eyes
	_fill_rect(img, 13, 7, 2, 2, eyes)
	_fill_rect(img, 17, 7, 2, 2, eyes)
	# Eye glow center
	img.set_pixel(13, 7, eyes.lightened(0.3))
	img.set_pixel(17, 7, eyes.lightened(0.3))

	# Scarf flowing right (rows 6-14)
	_fill_rect(img, 21, 6, 2, 2, scarf)
	_fill_rect(img, 22, 8, 2, 2, scarf)
	_fill_rect(img, 23, 10, 3, 2, scarf)
	_fill_rect(img, 24, 12, 3, 2, scarf)
	_fill_rect(img, 25, 14, 2, 2, scarf.darkened(0.15))
	# Scarf at neck
	_fill_rect(img, 12, 9, 8, 1, scarf)
	_fill_rect(img, 19, 7, 3, 3, scarf)

	# Body (slim, rows 10-16)
	_fill_rect(img, 12, 10, 8, 7, cloth)
	# Chest wrap / armor plate
	_fill_rect(img, 13, 11, 6, 2, cloth_light)
	# Belt / sash
	_fill_rect(img, 12, 14, 8, 1, scarf.darkened(0.2))

	# Arms (slim)
	_fill_rect(img, 10, 10, 2, 5, cloth)
	_fill_rect(img, 20, 10, 2, 5, cloth)
	# Hands
	_fill_rect(img, 9, 15, 2, 1, skin)
	_fill_rect(img, 21, 15, 2, 1, skin)

	# Legs (rows 17-22)
	_fill_rect(img, 12, 17, 3, 5, cloth)
	_fill_rect(img, 17, 17, 3, 5, cloth)
	# Leg wraps
	for i in range(3):
		_set_px(img, 13, 18 + i, cloth_light)
		_set_px(img, 18, 18 + i, cloth_light)

	# Feet / tabi boots
	_fill_rect(img, 11, 22, 4, 2, cloth_light)
	_fill_rect(img, 17, 22, 4, 2, cloth_light)
	# Split tabi toe
	img.set_pixel(12, 23, cloth.darkened(0.1))
	img.set_pixel(19, 23, cloth.darkened(0.1))

	# Shuriken (left hand area)
	# Cross shape
	_set_px(img, 7, 14, star)
	_set_px(img, 8, 13, star)
	_set_px(img, 8, 14, star.lightened(0.2))
	_set_px(img, 8, 15, star)
	_set_px(img, 9, 14, star)
	# Second shuriken higher
	_set_px(img, 6, 10, star)
	_set_px(img, 7, 9, star)
	_set_px(img, 7, 10, star.lightened(0.2))
	_set_px(img, 7, 11, star)
	_set_px(img, 8, 10, star)

	_add_outline(img, outline)
	_save_sprite(img, "res://assets/sprites/characters/ninja.png")

# ==================== NECRO ====================
func _generate_necro() -> void:
	var img = Image.create(SPRITE_SIZE, SPRITE_SIZE, false, Image.FORMAT_RGBA8)
	var robe = Color(0.12, 0.25, 0.12)  # Dark green
	var robe_dark = Color(0.08, 0.18, 0.08)
	var robe_light = Color(0.18, 0.35, 0.18)
	var glow = Color(0.3, 0.95, 0.3)  # Green glow
	var glow_dim = Color(0.2, 0.7, 0.2)
	var bone = Color(0.85, 0.82, 0.75)
	var bone_dark = Color(0.65, 0.6, 0.52)
	var staff_wood = Color(0.3, 0.2, 0.1)
	var outline = Color(0.05, 0.1, 0.05)

	# Hood (rows 2-9, pointed top)
	_fill_rect(img, 14, 2, 4, 1, robe)
	_fill_rect(img, 13, 3, 6, 1, robe)
	_fill_rect(img, 12, 4, 8, 1, robe)
	_fill_rect(img, 11, 5, 10, 1, robe)
	_fill_rect(img, 10, 6, 12, 4, robe)
	# Hood edge highlight
	_fill_rect(img, 10, 6, 1, 4, robe_light)
	_fill_rect(img, 21, 6, 1, 4, robe_light)

	# Face shadow under hood
	_fill_rect(img, 12, 7, 8, 3, Color(0.05, 0.08, 0.05))
	# Glowing eyes in shadow
	_fill_rect(img, 13, 8, 2, 1, glow)
	_fill_rect(img, 17, 8, 2, 1, glow)
	# Eye glow effect (lighter center)
	img.set_pixel(13, 8, glow.lightened(0.3))
	img.set_pixel(17, 8, glow.lightened(0.3))
	# Faint glow below eyes
	_set_px(img, 13, 9, glow_dim.darkened(0.5))
	_set_px(img, 18, 9, glow_dim.darkened(0.5))

	# Robe body (rows 10-22)
	_fill_rect(img, 10, 10, 12, 4, robe)
	# Wider robe skirt
	_fill_rect(img, 8, 14, 16, 5, robe)
	_fill_rect(img, 7, 19, 18, 3, robe)
	_fill_rect(img, 8, 22, 16, 3, robe_dark)
	# Robe center seam
	for y in range(10, 25):
		_set_px(img, 16, y, robe_dark)
	# Robe trim
	_fill_rect(img, 7, 19, 18, 1, robe_light)

	# Bony hands reaching out
	_fill_rect(img, 7, 13, 3, 1, bone)
	_fill_rect(img, 6, 14, 2, 2, bone)
	img.set_pixel(6, 15, bone_dark)  # Finger
	img.set_pixel(7, 15, bone_dark)
	# Right hand holds staff
	_fill_rect(img, 22, 13, 3, 1, bone)
	_fill_rect(img, 23, 14, 2, 1, bone)

	# Staff (right side, rows 2-24)
	for y in range(4, 25):
		_set_px(img, 25, y, staff_wood)
	# Skull on top of staff
	_fill_rect(img, 24, 1, 3, 3, bone)
	_fill_rect(img, 24, 1, 3, 1, bone.lightened(0.1))
	# Skull eyes
	img.set_pixel(24, 2, outline)
	img.set_pixel(26, 2, outline)
	# Skull nose
	img.set_pixel(25, 3, bone_dark)
	# Skull jaw
	_fill_rect(img, 24, 4, 3, 1, bone_dark)

	# Green glow around skull
	_set_px(img, 23, 1, glow_dim)
	_set_px(img, 27, 1, glow_dim)
	_set_px(img, 23, 3, glow_dim)
	_set_px(img, 27, 3, glow_dim)
	_set_px(img, 25, 0, glow_dim)

	# Feet barely visible
	_fill_rect(img, 10, 25, 4, 1, robe_dark.darkened(0.1))
	_fill_rect(img, 18, 25, 4, 1, robe_dark.darkened(0.1))

	_add_outline(img, outline)
	_save_sprite(img, "res://assets/sprites/characters/necro.png")

# ==================== PIRATA ====================
func _generate_pirata() -> void:
	var img = Image.create(SPRITE_SIZE, SPRITE_SIZE, false, Image.FORMAT_RGBA8)
	var skin = Color(0.82, 0.65, 0.48)
	var hat = Color(0.3, 0.2, 0.12)  # Brown tricorn
	var hat_edge = Color(0.55, 0.45, 0.3)
	var coat = Color(0.45, 0.25, 0.15)  # Brown coat
	var coat_light = Color(0.55, 0.35, 0.2)
	var shirt = Color(0.85, 0.8, 0.7)  # Cream shirt
	var pants_col = Color(0.3, 0.25, 0.18)
	var belt_col = Color(0.25, 0.18, 0.1)
	var gold = Color(0.85, 0.72, 0.2)
	var boots = Color(0.2, 0.15, 0.08)
	var eyepatch = Color(0.1, 0.1, 0.1)
	var outline = Color(0.1, 0.08, 0.05)

	# Tricorn hat (rows 2-7)
	_fill_rect(img, 12, 3, 8, 2, hat)
	_fill_rect(img, 10, 5, 12, 1, hat)
	# Hat brim (tricorn shape — wider sides, folded up)
	_fill_rect(img, 8, 6, 16, 1, hat_edge)
	_fill_rect(img, 7, 5, 2, 2, hat_edge)  # Left fold
	_fill_rect(img, 23, 5, 2, 2, hat_edge)  # Right fold
	# Hat top ornament
	_fill_rect(img, 14, 2, 4, 1, hat)
	# Skull emblem on hat
	img.set_pixel(15, 3, Color(0.8, 0.8, 0.75))
	img.set_pixel(16, 3, Color(0.8, 0.8, 0.75))
	img.set_pixel(15, 4, Color(0.8, 0.8, 0.75))
	img.set_pixel(16, 4, Color(0.8, 0.8, 0.75))

	# Face (rows 7-10)
	_fill_rect(img, 12, 7, 8, 4, skin)
	# Eye (left)
	img.set_pixel(14, 8, outline)
	# Eyepatch (right)
	_fill_rect(img, 17, 8, 2, 2, eyepatch)
	# Eyepatch string
	img.set_pixel(16, 7, eyepatch)
	img.set_pixel(19, 7, eyepatch)
	# Mouth / stubble
	_fill_rect(img, 14, 10, 4, 1, skin.darkened(0.15))
	img.set_pixel(15, 10, Color(0.6, 0.3, 0.25))

	# Gold earring (left)
	img.set_pixel(11, 8, gold)
	img.set_pixel(11, 9, gold)

	# Coat (rows 11-19)
	_fill_rect(img, 10, 11, 12, 3, coat)
	# Open coat revealing shirt
	_fill_rect(img, 13, 11, 6, 3, shirt)
	# Coat tails
	_fill_rect(img, 9, 14, 3, 6, coat)
	_fill_rect(img, 20, 14, 3, 6, coat)
	# Coat lapels
	_fill_rect(img, 12, 11, 1, 3, coat_light)
	_fill_rect(img, 19, 11, 1, 3, coat_light)
	# Gold buttons
	img.set_pixel(12, 12, gold)
	img.set_pixel(12, 14, gold)
	img.set_pixel(19, 12, gold)
	img.set_pixel(19, 14, gold)

	# Belt with pistols
	_fill_rect(img, 10, 14, 12, 1, belt_col)
	_set_px(img, 15, 14, gold)  # Buckle
	_set_px(img, 16, 14, gold)
	# Pistols at belt
	_fill_rect(img, 11, 15, 2, 2, Color(0.35, 0.35, 0.3))
	_fill_rect(img, 19, 15, 2, 2, Color(0.35, 0.35, 0.3))

	# Arms
	_fill_rect(img, 8, 11, 2, 4, coat)
	_fill_rect(img, 22, 11, 2, 4, coat)
	_fill_rect(img, 7, 15, 2, 1, skin)
	_fill_rect(img, 23, 15, 2, 1, skin)

	# Pants
	_fill_rect(img, 12, 15, 8, 5, pants_col)
	_fill_rect(img, 15, 17, 2, 3, pants_col.darkened(0.12))

	# Boots (tall pirate boots)
	_fill_rect(img, 11, 20, 4, 4, boots)
	_fill_rect(img, 17, 20, 4, 4, boots)
	# Boot fold-over
	_fill_rect(img, 11, 20, 4, 1, boots.lightened(0.2))
	_fill_rect(img, 17, 20, 4, 1, boots.lightened(0.2))

	_add_outline(img, outline)
	_save_sprite(img, "res://assets/sprites/characters/pirata.png")

# ==================== ENGENHEIRO ====================
func _generate_engenheiro() -> void:
	var img = Image.create(SPRITE_SIZE, SPRITE_SIZE, false, Image.FORMAT_RGBA8)
	var skin = Color(0.78, 0.62, 0.48)
	var hair = Color(0.35, 0.22, 0.12)
	var goggles = Color(0.45, 0.6, 0.7)  # Tinted lens
	var goggle_frame = Color(0.55, 0.5, 0.4)
	var overalls = Color(0.85, 0.72, 0.2)  # Yellow/gold
	var overalls_dark = Color(0.7, 0.58, 0.15)
	var shirt = Color(0.3, 0.4, 0.55)  # Blue undershirt
	var belt_col = Color(0.4, 0.3, 0.18)
	var tool_metal = Color(0.6, 0.62, 0.65)
	var boots = Color(0.35, 0.25, 0.15)
	var outline = Color(0.12, 0.1, 0.05)

	# Hair (rows 4-6)
	_fill_rect(img, 12, 4, 8, 2, hair)
	_fill_rect(img, 11, 5, 1, 3, hair)
	_fill_rect(img, 20, 5, 1, 3, hair)

	# Goggles on forehead (rows 5-6)
	_fill_rect(img, 12, 5, 3, 2, goggles)
	_fill_rect(img, 17, 5, 3, 2, goggles)
	_fill_rect(img, 15, 5, 2, 1, goggle_frame)
	# Goggle frames
	img.set_pixel(12, 5, goggle_frame)
	img.set_pixel(14, 5, goggle_frame)
	img.set_pixel(17, 5, goggle_frame)
	img.set_pixel(19, 5, goggle_frame)
	# Lens highlight
	img.set_pixel(12, 5, goggles.lightened(0.3))
	img.set_pixel(17, 5, goggles.lightened(0.3))

	# Face (rows 7-10)
	_fill_rect(img, 12, 7, 8, 4, skin)
	# Eyes
	img.set_pixel(14, 8, outline)
	img.set_pixel(17, 8, outline)
	# Smile
	img.set_pixel(14, 10, skin.darkened(0.15))
	_fill_rect(img, 15, 10, 2, 1, Color(0.65, 0.4, 0.35))
	img.set_pixel(17, 10, skin.darkened(0.15))

	# Undershirt at neck
	_fill_rect(img, 13, 11, 6, 1, shirt)

	# Overalls (rows 11-19)
	_fill_rect(img, 10, 11, 12, 3, shirt)
	_fill_rect(img, 10, 12, 12, 7, overalls)
	# Overall straps
	_fill_rect(img, 12, 11, 2, 2, overalls)
	_fill_rect(img, 18, 11, 2, 2, overalls)
	# Bib pocket
	_fill_rect(img, 14, 13, 4, 2, overalls_dark)
	_fill_rect(img, 14, 13, 4, 1, overalls.lightened(0.1))
	# Pens in pocket
	img.set_pixel(15, 12, Color(0.8, 0.2, 0.15))
	img.set_pixel(16, 12, Color(0.2, 0.3, 0.8))

	# Tool belt (rows 16-17)
	_fill_rect(img, 10, 16, 12, 1, belt_col)
	_set_px(img, 15, 16, Color(0.7, 0.6, 0.2))  # Buckle
	# Tools hanging from belt
	_fill_rect(img, 10, 17, 2, 2, tool_metal)  # Hammer
	img.set_pixel(21, 17, tool_metal)  # Screwdriver

	# Arms (shirt sleeves)
	_fill_rect(img, 8, 11, 2, 3, shirt)
	_fill_rect(img, 22, 11, 2, 3, shirt)
	# Hands
	_fill_rect(img, 7, 14, 2, 2, skin)
	_fill_rect(img, 23, 14, 2, 2, skin)

	# Wrench in right hand
	_fill_rect(img, 5, 12, 2, 1, tool_metal)
	_fill_rect(img, 5, 13, 1, 3, tool_metal)
	_fill_rect(img, 6, 13, 1, 3, tool_metal)
	_fill_rect(img, 5, 12, 1, 1, tool_metal.lightened(0.2))
	img.set_pixel(5, 16, tool_metal)
	img.set_pixel(6, 16, tool_metal)
	# Wrench head (open jaw)
	_fill_rect(img, 4, 11, 1, 2, tool_metal)
	_fill_rect(img, 7, 11, 1, 2, tool_metal)

	# Pants / overall legs
	_fill_rect(img, 11, 19, 4, 3, overalls_dark)
	_fill_rect(img, 17, 19, 4, 3, overalls_dark)

	# Boots
	_fill_rect(img, 10, 22, 5, 2, boots)
	_fill_rect(img, 17, 22, 5, 2, boots)
	# Boot soles
	_fill_rect(img, 10, 23, 5, 1, boots.darkened(0.2))
	_fill_rect(img, 17, 23, 5, 1, boots.darkened(0.2))

	_add_outline(img, outline)
	_save_sprite(img, "res://assets/sprites/characters/engenheiro.png")

# ==================== VAMPIRO ====================
func _generate_vampiro() -> void:
	var img = Image.create(SPRITE_SIZE, SPRITE_SIZE, false, Image.FORMAT_RGBA8)
	var skin = Color(0.9, 0.88, 0.85)  # Pale white
	var hair = Color(0.1, 0.08, 0.12)  # Black
	var suit = Color(0.45, 0.08, 0.1)  # Dark crimson
	var suit_dark = Color(0.3, 0.05, 0.07)
	var cape_out = Color(0.08, 0.08, 0.1)  # Black cape exterior
	var cape_in = Color(0.55, 0.05, 0.1)  # Red cape interior
	var shirt = Color(0.9, 0.88, 0.82)  # White shirt
	var eyes = Color(0.9, 0.1, 0.08)  # Red eyes
	var outline = Color(0.05, 0.03, 0.06)

	# Hair (rows 3-7, slicked back widow's peak)
	_fill_rect(img, 12, 3, 8, 2, hair)
	_fill_rect(img, 11, 5, 10, 1, hair)
	# Widow's peak
	img.set_pixel(15, 5, hair)
	img.set_pixel(16, 5, hair)
	img.set_pixel(15, 6, hair)
	img.set_pixel(16, 6, hair)
	# Hair sides
	_fill_rect(img, 11, 5, 1, 4, hair)
	_fill_rect(img, 20, 5, 1, 4, hair)

	# Face (rows 6-10)
	_fill_rect(img, 12, 6, 8, 5, skin)
	# Red eyes
	_fill_rect(img, 13, 7, 2, 1, eyes)
	_fill_rect(img, 17, 7, 2, 1, eyes)
	img.set_pixel(13, 7, eyes.lightened(0.2))
	img.set_pixel(17, 7, eyes.lightened(0.2))
	# Eyebrows (sharp)
	img.set_pixel(13, 6, outline)
	img.set_pixel(14, 6, outline)
	img.set_pixel(17, 6, outline)
	img.set_pixel(18, 6, outline)
	# Nose
	img.set_pixel(15, 9, skin.darkened(0.1))
	# Mouth with fangs
	_fill_rect(img, 14, 10, 4, 1, Color(0.5, 0.1, 0.12))
	img.set_pixel(14, 10, Color(0.9, 0.9, 0.85))  # Left fang
	img.set_pixel(17, 10, Color(0.9, 0.9, 0.85))  # Right fang

	# Cape (behind body, rows 8-25)
	_fill_rect(img, 7, 8, 3, 16, cape_out)
	_fill_rect(img, 22, 8, 3, 16, cape_out)
	# Cape interior showing
	_fill_rect(img, 8, 10, 2, 14, cape_in)
	_fill_rect(img, 22, 10, 2, 14, cape_in)
	# Cape bottom spread
	_fill_rect(img, 6, 22, 3, 3, cape_out)
	_fill_rect(img, 23, 22, 3, 3, cape_out)
	# Cape collar (high, dramatic)
	_fill_rect(img, 9, 8, 2, 3, cape_out)
	_fill_rect(img, 21, 8, 2, 3, cape_out)
	_fill_rect(img, 10, 7, 2, 2, cape_out)
	_fill_rect(img, 20, 7, 2, 2, cape_out)

	# Suit body (rows 11-16)
	_fill_rect(img, 11, 11, 10, 6, suit)
	# White shirt V-neck
	_fill_rect(img, 14, 11, 4, 1, shirt)
	_fill_rect(img, 15, 12, 2, 1, shirt)
	img.set_pixel(15, 13, shirt)
	# Suit lapels
	_fill_rect(img, 12, 11, 2, 3, suit_dark)
	_fill_rect(img, 18, 11, 2, 3, suit_dark)
	# Vest buttons
	img.set_pixel(16, 13, Color(0.7, 0.6, 0.2))
	img.set_pixel(16, 15, Color(0.7, 0.6, 0.2))

	# Arms
	_fill_rect(img, 10, 11, 1, 5, suit)
	_fill_rect(img, 21, 11, 1, 5, suit)
	# Pale hands
	_fill_rect(img, 9, 16, 2, 1, skin)
	_fill_rect(img, 21, 16, 2, 1, skin)

	# Pants
	_fill_rect(img, 12, 17, 8, 5, suit_dark)
	_fill_rect(img, 15, 19, 2, 3, suit_dark.darkened(0.1))

	# Shoes (elegant)
	_fill_rect(img, 11, 22, 4, 2, Color(0.1, 0.08, 0.1))
	_fill_rect(img, 17, 22, 4, 2, Color(0.1, 0.08, 0.1))
	# Shoe shine
	img.set_pixel(12, 22, Color(0.2, 0.18, 0.2))
	img.set_pixel(18, 22, Color(0.2, 0.18, 0.2))

	_add_outline(img, outline)
	_save_sprite(img, "res://assets/sprites/characters/vampiro.png")

# ==================== GLADIADOR ====================
func _generate_gladiador() -> void:
	var img = Image.create(SPRITE_SIZE, SPRITE_SIZE, false, Image.FORMAT_RGBA8)
	var skin = Color(0.75, 0.58, 0.42)
	var armor = Color(0.72, 0.6, 0.25)  # Gold/bronze
	var armor_light = Color(0.82, 0.72, 0.35)
	var armor_dark = Color(0.55, 0.45, 0.18)
	var plume = Color(0.85, 0.12, 0.1)  # Red plume
	var plume_dark = Color(0.65, 0.08, 0.08)
	var shield_col = Color(0.65, 0.55, 0.22)
	var shield_dark = Color(0.5, 0.4, 0.15)
	var sword_blade = Color(0.75, 0.78, 0.82)
	var sword_handle = Color(0.4, 0.25, 0.12)
	var leather = Color(0.45, 0.3, 0.15)
	var outline = Color(0.12, 0.08, 0.04)

	# Helmet (rows 2-8)
	_fill_rect(img, 12, 4, 8, 2, armor)
	_fill_rect(img, 11, 6, 10, 2, armor)
	_fill_rect(img, 11, 4, 10, 1, armor_light)  # Helmet top
	# Face guard / visor
	_fill_rect(img, 12, 7, 8, 1, armor_dark)
	# Red plume (mohawk style)
	_fill_rect(img, 15, 1, 2, 4, plume)
	_fill_rect(img, 14, 2, 4, 2, plume)
	img.set_pixel(15, 1, plume.lightened(0.2))
	_fill_rect(img, 15, 4, 2, 1, plume_dark)
	# Plume flowing back
	_fill_rect(img, 19, 3, 3, 2, plume)
	_fill_rect(img, 21, 4, 2, 2, plume_dark)

	# Face visible (rows 8-10)
	_fill_rect(img, 12, 8, 8, 3, skin)
	# Eyes
	img.set_pixel(14, 9, outline)
	img.set_pixel(17, 9, outline)
	# Chin guard
	_fill_rect(img, 11, 8, 1, 3, armor)
	_fill_rect(img, 20, 8, 1, 3, armor)

	# Chest armor (rows 11-15)
	_fill_rect(img, 11, 11, 10, 5, armor)
	# Chest plate details
	_fill_rect(img, 12, 11, 8, 2, armor_light)
	# Pectoral line
	_fill_rect(img, 15, 11, 2, 3, armor_dark)
	# Abs plate
	_fill_rect(img, 13, 14, 6, 1, armor_dark)
	# Belt / leather skirt
	_fill_rect(img, 10, 16, 12, 1, leather)
	_set_px(img, 15, 16, armor_light)  # Belt buckle
	_set_px(img, 16, 16, armor_light)

	# Shoulder pauldrons
	_fill_rect(img, 8, 10, 3, 3, armor)
	_fill_rect(img, 21, 10, 3, 3, armor)
	# Pauldron highlight
	_fill_rect(img, 8, 10, 3, 1, armor_light)
	_fill_rect(img, 21, 10, 3, 1, armor_light)

	# Arms
	_fill_rect(img, 8, 13, 2, 3, skin)
	_fill_rect(img, 22, 13, 2, 3, skin)
	# Bracers
	_fill_rect(img, 8, 13, 2, 1, armor_dark)
	_fill_rect(img, 22, 13, 2, 1, armor_dark)

	# Leather pteruges (skirt strips, rows 17-20)
	for x_off in range(6):
		var sx = 10 + x_off * 2
		_fill_rect(img, sx, 17, 2, 4, leather)
		img.set_pixel(sx, 17, leather.lightened(0.1))

	# Legs
	_fill_rect(img, 12, 21, 3, 2, skin)
	_fill_rect(img, 17, 21, 3, 2, skin)

	# Sandals / greaves
	_fill_rect(img, 11, 23, 4, 1, leather.darkened(0.2))
	_fill_rect(img, 17, 23, 4, 1, leather.darkened(0.2))
	# Shin guards
	_fill_rect(img, 12, 21, 1, 2, armor_dark)
	_fill_rect(img, 18, 21, 1, 2, armor_dark)

	# Shield (left hand, round)
	_fill_rect(img, 3, 12, 5, 1, shield_col)
	_fill_rect(img, 2, 13, 7, 5, shield_col)
	_fill_rect(img, 3, 18, 5, 1, shield_col)
	# Shield boss (center bump)
	_fill_rect(img, 4, 14, 3, 3, shield_dark)
	img.set_pixel(5, 15, armor_light)  # Boss highlight
	# Shield rim
	_fill_rect(img, 2, 13, 1, 5, shield_dark)
	_fill_rect(img, 8, 13, 1, 5, shield_dark)

	# Sword (right hand)
	for i in range(8):
		_set_px(img, 24, 8 + i, sword_blade)
	_fill_rect(img, 23, 8, 3, 1, sword_blade.lightened(0.2))  # Blade tip
	# Crossguard
	_fill_rect(img, 23, 15, 3, 1, armor)
	# Handle
	_set_px(img, 24, 16, sword_handle)
	_set_px(img, 24, 17, sword_handle)
	# Pommel
	_set_px(img, 24, 18, armor)

	_add_outline(img, outline)
	_save_sprite(img, "res://assets/sprites/characters/gladiador.png")

# ==================== CHEF ====================
func _generate_chef() -> void:
	var img = Image.create(SPRITE_SIZE, SPRITE_SIZE, false, Image.FORMAT_RGBA8)
	var skin = Color(0.85, 0.7, 0.55)
	var hat_white = Color(0.95, 0.93, 0.9)  # Chef hat
	var hat_shadow = Color(0.82, 0.8, 0.76)
	var uniform = Color(0.92, 0.9, 0.87)  # White chef jacket
	var uniform_shadow = Color(0.78, 0.76, 0.72)
	var buttons = Color(0.15, 0.15, 0.15)
	var pants_col = Color(0.2, 0.2, 0.22)  # Dark pants
	var mustache = Color(0.3, 0.2, 0.12)
	var pan_metal = Color(0.4, 0.4, 0.42)
	var pan_handle = Color(0.25, 0.18, 0.1)
	var apron = Color(0.88, 0.85, 0.8)
	var outline = Color(0.1, 0.1, 0.1)

	# Tall chef hat / toque (rows 0-7)
	_fill_rect(img, 12, 0, 8, 2, hat_white)
	_fill_rect(img, 11, 1, 10, 2, hat_white)
	_fill_rect(img, 11, 2, 10, 3, hat_white)
	# Hat puff top (wider)
	_fill_rect(img, 10, 0, 12, 1, hat_white)
	_fill_rect(img, 10, 1, 12, 2, hat_white)
	# Hat shadow / folds
	_fill_rect(img, 13, 1, 2, 2, hat_shadow)
	_fill_rect(img, 17, 2, 2, 1, hat_shadow)
	# Hat band
	_fill_rect(img, 11, 5, 10, 1, hat_shadow)
	_fill_rect(img, 11, 5, 10, 1, uniform_shadow)

	# Face (rows 6-10)
	_fill_rect(img, 12, 6, 8, 5, skin)
	# Eyes (friendly)
	img.set_pixel(14, 7, outline)
	img.set_pixel(17, 7, outline)
	# Rosy cheeks
	img.set_pixel(13, 8, Color(0.9, 0.6, 0.5))
	img.set_pixel(18, 8, Color(0.9, 0.6, 0.5))
	# Mustache (big curly)
	_fill_rect(img, 13, 9, 6, 1, mustache)
	_fill_rect(img, 12, 9, 1, 2, mustache)
	_fill_rect(img, 19, 9, 1, 2, mustache)
	img.set_pixel(11, 10, mustache)  # Curl left
	img.set_pixel(20, 10, mustache)  # Curl right
	# Mouth
	_fill_rect(img, 15, 10, 2, 1, Color(0.65, 0.4, 0.35))

	# Neck
	_fill_rect(img, 14, 11, 4, 1, skin)

	# Chef jacket (rows 11-18)
	_fill_rect(img, 10, 11, 12, 8, uniform)
	# Jacket collar
	_fill_rect(img, 12, 11, 2, 2, uniform.lightened(0.05))
	_fill_rect(img, 18, 11, 2, 2, uniform.lightened(0.05))
	# Double-breasted buttons
	for i in range(4):
		img.set_pixel(14, 12 + i, buttons)
		img.set_pixel(17, 12 + i, buttons)
	# Jacket shadow fold
	_fill_rect(img, 15, 12, 2, 5, uniform_shadow)

	# Apron (front)
	_fill_rect(img, 12, 14, 8, 5, apron)
	# Apron string
	_fill_rect(img, 11, 14, 1, 1, apron.darkened(0.1))
	_fill_rect(img, 20, 14, 1, 1, apron.darkened(0.1))

	# Arms (jacket sleeves)
	_fill_rect(img, 8, 11, 2, 5, uniform)
	_fill_rect(img, 22, 11, 2, 5, uniform)
	# Sleeve cuffs
	_fill_rect(img, 8, 15, 2, 1, uniform_shadow)
	_fill_rect(img, 22, 15, 2, 1, uniform_shadow)
	# Hands
	_fill_rect(img, 7, 16, 2, 1, skin)
	_fill_rect(img, 23, 16, 2, 1, skin)

	# Frying pan (left hand)
	# Pan (circle-ish)
	_fill_rect(img, 2, 14, 5, 1, pan_metal)
	_fill_rect(img, 1, 15, 7, 3, pan_metal)
	_fill_rect(img, 2, 18, 5, 1, pan_metal)
	# Pan shine
	img.set_pixel(3, 15, pan_metal.lightened(0.3))
	img.set_pixel(4, 15, pan_metal.lightened(0.2))
	# Pan handle
	_fill_rect(img, 7, 16, 1, 1, pan_handle)
	_fill_rect(img, 6, 16, 1, 1, pan_handle)
	# Fire in pan (small flame)
	img.set_pixel(3, 14, Color(0.95, 0.65, 0.1))
	img.set_pixel(4, 13, Color(0.95, 0.45, 0.1))
	img.set_pixel(5, 14, Color(0.95, 0.55, 0.1))

	# Pants
	_fill_rect(img, 11, 19, 4, 3, pants_col)
	_fill_rect(img, 17, 19, 4, 3, pants_col)

	# Shoes
	_fill_rect(img, 10, 22, 5, 2, Color(0.15, 0.12, 0.1))
	_fill_rect(img, 17, 22, 5, 2, Color(0.15, 0.12, 0.1))

	_add_outline(img, outline)
	_save_sprite(img, "res://assets/sprites/characters/chef.png")

# ==================== MYSTERY ====================
func _generate_mystery() -> void:
	var img = Image.create(SPRITE_SIZE, SPRITE_SIZE, false, Image.FORMAT_RGBA8)
	var body_base = Color(0.15, 0.2, 0.18)  # Dark grey-green
	var glitch_cyan = Color(0.1, 0.95, 0.85)  # Cyan glitch
	var glitch_green = Color(0.2, 0.9, 0.3)  # Green glitch
	var glitch_dim = Color(0.1, 0.5, 0.45)
	var static_light = Color(0.7, 0.75, 0.7, 0.6)
	var static_dark = Color(0.05, 0.1, 0.08, 0.5)
	var question_col = Color(0.1, 0.95, 0.8)  # Bright "?"
	var outline = Color(0.05, 0.12, 0.1)

	# Head (rows 4-10, slightly glitchy silhouette)
	_fill_rect(img, 12, 4, 8, 2, body_base)
	_fill_rect(img, 11, 6, 10, 4, body_base)
	# Glitch displacement on head (shifted pixels)
	_fill_rect(img, 20, 5, 2, 1, glitch_cyan)  # Horizontal glitch artifact
	_fill_rect(img, 10, 7, 1, 2, glitch_green)

	# Eyes (mismatched, one glitchy)
	_fill_rect(img, 13, 7, 2, 2, glitch_cyan)
	img.set_pixel(13, 7, glitch_cyan.lightened(0.3))
	# Right eye glitches (scanline)
	img.set_pixel(17, 7, glitch_green)
	img.set_pixel(18, 7, glitch_green.lightened(0.2))
	img.set_pixel(17, 8, glitch_cyan)
	img.set_pixel(18, 8, static_dark)

	# Static noise on face
	img.set_pixel(15, 9, static_light)
	img.set_pixel(14, 8, static_dark)

	# Body (rows 10-20)
	_fill_rect(img, 10, 10, 12, 10, body_base)

	# "?" symbol on chest (rows 11-16)
	# Top curve of ?
	_fill_rect(img, 14, 11, 4, 1, question_col)
	img.set_pixel(13, 12, question_col)
	img.set_pixel(18, 12, question_col)
	img.set_pixel(18, 13, question_col)
	# Middle curve
	_fill_rect(img, 16, 13, 2, 1, question_col)
	img.set_pixel(15, 14, question_col)
	img.set_pixel(15, 15, question_col)
	# Dot
	img.set_pixel(15, 17, question_col)
	# ? glow
	img.set_pixel(14, 11, question_col.darkened(0.3))
	img.set_pixel(18, 11, question_col.darkened(0.3))

	# Arms (glitchy)
	_fill_rect(img, 8, 10, 2, 5, body_base)
	_fill_rect(img, 22, 10, 2, 5, body_base)
	# Glitch on arms
	img.set_pixel(8, 12, glitch_cyan)
	img.set_pixel(23, 11, glitch_green)
	# Hands
	_fill_rect(img, 7, 15, 2, 1, body_base)
	_fill_rect(img, 23, 15, 2, 1, body_base)
	img.set_pixel(7, 15, glitch_dim)

	# Legs
	_fill_rect(img, 11, 20, 4, 3, body_base)
	_fill_rect(img, 17, 20, 4, 3, body_base)

	# Feet
	_fill_rect(img, 10, 23, 5, 1, body_base)
	_fill_rect(img, 17, 23, 5, 1, body_base)

	# Scattered glitch pixels (cyan/green noise around the body)
	var glitch_positions = [
		Vector2i(9, 5), Vector2i(22, 6), Vector2i(7, 9),
		Vector2i(24, 10), Vector2i(6, 13), Vector2i(25, 14),
		Vector2i(9, 17), Vector2i(23, 18), Vector2i(10, 21),
		Vector2i(22, 22), Vector2i(13, 3), Vector2i(18, 3),
		Vector2i(11, 22), Vector2i(20, 20), Vector2i(26, 12),
		Vector2i(5, 11), Vector2i(14, 22), Vector2i(19, 21),
	]
	var glitch_colors = [glitch_cyan, glitch_green, glitch_dim]
	for i in range(glitch_positions.size()):
		var pos = glitch_positions[i]
		_set_px(img, pos.x, pos.y, glitch_colors[i % 3])

	# Horizontal scanline glitch effect (rows of shifted color)
	for x in range(10, 22):
		_set_px(img, x + 1, 14, img.get_pixel(x, 14) if img.get_pixel(x, 14).a > 0 else Color(0, 0, 0, 0))
	# Additional scanlines
	_fill_rect(img, 10, 12, 12, 1, body_base.lightened(0.08))
	_fill_rect(img, 11, 18, 10, 1, body_base.lightened(0.06))

	# Static effect overlay (scattered pixels on body)
	var static_positions = [
		Vector2i(12, 11), Vector2i(19, 13), Vector2i(13, 16),
		Vector2i(17, 15), Vector2i(11, 19), Vector2i(20, 17),
		Vector2i(14, 19), Vector2i(18, 20), Vector2i(16, 12),
	]
	for pos in static_positions:
		if img.get_pixel(pos.x, pos.y).a > 0:
			_set_px(img, pos.x, pos.y, static_light)

	_add_outline(img, outline)
	_save_sprite(img, "res://assets/sprites/characters/mystery.png")
