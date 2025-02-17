extends Node

var current_player_scene: String = "res://entities/characters/player/player.tscn"

func set_current_player(scene_path: String) -> void:
	current_player_scene = scene_path

func get_current_player() -> String:
	return current_player_scene
