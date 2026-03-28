extends SceneTree

## Generates 32x32 pixel art sprites for themed enemies (Gen 3):
## 5 NEW exclusive enemies per stage, 50 total across all 10 stages.
## Run: godot --headless --path game --script res://scripts/tools/themed_enemies_gen3.gd

const S := 32

func _init() -> void:
	# Create all directories
	for stage in ["cemetery", "forest", "farm", "tokyo", "volcano", "ocean", "arena", "space", "castle", "candy"]:
		DirAccess.make_dir_recursive_absolute("res://assets/sprites/enemies/" + stage)

	# Cemetery (5)
	_gen_cemetery_ghoul()
	_gen_cemetery_banshee()
	_gen_cemetery_gravedigger()
	_gen_cemetery_rat_swarm()
	_gen_cemetery_bone_knight()

	# Forest (5)
	_gen_forest_fairy()
	_gen_forest_vine()
	_gen_forest_bear()
	_gen_forest_owl()
	_gen_forest_wisp()

	# Farm (5)
	_gen_farm_bull()
	_gen_farm_rat()
	_gen_farm_goat()
	_gen_farm_bee_swarm()
	_gen_farm_worm()

	# Tokyo (5)
	_gen_tokyo_yakuza()
	_gen_tokyo_cyborg()
	_gen_tokyo_hologram()
	_gen_tokyo_turret()
	_gen_tokyo_virus()

	# Volcano (5)
	_gen_volcano_phoenix()
	_gen_volcano_lava_snake()
	_gen_volcano_ash_ghost()
	_gen_volcano_fire_bat()
	_gen_volcano_obsidian_golem()

	# Ocean (5)
	_gen_ocean_shark()
	_gen_ocean_pufferfish()
	_gen_ocean_eel()
	_gen_ocean_seahorse()
	_gen_ocean_octopus()

	# Arena (5)
	_gen_arena_archer()
	_gen_arena_tiger()
	_gen_arena_prisoner()
	_gen_arena_eagle()
	_gen_arena_net_fighter()

	# Space (5)
	_gen_space_robot()
	_gen_space_tentacle()
	_gen_space_crystal()
	_gen_space_worm()
	_gen_space_sentinel()

	# Castle (5)
	_gen_castle_ghost_maid()
	_gen_castle_rat_king()
	_gen_castle_skeleton_mage()
	_gen_castle_bat_swarm()
	_gen_castle_cursed_armor()

	# Candy (5)
	_gen_candy_chocolate_golem()
	_gen_candy_ice_cream_cone()
	_gen_candy_cotton_candy_ghost()
	_gen_candy_cake_mimic()
	_gen_candy_sour_worm()

	print("All 50 themed enemy sprites (gen3) generated!")
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

func _circle(img: Image, cx: int, cy: int, r: int, color: Color) -> void:
	for x in range(cx - r, cx + r + 1):
		for y in range(cy - r, cy + r + 1):
			if (x - cx) * (x - cx) + (y - cy) * (y - cy) <= r * r:
				_px(img, x, y, color)

func _line_h(img: Image, x: int, y: int, length: int, color: Color) -> void:
	for i in range(length):
		_px(img, x + i, y, color)

func _line_v(img: Image, x: int, y: int, length: int, color: Color) -> void:
	for i in range(length):
		_px(img, x, y + i, color)

func _outline(img: Image, color: Color) -> void:
	var out = Image.create(S, S, false, Image.FORMAT_RGBA8)
	for x in range(S):
		for y in range(S):
			if img.get_pixel(x, y).a > 0:
				continue
			for off in [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]:
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

# ==================== CEMETERY ====================

func _gen_cemetery_ghoul() -> void:
	var img = _img()
	var skin = Color(0.55, 0.58, 0.52)
	var skin_dark = Color(0.4, 0.44, 0.38)
	var eye = Color(0.95, 0.2, 0.1)
	var mouth = Color(0.3, 0.1, 0.1)
	var bone = Color(0.9, 0.88, 0.8)
	var cloth = Color(0.3, 0.28, 0.25)

	# Hunched body - torso leaning forward
	_fill(img, 10, 10, 10, 10, skin)
	_fill(img, 8, 12, 14, 6, skin)
	_fill(img, 9, 18, 12, 3, skin_dark)

	# Head (tilted forward)
	_fill(img, 17, 4, 7, 7, skin)
	_fill(img, 18, 3, 5, 1, skin)
	_fill(img, 16, 6, 9, 4, skin)
	# Sunken eyes
	_px(img, 19, 6, Color(0.2, 0.2, 0.15))
	_px(img, 20, 6, eye)
	_px(img, 22, 6, eye)
	_px(img, 23, 6, Color(0.2, 0.2, 0.15))
	# Open mouth with teeth
	_fill(img, 19, 8, 4, 2, mouth)
	_px(img, 20, 8, bone)
	_px(img, 22, 8, bone)

	# Hunched spine bump
	_fill(img, 13, 8, 5, 3, skin_dark)

	# Arms reaching down
	_fill(img, 7, 14, 3, 7, skin)
	_fill(img, 22, 12, 3, 7, skin)
	# Claws
	_px(img, 6, 21, skin_dark)
	_px(img, 7, 21, skin)
	_px(img, 8, 21, skin_dark)
	_px(img, 22, 19, skin_dark)
	_px(img, 23, 19, skin)
	_px(img, 24, 19, skin_dark)

	# Tattered cloth around waist
	_fill(img, 9, 19, 12, 2, cloth)
	_px(img, 10, 21, cloth)
	_px(img, 14, 21, cloth)
	_px(img, 18, 21, cloth)

	# Legs (short, crouched)
	_fill(img, 10, 22, 4, 5, skin)
	_fill(img, 17, 22, 4, 5, skin)
	# Feet
	_fill(img, 9, 27, 5, 2, skin_dark)
	_fill(img, 16, 27, 5, 2, skin_dark)

	# Bone it's eating (in left hand)
	_fill(img, 4, 17, 4, 1, bone)
	_fill(img, 5, 16, 1, 3, bone)
	_px(img, 3, 17, Color(0.8, 0.78, 0.7))

	_outline(img, Color(0.15, 0.18, 0.12))
	_save(img, "res://assets/sprites/enemies/cemetery/cemetery_ghoul.png")

func _gen_cemetery_banshee() -> void:
	var img = _img()
	var body = Color(0.92, 0.92, 0.95, 0.7)
	var body_bright = Color(0.98, 0.98, 1.0, 0.85)
	var hair = Color(0.75, 0.78, 0.82)
	var hair_dark = Color(0.6, 0.62, 0.68)
	var eye = Color(0.1, 0.9, 0.9)
	var mouth = Color(0.2, 0.15, 0.3)

	# Flowing hair (long, wild)
	_fill(img, 8, 2, 16, 4, hair)
	_fill(img, 6, 6, 20, 3, hair)
	_fill(img, 5, 9, 6, 8, hair_dark)
	_fill(img, 21, 9, 6, 8, hair_dark)
	_px(img, 4, 12, hair_dark)
	_px(img, 27, 12, hair_dark)
	_px(img, 4, 14, hair)
	_px(img, 27, 14, hair)

	# Face
	_fill(img, 11, 5, 10, 8, body_bright)
	_fill(img, 10, 7, 12, 5, body_bright)
	# Glowing eyes (wide)
	_fill(img, 12, 7, 3, 2, eye)
	_fill(img, 18, 7, 3, 2, eye)
	_px(img, 13, 8, Color(0.2, 1.0, 1.0))
	_px(img, 19, 8, Color(0.2, 1.0, 1.0))
	# Screaming mouth (large open O)
	_fill(img, 13, 10, 6, 3, mouth)
	_fill(img, 14, 10, 4, 1, Color(0.4, 0.2, 0.45))

	# Ghostly body (flowing downward, semi-transparent)
	_fill(img, 10, 13, 12, 6, body)
	_fill(img, 9, 15, 14, 4, body)
	_fill(img, 8, 19, 16, 3, body)

	# Wispy arms reaching out
	_fill(img, 5, 14, 5, 2, body)
	_fill(img, 3, 15, 3, 2, body)
	_fill(img, 22, 14, 5, 2, body)
	_fill(img, 26, 15, 3, 2, body)

	# Wispy trailing bottom (ragged ghost tail)
	_fill(img, 9, 22, 4, 2, body)
	_fill(img, 15, 22, 4, 2, body)
	_fill(img, 11, 24, 3, 2, body)
	_fill(img, 17, 24, 3, 2, body)
	_px(img, 12, 26, body)
	_px(img, 18, 26, body)
	_px(img, 10, 25, body)
	_px(img, 20, 25, body)

	# Scream effect lines
	_px(img, 8, 10, Color(0.8, 0.8, 1.0, 0.5))
	_px(img, 7, 11, Color(0.8, 0.8, 1.0, 0.4))
	_px(img, 24, 10, Color(0.8, 0.8, 1.0, 0.5))
	_px(img, 25, 11, Color(0.8, 0.8, 1.0, 0.4))

	_outline(img, Color(0.4, 0.4, 0.5))
	_save(img, "res://assets/sprites/enemies/cemetery/cemetery_banshee.png")

func _gen_cemetery_gravedigger() -> void:
	var img = _img()
	var bone = Color(0.9, 0.88, 0.8)
	var bone_dark = Color(0.7, 0.68, 0.6)
	var eye = Color(0.95, 0.2, 0.1)
	var hat = Color(0.25, 0.22, 0.2)
	var shovel_handle = Color(0.5, 0.35, 0.2)
	var shovel_blade = Color(0.55, 0.55, 0.52)
	var cloth = Color(0.35, 0.3, 0.28)

	# Hat (wide brim)
	_fill(img, 9, 2, 10, 2, hat)
	_fill(img, 7, 4, 14, 1, hat)
	_fill(img, 11, 0, 6, 2, hat)

	# Skull head
	_fill(img, 11, 5, 6, 6, bone)
	_fill(img, 10, 6, 8, 4, bone)
	# Eye sockets
	_fill(img, 12, 7, 2, 2, Color(0.1, 0.05, 0.05))
	_px(img, 12, 7, eye)
	_fill(img, 16, 7, 2, 2, Color(0.1, 0.05, 0.05))
	_px(img, 17, 7, eye)
	# Nose hole
	_px(img, 14, 9, Color(0.2, 0.15, 0.12))
	# Jaw / teeth
	_fill(img, 12, 10, 6, 1, bone_dark)
	_px(img, 13, 10, bone)
	_px(img, 15, 10, bone)
	_px(img, 17, 10, bone)

	# Tattered shirt
	_fill(img, 10, 12, 8, 6, cloth)
	_fill(img, 9, 13, 10, 4, cloth)

	# Ribcage visible through torn shirt
	_px(img, 12, 13, bone_dark)
	_px(img, 12, 15, bone_dark)
	_px(img, 16, 13, bone_dark)
	_px(img, 16, 15, bone_dark)

	# Arms (bone)
	_fill(img, 7, 13, 3, 6, bone)
	_fill(img, 19, 13, 3, 6, bone)
	# Bony hands
	_px(img, 6, 19, bone_dark)
	_px(img, 7, 19, bone)
	_px(img, 8, 19, bone_dark)
	_px(img, 19, 19, bone_dark)
	_px(img, 20, 19, bone)
	_px(img, 21, 19, bone_dark)

	# Pants
	_fill(img, 11, 18, 3, 6, cloth)
	_fill(img, 16, 18, 3, 6, cloth)

	# Feet (bone)
	_fill(img, 10, 24, 4, 2, bone_dark)
	_fill(img, 15, 24, 4, 2, bone_dark)

	# Shovel (held in right hand, tall)
	_line_v(img, 5, 4, 18, shovel_handle)
	_line_v(img, 6, 4, 18, shovel_handle)
	# Shovel blade at bottom
	_fill(img, 3, 22, 6, 4, shovel_blade)
	_fill(img, 4, 21, 4, 1, shovel_blade)
	_fill(img, 4, 26, 4, 1, Color(0.45, 0.45, 0.42))

	_outline(img, Color(0.12, 0.1, 0.08))
	_save(img, "res://assets/sprites/enemies/cemetery/cemetery_gravedigger.png")

func _gen_cemetery_rat_swarm() -> void:
	var img = _img()
	var body = Color(0.5, 0.48, 0.45)
	var body_dark = Color(0.38, 0.36, 0.33)
	var body_light = Color(0.62, 0.6, 0.55)
	var eye = Color(0.9, 0.15, 0.1)
	var tail = Color(0.65, 0.5, 0.48)
	var ear = Color(0.72, 0.55, 0.52)

	# Rat 1 (front-left, largest)
	_fill(img, 4, 14, 8, 5, body)
	_fill(img, 3, 16, 10, 3, body)
	_fill(img, 2, 15, 3, 3, body_light) # head
	_px(img, 2, 15, eye)
	_px(img, 1, 14, ear)
	_px(img, 3, 13, ear)
	# Tail
	_px(img, 12, 16, tail)
	_px(img, 13, 15, tail)
	_px(img, 14, 14, tail)
	_px(img, 15, 14, tail)
	# Feet
	_px(img, 5, 19, body_dark)
	_px(img, 8, 19, body_dark)
	_px(img, 10, 19, body_dark)

	# Rat 2 (center, medium)
	_fill(img, 10, 8, 7, 4, body_dark)
	_fill(img, 9, 9, 9, 2, body_dark)
	_fill(img, 8, 9, 3, 2, body_light)
	_px(img, 8, 9, eye)
	_px(img, 7, 8, ear)
	_px(img, 9, 7, ear)
	_px(img, 17, 9, tail)
	_px(img, 18, 8, tail)
	_px(img, 19, 8, tail)
	_px(img, 11, 12, body_dark)
	_px(img, 14, 12, body_dark)

	# Rat 3 (right, medium)
	_fill(img, 17, 16, 7, 4, body)
	_fill(img, 16, 17, 9, 2, body)
	_fill(img, 24, 17, 3, 2, body_light)
	_px(img, 25, 17, eye)
	_px(img, 26, 16, ear)
	_px(img, 25, 15, ear)
	_px(img, 16, 18, tail)
	_px(img, 15, 17, tail)
	_px(img, 14, 17, tail)
	_px(img, 18, 20, body_dark)
	_px(img, 21, 20, body_dark)

	# Rat 4 (back-center, small)
	_fill(img, 14, 4, 5, 3, body_dark)
	_fill(img, 13, 5, 2, 2, body_light)
	_px(img, 13, 5, eye)
	_px(img, 12, 4, ear)
	_px(img, 19, 5, tail)
	_px(img, 20, 4, tail)

	# Rat 5 (bottom right, small)
	_fill(img, 21, 22, 5, 3, body)
	_fill(img, 20, 23, 2, 2, body_light)
	_px(img, 20, 23, eye)
	_px(img, 19, 22, ear)
	_px(img, 26, 23, tail)
	_px(img, 27, 22, tail)

	# Rat 6 (bottom left, small)
	_fill(img, 2, 22, 5, 3, body_dark)
	_fill(img, 1, 23, 2, 2, body_light)
	_px(img, 1, 23, eye)
	_px(img, 0, 22, ear)
	_px(img, 7, 23, tail)
	_px(img, 8, 22, tail)

	_outline(img, Color(0.18, 0.16, 0.14))
	_save(img, "res://assets/sprites/enemies/cemetery/cemetery_rat_swarm.png")

func _gen_cemetery_bone_knight() -> void:
	var img = _img()
	var bone = Color(0.88, 0.85, 0.78)
	var bone_dark = Color(0.68, 0.65, 0.58)
	var armor = Color(0.45, 0.48, 0.52)
	var armor_light = Color(0.58, 0.6, 0.65)
	var armor_dark = Color(0.32, 0.35, 0.38)
	var eye = Color(0.1, 0.85, 0.2)
	var sword = Color(0.78, 0.8, 0.85)
	var sword_light = Color(0.9, 0.92, 0.95)
	var cape = Color(0.25, 0.08, 0.08)

	# Helmet
	_fill(img, 12, 2, 8, 7, armor)
	_fill(img, 11, 3, 10, 5, armor)
	_fill(img, 13, 1, 6, 2, armor_light)
	# Visor slit
	_fill(img, 13, 5, 6, 2, Color(0.08, 0.08, 0.08))
	# Glowing eyes in visor
	_px(img, 14, 5, eye)
	_px(img, 15, 5, eye)
	_px(img, 17, 5, eye)
	_px(img, 18, 5, eye)
	# Helmet crest
	_line_v(img, 16, 0, 3, armor_light)

	# Neck
	_fill(img, 14, 9, 4, 1, bone)

	# Chest plate
	_fill(img, 10, 10, 12, 7, armor)
	_fill(img, 9, 11, 14, 5, armor)
	# Armor details
	_fill(img, 13, 11, 6, 5, armor_light)
	_line_v(img, 16, 10, 7, armor_dark)
	_line_h(img, 11, 13, 10, armor_dark)

	# Shoulder pauldrons
	_fill(img, 6, 10, 4, 4, armor)
	_fill(img, 22, 10, 4, 4, armor)
	_fill(img, 7, 10, 2, 1, armor_light)
	_fill(img, 23, 10, 2, 1, armor_light)

	# Arms (armored)
	_fill(img, 6, 14, 3, 6, armor_dark)
	_fill(img, 23, 14, 3, 6, armor_dark)
	# Gauntlets
	_fill(img, 5, 19, 4, 2, armor)
	_fill(img, 23, 19, 4, 2, armor)

	# Cape behind
	_fill(img, 11, 16, 10, 2, cape)
	_fill(img, 10, 18, 12, 4, cape)
	_fill(img, 11, 22, 10, 2, cape)
	_fill(img, 12, 24, 8, 2, cape)

	# Legs (armored)
	_fill(img, 12, 17, 3, 6, armor_dark)
	_fill(img, 17, 17, 3, 6, armor_dark)
	# Greaves
	_fill(img, 12, 22, 3, 2, armor)
	_fill(img, 17, 22, 3, 2, armor)
	# Boots
	_fill(img, 11, 24, 4, 3, armor)
	_fill(img, 17, 24, 4, 3, armor)

	# Sword (right hand, tall)
	_line_v(img, 4, 3, 14, sword)
	_line_v(img, 5, 3, 14, sword_light)
	# Sword guard
	_fill(img, 3, 17, 5, 1, armor_light)
	# Sword tip
	_px(img, 4, 2, sword_light)
	_px(img, 5, 2, sword_light)
	_px(img, 4, 1, sword_light)

	_outline(img, Color(0.1, 0.1, 0.12))
	_save(img, "res://assets/sprites/enemies/cemetery/cemetery_bone_knight.png")

