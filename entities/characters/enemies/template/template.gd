extends "res://entities/characters/enemies/base_enemy.gd"

@export var windup_time: float = 0.4
@export var attack_duration: float = 0.2
@export var recovery_time: float = 0.2

@onready var attack_panel = $AttackArea/AttackRange
@onready var attack_area = $AttackArea
@onready var hit_detector = $HitDetector

var is_winding_up: bool = false
var wind_up_timer: float = 0.0
var recovery_timer: float = 0.0
var attack_direction: Vector2 = Vector2.ZERO

var flip_threshold: float = 20.0
var last_flip_time: float = 0.0
var flip_cooldown: float = 0.2

var combo_damage_multiplier: float = 1.2
var attack_arc_degrees: float = 90.0

func _ready() -> void:
	health = 120.0
	max_health = 120.0
	base_speed = 200.0
	attack_damage = 15.0
	attack_range = 120.0
	attack_cooldown = 1.2
	current_health = health
	super._ready()

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
		start_attack()
	else:
		move_towards_position(current_target_position, delta)
		
		# Handle sprite flipping with noise reduction
		if sprite and abs(velocity.x) > 20:  # Increased threshold to reduce jitter
			var new_facing_right = to_player.x > 0
			var time = Time.get_ticks_msec() / 1000.0
			
			if time - last_flip_time >= flip_cooldown or abs(to_player.x) > flip_threshold:
				if sprite.flip_h != new_facing_right:
					sprite.flip_h = new_facing_right
					attack_area.position.x = -60 if !sprite.flip_h else 60
					attack_panel.position.x = -100 if !sprite.flip_h else -20
					attack_panel.scale.x = 1 if !sprite.flip_h else -1
					last_flip_time = time

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

func start_attack() -> void:
	is_winding_up = true
	wind_up_timer = windup_time
	can_attack = false
	
	if attack_panel:
		attack_panel.visible = true
		attack_panel.modulate = Color(1, 1, 1, 0)
		attack_panel.scale = Vector2(0.4, 0.4) * (1 if !sprite.flip_h else -1)
		
		var tween = create_tween()
		tween.tween_property(attack_panel, "modulate", Color(1, 1, 1, 1), 0.2)
	
	if is_instance_valid(player):
		var to_player = player.global_position - global_position
		sprite.flip_h = to_player.x > 0
		
		sprite.rotation = 0
		var tween = create_tween()
		tween.tween_property(sprite, "rotation", 0.4 if !sprite.flip_h else -0.4, 0.3)
		tween.parallel().tween_property(sprite, "scale", Vector2(0.35, 0.45), 0.3)
		
		attack_area.position.x = -60 if !sprite.flip_h else 60
		attack_direction = to_player.normalized()

func perform_attack() -> void:
	is_winding_up = false
	recovery_timer = recovery_time
	
	if sprite:
		var tween = create_tween()
		tween.tween_property(sprite, "rotation", -0.3 if !sprite.flip_h else 0.3, 0.1)
		tween.tween_property(sprite, "rotation", 0.0, 0.1)
		tween.parallel().tween_property(sprite, "scale", Vector2(0.4, 0.4), 0.2)
	
	if attack_panel:
		var tween = create_tween()
		tween.set_ease(Tween.EASE_IN)
		tween.set_trans(Tween.TRANS_BACK)
		
		# Arc movement
		var start_pos = Vector2(-40 if !sprite.flip_h else 40, -260)
		var mid_pos = Vector2(-140 if !sprite.flip_h else 140, -80)
		var end_pos = Vector2(-100 if !sprite.flip_h else 100, 20)
		
		tween.tween_property(attack_panel, "position", start_pos, 0.05)
		tween.tween_property(attack_panel, "position", mid_pos, 0.08)
		tween.tween_property(attack_panel, "position", end_pos, 0.08)
		
		# Visual effects
		tween.parallel().tween_property(attack_panel, "scale", Vector2(0.2, 1.2) * (1 if !sprite.flip_h else -1), 0.08)
		tween.parallel().tween_property(attack_panel, "scale", Vector2(1.0, 0.4) * (1 if !sprite.flip_h else -1), 0.08)
		tween.parallel().tween_property(attack_panel, "rotation", PI/3 if !sprite.flip_h else -PI/3, 0.16)
		
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
				var knockback_dir = Vector2(-1 if !sprite.flip_h else 1, 0.5).normalized()
				player.apply_knockback(knockback_dir * 1200)

func reset_attack_state() -> void:
	is_winding_up = false
	wind_up_timer = 0.0
	recovery_timer = 0.0
	
	if attack_panel:
		attack_panel.visible = false
		attack_panel.scale = Vector2(0.4, 0.4)
		attack_panel.modulate = Color(1, 1, 1, 1)
		attack_panel.rotation = 0
	
	if sprite:
		sprite.rotation = 0
		sprite.scale = Vector2(0.4, 0.4)
	
	attack_area.rotation = 0
	
	if current_state == EnemyState.ATTACK:
		var timer = get_tree().create_timer(attack_cooldown)
		timer.timeout.connect(func(): can_attack = true)

func take_damage(amount: float) -> void:
	if is_winding_up or current_state == EnemyState.ATTACK:
		reset_attack_state()
		can_attack = true
	
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
		
		if sprite and abs(velocity.x) > 0:
			sprite.flip_h = velocity.x < 0
	
	move_and_slide()

func handle_stunned_state(delta: float) -> void:
	if stun_timer <= 0:
		current_state = EnemyState.CHASE
		if sprite:
			sprite.modulate = original_color
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
	if sprite:
		sprite.modulate = Color(1.5, 1.5, 1.5)  # Flash white to indicate stun

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
	take_damage(player_node.strength)
	
	# Apply knockback effect
	var knockback_direction = (global_position - player_node.global_position).normalized()
	take_knockback(knockback_direction * 500)
	
	# Visual feedback
	if sprite:  # Use sprite instead of sprite_2d
		sprite.modulate = Color(2, 2, 2)  # Flash bright white
		var tween = create_tween()
		tween.tween_property(sprite, "modulate", Color.WHITE, 0.2)
	
	# Update health display
	hit_detector.health = current_health
