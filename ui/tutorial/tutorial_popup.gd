extends Control

signal tutorial_completed
signal fade_completed

@onready var moves_made = {
	"up": false,
	"down": false,
	"left": false,
	"right": false
}

var message_label: Label
var is_movement_tutorial = false
var has_sprinted = false
var has_dashed = false

func _ready():
	# Set initial visibility to transparent
	modulate = Color(1, 1, 1, 0)
	message_label = $Panel/Label
	fade_in()

func register_movement(direction: String) -> void:
	if not is_movement_tutorial:
		return
		
	if direction in moves_made:
		moves_made[direction] = true
	
	# Track movement completion
	if all_moves_completed():
		tutorial_completed.emit()
		fade_out()

func all_moves_completed() -> bool:
	if not is_movement_tutorial:
		return false
		
	for move in moves_made.values():
		if not move:
			return false
	return true

func set_message(message: String, is_movement: bool = false) -> void:
	message_label.text = message
	is_movement_tutorial = is_movement
	# Reset movement tracking if this is a movement tutorial
	if is_movement_tutorial:
		moves_made = {
			"up": false,
			"down": false,
			"left": false,
			"right": false
		}

func fade_in() -> void:
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(1, 1, 1, 1), 0.5)

func fade_out() -> void:
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(1, 1, 1, 0), 0.3)
	await tween.finished
	fade_completed.emit()
