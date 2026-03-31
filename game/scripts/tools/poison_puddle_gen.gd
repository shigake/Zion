extends SceneTree

## Gera sprite de poça de veneno (32x32).
## Run: godot --headless --path game --script res://scripts/tools/poison_puddle_gen.gd

const S := 32

func _init() -> void:
	var img = Image.create(S, S, false, Image.FORMAT_RGBA8)

	# Base: oval verde escuro
	var center = Vector2(16, 16)
	for x in range(S):
		for y in range(S):
			var dx = (float(x) - center.x) / 14.0
			var dy = (float(y) - center.y) / 11.0
			var dist = dx * dx + dy * dy
			if dist < 1.0:
				# Verde toxico com variação
				var noise = sin(x * 1.5) * cos(y * 2.0) * 0.08
				var alpha = clampf(1.0 - dist * 0.6, 0.4, 0.85)
				var green = clampf(0.45 + noise, 0.3, 0.6)
				img.set_pixel(x, y, Color(0.1 + noise * 0.5, green, 0.05, alpha))

	# Bolhas (pontos mais claros)
	var bubble_positions = [
		Vector2i(10, 12), Vector2i(18, 14), Vector2i(14, 10),
		Vector2i(20, 16), Vector2i(12, 18), Vector2i(16, 20),
		Vector2i(8, 15), Vector2i(22, 12), Vector2i(15, 8),
	]
	for bp in bubble_positions:
		if bp.x >= 0 and bp.x < S and bp.y >= 0 and bp.y < S:
			if img.get_pixel(bp.x, bp.y).a > 0:
				img.set_pixel(bp.x, bp.y, Color(0.3, 0.9, 0.2, 0.8))
				if bp.x + 1 < S:
					img.set_pixel(bp.x + 1, bp.y, Color(0.2, 0.7, 0.15, 0.6))

	# Brilho central (highlight)
	for x in range(13, 19):
		for y in range(13, 17):
			var px = img.get_pixel(x, y)
			if px.a > 0:
				img.set_pixel(x, y, Color(px.r + 0.1, px.g + 0.15, px.b, px.a))

	# Borda escura
	for x in range(S):
		for y in range(S):
			if img.get_pixel(x, y).a > 0:
				for d in [Vector2i(-1,0), Vector2i(1,0), Vector2i(0,-1), Vector2i(0,1)]:
					var nx = x + d.x
					var ny = y + d.y
					if nx >= 0 and nx < S and ny >= 0 and ny < S and img.get_pixel(nx, ny).a == 0:
						img.set_pixel(x, y, Color(0.05, 0.2, 0.02, img.get_pixel(x, y).a))

	DirAccess.make_dir_recursive_absolute("res://assets/sprites/effects/")
	img.save_png("res://assets/sprites/effects/poison_puddle.png")
	print("Saved: res://assets/sprites/effects/poison_puddle.png")
	quit()
