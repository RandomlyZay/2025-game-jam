extends Node2D

@onready var interactable: Area2D = $interactable
@onready var sprite_2d: Sprite2D = $Sprite2D
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	interactable.interact = _on_interact
	

func _on_interact():
	print("Chest is interacted with")
<<<<<<< HEAD
	queue_free()
=======
	#queue_free()
	
>>>>>>> 377014ea43272914aad6eac2198bf1ed29e84c21
