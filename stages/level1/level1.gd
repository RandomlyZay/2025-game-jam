extends Node2D

@onready var ui_manager: UIManager
@onready var dialogue = $HUD/PlayerHUD/DialogueBox

const SECTION_WIDTH = 1920

func _ready() -> void:
	setup_ui_manager()
	connect_player_signals()
	Audio.stop_music()
	#dialogue.load_and_start_dialogue("test", "test")  # Uncomment to run dialogue

func setup_ui_manager() -> void:
	ui_manager = UIManager.new()
	add_child(ui_manager)
	ui_manager.initialize_UI($HUD)

func connect_player_signals() -> void:
	var player = $Player000
	if player:
		player.health_changed.connect(func(new_health, max_health): 
			if is_instance_valid(ui_manager):
				ui_manager.update_health(new_health, max_health))
		player.player_died.connect(func(): 
			if is_instance_valid(ui_manager):
				ui_manager.show_game_over_menu())

func on_dialogue_finished() -> void:
	get_tree().change_scene_to_file("res://stages/level1/level1.tscn")

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"): 
		if is_instance_valid(ui_manager.game_over_menu_instance) and ui_manager.game_over_menu_instance.visible:
			return
		ui_manager.handle_pause_input(event)
