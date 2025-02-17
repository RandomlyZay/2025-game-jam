extends Node2D

var scroll_speed = 50
var star_scroll_speed = 100
var planet_scroll_speed = 70
var text_finished = false
var planet_transition_started = false
var planet_wait_time = 5.0
var planet_timer = 0.0
var planet_target_y = 0
var skip_text_time := 0.0
var fast_forward_multiplier := 10.0

func _ready() -> void:
	Audio.play_music("intro")
	$ScrollingText.modulate.a = 1.0
	$PlanetBackground.modulate.a = 0.0
	$StarParallax/ParallaxLayer.motion_offset.y = 0
	$SkipText.modulate.a = 1.0

func _process(delta: float) -> void:
	# Strobe skip text effect
	skip_text_time += delta * 3.0
	$SkipText.modulate.a = (sin(skip_text_time) + 1.0) * 0.5
	
	# Move skip text with main text
	$SkipText.position.y = $ScrollingText.position.y - 200
	
	# Fast forward when interact is held
	var speed_multiplier = fast_forward_multiplier if Input.is_action_pressed("interact") else 1.0
	
	# Apply speed multiplier to all movements
	$StarParallax/ParallaxLayer.motion_offset.y -= star_scroll_speed * delta * speed_multiplier
	
	if not text_finished:
		$ScrollingText.position.y -= scroll_speed * delta * speed_multiplier
		if $ScrollingText.position.y < -2000:
			text_finished = true
			start_planet_transition()
	
	if planet_transition_started:
		$PlanetBackground.visible = true
		$PlanetBackground.modulate.a = min($PlanetBackground.modulate.a + delta * 0.5, 1.0)
		
		# Scroll planet from bottom to target position
		if $PlanetBackground.position.y > planet_target_y:
			$PlanetBackground.position.y -= planet_scroll_speed * delta * speed_multiplier
		else:
			planet_timer += delta
			if planet_timer >= planet_wait_time:
				on_intro_finished()

func start_planet_transition() -> void:
	planet_transition_started = true

func on_intro_finished() -> void:
	get_tree().change_scene_to_file("res://stages/level1/level1.tscn")
