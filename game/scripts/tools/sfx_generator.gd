extends SceneTree

## Generates retro-style SFX as .wav files using procedural audio synthesis.
## Each sound is crafted with sine/square/noise waves, envelopes, and pitch sweeps.

const SAMPLE_RATE := 22050
const BIT_DEPTH := 16

func _init() -> void:
	DirAccess.make_dir_recursive_absolute("res://assets/audio/sfx/")

	_gen_hit()
	_gen_kill()
	_gen_collect_xp()
	_gen_level_up()
	_gen_dash()
	_gen_boss_appear()
	_gen_menu_click()
	_gen_player_hurt()
	_gen_evolve()
	_gen_game_over()

	print("All 10 SFX generated!")
	quit()

func _save_wav(samples: PackedFloat32Array, filename: String) -> void:
	var path = "res://assets/audio/sfx/%s" % filename
	var num_samples = samples.size()
	var data_size = num_samples * 2  # 16-bit = 2 bytes per sample
	var file_size = 36 + data_size

	var file = FileAccess.open(path, FileAccess.WRITE)
	if not file:
		print("ERROR: Cannot write %s" % path)
		return

	# WAV header
	file.store_string("RIFF")
	file.store_32(file_size)
	file.store_string("WAVE")

	# fmt chunk
	file.store_string("fmt ")
	file.store_32(16)           # chunk size
	file.store_16(1)            # PCM format
	file.store_16(1)            # mono
	file.store_32(SAMPLE_RATE)  # sample rate
	file.store_32(SAMPLE_RATE * 2)  # byte rate
	file.store_16(2)            # block align
	file.store_16(16)           # bits per sample

	# data chunk
	file.store_string("data")
	file.store_32(data_size)

	for s in samples:
		var clamped = clampf(s, -1.0, 1.0)
		var value = int(clamped * 32767.0)
		file.store_16(value)

	file.close()
	print("Saved: %s" % path)

# ===== OSCILLATORS =====

func _sine(phase: float) -> float:
	return sin(phase * TAU)

func _square(phase: float) -> float:
	return 1.0 if fmod(phase, 1.0) < 0.5 else -1.0

func _noise() -> float:
	return randf_range(-1.0, 1.0)

func _triangle(phase: float) -> float:
	var t = fmod(phase, 1.0)
	return 4.0 * absf(t - 0.5) - 1.0

# ===== ENVELOPES =====

func _env_decay(t: float, duration: float) -> float:
	return maxf(0.0, 1.0 - t / duration)

func _env_adsr(t: float, a: float, d: float, s: float, r: float, total: float) -> float:
	if t < a:
		return t / a
	elif t < a + d:
		return 1.0 - (1.0 - s) * ((t - a) / d)
	elif t < total - r:
		return s
	else:
		return s * maxf(0.0, 1.0 - (t - (total - r)) / r)

# ===== SFX =====

func _gen_hit() -> void:
	## Short punchy impact — square wave pitch down + noise burst
	var duration := 0.15
	var num_samples = int(duration * SAMPLE_RATE)
	var samples = PackedFloat32Array()
	samples.resize(num_samples)
	for i in range(num_samples):
		var t = float(i) / SAMPLE_RATE
		var freq = lerp(800.0, 200.0, t / duration)
		var phase = t * freq / SAMPLE_RATE * 0.5
		var osc = _square(phase) * 0.5 + _noise() * 0.3
		var env = _env_decay(t, duration)
		samples[i] = osc * env * 0.7
	_save_wav(samples, "hit.wav")

func _gen_kill() -> void:
	## Enemy death — descending tone + crunch
	var duration := 0.25
	var num_samples = int(duration * SAMPLE_RATE)
	var samples = PackedFloat32Array()
	samples.resize(num_samples)
	for i in range(num_samples):
		var t = float(i) / SAMPLE_RATE
		var freq = lerp(600.0, 80.0, t / duration)
		var phase = t * freq / SAMPLE_RATE
		var osc = _square(phase) * 0.4 + _noise() * 0.2 * _env_decay(t, 0.1)
		var env = _env_decay(t, duration)
		samples[i] = osc * env * 0.6
	_save_wav(samples, "kill.wav")

func _gen_collect_xp() -> void:
	## Collect gem — bright ascending chime
	var duration := 0.2
	var num_samples = int(duration * SAMPLE_RATE)
	var samples = PackedFloat32Array()
	samples.resize(num_samples)
	for i in range(num_samples):
		var t = float(i) / SAMPLE_RATE
		var freq = lerp(800.0, 1400.0, t / duration)
		var phase = t * freq / SAMPLE_RATE
		var osc = _sine(phase) * 0.6 + _sine(phase * 2.0) * 0.2
		var env = _env_decay(t, duration)
		samples[i] = osc * env * 0.5
	_save_wav(samples, "collect_xp.wav")

