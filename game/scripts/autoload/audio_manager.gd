extends Node

## Gerenciador de audio global: musica e efeitos sonoros.
## Tenta carregar arquivos de audio reais de res://assets/audio/.
## Se os arquivos nao existirem, imprime log e continua sem crash.

# Volume properties (0.0 - 1.0)
var music_volume: float = 0.5
var sfx_volume: float = 0.6
var master_volume: float = 0.7

var combat_volume: float = 1.0:
	set(v):
		combat_volume = v
		_apply_bus_volume("Combat", v)

var ambient_volume: float = 1.0:
	set(v):
		ambient_volume = v
		_apply_bus_volume("Ambient", v)

# Audio players (created in _ready)
var _music_player: AudioStreamPlayer
var _music_player_fade: AudioStreamPlayer  # For crossfade

# SFX player pool for simultaneous sounds
var _sfx_players: Array[AudioStreamPlayer] = []
const SFX_POOL_SIZE: int = 12

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

# --- Dynamic Audio Balancing (PRD 28 §2) ---

# SFX category mapping: sfx_name -> bus name
var _sfx_categories: Dictionary = {
	"hit": "Combat", "slash": "Combat", "explosion": "Combat", "shoot": "Combat",
	"arrow": "Combat", "fireball": "Combat", "lightning": "Combat", "boss_roar": "Combat",
	"sword_slash": "Combat", "axe_chop": "Combat", "scythe_swoosh": "Combat",
	"whip_crack": "Combat", "hammer_slam": "Combat", "lance_thrust": "Combat",
	"punch_hit": "Combat", "gun_shot": "Combat", "bow_release": "Combat",
	"magic_cast": "Combat", "electric_zap": "Combat", "poison_splash": "Combat",
	"boss_attack": "Combat", "boss_phase": "Combat", "boss_death": "Combat",
	"enemy_growl": "Combat", "fire_whoosh": "Combat", "kill": "Combat",
	"boomerang": "Combat", "tornado": "Combat", "chain_whip": "Combat",
	"blood_orb": "Combat", "summon_pop": "Combat",
	"click": "UI_Audio", "hover": "UI_Audio", "level_up": "UI_Audio", "menu": "UI_Audio",
	"menu_click": "UI_Audio", "select": "UI_Audio", "reroll": "UI_Audio",
	"banish": "UI_Audio", "equip": "UI_Audio", "error": "UI_Audio",
	"achievement": "UI_Audio", "evolve": "UI_Audio",
	"crystal": "Pickup", "xp_collect": "Pickup", "item_pickup": "Pickup",
	"chest_open": "Pickup", "collect_xp": "Pickup", "collect_crystal": "Pickup",
	"heal": "Pickup", "portal_hum": "Pickup",
	"ambient": "Ambient", "wind": "Ambient", "water": "Ambient",
	"lava_bubble": "Ambient", "footstep": "Ambient",
}

# Limits per category (max simultaneous sounds)
var _category_limits: Dictionary = {
	"Combat": 8,
	"UI_Audio": 2,
	"Pickup": 4,
	"Ambient": 2,
	"Voice": 1,
}

var _category_active_count: Dictionary = {}
var _category_cooldowns: Dictionary = {}
const CATEGORY_COOLDOWN_MS: int = 30

# Ducking system
var _ducking_active: bool = false
var _ducking_tween: Tween = null
var _ducking_enabled: bool = true  # User setting

# Duck priority enum and stack system
enum DuckPriority { NONE, LEVEL_UP, BOSS_SFX, CINEMATIC, VOICE }

var _duck_stack: Array[Dictionary] = []  # {priority, music_db, sfx_db, duration}
var _current_duck_priority: int = 0  # DuckPriority value

# Distance-based attenuation
const ATTENUATION_RADIUS: float = 15.0

