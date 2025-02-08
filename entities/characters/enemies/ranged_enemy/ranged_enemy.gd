extends "res://entities/enemies/base_enemy.gd"

@export_group("Ranged Combat")
@export var shoot_range: float = 450.0
@export var preferred_distance: float = 300.0
@export var burst_size: int = 2
@export var burst_delay: float = 0.2
@export var reload_time: float = 2.0
@export var shoot_rate: float = 0.5
@export var projectile_speed: float = 800.0
@export var accuracy: float = 0.8
@export var spread_angle: float = 0.3
@export var target_switch_cooldown: float = 2.0

@export_group("Movement")
@export var strafe_speed: float = 150.0
@export var backpedal_speed: float = 200.0
@export var chase_speed_multiplier: float = 1.2
@export var max_time_at_position: float = 3.0

# Shooting State
var shoot_timer: float = 0.0
var burst_count: int = 0
var burst_timer: float = 0.0
var is_bursting: bool = false
var last_shoot_position: Vector2 = Vector2.ZERO
var covering_fire: bool = false

# Position tracking
var time_at_position: float = 0.0
var current_cover_point: Vector2 = Vector2.ZERO
var strafe_direction_multiplier: float = 1.0

# Target Management
var target_switch_timer: float = 0.0

@onready var projectile_scene: PackedScene = preload("res://entities/projectiles/enemy_bullets/enemy_bullet.tscn")

func _ready() -> void:
	super._ready() 
	
	max_health = 40 
	health = max_health
	base_speed = 200.0
	
	# Initialize strafe direction
	strafe_direction_multiplier = 1.0 if randf() > 0.5 else -1.0

func update_timers(delta: float) -> void:
	super.update_timers(delta)
	shoot_timer = max(0, shoot_timer - delta)
	target_switch_timer = max(0, target_switch_timer - delta)
	burst_timer = max(0, burst_timer - delta)
	time_at_position += delta
	
	if is_bursting and burst_timer <= 0:
		continue_burst()

func handle_chase_state(delta: float) -> void:
	# Don't handle chase state if being knocked back
	if knockback_velocity.length() > 0:
		return
		
	var target = get_target()
	if !target:
		current_state = EnemyState.IDLE
		return

	var distance = position.distance_to(target.position)
	is_chasing = distance > shoot_range

	if is_chasing:
		var direction = (target.position - position).normalized()
		velocity = direction * base_speed * chase_speed_multiplier
	else:
		current_state = EnemyState.ATTACK

func handle_attack_state(delta: float) -> void:
	# Don't handle attack state if being knocked back
	if knockback_velocity.length() > 0:
		return
		
	var target = get_target()
	if !target or !is_instance_valid(target):
		return
		
	var distance = position.distance_to(target.position)
	
	# Only shoot if we're not already in a burst and our shoot timer is ready
	if !is_bursting and shoot_timer <= 0 and distance <= shoot_range:
		start_burst()
	
	# Move to preferred range while attacking
	var direction = Vector2.ZERO
	
	if distance > preferred_distance * 1.1:
		direction = (target.position - position).normalized()
	elif distance < preferred_distance * 0.9:
		direction = (position - target.position).normalized()
	
	# Add strafing movement
	var strafe = Vector2(-direction.y, direction.x) * strafe_direction_multiplier
	direction = (direction + strafe).normalized()
	
	velocity = direction * base_speed
	move_and_avoid(velocity, delta)

func start_burst() -> void:
	if is_bursting:
		return
		
	var target = get_target()
	if !target or !is_instance_valid(target):
		return
		
	is_bursting = true
	burst_count = 0
	burst_timer = 0
	last_shoot_position = target.position
	continue_burst()

func continue_burst() -> void:
	if burst_count >= burst_size:
		is_bursting = false
		shoot_timer = reload_time 
		return
		
	var target = get_target()
	if target and is_instance_valid(target):
		shoot_at_target(target)
		burst_count += 1
		burst_timer = burst_delay

func shoot_at_target(target: Node2D) -> void:
	if !projectile_scene:
		return
		
	var projectile = projectile_scene.instantiate()
	get_tree().root.add_child(projectile)
	
	# Calculate spread
	var base_direction = (target.position - position).normalized()
	var spread = randf_range(-spread_angle, spread_angle)
	var final_direction = base_direction.rotated(spread)
	
	# Offset the spawn position slightly in front of the enemy
	var spawn_offset = final_direction * 20.0 
	projectile.global_position = global_position + spawn_offset
	projectile.set_direction(final_direction)
	projectile.velocity = final_direction * projectile_speed
	
	if sprite:
		sprite.modulate = Color(1.2, 1.0, 1.0)  # Flash when shooting
		create_tween().tween_property(sprite, "modulate", original_color, 0.1)

func calculate_current_aggression() -> float:
	var health_ratio = health / max_health
	var aggression_modifier = 1.0
	
	match personality_type:
		"aggressive":
			# Get more aggressive at low health
			aggression_modifier = 1.0 + (1.0 - health_ratio) * 1.5
			covering_fire = health_ratio < 0.3  # Spray bullets when low health
		"cautious":
			# Become more cautious at low health
			aggression_modifier = 1.0 - (1.0 - health_ratio) * 0.7
			if health_ratio < 0.4:
				preferred_distance *= 1.2  # Try to maintain even more distance when hurt
		"neutral":
			# Slight random variation based on health
			aggression_modifier = 1.0 + (1.0 - health_ratio) * (randf() * 0.4 - 0.2)
	
	return base_aggression * aggression_modifier

func get_target() -> Node2D:
	if target_switch_timer <= 0:
		choose_best_target()
	return attack_target if is_instance_valid(attack_target) else super.get_target()

