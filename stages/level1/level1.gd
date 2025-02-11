extends Control

@onready var ui_manager: UIManager
@onready var game_camera: Camera2D = $GameWorld/GameCamera
@onready var player: CharacterBody2D = $GameWorld/Player
@onready var game_world: Node2D = $GameWorld

const BASE_VIEWPORT_WIDTH := 2
const BASE_VIEWPORT_HEIGHT := 1

var original_parallax_motion_scales := []

func _ready() -> void:
	setup_ui_manager()
	game_camera.make_current()
	Audio.stop_music()
	#get_viewport().size_changed.connect(_on_viewport_size_changed)
	
	# Store original parallax motion scales
	var parallax_bg = game_world.get_node("ParallaxBackground")
	original_parallax_motion_scales.clear()
	for layer in parallax_bg.get_children():
		if layer is ParallaxLayer:
			original_parallax_motion_scales.append(layer.motion_scale)
	
	#_on_viewport_size_changed()  # Initial scaling

func _process(_delta: float) -> void:
	if is_instance_valid(player):
		game_camera.position = player.position

#func _on_viewport_size_changed() -> void:
	##var current_viewport_size: Vector2i = viewport.size
	##var scale_factor: float = min(
		##current_viewport_size.x / BASE_VIEWPORT_WIDTH,
		##current_viewport_size.y / BASE_VIEWPORT_HEIGHT
	##)
	#
	##game_world.scale = Vector2(scale_factor, scale_factor)
	#
	## Adjust parallax layers' motion_scale
	#var parallax_bg = game_world.get_node("ParallaxBackground")
	#var layer_index := 0
	#for layer in parallax_bg.get_children():
		#if layer is ParallaxLayer:
			#if layer_index < original_parallax_motion_scales.size():
				##layer.motion_scale = original_parallax_motion_scales[layer_index] / scale_factor
				#layer_index += 1
	#
	##game_camera.limit_bottom = 720 * scale_factor

func setup_ui_manager() -> void:
	ui_manager = UIManager.new()
	add_child(ui_manager)
	ui_manager.initialize_UI($GameWorld/UILayer/HUD)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"): 
		if is_instance_valid(ui_manager.game_over_menu_instance) and ui_manager.game_over_menu_instance.visible:
			return
		ui_manager.handle_pause_input(event)
