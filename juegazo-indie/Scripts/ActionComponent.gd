# ActionComponent.gd
class_name ActionComponent extends Node

signal action_ready
signal action_changed(current: float, maximum: float)

const ACTION_MAX: float = 100.0

@export var regen_rate: float = 20.0  # unidades por segundo

var current_action: float = 0.0
var is_ready: bool = false
var is_filling: bool = false

func start_filling() -> void:
	current_action = 0.0
	is_ready = false
	is_filling = true
	action_changed.emit(current_action, ACTION_MAX)

func stop_filling() -> void:
	is_filling = false

func _process(delta: float) -> void:
	if not is_filling or is_ready:
		return
	current_action = minf(current_action + regen_rate * delta, ACTION_MAX)
	action_changed.emit(current_action, ACTION_MAX)
	if current_action >= ACTION_MAX:
		is_ready = true
		is_filling = false
		action_ready.emit()

func consume() -> void:
	current_action = 0.0
	is_ready = false
	action_changed.emit(current_action, ACTION_MAX)
