class_name ProgressBarComponent extends Node

var background_bar: TextureRect
var top_bar: TextureRect
var bottom_bar: TextureRect

@export var max_value: float = 100.0
@export var current_value: float = 100.0:
	set(value):
		var old_value = current_value
		var new_value_clamped = clamp(value, 0.0, max_value)
		current_value = new_value_clamped
		_update_top_bar(current_value)
		if new_value_clamped < old_value:
			_start_bloodborne_effect(new_value_clamped, old_value)
		elif new_value_clamped > old_value:
			_update_bottom_bar(current_value)
			is_bloodborne_active = false
		value_changed.emit(current_value)

@export var bloodborne_speed: float = 250

signal value_changed(new_value: float)

var target_bottom_value: float
var is_bloodborne_active: bool = false
var bar_full_width: float = 0.0

func setup_bars(bg: TextureRect, top: TextureRect, bottom: TextureRect) -> void:
	background_bar = bg
	top_bar = top
	bottom_bar = bottom
	if top_bar:
		top_bar.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		top_bar.stretch_mode = TextureRect.STRETCH_SCALE
	if bottom_bar:
		bottom_bar.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		bottom_bar.stretch_mode = TextureRect.STRETCH_SCALE
	await Engine.get_main_loop().process_frame
	if background_bar:
		bar_full_width = background_bar.size.x
	_setup_bars()

func _setup_bars() -> void:
	if not top_bar or not bottom_bar:
		return
	_update_top_bar(max_value)
	_update_bottom_bar(max_value)

func _update_top_bar(value: float) -> void:
	if not top_bar or bar_full_width == 0.0:
		return
	var percentage = clamp(value / max_value, 0.0, 1.0)
	top_bar.size.x = bar_full_width * percentage

func _update_bottom_bar(value: float) -> void:
	if not bottom_bar or bar_full_width == 0.0:
		return
	var percentage = clamp(value / max_value, 0.0, 1.0)
	bottom_bar.size.x = bar_full_width * percentage

func _start_bloodborne_effect(new_value: float, old_value: float) -> void:
	target_bottom_value = new_value
	_update_bottom_bar(old_value)
	is_bloodborne_active = true

func _process(delta: float) -> void:
	if not is_bloodborne_active or not bottom_bar or bar_full_width == 0.0:
		return
	var current_width = bottom_bar.size.x
	var target_width = (target_bottom_value / max_value) * bar_full_width
	var new_width = move_toward(current_width, target_width, bloodborne_speed * delta)
	bottom_bar.size.x = new_width
	if abs(new_width - target_width) < 0.5:
		bottom_bar.size.x = target_width
		is_bloodborne_active = false

func set_value(new_value: float) -> void:
	current_value = new_value

func set_max(new_max: float) -> void:
	max_value = new_max
	current_value = min(current_value, max_value)
	_setup_bars()

func connect_to_health(health_component: Health_Component) -> void:
	health_component.health_changed.connect(_on_health_changed)
	set_max(health_component.max_health)
	set_value(health_component.current_health)

func _on_health_changed(current: float, max: float) -> void:
	max_value = max
	set_value(current)
