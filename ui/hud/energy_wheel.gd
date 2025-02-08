extends Node2D

const WHEEL_RADIUS = 20
const LINE_WIDTH = 16
const FADE_SPEED = 10.0
const PULSE_SPEED = 3.0
const PULSE_STRENGTH = 0.15
const GLOW_WIDTH = 3.0
const FLASH_DURATION = 0.5

# Color constants
const COLOR_NORMAL = Color(0.2, 0.6, 1.0, 0.9)  # Lighter blue
const COLOR_COST = Color(1.0, 0.8, 0.2, 0.9)  # Yellow

@onready var wheel_background = $WheelBackground
@onready var wheel_fill = $WheelFill

var current_energy: float = 100.0
var max_energy: float = 100.0
var current_cost: float = 0.0
var max_cost: float = 100.0
var showing_cost: bool = false
var target_alpha: float = 0.0
var current_alpha: float = 0.0
var pulse_time: float = 0.0
var flash_intensity: float = 0.0
var should_fade_out: bool = false
var was_full: bool = true

# Cost bar variables

func _ready() -> void:
	z_index = 5
	modulate.a = 0.0
	scale.x = -1

func _process(delta: float) -> void:
	if should_fade_out and flash_intensity <= 0:
		target_alpha = 0.0
		should_fade_out = false
	
	current_alpha = lerp(current_alpha, target_alpha, delta * FADE_SPEED)
	modulate.a = current_alpha
	
	var parent = get_parent()
	if parent:
		position = Vector2(-70, -70)  # Mirror of stamina wheel position
	
	pulse_time += delta * PULSE_SPEED
	
	flash_intensity = move_toward(flash_intensity, 0.0, delta * 2.0)
	
	var is_full = current_energy >= max_energy and not showing_cost
	if is_full and not was_full:
		flash_full()
	was_full = is_full
	
	queue_redraw()

func _draw() -> void:
	var energy_ratio = current_energy / max_energy
	var energy_angle = TAU * energy_ratio
	
	# Draw background glow
	draw_arc(
		Vector2.ZERO,
		WHEEL_RADIUS + 1,
		0,
		TAU,
		32,
		Color(0.1, 0.1, 0.1, 0.3),
		LINE_WIDTH + 2,
		true
	)
	
	# Draw main background
	draw_arc(
		Vector2.ZERO,
		WHEEL_RADIUS,
		0,
		TAU,
		32,
		Color(0.1, 0.1, 0.1, 0.9),
		LINE_WIDTH,
		true
	)
	
	if energy_ratio > 0:
		# Draw the main energy fill
		var base_color = COLOR_NORMAL
		if flash_intensity > 0:
			base_color = base_color.lerp(Color(1, 1, 1, 1), flash_intensity)
		
		# Draw fill glow
		var glow_color = base_color
		glow_color.a = 0.4 + (sin(pulse_time) * 0.1)
		draw_arc(
			Vector2.ZERO,
			WHEEL_RADIUS + 1,
			-PI/2,
			-PI/2 + energy_angle,
			32,
			glow_color,
			LINE_WIDTH + GLOW_WIDTH,
			true
		)
		
		# Draw main fill
		draw_arc(
			Vector2.ZERO,
			WHEEL_RADIUS,
			-PI/2,
			-PI/2 + energy_angle,
			32,
			base_color,
			LINE_WIDTH,
			true
		)
		
		# Draw cost indicator if charging
		if showing_cost and current_cost > 0:
			# Calculate cost ratio based on current cost relative to max energy
			var cost_ratio = min(current_cost, max_energy) / max_energy
			var cost_angle = TAU * cost_ratio
			
			# Calculate start and end angles to show where energy will end up
			var energy_end = -PI/2 + energy_angle
			var cost_start = energy_end - cost_angle  # Go backwards by cost amount
			var cost_end = energy_end  # End at current energy level
			
			# Draw cost arc with same thickness as energy arc
			draw_arc(
				Vector2.ZERO,
				WHEEL_RADIUS,
				cost_start,
				cost_end,
				32,
				Color(1.0, 1.0, 0.0),  # Yellow
				LINE_WIDTH,
				true
			)
			
			# Draw cost glow
			var cost_glow_color = Color(1.0, 1.0, 0.0)
			cost_glow_color.a = 0.4 + (sin(pulse_time) * 0.1)
			draw_arc(
				Vector2.ZERO,
				WHEEL_RADIUS,
				cost_start,
				cost_end,
				32,
				cost_glow_color,
				LINE_WIDTH + 4,
				true
			)

func update_energy(new_energy: float, new_max_energy: float) -> void:
	current_energy = new_energy
	max_energy = new_max_energy
	
	if current_energy < max_energy:
		target_alpha = 1.0
		should_fade_out = false
	
	queue_redraw()

func update_cost(cost: float, max_cost_value: float) -> void:
	current_cost = cost
	max_cost = max_cost_value
	showing_cost = current_cost > 0
	
	if showing_cost:
		target_alpha = 1.0
		should_fade_out = false
	
	queue_redraw()

func hide_cost() -> void:
	showing_cost = false
	should_fade_out = true
	queue_redraw()

func flash_full() -> void:
	target_alpha = 1.0
	flash_intensity = 1.0
	should_fade_out = true
	
	var tween = create_tween()
	tween.tween_property(self, "flash_intensity", 0.0, FLASH_DURATION)