# ==================== FOREST ====================

func _gen_forest_fairy() -> void:
	var img = _img()
	var skin = Color(0.85, 0.75, 0.9)
	var glow = Color(0.9, 0.95, 0.4, 0.8)
	var glow_bright = Color(1.0, 1.0, 0.6, 0.9)
	var wing = Color(0.7, 0.95, 0.7, 0.6)
	var wing_edge = Color(0.5, 0.85, 0.5, 0.7)
	var hair = Color(0.2, 0.8, 0.3)
	var eye = Color(0.9, 0.15, 0.15)
	var dress = Color(0.3, 0.7, 0.25)

	# Glow aura
	_circle(img, 16, 14, 10, Color(0.9, 1.0, 0.5, 0.15))
	_circle(img, 16, 14, 7, Color(0.9, 1.0, 0.5, 0.25))

	# Wings (left)
	_fill(img, 4, 8, 6, 3, wing)
	_fill(img, 3, 10, 7, 4, wing)
	_fill(img, 5, 14, 5, 2, wing)
	_px(img, 3, 10, wing_edge)
	_px(img, 4, 8, wing_edge)
	_px(img, 5, 14, wing_edge)

	# Wings (right)
	_fill(img, 22, 8, 6, 3, wing)
	_fill(img, 22, 10, 7, 4, wing)
	_fill(img, 22, 14, 5, 2, wing)
	_px(img, 28, 10, wing_edge)
	_px(img, 27, 8, wing_edge)
	_px(img, 26, 14, wing_edge)

	# Body (tiny)
	_fill(img, 14, 10, 4, 3, skin)
	# Head
	_fill(img, 13, 6, 6, 5, skin)
	_fill(img, 14, 5, 4, 1, skin)
	# Hair
	_fill(img, 13, 5, 6, 2, hair)
	_px(img, 12, 6, hair)
	_px(img, 19, 6, hair)
	_fill(img, 12, 8, 2, 4, hair)
	_fill(img, 19, 8, 2, 4, hair)
	# Angry eyes
	_px(img, 14, 8, eye)
	_px(img, 17, 8, eye)
	# Angry brows
	_px(img, 14, 7, Color(0.15, 0.1, 0.1))
	_px(img, 17, 7, Color(0.15, 0.1, 0.1))
	# Scowl mouth
	_px(img, 15, 10, Color(0.6, 0.2, 0.2))
	_px(img, 16, 10, Color(0.6, 0.2, 0.2))

	# Green dress
	_fill(img, 13, 13, 6, 4, dress)
	_fill(img, 12, 15, 8, 3, dress)
	_px(img, 12, 18, dress)
	_px(img, 14, 18, dress)
	_px(img, 17, 18, dress)
	_px(img, 19, 18, dress)

	# Tiny arms
	_fill(img, 11, 11, 3, 2, skin)
	_fill(img, 18, 11, 3, 2, skin)

	# Sparkle particles
	_px(img, 8, 5, glow_bright)
	_px(img, 24, 6, glow_bright)
	_px(img, 6, 17, glow)
	_px(img, 26, 18, glow)
	_px(img, 10, 20, glow_bright)
	_px(img, 22, 4, glow)

	_outline(img, Color(0.15, 0.35, 0.1))
	_save(img, "res://assets/sprites/enemies/forest/forest_fairy.png")

func _gen_forest_vine() -> void:
	var img = _img()
	var vine = Color(0.2, 0.5, 0.15)
	var vine_dark = Color(0.12, 0.35, 0.08)
	var vine_light = Color(0.35, 0.65, 0.25)
	var eye = Color(0.95, 0.85, 0.1)
	var flower = Color(0.85, 0.2, 0.3)
	var thorn = Color(0.45, 0.3, 0.1)

	# Main body (thick vine trunk)
	_fill(img, 13, 8, 6, 16, vine)
	_fill(img, 12, 10, 8, 12, vine)
	_fill(img, 11, 12, 10, 8, vine)

	# Head (bulbous top)
	_fill(img, 11, 4, 10, 6, vine)
	_fill(img, 12, 3, 8, 2, vine_light)
	_fill(img, 10, 6, 12, 3, vine)

	# Eyes (angry yellow)
	_fill(img, 12, 6, 3, 2, eye)
	_fill(img, 18, 6, 3, 2, eye)
	_px(img, 13, 7, Color(0.1, 0.1, 0.1))
	_px(img, 19, 7, Color(0.1, 0.1, 0.1))
	# Angry brows (leaf-like)
	_px(img, 11, 5, vine_dark)
	_px(img, 12, 5, vine_dark)
	_px(img, 20, 5, vine_dark)
	_px(img, 21, 5, vine_dark)

	# Mouth (thorny)
	_fill(img, 13, 9, 6, 1, vine_dark)
	_px(img, 14, 9, thorn)
	_px(img, 16, 9, thorn)
	_px(img, 18, 9, thorn)

	# Vine arms (left, reaching)
	_fill(img, 7, 11, 5, 2, vine)
	_fill(img, 4, 12, 4, 2, vine)
	_fill(img, 2, 14, 3, 2, vine_dark)
	# Thorns on left arm
	_px(img, 6, 10, thorn)
	_px(img, 3, 11, thorn)

	# Vine arms (right, reaching)
	_fill(img, 20, 11, 5, 2, vine)
	_fill(img, 24, 12, 4, 2, vine)
	_fill(img, 27, 14, 3, 2, vine_dark)
	# Thorns on right arm
	_px(img, 25, 10, thorn)
	_px(img, 28, 11, thorn)

	# Root-like legs
	_fill(img, 10, 22, 4, 4, vine_dark)
	_fill(img, 18, 22, 4, 4, vine_dark)
	_fill(img, 8, 25, 6, 3, vine_dark)
	_fill(img, 18, 25, 6, 3, vine_dark)
	_px(img, 7, 27, vine_dark)
	_px(img, 24, 27, vine_dark)

	# Small flower on head (to make it recognizable)
	_fill(img, 10, 2, 3, 2, flower)
	_px(img, 11, 1, flower)
	_px(img, 11, 3, Color(0.95, 0.85, 0.2))

	# Leaf details on body
	_px(img, 11, 14, vine_light)
	_px(img, 12, 15, vine_light)
	_px(img, 20, 14, vine_light)
	_px(img, 19, 15, vine_light)

	_outline(img, Color(0.06, 0.2, 0.04))
	_save(img, "res://assets/sprites/enemies/forest/forest_vine.png")

func _gen_forest_bear() -> void:
	var img = _img()
	var fur = Color(0.45, 0.28, 0.12)
	var fur_dark = Color(0.32, 0.18, 0.08)
	var fur_light = Color(0.58, 0.38, 0.18)
	var snout = Color(0.62, 0.48, 0.3)
	var eye = Color(0.1, 0.1, 0.1)
	var nose = Color(0.15, 0.1, 0.08)
	var mouth = Color(0.5, 0.15, 0.12)
	var claw = Color(0.85, 0.82, 0.75)

	# Body (large, standing upright)
	_fill(img, 8, 12, 16, 10, fur)
	_fill(img, 7, 14, 18, 6, fur)
	_fill(img, 9, 22, 14, 3, fur)
	# Belly
	_fill(img, 11, 14, 10, 7, fur_light)

	# Head (round)
	_fill(img, 10, 3, 12, 10, fur)
	_fill(img, 9, 5, 14, 6, fur)
	# Ears (round)
	_fill(img, 9, 2, 4, 3, fur)
	_fill(img, 19, 2, 4, 3, fur)
	_fill(img, 10, 2, 2, 2, fur_dark)
	_fill(img, 20, 2, 2, 2, fur_dark)

	# Snout
	_fill(img, 13, 8, 6, 4, snout)
	_fill(img, 14, 7, 4, 1, snout)
	# Nose
	_fill(img, 14, 8, 4, 2, nose)
	# Mouth (roaring)
	_fill(img, 13, 10, 6, 2, mouth)
	# Teeth
	_px(img, 14, 10, claw)
	_px(img, 16, 10, claw)
	_px(img, 18, 10, claw)

	# Eyes (small, angry)
	_px(img, 12, 6, eye)
	_px(img, 19, 6, eye)
	# Angry brows
	_px(img, 11, 5, fur_dark)
	_px(img, 12, 5, fur_dark)
	_px(img, 19, 5, fur_dark)
	_px(img, 20, 5, fur_dark)

	# Arms raised (threatening)
	_fill(img, 4, 10, 4, 8, fur)
	_fill(img, 24, 10, 4, 8, fur)
	_fill(img, 3, 8, 4, 3, fur)
	_fill(img, 25, 8, 4, 3, fur)
	# Paws with claws
	_fill(img, 2, 7, 5, 2, fur)
	_fill(img, 25, 7, 5, 2, fur)
	_px(img, 1, 7, claw)
	_px(img, 2, 6, claw)
	_px(img, 4, 6, claw)
	_px(img, 27, 6, claw)
	_px(img, 29, 6, claw)
	_px(img, 30, 7, claw)

	# Legs
	_fill(img, 10, 24, 5, 4, fur_dark)
	_fill(img, 17, 24, 5, 4, fur_dark)
	# Feet
	_fill(img, 9, 27, 6, 2, fur)
	_fill(img, 17, 27, 6, 2, fur)

	_outline(img, Color(0.15, 0.08, 0.04))
	_save(img, "res://assets/sprites/enemies/forest/forest_bear.png")

func _gen_forest_owl() -> void:
	var img = _img()
	var body = Color(0.35, 0.28, 0.2)
	var body_light = Color(0.5, 0.42, 0.3)
	var body_dark = Color(0.22, 0.18, 0.12)
	var eye_ring = Color(0.7, 0.62, 0.45)
	var eye = Color(0.95, 0.7, 0.1)
	var pupil = Color(0.05, 0.05, 0.05)
	var beak = Color(0.65, 0.55, 0.2)
	var wing = Color(0.28, 0.22, 0.15)

	# Body (round owl shape)
	_fill(img, 10, 10, 12, 12, body)
	_fill(img, 9, 12, 14, 8, body)
	_fill(img, 11, 22, 10, 3, body)

	# Chest pattern (lighter)
	_fill(img, 12, 14, 8, 8, body_light)
	# Chest speckles
	_px(img, 13, 15, body)
	_px(img, 15, 16, body)
	_px(img, 17, 15, body)
	_px(img, 14, 18, body)
	_px(img, 16, 17, body)
	_px(img, 18, 18, body)

	# Head (wider than body)
	_fill(img, 8, 3, 16, 8, body)
	_fill(img, 7, 5, 18, 4, body)

	# Ear tufts (horned owl)
	_fill(img, 8, 1, 3, 3, body_dark)
	_fill(img, 21, 1, 3, 3, body_dark)
	_px(img, 9, 0, body_dark)
	_px(img, 22, 0, body_dark)

	# Eye rings (large concentric circles)
	_circle(img, 12, 6, 3, eye_ring)
	_circle(img, 20, 6, 3, eye_ring)
	# Eyes (glowing)
	_fill(img, 11, 5, 3, 3, eye)
	_fill(img, 19, 5, 3, 3, eye)
	# Pupils
	_px(img, 12, 6, pupil)
	_px(img, 20, 6, pupil)
	_px(img, 12, 5, pupil)
	_px(img, 20, 5, pupil)

	# Beak
	_px(img, 15, 8, beak)
	_px(img, 16, 8, beak)
	_px(img, 15, 9, beak)
	_px(img, 16, 9, beak)
	_px(img, 16, 10, Color(0.55, 0.45, 0.15))

	# Wings (folded at sides)
	_fill(img, 5, 10, 5, 10, wing)
	_fill(img, 22, 10, 5, 10, wing)
	_fill(img, 4, 14, 4, 6, wing)
	_fill(img, 24, 14, 4, 6, wing)
	# Wing tips
	_px(img, 3, 19, wing)
	_px(img, 4, 20, wing)
	_px(img, 27, 19, wing)
	_px(img, 28, 20, wing)

	# Talons
	_fill(img, 11, 24, 3, 2, body_dark)
	_fill(img, 18, 24, 3, 2, body_dark)
	_px(img, 11, 26, beak)
	_px(img, 13, 26, beak)
	_px(img, 18, 26, beak)
	_px(img, 20, 26, beak)

	_outline(img, Color(0.1, 0.08, 0.05))
	_save(img, "res://assets/sprites/enemies/forest/forest_owl.png")

func _gen_forest_wisp() -> void:
	var img = _img()
	var core = Color(0.3, 0.6, 1.0)
	var core_bright = Color(0.6, 0.85, 1.0)
	var glow = Color(0.2, 0.5, 0.9, 0.6)
	var glow_soft = Color(0.15, 0.4, 0.8, 0.3)
	var flame = Color(0.3, 0.65, 1.0, 0.7)
	var eye = Color(0.95, 0.95, 1.0)

	# Outer glow
	_circle(img, 16, 14, 11, Color(0.1, 0.3, 0.6, 0.1))
	_circle(img, 16, 14, 8, glow_soft)
	_circle(img, 16, 14, 5, glow)

	# Core flame shape
	_fill(img, 13, 10, 6, 8, core)
	_fill(img, 12, 12, 8, 4, core)
	_fill(img, 14, 8, 4, 2, core)
	_fill(img, 15, 6, 2, 2, core_bright)
	_px(img, 15, 5, flame)
	_px(img, 16, 4, flame)

	# Inner bright core
	_fill(img, 14, 11, 4, 4, core_bright)
	_fill(img, 15, 10, 2, 1, core_bright)

	# Eyes (two white dots)
	_px(img, 14, 12, eye)
	_px(img, 17, 12, eye)
	_px(img, 14, 13, Color(0.8, 0.85, 1.0))
	_px(img, 17, 13, Color(0.8, 0.85, 1.0))

	# Flame wisps trailing down
	_fill(img, 13, 18, 6, 2, flame)
	_fill(img, 12, 20, 3, 2, flame)
	_fill(img, 17, 20, 3, 2, flame)
	_px(img, 11, 22, glow)
	_px(img, 13, 22, glow)
	_px(img, 18, 22, glow)
	_px(img, 20, 22, glow)
	_px(img, 12, 23, glow_soft)
	_px(img, 19, 23, glow_soft)

	# Floating particles around
	_px(img, 6, 8, core_bright)
	_px(img, 25, 9, core_bright)
	_px(img, 8, 20, glow)
	_px(img, 24, 18, glow)
	_px(img, 5, 15, glow_soft)
	_px(img, 27, 13, glow_soft)

	_outline(img, Color(0.1, 0.25, 0.5))
	_save(img, "res://assets/sprites/enemies/forest/forest_wisp.png")

# ==================== FARM ====================

func _gen_farm_bull() -> void:
	var img = _img()
	var body = Color(0.55, 0.15, 0.1)
	var body_dark = Color(0.4, 0.1, 0.06)
	var body_light = Color(0.65, 0.22, 0.15)
	var horn = Color(0.85, 0.82, 0.7)
	var horn_dark = Color(0.65, 0.62, 0.5)
	var eye = Color(0.95, 0.2, 0.1)
	var nose = Color(0.3, 0.12, 0.08)
	var hoof = Color(0.25, 0.2, 0.15)

	# Body (large, muscular)
	_fill(img, 6, 14, 18, 8, body)
	_fill(img, 5, 16, 20, 4, body)
	_fill(img, 8, 12, 14, 3, body)
	# Belly
	_fill(img, 10, 17, 10, 4, body_light)

	# Head (wide, lowered for charge)
	_fill(img, 2, 8, 12, 8, body)
	_fill(img, 1, 10, 14, 4, body)
	# Forehead
	_fill(img, 4, 7, 8, 2, body_dark)

	# Horns (curved)
	_fill(img, 1, 5, 3, 3, horn)
	_px(img, 0, 5, horn)
	_px(img, 0, 4, horn_dark)
	_fill(img, 10, 5, 3, 3, horn)
	_px(img, 13, 5, horn)
	_px(img, 13, 4, horn_dark)

	# Eyes (fierce red)
	_fill(img, 4, 10, 2, 2, eye)
	_fill(img, 9, 10, 2, 2, eye)
	_px(img, 5, 11, Color(0.1, 0.05, 0.05))
	_px(img, 10, 11, Color(0.1, 0.05, 0.05))

	# Nostrils (snorting)
	_fill(img, 4, 13, 2, 2, nose)
	_fill(img, 8, 13, 2, 2, nose)
	# Steam from nostrils
	_px(img, 3, 12, Color(0.8, 0.8, 0.8, 0.5))
	_px(img, 2, 11, Color(0.7, 0.7, 0.7, 0.4))
	_px(img, 11, 12, Color(0.8, 0.8, 0.8, 0.5))

	# Front legs (sturdy)
	_fill(img, 7, 22, 4, 6, body_dark)
	_fill(img, 14, 22, 4, 6, body_dark)
	# Hooves
	_fill(img, 7, 27, 4, 2, hoof)
	_fill(img, 14, 27, 4, 2, hoof)

	# Back legs
	_fill(img, 20, 20, 4, 6, body_dark)
	_fill(img, 20, 25, 4, 2, hoof)

	# Tail
	_px(img, 25, 14, body_dark)
	_px(img, 26, 13, body_dark)
	_px(img, 27, 12, body_dark)
	_px(img, 28, 12, body)
	_px(img, 28, 11, body)

	_outline(img, Color(0.18, 0.06, 0.04))
	_save(img, "res://assets/sprites/enemies/farm/farm_bull.png")

