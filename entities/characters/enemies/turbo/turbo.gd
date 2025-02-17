extends "res://entities/characters/enemies/base_enemy.gd"

@export var swipe_damage: float = 2.0  
@export var swipe_range: float = 100.0  # Slightly shorter range
@export var swipe_arc: float = 140.0
@export var swipe_windup: float = 0.3  # Faster windup
@export var swipe_recovery: float = 0.15  # Faster recovery

var swipe_direction: Vector2 = Vector2.ZERO
var is_winding_up: bool = false
var wind_up_timer: float = 0.0
var recovery_timer: float = 0.0

@onready var animated_sprite = $AnimatedSprite2D
@onready var attack_panel = $AttackArea/AttackRange  # Fix reference to match scene
@onready var attack_area = $AttackArea
@onready var hit_detector = $HitDetector

var flip_threshold: float = 20.0
var last_flip_time: float = 0.0
var flip_cooldown: float = 0.2

func _ready() -> void:
	health = 60.0  # Less health than cyclops
	max_health = 60.0
	base_speed = 220.0  # Faster than cyclops
	attack_damage = swipe_damage
	attack_range = 100.0
	attack_cooldown = 1.0  # Faster cooldown
	current_health = health
	
	# Ensure sprite references are properly set
	sprite = $AnimatedSprite2D  # Set the base class sprite reference
	if sprite:
		original_color = sprite.modulate
	
	# Ensure attack panel exists and is visible when needed
	if attack_panel:
		attack_panel.visible = false
	
	super._ready()

func start_swipe_attack() -> void:
	is_winding_up = true
	wind_up_timer = swipe_windup
	can_attack = false
	
	if attack_panel:
		attack_panel.visible = true
		attack_panel.modulate = Color(1, 1, 1, 0)
		attack_panel.position = Vector2(-40, -240)
		
		var tween = create_tween()
		tween.tween_property(attack_panel, "modulate", Color(1, 1, 1, 1), 0.2)
	
	if is_instance_valid(player):
		var to_player = player.global_position - global_position
		animated_sprite.flip_h = to_player.x < 0  # Match chase state flipping
		animated_sprite.play("charging")  # Use charging animation
		
		# Windup animation
		animated_sprite.rotation = 0
		var tween = create_tween()
		tween.tween_property(animated_sprite, "rotation", 0.4 if !animated_sprite.flip_h else -0.4, 0.3)  # Swapped rotation
		tween.parallel().tween_property(animated_sprite, "scale", Vector2(0.35, 0.45), 0.3)
		
		attack_area.position.x = -60 if !animated_sprite.flip_h else 60  # Swapped positions
		attack_panel.scale = Vector2(0.4, 0.4) * (1 if !animated_sprite.flip_h else -1)  # Inverted scale
		swipe_direction = to_player.normalized()

func reset_attack_state() -> void:
	is_winding_up = false
	wind_up_timer = 0.0
	recovery_timer = 0.0
	
	if attack_panel:
		attack_panel.visible = false
		attack_panel.scale = Vector2(0.4, 0.4)
		attack_panel.modulate = Color(1, 1, 1, 1)
	
	if animated_sprite:
		animated_sprite.play("default")  # Return to default animation
		animated_sprite.rotation = 0
		animated_sprite.scale = Vector2(0.4, 0.4)
	
	attack_area.rotation = 0
	
	if current_state == EnemyState.ATTACK:
		var timer = get_tree().create_timer(attack_cooldown)
		timer.timeout.connect(func(): can_attack = true)

func handle_chase_state(delta: float) -> void:
	if !player or !is_instance_valid(player):
		current_state = EnemyState.IDLE
		return
		
	# Update target position periodically
	target_position_timer -= delta
	if target_position_timer <= 0:
		current_target_position = calculate_target_position()
		target_position_timer = position_update_frequency
	
	var distance = global_position.distance_to(player.global_position)
	var to_player = player.global_position - global_position
	
	if distance <= attack_range * 0.8 and can_attack:
		attack_target = player
		current_state = EnemyState.ATTACK
		start_swipe_attack()
	else:
		move_towards_position(current_target_position, delta)
		
		 # Fix flipping direction - flip when player is to the left of the enemy
		if animated_sprite and is_instance_valid(player):
			animated_sprite.flip_h = to_player.x < 0
			attack_area.position.x = -60 if animated_sprite.flip_h else 60
			attack_panel.position.x = -100 if animated_sprite.flip_h else -20
			attack_panel.scale.x = -1 if animated_sprite.flip_h else 1  # Fixed scale direction

func handle_attack_state(delta: float) -> void:
	if !is_instance_valid(player):
		reset_attack_state()
		current_state = EnemyState.IDLE
		return

	if is_winding_up:
		wind_up_timer -= delta
		if wind_up_timer <= 0:
			perform_attack()
	elif recovery_timer > 0:
		recovery_timer -= delta
		if recovery_timer <= 0:
			reset_attack_state()
			current_state = EnemyState.CHASE

