extends Node2D

@onready var interactable: Area2D = $interactable

func _ready() -> void:
	interactable.set_interaction_callable(func(): _on_interact())

func get_interact_name() -> String:
	return "Enter Next Level"
	
func _on_interact() -> void:
	print("Goal is interacted with")
	get_tree().change_scene_to_file("res://stages/upgrade/upgrade.tscn")