func _ready() -> void:
	_setup_buses()

	_music_player = AudioStreamPlayer.new()
	_music_player.name = "MusicPlayer"
	_music_player.bus = "Music"
	add_child(_music_player)

	_music_player_fade = AudioStreamPlayer.new()
	_music_player_fade.name = "MusicPlayerFade"
	_music_player_fade.bus = "Music"
	add_child(_music_player_fade)

	# Create SFX player pool
	for i in range(SFX_POOL_SIZE):
		var player = AudioStreamPlayer.new()
		player.name = "SFXPlayer_%d" % i
		player.bus = "SFX"
		add_child(player)
		_sfx_players.append(player)

	# Initialize category active counts
	for cat in _category_limits:
		_category_active_count[cat] = 0

	_apply_volumes()
	# Connect boss phase signal for dynamic music intensity
	GameManager.boss_phase_changed.connect(_on_boss_phase_changed)
	GameManager.boss_died.connect(_on_boss_died_music)
	# Music ducking during important events (PRD 28 §2)
	GameManager.player_leveled_up.connect(_on_level_up_ducking)
	GameManager.boss_spawned.connect(_on_boss_spawned_ducking)

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

func play_sfx(sfx_name: String, volume_mult: float = 1.0) -> void:
	if sfx_name not in _valid_sfx:
		LogManager.warn("Audio", "Unknown SFX: " + sfx_name)
		return

	# Determine category for this SFX
	var category: String = _sfx_categories.get(sfx_name, "SFX")

	# Per-category cooldown check
	var now_ms = Time.get_ticks_msec()
	var cooldown_key = sfx_name + "_" + category
	if cooldown_key in _category_cooldowns:
		var elapsed = now_ms - _category_cooldowns[cooldown_key]
		if elapsed < CATEGORY_COOLDOWN_MS:
			return

	# Legacy cooldown check: prevent same SFX spamming
	if sfx_name in _sfx_last_played:
		var elapsed = now_ms - _sfx_last_played[sfx_name]
		if elapsed < SFX_COOLDOWN_MS:
			return
	_sfx_last_played[sfx_name] = now_ms
	_category_cooldowns[cooldown_key] = now_ms

	# Category limit check
	if category in _category_limits:
		var active = _count_active_in_category(category)
		if active >= _category_limits[category]:
			return  # Too many sounds in this category

	# Hit sound volume normalization — prevent clipping when many enemies die at once
	var _hit_sfx_names = ["hit", "kill", "sword_slash", "axe_chop", "scythe_swoosh",
		"whip_crack", "hammer_slam", "lance_thrust", "punch_hit", "gun_shot",
		"bow_release", "explosion", "electric_zap"]
	if sfx_name in _hit_sfx_names:
		volume_mult *= _get_hit_volume_multiplier()

	# Try to load the audio file
	var stream = _load_audio("res://assets/audio/sfx/" + sfx_name, [".wav", ".ogg", ".mp3"])
	if stream == null:
		LogManager.debug("Audio", "SFX (no file): " + sfx_name)
		return

	# Find an available SFX player from the pool
	var player = _get_available_sfx_player()
	if player == null:
		return  # All players busy, skip this SFX

	# Assign the correct bus for this category
	player.bus = category if AudioServer.get_bus_index(category) != -1 else "SFX"
	player.stream = stream
	player.volume_db = linear_to_db(maxf(sfx_volume * master_volume * volume_mult, 0.0001))
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

# ---- Bus Setup (PRD 28 §2) ----