func _gen_farm_rat() -> void:
	var img = _img()
	var body = Color(0.55, 0.52, 0.48)
	var body_dark = Color(0.4, 0.38, 0.35)
	var belly = Color(0.7, 0.68, 0.62)
	var eye = Color(0.1, 0.1, 0.1)
	var ear = Color(0.75, 0.55, 0.52)
	var nose = Color(0.3, 0.15, 0.15)
	var tail = Color(0.7, 0.55, 0.5)
	var teeth = Color(0.95, 0.9, 0.75)

	# Body (side view, large rat)
	_fill(img, 8, 12, 14, 8, body)
	_fill(img, 7, 14, 16, 4, body)
	_fill(img, 10, 10, 10, 3, body)
	# Belly
	_fill(img, 10, 16, 10, 3, belly)

	# Head (pointed snout)
	_fill(img, 2, 10, 8, 6, body)
	_fill(img, 1, 12, 3, 3, body)
	_fill(img, 0, 13, 2, 2, body)

	# Ears (large, round)
	_fill(img, 5, 7, 4, 4, ear)
	_fill(img, 6, 8, 2, 2, Color(0.85, 0.65, 0.62))

	# Eye
	_fill(img, 4, 11, 2, 2, Color(0.95, 0.95, 0.95))
	_px(img, 5, 12, eye)

	# Nose
	_px(img, 0, 13, nose)
	_px(img, 0, 14, nose)

	# Teeth (buck teeth)
	_px(img, 1, 15, teeth)
	_px(img, 2, 15, teeth)
	_px(img, 1, 16, teeth)

	# Whiskers
	_px(img, 0, 11, body_dark)
	_px(img, 0, 15, body_dark)

	# Legs
	_fill(img, 8, 19, 3, 4, body_dark)
	_fill(img, 14, 19, 3, 4, body_dark)
	_fill(img, 19, 19, 3, 4, body_dark)
	# Paws
	_fill(img, 7, 23, 4, 2, body_dark)
	_fill(img, 13, 23, 4, 2, body_dark)
	_fill(img, 18, 23, 4, 2, body_dark)

	# Tail (long, curving up)
	_px(img, 22, 14, tail)
	_px(img, 23, 13, tail)
	_px(img, 24, 12, tail)
	_px(img, 25, 11, tail)
	_px(img, 26, 10, tail)
	_px(img, 27, 10, tail)
	_px(img, 28, 9, tail)
	_px(img, 29, 9, tail)

	_outline(img, Color(0.2, 0.18, 0.16))
	_save(img, "res://assets/sprites/enemies/farm/farm_rat.png")

func _gen_farm_goat() -> void:
	var img = _img()
	var body = Color(0.82, 0.8, 0.75)
	var body_dark = Color(0.6, 0.58, 0.55)
	var horn = Color(0.55, 0.5, 0.4)
	var horn_dark = Color(0.4, 0.35, 0.28)
	var eye = Color(0.9, 0.8, 0.1)
	var pupil = Color(0.1, 0.1, 0.1)
	var nose = Color(0.4, 0.3, 0.28)
	var hoof = Color(0.3, 0.25, 0.2)
	var beard = Color(0.7, 0.68, 0.62)

	# Body
	_fill(img, 8, 14, 14, 7, body)
	_fill(img, 7, 16, 16, 3, body)
	_fill(img, 10, 12, 10, 3, body)

	# Head
	_fill(img, 3, 6, 10, 8, body)
	_fill(img, 2, 8, 12, 4, body)

	# Horns (curved back)
	_fill(img, 4, 3, 3, 4, horn)
	_fill(img, 5, 2, 2, 2, horn_dark)
	_fill(img, 6, 1, 2, 2, horn_dark)
	_fill(img, 10, 3, 3, 4, horn)
	_fill(img, 11, 2, 2, 2, horn_dark)
	_fill(img, 12, 1, 2, 2, horn_dark)

	# Eyes (horizontal pupils like real goats)
	_fill(img, 4, 8, 3, 2, eye)
	_px(img, 5, 9, pupil)
	_fill(img, 9, 8, 3, 2, eye)
	_px(img, 10, 9, pupil)

	# Nose
	_px(img, 5, 12, nose)
	_px(img, 8, 12, nose)

	# Angry mouth
	_fill(img, 5, 13, 5, 1, Color(0.5, 0.2, 0.18))

	# Beard
	_fill(img, 5, 14, 4, 3, beard)
	_px(img, 6, 17, beard)
	_px(img, 7, 17, beard)

	# Front legs
	_fill(img, 9, 21, 3, 5, body_dark)
	_fill(img, 14, 21, 3, 5, body_dark)
	# Hooves
	_fill(img, 9, 25, 3, 2, hoof)
	_fill(img, 14, 25, 3, 2, hoof)

	# Back legs
	_fill(img, 19, 19, 3, 5, body_dark)
	_fill(img, 19, 23, 3, 2, hoof)

	# Tail (short, upright)
	_fill(img, 22, 13, 2, 3, body)
	_px(img, 23, 12, body)

	_outline(img, Color(0.2, 0.18, 0.16))
	_save(img, "res://assets/sprites/enemies/farm/farm_goat.png")

func _gen_farm_bee_swarm() -> void:
	var img = _img()
	var body_y = Color(0.95, 0.85, 0.15)
	var stripe = Color(0.12, 0.1, 0.08)
	var wing = Color(0.85, 0.9, 0.95, 0.6)
	var eye = Color(0.1, 0.1, 0.1)
	var stinger = Color(0.3, 0.25, 0.15)

	# Bee 1 (center, largest)
	_fill(img, 12, 10, 8, 5, body_y)
	_fill(img, 13, 9, 6, 1, body_y)
	_fill(img, 13, 15, 6, 1, body_y)
	_fill(img, 13, 11, 6, 1, stripe)
	_fill(img, 13, 13, 6, 1, stripe)
	_fill(img, 11, 8, 4, 3, wing)
	_fill(img, 18, 8, 4, 3, wing)
	_px(img, 13, 10, eye)
	_px(img, 18, 10, eye)
	_px(img, 20, 12, stinger)

	# Bee 2 (top-left)
	_fill(img, 4, 4, 6, 4, body_y)
	_fill(img, 5, 5, 4, 1, stripe)
	_fill(img, 5, 7, 4, 1, stripe)
	_fill(img, 3, 2, 3, 3, wing)
	_fill(img, 8, 2, 3, 3, wing)
	_px(img, 5, 4, eye)
	_px(img, 8, 4, eye)
	_px(img, 10, 6, stinger)

	# Bee 3 (top-right)
	_fill(img, 20, 3, 6, 4, body_y)
	_fill(img, 21, 4, 4, 1, stripe)
	_fill(img, 21, 6, 4, 1, stripe)
	_fill(img, 19, 1, 3, 3, wing)
	_fill(img, 24, 1, 3, 3, wing)
	_px(img, 21, 3, eye)
	_px(img, 24, 3, eye)
	_px(img, 26, 5, stinger)

	# Bee 4 (bottom-left)
	_fill(img, 3, 18, 6, 4, body_y)
	_fill(img, 4, 19, 4, 1, stripe)
	_fill(img, 4, 21, 4, 1, stripe)
	_fill(img, 2, 16, 3, 3, wing)
	_fill(img, 7, 16, 3, 3, wing)
	_px(img, 4, 18, eye)
	_px(img, 7, 18, eye)
	_px(img, 9, 20, stinger)

	# Bee 5 (bottom-right)
	_fill(img, 20, 19, 6, 4, body_y)
	_fill(img, 21, 20, 4, 1, stripe)
	_fill(img, 21, 22, 4, 1, stripe)
	_fill(img, 19, 17, 3, 3, wing)
	_fill(img, 24, 17, 3, 3, wing)
	_px(img, 21, 19, eye)
	_px(img, 24, 19, eye)
	_px(img, 26, 21, stinger)

	# Bee 6 (small, mid-left)
	_fill(img, 1, 12, 5, 3, body_y)
	_fill(img, 2, 13, 3, 1, stripe)
	_fill(img, 1, 10, 2, 3, wing)
	_px(img, 2, 12, eye)

	_outline(img, Color(0.3, 0.25, 0.05))
	_save(img, "res://assets/sprites/enemies/farm/farm_bee_swarm.png")

func _gen_farm_worm() -> void:
	var img = _img()
	var body = Color(0.82, 0.55, 0.62)
	var body_dark = Color(0.65, 0.4, 0.48)
	var body_light = Color(0.92, 0.68, 0.72)
	var ring = Color(0.72, 0.48, 0.55)
	var eye = Color(0.1, 0.1, 0.1)
	var mouth = Color(0.5, 0.2, 0.25)

	# Worm body (S-curve coming out of ground)
	# Bottom section (in ground)
	_fill(img, 20, 24, 6, 5, body_dark)
	_fill(img, 19, 26, 8, 3, body_dark)

	# Ground
	_fill(img, 16, 28, 14, 4, Color(0.45, 0.35, 0.2))
	_fill(img, 14, 29, 4, 3, Color(0.45, 0.35, 0.2))

	# Middle curve
	_fill(img, 17, 20, 6, 5, body)
	_fill(img, 14, 18, 6, 4, body)
	_fill(img, 12, 15, 5, 4, body)

	# Upper curve
	_fill(img, 10, 12, 5, 4, body)
	_fill(img, 9, 9, 5, 4, body)
	_fill(img, 10, 6, 5, 4, body)

	# Head (top, facing left)
	_fill(img, 9, 3, 7, 5, body)
	_fill(img, 8, 4, 9, 3, body)
	_fill(img, 10, 2, 5, 2, body_light)

	# Segment rings
	_line_h(img, 10, 8, 4, ring)
	_line_h(img, 11, 11, 4, ring)
	_line_h(img, 13, 14, 4, ring)
	_line_h(img, 15, 17, 4, ring)
	_line_h(img, 18, 20, 5, ring)
	_line_h(img, 20, 23, 5, ring)

	# Face
	# Eyes (two small dots)
	_px(img, 10, 4, eye)
	_px(img, 14, 4, eye)
	# Mouth (open circle)
	_fill(img, 11, 6, 3, 2, mouth)
	_px(img, 12, 5, mouth)
	# Teeth ring around mouth
	_px(img, 10, 6, body_light)
	_px(img, 14, 6, body_light)
	_px(img, 12, 7, body_light)
	_px(img, 11, 5, body_light)
	_px(img, 13, 5, body_light)

	# Light belly highlights
	_px(img, 11, 10, body_light)
	_px(img, 13, 13, body_light)
	_px(img, 16, 16, body_light)
	_px(img, 19, 21, body_light)

	_outline(img, Color(0.3, 0.18, 0.22))
	_save(img, "res://assets/sprites/enemies/farm/farm_worm.png")

# ==================== TOKYO ====================

func _gen_tokyo_yakuza() -> void:
	var img = _img()
	var skin = Color(0.82, 0.72, 0.58)
	var suit = Color(0.12, 0.12, 0.15)
	var suit_light = Color(0.2, 0.2, 0.25)
	var shirt = Color(0.95, 0.95, 0.95)
	var hair = Color(0.08, 0.08, 0.1)
	var eye = Color(0.1, 0.1, 0.1)
	var katana_blade = Color(0.82, 0.85, 0.9)
	var katana_handle = Color(0.3, 0.08, 0.08)
	var scar = Color(0.75, 0.5, 0.45)

	# Hair (slicked back)
	_fill(img, 12, 2, 8, 3, hair)
	_fill(img, 11, 3, 10, 3, hair)

	# Head
	_fill(img, 12, 4, 8, 7, skin)
	_fill(img, 11, 5, 10, 5, skin)
	# Eyes (narrow, menacing)
	_fill(img, 13, 7, 3, 1, eye)
	_fill(img, 18, 7, 3, 1, eye)
	# Scar on left cheek
	_px(img, 12, 8, scar)
	_px(img, 12, 9, scar)
	_px(img, 13, 9, scar)
	# Mouth (thin line)
	_fill(img, 14, 10, 4, 1, Color(0.5, 0.3, 0.28))

	# Suit jacket
	_fill(img, 10, 12, 12, 8, suit)
	_fill(img, 9, 13, 14, 6, suit)
	# Shirt collar V
	_px(img, 15, 12, shirt)
	_px(img, 16, 12, shirt)
	_px(img, 14, 13, shirt)
	_px(img, 17, 13, shirt)
	_px(img, 15, 13, shirt)
	_px(img, 16, 13, shirt)
	# Suit lapels
	_px(img, 13, 12, suit_light)
	_px(img, 18, 12, suit_light)
	_px(img, 12, 13, suit_light)
	_px(img, 19, 13, suit_light)

	# Arms
	_fill(img, 6, 13, 4, 7, suit)
	_fill(img, 22, 13, 4, 7, suit)
	# Hands
	_fill(img, 5, 19, 4, 2, skin)
	_fill(img, 23, 19, 4, 2, skin)

	# Pants
	_fill(img, 12, 20, 4, 5, suit)
	_fill(img, 17, 20, 4, 5, suit)
	# Shoes
	_fill(img, 11, 25, 5, 2, Color(0.15, 0.12, 0.1))
	_fill(img, 17, 25, 5, 2, Color(0.15, 0.12, 0.1))

	# Katana (held diagonally)
	for i in range(16):
		_px(img, 3 + i, 22 - i, katana_blade)
		if i < 15:
			_px(img, 4 + i, 22 - i, katana_blade)
	# Handle
	for i in range(4):
		_px(img, 2 + i, 23 + i - 1, katana_handle)
		_px(img, 3 + i, 23 + i - 1, katana_handle)
	# Guard
	_px(img, 5, 20, Color(0.75, 0.65, 0.15))
	_px(img, 6, 19, Color(0.75, 0.65, 0.15))

	_outline(img, Color(0.05, 0.05, 0.08))
	_save(img, "res://assets/sprites/enemies/tokyo/tokyo_yakuza.png")

func _gen_tokyo_cyborg() -> void:
	var img = _img()
	var skin = Color(0.78, 0.68, 0.55)
	var metal = Color(0.6, 0.62, 0.65)
	var metal_dark = Color(0.4, 0.42, 0.45)
	var metal_light = Color(0.75, 0.78, 0.82)
	var eye_red = Color(0.95, 0.15, 0.1)
	var eye_norm = Color(0.1, 0.1, 0.1)
	var wire = Color(0.2, 0.8, 0.3)
	var hair = Color(0.2, 0.18, 0.15)

	# Head - half skin, half metal
	_fill(img, 11, 3, 10, 8, skin)
	_fill(img, 10, 4, 12, 6, skin)
	# Metal half (right side)
	_fill(img, 17, 3, 5, 8, metal)
	_fill(img, 18, 2, 4, 1, metal)
	_fill(img, 17, 4, 5, 6, metal)
	# Metal plate lines
	_px(img, 18, 5, metal_dark)
	_px(img, 20, 5, metal_dark)
	_px(img, 19, 7, metal_dark)

	# Hair (left side only)
	_fill(img, 10, 2, 7, 2, hair)
	_fill(img, 9, 3, 3, 3, hair)

	# Normal eye (left)
	_px(img, 13, 6, eye_norm)
	_px(img, 14, 6, eye_norm)
	# Cyborg eye (right, glowing red)
	_fill(img, 18, 5, 3, 2, eye_red)
	_px(img, 19, 6, Color(1.0, 0.3, 0.2))

	# Mouth
	_fill(img, 14, 9, 4, 1, Color(0.5, 0.3, 0.25))
	# Metal jaw piece
	_fill(img, 17, 9, 4, 2, metal_dark)

	# Torso - half organic, half metal
	_fill(img, 10, 12, 12, 7, skin)
	_fill(img, 17, 12, 6, 7, metal)
	_fill(img, 9, 13, 14, 5, skin)
	_fill(img, 18, 13, 5, 5, metal)
	# Wires visible
	_px(img, 17, 14, wire)
	_px(img, 17, 16, wire)

	# Arms
	_fill(img, 6, 13, 4, 7, skin)
	_fill(img, 22, 13, 4, 7, metal)
	# Metal arm details
	_fill(img, 22, 15, 4, 1, metal_light)
	_fill(img, 22, 17, 4, 1, metal_light)
	# Hands
	_fill(img, 5, 19, 4, 2, skin)
	_fill(img, 23, 19, 4, 2, metal_light)

	# Pants
	_fill(img, 12, 19, 4, 5, Color(0.25, 0.25, 0.28))
	_fill(img, 17, 19, 4, 5, Color(0.25, 0.25, 0.28))
	# Boots
	_fill(img, 11, 24, 5, 3, Color(0.2, 0.2, 0.22))
	_fill(img, 17, 24, 5, 3, metal_dark)

	# Exposed wires on neck
	_px(img, 17, 11, wire)
	_px(img, 18, 11, wire)
	_px(img, 19, 11, Color(0.9, 0.2, 0.15))

	_outline(img, Color(0.08, 0.08, 0.1))
	_save(img, "res://assets/sprites/enemies/tokyo/tokyo_cyborg.png")

func _gen_tokyo_hologram() -> void:
	var img = _img()
	var holo = Color(0.2, 0.6, 0.95, 0.5)
	var holo_bright = Color(0.4, 0.8, 1.0, 0.7)
	var holo_dim = Color(0.15, 0.4, 0.7, 0.3)
	var scan = Color(0.3, 0.9, 1.0, 0.8)
	var glitch = Color(0.9, 0.2, 0.3, 0.6)
	var eye = Color(1.0, 1.0, 1.0, 0.9)

	# Humanoid figure (translucent blue)
	# Head
	_fill(img, 12, 3, 8, 7, holo)
	_fill(img, 11, 4, 10, 5, holo)
	_fill(img, 13, 2, 6, 2, holo_bright)

	# Eyes (bright white)
	_px(img, 13, 6, eye)
	_px(img, 14, 6, eye)
	_px(img, 18, 6, eye)
	_px(img, 19, 6, eye)

	# Body
	_fill(img, 11, 11, 10, 8, holo)
	_fill(img, 10, 13, 12, 4, holo)

	# Arms
	_fill(img, 7, 12, 4, 6, holo)
	_fill(img, 21, 12, 4, 6, holo)
	_fill(img, 6, 14, 3, 3, holo_dim)
	_fill(img, 23, 14, 3, 3, holo_dim)

	# Legs
	_fill(img, 12, 19, 3, 6, holo)
	_fill(img, 17, 19, 3, 6, holo)
	_fill(img, 12, 24, 3, 3, holo_dim)
	_fill(img, 17, 24, 3, 3, holo_dim)

	# Horizontal scan lines (every 3 pixels)
	for y in range(0, S, 3):
		for x in range(S):
			if img.get_pixel(x, y).a > 0.1:
				_px(img, x, y, scan)

	# Glitch artifacts (offset blocks)
	_fill(img, 14, 7, 8, 1, glitch)
	_fill(img, 8, 15, 5, 1, glitch)
	_fill(img, 18, 22, 6, 1, glitch)

	# Digital noise pixels
	_px(img, 10, 5, holo_bright)
	_px(img, 22, 7, holo_bright)
	_px(img, 8, 18, holo_dim)
	_px(img, 24, 20, holo_dim)
	_px(img, 15, 26, holo_bright)

	# Base projector line
	_fill(img, 10, 28, 12, 1, scan)
	_fill(img, 12, 29, 8, 1, holo_bright)

	_outline(img, Color(0.1, 0.3, 0.5, 0.4))
	_save(img, "res://assets/sprites/enemies/tokyo/tokyo_hologram.png")

