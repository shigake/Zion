extends SceneTree

## Generates 4 additional procedural music tracks as .wav files.
## Each track is 30 seconds, mono 16-bit at 44100 Hz.
## Run: godot --headless --script res://scripts/tools/music_generator_v2.gd

const SAMPLE_RATE := 44100
const DURATION := 30.0

func _init() -> void:
	DirAccess.make_dir_recursive_absolute("res://assets/audio/music/")

	print("=== Music Generator V2 ===")
	print("Generating 4 additional tracks (30s each, 44100Hz)...")

	_gen_victory()
	_gen_shop()
	_gen_lobby()
	_gen_game_over_music()

	print("All 4 additional music tracks generated!")
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
	file.store_16(1)        # PCM
	file.store_16(1)        # Mono
	file.store_32(SAMPLE_RATE)
	file.store_32(SAMPLE_RATE * 2)
	file.store_16(2)        # Block align
	file.store_16(16)       # Bits per sample
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

func _beat_info(t: float, bpm: float) -> Dictionary:
	var beat_dur := 60.0 / bpm
	var beat_num := int(t / beat_dur)
	var beat_frac := fmod(t, beat_dur) / beat_dur
	return {"num": beat_num, "frac": beat_frac, "dur": beat_dur}

func _chord_index(t: float, bpm: float, beats_per_bar: int) -> int:
	var beat_dur := 60.0 / bpm
	var bar_dur := beat_dur * beats_per_bar
	var loop_dur := bar_dur * 4.0
	var pos := fmod(t, loop_dur)
	return int(pos / bar_dur)

func _kick(beat_frac: float) -> float:
	if beat_frac > 0.15:
		return 0.0
	var kt := beat_frac / 0.15
	var freq := lerpf(150.0, 50.0, kt)
	return _sine(kt * freq * 0.15) * (1.0 - kt) * 0.8

func _snare(beat_frac: float) -> float:
	if beat_frac > 0.1:
		return 0.0
	var st := beat_frac / 0.1
	return _noise() * (1.0 - st) * 0.4

func _hihat(beat_frac: float) -> float:
	if beat_frac > 0.05:
		return 0.0
	var ht := beat_frac / 0.05
	return _noise() * (1.0 - ht) * 0.15

# Cymbal crash - longer noise with decay
func _cymbal(beat_frac: float) -> float:
	if beat_frac > 0.4:
		return 0.0
	var ct := beat_frac / 0.4
	return _noise() * (1.0 - ct) * 0.25

# ===== NOTE FREQUENCIES =====

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
const NOTE_Eb3 := 155.56
const NOTE_E3 := 164.81
const NOTE_F3 := 174.61
const NOTE_G3 := 196.0
const NOTE_Ab3 := 207.65
const NOTE_A3 := 220.0
const NOTE_Bb3 := 233.08
const NOTE_B3 := 246.94

const NOTE_C4 := 261.63
const NOTE_D4 := 293.66
const NOTE_Eb4 := 311.13
const NOTE_E4 := 329.63
const NOTE_F4 := 349.23
const NOTE_G4 := 392.0
const NOTE_Ab4 := 415.30
const NOTE_A4 := 440.0
const NOTE_Bb4 := 466.16
const NOTE_B4 := 493.88

const NOTE_C5 := 523.25
const NOTE_D5 := 587.33
const NOTE_Eb5 := 622.25
const NOTE_E5 := 659.25
const NOTE_F5 := 698.46
const NOTE_G5 := 783.99
const NOTE_A5 := 880.0
const NOTE_B5 := 987.77

const NOTE_C6 := 1046.50

# ===== TRACK GENERATORS =====

