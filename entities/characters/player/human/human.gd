extends "res://entities/player/base_player.gd"

signal stamina_changed(new_stamina: float, max_stamina: float)
signal velocity_changed(velocity: Vector2)
signal sprint
signal dash

@export_group("Dash")
@export var dash_speed: float = 1500.0
@export var dash_duration: float = 0.2
@export var dash_cooldown: float = 0.5
@export var dash_stamina_cost: float = 25.0

@export_group("Sprint")
@export var sprint_speed_multiplier: float = 1.5
@export var stamina_drain_rate: float = 20.0  # Stamina drained per second while sprinting
@export var stamina_regen_rate: float = 15.0  # Stamina regenerated per second while not sprinting
@export var max_stamina: float = 100.0
@export var exhausted_speed_multiplier: float = 0.7  
@export var exhausted_dash_speed_multiplier: float = 0.6  # Nerfed dash speed while exhausted

@export_group("Combat")
@export var knockback_resistance: float = 0.3 
@export var knockback_recovery_speed: float = 1200.0 

@export_group("Animations")
@export var normal_speed_scale: float = 1.0 
@export var sprint_speed_scale: float = 1.5  

@export_group("Shockwave")
@export var shockwave_min_radius: float = 0.0 
@export var shockwave_max_radius: float = 300.0
@export var shockwave_charge_rate: float = 120.0 
@export var shockwave_base_force: float = 800.0
@export var shockwave_max_force_multiplier: float = 2.0
@export var shockwave_stun_damage: float = 2.0
@export var shockwave_min_energy_cost: float = 0.0 
@export var shockwave_max_energy_cost: float = 45.0  
@export var wall_impact_threshold: float = 1000.0 
@export var wall_impact_damage: float = 1.0 

@export_group("Destabilizing Field")
@export var destabilizing_field_delay: float = 1.0  # Time before field appears when standing still
@export var destabilizing_field_drain_rate: float = 10.0  # Energy drained per second
@export var destabilizing_field_enabled: bool = true 

@export_group("Energy System")
@export var energy_regen_rate: float = 10.0  # Energy regenerated per second

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var trail_effect: CPUParticles2D = $TrailEffect
@onready var ShockwaveEffect = preload("res://entities/player/human/shockwave_effect.tscn")
@onready var ShockwaveRangeIndicator = preload("res://entities/player/human/shockwave_range_indicator.tscn")
@onready var DestabilizingField = preload("res://entities/player/human/destabilizing_field.tscn")
@onready var StaminaWheel = preload("res://ui/hud/stamina_wheel.tscn")
@onready var EnergyWheel = preload("res://ui/hud/energy_wheel.tscn")
@onready var hit_box: Area2D = $HitBox
@onready var camera: Camera2D = $Camera2D

var effects_container: Node2D
var current_shockwave_radius: float = shockwave_min_radius
var current_shockwave_force: float = shockwave_base_force
var is_charging_shockwave: bool = false
var range_indicator: Node2D = null
var destabilizing_field: Node2D = null
var time_since_last_move: float = 0.0

# Stamina State
var current_stamina: float = max_stamina
var stamina_wheel: Node2D = null

# Energy State
var current_energy: float = 100.0
var max_energy: float = 100.0
var energy_wheel: Node2D = null

# Movement State
var time_until_next_dash: float = 0.0
var dash_timer: float = 0.0
var is_dashing: bool = false
var is_sprinting: bool = false
var is_moving: bool = false
var is_exhausted: bool = false

# Combat State
var is_dying: bool = false 

# Add toggle state
var destabilizing_field_active: bool = true

