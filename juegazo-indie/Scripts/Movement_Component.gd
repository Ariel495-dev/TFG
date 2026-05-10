class_name Movement_Component extends Node

@export var body:CharacterBody2D 
@export var model: AnimatedSprite2D
@export var speed := 800.0
@export var sprint_speed := 3200.0

var direction: Vector2 = Vector2.ZERO
var wants_sprint := false

func tick(delta:float) -> void:
	if body == null:
		return
	
	# MOVIMIENTO - Estas líneas ahora están fuera del if
	body.velocity.x = direction.x * speed  
	body.velocity.y = direction.y * speed
	
	# Run
	if wants_sprint:
		
		body.velocity.x = direction.x * sprint_speed  
		body.velocity.y = direction.y * sprint_speed
		
	
	
	body.move_and_slide()
