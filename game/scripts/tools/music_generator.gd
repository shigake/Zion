extends SceneTree

## Generates procedural looping music tracks as .wav files.
## Each track is 30 seconds, mono 16-bit at 22050 Hz.
## Run: godot --headless --script res://scripts/tools/music_generator.gd

const SAMPLE_RATE := 22050
const DURATION := 30.0

func _init() -> void:
	DirAccess.make_dir_recursive_absolute("res://assets/audio/music/")

	print("=== Music Generator ===")
	print("Generating 12 tracks (30s each)...")

	_gen_menu()
	_gen_cemetery()
	_gen_forest()
	_gen_farm()
	_gen_tokyo()
	_gen_volcano()
	_gen_ocean()
	_gen_arena()
	_gen_space()
	_gen_castle()
	_gen_candy()
	_gen_boss()

	print("All 12 music tracks generated!")
	quit()

# ===== WAV WRITER =====

func _save_wav(samples: PackedFloat32Array, filename: String) -> void:
	var path = "res://assets/audio/music/%s" % filename
	var num_samples = samples.size()
	var data_size = num_samples * 2
	var file_size = 36 + data_size

	var file = FileAccess.open(path, FileAccess.WRITE)
	if not file:
		print("ERROR: Cannot write %s" % path)
		return

	file.store_string("RIFF")
	file.store_32(file_size)
	file.store_string("WAVE")
	file.store_string("fmt ")
	file.store_32(16)
	file.store_16(1)
	file.store_16(1)
	file.store_32(SAMPLE_RATE)
	file.store_32(SAMPLE_RATE * 2)
	file.store_16(2)
	file.store_16(16)
	file.store_string("data")
	file.store_32(data_size)

	for s in samples:
		var clamped = clampf(s, -1.0, 1.0)
		file.store_16(int(clamped * 32767.0))

	file.close()
	print("  Saved: %s (%d samples, %.1fs)" % [path, num_samples, float(num_samples) / SAMPLE_RATE])

# ===== OSCILLATORS =====

func _sine(phase: float) -> float:
	return sin(phase * TAU)

func _square(phase: float) -> float:
	return 1.0 if fmod(phase, 1.0) < 0.5 else -1.0

func _triangle(phase: float) -> float:
	var t = fmod(phase, 1.0)
	return 4.0 * absf(t - 0.5) - 1.0

func _saw(phase: float) -> float:
	return 2.0 * fmod(phase, 1.0) - 1.0

func _noise() -> float:
	return randf_range(-1.0, 1.0)

# Attempt a softer square (sum of odd harmonics, band-limited)
func _soft_square(phase: float) -> float:
	var out := 0.0
	out += _sine(phase)
	out += _sine(phase * 3.0) / 3.0
	out += _sine(phase * 5.0) / 5.0
	out += _sine(phase * 7.0) / 7.0
	return out * 0.8

# ===== ENVELOPES =====

func _env_adsr(t: float, a: float, d: float, s: float, r: float, total: float) -> float:
	if t < a:
		return t / a if a > 0.0 else 1.0
	elif t < a + d:
		return 1.0 - (1.0 - s) * ((t - a) / d)
	elif t < total - r:
		return s
	else:
		var rt = (t - (total - r)) / r if r > 0.0 else 1.0
		return s * maxf(0.0, 1.0 - rt)

func _env_decay(t: float, dur: float) -> float:
	return maxf(0.0, 1.0 - t / dur)

# ===== MUSIC HELPERS =====

# Returns which beat we're on and how far into that beat (0-1)
func _beat_info(t: float, bpm: float) -> Dictionary:
	var beat_dur := 60.0 / bpm
	var beat_num := int(t / beat_dur)
	var beat_frac := fmod(t, beat_dur) / beat_dur
	return {"num": beat_num, "frac": beat_frac, "dur": beat_dur}

# Get current chord index (4 chords over 4 bars, beats_per_bar beats each)
func _chord_index(t: float, bpm: float, beats_per_bar: int) -> int:
	var beat_dur := 60.0 / bpm
	var bar_dur := beat_dur * beats_per_bar
	var loop_dur := bar_dur * 4.0
	var pos := fmod(t, loop_dur)
	return int(pos / bar_dur)

# Phase accumulator - more accurate than t*freq for changing frequencies
# We use simple t*freq/SR approach here since frequencies are constant per chord
func _phase(t: float, freq: float) -> float:
	return t * freq / float(SAMPLE_RATE)

# Kick drum - short sine burst at low freq
func _kick(beat_frac: float) -> float:
	if beat_frac > 0.15:
		return 0.0
	var kt := beat_frac / 0.15
	var freq := lerpf(150.0, 50.0, kt)
	return _sine(kt * freq * 0.15) * (1.0 - kt) * 0.8

