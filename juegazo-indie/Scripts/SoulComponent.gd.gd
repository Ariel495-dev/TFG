class_name SoulComponent extends Node

signal souls_changed(current: int)

var current_souls: int = 10000000000

func add(amount: int) -> void:
	current_souls += amount
	souls_changed.emit(current_souls)
	print("[SoulComponent] Añadidos ", amount, " fragmentos. Total: ", current_souls)

func spend(amount: int) -> bool:
	if current_souls < amount:
		print("[SoulComponent] No hay suficientes fragmentos. Tienes: ", current_souls, " Necesitas: ", amount)
		return false
	current_souls -= amount
	souls_changed.emit(current_souls)
	print("[SoulComponent] Gastados ", amount, " fragmentos. Restantes: ", current_souls)
	return true

func get_souls() -> int:
	return current_souls

func set_souls(amount: int) -> void:
	current_souls = max(0, amount)
	souls_changed.emit(current_souls)
	print("[SoulComponent] Fragmentos establecidos a: ", current_souls)
