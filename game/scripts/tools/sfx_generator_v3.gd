extends SceneTree

## SFX Generator v3 — 33 polished retro SFX for Zion.
## Multi-layered oscillators, ADSR envelopes, 44100 Hz, 16-bit mono WAV.
## Categories: Combat (15), UI (8), Ambient (6), Boss (4).

const SR := 44100
const TWO_PI := TAU

func _init() -> void:
	DirAccess.make_dir_recursive_absolute("res://assets/audio/sfx/")
	# Combat (15)
	_gen_sword_slash()
	_gen_axe_chop()
	_gen_scythe_swoosh()
	_gen_whip_crack()
	_gen_hammer_slam()
	_gen_lance_thrust()
	_gen_punch_hit()
	_gen_gun_shot()
	_gen_bow_release()
	_gen_magic_cast()
	_gen_explosion()
	_gen_electric_zap()
	_gen_poison_splash()
	_gen_fire_whoosh()
	_gen_summon_pop()
	# UI (8)
	_gen_collect_crystal()
	_gen_heal()
	_gen_achievement()
	_gen_reroll()
	_gen_banish()
	_gen_select()
	_gen_equip()
	_gen_error()
	# Ambient (6)
	_gen_footstep()
	_gen_enemy_growl()
	_gen_chest_open()
	_gen_portal_hum()
	_gen_lava_bubble()
	_gen_wind()
	# Boss (4)
	_gen_boss_roar()
	_gen_boss_attack()
	_gen_boss_phase()
	_gen_boss_death()
	print("All 33 SFX v3 generated!")
	quit()

# ===== CORE HELPERS =====

func _save(samples: PackedFloat32Array, filename: String) -> void:
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
	file.store_16(1)       # PCM
	file.store_16(1)       # Mono
	file.store_32(SR)
	file.store_32(SR * 2)
	file.store_16(2)       # Block align
	file.store_16(16)      # Bits per sample
	file.store_string("data")
	file.store_32(n * 2)
	for s in samples:
		file.store_16(int(clampf(s, -1.0, 1.0) * 32767.0))
	file.close()
	print("  Saved: %s" % path)

func _sin(t: float, freq: float) -> float:
	return sin(t * freq * TWO_PI)

func _sq(t: float, freq: float) -> float:
	return 1.0 if fmod(t * freq, 1.0) < 0.5 else -1.0

func _tri(t: float, freq: float) -> float:
	return 4.0 * absf(fmod(t * freq, 1.0) - 0.5) - 1.0

func _saw(t: float, freq: float) -> float:
	return 2.0 * fmod(t * freq, 1.0) - 1.0

func _noise() -> float:
	return randf_range(-1.0, 1.0)

func _env(t: float, a: float, d: float, s: float, r: float, dur: float) -> float:
	if t < a: return t / a
	if t < a + d: return 1.0 - (1.0 - s) * ((t - a) / d)
	if t < dur - r: return s
	return s * maxf(0.0, (dur - t) / r)

func _decay(t: float, dur: float) -> float:
	return maxf(0.0, 1.0 - t / dur)

func _exp_decay(t: float, rate: float) -> float:
	return exp(-t * rate)

func _make(dur: float) -> PackedFloat32Array:
	var s = PackedFloat32Array()
	s.resize(int(dur * SR))
	return s

## Simple one-pole low-pass: mix = 0.0 (no filter) to 1.0 (heavy filter)
func _lpf(val: float, prev: float, cutoff: float) -> float:
	return prev + cutoff * (val - prev)

# ===== COMBAT SFX (15) =====

func _gen_sword_slash() -> void:
	## Fast metallic swoosh with harmonic ring
	var dur := 0.15
	var samples = _make(dur)
	var prev := 0.0
	for i in range(samples.size()):
		var t = float(i) / SR
		var p = t / dur
		# High-pitched metallic sweep
		var metal = _sin(t, lerp(4000.0, 1500.0, p)) * 0.2 * _exp_decay(t, 25.0)
		metal += _sin(t, lerp(6000.0, 2000.0, p)) * 0.12 * _exp_decay(t, 30.0)
		# Swoosh noise
		var n = _noise() * 0.5
		prev = _lpf(n, prev, lerp(0.6, 0.15, p))
		var swoosh = prev * sin(p * PI) * 0.7
		# Subtle body
		var body = _sin(t, lerp(800.0, 300.0, p)) * 0.1 * _exp_decay(t, 20.0)
		samples[i] = metal + swoosh + body
	_save(samples, "sword_slash.wav")