func _gen_tokyo_turret() -> void:
	var img = _img()
	var metal = Color(0.5, 0.52, 0.55)
	var metal_dark = Color(0.35, 0.37, 0.4)
	var metal_light = Color(0.65, 0.68, 0.72)
	var barrel = Color(0.3, 0.3, 0.32)
	var lens = Color(0.95, 0.15, 0.1)
	var base = Color(0.4, 0.4, 0.42)
	var light = Color(0.1, 0.9, 0.2)

	# Base platform
	_fill(img, 6, 24, 20, 4, base)
	_fill(img, 8, 22, 16, 3, base)
	_fill(img, 7, 23, 18, 1, metal_dark)

	# Rotating body (dome)
	_fill(img, 9, 14, 14, 8, metal)
	_fill(img, 8, 16, 16, 4, metal)
	_fill(img, 10, 12, 12, 3, metal)
	_fill(img, 12, 11, 8, 2, metal_light)

	# Barrel (pointing right)
	_fill(img, 23, 16, 7, 3, barrel)
	_fill(img, 24, 15, 5, 1, barrel)
	_fill(img, 24, 19, 5, 1, barrel)
	# Barrel tip
	_fill(img, 29, 15, 2, 5, metal_dark)
	# Flash suppressor
	_px(img, 30, 16, metal_light)
	_px(img, 30, 18, metal_light)

	# Targeting lens (red eye)
	_fill(img, 12, 16, 4, 3, Color(0.15, 0.1, 0.1))
	_fill(img, 13, 17, 2, 1, lens)
	_px(img, 13, 16, Color(0.7, 0.1, 0.08))
	_px(img, 14, 16, Color(0.7, 0.1, 0.08))

	# Status light
	_px(img, 16, 13, light)
	_px(img, 17, 13, light)

	# Rivets/details
	_px(img, 10, 18, metal_light)
	_px(img, 20, 18, metal_light)
	_px(img, 10, 15, metal_light)
	_px(img, 20, 15, metal_light)

	# Ammo belt detail
	_fill(img, 7, 18, 3, 3, Color(0.6, 0.55, 0.2))
	_px(img, 7, 19, Color(0.5, 0.45, 0.15))

	# Antenna
	_line_v(img, 15, 8, 4, metal_dark)
	_px(img, 15, 7, lens)

	_outline(img, Color(0.15, 0.15, 0.18))
	_save(img, "res://assets/sprites/enemies/tokyo/tokyo_turret.png")

func _gen_tokyo_virus() -> void:
	var img = _img()
	var body = Color(0.2, 0.75, 0.25)
	var body_dark = Color(0.12, 0.55, 0.15)
	var body_light = Color(0.35, 0.9, 0.4)
	var eye = Color(0.1, 0.1, 0.1)
	var glow = Color(0.3, 1.0, 0.4, 0.5)
	var data = Color(0.15, 0.85, 0.2, 0.6)

	# Main blob body
	_circle(img, 16, 15, 8, body)
	_circle(img, 16, 15, 6, body_light)
	_circle(img, 16, 15, 3, body)

	# Pseudopod extensions
	# Top
	_fill(img, 14, 4, 4, 4, body)
	_fill(img, 15, 2, 2, 3, body_dark)
	_px(img, 15, 1, body_dark)
	# Bottom-left
	_fill(img, 6, 20, 4, 4, body)
	_fill(img, 5, 22, 3, 3, body_dark)
	_px(img, 4, 24, body_dark)
	# Bottom-right
	_fill(img, 22, 20, 4, 4, body)
	_fill(img, 24, 22, 3, 3, body_dark)
	_px(img, 27, 24, body_dark)
	# Left
	_fill(img, 4, 12, 4, 4, body)
	_fill(img, 2, 13, 3, 2, body_dark)
	# Right
	_fill(img, 24, 12, 4, 4, body)
	_fill(img, 27, 13, 3, 2, body_dark)

	# Evil face
	_fill(img, 13, 13, 2, 2, eye)
	_fill(img, 18, 13, 2, 2, eye)
	# Grinning mouth
	_fill(img, 13, 17, 6, 1, eye)
	_px(img, 12, 16, eye)
	_px(img, 19, 16, eye)

	# Digital data fragments floating around
	_px(img, 3, 8, data)
	_px(img, 4, 7, data)
	_px(img, 28, 9, data)
	_px(img, 27, 8, data)
	_px(img, 6, 27, data)
	_px(img, 25, 27, data)
	_px(img, 2, 17, data)
	_px(img, 29, 16, data)

	# Binary-like specks on body
	_px(img, 14, 10, body_light)
	_px(img, 18, 11, body_light)
	_px(img, 12, 18, body_light)
	_px(img, 20, 19, body_light)

	_outline(img, Color(0.05, 0.3, 0.08))
	_save(img, "res://assets/sprites/enemies/tokyo/tokyo_virus.png")

# ==================== VOLCANO ====================

func _gen_volcano_phoenix() -> void:
	var img = _img()
	var body = Color(0.95, 0.45, 0.1)
	var body_bright = Color(1.0, 0.7, 0.2)
	var body_dark = Color(0.8, 0.25, 0.05)
	var flame = Color(1.0, 0.85, 0.2, 0.8)
	var eye = Color(0.1, 0.1, 0.1)
	var beak = Color(0.85, 0.65, 0.1)

	# Tail flames (long, trailing)
	_fill(img, 1, 16, 6, 3, flame)
	_fill(img, 3, 14, 4, 2, flame)
	_fill(img, 0, 18, 5, 2, Color(1.0, 0.6, 0.15, 0.6))
	_fill(img, 2, 20, 3, 2, Color(1.0, 0.5, 0.1, 0.4))
	_px(img, 0, 15, Color(1.0, 0.9, 0.3, 0.5))

	# Body
	_fill(img, 10, 12, 10, 6, body)
	_fill(img, 9, 14, 12, 3, body)
	_fill(img, 7, 14, 4, 4, body_dark)

	# Wings spread (top)
	_fill(img, 5, 6, 8, 4, body)
	_fill(img, 3, 8, 6, 3, body_dark)
	_fill(img, 2, 9, 3, 2, body_bright)
	_fill(img, 19, 6, 8, 4, body)
	_fill(img, 23, 8, 6, 3, body_dark)
	_fill(img, 27, 9, 3, 2, body_bright)
	# Wing tips with flame
	_px(img, 1, 9, flame)
	_px(img, 0, 10, flame)
	_px(img, 30, 9, flame)
	_px(img, 31, 10, flame)

	# Wing middle
	_fill(img, 7, 10, 6, 3, body)
	_fill(img, 19, 10, 6, 3, body)

	# Head
	_fill(img, 14, 5, 6, 6, body)
	_fill(img, 13, 6, 8, 4, body)
	_fill(img, 15, 4, 4, 2, body_bright)
	# Crest (flames on head)
	_px(img, 15, 2, flame)
	_px(img, 16, 1, flame)
	_px(img, 17, 2, flame)
	_px(img, 18, 3, body_bright)
	_px(img, 14, 3, body_bright)

	# Eyes
	_px(img, 15, 7, eye)
	_px(img, 18, 7, eye)

	# Beak
	_fill(img, 16, 9, 2, 2, beak)
	_px(img, 17, 11, Color(0.75, 0.55, 0.08))

	# Belly glow
	_fill(img, 12, 15, 6, 2, body_bright)

	# Tail feathers
	_fill(img, 5, 17, 5, 2, body_dark)

	_outline(img, Color(0.4, 0.12, 0.02))
	_save(img, "res://assets/sprites/enemies/volcano/volcano_phoenix.png")

func _gen_volcano_lava_snake() -> void:
	var img = _img()
	var body = Color(0.9, 0.4, 0.08)
	var body_bright = Color(1.0, 0.7, 0.15)
	var body_dark = Color(0.7, 0.2, 0.05)
	var belly = Color(0.95, 0.85, 0.3)
	var eye = Color(0.95, 0.95, 0.1)
	var pupil = Color(0.1, 0.05, 0.05)
	var tongue = Color(0.95, 0.2, 0.1)

	# Snake body S-curve
	# Head (top-right, facing right)
	_fill(img, 18, 3, 8, 5, body)
	_fill(img, 17, 4, 10, 3, body)
	# Eyes
	_fill(img, 22, 4, 2, 2, eye)
	_px(img, 23, 5, pupil)
	_fill(img, 19, 4, 2, 2, eye)
	_px(img, 20, 5, pupil)
	# Tongue
	_px(img, 27, 5, tongue)
	_px(img, 28, 4, tongue)
	_px(img, 28, 6, tongue)
	_px(img, 29, 4, tongue)
	_px(img, 29, 6, tongue)

	# Neck curving down-left
	_fill(img, 16, 7, 5, 4, body)
	_fill(img, 13, 10, 5, 4, body)

	# Mid-body curving right
	_fill(img, 10, 13, 5, 4, body)
	_fill(img, 13, 15, 6, 4, body)
	_fill(img, 18, 16, 5, 4, body)

	# Tail curving left-down
	_fill(img, 15, 19, 5, 4, body)
	_fill(img, 11, 21, 5, 4, body)
	_fill(img, 8, 23, 5, 3, body_dark)
	_fill(img, 6, 25, 3, 2, body_dark)
	_px(img, 5, 26, body_dark)

	# Belly highlights along the curve
	_px(img, 18, 9, belly)
	_px(img, 15, 12, belly)
	_px(img, 14, 15, belly)
	_px(img, 19, 18, belly)
	_px(img, 14, 22, belly)
	_px(img, 9, 24, belly)

	# Glowing lava cracks on body
	_px(img, 17, 8, body_bright)
	_px(img, 12, 11, body_bright)
	_px(img, 16, 16, body_bright)
	_px(img, 20, 18, body_bright)
	_px(img, 13, 22, body_bright)

	# Head crown (small flame)
	_px(img, 21, 2, body_bright)
	_px(img, 22, 1, body_bright)
	_px(img, 23, 2, body_bright)

	_outline(img, Color(0.35, 0.1, 0.02))
	_save(img, "res://assets/sprites/enemies/volcano/volcano_lava_snake.png")

func _gen_volcano_ash_ghost() -> void:
	var img = _img()
	var body = Color(0.45, 0.42, 0.4, 0.7)
	var body_dark = Color(0.3, 0.28, 0.26, 0.8)
	var body_light = Color(0.6, 0.58, 0.55, 0.6)
	var eye = Color(0.95, 0.5, 0.1)
	var ember = Color(1.0, 0.6, 0.15, 0.7)
	var ash = Color(0.35, 0.33, 0.3, 0.4)

	# Smoky body (irregular cloud shape)
	_circle(img, 16, 14, 9, body)
	_circle(img, 14, 12, 6, body_dark)
	_circle(img, 18, 16, 6, body_light)
	_fill(img, 10, 8, 12, 4, body)
	_fill(img, 8, 12, 16, 6, body)

	# Head region (darker, more solid)
	_fill(img, 11, 5, 10, 8, body_dark)
	_fill(img, 10, 7, 12, 4, body_dark)

	# Eyes (glowing orange, hollow)
	_fill(img, 12, 7, 3, 3, Color(0.15, 0.1, 0.08))
	_fill(img, 18, 7, 3, 3, Color(0.15, 0.1, 0.08))
	_px(img, 13, 8, eye)
	_px(img, 19, 8, eye)
	# Eye glow
	_px(img, 12, 8, Color(0.8, 0.4, 0.08))
	_px(img, 14, 8, Color(0.8, 0.4, 0.08))
	_px(img, 18, 8, Color(0.8, 0.4, 0.08))
	_px(img, 20, 8, Color(0.8, 0.4, 0.08))

	# Mouth (dark void)
	_fill(img, 14, 11, 4, 2, Color(0.1, 0.08, 0.06))

	# Wispy arms
	_fill(img, 5, 12, 5, 3, body)
	_fill(img, 3, 14, 3, 2, ash)
	_fill(img, 22, 12, 5, 3, body)
	_fill(img, 27, 14, 3, 2, ash)

	# Trailing smoke bottom
	_fill(img, 10, 20, 12, 2, body)
	_fill(img, 8, 22, 5, 2, ash)
	_fill(img, 18, 22, 5, 2, ash)
	_px(img, 7, 24, ash)
	_px(img, 12, 24, ash)
	_px(img, 20, 24, ash)
	_px(img, 24, 24, ash)

	# Embers floating around
	_px(img, 8, 4, ember)
	_px(img, 24, 5, ember)
	_px(img, 5, 18, ember)
	_px(img, 27, 10, ember)
	_px(img, 16, 2, ember)
	_px(img, 22, 22, ember)

	_outline(img, Color(0.18, 0.16, 0.14))
	_save(img, "res://assets/sprites/enemies/volcano/volcano_ash_ghost.png")

func _gen_volcano_fire_bat() -> void:
	var img = _img()
	var body = Color(0.35, 0.15, 0.1)
	var body_dark = Color(0.22, 0.08, 0.06)
	var wing_mem = Color(0.6, 0.2, 0.08)
	var wing_dark = Color(0.4, 0.12, 0.05)
	var flame = Color(1.0, 0.65, 0.15)
	var flame_dark = Color(0.95, 0.4, 0.1)
	var eye = Color(0.95, 0.85, 0.1)

	# Body (small, center)
	_fill(img, 13, 12, 6, 6, body)
	_fill(img, 14, 11, 4, 1, body)
	_fill(img, 14, 18, 4, 1, body_dark)

	# Head
	_fill(img, 13, 8, 6, 4, body)
	_fill(img, 12, 9, 8, 2, body)
	# Ears (pointed)
	_fill(img, 12, 6, 2, 3, body)
	_fill(img, 18, 6, 2, 3, body)
	_px(img, 12, 5, body_dark)
	_px(img, 19, 5, body_dark)

	# Eyes (glowing)
	_px(img, 14, 9, eye)
	_px(img, 17, 9, eye)
	# Tiny fangs
	_px(img, 15, 11, Color(0.9, 0.9, 0.85))
	_px(img, 16, 11, Color(0.9, 0.9, 0.85))

	# Left wing (spread wide)
	_fill(img, 5, 10, 8, 2, wing_mem)
	_fill(img, 3, 11, 10, 3, wing_mem)
	_fill(img, 1, 13, 12, 3, wing_mem)
	_fill(img, 2, 16, 8, 2, wing_dark)
	# Wing bones
	_px(img, 8, 10, body_dark)
	_px(img, 6, 11, body_dark)
	_px(img, 4, 12, body_dark)
	_px(img, 2, 13, body_dark)
	# Flame on wing tip
	_px(img, 0, 13, flame)
	_px(img, 0, 14, flame_dark)
	_px(img, 1, 12, flame)

	# Right wing (spread wide)
	_fill(img, 19, 10, 8, 2, wing_mem)
	_fill(img, 19, 11, 10, 3, wing_mem)
	_fill(img, 19, 13, 12, 3, wing_mem)
	_fill(img, 22, 16, 8, 2, wing_dark)
	# Wing bones
	_px(img, 23, 10, body_dark)
	_px(img, 25, 11, body_dark)
	_px(img, 27, 12, body_dark)
	_px(img, 29, 13, body_dark)
	# Flame on wing tip
	_px(img, 31, 13, flame)
	_px(img, 31, 14, flame_dark)
	_px(img, 30, 12, flame)

	# Flame trail from wings
	_px(img, 3, 18, flame_dark)
	_px(img, 5, 19, flame)
	_px(img, 28, 18, flame_dark)
	_px(img, 26, 19, flame)

	# Feet (small)
	_px(img, 14, 19, body_dark)
	_px(img, 17, 19, body_dark)

	_outline(img, Color(0.12, 0.05, 0.03))
	_save(img, "res://assets/sprites/enemies/volcano/volcano_fire_bat.png")

func _gen_volcano_obsidian_golem() -> void:
	var img = _img()
	var rock = Color(0.15, 0.14, 0.18)
	var rock_light = Color(0.25, 0.24, 0.28)
	var sheen = Color(0.4, 0.38, 0.5)
	var crack = Color(0.9, 0.35, 0.08)
	var crack_bright = Color(1.0, 0.6, 0.15)
	var eye = Color(0.95, 0.45, 0.1)

	# Body (massive, blocky)
	_fill(img, 8, 10, 16, 12, rock)
	_fill(img, 7, 12, 18, 8, rock)
	_fill(img, 9, 22, 14, 2, rock)

	# Head (square, smaller than body)
	_fill(img, 10, 3, 12, 8, rock)
	_fill(img, 9, 4, 14, 6, rock)
	# Shiny obsidian highlights
	_fill(img, 11, 4, 3, 2, sheen)
	_fill(img, 18, 5, 2, 2, sheen)
	_fill(img, 10, 12, 3, 2, sheen)
	_fill(img, 20, 14, 2, 3, sheen)

	# Eyes (glowing lava)
	_fill(img, 12, 6, 3, 2, eye)
	_fill(img, 18, 6, 3, 2, eye)
	_px(img, 13, 6, crack_bright)
	_px(img, 19, 6, crack_bright)

	# Mouth crack
	_fill(img, 13, 9, 6, 1, crack)

	# Arms (thick, blocky)
	_fill(img, 3, 11, 5, 10, rock)
	_fill(img, 2, 13, 6, 6, rock)
	_fill(img, 24, 11, 5, 10, rock)
	_fill(img, 24, 13, 6, 6, rock)
	# Fists
	_fill(img, 2, 20, 6, 4, rock)
	_fill(img, 24, 20, 6, 4, rock)
	# Arm sheen
	_fill(img, 3, 14, 2, 2, sheen)
	_fill(img, 27, 14, 2, 2, sheen)

	# Legs (thick pillars)
	_fill(img, 9, 23, 5, 5, rock)
	_fill(img, 18, 23, 5, 5, rock)
	# Feet
	_fill(img, 8, 27, 6, 2, rock)
	_fill(img, 17, 27, 6, 2, rock)

	# Lava cracks throughout body
	# Chest crack
	_px(img, 14, 13, crack)
	_px(img, 15, 14, crack)
	_px(img, 16, 14, crack)
	_px(img, 17, 15, crack)
	_px(img, 18, 14, crack)
	# Arm cracks
	_px(img, 4, 16, crack)
	_px(img, 5, 17, crack)
	_px(img, 26, 16, crack)
	_px(img, 25, 17, crack)
	# Leg cracks
	_px(img, 11, 25, crack)
	_px(img, 20, 25, crack)
	# Glow from cracks
	_px(img, 15, 13, crack_bright)
	_px(img, 16, 15, crack_bright)

	_outline(img, Color(0.05, 0.04, 0.06))
	_save(img, "res://assets/sprites/enemies/volcano/volcano_obsidian_golem.png")

