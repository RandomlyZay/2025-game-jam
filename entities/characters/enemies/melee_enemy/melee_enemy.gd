extends "res://entities/characters/enemies/base_enemy.gd"


@onready var hit_detector: Area2D = $HitDetector
@onready var attack_area: Area2D = $AttackArea
@onready var sprite_2d: Sprite2D = $Sprite2D

@onready var floating_numbers: Node2D = $FloatingNumbers




@export var attack_windup_time: float = 0.2
@export var attack_lunge_speed: float = 1500.0
@export var attack_lunge_duration: float = 0.15
@export var knockback_force: float = 800.0
@export var melee_damage: int = 15
@export var combo_damage_multiplier: float = 1.2
@export var attack_arc_degrees: float = 90.0
@export var positioning_distance: float = 60.0

# Melee specific variables
var melee_attack_direction: Vector2 = Vector2.ZERO
var melee_attack_timer: float = 0.0
var melee_lunge_timer: float = 0.0
var is_in_attack_lunge: bool = false

func _ready() -> void:
	base_speed = 200.0  # Make sure speed is set
	max_health = 120
	health = max_health
	attack_damage = 20.0
	max_combo = 3
	block_chance = 0.4
	hit_detector.set_interaction_callable(Callable(self, "_on_interact"))
	hit_detector.health = current_health
	super._ready()
	$AttackArea.collision_mask = 4
	setup_attack_area()

func handle_chase_state(_delta: float) -> void:
	if !player or !is_instance_valid(player):
		current_state = EnemyState.IDLE
		return
		
	var distance = global_position.distance_to(player.global_position)
	var direction = (player.global_position - global_position).normalized()
	
	# Always move towards player when in chase state
	velocity = direction * base_speed
	
	# Switch to attack state when in range
	if distance <= attack_range and can_attack:
		attack_target = player
		current_state = EnemyState.ATTACK

func handle_attack_state(delta: float) -> void:
	if !attack_target or !is_instance_valid(attack_target):
		reset_attack_state()
		return
		
	var distance = global_position.distance_to(attack_target.global_position)
	
	if distance > attack_range:
		# Circle around target while closing in
		var direction = (attack_target.global_position - global_position).normalized()
		var strafe = Vector2(-direction.y, direction.x)
		velocity = (direction + strafe * 0.5).normalized() * base_speed
	else:
		if can_attack:
			perform_combo_attack()
		else:
			reset_attack_state()

	if melee_attack_timer > 0:
		melee_attack_timer -= delta
		melee_attack_direction = (attack_target.global_position - global_position).normalized()
		velocity = velocity.move_toward(Vector2.ZERO, base_speed * 2 * delta)
		
	elif is_in_attack_lunge:
		melee_lunge_timer -= delta
		velocity = melee_attack_direction * attack_lunge_speed
		
		if !has_hit_target:
			check_for_hit()
		
		if melee_lunge_timer <= 0 or has_hit_target:
			reset_attack_state()
	else:
		is_in_attack_lunge = true
		melee_lunge_timer = attack_lunge_duration
		velocity = melee_attack_direction * attack_lunge_speed
		check_for_hit()

func check_for_hit() -> void:
	if !attack_area:
		return
		
	var overlapping = attack_area.get_overlapping_areas()
	
	for area in overlapping:
		# Only check combat-related interactions
		if is_valid_target_area(area):
			register_hit()
			if attack_target.has_method("take_damage"):
				attack_target.take_damage(melee_damage)
			if attack_target.has_method("apply_knockback"):
				attack_target.apply_knockback(melee_attack_direction * knockback_force)
			return

func start_attack() -> void:
	is_attacking = true
	is_in_attack_lunge = false
	has_hit_target = false
	melee_attack_timer = attack_windup_time
	melee_lunge_timer = 0.0
	last_hit_position = attack_target.global_position
	last_hit_time = Time.get_ticks_msec()
	can_attack = false
	
	if sprite:
		sprite.modulate = Color(1.5, 1.0, 1.0)

func reset_attack_state() -> void:
	is_attacking = false
	is_in_attack_lunge = false
	has_hit_target = false
	melee_attack_timer = 0.0
	melee_lunge_timer = 0.0
	current_state = EnemyState.CHASE
	if sprite:
		sprite.modulate = original_color
	
	var timer = get_tree().create_timer(attack_cooldown)
	timer.timeout.connect(func(): can_attack = true)

func register_hit() -> void:
	has_hit_target = true

func is_in_lunge_state() -> bool:
	return current_state == EnemyState.ATTACK and is_in_attack_lunge

func _on_attack_area_area_entered(area: Area2D) -> void:
	if is_in_attack_lunge and !has_hit_target and is_valid_target_area(area):
		register_hit()
		if attack_target.has_method("take_damage"):
			attack_target.take_damage(melee_damage)
		if attack_target.has_method("apply_knockback"):
			attack_target.apply_knockback(melee_attack_direction * knockback_force)

func take_damage(amount: float) -> void:
	super.take_damage(amount)
	hits_taken += 1
	
	current_state = EnemyState.STUNNED
	stun_timer = stun_duration
	
	var knockback_direction = -velocity.normalized()
	if knockback_direction == Vector2.ZERO:
		knockback_direction = Vector2.RIGHT.rotated(randf() * TAU)
	knockback_velocity = knockback_direction * 500
	
	if sprite:
		sprite.modulate = Color(1.0, 0.5, 0.5)

func _on_hit(is_overheated: bool = false) -> void:
	super._on_hit(is_overheated)
	
	# Reset attack state when hit
	if is_attacking or is_in_attack_lunge:
		reset_attack_state()

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

func perform_combo_attack() -> void:
	current_combo = (current_combo + 1) % (max_combo + 1)
	var _damage = attack_damage * pow(combo_damage_multiplier, current_combo - 1)
	
	# Different attack animations/effects based on combo stage
	match current_combo:
		1: # Quick jab
			attack_arc_degrees = 60.0
			attack_range = 70.0
		2: # Wide swing
			attack_arc_degrees = 120.0
			attack_range = 80.0
		3: # Power attack
			attack_arc_degrees = 90.0
			attack_range = 90.0
			
	# Start combo timer
	combo_timer = combo_window
	start_attack()

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
	if sprite_2d:
		sprite_2d.modulate = Color(2, 2, 2)  # Flash bright white
		var tween = create_tween()
		tween.tween_property(sprite_2d, "modulate", Color.WHITE, 0.2)
	
	# Update health display
	hit_detector.health = current_health
