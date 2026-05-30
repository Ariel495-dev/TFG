# EnemyScene.gd
class_name EnemyScene extends CharacterBody2D

@export var enemy_name:    String       = "Goblin"
@export var max_hp:        float        = 80.0
@export var max_stamina:   float        = 100.0
@export var stamina_regen: float        = 4.0
@export var action_regen:  float        = 15.0
@export var attack:        float        = 12.0
@export var defense:       float        = 4.0
@export var xp_reward:     float        = 30.0
@export var soul_reward:   int          = 10
@export var sprite_frames: SpriteFrames = null

@onready var health_component:         Health_Component       = %Health_Component
@onready var stamina_component:        StaminaComponent       = %StaminaComponent
@onready var action_component:         ActionComponent        = %ActionComponent
@onready var experience_component:     ExperienceComponent    = %ExperienceComponent
@onready var soul_reward_component:    SoulRewardComponent    = %SoulRewardComponent
@onready var combat_trigger_component: CombatTriggerComponent = %CombatTriggerComponent
@onready var animated_sprite_2d:       AnimatedSprite2D       = $AnimatedSprite2D

func _ready() -> void:
	health_component.max_health      = max_hp
	health_component.current_health  = max_hp
	stamina_component.set_max(max_stamina)
	stamina_component.set_regen(stamina_regen)
	action_component.regen_rate      = action_regen
	experience_component.xp_amount   = xp_reward
	soul_reward_component.soul_amount = soul_reward

	if sprite_frames != null:
		animated_sprite_2d.sprite_frames = sprite_frames

	health_component.died.connect(_on_died)
	combat_trigger_component.combat_requested.connect(_on_combat_requested)
	combat_trigger_component.rematch_ready.connect(_on_rematch_ready)

func _on_combat_requested(data: Dictionary) -> void:
	data["sprite_node"]       = animated_sprite_2d
	data["health_component"]  = health_component
	data["stamina_component"] = stamina_component
	data["action_component"]  = action_component
	SceneCombat.start(data, self)

func _on_died() -> void:
	experience_component.grant()
	soul_reward_component.grant()
	combat_trigger_component.mark_defeated()

func _on_rematch_ready() -> void:
	health_component.current_health = max_hp
	stamina_component.reset()
	action_component.reset()
	var data = _build_data()
	data["sprite_node"]       = animated_sprite_2d
	data["health_component"]  = health_component
	data["stamina_component"] = stamina_component
	data["action_component"]  = action_component
	SceneCombat.start(data, self)

func _build_data() -> Dictionary:
	return {
		"name":          enemy_name,
		"max_hp":        max_hp,
		"max_stamina":   max_stamina,
		"attack":        attack,
		"defense":       defense,
		"xp_reward":     xp_reward,
		"soul_reward":   soul_reward,
		"sprite_frames": sprite_frames,
	}