# ==================== OCEAN ====================

func _gen_ocean_shark() -> void:
	var img = _img()
	var body = Color(0.5, 0.52, 0.58)
	var body_dark = Color(0.35, 0.38, 0.42)
	var belly = Color(0.85, 0.85, 0.88)
	var eye = Color(0.1, 0.1, 0.1)
	var teeth = Color(0.95, 0.95, 0.95)
	var mouth = Color(0.4, 0.15, 0.15)
	var fin = Color(0.42, 0.45, 0.5)

	# Body (side view, torpedo shape)
	_fill(img, 6, 12, 20, 6, body)
	_fill(img, 4, 14, 24, 3, body)
	_fill(img, 8, 10, 16, 2, body)
	_fill(img, 10, 18, 14, 2, body)
	# Belly
	_fill(img, 8, 16, 16, 2, belly)

	# Head (pointed snout)
	_fill(img, 2, 13, 5, 4, body)
	_fill(img, 0, 14, 3, 2, body)
	# Mouth
	_fill(img, 1, 16, 8, 2, mouth)
	# Teeth (jagged)
	_px(img, 2, 16, teeth)
	_px(img, 4, 16, teeth)
	_px(img, 6, 16, teeth)
	_px(img, 8, 16, teeth)
	_px(img, 3, 15, teeth)
	_px(img, 5, 15, teeth)
	_px(img, 7, 15, teeth)

	# Eye
	_fill(img, 5, 12, 2, 2, eye)

	# Dorsal fin (top)
	_fill(img, 14, 6, 4, 4, fin)
	_fill(img, 15, 4, 3, 2, fin)
	_px(img, 16, 3, fin)

	# Tail fin
	_fill(img, 26, 10, 3, 3, fin)
	_fill(img, 28, 8, 2, 3, fin)
	_fill(img, 26, 16, 3, 3, fin)
	_fill(img, 28, 18, 2, 3, fin)
	_px(img, 30, 8, body_dark)
	_px(img, 30, 19, body_dark)

	# Pectoral fins (sides)
	_fill(img, 10, 18, 4, 3, fin)
	_fill(img, 9, 20, 3, 2, fin)

	# Gill slits
	_px(img, 8, 13, body_dark)
	_px(img, 8, 14, body_dark)
	_px(img, 8, 15, body_dark)

	_outline(img, Color(0.15, 0.18, 0.22))
	_save(img, "res://assets/sprites/enemies/ocean/ocean_shark.png")

func _gen_ocean_pufferfish() -> void:
	var img = _img()
	var body = Color(0.85, 0.78, 0.4)
	var body_dark = Color(0.7, 0.62, 0.3)
	var belly = Color(0.92, 0.9, 0.75)
	var spike = Color(0.75, 0.68, 0.35)
	var eye = Color(0.1, 0.1, 0.1)
	var eye_white = Color(0.95, 0.95, 0.95)
	var lip = Color(0.7, 0.45, 0.35)

	# Round puffed body
	_circle(img, 16, 15, 10, body)
	_circle(img, 16, 15, 8, body)
	# Belly
	_circle(img, 16, 17, 5, belly)

	# Spots on top
	_px(img, 12, 9, body_dark)
	_px(img, 18, 8, body_dark)
	_px(img, 15, 7, body_dark)
	_px(img, 21, 10, body_dark)
	_px(img, 10, 12, body_dark)

	# Eyes (large, surprised)
	_fill(img, 11, 12, 4, 4, eye_white)
	_fill(img, 18, 12, 4, 4, eye_white)
	_fill(img, 12, 13, 2, 2, eye)
	_fill(img, 19, 13, 2, 2, eye)

	# Pursed lips
	_fill(img, 14, 18, 4, 2, lip)
	_fill(img, 15, 17, 2, 1, lip)

	# Spikes all around (key visual feature)
	# Top spikes
	_px(img, 12, 4, spike)
	_px(img, 15, 3, spike)
	_px(img, 18, 4, spike)
	_px(img, 21, 5, spike)
	_px(img, 9, 6, spike)
	# Side spikes
	_px(img, 5, 12, spike)
	_px(img, 4, 15, spike)
	_px(img, 5, 18, spike)
	_px(img, 27, 12, spike)
	_px(img, 28, 15, spike)
	_px(img, 27, 18, spike)
	# Bottom spikes
	_px(img, 10, 24, spike)
	_px(img, 14, 25, spike)
	_px(img, 18, 25, spike)
	_px(img, 22, 24, spike)

	# Small tail fin
	_fill(img, 25, 14, 3, 3, body_dark)
	_px(img, 27, 13, body_dark)
	_px(img, 27, 17, body_dark)

	# Small pectoral fins
	_fill(img, 6, 15, 2, 2, body_dark)

	_outline(img, Color(0.3, 0.28, 0.12))
	_save(img, "res://assets/sprites/enemies/ocean/ocean_pufferfish.png")

func _gen_ocean_eel() -> void:
	var img = _img()
	var body = Color(0.85, 0.82, 0.2)
	var body_dark = Color(0.7, 0.65, 0.12)
	var belly = Color(0.92, 0.9, 0.55)
	var eye = Color(0.1, 0.1, 0.1)
	var spark = Color(0.5, 0.7, 1.0)
	var spark_bright = Color(0.7, 0.9, 1.0)
	var mouth = Color(0.4, 0.15, 0.15)

	# Eel body (sinuous S-curve)
	# Head (top left)
	_fill(img, 4, 3, 8, 5, body)
	_fill(img, 3, 4, 10, 3, body)
	# Eyes
	_fill(img, 5, 4, 2, 2, Color(0.95, 0.95, 0.95))
	_px(img, 6, 5, eye)
	_fill(img, 9, 4, 2, 2, Color(0.95, 0.95, 0.95))
	_px(img, 10, 5, eye)
	# Mouth
	_fill(img, 5, 7, 6, 1, mouth)
	_px(img, 6, 7, Color(0.9, 0.9, 0.85))
	_px(img, 9, 7, Color(0.9, 0.9, 0.85))

	# Curve down-right
	_fill(img, 10, 7, 5, 4, body)
	_fill(img, 14, 10, 5, 4, body)
	_fill(img, 18, 12, 5, 4, body)

	# Curve back left
	_fill(img, 17, 15, 5, 4, body)
	_fill(img, 13, 17, 5, 4, body)
	_fill(img, 10, 19, 5, 4, body)

	# Curve down right to tail
	_fill(img, 12, 22, 5, 4, body)
	_fill(img, 16, 24, 5, 3, body_dark)
	_fill(img, 19, 25, 4, 2, body_dark)
	_px(img, 22, 26, body_dark)

	# Belly highlights
	_px(img, 6, 6, belly)
	_px(img, 13, 11, belly)
	_px(img, 20, 14, belly)
	_px(img, 14, 18, belly)
	_px(img, 14, 23, belly)

	# Electric sparks
	_px(img, 2, 2, spark_bright)
	_px(img, 1, 3, spark)
	_px(img, 13, 8, spark_bright)
	_px(img, 22, 11, spark_bright)
	_px(img, 23, 12, spark)
	_px(img, 8, 19, spark_bright)
	_px(img, 7, 20, spark)
	_px(img, 17, 22, spark_bright)
	_px(img, 25, 25, spark)

	# Dorsal fin line
	_px(img, 12, 9, body_dark)
	_px(img, 16, 11, body_dark)
	_px(img, 20, 14, body_dark)

	_outline(img, Color(0.35, 0.32, 0.06))
	_save(img, "res://assets/sprites/enemies/ocean/ocean_eel.png")

func _gen_ocean_seahorse() -> void:
	var img = _img()
	var body = Color(0.3, 0.55, 0.45)
	var body_light = Color(0.45, 0.7, 0.58)
	var body_dark = Color(0.2, 0.4, 0.32)
	var armor = Color(0.5, 0.65, 0.55)
	var eye = Color(0.9, 0.8, 0.1)
	var pupil = Color(0.1, 0.1, 0.1)
	var snout = Color(0.35, 0.58, 0.48)
	var crown = Color(0.65, 0.6, 0.3)

	# Crown/crest on head
	_px(img, 14, 0, crown)
	_px(img, 15, 0, crown)
	_px(img, 13, 1, crown)
	_px(img, 16, 1, crown)
	_fill(img, 14, 1, 2, 2, crown)

	# Head (round)
	_fill(img, 12, 3, 6, 5, body)
	_fill(img, 11, 4, 8, 3, body)

	# Eye
	_fill(img, 13, 4, 2, 2, eye)
	_px(img, 14, 5, pupil)

	# Snout (long, thin, pointing right)
	_fill(img, 18, 5, 5, 2, snout)
	_fill(img, 22, 5, 2, 1, snout)

	# Neck
	_fill(img, 13, 8, 4, 3, body)

	# Armored body (segmented belly plates)
	_fill(img, 12, 11, 6, 3, body)
	_fill(img, 11, 13, 7, 3, body)
	_fill(img, 10, 15, 7, 3, body)
	_fill(img, 9, 17, 7, 3, body)
	# Armor plates
	_fill(img, 12, 11, 4, 1, armor)
	_fill(img, 11, 13, 5, 1, armor)
	_fill(img, 10, 15, 5, 1, armor)
	_fill(img, 9, 17, 5, 1, armor)

	# Curled tail
	_fill(img, 8, 19, 6, 2, body)
	_fill(img, 7, 21, 5, 2, body_dark)
	_fill(img, 8, 23, 4, 2, body_dark)
	_fill(img, 10, 24, 3, 2, body_dark)
	_fill(img, 12, 24, 2, 2, body_dark)
	_px(img, 13, 25, body_dark)
	_px(img, 13, 23, body_dark)

	# Dorsal fin (spiky)
	_px(img, 17, 12, body_light)
	_px(img, 18, 11, body_light)
	_px(img, 17, 14, body_light)
	_px(img, 18, 13, body_light)
	_px(img, 16, 16, body_light)
	_px(img, 17, 15, body_light)

	# Belly highlights
	_px(img, 13, 12, body_light)
	_px(img, 12, 14, body_light)
	_px(img, 11, 16, body_light)
	_px(img, 10, 18, body_light)

	_outline(img, Color(0.1, 0.22, 0.16))
	_save(img, "res://assets/sprites/enemies/ocean/ocean_seahorse.png")

func _gen_ocean_octopus() -> void:
	var img = _img()
	var body = Color(0.75, 0.2, 0.15)
	var body_dark = Color(0.55, 0.12, 0.08)
	var body_light = Color(0.88, 0.35, 0.25)
	var sucker = Color(0.9, 0.65, 0.55)
	var eye = Color(0.95, 0.9, 0.1)
	var pupil = Color(0.1, 0.08, 0.08)

	# Head (large, bulbous dome)
	_fill(img, 9, 2, 14, 10, body)
	_fill(img, 8, 4, 16, 6, body)
	_fill(img, 10, 1, 12, 2, body)
	# Head highlight
	_fill(img, 11, 3, 4, 3, body_light)

	# Eyes (large, expressive)
	_fill(img, 10, 7, 4, 3, Color(0.95, 0.95, 0.95))
	_fill(img, 18, 7, 4, 3, Color(0.95, 0.95, 0.95))
	_fill(img, 11, 8, 2, 2, eye)
	_fill(img, 19, 8, 2, 2, eye)
	_px(img, 12, 9, pupil)
	_px(img, 20, 9, pupil)
	# Angry brows
	_px(img, 10, 6, body_dark)
	_px(img, 11, 6, body_dark)
	_px(img, 21, 6, body_dark)
	_px(img, 22, 6, body_dark)

	# Tentacles (8, radiating outward)
	# Front-left tentacle
	_fill(img, 5, 12, 4, 3, body)
	_fill(img, 3, 15, 3, 3, body)
	_fill(img, 1, 18, 3, 2, body_dark)
	_px(img, 2, 16, sucker)
	_px(img, 3, 17, sucker)

	# Front-right tentacle
	_fill(img, 23, 12, 4, 3, body)
	_fill(img, 26, 15, 3, 3, body)
	_fill(img, 28, 18, 3, 2, body_dark)
	_px(img, 28, 16, sucker)
	_px(img, 27, 17, sucker)

	# Mid-left tentacle
	_fill(img, 7, 12, 3, 4, body)
	_fill(img, 5, 16, 3, 4, body)
	_fill(img, 3, 20, 3, 3, body_dark)
	_px(img, 5, 18, sucker)
	_px(img, 4, 20, sucker)

	# Mid-right tentacle
	_fill(img, 22, 12, 3, 4, body)
	_fill(img, 24, 16, 3, 4, body)
	_fill(img, 26, 20, 3, 3, body_dark)
	_px(img, 25, 18, sucker)
	_px(img, 27, 20, sucker)

	# Center-left tentacle
	_fill(img, 10, 12, 3, 5, body)
	_fill(img, 8, 17, 3, 4, body)
	_fill(img, 7, 21, 3, 4, body_dark)
	_px(img, 9, 19, sucker)
	_px(img, 8, 22, sucker)

	# Center-right tentacle
	_fill(img, 19, 12, 3, 5, body)
	_fill(img, 21, 17, 3, 4, body)
	_fill(img, 22, 21, 3, 4, body_dark)
	_px(img, 22, 19, sucker)
	_px(img, 23, 22, sucker)

	# Inner-left tentacle
	_fill(img, 12, 12, 3, 6, body)
	_fill(img, 11, 18, 3, 5, body_dark)
	_fill(img, 10, 23, 3, 4, body_dark)
	_px(img, 12, 20, sucker)
	_px(img, 11, 24, sucker)

	# Inner-right tentacle
	_fill(img, 17, 12, 3, 6, body)
	_fill(img, 18, 18, 3, 5, body_dark)
	_fill(img, 19, 23, 3, 4, body_dark)
	_px(img, 18, 20, sucker)
	_px(img, 20, 24, sucker)

	_outline(img, Color(0.25, 0.06, 0.04))
	_save(img, "res://assets/sprites/enemies/ocean/ocean_octopus.png")

# ==================== ARENA ====================

func _gen_arena_archer() -> void:
	var img = _img()
	var skin = Color(0.75, 0.58, 0.42)
	var tunic = Color(0.7, 0.15, 0.1)
	var tunic_dark = Color(0.5, 0.1, 0.07)
	var armor = Color(0.65, 0.6, 0.3)
	var hair = Color(0.3, 0.2, 0.1)
	var eye = Color(0.1, 0.1, 0.1)
	var bow = Color(0.5, 0.35, 0.15)
	var string = Color(0.85, 0.82, 0.75)

	# Head
	_fill(img, 13, 3, 6, 6, skin)
	_fill(img, 12, 4, 8, 4, skin)
	# Hair
	_fill(img, 13, 2, 6, 2, hair)
	_fill(img, 12, 3, 8, 2, hair)
	# Eyes
	_px(img, 14, 6, eye)
	_px(img, 17, 6, eye)
	# Mouth
	_px(img, 15, 8, Color(0.5, 0.3, 0.25))

	# Leather chest armor
	_fill(img, 11, 10, 10, 6, tunic)
	_fill(img, 10, 11, 12, 4, tunic)
	# Armor strap diagonal
	_px(img, 12, 10, armor)
	_px(img, 13, 11, armor)
	_px(img, 14, 12, armor)
	_px(img, 15, 13, armor)
	_px(img, 18, 10, armor)
	_px(img, 19, 11, armor)

	# Arms
	_fill(img, 7, 11, 4, 6, skin)
	_fill(img, 21, 11, 4, 6, skin)
	# Left hand holding bow
	_fill(img, 5, 16, 3, 2, skin)

	# Skirt
	_fill(img, 11, 16, 10, 3, tunic_dark)
	_px(img, 12, 19, tunic_dark)
	_px(img, 15, 19, tunic_dark)
	_px(img, 18, 19, tunic_dark)

	# Legs
	_fill(img, 12, 19, 3, 5, skin)
	_fill(img, 17, 19, 3, 5, skin)
	# Sandals
	_fill(img, 11, 24, 4, 2, Color(0.45, 0.3, 0.15))
	_fill(img, 17, 24, 4, 2, Color(0.45, 0.3, 0.15))

	# Bow (left side)
	_line_v(img, 4, 8, 14, bow)
	_px(img, 3, 8, bow)
	_px(img, 3, 21, bow)
	# String
	_line_v(img, 6, 9, 12, string)

	# Arrow (nocked)
	_line_h(img, 6, 14, 16, Color(0.6, 0.5, 0.3))
	_px(img, 22, 14, Color(0.5, 0.5, 0.55))
	_px(img, 23, 14, Color(0.5, 0.5, 0.55))
	# Fletching
	_px(img, 6, 13, Color(0.8, 0.2, 0.15))
	_px(img, 6, 15, Color(0.8, 0.2, 0.15))

	# Quiver on back
	_fill(img, 20, 8, 3, 8, Color(0.45, 0.3, 0.15))
	_px(img, 20, 7, Color(0.5, 0.5, 0.55))
	_px(img, 21, 7, Color(0.5, 0.5, 0.55))
	_px(img, 22, 7, Color(0.5, 0.5, 0.55))

	_outline(img, Color(0.15, 0.1, 0.05))
	_save(img, "res://assets/sprites/enemies/arena/arena_archer.png")

