extends CanvasLayer

@onready var health_bar: ProgressBar = $PlayerHUD/Sprite2D/Health
@onready var special_bar: ProgressBar = $PlayerHUD/Sprite2D/Special

func update_human_health(health: float, max_health: float = 50.0) -> void:
	health_bar.max_value = max_health
	health_bar.value = health

func update_special(special: float, max_special: float = 50.0) -> void:
	special_bar.max_value = max_special
	special_bar.value = special