func _ready() -> void:
	max_health = 50 
	current_health = max_health
	
	emit_signal("health_changed", current_health, max_health)
	
	add_to_group("human")
	
	# Create effects container
	effects_container = Node2D.new()
	add_child(effects_container)
	effects_container.add_to_group("effects_container")
	
	# Create stamina wheel
	stamina_wheel = StaminaWheel.instantiate()
	add_child(stamina_wheel)
	update_stamina_bar()
	
	# Create energy wheel
	energy_wheel = EnergyWheel.instantiate()
	add_child(energy_wheel)
	update_energy_wheel()
	
	# Set up post-process effects
	var post_process = $Camera2D/PostProcess
	if not post_process:
		return
	
	# Set up collision detection
	set_collision_layer_value(1, true)  # Player's physical collision layer
	set_collision_mask_value(2, true)   # Can detect enemy physical bodies
	
	current_stamina = max_stamina
	emit_signal("stamina_changed", current_stamina, max_stamina)
	
	# Initialize invincibility state
	set_invincibility_visuals(is_invincible)
	
	# Set initial animation to face down
	animated_sprite.animation = "idle_down"
	animated_sprite.play()
	
	# Initialize destabilizing field state
	destabilizing_field_active = destabilizing_field_enabled

func _process(delta: float) -> void:
	super._process(delta)  # Call base class _process for i-frame handling
	
	if not is_dying:
		# Handle destabilizing field energy drain first
		if destabilizing_field and destabilizing_field.is_inside_tree():
			var drain_cost = destabilizing_field_drain_rate * delta
			if current_energy >= drain_cost:
				current_energy -= drain_cost
				update_energy_wheel()
			else:
				# Not enough energy to maintain field
				destabilizing_field.fade_out()
				destabilizing_field = null
		
		# Handle energy regeneration when not using abilities
		if not is_charging_shockwave and not destabilizing_field:
			current_energy = min(current_energy + energy_regen_rate * delta, max_energy)
			update_energy_wheel()
		
		if is_charging_shockwave:
			charge_shockwave(delta)
		if time_since_last_move >= destabilizing_field_delay:
			spawn_destabilizing_field()
	
	# Keep effects container aligned with scene
	if effects_container:
		effects_container.global_position = global_position
	
	# Update trail effect position
	if trail_effect and trail_effect.is_inside_tree():
		# Only set the local position, let the parent handle global transforms
		trail_effect.position = Vector2(0, 73) 
	
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("dash"):
		start_dash()
	if event.is_action_pressed("shockwave"):
		start_charging_shockwave()
	elif event.is_action_released("shockwave"):
		release_shockwave()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_destabilizing_field"):
		destabilizing_field_active = !destabilizing_field_active
		if !destabilizing_field_active and destabilizing_field:
			destabilizing_field.fade_out()
			destabilizing_field = null
			time_since_last_move = 0.0

func update_stamina_bar() -> void:
	if not stamina_wheel or not is_instance_valid(stamina_wheel):
		return
	
	stamina_wheel.update_stamina(current_stamina, max_stamina, is_exhausted)

func update_energy_wheel() -> void:
	if not energy_wheel or not is_instance_valid(energy_wheel):
		return
	
	energy_wheel.update_energy(current_energy, max_energy)

