# StaminaComponent.gd
class_name StaminaComponent extends Node

signal stamina_changed(current: float, maximum: float)
signal stamina_depleted

@export var max_stamina: float = 100.0
@export var regen_rate: float  = 5.0   # unidades por segundo

var current_stamina: float = 0.0
var is_regenerating: bool = false

func _ready() -> void:
	current_stamina = max_stamina
	stamina_changed.emit(current_stamina, max_stamina)

func set_max(value: float) -> void:
	max_stamina = value
	current_stamina = minf(current_stamina, max_stamina)
	stamina_changed.emit(current_stamina, max_stamina)

func set_regen(value: float) -> void:
	regen_rate = value

func spend(amount: float) -> bool:
	if current_stamina < amount:
		return false
	current_stamina = maxf(current_stamina - amount, 0.0)
	stamina_changed.emit(current_stamina, max_stamina)
	if current_stamina == 0.0:
		stamina_depleted.emit()
	return true

func start_regen() -> void:
	is_regenerating = true

func stop_regen() -> void:
	is_regenerating = false

func _process(delta: float) -> void:
	if not is_regenerating:
		return
	if current_stamina >= max_stamina:
		return
	current_stamina = minf(current_stamina + regen_rate * delta, max_stamina)
	stamina_changed.emit(current_stamina, max_stamina)
