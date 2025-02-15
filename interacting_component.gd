extends Node2D

#variable for label to be displayed
@onready var interact_label: Label = $InteractLabel

#array of interactable items
var current_interactions := []
var can_interact := true

#check for interact 'e'
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and can_interact:
		if current_interactions:
			can_interact = false
			interact_label.hide()
			
			await current_interactions[0].interact.call()
			
			can_interact = true
			


func _process(_delta: float) -> void:
	if current_interactions and can_interact:
		
		# Remove any freed interactions
		current_interactions = current_interactions.filter(func(area): return is_instance_valid(area))
		
		 # Sort and check for valid interactions
		current_interactions.sort_custom(_sort_by_nearest)
		if current_interactions.size() > 0:
			# Make sure the area has the required properties before accessing them
			var area = current_interactions[0]
			if area.has_method("interact") and area.has_method("get_interact_name"):
				interact_label.text = area.get_interact_name()
				interact_label.show()
			else:
				interact_label.hide()
		else:
			interact_label.hide()
	else:
		interact_label.hide()

func _sort_by_nearest(area1, area2):
	# Fix typo in 'position'
	var area1_dist = global_position.distance_to(area1.global_position)
	var area2_dist = global_position.distance_to(area2.global_position)
	return area1_dist < area2_dist
	
#add area to array
func _on_interact_range_area_entered(area: Area2D) -> void:
	print("area entered")
	current_interactions.push_back(area)

#remove from array

func _on_interact_range_area_exited(area: Area2D) -> void:
	print("area Exited")
	current_interactions.erase(area)
