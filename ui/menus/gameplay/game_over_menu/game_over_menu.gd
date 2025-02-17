extends CanvasLayer

# Nodes
@onready var retry_button: Button = $VBoxContainer/RetryButton
@onready var quit_button: Button = $VBoxContainer/QuitButton
@onready var message_label: Label = $VBoxContainer/Message

# Public Function to Show Menu
func show_menu(message: String = "") -> void:
	if message and message_label:
		message_label.text = message
	
	visible = true
	get_tree().paused = true
	
	Audio.play_music("game_over")
	
	if InputManager.get_current_mode() == "controller":
		retry_button.grab_focus()

# Button Callbacks
func _ready() -> void:
	connect_signals()
	setup_focus()
	visible = false
	
	InputManager.input_mode_changed.connect(_on_input_mode_changed)
	_on_input_mode_changed(InputManager.get_current_mode())

func connect_signals() -> void:
	retry_button.pressed.connect(on_retry_pressed)
	quit_button.pressed.connect(on_quit_pressed)

func setup_focus() -> void:
	# Setup focus neighbors
	retry_button.focus_neighbor_top = retry_button.get_path_to(quit_button)
	retry_button.focus_neighbor_bottom = retry_button.get_path_to(quit_button)
	
	quit_button.focus_neighbor_top = quit_button.get_path_to(retry_button)
	quit_button.focus_neighbor_bottom = quit_button.get_path_to(retry_button)
	
	# Setup focus next/previous
	retry_button.focus_next = retry_button.get_path_to(quit_button)
	retry_button.focus_previous = retry_button.get_path_to(quit_button)
	
	quit_button.focus_next = quit_button.get_path_to(retry_button)
	quit_button.focus_previous = quit_button.get_path_to(retry_button)

func on_retry_pressed() -> void:
	get_tree().paused = false
	Audio.play_sfx("tech_part")
	get_tree().reload_current_scene()

func on_quit_pressed() -> void:
	get_tree().paused = false
	
	# Stop all audio
	get_tree().call_group("music_players", "stop")
	get_tree().call_group("sfx_players", "stop")
	
	Audio.play_sfx("tech_part")
	get_tree().change_scene_to_file("res://ui/menus/main_menu/main_menu.tscn")

func _on_input_mode_changed(mode: String) -> void:
	if mode == "controller" and visible and retry_button:
		retry_button.grab_focus()


func _on_retry_button_mouse_entered() -> void:
	Audio.play_sfx("text")


func _on_quit_button_mouse_entered() -> void:
	Audio.play_sfx("text")
