extends Node2D

const WHEEL_RADIUS = 20
const LINE_WIDTH = 16
const FADE_SPEED = 10.0
const PULSE_SPEED = 3.0
const OVERHEAT_PULSE_SPEED = 8.0
const GLOW_WIDTH = 3.0

# Color constants
const COLOR_NORMAL = Color(0.2, 0.2, 0.9, 0.9)  # Blue
const COLOR_WARNING = Color(0.9, 0.6, 0.2, 0.9)  # Orange
const COLOR_DANGER = Color(0.9, 0.2, 0.2, 0.9)  # Red

var current_heat: float = 0.0
var max_heat: float = 100.0
var target_alpha: float = 0.0
var current_alpha: float = 0.0
var pulse_time: float = 0.0

func _ready() -> void:
	z_index = 5
	modulate.a = 0.0
	scale.x = -1

func _process(delta: float) -> void:
	current_alpha = lerp(current_alpha, target_alpha, delta * FADE_SPEED)
	modulate.a = current_alpha
	
	var parent = get_parent()
	if parent:
		position = Vector2(70, -100)  # Position above stamina wheel
	
	var heat_ratio = current_heat / max_heat
	var current_pulse_speed = OVERHEAT_PULSE_SPEED if heat_ratio > 0.8 else PULSE_SPEED
	pulse_time += delta * current_pulse_speed
	
	queue_redraw()

func _draw() -> void:
	var heat_ratio = current_heat / max_heat
	
	# Draw background glow
	draw_arc(
		Vector2.ZERO,
		WHEEL_RADIUS + 1,
		0,
		TAU,
		128,
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
		128,
		Color(0.1, 0.1, 0.1, 0.9),
		LINE_WIDTH,
		true
	)
	
	if heat_ratio > 0:
		var fill_angle = TAU * heat_ratio
		
		# Determine color based on heat level
		var base_color
		if heat_ratio >= 0.8:
			var pulse = (sin(pulse_time) * 0.5 + 0.5) * 0.3
			base_color = Color(COLOR_DANGER.r, COLOR_DANGER.g + pulse, COLOR_DANGER.b + pulse, COLOR_DANGER.a)
		elif heat_ratio >= 0.5:
			base_color = COLOR_WARNING
		else:
			base_color = COLOR_NORMAL
		
		# Draw fill glow
		var glow_color = base_color
		glow_color.a = 0.4 + (sin(pulse_time) * 0.1)
		draw_arc(
			Vector2.ZERO,
			WHEEL_RADIUS + 1,
			-PI/2,
			-PI/2 + fill_angle,
			128,
			glow_color,
			LINE_WIDTH + GLOW_WIDTH,
			true
		)
		
		# Draw main fill
		draw_arc(
			Vector2.ZERO,
			WHEEL_RADIUS,
			-PI/2,
			-PI/2 + fill_angle,
			128,
			base_color,
			LINE_WIDTH,
			true
		)

func update_heat(new_heat: float, new_max_heat: float) -> void:
	current_heat = new_heat
	max_heat = new_max_heat
	
	if current_heat > 0:
		target_alpha = 1.0
	else:
		target_alpha = 0.0