func _gen_axe_chop() -> void:
	## Heavy thunk impact with low-end
	var dur := 0.2
	var samples = _make(dur)
	for i in range(samples.size()):
		var t = float(i) / SR
		var p = t / dur
		# Deep thud
		var thud = _sin(t, lerp(180.0, 50.0, p)) * 0.6 * _exp_decay(t, 12.0)
		# Wood crack
		var crack = _noise() * 0.5 * _exp_decay(t, 40.0)
		# Impact transient
		var hit = _sin(t, lerp(500.0, 150.0, p)) * 0.35 * _exp_decay(t, 25.0)
		# Low rumble
		var rumble = _sin(t, 40.0 + sin(t * 30.0) * 10.0) * 0.15 * _decay(t, dur)
		samples[i] = thud + crack + hit + rumble
	_save(samples, "axe_chop.wav")

func _gen_scythe_swoosh() -> void:
	## Circular whoosh — wider, darker than sword
	var dur := 0.2
	var samples = _make(dur)
	var prev := 0.0
	for i in range(samples.size()):
		var t = float(i) / SR
		var p = t / dur
		# Bell-shaped sweep: pitch rises then falls
		var sweep_p = sin(p * PI)
		var freq = lerp(200.0, 1200.0, sweep_p)
		var tone = _sin(t, freq) * 0.15 * sweep_p
		# Dark noise whoosh
		var n = _noise() * 0.6
		prev = _lpf(n, prev, lerp(0.3, 0.08, abs(p - 0.5) * 2.0))
		var whoosh = prev * sin(p * PI) * 0.7
		# Low body
		var body = _sin(t, lerp(150.0, 80.0, p)) * 0.2 * sin(p * PI)
		samples[i] = tone + whoosh + body
	_save(samples, "scythe_swoosh.wav")

func _gen_whip_crack() -> void:
	## Sharp crack — short transient + snap
	var dur := 0.1
	var samples = _make(dur)
	for i in range(samples.size()):
		var t = float(i) / SR
		var p = t / dur
		# Sharp transient noise
		var snap = _noise() * 0.8 * _exp_decay(t, 80.0)
		# High-freq click
		var click = _sin(t, lerp(5000.0, 1000.0, p)) * 0.3 * _exp_decay(t, 60.0)
		# Tiny tail ring
		var ring = _sin(t, 2000.0) * 0.08 * _exp_decay(t, 15.0)
		# Sub thump
		var sub = _sin(t, 120.0) * 0.15 * _exp_decay(t, 30.0)
		samples[i] = snap + click + ring + sub
	_save(samples, "whip_crack.wav")

func _gen_hammer_slam() -> void:
	## Deep ground impact with rumble
	var dur := 0.3
	var samples = _make(dur)
	for i in range(samples.size()):
		var t = float(i) / SR
		var p = t / dur
		# Massive sub impact
		var sub = _sin(t, lerp(100.0, 30.0, p)) * 0.6 * _exp_decay(t, 8.0)
		# Mid crack
		var crack = _noise() * 0.5 * _exp_decay(t, 35.0)
		# Metal clang
		var clang = _sin(t, 450.0) * 0.2 * _exp_decay(t, 12.0)
		clang += _sin(t, 680.0) * 0.1 * _exp_decay(t, 10.0)
		# Ground rumble (vibrato on low freq)
		var rumble = _sin(t, 35.0 + sin(t * 25.0) * 8.0) * 0.3 * _decay(t, 0.25)
		# Debris scatter
		var debris = _noise() * 0.1 * _decay(t, dur) * (0.5 + 0.5 * sin(t * 60.0))
		samples[i] = sub + crack + clang + rumble + debris
	_save(samples, "hammer_slam.wav")

func _gen_lance_thrust() -> void:
	## Quick thrust swoosh — tight and directional
	var dur := 0.12
	var samples = _make(dur)
	var prev := 0.0
	for i in range(samples.size()):
		var t = float(i) / SR
		var p = t / dur
		# Fast ascending swoosh
		var n = _noise() * 0.4
		prev = _lpf(n, prev, lerp(0.7, 0.2, p))
		var swoosh = prev * sin(p * PI * 0.8) * 0.6
		# Piercing tone
		var pierce = _sin(t, lerp(1500.0, 3000.0, p * 0.5)) * 0.2 * _exp_decay(t, 30.0)
		# Point impact at end
		var impact = _sin(t, 600.0) * 0.15 * maxf(0.0, p - 0.6) * 2.5 * _exp_decay(maxf(0.0, t - dur * 0.6), 40.0)
		samples[i] = swoosh + pierce + impact
	_save(samples, "lance_thrust.wav")

func _gen_punch_hit() -> void:
	## Meaty punch — body thud + flesh slap
	var dur := 0.15
	var samples = _make(dur)
	for i in range(samples.size()):
		var t = float(i) / SR
		var p = t / dur
		# Meaty thud
		var thud = _sin(t, lerp(200.0, 60.0, p)) * 0.55 * _exp_decay(t, 15.0)
		# Slap transient
		var slap = _noise() * 0.6 * _exp_decay(t, 50.0)
		# Mid body
		var body = _sin(t, lerp(350.0, 120.0, p)) * 0.25 * _exp_decay(t, 18.0)
		# Subtle ring
		var ring = _sin(t, 800.0) * 0.06 * _exp_decay(t, 12.0)
		samples[i] = thud + slap + body + ring
	_save(samples, "punch_hit.wav")

