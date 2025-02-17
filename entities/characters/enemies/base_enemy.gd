extends CharacterBody2D

@onready var current_health = health

@export_group("Movement")
@export var base_speed: float = 250.0  # Slower base speed for beat 'em up style
@export var acceleration: float = 800.0
@export var deceleration: float = 1200.0
@export var knockback_recovery: float = 900.0
@export var dash_speed: float = 1200.0
@export var dash_duration: float = 0.2
@export var dodge_speed: float = 800.0
@export var dodge_duration: float = 0.2
@export var dodge_cooldown: float = 0.5
@export var dodge_detection_range: float = 300.0
@export var repositioning_distance: float = 150.0
@export var blocked_time_limit: float = 2.0
@export var personal_space: float = 120.0  # Minimum distance from other enemies
@export var personal_space_weight: float = 0.5  # How strongly to avoid other enemies
@export var position_update_frequency: float = 0.5  # How often to update target position

@export_group("Combat")
@export var health: float = 100.0
@export var attack_damage: float = 15.0
@export var attack_range: float = 80.0  # Closer range for melee combat
@export var attack_cooldown: float = 1.2
@export var stun_duration: float = 0.5
@export var hit_stun_duration: float = 0.3
@export var combo_window: float = 0.8  # Time window for combo hits
@export var detection_radius: float = 150.0

# Add these missing properties
@export var max_health: float = 100.0
@export var wall_impact_speed_threshold: float = 800.0
@export var wall_impact_damage_amount: float = 15.0

# Beat 'em up specific states
enum EnemyState {
	IDLE,
	CHASE,
	ATTACK,
	STUNNED,
	COMBO,
	BLOCK
}
var current_state: int = EnemyState.IDLE

# Core
var initialized: bool = false
var player: Node2D = null
var sprite: Node2D = null
var original_color: Color = Color.WHITE
var trail: CPUParticles2D = null

# Obstacle Avoidance
var blocked_timer: float = 0.0
var obstacle_check_timer: float = 0.0
var feeler_angles: Array = []
var feelers: Array[RayCast2D] = []
var cached_obstacle_direction: Vector2 = Vector2.ZERO
var last_valid_position: Vector2 = Vector2.ZERO

# Movement
var is_chasing: bool = false
var target_position_timer: float = 0.0
var current_target_position: Vector2 = Vector2.ZERO
var position_noise_offset: float = 0.0

# Combat
var dodge_chance: float = 0.3
var is_stunned: bool = false
var stun_timer: float = 0.0
var knockback_velocity: Vector2 = Vector2.ZERO
var knockback_decay: float = 1500.0
var impact_scale: float = 1.0
var is_dashing: bool = false
var dash_timer: float = 0.0
var can_damage: bool = true
var cooldown_timer: float = 0.0
var is_attacking: bool = false
var attack_target: Node2D = null
var can_attack: bool = true
var has_hit_target: bool = false
var last_hit_position: Vector2
var last_hit_time: int = 0

# Dodge State
var can_dodge: bool = true
var dodge_direction: Vector2 = Vector2.ZERO
var dodge_timer: float = 0.0
var is_dodging: bool = false
var dodge_success_count: int = 0

# Positioning State
var seeking_position: bool = false
var target_position: Vector2 = Vector2.ZERO

# Combat variables
var combo_timer: float = 0.0
var current_combo: int = 0
var max_combo: int = 3
var is_blocking: bool = false
var block_chance: float = 0.3
var vulnerability_window: float = 0.0
var hit_count: int = 0
var max_super_armor: int = 3  # Hits before stun
var hits_taken: int = 0
var monitoring_wall_impact: bool = true

### Core Functions ###
func _ready() -> void:
	# Initialize core components
	sprite = $Sprite2D
	if sprite:
		original_color = sprite.modulate
	
	# Set up interaction component and sync health
	var hit_detector = get_node_or_null("HitDetector")
	if hit_detector:
		hit_detector.set_interaction_callable(Callable(self, "_on_interact"))
		current_health = health  # Initialize current_health
		hit_detector.health = current_health  # Sync with hit_detector
	
	# Trail effect is optional
	trail = get_node_or_null("CPUParticles2D")
	
	setup_obstacle_avoidance()
	initialize_references()
	initialized = true
	position_noise_offset = randf() * 100  # Random offset for movement variation

func initialize_references() -> void:
	if !initialized:
		# Look for player in the scene tree without Main node
		player = get_tree().get_first_node_in_group("player")
	
	reset_state()

