extends Node3D

## Tombstone left when a player dies in multiplayer.
## Allies can stand nearby for 5 seconds to revive the dead player.
## The reviver gets a temporary debuff (-30% max HP for 30s).

signal player_revived(peer_id: int)

var dead_peer_id: int = 0
var despawn_timer: float = GameConstants.TOMBSTONE_DESPAWN_TIME
var revive_progress: float = 0.0
var allies_in_range: Array[Node3D] = []
var is_reviving: bool = false
var _revived: bool = false

@onready var area: Area3D = $ReviveArea
@onready var progress_bar: MeshInstance3D = $ProgressBar
@onready var particles: GPUParticles3D = $SoulParticles

func _ready() -> void:
	_build_visual()
	_build_revive_area()
	_build_progress_bar()
	_build_soul_particles()

func _build_visual() -> void:
	# Tombstone billboard sprite
	var sprite = Sprite3D.new()
	var tex_path = "res://assets/sprites/props/cemetery/tombstone1.png"
	if ResourceLoader.exists(tex_path):
		sprite.texture = load(tex_path)
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	sprite.pixel_size = GameConstants.TOMBSTONE_SPRITE_PIXEL_SIZE
	sprite.shaded = false
	sprite.transparent = true
	sprite.position.y = GameConstants.TOMBSTONE_SPRITE_Y
	sprite.name = "TombstoneSprite"
	add_child(sprite)

	# Ground circle indicator (flat pixel-art ring)
	var circle_sprite = Sprite3D.new()
	var img = Image.create(32, 32, false, Image.FORMAT_RGBA8)
	var ring_color = Color(0.2, 0.6, 1.0, 0.3)
	for x in range(32):
		for y in range(32):
			var dx = x - 16
			var dy = y - 16
			var dist = sqrt(dx * dx + dy * dy)
			if dist > 12 and dist < 15:
				img.set_pixel(x, y, ring_color)
	circle_sprite.texture = ImageTexture.create_from_image(img)
	circle_sprite.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	circle_sprite.rotation.x = deg_to_rad(-90)
	circle_sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	circle_sprite.pixel_size = GameConstants.TOMBSTONE_RING_PIXEL_SIZE
	circle_sprite.shaded = false
	circle_sprite.transparent = true
	circle_sprite.position.y = 0.02
	add_child(circle_sprite)

func _build_revive_area() -> void:
	var a = Area3D.new()
	a.name = "ReviveArea"
	a.collision_layer = 0
	a.collision_mask = 1  # Players
	var col = CollisionShape3D.new()
	var shape = SphereShape3D.new()
	shape.radius = GameConstants.TOMBSTONE_INTERACT_RADIUS
	col.shape = shape
	a.add_child(col)
	a.body_entered.connect(_on_ally_entered)
	a.body_exited.connect(_on_ally_exited)
	add_child(a)
	area = a

func _build_progress_bar() -> void:
	var bar = MeshInstance3D.new()
	bar.name = "ProgressBar"
	var mesh = BoxMesh.new()
	mesh.size = Vector3(1.0, 0.08, 0.08)
	bar.mesh = mesh
	bar.position = Vector3(0, GameConstants.TOMBSTONE_PROGRESS_BAR_Y, 0)
	bar.visible = false
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.8, 1.0)
	mat.emission_enabled = true
	mat.emission = Color(0.2, 0.6, 1.0)
	mat.emission_energy_multiplier = 1.5
	bar.material_override = mat
	add_child(bar)
	progress_bar = bar

