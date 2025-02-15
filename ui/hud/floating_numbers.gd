extends Node2D

# Since the scene root is Node2D, we need to modify the class
class_name FloatingNumbers

@onready var label: Label = $Label
@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	randomize()

func popup() -> void:
	# Don't create new numbers if we're being freed
	if not is_instance_valid(self) or is_queued_for_deletion():
		return
		
	var damage_text = ""
	var is_chest = false
	
	# Get the player's strength value
	var player = get_tree().get_first_node_in_group("player")
	if !is_instance_valid(player):
		return
		
	# Check if parent is valid
	var parent = get_parent()
	if !is_instance_valid(parent):
		return
		
	# Check if parent is a chest
	if parent.get_class() == "Node2D" and parent.has_node("interactable"):
		var interactable = parent.get_node("interactable")
		if is_instance_valid(interactable):
			damage_text = str(interactable.health) + " hits left"
			is_chest = true
	else:
		damage_text = str(player.strength)
	
	# Create a new floating number instance as a child of the scene root
	var new_floating_number = self.duplicate() as Node2D
	if not is_instance_valid(new_floating_number):
		return
		
	get_tree().current_scene.add_child(new_floating_number)
	new_floating_number.global_position = global_position
	
	var new_label = new_floating_number.get_node("Label")
	if !is_instance_valid(new_label):
		new_floating_number.queue_free()
		return
		
	new_label.text = damage_text
	
	# Different colors for chest vs enemy damage
	if is_chest:
		new_label.modulate = Color(1, 0.8, 0)  # Gold color for chest hits
	else:
		new_label.modulate = Color(1, 0.2, 0.2)  # Red color for enemy damage
	
	new_floating_number.global_position += _get_random_offset()
	
	var anim_player = new_floating_number.get_node("AnimationPlayer")
	if is_instance_valid(anim_player):
		anim_player.play("popup")

func _get_random_offset() -> Vector2:
	return Vector2(randf_range(-20, 20), randf_range(-20, -10))