func _setup_buses() -> void:
	## Create audio bus hierarchy: Master -> Music, SFX (Combat, UI_Audio, Pickup, Ambient), Voice
	var bus_config = {
		"Music": {"parent": "Master", "volume_db": -6.0},
		"SFX": {"parent": "Master", "volume_db": 0.0},
		"Combat": {"parent": "SFX", "volume_db": 0.0},
		"UI_Audio": {"parent": "SFX", "volume_db": 0.0},
		"Pickup": {"parent": "SFX", "volume_db": 0.0},
		"Ambient": {"parent": "SFX", "volume_db": 0.0},
		"Voice": {"parent": "Master", "volume_db": 0.0},
	}
	for bus_name in bus_config:
		var idx = AudioServer.get_bus_index(bus_name)
		if idx == -1:
			AudioServer.add_bus()
			idx = AudioServer.bus_count - 1
			AudioServer.set_bus_name(idx, bus_name)
		AudioServer.set_bus_send(idx, bus_config[bus_name]["parent"])
		AudioServer.set_bus_volume_db(idx, bus_config[bus_name]["volume_db"])
	# Add a limiter effect to the Combat bus to prevent clipping
	var combat_idx = AudioServer.get_bus_index("Combat")
	if combat_idx != -1:
		var limiter = AudioEffectLimiter.new()
		limiter.ceiling_db = -1.0
		limiter.threshold_db = -6.0
		limiter.soft_clip_db = 2.0
		AudioServer.add_bus_effect(combat_idx, limiter)
	# Add a limiter to the SFX bus as a safety net
	var sfx_idx = AudioServer.get_bus_index("SFX")
	if sfx_idx != -1:
		var sfx_limiter = AudioEffectLimiter.new()
		sfx_limiter.ceiling_db = -0.5
		sfx_limiter.threshold_db = -3.0
		sfx_limiter.soft_clip_db = 2.0
		AudioServer.add_bus_effect(sfx_idx, sfx_limiter)
	# Master compressor to prevent clipping
	var master_idx = AudioServer.get_bus_index("Master")
	if master_idx != -1:
		var compressor = AudioEffectCompressor.new()
		compressor.threshold = GameConstants.MASTER_COMPRESSOR_THRESHOLD
		compressor.ratio = GameConstants.MASTER_COMPRESSOR_RATIO
		compressor.attack_us = GameConstants.MASTER_COMPRESSOR_ATTACK_US
		compressor.release_ms = GameConstants.MASTER_COMPRESSOR_RELEASE_MS
		compressor.gain = 0.0
		AudioServer.add_bus_effect(master_idx, compressor)
	LogManager.info("Audio", "Audio buses configured: %d total (with limiters + compressor)" % AudioServer.bus_count)

func _apply_bus_volume(bus_name: String, volume: float) -> void:
	var idx = AudioServer.get_bus_index(bus_name)
	if idx != -1:
		AudioServer.set_bus_volume_db(idx, linear_to_db(maxf(volume, 0.0001)))

func _count_active_in_category(category: String) -> int:
	var count := 0
	for player in _sfx_players:
		if player.playing and player.bus == category:
			count += 1
	return count

# ---- Ducking System (PRD 28 §2 + PRD 38 stack-based) ----

func push_duck(priority: int, music_db: float, sfx_db: float, duration: float = 0.0) -> void:
	_duck_stack.append({"priority": priority, "music_db": music_db, "sfx_db": sfx_db})
	_apply_highest_duck()
	if duration > 0:
		get_tree().create_timer(duration).timeout.connect(func(): pop_duck(priority))

func pop_duck(priority: int) -> void:
	for i in range(_duck_stack.size() - 1, -1, -1):
		if _duck_stack[i]["priority"] == priority:
			_duck_stack.remove_at(i)
			break
	_apply_highest_duck()

func _apply_highest_duck() -> void:
	if _duck_stack.is_empty():
		# Restore to normal
		_restore_bus_volume("Music", -6.0, GameConstants.DUCK_RESTORE_TIME)
		_restore_bus_volume("SFX", 0.0, GameConstants.DUCK_RESTORE_TIME)
		_current_duck_priority = 0
		_ducking_active = false
		return

	# Find highest priority entry
	var highest = _duck_stack[0]
	for entry in _duck_stack:
		if entry["priority"] > highest["priority"]:
			highest = entry

	_current_duck_priority = highest["priority"]
	_ducking_active = true
	_duck_bus("Music", highest["music_db"], GameConstants.DUCK_TRANSITION_TIME)
	if highest["sfx_db"] != 0.0:
		_duck_bus("SFX", highest["sfx_db"], GameConstants.DUCK_TRANSITION_TIME)

func _duck_bus(bus_name: String, target_db: float, duration: float) -> void:
	var idx = AudioServer.get_bus_index(bus_name)
	if idx == -1:
		return
	var current_db = AudioServer.get_bus_volume_db(idx)
	var tween = create_tween()
	tween.tween_method(func(db): AudioServer.set_bus_volume_db(idx, db), current_db, target_db, duration)

