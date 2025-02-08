extends Node2D

const WHEEL_RADIUS = 20
const LINE_WIDTH = 16
const FADE_SPEED = 10.0
const PULSE_SPEED = 3.0
const EXHAUSTED_PULSE_SPEED = 8.0
const PULSE_STRENGTH = 0.15
const GLOW_WIDTH = 3.0
const FLASH_DURATION = 0.5

# Color constants
const COLOR_NORMAL = Color(0.2, 0.9, 0.2, 0.9)  # Green
const COLOR_EXHAUSTED = Color(0.9, 0.2, 0.2, 0.9)  # Red

@onready var wheel_background = $WheelBackground
@onready var wheel_fill = $WheelFill

var current_stamina: float = 100.0
var max_stamina: float = 100.0
var is_exhausted: bool = false
var target_alpha: float = 0.0
var current_alpha: float = 0.0
var pulse_time: float = 0.0
var flash_intensity: float = 0.0
var should_fade_out: bool = false
var was_full: bool = true

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
		position = Vector2(70, -70)
	
	var current_pulse_speed = EXHAUSTED_PULSE_SPEED if is_exhausted else PULSE_SPEED
	pulse_time += delta * current_pulse_speed
	
	flash_intensity = move_toward(flash_intensity, 0.0, delta * 2.0)
	
	var is_full = current_stamina >= max_stamina and not is_exhausted
	if is_full and not was_full:
		flash_full()
	was_full = is_full
	
	queue_redraw()

func _draw() -> void:
	var stamina_ratio = current_stamina / max_stamina
	
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
	
	if stamina_ratio > 0:
		var fill_angle = TAU * stamina_ratio
		
		# Draw the main stamina fill (always green when fading out)
		var base_color
		if is_exhausted and target_alpha > 0:  # Only show red when not fading out
			var pulse = (sin(pulse_time) * 0.5 + 0.5) * 0.3
			base_color = Color(COLOR_EXHAUSTED.r, 0.2 + pulse, 0.2 + pulse, COLOR_EXHAUSTED.a)
		else:
			base_color = COLOR_NORMAL
		
		if flash_intensity > 0:
			base_color = base_color.lerp(Color(1, 1, 1, 1), flash_intensity)
		
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

func update_stamina(new_stamina: float, new_max_stamina: float, exhausted: bool = false) -> void:
	current_stamina = new_stamina
	max_stamina = new_max_stamina
	is_exhausted = exhausted
	
	if current_stamina < max_stamina or is_exhausted:
		target_alpha = 1.0
		should_fade_out = false

func flash_full() -> void:
	target_alpha = 1.0
	flash_intensity = 1.0
	should_fade_out = true
	
	var tween = create_tween()
	tween.tween_property(self, "flash_intensity", 0.0, FLASH_DURATION)
