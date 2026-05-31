# StaminaComponent.gd
class_name StaminaComponent extends Node

signal stamina_changed(current: float, max: float)
signal stamina_depleted
signal regen_rate_changed(new_rate: float)

var max_stamina: float = 100.0
var current_stamina: float = 0.0
var regen_rate: float = 80.0

var _is_regening: bool = false
var _is_paused: bool = false

func initialize(p_max_stamina: float, p_regen_rate: float = 80.0) -> void:
	print("[StaminaComponent] Initialize max=", p_max_stamina, " regen=", p_regen_rate)
	max_stamina = p_max_stamina
	regen_rate = p_regen_rate
	current_stamina = 0.0
	_emit()

func _ready() -> void:
	current_stamina = 0.0
	_emit()

func _process(delta: float) -> void:
	if _is_regening and not _is_paused and current_stamina < max_stamina:
		var previous = current_stamina
		current_stamina = min(current_stamina + regen_rate * delta, max_stamina)
		if previous != current_stamina:
			_emit()

func start_regen() -> void:
	print("[StaminaComponent] Start regen")
	_is_regening = true
	_is_paused = false

func stop_regen() -> void:
	print("[StaminaComponent] Stop regen")
	_is_regening = false

func pause_regen() -> void:
	print("[StaminaComponent] Pause regen")
	_is_paused = true

func resume_regen() -> void:
	print("[StaminaComponent] Resume regen")
	_is_paused = false

func reset() -> void:
	print("[StaminaComponent] Reset")
	current_stamina = 0.0
	_emit()

func spend(amount: float) -> bool:
	print("[StaminaComponent] Spend ", amount, ", current=", current_stamina)
	if current_stamina >= amount:
		current_stamina -= amount
		_emit()
		if current_stamina == 0.0:
			print("[StaminaComponent] Stamina depleted")
			stamina_depleted.emit()
		return true
	print("[StaminaComponent] Not enough stamina")
	return false

func set_max(value: float) -> void:
	print("[StaminaComponent] Set max to ", value)
	max_stamina = value
	current_stamina = min(current_stamina, max_stamina)
	_emit()

func set_regen(value: float) -> void:
	print("[StaminaComponent] Set regen to ", value)
	regen_rate = value
	regen_rate_changed.emit(regen_rate)

func _emit() -> void:
	stamina_changed.emit(current_stamina, max_stamina)
