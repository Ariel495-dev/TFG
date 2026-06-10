class_name ExperienceComponent extends Node

signal xp_changed(current: float, to_next: float)
signal level_up(new_level: int)

const BASE_XP: float = 20.0
const LEVEL_MULTIPLIER: float = 1.10

var current_xp:    float = 0.0
var level:         int   = 0
var xp_to_next:    float = BASE_XP

func grant(amount: float) -> void:
	current_xp += amount
	_check_level_up()
	xp_changed.emit(current_xp, xp_to_next)

func _check_level_up() -> void:
	while current_xp >= xp_to_next:
		current_xp -= xp_to_next
		level += 1
		xp_to_next = BASE_XP * pow(LEVEL_MULTIPLIER, level)
		level_up.emit(level)

func reset() -> void:
	current_xp = 0.0
	level      = 0
	xp_to_next = BASE_XP
	xp_changed.emit(current_xp, xp_to_next)