# Movement
func handle_movement(delta: float) -> void:
	# Handle knockback first
	if knockback_velocity.length() > 10:
		# Apply knockback resistance and smooth recovery
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, knockback_recovery_speed * delta)
		velocity = knockback_velocity
		trail_effect.emitting = false
		return
	
	var move_direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	is_moving = move_direction.length() > 0
	is_sprinting = Input.is_action_pressed("sprint") and not is_exhausted 
	 
	# Update time since last move
	if is_moving:
		time_since_last_move = 0.0
	else:
		time_since_last_move += delta
	
	# Clear destabilizing field if we start moving
	if is_moving and destabilizing_field:
		destabilizing_field.fade_out()
		destabilizing_field = null
	
	if is_moving:
		# Update look_direction from base class only when actually moving
		look_direction = move_direction
		
		# Calculate movement speed
		var current_speed = base_speed
		if is_exhausted:
			current_speed *= exhausted_speed_multiplier
		elif is_sprinting:  # Only apply sprint multiplier if actually sprinting
			current_speed *= sprint_speed_multiplier
			
		velocity = move_direction * current_speed
		velocity_changed.emit(velocity)  # Emit the signal with current velocity
		
		# Handle movement animations
		if abs(move_direction.x) >= abs(move_direction.y):
			if move_direction.x < 0:
				animated_sprite.animation = "move_left"
			else:
				animated_sprite.animation = "move_right"
		else:
			if move_direction.y < 0:
				animated_sprite.animation = "move_up"
			else:
				animated_sprite.animation = "move_down"
		animated_sprite.play()
	else:
		# Keep the current animation direction when idle
		var current_anim = animated_sprite.animation
		if current_anim.begins_with("move_"):
			animated_sprite.animation = "idle_" + current_anim.substr(5)
		elif not current_anim.begins_with("idle_"):
			# If we don't have a movement or idle animation, determine it from look_direction
			if abs(look_direction.x) >= abs(look_direction.y):
				animated_sprite.animation = "idle_" + ("left" if look_direction.x < 0 else "right")
			else:
				animated_sprite.animation = "idle_" + ("up" if look_direction.y < 0 else "down")
		animated_sprite.play()
	
	# Handle stamina
	if is_sprinting and is_moving:
		current_stamina = max(0, current_stamina - stamina_drain_rate * delta)
		if current_stamina == 0:
			is_exhausted = true
	elif not is_dashing:  # Don't regenerate during dash
		current_stamina = min(max_stamina, current_stamina + stamina_regen_rate * delta)
		if is_exhausted and current_stamina >= max_stamina:
			is_exhausted = false
	
	emit_signal("stamina_changed", current_stamina, max_stamina)
	update_stamina_bar()
	update_energy_wheel()
	
	var current_speed = base_speed
	if is_exhausted:
		current_speed *= exhausted_speed_multiplier
	elif is_sprinting:  # Only apply sprint multiplier if actually sprinting
		current_speed *= sprint_speed_multiplier
	
	if is_dashing:
		animated_sprite.stop()  # Pause animation during dash
		if is_exhausted:
			velocity = move_direction * (dash_speed * exhausted_dash_speed_multiplier)
		else:
			velocity = move_direction * dash_speed
	else:
		velocity = move_direction * current_speed
		
		# Set animation speed based on state
		if is_sprinting and is_moving:
			animated_sprite.set_speed_scale(sprint_speed_scale)
		else:
			animated_sprite.set_speed_scale(normal_speed_scale)
			
	time_until_next_dash = max(0, time_until_next_dash - delta)
	
	if is_dashing:
		dash_timer -= delta
		if dash_timer <= 0:
			end_dash()
	
	# Update trail effect
	trail_effect.emitting = is_dashing || (is_sprinting && is_moving && not is_exhausted)

func handle_sprint() -> void:
	if is_sprinting:
		emit_signal("sprint")

func handle_dash() -> void:
	if is_dashing:
		emit_signal("dash")

func start_dash() -> void:
	if time_until_next_dash > 0 or is_dashing:
		return
	if current_stamina < dash_stamina_cost and not is_exhausted:  # Allow dash while exhausted
		return
	
	is_dashing = true
	dash_timer = dash_duration
	time_until_next_dash = dash_cooldown
	
	if not is_exhausted:
		current_stamina -= dash_stamina_cost
		emit_signal("stamina_changed", current_stamina, max_stamina)
	handle_dash()

func end_dash() -> void:
	is_dashing = false
	set_collision_layer_value(1, true)
	modulate.a = 1.0
	animated_sprite.play()  # Resume animation after dash

# Stamina
func flash_stamina_full() -> void:
	if not stamina_wheel or not is_instance_valid(stamina_wheel):
		return
	
	# Flash the stamina wheel green briefly
	stamina_wheel.flash_full()

# Combat
func take_damage(amount: float = 1.0) -> void:
	if is_invincible or is_dying:  # Prevent damage if already dying
		return
		
	AudioManager.play_sfx("human_hurt")
	
	# Normal damage effect for non-lethal damage
	var post_process = $Camera2D/PostProcess
	if post_process and not is_invincible:
		var health_percent = (current_health - amount) / max_health
		var intensity_scale = 1.0 + (1.0 - health_percent) * 0.5
		post_process.flash_vignette(0.8 * intensity_scale, 0.3)
		post_process.flash_chromatic_aberration(1.0 * intensity_scale, 0.2)
	
	super.take_damage(amount)

