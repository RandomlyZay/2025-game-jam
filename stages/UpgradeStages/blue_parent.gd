extends Node2D

@onready var blue: Area2D = $Blue




# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	blue.health = 1


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass





func _on_blue_interaction_completed(success: bool) -> void:
	print("Blue interaction Completed")
	pass # Replace with function body.
