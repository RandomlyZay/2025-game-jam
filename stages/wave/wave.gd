extends Node2D

# Player Nodes
@onready var human: CharacterBody2D = $Player/Human

@export_group("Enemy Count")
@export var initial_enemy_count: int = 1
@export var melee_enemy_ratio: float = 0.25
@export var max_melee_ratio: float = 0.4

# UI Manager
@onready var ui_manager: UIManager

### Core and Setup Functions
func _ready() -> void:
	get_tree().paused = false
	
	Audio.play_music("sanctuary_riot")
	
	setup_ui_manager()
	connect_player_signals()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"): 
		# Don't allow pausing if game over menu is visible
		if is_instance_valid(ui_manager.game_over_menu_instance) and ui_manager.game_over_menu_instance.visible:
			return
			
		if is_instance_valid(ui_manager.pause_menu_instance) and ui_manager.pause_menu_instance.visible:
			ui_manager.hide_pause_menu()
		else:
			ui_manager.show_pause_menu()

func setup_ui_manager() -> void:
	ui_manager = UIManager.new()
	add_child(ui_manager)
	ui_manager.initialize_UI($HUDCamera/HUD)

func connect_player_signals() -> void:
	# Connect human signals
	human.health_changed.connect(func(new_health, max_health): 
		ui_manager.update_human_health(new_health, max_health))
	human.human_died.connect(on_human_death)

func _notification(what: int) -> void:
	if (what == NOTIFICATION_WM_WINDOW_FOCUS_OUT 
		and (!is_instance_valid(ui_manager.game_over_menu_instance) or !ui_manager.game_over_menu_instance.visible)):
		ui_manager.show_pause_menu()

func find_nearest_enemy() -> Node2D:
	# Determine if any enemies are within the visible screen area
	var viewport_rect = get_viewport().get_visible_rect()
	var screen_center = viewport_rect.size / 2
	var buffer = 400.0  # Buffer zone around the screen for detecting enemies
	
	# Check if any enemies are visible on screen
	for enemy in get_tree().get_nodes_in_group("enemies"):
		var enemy_screen_position = enemy.global_position - human.global_position + screen_center
		
		# Check if the enemy is within the visible buffer area
		var is_offscreen = (
			enemy_screen_position.x < -buffer or
			enemy_screen_position.x > viewport_rect.size.x + buffer or
			enemy_screen_position.y < -buffer or
			enemy_screen_position.y > viewport_rect.size.y + buffer
		)
		# If any enemy is in the screen area, return null for the indicator to be invisible
		if !is_offscreen:
			return null
	
	# Find the nearest enemy when none are visible on screen
	var nearest_enemy: Node2D = null
	var min_distance: float = INF
	
	for enemy in get_tree().get_nodes_in_group("enemies"):
		var distance_to_human = human.global_position.distance_squared_to(enemy.global_position)
		if distance_to_human < min_distance:
			min_distance = distance_to_human
			nearest_enemy = enemy
	
	return nearest_enemy

### Death Handling
func on_human_death() -> void:
	if is_instance_valid(human):
		human.visible = false
		human.set_process(false)
		human.set_physics_process(false)
		human.set_process_input(false)
		
		# Play death sound before setting game over flag
		Audio.play_sfx("human_death")
	
	# Create timer for delayed game over message
	var timer = get_tree().create_timer(1.5)
	timer.timeout.connect(func():
		ui_manager.trigger_game_over("Human Died!")
		if is_instance_valid(human):
			human.queue_free()
	)
	