func _gen_gun_shot() -> void:
	## Retro blaster shot — saw burst + noise pop
	var dur := 0.1
	var samples = _make(dur)
	for i in range(samples.size()):
		var t = float(i) / SR
		var p = t / dur
		# Descending saw for that retro laser feel
		var laser = _saw(t, lerp(1200.0, 300.0, p)) * 0.35 * _exp_decay(t, 25.0)
		# Noise burst
		var burst = _noise() * 0.3 * _exp_decay(t, 50.0)
		# Sub punch
		var punch = _sin(t, lerp(200.0, 80.0, p)) * 0.25 * _exp_decay(t, 20.0)
		# Square overtone
		var sq = _sq(t, lerp(800.0, 200.0, p)) * 0.1 * _exp_decay(t, 30.0)
		samples[i] = laser + burst + punch + sq
	_save(samples, "gun_shot.wav")

func _gen_bow_release() -> void:
	## String twang + arrow whoosh
	var dur := 0.15
	var samples = _make(dur)
	var prev := 0.0
	for i in range(samples.size()):
		var t = float(i) / SR
		var p = t / dur
		# String twang (decaying harmonics)
		var twang = _sin(t, 400.0) * 0.3 * _exp_decay(t, 20.0)
		twang += _sin(t, 800.0) * 0.15 * _exp_decay(t, 25.0)
		twang += _sin(t, 1200.0) * 0.08 * _exp_decay(t, 30.0)
		# Arrow whoosh (delayed, filtered noise)
		var whoosh_env = maxf(0.0, sin((p - 0.15) * PI * 1.5)) if p > 0.15 else 0.0
		var n = _noise() * 0.3
		prev = _lpf(n, prev, 0.4)
		var whoosh = prev * whoosh_env * 0.5
		samples[i] = twang + whoosh
	_save(samples, "bow_release.wav")

func _gen_magic_cast() -> void:
	## Mystical sparkle ascending
	var dur := 0.3
	var samples = _make(dur)
	for i in range(samples.size()):
		var t = float(i) / SR
		var p = t / dur
		# Ascending shimmer
		var freq = lerp(600.0, 2400.0, p * p)
		var shimmer = _sin(t, freq) * 0.25
		shimmer += _sin(t, freq * 1.5) * 0.12
		shimmer += _sin(t, freq * 2.01) * 0.08
		# Tremolo sparkle
		shimmer *= (0.6 + 0.4 * sin(t * 30.0))
		# Soft pad
		var pad = _tri(t, freq * 0.5) * 0.1
		# Random sparkle pings
		var sparkle = 0.0
		if fmod(t * 80.0, 1.0) < 0.05:
			sparkle = _sin(t, freq * 3.0) * 0.1
		var env_val = _env(t, 0.02, 0.08, 0.5, 0.1, dur)
		samples[i] = (shimmer + pad + sparkle) * env_val
	_save(samples, "magic_cast.wav")

func _gen_explosion() -> void:
	## Boom with debris
	var dur := 0.4
	var samples = _make(dur)
	var prev := 0.0
	for i in range(samples.size()):
		var t = float(i) / SR
		var p = t / dur
		# Initial blast
		var blast = _noise() * 0.8 * _exp_decay(t, 15.0)
		# Low boom
		var boom = _sin(t, lerp(120.0, 25.0, p)) * 0.6 * _exp_decay(t, 6.0)
		# Sub rumble
		var rumble = _sin(t, 30.0 + sin(t * 15.0) * 10.0) * 0.3 * _decay(t, 0.35)
		# Filtered debris (noise with decreasing cutoff)
		var n = _noise() * 0.3
		prev = _lpf(n, prev, lerp(0.5, 0.05, p))
		var debris = prev * _decay(t, dur) * 0.5
		# Crackle tail
		var crackle = _noise() * 0.08 * _decay(t, dur) * (0.5 + 0.5 * _sq(t, lerp(40.0, 10.0, p)))
		samples[i] = blast + boom + rumble + debris + crackle
	_save(samples, "explosion.wav")

func _gen_electric_zap() -> void:
	## Crackling electric zap
	var dur := 0.2
	var samples = _make(dur)
	for i in range(samples.size()):
		var t = float(i) / SR
		var p = t / dur
		# Electric buzz (square wave with fast pitch mod)
		var buzz_freq = 400.0 + sin(t * 120.0) * 200.0
		var buzz = _sq(t, buzz_freq) * 0.3 * _exp_decay(t, 10.0)
		# Crackling noise
		var crackle = _noise() * (0.4 if randf() < 0.3 else 0.05) * _exp_decay(t, 8.0)
		# High zap tone
		var zap = _sin(t, lerp(3000.0, 800.0, p)) * 0.2 * _exp_decay(t, 20.0)
		# Arc hum
		var arc = _sin(t, 60.0) * 0.1 * _decay(t, dur)
		samples[i] = buzz + crackle + zap + arc
	_save(samples, "electric_zap.wav")

