class_name ResultPanel extends Control

signal rematch_requested

func show_result(result: String) -> void:
	$Label.text = "Victoria" if result == "victory" else "Derrota"
	$RematchHint.visible = result == "victory"
	show()

func _input(event: InputEvent) -> void:
	if visible and event.is_action_just_pressed("revancha"):
		rematch_requested.emit()
		SceneCombat.rematch()
