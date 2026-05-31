# Recursos.gd
extends CanvasLayer

@onready var xp_label:        Label = $Experiencia/Label
@onready var polvo_label:     Label = $PolvoEstrellas/Label
@onready var estrellas_label: Label = $Estrella/Label

func _ready() -> void:
	await get_tree().process_frame
	var luis: Luis = get_tree().get_first_node_in_group("player")
	if luis == null:
		push_error("[Recursos] Luis no encontrado")
		return
	luis.soul_component.souls_changed.connect(_on_souls_changed)
	luis.experience_component.xp_changed.connect(_on_xp_changed)
	_on_souls_changed(luis.get_fragmentos())
	_on_xp_changed(luis.experience_component.current_xp, luis.experience_component.xp_to_next)
	estrellas_label.text = str(luis.estrellas)

func _on_souls_changed(current: int) -> void:
	polvo_label.text = str(current)

func _on_xp_changed(current: float, _to_next: float) -> void:
	xp_label.text = str(int(current))

func update_estrellas(value: int) -> void:
	estrellas_label.text = str(value)