func apply_knockback(knockback: Vector2) -> void:
	knockback_velocity = knockback * (1.0 - knockback_resistance)
	
	# Cancel dash if we're knocked back
	if is_dashing:
		end_dash()

func on_death() -> void:
	if is_dying:  # Prevent multiple death calls
		return
	is_dying = true
	
	# Immediate death
	if not GameState.is_game_over():
		AudioManager.play_sfx("human_death")
	emit_signal("human_died")
	queue_free()  # Remove human immediately

func _on_health_depleted() -> void:
	if is_dying:
		return
	is_dying = true
	
	# Immediate death
	if not GameState.is_game_over():
		AudioManager.play_sfx("human_death")
	emit_signal("human_died")
	queue_free()  # Remove human immediately

func start_charging_shockwave() -> void:
	if is_charging_shockwave or current_energy <= 0:  
		return
	
	# Clear destabilizing field if it exists
	if destabilizing_field:
		destabilizing_field.fade_out()
		destabilizing_field = null
		
	is_charging_shockwave = true
	current_shockwave_radius = 0.0
	current_shockwave_force = shockwave_base_force
	
	# Show initial cost on energy wheel
	energy_wheel.update_cost(shockwave_min_energy_cost, shockwave_max_energy_cost)
	
	# Create range indicator
	range_indicator = ShockwaveRangeIndicator.instantiate()
	effects_container.add_child(range_indicator)
	range_indicator.set_radius(0)  

func charge_shockwave(delta: float) -> void:
	if not is_charging_shockwave:
		return
	
	# Calculate how much more we can charge based on remaining energy
	var current_charge_ratio = (current_shockwave_radius) / (shockwave_max_radius)
	var current_cost = lerp(shockwave_min_energy_cost, shockwave_max_energy_cost, current_charge_ratio)
	
	# Calculate potential next frame's cost
	var next_radius = min(current_shockwave_radius + shockwave_charge_rate * delta, shockwave_max_radius)
	var next_charge_ratio = (next_radius) / (shockwave_max_radius)
	var next_cost = lerp(shockwave_min_energy_cost, shockwave_max_energy_cost, next_charge_ratio)
	
	# Update cost display on energy wheel
	energy_wheel.update_cost(current_cost, shockwave_max_energy_cost)
	
	# Check if we can afford the next charge increment
	if next_cost > current_energy:
		release_shockwave()
		return
	
	# Continue charging if we can afford it and haven't reached max size
	if current_shockwave_radius < shockwave_max_radius:
		current_shockwave_radius = next_radius
		current_shockwave_force = lerp(shockwave_base_force, shockwave_base_force * shockwave_max_force_multiplier, current_charge_ratio)
	
	if range_indicator:
		range_indicator.set_radius(current_shockwave_radius)

func release_shockwave() -> void:
	if not is_charging_shockwave:
		return
	
	# Calculate energy cost based on current charge level
	var charge_ratio = (current_shockwave_radius) / (shockwave_max_radius)
	var energy_cost = lerp(shockwave_min_energy_cost, shockwave_max_energy_cost, charge_ratio)
	
	# Ensure we don't try to use more energy than we have
	energy_cost = min(energy_cost, current_energy)
	
	# Create shockwave effect
	var effect = ShockwaveEffect.instantiate()
	effects_container.add_child(effect)
		
	# Consume energy and update wheel
	current_energy -= energy_cost
	update_energy_wheel()
		
	# Handle shockwave logic
	var overlapping_bodies = []
	
	# Get all projectiles (includes robot bullets)
	var areas = get_tree().get_nodes_in_group("projectiles")
	for area in areas:
		if area.global_position.distance_to(global_position) <= current_shockwave_radius:
			overlapping_bodies.append(area)
	
	# Get enemy bullets
	for area in get_tree().get_nodes_in_group("enemy_bullets"):
		var parent = area.get_parent()
		if parent and parent.is_in_group("projectiles"):
			if parent.global_position.distance_to(global_position) <= current_shockwave_radius:
				overlapping_bodies.append(parent)
	
	# Get enemies
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		var distance = enemy.global_position.distance_to(global_position)
		if distance <= current_shockwave_radius:
			overlapping_bodies.append(enemy)
	
	for object in overlapping_bodies:
		# Calculate deflection direction and force
		var direction = (object.global_position - global_position).normalized()
		var distance = object.global_position.distance_to(global_position)
		var distance_factor = 1.0 - clamp(distance / current_shockwave_radius, 0.0, 1.0)
		var deflection_force = current_shockwave_force * (distance_factor * 1.3 + 0.4)
		
		if object.is_in_group("enemies"):
			object.take_knockback(direction * deflection_force)
		else:
			# Set velocity directly for non-enemy objects (projectiles)
			object.velocity = direction * deflection_force
	
	# Hide cost indicator
	energy_wheel.hide_cost()
	
	# Reset shockwave state
	is_charging_shockwave = false
	current_shockwave_radius = 0
	current_shockwave_force = shockwave_base_force
	
	# Remove range indicator
	if range_indicator:
		range_indicator.queue_free()
		range_indicator = null

