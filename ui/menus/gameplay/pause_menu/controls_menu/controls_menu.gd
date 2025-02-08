extends Control

@onready var back_button: Button = $BackButton

func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	back_button.focus_mode = Control.FOCUS_ALL
	back_button.grab_focus()
	
	InputManager.input_mode_changed.connect(_on_input_mode_changed)
	_on_input_mode_changed(InputManager.get_current_mode())
	
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process_input(true)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_back_pressed()

func _on_back_pressed() -> void:
	hide()  # Hide controls menu
	var pause_menu = get_parent()
	pause_menu.background.show()  # Show pause menu background
	pause_menu.center_container.show()  # Show pause menu buttons

func _on_input_mode_changed(mode: String) -> void:
	if mode == "controller" and visible:
		back_button.grab_focus() 
