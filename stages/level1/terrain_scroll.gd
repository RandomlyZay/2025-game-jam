extends Node2D

var section1: StaticBody2D
var section2: StaticBody2D
var section3: StaticBody2D
var camera: Camera2D

const SECTION_WIDTH = 1920

func _ready():
	section1 = $Section1
	section2 = $Section2
	section3 = $Section3
	# Wait a frame to ensure Player and Camera are ready
	await get_tree().create_timer(0.1).timeout
	camera = get_node("../Player/Camera")
	if !camera:
		push_error("Camera not found!")
		return

func _process(_delta):
	if !camera:
		return
		
	var camera_x = camera.get_screen_center_position().x
	var current_section = floor(camera_x / SECTION_WIDTH)
	
	# Position sections based on current section
	section1.position.x = (current_section - 1) * SECTION_WIDTH
	section2.position.x = current_section * SECTION_WIDTH
	section3.position.x = (current_section + 1) * SECTION_WIDTH
	
	# Only rotate when we're very close to the end of current section
	var section_progress = camera_x - (current_section * SECTION_WIDTH)
	if section_progress > SECTION_WIDTH * 0.95:
		var temp = section1
		section1 = section2
		section2 = section3
		section3 = temp
