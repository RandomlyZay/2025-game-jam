extends CanvasLayer

@onready var health_bar: ProgressBar = $PlayerHUD/Health

func update_human_health(health: int) -> void:
	health_bar.value = health
