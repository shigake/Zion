extends Node

## Gerenciador de audio global: musica e efeitos sonoros.
## Tenta carregar arquivos de audio reais de res://assets/audio/.
## Se os arquivos nao existirem, imprime log e continua sem crash.

# Volume properties (0.0 - 1.0)
var music_volume: float = 0.5
var sfx_volume: float = 0.6
var master_volume: float = 0.7

# Audio players (created in _ready)
var _music_player: AudioStreamPlayer
var _music_player_fade: AudioStreamPlayer  # For crossfade

# SFX player pool for simultaneous sounds
var _sfx_players: Array[AudioStreamPlayer] = []
const SFX_POOL_SIZE: int = 5

# Known SFX names
var _valid_sfx: Array[String] = [
	"hit", "kill", "collect_xp", "collect_crystal", "level_up",
	"evolve", "boss_appear", "dash", "player_hurt", "menu_click",
	"boomerang", "tornado", "chain_whip", "blood_orb",
	"sword_slash", "axe_chop", "scythe_swoosh", "whip_crack",
	"hammer_slam", "lance_thrust", "punch_hit", "gun_shot",
	"bow_release", "magic_cast", "explosion", "electric_zap",
	"poison_splash", "summon_pop", "heal", "achievement",
	"reroll", "banish", "select", "boss_roar", "boss_death",
	"enemy_growl", "chest_open", "portal_hum", "boss_attack",
	"boss_phase", "equip", "error", "footstep",
	"fire_whoosh", "game_over", "lava_bubble", "wind"
]

# Known music names
var _valid_music: Array[String] = [
	"menu", "cemetery", "forest", "farm", "boss",
	"tokyo", "volcano", "ocean", "arena", "space", "castle", "candy",
	"victory", "shop", "lobby", "game_over_music"
]

# Current music track
var _current_music: String = ""

# Crossfade
var _crossfade_duration: float = 1.0
var _crossfading: bool = false
var _crossfade_time: float = 0.0

# SFX cooldown tracking: sfx_name -> last play time (msec)
var _sfx_last_played: Dictionary = {}
const SFX_COOLDOWN_MS: int = 50  # 0.05 seconds minimum between same SFX

# Audio file cache to avoid repeated load attempts
var _audio_cache: Dictionary = {}  # path -> AudioStream or null

func _ready() -> void:
	_music_player = AudioStreamPlayer.new()
	_music_player.name = "MusicPlayer"
	_music_player.bus = "Master"
	add_child(_music_player)

	_music_player_fade = AudioStreamPlayer.new()
	_music_player_fade.name = "MusicPlayerFade"
	_music_player_fade.bus = "Master"
	add_child(_music_player_fade)

	# Create SFX player pool
	for i in range(SFX_POOL_SIZE):
		var player = AudioStreamPlayer.new()
		player.name = "SFXPlayer_%d" % i
		player.bus = "Master"
		add_child(player)
		_sfx_players.append(player)

	_apply_volumes()
	# Connect boss phase signal for dynamic music intensity
	GameManager.boss_phase_changed.connect(_on_boss_phase_changed)
	GameManager.boss_died.connect(_on_boss_died_music)

func _on_boss_phase_changed(_boss_name: String, phase: int) -> void:
	set_boss_phase_intensity(phase)

func _on_boss_died_music(_boss_name: String) -> void:
	reset_music_intensity()
	# Volta para a musica da fenda apos boss morrer
	if GameManager.selected_stage and not GameManager.selected_stage.is_empty():
		play_music(GameManager.selected_stage)

func _process(delta: float) -> void:
	if _crossfading:
		_crossfade_time += delta
		var t = clampf(_crossfade_time / _crossfade_duration, 0.0, 1.0)
		var vol = music_volume * master_volume
		_music_player_fade.volume_db = linear_to_db(maxf((1.0 - t) * vol, 0.0001))
		_music_player.volume_db = linear_to_db(maxf(t * vol, 0.0001))
		if t >= 1.0:
			_crossfading = false
			_music_player_fade.stop()
			_music_player_fade.stream = null
	# Intensificacao temporal da musica da fenda
	_update_stage_music_intensity()

func play_music(stream_name: String) -> void:
	if stream_name == _current_music:
		return
	if stream_name not in _valid_music:
		LogManager.warn("Audio", "Unknown music: " + stream_name)
		return

	# Try to load the audio file
	var stream = _load_audio("res://assets/audio/music/" + stream_name, [".ogg", ".mp3", ".wav"])
	if stream == null:
		LogManager.debug("Audio", "Music (no file): " + stream_name)
		_current_music = stream_name
		return

	# Crossfade: move current stream to fade player, start new on main
	if _music_player.playing:
		_music_player_fade.stream = _music_player.stream
		_music_player_fade.volume_db = _music_player.volume_db
		_music_player_fade.play(_music_player.get_playback_position())
		_music_player.stop()
		_crossfading = true
		_crossfade_time = 0.0
		_music_player.volume_db = linear_to_db(0.0001)
	else:
		_music_player.volume_db = linear_to_db(music_volume * master_volume)

	_current_music = stream_name
	# Enable looping for music (set on stream AND use finished signal as fallback)
	if stream is AudioStreamMP3:
		stream.loop = true
	elif stream is AudioStreamOggVorbis:
		stream.loop = true
	elif stream is AudioStreamWAV:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_end = stream.mix_rate * int(stream.get_length())
	_music_player.stream = stream
	_music_player.play()
	# Fallback loop: if stream.loop doesn't work (import override), restart on finish
	if not _music_player.finished.is_connected(_on_music_finished):
		_music_player.finished.connect(_on_music_finished)
	LogManager.info("Audio", "Music: " + stream_name)