func reset_state() -> void:
	# Reset all state variables to default values
	is_dashing = false
	is_stunned = false
	can_damage = true
	dash_timer = 0.0
	cooldown_timer = 0.0
	stun_timer = 0.0
	can_dodge = true
	dodge_direction = Vector2.ZERO
	dodge_timer = 0.0
	is_dodging = false
	blocked_timer = 0.0
	seeking_position = false
	target_position = Vector2.ZERO
	velocity = Vector2.ZERO
	if sprite:
		sprite.modulate = original_color

func setup_obstacle_avoidance() -> void:
	# Create raycasts in a circle for obstacle detection
	feeler_angles = [-60, -30, 0, 30, 60]  # Angles for obstacle detection
	
	for angle in feeler_angles:
		var ray = RayCast2D.new()
		ray.target_position = Vector2.RIGHT.rotated(deg_to_rad(angle)) * 100
		ray.collision_mask = 1  # Collide with world
		ray.enabled = true
		add_child(ray)
		feelers.append(ray)
	
	last_valid_position = global_position

func setup_attack_area() -> void:
	var attack_area = $AttackArea
	if attack_area:
		attack_area.collision_mask = 4  # Set appropriate collision mask
		attack_area.call_deferred("set_monitorable", true)
		attack_area.call_deferred("set_monitoring", true)
		
		if not attack_area.area_entered.is_connected(_on_attack_area_area_entered):
			attack_area.area_entered.connect(_on_attack_area_area_entered)

### State Management ###
func update_timers(delta: float) -> void:
	cooldown_timer = max(0, cooldown_timer - delta)
	dodge_timer = max(0, dodge_timer - delta)
	obstacle_check_timer = max(0.0, obstacle_check_timer - delta)

func handle_stunned_state(delta: float) -> void:
	if stun_timer <= 0:
		reset_state()
		current_combo = 0  # Reset combo on stun recovery
		current_state = EnemyState.CHASE  # Add this line to resume chasing
		# Ensure sprite is reset
		if sprite:
			sprite.modulate = original_color
			sprite.rotation = 0.0
			sprite.scale = Vector2(0.4, 0.4)
	else:
		stun_timer -= delta
		velocity = velocity.move_toward(Vector2.ZERO, deceleration * delta)
		if sprite:
			sprite.modulate = Color(1.0, 0.3, 0.3, 1.0)

func handle_dash(delta: float) -> void:
	if !trail.emitting:
		trail.emitting = true
	
	dash_timer -= delta
	
	if dash_timer <= 0:
		# Successful dodge if we didn't get hit during the dash
		if is_dodging:
			dodge_success_count += 1
		end_dash()
		return
	elif get_slide_collision_count() > 0:
		end_dash()
		return
		
	# Maintain the dash velocity
	velocity = dodge_direction * (dodge_speed * (1.0 + (dodge_success_count * 0.1)))

func end_dash() -> void:
	is_dashing = false
	is_dodging = false
	dodge_direction = Vector2.ZERO
	velocity = Vector2.ZERO
	trail.emitting = false

### Movement and Combat ###
# Virtual function for child classes to override
func handle_movement(_delta: float) -> Vector2:
	return Vector2.ZERO  # Base implementation returns no movement

func get_target() -> Node2D:
	if !is_instance_valid(player):
		initialize_references()  # Try to get fresh references
		if !player:
			return null
			
	return player  # Always target player for consistency

func _on_hit(is_overheated: bool = false) -> void:
	if !can_damage:
		return
	
	Audio.play_sfx("enemy_hurt")
	
	# Apply proper damage based on overheated state
	var damage = 20.0 if is_overheated else 10.0
	current_health -= damage  # Use current_health instead of health
	health = current_health  # Keep health in sync
	
	# Update hit_detector health
	var hit_detector = get_node_or_null("HitDetector")
	if hit_detector:
		hit_detector.health = current_health
	
	flash_hit()
	apply_hit_stun()
	
	# Reset adaptation on hit
	last_hit_time = 0
	dodge_success_count = max(0, dodge_success_count - 1)  # Lose dodge experience
	
	if current_health <= 0:
		die()

func flash_hit() -> void:
	if !sprite:
		return
		
	# Flash red
	sprite.modulate = Color(1, 0, 0, 1)
	
	# Reset color after a short delay
	var timer = get_tree().create_timer(0.1)
	timer.timeout.connect(func(): 
		if sprite and is_instance_valid(sprite):
			sprite.modulate = original_color
	)

func apply_hit_stun() -> void:
	is_stunned = true
	stun_timer = hit_stun_duration
	current_state = EnemyState.STUNNED  # Add this to ensure state change
	velocity = Vector2.ZERO
	# Reset all movement states
	is_dashing = false
	is_dodging = false
	cooldown_timer = 0.0
	dash_timer = 0.0
	dodge_timer = 0.0
	
	# Reset sprite transformations
	if sprite:
		sprite.rotation = 0.0
		sprite.scale = Vector2(0.4, 0.4)

