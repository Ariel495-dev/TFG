# TurnComponent.gd
class_name TurnComponent extends Node

signal player_turn_started
signal enemy_turn_started
signal turns_paused
signal turns_resumed

var _paused: bool = false
var _player_ready: bool = false
var _enemy_ready: bool  = false

func notify_player_ready() -> void:
	if _paused:
		return
	_player_ready = true
	# Jugador tiene prioridad si coinciden
	_paused = true
	turns_paused.emit()
	player_turn_started.emit()

func notify_enemy_ready() -> void:
	if _paused:
		return
	_enemy_ready = true
	_paused = true
	turns_paused.emit()
	enemy_turn_started.emit()

func resume_after_player() -> void:
	_player_ready = false
	_enemy_ready  = false
	_paused = false
	turns_resumed.emit()

func resume_after_enemy() -> void:
	_player_ready = false
	_enemy_ready  = false
	_paused = false
	turns_resumed.emit()

func pause_all() -> void:
	_paused = true
	turns_paused.emit()

func reset() -> void:
	_paused       = false
	_player_ready = false
	_enemy_ready  = false
