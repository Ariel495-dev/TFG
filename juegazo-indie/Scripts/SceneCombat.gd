# SceneCombat.gd — solo emite, no sabe que existe CombatUI
extends Node

signal combat_started(enemy_data: Dictionary)
signal combat_ended(result: String)
signal combat_rematch

var _enemy_ref: Node = null
var _enemy_data: Dictionary = {}

func start(data: Dictionary, enemy_node: Node) -> void:
	_enemy_ref = enemy_node
	_enemy_data = data
	get_tree().paused = true
	combat_started.emit(data)      # ← CombatUI escucha esto

func resolve(result: String) -> void:
	get_tree().paused = false
	combat_ended.emit(result)      # ← CombatUI escucha esto
	if result == "victory" and _enemy_ref:
		_enemy_ref.health_component.died.emit()

func rematch() -> void:
	combat_rematch.emit()          # ← CombatUI escucha esto
