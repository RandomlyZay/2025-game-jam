extends CanvasLayer

@onready var health_bar: ProgressBar = $PlayerHUD/Health

func update_human_health(health: float, max_health: float = 50.0) -> void:
	health_bar.max_value = max_health
	health_bar.value = health
