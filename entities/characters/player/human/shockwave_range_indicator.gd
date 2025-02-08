extends Node2D

var num_points = 32  # Number of points in the circle
var radius = 100.0  # Will be set by the player

func _ready() -> void:
    update_circle()
    queue_redraw()

func _draw() -> void:
    pass

func update_circle() -> void:
    var circle = $Circle
    circle.clear_points()
    
    # Generate points for the circle
    for i in range(num_points + 1):
        var angle = i * 2 * PI / num_points
        var point = Vector2(cos(angle), sin(angle)) * radius
        circle.add_point(point)

func set_radius(new_radius: float) -> void:
    radius = new_radius
    update_circle()
    queue_redraw()
