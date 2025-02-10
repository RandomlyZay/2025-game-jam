extends Control

@onready var first_button: Button = $VBoxContainer/PlayButton

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	setup_buttons()
	
	# Only start menu music if it's not already playing
	if not Audio.current_track == "main_menu_theme":
		Audio.play_music("main_menu_theme")
	
	InputManager.input_mode_changed.connect(_on_input_mode_changed)
	_on_input_mode_changed(InputManager.get_current_mode())

func setup_buttons() -> void:
	# Connect button signals
	$VBoxContainer/PlayButton.pressed.connect(_on_play_pressed)
	$VBoxContainer/ControlsButton.pressed.connect(_on_controls_pressed)
	$VBoxContainer/SettingsButton.pressed.connect(_on_settings_pressed)
	$VBoxContainer/CreditsButton.pressed.connect(_on_credits_pressed)
	$VBoxContainer/QuitButton.pressed.connect(_on_quit_pressed)
	
	# Setup controller focus neighbors
	var buttons = [
		$VBoxContainer/PlayButton,
		$VBoxContainer/ControlsButton,
		$VBoxContainer/SettingsButton,
		$VBoxContainer/CreditsButton,
		$VBoxContainer/QuitButton
	]
	 
	for i in range(buttons.size()):
		var button = buttons[i]
		var prev_button = buttons[i - 1] if i > 0 else buttons[-1]
		var next_button = buttons[i + 1] if i < buttons.size() - 1 else buttons[0]
		
		button.focus_neighbor_top = button.get_path_to(prev_button)
		button.focus_neighbor_bottom = button.get_path_to(next_button)
		button.focus_previous = button.get_path_to(prev_button)
		button.focus_next = button.get_path_to(next_button)

func _on_input_mode_changed(mode: String) -> void:
	if mode == "controller":
		first_button.grab_focus()

func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://stages/level1/level1.tscn")

func _on_controls_pressed() -> void:
	get_tree().change_scene_to_file("res://ui/menus/main_menu/controls_menu/controls_menu.tscn")

func _on_settings_pressed() -> void:
	get_tree().change_scene_to_file("res://ui/menus/main_menu/settings_menu/settings_menu.tscn")

func _on_credits_pressed() -> void:
	get_tree().change_scene_to_file("res://ui/menus/main_menu/credits_menu/credits_menu.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()
