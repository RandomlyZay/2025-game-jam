extends CanvasLayer

signal dialogue_finished
signal custom_event(event_name: String)

# Configuration
var dialogue_speed: float = 0.05  # Time between characters
var skip_action: String = "ui_accept"
var current_dialogue: Array = []
var current_line: int = -1
var is_animating: bool = false
var visible_characters: int = 0
var current_commands: Array = []
var current_sound: String = "text"
var current_pitch_range: Vector2 = Vector2(0.9, 1.1)
var last_sound_character: int = 0  # Track the last character we played a sound for

@onready var speaker_label: Label = $Panel/MarginContainer/VBoxContainer/SpeakerName
@onready var text_label: Label = $Panel/MarginContainer/VBoxContainer/DialogueText
@onready var text_timer: Timer = $Panel/MarginContainer/TextTimer

func _ready():
	hide()
	text_timer.wait_time = dialogue_speed
	text_timer.timeout.connect(_on_text_timer_timeout)

func load_and_start_dialogue(stage_name: String, dialogue_name: String):
	var full_path = "res://stages/%s/dialogues/%s.json" % [stage_name, dialogue_name]
	var file = FileAccess.open(full_path, FileAccess.READ)
	
	if file:
		var content = file.get_as_text()
		var dialogue = JSON.parse_string(content)
		if dialogue is Array:
			start_dialogue(dialogue)
		else:
			push_error("Invalid dialogue format in: ", full_path)
	else:
		push_error("Failed to load dialogue file: ", full_path)

func start_dialogue(dialogue: Array):
	show()
	current_dialogue = dialogue
	current_line = -1
	next_line()

func next_line():
	# Reset sound to defaults for new line
	current_sound = "text"
	current_pitch_range = Vector2(0.9, 1.1)
	last_sound_character = 0  # Reset the last sound character counter
	
	if is_animating:
		complete_line()
		return
	
	current_line += 1
	if current_line >= current_dialogue.size():
		end_dialogue()
		return
	
	var line_data = current_dialogue[current_line]
	speaker_label.text = line_data.get("speaker", "")
	var original_text = line_data.get("text", "")
	var parsed = parse_text(original_text)
	text_label.text = parsed.processed_text
	current_commands = parsed.commands
	text_label.visible_ratio = 0
	visible_characters = 0
	
	start_animation()

func start_animation():
	is_animating = true
	text_timer.start()

func complete_line():
	visible_characters = text_label.get_total_character_count()
	text_label.visible_characters = visible_characters
	for cmd in current_commands:
		if cmd.position <= visible_characters and not cmd.get("executed", false):
			execute_command(cmd)
			cmd.executed = true
	text_timer.stop()
	is_animating = false

func end_dialogue():
	hide()
	current_dialogue = []
	current_line = -1
	is_animating = false
	dialogue_finished.emit()

func parse_text(original_text: String) -> Dictionary:
	var processed_text := ""
	var commands := []
	var regex = RegEx.new()
	regex.compile("\\[(?<command>[^\\]]+)\\]")
	var matches = regex.search_all(original_text)
	
	var last_end := 0
	for match in matches:
		var start = match.get_start()
		var end = match.get_end()
		var text_before = original_text.substr(last_end, start - last_end)
		processed_text += text_before
		var command_str = match.get_string("command")
		var parts = command_str.split(" ", false)
		var command_name = parts[0]
		var args = parts.slice(1) if parts.size() > 1 else []
		
		commands.append({
			"position": processed_text.length(),
			"command": command_name,
			"args": args
		})
		last_end = end
	processed_text += original_text.substr(last_end)
	return { "processed_text": processed_text, "commands": commands }

func execute_command(cmd: Dictionary):
	var command = cmd.command
	var args: Array = cmd.args
	
	match command:
		"sound":
			if args.size() >= 1:
				current_sound = args[0]
				if args.size() >= 3:
					current_pitch_range = Vector2(args[1].to_float(), args[2].to_float())
				elif args.size() >= 2:
					var pitch = args[1].to_float()
					current_pitch_range = Vector2(pitch, pitch)
		"music":
			if args.size() >= 1:
				Audio.play_music(args[0])
		"speed":
			if args.size() >= 1:
				dialogue_speed = args[0].to_float()
				text_timer.wait_time = dialogue_speed
		"wait":
			if args.size() >= 1:
				text_timer.stop()
				await get_tree().create_timer(args[0].to_float()).timeout
				text_timer.start()
		"speaker":
			if !args.is_empty():
				speaker_label.text = " ".join(args)
		"event":
			if !args.is_empty():
				custom_event.emit(args[0])
		_:
			push_error("Unknown command: %s" % command)

func _on_text_timer_timeout():
	if visible_characters < text_label.get_total_character_count():
		visible_characters += 1
		text_label.visible_characters = visible_characters
		
		# Calculate how many characters to wait between sounds based on speed
		var speed_ratio = dialogue_speed / 0.05
		var chars_between_sounds = 1  # Default to every character at normal speed
		
		if speed_ratio < 1.0:  # For faster speeds
			# As speed increases (ratio decreases), we increase characters between sounds
			# At 0.025 (2x speed) -> every 2 chars
			# At 0.0125 (4x speed) -> every 3 chars
			# At 0.00625 (8x speed) -> every 4 chars, etc
			chars_between_sounds = ceili(1.0 / speed_ratio * 0.5)
			chars_between_sounds = clampi(chars_between_sounds, 1, 4)  # Never wait more than 4 chars
		
		# Play sound if we've passed enough characters since the last sound
		if visible_characters - last_sound_character >= chars_between_sounds:
			Audio.play_sfx(
				current_sound,
				{"pitch": randf_range(current_pitch_range.x, current_pitch_range.y)}
			)
			last_sound_character = visible_characters
		
		# Process commands
		for cmd in current_commands:
			if cmd.position == visible_characters and not cmd.get("executed", false):
				execute_command(cmd)
				cmd.executed = true
	else:
		complete_line()

func _unhandled_input(event):
	if event.is_action_pressed(skip_action) and visible:
		if is_animating:
			complete_line()
		else:
			next_line()
		get_viewport().set_input_as_handled()
