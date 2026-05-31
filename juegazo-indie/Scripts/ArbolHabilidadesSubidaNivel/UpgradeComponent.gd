class_name UpgradeComponent extends Node

signal upgrade_completed(node_name: String, cantidad: int, precio: int)
signal upgrade_requested(node_name: String, fragmentos_necesarios: int)
signal audio_play
signal audio_stop
signal audio_deny

@export var mejora_id: String = ""

var _button: Button = null
var _allowed: TextureRect = null
var _unallowed: TextureRect = null
var _cantidad_label: Label = null
var _precio_label: Label = null
var _polvo_estrella: TextureRect = null

const HOLD_TIME := 2.0
var _holding: bool = false
var _hold_progress: float = 0.0
var _unlocked: bool = false
var _blocked: bool = false
var _full_height: float = 0.0

var _deny_cooldown: float = 0.0
var _is_denied: bool = false


func _ready() -> void:
	add_to_group("mejora")
	
	for hijo in get_children():
		if hijo is Button:
			_button = hijo
			break
	
	if _button == null:
		print("[UpgradeComponent] ERROR: No se encontro Button en ", name)
		return
	
	for hijo in get_children():
		if hijo is TextureRect:
			if hijo.name == "Allowed":
				_allowed = hijo
			elif hijo.name == "Unallowed":
				_unallowed = hijo
			elif hijo.name == "polvoEstrella":
				_polvo_estrella = hijo
				_polvo_estrella.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	for hijo in get_children():
		if hijo is Label and hijo.name == "cantidad":
			_cantidad_label = hijo
			break
	
	if _polvo_estrella != null:
		for hijo in _polvo_estrella.get_children():
			if hijo is Label and hijo.name == "Precio":
				_precio_label = hijo
				break
	
	if _precio_label == null:
		for hijo in get_children():
			if hijo is Label and hijo.name == "Precio":
				_precio_label = hijo
				break
	
	if _allowed == null or _unallowed == null:
		push_error("[UpgradeComponent] Faltan Allowed o Unallowed en ", name)
		return

	_allowed.clip_contents = true
	_allowed.visible = true
	_allowed.modulate.a = 0.0
	_unallowed.modulate.a = 1.0

	await get_tree().process_frame
	_full_height = _unallowed.size.y
	_update_bar(0.0)

	if _button.button_down.is_connected(_on_button_down):
		_button.button_down.disconnect(_on_button_down)
	if _button.button_up.is_connected(_on_button_up):
		_button.button_up.disconnect(_on_button_up)
	
	_button.button_down.connect(_on_button_down)
	_button.button_up.connect(_on_button_up)
	
	_button.mouse_filter = Control.MOUSE_FILTER_STOP
	
	if mejora_id.is_empty():
		mejora_id = name


func _process(delta: float) -> void:
	if _is_denied:
		_deny_cooldown -= delta
		if _deny_cooldown <= 0.0:
			_is_denied = false
			_blocked = false
	
	if _holding:
		_hold_progress += delta / HOLD_TIME
		_hold_progress = clamp(_hold_progress, 0.0, 1.0)
		_update_bar(_hold_progress)
		
		if _allowed != null and _unallowed != null:
			_allowed.modulate.a = _hold_progress
			_unallowed.modulate.a = 1.0 - _hold_progress
		
		if _hold_progress >= 1.0:
			_holding = false
			_complete()


func _on_button_down() -> void:
	if _unlocked or _blocked:
		return
	
	if mejora_id.is_empty():
		return
	
	var precio := _get_precio()
	upgrade_requested.emit(mejora_id, precio)


func _on_button_up() -> void:
	if _holding:
		_cancel()


func allow_unlock() -> void:
	if _unlocked or _blocked:
		return
	
	audio_play.emit()
	_holding = true
	_hold_progress = 0.0


func deny_unlock() -> void:
	audio_deny.emit()  # ← Ahora esta señal existe
	_cancel()
	_is_denied = true
	_deny_cooldown = 0.5
	_blocked = true


func _update_bar(t: float) -> void:
	if _allowed == null:
		return
	_allowed.size = Vector2(_allowed.size.x, _full_height * t)


func _cancel() -> void:
	_holding = false
	_hold_progress = 0.0
	_update_bar(0.0)
	
	if _allowed != null:
		_allowed.modulate.a = 0.0
	if _unallowed != null:
		_unallowed.modulate.a = 1.0
	
	audio_stop.emit()


func _complete() -> void:
	_unlocked = true
	_update_bar(1.0)
	
	if _allowed != null:
		_allowed.modulate.a = 1.0
	if _unallowed != null:
		_unallowed.modulate.a = 0.0
	
	var cantidad := _get_cantidad()
	var precio := _get_precio()
	
	audio_stop.emit()
	upgrade_completed.emit(mejora_id, cantidad, precio)


func _get_cantidad() -> int:
	if _cantidad_label != null:
		var texto = _cantidad_label.text
		if texto.is_valid_int():
			return int(texto)
	return 0


func _get_precio() -> int:
	if _precio_label != null:
		var texto = _precio_label.text
		if texto.is_valid_int():
			return int(texto)
	return 0


func set_blocked(value: bool) -> void:
	_blocked = value


func reset_visual() -> void:
	if not _unlocked:
		_holding = false
		_hold_progress = 0.0
		_update_bar(0.0)
		_is_denied = false
		_blocked = false
		
		if _allowed != null:
			_allowed.modulate.a = 0.0
		if _unallowed != null:
			_unallowed.modulate.a = 1.0
