class_name InputComponent extends Node

var is_running := false
var move_dir: Vector2 = Vector2.ZERO
var hurt_pressed := false
var heal_pressed := false

func update() -> void:
	move_dir = Input.get_vector("move_left","move_rigth","move_up","move_down")
	is_running = Input.is_action_pressed("select")
	hurt_pressed = Input.is_action_just_pressed("hurt")
	heal_pressed = Input.is_action_just_pressed("heal")
	
	
	
	
	
	
