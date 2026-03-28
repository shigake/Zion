extends SceneTree

## SFX Generator v2 — richer, multi-layered retro sound effects.
## Each SFX uses layered oscillators, proper ADSR, pitch sweeps, and filtering.

const SR := 44100  # Higher sample rate for better quality
const TWO_PI := TAU

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
	print("All 10 SFX v2 generated!")
	quit()

# ===== CORE =====

func _save(samples: PackedFloat32Array, filename: String) -> void:
	# Normalize to prevent clipping
	var peak := 0.0
	for s in samples:
		peak = maxf(peak, absf(s))
	if peak > 0.01:
		var gain = 0.85 / peak
		for i in range(samples.size()):
			samples[i] *= gain

	var path = "res://assets/audio/sfx/%s" % filename
	var n = samples.size()
	var file = FileAccess.open(path, FileAccess.WRITE)
	file.store_string("RIFF")
	file.store_32(36 + n * 2)
	file.store_string("WAVE")
	file.store_string("fmt ")
	file.store_32(16)
	file.store_16(1)
	file.store_16(1)
	file.store_32(SR)
	file.store_32(SR * 2)
	file.store_16(2)
	file.store_16(16)
	file.store_string("data")
	file.store_32(n * 2)
	for s in samples:
		file.store_16(int(clampf(s, -1.0, 1.0) * 32767.0))
	file.close()
	print("Saved: %s" % path)

func _sin(t: float, freq: float) -> float:
	return sin(t * freq * TWO_PI)

func _sq(t: float, freq: float) -> float:
	return 1.0 if fmod(t * freq, 1.0) < 0.5 else -1.0

func _tri(t: float, freq: float) -> float:
	return 4.0 * absf(fmod(t * freq, 1.0) - 0.5) - 1.0

func _noise() -> float:
	return randf_range(-1.0, 1.0)

func _env(t: float, a: float, d: float, s: float, r: float, dur: float) -> float:
	if t < a: return t / a
	if t < a + d: return 1.0 - (1.0 - s) * ((t - a) / d)
	if t < dur - r: return s
	return s * maxf(0.0, (dur - t) / r)

func _decay(t: float, dur: float) -> float:
	return maxf(0.0, 1.0 - t / dur)

func _make(dur: float) -> PackedFloat32Array:
	var s = PackedFloat32Array()
	s.resize(int(dur * SR))
	return s

# ===== SFX =====

func _gen_hit() -> void:
	## Meaty impact: layered thud + crack + ring
	var dur := 0.18
	var samples = _make(dur)
	for i in range(samples.size()):
		var t = float(i) / SR
		var p = t / dur
		# Low thud
		var thud = _sin(t, lerp(200.0, 60.0, p)) * 0.6 * _decay(t, 0.12)
		# Mid crack
		var crack = _sq(t, lerp(800.0, 300.0, p)) * 0.25 * _decay(t, 0.06)
		# Noise burst
		var burst = _noise() * 0.3 * _decay(t, 0.04)
		# Metal ring
		var ring = _sin(t, 1200.0) * 0.08 * _decay(t, 0.15)
		samples[i] = thud + crack + burst + ring
	_save(samples, "hit.wav")

func _gen_kill() -> void:
	## Satisfying pop + descend + sparkle
	var dur := 0.3
	var samples = _make(dur)
	for i in range(samples.size()):
		var t = float(i) / SR
		var p = t / dur
		# Pop
		var pop = _sin(t, lerp(600.0, 100.0, p * 2.0)) * 0.5 * _decay(t, 0.08)
		# Descending body
		var body = _tri(t, lerp(400.0, 80.0, p)) * 0.3 * _decay(t, 0.25)
		# Sparkle overtones
		var spark = _sin(t, lerp(1500.0, 800.0, p)) * 0.12 * _decay(t, 0.15)
		# Crunch
		var crunch = _noise() * 0.15 * _decay(t, 0.05)
		samples[i] = pop + body + spark + crunch
	_save(samples, "kill.wav")

func _gen_collect_xp() -> void:
	## Bright coin chime: two-note arpeggio with harmonics
	var dur := 0.25
	var samples = _make(dur)
	for i in range(samples.size()):
		var t = float(i) / SR
		# Note 1 (E6) then Note 2 (C7)
		var freq = 1318.0 if t < 0.1 else 2093.0
		var env_val = _env(t, 0.005, 0.05, 0.3, 0.1, dur)
		var tone = _sin(t, freq) * 0.4 + _sin(t, freq * 2.0) * 0.15 + _sin(t, freq * 3.0) * 0.05
		samples[i] = tone * env_val
	_save(samples, "collect_xp.wav")

func _gen_level_up() -> void:
	## Triumphant arpeggio: C-E-G-C with shimmer
	var dur := 0.7
	var samples = _make(dur)
	var notes = [523.0, 659.0, 784.0, 1047.0]  # C5 E5 G5 C6
	for i in range(samples.size()):
		var t = float(i) / SR
		var p = t / dur
		var note_idx = mini(int(p * 4.0), 3)
		var freq = notes[note_idx]
		var note_t = t - (note_idx * dur / 4.0)
		var env_val = _env(note_t, 0.01, 0.08, 0.5, 0.08, dur / 4.0)
		# Rich tone
		var tone = _sin(t, freq) * 0.35
		tone += _tri(t, freq) * 0.15
		tone += _sin(t, freq * 2.0) * 0.1
		# Shimmer
		tone += _sin(t, freq * 3.01) * 0.05 * sin(t * 12.0)
		samples[i] = tone * env_val
	_save(samples, "level_up.wav")