# Snare - noise burst
func _snare(beat_frac: float) -> float:
	if beat_frac > 0.1:
		return 0.0
	var st := beat_frac / 0.1
	return _noise() * (1.0 - st) * 0.4

# Hi-hat - short high noise
func _hihat(beat_frac: float) -> float:
	if beat_frac > 0.05:
		return 0.0
	var ht := beat_frac / 0.05
	return _noise() * (1.0 - ht) * 0.15

# ===== NOTE FREQUENCIES =====
# Using standard tuning A4=440Hz

const NOTE_C2 := 65.41
const NOTE_D2 := 73.42
const NOTE_E2 := 82.41
const NOTE_F2 := 87.31
const NOTE_G2 := 98.0
const NOTE_A2 := 110.0
const NOTE_Bb2 := 116.54
const NOTE_B2 := 123.47

const NOTE_C3 := 130.81
const NOTE_D3 := 146.83
const NOTE_E3 := 164.81
const NOTE_F3 := 174.61
const NOTE_G3 := 196.0
const NOTE_A3 := 220.0
const NOTE_Bb3 := 233.08
const NOTE_B3 := 246.94

const NOTE_C4 := 261.63
const NOTE_D4 := 293.66
const NOTE_E4 := 329.63
const NOTE_F4 := 349.23
const NOTE_G4 := 392.0
const NOTE_A4 := 440.0
const NOTE_Bb4 := 466.16
const NOTE_B4 := 493.88

const NOTE_C5 := 523.25
const NOTE_D5 := 587.33
const NOTE_E5 := 659.25
const NOTE_F5 := 698.46
const NOTE_G5 := 783.99
const NOTE_A5 := 880.0

# Chord = array of [bass_freq, [chord_freqs], melody_note]
# Each chord entry: { bass, notes, melody }

# ===== TRACK GENERATORS =====

func _gen_menu() -> void:
	## Am-F-C-G — mysterious, 100bpm, pad-heavy, no drums
	print("Generating menu.wav...")
	var bpm := 100.0
	var chords := [
		{bass = NOTE_A2, notes = [NOTE_A3, NOTE_C4, NOTE_E4]},
		{bass = NOTE_F2, notes = [NOTE_F3, NOTE_A3, NOTE_C4]},
		{bass = NOTE_C3, notes = [NOTE_C4, NOTE_E4, NOTE_G4]},
		{bass = NOTE_G2, notes = [NOTE_G3, NOTE_B3, NOTE_D4]},
	]
	var melody := [NOTE_E5, NOTE_C5, NOTE_G5, NOTE_D5]
	var num_samples := int(DURATION * SAMPLE_RATE)
	var samples := PackedFloat32Array()
	samples.resize(num_samples)

	for i in range(num_samples):
		var t := float(i) / SAMPLE_RATE
		var ci := _chord_index(t, bpm, 4)
		var chord: Dictionary = chords[ci]
		var bi := _beat_info(t, bpm)
		var out := 0.0

		# Deep bass - slow sine with gentle pulse
		var bass_phase: float = t * chord.bass / float(SAMPLE_RATE)
		out += _sine(bass_phase) * 0.2

		# Lush pad - multiple detuned sines
		for note_freq: float in chord.notes:
			var p1 := t * note_freq / float(SAMPLE_RATE)
			var p2 := t * (note_freq * 1.003) / float(SAMPLE_RATE)
			var p3 := t * (note_freq * 0.997) / float(SAMPLE_RATE)
			out += (_sine(p1) + _sine(p2) + _sine(p3)) * 0.07

		# Gentle melody - appears every other bar, slow envelope
		var bar_in_loop := ci
		if bar_in_loop % 2 == 0:
			var mel_freq: float = melody[ci]
			var mel_phase: float = t * mel_freq / float(SAMPLE_RATE)
			var mel_env := _env_adsr(bi.frac, 0.2, 0.3, 0.4, 0.3, 1.0)
			out += _sine(mel_phase) * mel_env * 0.12

		# Slow LFO tremolo on everything
		var lfo := 0.85 + 0.15 * _sine(t * 0.3)
		out *= lfo

		# No drums - just gentle ambience
		samples[i] = out * 0.7

	_save_wav(samples, "menu.wav")


