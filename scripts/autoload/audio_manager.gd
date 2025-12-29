extends Node
## AudioManager - Handles all game audio (music, SFX)
## Autoload singleton for easy access throughout the game

# Audio bus names
const BUS_MASTER := "Master"
const BUS_MUSIC := "Music"
const BUS_SFX := "SFX"

# Volume settings (0.0 to 1.0)
var music_volume: float = 0.7:
	set(value):
		music_volume = clampf(value, 0.0, 1.0)
		_update_bus_volume(BUS_MUSIC, music_volume)

var sfx_volume: float = 1.0:
	set(value):
		sfx_volume = clampf(value, 0.0, 1.0)
		_update_bus_volume(BUS_SFX, sfx_volume)

var music_enabled: bool = true:
	set(value):
		music_enabled = value
		if music_player:
			if value and not music_player.playing:
				music_player.play()
			elif not value:
				music_player.stop()

var sfx_enabled: bool = true

# Audio players
var music_player: AudioStreamPlayer
var sfx_players: Array[AudioStreamPlayer] = []
const MAX_SFX_PLAYERS := 8

# Preloaded sounds (will be generated procedurally for now)
var sound_meow: AudioStream
var sound_meow_variants: Array[AudioStream] = []
var sound_fusion: AudioStream
var sound_currency: AudioStream
var sound_spawn: AudioStream
var sound_ui_click: AudioStream

func _ready() -> void:
	_setup_audio_buses()
	_setup_audio_players()
	_load_audio_files()
	_generate_placeholder_sounds()
	print("AudioManager: Initialized")

func _load_audio_files() -> void:
	# Load real audio files if they exist
	var meow_path = "res://sounds/cat_meow.mp3"
	var music_path = "res://sounds/background_music.mp3"

	if ResourceLoader.exists(meow_path):
		var meow_stream = load(meow_path)
		if meow_stream:
			sound_meow = meow_stream
			sound_meow_variants.clear()
			sound_meow_variants.append(meow_stream)
			print("AudioManager: Loaded cat_meow.mp3")

	if ResourceLoader.exists(music_path):
		background_music = load(music_path)
		if background_music:
			# Enable looping for MP3
			if background_music is AudioStreamMP3:
				background_music.loop = true
			print("AudioManager: Loaded background_music.mp3")

func _setup_audio_buses() -> void:
	# Ensure audio buses exist
	# Note: In production, use a proper default_bus_layout.tres
	# For now, we'll use the Master bus for everything
	var music_bus_idx = AudioServer.get_bus_index(BUS_MUSIC)
	var sfx_bus_idx = AudioServer.get_bus_index(BUS_SFX)

	# If buses don't exist, add them
	if music_bus_idx == -1:
		AudioServer.add_bus()
		music_bus_idx = AudioServer.bus_count - 1
		AudioServer.set_bus_name(music_bus_idx, BUS_MUSIC)
		AudioServer.set_bus_send(music_bus_idx, BUS_MASTER)

	if sfx_bus_idx == -1:
		AudioServer.add_bus()
		sfx_bus_idx = AudioServer.bus_count - 1
		AudioServer.set_bus_name(sfx_bus_idx, BUS_SFX)
		AudioServer.set_bus_send(sfx_bus_idx, BUS_MASTER)

	# Apply initial volumes
	_update_bus_volume(BUS_MUSIC, music_volume)
	_update_bus_volume(BUS_SFX, sfx_volume)

func _setup_audio_players() -> void:
	# Create music player
	music_player = AudioStreamPlayer.new()
	music_player.bus = BUS_MUSIC
	add_child(music_player)

	# Create pool of SFX players for overlapping sounds
	for i in range(MAX_SFX_PLAYERS):
		var player = AudioStreamPlayer.new()
		player.bus = BUS_SFX
		add_child(player)
		sfx_players.append(player)

func _update_bus_volume(bus_name: String, volume: float) -> void:
	var bus_idx = AudioServer.get_bus_index(bus_name)
	if bus_idx >= 0:
		# Convert linear volume to dB (-80 dB = silent, 0 dB = full)
		var db = linear_to_db(volume) if volume > 0 else -80.0
		AudioServer.set_bus_volume_db(bus_idx, db)

func _generate_placeholder_sounds() -> void:
	# Generate simple synthesized placeholder sounds
	# Only generate if real files weren't loaded

	# Meow sounds - only if not already loaded from file
	if sound_meow_variants.is_empty():
		for i in range(4):
			var pitch_offset = randf_range(-0.2, 0.2)
			var meow = _create_meow_sound(0.25 + pitch_offset)
			sound_meow_variants.append(meow)
		if sound_meow_variants.size() > 0:
			sound_meow = sound_meow_variants[0]
		print("AudioManager: Using procedural meow sounds")

	# Other sounds (always procedural for now)
	sound_fusion = _create_fusion_sound()
	sound_currency = _create_currency_sound()
	sound_spawn = _create_spawn_sound()
	sound_ui_click = _create_click_sound()