func _on_music_finished() -> void:
	# Fallback loop: restart music if it ended (import loop=false override)
	if _music_player.stream and not _current_music.is_empty():
		_music_player.play()

func stop_music() -> void:
	LogManager.info("Audio", "Music stopped")
	_current_music = ""
	_music_player.stop()
	_music_player.stream = null
	_music_player_fade.stop()
	_music_player_fade.stream = null
	_crossfading = false

func play_sfx(sfx_name: String) -> void:
	if sfx_name not in _valid_sfx:
		LogManager.warn("Audio", "Unknown SFX: " + sfx_name)
		return

	# Cooldown check: prevent same SFX spamming
	var now_ms = Time.get_ticks_msec()
	if sfx_name in _sfx_last_played:
		var elapsed = now_ms - _sfx_last_played[sfx_name]
		if elapsed < SFX_COOLDOWN_MS:
			return
	_sfx_last_played[sfx_name] = now_ms

	# Try to load the audio file
	var stream = _load_audio("res://assets/audio/sfx/" + sfx_name, [".wav", ".ogg", ".mp3"])
	if stream == null:
		LogManager.debug("Audio", "SFX (no file): " + sfx_name)
		return

	# Find an available SFX player from the pool
	var player = _get_available_sfx_player()
	if player == null:
		return  # All players busy, skip this SFX

	player.stream = stream
	player.volume_db = linear_to_db(maxf(sfx_volume * master_volume, 0.0001))
	player.play()
	if not player.playing:
		push_warning("[Audio] SFX player NOT playing after play() call: %s (vol_db=%.1f)" % [sfx_name, player.volume_db])

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
	var mvol = maxf(music_volume * master_volume, 0.0001)
	if _music_player and not _crossfading:
		_music_player.volume_db = linear_to_db(mvol)
	if _music_player_fade and not _crossfading:
		_music_player_fade.volume_db = linear_to_db(mvol)
	var svol = maxf(sfx_volume * master_volume, 0.0001)
	for player in _sfx_players:
		if player:
			player.volume_db = linear_to_db(svol)

func _get_available_sfx_player() -> AudioStreamPlayer:
	# Find a player that is not currently playing
	for player in _sfx_players:
		if not player.playing:
			return player
	# All busy - return the first one (will interrupt oldest sound)
	return _sfx_players[0]

func _load_audio(base_path: String, extensions: Array) -> AudioStream:
	# Check cache first (skip null entries to retry on next call)
	if base_path in _audio_cache and _audio_cache[base_path] != null:
		return _audio_cache[base_path]

	# Determine subdirectories to search based on path type
	var subdirs: Array[String] = [""]
	if "audio/sfx/" in base_path:
		subdirs = ["", "combat/", "player/", "pickup/", "ui/", "enemies/", "boss/", "environment/"]
	elif "audio/music/" in base_path:
		subdirs = ["", "stages/", "menu/", "boss/"]

	# Extract the filename from the base_path
	var filename = base_path.get_file()
	var dir_path = base_path.get_base_dir()

	# Try each subdirectory and extension combination
	for subdir in subdirs:
		for ext in extensions:
			var path: String
			if subdir == "":
				path = base_path + ext
			else:
				path = dir_path + "/" + subdir + filename + ext
			if ResourceLoader.exists(path):
				var stream = load(path)
				if stream is AudioStream:
					_audio_cache[base_path] = stream
					return stream

	# No file found - cache null to avoid repeated lookups
	_audio_cache[base_path] = null
	return null

## Boss phase music intensity — increases pitch and volume at higher phases
func set_boss_phase_intensity(phase: int) -> void:
	if not _music_player or not _music_player.playing:
		return
	if _current_music != "boss":
		return
	# Phase 1: normal, Phase 2: slightly faster/louder, Phase 3: intense
	match phase:
		1:
			_music_player.pitch_scale = 1.0
			_apply_volumes()
		2:
			_music_player.pitch_scale = 1.08
			# Slight volume boost
			var vol = minf(music_volume * master_volume * 1.15, 1.0)
			_music_player.volume_db = linear_to_db(maxf(vol, 0.0001))
		3:
			_music_player.pitch_scale = 1.18
			# More volume boost
			var vol = minf(music_volume * master_volume * 1.3, 1.0)
			_music_player.volume_db = linear_to_db(maxf(vol, 0.0001))
		_:
			# Fury mode (phase 4+)
			_music_player.pitch_scale = 1.25
			var vol = minf(music_volume * master_volume * 1.4, 1.0)
			_music_player.volume_db = linear_to_db(maxf(vol, 0.0001))

## Reset boss music intensity (called on boss death / stage end)
func reset_music_intensity() -> void:
	if _music_player:
		_music_player.pitch_scale = 1.0
		_apply_volumes()

## Intensificacao gradual da musica da fenda conforme o tempo avanca
func _update_stage_music_intensity() -> void:
	if not _music_player or not _music_player.playing:
		return
	# Nao escala tracks de UI/boss/victory
	if _current_music in ["menu", "lobby", "boss", "victory", "shop", "game_over_music"]:
		return
	var time_factor = clampf(GameManager.game_time / 900.0, 0.0, 1.0)
	_music_player.pitch_scale = 1.0 + time_factor * 0.12

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
