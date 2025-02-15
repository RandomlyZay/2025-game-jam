extends CharacterBody2D

# Health Signals
signal health_changed(new_health: float, max_health: float)
signal player_died

# Movement Signals
signal dash_started
signal dash_ended

@export_group("Health")
@export var max_health: float = 1000.0
@export var strength: float = 1.00


@export_group("Movement")
@export var base_speed: float = 500.0
@export var knockback_recovery_speed: float = 1200.0  # How fast you recover from getting knocked back
@export var knockback_resistance: float = 0.3
@export var jump_speed: float = 25.00
@export var gravity: float = 5.00
@export var acceleration: float = 500

@export_group("Dash")
@export var dash_speed: float = 1500.0
@export var dash_duration: float = 0.2
@export var dash_cooldown: float = 0.5
@export var dash_invincibility_duration: float = 0.3

# Timer References
var dash_cooldown_timer: Timer
var dash_duration_timer: Timer
var invincibility_timer: Timer

# State Variables
var current_health: float
var knockback_velocity: Vector2 = Vector2.ZERO
var is_invincible: bool = false
var is_dying: bool = false
var can_dash: bool = true
var last_move_direction: Vector2 = Vector2.RIGHT
var is_jumping: bool = false
var z = 0
var jumpMultiplyer = 8
var direction_x = 0
var direction_y = 0


func _ready() -> void:
	current_health = max_health
	emit_signal("health_changed", current_health, max_health)
	
	# Initialize timers
	create_timers()

func create_timers() -> void:
	# Dash duration timer
	dash_duration_timer = Timer.new()
	dash_duration_timer.wait_time = dash_duration
	dash_duration_timer.one_shot = true
	dash_duration_timer.timeout.connect(_on_dash_duration_timer_timeout)
	add_child(dash_duration_timer)
	
	# Dash cooldown timer
	dash_cooldown_timer = Timer.new()
	dash_cooldown_timer.wait_time = dash_cooldown
	dash_cooldown_timer.one_shot = true
	dash_cooldown_timer.timeout.connect(_on_dash_cooldown_timer_timeout)
	add_child(dash_cooldown_timer)
	
	# Invincibility timer
	invincibility_timer = Timer.new()
	invincibility_timer.wait_time = dash_invincibility_duration
	invincibility_timer.one_shot = true
	invincibility_timer.timeout.connect(_on_invincibility_timer_timeout)
	add_child(invincibility_timer)

func _physics_process(delta: float) -> void:
	
	
	#keep track of direction vars
	direction_var_checker()
	
	if direction_x == 0 && is_jumping == false:
		#$AnimationPlayer.play("Idle")
		pass
	
	
	if is_jumping == false:
		
		pass
		
	
	handle_knockback(delta)
	
	move_and_slide()
	
	if knockback_velocity.is_zero_approx():
		handle_movement()
		handle_dash_input()
		
	if Input.is_action_just_pressed("jump") and is_jumping == false:
		print("jump initiated")
		jumping()

func handle_knockback(delta: float) -> void:
	if knockback_velocity.length() > 10:
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, knockback_recovery_speed * delta)
		velocity = knockback_velocity
	else:
		knockback_velocity = Vector2.ZERO

func handle_movement() -> void:
	var move_direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	
	# Update direction only when moving
	if move_direction.length() > 0:
		last_move_direction = move_direction.normalized()
	
	# Only apply movement if not dashing and there's input
	if dash_duration_timer.is_stopped():
		if move_direction.length() > 0:
			velocity = last_move_direction * base_speed
		else:
			velocity = Vector2.ZERO  # Stop when no input

func handle_dash_input() -> void:
	if Input.is_action_just_pressed("dash") and can_dash:
		start_dash()

func start_dash() -> void:
	can_dash = false
	is_invincible = true
	velocity = last_move_direction * dash_speed
	emit_signal("dash_started")
	
	dash_duration_timer.start()
	dash_cooldown_timer.start()
	invincibility_timer.start()
	
	modulate.a = 0.7

func end_dash() -> void:
	emit_signal("dash_ended")
	modulate.a = 1.0

func take_damage(amount: float) -> void:
	if is_invincible or is_dying:
		return
	
	current_health = max(0.0, current_health - amount)
	emit_signal("health_changed", current_health, max_health)
	
	modulate = Color(1, 0, 0, 1)
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.2)
	
	if current_health <= 0:
		on_death()

func on_death() -> void:
	is_dying = true
	emit_signal("player_died")
	queue_free()

func apply_knockback(force: Vector2) -> void:
	if not dash_duration_timer.is_stopped():
		return
	knockback_velocity = force * (1.0 - knockback_resistance)

# Timer callbacks
func _on_dash_cooldown_timer_timeout() -> void:
	can_dash = true

func _on_dash_duration_timer_timeout() -> void:
	end_dash()

func _on_invincibility_timer_timeout() -> void:
	is_invincible = false

func jumping() -> void:
	#$AnimationPlayer.play("Jump")
		is_jumping = true
		

func direction_var_checker() -> void:
	check_x()
	check_y()
	

func check_x() -> void:
	if Input.is_action_just_pressed('move_right'):
		print("moving right")
		direction_x += 1
	
	if Input.is_action_just_released("move_right"):
		print("Stopped moving right")
		direction_x -=1
		
	if Input.is_action_just_pressed('move_left'):
		print("moving left")
		direction_x -= 1
	
	if Input.is_action_just_released("move_left"):
		print("Stopped moving left")
		direction_x +=1



func check_y() -> void:
	if Input.is_action_just_pressed('move_down'):
		print("moving down")
		direction_y -= 1
	
	if Input.is_action_just_released("move_down"):
		print("Stopped moving down")
		direction_y +=1
		
	if Input.is_action_just_pressed('move_up'):
		print("moving up")
		direction_x += 1
	
	if Input.is_action_just_released("move_up"):
		print("Stopped moving up")
		direction_x -=1