func _gen_poison_splash() -> void:
	## Wet splat sound
	var dur := 0.15
	var samples = _make(dur)
	var prev := 0.0
	for i in range(samples.size()):
		var t = float(i) / SR
		var p = t / dur
		# Wet burst (filtered noise, mid-range)
		var n = _noise() * 0.6
		var cutoff = lerp(0.5, 0.15, p)
		prev = _lpf(n, prev, cutoff)
		var wet = prev * _exp_decay(t, 18.0) * 0.7
		# Squelch (pitch-bending sine)
		var squelch = _sin(t, lerp(500.0, 150.0, p)) * 0.3 * _exp_decay(t, 15.0)
		# Bubble (quick sine blip)
		var bubble = _sin(t, lerp(800.0, 400.0, p * 3.0)) * 0.1 * _exp_decay(t, 25.0)
		# Drip tail
		var drip = _sin(t, 600.0) * 0.05 * maxf(0.0, p - 0.5) * 2.0 * _exp_decay(maxf(0.0, t - dur * 0.5), 20.0)
		samples[i] = wet + squelch + bubble + drip
	_save(samples, "poison_splash.wav")

func _gen_fire_whoosh() -> void:
	## Flame burst — rising filtered noise + warm tones
	var dur := 0.25
	var samples = _make(dur)
	var prev := 0.0
	for i in range(samples.size()):
		var t = float(i) / SR
		var p = t / dur
		# Fire noise (filtered, rising then falling)
		var n = _noise() * 0.5
		var cutoff_curve = sin(p * PI)
		prev = _lpf(n, prev, lerp(0.2, 0.7, cutoff_curve))
		var fire = prev * cutoff_curve * 0.7
		# Warm tone underneath
		var warm = _sin(t, lerp(200.0, 500.0, p)) * 0.15 * sin(p * PI)
		warm += _tri(t, lerp(150.0, 350.0, p)) * 0.08 * sin(p * PI)
		# Crackle
		var crackle = _noise() * 0.1 * (0.5 + 0.5 * _sq(t, 50.0)) * sin(p * PI)
		samples[i] = fire + warm + crackle
	_save(samples, "fire_whoosh.wav")

func _gen_summon_pop() -> void:
	## Magical pop with echo
	var dur := 0.2
	var samples = _make(dur)
	for i in range(samples.size()):
		var t = float(i) / SR
		var p = t / dur
		# Pop transient
		var pop = _sin(t, lerp(1200.0, 600.0, p * 3.0)) * 0.5 * _exp_decay(t, 35.0)
		# Magical harmonics
		var magic = _sin(t, 880.0) * 0.15 * _exp_decay(t, 10.0)
		magic += _sin(t, 1320.0) * 0.1 * _exp_decay(t, 12.0)
		magic += _sin(t, 1760.0) * 0.06 * _exp_decay(t, 14.0)
		# Echo (delayed, quieter copy)
		var echo = 0.0
		if t > 0.06:
			var et = t - 0.06
			echo = _sin(et, 800.0) * 0.12 * _exp_decay(et, 15.0)
		if t > 0.12:
			var et2 = t - 0.12
			echo += _sin(et2, 700.0) * 0.06 * _exp_decay(et2, 18.0)
		# Shimmer
		var shimmer = _sin(t, 2200.0) * 0.04 * sin(t * 40.0) * _decay(t, dur)
		samples[i] = pop + magic + echo + shimmer
	_save(samples, "summon_pop.wav")

# ===== UI SFX (8) =====

func _gen_collect_crystal() -> void:
	## Higher-pitched coin chime — bright two-note
	var dur := 0.15
	var samples = _make(dur)
	for i in range(samples.size()):
		var t = float(i) / SR
		# Two ascending notes: G6 then E7
		var freq = 1568.0 if t < 0.06 else 2637.0
		var env_val = _env(t, 0.003, 0.03, 0.3, 0.05, dur)
		# Clean bright tone with harmonics
		var tone = _sin(t, freq) * 0.4
		tone += _sin(t, freq * 2.0) * 0.18
		tone += _sin(t, freq * 3.0) * 0.06
		# Tiny shimmer
		tone += _sin(t, freq * 4.01) * 0.03 * sin(t * 50.0)
		samples[i] = tone * env_val
	_save(samples, "collect_crystal.wav")

