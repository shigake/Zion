extends SceneTree

## Generates 16x16 pixel art sprites for all 33 weapons and 4 pickups.
## Run: godot --headless --script res://scripts/tools/weapon_sprite_generator.gd

const S := 16  # Sprite size

func _init() -> void:
	_generate_all()
	quit()

func _generate_all() -> void:
	DirAccess.make_dir_recursive_absolute("res://assets/sprites/weapons")
	DirAccess.make_dir_recursive_absolute("res://assets/sprites/pickups")

	# Melee (12)
	_gen_katana()
	_gen_scythe()
	_gen_axe()
	_gen_whip()
	_gen_lance()
	_gen_hammer()
	_gen_nunchaku()
	_gen_dual_katana()
	_gen_cloud_sword()
	_gen_boxing_gloves()
	_gen_shadow_claw()
	_gen_chain_whip()

	# Ranged (11)
	_gen_machinegun()
	_gen_staff()
	_gen_bazooka()
	_gen_shuriken()
	_gen_dual_pistol()
	_gen_flamethrower()
	_gen_ice_staff()
	_gen_crossbow()
	_gen_plasma_cannon()
	_gen_elven_bow()
	_gen_boomerang()

	# Summon/Special (10)
	_gen_necro()
	_gen_drone()
	_gen_totem()
	_gen_poison_bottle()
	_gen_lightning_chain()
	_gen_magic_book()
	_gen_time_bomb()
	_gen_portal_weapon()
	_gen_tornado()
	_gen_blood_orb()

	# Pickups (4)
	_gen_xp_gem()
	_gen_crystal()
	_gen_health_pickup()
	_gen_magnet_pickup()

	print("All 33 weapon and 4 pickup sprites generated!")

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

# ==================== MELEE (12) ====================

func _gen_katana() -> void:
	var img = _img()
	var blade = Color(0.82, 0.85, 0.9)
	var edge = Color(0.95, 0.97, 1.0)
	var handle = Color(0.6, 0.12, 0.12)
	var guard = Color(0.75, 0.7, 0.2)

	# Blade diagonal from top-right to center
	for i in range(9):
		_px(img, 12 - i, 1 + i, blade)
		_px(img, 13 - i, 1 + i, edge)
	# Guard
	_fill(img, 3, 9, 4, 1, guard)
	_fill(img, 4, 10, 2, 1, guard)
	# Handle
	for i in range(4):
		_px(img, 3 - i, 11 + i, handle)
		_px(img, 4 - i, 11 + i, handle)
	# Wrap marks on handle
	_px(img, 3, 12, Color(0.4, 0.08, 0.08))
	_px(img, 1, 14, Color(0.4, 0.08, 0.08))

	_outline(img, Color(0.1, 0.1, 0.12))
	_save(img, "res://assets/sprites/weapons/katana.png")

func _gen_scythe() -> void:
	var img = _img()
	var blade = Color(0.6, 0.3, 0.7)
	var blade_edge = Color(0.8, 0.5, 0.9)
	var handle = Color(0.5, 0.35, 0.2)

	# Handle (vertical shaft)
	_fill(img, 7, 4, 2, 11, handle)
	# Blade (curved top)
	_fill(img, 8, 1, 5, 2, blade)
	_fill(img, 11, 3, 3, 1, blade)
	_fill(img, 12, 4, 2, 1, blade)
	_fill(img, 13, 5, 1, 1, blade)
	# Edge highlight
	_fill(img, 8, 1, 5, 1, blade_edge)
	_px(img, 13, 3, blade_edge)

	_outline(img, Color(0.15, 0.08, 0.18))
	_save(img, "res://assets/sprites/weapons/scythe.png")

func _gen_axe() -> void:
	var img = _img()
	var blade = Color(0.6, 0.62, 0.65)
	var blade_hi = Color(0.78, 0.8, 0.85)
	var handle = Color(0.5, 0.35, 0.2)

	# Handle
	_fill(img, 7, 5, 2, 10, handle)
	# Axe head (left side)
	_fill(img, 2, 1, 5, 2, blade)
	_fill(img, 3, 3, 5, 2, blade)
	_fill(img, 5, 5, 3, 1, blade)
	# Highlight
	_fill(img, 2, 1, 3, 1, blade_hi)
	_px(img, 3, 2, blade_hi)
	# Right side mirror
	_fill(img, 9, 1, 5, 2, blade)
	_fill(img, 9, 3, 5, 2, blade)
	_fill(img, 9, 5, 2, 1, blade)
	_fill(img, 11, 1, 3, 1, blade_hi)

	_outline(img, Color(0.1, 0.1, 0.1))
	_save(img, "res://assets/sprites/weapons/axe.png")

func _gen_whip() -> void:
	var img = _img()
	var leather = Color(0.55, 0.35, 0.18)
	var leather_hi = Color(0.7, 0.48, 0.25)
	var handle = Color(0.4, 0.22, 0.1)

	# Handle (bottom left)
	_fill(img, 1, 12, 3, 3, handle)
	_fill(img, 2, 11, 2, 1, handle)
	# Whip coil curving up and right
	_px(img, 3, 10, leather)
	_px(img, 4, 9, leather)
	_px(img, 5, 8, leather)
	_px(img, 5, 7, leather)
	_px(img, 6, 6, leather)
	_px(img, 7, 5, leather)
	_px(img, 8, 5, leather)
	_px(img, 9, 4, leather)
	_px(img, 10, 3, leather)
	_px(img, 11, 3, leather)
	_px(img, 12, 2, leather)
	_px(img, 13, 1, leather)
	_px(img, 14, 1, leather)
	# Highlight on curve
	_px(img, 6, 6, leather_hi)
	_px(img, 9, 4, leather_hi)
	_px(img, 12, 2, leather_hi)
	# Tip crack
	_px(img, 14, 0, Color(0.8, 0.6, 0.3))

	_outline(img, Color(0.15, 0.1, 0.05))
	_save(img, "res://assets/sprites/weapons/whip.png")

func _gen_lance() -> void:
	var img = _img()
	var tip = Color(0.85, 0.75, 0.2)
	var tip_hi = Color(1.0, 0.9, 0.4)
	var shaft = Color(0.55, 0.4, 0.25)
	var shaft_dk = Color(0.4, 0.28, 0.15)

	# Tip (top, pointed)
	_px(img, 7, 0, tip_hi)
	_px(img, 8, 0, tip_hi)
	_fill(img, 6, 1, 4, 1, tip)
	_fill(img, 6, 2, 4, 1, tip)
	_fill(img, 7, 3, 2, 1, tip)
	# Guard wings
	_fill(img, 4, 4, 8, 1, Color(0.7, 0.6, 0.15))
	# Shaft
	_fill(img, 7, 5, 2, 10, shaft)
	# Shaft detail
	_px(img, 7, 7, shaft_dk)
	_px(img, 7, 9, shaft_dk)
	_px(img, 7, 11, shaft_dk)
	_px(img, 7, 13, shaft_dk)

	_outline(img, Color(0.12, 0.1, 0.05))
	_save(img, "res://assets/sprites/weapons/lance.png")