func choose_best_target() -> void:
	if !is_instance_valid(human) or !is_instance_valid(robot):
		attack_target = human if is_instance_valid(human) else robot
		return

	var human_score = calculate_target_score(human)
	var robot_score = calculate_target_score(robot)
	
	# Personality affects target selection
	match personality_type:
		"aggressive":
			# Prefer closer targets
			human_score *= 1.0 + (1.0 - position.distance_to(human.position) / shoot_range)
			robot_score *= 1.0 + (1.0 - position.distance_to(robot.position) / shoot_range)
		"cautious":
			# Prefer targets that aren't looking at us
			if is_instance_valid(human) and human.global_position.direction_to(global_position).dot(human.look_direction) > 0:
				human_score *= 0.7
			if is_instance_valid(robot) and robot.global_position.direction_to(global_position).dot(robot.look_direction) > 0:
				robot_score *= 0.7
	
	# Only switch targets if the new target is significantly more attractive
	if is_instance_valid(attack_target):
		var current_score = calculate_target_score(attack_target)
		if current_score * 1.3 < max(human_score, robot_score): 
			attack_target = human if human_score > robot_score else robot
			target_switch_timer = target_switch_cooldown
	else:
		attack_target = human if human_score > robot_score else robot
		target_switch_timer = target_switch_cooldown

func calculate_target_score(target: Node2D) -> float:
	if !is_instance_valid(target):
		return 0.0
		
	var distance = position.distance_to(target.position)
	var score = 1000.0  # Base score
	
	# Distance factor (closer targets are more attractive, but not too close)
	if distance < preferred_distance:
		score *= 0.5  # Penalty for being too close
	elif distance > shoot_range:
		score *= 0.7  # Penalty for being too far
	else:
		score *= 1.0  # Ideal range
		
	# Line of sight factor
	if !has_clear_shot(target):
		score *= 0.6  # Significant penalty for no clear shot
		
	# Health factor (prefer targeting lower health enemies)
	if target.has_method("get_health_percentage"):
		var health = target.get_health_percentage()
		score *= (1.0 + (1.0 - health))  # Lower health increases score
		
	# Add some randomness to prevent predictable behavior
	score *= randf_range(0.9, 1.1)
	
	return score

func find_new_cover_point(target: Node2D) -> void:
	if !is_instance_valid(target):
		return
	
	# Find a point at preferred distance that has cover nearby
	var angle = randf() * PI * 2
	var new_point = target.position + Vector2(cos(angle), sin(angle)) * preferred_distance
	
	# TODO: Implement actual cover detection using raycasts
	# For now, just use this as a repositioning point
	current_cover_point = new_point

func take_damage(amount: float) -> void:
	super.take_damage(amount)
	hits_taken += 1
	maybe_change_personality()
	
	# Interrupt burst when hit
	if is_bursting:
		is_bursting = false
		shoot_timer = reload_time
	
	# Switch strafe direction when hit
	strafe_direction_multiplier *= -1.0

func _on_hit(is_overheated: bool = false) -> void:
	super._on_hit(is_overheated)
	
	# Switch strafe direction when hit
	strafe_direction_multiplier *= -1.0
	
	# Interrupt burst when hit
	if is_bursting:
		is_bursting = false
		shoot_timer = reload_time

func initialize_personality() -> void:
	var roll = randf()
	if roll < 0.05: 
		set_personality("aggressive")
	elif roll < 0.8: 
		set_personality("cautious")
	else: 
		set_personality("neutral")

func maybe_change_personality() -> void:
	# Calculate chance based on hits taken
	var change_chance = min(PERSONALITY_CHANGE_BASE_CHANCE + (hits_taken * 0.05), MAX_PERSONALITY_CHANGE_CHANCE)
	
	if randf() < change_chance:
		var roll = randf()
		if roll < 0.1: 
			set_personality("aggressive")
		elif roll < 0.9: 
			set_personality("cautious")
		else: 
			set_personality("neutral")

func take_knockback(knockback_force: Vector2) -> void:
	knockback_velocity = knockback_force * 1.2 
	velocity = knockback_velocity
	impact_scale = 0.7
	apply_hit_stun()

func _physics_process(delta: float) -> void:
	# Handle knockback first if it exists
	if knockback_velocity.length() > 0:
		velocity = knockback_velocity * 1.2 
		# Check for wall impacts during knockback
		if monitoring_wall_impact and get_slide_collision_count() > 0:
			for i in range(get_slide_collision_count()):
				var collision = get_slide_collision(i)
				if collision and velocity.length() >= wall_impact_speed_threshold:
					take_damage(wall_impact_damage_amount)
					monitoring_wall_impact = false
					break
		# Gradually reduce knockback
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, knockback_decay * delta)
		# Scale effect during impact
		var impact_amount = min(knockback_velocity.length() / 1200.0, 1.0)
		scale = Vector2.ONE * (1.0 + impact_amount * 0.2)
	else:
		scale = Vector2.ONE  # Reset scale when not in knockback
		# Update timers
		update_timers(delta)
		
		# Normal state machine processing
		match current_state:
			EnemyState.IDLE:
				velocity = Vector2.ZERO
				if human and is_instance_valid(human):
					current_state = EnemyState.CHASE
			
			EnemyState.CHASE:
				handle_chase_state(delta)
			
			EnemyState.ATTACK:
				handle_attack_state(delta)
			
			EnemyState.STUNNED:
				handle_stunned_state(delta)
				if !is_stunned:  # If stun ended, return to chase
					current_state = EnemyState.CHASE
		
		if sprite and abs(velocity.x) > 0:
			sprite.flip_h = velocity.x < 0
	
	move_and_slide()
