extends Node2D

@onready var interact_label: Label = $InteractLabel
@onready var interact_range: Area2D = $InteractRange

var current_interactions := []
var can_interact := true

func _ready() -> void:
	interact_range.collision_layer = 0
	interact_range.collision_mask = 2
	interact_label.hide()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and can_interact and !current_interactions.is_empty():
		can_interact = false
		interact_label.hide()
		
		# Get the closest interaction, ensuring it's valid
		var interaction = current_interactions[0]
		if is_instance_valid(interaction) and interaction.has_method("interact"):
			await interaction.interact()
		
		can_interact = true
		_clean_invalid_interactions()

func _process(_delta: float) -> void:
	if current_interactions and can_interact:
		_clean_invalid_interactions()
		
		if !current_interactions.is_empty():
			var area = current_interactions[0]
			if is_instance_valid(area) and area.has_method("get_interact_name"):
				interact_label.text = area.get_interact_name()
				interact_label.show()
			else:
				interact_label.hide()
		else:
			interact_label.hide()
	else:
		interact_label.hide()

func _clean_invalid_interactions() -> void:
	# Remove any freed or invalid interactions
	current_interactions = current_interactions.filter(func(area): 
		return is_instance_valid(area) and !area.is_queued_for_deletion()
	)
	
	# Sort remaining valid interactions
	if !current_interactions.is_empty():
		current_interactions.sort_custom(_sort_by_nearest)

func _sort_by_nearest(area1, area2) -> bool:
	if !is_instance_valid(area1) or !is_instance_valid(area2):
		return false
	var area1_dist = global_position.distance_to(area1.global_position)
	var area2_dist = global_position.distance_to(area2.global_position)
	return area1_dist < area2_dist

func _on_interact_range_area_entered(area: Area2D) -> void:
	if is_instance_valid(area) and area.has_method("interact"):
		current_interactions.push_back(area)

func _on_interact_range_area_exited(area: Area2D) -> void:
	current_interactions.erase(area)
	_clean_invalid_interactions()