func _gen_hammer() -> void:
	var img = _img()
	var head = Color(0.6, 0.62, 0.65)
	var head_hi = Color(0.8, 0.82, 0.88)
	var handle = Color(0.5, 0.35, 0.2)

	# Handle
	_fill(img, 7, 7, 2, 8, handle)
	# Hammer head (wide rectangle on top)
	_fill(img, 2, 2, 12, 5, head)
	# Highlight on top
	_fill(img, 2, 2, 12, 1, head_hi)
	_fill(img, 2, 3, 2, 1, head_hi)
	# Face details
	_px(img, 3, 5, head.darkened(0.2))
	_px(img, 12, 5, head.darkened(0.2))

	_outline(img, Color(0.1, 0.1, 0.1))
	_save(img, "res://assets/sprites/weapons/hammer.png")

func _gen_nunchaku() -> void:
	var img = _img()
	var wood = Color(0.55, 0.35, 0.18)
	var wood_hi = Color(0.7, 0.48, 0.25)
	var chain = Color(0.7, 0.7, 0.72)

	# Left stick (angled)
	_fill(img, 3, 2, 2, 6, wood)
	_px(img, 3, 3, wood_hi)
	_px(img, 3, 4, wood_hi)
	# Right stick
	_fill(img, 10, 5, 2, 6, wood)
	_px(img, 10, 6, wood_hi)
	_px(img, 10, 7, wood_hi)
	# Chain connecting them
	_px(img, 5, 5, chain)
	_px(img, 6, 5, chain)
	_px(img, 7, 5, chain)
	_px(img, 8, 5, chain)
	_px(img, 9, 5, chain)
	# Chain sag
	_px(img, 6, 6, chain)
	_px(img, 7, 6, chain)
	_px(img, 8, 6, chain)
	# End caps
	_fill(img, 3, 1, 2, 1, Color(0.65, 0.6, 0.2))
	_fill(img, 10, 11, 2, 1, Color(0.65, 0.6, 0.2))

	_outline(img, Color(0.15, 0.1, 0.05))
	_save(img, "res://assets/sprites/weapons/nunchaku.png")

func _gen_dual_katana() -> void:
	var img = _img()
	var blade = Color(0.82, 0.85, 0.9)
	var edge = Color(0.95, 0.97, 1.0)
	var handle = Color(0.6, 0.12, 0.12)

	# Left blade (top-left to center)
	for i in range(8):
		_px(img, 2 + i, 1 + i, blade)
		_px(img, 3 + i, 1 + i, edge)
	# Left handle
	_px(img, 10, 9, handle)
	_px(img, 11, 10, handle)
	_px(img, 12, 11, handle)

	# Right blade (top-right to center, crossing)
	for i in range(8):
		_px(img, 13 - i, 1 + i, blade)
		_px(img, 12 - i, 1 + i, edge)
	# Right handle
	_px(img, 5, 9, handle)
	_px(img, 4, 10, handle)
	_px(img, 3, 11, handle)

	# Cross guard marks
	_px(img, 7, 7, Color(0.75, 0.7, 0.2))
	_px(img, 8, 8, Color(0.75, 0.7, 0.2))

	_outline(img, Color(0.1, 0.1, 0.12))
	_save(img, "res://assets/sprites/weapons/dual_katana.png")

func _gen_cloud_sword() -> void:
	var img = _img()
	var blade = Color(0.3, 0.5, 0.9)
	var glow = Color(0.5, 0.7, 1.0)
	var glow_hi = Color(0.7, 0.85, 1.0)
	var handle = Color(0.35, 0.3, 0.25)
	var guard = Color(0.75, 0.7, 0.2)

	# Big wide blade
	_fill(img, 5, 0, 6, 2, glow_hi)
	_fill(img, 4, 2, 8, 3, blade)
	_fill(img, 5, 5, 6, 2, blade)
	_fill(img, 6, 7, 4, 2, blade)
	# Glow effect
	_fill(img, 5, 1, 6, 1, glow)
	_fill(img, 4, 3, 1, 2, glow)
	_fill(img, 11, 3, 1, 2, glow)
	# Center line
	for y in range(0, 9):
		_px(img, 7, y, glow_hi)
		_px(img, 8, y, glow_hi)
	# Guard
	_fill(img, 4, 9, 8, 1, guard)
	# Handle
	_fill(img, 7, 10, 2, 4, handle)
	# Pommel
	_fill(img, 6, 14, 4, 1, guard)

	_outline(img, Color(0.1, 0.15, 0.3))
	_save(img, "res://assets/sprites/weapons/cloud_sword.png")

func _gen_boxing_gloves() -> void:
	var img = _img()
	var glove = Color(0.85, 0.15, 0.15)
	var glove_hi = Color(1.0, 0.35, 0.3)
	var lace = Color(0.9, 0.85, 0.8)

	# Left glove
	_fill(img, 1, 3, 5, 5, glove)
	_fill(img, 2, 2, 3, 1, glove)
	_fill(img, 2, 8, 3, 1, glove)
	# Highlight
	_fill(img, 2, 3, 2, 2, glove_hi)
	# Thumb
	_px(img, 0, 5, glove)
	_px(img, 0, 6, glove)
	# Lace
	_fill(img, 2, 9, 2, 2, lace)

	# Right glove
	_fill(img, 9, 3, 5, 5, glove)
	_fill(img, 10, 2, 3, 1, glove)
	_fill(img, 10, 8, 3, 1, glove)
	_fill(img, 10, 3, 2, 2, glove_hi)
	_px(img, 14, 5, glove)
	_px(img, 14, 6, glove)
	_fill(img, 11, 9, 2, 2, lace)

	_outline(img, Color(0.2, 0.05, 0.05))
	_save(img, "res://assets/sprites/weapons/boxing_gloves.png")

