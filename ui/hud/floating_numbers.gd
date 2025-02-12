extends Marker2D

@export var damage_node : PackedScene
@onready var label_node: Label = $Label

func _ready():
	randomize()

func popup():
	var damage = damage_node.instantiate()
	damage.position = global_position
	
	
	var tween = get_tree().create_tween()
	tween.tween_property(damage, "position", global_position + _get_direction(), 0.75)
	
	get_tree().current_scene.add_child(damage)
	
func _get_direction():
	#random direction for text to go
	return Vector2(randf_range(-1,1), -randf()) * 16
