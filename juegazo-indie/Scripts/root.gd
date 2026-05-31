extends Node

@onready var world:           Node2D         = $Node2D
@onready var luis:            Luis           = $Node2D/Luis
@onready var input_component: InputComponent = $InputComponent

func _ready() -> void:
	print("[Root] Inicializando")
	process_mode = Node.PROCESS_MODE_ALWAYS
	input_component.process_mode = Node.PROCESS_MODE_ALWAYS

	input_component.attack_pressed.connect(_on_attack_pressed)
	input_component.rematch_pressed.connect(_on_rematch_pressed)
	input_component.moved.connect(luis.on_move_input)
	input_component.sprint_changed.connect(luis.on_sprint_input)

	SceneCombat.combat_started.connect(_on_combat_started)
	SceneCombat.combat_ended.connect(_on_combat_ended)
	print("[Root] Listo")

func _process(_delta: float) -> void:
	input_component.update()

func _on_combat_started(_data: Dictionary) -> void:
	world.hide()

func _on_combat_ended(_result: String) -> void:
	world.show()

func _on_attack_pressed() -> void:
	var combat_ui = get_tree().get_first_node_in_group("combat_ui")
	if is_instance_valid(combat_ui):
		combat_ui.on_attack_pressed()

func _on_rematch_pressed() -> void:
	var combat_ui = get_tree().get_first_node_in_group("combat_ui")
	if is_instance_valid(combat_ui) and combat_ui.visible:
		var result_panel = combat_ui.get_node("ResultPanel")
		if is_instance_valid(result_panel) and result_panel.visible:
			result_panel.rematch_requested.emit()