func _gen_cemetery() -> void:
	## Dm-Bb-A-Dm — dark minor, 90bpm, organ-like square waves
	print("Generating cemetery.wav...")
	var bpm := 90.0
	var chords := [
		{bass = NOTE_D2, notes = [NOTE_D3, NOTE_F3, NOTE_A3]},
		{bass = NOTE_Bb2, notes = [NOTE_Bb3, NOTE_D4, NOTE_F4]},
		{bass = NOTE_A2, notes = [NOTE_A3, NOTE_C4 + 17.32, NOTE_E4]},  # A major (C#4)
		{bass = NOTE_D2, notes = [NOTE_D3, NOTE_F3, NOTE_A3]},
	]
	var melody := [NOTE_A4, NOTE_F4, NOTE_E4, NOTE_D4]
	var num_samples := int(DURATION * SAMPLE_RATE)
	var samples := PackedFloat32Array()
	samples.resize(num_samples)

	for i in range(num_samples):
		var t := float(i) / SAMPLE_RATE
		var ci := _chord_index(t, bpm, 4)
		var chord: Dictionary = chords[ci]
		var bi := _beat_info(t, bpm)
		var out := 0.0

		# Organ bass - square wave fundamental
		var bass_phase: float = t * chord.bass / float(SAMPLE_RATE)
		out += _soft_square(bass_phase) * 0.18

		# Organ pads - layered square harmonics (church organ character)
		for note_freq: float in chord.notes:
			var p := t * note_freq / float(SAMPLE_RATE)
			out += _soft_square(p) * 0.08
			out += _sine(p * 2.0) * 0.03  # 2nd harmonic (organ pipe)

		# Creepy melody - slow, deliberate
		var mel_freq: float = melody[ci]
		var bar_dur := 60.0 / bpm * 4.0
		var bar_t := fmod(t, bar_dur * 4.0)
		var bar_local := fmod(bar_t, bar_dur) / bar_dur
		var mel_env := _env_adsr(bar_local, 0.15, 0.2, 0.5, 0.3, 1.0)
		var mel_phase: float = t * mel_freq / float(SAMPLE_RATE)
		out += _triangle(mel_phase) * mel_env * 0.1

		# Slow drums - just a faint kick on beat 1
		if bi.num % 4 == 0:
			out += _kick(bi.frac) * 0.3

		# Eerie vibrato
		var vib := 1.0 + 0.008 * sin(t * 5.0 * TAU)
		out *= vib

		samples[i] = out * 0.7

	_save_wav(samples, "cemetery.wav")


func _gen_forest() -> void:
	## C-Am-F-G — magical, 110bpm, sine bells
	print("Generating forest.wav...")
	var bpm := 110.0
	var chords := [
		{bass = NOTE_C3, notes = [NOTE_C4, NOTE_E4, NOTE_G4]},
		{bass = NOTE_A2, notes = [NOTE_A3, NOTE_C4, NOTE_E4]},
		{bass = NOTE_F2, notes = [NOTE_F3, NOTE_A3, NOTE_C4]},
		{bass = NOTE_G2, notes = [NOTE_G3, NOTE_B3, NOTE_D4]},
	]
	var melody := [NOTE_G5, NOTE_E5, NOTE_C5, NOTE_D5]
	var num_samples := int(DURATION * SAMPLE_RATE)
	var samples := PackedFloat32Array()
	samples.resize(num_samples)

	for i in range(num_samples):
		var t := float(i) / SAMPLE_RATE
		var ci := _chord_index(t, bpm, 4)
		var chord: Dictionary = chords[ci]
		var bi := _beat_info(t, bpm)
		var out := 0.0

		# Warm bass
		var bass_phase: float = t * chord.bass / float(SAMPLE_RATE)
		out += _sine(bass_phase) * 0.2

		# Bell-like pads (sine with fast decay harmonics)
		for note_freq: float in chord.notes:
			var p := t * note_freq / float(SAMPLE_RATE)
			out += _sine(p) * 0.08
			out += _sine(p * 2.0) * 0.03 * _env_decay(bi.frac, 0.5)
			out += _sine(p * 3.0) * 0.015 * _env_decay(bi.frac, 0.3)

		# Twinkling melody - each beat has a bell hit
		var mel_freq: float = melody[ci]
		var mel_phase: float = t * mel_freq / float(SAMPLE_RATE)
		# Bell on beats 1 and 3
		if bi.num % 2 == 0:
			var mel_env := _env_decay(bi.frac, 0.6)
			out += _sine(mel_phase) * mel_env * 0.15
			out += _sine(mel_phase * 2.5) * mel_env * 0.05  # Bell harmonic

		# Light percussion
		if bi.num % 4 == 0:
			out += _kick(bi.frac) * 0.25
		if bi.num % 4 == 2:
			out += _snare(bi.frac) * 0.15
		out += _hihat(bi.frac) * 0.6

		samples[i] = out * 0.65

	_save_wav(samples, "forest.wav")