func _gen_shadow_claw() -> void:
	var img = _img()
	var claw = Color(0.5, 0.1, 0.8)
	var claw_hi = Color(0.7, 0.3, 1.0)
	var shadow = Color(0.2, 0.05, 0.4)
	var tip = Color(0.9, 0.5, 1.0)

	# Shadow aura base
	_fill(img, 3, 4, 10, 8, shadow)
	# Three claw blades fanning out from bottom-center
	# Left claw
	_px(img, 3, 2, tip)
	_px(img, 4, 3, claw_hi)
	_px(img, 4, 4, claw)
	_px(img, 5, 5, claw)
	_px(img, 5, 6, claw)
	_px(img, 6, 7, claw)
	_px(img, 6, 8, claw)
	_px(img, 7, 9, claw)
	# Center claw
	_px(img, 7, 1, tip)
	_px(img, 8, 1, tip)
	_px(img, 7, 2, claw_hi)
	_px(img, 8, 2, claw_hi)
	_fill(img, 7, 3, 2, 7, claw)
	# Right claw
	_px(img, 12, 2, tip)
	_px(img, 11, 3, claw_hi)
	_px(img, 11, 4, claw)
	_px(img, 10, 5, claw)
	_px(img, 10, 6, claw)
	_px(img, 9, 7, claw)
	_px(img, 9, 8, claw)
	_px(img, 8, 9, claw)
	# Grip / palm base
	_fill(img, 5, 10, 6, 3, Color(0.35, 0.1, 0.5))
	_fill(img, 6, 13, 4, 2, Color(0.3, 0.08, 0.45))
	# Purple energy glow on claws
	_px(img, 5, 4, claw_hi)
	_px(img, 10, 4, claw_hi)
	_px(img, 7, 2, claw_hi)

	_outline(img, Color(0.1, 0.02, 0.18))
	_save(img, "res://assets/sprites/weapons/shadow_claw.png")

func _gen_chain_whip() -> void:
	var img = _img()
	var chain = Color(0.6, 0.6, 0.65)
	var chain_hi = Color(0.78, 0.78, 0.84)
	var handle = Color(0.4, 0.25, 0.15)
	var spike = Color(0.5, 0.5, 0.55)

	# Handle (bottom-left)
	_fill(img, 1, 12, 3, 3, handle)
	_fill(img, 2, 11, 2, 1, handle)
	# Chain links curving up and right
	# Each link is a 2x1 block
	_fill(img, 3, 10, 2, 1, chain)
	_fill(img, 4, 9, 2, 1, chain_hi)
	_fill(img, 5, 8, 2, 1, chain)
	_fill(img, 6, 7, 2, 1, chain_hi)
	_fill(img, 7, 6, 2, 1, chain)
	_fill(img, 8, 5, 2, 1, chain_hi)
	_fill(img, 9, 4, 2, 1, chain)
	_fill(img, 10, 3, 2, 1, chain_hi)
	_fill(img, 11, 2, 2, 1, chain)
	# Spiked tip at end
	_px(img, 13, 1, spike)
	_px(img, 14, 0, spike)
	_px(img, 14, 2, spike)
	_px(img, 12, 1, spike)
	# Highlight on handle
	_px(img, 2, 12, Color(0.55, 0.38, 0.22))

	_outline(img, Color(0.12, 0.12, 0.14))
	_save(img, "res://assets/sprites/weapons/chain_whip.png")

# ==================== RANGED (11) ====================

func _gen_machinegun() -> void:
	var img = _img()
	var metal = Color(0.45, 0.47, 0.5)
	var metal_hi = Color(0.6, 0.62, 0.68)
	var grip = Color(0.3, 0.25, 0.2)
	var barrel = Color(0.35, 0.37, 0.4)

	# Body
	_fill(img, 2, 6, 10, 3, metal)
	# Highlight on top
	_fill(img, 2, 6, 10, 1, metal_hi)
	# Barrel
	_fill(img, 12, 7, 3, 1, barrel)
	_px(img, 15, 7, Color(0.25, 0.25, 0.28))
	# Muzzle flash hint
	_px(img, 15, 6, Color(0.9, 0.7, 0.2, 0.5))
	# Grip
	_fill(img, 4, 9, 3, 3, grip)
	# Magazine
	_fill(img, 7, 9, 2, 4, metal.darkened(0.15))
	# Stock
	_fill(img, 0, 6, 2, 3, grip)
	_px(img, 0, 9, grip)

	_outline(img, Color(0.1, 0.1, 0.1))
	_save(img, "res://assets/sprites/weapons/machinegun.png")

func _gen_staff() -> void:
	var img = _img()
	var rod = Color(0.55, 0.3, 0.6)
	var rod_hi = Color(0.7, 0.4, 0.75)
	var orb = Color(0.3, 0.5, 1.0)
	var orb_glow = Color(0.5, 0.7, 1.0)

	# Rod
	_fill(img, 7, 4, 2, 11, rod)
	_px(img, 7, 6, rod_hi)
	_px(img, 7, 8, rod_hi)
	_px(img, 7, 10, rod_hi)
	# Orb on top
	_fill(img, 6, 1, 4, 3, orb)
	_fill(img, 7, 0, 2, 1, orb)
	_fill(img, 7, 4, 2, 1, orb)
	# Orb glow center
	_px(img, 7, 2, orb_glow)
	_px(img, 8, 2, orb_glow)
	_px(img, 7, 1, orb_glow)
	# Cradle
	_px(img, 5, 3, rod)
	_px(img, 10, 3, rod)

	_outline(img, Color(0.15, 0.08, 0.18))
	_save(img, "res://assets/sprites/weapons/staff.png")

func _gen_bazooka() -> void:
	var img = _img()
	var tube = Color(0.3, 0.5, 0.3)
	var tube_hi = Color(0.4, 0.6, 0.38)
	var grip = Color(0.3, 0.25, 0.2)

	# Main tube
	_fill(img, 1, 5, 13, 3, tube)
	# Front opening
	_fill(img, 14, 5, 2, 3, tube.darkened(0.2))
	# Highlight
	_fill(img, 1, 5, 13, 1, tube_hi)
	# Sight
	_fill(img, 10, 3, 1, 2, tube)
	_px(img, 10, 3, tube_hi)
	# Grip
	_fill(img, 4, 8, 2, 3, grip)
	# Trigger
	_px(img, 6, 9, grip)
	# Exhaust end
	_fill(img, 0, 5, 1, 3, Color(0.2, 0.2, 0.2))

	_outline(img, Color(0.1, 0.15, 0.1))
	_save(img, "res://assets/sprites/weapons/bazooka.png")