func _create_meow_sound(duration: float = 0.25) -> AudioStreamWAV:
	# Create a cute, soft "mew" sound - short and sweet
	var sample_rate := 22050
	var samples := int(sample_rate * duration)
	var data := PackedByteArray()
	data.resize(samples * 2)  # 16-bit samples

	for i in range(samples):
		var t: float = float(i) / sample_rate
		var progress: float = float(i) / samples

		# Gentle pitch curve: slight rise then fall (like "mew")
		var pitch_mult: float
		if progress < 0.2:
			pitch_mult = lerpf(1.0, 1.15, progress / 0.2)
		elif progress < 0.5:
			pitch_mult = lerpf(1.15, 1.1, (progress - 0.2) / 0.3)
		else:
			pitch_mult = lerpf(1.1, 0.95, (progress - 0.5) / 0.5)

		# Higher base frequency for cute kitten sound
		var base_freq: float = 600.0 * pitch_mult

		# Soft volume envelope: smooth attack and decay
		var envelope: float
		if progress < 0.1:
			envelope = sin(progress / 0.1 * PI * 0.5)  # Smooth attack
		elif progress < 0.4:
			envelope = 1.0
		else:
			envelope = cos((progress - 0.4) / 0.6 * PI * 0.5)  # Smooth decay

		# Pure sine wave for soft, cute sound
		var sample_value: float = sin(t * base_freq * TAU) * envelope * 0.35

		var sample_int: int = int(clampf(sample_value, -1.0, 1.0) * 32767)
		data[i * 2] = sample_int & 0xFF
		data[i * 2 + 1] = (sample_int >> 8) & 0xFF

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.data = data
	return stream

func _create_fusion_sound() -> AudioStreamWAV:
	# Fusion: sparkly rising chime
	var sample_rate := 22050
	var duration := 0.5
	var samples := int(sample_rate * duration)
	var data := PackedByteArray()
	data.resize(samples * 2)

	for i in range(samples):
		var t := float(i) / sample_rate
		var progress := float(i) / samples

		# Multiple harmonics for sparkle effect
		var freq1 := 523.0 * (1.0 + progress * 0.5)  # C5 rising
		var freq2 := 659.0 * (1.0 + progress * 0.5)  # E5 rising
		var freq3 := 784.0 * (1.0 + progress * 0.5)  # G5 rising

		var envelope := (1.0 - progress) * (1.0 - progress)  # Exponential decay

		var sample_value := (sin(t * freq1 * TAU) * 0.4 +
							 sin(t * freq2 * TAU) * 0.3 +
							 sin(t * freq3 * TAU) * 0.3) * envelope * 0.4

		var sample_int := int(clampf(sample_value, -1.0, 1.0) * 32767)
		data[i * 2] = sample_int & 0xFF
		data[i * 2 + 1] = (sample_int >> 8) & 0xFF

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.data = data
	return stream

func _create_currency_sound() -> AudioStreamWAV:
	# Currency: short coin-like ding
	var sample_rate := 22050
	var duration := 0.15
	var samples := int(sample_rate * duration)
	var data := PackedByteArray()
	data.resize(samples * 2)

	for i in range(samples):
		var t := float(i) / sample_rate
		var progress := float(i) / samples

		var freq := 1200.0  # High pitched ding
		var envelope := (1.0 - progress) * (1.0 - progress)

		var sample_value := sin(t * freq * TAU) * envelope * 0.3

		var sample_int := int(clampf(sample_value, -1.0, 1.0) * 32767)
		data[i * 2] = sample_int & 0xFF
		data[i * 2 + 1] = (sample_int >> 8) & 0xFF

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.data = data
	return stream

func _create_spawn_sound() -> AudioStreamWAV:
	# Spawn: soft pop/poof sound
	var sample_rate := 22050
	var duration := 0.2
	var samples := int(sample_rate * duration)
	var data := PackedByteArray()
	data.resize(samples * 2)

	for i in range(samples):
		var t := float(i) / sample_rate
		var progress := float(i) / samples

		# Descending pitch for pop effect
		var freq := 400.0 * (1.0 - progress * 0.5)
		var envelope := (1.0 - progress) * (1.0 - progress)

		# Mix sine with some noise for soft texture
		var sine := sin(t * freq * TAU)
		var noise := randf_range(-0.3, 0.3) * (1.0 - progress)
		var sample_value := (sine * 0.7 + noise) * envelope * 0.35

		var sample_int := int(clampf(sample_value, -1.0, 1.0) * 32767)
		data[i * 2] = sample_int & 0xFF
		data[i * 2 + 1] = (sample_int >> 8) & 0xFF

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.data = data
	return stream

