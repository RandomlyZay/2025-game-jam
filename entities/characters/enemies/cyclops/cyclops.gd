extends "res://entities/characters/enemies/base_enemy.gd"

@export var swipe_damage: float = 25.0
@export var swipe_range: float = 120.0
@export var swipe_arc: float = 160.0
@export var swipe_windup: float = 0.4  # Reduced from 0.6
@export var swipe_recovery: float = 0.2  # Reduced from 0.3

var swipe_direction: Vector2 = Vector2.ZERO
var is_winding_up: bool = false
var wind_up_timer: float = 0.0
var recovery_timer: float = 0.0

@onready var attack_panel = $AttackArea/AttackPanel
@onready var attack_area = $AttackArea

var flip_threshold: float = 20.0  # Minimum X distance before allowing flip
var last_flip_time: float = 0.0
var flip_cooldown: float = 0.2

func _ready() -> void:
	health = 80.0
	max_health = 80.0
	base_speed = 180.0
	attack_damage = swipe_damage
	attack_range = 140.0  # Increased from 120
	attack_cooldown = 1.5
	current_health = health
	super._ready()

func handle_chase_state(_delta: float) -> void:
	if !player or !is_instance_valid(player):
		current_state = EnemyState.IDLE
		return
		
	var distance = global_position.distance_to(player.global_position)
	var to_player = player.global_position - global_position
	
	if distance <= attack_range * 0.8 and can_attack:  # Changed from attack_range to 0.8
		attack_target = player
		current_state = EnemyState.ATTACK
		start_swipe_attack()
	else:
		var ideal_distance = attack_range * 0.7
		var ideal_position: Vector2
		
		# Prefer horizontal positioning
		var side_offset = Vector2(ideal_distance * (1.0 if randf() > 0.5 else -1.0), 0)
		ideal_position = player.global_position + side_offset
		
		# Only adjust vertical position if too far up or down
		if abs(to_player.y) > 40:
			ideal_position.y = player.global_position.y
		
		velocity = (ideal_position - global_position).normalized() * base_speed
		
		if sprite and abs(velocity.x) > 10:  # Only flip if moving significantly
			var new_facing_right = to_player.x > 0
			var time = Time.get_ticks_msec() / 1000.0
			
			# Only allow flipping if enough time has passed or X distance is significant
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
	
	if attack_panel:
		attack_panel.visible = true
		attack_panel.modulate = Color(1, 1, 1, 0)
		attack_panel.position = Vector2(-40, -240)  # Start position higher up
		
		var tween = create_tween()
		tween.tween_property(attack_panel, "modulate", Color(1, 1, 1, 1), 0.2)
	
	if is_instance_valid(player):
		var to_player = player.global_position - global_position
		sprite.flip_h = to_player.x > 0
		
		# Windup animation leaning back
		sprite.rotation = 0
		var tween = create_tween()
		tween.tween_property(sprite, "rotation", 0.6 if !sprite.flip_h else -0.6, 0.3)
		tween.parallel().tween_property(sprite, "scale", Vector2(0.35, 0.45), 0.3)
		
		# Update positions based on facing direction
		attack_area.position.x = -60 if !sprite.flip_h else 60
		attack_panel.scale = Vector2(0.4, 0.4) * (1 if !sprite.flip_h else -1)
		swipe_direction = to_player.normalized()

func perform_swipe() -> void:
	is_winding_up = false
	recovery_timer = swipe_recovery
	
	if sprite:
		var tween = create_tween()
		tween.tween_property(sprite, "rotation", -0.3 if !sprite.flip_h else 0.3, 0.1)  # Faster rotation
		tween.tween_property(sprite, "rotation", 0.0, 0.1)
		tween.parallel().tween_property(sprite, "scale", Vector2(0.4, 0.4), 0.2)
	
	if attack_panel:
		# Enhanced arc swing motion
		var tween = create_tween()
		tween.set_ease(Tween.EASE_IN)
		tween.set_trans(Tween.TRANS_BACK)  # Changed for more dramatic movement
		
		# Calculate better arc points with more extreme positions
		var start_pos = Vector2(-40 if !sprite.flip_h else 40, -260)
		var mid_pos = Vector2(-160 if !sprite.flip_h else 160, -80)  # More extreme horizontal stretch
		var end_pos = Vector2(-120 if !sprite.flip_h else 120, 40)
		
		# Faster, more dramatic movement
		tween.tween_property(attack_panel, "position", start_pos, 0.05)
		tween.tween_property(attack_panel, "position", mid_pos, 0.08)
		tween.tween_property(attack_panel, "position", end_pos, 0.08)
		
		# More extreme scaling during swing
		tween.parallel().tween_property(attack_panel, "scale", Vector2(0.2, 1.2) * (1 if !sprite.flip_h else -1), 0.08)
		tween.parallel().tween_property(attack_panel, "scale", Vector2(1.0, 0.4) * (1 if !sprite.flip_h else -1), 0.08)
		tween.parallel().tween_property(attack_panel, "rotation", PI/3 if !sprite.flip_h else -PI/3, 0.16)
		
		# Stronger impact flash
		tween.parallel().tween_property(attack_panel, "modulate", Color(8.0, 4.0, 4.0, 1), 0.08)
		tween.parallel().tween_property(attack_panel, "modulate", Color(1, 1, 1, 0), 0.12)
	
	# Apply damage with horizontal knockback
	if is_instance_valid(player):
		var to_player = player.global_position - global_position
		if abs(to_player.x) <= swipe_range * 1.2 and abs(to_player.y) <= swipe_range * 0.8:
			if player.has_method("take_damage"):
				player.take_damage(swipe_damage)
			if player.has_method("apply_knockback"):
				# Strong horizontal knockback AWAY from enemy - fixed direction
				var knockback_dir = Vector2(-1 if !sprite.flip_h else 1, 0.5).normalized()
				player.apply_knockback(knockback_dir * 1400)  # Increased knockback force

func reset_attack_state() -> void:
	is_winding_up = false
	wind_up_timer = 0.0
	recovery_timer = 0.0
	
	if attack_panel:
		attack_panel.visible = false
		attack_panel.scale = Vector2(0.4, 0.4)
		attack_panel.modulate = Color(1, 1, 1, 1)
	
	# Reset sprite transformations
	if sprite:
		sprite.rotation = 0
		sprite.scale = Vector2(0.4, 0.4)
	
	attack_area.rotation = 0
	
	# Only set up attack cooldown if not interrupted by damage
	if current_state == EnemyState.ATTACK:
		var timer = get_tree().create_timer(attack_cooldown)
		timer.timeout.connect(func(): can_attack = true)

func take_damage(amount: float) -> void:
	# First cancel any ongoing attack
	if is_winding_up or current_state == EnemyState.ATTACK:
		reset_attack_state()
		can_attack = true  # Allow attacking again after recovery
	
	# Call parent's take_damage which handles stun state
	super.take_damage(amount)
	
	# Ensure proper stun duration
	stun_timer = hit_stun_duration