func _gen_shuriken() -> void:
	var img = _img()
	var metal = Color(0.75, 0.78, 0.82)
	var metal_hi = Color(0.9, 0.92, 0.96)
	var center = Color(0.4, 0.4, 0.45)

	# 4-point star shape
	# Center
	_fill(img, 6, 6, 4, 4, metal)
	# Top point
	_fill(img, 7, 1, 2, 5, metal)
	_px(img, 7, 0, metal_hi)
	_px(img, 8, 0, metal_hi)
	# Bottom point
	_fill(img, 7, 10, 2, 5, metal)
	_px(img, 7, 15, metal_hi)
	_px(img, 8, 15, metal_hi)
	# Left point
	_fill(img, 1, 7, 5, 2, metal)
	_px(img, 0, 7, metal_hi)
	_px(img, 0, 8, metal_hi)
	# Right point
	_fill(img, 10, 7, 5, 2, metal)
	_px(img, 15, 7, metal_hi)
	_px(img, 15, 8, metal_hi)
	# Center hole
	_fill(img, 7, 7, 2, 2, center)

	_outline(img, Color(0.15, 0.15, 0.18))
	_save(img, "res://assets/sprites/weapons/shuriken.png")

func _gen_dual_pistol() -> void:
	var img = _img()
	var metal = Color(0.5, 0.52, 0.55)
	var metal_hi = Color(0.65, 0.67, 0.72)
	var grip = Color(0.3, 0.22, 0.15)

	# Top pistol (pointing right)
	_fill(img, 3, 2, 7, 2, metal)
	_fill(img, 10, 2, 2, 1, metal)  # barrel
	_fill(img, 3, 2, 7, 1, metal_hi)
	_fill(img, 5, 4, 2, 3, grip)

	# Bottom pistol (pointing left)
	_fill(img, 5, 9, 7, 2, metal)
	_fill(img, 3, 9, 2, 1, metal)  # barrel
	_fill(img, 5, 9, 7, 1, metal_hi)
	_fill(img, 9, 11, 2, 3, grip)

	_outline(img, Color(0.1, 0.1, 0.1))
	_save(img, "res://assets/sprites/weapons/dual_pistol.png")

func _gen_flamethrower() -> void:
	var img = _img()
	var body = Color(0.65, 0.2, 0.15)
	var body_hi = Color(0.8, 0.3, 0.2)
	var nozzle = Color(0.5, 0.5, 0.52)
	var flame1 = Color(1.0, 0.6, 0.1)
	var flame2 = Color(1.0, 0.35, 0.1)
	var flame3 = Color(1.0, 0.85, 0.2)

	# Body
	_fill(img, 1, 7, 8, 3, body)
	_fill(img, 1, 7, 8, 1, body_hi)
	# Tank on back
	_fill(img, 1, 6, 3, 5, body.darkened(0.15))
	# Nozzle
	_fill(img, 9, 7, 2, 2, nozzle)
	# Flames coming out
	_fill(img, 11, 6, 2, 3, flame2)
	_fill(img, 13, 5, 2, 4, flame1)
	_px(img, 14, 4, flame3)
	_px(img, 15, 5, flame3)
	_px(img, 15, 7, flame1)
	# Grip
	_fill(img, 5, 10, 2, 3, Color(0.3, 0.22, 0.15))

	_outline(img, Color(0.18, 0.08, 0.05))
	_save(img, "res://assets/sprites/weapons/flamethrower.png")

func _gen_ice_staff() -> void:
	var img = _img()
	var rod = Color(0.4, 0.55, 0.8)
	var rod_hi = Color(0.55, 0.7, 0.9)
	var crystal = Color(0.9, 0.95, 1.0)
	var crystal_core = Color(0.7, 0.88, 1.0)

	# Rod
	_fill(img, 7, 5, 2, 10, rod)
	_px(img, 7, 7, rod_hi)
	_px(img, 7, 9, rod_hi)
	_px(img, 7, 11, rod_hi)
	# Crystal on top (diamond shape)
	_px(img, 7, 0, crystal)
	_px(img, 8, 0, crystal)
	_fill(img, 6, 1, 4, 1, crystal)
	_fill(img, 5, 2, 6, 2, crystal)
	_fill(img, 6, 4, 4, 1, crystal)
	# Crystal core glow
	_px(img, 7, 2, crystal_core)
	_px(img, 8, 2, crystal_core)
	_px(img, 7, 3, crystal_core)
	_px(img, 8, 3, crystal_core)
	# Frost sparkles
	_px(img, 4, 1, Color(0.8, 0.9, 1.0, 0.6))
	_px(img, 11, 3, Color(0.8, 0.9, 1.0, 0.6))

	_outline(img, Color(0.1, 0.15, 0.25))
	_save(img, "res://assets/sprites/weapons/ice_staff.png")

func _gen_crossbow() -> void:
	var img = _img()
	var wood = Color(0.5, 0.35, 0.2)
	var wood_hi = Color(0.65, 0.48, 0.3)
	var string_c = Color(0.8, 0.78, 0.7)
	var bolt = Color(0.6, 0.6, 0.65)

	# Stock (horizontal)
	_fill(img, 4, 7, 8, 2, wood)
	_fill(img, 4, 7, 8, 1, wood_hi)
	# Bow arms
	_fill(img, 1, 3, 2, 5, wood)
	_fill(img, 1, 3, 1, 1, wood_hi)
	_fill(img, 12, 3, 2, 5, wood)
	_fill(img, 13, 3, 1, 1, wood_hi)
	# String
	for i in range(3):
		_px(img, 3 + i, 5 + i, string_c)
		_px(img, 11 - i, 5 + i, string_c)
	# Bolt (loaded)
	_fill(img, 6, 6, 6, 1, bolt)
	_px(img, 12, 6, Color(0.5, 0.5, 0.55))
	# Trigger
	_px(img, 7, 9, wood.darkened(0.2))
	_px(img, 7, 10, wood.darkened(0.2))
	# Grip
	_fill(img, 5, 9, 2, 3, wood.darkened(0.1))

	_outline(img, Color(0.15, 0.1, 0.05))
	_save(img, "res://assets/sprites/weapons/crossbow.png")

func _gen_plasma_cannon() -> void:
	var img = _img()
	var body = Color(0.4, 0.25, 0.55)
	var body_hi = Color(0.55, 0.35, 0.7)
	var tech = Color(0.2, 0.7, 0.8)
	var glow = Color(0.4, 0.9, 1.0)
	var grip = Color(0.25, 0.2, 0.3)

	# Body
	_fill(img, 2, 5, 9, 4, body)
	_fill(img, 2, 5, 9, 1, body_hi)
	# Barrel (wide)
	_fill(img, 11, 4, 3, 5, body)
	_fill(img, 14, 5, 1, 3, body.darkened(0.2))
	# Tech lines
	_fill(img, 3, 7, 6, 1, tech)
	_px(img, 12, 5, glow)
	_px(img, 12, 7, glow)
	# Energy core
	_fill(img, 6, 5, 2, 2, glow)
	# Grip
	_fill(img, 4, 9, 2, 3, grip)
	# Muzzle glow
	_px(img, 15, 6, glow)

	_outline(img, Color(0.12, 0.08, 0.18))
	_save(img, "res://assets/sprites/weapons/plasma_cannon.png")

