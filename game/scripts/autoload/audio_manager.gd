extends Node

## Gerenciador de audio global: musica e efeitos sonoros.
## Usa logs placeholder ate que arquivos de audio reais sejam adicionados.

# Volume properties (0.0 - 1.0)
var music_volume: float = 1.0
var sfx_volume: float = 1.0
var master_volume: float = 1.0

# Audio players (created in _ready)
var _music_player: AudioStreamPlayer
var _music_player_fade: AudioStreamPlayer  # For crossfade
var _sfx_player: AudioStreamPlayer

# Known SFX names
var _valid_sfx: Array[String] = [
	"hit", "kill", "collect_xp", "collect_crystal", "level_up",
	"evolve", "boss_appear", "dash", "player_hurt", "menu_click"
]

# Known music names
var _valid_music: Array[String] = [
	"menu", "cemetery", "forest", "farm", "boss"
]

# Current music track
var _current_music: String = ""

# Crossfade
var _crossfade_duration: float = 1.0
var _crossfading: bool = false
var _crossfade_time: float = 0.0

func _ready() -> void:
	_music_player = AudioStreamPlayer.new()
	_music_player.name = "MusicPlayer"
	_music_player.bus = "Master"
	add_child(_music_player)

	_music_player_fade = AudioStreamPlayer.new()
	_music_player_fade.name = "MusicPlayerFade"
	_music_player_fade.bus = "Master"
	add_child(_music_player_fade)

	_sfx_player = AudioStreamPlayer.new()
	_sfx_player.name = "SFXPlayer"
	_sfx_player.bus = "Master"
	add_child(_sfx_player)

	_apply_volumes()

func _process(delta: float) -> void:
	if _crossfading:
		_crossfade_time += delta
		var t = clampf(_crossfade_time / _crossfade_duration, 0.0, 1.0)
		_music_player_fade.volume_db = linear_to_db((1.0 - t) * music_volume * master_volume)
		_music_player.volume_db = linear_to_db(t * music_volume * master_volume)
		if t >= 1.0:
			_crossfading = false
			_music_player_fade.stop()

func play_music(stream_name: String) -> void:
	if stream_name == _current_music:
		return
	if stream_name not in _valid_music:
		print("[AudioManager] Unknown music: " + stream_name)
		return

	print("[AudioManager] Music: " + stream_name)

	# Crossfade: move current to fade player, start new on main
	if _current_music != "":
		# Swap players for crossfade
		_music_player_fade.volume_db = _music_player.volume_db
		# In a real implementation, we'd assign the stream here:
		# _music_player_fade.stream = _music_player.stream
		# _music_player_fade.play(_music_player.get_playback_position())
		_music_player.stop()
		_crossfading = true
		_crossfade_time = 0.0

	_current_music = stream_name

	# Placeholder: In real implementation, load and play the stream:
	# var path = "res://assets/audio/music/" + stream_name + ".ogg"
	# _music_player.stream = load(path)
	# _music_player.play()
	_music_player.volume_db = linear_to_db(music_volume * master_volume)

func stop_music() -> void:
	print("[AudioManager] Music stopped")
	_current_music = ""
	_music_player.stop()
	_music_player_fade.stop()
	_crossfading = false

func play_sfx(sfx_name: String) -> void:
	if sfx_name not in _valid_sfx:
		print("[AudioManager] Unknown SFX: " + sfx_name)
		return

	print("[AudioManager] SFX: " + sfx_name)

	# Placeholder: In real implementation, load and play one-shot:
	# var path = "res://assets/audio/sfx/" + sfx_name + ".wav"
	# _sfx_player.stream = load(path)
	# _sfx_player.play()

func set_music_volume(vol: float) -> void:
	music_volume = clampf(vol, 0.0, 1.0)
	_apply_volumes()

func set_sfx_volume(vol: float) -> void:
	sfx_volume = clampf(vol, 0.0, 1.0)
	_apply_volumes()

func set_master_volume(vol: float) -> void:
	master_volume = clampf(vol, 0.0, 1.0)
	_apply_volumes()

func _apply_volumes() -> void:
	if _music_player:
		_music_player.volume_db = linear_to_db(music_volume * master_volume)
	if _music_player_fade:
		_music_player_fade.volume_db = linear_to_db(music_volume * master_volume)
	if _sfx_player:
		_sfx_player.volume_db = linear_to_db(sfx_volume * master_volume)

# ---- Integration points ----
# Call AudioManager.play_sfx("hit") when an enemy is hit
# Call AudioManager.play_sfx("kill") when an enemy dies
# Call AudioManager.play_sfx("collect_xp") when XP gem is collected
# Call AudioManager.play_sfx("collect_crystal") when crystal is collected
# Call AudioManager.play_sfx("level_up") in GameManager.add_xp() on level up
# Call AudioManager.play_sfx("evolve") when a weapon evolves
# Call AudioManager.play_sfx("boss_appear") when boss spawns
# Call AudioManager.play_sfx("dash") when player dashes
# Call AudioManager.play_sfx("player_hurt") in GameManager.take_damage()
# Call AudioManager.play_sfx("menu_click") on UI button presses
# Call AudioManager.play_music("menu") on main menu _ready
# Call AudioManager.play_music("cemetery"/"forest"/"farm") on stage start
# Call AudioManager.play_music("boss") when boss phase begins
