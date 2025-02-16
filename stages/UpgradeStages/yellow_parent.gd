extends Node2D

@onready var yellow: Area2D = $Yellow



# Called when the node enters the scene tree for the first time.
func _ready() -> void:

	yellow.health = 1
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
