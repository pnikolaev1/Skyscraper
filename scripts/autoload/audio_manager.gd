extends Node
# music bus + sfx bus. if we dont have real audio files we just synthesize beep tones
# so the game isnt totally silent on a fresh checkout

const MUSIC_BUS := "Music"
const SFX_BUS := "SFX"
# one song for the whole game (menu + gameplay use the same track)
const BACKGROUND_MUSIC_PATH := "res://assets/audio/music/background.mp3"

var _music_player: AudioStreamPlayer
var _sfx_players: Array[AudioStreamPlayer] = []
var _sfx_index: int = 0
const SFX_VOICES := 8

# tone cache so we dont rebuild the same waveform over and over
var _tone_cache: Dictionary = {}

func _ready() -> void:
	# make the buses if they arent already there
	if AudioServer.get_bus_index(MUSIC_BUS) == -1:
		AudioServer.add_bus()
		AudioServer.set_bus_name(AudioServer.bus_count - 1, MUSIC_BUS)
		AudioServer.set_bus_send(AudioServer.bus_count - 1, "Master")
	if AudioServer.get_bus_index(SFX_BUS) == -1:
		AudioServer.add_bus()
		AudioServer.set_bus_name(AudioServer.bus_count - 1, SFX_BUS)
		AudioServer.set_bus_send(AudioServer.bus_count - 1, "Master")

	_music_player = AudioStreamPlayer.new()
	_music_player.bus = MUSIC_BUS
	add_child(_music_player)

	for i in range(SFX_VOICES):
		var p := AudioStreamPlayer.new()
		p.bus = SFX_BUS
		add_child(p)
		_sfx_players.append(p)

	# load whatever volumes the user had last time
	apply_settings()
	SaveSystem.save_loaded.connect(apply_settings)

func apply_settings() -> void:
	set_music_volume(SaveSystem.get_music_vol())
	set_sfx_volume(SaveSystem.get_sfx_vol())

func set_music_volume(v: float) -> void:
	var idx := AudioServer.get_bus_index(MUSIC_BUS)
	if idx >= 0:
		AudioServer.set_bus_volume_db(idx, linear_to_db(max(0.0001, v)))

func set_sfx_volume(v: float) -> void:
	var idx := AudioServer.get_bus_index(SFX_BUS)
	if idx >= 0:
		AudioServer.set_bus_volume_db(idx, linear_to_db(max(0.0001, v)))

# ---------------- music ----------------
func play_music(_id: String) -> void:
	# just plays the one background track. id is ignored - same song everywhere
	if ResourceLoader.exists(BACKGROUND_MUSIC_PATH):
		var s: AudioStream = load(BACKGROUND_MUSIC_PATH)
		if s is AudioStreamMP3:
			(s as AudioStreamMP3).loop = true
		elif s is AudioStreamOggVorbis:
			(s as AudioStreamOggVorbis).loop = true
		if s and _music_player.stream != s:
			_music_player.stream = s
			_music_player.play()
		elif s and not _music_player.playing:
			_music_player.play()
		return
	# file missing for some reason - fall back to a tone so its not totally silent
	var tone := _get_or_build_ambient("gameplay")
	if _music_player.stream != tone:
		_music_player.stream = tone
		_music_player.play()
	elif not _music_player.playing:
		_music_player.play()

func stop_music() -> void:
	_music_player.stop()

# ---------------- sfx ----------------
func play_sfx(id: String, pitch: float = 1.0, volume_db: float = 0.0) -> void:
	var stream: AudioStream = null
	var path := "res://assets/audio/sfx/%s.wav" % id
	if ResourceLoader.exists(path):
		stream = load(path)
	if stream == null:
		stream = _get_or_build_sfx(id)
	var p := _next_sfx_player()
	p.stream = stream
	p.pitch_scale = pitch
	p.volume_db = volume_db
	p.play()

func _next_sfx_player() -> AudioStreamPlayer:
	var p := _sfx_players[_sfx_index]
	_sfx_index = (_sfx_index + 1) % _sfx_players.size()
	return p

