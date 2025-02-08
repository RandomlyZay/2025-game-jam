extends Control

@onready var back_button: Button = $BackButton
@onready var tutorial_button: Button = $TutorialButton
@onready var keyboard_controls: VBoxContainer = $ControlsContainer/MarginContainer/HBoxContainer/KeyboardControls
@onready var controller_controls: VBoxContainer = $ControlsContainer/MarginContainer/HBoxContainer/ControllerControls
@onready var v_separator: VSeparator = $ControlsContainer/MarginContainer/HBoxContainer/VSeparator

func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	tutorial_button.pressed.connect(_on_tutorial_pressed)
	back_button.focus_mode = Control.FOCUS_ALL
	tutorial_button.focus_mode = Control.FOCUS_ALL
	back_button.grab_focus()
	
	InputManager.input_mode_changed.connect(_on_input_mode_changed)
	_on_input_mode_changed(InputManager.get_current_mode())
	
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process_input(true)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_back_pressed()

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://ui/menus/main_menu/main_menu.tscn")

func _on_tutorial_pressed() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	get_tree().change_scene_to_file("res://stages/tutorial/tutorial.tscn")

func _on_input_mode_changed(mode: String) -> void:
	# Update control visibility
	keyboard_controls.visible = (mode == "mouse")
	controller_controls.visible = (mode == "controller")
	v_separator.visible = false
	
	# Handle focus
	if mode == "controller":
		back_button.grab_focus()