func _restore_bus_volume(bus_name: String, target_db: float, duration: float) -> void:
	var idx = AudioServer.get_bus_index(bus_name)
	if idx == -1:
		return
	var current_db = AudioServer.get_bus_volume_db(idx)
	var tween = create_tween()
	tween.tween_method(func(db): AudioServer.set_bus_volume_db(idx, db), current_db, target_db, duration)

# Backwards-compatible wrappers for existing callers
func start_ducking(reason: String = "voice") -> void:
	if not _ducking_enabled:
		return
	push_duck(DuckPriority.VOICE, -18.0, 0.0)
	LogManager.debug("Audio", "Ducking started: " + reason)

func stop_ducking() -> void:
	pop_duck(DuckPriority.VOICE)
	LogManager.debug("Audio", "Ducking stopped")

# ---- Music Ducking Triggers (PRD 28 §2) ----

func _on_level_up_ducking(_new_level: int) -> void:
	push_duck(DuckPriority.LEVEL_UP, -18.0, 0.0, 2.0)

func _on_boss_spawned_ducking(_boss_name: String) -> void:
	push_duck(DuckPriority.BOSS_SFX, GameConstants.DUCK_BOSS_AMBIENT_DB, 0.0, 3.0)

# ---- Hit Sound Volume Normalization (PRD 28 §2) ----
# When many hits happen in quick succession, reduce volume of subsequent hits
# to prevent audio clipping and ear fatigue.

var _hit_sfx_count: int = 0  # Number of hit SFX in current normalization window
var _hit_sfx_window_start: int = 0  # Start of current window (msec)
const HIT_NORMALIZATION_WINDOW_MS: int = 200  # 200ms window
const HIT_NORMALIZATION_MAX: int = 4  # After this many hits in window, start reducing
const HIT_NORMALIZATION_MIN_MULT: float = 0.3  # Minimum volume multiplier for normalized hits

func _get_hit_volume_multiplier() -> float:
	var now_ms = Time.get_ticks_msec()
	if now_ms - _hit_sfx_window_start > HIT_NORMALIZATION_WINDOW_MS:
		# New window
		_hit_sfx_window_start = now_ms
		_hit_sfx_count = 0
	_hit_sfx_count += 1
	if _hit_sfx_count <= HIT_NORMALIZATION_MAX:
		return 1.0
	# Gradually reduce volume for excess hits
	var excess = _hit_sfx_count - HIT_NORMALIZATION_MAX
	var mult = maxf(1.0 - (excess * 0.15), HIT_NORMALIZATION_MIN_MULT)
	return mult

# ---- Distance-based Attenuation (PRD 28 §2) ----

func play_sfx_at_position(sfx_name: String, world_pos: Vector3, is_local_player: bool = true) -> void:
	if is_local_player:
		play_sfx(sfx_name)
		return
	# Attenuate based on distance to local player
	var local_player = GameManager.get_local_player()
	if not local_player:
		play_sfx(sfx_name)
		return
	var distance = local_player.global_position.distance_to(world_pos)
	if distance > ATTENUATION_RADIUS:
		return  # Too far, don't play
	var volume_mult = 1.0 - (distance / ATTENUATION_RADIUS)
	play_sfx(sfx_name, volume_mult)

# ---- Dynamic Volume Based on Enemy Count (PRD 38) ----

func get_enemy_volume_modifier() -> float:
	var enemy_count = GameManager.enemies_alive
	if enemy_count <= GameConstants.AUDIO_ENEMY_THRESHOLD_LOW:
		return 0.0
	elif enemy_count <= GameConstants.AUDIO_ENEMY_THRESHOLD_MED:
		return GameConstants.AUDIO_ENEMY_DUCK_LOW
	elif enemy_count <= GameConstants.AUDIO_ENEMY_THRESHOLD_HIGH:
		return GameConstants.AUDIO_ENEMY_DUCK_MED
	else:
		return GameConstants.AUDIO_ENEMY_DUCK_HIGH

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
