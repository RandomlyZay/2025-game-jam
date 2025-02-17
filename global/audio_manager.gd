# Audio Manager Guide
# 1. **Resource Management**:
# 	- Audio resources are pre-loaded from `res://audio_resources.tres`
# 	- Run the generate_audio_resources.gd script whenever audio files are added/removed
#
# 2. **Playing SFX**:
# 	- Use `Audio.play_sfx(sound_name: String, params: Dictionary = {})` to play a sound effect.
# 	- Optional parameters can include:
# 		- `pitch`: A float multiplier for pitch (default is 1.0). Values other than 1.0 will adjust the mix_rate of the stream if applicable.
# 		- `position`: A Vector2 for positional audio. If provided, a temporary AudioStreamPlayer2D is created for spatial sound.
#
# 3. **Playing Music**:
# 	- Use `play_music(track_name: String, transition: String = "instant", duration: float = 1.0)` to start a music track.
# 	- Supported transitions:
# 		- (Default) "instant": Stops the current track and starts the new track immediately.
# 		- "crossfade": Smoothly crossfades between the old and new tracks over the given duration.
# 		- "fade_out_in": Fades out the old track and then fades in the new track.
#
# 4. **Global Controls**:
# 	- Adjust volume levels for Master, Music, and SFX via the corresponding variables.
# 		- Use `pause_all()` and `resume_all()` to mute/unmute the Master bus.
# 		- Use `stop_music(fade_duration: float = 0.5)` to stop all music with a fade out.
#
# 5. **Misc Functions**:
# 	- Use `remember_position()` and `resume_position()` to save and resume the playback position of the current track.
# 	- Use `set_bus_effect(effect_name: String, enabled: bool)` to enable or disable a bus effect by its resource name.
# 	- Use `play_random_sfx(sfx_list: Array)` to play a random SFX from a provided list.

extends Node

# --- Audio Bus Configuration ---
const MASTER_BUS := "Master"
const MUSIC_BUS := "Music"
const SFX_BUS := "SFX"

# Changing these properties will automatically update the corresponding Audio Bus volume.
var master_volume: float = 1.0:
	set(value):
		# Clamp the value between 0.0 and 1.0 and update the Master bus volume.
		master_volume = clampf(value, 0.0, 1.0)
		AudioServer.set_bus_volume_db(
			AudioServer.get_bus_index(MASTER_BUS),
			linear_to_db(master_volume)
		)

var music_volume: float = 1.0:
	set(value):
		var clamped = clampf(value, 0.0, 1.0)
		# Prevent setting to absolute zero
		if clamped < 0.01:
			clamped = 0.0
		AudioServer.set_bus_volume_db(
			AudioServer.get_bus_index(MUSIC_BUS),
			linear_to_db(clamped if clamped > 0.0 else 0.0001)  # Prevent -inf dB
		)
		music_volume = clamped

var sfx_volume: float = 1.0:
	set(value):
		# Clamp the value between 0.0 and 1.0 and update the SFX bus volume.
		sfx_volume = clampf(value, 0.0, 1.0)
		AudioServer.set_bus_volume_db(
			AudioServer.get_bus_index(SFX_BUS),
			linear_to_db(sfx_volume)
		)

# --- Audio Resources ---
var sfx: Dictionary = {}    # Dictionary of SFX: Key is sound name, Value is AudioStream resource.
var music: Dictionary = {}  # Dictionary of music tracks: Key is track name, Value is AudioStream resource.

# --- Audio Players ---
var music_players: Array = []  # Two music players for crossfading.
var active_music_index := 0  # Index to track which music player is currently active.
var sfx_players: Array[AudioStreamPlayer] = []  # Pool of SFX players.
const INITIAL_SFX_PLAYERS := 8  # Initial number of SFX players to create.

# --- Track Management ---
var current_track: String = ""
var track_position: float = 0.0

# Called when the node is added to the scene.
func _ready() -> void:
	# Load pre-generated audio resources
	var audio_res = load("res://audio_resources.tres") as AudioResources
	if audio_res:
		sfx = audio_res.sfx
		music = audio_res.music
	else:
		push_error("Failed to load audio_resources.tres")
	
	# Initialize music and SFX players.
	initialize_players()

