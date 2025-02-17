extends Node

signal settings_changed

var music_volume: float = 100.0  # Start at full volume
var sfx_volume: float = 80.0    # Start at full volume
var fullscreen: bool = true

func _ready() -> void:
	# Make sure audio buses exist
	var music_bus = AudioServer.get_bus_index("Music")
	var sfx_bus = AudioServer.get_bus_index("SFX")
	
	if music_bus == -1:
		push_error("Music bus not found!")
		return
	if sfx_bus == -1:
		push_error("SFX bus not found!")
		return
	
	# Set initial volumes to match our stored values
	set_music_volume(music_volume)
	set_sfx_volume(sfx_volume)
	
	fullscreen = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN

func volume_to_db(percent: float) -> float:
	# Convert percentage (0-100) to a value between 0 and 1
	var normalized = percent / 100.0
	
	if normalized <= 0:
		return -80.0  # Silent
	elif normalized >= 1:
		return 0.0    # Full volume
	
	# Linear mapping from 0-100% to -80dB to 0dB
	return linear_to_db(normalized)

func set_music_volume(value: float) -> void:
	music_volume = value
	var bus_idx = AudioServer.get_bus_index("Music")
	if bus_idx >= 0:
		var db = volume_to_db(value)
		AudioServer.set_bus_volume_db(bus_idx, db)
	settings_changed.emit()

func set_sfx_volume(value: float) -> void:
	sfx_volume = value
	var bus_idx = AudioServer.get_bus_index("SFX")
	if bus_idx >= 0:
		var db = volume_to_db(value)
		AudioServer.set_bus_volume_db(bus_idx, db)
	settings_changed.emit()

func set_fullscreen(enabled: bool) -> void:
	fullscreen = enabled
	if enabled:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	settings_changed.emit()
