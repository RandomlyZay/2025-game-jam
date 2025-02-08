extends Node
class_name UIManager

var human_health_bar: ProgressBar

# Menus
var pause_menu_scene: PackedScene = preload("res://ui/menus/gameplay/pause_menu/pause_menu.tscn")
var game_over_menu_scene: PackedScene = preload("res://ui/menus/gameplay/game_over_menu/game_over_menu.tscn")
var pause_menu_instance: Node = null
var game_over_menu_instance: Node = null

func initialize_UI(hud_node: Node) -> void:
	# Get references to health bars
	human_health_bar = hud_node.get_node("PlayerHUD/HumanHealth")

func update_human_health(health: int, max_health: int = 50) -> void:
	if human_health_bar:
		human_health_bar.max_value = max_health
		human_health_bar.value = health

func show_pause_menu() -> void:
	if !is_instance_valid(pause_menu_instance):
		pause_menu_instance = pause_menu_scene.instantiate()
		add_child(pause_menu_instance)
	
	pause_menu_instance.show_menu()
	pause_menu_instance.visible = true
	get_tree().paused = true

func hide_pause_menu() -> void:
	if is_instance_valid(pause_menu_instance):
		pause_menu_instance.visible = false
	get_tree().paused = false

func show_game_over_menu(message: String = "") -> void:
	if !is_instance_valid(game_over_menu_instance):
		game_over_menu_instance = game_over_menu_scene.instantiate()
		add_child(game_over_menu_instance)
	
	game_over_menu_instance.call("show_menu", message)
	game_over_menu_instance.visible = true
	get_tree().paused = true

func hide_game_over_menu() -> void:
	if is_instance_valid(game_over_menu_instance):
		game_over_menu_instance.visible = false
	get_tree().paused = false

func trigger_game_over(message: String) -> void:
	if is_instance_valid(pause_menu_instance):
		pause_menu_instance.queue_free()
		pause_menu_instance = null
	
	show_game_over_menu(message)
