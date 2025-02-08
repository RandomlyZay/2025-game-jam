extends Node2D

var fade_in_time := 0.5
var fade_out_time := 0.3
var current_tween: Tween
var noise := FastNoiseLite.new()
var time := 0.0
var base_scale := Vector2(1.0, 1.0)
var heat_rate := 120.0 

# For projectile detection
@onready var projectile_detector := Area2D.new()
@onready var detector_shape := CollisionShape2D.new()
@onready var robot_detector := Area2D.new()
@onready var robot_shape := CollisionShape2D.new()

func _ready() -> void:
	noise.seed = randi()
	noise.frequency = 2.0
	
	add_to_group("destabilizing_field")
	
	# Setup robot detection
	add_child(robot_detector)
	robot_detector.add_child(robot_shape)
	robot_detector.add_to_group("destabilizing_field")
	
	var robot_circle = CircleShape2D.new()
	robot_circle.radius = 150  # Match the field size
	robot_shape.shape = robot_circle
	
	# Set up collision for robot detection
	robot_detector.collision_layer = 0
	robot_detector.collision_mask = 2  # Layer 2 for robot detection
	
	# Connect robot detector signals
	robot_detector.area_entered.connect(_on_robot_entered)
	robot_detector.area_exited.connect(_on_robot_exited)
	
	# Setup projectile detection
	add_child(projectile_detector)
	projectile_detector.add_child(detector_shape)
	
	var circle_shape = CircleShape2D.new()
	circle_shape.radius = 150  # Match the field size
	detector_shape.shape = circle_shape
	
	# Set up collision masks to detect projectiles
	projectile_detector.collision_layer = 0
	projectile_detector.collision_mask = 4 | 8  # Layer 3 (4) for robot bullets, layer 4 (8) for enemy bullets
	
	# Connect projectile detector signals
	projectile_detector.area_entered.connect(_on_projectile_entered)
	projectile_detector.body_entered.connect(_on_body_entered)
	projectile_detector.area_exited.connect(_on_body_exited)
	
	fade_in()

func _process(delta: float) -> void:
	time += delta * 5.0
	
	# Add twitchy, unstable movement
	var noise_x = noise.get_noise_2d(time, 0.0) * 10.0
	var noise_y = noise.get_noise_2d(0.0, time) * 10.0
	position = Vector2(noise_x, noise_y)
	
	# Add pulsing/bouncy scale effect
	var scale_noise = (noise.get_noise_1d(time) * 0.1) + 1.0
	$Sprite2D.scale = base_scale * scale_noise
	
	# Check for robot in field radius
	var robot = get_tree().get_first_node_in_group("robot")
	if robot:
		var distance = global_position.distance_to(robot.global_position)
		var in_field = distance <= 150  # Field radius
		if in_field and not robot.in_destabilizing_field:
			robot.in_destabilizing_field = true
		elif not in_field and robot.in_destabilizing_field:
			robot.in_destabilizing_field = false

func fade_in() -> void:
	if current_tween and current_tween.is_valid():
		current_tween.kill()
	
	base_scale = Vector2(1.0, 1.0)
	current_tween = create_tween()
	current_tween.tween_property($Sprite2D, "modulate", Color(1, 1, 1, 0.8), fade_in_time)
	current_tween.parallel().tween_property($Sprite2D, "scale", base_scale, fade_in_time).set_trans(Tween.TRANS_BOUNCE)

func fade_out() -> void:
	if current_tween and current_tween.is_valid():
		current_tween.kill()
	
	current_tween = create_tween()
	current_tween.tween_property($Sprite2D, "modulate", Color(1, 1, 1, 0), fade_out_time)
	current_tween.parallel().tween_property($Sprite2D, "scale", Vector2(0.8, 0.8), fade_out_time)
	current_tween.tween_callback(queue_free)

func _on_projectile_entered(area: Area2D) -> void:
	# First check if the area itself is a projectile
	if area.is_in_group("projectiles"):
		destroy_projectile(area)
		return
		
	# If not, check its parent
	var projectile = area.get_parent()
	if projectile and projectile.is_in_group("projectiles"):
		destroy_projectile(projectile)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("projectiles"):
		destroy_projectile(body)

func _on_body_exited(_body: Node2D) -> void:
	pass  # Handle continuous heat application in _process

func _on_robot_entered(area: Area2D) -> void:
	var parent = area.get_parent()
	if parent and parent.is_in_group("robot"):
		parent.in_destabilizing_field = true

func _on_robot_exited(area: Area2D) -> void:
	var parent = area.get_parent()
	if parent and parent.is_in_group("robot"):
		parent.in_destabilizing_field = false

func destroy_projectile(projectile: Node2D) -> void:
	# Calculate direction towards field center
	var direction_to_center = (global_position - projectile.global_position).normalized()
	var angle_to_center = direction_to_center.angle()
	
	# Create particles at the projectile's position
	var particles = CPUParticles2D.new()
	get_parent().add_child(particles)
	particles.global_position = projectile.global_position
	
	# Configure particle effect
	particles.amount = 12
	particles.lifetime = 0.3
	particles.one_shot = true
	particles.explosiveness = 0.8
	particles.direction = Vector2.RIGHT.rotated(angle_to_center)  # Point towards center
	particles.spread = 15.0  # Narrow spread
	particles.gravity = direction_to_center * 800  # Use gravity to pull particles toward center
	particles.initial_velocity_min = 150.0
	particles.initial_velocity_max = 200.0
	particles.scale_amount_min = 3.0
	particles.scale_amount_max = 5.0
	particles.scale_amount_curve = create_scale_curve()  # Particles get smaller as they approach center
	particles.color = Color(0, 0.6, 0.1, 0.8)  # Match field color
	
	# Start emitting and set up cleanup
	particles.emitting = true
	var timer = Timer.new()
	particles.add_child(timer)
	timer.wait_time = particles.lifetime + 0.1  # Add a small buffer
	timer.one_shot = true
	timer.timeout.connect(func(): particles.queue_free())
	timer.start()
	
	# Destroy the projectile immediately
	projectile.queue_free()

func create_scale_curve() -> Curve:
	# Create a curve that makes particles smaller as they travel
	var curve = Curve.new()
	curve.add_point(Vector2(0, 1))  # Start at full size
	curve.add_point(Vector2(1, 0.2))  # Shrink to 20% size
	return curve