# ---------------- procedural tones ----------------
# yeah its a bit ghetto but it works without any external assets
func _get_or_build_sfx(id: String) -> AudioStreamWAV:
	if _tone_cache.has(id):
		return _tone_cache[id]
	var s: AudioStreamWAV
	match id:
		"click":
			s = _build_tone(880.0, 0.05, 0.4, false)
		"whoosh":
			s = _build_noise(0.25, 0.5)
		"thud_good":
			s = _build_tone(220.0, 0.15, 0.6, true)
		"chime_perfect":
			s = _build_chord([880.0, 1320.0, 1760.0], 0.35, 0.5)
		"thunk_miss":
			s = _build_tone(110.0, 0.30, 0.7, true)
		"combo_step":
			s = _build_tone(660.0, 0.12, 0.4, true)
		"fanfare":
			s = _build_chord([523.25, 659.25, 783.99, 1046.5], 0.7, 0.5)
		"fail":
			s = _build_tone(160.0, 0.6, 0.55, true)
		"unlock":
			s = _build_chord([523.25, 783.99, 1046.5], 0.5, 0.4)
		"ui_blip":
			s = _build_tone(1320.0, 0.05, 0.3, false)
		_:
			s = _build_tone(440.0, 0.1, 0.4, false)
	_tone_cache[id] = s
	return s

func _get_or_build_ambient(id: String) -> AudioStreamWAV:
	var key := "music_" + id
	if _tone_cache.has(key):
		return _tone_cache[key]
	# soft pad: low freq sine + a couple harmonics, looped
	var base := 0.0
	match id:
		"menu":
			base = 220.0
		"gameplay":
			base = 196.0  # G3
		_:
			base = 174.61
	var s := _build_pad([base, base * 1.5, base * 2.0], 4.0, 0.18)
	s.loop_mode = AudioStreamWAV.LOOP_FORWARD
	s.loop_begin = 0
	s.loop_end = s.data.size() / 2 - 1
	_tone_cache[key] = s
	return s

func _build_tone(freq: float, dur: float, amp: float, decay: bool) -> AudioStreamWAV:
	var sample_rate := 22050
	var sample_count := int(sample_rate * dur)
	var bytes := PackedByteArray()
	bytes.resize(sample_count * 2)
	for i in range(sample_count):
		var t := float(i) / sample_rate
		var env := 1.0
		if decay:
			env = clampf(1.0 - t / dur, 0.0, 1.0)
		else:
			# tiny fade in/out so we dont hear a click on the edges
			env = clampf(min(t * 20.0, (dur - t) * 20.0), 0.0, 1.0)
		var v: float = sin(t * TAU * freq) * amp * env
		var s: int = int(clampf(v, -1.0, 1.0) * 32767.0)
		bytes[i * 2] = s & 0xFF
		bytes[i * 2 + 1] = (s >> 8) & 0xFF
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = bytes
	return stream

func _build_chord(freqs: Array, dur: float, amp: float) -> AudioStreamWAV:
	var sample_rate := 22050
	var sample_count := int(sample_rate * dur)
	var bytes := PackedByteArray()
	bytes.resize(sample_count * 2)
	for i in range(sample_count):
		var t := float(i) / sample_rate
		var env := clampf(1.0 - t / dur, 0.0, 1.0)
		var v := 0.0
		for f in freqs:
			v += sin(t * TAU * float(f))
		v = (v / float(freqs.size())) * amp * env
		var s: int = int(clampf(v, -1.0, 1.0) * 32767.0)
		bytes[i * 2] = s & 0xFF
		bytes[i * 2 + 1] = (s >> 8) & 0xFF
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = bytes
	return stream

func _build_pad(freqs: Array, dur: float, amp: float) -> AudioStreamWAV:
	var sample_rate := 22050
	var sample_count := int(sample_rate * dur)
	var bytes := PackedByteArray()
	bytes.resize(sample_count * 2)
	for i in range(sample_count):
		var t := float(i) / sample_rate
		# slow wow so it doesnt sound completely dead
		var wow := 1.0 + 0.005 * sin(t * TAU * 0.3)
		var v := 0.0
		for f in freqs:
			v += sin(t * TAU * float(f) * wow)
		v = (v / float(freqs.size())) * amp
		# fade the very start/end so the loop doesnt click
		var fade := clampf(min(t * 4.0, (dur - t) * 4.0), 0.0, 1.0)
		v *= fade
		var s: int = int(clampf(v, -1.0, 1.0) * 32767.0)
		bytes[i * 2] = s & 0xFF
		bytes[i * 2 + 1] = (s >> 8) & 0xFF
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = bytes
	return stream

func _build_noise(dur: float, amp: float) -> AudioStreamWAV:
	var sample_rate := 22050
	var sample_count := int(sample_rate * dur)
	var bytes := PackedByteArray()
	bytes.resize(sample_count * 2)
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for i in range(sample_count):
		var t := float(i) / sample_rate
		var env := clampf(1.0 - t / dur, 0.0, 1.0)
		var v: float = rng.randf_range(-1.0, 1.0) * amp * env
		var s: int = int(clampf(v, -1.0, 1.0) * 32767.0)
		bytes[i * 2] = s & 0xFF
		bytes[i * 2 + 1] = (s >> 8) & 0xFF
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = bytes
	return stream
