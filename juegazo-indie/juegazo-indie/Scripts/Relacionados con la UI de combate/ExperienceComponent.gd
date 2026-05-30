# ExperienceComponent.gd
class_name ExperienceComponent extends Node

signal xp_granted(amount: float)

@export var xp_amount: float = 0.0

func grant() -> void:
	xp_granted.emit(xp_amount)
