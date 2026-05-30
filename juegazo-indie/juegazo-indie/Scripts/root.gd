# root.gd
extends Node

@onready var world:           Node2D         = $Node2D
@onready var luis:            Luis           = $Node2D/Luis
@onready var input_component: InputComponent = $InputComponent

func _ready() -> void:
	input_component.attack_pressed.connect(_on_attack_pressed)

	input_component.moved.connect(luis.on_move_input)
	input_component.sprint_changed.connect(luis.on_sprint_input)
	input_component.hurt_pressed.connect(luis.on_hurt_input)
	input_component.heal_pressed.connect(luis.on_heal_input)
	SceneCombat.combat_started.connect(_on_combat_started)
	SceneCombat.combat_ended.connect(_on_combat_ended)

func _process(_delta: float) -> void:
	input_component.update()

func _on_combat_started(_data: Dictionary) -> void:
	world.hide()

func _on_combat_ended(_result: String) -> void:
	world.show()
	
func _on_attack_pressed() -> void:
	var combat_ui = get_tree().get_first_node_in_group("combat_ui")
	if is_instance_valid(combat_ui):
		combat_ui._on_attack_input()
