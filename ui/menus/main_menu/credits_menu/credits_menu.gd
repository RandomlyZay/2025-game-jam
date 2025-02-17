extends Control

func _ready() -> void:
	$BackButton.pressed.connect(_on_back_pressed)
	# Set up initial focus for controller support
	$BackButton.focus_mode = Control.FOCUS_ALL
	$BackButton.grab_focus()
	
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process_input(true)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_back_pressed()

func _on_back_pressed() -> void:
	Audio.play_sfx("tech_part")
	get_tree().change_scene_to_file("res://ui/menus/main_menu/main_menu.tscn") 


func _on_back_button_mouse_entered() -> void:
	Audio.play_sfx("text")
