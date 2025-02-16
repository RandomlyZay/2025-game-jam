extends "res://entities/characters/enemies/base_enemy.gd"

@export var swipe_damage: float = 25.0
@export var swipe_range: float = 100.0
@export var swipe_arc: float = 90.0
@export var swipe_windup: float = 0.3
@export var swipe_recovery: float = 0.4

var swipe_direction: Vector2 = Vector2.ZERO
var is_winding_up: bool = false
var wind_up_timer: float = 0.0
var recovery_timer: float = 0.0

func _ready() -> void:
	# Initialize with combat-focused stats
	health = 80.0
	max_health = 80.0
	base_speed = 180.0  # Slower but steady
	attack_damage = swipe_damage
	attack_range = swipe_range
	attack_cooldown = 1.5
	current_health = health
	super._ready()

func handle_chase_state(_delta: float) -> void:
	if !player or !is_instance_valid(player):
		current_state = EnemyState.IDLE
		return
		
	var distance = global_position.distance_to(player.global_position)
	var direction = (player.global_position - global_position).normalized()
	
	if distance <= attack_range and can_attack:
		attack_target = player
		current_state = EnemyState.ATTACK
		start_swipe_attack()
	else:
		# Move towards player but maintain slight distance
		var target_pos = player.global_position - direction * (attack_range * 0.7)
		velocity = (target_pos - global_position).normalized() * base_speed
		
		# Update sprite direction - inverted since sprite faces left by default
		if sprite and abs(velocity.x) > 0:
			sprite.flip_h = velocity.x > 0

func handle_attack_state(delta: float) -> void:
	if is_winding_up:
		wind_up_timer -= delta
		if wind_up_timer <= 0:
			perform_swipe()
	elif recovery_timer > 0:
		recovery_timer -= delta
		if recovery_timer <= 0:
			reset_attack_state()
			current_state = EnemyState.CHASE

func start_swipe_attack() -> void:
	is_winding_up = true
	wind_up_timer = swipe_windup
	can_attack = false
	
	# Telegraph the attack
	if sprite:
		sprite.modulate = Color(1.2, 0.8, 0.8)
	
	# Aim at player's current position
	if is_instance_valid(player):
		swipe_direction = (player.global_position - global_position).normalized()

func perform_swipe() -> void:
	is_winding_up = false
	recovery_timer = swipe_recovery
	
	# Visual feedback
	if sprite:
		sprite.modulate = Color(1.5, 1.0, 1.0)
	
	# Check for hits in an arc
	var attack_area = $AttackArea
	if attack_area and is_instance_valid(player):
		var to_player = player.global_position - global_position
		if to_player.length() <= attack_range:
			var angle = rad_to_deg(swipe_direction.angle_to(to_player))
			if abs(angle) <= swipe_arc / 2:
				if player.has_method("take_damage"):
					player.take_damage(swipe_damage)
				if player.has_method("apply_knockback"):
					player.apply_knockback(swipe_direction * 400)

func reset_attack_state() -> void:
	is_winding_up = false
	wind_up_timer = 0.0
	recovery_timer = 0.0
	if sprite:
		sprite.modulate = original_color
	
	# Start attack cooldown
	var timer = get_tree().create_timer(attack_cooldown)
	timer.timeout.connect(func(): can_attack = true)

func take_damage(amount: float) -> void:
	super.take_damage(amount)
	
	# Cancel attack if hit during windup
	if is_winding_up:
		reset_attack_state()
