extends Node2D



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_weight_pressed() -> void:
	next_level()

func _on_power_pressed() -> void:
	next_level()

func _on_speed_pressed() -> void:
	next_level()
	
func next_level() -> void:
	get_tree().change_scene_to_file("res://stages/level2/level2.tscn")