func spawn_destabilizing_field() -> void:
	if !destabilizing_field_active:
		return
		
	if destabilizing_field or is_charging_shockwave or current_energy < destabilizing_field_drain_rate:
		return
		
	# Create destabilizing field
	destabilizing_field = DestabilizingField.instantiate()
	effects_container.add_child(destabilizing_field)
	destabilizing_field.fade_in()

func handle_destabilizing_field(delta: float) -> void:
	if !destabilizing_field_active:
		if destabilizing_field:
			destabilizing_field.fade_out()
			destabilizing_field = null
		time_since_last_move = 0.0
		return
		
	if is_moving or is_dashing:
		time_since_last_move = 0.0
		if destabilizing_field:
			destabilizing_field.fade_out()
			destabilizing_field = null
	else:
		time_since_last_move += delta
		if time_since_last_move >= destabilizing_field_delay and !destabilizing_field:
			destabilizing_field = DestabilizingField.instantiate()
			effects_container.add_child(destabilizing_field)

func _on_hit_box_area_entered(area: Area2D) -> void:
	if area.get_parent().has_method("is_in_lunge_state"):
		var enemy = area.get_parent()
		if enemy.is_in_lunge_state():
			take_damage()  # Use default damage amount
			enemy.has_hit_target = true
	elif area.get_parent().is_in_group("enemies"):
		var enemy = area.get_parent()
		take_damage()  # Use default damage amount

func _physics_process(delta: float) -> void:
	if not GameState.is_game_over():
		super._physics_process(delta)  # This handles knockback and basic movement
		
		# Handle human-specific abilities and states
		if is_charging_shockwave:
			charge_shockwave(delta)
		if time_since_last_move >= destabilizing_field_delay:
			spawn_destabilizing_field()
			
		# Update animations and stamina
		var movement = velocity
		if movement.x != 0 or movement.y != 0:
			if abs(movement.x) > abs(movement.y):
				pass
		else:
			if look_direction.x != 0:
				if look_direction.x > 0:
					animated_sprite.play("idle_right")
				else:
					animated_sprite.play("idle_left")
			else:
				if look_direction.y > 0:
					animated_sprite.play("idle_down")
				else:
					animated_sprite.play("idle_up")
					
		# Handle stamina regeneration
		if is_sprinting and is_moving and current_stamina > 0:
			current_stamina = max(0, current_stamina - stamina_drain_rate * delta)
		else:
			if not is_dashing:  # Don't regenerate stamina during dash
				current_stamina = min(max_stamina, current_stamina + stamina_regen_rate * delta)
				if is_exhausted and current_stamina >= max_stamina:
					is_exhausted = false
		emit_signal("stamina_changed", current_stamina, max_stamina)

func _exit_tree() -> void:
	if effects_container:
		effects_container.queue_free()

func set_invincibility_visuals(enabled: bool) -> void:
	if enabled:
		animated_sprite.modulate = Color(0.3, 0.3, 0.3, 1.0)  # Dark tint
	else:
		animated_sprite.modulate = Color.WHITE  # Normal color