func _gen_elven_bow() -> void:
	var img = _img()
	var wood = Color(0.3, 0.55, 0.3)
	var wood_hi = Color(0.45, 0.7, 0.4)
	var string_c = Color(0.85, 0.82, 0.7)
	var leaf = Color(0.4, 0.65, 0.25)

	# Bow body (curved, vertical)
	# Top limb
	_px(img, 5, 0, wood)
	_px(img, 5, 1, wood)
	_px(img, 6, 2, wood)
	_px(img, 6, 3, wood)
	_px(img, 7, 4, wood)
	# Grip area
	_fill(img, 7, 5, 2, 5, wood)
	_px(img, 7, 6, wood_hi)
	_px(img, 7, 8, wood_hi)
	# Bottom limb
	_px(img, 7, 10, wood)
	_px(img, 6, 11, wood)
	_px(img, 6, 12, wood)
	_px(img, 5, 13, wood)
	_px(img, 5, 14, wood)
	# String
	for y in range(0, 15):
		_px(img, 9, y, string_c)
	# Leaf ornaments
	_px(img, 4, 0, leaf)
	_px(img, 4, 14, leaf)
	_px(img, 6, 5, leaf)
	_px(img, 6, 9, leaf)
	# Arrow nocked
	_fill(img, 10, 7, 5, 1, Color(0.6, 0.55, 0.4))
	_px(img, 15, 7, Color(0.5, 0.5, 0.55))

	_outline(img, Color(0.08, 0.18, 0.08))
	_save(img, "res://assets/sprites/weapons/elven_bow.png")

func _gen_boomerang() -> void:
	var img = _img()
	var wood = Color(0.6, 0.45, 0.2)
	var wood_hi = Color(0.75, 0.58, 0.3)
	var wood_dk = Color(0.45, 0.32, 0.12)
	var stripe = Color(0.85, 0.3, 0.15)

	# V-shaped boomerang (angled, opening to top-right)
	# Left arm (going up-left)
	_fill(img, 2, 6, 2, 5, wood)
	_fill(img, 3, 5, 2, 1, wood)
	_fill(img, 4, 4, 2, 1, wood)
	_px(img, 5, 3, wood)
	_px(img, 6, 3, wood)
	# Right arm (going up-right)
	_fill(img, 7, 4, 2, 1, wood)
	_fill(img, 8, 3, 2, 1, wood)
	_fill(img, 9, 2, 2, 1, wood)
	_fill(img, 10, 1, 2, 1, wood)
	_fill(img, 11, 1, 2, 2, wood)
	# Bend at the V vertex
	_fill(img, 4, 7, 4, 2, wood)
	_fill(img, 5, 6, 3, 1, wood)
	# Wood highlights
	_px(img, 2, 6, wood_hi)
	_px(img, 3, 5, wood_hi)
	_px(img, 10, 1, wood_hi)
	_px(img, 11, 1, wood_hi)
	# Painted stripe decoration
	_px(img, 2, 8, stripe)
	_px(img, 2, 9, stripe)
	_px(img, 12, 1, stripe)
	_px(img, 12, 2, stripe)
	# Dark edge
	_px(img, 2, 10, wood_dk)
	_px(img, 13, 1, wood_dk)

	_outline(img, Color(0.15, 0.12, 0.05))
	_save(img, "res://assets/sprites/weapons/boomerang.png")

# ==================== SUMMON/SPECIAL (10) ====================

func _gen_necro() -> void:
	var img = _img()
	var cover = Color(0.2, 0.35, 0.2)
	var cover_dk = Color(0.12, 0.22, 0.12)
	var pages = Color(0.85, 0.82, 0.7)
	var skull = Color(0.5, 0.8, 0.4)
	var skull_hi = Color(0.6, 0.9, 0.5)

	# Book body
	_fill(img, 3, 3, 10, 10, cover)
	_fill(img, 3, 3, 10, 1, cover_dk)
	_fill(img, 3, 12, 10, 1, cover_dk)
	# Spine
	_fill(img, 3, 3, 1, 10, cover_dk)
	# Pages peeking
	_fill(img, 4, 4, 8, 8, pages)
	# Skull on cover
	_fill(img, 6, 5, 4, 3, skull)
	_fill(img, 7, 4, 2, 1, skull)
	_fill(img, 7, 8, 2, 1, skull)
	# Skull eyes
	_px(img, 7, 6, Color(0.1, 0.1, 0.1))
	_px(img, 9, 6, Color(0.1, 0.1, 0.1))
	# Skull nose
	_px(img, 8, 7, cover)
	# Skull glow
	_px(img, 7, 5, skull_hi)

	_outline(img, Color(0.05, 0.1, 0.05))
	_save(img, "res://assets/sprites/weapons/necro.png")

func _gen_drone() -> void:
	var img = _img()
	var body = Color(0.5, 0.52, 0.55)
	var body_hi = Color(0.65, 0.67, 0.72)
	var prop = Color(0.4, 0.42, 0.45)
	var light = Color(0.2, 0.8, 0.3)

	# Body (central box)
	_fill(img, 5, 6, 6, 4, body)
	_fill(img, 5, 6, 6, 1, body_hi)
	# Camera/sensor
	_fill(img, 7, 10, 2, 1, Color(0.15, 0.15, 0.2))
	# LED
	_px(img, 8, 7, light)
	# Arms
	_fill(img, 2, 5, 3, 1, prop)
	_fill(img, 11, 5, 3, 1, prop)
	# Propellers (top)
	_fill(img, 0, 3, 5, 1, prop)
	_fill(img, 2, 4, 1, 1, prop)
	_fill(img, 11, 3, 5, 1, prop)
	_fill(img, 13, 4, 1, 1, prop)
	# Propeller blur
	_px(img, 0, 3, Color(0.5, 0.5, 0.55, 0.5))
	_px(img, 4, 3, Color(0.5, 0.5, 0.55, 0.5))
	_px(img, 11, 3, Color(0.5, 0.5, 0.55, 0.5))
	_px(img, 15, 3, Color(0.5, 0.5, 0.55, 0.5))

	_outline(img, Color(0.1, 0.1, 0.12))
	_save(img, "res://assets/sprites/weapons/drone.png")