func _gen_heal() -> void:
	## Warm ascending tone
	var dur := 0.25
	var samples = _make(dur)
	for i in range(samples.size()):
		var t = float(i) / SR
		var p = t / dur
		# Warm ascending frequency
		var freq = lerp(400.0, 900.0, p)
		var tone = _sin(t, freq) * 0.35
		tone += _tri(t, freq * 0.5) * 0.15
		# Gentle harmonics
		tone += _sin(t, freq * 1.5) * 0.1 * (0.6 + 0.4 * sin(t * 15.0))
		# Soft pad
		tone += _sin(t, freq * 0.25) * 0.08
		var env_val = _env(t, 0.03, 0.06, 0.5, 0.08, dur)
		samples[i] = tone * env_val
	_save(samples, "heal.wav")

func _gen_achievement() -> void:
	## Triumphant mini-fanfare: G-B-D-G arpeggio
	var dur := 0.5
	var samples = _make(dur)
	var notes = [784.0, 988.0, 1175.0, 1568.0]  # G5 B5 D6 G6
	for i in range(samples.size()):
		var t = float(i) / SR
		var p = t / dur
		var note_idx = mini(int(p * 4.0), 3)
		var freq = notes[note_idx]
		var note_t = t - (note_idx * dur / 4.0)
		var note_env = _env(note_t, 0.008, 0.04, 0.5, 0.05, dur / 4.0)
		# Bright rich tone
		var tone = _sin(t, freq) * 0.3
		tone += _tri(t, freq) * 0.12
		tone += _sin(t, freq * 2.0) * 0.08
		tone += _sin(t, freq * 3.0) * 0.04
		# Shimmer on final note
		if note_idx == 3:
			tone += _sin(t, freq * 2.005) * 0.06 * sin(t * 18.0)
		samples[i] = tone * note_env
	_save(samples, "achievement.wav")

func _gen_reroll() -> void:
	## Dice/shuffle: rapid alternating tones + noise
	var dur := 0.2
	var samples = _make(dur)
	for i in range(samples.size()):
		var t = float(i) / SR
		var p = t / dur
		# Rapid clicking tones (simulates dice tumbling)
		var click_rate = lerp(50.0, 15.0, p)  # Slowing down
		var click_freq = 1200.0 + sin(t * click_rate * TWO_PI) * 400.0
		var clicks = _sin(t, click_freq) * 0.2 * (0.5 + 0.5 * _sq(t, click_rate))
		# Rattle noise
		var rattle = _noise() * 0.15 * (0.5 + 0.5 * sin(t * click_rate * TWO_PI)) * _decay(t, dur)
		# Body tone
		var body = _sin(t, 600.0) * 0.08 * _decay(t, dur)
		var env_val = _env(t, 0.01, 0.05, 0.6, 0.06, dur)
		samples[i] = (clicks + rattle + body) * env_val
	_save(samples, "reroll.wav")

func _gen_banish() -> void:
	## Dismissive whoosh downward
	var dur := 0.15
	var samples = _make(dur)
	var prev := 0.0
	for i in range(samples.size()):
		var t = float(i) / SR
		var p = t / dur
		# Descending tone
		var freq = lerp(1500.0, 200.0, p * p)
		var tone = _sin(t, freq) * 0.25 * _decay(t, dur * 0.8)
		# Whoosh noise (descending filter)
		var n = _noise() * 0.4
		prev = _lpf(n, prev, lerp(0.6, 0.08, p))
		var whoosh = prev * sin(p * PI * 0.7) * 0.5
		# Sub bump
		var sub = _sin(t, lerp(300.0, 60.0, p)) * 0.15 * _exp_decay(t, 15.0)
		samples[i] = tone + whoosh + sub
	_save(samples, "banish.wav")

func _gen_select() -> void:
	## Soft confirm blip — clean and short
	var dur := 0.08
	var samples = _make(dur)
	for i in range(samples.size()):
		var t = float(i) / SR
		# Clean sine blip
		var tone = _sin(t, 1200.0) * 0.35 * _exp_decay(t, 30.0)
		# Subtle harmonic
		tone += _sin(t, 1800.0) * 0.1 * _exp_decay(t, 35.0)
		# Tiny sub body
		tone += _sin(t, 600.0) * 0.1 * _exp_decay(t, 25.0)
		samples[i] = tone
	_save(samples, "select.wav")

func _gen_equip() -> void:
	## Metallic click + shine
	var dur := 0.15
	var samples = _make(dur)
	for i in range(samples.size()):
		var t = float(i) / SR
		var p = t / dur
		# Metallic click
		var click = _sin(t, 2500.0) * 0.3 * _exp_decay(t, 50.0)
		click += _sin(t, 3800.0) * 0.15 * _exp_decay(t, 55.0)
		# Metal ring
		var ring = _sin(t, 1800.0) * 0.2 * _exp_decay(t, 12.0)
		ring += _sin(t, 2700.0) * 0.08 * _exp_decay(t, 14.0)
		# Shine (ascending brief)
		var shine = 0.0
		if t > 0.03:
			var st = t - 0.03
			shine = _sin(st, lerp(2000.0, 4000.0, st * 15.0)) * 0.1 * _exp_decay(st, 18.0)
		samples[i] = click + ring + shine
	_save(samples, "equip.wav")

