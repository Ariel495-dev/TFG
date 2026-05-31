class_name InputComponent extends Node

signal moved(direction: Vector2)
signal sprint_changed(is_running: bool)
signal hurt_pressed
signal heal_pressed
signal attack_pressed
signal rematch_pressed
signal volver_pressed
signal ver_arbol_pressed

var is_running := false
var move_dir: Vector2 = Vector2.ZERO

func update() -> void:
	move_dir = Input.get_vector("move_left", "move_rigth", "move_up", "move_down")
	is_running = Input.is_action_pressed("select")
	moved.emit(move_dir)
	sprint_changed.emit(is_running)
	if Input.is_action_just_pressed("hurt"):
		hurt_pressed.emit()
		attack_pressed.emit()
	if Input.is_action_just_pressed("heal"):
		heal_pressed.emit()
	if Input.is_action_just_pressed("revancha"):
		rematch_pressed.emit()
	if Input.is_action_just_pressed("volver"):
		volver_pressed.emit()
	if Input.is_action_just_pressed("ver_arbol"):
		ver_arbol_pressed.emit()