func take_knockback(knockback_force: Vector2) -> void:
	knockback_velocity = knockback_force * 1.2 
	velocity = knockback_velocity
	impact_scale = 0.7
	apply_hit_stun()

func take_damage(amount: float) -> void:
	# Reset attack state and sprite transformations first
	if current_state == EnemyState.ATTACK:
		# Reset sprite transformations
		if sprite:
			sprite.rotation = 0.0
			sprite.scale = Vector2(0.4, 0.4)
		current_state = EnemyState.STUNNED
	
	if is_blocking:
		amount *= 0.2  # Reduced damage when blocking
		
	hit_count += 1
	if hit_count >= max_super_armor:
		is_stunned = true
		hit_count = 0
		
	Audio.play_sfx("enemy_hurt")
	
	current_health -= amount  # Use current_health instead of health
	health = current_health  # Keep health in sync
	
	# Update hit_detector health
	var hit_detector = get_node_or_null("HitDetector")
	if hit_detector:
		hit_detector.health = current_health
	
	flash_hit()
	apply_hit_stun() 
	
	# Show floating numbers if they exist
	var floating_numbers = get_node_or_null("FloatingNumbers")
	if is_instance_valid(floating_numbers) and not floating_numbers.is_queued_for_deletion():
		floating_numbers.popup()
	
	# Reset adaptation like in _on_hit
	last_hit_time = 0  # Changed from 0.0 to 0 to avoid narrowing conversion
	dodge_success_count = max(0, dodge_success_count - 1)
	
	if current_health <= 0:
		die()

### Death and Effects ###
func die() -> void:
	Audio.play_sfx("enemy_death")
	
	# Clean fade out
	if sprite:
		var tween = create_tween()
		tween.set_ease(Tween.EASE_IN)
		tween.set_trans(Tween.TRANS_SINE)
		tween.tween_property(sprite, "modulate", Color(1, 0.3, 0.3, 1), 0.1)
		tween.tween_property(sprite, "modulate", Color(1, 1, 1, 0), 0.3)
	
	# Disable collisions immediately
	for child in get_children():
		if child is CollisionShape2D or child is CollisionPolygon2D:
			child.call_deferred("set_disabled", true)
		elif child is Area2D:
			child.call_deferred("set_monitoring", false)
			child.call_deferred("set_monitorable", false)
	
	# Create red death particles
	var death_particles = CPUParticles2D.new()
	death_particles.emitting = false
	death_particles.amount = 16
	death_particles.lifetime = 0.4
	death_particles.explosiveness = 0.8
	death_particles.spread = 180.0
	death_particles.gravity = Vector2.ZERO
	death_particles.initial_velocity_min = 100.0
	death_particles.initial_velocity_max = 150.0
	death_particles.scale_amount_min = 4.0
	death_particles.scale_amount_max = 6.0
	death_particles.color = Color(1.0, 0.3, 0.3, 0.8)  # Red particles
	add_child(death_particles)
	death_particles.emitting = true
	
	# Remove enemy after effects finish
	await get_tree().create_timer(0.4).timeout
	get_node("l")
	queue_free()

### Dodging and Repositioning ###
func check_obstacles(desired_velocity: Vector2) -> Vector2:
	if obstacle_check_timer <= 0:
		cached_obstacle_direction = Vector2.ZERO
		var total_weight = 0.0
		
		for i in range(feelers.size()):
			var feeler = feelers[i]
			if feeler.is_colliding():
				var collision_point = feeler.get_collision_point()
				var to_obstacle = collision_point - global_position
				var distance = to_obstacle.length()
				var weight = 1.0 - (distance / 100.0) 
				cached_obstacle_direction += -to_obstacle.normalized() * weight
				total_weight += weight
		
		if total_weight > 0:
			cached_obstacle_direction /= total_weight
			blocked_timer += 0.1
		else:
			blocked_timer = max(0, blocked_timer - 0.1)
		
		#obstacle_check_timer = obstacle_check_interval
	
	if cached_obstacle_direction != Vector2.ZERO:
		# Blend between desired velocity and obstacle avoidance
		var blend_factor = min(blocked_timer, 1.0)
		return desired_velocity.lerp(cached_obstacle_direction * desired_velocity.length(), blend_factor)
	
	return desired_velocity

