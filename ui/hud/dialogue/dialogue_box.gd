extends CanvasLayer

signal dialogue_finished
signal custom_event(event_name: String)

# Configuration
var default_dialogue_speed: float = 0.05  # Default time per character at speed 1.0
var dialogue_speed: float = default_dialogue_speed
var skip_action: String = "ui_accept"
var current_dialogue: Array = []
var current_line: int = -1
var is_animating: bool = false
var visible_characters: int = 0
var current_commands: Array = []
var current_sound: String = "text"
var current_pitch_range: Vector2 = Vector2(0.9, 1.1)
var last_sound_character: int = 0

# Auto-progress variables
var line_has_auto: bool = false
var auto_progress_time: float = -1.0
var is_auto_progressing: bool = false
var auto_progress_timer: Timer

# Skip variables
var hold_timer: Timer
var is_holding_skip: bool = false
const HOLD_SKIP_TIME: float = 3.0

@onready var speaker_label: Label = $Panel/MarginContainer/VBoxContainer/SpeakerName
@onready var text_label: Label = $Panel/MarginContainer/VBoxContainer/DialogueText
@onready var text_timer: Timer = $Panel/MarginContainer/TextTimer

func _ready() -> void:
	hide()
	text_timer.wait_time = dialogue_speed
	text_timer.timeout.connect(_on_text_timer_timeout)
	
	# Auto-progress timer setup
	auto_progress_timer = Timer.new()
	auto_progress_timer.one_shot = true
	add_child(auto_progress_timer)
	auto_progress_timer.timeout.connect(_on_auto_progress_timer_timeout)
	
	# Skip timer setup
	hold_timer = Timer.new()
	hold_timer.one_shot = true
	hold_timer.wait_time = HOLD_SKIP_TIME
	add_child(hold_timer)
	hold_timer.timeout.connect(_on_hold_timer_timeout)

func load_and_start_dialogue(stage_name: String, dialogue_name: String) -> void:
	var full_path = "res://stages/%s/dialogues/%s.json" % [stage_name, dialogue_name]
	var file = FileAccess.open(full_path, FileAccess.READ)
	if file:
		var content = file.get_as_text()
		var dialogue = JSON.parse_string(content)
		if dialogue is Array:
			start_dialogue(dialogue)
		else:
			push_error("Invalid dialogue format in: %s" % full_path)
	else:
		push_error("Failed to load dialogue file: %s" % full_path)

func start_dialogue(dialogue: Array) -> void:
	show()
	current_dialogue = dialogue
	current_line = -1
	next_line()

func next_line() -> void:
	# Reset all command parameters to defaults.
	current_sound = "text"
	current_pitch_range = Vector2(0.9, 1.1)
	dialogue_speed = default_dialogue_speed
	text_timer.wait_time = dialogue_speed
	auto_progress_time = -1.0
	is_auto_progressing = false
	line_has_auto = false
	last_sound_character = 0
	
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
	text_label.visible_characters = 0
	visible_characters = 0
	
	# Check for an auto command in this line.
	for cmd in current_commands:
		if cmd.command == "auto":
			line_has_auto = true
			break
	
	is_animating = true
	text_timer.start()

func _on_text_timer_timeout() -> void:
	if visible_characters < text_label.get_total_character_count():
		await _process_commands(visible_characters)
		visible_characters += 1
		text_label.visible_characters = visible_characters
		
		# Determine when to play a sound (based on speed).
		var base_speed = default_dialogue_speed
		var actual_speed = dialogue_speed
		var speed_ratio = base_speed / actual_speed
		var chars_between_sounds = clamp(floor(speed_ratio), 1, 4)
		if visible_characters - last_sound_character >= chars_between_sounds:
			Audio.play_sfx(
				current_sound,
				{"pitch": randf_range(current_pitch_range.x, current_pitch_range.y)}
			)
			last_sound_character = visible_characters
	else:
		await complete_line()

func _process_commands(pos: int) -> void:
	for cmd in current_commands:
		if cmd.position == pos and (not cmd.has("executed") or not cmd.executed):
			await execute_command(cmd)
			cmd.executed = true

func execute_command(cmd: Dictionary, instant: bool = false) -> void:
	var command = cmd.command
	var args: Array = cmd.args
	match command:
		"sound":
			if args.size() >= 1:
				current_sound = args[0]
				if args.size() >= 3:
					current_pitch_range = Vector2(args[1].to_float(), args[2].to_float())
				elif args.size() >= 2:
					current_pitch_range = Vector2(args[1].to_float(), args[1].to_float())
		"music":
			if args.size() >= 1:
				Audio.play_music(args[0])
		"speed":
			if args.size() >= 1:
				var speed_multiplier = args[0].to_float()
				dialogue_speed = default_dialogue_speed / speed_multiplier
				text_timer.wait_time = dialogue_speed
		"wait":
			if args.size() >= 1:
				if not instant:
					text_timer.stop()
					await get_tree().create_timer(args[0].to_float()).timeout
					text_timer.start()
		"speaker":
			if args.size() > 0:
				speaker_label.text = join_array(args, " ")
		"event":
			if args.size() > 0:
				custom_event.emit(args[0])
		"auto":
			if args.size() >= 1:
				auto_progress_time = args[0].to_float()
		_:
			push_error("Unknown command: %s" % command)

func complete_line() -> void:
	# Reveal all remaining text immediately.
	visible_characters = text_label.get_total_character_count()
	text_label.visible_characters = visible_characters
	
	# Execute any remaining commands.
	for cmd in current_commands:
		if cmd.position <= visible_characters and (not cmd.has("executed") or not cmd.executed):
			if cmd.command == "wait":
				cmd.executed = true
			else:
				await execute_command(cmd, true)
				cmd.executed = true
	
	text_timer.stop()
	is_animating = false
	
	# Play finishing sound if not auto-progressing.
	if not line_has_auto and auto_progress_time < 0:
		Audio.play_sfx("text_finish")
	
	# Handle auto-progress.
	if auto_progress_time >= 0:
		is_auto_progressing = true
		if auto_progress_time == 0:
			next_line()
		else:
			auto_progress_timer.start(auto_progress_time)

func end_dialogue() -> void:
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
		# Use Godot 4’s ternary operator syntax:
		var args: Array = parts.slice(1, parts.size()) if parts.size() > 1 else []
		commands.append({
			"position": processed_text.length(),
			"command": command_name,
			"args": args
		})
		last_end = end
	processed_text += original_text.substr(last_end)
	return {"processed_text": processed_text, "commands": commands}

func _on_auto_progress_timer_timeout() -> void:
	next_line()

func _on_hold_timer_timeout() -> void:
	if visible:
		end_dialogue()

func _unhandled_input(event: InputEvent) -> void:
	# Handle hold-to-skip.
	if event.is_action_pressed("interact") and visible:
		is_holding_skip = true
		hold_timer.start()
		get_viewport().set_input_as_handled()
	
	if event.is_action_released("interact") and visible:
		is_holding_skip = false
		hold_timer.stop()
		get_viewport().set_input_as_handled()
	
	# Handle skip action.
	if event.is_action_pressed(skip_action) and visible:
		if line_has_auto or is_auto_progressing:
			get_viewport().set_input_as_handled()
			return
		
		if is_animating:
			complete_line()
		else:
			next_line()
		
		if get_viewport():
			get_viewport().set_input_as_handled()

# Helper function to join an array of strings using a delimiter.
func join_array(arr: Array, delim: String) -> String:
	var result: String = ""
	for i in arr:
		if result != "":
			result += delim
		result += str(i)
	return result
