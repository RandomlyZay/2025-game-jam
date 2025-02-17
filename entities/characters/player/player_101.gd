extends CharacterBody2D

@onready var sprite_2d: Sprite2D = $Sprite2D

# Health Signals
signal health_changed(new_health: float, max_health: float)
signal player_died

# Movement Signals
signal dash_started
signal dash_ended
signal berserk_started
signal berserk_ended

@export_group("Health")
@export var max_health: float = 1.0
@export var weak_attack: float = 15.0
@export var heavy_attack: float = 20.0

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

@export_group("Berserk")
@export var berserk_speed: float = 1500.0
@export var berserk_duration: float = 15
@export var berserk_cooldown: float = 5
@export var berserk_invincibility_duration: float = 15

#abilities
@export_group("Abilities")

@export var can_fly = false
@export var can_berserk = true
@export var can_super_laser = false
@export var can_super_bomb = false

# Timer References
var dash_cooldown_timer: Timer
var dash_duration_timer: Timer
var berserk_invincibility_timer: Timer
var invincibility_timer: Timer
var berserk_cooldown_timer: Timer
var berserk_duration_timer: Timer

# State Variables
var current_health: float
var knockback_velocity: Vector2 = Vector2.ZERO
var is_invincible: bool = false
var is_dying: bool = false
var can_dash: bool = false
var last_move_direction: Vector2 = Vector2.RIGHT
var can_jump = false
var is_jumping: bool = false
var jumpMultiplyer = 8
var last_horizontal_direction: int = 1  # 1 for right, -1 for left

@onready var sprite = $Sprite2D

func _ready() -> void:
	current_health = max_health
	emit_signal("health_changed", current_health, max_health)
	
	
	# Initialize timers
	create_timers()
	

func create_timers() -> void:
	
	#Berserk Timer
	berserk_duration_timer = Timer.new()
	berserk_duration_timer.wait_time = berserk_duration
	berserk_duration_timer.one_shot = true
	berserk_duration_timer.timeout.connect(_on_berserk_duration_timer_timeout)
	add_child(berserk_duration_timer)
	
	# berserk cooldown timer
	dash_cooldown_timer = Timer.new()
	dash_cooldown_timer.wait_time = dash_cooldown
	dash_cooldown_timer.one_shot = true
	dash_cooldown_timer.timeout.connect(_on_berserk_cooldown_timer_timeout)
	add_child(dash_cooldown_timer)
	
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
	berserk_invincibility_timer = Timer.new()
	berserk_invincibility_timer.wait_time = dash_invincibility_duration
	berserk_invincibility_timer.one_shot = true
	berserk_invincibility_timer.timeout.connect(_on_invincibility_timer_timeout)
	add_child(berserk_invincibility_timer)
	
	# Invincibility timer
	invincibility_timer = Timer.new()
	invincibility_timer.wait_time = dash_invincibility_duration
	invincibility_timer.one_shot = true
	invincibility_timer.timeout.connect(_on_invincibility_timer_timeout)
	add_child(invincibility_timer)

func _physics_process(delta: float) -> void:
	handle_knockback(delta)
	
	move_and_slide()
	
	if knockback_velocity.is_zero_approx():
		var move_direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
		
		# Update direction only when moving
		if move_direction.length() > 0:
			last_move_direction = move_direction.normalized()
			
			# Update horizontal direction only when moving left or right
			if move_direction.x != 0:
				last_horizontal_direction = -1 if move_direction.x < 0 else 1
				if sprite:
					sprite.flip_h = last_horizontal_direction < 0
		
		# Only apply movement if not dashing and there's input
		if dash_duration_timer.is_stopped():
			if move_direction.length() > 0:
				velocity = last_move_direction * base_speed
			else:
				velocity = Vector2.ZERO  # Stop when no input
				
		handle_dash_input()
		
	if Input.is_action_just_pressed("jump") and can_jump == true and is_jumping == false:
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
		
		# Update horizontal direction only when moving left or right
		if move_direction.x != 0:
			last_horizontal_direction = -1 if move_direction.x < 0 else 1
			if sprite:
				sprite.flip_h = last_horizontal_direction < 0
	
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
	#MAKE BIGGER AND STRONGER AND AURA
	emit_signal("dash_started")
	
	berserk_duration_timer.start()
	berserk_cooldown_timer.start()
	invincibility_timer.start()
	
	modulate.a = 0.7

func end_dash() -> void:
	emit_signal("dash_ended")
	modulate.a = 1.0
	
	
func start_berserk() -> void:
	can_berserk = false
	is_invincible = true
	
	emit_signal("berserk_started")
	
	sprite_2d.scale = Vector2(3,3)
	
	dash_duration_timer.start()
	dash_cooldown_timer.start()
	invincibility_timer.start()
	
	modulate.a = 0.7

func end_berserk() -> void:
	emit_signal("berserk_ended")
	sprite_2d.scale = Vector2(1,1)
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
	
	Audio.play_sfx("bad_explosion")
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
	
func _on_berserk_cooldown_timer_timeout() -> void:
	can_berserk = true
	
func _on_berserk_duration_timer_timeout() -> void:
	end_berserk()

func jumping() -> void:
	#$AnimationPlayer.play("Jump")
		is_jumping = true