func _gen_error() -> void:
	## Low buzz rejection
	var dur := 0.2
	var samples = _make(dur)
	for i in range(samples.size()):
		var t = float(i) / SR
		var p = t / dur
		# Low dissonant buzz
		var buzz = _sq(t, 150.0) * 0.25 * _decay(t, dur)
		buzz += _sq(t, 157.0) * 0.15 * _decay(t, dur)  # Detuned for dissonance
		# Two quick pulses
		var pulse_env = 1.0
		if p > 0.35 and p < 0.5:
			pulse_env = 0.2
		# Sub tone
		var sub = _sin(t, 80.0) * 0.2 * _decay(t, dur)
		# Noise edge
		var edge = _noise() * 0.06 * _decay(t, dur * 0.5)
		samples[i] = (buzz + sub + edge) * pulse_env
	_save(samples, "error.wav")

# ===== AMBIENT SFX (6) =====

func _gen_footstep() -> void:
	## Soft ground step
	var dur := 0.08
	var samples = _make(dur)
	var prev := 0.0
	for i in range(samples.size()):
		var t = float(i) / SR
		var p = t / dur
		# Soft thud
		var thud = _sin(t, lerp(150.0, 60.0, p)) * 0.35 * _exp_decay(t, 30.0)
		# Ground crunch (filtered noise)
		var n = _noise() * 0.4
		prev = _lpf(n, prev, 0.25)
		var crunch = prev * _exp_decay(t, 25.0) * 0.5
		# Tiny click
		var click = _noise() * 0.2 * _exp_decay(t, 80.0)
		samples[i] = thud + crunch + click
	_save(samples, "footstep.wav")

func _gen_enemy_growl() -> void:
	## Low monster growl with wobble
	var dur := 0.3
	var samples = _make(dur)
	for i in range(samples.size()):
		var t = float(i) / SR
		var p = t / dur
		# Deep growl with vibrato
		var freq = 80.0 + sin(t * 8.0) * 15.0
		var growl = _saw(t, freq) * 0.3
		growl = clampf(growl * 2.5, -1.0, 1.0) * 0.3  # Soft clip for grit
		# Sub rumble
		var rumble = _sin(t, 40.0 + sin(t * 5.0) * 8.0) * 0.25
		# Breath noise
		var breath = _noise() * 0.1 * (0.5 + 0.5 * sin(t * 6.0))
		var env_val = _env(t, 0.05, 0.08, 0.6, 0.1, dur)
		samples[i] = (growl + rumble + breath) * env_val
	_save(samples, "enemy_growl.wav")

func _gen_chest_open() -> void:
	## Creaky wood + jingle
	var dur := 0.4
	var samples = _make(dur)
	var prev := 0.0
	for i in range(samples.size()):
		var t = float(i) / SR
		var p = t / dur
		# Creaky hinge (frequency-modulated noise)
		var creak_env = sin(p * PI * 0.8) if p < 0.4 else 0.0
		var creak_freq = lerp(300.0, 800.0, p * 2.5)
		var creak = _sin(t, creak_freq + sin(t * 30.0) * 100.0) * 0.2 * creak_env
		var n = _noise() * 0.15
		prev = _lpf(n, prev, lerp(0.3, 0.1, p))
		var wood = prev * creak_env * 0.4
		# Jingle (delayed coins/gems sound)
		var jingle = 0.0
		if p > 0.3:
			var jt = t - dur * 0.3
			var jp = (p - 0.3) / 0.7
			jingle = _sin(jt, 1500.0) * 0.15 * _exp_decay(jt, 8.0)
			jingle += _sin(jt, 2000.0) * 0.1 * _exp_decay(jt, 10.0)
			jingle += _sin(jt, 2500.0) * 0.06 * _exp_decay(jt, 12.0)
			# Second jingle hit
			if p > 0.5:
				var jt2 = t - dur * 0.5
				jingle += _sin(jt2, 1800.0) * 0.1 * _exp_decay(jt2, 9.0)
				jingle += _sin(jt2, 2400.0) * 0.07 * _exp_decay(jt2, 11.0)
		samples[i] = creak + wood + jingle
	_save(samples, "chest_open.wav")