func _gen_dash() -> void:
	## Fast whoosh: filtered noise with pitch sweep
	var dur := 0.12
	var samples = _make(dur)
	var prev := 0.0
	for i in range(samples.size()):
		var t = float(i) / SR
		var p = t / dur
		# Shaped noise
		var n = _noise()
		# Simple low-pass (lerp with previous)
		var cutoff = lerp(0.9, 0.2, p)
		var filtered = prev + cutoff * (n - prev)
		prev = filtered
		# Add subtle wind tone
		var wind = _sin(t, lerp(400.0, 150.0, p)) * 0.15
		var env_val = sin(p * PI)  # Bell curve envelope
		samples[i] = (filtered * 0.6 + wind) * env_val
	_save(samples, "dash.wav")

func _gen_boss_appear() -> void:
	## Ominous: deep horn + sub rumble + reverse cymbal feel
	var dur := 2.0
	var samples = _make(dur)
	for i in range(samples.size()):
		var t = float(i) / SR
		var p = t / dur
		# Deep horn (wobble)
		var horn_freq = 65.0 + sin(t * 3.0) * 8.0
		var horn = _sin(t, horn_freq) * 0.3 + _sq(t, horn_freq * 0.5) * 0.1
		# Sub rumble
		var sub = _sin(t, 35.0 + sin(t * 1.5) * 5.0) * 0.25
		# Rising tension
		var rise = _sin(t, lerp(100.0, 300.0, p * p)) * 0.15 * p
		# Noise swell
		var noise_swell = _noise() * 0.08 * p * p
		var env_val = _env(t, 0.5, 0.3, 0.7, 0.5, dur)
		samples[i] = (horn + sub + rise + noise_swell) * env_val
	_save(samples, "boss_appear.wav")

func _gen_menu_click() -> void:
	## Crisp UI click: short pluck with body
	var dur := 0.08
	var samples = _make(dur)
	for i in range(samples.size()):
		var t = float(i) / SR
		# Sharp attack
		var click = _sin(t, 1800.0) * 0.4 * _decay(t, 0.02)
		# Body
		var body = _sin(t, 900.0) * 0.3 * _decay(t, 0.06)
		# Sub
		var sub = _sin(t, 300.0) * 0.15 * _decay(t, 0.04)
		samples[i] = click + body + sub
	_save(samples, "menu_click.wav")

func _gen_player_hurt() -> void:
	## Pain: distorted buzz + low impact + crackle
	var dur := 0.35
	var samples = _make(dur)
	for i in range(samples.size()):
		var t = float(i) / SR
		var p = t / dur
		# Distorted buzz
		var buzz = _sq(t, lerp(250.0, 80.0, p)) * 0.4
		buzz = clampf(buzz * 3.0, -1.0, 1.0) * 0.35  # Hard clip distortion
		# Low impact
		var impact = _sin(t, lerp(150.0, 40.0, p)) * 0.3 * _decay(t, 0.15)
		# Crackle
		var crackle = _noise() * 0.2 * _decay(t, 0.08)
		var env_val = _decay(t, dur)
		samples[i] = (buzz + impact + crackle) * env_val
	_save(samples, "player_hurt.wav")

func _gen_evolve() -> void:
	## Magical transformation: rising shimmer + power chord + sparkles
	var dur := 1.2
	var samples = _make(dur)
	for i in range(samples.size()):
		var t = float(i) / SR
		var p = t / dur
		# Rising sweep
		var sweep_freq = lerp(300.0, 2000.0, p * p)
		var sweep = _sin(t, sweep_freq) * 0.2
		# Harmonics shimmer
		var shimmer = _sin(t, sweep_freq * 1.5) * 0.1 + _sin(t, sweep_freq * 2.0) * 0.08
		shimmer *= (0.5 + 0.5 * sin(t * 20.0))  # Tremolo
		# Power chord (appears at end)
		var chord = 0.0
		if p > 0.6:
			var chord_env = (p - 0.6) / 0.4
			chord = (_sin(t, 523.0) + _sin(t, 659.0) + _sin(t, 784.0)) * 0.12 * chord_env
		# Sparkle pings
		var sparkle = 0.0
		if randf() < 0.005:
			sparkle = _sin(t, randf_range(2000.0, 4000.0)) * 0.15
		var env_val = _env(t, 0.1, 0.2, 0.6, 0.3, dur)
		samples[i] = (sweep + shimmer + chord + sparkle) * env_val
	_save(samples, "evolve.wav")

func _gen_game_over() -> void:
	## Defeat: sad descending phrase + fade to silence
	var dur := 2.0
	var samples = _make(dur)
	# D5-C5-A4-F4-D4 (sad minor descent)
	var notes = [587.0, 523.0, 440.0, 349.0, 294.0]
	var note_dur = dur / notes.size()
	for i in range(samples.size()):
		var t = float(i) / SR
		var p = t / dur
		var note_idx = mini(int(p * notes.size()), notes.size() - 1)
		var freq = notes[note_idx]
		var note_t = t - (note_idx * note_dur)
		# Mournful tone
		var tone = _sin(t, freq) * 0.3 + _tri(t, freq) * 0.15
		# Detuned double for sadness
		tone += _sin(t, freq * 1.003) * 0.1
		var note_env = _env(note_t, 0.03, 0.15, 0.4, 0.1, note_dur)
		# Overall fade
		var fade = 1.0 - p * 0.5
		samples[i] = tone * note_env * fade
	_save(samples, "game_over.wav")
