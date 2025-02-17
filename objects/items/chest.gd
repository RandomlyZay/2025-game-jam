extends Node2D

@onready var interactable: Area2D = $interactable
@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var floatingnumbers: Node2D = $FloatingNumbers

func _ready() -> void:
	interactable.health = 2
	interactable.set_interaction_callable(func(): _on_interact())

func get_interact_name() -> String:
	return "Open Chest (%d hits left)" % interactable.health
	
func _on_interact() -> void:
	print("Chest is interacted with")
	
	var player = get_tree().get_first_node_in_group("player")
	if !player:
		return
	
	# Flash effect
	sprite_2d.modulate = Color(2, 2, 2)  # Flash bright white
	var tween = create_tween()
	tween.tween_property(sprite_2d, "modulate", Color.WHITE, 0.2)
	
	# Small shake effect
	var original_pos = sprite_2d.position
	var shake_strength = 4.0
	
	tween = create_tween()
	tween.tween_property(sprite_2d, "position", 
		original_pos + Vector2(randf_range(-1, 1), randf_range(-1, 1)) * shake_strength, 
		0.05)
	tween.tween_property(sprite_2d, "position", original_pos, 0.05)
		
	if interactable.health <= 1:
			# Show final floating number before destroying
		if is_instance_valid(floatingnumbers):
			floatingnumbers.popup()
			
		# Final hit effect before destroying
		var final_tween = create_tween()
		final_tween.tween_property(sprite_2d, "modulate", Color(1, 1, 1, 0), 0.3)
		await final_tween.finished
		
		queue_free()
	else:
		interactable.health -= 1
		Audio.play_sfx("punch")
		
		# Update floating numbers damage display
		if is_instance_valid(floatingnumbers):
			floatingnumbers.popup()