func _gen_farm() -> void:
	## Em-C-G-D — country tension, 120bpm, twangy square wave
	print("Generating farm.wav...")
	var bpm := 120.0
	var chords := [
		{bass = NOTE_E2, notes = [NOTE_E3, NOTE_G3, NOTE_B3]},
		{bass = NOTE_C3, notes = [NOTE_C4, NOTE_E4, NOTE_G4]},
		{bass = NOTE_G2, notes = [NOTE_G3, NOTE_B3, NOTE_D4]},
		{bass = NOTE_D2, notes = [NOTE_D3, NOTE_F3 + 18.35, NOTE_A3]},  # D major (F#3)
	]
	var melody := [NOTE_B4, NOTE_G4, NOTE_D5, NOTE_A4]
	var num_samples := int(DURATION * SAMPLE_RATE)
	var samples := PackedFloat32Array()
	samples.resize(num_samples)

	for i in range(num_samples):
		var t := float(i) / SAMPLE_RATE
		var ci := _chord_index(t, bpm, 4)
		var chord: Dictionary = chords[ci]
		var bi := _beat_info(t, bpm)
		var out := 0.0

		# Walking bass - alternates root and fifth each beat
		var bass_freq: float = chord.bass
		if bi.num % 2 == 1:
			bass_freq *= 1.5  # Fifth
		var bass_phase: float = t * bass_freq / float(SAMPLE_RATE)
		out += _triangle(bass_phase) * 0.2

		# Twangy chords - square wave with fast decay (plucked feel)
		for note_freq: float in chord.notes:
			var p := t * note_freq / float(SAMPLE_RATE)
			# Strum on offbeats
			if bi.num % 2 == 1:
				var tw_env := _env_decay(bi.frac, 0.4)
				out += _square(p) * tw_env * 0.06
				out += _sine(p) * tw_env * 0.04

		# Twangy melody
		var mel_freq: float = melody[ci]
		var mel_phase: float = t * mel_freq / float(SAMPLE_RATE)
		if bi.num % 4 < 3:
			var mel_env := _env_decay(bi.frac, 0.35)
			out += _square(mel_phase) * mel_env * 0.08
			out += _sine(mel_phase * 2.0) * mel_env * 0.03

		# Stompy drums
		if bi.num % 4 == 0 or bi.num % 4 == 2:
			out += _kick(bi.frac) * 0.5
		if bi.num % 4 == 1 or bi.num % 4 == 3:
			out += _snare(bi.frac) * 0.3
		out += _hihat(bi.frac) * 0.5

		samples[i] = out * 0.6

	_save_wav(samples, "farm.wav")


func _gen_tokyo() -> void:
	## Am-F-C-E — synthwave, 128bpm, saw-like, pulsing bass
	print("Generating tokyo.wav...")
	var bpm := 128.0
	var chords := [
		{bass = NOTE_A2, notes = [NOTE_A3, NOTE_C4, NOTE_E4]},
		{bass = NOTE_F2, notes = [NOTE_F3, NOTE_A3, NOTE_C4]},
		{bass = NOTE_C3, notes = [NOTE_C4, NOTE_E4, NOTE_G4]},
		{bass = NOTE_E2, notes = [NOTE_E3, NOTE_G3 + 15.56, NOTE_B3]},  # E major (G#3)
	]
	var melody := [NOTE_E5, NOTE_C5, NOTE_G5, NOTE_B4]
	var num_samples := int(DURATION * SAMPLE_RATE)
	var samples := PackedFloat32Array()
	samples.resize(num_samples)

	for i in range(num_samples):
		var t := float(i) / SAMPLE_RATE
		var ci := _chord_index(t, bpm, 4)
		var chord: Dictionary = chords[ci]
		var bi := _beat_info(t, bpm)
		var out := 0.0

		# Pulsing sidechain bass - pumps with kick
		var bass_phase: float = t * chord.bass / float(SAMPLE_RATE)
		var sidechain := minf(bi.frac * 8.0, 1.0)  # Quick pump recovery
		out += _saw(bass_phase) * 0.2 * sidechain
		# Sub bass
		out += _sine(bass_phase * 0.5) * 0.15 * sidechain

		# Synthwave pads - detuned saws
		for note_freq: float in chord.notes:
			var p1 := t * note_freq / float(SAMPLE_RATE)
			var p2 := t * (note_freq * 1.005) / float(SAMPLE_RATE)
			out += (_saw(p1) + _saw(p2)) * 0.04 * sidechain

		# Arpeggiated melody - 16th notes cycling chord tones
		var arp_notes: Array = chord.notes.duplicate()
		arp_notes.append(melody[ci])
		var sixteenth := int(bi.frac * 4.0) % arp_notes.size()
		var arp_freq: float = arp_notes[sixteenth]
		var arp_phase: float = t * arp_freq / float(SAMPLE_RATE)
		var arp_frac: float = fmod(bi.frac * 4.0, 1.0)
		var arp_env := _env_decay(arp_frac, 0.7)
		out += _square(arp_phase) * arp_env * 0.08

		# Four-on-floor kick
		out += _kick(bi.frac) * 0.5
		# Clap on 2 and 4
		if bi.num % 4 == 2:
			out += _snare(bi.frac) * 0.3
		# 8th note hihats
		var hh_frac: float = fmod(bi.frac * 2.0, 1.0)
		out += _hihat(hh_frac) * 0.5

		samples[i] = out * 0.6

	_save_wav(samples, "tokyo.wav")


