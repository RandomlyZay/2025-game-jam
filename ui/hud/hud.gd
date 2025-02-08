extends CanvasLayer

@onready var human_health_bar: ProgressBar = $PlayerHUD/HumanHealth
@onready var human_stamina_bar: ProgressBar = $PlayerHUD/HumanStamina
@onready var energy_wheel: Node2D = $EnergyWheel

func set_human_stamina(new_stamina: float, max_stamina: float) -> void:
	human_stamina_bar.max_value = max_stamina
	human_stamina_bar.value = new_stamina

func update_human_health(health: int) -> void:
	human_health_bar.value = health

func update_energy(new_energy: float, new_max_energy: float, exhausted: bool = false) -> void:
	if energy_wheel:
		energy_wheel.update_energy(new_energy, new_max_energy, exhausted)
