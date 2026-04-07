extends Node

## PRD 58 — Feedback visual de sinergia in-world.
## Aura flash no player + texto flutuante quando sinergias procam.

const SYNERGY_COLORS := {
	"fire_fire": [Color(1.0, 0.27, 0.0), Color(1.0, 0.84, 0.0)],
	"ice_ice": [Color(0.0, 0.75, 1.0), Color(1.0, 1.0, 1.0)],
	"electric_electric": [Color(1.0, 0.84, 0.0), Color(1.0, 1.0, 1.0)],
	"dark_dark": [Color(0.55, 0.0, 1.0), Color(0.1, 0.0, 0.2)],
	"poison_poison": [Color(0.2, 0.8, 0.2), Color(0.56, 0.93, 0.56)],
	"physical_physical": [Color(0.8, 0.52, 0.25), Color(1.0, 0.84, 0.0)],
	"fire_ice": [Color(0.69, 0.77, 0.87), Color(1.0, 0.39, 0.28)],
	"electric_ice": [Color(0.0, 1.0, 1.0), Color(1.0, 0.84, 0.0)],
	"fire_poison": [Color(1.0, 0.27, 0.0), Color(0.2, 0.8, 0.2)],
	"ice_dark": [Color(0.55, 0.0, 1.0), Color(0.0, 0.75, 1.0)],
	"electric_poison": [Color(1.0, 0.84, 0.0), Color(0.2, 0.8, 0.2)],
	"water_water": [Color(0.0, 0.47, 0.75), Color(0.0, 0.81, 0.82)],
	"water_fire": [Color(0.0, 0.47, 0.75), Color(1.0, 0.27, 0.0)],
	"water_electric": [Color(0.0, 0.47, 0.75), Color(1.0, 0.84, 0.0)],
	"water_ice": [Color(0.0, 0.47, 0.75), Color(0.0, 0.75, 1.0)],
	"water_dark": [Color(0.0, 0.47, 0.75), Color(0.55, 0.0, 1.0)],
}

const SYNERGY_NAMES := {
	"fire_fire": "Combustao espontanea",
	"ice_ice": "Estilhacamento glacial",
	"electric_electric": "Relampago em cadeia",
	"dark_dark": "Veu da escuridao",
	"poison_poison": "Praga dimensional",
	"physical_physical": "Furia do berserker",
	"fire_ice": "Nuvem de vapor",
	"electric_ice": "Descarga condutora",
	"fire_poison": "Chama toxica",
	"ice_dark": "Congelamento sombrio",
	"electric_poison": "Choque toxico",
	"water_water": "Onda primordial",
	"water_fire": "Explosao de vapor",
	"water_electric": "Eletrolise",
	"water_ice": "Zero absoluto",
	"water_dark": "Profundezas abissais",
}

var _cooldowns: Dictionary = {}  # synergy_name -> float (time until can show again)
const COOLDOWN := 0.5

func _ready() -> void:
	SynergySystem.synergy_procced.connect(_on_synergy_proc)

func _process(delta: float) -> void:
	for key in _cooldowns.keys():
		_cooldowns[key] -= delta
		if _cooldowns[key] <= 0:
			_cooldowns.erase(key)

func _on_synergy_proc(synergy_name: String, damage: float) -> void:
	# Throttle
	if synergy_name in _cooldowns:
		return
	_cooldowns[synergy_name] = COOLDOWN

	var players := GameManager.get_players()
	if players.is_empty():
		return
	var player: Node3D = players[0]

	var colors: Array = SYNERGY_COLORS.get(synergy_name, [Color.WHITE, Color.WHITE])
	var primary: Color = colors[0]

	# Aura flash on player sprite
	_play_aura(player, primary)

	# Floating name text (1st proc and every 10th)
	var count: int = SynergySystem.synergy_proc_counts.get(synergy_name, 0)
	if count <= 1 or count % 10 == 0:
		_play_floating_name(player.global_position, synergy_name, primary)

	# Shockwave particles at player position
	ParticleFactory.spawn_hit_particles(
		player.global_position + Vector3(0, 0.5, 0),
		primary, 6
	)

func _play_aura(player: Node3D, color: Color) -> void:
	var sprite := player.get_node_or_null("PlayerSprite")
	if sprite == null:
		return
	# Flash the sprite with synergy color briefly
	var original_mod: Color = sprite.modulate
	sprite.modulate = Color(color.r * 2, color.g * 2, color.b * 2)
	var tween := get_tree().create_tween()
	tween.tween_property(sprite, "modulate", original_mod, 0.3).set_ease(Tween.EASE_OUT)

func _play_floating_name(pos: Vector3, synergy_name: String, color: Color) -> void:
	var display_name: String = SYNERGY_NAMES.get(synergy_name, synergy_name.capitalize())

	# Create 3D label that floats up and fades
	var label := Label3D.new()
	label.text = display_name
	label.font_size = 28
	label.modulate = color
	label.outline_modulate = Color(0, 0, 0)
	label.outline_size = 4
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.pixel_size = 0.01
	label.position = pos + Vector3(0, 1.5, 0)

	var scene := get_tree().current_scene
	if scene and is_instance_valid(scene):
		scene.add_child(label)
	else:
		label.queue_free()
		return

	# Animate: float up + fade out
	var tween := get_tree().create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", pos.y + 3.0, 1.2).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, 1.2).set_delay(0.6)
	tween.set_parallel(false)
	tween.tween_callback(label.queue_free)
