extends Control

@onready var ui_manager: UIManager
@onready var game_camera: Camera2D = $AspectRatioContainer/SubViewportContainer/SubViewport/GameWorld/GameCamera
@onready var player: CharacterBody2D = $AspectRatioContainer/SubViewportContainer/SubViewport/GameWorld/Player

func _ready() -> void:
	setup_ui_manager()
	game_camera.make_current()
	Audio.stop_music()

func _process(_delta: float) -> void:
	if is_instance_valid(player):
		game_camera.position = player.position

func setup_ui_manager() -> void:
	ui_manager = UIManager.new()
	add_child(ui_manager)
	ui_manager.initialize_UI($AspectRatioContainer/SubViewportContainer/SubViewport/UILayer/HUD)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"): 
		if is_instance_valid(ui_manager.game_over_menu_instance) and ui_manager.game_over_menu_instance.visible:
			return
		ui_manager.handle_pause_input(event)
