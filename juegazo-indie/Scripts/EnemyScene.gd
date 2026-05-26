class_name EnemyScene extends CharacterBody2D

@export var enemy_name    := "Goblin"
@export var max_hp        := 80.0
@export var attack        := 12.0
@export var defense       := 4.0
@export var xp_reward     := 30.0
@export var sprite_frames : SpriteFrames

@onready var health_component: Health_Component         = %HealthComponent
@onready var experience_component: ExperienceComponent = %ExperienceComponent
@onready var trigger: CombatTriggerComponent            = %CombatTriggerComponent

func _ready() -> void:
	health_component.max_health = max_hp
	health_component.current_health = max_hp
	experience_component.xp_amount = xp_reward

	health_component.died.connect(_on_died)
	trigger.combat_requested.connect(_on_combat_requested)
	trigger.rematch_ready.connect(_on_rematch_ready)

func _on_combat_requested(data: Dictionary) -> void:
	SceneCombat.start(data, self)

func _on_died() -> void:
	experience_component.grant()
	trigger.mark_defeated()

func _on_rematch_ready() -> void:
	health_component.current_health = max_hp
	SceneCombat.start(_build_data(), self)

func _build_data() -> Dictionary:
	return {
		"name": enemy_name, "max_hp": max_hp,
		"attack": attack, "defense": defense,
		"xp_reward": xp_reward, "sprite": sprite_frames,
	}
