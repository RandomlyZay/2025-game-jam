extends Node2D

@onready var ui_manager: UIManager
@onready var dialogue = $HUD/PlayerHUD/DialogueBox
@onready var camera = $Player/Camera
@onready var section1: StaticBody2D = $TerrainBounds/Section1
@onready var section2: StaticBody2D = $TerrainBounds/Section2
@onready var section3: StaticBody2D = $TerrainBounds/Section3

const SECTION_WIDTH = 1920

func _ready() -> void:
	setup_ui_manager()
	connect_player_signals()
	$HUD/PlayerHUD/Health.show()
	Audio.stop_music()
	#dialogue.load_and_start_dialogue("test", "test")  # Uncomment to run dialogue

func setup_ui_manager() -> void:
	ui_manager = UIManager.new()
	add_child(ui_manager)
	ui_manager.initialize_UI($HUD)

func connect_player_signals() -> void:
	var player = $Player
	if player:
		player.health_changed.connect(func(new_health, max_health): 
			if is_instance_valid(ui_manager):
				ui_manager.update_health(new_health, max_health))
		player.player_died.connect(func(): 
			if is_instance_valid(ui_manager):
				ui_manager.show_game_over_menu())

func _process(_delta) -> void:
	if !camera:
		return
		
	var camera_x = camera.get_screen_center_position().x
	var current_section = floor(camera_x / SECTION_WIDTH)
	
	# Position sections based on current section
	section1.position.x = (current_section - 1) * SECTION_WIDTH
	section2.position.x = current_section * SECTION_WIDTH
	section3.position.x = (current_section + 1) * SECTION_WIDTH
	
	# Only rotate when we're very close to the end of current section
	var section_progress = camera_x - (current_section * SECTION_WIDTH)
	if section_progress > SECTION_WIDTH * 0.95:
		var temp = section1
		section1 = section2
		section2 = section3
		section3 = temp

func on_dialogue_finished() -> void:
	get_tree().change_scene_to_file("res://stages/level1/level1.tscn")

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"): 
		if is_instance_valid(ui_manager.game_over_menu_instance) and ui_manager.game_over_menu_instance.visible:
			return
		ui_manager.handle_pause_input(event)
