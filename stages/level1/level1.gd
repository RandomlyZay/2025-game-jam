extends Node2D

@onready var ui_manager: UIManager

func _ready() -> void:
	setup_ui_manager()
	Audio.stop_music()
	
func setup_ui_manager() -> void:
	ui_manager = UIManager.new()
	add_child(ui_manager)
	ui_manager.initialize_UI($UILayer/HUD)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"): 
		if is_instance_valid(ui_manager.game_over_menu_instance) and ui_manager.game_over_menu_instance.visible:
			return
		ui_manager.handle_pause_input(event)
