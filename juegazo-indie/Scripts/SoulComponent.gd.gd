# SoulComponent.gd
class_name SoulComponent extends Node

signal souls_changed(current: int)

var current_souls: int = 0

func add(amount: int) -> void:
	current_souls += amount
	souls_changed.emit(current_souls)

func spend(amount: int) -> bool:
	if current_souls < amount:
		return false
	current_souls -= amount
	souls_changed.emit(current_souls)
	return true