func perform_attack() -> void:
	is_winding_up = false
	recovery_timer = swipe_recovery
	
	if animated_sprite:
		var tween = create_tween()
		tween.tween_property(animated_sprite, "rotation", -0.3 if !animated_sprite.flip_h else 0.3, 0.1)
		tween.tween_property(animated_sprite, "rotation", 0.0, 0.1)
		tween.parallel().tween_property(animated_sprite, "scale", Vector2(0.4, 0.4), 0.2)
	
	if attack_panel:
		var tween = create_tween()
		tween.set_ease(Tween.EASE_IN)
		tween.set_trans(Tween.TRANS_BACK)
		
		# Arc movement
		var start_pos = Vector2(-40 if !animated_sprite.flip_h else 40, -260)
		var mid_pos = Vector2(-140 if !animated_sprite.flip_h else 140, -80)
		var end_pos = Vector2(-100 if !animated_sprite.flip_h else 100, 20)
		
		tween.tween_property(attack_panel, "position", start_pos, 0.05)
		tween.tween_property(attack_panel, "position", mid_pos, 0.08)
		tween.tween_property(attack_panel, "position", end_pos, 0.08)
		
		# Visual effects
		tween.parallel().tween_property(attack_panel, "scale", Vector2(0.2, 1.2) * (1 if !animated_sprite.flip_h else -1), 0.08)
		tween.parallel().tween_property(attack_panel, "scale", Vector2(1.0, 0.4) * (1 if !animated_sprite.flip_h else -1), 0.08)
		tween.parallel().tween_property(attack_panel, "rotation", PI/3 if !animated_sprite.flip_h else -PI/3, 0.16)
		
		# Impact flash
		tween.parallel().tween_property(attack_panel, "modulate", Color(6.0, 3.0, 3.0, 1), 0.08)
		tween.parallel().tween_property(attack_panel, "modulate", Color(1, 1, 1, 0), 0.12)
	
	# Apply damage
	if is_instance_valid(player):
		var to_player = player.global_position - global_position
		if abs(to_player.x) <= attack_range * 1.2 and abs(to_player.y) <= attack_range * 0.8:
			if player.has_method("take_damage"):
				player.take_damage(attack_damage)
			if player.has_method("apply_knockback"):
				var knockback_dir = Vector2(-1 if !animated_sprite.flip_h else 1, 0.5).normalized()
				player.apply_knockback(knockback_dir * 1200)

func take_damage(amount: float) -> void:
	# Cancel attack first and ensure animations reset
	if is_winding_up or current_state == EnemyState.ATTACK:
		reset_attack_state()
		can_attack = true
	
	if animated_sprite:
		animated_sprite.play("default")  # Return to default animation
		animated_sprite.rotation = 0.0
		animated_sprite.scale = Vector2(0.4, 0.4)
	
	super.take_damage(amount)
	
	stun_timer = hit_stun_duration

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
		# Normal state machine processing
		match current_state:
			EnemyState.IDLE:
				velocity = Vector2.ZERO
				if player and is_instance_valid(player):
					current_state = EnemyState.CHASE
			
			EnemyState.CHASE:
				handle_chase_state(delta)
			
			EnemyState.ATTACK:
				handle_attack_state(delta)
			
			EnemyState.STUNNED:
				handle_stunned_state(delta)
				if !is_stunned:  # If stun ended, return to chase
					current_state = EnemyState.CHASE
		
		# Remove the movement-based flipping since we handle it in chase state
	
	move_and_slide()

func handle_stunned_state(delta: float) -> void:
	if stun_timer <= 0:
		current_state = EnemyState.CHASE
		if animated_sprite:
			animated_sprite.modulate = original_color
			animated_sprite.rotation = 0.0
			animated_sprite.scale = Vector2(0.4, 0.4)
	else:
		stun_timer -= delta
		velocity = knockback_velocity
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, delta * 1500)

func take_knockback(knockback: Vector2) -> void:
	# Reduce knockback force significantly for melee enemies since they're bigger/tougher
	knockback_velocity = knockback * 0.3 
	
	# Apply a stun effect
	current_state = EnemyState.STUNNED
	is_stunned = true
	stun_timer = 1.0  # 1 second stun duration
	if animated_sprite:
		animated_sprite.modulate = Color(1.5, 1.5, 1.5)  # Flash white to indicate stun

func setup_attack_area() -> void:
	if attack_area:
		attack_area.collision_mask = 4
		attack_area.call_deferred("set_monitorable", true)
		attack_area.call_deferred("set_monitoring", true)
		
		if not attack_area.area_entered.is_connected(_on_attack_area_area_entered):
			attack_area.area_entered.connect(_on_attack_area_area_entered)

func _on_interact() -> void:
	var player_node = get_tree().get_first_node_in_group("player")
	if !is_instance_valid(player_node):
		return
		
	# Apply damage
	take_damage(player_node.weak_attack)
	
	# Apply knockback effect
	var knockback_direction = (global_position - player_node.global_position).normalized()
	take_knockback(knockback_direction * 500)
	
	# Visual feedback
	if animated_sprite:  # Use animated_sprite instead of sprite_2d
		animated_sprite.modulate = Color(2, 2, 2)  # Flash bright white
		var tween = create_tween()
		tween.tween_property(animated_sprite, "modulate", Color.WHITE, 0.2)
	
	# Update health display
	hit_detector.health = current_health
