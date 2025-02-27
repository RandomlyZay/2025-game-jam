extends Node2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Audio.play_music("upgrade")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_weight_pressed() -> void:
	PlayerVariables.set_current_player("res://entities/characters/player/weight/player.tscn")
	next_level()

func _on_power_pressed() -> void:
	PlayerVariables.set_current_player("res://entities/characters/player/power/player.tscn")
	next_level()

func _on_speed_pressed() -> void:
	PlayerVariables.set_current_player("res://entities/characters/player/speed/player.tscn")
	next_level()
	
func next_level() -> void:
	get_tree().change_scene_to_file("res://stages/level2/level2.tscn")