func _gen_volcano() -> void:
	## Dm-Dm-Bb-A — heavy, 140bpm, distorted, aggressive drums
	print("Generating volcano.wav...")
	var bpm := 140.0
	var chords := [
		{bass = NOTE_D2, notes = [NOTE_D3, NOTE_F3, NOTE_A3]},
		{bass = NOTE_D2, notes = [NOTE_D3, NOTE_F3, NOTE_A3]},
		{bass = NOTE_Bb2, notes = [NOTE_Bb3, NOTE_D4, NOTE_F4]},
		{bass = NOTE_A2, notes = [NOTE_A3, NOTE_C4 + 17.32, NOTE_E4]},  # A major
	]
	var num_samples := int(DURATION * SAMPLE_RATE)
	var samples := PackedFloat32Array()
	samples.resize(num_samples)

	for i in range(num_samples):
		var t := float(i) / SAMPLE_RATE
		var ci := _chord_index(t, bpm, 4)
		var chord: Dictionary = chords[ci]
		var bi := _beat_info(t, bpm)
		var out := 0.0

		# Heavy distorted bass
		var bass_phase: float = t * chord.bass / float(SAMPLE_RATE)
		var bass_raw := _saw(bass_phase) * 0.4 + _square(bass_phase * 0.5) * 0.2
		out += clampf(bass_raw * 2.5, -0.4, 0.4)  # Distortion

		# Power chord - root + fifth, distorted
		var root_freq: float = chord.notes[0]
		var fifth_freq: float = root_freq * 1.5
		var pr: float = t * root_freq / float(SAMPLE_RATE)
		var pf: float = t * fifth_freq / float(SAMPLE_RATE)
		var power := _square(pr) * 0.12 + _square(pf) * 0.08
		out += clampf(power * 2.0, -0.2, 0.2)

		# Aggressive drums - double kick pattern
		if bi.num % 4 == 0 or bi.num % 4 == 1:
			out += _kick(bi.frac) * 0.6
		if bi.num % 2 == 0:
			var half_frac: float = fmod(bi.frac * 2.0, 1.0)
			if half_frac < 0.12:
				out += _kick(half_frac / 0.12) * 0.3  # Extra ghost kick
		# Snare on 2 and 4
		if bi.num % 4 == 2 or bi.num % 4 == 3:
			out += _snare(bi.frac) * 0.4
		# Fast hihats
		var hh16: float = fmod(bi.frac * 4.0, 1.0)
		out += _hihat(hh16) * 0.4

		# Rumble - low noise
		out += _noise() * 0.03

		samples[i] = out * 0.6

	_save_wav(samples, "volcano.wav")


func _gen_ocean() -> void:
	## Cmaj7-Am7-Fmaj7-G — dreamy, 85bpm, soft sine, no drums
	print("Generating ocean.wav...")
	var bpm := 85.0
	var chords := [
		{bass = NOTE_C3, notes = [NOTE_C4, NOTE_E4, NOTE_G4, NOTE_B4]},      # Cmaj7
		{bass = NOTE_A2, notes = [NOTE_A3, NOTE_C4, NOTE_E4, NOTE_G4]},      # Am7
		{bass = NOTE_F2, notes = [NOTE_F3, NOTE_A3, NOTE_C4, NOTE_E4]},      # Fmaj7
		{bass = NOTE_G2, notes = [NOTE_G3, NOTE_B3, NOTE_D4]},               # G
	]
	var melody := [NOTE_B4, NOTE_G4, NOTE_E4, NOTE_D5]
	var num_samples := int(DURATION * SAMPLE_RATE)
	var samples := PackedFloat32Array()
	samples.resize(num_samples)

	for i in range(num_samples):
		var t := float(i) / SAMPLE_RATE
		var ci := _chord_index(t, bpm, 4)
		var chord: Dictionary = chords[ci]
		var out := 0.0

		# Gentle bass with slow swell
		var bass_phase: float = t * chord.bass / float(SAMPLE_RATE)
		var swell := 0.7 + 0.3 * _sine(t * 0.15)
		out += _sine(bass_phase) * 0.15 * swell

		# Shimmering pad - heavily detuned sine layers
		for note_freq: float in chord.notes:
			var p1 := t * note_freq / float(SAMPLE_RATE)
			var p2 := t * (note_freq * 1.004) / float(SAMPLE_RATE)
			var p3 := t * (note_freq * 0.996) / float(SAMPLE_RATE)
			out += (_sine(p1) + _sine(p2) + _sine(p3)) * 0.045 * swell

		# Gentle melody with long attack
		var mel_freq: float = melody[ci]
		var mel_phase: float = t * mel_freq / float(SAMPLE_RATE)
		var bar_dur := 60.0 / bpm * 4.0
		var bar_pos := fmod(t, bar_dur) / bar_dur
		var mel_env := _env_adsr(bar_pos, 0.3, 0.2, 0.5, 0.3, 1.0)
		out += _sine(mel_phase) * mel_env * 0.1

		# Wave-like noise (ocean ambience)
		var wave := absf(_sine(t * 0.08)) * 0.03
		out += _noise() * wave

		samples[i] = out * 0.7

	_save_wav(samples, "ocean.wav")


