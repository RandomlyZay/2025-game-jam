extends Area2D

signal interaction_completed(success: bool)

@export var interact_name: String = "Interact"
@export var is_interactable: bool = true
@export var health: int = 100

var _interaction_func: Callable

func _ready() -> void:
	# Connect to our own signal to ensure it's used
	interaction_completed.connect(_on_interaction_completed)

func set_interaction_callable(callable: Callable) -> void:
	_interaction_func = callable

func get_interact_name() -> String:
	var parent = get_parent()
	if is_instance_valid(parent) and parent.has_method("get_interact_name"):
		return parent.get_interact_name()
	return interact_name

func interact() -> void:
	var success = false
	if _interaction_func.is_valid():
		_interaction_func.call()  # Call the interaction function
		success = true
	# Emit the signal after the interaction is complete
	interaction_completed.emit(success)

func _on_interaction_completed(_success: bool) -> void:
	# Handle interaction completion, update state as needed
	pass
