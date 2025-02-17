@tool
extends EditorScript

func _run() -> void:
	var audio_res = AudioResources.new()
	
	# Load SFX
	_load_audio_dir("res://audio/sfx/", audio_res.sfx)
	# Load Music
	_load_audio_dir("res://audio/music/", audio_res.music)
	
	# Save the resource
	var err = ResourceSaver.save(audio_res, "res://audio_resources.tres")
	if err == OK:
		print("Audio resources generated successfully!")
	else:
		push_error("Failed to save audio resources!")

func _load_audio_dir(path: String, target: Dictionary) -> void:
	var dir := DirAccess.open(path)
	if not dir:
		push_error("Failed to open directory: " + path)
		return

	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and (file_name.ends_with(".wav") or file_name.ends_with(".ogg")):
			var basename = file_name.get_basename()
			var resource = load(path + file_name)
			if resource:
				target[basename] = resource
			else:
				push_error("Failed to load audio file: " + path + file_name)
		file_name = dir.get_next()