func _gen_totem() -> void:
	var img = _img()
	var wood = Color(0.5, 0.35, 0.2)
	var wood_dk = Color(0.38, 0.25, 0.12)
	var face = Color(0.6, 0.45, 0.28)
	var eyes = Color(0.9, 0.3, 0.1)

	# Pole body
	_fill(img, 5, 1, 6, 14, wood)
	# Carved sections
	_fill(img, 5, 1, 6, 1, wood_dk)
	_fill(img, 5, 5, 6, 1, wood_dk)
	_fill(img, 5, 9, 6, 1, wood_dk)
	_fill(img, 5, 13, 6, 1, wood_dk)
	# Top face
	_fill(img, 6, 2, 4, 3, face)
	_px(img, 7, 3, eyes)
	_px(img, 9, 3, eyes)
	_px(img, 8, 4, wood_dk)
	# Bottom face
	_fill(img, 6, 10, 4, 3, face)
	_px(img, 7, 11, eyes)
	_px(img, 9, 11, eyes)
	# Wings/ears sticking out
	_fill(img, 3, 2, 2, 2, wood)
	_fill(img, 11, 2, 2, 2, wood)
	_fill(img, 3, 10, 2, 2, wood)
	_fill(img, 11, 10, 2, 2, wood)

	_outline(img, Color(0.15, 0.1, 0.05))
	_save(img, "res://assets/sprites/weapons/totem.png")

func _gen_poison_bottle() -> void:
	var img = _img()
	var glass = Color(0.3, 0.65, 0.3, 0.85)
	var liquid = Color(0.2, 0.7, 0.15)
	var liquid_hi = Color(0.35, 0.85, 0.3)
	var cork = Color(0.6, 0.45, 0.25)

	# Neck
	_fill(img, 7, 1, 2, 2, glass)
	# Cork
	_fill(img, 6, 0, 4, 1, cork)
	# Body (round bottle)
	_fill(img, 5, 3, 6, 2, glass)
	_fill(img, 4, 5, 8, 5, glass)
	_fill(img, 5, 10, 6, 2, glass)
	# Liquid inside
	_fill(img, 5, 6, 6, 4, liquid)
	_fill(img, 6, 10, 4, 1, liquid)
	# Liquid highlight
	_px(img, 5, 6, liquid_hi)
	_px(img, 5, 7, liquid_hi)
	# Bubbles
	_px(img, 8, 7, liquid_hi)
	_px(img, 7, 9, liquid_hi)
	# Skull label (tiny)
	_px(img, 7, 5, Color(0.9, 0.9, 0.8))
	_px(img, 8, 5, Color(0.9, 0.9, 0.8))
	_px(img, 7, 4, Color(0.9, 0.9, 0.8))
	_px(img, 8, 4, Color(0.9, 0.9, 0.8))

	_outline(img, Color(0.08, 0.2, 0.05))
	_save(img, "res://assets/sprites/weapons/poison_bottle.png")

func _gen_lightning_chain() -> void:
	var img = _img()
	var bolt = Color(1.0, 0.9, 0.2)
	var bolt_hi = Color(1.0, 1.0, 0.6)
	var glow = Color(1.0, 0.95, 0.4, 0.5)

	# Zigzag bolt from top to bottom
	_px(img, 7, 0, bolt_hi)
	_px(img, 8, 0, bolt_hi)
	_px(img, 8, 1, bolt)
	_px(img, 9, 2, bolt)
	_px(img, 10, 2, bolt)
	_px(img, 10, 3, bolt)
	_px(img, 9, 4, bolt)
	_px(img, 8, 4, bolt)
	_fill(img, 6, 5, 3, 1, bolt)
	_fill(img, 5, 6, 3, 1, bolt)
	_px(img, 5, 7, bolt)
	_px(img, 6, 8, bolt)
	_px(img, 7, 8, bolt)
	_fill(img, 7, 9, 3, 1, bolt)
	_px(img, 9, 10, bolt)
	_px(img, 8, 11, bolt)
	_px(img, 7, 12, bolt)
	_px(img, 6, 12, bolt)
	_px(img, 6, 13, bolt)
	_px(img, 7, 14, bolt)
	_px(img, 7, 15, bolt_hi)
	_px(img, 8, 15, bolt_hi)
	# Glow around bolt
	_px(img, 6, 1, glow)
	_px(img, 11, 3, glow)
	_px(img, 4, 6, glow)
	_px(img, 10, 10, glow)
	_px(img, 5, 14, glow)

	_outline(img, Color(0.3, 0.25, 0.05))
	_save(img, "res://assets/sprites/weapons/lightning_chain.png")

func _gen_magic_book() -> void:
	var img = _img()
	var cover = Color(0.2, 0.3, 0.7)
	var cover_dk = Color(0.12, 0.18, 0.5)
	var pages = Color(0.9, 0.88, 0.8)
	var star = Color(0.85, 0.8, 0.2)
	var magic = Color(0.4, 0.6, 1.0)

	# Open book - left page
	_fill(img, 1, 4, 6, 9, pages)
	_fill(img, 1, 4, 6, 1, cover)
	_fill(img, 1, 12, 6, 1, cover)
	_fill(img, 1, 4, 1, 9, cover_dk)
	# Right page
	_fill(img, 8, 4, 6, 9, pages)
	_fill(img, 8, 4, 6, 1, cover)
	_fill(img, 8, 12, 6, 1, cover)
	_fill(img, 14, 4, 1, 9, cover_dk)
	# Spine
	_fill(img, 7, 3, 1, 11, cover_dk)
	# Text lines (left)
	_fill(img, 2, 6, 4, 1, Color(0.5, 0.5, 0.55, 0.4))
	_fill(img, 2, 8, 4, 1, Color(0.5, 0.5, 0.55, 0.4))
	_fill(img, 2, 10, 3, 1, Color(0.5, 0.5, 0.55, 0.4))
	# Star on right page
	_px(img, 11, 6, star)
	_fill(img, 10, 7, 3, 2, star)
	_px(img, 11, 9, star)
	# Magic sparkles
	_px(img, 9, 5, magic)
	_px(img, 13, 8, magic)
	_px(img, 10, 10, magic)
	# Floating particles
	_px(img, 3, 2, magic)
	_px(img, 12, 1, magic)

	_outline(img, Color(0.05, 0.08, 0.2))
	_save(img, "res://assets/sprites/weapons/magic_book.png")

func _gen_time_bomb() -> void:
	var img = _img()
	var body = Color(0.15, 0.15, 0.18)
	var body_hi = Color(0.25, 0.25, 0.3)
	var fuse = Color(0.6, 0.45, 0.25)
	var spark = Color(1.0, 0.7, 0.2)
	var band = Color(0.5, 0.5, 0.55)

	# Round bomb body
	_fill(img, 5, 5, 7, 2, body)
	_fill(img, 4, 7, 9, 4, body)
	_fill(img, 5, 11, 7, 2, body)
	_fill(img, 6, 13, 5, 1, body)
	# Top
	_fill(img, 6, 4, 5, 1, body)
	# Highlight
	_px(img, 5, 6, body_hi)
	_px(img, 6, 6, body_hi)
	_px(img, 5, 7, body_hi)
	# Metal band on top
	_fill(img, 7, 3, 3, 1, band)
	# Fuse
	_fill(img, 8, 1, 1, 2, fuse)
	_px(img, 9, 1, fuse)
	_px(img, 10, 0, fuse)
	# Spark
	_px(img, 11, 0, spark)
	_px(img, 10, 0, Color(1.0, 0.5, 0.1))
	_px(img, 12, 0, Color(1.0, 0.85, 0.3, 0.6))

	_outline(img, Color(0.08, 0.08, 0.1))
	_save(img, "res://assets/sprites/weapons/time_bomb.png")