func move_and_avoid(desired_velocity: Vector2, delta: float) -> void:
	var final_velocity = check_obstacles(desired_velocity)
	velocity = velocity.move_toward(final_velocity, base_speed * delta)
	move_and_slide()
	
	# Update position tracking
	if !get_slide_collision_count():
		last_valid_position = global_position

func _physics_process(delta: float) -> void:
	if !initialized or !player:
		initialize_references()
		return

	if is_stunned:
		handle_stunned_state(delta)
		return

	# Handle knockback and states
	if knockback_velocity.length() > 0:
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
		# Normal state machine processing
		match current_state:
			EnemyState.IDLE:
				handle_idle_state(delta)
			EnemyState.CHASE:
				handle_chase_state(delta)
			EnemyState.ATTACK:
				handle_attack_state(delta)
			EnemyState.STUNNED:
				handle_stunned_state(delta)
		
		# Remove sprite flipping from base class entirely
	
	move_and_slide()

func handle_idle_state(_delta: float) -> void:
	velocity = Vector2.ZERO
	if player and is_instance_valid(player):
		current_state = EnemyState.CHASE

func handle_chase_state(_delta: float) -> void:
	# Virtual function to be implemented by child classes
	pass

func handle_attack_state(_delta: float) -> void:
	# Virtual function to be implemented by child classes
	pass

func _on_timeout_can_attack() -> void:
	can_attack = true

func _on_timeout_reset_dodge() -> void:
	can_dodge = true

func _on_timeout_reset_stun() -> void:
	is_stunned = false
	if sprite:
		sprite.modulate = original_color

func _on_timeout_reset_attack() -> void:
	is_attacking = false
	can_attack = false
	attack_target = null
	if sprite:
		sprite.modulate = original_color
	var timer = get_tree().create_timer(attack_cooldown)
	timer.timeout.connect(_on_timeout_can_attack)

func is_valid_target_area(area: Area2D) -> bool:
	if !area or !is_instance_valid(area):
		return false
	
	# Only check for player hitbox for combat
	var parent = area.get_parent()
	if !parent:
		return false
		
	# Check if it's specifically a hitbox from the player
	return area.name == "HitBox" and parent.is_in_group("player")

func _on_attack_area_area_entered(area: Area2D) -> void:
	if !is_valid_target_area(area):
		return
	# Child classes will implement specific behavior

# Override in child classes
func perform_combo_attack() -> void:
	pass

func attempt_block() -> void:
	if randf() < block_chance:
		is_blocking = true
		# Add block animation/effect here

func _on_interact() -> void:
	if !is_instance_valid(player):
		return
		
	var damage = player.weak_attack
	take_damage(damage)
	
	# Update hitdetector health display with instance validation
	var hit_detector = get_node_or_null("HitDetector")
	if is_instance_valid(hit_detector):
		hit_detector.health = current_health
	
	# No need to call floating numbers popup here since it's handled in take_damage()

func get_avoidance_vector() -> Vector2:
	var avoidance = Vector2.ZERO
	var nearby_enemies = get_tree().get_nodes_in_group("enemies")
	
	for enemy in nearby_enemies:
		if enemy == self or !is_instance_valid(enemy):
			continue
			
		var to_enemy = global_position - enemy.global_position
		var distance = to_enemy.length()
		
		if distance < personal_space:
			var repulsion = to_enemy.normalized() * (1.0 - distance / personal_space)
			avoidance += repulsion
	
	return avoidance

func calculate_target_position() -> Vector2:
	if !is_instance_valid(player):
		return global_position
		
	var base_target = player.global_position
	var ideal_distance = attack_range * 0.7
	
	# Add some noise to movement
	var time = Time.get_ticks_msec() / 1000.0
	var noise_x = sin(time + position_noise_offset) * 30.0
	var noise_y = cos(time * 1.3 + position_noise_offset) * 20.0
	
	# Calculate position with personal space and noise
	var avoidance = get_avoidance_vector() * personal_space_weight
	var side_offset = Vector2(ideal_distance * (1.0 if randf() > 0.5 else -1.0), 0)
	var target = base_target + side_offset + Vector2(noise_x, noise_y)
	
	# Apply avoidance
	target += avoidance * base_speed
	
	return target

func move_towards_position(target_pos: Vector2, delta: float) -> void:
	var to_target = target_pos - global_position
	var distance = to_target.length()
	
	if distance > 5.0:  # Only move if we're not already at the target
		var desired_velocity = to_target.normalized() * base_speed
		
		# Apply avoidance
		var avoidance = get_avoidance_vector() * personal_space_weight * base_speed
		desired_velocity += avoidance
		
		# Smooth velocity change
		velocity = velocity.move_toward(desired_velocity, acceleration * delta)