func _gen_arena_tiger() -> void:
	var img = _img()
	var body = Color(0.9, 0.6, 0.15)
	var stripe = Color(0.15, 0.1, 0.05)
	var belly = Color(0.95, 0.9, 0.75)
	var eye = Color(0.85, 0.75, 0.1)
	var pupil = Color(0.1, 0.1, 0.1)
	var nose = Color(0.3, 0.18, 0.12)
	var teeth = Color(0.95, 0.95, 0.95)

	# Body (side view, crouched to pounce)
	_fill(img, 6, 14, 18, 6, body)
	_fill(img, 8, 12, 14, 2, body)
	_fill(img, 7, 20, 16, 2, body)
	# Belly
	_fill(img, 10, 17, 10, 2, belly)

	# Head
	_fill(img, 1, 8, 10, 8, body)
	_fill(img, 0, 10, 12, 4, body)
	# White face patches
	_fill(img, 2, 12, 4, 3, belly)
	_fill(img, 7, 12, 4, 3, belly)

	# Ears
	_fill(img, 2, 6, 3, 3, body)
	_fill(img, 8, 6, 3, 3, body)
	_px(img, 3, 7, Color(0.85, 0.6, 0.55))
	_px(img, 9, 7, Color(0.85, 0.6, 0.55))

	# Eyes
	_fill(img, 3, 10, 2, 2, eye)
	_fill(img, 8, 10, 2, 2, eye)
	_px(img, 4, 11, pupil)
	_px(img, 9, 11, pupil)

	# Nose
	_fill(img, 5, 13, 3, 1, nose)
	# Mouth
	_fill(img, 3, 14, 7, 1, Color(0.5, 0.18, 0.15))
	_px(img, 4, 14, teeth)
	_px(img, 6, 14, teeth)
	_px(img, 8, 14, teeth)

	# Tiger stripes on body
	_fill(img, 10, 13, 2, 4, stripe)
	_fill(img, 14, 12, 2, 5, stripe)
	_fill(img, 18, 13, 2, 4, stripe)
	_fill(img, 22, 14, 2, 3, stripe)
	# Head stripes
	_px(img, 4, 8, stripe)
	_px(img, 5, 9, stripe)
	_px(img, 8, 8, stripe)
	_px(img, 7, 9, stripe)

	# Legs
	_fill(img, 7, 21, 4, 5, body)
	_fill(img, 14, 21, 4, 5, body)
	_fill(img, 20, 20, 4, 5, body)
	# Paws
	_fill(img, 6, 26, 5, 2, body)
	_fill(img, 13, 26, 5, 2, body)
	_fill(img, 19, 25, 5, 2, body)

	# Tail
	_px(img, 24, 14, body)
	_px(img, 25, 13, body)
	_px(img, 26, 12, body)
	_px(img, 27, 12, stripe)
	_px(img, 28, 11, body)
	_px(img, 29, 11, stripe)

	_outline(img, Color(0.25, 0.15, 0.03))
	_save(img, "res://assets/sprites/enemies/arena/arena_tiger.png")

func _gen_arena_prisoner() -> void:
	var img = _img()
	var skin = Color(0.7, 0.55, 0.4)
	var cloth = Color(0.6, 0.58, 0.52)
	var cloth_dark = Color(0.45, 0.42, 0.38)
	var chain = Color(0.55, 0.55, 0.58)
	var chain_dark = Color(0.38, 0.38, 0.42)
	var eye = Color(0.1, 0.1, 0.1)
	var club = Color(0.5, 0.35, 0.2)
	var club_dark = Color(0.35, 0.22, 0.12)

	# Head (bald, scarred)
	_fill(img, 12, 3, 8, 7, skin)
	_fill(img, 11, 4, 10, 5, skin)
	# Eyes (wild)
	_px(img, 14, 6, eye)
	_px(img, 18, 6, eye)
	# Scar across face
	_px(img, 13, 5, Color(0.55, 0.35, 0.3))
	_px(img, 14, 5, Color(0.55, 0.35, 0.3))
	_px(img, 15, 6, Color(0.55, 0.35, 0.3))
	# Mouth (grimace)
	_fill(img, 14, 8, 4, 1, Color(0.45, 0.25, 0.2))

	# Tattered cloth (one shoulder)
	_fill(img, 10, 10, 12, 8, cloth)
	_fill(img, 9, 12, 14, 4, cloth)
	# Torn edges
	_px(img, 10, 18, cloth)
	_px(img, 13, 18, cloth)
	_px(img, 16, 18, cloth_dark)
	_px(img, 19, 18, cloth)
	# Exposed chest
	_fill(img, 13, 11, 6, 3, skin)

	# Chains on wrists
	_fill(img, 6, 17, 3, 2, chain)
	_px(img, 5, 17, chain_dark)
	_px(img, 5, 18, chain_dark)
	_fill(img, 23, 17, 3, 2, chain)
	_px(img, 26, 17, chain_dark)
	_px(img, 26, 18, chain_dark)
	# Chain links dangling
	_px(img, 4, 19, chain)
	_px(img, 4, 21, chain)
	_px(img, 27, 19, chain)
	_px(img, 27, 21, chain)

	# Arms (muscular)
	_fill(img, 6, 12, 4, 6, skin)
	_fill(img, 22, 12, 4, 6, skin)

	# Legs (torn cloth)
	_fill(img, 12, 18, 3, 6, cloth_dark)
	_fill(img, 17, 18, 3, 6, cloth_dark)
	# Bare feet
	_fill(img, 11, 24, 4, 2, skin)
	_fill(img, 17, 24, 4, 2, skin)

	# Crude club in right hand
	_fill(img, 24, 6, 3, 12, club)
	_fill(img, 23, 4, 5, 4, club)
	_fill(img, 23, 3, 5, 2, club_dark)
	# Nails in club
	_px(img, 23, 4, chain)
	_px(img, 27, 5, chain)
	_px(img, 24, 7, chain)

	_outline(img, Color(0.15, 0.12, 0.08))
	_save(img, "res://assets/sprites/enemies/arena/arena_prisoner.png")

func _gen_arena_eagle() -> void:
	var img = _img()
	var body = Color(0.75, 0.6, 0.2)
	var body_dark = Color(0.55, 0.42, 0.12)
	var wing = Color(0.65, 0.5, 0.15)
	var wing_dark = Color(0.45, 0.32, 0.08)
	var belly = Color(0.9, 0.85, 0.65)
	var eye = Color(0.9, 0.75, 0.1)
	var pupil = Color(0.1, 0.1, 0.1)
	var beak = Color(0.85, 0.65, 0.1)

	# Body (centered)
	_fill(img, 12, 12, 8, 8, body)
	_fill(img, 13, 10, 6, 2, body)
	_fill(img, 13, 20, 6, 2, body_dark)
	# Belly
	_fill(img, 13, 14, 6, 4, belly)

	# Head
	_fill(img, 13, 4, 6, 7, body)
	_fill(img, 12, 5, 8, 5, body)
	# Crown feathers
	_fill(img, 14, 2, 4, 3, body)
	_px(img, 15, 1, body_dark)
	_px(img, 16, 1, body_dark)

	# Eyes (fierce)
	_fill(img, 13, 6, 2, 2, eye)
	_fill(img, 17, 6, 2, 2, eye)
	_px(img, 14, 7, pupil)
	_px(img, 18, 7, pupil)
	# Brow ridge
	_fill(img, 13, 5, 2, 1, body_dark)
	_fill(img, 17, 5, 2, 1, body_dark)

	# Beak (curved, golden)
	_fill(img, 15, 8, 2, 2, beak)
	_px(img, 15, 10, beak)
	_px(img, 16, 10, Color(0.7, 0.5, 0.08))

	# Wings spread wide
	# Left wing
	_fill(img, 4, 10, 9, 3, wing)
	_fill(img, 2, 12, 10, 3, wing)
	_fill(img, 1, 14, 8, 2, wing_dark)
	_px(img, 0, 15, wing_dark)
	_px(img, 0, 14, wing)
	# Feather details
	_px(img, 3, 14, body)
	_px(img, 5, 14, body)

	# Right wing
	_fill(img, 19, 10, 9, 3, wing)
	_fill(img, 20, 12, 10, 3, wing)
	_fill(img, 23, 14, 8, 2, wing_dark)
	_px(img, 31, 15, wing_dark)
	_px(img, 31, 14, wing)
	_px(img, 26, 14, body)
	_px(img, 28, 14, body)

	# Tail feathers
	_fill(img, 13, 21, 6, 3, wing)
	_fill(img, 14, 24, 4, 2, wing_dark)

	# Talons
	_fill(img, 12, 22, 2, 3, body_dark)
	_fill(img, 18, 22, 2, 3, body_dark)
	_px(img, 11, 24, beak)
	_px(img, 13, 24, beak)
	_px(img, 18, 24, beak)
	_px(img, 20, 24, beak)

	_outline(img, Color(0.22, 0.16, 0.04))
	_save(img, "res://assets/sprites/enemies/arena/arena_eagle.png")

func _gen_arena_net_fighter() -> void:
	var img = _img()
	var skin = Color(0.75, 0.58, 0.42)
	var armor = Color(0.6, 0.58, 0.35)
	var armor_dark = Color(0.45, 0.42, 0.25)
	var cloth = Color(0.3, 0.5, 0.35)
	var eye = Color(0.1, 0.1, 0.1)
	var net = Color(0.65, 0.6, 0.5)
	var trident = Color(0.6, 0.62, 0.65)
	var trident_light = Color(0.75, 0.78, 0.82)

	# Head
	_fill(img, 13, 3, 6, 6, skin)
	_fill(img, 12, 4, 8, 4, skin)
	# Helmet (partial)
	_fill(img, 12, 2, 8, 3, armor)
	_fill(img, 11, 3, 2, 3, armor)
	_fill(img, 19, 3, 2, 3, armor)
	# Eyes
	_px(img, 14, 6, eye)
	_px(img, 17, 6, eye)
	# Mouth
	_px(img, 15, 8, Color(0.5, 0.3, 0.25))

	# Shoulder pad (one side - left)
	_fill(img, 8, 10, 5, 3, armor)
	_fill(img, 9, 10, 3, 1, armor_dark)

	# Torso (partial armor)
	_fill(img, 11, 10, 10, 7, cloth)
	_fill(img, 10, 12, 12, 4, cloth)
	# Armor belt
	_fill(img, 11, 16, 10, 1, armor)

	# Arms
	_fill(img, 7, 13, 4, 6, skin)
	_fill(img, 21, 13, 4, 6, skin)

	# Legs
	_fill(img, 12, 17, 3, 6, cloth)
	_fill(img, 17, 17, 3, 6, cloth)
	# Greaves
	_fill(img, 12, 22, 3, 2, armor)
	_fill(img, 17, 22, 3, 2, armor)
	# Sandals
	_fill(img, 11, 24, 4, 2, Color(0.45, 0.3, 0.15))
	_fill(img, 17, 24, 4, 2, Color(0.45, 0.3, 0.15))

	# Trident (right hand)
	_line_v(img, 24, 3, 18, trident)
	_line_v(img, 25, 3, 18, trident)
	# Three prongs
	_line_v(img, 23, 0, 4, trident_light)
	_line_v(img, 25, 0, 4, trident_light)
	_line_v(img, 27, 0, 4, trident_light)
	_px(img, 23, 0, trident_light)
	_px(img, 27, 0, trident_light)
	# Cross guard
	_fill(img, 22, 4, 7, 1, trident)

	# Net (left hand, draped)
	# Net grid pattern
	for x in range(0, 8, 2):
		for y in range(14, 26, 2):
			_px(img, x, y, net)
	for x in range(1, 8, 2):
		for y in range(15, 26, 2):
			_px(img, x, y, net)
	# Net connections
	for x in range(0, 7):
		if x % 2 == 0:
			_px(img, x, 14, net)
		_px(img, x, 25, net)
	# Weights at bottom
	_px(img, 1, 26, armor_dark)
	_px(img, 4, 26, armor_dark)
	_px(img, 7, 26, armor_dark)

	_outline(img, Color(0.15, 0.12, 0.08))
	_save(img, "res://assets/sprites/enemies/arena/arena_net_fighter.png")

# ==================== SPACE ====================

func _gen_space_robot() -> void:
	var img = _img()
	var metal = Color(0.55, 0.58, 0.62)
	var metal_dark = Color(0.38, 0.4, 0.45)
	var metal_light = Color(0.72, 0.75, 0.8)
	var eye = Color(0.95, 0.15, 0.1)
	var joint = Color(0.3, 0.32, 0.35)
	var light = Color(0.2, 0.85, 0.3)

	# Head (boxy)
	_fill(img, 11, 3, 10, 7, metal)
	_fill(img, 10, 4, 12, 5, metal)
	# Antenna
	_line_v(img, 16, 0, 4, metal_dark)
	_px(img, 16, 0, eye)
	# Visor
	_fill(img, 12, 5, 8, 3, Color(0.1, 0.1, 0.15))
	# Eyes (red dots)
	_fill(img, 13, 6, 2, 1, eye)
	_fill(img, 17, 6, 2, 1, eye)
	# Mouth grill
	_fill(img, 13, 8, 6, 1, metal_dark)
	_px(img, 14, 8, metal_light)
	_px(img, 16, 8, metal_light)
	_px(img, 18, 8, metal_light)

	# Neck
	_fill(img, 14, 10, 4, 1, joint)

	# Torso (boxy)
	_fill(img, 10, 11, 12, 8, metal)
	_fill(img, 9, 12, 14, 6, metal)
	# Chest panel
	_fill(img, 12, 13, 8, 4, metal_dark)
	# Status lights
	_px(img, 13, 14, light)
	_px(img, 15, 14, eye)
	_px(img, 17, 14, light)
	# Rivets
	_px(img, 10, 12, metal_light)
	_px(img, 21, 12, metal_light)
	_px(img, 10, 17, metal_light)
	_px(img, 21, 17, metal_light)

	# Arms (segmented)
	_fill(img, 5, 12, 4, 3, metal)
	_fill(img, 4, 14, 4, 1, joint)
	_fill(img, 4, 15, 4, 4, metal_dark)
	_fill(img, 3, 18, 5, 2, metal)

	_fill(img, 23, 12, 4, 3, metal)
	_fill(img, 24, 14, 4, 1, joint)
	_fill(img, 24, 15, 4, 4, metal_dark)
	_fill(img, 24, 18, 5, 2, metal)

	# Legs (segmented)
	_fill(img, 11, 19, 4, 2, joint)
	_fill(img, 11, 21, 4, 4, metal_dark)
	_fill(img, 10, 25, 5, 2, metal)

	_fill(img, 17, 19, 4, 2, joint)
	_fill(img, 17, 21, 4, 4, metal_dark)
	_fill(img, 17, 25, 5, 2, metal)

	_outline(img, Color(0.15, 0.15, 0.2))
	_save(img, "res://assets/sprites/enemies/space/space_robot.png")

func _gen_space_tentacle() -> void:
	var img = _img()
	var flesh = Color(0.45, 0.25, 0.5)
	var flesh_dark = Color(0.3, 0.15, 0.35)
	var flesh_light = Color(0.6, 0.38, 0.65)
	var sucker = Color(0.7, 0.5, 0.6)
	var slime = Color(0.5, 0.8, 0.4, 0.6)
	var wall = Color(0.4, 0.42, 0.45)

	# Wall section (right side, where tentacle emerges)
	_fill(img, 26, 0, 6, 32, wall)
	_fill(img, 24, 0, 3, 32, Color(0.35, 0.37, 0.4))

	# Tentacle emerging from wall, curving left
	# Base at wall
	_fill(img, 20, 10, 6, 6, flesh)
	_fill(img, 22, 8, 4, 3, flesh)

	# Main body curves
	_fill(img, 16, 12, 5, 5, flesh)
	_fill(img, 12, 14, 5, 5, flesh)
	_fill(img, 8, 13, 5, 5, flesh)
	_fill(img, 5, 10, 5, 5, flesh)

	# Tip (reaching/grasping)
	_fill(img, 2, 8, 5, 4, flesh)
	_fill(img, 1, 9, 3, 2, flesh_light)
	# Tip curls
	_px(img, 0, 8, flesh_light)
	_px(img, 0, 9, flesh)
	_px(img, 1, 7, flesh_light)

	# Suckers along the underside
	_px(img, 21, 15, sucker)
	_px(img, 18, 16, sucker)
	_px(img, 15, 17, sucker)
	_px(img, 12, 18, sucker)
	_px(img, 9, 17, sucker)
	_px(img, 6, 14, sucker)
	_px(img, 3, 11, sucker)

	# Dark underside
	_px(img, 20, 14, flesh_dark)
	_px(img, 17, 15, flesh_dark)
	_px(img, 14, 17, flesh_dark)
	_px(img, 11, 16, flesh_dark)
	_px(img, 8, 15, flesh_dark)
	_px(img, 5, 13, flesh_dark)

	# Slime drips
	_px(img, 19, 17, slime)
	_px(img, 19, 18, slime)
	_px(img, 13, 19, slime)
	_px(img, 13, 20, slime)
	_px(img, 7, 18, slime)

	# Small secondary tentacle
	_fill(img, 22, 18, 3, 3, flesh_dark)
	_fill(img, 19, 20, 4, 3, flesh_dark)
	_fill(img, 17, 22, 3, 2, flesh_dark)

	_outline(img, Color(0.15, 0.08, 0.18))
	_save(img, "res://assets/sprites/enemies/space/space_tentacle.png")

func _gen_space_crystal() -> void:
	var img = _img()
	var crystal = Color(0.5, 0.3, 0.8)
	var crystal_light = Color(0.7, 0.5, 0.95)
	var crystal_dark = Color(0.3, 0.15, 0.55)
	var glow = Color(0.6, 0.4, 0.9, 0.5)
	var core = Color(0.85, 0.7, 1.0)
	var eye = Color(0.95, 0.2, 0.2)

	# Outer glow
	_circle(img, 16, 15, 10, Color(0.4, 0.2, 0.65, 0.15))

	# Main crystal body (hexagonal-ish)
	_fill(img, 12, 6, 8, 18, crystal)
	_fill(img, 10, 8, 12, 14, crystal)
	_fill(img, 9, 10, 14, 10, crystal)

	# Facets (light and dark faces)
	# Right face (lighter)
	_fill(img, 17, 8, 5, 12, crystal_light)
	_fill(img, 19, 10, 4, 8, crystal_light)
	# Left face (darker)
	_fill(img, 9, 10, 4, 10, crystal_dark)
	_fill(img, 10, 8, 3, 4, crystal_dark)

	# Top point
	_fill(img, 14, 3, 4, 4, crystal)
	_fill(img, 15, 1, 2, 3, crystal_light)
	_px(img, 15, 0, crystal)

	# Bottom point
	_fill(img, 14, 23, 4, 3, crystal)
	_fill(img, 15, 25, 2, 3, crystal_dark)
	_px(img, 15, 27, crystal_dark)

	# Inner core glow
	_fill(img, 14, 12, 4, 6, core)
	_fill(img, 13, 14, 6, 2, core)

	# Hostile eye in core
	_fill(img, 14, 13, 4, 3, Color(0.15, 0.05, 0.1))
	_px(img, 15, 14, eye)
	_px(img, 16, 14, eye)

	# Floating crystal shards around
	_fill(img, 3, 6, 2, 4, crystal_dark)
	_px(img, 3, 5, crystal)
	_fill(img, 27, 8, 2, 3, crystal_light)
	_px(img, 28, 7, crystal)
	_fill(img, 5, 22, 2, 3, crystal)
	_fill(img, 25, 20, 2, 3, crystal_dark)

	_outline(img, Color(0.18, 0.08, 0.3))
	_save(img, "res://assets/sprites/enemies/space/space_crystal.png")

