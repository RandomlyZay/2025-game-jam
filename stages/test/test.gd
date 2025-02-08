extends Node2D

# UI Manager
@onready var ui_manager: UIManager

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	setup_ui_manager()
	Audio.play_music("test")

func setup_ui_manager() -> void:
	ui_manager = UIManager.new()
	add_child(ui_manager)
	ui_manager.initialize_UI($HUDCamera/HUD)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"): 
		# Don't allow pausing if game over menu is visible
		if is_instance_valid(ui_manager.game_over_menu_instance) and ui_manager.game_over_menu_instance.visible:
			return
			
		if is_instance_valid(ui_manager.pause_menu_instance) and ui_manager.pause_menu_instance.visible:
			ui_manager.hide_pause_menu()
		else:
			ui_manager.show_pause_menu()
