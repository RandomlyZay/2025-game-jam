extends CanvasLayer

# Nodes
@onready var resume_button: Button = $CenterContainer/VBoxContainer/Resume
@onready var settings_button: Button = $CenterContainer/VBoxContainer/Settings
@onready var controls_button: Button = $CenterContainer/VBoxContainer/Controls
@onready var quit_button: Button = $CenterContainer/VBoxContainer/Quit
@onready var background: ColorRect = $Background
@onready var center_container: CenterContainer = $CenterContainer

var settings_menu_scene = preload("res://ui/menus/gameplay/pause_menu/settings_menu/settings_menu.tscn")
var controls_menu_scene = preload("res://ui/menus/gameplay/pause_menu/controls_menu/controls_menu.tscn")
var settings_menu_instance: Control = null
var controls_menu_instance: Control = null
var tutorial_popup: Control = null

# Public Function to Show Menu
func show_menu() -> void:
	visible = true
	get_tree().paused = true
	if tutorial_popup:
		tutorial_popup.hide()
	
	if InputManager.get_current_mode() == "controller":
		resume_button.grab_focus()
	setup_focus()

# Button Callbacks
func _ready() -> void:
	# Handle UI cancel action (B button/Escape)
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Find the countdown label and tutorial popup
	var hud = get_tree().get_first_node_in_group("hud")
	if hud:
		tutorial_popup = hud.get_node_or_null("TutorialPopup")
	
	# Enable focus for all buttons
	resume_button.focus_mode = Control.FOCUS_ALL
	settings_button.focus_mode = Control.FOCUS_ALL
	controls_button.focus_mode = Control.FOCUS_ALL
	quit_button.focus_mode = Control.FOCUS_ALL
	
	# Connect to input mode changes
	InputManager.input_mode_changed.connect(_on_input_mode_changed)
	
	setup_focus()

func setup_focus() -> void:
	# Setup focus neighbors
	resume_button.focus_neighbor_top = resume_button.get_path_to(quit_button)
	resume_button.focus_neighbor_bottom = resume_button.get_path_to(controls_button)
	resume_button.focus_next = resume_button.get_path_to(controls_button)
	resume_button.focus_previous = resume_button.get_path_to(quit_button)
	
	controls_button.focus_neighbor_top = controls_button.get_path_to(resume_button)
	controls_button.focus_neighbor_bottom = controls_button.get_path_to(settings_button)
	controls_button.focus_next = controls_button.get_path_to(settings_button)
	controls_button.focus_previous = controls_button.get_path_to(resume_button)
	
	settings_button.focus_neighbor_top = settings_button.get_path_to(controls_button)
	settings_button.focus_neighbor_bottom = settings_button.get_path_to(quit_button)
	settings_button.focus_next = settings_button.get_path_to(quit_button)
	settings_button.focus_previous = settings_button.get_path_to(controls_button)
	
	quit_button.focus_neighbor_top = quit_button.get_path_to(settings_button)
	quit_button.focus_neighbor_bottom = quit_button.get_path_to(resume_button)
	quit_button.focus_next = quit_button.get_path_to(resume_button)
	quit_button.focus_previous = quit_button.get_path_to(settings_button)

func _on_resume_pressed() -> void:
	get_tree().paused = false
	if tutorial_popup:
		tutorial_popup.show()
	Audio.play_sfx("tech_part")
	visible = false

func _on_controls_pressed() -> void:
	Audio.play_sfx("tech_part")
	# Create controls menu if it doesn't exist
	if not controls_menu_instance:
		controls_menu_instance = controls_menu_scene.instantiate()
		add_child(controls_menu_instance)
		controls_menu_instance.back_pressed.connect(_on_submenu_back_pressed.bind("controls"))
	
	# Hide pause menu elements
	background.hide()
	center_container.hide()
	
	# Show controls menu
	controls_menu_instance.show()
	if InputManager.get_current_mode() == "controller":
		controls_menu_instance.grab_initial_focus()

func _on_settings_pressed() -> void:
	Audio.play_sfx("tech_part")
	# Create settings menu if it doesn't exist
	if not settings_menu_instance:
		settings_menu_instance = settings_menu_scene.instantiate()
		add_child(settings_menu_instance)
		settings_menu_instance.back_pressed.connect(_on_submenu_back_pressed.bind("settings"))
	
	# Hide pause menu elements
	background.hide()
	center_container.hide()
	
	# Show settings menu
	settings_menu_instance.show()
	if InputManager.get_current_mode() == "controller":
		settings_menu_instance.grab_initial_focus()

func _on_submenu_back_pressed(menu_type: String) -> void:
	background.show()
	center_container.show()
	
	if InputManager.get_current_mode() == "controller":
		match menu_type:
			"controls":
				controls_button.grab_focus()
			"settings":
				settings_button.grab_focus()

func _on_quit_pressed() -> void:
	# Stop all audio before quitting
	Audio.stop_music()
	get_tree().paused = false
	Audio.play_sfx("tech_part")
	get_tree().change_scene_to_file("res://ui/menus/main_menu/main_menu.tscn")

func _on_input_mode_changed(mode: String) -> void:
	if mode == "controller":
		if visible and center_container.visible:
			resume_button.grab_focus()
		elif settings_menu_instance and settings_menu_instance.visible:
			settings_menu_instance.grab_initial_focus()
		elif controls_menu_instance and controls_menu_instance.visible:
			controls_menu_instance.grab_initial_focus()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and visible: 
		_on_resume_pressed() 
		get_viewport().set_input_as_handled()


func _on_resume_mouse_entered() -> void:
	Audio.play_sfx("text")


func _on_controls_mouse_entered() -> void:
	Audio.play_sfx("text")


func _on_settings_mouse_entered() -> void:
	Audio.play_sfx("text")


func _on_quit_mouse_entered() -> void:
	Audio.play_sfx("text")