func _gen_level_up() -> void:
	## Level up — triumphant ascending arpeggio
	var duration := 0.6
	var num_samples = int(duration * SAMPLE_RATE)
	var samples = PackedFloat32Array()
	samples.resize(num_samples)
	var notes = [523.0, 659.0, 784.0, 1047.0]  # C5, E5, G5, C6
	for i in range(num_samples):
		var t = float(i) / SAMPLE_RATE
		var note_idx = mini(int(t / duration * notes.size()), notes.size() - 1)
		var freq = notes[note_idx]
		var phase = t * freq / SAMPLE_RATE
		var osc = _sine(phase) * 0.5 + _triangle(phase * 0.5) * 0.3
		var env = _env_adsr(t, 0.02, 0.1, 0.6, 0.15, duration)
		samples[i] = osc * env * 0.6
	_save_wav(samples, "level_up.wav")

func _gen_dash() -> void:
	## Dash — quick whoosh (filtered noise sweep)
	var duration := 0.15
	var num_samples = int(duration * SAMPLE_RATE)
	var samples = PackedFloat32Array()
	samples.resize(num_samples)
	for i in range(num_samples):
		var t = float(i) / SAMPLE_RATE
		var n = _noise()
		# Simple low-pass by averaging with previous
		var cutoff = lerp(0.8, 0.1, t / duration)
		var env = _env_decay(t, duration)
		samples[i] = n * cutoff * env * 0.5
	_save_wav(samples, "dash.wav")

func _gen_boss_appear() -> void:
	## Boss appear — deep ominous horn + rumble
	var duration := 1.5
	var num_samples = int(duration * SAMPLE_RATE)
	var samples = PackedFloat32Array()
	samples.resize(num_samples)
	for i in range(num_samples):
		var t = float(i) / SAMPLE_RATE
		var freq = 80.0 + sin(t * 2.0) * 10.0  # Wobbling low tone
		var phase = t * freq / SAMPLE_RATE
		var osc = _sine(phase) * 0.5 + _square(phase * 0.5) * 0.2 + _noise() * 0.1
		var env = _env_adsr(t, 0.3, 0.3, 0.7, 0.4, duration)
		samples[i] = osc * env * 0.7
	_save_wav(samples, "boss_appear.wav")

func _gen_menu_click() -> void:
	## Menu click — short crisp tick
	var duration := 0.06
	var num_samples = int(duration * SAMPLE_RATE)
	var samples = PackedFloat32Array()
	samples.resize(num_samples)
	for i in range(num_samples):
		var t = float(i) / SAMPLE_RATE
		var freq = 1200.0
		var phase = t * freq / SAMPLE_RATE
		var osc = _sine(phase) * 0.6 + _square(phase * 2.0) * 0.2
		var env = _env_decay(t, duration)
		samples[i] = osc * env * 0.4
	_save_wav(samples, "menu_click.wav")

func _gen_player_hurt() -> void:
	## Player hurt — distorted buzz + low thud
	var duration := 0.3
	var num_samples = int(duration * SAMPLE_RATE)
	var samples = PackedFloat32Array()
	samples.resize(num_samples)
	for i in range(num_samples):
		var t = float(i) / SAMPLE_RATE
		var freq = lerp(300.0, 100.0, t / duration)
		var phase = t * freq / SAMPLE_RATE
		var osc = _square(phase) * 0.4 + _noise() * 0.3
		# Distortion
		osc = clampf(osc * 2.0, -1.0, 1.0)
		var env = _env_decay(t, duration)
		samples[i] = osc * env * 0.5
	_save_wav(samples, "player_hurt.wav")

func _gen_evolve() -> void:
	## Weapon evolve — magical ascending sparkle cascade
	var duration := 1.0
	var num_samples = int(duration * SAMPLE_RATE)
	var samples = PackedFloat32Array()
	samples.resize(num_samples)
	for i in range(num_samples):
		var t = float(i) / SAMPLE_RATE
		var freq = lerp(400.0, 2000.0, t / duration)
		var phase = t * freq / SAMPLE_RATE
		# Shimmering harmonics
		var osc = _sine(phase) * 0.3 + _sine(phase * 1.5) * 0.2 + _sine(phase * 2.0) * 0.15
		# Sparkle (random high pings)
		if randf() < 0.02:
			osc += _sine(phase * 4.0) * 0.3
		var env = _env_adsr(t, 0.05, 0.2, 0.5, 0.3, duration)
		samples[i] = osc * env * 0.6
	_save_wav(samples, "evolve.wav")

func _gen_game_over() -> void:
	## Game over — sad descending melody + fade
	var duration := 1.5
	var num_samples = int(duration * SAMPLE_RATE)
	var samples = PackedFloat32Array()
	samples.resize(num_samples)
	var notes = [523.0, 493.0, 440.0, 349.0, 261.0]  # C5, B4, A4, F4, C4 (descending sad)
	for i in range(num_samples):
		var t = float(i) / SAMPLE_RATE
		var note_idx = mini(int(t / duration * notes.size()), notes.size() - 1)
		var freq = notes[note_idx]
		var phase = t * freq / SAMPLE_RATE
		var osc = _sine(phase) * 0.5 + _triangle(phase * 0.5) * 0.2
		var env = _env_adsr(t, 0.05, 0.2, 0.4, 0.5, duration)
		samples[i] = osc * env * 0.5
	_save_wav(samples, "game_over.wav")