# Initializes the music and SFX audio players.
func initialize_players() -> void:
	# Create or retrieve two music players.
	for i in range(2):
		var node_name = "MusicPlayer" + str(i + 1)
		var player: AudioStreamPlayer = get_node_or_null(node_name)
		if player == null:
			player = AudioStreamPlayer.new()
			player.name = node_name
			player.bus = MUSIC_BUS
			add_child(player)
		# Add the player to the music_players array.
		music_players.append(player)
	
	# Create initial pool of SFX players.
	for i in range(INITIAL_SFX_PLAYERS):
		var sfx_player = AudioStreamPlayer.new()
		sfx_player.bus = SFX_BUS
		sfx_player.volume_db = linear_to_db(sfx_volume)
		add_child(sfx_player)
		sfx_players.append(sfx_player)

# Plays a sound effect with optional parameters.
# Params may include:
#   - pitch: A float multiplier for pitch (default 1.0). Adjusts mix_rate for WAV streams.
#   - position: A Vector2 for positional audio; if provided, a 2D spatial player is used.
func play_sfx(sound_name: String, params := {}) -> void:
	if not sfx.has(sound_name):
		push_warning("SFX not found: ", sound_name)
		return
	
	# Check if a positional sound is requested.
	if params.has("position"):
		# Create a temporary AudioStreamPlayer2D for spatialized sound.
		var spatial_player = AudioStreamPlayer2D.new()
		spatial_player.position = params.position
		spatial_player.bus = SFX_BUS
		spatial_player.stream = get_processed_stream(sound_name, params)
		add_child(spatial_player)
		spatial_player.play()
		# Automatically free the node when finished.
		spatial_player.finished.connect(spatial_player.queue_free)
		return
	else:
		# Use an available SFX player from the pool.
		var player: AudioStreamPlayer = get_available_sfx_player()
		player.stream = get_processed_stream(sound_name, params)
		player.play()

# Processes the audio stream according to provided parameters.
# Currently, it adjusts the pitch for AudioStreamWAV types by modifying the mix_rate.
func get_processed_stream(sound_name: String, params: Dictionary) -> AudioStream:
	var stream: AudioStream = sfx[sound_name]
	# Check if a pitch modification is requested.
	if params.get("pitch", 1.0) != 1.0 and stream is AudioStreamWAV:
		# Duplicate the stream and modify its mix_rate to change pitch.
		var stream_copy: AudioStreamWAV = stream.duplicate()
		stream_copy.mix_rate *= params.pitch
		return stream_copy
	return stream

# Retrieves an available SFX player from the pool, or creates a new one if all are busy.
func get_available_sfx_player() -> AudioStreamPlayer:
	for player in sfx_players:
		if not player.playing:
			return player
	
	# If all players are busy, create a new one.
	var new_player = AudioStreamPlayer.new()
	new_player.bus = SFX_BUS
	add_child(new_player)
	sfx_players.append(new_player)
	return new_player

# Plays a music track with a specified transition method.
# Transition types:
#   - "crossfade": Crossfades between the current and new tracks.
#   - "fade_out_in": Fades out the current track then fades in the new track.
#   - "instant": Stops the current track and starts the new one immediately.
func play_music(track_name: String, transition: String = "instant", duration: float = 1.0) -> void:
	# If the requested track is already playing, do nothing.
	if track_name == current_track and (music_players[0].playing or music_players[1].playing):
		return
	
	if not music.has(track_name):
		push_warning("Music track not found: ", track_name)
		return
	
	current_track = track_name
	# Determine the new and old music players for the transition.
	var new_index := 1 - active_music_index
	var new_player: AudioStreamPlayer = music_players[new_index]
	var old_player: AudioStreamPlayer = music_players[active_music_index]
	
	new_player.stream = music[track_name]
	
	match transition:
		"crossfade":
			crossfade_music(new_player, old_player, duration)
		"fade_out_in":
			fade_out_in(old_player, new_player, duration)
		_:
			instant_transition(new_player, old_player)
	
	active_music_index = new_index