func _build_soul_particles() -> void:
	var p = GPUParticles3D.new()
	p.name = "SoulParticles"
	p.amount = GameConstants.TOMBSTONE_SOUL_PARTICLES
	p.lifetime = 2.0
	p.position = Vector3(0, 0.5, 0)
	var mat = ParticleProcessMaterial.new()
	mat.direction = Vector3(0, 1, 0)
	mat.initial_velocity_min = 0.2
	mat.initial_velocity_max = 0.6
	mat.spread = 30.0
	mat.gravity = Vector3(0, 0.2, 0)
	mat.scale_min = 0.03
	mat.scale_max = 0.06
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	mat.emission_sphere_radius = 0.5
	var color_ramp = GradientTexture1D.new()
	var grad = Gradient.new()
	grad.set_offset(0, 0.0)
	grad.set_color(0, Color(0.4, 0.7, 1.0, 0.8))
	grad.set_offset(1, 1.0)
	grad.set_color(1, Color(0.2, 0.4, 1.0, 0.0))
	color_ramp.gradient = grad
	mat.color_ramp = color_ramp
	p.process_material = mat
	var draw_mesh = SphereMesh.new()
	draw_mesh.radius = 0.03
	draw_mesh.height = 0.06
	var draw_mat = StandardMaterial3D.new()
	draw_mat.albedo_color = Color(0.5, 0.8, 1.0, 0.7)
	draw_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	draw_mat.emission_enabled = true
	draw_mat.emission = Color(0.3, 0.6, 1.0)
	draw_mat.emission_energy_multiplier = 2.0
	draw_mesh.material = draw_mat
	p.draw_pass_1 = draw_mesh
	add_child(p)
	particles = p

func _process(delta: float) -> void:
	if _revived or GameManager.paused:
		return

	# Despawn timer
	despawn_timer -= delta
	if despawn_timer <= 0:
		queue_free()
		return

	# Revive progress
	if allies_in_range.size() > 0:
		is_reviving = true
		revive_progress += delta
		# Update progress bar
		progress_bar.visible = true
		var pct = clampf(revive_progress / GameConstants.TOMBSTONE_REVIVE_TIME, 0.0, 1.0)
		progress_bar.scale.x = pct
		progress_bar.position.x = (pct - 1.0) * 0.5
		if revive_progress >= GameConstants.TOMBSTONE_REVIVE_TIME:
			_do_revive()
	else:
		is_reviving = false
		revive_progress = 0.0
		progress_bar.visible = false

func _on_ally_entered(body: Node3D) -> void:
	if body.is_in_group("players") and body not in allies_in_range:
		allies_in_range.append(body)

func _on_ally_exited(body: Node3D) -> void:
	allies_in_range.erase(body)

func _do_revive() -> void:
	if _revived:
		return
	_revived = true

	# Apply debuff to allies who helped
	for ally in allies_in_range:
		if is_instance_valid(ally):
			_apply_sacrifice_debuff()

	# Visual: revive explosion
	ParticleFactory.spawn_explosion_particles(global_position + Vector3(0, 0.5, 0), 2.0)
	ScreenEffects.shake(0.15)

	# Emit signal and notify multiplayer
	player_revived.emit(dead_peer_id)

	# Revive the player via GameManager
	if MultiplayerManager.is_host():
		_revive_on_host()

	# Remove tombstone
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector3.ZERO, 0.5)
	tween.tween_callback(queue_free)

func _revive_on_host() -> void:
	# Restore player HP to 50%
	var max_hp = GameManager.get_effective_max_hp()
	GameManager.player_hp = int(max_hp * GameConstants.TOMBSTONE_REVIVE_HP_PCT)
	GameManager.is_game_over = false

func _apply_sacrifice_debuff() -> void:
	## Reduce max HP by 30% for 30 seconds
	var original_mult = GameManager.max_hp_mult
	GameManager.max_hp_mult *= (1.0 - GameConstants.TOMBSTONE_DEBUFF_HP_REDUCTION)
	# Cap current HP to new max
	var new_max = GameManager.get_effective_max_hp()
	GameManager.player_hp = mini(GameManager.player_hp, new_max)
	# Restore after duration
	get_tree().create_timer(GameConstants.TOMBSTONE_DEBUFF_DURATION).timeout.connect(func():
		GameManager.max_hp_mult = original_mult
	)
	LogManager.info("Game", "Sacrifice debuff applied: -%.0f%% max HP for %.0fs" % [GameConstants.TOMBSTONE_DEBUFF_HP_REDUCTION * 100, GameConstants.TOMBSTONE_DEBUFF_DURATION])
