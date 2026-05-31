class_name UpgradeComponent extends Node

signal upgrade_completed(node_name: String, cantidad: int)

@export var audio_stream: AudioStream = null

@onready var area:      Area2D      = get_parent().get_node("Area2D")
@onready var allowed:   TextureRect = get_parent().get_node("Allowed")
@onready var unallowed: TextureRect = get_parent().get_node("Unallowed")
@onready var cantidad_label: Label  = get_parent().get_node("polvoEstrella/cantidad")
@onready var precio_label:   Label  = get_parent().get_node("polvoEstrella/Precio")

const HOLD_TIME := 2.0

var _holding:  bool  = false
var _progress: float = 0.0
var _unlocked: bool  = false
var _audio:    AudioStreamPlayer = null

func _ready() -> void:
	allowed.clip_contents = true
	allowed.visible = true
	_update_bar(0.0)

	if audio_stream != null:
		_audio = AudioStreamPlayer.new()
		_audio.stream = audio_stream
		add_child(_audio)

	area.input_pickable = true
	area.input_event.connect(_on_input_event)

func _process(delta: float) -> void:
	if not _holding:
		return
	_progress += delta / HOLD_TIME
	_progress = clamp(_progress, 0.0, 1.0)
	_update_bar(_progress)
	if _progress >= 1.0:
		_holding = false
		_complete()

func _on_input_event(_viewport, event: InputEvent, _shape_idx: int) -> void:
	if _unlocked:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			var precio  := int(precio_label.text)
			var fragmentos := _get_fragmentos()
			if not ArbolHabilidades.can_unlock(get_parent().name, fragmentos, precio):
				return
			_holding = true
			if _audio != null:
				_audio.play()
		else:
			if _holding:
				_cancel()

func _update_bar(t: float) -> void:
	var full_height: float = unallowed.size.y
	allowed.size = Vector2(allowed.size.x, full_height * t)

func _cancel() -> void:
	_holding  = false
	_progress = 0.0
	_update_bar(0.0)
	if _audio != null and _audio.playing:
		_audio.stop()

func _complete() -> void:
	_unlocked = true
	_update_bar(1.0)
	if _audio != null and _audio.playing:
		_audio.stop()
	var cantidad := int(cantidad_label.text)
	ArbolHabilidades.unlock(get_parent().name)
	upgrade_completed.emit(get_parent().name, cantidad)

func _get_fragmentos() -> int:
	var luis = get_tree().get_first_node_in_group("player")
	if is_instance_valid(luis):
		return luis.fragmentos
	return 0
