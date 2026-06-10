# StatsComponent.gd
class_name StatsComponent extends Node

signal stats_changed(stats: Dictionary)

# ============ VALORES BASE ============
const BASE_HEALTH:    float = 50.0
const BASE_DAMAGE:    float = 5.0
const BASE_ARMOR:     float = 0.0
const BASE_REGEN:     float = 0.0
const BASE_VAMPIRISM: float = 0.0
const BASE_AGILITY:   float = 100.0  # regen_rate del ActionComponent

# ============ STATS ACTUALES ============
var max_health:  float = BASE_HEALTH
var damage:      float = BASE_DAMAGE
var armor:       float = BASE_ARMOR
var regen_vida:  float = BASE_REGEN
var vampirismo:  float = BASE_VAMPIRISM
var agility:     float = BASE_AGILITY

# ============ TABLA DE EFECTOS ============
const UPGRADE_EFFECTS: Dictionary = {
	"vida1":      {"max_health": 5.0},
	"vida2":      {"max_health": 5.0},
	"vida3":      {"max_health": 10.0},
	"vida4":      {"max_health": 10.0},
	"vida5":      {"max_health": 35.0},
	"vida6":      {"max_health": 35.0},

	"danho1":     {"damage": 1.0},
	"danho2":     {"damage": 1.0},
	"danho3":     {"damage": 2.0},
	"danho4":     {"damage": 2.0},
	"danho5":     {"damage": 7.0},
	"danho6":     {"damage": 7.0},

	"agilidad1":  {"agility": 10.0},
	"agilidad2":  {"agility": 10.0},
	"agilidad3":  {"agility": 20.0},
	"agilidad4":  {"agility": 20.0},
	"agilidad5":  {"agility": 70.0},
	"agilidad6":  {"agility": 70.0},

	"vampirismo": {"vampirismo": 5.0},
	"defensa":    {"armor": 5.0},
	"regen":      {"regen_vida": 1.0},

	# Estos no modifican stats numéricas
	"fogata":     {},
	"estrella":   {},
}


func _ready() -> void:
	reset()


func reset() -> void:
	max_health  = BASE_HEALTH
	damage      = BASE_DAMAGE
	armor       = BASE_ARMOR
	regen_vida  = BASE_REGEN
	vampirismo  = BASE_VAMPIRISM
	agility     = BASE_AGILITY
	print("[StatsComponent] Stats reseteadas a valores base")
	_emit()


func apply_upgrade(upgrade_id: String) -> void:
	if not UPGRADE_EFFECTS.has(upgrade_id):
		print("[StatsComponent] WARN: upgrade desconocido: ", upgrade_id)
		return

	var effects: Dictionary = UPGRADE_EFFECTS[upgrade_id]
	for stat in effects:
		match stat:
			"max_health": max_health  += effects[stat]
			"damage":     damage      += effects[stat]
			"armor":      armor       += effects[stat]
			"regen_vida": regen_vida  += effects[stat]
			"vampirismo": vampirismo  += effects[stat]
			"agility":    agility     += effects[stat]

	print("[StatsComponent] Aplicado %s → %s" % [upgrade_id, str(effects)])
	_emit()


func apply_upgrades_bulk(upgrade_ids: Array) -> void:
	for id in upgrade_ids:
		apply_upgrade(id)


func get_stats() -> Dictionary:
	return {
		"max_health": max_health,
		"damage":     damage,
		"armor":      armor,
		"regen_vida": regen_vida,
		"vampirismo": vampirismo,
		"agility":    agility,
	}


func _emit() -> void:
	stats_changed.emit(get_stats())