func _gen_arena() -> void:
	## Dm-F-C-Dm — epic, 130bpm, brass-like square, heavy drums
	print("Generating arena.wav...")
	var bpm := 130.0
	var chords := [
		{bass = NOTE_D2, notes = [NOTE_D3, NOTE_F3, NOTE_A3]},
		{bass = NOTE_F2, notes = [NOTE_F3, NOTE_A3, NOTE_C4]},
		{bass = NOTE_C3, notes = [NOTE_C4, NOTE_E4, NOTE_G4]},
		{bass = NOTE_D2, notes = [NOTE_D3, NOTE_F3, NOTE_A3]},
	]
	var melody := [NOTE_D5, NOTE_C5, NOTE_E5, NOTE_A4]
	var num_samples := int(DURATION * SAMPLE_RATE)
	var samples := PackedFloat32Array()
	samples.resize(num_samples)

	for i in range(num_samples):
		var t := float(i) / SAMPLE_RATE
		var ci := _chord_index(t, bpm, 4)
		var chord: Dictionary = chords[ci]
		var bi := _beat_info(t, bpm)
		var out := 0.0

		# Punchy bass - octave hits on beats
		var bass_phase: float = t * chord.bass / float(SAMPLE_RATE)
		var bass_env := _env_decay(bi.frac, 0.4)
		out += _sine(bass_phase) * 0.22 * bass_env
		out += _sine(bass_phase * 2.0) * 0.1 * bass_env

		# Brass-like chords - square with envelope for attack bite
		for note_freq: float in chord.notes:
			var p := t * note_freq / float(SAMPLE_RATE)
			var brass_env := _env_adsr(bi.frac, 0.05, 0.15, 0.6, 0.1, 1.0)
			out += _soft_square(p) * brass_env * 0.07

		# Heroic melody
		var mel_freq: float = melody[ci]
		var mel_phase: float = t * mel_freq / float(SAMPLE_RATE)
		if bi.num % 2 == 0:
			var mel_env := _env_adsr(bi.frac, 0.05, 0.1, 0.7, 0.2, 1.0)
			out += _soft_square(mel_phase) * mel_env * 0.1
			out += _sine(mel_phase) * mel_env * 0.06

		# Heavy drums - kick on 1,3 snare on 2,4
		if bi.num % 4 == 0 or bi.num % 4 == 2:
			out += _kick(bi.frac) * 0.55
		if bi.num % 4 == 1 or bi.num % 4 == 3:
			out += _snare(bi.frac) * 0.4
		out += _hihat(bi.frac) * 0.4

		samples[i] = out * 0.6

	_save_wav(samples, "arena.wav")


func _gen_space() -> void:
	## Am-Em-F-C — floating, 90bpm, detuned pads, minimal
	print("Generating space.wav...")
	var bpm := 90.0
	var chords := [
		{bass = NOTE_A2, notes = [NOTE_A3, NOTE_C4, NOTE_E4]},
		{bass = NOTE_E2, notes = [NOTE_E3, NOTE_G3, NOTE_B3]},
		{bass = NOTE_F2, notes = [NOTE_F3, NOTE_A3, NOTE_C4]},
		{bass = NOTE_C3, notes = [NOTE_C4, NOTE_E4, NOTE_G4]},
	]
	var num_samples := int(DURATION * SAMPLE_RATE)
	var samples := PackedFloat32Array()
	samples.resize(num_samples)

	for i in range(num_samples):
		var t := float(i) / SAMPLE_RATE
		var ci := _chord_index(t, bpm, 4)
		var chord: Dictionary = chords[ci]
		var out := 0.0

		# Sub bass - very deep sine
		var bass_phase: float = t * chord.bass / float(SAMPLE_RATE)
		out += _sine(bass_phase) * 0.18

		# Detuned floating pads - multiple layers with slow beating
		for note_freq: float in chord.notes:
			var p1 := t * note_freq / float(SAMPLE_RATE)
			var p2 := t * (note_freq * 1.006) / float(SAMPLE_RATE)
			var p3 := t * (note_freq * 0.994) / float(SAMPLE_RATE)
			var p4 := t * (note_freq * 0.5) / float(SAMPLE_RATE)  # Sub octave
			out += (_sine(p1) + _sine(p2) + _sine(p3)) * 0.05
			out += _sine(p4) * 0.02

		# Sparse high pings (stars twinkling)
		var ping_hash := int(t * 3.0)
		if ping_hash % 7 == 0:
			var ping_t := fmod(t * 3.0, 1.0)
			if ping_t < 0.3:
				var ping_freq := 800.0 + float(ping_hash % 5) * 200.0
				var ping_phase: float = t * ping_freq / float(SAMPLE_RATE)
				out += _sine(ping_phase) * _env_decay(ping_t, 0.3) * 0.08

		# Slow LFO filter sweep feel
		var sweep := 0.6 + 0.4 * _sine(t * 0.1)
		out *= sweep

		# Very minimal percussion - just a soft pulse
		var bi := _beat_info(t, bpm)
		if bi.num % 8 == 0:
			out += _kick(bi.frac) * 0.2

		samples[i] = out * 0.7

	_save_wav(samples, "space.wav")


