extends Node3D

## Aura visual ao redor do jogador. Pulsa suavemente.
## Uses a flat pixel-art circle sprite instead of a 3D TorusMesh.

var base_color: Color = Color(0.2, 0.8, 0.3, 0.15)
var _sprite: Sprite3D = null

func _ready() -> void:
	# Draw a simple circle ring as pixel art
	var img = Image.create(32, 32, false, Image.FORMAT_RGBA8)
	for x in range(32):
		for y in range(32):
			var dx = x - 16
			var dy = y - 16
			var dist = sqrt(dx * dx + dy * dy)
			if dist > 11 and dist < 14:
				img.set_pixel(x, y, base_color)
	var tex = ImageTexture.create_from_image(img)
	_sprite = Sprite3D.new()
	_sprite.texture = tex
	_sprite.billboard = BaseMaterial3D.BILLBOARD_DISABLED  # Flat on ground
	_sprite.rotation.x = deg_to_rad(-90)
	_sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	_sprite.pixel_size = 0.08
	_sprite.shaded = false
	_sprite.transparent = true
	_sprite.position.y = 0.05
	add_child(_sprite)

func _process(delta: float) -> void:
	if not _sprite:
		return
	# Gentle pulse via modulate alpha and scale
	var pulse = sin(Time.get_ticks_msec() * 0.003) * 0.1 + 0.9
	_sprite.scale = Vector3(pulse, pulse, 1.0)
	_sprite.modulate.a = 0.6 + sin(Time.get_ticks_msec() * 0.004) * 0.3

	# Rotate slowly
	_sprite.rotation.z += delta * 0.5
