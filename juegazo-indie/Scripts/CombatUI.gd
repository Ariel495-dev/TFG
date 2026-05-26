# CombatUI.gd — CanvasLayer
class_name CombatUI extends CanvasLayer

@onready var result_panel: ResultPanel                   = $ResultPanel
@onready var health_bar_enemy: ProgressBarComponent      = $EnemyHealthBar
@onready var health_bar_player: ProgressBarComponent     = $PlayerHealthBar
@onready var mana_bar_player: ProgressBarComponent       = $PlayerManaBar
@onready var enemy_name_label: Label                     = $EnemyName
@onready var action_buttons: Control                     = $ActionButtons
@onready var log_label: Label                            = $LogLabel

func _ready() -> void:
	SceneCombat.combat_started.connect(_on_combat_started)
	SceneCombat.combat_ended.connect(_on_combat_ended)
	SceneCombat.combat_rematch.connect(_on_rematch)
	result_panel.rematch_requested.connect(_on_rematch_requested)
	hide()

func _on_combat_started(data: Dictionary) -> void:
	_initialize(data)
	show()

func _on_combat_ended(result: String) -> void:
	action_buttons.hide()
	result_panel.show_result(result)

func _on_rematch() -> void:
	_reset()
	show()

func _on_rematch_requested() -> void:
	SceneCombat.rematch()

func _initialize(data: Dictionary) -> void:
	enemy_name_label.text   = data.get("name", "Enemigo")
	health_bar_enemy.set_max(data.get("max_hp", 100.0))
	health_bar_enemy.set_value(data.get("max_hp", 100.0))
	result_panel.hide()
	action_buttons.show()
	log_label.text = "¡El combate ha comenzado!"

func _reset() -> void:
	result_panel.hide()
	action_buttons.show()
	health_bar_enemy.set_max(SceneCombat._enemy_data.get("max_hp", 100.0))
	health_bar_enemy.set_value(SceneCombat._enemy_data.get("max_hp", 100.0))
	log_label.text = "¡Revancha!"