# Crossfades between the current and new tracks concurrently.
func crossfade_music(new_player: AudioStreamPlayer, old_player: AudioStreamPlayer, duration: float) -> void:
	# Start new track silent and play it
	new_player.volume_db = -80.0
	new_player.play()
	
	duration = max(duration, 0.01)
	
	# Fade in the new track to 0 dB and fade out the old track to -80 dB
	var tween = create_tween()
	tween.parallel().tween_property(new_player, "volume_db", 0.0, duration)  # Target 0 dB
	tween.parallel().tween_property(old_player, "volume_db", -80.0, duration)
	
	await tween.finished
	
	old_player.stop()
	old_player.volume_db = 0.0  # Reset to full volume for future use

# Fades out the old track and then fades in the new track.
func fade_out_in(old_player: AudioStreamPlayer, new_player: AudioStreamPlayer, duration: float) -> void:
	duration = max(duration, 0.01)
	# If the current (old) track is playing, fade it out.
	if old_player.playing:
		var tween_out = create_tween()
		tween_out.tween_property(old_player, "volume_db", -80.0, duration)
		# Wait until the fade-out is complete before stopping the old track.
		await tween_out.finished
		old_player.stop()
		# Reset the old player's volume for future use.
		old_player.volume_db = linear_to_db(music_volume)
	# Immediately start the new track at full volume (no fade-in effect).
	new_player.volume_db = linear_to_db(music_volume)
	new_player.play()

# Immediately transitions to the new track without fading.
func instant_transition(new_player: AudioStreamPlayer, old_player: AudioStreamPlayer) -> void:
	old_player.stop()
	new_player.volume_db = 0.0  # Set to full volume
	new_player.play()

# Stops all music tracks with an optional fade out duration.
func stop_music(fade_duration: float = 0.5) -> void:
	var tween = create_tween()
	# Fade out all playing music players in parallel.
	for player in music_players:
		if player.playing:
			# Start from current volume and fade to silent
			tween.parallel().tween_property(
				player, 
				"volume_db", 
				-80.0,  # Effective silence
				fade_duration
			)
	
	await tween.finished
	# Stop all players after fading out and reset volumes
	for player in music_players:
		player.stop()
		player.volume_db = linear_to_db(music_volume)  # Reset to current music volume
	
	current_track = ""
	track_position = 0.0

# Mutes all audio on the Master bus.
func pause_all() -> void:
	AudioServer.set_bus_mute(AudioServer.get_bus_index(MASTER_BUS), true)

# Unmutes the Master bus.
func resume_all() -> void:
	AudioServer.set_bus_mute(AudioServer.get_bus_index(MASTER_BUS), false)

# Remembers the current playback position of the active music track.
func remember_position() -> void:
	var player = music_players[active_music_index]
	if player.playing:
		track_position = player.get_playback_position()

# Resumes playing the current track from the remembered position.
func resume_position() -> void:
	if current_track and music.has(current_track):
		var player = music_players[active_music_index]
		player.stream = music[current_track]
		player.play(track_position)
		player.volume_db = linear_to_db(music_volume)

# Enables or disables a bus effect on the Master bus by matching the effect name.
func set_bus_effect(effect_name: String, enabled: bool) -> void:
	var bus_idx = AudioServer.get_bus_index(MASTER_BUS)
	for i in AudioServer.get_bus_effect_count(bus_idx):
		var effect = AudioServer.get_bus_effect(bus_idx, i)
		if effect and effect_name in effect.resource_name:
			AudioServer.set_bus_effect_enabled(bus_idx, i, enabled)
			return

# Plays a random SFX from a provided list. Each element in sfx_list can be either:
#   - A String representing the sound name, or
#   - An Array where the first element is the sound name and the second is a Dictionary of parameters.
func play_random_sfx(sfx_list: Array) -> void:
	if sfx_list.is_empty():
		return
	var sound = sfx_list.pick_random()
	if sound is String:
		play_sfx(sound)
	elif sound is Array:
		play_sfx(sound[0], sound[1])

# --- Utility Functions ---

# Returns true if any music player is currently playing.
func is_music_playing() -> bool:
	return music_players[0].playing or music_players[1].playing

# Returns the playback position of the currently active music track.
func get_current_music_time() -> float:
	return music_players[active_music_index].get_playback_position()
