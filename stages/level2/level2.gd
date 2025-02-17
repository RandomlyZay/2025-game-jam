extends Node2D

const Player = preload("res://entities/characters/player/player.gd")

@onready var ui_manager: UIManager
var player: Node2D

func _ready() -> void:
	setup_ui_manager()
	spawn_player()
	Audio.play_music("level")

func setup_ui_manager() -> void:
	ui_manager = UIManager.new()
	add_child(ui_manager)
	ui_manager.initialize_UI($HUD)

func spawn_player() -> void:
	var player_scene = load(PlayerVariables.get_current_player())
	player = player_scene.instantiate()
	player.position = Vector2(200, 1000)
	add_child(player)
	
	var camera = Camera2D.new()
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_bottom = 1440
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 3.0
	player.add_child(camera)
	
	var typed_player := player as Player
	if typed_player:
		typed_player.health_changed.connect(func(new_health, max_health): 
			if is_instance_valid(ui_manager):
				ui_manager.update_health(new_health, max_health))
		typed_player.player_died.connect(func(): 
			if is_instance_valid(ui_manager):
				ui_manager.show_game_over_menu())

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"): 
		if is_instance_valid(ui_manager.game_over_menu_instance) and ui_manager.game_over_menu_instance.visible:
			return
		ui_manager.handle_pause_input(event)
