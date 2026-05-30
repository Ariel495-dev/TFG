# CombatTriggerComponent.gd
class_name CombatTriggerComponent extends Node

signal combat_requested(enemy_data: Dictionary)
signal rematch_ready

@export var area: Area2D
var _defeated := false

func _ready() -> void:
	area.body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if not body is Luis:
		return
	if _defeated:
		return  # fix: eliminado el bloque de revancha aquí, lo maneja _input solo
	var parent = get_parent()
	var data := {
		"name":      parent.enemy_name,
		"max_hp":    parent.max_hp,
		"attack":    parent.attack,
		"defense":   parent.defense,
		"xp_reward": parent.xp_reward,
		"sprite":    parent.sprite_frames,
	}
	combat_requested.emit(data)

func mark_defeated() -> void:
	_defeated = true

func _input(event: InputEvent) -> void:
	if _defeated and event.is_action_pressed("revancha"):
		rematch_ready.emit()
