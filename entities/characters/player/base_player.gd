extends CharacterBody2D

signal health_changed(new_health: float, max_health: float)
signal human_died

@export_group("Health")
@export var max_health: float = 100.0 
var current_health: float = max_health

@export_group("Movement")
@export var base_speed: float = 500.0
@export var knockback_friction: float = 2000.0

var knockback_velocity: Vector2 = Vector2.ZERO
var look_direction: Vector2 = Vector2.DOWN 
var is_invincible: bool = false  

func _ready() -> void:
	current_health = max_health
	emit_signal("health_changed", current_health, max_health)

func _physics_process(delta: float) -> void:
	handle_knockback(delta)
	handle_movement(delta)
	move_and_slide()

func _process(delta: float) -> void:
	pass  

func handle_knockback(delta: float) -> void:
	if knockback_velocity.length() > 0:
		velocity = knockback_velocity
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, knockback_friction * delta)

func handle_movement(delta: float) -> void:
	if knockback_velocity.length() > 0:
		return
	
	var direction = Vector2.ZERO
	if Input.is_action_pressed("move_right"):
		direction.x += 1
	if Input.is_action_pressed("move_left"):
		direction.x -= 1
	if Input.is_action_pressed("move_down"):
		direction.y += 1
	if Input.is_action_pressed("move_up"):
		direction.y -= 1
	
	if direction != Vector2.ZERO:
		direction = direction.normalized()
		velocity = direction * base_speed
		look_direction = direction  
	else:
		velocity = Vector2.ZERO

func take_damage(amount: float = 1.0) -> void:
	if is_invincible:  
		return
		
	current_health = max(0.0, current_health - amount)
	emit_signal("health_changed", current_health, max_health)
	
	if current_health <= 0:
		if is_in_group("human"):
			emit_signal("human_died")
		on_death()
		return
		
	flash_hit()

func flash_hit() -> void:
	if not is_invincible:
		modulate = Color(1, 0, 0, 1)
		var tween = create_tween()
		tween.tween_property(self, "modulate", Color.WHITE, 0.2)

func add_health(amount: float = 1.0) -> void:
	current_health = min(current_health + amount, max_health)
	emit_signal("health_changed", current_health, max_health)

func on_death() -> void:
	visible = false
	set_process(false)
	set_physics_process(false)
	set_process_input(false)
