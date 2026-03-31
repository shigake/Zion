extends SceneTree

## Gera sprites de slash faltantes para armas melee.
## Run: godot --headless --path game --script res://scripts/tools/melee_slash_gen.gd

const S := 32
const OUT := "res://assets/sprites/effects/slashes/"

func _init() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	_gen_shadow_claw_slash()
	_gen_chain_whip_slash()
	print("Melee slash sprites generated!")
	quit()

func _fill(img: Image, x: int, y: int, w: int, h: int, c: Color) -> void:
	for px in range(maxi(x, 0), mini(x + w, S)):
		for py in range(maxi(y, 0), mini(y + h, S)):
			img.set_pixel(px, py, c)

func _outline(img: Image, color: Color) -> void:
	var copy = img.duplicate()
	for x in range(S):
		for y in range(S):
			if copy.get_pixel(x, y).a > 0:
				for dx in [-1, 0, 1]:
					for dy in [-1, 0, 1]:
						if dx == 0 and dy == 0: continue
						var nx = x + dx
						var ny = y + dy
						if nx >= 0 and nx < S and ny >= 0 and ny < S and copy.get_pixel(nx, ny).a == 0:
							img.set_pixel(nx, ny, color)

# Shadow Claw: garras roxas triplas (3 linhas diagonais)
func _gen_shadow_claw_slash() -> void:
	var img = Image.create(S, S, false, Image.FORMAT_RGBA8)
	var purple = Color(0.6, 0.15, 0.9, 0.9)
	var light_purple = Color(0.8, 0.4, 1.0, 0.7)
	# 3 garras diagonais
	for claw in range(3):
		var offset_x = claw * 5 + 4
		var offset_y = claw * 3 + 2
		for i in range(18):
			var x = offset_x + i
			var y = offset_y + int(i * 0.8)
			if x >= 0 and x < S and y >= 0 and y < S:
				img.set_pixel(x, y, purple)
				if x + 1 < S:
					img.set_pixel(x + 1, y, light_purple)
				if y + 1 < S:
					img.set_pixel(x, y + 1, Color(0.4, 0.1, 0.6, 0.5))
	_outline(img, Color(0.2, 0.05, 0.3))
	img.save_png(OUT + "shadow_claw_slash.png")
	print("Saved: shadow_claw_slash.png")

# Chain Whip: cadeia elétrica em arco (amarelo/azul)
func _gen_chain_whip_slash() -> void:
	var img = Image.create(S, S, false, Image.FORMAT_RGBA8)
	var yellow = Color(1.0, 0.9, 0.2, 0.9)
	var blue = Color(0.3, 0.6, 1.0, 0.7)
	# Arco de cadeia
	for i in range(20):
		var t = float(i) / 19.0
		var x = int(6 + t * 20)
		var y = int(16 - sin(t * PI) * 10)
		if x >= 0 and x < S and y >= 0 and y < S:
			# Elos da cadeia (alternando amarelo/azul)
			var c = yellow if i % 2 == 0 else blue
			img.set_pixel(x, y, c)
			if x + 1 < S:
				img.set_pixel(x + 1, y, c)
			if y + 1 < S:
				img.set_pixel(x, y + 1, c.darkened(0.2))
			# Sparks
			if i % 4 == 0:
				if y - 1 >= 0:
					img.set_pixel(x, y - 1, Color(1.0, 1.0, 0.5, 0.5))
	_outline(img, Color(0.15, 0.1, 0.05))
	img.save_png(OUT + "chain_whip_slash.png")
	print("Saved: chain_whip_slash.png")