func _gen_space_worm() -> void:
	var img = _img()
	var body = Color(0.45, 0.55, 0.42)
	var body_dark = Color(0.3, 0.4, 0.28)
	var body_light = Color(0.6, 0.7, 0.55)
	var ring = Color(0.38, 0.48, 0.35)
	var eye = Color(0.1, 0.1, 0.1)
	var mouth = Color(0.5, 0.2, 0.2)
	var teeth = Color(0.9, 0.88, 0.82)
	var antenna = Color(0.7, 0.8, 0.3)

	# Body segments (curved like a caterpillar/worm in space)
	# Segment 1 (tail, bottom right)
	_circle(img, 24, 24, 3, body_dark)
	_px(img, 24, 24, body_light)
	# Segment 2
	_circle(img, 21, 20, 3, body)
	_px(img, 21, 20, body_light)
	# Segment 3
	_circle(img, 17, 18, 4, body)
	_px(img, 17, 18, body_light)
	# Segment 4 (largest, mid body)
	_circle(img, 13, 15, 4, body)
	_px(img, 13, 15, body_light)
	# Segment 5
	_circle(img, 10, 11, 4, body)
	_px(img, 10, 11, body_light)

	# Head (segment 6, front, top-left)
	_circle(img, 10, 6, 5, body)
	_fill(img, 7, 4, 8, 5, body)

	# Segment ring lines
	_px(img, 22, 22, ring)
	_px(img, 23, 22, ring)
	_px(img, 19, 19, ring)
	_px(img, 20, 19, ring)
	_px(img, 15, 17, ring)
	_px(img, 16, 17, ring)
	_px(img, 11, 14, ring)
	_px(img, 12, 14, ring)

	# Eyes (two, on head)
	_fill(img, 7, 4, 3, 3, Color(0.95, 0.95, 0.95))
	_fill(img, 12, 4, 3, 3, Color(0.95, 0.95, 0.95))
	_px(img, 8, 5, eye)
	_px(img, 13, 5, eye)

	# Mouth (circular, with teeth)
	_fill(img, 9, 8, 4, 3, mouth)
	_px(img, 9, 8, teeth)
	_px(img, 12, 8, teeth)
	_px(img, 10, 10, teeth)
	_px(img, 11, 10, teeth)

	# Antennae
	_px(img, 7, 2, antenna)
	_px(img, 6, 1, antenna)
	_px(img, 5, 0, Color(0.9, 0.95, 0.4))
	_px(img, 14, 2, antenna)
	_px(img, 15, 1, antenna)
	_px(img, 16, 0, Color(0.9, 0.95, 0.4))

	# Tiny legs/appendages on segments
	_px(img, 11, 13, body_dark)
	_px(img, 15, 19, body_dark)
	_px(img, 19, 21, body_dark)
	_px(img, 23, 25, body_dark)

	_outline(img, Color(0.12, 0.18, 0.1))
	_save(img, "res://assets/sprites/enemies/space/space_worm.png")

func _gen_space_sentinel() -> void:
	var img = _img()
	var body = Color(0.4, 0.42, 0.48)
	var body_light = Color(0.55, 0.58, 0.65)
	var body_dark = Color(0.28, 0.3, 0.35)
	var eye = Color(0.95, 0.12, 0.08)
	var eye_glow = Color(1.0, 0.3, 0.2, 0.6)
	var light = Color(0.15, 0.7, 0.9)
	var thruster = Color(0.3, 0.6, 0.95, 0.7)

	# Main body (oval/disc shape, hovering)
	_fill(img, 8, 10, 16, 8, body)
	_fill(img, 6, 12, 20, 4, body)
	_fill(img, 10, 8, 12, 2, body)
	_fill(img, 10, 18, 12, 2, body)

	# Top dome
	_fill(img, 11, 6, 10, 3, body_light)
	_fill(img, 13, 4, 6, 3, body_light)
	_fill(img, 14, 3, 4, 2, body_light)

	# Central red eye (large)
	_fill(img, 13, 12, 6, 4, Color(0.12, 0.05, 0.05))
	_fill(img, 14, 13, 4, 2, eye)
	_px(img, 15, 13, Color(1.0, 0.4, 0.3))
	_px(img, 16, 13, Color(1.0, 0.4, 0.3))
	# Eye glow
	_px(img, 12, 13, eye_glow)
	_px(img, 19, 13, eye_glow)
	_px(img, 12, 15, eye_glow)
	_px(img, 19, 15, eye_glow)

	# Side panels
	_fill(img, 5, 12, 3, 4, body_dark)
	_fill(img, 24, 12, 3, 4, body_dark)
	# Panel lights
	_px(img, 6, 13, light)
	_px(img, 25, 13, light)

	# Bottom thrusters (glow)
	_fill(img, 11, 20, 4, 2, thruster)
	_fill(img, 17, 20, 4, 2, thruster)
	_fill(img, 12, 22, 2, 2, Color(0.2, 0.5, 0.85, 0.5))
	_fill(img, 18, 22, 2, 2, Color(0.2, 0.5, 0.85, 0.5))
	_px(img, 12, 24, Color(0.15, 0.4, 0.7, 0.3))
	_px(img, 19, 24, Color(0.15, 0.4, 0.7, 0.3))

	# Antenna
	_line_v(img, 16, 0, 4, body_dark)
	_px(img, 16, 0, eye)

	# Panel seam lines
	_line_h(img, 8, 11, 16, body_dark)
	_line_h(img, 8, 17, 16, body_dark)

	_outline(img, Color(0.12, 0.12, 0.18))
	_save(img, "res://assets/sprites/enemies/space/space_sentinel.png")

# ==================== CASTLE ====================

func _gen_castle_ghost_maid() -> void:
	var img = _img()
	var body = Color(0.85, 0.88, 0.92, 0.6)
	var body_bright = Color(0.92, 0.94, 0.97, 0.7)
	var apron = Color(0.95, 0.95, 0.97, 0.8)
	var dress = Color(0.2, 0.2, 0.25, 0.7)
	var hair = Color(0.25, 0.22, 0.3, 0.8)
	var eye = Color(0.4, 0.7, 0.9)
	var headband = Color(0.9, 0.9, 0.95, 0.8)

	# Hair
	_fill(img, 11, 3, 10, 3, hair)
	_fill(img, 10, 4, 12, 5, hair)
	_fill(img, 9, 7, 3, 6, hair)
	_fill(img, 20, 7, 3, 6, hair)

	# Head (ghostly white)
	_fill(img, 12, 4, 8, 7, body_bright)
	_fill(img, 11, 5, 10, 5, body_bright)

	# Maid headband with bow
	_fill(img, 11, 3, 10, 1, headband)
	_fill(img, 12, 2, 3, 2, headband)
	_fill(img, 17, 2, 3, 2, headband)
	_px(img, 13, 1, headband)
	_px(img, 18, 1, headband)

	# Eyes (hollow, glowing blue)
	_fill(img, 13, 6, 2, 2, eye)
	_fill(img, 18, 6, 2, 2, eye)
	_px(img, 13, 7, Color(0.2, 0.5, 0.8))
	_px(img, 19, 7, Color(0.2, 0.5, 0.8))

	# Small mouth
	_px(img, 15, 9, Color(0.5, 0.5, 0.6, 0.5))
	_px(img, 16, 9, Color(0.5, 0.5, 0.6, 0.5))

	# Maid dress (dark with white apron)
	_fill(img, 10, 12, 12, 6, dress)
	_fill(img, 9, 14, 14, 3, dress)
	# Apron
	_fill(img, 12, 12, 8, 6, apron)
	_fill(img, 13, 11, 6, 1, apron)
	# Apron strings
	_px(img, 11, 14, apron)
	_px(img, 20, 14, apron)

	# Arms (holding tray/duster)
	_fill(img, 6, 13, 4, 3, body)
	_fill(img, 22, 13, 4, 3, body)

	# Ghost tail (no legs, fading)
	_fill(img, 10, 18, 12, 3, dress)
	_fill(img, 9, 20, 14, 2, body)
	_fill(img, 8, 22, 5, 2, body)
	_fill(img, 18, 22, 5, 2, body)
	_px(img, 7, 24, Color(0.8, 0.85, 0.9, 0.3))
	_px(img, 11, 24, Color(0.8, 0.85, 0.9, 0.3))
	_px(img, 20, 24, Color(0.8, 0.85, 0.9, 0.3))
	_px(img, 24, 24, Color(0.8, 0.85, 0.9, 0.3))

	# Feather duster in right hand
	_fill(img, 25, 10, 3, 4, Color(0.6, 0.5, 0.3))
	_fill(img, 24, 8, 5, 3, Color(0.75, 0.7, 0.55))
	_px(img, 26, 7, Color(0.8, 0.75, 0.6))

	_outline(img, Color(0.3, 0.32, 0.4, 0.5))
	_save(img, "res://assets/sprites/enemies/castle/castle_ghost_maid.png")

func _gen_castle_rat_king() -> void:
	var img = _img()
	var body = Color(0.48, 0.42, 0.38)
	var body_dark = Color(0.35, 0.3, 0.26)
	var belly = Color(0.62, 0.58, 0.52)
	var eye = Color(0.9, 0.15, 0.1)
	var ear = Color(0.7, 0.52, 0.5)
	var crown = Color(0.9, 0.78, 0.15)
	var crown_dark = Color(0.7, 0.6, 0.1)
	var gem = Color(0.85, 0.15, 0.15)
	var tail = Color(0.65, 0.5, 0.48)
	var teeth = Color(0.92, 0.88, 0.75)
	var cape = Color(0.55, 0.12, 0.15)

	# Crown
	_fill(img, 10, 1, 12, 3, crown)
	_fill(img, 11, 0, 2, 2, crown)
	_fill(img, 15, 0, 2, 2, crown)
	_fill(img, 19, 0, 2, 2, crown)
	_px(img, 11, 0, crown_dark)
	_px(img, 15, 0, crown_dark)
	_px(img, 19, 0, crown_dark)
	# Gems
	_px(img, 13, 2, gem)
	_px(img, 16, 1, gem)
	_px(img, 19, 2, gem)

	# Ears (large)
	_fill(img, 7, 3, 4, 4, ear)
	_fill(img, 8, 4, 2, 2, Color(0.8, 0.6, 0.58))
	_fill(img, 21, 3, 4, 4, ear)
	_fill(img, 22, 4, 2, 2, Color(0.8, 0.6, 0.58))

	# Head (large rat)
	_fill(img, 10, 4, 12, 8, body)
	_fill(img, 9, 5, 14, 6, body)

	# Eyes (red, glowing)
	_fill(img, 12, 6, 3, 2, eye)
	_fill(img, 18, 6, 3, 2, eye)
	_px(img, 13, 6, Color(1.0, 0.3, 0.2))
	_px(img, 19, 6, Color(1.0, 0.3, 0.2))

	# Snout
	_fill(img, 13, 9, 6, 3, body)
	_px(img, 15, 9, Color(0.3, 0.18, 0.15))
	_px(img, 16, 9, Color(0.3, 0.18, 0.15))
	# Buck teeth
	_px(img, 15, 11, teeth)
	_px(img, 16, 11, teeth)
	_px(img, 15, 12, teeth)
	_px(img, 16, 12, teeth)
	# Whiskers
	_px(img, 9, 9, body_dark)
	_px(img, 8, 10, body_dark)
	_px(img, 23, 9, body_dark)
	_px(img, 24, 10, body_dark)

	# Royal cape
	_fill(img, 7, 12, 18, 3, cape)
	_fill(img, 6, 14, 20, 5, cape)
	_fill(img, 8, 19, 16, 3, cape)

	# Body (under cape)
	_fill(img, 10, 13, 12, 6, body)
	_fill(img, 12, 15, 8, 3, belly)

	# Arms
	_fill(img, 6, 13, 4, 5, body)
	_fill(img, 22, 13, 4, 5, body)

	# Legs
	_fill(img, 11, 20, 4, 5, body_dark)
	_fill(img, 17, 20, 4, 5, body_dark)
	# Paws
	_fill(img, 10, 25, 5, 2, body_dark)
	_fill(img, 17, 25, 5, 2, body_dark)

	# Tail (thick, curling)
	_px(img, 25, 18, tail)
	_px(img, 26, 17, tail)
	_px(img, 27, 16, tail)
	_px(img, 28, 16, tail)
	_px(img, 29, 17, tail)
	_px(img, 29, 18, tail)

	_outline(img, Color(0.15, 0.12, 0.1))
	_save(img, "res://assets/sprites/enemies/castle/castle_rat_king.png")

func _gen_castle_skeleton_mage() -> void:
	var img = _img()
	var bone = Color(0.9, 0.88, 0.8)
	var bone_dark = Color(0.7, 0.68, 0.6)
	var robe = Color(0.25, 0.12, 0.4)
	var robe_dark = Color(0.15, 0.06, 0.28)
	var eye = Color(0.6, 0.15, 0.9)
	var magic = Color(0.7, 0.3, 1.0, 0.7)
	var magic_bright = Color(0.85, 0.5, 1.0, 0.9)
	var staff = Color(0.45, 0.3, 0.2)

	# Hood
	_fill(img, 10, 2, 12, 4, robe)
	_fill(img, 9, 4, 14, 4, robe)
	_fill(img, 8, 6, 16, 3, robe)
	# Hood shadow
	_fill(img, 11, 4, 10, 2, robe_dark)

	# Skull face (visible in hood)
	_fill(img, 12, 5, 8, 5, bone)
	_fill(img, 11, 6, 10, 3, bone)
	# Eye sockets
	_fill(img, 13, 6, 2, 2, Color(0.08, 0.04, 0.12))
	_px(img, 13, 6, eye)
	_fill(img, 18, 6, 2, 2, Color(0.08, 0.04, 0.12))
	_px(img, 19, 6, eye)
	# Nose
	_px(img, 16, 8, bone_dark)
	# Jaw
	_fill(img, 13, 9, 6, 1, bone_dark)
	_px(img, 14, 9, bone)
	_px(img, 16, 9, bone)
	_px(img, 18, 9, bone)

	# Robe body
	_fill(img, 9, 10, 14, 10, robe)
	_fill(img, 8, 12, 16, 6, robe)
	_fill(img, 9, 20, 14, 4, robe)
	_fill(img, 10, 24, 12, 3, robe)
	_fill(img, 11, 27, 10, 2, robe_dark)
	# Robe trim
	_fill(img, 11, 26, 10, 1, Color(0.4, 0.2, 0.55))

	# Bony arms
	_fill(img, 5, 12, 4, 2, robe)
	_fill(img, 3, 14, 4, 5, bone)
	_fill(img, 23, 12, 4, 2, robe)
	_fill(img, 25, 14, 4, 5, bone)
	# Bony hands
	_px(img, 2, 18, bone_dark)
	_px(img, 3, 19, bone)
	_px(img, 4, 18, bone_dark)
	_px(img, 26, 18, bone_dark)
	_px(img, 27, 19, bone)
	_px(img, 28, 18, bone_dark)

	# Staff (left hand)
	_line_v(img, 1, 4, 22, staff)
	_line_v(img, 2, 4, 22, staff)
	# Orb on top
	_circle(img, 1, 3, 2, magic)
	_px(img, 1, 3, magic_bright)

	# Casting spell (right hand) - magic particles
	_px(img, 28, 14, magic_bright)
	_px(img, 29, 13, magic)
	_px(img, 30, 14, magic)
	_px(img, 29, 16, magic_bright)
	_px(img, 30, 15, magic)
	_px(img, 27, 12, magic)

	_outline(img, Color(0.08, 0.04, 0.15))
	_save(img, "res://assets/sprites/enemies/castle/castle_skeleton_mage.png")

func _gen_castle_bat_swarm() -> void:
	var img = _img()
	var body = Color(0.2, 0.15, 0.18)
	var wing = Color(0.3, 0.22, 0.28)
	var wing_dark = Color(0.15, 0.1, 0.13)
	var eye = Color(0.9, 0.2, 0.15)

	# Bat 1 (center, largest)
	_fill(img, 14, 12, 4, 3, body)
	_fill(img, 10, 11, 5, 3, wing)
	_fill(img, 7, 12, 4, 2, wing)
	_fill(img, 5, 13, 3, 1, wing_dark)
	_fill(img, 18, 11, 5, 3, wing)
	_fill(img, 22, 12, 4, 2, wing)
	_fill(img, 25, 13, 3, 1, wing_dark)
	_px(img, 15, 12, eye)
	_px(img, 17, 12, eye)

	# Bat 2 (top-left)
	_fill(img, 5, 4, 3, 2, body)
	_fill(img, 2, 4, 4, 2, wing)
	_fill(img, 0, 5, 3, 1, wing_dark)
	_fill(img, 8, 4, 3, 2, wing)
	_fill(img, 10, 5, 2, 1, wing_dark)
	_px(img, 5, 4, eye)
	_px(img, 7, 4, eye)

	# Bat 3 (top-right)
	_fill(img, 22, 3, 3, 2, body)
	_fill(img, 19, 3, 4, 2, wing)
	_fill(img, 17, 4, 3, 1, wing_dark)
	_fill(img, 25, 3, 3, 2, wing)
	_fill(img, 27, 4, 3, 1, wing_dark)
	_px(img, 23, 3, eye)
	_px(img, 24, 3, eye)

	# Bat 4 (bottom-left)
	_fill(img, 3, 20, 3, 2, body)
	_fill(img, 0, 20, 4, 2, wing)
	_fill(img, 6, 20, 3, 2, wing)
	_fill(img, 8, 21, 2, 1, wing_dark)
	_px(img, 4, 20, eye)
	_px(img, 5, 20, eye)

	# Bat 5 (bottom-right)
	_fill(img, 23, 20, 3, 2, body)
	_fill(img, 20, 20, 4, 2, wing)
	_fill(img, 26, 20, 3, 2, wing)
	_fill(img, 28, 21, 2, 1, wing_dark)
	_px(img, 24, 20, eye)
	_px(img, 25, 20, eye)

	# Bat 6 (middle-left, small)
	_fill(img, 1, 14, 2, 2, body)
	_fill(img, 0, 14, 2, 1, wing)
	_fill(img, 3, 14, 2, 1, wing)
	_px(img, 1, 14, eye)

	# Bat 7 (middle-right, small)
	_fill(img, 28, 8, 2, 2, body)
	_fill(img, 27, 8, 2, 1, wing)
	_fill(img, 30, 8, 1, 1, wing)
	_px(img, 29, 8, eye)

	_outline(img, Color(0.06, 0.04, 0.06))
	_save(img, "res://assets/sprites/enemies/castle/castle_bat_swarm.png")