func _gen_castle() -> void:
	## Dm-A-Bb-Gm — gothic waltz, 115bpm, 3/4 time, harpsichord-like
	print("Generating castle.wav...")
	var bpm := 115.0
	var chords := [
		{bass = NOTE_D2, notes = [NOTE_D3, NOTE_F3, NOTE_A3]},
		{bass = NOTE_A2, notes = [NOTE_A3, NOTE_C4 + 17.32, NOTE_E4]},  # A major
		{bass = NOTE_Bb2, notes = [NOTE_Bb3, NOTE_D4, NOTE_F4]},
		{bass = NOTE_G2, notes = [NOTE_G3, NOTE_Bb3, NOTE_D4]},          # Gm
	]
	var melody := [NOTE_A4, NOTE_E5, NOTE_D5, NOTE_Bb4]
	var num_samples := int(DURATION * SAMPLE_RATE)
	var samples := PackedFloat32Array()
	samples.resize(num_samples)

	# 3/4 time - 3 beats per bar
	for i in range(num_samples):
		var t := float(i) / SAMPLE_RATE
		var ci := _chord_index(t, bpm, 3)  # 3 beats per bar!
		var chord: Dictionary = chords[ci]
		var bi := _beat_info(t, bpm)
		var out := 0.0

		# Waltz bass - root on beat 1, chord on 2 and 3
		var bass_phase: float = t * chord.bass / float(SAMPLE_RATE)
		var beat_in_bar: int = bi.num % 3
		if beat_in_bar == 0:
			var be := _env_decay(bi.frac, 0.5)
			out += _triangle(bass_phase) * 0.22 * be
		else:
			# Higher chord stabs on beats 2-3
			for note_freq: float in chord.notes:
				var p := t * note_freq / float(SAMPLE_RATE)
				var ce := _env_decay(bi.frac, 0.25)
				out += _square(p) * ce * 0.04

		# Harpsichord melody - fast attack, quick decay (plucked string character)
		var mel_freq: float = melody[ci]
		var mel_phase: float = t * mel_freq / float(SAMPLE_RATE)
		if beat_in_bar == 0 or beat_in_bar == 2:
			var harp_env := _env_decay(bi.frac, 0.3)
			# Harpsichord = sharp attack with harmonics
			out += _square(mel_phase) * harp_env * 0.07
			out += _sine(mel_phase * 2.0) * harp_env * 0.04
			out += _sine(mel_phase * 3.0) * harp_env * 0.02

		# Waltz drums - bass on 1, light tick on 2,3
		if beat_in_bar == 0:
			out += _kick(bi.frac) * 0.35
		else:
			out += _hihat(bi.frac) * 0.4

		samples[i] = out * 0.65

	_save_wav(samples, "castle.wav")


