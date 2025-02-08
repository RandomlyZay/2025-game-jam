extends Node2D

func _ready() -> void:
	$AnimationPlayer.play("shockwave")
	await $AnimationPlayer.animation_finished
	queue_free()
