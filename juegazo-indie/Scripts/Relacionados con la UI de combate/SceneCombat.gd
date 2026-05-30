# SceneCombat.gd — Autoload
extends Node

signal combat_started(enemy_data: Dictionary)
signal combat_ended(result: String)
signal combat_rematch

const COMBAT_UI_SCENE = preload("res://escenas/combat_ui.tscn")

var _enemy_ref:     Node        = null
var _enemy_data:    Dictionary  = {}
var _combat_active: bool        = false
var _combat_ui:     CanvasLayer = null
var _luis_ref:      Luis        = null

func start(data: Dictionary, enemy_node: Node) -> void:
	if _combat_active:
		return
	_enemy_ref     = enemy_node
	_enemy_data    = data.duplicate()
	_luis_ref      = get_tree().get_first_node_in_group("player")
	_combat_active = true

	_luis_ref.action_component.process_mode   = Node.PROCESS_MODE_ALWAYS
	_enemy_ref.action_component.process_mode  = Node.PROCESS_MODE_ALWAYS
	_luis_ref.stamina_component.process_mode  = Node.PROCESS_MODE_ALWAYS
	_enemy_ref.stamina_component.process_mode = Node.PROCESS_MODE_ALWAYS

	get_tree().paused = true
	combat_started.emit(_enemy_data)

	_combat_ui = COMBAT_UI_SCENE.instantiate()
	_combat_ui.process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().root.add_child(_combat_ui)
	_combat_ui.initialize(data, _luis_ref)

func resolve(result: String) -> void:
	if not _combat_active:
		return
	_combat_active = false
	get_tree().paused = false

	if is_instance_valid(_combat_ui):
		_combat_ui.return_sprite_to_enemy()
		_combat_ui.queue_free()
		_combat_ui = null

	combat_ended.emit(result)

func rematch() -> void:
	if _combat_active:
		return
	combat_rematch.emit()

func _exit_tree() -> void:
	if _combat_active:
		get_tree().paused = false