func _gen_victory() -> void:
	## C-F-G-C — triumphant ascending major, 120bpm, bright chiptune fanfare
	print("Generating victory.wav...")
	var bpm := 120.0
	var chords := [
		{bass = NOTE_C3, notes = [NOTE_C4, NOTE_E4, NOTE_G4]},
		{bass = NOTE_F2, notes = [NOTE_F3, NOTE_A3, NOTE_C4]},
		{bass = NOTE_G2, notes = [NOTE_G3, NOTE_B3, NOTE_D4]},
		{bass = NOTE_C3, notes = [NOTE_C4, NOTE_E4, NOTE_G4]},
	]
	# Ascending arpeggio melody for triumphant feel
	var melody_patterns := [
		[NOTE_C5, NOTE_E5, NOTE_G5, NOTE_C6],   # C major ascending
		[NOTE_F4, NOTE_A4, NOTE_C5, NOTE_F5],    # F major ascending
		[NOTE_G4, NOTE_B4, NOTE_D5, NOTE_G5],    # G major ascending
		[NOTE_C5, NOTE_E5, NOTE_G5, NOTE_C6],    # C major ascending (repeat high)
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

		# Strong punchy bass - square wave
		var bass_phase: float = t * chord.bass / float(SAMPLE_RATE)
		out += _soft_square(bass_phase) * 0.18

		# Bright chiptune chords - square wave pads
		for note_freq: float in chord.notes:
			var p := t * note_freq / float(SAMPLE_RATE)
			out += _square(p) * 0.06
			out += _sine(p * 2.0) * 0.02  # Octave shimmer

		# Ascending arpeggio melody — one note per beat, cycles through 4 notes
		var mel_arr: Array = melody_patterns[ci]
		var mel_idx: int = int(bi.num) % 4
		var mel_freq: float = mel_arr[mel_idx]
		var mel_phase: float = t * mel_freq / float(SAMPLE_RATE)
		var mel_env := _env_adsr(bi.frac, 0.05, 0.15, 0.6, 0.2, 1.0)
		out += _square(mel_phase) * mel_env * 0.12
		# Add an octave above for brightness
		out += _sine(mel_phase * 2.0) * mel_env * 0.04

		# Counter melody - descending on off-beats for call/response
		if int(bi.num) % 2 == 1:
			var counter_freq: float = mel_arr[3 - mel_idx]  # Reverse
			var counter_phase: float = t * counter_freq * 0.5 / float(SAMPLE_RATE)
			var counter_env := _env_decay(bi.frac, 0.4)
			out += _triangle(counter_phase) * counter_env * 0.06

		# Energetic drums — kick on 1&3, snare on 2&4, hi-hat on all
		if int(bi.num) % 4 == 0 or int(bi.num) % 4 == 2:
			out += _kick(bi.frac) * 0.35
		if int(bi.num) % 4 == 1 or int(bi.num) % 4 == 3:
			out += _snare(bi.frac) * 0.25
		out += _hihat(bi.frac) * 0.8

		# Cymbal crash at start of each chord change
		var bar_beat: int = int(bi.num) % 16  # 4 bars of 4 beats
		if bar_beat == 0:
			out += _cymbal(bi.frac) * 0.5

		# Slight volume swell for drama
		var global_env := minf(t / 0.5, 1.0)  # Fade in first 0.5s
		samples[i] = out * 0.65 * global_env

	_save_wav(samples, "victory.wav")


func _gen_shop() -> void:
	## F-Dm-Bb-C — calm, gentle, coin-collecting feel, 90bpm, soft sine
	print("Generating shop.wav...")
	var bpm := 90.0
	var chords := [
		{bass = NOTE_F2, notes = [NOTE_F3, NOTE_A3, NOTE_C4]},
		{bass = NOTE_D2, notes = [NOTE_D3, NOTE_F3, NOTE_A3]},
		{bass = NOTE_Bb2, notes = [NOTE_Bb3, NOTE_D4, NOTE_F4]},
		{bass = NOTE_C3, notes = [NOTE_C4, NOTE_E4, NOTE_G4]},
	]
	# Gentle melody - coin-like tinkle notes
	var melody_notes := [
		[NOTE_A4, NOTE_C5, NOTE_F5, NOTE_C5],
		[NOTE_F4, NOTE_A4, NOTE_D5, NOTE_A4],
		[NOTE_D5, NOTE_F5, NOTE_Bb4, NOTE_D5],
		[NOTE_E5, NOTE_G4, NOTE_C5, NOTE_E5],
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

		# Very soft sine bass - warm and round
		var bass_phase: float = t * chord.bass / float(SAMPLE_RATE)
		out += _sine(bass_phase) * 0.15

		# Soft pad - detuned sines for warmth (like the menu track)
		for note_freq: float in chord.notes:
			var p1 := t * note_freq / float(SAMPLE_RATE)
			var p2 := t * (note_freq * 1.004) / float(SAMPLE_RATE)
			var p3 := t * (note_freq * 0.996) / float(SAMPLE_RATE)
			out += (_sine(p1) + _sine(p2) + _sine(p3)) * 0.04

		# Tinkle melody - bell-like sine with fast harmonics (coin feel)
		var mel_arr: Array = melody_notes[ci]
		var mel_idx: int = int(bi.num) % 4
		var mel_freq: float = mel_arr[mel_idx]
		var mel_phase: float = t * mel_freq / float(SAMPLE_RATE)
		var mel_env := _env_decay(bi.frac, 0.5)
		out += _sine(mel_phase) * mel_env * 0.12
		# Bell overtone (non-harmonic for metallic coin sound)
		out += _sine(mel_phase * 2.76) * mel_env * 0.04
		out += _sine(mel_phase * 4.07) * mel_env * 0.02

		# Second melody layer: slower, plays every other beat
		if int(bi.num) % 2 == 0:
			var slow_freq: float = mel_arr[0] * 0.5  # Octave below
			var slow_phase: float = t * slow_freq / float(SAMPLE_RATE)
			var slow_env := _env_adsr(bi.frac, 0.1, 0.3, 0.3, 0.3, 1.0)
			out += _triangle(slow_phase) * slow_env * 0.06

		# Very light percussion - just a soft hi-hat on every beat
		out += _hihat(bi.frac) * 0.3
		# Gentle kick on beat 1 only
		if int(bi.num) % 4 == 0:
			out += _kick(bi.frac) * 0.15

		# LFO for gentle pulsing
		var lfo := 0.9 + 0.1 * _sine(t * 0.4)
		out *= lfo

		samples[i] = out * 0.6

	_save_wav(samples, "shop.wav")


func _gen_lobby() -> void:
	## G-Em-C-D — upbeat waiting room, 100bpm, friendly chiptune
	print("Generating lobby.wav...")
	var bpm := 100.0
	var chords := [
		{bass = NOTE_G2, notes = [NOTE_G3, NOTE_B3, NOTE_D4]},
		{bass = NOTE_E2, notes = [NOTE_E3, NOTE_G3, NOTE_B3]},
		{bass = NOTE_C3, notes = [NOTE_C4, NOTE_E4, NOTE_G4]},
		{bass = NOTE_D2, notes = [NOTE_D3, NOTE_A3, NOTE_D4]},  # Dsus4 feel
	]
	# Bouncy melody
	var melody_patterns := [
		[NOTE_D5, NOTE_B4, NOTE_G4, NOTE_B4],
		[NOTE_B4, NOTE_G4, NOTE_E4, NOTE_G4],
		[NOTE_E5, NOTE_C5, NOTE_G4, NOTE_C5],
		[NOTE_D5, NOTE_A4, NOTE_D4, NOTE_A4],
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

		# Bouncy bass - square with short decay for rhythmic feel
		var bass_phase: float = t * chord.bass / float(SAMPLE_RATE)
		var bass_env := _env_adsr(bi.frac, 0.02, 0.15, 0.4, 0.1, 1.0)
		out += _soft_square(bass_phase) * bass_env * 0.18

		# Chiptune chord stabs on off-beats (beats 2 and 4)
		if int(bi.num) % 2 == 1:
			for note_freq: float in chord.notes:
				var p := t * note_freq / float(SAMPLE_RATE)
				var stab_env := _env_decay(bi.frac, 0.3)
				out += _square(p) * stab_env * 0.05

		# Main melody - bouncy, each beat plays a note
		var mel_arr: Array = melody_patterns[ci]
		var mel_idx: int = int(bi.num) % 4
		var mel_freq: float = mel_arr[mel_idx]
		var mel_phase: float = t * mel_freq / float(SAMPLE_RATE)
		var mel_env := _env_adsr(bi.frac, 0.03, 0.1, 0.5, 0.2, 1.0)
		out += _triangle(mel_phase) * mel_env * 0.14

		# Arpeggio layer — quick 16th note arpeggios on sustained chords
		var beat_dur := 60.0 / bpm
		var sub_beat := fmod(t, beat_dur) / beat_dur
		var arp_idx := int(sub_beat * 4) % 3  # 3 notes in arpeggio
		var arp_freq: float = chord.notes[arp_idx]
		var arp_phase: float = t * arp_freq * 2.0 / float(SAMPLE_RATE)  # Octave up
		var arp_env := _env_decay(fmod(sub_beat * 4.0, 1.0), 0.6)
		out += _sine(arp_phase) * arp_env * 0.05

		# Fun drums — kick on 1&3, snare on 2&4, hi-hat on 8ths
		if int(bi.num) % 4 == 0 or int(bi.num) % 4 == 2:
			out += _kick(bi.frac) * 0.3
		if int(bi.num) % 4 == 1 or int(bi.num) % 4 == 3:
			out += _snare(bi.frac) * 0.2
		# Hi-hat on 8th notes
		var eighth_frac := fmod(bi.frac * 2.0, 1.0)
		out += _hihat(eighth_frac) * 0.5

		samples[i] = out * 0.6

	_save_wav(samples, "lobby.wav")


func _gen_game_over_music() -> void:
	## Am-Dm-Em-Am — sad, slow, minor key, 80bpm, melancholic
	print("Generating game_over_music.wav...")
	var bpm := 80.0
	var chords := [
		{bass = NOTE_A2, notes = [NOTE_A3, NOTE_C4, NOTE_E4]},
		{bass = NOTE_D2, notes = [NOTE_D3, NOTE_F3, NOTE_A3]},
		{bass = NOTE_E2, notes = [NOTE_E3, NOTE_G3, NOTE_B3]},
		{bass = NOTE_A2, notes = [NOTE_A3, NOTE_C4, NOTE_E4]},
	]
	# Descending minor melody for sadness
	var melody_notes := [
		[NOTE_E5, NOTE_C5, NOTE_A4, NOTE_E4],   # Descending Am
		[NOTE_F4, NOTE_D4, NOTE_A3, NOTE_D4],    # Descending Dm
		[NOTE_G4, NOTE_E4, NOTE_B3, NOTE_E4],    # Descending Em
		[NOTE_C5, NOTE_A4, NOTE_E4, NOTE_A3],    # Final descent Am
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

		# Deep, mournful bass - slow sine
		var bass_phase: float = t * chord.bass / float(SAMPLE_RATE)
		out += _sine(bass_phase) * 0.2
		# Sub-bass for weight
		out += _sine(bass_phase * 0.5) * 0.08

		# Sorrowful pad - detuned sines, wider detune for dissonance
		for note_freq: float in chord.notes:
			var p1 := t * note_freq / float(SAMPLE_RATE)
			var p2 := t * (note_freq * 1.005) / float(SAMPLE_RATE)
			var p3 := t * (note_freq * 0.995) / float(SAMPLE_RATE)
			out += (_sine(p1) + _sine(p2) + _sine(p3)) * 0.05

		# Descending melody - slow, each beat a step down
		var mel_arr: Array = melody_notes[ci]
		var mel_idx: int = int(bi.num) % 4
		var mel_freq: float = mel_arr[mel_idx]
		var mel_phase: float = t * mel_freq / float(SAMPLE_RATE)
		# Long, sustained notes with slow attack (crying feel)
		var mel_env := _env_adsr(bi.frac, 0.2, 0.2, 0.5, 0.3, 1.0)
		out += _sine(mel_phase) * mel_env * 0.13
		# Slight vibrato for emotion
		var vibrato := sin(t * 5.5 * TAU) * 0.005
		out += _sine(mel_phase * (1.0 + vibrato)) * mel_env * 0.05

		# Ghost notes - very quiet triangle echoes
		if int(bi.num) % 3 == 0:
			var ghost_freq: float = mel_freq * 0.5
			var ghost_phase: float = t * ghost_freq / float(SAMPLE_RATE)
			var ghost_env := _env_decay(bi.frac, 0.8)
			out += _triangle(ghost_phase) * ghost_env * 0.04

		# No snare/hi-hat — just a very soft kick on beat 1 of each bar
		if int(bi.num) % 4 == 0:
			out += _kick(bi.frac) * 0.15

		# Overall slow tremolo (heartbeat-like)
		var lfo := 0.85 + 0.15 * _sine(t * 0.25)
		out *= lfo

		# Fade out over last 3 seconds
		var fade_out := 1.0
		if t > DURATION - 3.0:
			fade_out = maxf(0.0, (DURATION - t) / 3.0)

		samples[i] = out * 0.6 * fade_out

	_save_wav(samples, "game_over_music.wav")
