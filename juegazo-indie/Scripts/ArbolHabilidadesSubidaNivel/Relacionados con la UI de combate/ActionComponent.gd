# ActionComponent.gd
class_name ActionComponent extends Node

signal action_changed(current: float, max: float)
signal action_ready
signal regen_rate_changed(new_rate: float)

const MAX_ACTION: float = 100.0

var current_action: float  = 0.0
var regen_rate:     float  = 300.0
var _is_filling:    bool   = false
var _is_paused:     bool   = false
var _was_ready_emitted: bool = false
var _skip_frame:    bool   = false


func initialize(p_regen_rate: float = 300.0) -> void:
	print("[ActionComponent] Initialize con regen_rate=", p_regen_rate)
	regen_rate         = p_regen_rate
	current_action     = 0.0
	_was_ready_emitted = false
	_skip_frame        = false
	_emit()


func _ready() -> void:
	current_action     = 0.0
	_was_ready_emitted = false
	_skip_frame        = false
	_emit()


func _process(delta: float) -> void:
	if not _is_filling or _is_paused:
		return

	if _skip_frame:
		print("[ActionComponent] >>> SKIP FRAME EJECUTADO delta=", delta)
		_skip_frame = false
		return

	if current_action < MAX_ACTION:
		var previous := current_action
		current_action = min(current_action + regen_rate * delta, MAX_ACTION)
		if int(previous) != int(current_action):
			_emit()
		if not _was_ready_emitted and current_action >= MAX_ACTION:
			_was_ready_emitted = true
			print("[ActionComponent] Action ready! current_action=", current_action)
			action_ready.emit()
	elif not _was_ready_emitted:
		_was_ready_emitted = true
		print("[ActionComponent] Action ready (already full)! current_action=", current_action)
		action_ready.emit()


func start_filling() -> void:
	print("[ActionComponent] Start filling, current_action=", current_action)
	_is_filling        = true
	_is_paused         = false
	_was_ready_emitted = false
	_skip_frame        = true
	print("[ActionComponent] >>> _skip_frame=TRUE tras start_filling")


func stop_filling() -> void:
	print("[ActionComponent] Stop filling")
	_is_filling = false


func pause_filling() -> void:
	print("[ActionComponent] Pause filling, current_action=", current_action)
	_is_paused = true


func resume_filling() -> void:
	print("[ActionComponent] Resume filling, current_action=", current_action)
	_is_paused  = false
	_skip_frame = true
	print("[ActionComponent] >>> _skip_frame=TRUE tras resume_filling")


func reset() -> void:
	print("[ActionComponent] Reset")
	current_action     = 0.0
	_was_ready_emitted = false
	_skip_frame        = false
	_emit()


func consume() -> void:
	print("[ActionComponent] Consume, current_action antes=", current_action)
	current_action     = 0.0
	_was_ready_emitted = false
	_skip_frame        = false
	_emit()
	print("[ActionComponent] Consume completado, current_action despues=", current_action)


func set_value(value: float) -> void:
	current_action = clamp(value, 0.0, MAX_ACTION)
	if current_action < MAX_ACTION:
		_was_ready_emitted = false
	_emit()


func set_regen(value: float) -> void:
	print("[ActionComponent] Set regen rate to ", value)
	regen_rate = value
	regen_rate_changed.emit(regen_rate)


func _emit() -> void:
	action_changed.emit(current_action, MAX_ACTION)
