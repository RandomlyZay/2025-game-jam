extends Node2D



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Audio.play_sfx("ding")
	Audio.play_music("upgrade")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_weight_pressed() -> void:
	Audio.play_sfx("robot_heal")
	next_level()

func _on_power_pressed() -> void:
	Audio.play_sfx("robot_heal")
	next_level()

func _on_speed_pressed() -> void:
	Audio.play_sfx("robot_heal")
	next_level()
	
func next_level() -> void:
	get_tree().change_scene_to_file("res://stages/level3/level3.tscn")


func _on_armor_mouse_entered() -> void:
	Audio.play_sfx("text")


func _on_element_mouse_entered() -> void:
	Audio.play_sfx("text")


func _on_flight_mouse_entered() -> void:
	Audio.play_sfx("text")
