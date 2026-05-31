class_name ResultPanel extends Control

signal rematch_requested
signal timeout_exit

var _timer: Timer = null
var _is_victory: bool = false

func show_result(result: String) -> void:
	_is_victory = result == "victory"
	$Label.text = "Victoria" if _is_victory else "Derrota"
	# RematchHint ahora muestra el texto solo en victoria
	$RematchHint.visible = _is_victory
	if _is_victory:
		$RematchHint.text = "Pulsa R para revancha"
	show()
	_start_timer()

func _start_timer() -> void:
	if is_instance_valid(_timer):
		_timer.queue_free()
	_timer = Timer.new()
	add_child(_timer)
	_timer.wait_time = 2.0
	_timer.one_shot = true
	_timer.timeout.connect(_on_timeout)
	_timer.start()

func _on_timeout() -> void:
	# Si el jugador no pulsó R a tiempo, salir
	timeout_exit.emit()