func _create_click_sound() -> AudioStreamWAV:
	# UI click: very short tick
	var sample_rate := 22050
	var duration := 0.05
	var samples := int(sample_rate * duration)
	var data := PackedByteArray()
	data.resize(samples * 2)

	for i in range(samples):
		var t := float(i) / sample_rate
		var progress := float(i) / samples

		var freq := 800.0
		var envelope := 1.0 - progress

		var sample_value := sin(t * freq * TAU) * envelope * 0.25

		var sample_int := int(clampf(sample_value, -1.0, 1.0) * 32767)
		data[i * 2] = sample_int & 0xFF
		data[i * 2 + 1] = (sample_int >> 8) & 0xFF

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.data = data
	return stream

func _create_lofi_music() -> AudioStreamWAV:
	# Create a smooth, cozy ambient music loop
	var sample_rate := 22050
	var duration := 16.0  # 16 second loop
	var samples := int(sample_rate * duration)
	var data := PackedByteArray()
	data.resize(samples * 2)

	# Pentatonic scale (C major pentatonic, lower octave for warmth)
	var scale: Array[float] = [130.81, 146.83, 164.81, 196.00, 220.00, 261.63, 293.66, 329.63]

	# Generate the music
	for i in range(samples):
		var t: float = float(i) / sample_rate

		# Slow-moving pad with smooth chord changes
		var chord_progress: float = fmod(t / 8.0, 1.0)  # 8 seconds per chord change
		var chord_blend: float = 0.5 + 0.5 * cos(chord_progress * TAU)  # Smooth crossfade

		# Two chord tones that blend together
		var freq1: float = scale[0] * (1.0 + chord_blend * 0.5)  # Root note shifts
		var freq2: float = scale[2]  # Third
		var freq3: float = scale[4]  # Fifth

		# Warm pad sound - pure sine waves, very gentle
		var pad: float = 0.0
		pad += sin(t * freq1 * TAU) * 0.12
		pad += sin(t * freq2 * TAU) * 0.08
		pad += sin(t * freq3 * TAU) * 0.06
		# Add octave up, quieter
		pad += sin(t * freq1 * 2.0 * TAU) * 0.03

		# Very slow volume swell for movement
		var swell: float = 0.7 + 0.3 * sin(t * 0.15 * TAU)

		# Combine - keep it simple and clean
		var sample_value: float = pad * swell * 0.5

		var sample_int: int = int(clampf(sample_value, -1.0, 1.0) * 32767)
		data[i * 2] = sample_int & 0xFF
		data[i * 2 + 1] = (sample_int >> 8) & 0xFF

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.data = data
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = samples
	return stream

var background_music: AudioStream

func start_background_music() -> void:
	if not background_music:
		# Fallback to procedural music if no file loaded
		background_music = _create_lofi_music()
		print("AudioManager: Using procedural music (no file found)")
	play_music(background_music, 2.0)

# Public API for playing sounds

func play_meow(pitch_scale: float = 1.0) -> void:
	if not sfx_enabled or sound_meow_variants.is_empty():
		return
	# Pick random meow variant
	var variant = sound_meow_variants[randi() % sound_meow_variants.size()]
	_play_sfx(variant, pitch_scale)

func play_fusion() -> void:
	if not sfx_enabled or not sound_fusion:
		return
	_play_sfx(sound_fusion)

func play_currency() -> void:
	if not sfx_enabled or not sound_currency:
		return
	_play_sfx(sound_currency, randf_range(0.9, 1.1))  # Slight pitch variation

func play_spawn() -> void:
	if not sfx_enabled or not sound_spawn:
		return
	_play_sfx(sound_spawn)

func play_ui_click() -> void:
	if not sfx_enabled or not sound_ui_click:
		return
	_play_sfx(sound_ui_click)

func _play_sfx(stream: AudioStream, pitch: float = 1.0) -> void:
	# Find an available SFX player
	for player in sfx_players:
		if not player.playing:
			player.stream = stream
			player.pitch_scale = pitch
			player.play()
			return

	# All players busy, use the first one (will cut off oldest sound)
	if sfx_players.size() > 0:
		sfx_players[0].stream = stream
		sfx_players[0].pitch_scale = pitch
		sfx_players[0].play()

# Music control

func play_music(stream: AudioStream, fade_in: float = 1.0) -> void:
	if not music_enabled:
		music_player.stream = stream  # Store but don't play
		return

	if fade_in > 0:
		music_player.volume_db = -80.0
		music_player.stream = stream
		music_player.play()
		var tween = create_tween()
		tween.tween_property(music_player, "volume_db", 0.0, fade_in)
	else:
		music_player.stream = stream
		music_player.play()

func stop_music(fade_out: float = 1.0) -> void:
	if fade_out > 0 and music_player.playing:
		var tween = create_tween()
		tween.tween_property(music_player, "volume_db", -80.0, fade_out)
		tween.tween_callback(music_player.stop)
	else:
		music_player.stop()

func set_music_volume(volume: float) -> void:
	music_volume = volume

func set_sfx_volume(volume: float) -> void:
	sfx_volume = volume

func toggle_music() -> void:
	music_enabled = not music_enabled

func toggle_sfx() -> void:
	sfx_enabled = not sfx_enabled
