class_name TurnComponent extends Node

signal player_turn_started
signal enemy_turn_started

enum TurnState { IDLE, WAITING_TURN, PLAYER_TURN, ENEMY_TURN }

var _state: TurnState = TurnState.IDLE
var _player_ready: bool = false
var _enemy_ready: bool = false

func _ready() -> void:
	print("[TurnComponent] Inicializado")

func start_waiting() -> void:
	_state = TurnState.WAITING_TURN
	_player_ready = false
	_enemy_ready = false
	print("[TurnComponent] Esperando que alguien esté listo")
	_check_turn()

func notify_player_ready() -> void:
	print("[TurnComponent] Player ready. Estado: ", _state)
	if _state != TurnState.WAITING_TURN:
		print("[TurnComponent] Ignorado, no estamos esperando")
		return
	_player_ready = true
	_check_turn()

func notify_enemy_ready() -> void:
	print("[TurnComponent] Enemy ready. Estado: ", _state)
	if _state != TurnState.WAITING_TURN:
		print("[TurnComponent] Ignorado, no estamos esperando")
		return
	_enemy_ready = true
	_check_turn()

func _check_turn() -> void:
	if _state != TurnState.WAITING_TURN:
		return
	# Si ambos llegan a la vez, el jugador tiene prioridad
	if _player_ready:
		_state = TurnState.PLAYER_TURN
		_player_ready = false
		_enemy_ready = false
		print("[TurnComponent] → TURNO JUGADOR")
		player_turn_started.emit()
	elif _enemy_ready:
		_state = TurnState.ENEMY_TURN
		_player_ready = false
		_enemy_ready = false
		print("[TurnComponent] → TURNO ENEMIGO")
		enemy_turn_started.emit()

func resume_after_player() -> void:
	print("[TurnComponent] Fin turno jugador, volviendo a espera")
	_state = TurnState.WAITING_TURN
	_player_ready = false
	_enemy_ready = false
	_check_turn()

func resume_after_enemy() -> void:
	print("[TurnComponent] Fin turno enemigo, volviendo a espera")
	_state = TurnState.WAITING_TURN
	_player_ready = false
	_enemy_ready = false
	_check_turn()