func _gen_portal_hum() -> void:
	## Deep resonant hum with subtle movement
	var dur := 0.5
	var samples = _make(dur)
	for i in range(samples.size()):
		var t = float(i) / SR
		var p = t / dur
		# Deep drone
		var drone = _sin(t, 80.0) * 0.3
		drone += _sin(t, 80.5) * 0.15  # Slight detune for beating
		# Resonant harmonics
		var harm = _sin(t, 160.0) * 0.12 * (0.7 + 0.3 * sin(t * 3.0))
		harm += _sin(t, 240.0) * 0.08 * (0.6 + 0.4 * sin(t * 4.5))
		# Ethereal shimmer
		var shimmer = _sin(t, 800.0 + sin(t * 2.0) * 50.0) * 0.05
		shimmer += _sin(t, 1200.0 + sin(t * 3.0) * 60.0) * 0.03
		# Wobble
		var wobble = _sin(t, 60.0 + sin(t * 1.5) * 10.0) * 0.1
		var env_val = _env(t, 0.08, 0.1, 0.7, 0.12, dur)
		samples[i] = (drone + harm + shimmer + wobble) * env_val
	_save(samples, "portal_hum.wav")

func _gen_lava_bubble() -> void:
	## Bubbling liquid
	var dur := 0.3
	var samples = _make(dur)
	for i in range(samples.size()):
		var t = float(i) / SR
		var p = t / dur
		# Main bubble (pitch drops as bubble rises)
		var bub_freq = lerp(300.0, 100.0, p)
		var bubble = _sin(t, bub_freq) * 0.3 * sin(p * PI)
		# Pop at top
		var pop = 0.0
		if p > 0.3 and p < 0.5:
			var pp = (p - 0.3) / 0.2
			pop = _noise() * 0.25 * sin(pp * PI)
		# Secondary smaller bubbles
		var bub2 = _sin(t, 500.0 + sin(t * 20.0) * 80.0) * 0.08 * (0.5 + 0.5 * sin(t * 12.0))
		# Deep liquid body
		var liquid = _sin(t, 60.0 + sin(t * 4.0) * 15.0) * 0.15 * _env(t, 0.05, 0.05, 0.5, 0.08, dur)
		# Wet noise
		var wet = _noise() * 0.06 * sin(p * PI * 2.0) * _decay(t, dur)
		samples[i] = bubble + pop + bub2 + liquid + wet
	_save(samples, "lava_bubble.wav")

func _gen_wind() -> void:
	## Gentle wind sweep — filtered noise with slow modulation
	var dur := 0.5
	var samples = _make(dur)
	var prev := 0.0
	var prev2 := 0.0
	for i in range(samples.size()):
		var t = float(i) / SR
		var p = t / dur
		# Wind noise with slowly modulating filter
		var n = _noise() * 0.5
		var cutoff = 0.15 + 0.2 * sin(t * 4.0)
		prev = _lpf(n, prev, cutoff)
		# Second filter pass for smoother sound
		prev2 = _lpf(prev, prev2, 0.3)
		var wind = prev2 * 0.8
		# Subtle tonal whistle
		var whistle = _sin(t, 800.0 + sin(t * 2.5) * 200.0) * 0.04
		whistle += _sin(t, 1200.0 + sin(t * 3.0) * 150.0) * 0.02
		# Bell-shaped envelope
		var env_val = sin(p * PI)
		samples[i] = (wind + whistle) * env_val
	_save(samples, "wind.wav")

# ===== BOSS SFX (4) =====

func _gen_boss_roar() -> void:
	## Powerful roar with reverb
	var dur := 0.6
	var samples = _make(dur)
	for i in range(samples.size()):
		var t = float(i) / SR
		var p = t / dur
		# Deep roar core (distorted saw)
		var roar_freq = 70.0 + sin(t * 6.0) * 20.0
		var roar = _saw(t, roar_freq) * 0.4
		roar += _saw(t, roar_freq * 1.01) * 0.2  # Detuned layer
		roar = clampf(roar * 2.0, -1.0, 1.0) * 0.4  # Distortion
		# Mid growl
		var growl = _sq(t, roar_freq * 2.0) * 0.15 * (0.7 + 0.3 * sin(t * 10.0))
		# Rumble
		var rumble = _sin(t, 30.0 + sin(t * 3.0) * 8.0) * 0.25
		# Breath noise
		var breath = _noise() * 0.12 * (0.5 + 0.5 * sin(t * 7.0))
		# High scream overtone
		var scream = _sin(t, lerp(400.0, 600.0, sin(t * 5.0) * 0.5 + 0.5)) * 0.08
		var env_val = _env(t, 0.05, 0.15, 0.6, 0.2, dur)
		samples[i] = (roar + growl + rumble + breath + scream) * env_val
	# Simple reverb: add delayed copies
	for i in range(samples.size()):
		var d1 = i - int(0.03 * SR)
		var d2 = i - int(0.07 * SR)
		var d3 = i - int(0.12 * SR)
		if d1 >= 0:
			samples[i] += samples[d1] * 0.2
		if d2 >= 0:
			samples[i] += samples[d2] * 0.1
		if d3 >= 0:
			samples[i] += samples[d3] * 0.05
	_save(samples, "boss_roar.wav")