func _gen_candy() -> void:
	## C-F-G-C — happy chiptune, 140bpm, bright square, bouncy
	print("Generating candy.wav...")
	var bpm := 140.0
	var chords := [
		{bass = NOTE_C3, notes = [NOTE_C4, NOTE_E4, NOTE_G4]},
		{bass = NOTE_F2, notes = [NOTE_F3, NOTE_A3, NOTE_C4]},
		{bass = NOTE_G2, notes = [NOTE_G3, NOTE_B3, NOTE_D4]},
		{bass = NOTE_C3, notes = [NOTE_C4, NOTE_E4, NOTE_G4]},
	]
	# Bouncy melody - more notes for chiptune feel
	var melody_seq := [NOTE_C5, NOTE_E5, NOTE_G5, NOTE_E5, NOTE_F5, NOTE_A5, NOTE_G5, NOTE_F5,
					   NOTE_G5, NOTE_B4, NOTE_D5, NOTE_B4, NOTE_C5, NOTE_E5, NOTE_G5, NOTE_C5]
	var num_samples := int(DURATION * SAMPLE_RATE)
	var samples := PackedFloat32Array()
	samples.resize(num_samples)

	for i in range(num_samples):
		var t := float(i) / SAMPLE_RATE
		var ci := _chord_index(t, bpm, 4)
		var chord: Dictionary = chords[ci]
		var bi := _beat_info(t, bpm)
		var out := 0.0

		# Bouncy bass - 8th note pattern
		var bass_phase: float = t * chord.bass / float(SAMPLE_RATE)
		var eighth_frac: float = fmod(bi.frac * 2.0, 1.0)
		var bass_env := _env_decay(eighth_frac, 0.4)
		out += _square(bass_phase) * bass_env * 0.12

		# Bright chord stabs on offbeats
		if bi.frac > 0.5:
			var stab_frac: float = (bi.frac - 0.5) * 2.0
			var stab_env := _env_decay(stab_frac, 0.3)
			for note_freq: float in chord.notes:
				var p := t * note_freq / float(SAMPLE_RATE)
				out += _square(p) * stab_env * 0.04

		# Fast chiptune melody - 16th notes
		var beat_dur := 60.0 / bpm
		var loop_dur := beat_dur * 16.0  # Full 4-bar loop in beats
		var mel_pos := fmod(t, loop_dur)
		var mel_idx := int(mel_pos / beat_dur) % melody_seq.size()
		var mel_freq: float = melody_seq[mel_idx]
		var mel_phase: float = t * mel_freq / float(SAMPLE_RATE)
		var mel_frac := fmod(mel_pos / beat_dur, 1.0)
		var mel_env := _env_decay(mel_frac, 0.6)
		out += _square(mel_phase) * mel_env * 0.1

		# Punchy drums
		if bi.num % 4 == 0 or bi.num % 4 == 2:
			out += _kick(bi.frac) * 0.45
		if bi.num % 4 == 1 or bi.num % 4 == 3:
			out += _snare(bi.frac) * 0.3
		out += _hihat(bi.frac) * 0.4

		samples[i] = out * 0.55

	_save_wav(samples, "candy.wav")


func _gen_boss() -> void:
	## Am-Am-F-E — intense, 160bpm, aggressive, fast drums, urgent
	print("Generating boss.wav...")
	var bpm := 160.0
	var chords := [
		{bass = NOTE_A2, notes = [NOTE_A3, NOTE_C4, NOTE_E4]},
		{bass = NOTE_A2, notes = [NOTE_A3, NOTE_C4, NOTE_E4]},
		{bass = NOTE_F2, notes = [NOTE_F3, NOTE_A3, NOTE_C4]},
		{bass = NOTE_E2, notes = [NOTE_E3, NOTE_G3 + 15.56, NOTE_B3]},  # E major
	]
	var melody := [NOTE_E5, NOTE_A5, NOTE_C5, NOTE_B4]
	var num_samples := int(DURATION * SAMPLE_RATE)
	var samples := PackedFloat32Array()
	samples.resize(num_samples)

	for i in range(num_samples):
		var t := float(i) / SAMPLE_RATE
		var ci := _chord_index(t, bpm, 4)
		var chord: Dictionary = chords[ci]
		var bi := _beat_info(t, bpm)
		var out := 0.0

		# Aggressive pulsing bass
		var bass_phase: float = t * chord.bass / float(SAMPLE_RATE)
		var pulse := 0.5 + 0.5 * _square(t * 4.0 / float(SAMPLE_RATE) * SAMPLE_RATE * 0.0001)
		out += _saw(bass_phase) * 0.22 * pulse
		out += _sine(bass_phase * 0.5) * 0.12  # Sub

		# Aggressive power chords
		for note_freq: float in chord.notes:
			var p := t * note_freq / float(SAMPLE_RATE)
			var raw := _saw(p) * 0.08 + _square(p) * 0.05
			out += clampf(raw * 1.8, -0.12, 0.12)

		# Urgent melody - fast rhythmic pattern
		var mel_freq: float = melody[ci]
		var mel_phase: float = t * mel_freq / float(SAMPLE_RATE)
		var sixteenth: float = fmod(bi.frac * 4.0, 1.0)
		var mel_env := _env_decay(sixteenth, 0.5)
		# Play on 16th notes 1,2,4 (rest on 3 for syncopation)
		var sixteenth_idx := int(bi.frac * 4.0) % 4
		if sixteenth_idx != 2:
			out += _square(mel_phase) * mel_env * 0.09

		# Intense drums - double bass, fast hihats
		# Kick on every 8th note
		var eighth_frac: float = fmod(bi.frac * 2.0, 1.0)
		out += _kick(eighth_frac) * 0.45
		# Snare on 2 and 4
		if bi.num % 4 == 2 or bi.num % 4 == 3:
			out += _snare(bi.frac) * 0.35
		# 16th note hihats
		var hh_frac: float = fmod(bi.frac * 4.0, 1.0)
		out += _hihat(hh_frac) * 0.35

		# Urgency - slight pitch wobble
		var urgency := 1.0 + 0.003 * sin(t * 8.0 * TAU)
		out *= urgency

		samples[i] = out * 0.6

	_save_wav(samples, "boss.wav")
