# SoulRewardComponent.gd
class_name SoulRewardComponent extends Node

signal souls_granted(amount: int)

@export var soul_amount: int = 0

func grant() -> void:
	souls_granted.emit(soul_amount)
