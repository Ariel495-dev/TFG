extends Node
#este es root
@onready var combate = $CombatUI
@onready var input_component: InputComponent = $InputComponent
@onready var luis: Luis = $Node2D/Luis
func _ready() -> void:
	combate.hide()
	combate.set_process(false)
	input_component.moved.connect(luis.on_move_input)
	input_component.sprint_changed.connect(luis.on_sprint_input)
	input_component.hurt_pressed.connect(luis.on_hurt_input)
	input_component.heal_pressed.connect(luis.on_heal_input)
	
func _process(_delta: float) -> void:
	input_component.update()
