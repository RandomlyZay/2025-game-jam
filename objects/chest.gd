extends Node2D

@onready var interactable: Area2D = $interactable
@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var floatingnumbers: Marker2D = $FloatingNumbers
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	interactable.interact = _on_interact
	

func _on_interact():
	print("Chest is interacted with")
	
	if interactable.health == 0:
		queue_free()
	else:
		interactable.health -=1
		floatingnumbers.popup()
