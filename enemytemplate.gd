extends CharacterBody2D


@onready var interactable: Area2D = $interactable
@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var floatingnumbers: Marker2D = $FloatingNumbers
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	interactable.health = 2
	interactable.interact = _on_interact
	

func _on_interact():
	print("Enemy is interacted with")
	
	if interactable.health == 0:
		queue_free()
	else:
		interactable.health -= get_node("/root/Level1/Player").strength
		
		floatingnumbers.popup()

const SPEED = 300.0
const JUMP_VELOCITY = -400.0


#func _physics_process(delta: float) -> void:
	## Add the gravity.
	#if not is_on_floor():
		#velocity += get_gravity() * delta
#
	## Handle jump.
	#if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		#velocity.y = JUMP_VELOCITY
#
	## Get the input direction and handle the movement/deceleration.
	## As good practice, you should replace UI actions with custom gameplay actions.
	#var direction := Input.get_axis("ui_left", "ui_right")
	#if direction:
		#velocity.x = direction * SPEED
	#else:
		#velocity.x = move_toward(velocity.x, 0, SPEED)
#
	#move_and_slide()