func _gen_castle_cursed_armor() -> void:
	var img = _img()
	var armor = Color(0.45, 0.42, 0.5)
	var armor_light = Color(0.58, 0.55, 0.65)
	var armor_dark = Color(0.3, 0.28, 0.35)
	var glow = Color(0.5, 0.15, 0.8, 0.6)
	var glow_bright = Color(0.7, 0.3, 1.0, 0.8)
	var visor = Color(0.08, 0.04, 0.12)
	var eye = Color(0.6, 0.15, 0.9)

	# Helmet (floating, slight tilt)
	_fill(img, 11, 2, 10, 7, armor)
	_fill(img, 10, 3, 12, 5, armor)
	_fill(img, 12, 1, 8, 2, armor_light)
	# Visor
	_fill(img, 12, 4, 8, 3, visor)
	# Glowing eyes
	_fill(img, 13, 5, 2, 1, eye)
	_fill(img, 18, 5, 2, 1, eye)
	# Plume
	_fill(img, 15, 0, 2, 2, armor_dark)

	# Gap between helmet and body (floating, dark energy)
	_px(img, 14, 9, glow)
	_px(img, 16, 9, glow)
	_px(img, 18, 9, glow)

	# Chest plate (floating)
	_fill(img, 9, 10, 14, 8, armor)
	_fill(img, 8, 12, 16, 4, armor)
	# Chest details
	_fill(img, 12, 12, 8, 4, armor_light)
	_line_v(img, 16, 10, 8, armor_dark)
	_line_h(img, 10, 14, 12, armor_dark)
	# Cursed glow from gaps
	_px(img, 9, 11, glow)
	_px(img, 22, 11, glow)
	_px(img, 9, 16, glow)
	_px(img, 22, 16, glow)

	# Shoulder pauldrons (floating, separate)
	_fill(img, 4, 10, 5, 4, armor)
	_fill(img, 5, 10, 3, 1, armor_light)
	_fill(img, 23, 10, 5, 4, armor)
	_fill(img, 24, 10, 3, 1, armor_light)

	# Gauntlets (floating)
	_fill(img, 3, 15, 5, 4, armor_dark)
	_fill(img, 4, 15, 3, 1, armor)
	_fill(img, 24, 15, 5, 4, armor_dark)
	_fill(img, 25, 15, 3, 1, armor)

	# Energy connecting pieces
	_px(img, 7, 13, glow_bright)
	_px(img, 24, 13, glow_bright)
	_px(img, 5, 14, glow)
	_px(img, 26, 14, glow)

	# Greaves (floating, below body)
	_fill(img, 10, 19, 4, 5, armor_dark)
	_fill(img, 18, 19, 4, 5, armor_dark)
	_fill(img, 10, 19, 4, 1, armor)
	_fill(img, 18, 19, 4, 1, armor)

	# Sabatons (floating)
	_fill(img, 9, 25, 5, 3, armor)
	_fill(img, 18, 25, 5, 3, armor)

	# Energy wisps between leg pieces
	_px(img, 12, 24, glow)
	_px(img, 19, 24, glow)

	# Central core glow (inside chest)
	_fill(img, 14, 13, 4, 2, glow_bright)
	_px(img, 15, 14, Color(0.9, 0.5, 1.0))
	_px(img, 16, 14, Color(0.9, 0.5, 1.0))

	# Floating particles
	_px(img, 2, 8, glow)
	_px(img, 28, 6, glow)
	_px(img, 6, 22, glow)
	_px(img, 26, 24, glow)

	_outline(img, Color(0.12, 0.1, 0.18))
	_save(img, "res://assets/sprites/enemies/castle/castle_cursed_armor.png")

# ==================== CANDY ====================

func _gen_candy_chocolate_golem() -> void:
	var img = _img()
	var choc = Color(0.35, 0.18, 0.08)
	var choc_light = Color(0.5, 0.3, 0.15)
	var choc_dark = Color(0.22, 0.1, 0.04)
	var drip = Color(0.4, 0.22, 0.1)
	var eye = Color(0.95, 0.85, 0.1)
	var mouth = Color(0.15, 0.06, 0.02)

	# Body (massive, hulking)
	_fill(img, 8, 10, 16, 12, choc)
	_fill(img, 7, 12, 18, 8, choc)
	_fill(img, 9, 22, 14, 2, choc)

	# Head
	_fill(img, 10, 3, 12, 8, choc)
	_fill(img, 9, 5, 14, 4, choc)
	# Melted chocolate dripping from head
	_fill(img, 10, 2, 12, 2, choc_light)
	_px(img, 9, 3, choc_light)
	_px(img, 22, 3, choc_light)
	# Drips
	_line_v(img, 9, 9, 3, drip)
	_line_v(img, 22, 8, 4, drip)
	_line_v(img, 13, 10, 2, drip)

	# Eyes (candy-like, yellow)
	_fill(img, 12, 5, 3, 3, eye)
	_fill(img, 18, 5, 3, 3, eye)
	_px(img, 13, 6, Color(0.1, 0.05, 0.02))
	_px(img, 19, 6, Color(0.1, 0.05, 0.02))

	# Angry mouth
	_fill(img, 13, 9, 6, 2, mouth)
	_px(img, 14, 9, choc_light)
	_px(img, 16, 9, choc_light)
	_px(img, 18, 9, choc_light)

	# Arms (thick)
	_fill(img, 3, 11, 5, 10, choc)
	_fill(img, 2, 13, 6, 6, choc)
	_fill(img, 24, 11, 5, 10, choc)
	_fill(img, 24, 13, 6, 6, choc)
	# Fists
	_fill(img, 2, 20, 6, 4, choc_dark)
	_fill(img, 24, 20, 6, 4, choc_dark)

	# Drip details on body
	_line_v(img, 10, 20, 3, drip)
	_line_v(img, 21, 18, 4, drip)
	_line_v(img, 15, 22, 2, drip)

	# Legs
	_fill(img, 9, 23, 5, 5, choc_dark)
	_fill(img, 18, 23, 5, 5, choc_dark)
	# Feet
	_fill(img, 8, 27, 6, 2, choc)
	_fill(img, 17, 27, 7, 2, choc)

	# Highlight (chocolate sheen)
	_fill(img, 12, 13, 3, 2, choc_light)
	_fill(img, 4, 14, 2, 2, choc_light)

	_outline(img, Color(0.1, 0.04, 0.01))
	_save(img, "res://assets/sprites/enemies/candy/candy_chocolate_golem.png")

func _gen_candy_ice_cream_cone() -> void:
	var img = _img()
	var scoop1 = Color(0.95, 0.75, 0.8)  # strawberry
	var scoop2 = Color(0.7, 0.5, 0.3)     # chocolate
	var scoop3 = Color(0.92, 0.92, 0.75)  # vanilla
	var cone = Color(0.82, 0.65, 0.35)
	var cone_dark = Color(0.65, 0.5, 0.25)
	var eye = Color(0.1, 0.1, 0.1)
	var mouth = Color(0.5, 0.15, 0.15)
	var sprinkle = Color(0.9, 0.2, 0.3)

	# Cone (bottom, walking)
	_fill(img, 12, 18, 8, 4, cone)
	_fill(img, 13, 22, 6, 3, cone)
	_fill(img, 14, 25, 4, 3, cone)
	_fill(img, 15, 28, 2, 1, cone_dark)
	# Waffle pattern
	for y in range(18, 26):
		for x in range(12, 20):
			if (x + y) % 3 == 0:
				_px(img, x, y, cone_dark)

	# Legs (sticking out from cone bottom)
	_fill(img, 10, 26, 4, 3, cone)
	_fill(img, 18, 26, 4, 3, cone)
	# Shoes
	_fill(img, 9, 28, 5, 2, Color(0.5, 0.3, 0.15))
	_fill(img, 18, 28, 5, 2, Color(0.5, 0.3, 0.15))

	# Scoop 1 (bottom - chocolate)
	_circle(img, 16, 15, 5, scoop2)

	# Scoop 2 (middle - vanilla)
	_circle(img, 14, 10, 5, scoop3)

	# Scoop 3 (top - strawberry, with face)
	_circle(img, 16, 5, 5, scoop1)
	_fill(img, 15, 3, 4, 2, Color(0.98, 0.8, 0.85))

	# Face on top scoop
	# Eyes (angry)
	_px(img, 14, 4, eye)
	_px(img, 18, 4, eye)
	# Angry brows
	_px(img, 13, 3, eye)
	_px(img, 14, 3, eye)
	_px(img, 18, 3, eye)
	_px(img, 19, 3, eye)
	# Mouth
	_fill(img, 15, 7, 3, 1, mouth)
	_px(img, 14, 6, mouth)
	_px(img, 18, 6, mouth)

	# Sprinkles on scoops
	_px(img, 13, 5, sprinkle)
	_px(img, 19, 6, Color(0.2, 0.7, 0.3))
	_px(img, 12, 10, Color(0.9, 0.85, 0.2))
	_px(img, 17, 9, sprinkle)
	_px(img, 14, 14, Color(0.3, 0.5, 0.9))
	_px(img, 19, 15, Color(0.9, 0.85, 0.2))

	# Arms (small, from sides)
	_fill(img, 7, 14, 4, 2, scoop2)
	_fill(img, 21, 14, 4, 2, scoop2)

	_outline(img, Color(0.3, 0.2, 0.12))
	_save(img, "res://assets/sprites/enemies/candy/candy_ice_cream_cone.png")

func _gen_candy_cotton_candy_ghost() -> void:
	var img = _img()
	var body = Color(0.95, 0.65, 0.85, 0.7)
	var body_light = Color(0.98, 0.8, 0.92, 0.8)
	var body_bright = Color(1.0, 0.9, 0.95, 0.9)
	var body_dark = Color(0.85, 0.5, 0.72, 0.6)
	var eye = Color(0.15, 0.1, 0.12)
	var blush = Color(0.95, 0.55, 0.65, 0.5)

	# Fluffy body (irregular, cloud-like)
	_circle(img, 16, 14, 10, body)
	_circle(img, 12, 12, 7, body)
	_circle(img, 20, 12, 7, body)
	_circle(img, 16, 10, 6, body_light)
	_circle(img, 14, 16, 6, body)
	_circle(img, 18, 16, 6, body)

	# Extra fluffy bumps
	_circle(img, 10, 10, 4, body)
	_circle(img, 22, 10, 4, body)
	_circle(img, 8, 14, 4, body_dark)
	_circle(img, 24, 14, 4, body_dark)

	# Top poof
	_circle(img, 14, 6, 4, body_light)
	_circle(img, 18, 6, 4, body_light)
	_circle(img, 16, 4, 3, body_bright)

	# Face
	# Eyes (small, cute but menacing)
	_fill(img, 12, 12, 3, 3, eye)
	_fill(img, 18, 12, 3, 3, eye)
	# Eye highlights
	_px(img, 13, 12, Color(0.95, 0.95, 0.95))
	_px(img, 19, 12, Color(0.95, 0.95, 0.95))

	# Blush
	_fill(img, 10, 15, 3, 1, blush)
	_fill(img, 20, 15, 3, 1, blush)

	# Smile (creepy)
	_fill(img, 14, 16, 5, 1, eye)
	_px(img, 13, 15, eye)
	_px(img, 19, 15, eye)

	# Wispy ghost tail
	_fill(img, 12, 20, 8, 2, body)
	_fill(img, 10, 22, 5, 2, body_dark)
	_fill(img, 17, 22, 5, 2, body_dark)
	_px(img, 9, 24, body_dark)
	_px(img, 13, 24, body_dark)
	_px(img, 18, 24, body_dark)
	_px(img, 22, 24, body_dark)

	# Sugar sparkles
	_px(img, 8, 6, body_bright)
	_px(img, 24, 7, body_bright)
	_px(img, 6, 16, body_bright)
	_px(img, 26, 15, body_bright)
	_px(img, 16, 2, body_bright)

	_outline(img, Color(0.4, 0.25, 0.35))
	_save(img, "res://assets/sprites/enemies/candy/candy_cotton_candy_ghost.png")

func _gen_candy_cake_mimic() -> void:
	var img = _img()
	var cake = Color(0.9, 0.75, 0.55)
	var cake_dark = Color(0.75, 0.6, 0.4)
	var frosting = Color(0.95, 0.4, 0.5)
	var frosting_light = Color(0.98, 0.6, 0.65)
	var cream = Color(0.95, 0.92, 0.85)
	var eye = Color(0.95, 0.85, 0.1)
	var pupil = Color(0.15, 0.08, 0.08)
	var teeth = Color(0.95, 0.95, 0.95)
	var mouth_inside = Color(0.4, 0.12, 0.12)
	var cherry = Color(0.85, 0.12, 0.15)

	# Bottom cake layer
	_fill(img, 6, 18, 20, 6, cake)
	_fill(img, 5, 20, 22, 3, cake)
	_fill(img, 7, 24, 18, 3, cake)
	# Cream layer
	_fill(img, 6, 18, 20, 1, cream)

	# Top cake layer (tilted open like a mouth)
	_fill(img, 5, 8, 22, 5, cake)
	_fill(img, 6, 6, 20, 3, cake)
	_fill(img, 8, 5, 16, 2, cake)
	# Frosting on top
	_fill(img, 6, 6, 20, 2, frosting)
	_fill(img, 8, 5, 16, 2, frosting)
	_fill(img, 10, 4, 12, 2, frosting_light)
	# Frosting drips
	_px(img, 7, 8, frosting)
	_px(img, 12, 8, frosting)
	_px(img, 18, 8, frosting)
	_px(img, 24, 8, frosting)

	# Cherry on top
	_fill(img, 15, 2, 3, 3, cherry)
	_fill(img, 14, 3, 5, 1, cherry)
	_px(img, 16, 1, Color(0.3, 0.5, 0.15))  # stem

	# Mouth (gap between layers - the mimic opening)
	_fill(img, 7, 13, 18, 5, mouth_inside)
	_fill(img, 8, 12, 16, 1, mouth_inside)

	# Teeth (top row, hanging from upper layer)
	_px(img, 9, 13, teeth)
	_px(img, 12, 13, teeth)
	_px(img, 15, 13, teeth)
	_px(img, 18, 13, teeth)
	_px(img, 21, 13, teeth)
	_px(img, 10, 14, teeth)
	_px(img, 13, 14, teeth)
	_px(img, 16, 14, teeth)
	_px(img, 19, 14, teeth)
	_px(img, 22, 14, teeth)

	# Teeth (bottom row, from lower layer)
	_px(img, 10, 17, teeth)
	_px(img, 13, 17, teeth)
	_px(img, 16, 17, teeth)
	_px(img, 19, 17, teeth)
	_px(img, 22, 17, teeth)

	# Eyes (on front of upper cake, malicious)
	_fill(img, 10, 9, 3, 3, eye)
	_fill(img, 19, 9, 3, 3, eye)
	_px(img, 11, 10, pupil)
	_px(img, 20, 10, pupil)

	# Tongue
	_fill(img, 14, 15, 4, 2, Color(0.85, 0.35, 0.4))
	_px(img, 15, 16, Color(0.75, 0.25, 0.3))

	# Cake crumbs
	_px(img, 4, 22, cake_dark)
	_px(img, 27, 20, cake_dark)
	_px(img, 3, 18, cake_dark)

	_outline(img, Color(0.3, 0.2, 0.12))
	_save(img, "res://assets/sprites/enemies/candy/candy_cake_mimic.png")

func _gen_candy_sour_worm() -> void:
	var img = _img()
	var seg1 = Color(0.2, 0.85, 0.3)   # green
	var seg2 = Color(0.95, 0.85, 0.15)  # yellow
	var seg3 = Color(0.95, 0.35, 0.2)   # red/orange
	var seg4 = Color(0.3, 0.5, 0.95)    # blue
	var seg5 = Color(0.9, 0.3, 0.8)     # pink/purple
	var eye = Color(0.1, 0.1, 0.1)
	var sugar = Color(0.95, 0.95, 0.95, 0.6)

	# Worm body S-curve (colorful segments)
	# Head segment (green, top-left)
	_fill(img, 5, 3, 7, 5, seg1)
	_fill(img, 4, 4, 9, 3, seg1)

	# Face on head
	_fill(img, 6, 4, 2, 2, Color(0.95, 0.95, 0.95))
	_fill(img, 10, 4, 2, 2, Color(0.95, 0.95, 0.95))
	_px(img, 7, 5, eye)
	_px(img, 11, 5, eye)
	# Mouth
	_fill(img, 7, 7, 4, 1, Color(0.5, 0.2, 0.15))
	_px(img, 8, 7, Color(0.9, 0.9, 0.85))
	_px(img, 10, 7, Color(0.9, 0.9, 0.85))

	# Segment 2 (yellow) - curves right
	_fill(img, 10, 7, 6, 4, seg2)
	_fill(img, 14, 9, 5, 4, seg2)

	# Segment 3 (red) - curves down
	_fill(img, 17, 11, 5, 5, seg3)
	_fill(img, 16, 14, 5, 4, seg3)

	# Segment 4 (blue) - curves left
	_fill(img, 13, 16, 5, 4, seg4)
	_fill(img, 10, 18, 5, 4, seg4)

	# Segment 5 (pink) - curves down (tail)
	_fill(img, 8, 21, 5, 4, seg5)
	_fill(img, 10, 24, 4, 3, seg5)
	_fill(img, 12, 26, 3, 2, seg5)
	_px(img, 14, 27, seg5)

	# Sugar coating (sparkly dots)
	_px(img, 6, 3, sugar)
	_px(img, 9, 5, sugar)
	_px(img, 12, 8, sugar)
	_px(img, 16, 10, sugar)
	_px(img, 19, 12, sugar)
	_px(img, 18, 15, sugar)
	_px(img, 14, 17, sugar)
	_px(img, 11, 19, sugar)
	_px(img, 9, 22, sugar)
	_px(img, 12, 25, sugar)

	# Segment divider lines
	_line_v(img, 10, 6, 2, Color(0.15, 0.6, 0.2))
	_px(img, 14, 9, Color(0.7, 0.6, 0.1))
	_px(img, 17, 12, Color(0.7, 0.2, 0.15))
	_px(img, 14, 16, Color(0.2, 0.35, 0.7))
	_px(img, 10, 21, Color(0.65, 0.2, 0.6))

	_outline(img, Color(0.15, 0.3, 0.1))
	_save(img, "res://assets/sprites/enemies/candy/candy_sour_worm.png")
