extends Node2D

@onready var ui_manager: UIManager
@onready var dialogue = $HUD/PlayerHUD/DialogueBox

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	setup_ui_manager()
	Audio.play_music("intro")
	
	dialogue.dialogue_finished.connect(_on_dialogue_finished)
	dialogue.load_and_start_dialogue("intro", "intro")

func setup_ui_manager() -> void:
	ui_manager = UIManager.new()
	add_child(ui_manager)
	ui_manager.initialize_UI($HUD)

func _on_dialogue_finished() -> void:
	get_tree().change_scene_to_file("res://stages/level1/level1.tscn")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
