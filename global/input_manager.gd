extends Node

signal input_mode_changed(mode: String)

var current_mode: String = "mouse"
var last_mouse_position := Vector2.ZERO
var last_mouse_move_time := 0.0
const MOUSE_TIMEOUT := 0.5
const MOUSE_MOVEMENT_THRESHOLD := 5.0

func _ready() -> void:
	last_mouse_position = get_viewport().get_mouse_position()
	process_mode = Node.PROCESS_MODE_ALWAYS  # Keep running even when paused

func _process(_delta: float) -> void:
	check_input_mode()

func check_input_mode() -> void:
	# Check for mouse movement
	var current_mouse_pos = get_viewport().get_mouse_position()
	if current_mouse_pos != last_mouse_position:
		if current_mode == "controller":
			# Only switch to mouse if significant movement detected
			var movement = (current_mouse_pos - last_mouse_position).length()
			if movement > MOUSE_MOVEMENT_THRESHOLD:
				switch_to_mouse()
		last_mouse_position = current_mouse_pos
	
	# Check for controller input
	var any_stick_movement = false
	# Check both sticks
	for stick in [Vector2(Input.get_joy_axis(0, JOY_AXIS_LEFT_X), Input.get_joy_axis(0, JOY_AXIS_LEFT_Y)),
				 Vector2(Input.get_joy_axis(0, JOY_AXIS_RIGHT_X), Input.get_joy_axis(0, JOY_AXIS_RIGHT_Y))]:
		if stick.length() > 0.3:
			any_stick_movement = true
			break
	
	# Check for any controller button press
	var any_button_pressed = false
	for button in range(JOY_BUTTON_LEFT_SHOULDER, JOY_BUTTON_START + 1):
		if Input.is_joy_button_pressed(0, button):
			any_button_pressed = true
			break
	
	if any_stick_movement or any_button_pressed:
		if current_mode != "controller":
			switch_to_controller()
	elif current_mode == "controller":
		# Check if we should switch back to mouse
		var current_time = Time.get_ticks_msec() / 1000.0
		if current_time - last_mouse_move_time < MOUSE_TIMEOUT:
			switch_to_mouse()

func switch_to_controller() -> void:
	if current_mode != "controller":
		current_mode = "controller"
		emit_signal("input_mode_changed", current_mode)

func switch_to_mouse() -> void:
	if current_mode != "mouse":
		current_mode = "mouse"
		emit_signal("input_mode_changed", current_mode)

func get_current_mode() -> String:
	return current_mode