func _gen_portal_weapon() -> void:
	var img = _img()
	var outer = Color(0.5, 0.2, 0.7)
	var mid = Color(0.6, 0.3, 0.85)
	var inner = Color(0.7, 0.4, 1.0)
	var core = Color(0.2, 0.1, 0.35)
	var sparkle = Color(0.85, 0.6, 1.0)

	# Outer ring (circle)
	_fill(img, 5, 1, 6, 1, outer)
	_fill(img, 3, 2, 2, 1, outer)
	_fill(img, 11, 2, 2, 1, outer)
	_fill(img, 2, 3, 1, 2, outer)
	_fill(img, 13, 3, 1, 2, outer)
	_fill(img, 1, 5, 1, 6, outer)
	_fill(img, 14, 5, 1, 6, outer)
	_fill(img, 2, 11, 1, 2, outer)
	_fill(img, 13, 11, 1, 2, outer)
	_fill(img, 3, 13, 2, 1, outer)
	_fill(img, 11, 13, 2, 1, outer)
	_fill(img, 5, 14, 6, 1, outer)

	# Mid ring
	_fill(img, 5, 3, 6, 1, mid)
	_fill(img, 3, 5, 1, 6, mid)
	_fill(img, 12, 5, 1, 6, mid)
	_fill(img, 5, 12, 6, 1, mid)
	_fill(img, 4, 4, 1, 1, mid)
	_fill(img, 11, 4, 1, 1, mid)
	_fill(img, 4, 11, 1, 1, mid)
	_fill(img, 11, 11, 1, 1, mid)

	# Inner swirl
	_fill(img, 5, 5, 6, 6, inner)
	# Core void
	_fill(img, 6, 6, 4, 4, core)
	_fill(img, 7, 7, 2, 2, Color(0.1, 0.05, 0.2))
	# Swirl lines
	_px(img, 5, 7, inner.lightened(0.2))
	_px(img, 6, 5, inner.lightened(0.2))
	_px(img, 10, 8, inner.lightened(0.2))
	_px(img, 9, 10, inner.lightened(0.2))
	# Sparkles
	_px(img, 4, 3, sparkle)
	_px(img, 12, 4, sparkle)
	_px(img, 3, 11, sparkle)
	_px(img, 13, 12, sparkle)

	_outline(img, Color(0.18, 0.08, 0.25))
	_save(img, "res://assets/sprites/weapons/portal_weapon.png")

func _gen_tornado() -> void:
	var img = _img()
	var wind = Color(0.6, 0.75, 0.8)
	var wind_hi = Color(0.8, 0.9, 0.95)
	var wind_dk = Color(0.4, 0.55, 0.65)
	var core = Color(0.9, 0.95, 1.0)

	# Funnel shape — wide at top, narrow at bottom
	# Top (widest)
	_fill(img, 1, 1, 14, 2, wind)
	_fill(img, 2, 1, 12, 1, wind_hi)
	# Upper-mid
	_fill(img, 3, 3, 10, 2, wind)
	_fill(img, 4, 3, 8, 1, wind_hi)
	# Mid
	_fill(img, 5, 5, 6, 2, wind)
	_fill(img, 5, 5, 6, 1, wind_hi)
	# Lower-mid
	_fill(img, 6, 7, 4, 2, wind)
	_px(img, 6, 7, wind_hi)
	_px(img, 7, 7, wind_hi)
	# Bottom (narrowest)
	_fill(img, 7, 9, 2, 3, wind_dk)
	_px(img, 7, 12, wind_dk)
	_px(img, 8, 12, wind_dk)
	# Swirl lines
	_px(img, 2, 2, wind_dk)
	_px(img, 5, 4, wind_dk)
	_px(img, 12, 2, wind_dk)
	_px(img, 10, 4, wind_dk)
	# Bright core center
	_px(img, 7, 5, core)
	_px(img, 8, 5, core)
	_px(img, 7, 6, core)
	# Debris particles
	_px(img, 0, 2, Color(0.5, 0.4, 0.3, 0.6))
	_px(img, 15, 1, Color(0.5, 0.4, 0.3, 0.6))
	_px(img, 3, 5, Color(0.5, 0.4, 0.3, 0.5))
	_px(img, 12, 6, Color(0.5, 0.4, 0.3, 0.5))

	_outline(img, Color(0.15, 0.2, 0.25))
	_save(img, "res://assets/sprites/weapons/tornado.png")

func _gen_blood_orb() -> void:
	var img = _img()
	var blood = Color(0.7, 0.05, 0.1)
	var blood_hi = Color(0.9, 0.15, 0.2)
	var blood_dk = Color(0.45, 0.02, 0.05)
	var core = Color(1.0, 0.3, 0.35)
	var drip = Color(0.55, 0.03, 0.08)

	# Orb body (circle)
	_fill(img, 5, 2, 6, 1, blood)
	_fill(img, 4, 3, 8, 2, blood)
	_fill(img, 3, 5, 10, 4, blood)
	_fill(img, 4, 9, 8, 2, blood)
	_fill(img, 5, 11, 6, 1, blood)
	# Highlight (upper-left)
	_fill(img, 5, 3, 3, 2, blood_hi)
	_px(img, 5, 2, blood_hi)
	_px(img, 4, 4, blood_hi)
	# Core glow
	_px(img, 7, 6, core)
	_px(img, 8, 6, core)
	_px(img, 7, 7, core)
	# Dark shading (lower-right)
	_fill(img, 9, 7, 3, 2, blood_dk)
	_fill(img, 8, 9, 3, 2, blood_dk)
	_fill(img, 7, 11, 2, 1, blood_dk)
	# Blood drips hanging from bottom
	_px(img, 6, 12, drip)
	_px(img, 6, 13, drip)
	_px(img, 9, 12, drip)
	_px(img, 9, 13, drip)
	_px(img, 9, 14, drip)
	# Pulsing aura pixels
	_px(img, 2, 6, Color(0.6, 0.05, 0.1, 0.3))
	_px(img, 13, 6, Color(0.6, 0.05, 0.1, 0.3))
	_px(img, 7, 0, Color(0.6, 0.05, 0.1, 0.3))
	_px(img, 8, 14, Color(0.6, 0.05, 0.1, 0.3))

	_outline(img, Color(0.2, 0.02, 0.05))
	_save(img, "res://assets/sprites/weapons/blood_orb.png")