func _gen_boss_attack() -> void:
	## Heavy swoosh + impact
	var dur := 0.3
	var samples = _make(dur)
	var prev := 0.0
	for i in range(samples.size()):
		var t = float(i) / SR
		var p = t / dur
		# Wind-up swoosh (first half)
		var swoosh_env = sin(minf(p * 2.0, 1.0) * PI)
		var n = _noise() * 0.4
		prev = _lpf(n, prev, lerp(0.3, 0.6, minf(p * 2.0, 1.0)))
		var swoosh = prev * swoosh_env * 0.6
		# Tonal swoosh
		var tone_swoosh = _sin(t, lerp(300.0, 1000.0, minf(p * 2.0, 1.0))) * 0.15 * swoosh_env
		# Impact (second half)
		var impact = 0.0
		if p > 0.4:
			var it = t - dur * 0.4
			impact = _sin(it, lerp(200.0, 40.0, (p - 0.4) / 0.6)) * 0.5 * _exp_decay(it, 10.0)
			impact += _noise() * 0.35 * _exp_decay(it, 25.0)
			# Sub boom
			impact += _sin(it, 35.0) * 0.3 * _exp_decay(it, 6.0)
		samples[i] = swoosh + tone_swoosh + impact
	_save(samples, "boss_attack.wav")

func _gen_boss_phase() -> void:
	## Dramatic transition sting
	var dur := 0.5
	var samples = _make(dur)
	for i in range(samples.size()):
		var t = float(i) / SR
		var p = t / dur
		# Rising tension sweep
		var sweep = _sin(t, lerp(200.0, 1200.0, p * p)) * 0.2 * p
		sweep += _sin(t, lerp(300.0, 1800.0, p * p)) * 0.1 * p
		# Dramatic hit at peak
		var hit_env = 0.0
		if p > 0.6:
			hit_env = _exp_decay(t - dur * 0.6, 8.0)
		var hit = (_sin(t, 150.0) * 0.4 + _sin(t, 300.0) * 0.2 + _sin(t, 450.0) * 0.1) * hit_env
		# Cymbal crash noise
		var crash = _noise() * 0.3 * hit_env * 0.7
		# Sub drop
		var sub_drop = 0.0
		if p > 0.6:
			sub_drop = _sin(t, lerp(120.0, 40.0, (p - 0.6) / 0.4)) * 0.25 * hit_env
		# Tension noise building up
		var tension = _noise() * 0.08 * p * p
		samples[i] = sweep + hit + crash + sub_drop + tension
	# Add reverb tail
	for i in range(samples.size()):
		var d1 = i - int(0.04 * SR)
		var d2 = i - int(0.09 * SR)
		if d1 >= 0:
			samples[i] += samples[d1] * 0.15
		if d2 >= 0:
			samples[i] += samples[d2] * 0.08
	_save(samples, "boss_phase.wav")

func _gen_boss_death() -> void:
	## Explosion + triumphant fanfare
	var dur := 0.8
	var samples = _make(dur)
	var prev := 0.0
	for i in range(samples.size()):
		var t = float(i) / SR
		var p = t / dur
		# Big explosion (first 0.3s)
		var explosion = 0.0
		if p < 0.4:
			var ep = p / 0.4
			explosion = _noise() * 0.5 * _exp_decay(t, 6.0)
			explosion += _sin(t, lerp(120.0, 25.0, ep)) * 0.4 * _exp_decay(t, 5.0)
			explosion += _sin(t, 30.0 + sin(t * 10.0) * 8.0) * 0.2 * _decay(t, 0.35)
		# Victory fanfare (starts at 0.25s): C-E-G-C
		var fanfare = 0.0
		if p > 0.3:
			var fp = (p - 0.3) / 0.7
			var fan_notes = [523.0, 659.0, 784.0, 1047.0]
			var note_idx = mini(int(fp * 4.0), 3)
			var freq = fan_notes[note_idx]
			var note_dur = 0.7 * dur / 4.0
			var note_t = (t - dur * 0.3) - (note_idx * note_dur)
			var note_env = _env(note_t, 0.01, 0.05, 0.5, 0.06, note_dur)
			fanfare = _sin(t, freq) * 0.25 * note_env
			fanfare += _tri(t, freq) * 0.1 * note_env
			fanfare += _sin(t, freq * 2.0) * 0.06 * note_env
			# Final note shimmer
			if note_idx == 3:
				fanfare += _sin(t, freq * 1.002) * 0.08 * note_env * sin(t * 15.0)
		# Debris (filtered noise tail)
		var n = _noise() * 0.15
		prev = _lpf(n, prev, lerp(0.3, 0.05, p))
		var debris = prev * _decay(t, dur * 0.6) * 0.4
		samples[i] = explosion + fanfare + debris
	# Light reverb
	for i in range(samples.size()):
		var d1 = i - int(0.05 * SR)
		if d1 >= 0:
			samples[i] += samples[d1] * 0.12
	_save(samples, "boss_death.wav")