# ==================== PICKUPS (4) ====================

func _gen_xp_gem() -> void:
	var img = _img()
	var gem = Color(0.2, 0.4, 0.9)
	var gem_hi = Color(0.4, 0.6, 1.0)
	var gem_bright = Color(0.6, 0.8, 1.0)

	# Diamond shape
	_px(img, 7, 2, gem_hi)
	_px(img, 8, 2, gem_hi)
	_fill(img, 6, 3, 4, 1, gem_hi)
	_fill(img, 5, 4, 6, 1, gem)
	_fill(img, 4, 5, 8, 2, gem)
	_fill(img, 3, 7, 10, 2, gem)
	_fill(img, 4, 9, 8, 2, gem)
	_fill(img, 5, 11, 6, 1, gem)
	_fill(img, 6, 12, 4, 1, gem)
	_px(img, 7, 13, gem)
	_px(img, 8, 13, gem)
	# Facet highlight
	_fill(img, 6, 4, 2, 2, gem_bright)
	_px(img, 5, 5, gem_hi)
	_px(img, 5, 6, gem_hi)
	# Bottom shade
	for x in range(4, 12):
		for y in range(10, 14):
			var c = img.get_pixel(x, y)
			if c.a > 0:
				img.set_pixel(x, y, c.darkened(0.2))
	# Glow pixels
	_px(img, 2, 7, Color(0.3, 0.5, 1.0, 0.3))
	_px(img, 13, 7, Color(0.3, 0.5, 1.0, 0.3))
	_px(img, 7, 1, Color(0.5, 0.7, 1.0, 0.3))

	_outline(img, Color(0.08, 0.12, 0.3))
	_save(img, "res://assets/sprites/pickups/xp_gem.png")

func _gen_crystal() -> void:
	var img = _img()
	var crystal = Color(0.85, 0.7, 0.15)
	var crystal_hi = Color(1.0, 0.88, 0.3)
	var crystal_dk = Color(0.65, 0.5, 0.1)

	# Hexagonal crystal
	_fill(img, 6, 1, 4, 1, crystal_hi)
	_fill(img, 5, 2, 6, 2, crystal)
	_fill(img, 4, 4, 8, 4, crystal)
	_fill(img, 4, 8, 8, 3, crystal)
	_fill(img, 5, 11, 6, 2, crystal_dk)
	_fill(img, 6, 13, 4, 1, crystal_dk)
	# Facets
	_fill(img, 6, 2, 2, 2, crystal_hi)
	_fill(img, 5, 4, 2, 3, crystal_hi)
	# Dark facet
	_fill(img, 9, 5, 2, 4, crystal_dk)
	# Center shine
	_px(img, 7, 5, Color(1.0, 0.95, 0.6))
	_px(img, 7, 6, Color(1.0, 0.95, 0.6))
	# Edge amber glow
	_px(img, 3, 6, Color(0.9, 0.75, 0.2, 0.4))
	_px(img, 12, 6, Color(0.9, 0.75, 0.2, 0.4))

	_outline(img, Color(0.25, 0.18, 0.02))
	_save(img, "res://assets/sprites/pickups/crystal.png")

func _gen_health_pickup() -> void:
	var img = _img()
	var red = Color(0.85, 0.15, 0.15)
	var red_hi = Color(1.0, 0.3, 0.3)
	var red_dk = Color(0.6, 0.08, 0.08)
	var shine = Color(1.0, 0.6, 0.6)

	# Heart shape
	# Top bumps
	_fill(img, 2, 3, 4, 3, red)
	_fill(img, 10, 3, 4, 3, red)
	_fill(img, 3, 2, 2, 1, red)
	_fill(img, 11, 2, 2, 1, red)
	# Middle
	_fill(img, 1, 5, 14, 2, red)
	# Taper down
	_fill(img, 2, 7, 12, 2, red)
	_fill(img, 3, 9, 10, 1, red)
	_fill(img, 4, 10, 8, 1, red)
	_fill(img, 5, 11, 6, 1, red)
	_fill(img, 6, 12, 4, 1, red)
	_fill(img, 7, 13, 2, 1, red)
	# Highlight (top-left)
	_fill(img, 3, 3, 2, 2, red_hi)
	_px(img, 3, 2, red_hi)
	_px(img, 4, 4, shine)
	# Shading (bottom-right)
	_fill(img, 10, 5, 4, 2, red_dk)
	_fill(img, 9, 7, 4, 2, red_dk)
	_fill(img, 8, 9, 3, 1, red_dk)
	_fill(img, 8, 10, 2, 1, red_dk)

	_outline(img, Color(0.25, 0.05, 0.05))
	_save(img, "res://assets/sprites/pickups/health_pickup.png")

func _gen_magnet_pickup() -> void:
	var img = _img()
	var red = Color(0.8, 0.2, 0.2)
	var gray = Color(0.6, 0.6, 0.62)
	var metal = Color(0.5, 0.5, 0.52)
	var red_hi = Color(0.95, 0.35, 0.3)
	var gray_hi = Color(0.75, 0.75, 0.78)

	# Horseshoe magnet (U shape opening up)
	# Left arm - red
	_fill(img, 2, 5, 3, 8, red)
	_fill(img, 2, 5, 3, 2, red_hi)
	# Right arm - red
	_fill(img, 11, 5, 3, 8, red)
	_fill(img, 11, 5, 3, 2, red_hi)
	# Curved top connecting
	_fill(img, 4, 3, 8, 2, red)
	_fill(img, 5, 2, 6, 1, red)
	_fill(img, 3, 4, 1, 1, red)
	_fill(img, 12, 4, 1, 1, red)
	# Gray tips (poles)
	_fill(img, 2, 13, 3, 2, gray)
	_fill(img, 2, 13, 3, 1, gray_hi)
	_fill(img, 11, 13, 3, 2, gray)
	_fill(img, 11, 13, 3, 1, gray_hi)
	# Metal shine on top
	_fill(img, 6, 2, 3, 1, red_hi)
	# Inner dark
	_fill(img, 5, 5, 6, 7, Color(0, 0, 0, 0))  # clear inner
	# Force lines (tiny)
	_px(img, 6, 14, Color(0.4, 0.6, 1.0, 0.4))
	_px(img, 9, 14, Color(0.4, 0.6, 1.0, 0.4))

	_outline(img, Color(0.2, 0.08, 0.08))
	_save(img, "res://assets/sprites/pickups/magnet_pickup.png")
